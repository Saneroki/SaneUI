local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - PinView
--  The pins drawn: a button for each pin Pins.For gives, at a fixed size on the
--  screen whatever the zoom, in the game's own looks (its quest marks, flight
--  points, vignettes, town tracking and map legend), on a layer of the canvas
--  above the map and the game's minimap (Canvas.LEVELS), so they can be seen and
--  clicked in both views.
--
--      every pin   its own icon from the game's map icons (Pins.ICONS and the kinds' tables): no discs, no
--                  numbers. A quest in your log: the yellow question mark (the one the game's arrow leads to with
--                  a glow); on the full map a click shows it in the quest log and lets the arrow lead to it
--                  (QuestLog.lua). A quest giver of Core's data: the yellow exclamation mark, grey for a quest too
--                  low, a red question mark for one for later; on the full map a click shows its quests in the
--                  quest log as previews (QuestLog.Preview)
--      an objective  where a quest of your log needs you, at each spawn Core's data knows (Goals.lua): the quest log's
--                  sword or sack, or the game's speech bubble; no glow of its own. The tooltip what stands there, the
--                  quests it is for and the game's words of what is open; a click on the full map as on the quest's pin
--      the mouse on a quest in the quest log  that quest's pins glow a little (Light)
--      a cloud    pins that would cover each other stand side by side round their middle (Pins.Spread; Saneroki,
--                  2026-11-11, in place of one marker with the game's plus), each its own pin; closer in each stands
--                  at its own place. Many spawns of one thing in one spot (a herb's, a creature's) are one marker in
--                  its picture: its tooltip what is there; a click zooms in, a double click puts the game's map pin
--                  on the first
--      what it gives  on a rare's, a chest's, a herb's and a vein's tooltip, and on the dots of a dungeon's enemies and its
--                  bosses' loot (Dungeons.lua): each item with how often it comes, from Core's Data.Drops: what shipped
--                  and what play counted. A percent once enough came, until then how many of how many; the likeliest
--                  first, at most PinView.DROPS lines. In a gathered marker a line or so under each name
--      a dock      a boat's, a zeppelin's or the tram's: under its name when it next comes here and leaves,
--                  counting down while the tooltip shows (DockWatch.Timer; Saneroki, 2026-11-09), then its ports;
--                  its way round drawn over the map while the mouse is on it, a flight point's flights too (Paths.lua)
--      a rare      its tooltip as a dungeon boss's (Dungeons.lua): a creature's panel (Core.TipLook: its own 3D
--                  model in the portrait's place, the silver dragon of a rare round it, its level on the plaque),
--                  its name in its side's colour, under it Rare or Rare Elite, its kind and when it comes back;
--                  then the sections Abilities and its loot, each with the game's icons, and with Alt each one's
--                  details (an ability's description, an item's effects and stats). Also the Sane Rare tracker's
--                  notice's (RareTracker.lua: PinView.Tip). With Alt held, its 3D model (the game's, by its
--                  creature: SetCreature) stands beside the
--                  tooltip, at its left, or at its right where the left has no room; Alt let go, or the
--                  mouse off the pin, and it goes. Where the game has no model of it, nothing stands there
--      a flight master  open (Taxi.lua): the flight points large and over all, the one you stand at glowing, a click
--                  on one flies there, its tooltip what it costs; its name and price at its right, sized by the zoom,
--                  under every pin (PinView.LABEL)
--      a flight point, a dock  on the full map a click keeps its ways drawn (Paths.lua), its pin glowing; again: no more
--      a click     its own, where it has one (Act; above): Shift and a click on one that leads into another
--                  map opens that map; else as a click on the map there (Canvas.lua: the map under it opens, or
--                  a ping). A double click, on the small map and the full one: the game's map pin where it
--                  stands, as Ctrl and a click
--
--  Placed against the canvas' holder like the map's layers, so a drag moves them
--  with the map; laid out again with the map. A pin shows only while it lies
--  wholly inside the canvas (Fit: the game does not cut a button at its edge, nor
--  its clicks). A press on a pin is the map's (a drag that starts on a pin moves
--  the map), and so is a click, which asks the pin first (Canvas.Release).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Pins = ns.Pins
local Ships = Core.Data.Ships()
local PinView = {}
ns.PinView = PinView

