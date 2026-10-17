local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips
--  The module's own table (ns in all its files), its switches, and when a
--  tooltip is drawn.
--
--  An addon of its own (SaneUI_Tooltips): it needs Core and nothing else, and
--  is switched on and off in the game's addon list.
--
--  The idea in one line: when the game has filled a tooltip from data (an
--  item, a spell, a unit, ...), its lines are read and sorted (Read.lua and the
--  files in Kinds, into a model: Model.lua), drawn anew on a panel of our own
--  (Panel.lua, with Live.lua for what changes while it is shown), and the game's
--  tooltip is kept out of sight behind that panel (Host.lua). The game goes on running its tooltip,
--  placing, filling and hiding it as always, and the panel follows.
--
--  A tooltip somebody only wrote lines into (a button's name, a hint) gets a
--  panel too: its name and its lines. Left to the game is only a tooltip the
--  panel could not show in full (one with a bar or a frame inside, or with a
--  line the game hides in a fight), one nobody sees (another addon's, to read
--  things with), every tooltip of a kind whose reader failed (Read.lua), and
--  every tooltip once anything else here fails (Core's StandDown, GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Tooltips", ns)
local Plain = Core.Plain
local Guarded = ns.Guarded -- runs a step; its error stands the module down (Core)

-- Settings saved by an older version, put right before Core.Options checks them against their
-- defaults. 2: the background was 90 percent solid at first; it is 97 now, and 90 is taken for the
-- old default, not for a choice. 3: the mouse switch, on or off, is one of a few now (always, or
-- while a key is held); tooltips were shown only while Shift was held at first, for a day: Always
-- is that default now.
do
    local ok, store = pcall(Core.Store, ns.name)
    local saved = ok and type(store.options) == "table" and store.options
    if saved and (store.version or 1) < 2 then
        if saved.opacity == 90 then saved.opacity = 97 end
        saved.border = nil -- a setting that is gone
    end
    if saved and (store.version or 1) < 3 then
        if type(saved.cursor) == "boolean" then saved.cursor = saved.cursor and "always" or "default" end
        if saved.show == "shift" then saved.show = "always" end
    end
    if ok then store.version = 3 end
end

-- The keys the two options below can wait for
local KEYS = { { "shift", "While Shift is held" }, { "ctrl", "While Ctrl is held" }, { "alt", "While Alt is held" } }
Core.Options(ns.name, {
    { key = "show", default = "always", text = "Show tooltips",
      choices = { { "always", "Always" }, KEYS[1], KEYS[2], KEYS[3], { "shiftalt", "While Shift and Alt are held" } },
      tip = "Always: tooltips show at once, as the game's do. Or they stay hidden until you hold a key down, and hide again when you let go." },
    { key = "cursor", default = "default", text = "Tooltips at the mouse cursor",
      choices = { { "default", "Default: where the game puts them" }, KEYS[1], KEYS[2], KEYS[3], { "always", "Always" } },
      tip = "The tooltips that stand in the corner of the screen (of creatures, players and things in the world, and of your action bars) follow the mouse instead: always, or while a key is held. Pressing or letting go of the key moves a shown tooltip at once." },
    { key = "classColors", default = true, text = "Colour players by their class",
      tip = "Switched off, a player's tooltip takes the colour the game gives the name." },
    { key = "icons", default = true, text = "Show the icon of items and spells" },
    { key = "models", default = true, text = "3D model in tooltips",
      tip = "Where a tooltip's thing has a 3D model, it stands in the picture's place: a creature or player, moving; a mount or a pet; a piece of gear, worn by your own character. Switched off, or where the game cannot load the model, it is the picture: the portrait or the item's icon." },
    { key = "textSize", default = 14, min = 10, max = 20, step = 1, text = "Text size",
      tip = "How large a tooltip's name and lines are written. The smaller texts follow." },
    { key = "opacity", default = 97, min = 30, max = 100, step = 1, text = "Opacity",
      tip = "How solid a tooltip's background is, in percent. Its texts and pictures stay as they are." },
}, function()
    -- A switch was flipped: what the panels show is no longer what they would show.
    for _, panel in pairs(ns.Panel.All()) do panel.drawn = false end
end)

local adopted = {} -- [tooltip] = true: hooked; false: not one we can draw
-- The game's tooltips that are also written into by hand (a hint), hooked at login. Those filled
-- from data are hooked when they are first filled, whichever they are.
local SHOWN_PLAIN = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2", "GameNoHeaderTooltip", "GameSmallHeaderTooltip", "BuffFrameTooltip", "AuraButtonTooltip" }
-- What each of the module's other files leaves in its table: all there, or the module is not whole.
local PARTS = { "TEXT", "Model", "Reader", "Live", "Inspect", "Numbers", "Quests", "Auction", "Figures", "Gold",
    "Inventory", "KINDS", "Pools", "Panel", "Host" }

-- Whether the player sees the tooltip: it is visible, and placed somewhere. Other addons read what
-- the game says of a thing with tooltips of their own that nobody sees: owned, but placed nowhere
-- (ANCHOR_NONE, and no point). Those are left alone.
local function OnScreen(tooltip)
    if not (tooltip:IsVisible() and tooltip:GetOwner()) then return false end
    return Plain(tooltip:GetAnchorType()) ~= "ANCHOR_NONE" or (Plain(tooltip:GetNumPoints()) or 0) > 0
end

-- Whether an option's choice holds now: always, never (default), or while its key is held.
local HELD = {
    shift = function() return IsShiftKeyDown() end,
    ctrl = function() return IsControlKeyDown() end,
    alt = function() return IsAltKeyDown() end,
    shiftalt = function() return IsShiftKeyDown() and IsAltKeyDown() end,
}
local function Holds(choice)
    if choice == "always" then return true end
    local held = HELD[choice]
    return held ~= nil and Plain(held()) == true
end

-- Whether tooltips may be seen now: always, or while the chosen key is held (the option show).
-- A tooltip that may not is there all the same, filled and placed by the game, its panel drawn;
-- only it and its panel are see-through, until the key is pressed (Gate).
function ns.Allowed()
    return Holds(ns.options and ns.options.show or "always")
end

-- What a tooltip can hold that a panel cannot show: another tooltip inside it, bars, frames
-- somebody put in, coins other than an item's price.
local function HoldsMore(tooltip, model)
    if tooltip.IsEmbedded then return true end
    local inner = tooltip.ItemTooltip
    if inner and inner:IsShown() then return true end
    local inserted = tooltip.insertedFrames
    if inserted and #inserted > 0 then return true end
    local bars = tooltip.statusBarPool
    if bars and bars:GetNumActive() > 0 then return true end
    return (tooltip.shownMoneyFrames or 0) > (model.priced and 1 or 0)
end

local Watching, Gate -- below: a panel's OnUpdate; whether the tooltips are seen

-- The tooltip's panel, made when it is first needed (not at login: most tooltips never are). The
-- panel only works while it is shown: an OnUpdate of its own, and none while hidden.
local function PanelOf(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if panel then return panel end
    panel = ns.Panel.Of(tooltip)
    panel:SetScript("OnUpdate", Watching)
    return panel
end

-- data: what the game filled the tooltip from; false: lines somebody wrote into it (a hint).
local function Draw(tooltip, data)
    local plain = data == false
    if plain then
        data = nil
    else
        -- The game may add further data to a filled tooltip (a recipe's item, a comparison's
        -- differences) and tells us with that data alone. What the tooltip is about, and where
        -- its price stands, is in the data it was first filled from.
        data = tooltip.GetPrimaryTooltipData and Plain(tooltip:GetPrimaryTooltipData()) or data
    end
    local panel = PanelOf(tooltip)
    panel.data, panel.stale = plain and false or data, false
    local model = panel.model
    local ok, changed = ns.Read(tooltip, data, model, ns.options)
    -- What the panel shows is only good as long as every change of its model was drawn.
    if changed or not ok then panel.drawn = false end
    if not ok or HoldsMore(tooltip, model) then
        ns.Host.Free(tooltip, panel)
        if not ns.Allowed() then tooltip:SetAlpha(0) end -- the game's, but not to be seen yet
        return
    end
    -- How many lines the tooltip had when it was read: a different count later means somebody
    -- wrote more into it (Watch).
    panel.linesRead = Plain(tooltip:NumLines())
    if panel.drawn then
        panel:Show() -- the same lines as before (the game fills a shown tooltip again and again)
    elseif ns.Panel.Draw(panel) then
        panel.drawn = true
    else
        ns.Host.Free(tooltip, panel) -- a size the game hid (Pools.lua): the game's, this time
        if not ns.Allowed() then tooltip:SetAlpha(0) end
        return
    end
    ns.Host.Seat(tooltip, panel)
end

-- New lines are coming. If the game fills the tooltip from data again, the panel is drawn anew;
-- if not, Watch gives the tooltip back on the next frame.
local function Cleared(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if panel then panel.stale = true end
end

local function Hidden(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if not panel then return end
    panel.hiddenAt = GetTime()
    ns.Host.Free(tooltip, panel)
end

local Filled -- below

-- The tooltip was made visible, its alpha whole again. (A hidden one brought back by Show or
-- SetShown runs this twice, after OnShow and after the function; the second time the panel waits
-- to be drawn and only the tooltip's alpha is set again.)
local function Reshown(tooltip)
    local panel = PanelOf(tooltip)
    if panel.pending then
        ns.Host.Keep(tooltip) -- filled and not drawn yet: it must not show through
    elseif panel.stale or not panel:IsShown() then
        -- Shown with lines nobody told us about (somebody wrote them in: a button's hint), or
        -- shown again: drawn at the end of the frame too.
        Filled(tooltip, (not panel.stale and panel.data) or false)
    else
        ns.Host.Seat(tooltip, panel)
    end
end

-- The game has filled a tooltip (from data, or false: somebody wrote lines into it). It is not
-- drawn at once but at the end of the frame (Settle): what fills a tooltip often goes on writing
-- into it. A comparison gets the lines
-- that say what would change after the game told us, several times a second; drawn at once,
-- its panel would be laid out short and then long again every time.
local queue, driver = {}, nil -- the tooltips that wait, and the frame whose OnUpdate draws them

function Filled(tooltip, data)
    local panel = PanelOf(tooltip)
    panel.data, panel.stale = data, false
    if panel.drawn and not panel:IsShown() and panel.hiddenAt == GetTime() then
        -- Hidden and filled again in one go, as the game does to refresh: the old picture stays,
        -- where it stood, until the new one is drawn, so nothing blinks or jumps (Host.Hold).
        panel:Show()
        ns.Host.Hold(tooltip, panel)
    elseif OnScreen(tooltip) then
        ns.Host.Blank(tooltip, panel)
    else
        -- One nobody sees (another addon's that reads what the game says) is not blanked piece by
        -- piece on every fill: Settle gives it back, or the draw blanks its pieces.
        ns.Host.Dim(tooltip, panel)
    end
    if panel.pending then return end
    panel.pending = true
    queue[#queue + 1] = tooltip
    driver:Show()
end

local function Settle(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if not panel.pending then return end
    panel.pending = false
    if OnScreen(tooltip) then
        Draw(tooltip, panel.data)
    else
        ns.Host.Free(tooltip, panel)
    end
end

-- The mouse has left what the tooltip was about (a unit or a thing in the world, a unit frame),
-- and the game lets the tooltip fade out, slowly. Its panel is gone at once, and a draw that
-- waited is not wanted any more. The game's tooltip is left to fade and hide as the game does
-- (hidden from here, it would be tainted); it is not seen meanwhile: its pieces keep the alpha 0
-- Host.Blank gave them, until it hides and Host.Free sets them back.
local function Faded(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if not panel then return end
    panel.pending = false
    panel:Hide()
end

local function OnShown(tooltip) Guarded(Reshown, tooltip) end
local function OnFaded(tooltip) Guarded(Faded, tooltip) end
local function OnSetShown(tooltip, shown)
    if shown then Guarded(Reshown, tooltip) end
end
local function OnHidden(tooltip) Guarded(Hidden, tooltip) end
local function OnCleared(tooltip) Guarded(Cleared, tooltip) end

-- Once a frame while a panel is shown (see Watching).
local function Watch(tooltip)
    local panel = ns.Panel.All()[tooltip]
    if panel.pending then return end      -- Settle draws it this frame
    if not OnScreen(tooltip) then
        ns.Host.Free(tooltip, panel) -- gone with what it stands on, or placed nowhere now
    elseif panel.stale then
        -- Cleared, and the game told us of nothing new: what it shows now was written in by hand.
        if tooltip:IsShown() and (Plain(tooltip:NumLines()) or 0) > 0 then
            Filled(tooltip, false)
        else
            ns.Host.Free(tooltip, panel)
        end
    elseif Plain(tooltip:NumLines()) ~= panel.linesRead then
        Draw(tooltip, panel.data)         -- another addon added its lines after us
    else
        ns.Host.Keep(tooltip)
        ns.Host.Track(tooltip, panel) -- its comparisons follow it, once it has moved (Host.lua)
        -- A unit's numbers are kept up to date; if it has got or lost a row (a target, its
        -- buffs), the tooltip is read anew.
        if ns.Live.Update(panel, panel.elapsed or 0) then Draw(tooltip, panel.data) end
    end
end

function Watching(panel, elapsed)
    panel.elapsed = elapsed
    Guarded(Watch, panel.tooltip)
end

-- Hooks a tooltip, once. False for one that is not drawn anew.
local function Adopt(tooltip)
    local known = adopted[tooltip]
    if known ~= nil then return known end
    known = not tooltip:IsForbidden() and not tooltip.IsEmbedded
    adopted[tooltip] = known
    if not known then return false end
    tooltip:HookScript("OnTooltipCleared", OnCleared)
    tooltip:HookScript("OnHide", OnHidden)
    tooltip:HookScript("OnShow", OnShown)
    -- Filled anew while already shown, a tooltip runs no OnShow; its Show is what follows the new lines.
    hooksecurefunc(tooltip, "Show", OnShown)
    -- TooltipComparisonManager brings its tooltips back with SetShown(true), not with Show: a
    -- hook of its own, so those come back out of sight too.
    hooksecurefunc(tooltip, "SetShown", OnSetShown)
    if type(tooltip.FadeOut) == "function" then hooksecurefunc(tooltip, "FadeOut", OnFaded) end
    return true
end

local function OnFilled(tooltip, data)
    if Adopt(tooltip) then Filled(tooltip, data) end
end

-- Each shown tooltip seen or not, as the option show says now: its panel, or the game's tooltip
-- where it has none (one the panel could not show).
function Gate()
    local allowed = ns.Allowed()
    for tooltip, panel in pairs(ns.Panel.All()) do
        if panel:IsShown() then
            ns.Panel.Strength(panel, allowed)
        elseif tooltip:IsShown() and not panel.pending then
            tooltip:SetAlpha(allowed and 1 or 0)
        end
    end
end

-- Something failed (a step run by Guarded): Core's StandDown sets ns.off, calls this and tells it
-- once. The tooltips are the game's own again, until the next /reload. Each is given back by
-- itself, so one that fails keeps none of the others.
ns.GIVEN_BACK = "the game's own tooltips are back"
function ns.GiveBack()
    if not (ns.Panel and ns.Host) then return end
    for tooltip, panel in pairs(ns.Panel.All()) do pcall(ns.Host.Free, tooltip, panel) end
end

-- The option for the mouse (cursor). The game puts a tooltip without a place of its own into the
-- screen's corner with GameTooltip_SetDefaultAnchor; the game's own "at the cursor" anchor replaces
-- that, always or while the chosen key is held, and the game moves the tooltip itself. Where the
-- game put it is noted, so that a key pressed or let go while it is shown can move it to the mouse
-- and back (Follow; SetAnchorType keeps its lines, SetOwner would clear them).
local CURSOR = "ANCHOR_CURSOR_RIGHT"
local placed = {} -- [tooltip] = { the point the game gave it (5 values), parent = , moved = }
local function AtCursor()
    return Holds(ns.options.cursor)
end

local function ToCursor(tooltip, parent)
    if not parent or tooltip:IsForbidden() then return end
    local spot = placed[tooltip] or {}
    placed[tooltip] = spot
    spot.parent, spot.moved = parent, false
    spot[1], spot[2], spot[3], spot[4], spot[5] = tooltip:GetPoint(1)
    if AtCursor() then
        tooltip:SetOwner(parent, CURSOR)
        spot.moved = true
    end
end

local function Follow()
    local cursor = AtCursor()
    for tooltip, spot in pairs(placed) do
        if tooltip:IsShown() and tooltip.SetAnchorType and tooltip:GetOwner() == spot.parent then
            local anchor = Plain(tooltip:GetAnchorType())
            if cursor and not spot.moved and anchor == "ANCHOR_NONE" then
                tooltip:SetAnchorType(CURSOR)
                spot.moved = true
            elseif not cursor and spot.moved and anchor == CURSOR and spot[1] then
                tooltip:SetAnchorType("ANCHOR_NONE")
                tooltip:ClearAllPoints()
                tooltip:SetPoint(spot[1], spot[2], spot[3], spot[4], spot[5])
                spot.moved = false
            else
                spot = nil
            end
            -- Its panel follows it
            local panel = spot and ns.Panel and ns.Panel.All()[tooltip]
            if panel and panel:IsShown() then
                panel.corner = nil
                ns.Host.Seat(tooltip, panel)
            end
        end
    end
end

-- The tooltip a chat link opens (ItemRefTooltip) stays until it is closed. It opens in the middle
-- of the screen, and a click anywhere on it closes it; its panel has no X (Host.lua gives the
-- tooltip the panel's area for the mouse and takes the game's X off it). It can still be dragged,
-- as in the game: a press that dragged it closes nothing. The game's X closes it with HideUIPanel,
-- which for this tooltip (no place among the game's windows) is Hide; HideUIPanel from an addon is
-- refused in a fight, so Hide. In ns.Safe, like the mouse switch: this is done to the game's
-- tooltip, whether or not the panels work.
local PINNED = "the chat link's tooltip"
local function Center(tooltip)
    tooltip:ClearAllPoints()
    tooltip:SetPoint("CENTER", UIParent, "CENTER")
end

local function Pin(tooltip)
    local pressed, dragged = false, false
    tooltip:HookScript("OnShow", function(self) ns.Safe(PINNED, Center, self) end)
    tooltip:HookScript("OnMouseDown", function() pressed, dragged = true, false end)
    tooltip:HookScript("OnDragStart", function() dragged = true end)
    tooltip:HookScript("OnMouseUp", function(self)
        local click = pressed and not dragged
        pressed = false
        if click then ns.Safe(PINNED, self.Hide, self) end
    end)
end

function ns.OnLoad()
    local store = Core.Store(ns.name)
    ns.options = store.options
    ns.store = store
    -- The mouse switch of version 2, still on or off in a profile or a character's own settings.
    for _, copy in ipairs(Core.Profiles and Core.Profiles.Copies(ns.name) or {}) do
        if type(copy.cursor) == "boolean" then copy.cursor = copy.cursor and "always" or "default" end
    end
end

function ns.OnLogin()
    -- The switch for the mouse works whether or not the panels do: Safe, not Guarded. An error in
    -- it is noted and told once, and stands nothing down.
    if GameTooltip_SetDefaultAnchor then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            ns.Safe("the mouse switch", ToCursor, tooltip, parent)
        end)
        Core.On("MODIFIER_STATE_CHANGED", function()
            ns.Safe("the mouse switch", Follow)
        end)
    end
    local pinned = rawget(_G, "ItemRefTooltip")
    if pinned and pinned.HookScript and not pinned:IsForbidden() then ns.Safe(PINNED, Pin, pinned) end

    -- Are all of the module's files here? The game learns which files an addon has when it
    -- starts; a /reload reads the ones it knew anew, but not files that were added since. After
    -- an update with new files and only a /reload, half of the module would be missing and the
    -- first tooltip would fail. Say what to do instead, and leave the tooltips to the game.
    for _, part in ipairs(PARTS) do
        if not ns[part] then
            ns.off = true
            ns.Print("Tooltips was updated with new files. Please restart the game: a /reload does not read new files. Until then the tooltips are the game's own.")
            return
        end
    end

    local processor = TooltipDataProcessor
    if not (processor and processor.AddTooltipPostCall and processor.AllTypes and Enum.TooltipDataType) then
        ns.StandDown("this client fills its tooltips in a way the module does not know")
        return
    end
    driver = CreateFrame("Frame")
    driver:Hide() -- it only runs while a tooltip waits to be drawn
    driver:SetScript("OnUpdate", function()
        driver:Hide()
        for index = 1, #queue do
            local tooltip = queue[index]
            queue[index] = nil
            Guarded(Settle, tooltip)
        end
    end)
    ns.driver = driver
    processor.AddTooltipPostCall(processor.AllTypes, function(tooltip, data)
        Guarded(OnFilled, tooltip, data)
    end)
    -- The auction house's prices, noted as you browse it (Auction.lua)
    ns.Auction.Start(ns.store)
    -- Core's data the panels show: the shown ones are read anew when it comes or changes. What a
    -- creature's quest section says is kept until your quests, your level or the quest data change
    -- (Quests.lua; the data asked for now); an item's Inventory follows your characters' bags.
    local function Redraw()
        for tooltip, panel in pairs(ns.Panel.All()) do
            if panel:IsShown() and not panel.pending then Guarded(Draw, tooltip, panel.data) end
        end
    end
    ns.Quests.Start(Redraw)
    Core.Data.OnCharacters(Redraw)
    -- A player's item level has come (Inspect.lua): their panel is read anew.
    ns.Inspect.Start(function(guid)
        for tooltip, panel in pairs(ns.Panel.All()) do
            local unit = panel:IsShown() and panel.model.shown.head.unit
            if unit and Plain(UnitGUID(unit)) == guid then Guarded(Draw, tooltip, panel.data) end
        end
    end)
    -- A key pressed or let go: the shown tooltips are seen or not (the option show); with Alt, the
    -- shown panels are read anew, with or without their technical details.
    Core.On("MODIFIER_STATE_CHANGED", function(key)
        local alt = key == "LALT" or key == "RALT"
        for tooltip, panel in pairs(ns.Panel.All()) do
            if alt and panel:IsShown() and not panel.pending then Guarded(Draw, tooltip, panel.data) end
        end
        Guarded(Gate)
    end)
    -- The tooltips that also show lines somebody wrote in (a button's hint) are hooked at once
    -- (their panels are made when they are first shown); any other tooltip when the game first
    -- fills it from data.
    for _, name in ipairs(SHOWN_PLAIN) do
        local tooltip = rawget(_G, name)
        if tooltip then Guarded(Adopt, tooltip) end
    end
end
