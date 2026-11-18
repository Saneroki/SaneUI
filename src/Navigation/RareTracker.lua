local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - RareTracker
--  The Sane Rare tracker: a rare, a treasure or an event near you, told the
--  moment the game shows it, with the game's war horn and a notice at the
--  screen's right edge under the minimap (Saneroki, 2026-11-11), in the look of
--  what SaneUI tells over the world: outlined words on a faint dark shade whose
--  sides fade out, the right one ending at the screen's edge.
--
--      found by     the game's marks near you (its vignettes, those it puts on the minimap: rares, treasures,
--                   events; Retail's: Forever's client has none), and a rare creature itself as soon as the game
--                   shows it to you (its nameplate, your target, the mouse on it: UnitClassification rare or
--                   rareelite), for the rares the game gives no mark. A chest or a book the interact key picks
--                   near you (the soft target: what Core's Objects says it is). A book a librarian asks for
--                   (Core's Objects, kind book) within RareTracker.BOOK_REACH yards of you, looked for every
--                   RareTracker.SCAN seconds, while this character still needs it: its quest not done, the book
--                   not in its bags or bank, and one only for those on a quest only while it is (Saneroki,
--                   2026-11-11). Not inside an instance; never a dead one
--      the notice   at its left the rare's own 3D model (the game's model of its creature), for a treasure or an
--                   event the game's icon of its mark; its name in gold, under it what it is (Rare, Rare Elite,
--                   Treasure, Event) and its level, under that how far it is and which way (kept up to date)
--      the mouse    on it: the tooltip of its pin on the map (PinView.lua: a rare's abilities and loot); a double
--                   click puts the game's map pin on it, and the golden line leads there (Planner.lua), as a double
--                   click on a pin does; a right click sends it away; a drag with the left button moves the notices,
--                   kept where they are let go (ns.store.rareTracker; /sane testraretracker reset: under the minimap
--                   again)
--      how long     until it is sent away (a right click), the rare is dead or the treasure taken (its mark gone or
--                   dead, the creature seen dead: your target, the mouse on it, its nameplate; a loot window from
--                   it), a book gathered (in the bags, its quest done), or you are
--                   RareTracker.FAR yards from it, in another part of the world or an instance; then it fades out
--                   (Saneroki, 2026-11-11). A /reload ends them too. At most RareTracker.MOST at once, the newest
--                   nearest their place, the others under it (over it in the screen's lower half); the same thing
--                   seen again while its notice shows: that notice kept, no sound; told again only after
--                   RareTracker.AGAIN seconds
--      settings     Sane Rare tracker (on), what it tells of (rares, treasures, events), its sound
--      /sane testraretracker  a notice as a find brings it, with its sound: the nearest rare of Core's data on
--                   your map, else a made-up one ahead of you; "chest" a treasure's, "book" the nearest book's,
--                   "event" an event's; "reset" the
--                   notices' place under the minimap again
--
--      RareTracker.Found(find, test)  tells of a find: { kind, thing, name, map, x, y, level, elite, atlas, vignette
--                                     (the game's mark of it), guid (the creature's) };
--                                     test: whatever the settings say and whenever it was told last
--      RareTracker.Kind(atlas)        what a mark of the game's is: "rare", "treasure" or "event"
--      RareTracker.Hide()             every notice gone (the module stands down, the switch goes off)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live = ns.Coords, ns.Live
local RareTracker = {}
ns.RareTracker = RareTracker

RareTracker.BELOW = 10   -- between the minimap and the first notice
RareTracker.WIDTH = 250  -- the shade, without its edges that fade out
RareTracker.EDGE = 60
RareTracker.HEIGHT = 72
RareTracker.GAP = 4      -- between two notices
RareTracker.PICTURE = 60 -- the model's square at the left; a mark's icon in it ICON
RareTracker.ICON = 40
RareTracker.PAD = 6
RareTracker.NAME, RareTracker.LINE = 19, 14 -- the words' sizes
RareTracker.DARK = 0.5   -- the shade
RareTracker.FAR = 400    -- yards from it: it goes
RareTracker.NEAR = 25    -- yards from it: near you
RareTracker.BOOK_REACH = 100 -- yards: a book still to gather told as you come so near
RareTracker.SCAN = 2     -- seconds between two looks for books near you
RareTracker.BOOK = "lorewalking-map-icon" -- a book's picture: the game's, as the map's book pins have it
RareTracker.FADE_IN, RareTracker.FADE_OUT = 0.25, 1
RareTracker.MOST = 3
RareTracker.AGAIN = 300
RareTracker.LOOK = 0.5   -- seconds between two looks at where it is
RareTracker.REACH = 250  -- yards: a rare seen in person stands at the nearest point of Core's data within this
RareTracker.AHEAD = 80   -- yards: the made-up rare of the test, north-east of you
-- The sounds to choose from: the game's own (its sound kits), heard on the game's master channel. The war horn of a
-- garrison's invasion is the first.
RareTracker.SOUNDS = { horn = 44292, chime = 45142, warning = 8959 }

local FONT = "Interface\\AddOns\\SaneUI\\Fonts\\Expressway.ttf"
local GOLD = { 1, 0.82, 0 }
local SILVER = { 0.8, 0.82, 0.88 } -- a rare's rank, as its silver dragon
local LIGHT = { 0.95, 0.95, 0.95 }
local BLUE = { 0.55, 0.78, 1 } -- a book's kind
-- The test's made-up rare where Core's data has none on your map: a creature both games have.
local SAMPLE = { thing = "npc:448", name = "Hogger", level = 11, elite = true }

RareTracker.TEXT = {
    rare = Core.Word("RARE", "Rare"),
    elite = Core.Word("ELITE", "Elite"),
    treasure = "Treasure",
    book = "Book",
    event = "Event",
    level = Core.Word("LEVEL", "Level"),
    near = "Near you",
    away = "%s %s", -- how far, which way
    ways = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" },
    click = "Double click: the map pin there. Right click: away. Drag: move.",
    away1 = "Right click: away. Drag: move.",
    reset = "the Sane Rare tracker's notices stand under the minimap again.",
    chest = "A treasure chest",
    aBook = "A library book",
    anEvent = "Something going on",
    about = "a notice of the Sane Rare tracker as a find brings it, with its sound (chest, book, event: theirs; reset: its place under the minimap)",
}
local TEXT = RareTracker.TEXT

local NPCS, OBJECTS, QUESTS = Core.Data.Set("NPCs"), Core.Data.Set("Objects"), Core.Data.Set("Quests")
local holder        -- the notices' place, as large as one, dragged; its OnUpdate keeps them (shown while one shows):
                    -- RareTracker.holder
local dragging      -- the notices are being dragged
local shown = {}    -- the notices in sight, the newest first (RareTracker.shown, read only)
local spare = {}    -- notices let go, to be used again
local seen = {}     -- [thing] = GetTime() it was last told
local marked = {}   -- [the game's vignette GUID] = true: looked at already
local taken = {}    -- [GUID] = true: a loot window came from it (a chest opened, a book or a corpse looted)
local books = {}    -- the books on the player's map (Core's places): { map, list }, read anew when either changes
local since = 0     -- seconds since the last look
RareTracker.shown = shown

-------------------------------------------------------------------------------
--  What a find is
-------------------------------------------------------------------------------
-- What a mark of the game's is, by its atlas: its treasures' have Loot in their name, its rares' Kill; the rest are
-- events and the like.
function RareTracker.Kind(atlas)
    atlas = type(atlas) == "string" and atlas:lower() or ""
    if atlas:find("loot", 1, true) or atlas:find("treasure", 1, true) then return "treasure" end
    if atlas:find("kill", 1, true) then return "rare" end
    return "event"
end

-- The creature or object a GUID names, as Core's data keys them ("npc:69", "object:1617").
local function Thing(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" then return "npc:" .. id end
    if kind == "GameObject" then return "object:" .. id end
    return nil
end

local function Creature(thing)
    return tonumber(type(thing) == "string" and thing:match("^npc:(%d+)$") or nil)
end

-- Whether a kind is wanted now: the switch on, the kind ticked, the module running, outside an instance.
local function Wanted(kind)
    local options = ns.options
    if ns.off or not options or options.rareTracker == false then return false end
    local kinds = options.rareKinds
    if type(kinds) == "table" and not kinds[kind] then return false end
    return Core.Ask(rawget(_G, "IsInInstance")) ~= true
end

-- Whether a thing may be told again: never told, or told RareTracker.AGAIN seconds ago.
local function Fresh(thing)
    local last = seen[thing]
    return not last or GetTime() - last >= RareTracker.AGAIN
end

-- The point of Core's data nearest the player where a thing stands on this map, within RareTracker.REACH; nil for none.
local function Nearest(thing, map)
    local data = Core.Data.Map and Core.Data.Map()
    local spawns = data and Core.Ask(data.Spawns, data, thing)
    local points = type(spawns) == "table" and spawns[map]
    local box = Coords.Box(map)
    local here = Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    if type(points) ~= "table" or not box or not here then return nil end
    local px, py = Core.Plain(here.x), Core.Plain(here.y)
    if not (px and py) then return nil end
    local best, bx, by = RareTracker.REACH, nil, nil
    for _, point in ipairs(points) do
        local yards = math.sqrt(((point[1] - px) * box.width) ^ 2 + ((point[2] - py) * box.height) ^ 2)
        if yards <= best then best, bx, by = yards, point[1], point[2] end
    end
    return bx, by
end

-------------------------------------------------------------------------------
--  Where it is, from you
-------------------------------------------------------------------------------
-- How far a find is from you in yards, and which way (degrees from north, clockwise); math.huge where you are in another
-- part of the world (another plane) or the game tells no place of yours (an instance); nil where it has no place.
local function Yards(find)
    if not (find.map and find.x and find.y) then return nil end
    local home, u, v = Coords.PlaneOf(find.map), nil, nil
    if home then u, v = Coords.MapToPlane(find.map, find.x, find.y, home) end
    if not u then return nil end
    local plane, pu, pv = Coords.Player()
    if plane ~= home or not pu then return math.huge end
    local east, north = u - pu, v - pv
    return math.sqrt(east * east + north * north), math.deg(math.atan2(east, north)) % 360
end

-- How far a find is and which way, in words: near you where it has no place or stands close.
local function Where(find)
    local yards, turn = Yards(find)
    if not yards or yards <= RareTracker.NEAR or yards == math.huge then return TEXT.near end
    return TEXT.away:format(Core.Distance(yards), TEXT.ways[math.floor((turn + 22.5) / 45) % 8 + 1])
end

-- Whether the game shows that creature dead now: your target, the one under the mouse, one with a nameplate.
local function Dead(guid)
    local function Is(unit)
        return unit ~= nil and Core.Ask(UnitGUID, unit) == guid and Core.Ask(UnitIsDead, unit) == true
    end
    if Is("target") or Is("mouseover") then return true end
    local plates = rawget(_G, "C_NamePlate")
    local list = type(plates) == "table" and Core.Ask(plates.GetNamePlates)
    for _, plate in ipairs(type(list) == "table" and list or {}) do
        if Is(Core.Plain(plate.namePlateUnitToken)) then return true end
    end
    return false
end

-- A find's place as its mark has it now (a rare walks); whether it is over: its mark gone (dead, taken, out of the game's
-- reach) or dead, the creature seen dead, or you too far from it.
local function Follow(notice)
    local find = notice.find
    if not (find.vignette and find.map) then return end
    local position = Core.Ask(C_VignetteInfo.GetVignettePosition, find.vignette, find.map)
    local x, y = type(position) == "table" and Core.Plain(position.x), type(position) == "table" and Core.Plain(position.y)
    if x and y then
        find.x, find.y = x, y
        notice.pin.x, notice.pin.y = x, y
    end
end

-- The book an object gives (Core's Drops) and the quests that ask for it (Core's Quests), and the quest one only for those
-- on it is (0: anyone); nil where Core's data knows none.
local function Book(object)
    local drops = Core.Data.Drops and Core.Data.Drops()
    local entries = drops and Core.Ask(drops.Of, drops, "object:" .. tostring(object))
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        local quests = QUESTS:Keys("byObjective", entry.item)
        if #quests > 0 then return entry.item, quests, entry.quest or 0 end
    end
    return nil
end

-- Whether this character still needs a book: not in its bags or bank, none of its quests done, and where it is only for
-- those on a quest, on it. One Core's data knows nothing of: yes.
local function Needed(item, quests, only)
    if not item then return true end
    local items = rawget(_G, "C_Item")
    local count = Core.Ask(type(items) == "table" and items.GetItemCount or rawget(_G, "GetItemCount"), item, true)
    if type(count) == "number" and count > 0 then return false end
    local log = rawget(_G, "C_QuestLog")
    local done = type(log) == "table" and log.IsQuestFlaggedCompleted or rawget(_G, "IsQuestFlaggedCompleted")
    for _, quest in ipairs(quests or {}) do
        if Core.Ask(done, quest) == true then return false end
    end
    if only and only ~= 0 and Core.Ask(type(log) == "table" and log.IsOnQuest, only) ~= true then return false end
    return true
end

-- A book's name: its item's, as the game has it (asked of it while it has not loaded it); nil while unknown.
local function BookName(item)
    if not item then return nil end
    local name = Core.Ask(C_Item.GetItemInfo, item)
    if not name then Core.Ask(C_Item.RequestLoadItemDataByID, item) end
    return name
end

local function Over(find)
    if find.guid and taken[find.guid] then return true end
    if find.item and not Needed(find.item, find.quests, find.only) then return true end
    if find.vignette then
        local info = Core.Ask(C_VignetteInfo.GetVignetteInfo, find.vignette)
        if type(info) ~= "table" or Core.Plain(info.isDead) == true then return true end
    end
    if find.guid and Dead(find.guid) then return true end
    local yards = Yards(find)
    return yards ~= nil and yards > RareTracker.FAR
end

-- What it is, and its level: "Rare Elite, Level 24", "Treasure".
local function What(find)
    local words = find.kind == "rare" and TEXT.rare or TEXT[find.kind] or TEXT.event
    if find.elite then words = words .. " " .. TEXT.elite end
    if find.level and find.level > 0 then words = ("%s, %s %d"):format(words, TEXT.level, find.level) end
    return words
end

-------------------------------------------------------------------------------
--  The notices
-------------------------------------------------------------------------------
-- A part of the dark behind it, left to right: its middle even, its edges fading out into the world.
local function Shade(parent, from, to)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and rawget(_G, "CreateColor") then
        texture:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, from), CreateColor(0, 0, 0, to))
    else
        texture:SetVertexColor(0, 0, 0, (from + to) / 2)
    end
    return texture