PinView.GLOW = "UI-QuestPoi-OuterGlow" -- behind the quest the game's arrow leads to
PinView.GREY = 0.8 -- a grey quest's icon: so opaque, its colour taken away
PinView.LIT, PinView.LIT_ALPHA = 1.9, 0.75 -- a pin of the quest under the mouse: its glow's size over the pin's, how strong
PinView.PLUS = "Garr_Building-AddFollowerPlus" -- a gathered marker of pins with different icons: the game's round plus
PinView.TIP_ICON = 16 -- a pin's icon before its name in a gathered marker's tooltip
PinView.DROPS = 8     -- what a thing gives, lines of a tooltip at most (a gathered marker's, over all its pins)
PinView.DROPPERS = { rare = true, treasure = true, herb = true, ore = true, book = true } -- the kinds of pin that tell what
                                                                                      -- they give (a book: itself)

-- The pins' own levels over their layer, by kind (a gathered marker: its first pin's), in Pins' order: a higher kind
-- stands over a lower one. Kinds that share a level are those that may stand together in a cloud (Pins.Spread)
-- (the game's own marks nearby aside); at most PinView.LEVELS, all under the marks (Canvas.LEVELS).
PinView.TIERS = { log = 6, quest = 5, rare = 4, goal = 4, entrance = 3, flight = 3, travel = 3, place = 3, treasure = 2,
                  service = 1 }
PinView.LEVELS = 6
-- At a flight master a flight point's name and price at its right (Saneroki, 2026-11-11), its size by the zoom: LABEL.MAX
-- points with the view LABEL.AT yards high, LABEL.STEP less each time the view is twice as high, LABEL.MIN at least; on
-- a layer under every pin, so it never covers one nor takes its click.
PinView.LABEL = { MIN = 9, MAX = 15, AT = 2000, STEP = 2, GAP = 3 }
PinView.MODEL_WIDTH, PinView.MODEL_HEIGHT = 170, 210 -- a rare's model beside its tooltip (Alt held)
PinView.MODEL_GAP = 8     -- between the tooltip and the model
PinView.MODEL_TURN = -0.5 -- radians: a little from the side, as the tooltips turn a creature

local layer, holder, view
local words -- the flight points' names at a flight master: a layer under the pins' (PinView.LABEL)
local used, free = {}, {} -- [key] = button while in view; buttons let go
local hovered             -- the pin's button the mouse is on (Tip), for the rare's model
local tipped              -- the pin's button whose tooltip was drawn last: again when an item it asked for has come
local lit                 -- the quest under the mouse in the quest log: its pins glow (Light)
local stage               -- the rare's model frame, once made; false where the client has none
local Model               -- below

-- A pin's tooltip: its name (an NPC's role: Pins.lua), its lines; a quest's objectives as the game tells them. Words
-- the tooltip says already are not said again (two trainers of a kind gathered: Priest Trainer once).
local said = {} -- the words in the tooltip so far, for one tooltip
local function Say(words, r, g, b, wrap)
    if said[words] then return end
    said[words] = true
    GameTooltip:AddLine(words, r, g, b, wrap)
end

-- A pin's name with its icon before it, as its pin shows it (a grey one grey, a tinted one in its colour); one not yet
-- confirmed by the game with the red ! between them (Core.UNCONFIRMED_MARK).
local function Iconed(pin, words)
    local size = PinView.TIP_ICON
    if pin.doubt then words = Core.UNCONFIRMED_MARK .. words end
    if pin.texture then return ("|T%s:%d:%d|t %s"):format(pin.texture, size, size, words) end
    if not pin.atlas then return words end
    local tint = pin.tint or (pin.grey or pin.dim) and { 0.6, 0.6, 0.6 } or nil
    if tint then
        return ("|A:%s:%d:%d:0:0:%d:%d:%d|a %s"):format(pin.atlas, size, size, math.floor(tint[1] * 255),
            math.floor(tint[2] * 255), math.floor(tint[3] * 255), words)
    end
    return ("|A:%s:%d:%d|a %s"):format(pin.atlas, size, size, words)
end
PinView.Iconed = Iconed

-- A percent as short as it goes: 100, 7.5.
local function Percent(chance)
    return (("%.1f"):format(chance):gsub("%.0$", ""))
end