end

local function Words(parent, size)
    local words = parent:CreateFontString(nil, "OVERLAY")
    words:SetFont(FONT, size, "OUTLINE")
    words:SetJustifyH("LEFT")
    words:SetWordWrap(false)
    return words
end

local Let -- below

-- The mouse on a notice: its pin's tooltip, as on the map, and what a click does.
local function Entered(notice)
    local pin = notice.pin
    if not pin then return end
    ns.PinView.Tip(notice)
    GameTooltip:AddLine(pin.map and pin.x and TEXT.click or TEXT.away1, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function Left()
    ns.PinView.Untip()
end

local function Clicked(notice, mouse)
    if mouse == "RightButton" then Let(notice) end
end

local function Doubled(notice, mouse)
    local pin = notice.pin
    if mouse == "LeftButton" and pin and pin.map and pin.x then ns.PinView.Drop(pin) end
end

local Stack, Look -- below

-- A drag with the left button on a notice moves them all; where they are let go is kept, from the screen's top right.
local function Dragged()
    if not holder then return end
    dragging = true
    Left()
    holder:StartMoving()
end

local function Dropped()
    if not (holder and dragging) then return end
    holder:StopMovingOrSizing()
    dragging = false
    local right, top = Core.Plain(holder:GetRight()), Core.Plain(holder:GetTop())
    local screenRight, screenTop = Core.Plain(UIParent:GetRight()), Core.Plain(UIParent:GetTop())
    local scale = holder:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if ns.store and right and top and screenRight and screenTop and screenTop > 0 then
        ns.store.rareTracker = { right = math.floor(screenRight - right * scale + 0.5),
                                 top = math.floor(screenTop - top * scale + 0.5) }
    end
    Stack()
end

local function Loaded(model)
    model:SetAlpha(1)
end

local function Make()
    local notice = CreateFrame("Button", nil, UIParent)
    -- Over the quest log on the screen alone, which stands under the minimap too (its layer LOW, its items with it):
    -- a notice covers its top lines while it shows (Saneroki, 2026-11-18: "make sure it draws over the Questlog").
    notice:SetFrameStrata("HIGH")
    notice:SetSize(RareTracker.WIDTH, RareTracker.HEIGHT)
    -- In sight while a talk fades the interface out (Lore)
    if notice.SetIgnoreParentAlpha then notice:SetIgnoreParentAlpha(true) end
    notice:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    notice:RegisterForDrag("LeftButton")
    local middle, left, right = Shade(notice, RareTracker.DARK, RareTracker.DARK), Shade(notice, 0, RareTracker.DARK),
        Shade(notice, RareTracker.DARK, 0)
    middle:SetAllPoints(notice)
    left:SetPoint("TOPRIGHT", notice, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", notice, "BOTTOMLEFT", 0, 0)
    left:SetWidth(RareTracker.EDGE)
    right:SetPoint("TOPLEFT", notice, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMLEFT", notice, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(RareTracker.EDGE)
    local made, model = pcall(CreateFrame, "PlayerModel", nil, notice)
    if made and model then
        notice.model = model
        model:SetSize(RareTracker.PICTURE, RareTracker.PICTURE)
        model:SetPoint("LEFT", notice, "LEFT", 0, 0)
        pcall(model.SetScript, model, "OnModelLoaded", ns.Guard(Loaded))
    end
    notice.icon = notice:CreateTexture(nil, "ARTWORK")
    notice.icon:SetSize(RareTracker.ICON, RareTracker.ICON)
    notice.icon:SetPoint("CENTER", notice, "LEFT", RareTracker.PICTURE / 2, 0)
    local at = RareTracker.PICTURE + RareTracker.PAD
    notice.name = Words(notice, RareTracker.NAME)
    notice.name:SetPoint("TOPLEFT", notice, "TOPLEFT", at, -RareTracker.PAD - 2)
    notice.name:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    notice.what = Words(notice, RareTracker.LINE)
    notice.what:SetPoint("TOPLEFT", notice.name, "BOTTOMLEFT", 0, -4)
    notice.what:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.where = Words(notice, RareTracker.LINE)
    notice.where:SetPoint("TOPLEFT", notice.what, "BOTTOMLEFT", 0, -3)
    notice.where:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.where:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
    notice.fade = Core.Motion.Fade(notice)
    notice:SetScript("OnClick", ns.Guard(Clicked))
    notice:SetScript("OnDoubleClick", ns.Guard(Doubled))
    notice:SetScript("OnDragStart", ns.Guard(Dragged))
    notice:SetScript("OnDragStop", ns.Guard(Dropped))
    notice:SetScript("OnEnter", ns.Guard(Entered))
    notice:SetScript("OnLeave", ns.Guard(Left))
    notice:Hide()
    return notice
end

-- The notices' place: where they were let go, else at the screen's right edge under the minimap (Window.Under: the
-- small map's window, measured while it is small; the game's minimap where it is chosen), the shade's fading edge
-- ending at the screen's. How far below the screen's top it is.
local function Place()
    local saved = ns.store and ns.store.rareTracker
    local right, top
    if type(saved) == "table" and tonumber(saved.right) and tonumber(saved.top) then
        right, top = tonumber(saved.right), tonumber(saved.top)
    else
        right, top = RareTracker.EDGE, ns.Window.Under() + RareTracker.BELOW
    end
    holder:ClearAllPoints()
    holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -right, -top)
    return top
end

local function Holder()
    if holder then return holder end
    holder = CreateFrame("Frame", nil, UIParent)
    RareTracker.holder = holder
    holder:SetSize(RareTracker.WIDTH, RareTracker.HEIGHT)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder:SetClampRectInsets(-RareTracker.EDGE, RareTracker.EDGE, 0, 0) -- the shade's fading edges on the screen too
    holder:SetScript("OnUpdate", ns.Guard(Look))
    holder:Hide()
    return holder
end

-- The notices at their place, the newest nearest it, the others under it (over it in the screen's lower half).
function Stack()
    if not holder then return end
    local top
    if not dragging then top = Place() end -- (while dragged, where it is)
    local height = Core.Plain(UIParent:GetHeight())
    local up = top and type(height) == "number" and top > height / 2
    if top then holder.up = up else up = holder.up end
    local step = RareTracker.HEIGHT + RareTracker.GAP
    for index, notice in ipairs(shown) do
        notice:ClearAllPoints()
        if up then
            notice:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, (index - 1) * step)
        else
            notice:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -(index - 1) * step)
        end
    end
end

-- A notice let go: out of sight, its tooltip with it, free for the next find.
function Let(notice)
    for index, each in ipairs(shown) do
        if each == notice then
            table.remove(shown, index)
            break
        end
    end
    if GameTooltip:GetOwner() == notice then Left() end
    notice:Hide()
    notice.pin, notice.find = nil, nil
    spare[#spare + 1] = notice
    Stack()
    if #shown == 0 and holder then
        if dragging then Dropped() end -- (the last one gone while dragged: let go where it is)
        holder:Hide()
    end
end

-- Every RareTracker.LOOK seconds while one shows: where each is now and how far; one that is over fades out and goes.
function Look(_, elapsed)
    since = since + (elapsed or 0)
    if since < RareTracker.LOOK then return end
    since = 0
    local now = GetTime()
    for index = #shown, 1, -1 do
        local notice = shown[index]
        if notice.gone then
            if now >= notice.gone then Let(notice) end
        else
            Follow(notice)
            if Over(notice.find) then
                notice.gone = now + RareTracker.FADE_OUT
                notice.fade:To(0, RareTracker.FADE_OUT)
            else
                notice.where:SetText(Where(notice.find))
            end
        end
    end
end

-- The notice's picture: the rare's own model, else its mark's icon (a rare's skull without a model).
local function Picture(notice, find)
    local npc = find.kind == "rare" and Creature(find.thing)
    local model = notice.model
    if model then
        pcall(model.ClearModel, model)
        model:SetAlpha(0)
        model:Hide()
    end
    notice.icon:SetAtlas(find.atlas or (find.kind == "rare" and ns.Pins.ICONS.rare)
        or (find.kind == "book" and RareTracker.BOOK) or ns.Pins.ICONS.treasure)
    notice.icon:Show()
    if not (npc and model and pcall(model.SetCreature, model, npc)) then return end
    pcall(model.SetPortraitZoom, model, 1)
    notice.icon:Hide()
    model:Show()
    local file = Core.Ask(model.GetModelFileID, model)
    if type(file) == "number" and file > 0 then model:SetAlpha(1) end -- the game had it already
end

local function Sound()
    local kit = RareTracker.SOUNDS[ns.options and ns.options.rareSound or "horn"]
    if kit then Core.Ask(PlaySound, kit, "Master") end
end
RareTracker.Sound = Sound

-- The facts Core's data has of a rare where the game told none: its name, its level, whether it is an elite.
local function Known(find)
    local npc = Creature(find.thing)
    if not npc then return end
    find.name = find.name or NPCS:Get(npc, "name")
    find.level = find.level or tonumber(NPCS:Get(npc, "levelMax") or NPCS:Get(npc, "levelMin"))
    if find.elite == nil then find.elite = NPCS:Get(npc, "rank") == "rareelite" end
end

-- A thing seen again while its notice shows: that notice keeps it, with what was not known yet (its mark, its place).
local function Again(notice, find)
    local had = notice.find
    had.vignette, had.guid = had.vignette or find.vignette, had.guid or find.guid
    if find.x and find.y and (find.vignette or not had.vignette) then
        had.map, had.x, had.y = find.map, find.x, find.y
        notice.pin.map, notice.pin.x, notice.pin.y = find.map, find.x, find.y
    end
end

function RareTracker.Found(find, test)
    if not (find and find.thing and find.kind) then return false end
    local old
    for _, each in ipairs(shown) do
        if each.find and each.find.thing == find.thing and not each.gone then old = each break end
    end
    if old and not test then
        Again(old, find)
        return false
    end
    if not test and not (Wanted(find.kind) and Fresh(find.thing)) then return false end
    seen[find.thing] = GetTime()
    Known(find)
    if old then Let(old) end -- the test's: anew
    if #shown >= RareTracker.MOST then Let(shown[#shown]) end
    local notice = table.remove(spare) or Make()
    notice.find = find
    -- Its pin, for its tooltip and the map pin: as the map has it (an event a place)
    notice.pin = { kind = find.kind == "event" and "place" or find.kind, key = find.thing, name = find.name or "?",
                   map = find.map, x = find.x, y = find.y, live = true }
    notice.name:SetText(find.name or "?")
    notice.what:SetText(What(find))
    local colour = find.kind == "rare" and SILVER or find.kind == "treasure" and GOLD or find.kind == "book" and BLUE or LIGHT
    notice.what:SetTextColor(colour[1], colour[2], colour[3])
    notice.where:SetText(Where(find))
    Picture(notice, find)
    table.insert(shown, 1, notice)
    Holder()
    Stack()
    notice.gone = nil
    notice:Show()
    notice.fade:To(1, RareTracker.FADE_IN, 0)
    holder:Show()
    Sound()
    return true
end

function RareTracker.Hide()
    for index = #shown, 1, -1 do Let(shown[index]) end
end

-------------------------------------------------------------------------------
--  What the game shows
-------------------------------------------------------------------------------
-- One of the game's marks: told when it is on the minimap (near you) and not dead.
local function Vignette(guid)
    local info = Core.Ask(C_VignetteInfo.GetVignetteInfo, guid)
    if type(info) ~= "table" or Core.Plain(info.onMinimap) ~= true or Core.Plain(info.isDead) == true then return end
    marked[guid] = true
    local atlas = Core.Plain(info.atlasName)
    local kind = RareTracker.Kind(atlas)
    local id = Core.Plain(info.vignetteID)
    local creature = Core.Plain(info.objectGUID)
    local thing = Thing(creature) or ("vignette:" .. tostring(id or guid))
    if not Wanted(kind) then return end
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local position = map and Core.Ask(C_VignetteInfo.GetVignettePosition, guid, map)
    local x, y = type(position) == "table" and Core.Plain(position.x), type(position) == "table" and Core.Plain(position.y)
    RareTracker.Found({ kind = kind, thing = thing, name = Core.Plain(info.name), atlas = atlas, vignette = guid,
                        guid = type(creature) == "string" and creature or nil,
                        elite = type(atlas) == "string" and atlas:find("Elite", 1, true) ~= nil or nil,
                        map = map, x = x or nil, y = y or nil })
end

local function Vignettes()
    local list = Core.Ask(C_VignetteInfo.GetVignettes)
    for _, guid in ipairs(type(list) == "table" and list or {}) do
        if not marked[guid] then Vignette(guid) end
    end
end

-- A creature the game shows you: told when it is a rare, alive and no player's.
local function Unit(unit)
    local rank = Core.Ask(rawget(_G, "UnitClassification"), unit)
    if rank ~= "rare" and rank ~= "rareelite" then return end
    if Core.Ask(UnitExists, unit) ~= true or Core.Ask(UnitIsPlayer, unit) == true or Core.Ask(UnitIsDead, unit) == true then
        return
    end
    local guid = Core.Ask(UnitGUID, unit)
    local thing = Thing(guid)
    if not (thing and Wanted("rare")) then return end
    -- Where it stands: the nearest point of Core's data, else where you see it from (a nameplate's reach)
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local x, y
    if map then x, y = Nearest(thing, map) end
    if map and not x then
        local here = Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
        if type(here) == "table" then x, y = Core.Plain(here.x), Core.Plain(here.y) end
    end
    local level = Core.Ask(UnitLevel, unit)
    RareTracker.Found({ kind = "rare", thing = thing, name = Core.Ask(UnitName, unit), elite = rank == "rareelite", guid = guid,
                        level = type(level) == "number" and level > 0 and level or nil, map = map, x = x, y = y })
end

-- Where the player stands: their map and the point on it; nil where the game tells none.
local function Here()
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local here = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local x, y = type(here) == "table" and Core.Plain(here.x), type(here) == "table" and Core.Plain(here.y)
    if not (x and y) then return map end
    return map, x, y
end

-- What the interact key picks near you (its soft target): a chest, or a book this character still needs, by what Core's
-- Objects says the object is. It stands within the key's reach: at your place.
local function Soft()
    local guid = Core.Ask(UnitGUID, "softinteract")
    local thing = Thing(guid)
    local id = thing and tonumber(thing:match("^object:(%d+)$"))
    local kind = id and OBJECTS:Get(id, "kind")
    local tell = kind == "chest" and "treasure" or kind == "book" and "book" or nil
    if not (tell and Wanted(tell)) then return end
    local item, quests, only
    if tell == "book" then
        item, quests, only = Book(id)
        if not Needed(item, quests, only) then return end
    end
    local map, x, y = Here()
    RareTracker.Found({ kind = tell, thing = thing, guid = guid, map = map, x = x, y = y, item = item, quests = quests,
                        only = only, atlas = tell == "book" and RareTracker.BOOK or nil,
                        name = BookName(item) or Core.Ask(UnitName, "softinteract") or OBJECTS:Get(id, "name") })