-- How often an entry of Core's Drops comes, in words; nil when nobody can say. A chance the set gives alone; one counted with
-- what it was counted from; while too few came, only how many of how many; a chance of 0 in the set is one under 1 %.
function PinView.Often(entry)
    local TEXT = Pins.TEXT
    if entry.chance == 0 then return TEXT.dropUnder end
    if entry.chance and (entry.shipped or entry.listed) then return TEXT.dropChance:format(Percent(entry.chance)) end
    if entry.chance then return TEXT.dropCounted:format(Percent(entry.chance), entry.drops, entry.loots) end
    if entry.drops > 0 and entry.loots > 0 then return TEXT.dropCount:format(entry.drops, entry.loots) end
    return nil
end

-- The heading of what a thing gives: a creature's corpse, a node's gather, a chest.
local function DropsTitle(key, entry)
    if key:find("^npc:") then return Pins.TEXT.dropsCorpse end
    return entry.how == "gather" and Pins.TEXT.dropsNode or Pins.TEXT.dropsChest
end

-- What a thing ("npc:69", "object:1617") gives on the tooltip being written, the likeliest first, at most limit lines: under a
-- heading, or inset under its name (a gathered marker). An item only for those on a quest only while you are. How many lines
-- it wrote, and whether one of them is not yet confirmed (the red ! before its name). details(item): what goes under each
-- item's line (a rare's, with Alt: Dungeons.ItemDetails).
function PinView.Drops(key, limit, inset, details)
    local shown, more, doubt = 0, 0, false
    for _, entry in ipairs(Core.Data.Drops():Of(key)) do
        if entry.quest == 0 or Core.Plain(Core.Ask(C_QuestLog.IsOnQuest, entry.quest)) == true then
            if shown >= limit then
                more = more + 1
            else
                local words, r, g, b = ns.Dungeons.ItemLine(entry.item, entry.doubt and Core.UNCONFIRMED_MARK or nil)
                if words then
                    if shown == 0 and not inset then Core.TipSection(GameTooltip, DropsTitle(key, entry)) end
                    shown = shown + 1
                    doubt = doubt or entry.doubt == true
                    words = (inset and "    " or "") .. words
                        .. (entry.how == "skin" and Pins.TEXT.dropSkinned or entry.how == "pickpocket" and Pins.TEXT.dropPicked or "")
                    local often = PinView.Often(entry)
                    if often then
                        GameTooltip:AddDoubleLine(words, often, r or 1, g or 1, b or 1, 1, 1, 1)
                    else
                        GameTooltip:AddLine(words, r or 1, g or 1, b or 1)
                    end
                    if details then details(entry.item) end
                end
            end
        end
    end
    if more > 0 and shown > 0 and not inset then GameTooltip:AddLine(ns.Dungeons.TEXT.more:format(more), 0.6, 0.6, 0.6) end
    return shown, doubt
end

-- The thing a pin's tooltip tells the gifts of: a rare, a chest, a herb, a vein; nil for any other.
local function Dropper(pin)
    if not (PinView.DROPPERS[pin.kind] or pin.rare) then return nil end
    local key = pin.thing or pin.key
    return type(key) == "string" and key:find("^%a+:%d+$") and key or nil
end

-- A pin's further lines: words, words in their colour { words, r, g, b }, or an objective: the game's words of it now.
local function Lines(pin)
    for _, line in ipairs(pin.lines or {}) do
        if type(line) ~= "table" then
            Say(line, 1, 1, 1, true)
        elseif line.quest then
            local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, line.quest)
            local objective = type(objectives) == "table" and objectives[line.index]
            local words = type(objective) == "table" and Core.Plain(objective.text)
            if words and words ~= "" then Say("- " .. words, 1, 1, 1, true) end
        else
            Say(line[1], line[2], line[3], line[4], true)
        end
    end
end

-- A rare's creature (its NPC ID), from its pin's key ("npc:<id>": Core's data, or the game's mark of it).
local function Creature(pin)
    if not pin or pin.kind ~= "rare" or pin.gathered then return nil end
    return tonumber(tostring(pin.key):match("^npc:(%d+)$"))
end