end

-- The books on a map (Core's places of the kind book): kept until the map or the places change.
local function BooksOn(map)
    if books.map == map and books.list then return books.list end
    local data = Core.Data.Map and Core.Data.Map()
    local places = data and Core.Ask(data.On, data, map)
    if type(places) ~= "table" then return {} end -- (being read: asked again at the next look)
    local list = {}
    for _, place in ipairs(places) do
        if place.kind == "object" and place.what == "book" and place.x and place.y then list[#list + 1] = place end
    end
    books.map, books.list = map, list
    return list
end

-- Every RareTracker.SCAN seconds: a book on your map within RareTracker.BOOK_REACH yards, told while you still need it;
-- one you do not, looked at again only after RareTracker.AGAIN seconds.
local function Scan()
    if not Wanted("book") then return end
    local map, x, y = Here()
    local box = map and Coords.Box(map)
    if not (box and x) then return end
    for _, place in ipairs(BooksOn(map)) do
        local yards = math.sqrt(((place.x - x) * box.width) ^ 2 + ((place.y - y) * box.height) ^ 2)
        if yards <= RareTracker.BOOK_REACH and Fresh(place.key) then
            local item, quests, only = Book(place.id)
            if Needed(item, quests, only) then
                RareTracker.Found({ kind = "book", thing = place.key, name = BookName(item) or place.name, map = map,
                                    x = place.x, y = place.y, item = item, quests = quests, only = only,
                                    atlas = RareTracker.BOOK })
            else
                seen[place.key] = GetTime()
            end
        end
    end
end
RareTracker.Scan = Scan

-- Core's places changed: the books on the map read anew at the next look.
function RareTracker.Reread()
    books.list = nil
end

-- A loot window: each thing it came from (a chest, a book, a corpse) is taken, and its notice goes.
local function Looted()
    local count = Core.Ask(rawget(_G, "GetNumLootItems")) or 0
    local sources = rawget(_G, "GetLootSourceInfo")
    if type(sources) ~= "function" then return end
    for slot = 1, count do
        local answer = { pcall(sources, slot) }
        if answer[1] then
            for index = 2, #answer, 2 do
                local guid = Core.Plain(answer[index])
                if type(guid) == "string" then taken[guid] = true end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  The test
-------------------------------------------------------------------------------
-- A point so many yards north-east of the player on their map; nil where the game tells no place.
local function Ahead(map, yards)
    local box = map and Coords.Box(map)
    local here = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local x, y = here and Core.Plain(here.x), here and Core.Plain(here.y)
    if not (box and x and y) then return nil end
    local step = yards / math.sqrt(2)
    return math.min(math.max(x + step / box.width, 0), 1), math.min(math.max(y - step / box.height, 0), 1)
end

-- The nearest thing of Core's data on the map of a kind (a rare, a chest), with its place; nil for none.
local function NearestOf(map, want)
    local data = Core.Data.Map and Core.Data.Map()
    local places = data and map and Core.Ask(data.On, data, map)
    local here = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local px, py = here and Core.Plain(here.x), here and Core.Plain(here.y)
    if type(places) ~= "table" or not (px and py) then return nil end
    local best, found = math.huge, nil
    for _, place in ipairs(places) do
        if want(place) and place.x and place.y then
            local far = (place.x - px) ^ 2 + (place.y - py) ^ 2
            if far < best then best, found = far, place end
        end
    end
    return found
end

function RareTracker.Test(rest)
    rest = type(rest) == "string" and rest:lower() or ""
    if rest == "reset" then
        if ns.store then ns.store.rareTracker = nil end
        Stack()
        return ns.Print(TEXT.reset)
    end
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local find
    if rest == "chest" or rest == "treasure" then
        local place = NearestOf(map, function(place) return place.kind == "object" and place.what == "chest" end)
        find = { kind = "treasure", atlas = "VignetteLoot", thing = place and place.key or "object:0",
                 name = place and place.name or TEXT.chest, map = map, x = place and place.x, y = place and place.y }
    elseif rest == "event" then
        find = { kind = "event", atlas = "VignetteEvent", thing = "vignette:test", name = TEXT.anEvent, map = map }
    elseif rest == "book" then
        local place = NearestOf(map, function(place) return place.kind == "object" and place.what == "book" end)
        local item = place and Book(place.id)
        find = { kind = "book", atlas = RareTracker.BOOK, thing = place and place.key or "object:0",
                 name = BookName(item) or place and place.name or TEXT.aBook, map = map, x = place and place.x,
                 y = place and place.y }
    else
        local place = NearestOf(map, function(place)
            return place.kind == "npc" and type(place.what) == "table" and place.what.rare
        end)
        if place then
            find = { kind = "rare", thing = place.key, name = place.name, map = map, x = place.x, y = place.y }
        else
            find = { kind = "rare", thing = SAMPLE.thing, name = SAMPLE.name, level = SAMPLE.level, elite = SAMPLE.elite,
                     map = map }
        end
    end
    if find.map and not find.x then find.x, find.y = Ahead(find.map, RareTracker.AHEAD) end
    RareTracker.Found(find, true)
end

Core.Command("testraretracker", TEXT.about, function(rest)
    if ns.off then return ns.Print(ns.TEXT.stopped) end
    ns.Guarded(RareTracker.Test, rest)
end)

function RareTracker.Start()
    if rawget(_G, "C_VignetteInfo") then
        ns.On("VIGNETTE_MINIMAP_UPDATED", ns.Guard(function(guid, onMinimap)
            if onMinimap and guid and not marked[guid] then Vignette(guid) end
        end))
        ns.On("VIGNETTES_UPDATED", ns.Guard(Vignettes))
    end
    ns.On("NAME_PLATE_UNIT_ADDED", ns.Guard(Unit))
    ns.On("PLAYER_TARGET_CHANGED", ns.Guard(function() Unit("target") end))
    ns.On("UPDATE_MOUSEOVER_UNIT", ns.Guard(function() Unit("mouseover") end))
    ns.On("PLAYER_SOFT_INTERACT_CHANGED", ns.Guard(Soft))
    ns.On("LOOT_OPENED", ns.Guard(Looted))
    -- A new place (a loading screen): the marks there looked at anew
    ns.On("PLAYER_ENTERING_WORLD", ns.Guard(function() wipe(marked) end))
    -- The books near you, looked for in turn; their list anew when Core's places change
    local data = Core.Data.Map and Core.Data.Map()
    if data and data.OnChange then data:OnChange(ns.Guard(RareTracker.Reread)) end
    if rawget(_G, "C_Timer") and C_Timer.NewTicker then C_Timer.NewTicker(RareTracker.SCAN, ns.Guard(Scan)) end
end