-- A rare's tooltip as a dungeon boss's (Dungeons.lua, BossTip): its look (Core.TipLook), drawn by Sane UI's tooltips
-- as a creature's panel: its model by its creature, the silver dragon, its level on the plaque. Core's NPCs tell its rank,
-- levels, kind, side, abilities and how long it takes to come back, where they know them.
local NPC_FACTS = Core.Data.Set("NPCs")
PinView.FRIEND, PinView.NEUTRAL = { 0.25, 1, 0.25 }, { 1, 1, 0 } -- a rare's name: friendly, neutral (a foe: Dungeons.FOE)
PinView.TEXT = { rare = Core.Word("RARE", "Rare"), elite = Core.Word("ELITE", "Elite"), respawn = "Respawns after %s" }
local faction -- the player's side, asked once
local function RareLook(npc)
    local level = tonumber(NPC_FACTS:Get(npc, "levelMax") or NPC_FACTS:Get(npc, "levelMin"))
    local boss = NPC_FACTS:Get(npc, "boss") == true
    return { creature = npc, dragon = "silver", badge = boss and "??" or level and tostring(level) or nil }
end

local function RareColour(npc)
    faction = faction or Core.Plain(UnitFactionGroup("player"))
    local side = NPC_FACTS:Get(npc, faction == "Horde" and "horde" or "alliance")
    local colour = side == "friendly" and PinView.FRIEND or side == "neutral" and PinView.NEUTRAL or ns.Dungeons.FOE
    return colour[1], colour[2], colour[3]
end

-- Under its name: Rare or Rare Elite, its kind, when it comes back.
local function RareLines(npc)
    local words = PinView.TEXT.rare
    if NPC_FACTS:Get(npc, "rank") == "rareelite" then words = words .. " " .. PinView.TEXT.elite end
    GameTooltip:AddLine(words, 0.8, 0.82, 0.88)
    local kind = NPC_FACTS:Get(npc, "kind")
    if type(kind) == "string" and kind ~= "other" then GameTooltip:AddLine((kind:gsub("^%l", string.upper)), 1, 1, 1) end
    local respawn = tonumber(NPC_FACTS:Get(npc, "respawn"))
    if respawn and respawn > 0 then
        local time = Core.Ask(rawget(_G, "SecondsToTime"), respawn) or ("%d min"):format(math.ceil(respawn / 60))
        GameTooltip:AddLine(PinView.TEXT.respawn:format(time), 0.6, 0.6, 0.6)
    end
end

-- Its abilities, a section as a boss's: each with its icon and name as the game has them, with Alt its description.
-- Whether those shown are not yet confirmed (Core's data of it).
local function RareAbilities(npc, alt)
    local shown, more = 0, 0
    for _, id in ipairs(NPC_FACTS:Get(npc, "abilities") or {}) do
        if shown >= ns.Dungeons.LINES then
            more = more + 1
        else
            local words = ns.Dungeons.SpellLine(id)
            if words then
                if shown == 0 then Core.TipSection(GameTooltip, ns.Dungeons.TEXT.abilities) end
                shown = shown + 1
                GameTooltip:AddLine(words, 1, 1, 1)
                if alt then ns.Dungeons.SpellDetails(id) end
            end
        end
    end
    if more > 0 and shown > 0 then GameTooltip:AddLine(ns.Dungeons.TEXT.more:format(more), 0.6, 0.6, 0.6) end
    return shown > 0 and NPC_FACTS:Unverified(npc) == true
end

-- A dock's tooltip, while it shows: drawn again as its timer's second turns (the game's tooltip asks its owner's
-- UpdateTooltip every TOOLTIP_UPDATE_TIME, as for an action button's cooldown).
local Tip
local ticked -- the server's second the dock's tooltip was last drawn at
local ticking = ns.Guard(function(button)
    local second = math.floor(Ships.Now())
    if second ~= ticked and button.pin and button.pin.dock then Tip(button) end
end)

function Tip(button)
    local pin = button.pin
    if not pin then return end
    tipped = button
    button.UpdateTooltip = pin.dock and not pin.gathered and ticking or nil
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    wipe(said)
    if pin.gathered then
        -- What is there, one under the other, each with its own pin's icon: the first as the heading; Unconfirmed Data
        -- under them where one is not yet confirmed; what each gives inset under its name, while there is room
        local doubt, room, names = false, PinView.DROPS, 0
        for index, each in ipairs(pin.gathered) do
            if each.doubt or each.unverified then doubt = true end
            local words = each.role or each.name or "?"
            local new = not said[words]
            if new then names = names + 1 end
            if names > 12 then break end
            if index == 1 then
                said[words] = true
                GameTooltip:SetText(Iconed(each, words), 1, 1, 1)
            elseif new then
                said[words] = true
                GameTooltip:AddLine(Iconed(each, words), 1, 0.82, 0)
            end
            if new and each.kind == "goal" then Lines(each) end
            local key = new and room > 0 and Dropper(each)
            if key then
                local shown, unsure = PinView.Drops(key, room, true)
                room, doubt = room - shown, doubt or unsure
            end
        end
        if doubt then GameTooltip:AddLine(Pins.TEXT.unverified, 0.5, 0.5, 0.5) end
        return GameTooltip:Show()
    end
    local heading = pin.role or pin.name or "?"
    said[heading] = true
    local npc, alt = Creature(pin), IsAltKeyDown()
    if npc then
        Core.TipLook(GameTooltip, RareLook(npc))
        GameTooltip:SetText(pin.doubt and Core.UNCONFIRMED_MARK .. heading or heading, RareColour(npc))
        RareLines(npc)
    else
        GameTooltip:SetText(pin.doubt and Core.UNCONFIRMED_MARK .. heading or heading, 1, 1, 1)
    end
    if pin.kind == "log" and pin.quest then
        if pin.complete then GameTooltip:AddLine(Pins.TEXT.turnIn, 0.2, 1, 0.2) end
        local objectives = Core.Ask(C_QuestLog.GetQuestObjectives, pin.quest)
        for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
            local done = objective.finished
            if objective.text and objective.text ~= "" then
                GameTooltip:AddLine("- " .. objective.text, done and 0.5 or 1, done and 0.5 or 1, done and 0.5 or 1, true)
            end
        end
        GameTooltip:AddLine(Pins.TEXT.open, 0.5, 0.5, 0.5)
    else
        if pin.offer then Say(Pins.TEXT.offered, 1, 0.82, 0) end
        -- A boat's, a zeppelin's or the tram's: when it comes here next and leaves, counting down, as at the dock
        -- (Saneroki, 2026-11-09); how often it sails while a ride has not taught its times.
        local timer, known = pin.dock and ns.DockWatch.Timer(pin.way, pin.dock)
        if timer then
            ticked = math.floor(Ships.Now())
            if known then GameTooltip:AddLine(timer, 1, 1, 1) else GameTooltip:AddLine(timer, 0.6, 0.6, 0.6) end
        end
        Lines(pin)
        if pin.kind == "goal" then Say(Pins.TEXT.open, 0.5, 0.5, 0.5) end
        local key, unsure = Dropper(pin), false
        if npc then unsure = RareAbilities(npc, alt) end
        if key then
            local _, doubt = PinView.Drops(key, PinView.DROPS, nil, npc and alt and ns.Dungeons.ItemDetails or nil)
            unsure = unsure or doubt
        end
        if pin.unverified or unsure then GameTooltip:AddLine(Pins.TEXT.unverified, 0.5, 0.5, 0.5) end
    end
    GameTooltip:Show()
    hovered = button
    Model()
    ns.Safe("paths", ns.Paths.Show, pin) -- a flight point's flights, a dock's way round, drawn over the map
end

-- An item the tooltip asked for has come from the game: drawn again, once, on the next frame.
local Again = Core.Later(function()
    if tipped and tipped:IsMouseOver() and GameTooltip:GetOwner() == tipped then Tip(tipped) end
end)
ns.On("ITEM_DATA_LOAD_RESULT", function()
    if tipped then Again() end
end)

-- The game's map pin where a pin stands (its own map and its place there; a gathered marker's first pin), as Ctrl
-- and a click puts it on the map: the golden line leads there. Also for what else is clicked to put it somewhere
-- (a quest in the quest log, a herb found on the minimap): { map, x, y }; where the game takes none, it says so.
function PinView.Drop(pin)
    local first = pin.gathered and pin.gathered[1] or pin
    if first.map and first.x and ns.Live.SetWaypoint(first.map, first.x, first.y) then
        ns.Marks.Sound("UI_MAP_WAYPOINT_CONTROL_CLICK")
    else
        UIErrorsFrame:AddMessage(ns.TEXT.noPin, 1, 0.1, 0.1)
    end
end

-- A click's own for a pin (Canvas.lua asks first; a double click puts the game's map pin there, as Ctrl and a click
-- does): Shift and a click on a pin that leads into another map opens it; a gathered marker zooms in; on the full map
-- a quest shows in the quest log (in the log: the arrow leads to it; a giver's: its quests as previews). False where
-- the pin has none: the click is the map's there.
function PinView.Act(pin)
    if pin.taxi then return ns.Taxi.Fly(pin.taxi) end -- at a flight master: the flight there (Taxi.lua)
    if IsShiftKeyDown() and pin.to then
        ns.Canvas.Show(pin.to)
        return true
    end
    -- On the full map a flight point's or a dock's ways kept drawn, or let go (Paths.lua).
    if ns.Canvas.camera == ns.Window.full and ns.Paths.Toggle(pin) then return true end
    if pin.gathered then
        ns.Canvas.ZoomTo(pin.pu, pin.pv, 3)
        return true
    end
    if ns.Canvas.camera ~= ns.Window.full then return false end
    if pin.click == "quest" and pin.quest then
        ns.QuestLog.Focus(pin.quest)
        return true
    end
    if pin.click == "preview" and pin.quests then
        ns.QuestLog.Preview(pin.quests, pin.map, pin.x, pin.y)
        return true
    end
    return false
end

-- The model's frame, made the first time Alt is held over a rare: see-through, over the tooltips' layer, unseen
-- until the game has the model (OnModelLoaded).
local function Stage()
    if stage ~= nil then return stage end
    local made, model = pcall(CreateFrame, "PlayerModel", nil, UIParent)
    stage = made and model or false
    if not stage then return false end
    model:SetFrameStrata("TOOLTIP")
    model:SetSize(PinView.MODEL_WIDTH, PinView.MODEL_HEIGHT)
    model:Hide()
    pcall(model.SetScript, model, "OnModelLoaded", ns.Guard(function(self) self:SetAlpha(1) end))
    return model
end

-- The rare's model beside the tooltip while Alt is held over its pin (see above), else none.
function Model()
    local npc = hovered and hovered:IsMouseOver() and IsAltKeyDown() and Creature(hovered.pin)
    local model = (npc or stage) and Stage()
    if not model then return end
    if not npc then
        model:Hide()
        return
    end
    if model.npc ~= npc then
        model:SetAlpha(0)
        model:ClearModel()
        model.npc = nil
        if not pcall(model.SetCreature, model, npc) then return model:Hide() end
        model.npc = npc
        pcall(model.SetPortraitZoom, model, 0)
        pcall(model.SetFacing, model, PinView.MODEL_TURN)
        local file = Core.Ask(model.GetModelFileID, model)
        if type(file) == "number" and file > 0 then model:SetAlpha(1) end -- the game had it already
    end
    model:ClearAllPoints()
    local left = GameTooltip:GetLeft()
    if left and left > PinView.MODEL_WIDTH + PinView.MODEL_GAP then
        model:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -PinView.MODEL_GAP, 0)
    else
        model:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", PinView.MODEL_GAP, 0)
    end
    model:Show()
end

local function Left()
    hovered = nil
    GameTooltip_Hide()
    Model()
    ns.Safe("paths", ns.Paths.Hide)
end
-- A pin's tooltip off the map, and its end (the Sane Rare tracker's notice, RareTracker.lua): the button holds the pin
-- (button.pin), as a pin's own does.
PinView.Tip, PinView.Untip = Tip, Left

local function Down(button, mouse)
    ns.Canvas.Press(mouse)
end

local function Up(button, mouse)
    ns.Canvas.Release(mouse, button.pin)
end

-- A pin's level: over the layer, a higher kind over a lower one, and still under the marks (Canvas.LEVELS).
local function Level(button)
    local pin = button.pin
    local first = pin and (pin.gathered and pin.gathered[1] or pin)
    local tier = first and (first.taxi and PinView.LEVELS or PinView.TIERS[first.kind]) or 0 -- a flight master's over all
    button:SetFrameLevel(layer:GetFrameLevel() + 1 + math.min(tier, PinView.LEVELS))
end

local function Make()
    local button = CreateFrame("Button", nil, layer)
    button.glow = button:CreateTexture(nil, "BACKGROUND")
    button.glow:SetAtlas(PinView.GLOW)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.light = button:CreateTexture(nil, "HIGHLIGHT")
    button.light:SetAllPoints()
    button.light:SetBlendMode("ADD")
    button.light:SetAlpha(0.5)
    button:RegisterForClicks() -- the press and the release are the map's and the pin's (Down, Up)
    button:SetScript("OnMouseDown", ns.Guard(Down))
    button:SetScript("OnMouseUp", ns.Guard(Up))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", ns.Guard(Left))
    return button
end

-- Whether the pins of a gathered marker all have the same icon (atlas and colour): then it shows that one.
local function Alike(gathered)
    local first = gathered[1]
    if first.kind == "goal" then return true end -- never the plus: the first's picture, what stands there in the tooltip
    for index = 2, #gathered do
        local each = gathered[index]
        if each.atlas ~= first.atlas or each.tint ~= first.tint or (each.grey or each.dim) ~= (first.grey or first.dim) then
            return false
        end
    end
    return true
end
PinView.Alike = Alike

-- Whether a pin, or one in a gathered marker, belongs to a quest: the quest's own, or one of what it asks for.
local function Tied(pin, quest)
    if pin.quest == quest then return true end
    for _, goal in ipairs(pin.goals or {}) do
        if goal.quest == quest then return true end
    end
    for _, each in ipairs(pin.gathered or {}) do
        if Tied(each, quest) then return true end
    end
    return false
end

-- A button's look for its pin: its icon, whatever its kind (a gathered marker: its pins' where all have the same, else
-- the game's plus, PinView.PLUS), at its kind's size from the pin filter's slider. A grey quest without its colour, a tinted one in its
-- colour (a quest for later: red; a flight point not found yet: its colour taken out first, then red), the quest the
-- game's arrow leads to with a glow
-- behind it, a pin of the quest under the mouse in the quest log with a fainter one. Not made again while it is the
-- same (the same first pin, size and glow: a pin's record is made anew whenever what it shows changes).
local function Look(button, pin)
    local first = pin.gathered and pin.gathered[1] or pin
    local size = (first.size or Pins.SIZE[first.kind] or 20) * ns.PinScale(first.kind)
    local glowing = (first.focused or first.here or ns.Paths.Active(first)) and not pin.gathered and true or false
    local plus = pin.gathered and not Alike(pin.gathered) or false
    local shining = lit ~= nil and Tied(pin, lit)
    if button.first == first and button.size == size and button.glowing == glowing and button.plus == plus
        and button.shining == shining then return end
    button.first, button.size, button.glowing, button.plus, button.shining = first, size, glowing, plus, shining
    button:SetSize(size, size)
    button.half = size / 2 -- how far it reaches from its middle (Fit); the focused quest's glow farther
    local icon, glow = button.icon, button.glow
    local grey, tint = first.grey or first.dim, first.tint
    if plus then grey, tint = nil, nil end
    icon:SetDesaturated(grey and true or false)
    if tint then icon:SetVertexColor(tint[1], tint[2], tint[3], 1)
    else icon:SetVertexColor(1, 1, 1, grey and PinView.GREY or 1) end
    local atlas = plus and PinView.PLUS or first.atlas or not first.texture and Pins.ICONS.offer
    if atlas then
        icon:SetAtlas(atlas)
        button.light:SetAtlas(atlas)
    else
        -- A picture of its own: the whole of it, whatever atlas the button showed before
        icon:SetTexture(first.texture)
        icon:SetTexCoord(0, 1, 0, 1)
        button.light:SetTexture(first.texture)
        button.light:SetTexCoord(0, 1, 0, 1)
    end
    glow:Hide()
    if glowing or shining then
        local reach = glowing and 1.6 or PinView.LIT
        glow:SetSize(size * reach, size * reach)
        glow:SetPoint("CENTER")
        glow:SetAlpha(glowing and 1 or PinView.LIT_ALPHA)
        glow:Show()
    end
    if glowing then button.half = size * 0.8 end
end

-- The quest the mouse is on in the quest log (nil: off it): its pins glow a little while it is there, each drawn again
-- only if that changes it.
function PinView.Light(quest)
    if lit == quest then return end
    lit = quest
    PinView.Relook()
end

-- Every pin's look again (a quest lit, a flight point's or dock's ways kept drawn or let go: its glow).
function PinView.Relook()
    for _, button in pairs(used) do
        if button.pin then Look(button, button.pin) end
    end
end

function PinView.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    words = CreateFrame("Frame", nil, holder)
    words:SetSize(1, 1)
    words:SetPoint("CENTER")
    return layer
end

-- The layer at that frame level (the canvas' order: over the map and the game's minimap), its buttons over it, the
-- flight points' names at that level too, under every button.
function PinView.Stack(level)
    layer:SetFrameLevel(level)
    words:SetFrameLevel(level)
    for _, button in pairs(used) do Level(button) end
end

-- The names' size for a view so many yards high (PinView.LABEL), as one of Core's fonts made for it.
local function LabelFont(span)
    local label = PinView.LABEL
    local size = label.MAX - label.STEP * math.log(math.max(span or label.AT, 1) / label.AT) / math.log(2)
    size = math.floor(math.max(label.MIN, math.min(label.MAX, size)) + 0.5)
    return Core.Font("SaneUINavigationTaxi" .. size, "GameFontNormal", size, "OUTLINE") or "GameFontNormal", size
end

-- A button's name at its right: a flight point's at a flight master (Taxi.Label), in font of size points, else none.
local function Name(button, pin, font, size)
    local text = pin.taxi and not pin.gathered and ns.Taxi.Label(pin.taxi, pin.name)
    local label = button.label
    if not text then
        button.labeled = false
        if label then label:Hide() end
        return
    end
    if not label then
        label = words:CreateFontString(nil, "OVERLAY")
        button.label = label
    end
    label:SetFontObject(font)
    label.size = size
    label:SetText(text)
    label:ClearAllPoints()
    label:SetPoint("LEFT", button, "RIGHT", PinView.LABEL.GAP, 0)
    button.labeled = true
end

local seen = {}

-- Every pin in view placed, as the canvas laid it out (view: Canvas.view); small: the small window. The
-- buttons of pins still in view are kept, the others let go.
function PinView.Place(laidView, small)
    view = laidView
    wipe(seen)
    local pu, pv
    if small then
        local map, u, v = ns.Live.Player()
        local link = map and u and ns.Coords.Link(map, view.map)
        if link then pu, pv = link.du + link.su * u, link.dv + link.sv * v end
    end
    local drawn = Pins.Spread(Pins.For(view, small, pu, pv), view.k)
    local font, size
    if ns.Taxi.On() then font, size = LabelFont(view.span) end
    for index = 1, #drawn do
        local pin = drawn[index]
        local button = used[pin.key]
        if not button then
            button = table.remove(free) or Make()
            used[pin.key] = button
        end
        seen[pin.key] = true
        button.pin = pin
        Look(button, pin)
        Level(button)
        -- (in a cloud, pushed aside from its own place: Pins.Spread)
        button.x, button.y = (pin.pu - view.u) * view.k + (pin.sx or 0), (pin.pv - view.v) * view.k + (pin.sy or 0)
        button:ClearAllPoints()
        button:SetPoint("CENTER", holder, "CENTER", button.x, button.y)
        if font or button.labeled then Name(button, pin, font, size) end
    end
    for key, button in pairs(used) do
        if not seen[key] then
            button:Hide()
            if button.label then button.label:Hide() end
            button.pin, button.inside, button.labeled = nil, false, false
            used[key] = nil
            free[#free + 1] = button
        end
    end
    PinView.Fit()
end

-- Each pin shown while it lies wholly inside the canvas' rectangle (Canvas.edge, in the holder's units); told the
-- game only when that changed.
function PinView.Fit()
    local Inside = ns.Canvas.Inside
    for _, button in pairs(used) do
        local inside = Inside(button.x, button.y, button.half)
        if inside ~= button.inside then
            button.inside = inside
            button:SetShown(inside)
        end
        if button.label then button.label:SetShown(inside and button.labeled or false) end
    end
end

-- Every pin out of sight (the window hidden).
function PinView.Clear()
    for key, button in pairs(used) do
        button:Hide()
        if button.label then button.label:Hide() end
        button.pin, button.inside, button.labeled = nil, false, false
        used[key] = nil
        free[#free + 1] = button
    end
    hovered = nil
    if stage then stage:Hide() end
end

-- Alt pressed or let go over a rare's pin: its tooltip drawn again (each ability's and item's details) and its model
-- comes or goes.
ns.On("MODIFIER_STATE_CHANGED", function()
    if hovered and Creature(hovered.pin) and hovered:IsMouseOver() and GameTooltip:GetOwner() == hovered then
        return Tip(hovered)
    end
    if hovered or (stage and stage:IsShown()) then Model() end
end)
