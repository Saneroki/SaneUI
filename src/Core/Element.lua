local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Element
--  What every element of Sane UI on the screen has on its right click
--  (Saneroki, 2026-11-14): your unit frames, the group's, the minimap, the
--  quest log, the chat, the meter, the reminder bars, the guide and its arrow,
--  the loot feed and roll cards, the game's action bars. Under its name, four
--  lines:
--      Unlock to move     its box over it outside Edit Mode too, dragged by it
--                         until Lock (Window:Unlock; not kept: a /reload locks it)
--      Hide in combat     out of sight while you fight, the mouse on it too
--      Show on mouseover  out of sight but while the mouse is on it
--      Click-through      nothing of it takes the mouse: clicks, the mouse's
--                         coming and the wheel go on to what is under it
--  The three ticks are kept with its place, in the profile in use
--  (Window:Remember), and stand aside while it is unlocked, in Edit Mode and
--  while it fills the screen.
--
--  Out of sight is its alpha alone, by a set of Core.Rest: the module's own
--  where it has one (Rest.New with window: the unit frames, the quest log),
--  else one made for it on the window's frame. Hidden in a fight it takes no
--  mouse either: its frames go through from the fight's first moment
--  (PLAYER_REGEN_DISABLED, while the game still lets its protected frames be
--  changed) to its end. Where no door of its own hears the mouse (a set made
--  here, or clicks going through), the set looks for the mouse on its
--  rectangle now and then (Rest's Watch).
--
--  Click-through lends each frame of it but its box and grip (Core.Lend: its
--  clicks, its motion, its wheel off), given back exactly when the tick goes,
--  when it is unlocked or fills the screen. Frames it makes later are taken as
--  they come: when it shows, when its size changes, when a fight ends. In a
--  fight the game keeps protected frames as they are: those wait for its end.
--
--  Where its menu opens: a right click on its box (unlocked, or in Edit Mode)
--  and on its title bar; the game's own menu of a unit opened from one of its
--  secure unit buttons (Menu.ModifyMenu: the lines at the end); and where its
--  module puts it: its own right click (Element.RightClick, Element.Menu) or
--  its own menu (Element.Lines). A click-through one is reached by its box in
--  Edit Mode (or /sane arrange).
--
--  An element may also be frames that are no window of ours (Element.New: the
--  game's action bars, which its own Edit Mode places; Saneroki, 2026-11-14:
--  "on the actionbars only on the pager arrows and checkboxes"). It has no
--  Unlock then (its line says where it is moved, greyed); its ticks are kept in
--  the profile by its module and key as a window's are; the frames it spares
--  (spare: the pager arrows and checkboxes beside the bars) keep the mouse
--  while it is click-through, so its menu stays at hand there, but not in a
--  fight it hides in.
--
--      Core.Window.New(frame, { ..., element = true })  an element (New calls Element.Take)
--          element = { mouse = { get = fn, set = fn } }   a tick its module keeps itself: the line reads and writes
--                                                         that (the meter's own Show on mouseover), Core does nothing more
--      Core.Element.Lines(root, window)      its name and the four lines, in a menu of the module's own
--      Core.Element.Menu(owner, window)      a menu of those alone at owner
--      Core.Element.RightClick(frame, window)  a right click on frame (one that takes clicks) opens it
--      Core.Element.TitleBar(window)         its title bar's right click (Window.lua, once the bar is made)
--      Core.Element.Of(frame)                the element a frame is part of (it, or a frame it stands in), or nil
--      Core.Element.Is(window)               whether a window is an element
--      Core.Element.Get(window, what)        "fight", "mouse", "through": whether it is ticked
--      Core.Element.Set(window, what, on)    ticked or not, kept, and so at once
--      Core.Element.Sleep(window, on)        its module keeps it out of sight now, whatever is ticked (the minimap
--                                            while the game's own is chosen), its clicks its own
--      Core.Element.Join(window, set)        a set of Core.Rest of the module's own serves it (Rest.New's window)
--      Core.Element.Away(window, on)         it goes to fill the screen (Edge.lua): in sight and its clicks its
--                                            own until it is back (off)
--      Core.Element.Look(window)             as ticked, unlocked and its frames now
--      Core.Element.LookAll()                every element as the profile in use has it (Window.PlaceAll)
--      local element = Core.Element.New({ name = "Combat", key = "actionBars", title = "Action bars",
--                                         frames = { ... }, spare = function(frame) end })
--                                            frames of the game's as one element: kept under that module and key;
--                                            spare(frame): one whose part keeps the mouse while it is click-through
--                                            (its frames for Rest.New's window, Element.Away, Element.RightClick)
-------------------------------------------------------------------------------
local Element = {}
Core.Element = Element
local Plain = Core.Plain

Element.WHATS = { "fight", "mouse", "through" } -- the ticks, in the menu's order; each a key of its kept place
Element.TEXT = {
    unlock = "Unlock to move", lock = "Lock",
    unlockTip = "Its box lies over it: drag it where you want it, then Lock. Edit Mode moves every element too.",
    locked = "Not in a fight: it holds the game's protected frames.",
    fight = "Hide in combat", fightTip = "Out of sight while you fight, and clicks go through it then.",
    mouse = "Show on mouseover", mouseTip = "Out of sight until the mouse is on it.",
    through = "Click-through",
    throughTip = "Clicks go through it to what is under it. Its menu is then on its box in Edit Mode.",
    gameMoves = "Move in Edit Mode", gameMovesTip = "The game's own Edit Mode moves these: Esc > Edit Mode.",
    spareTip = "Clicks go through it to what is under it, but for the arrows and checkboxes beside it, where its menu stays.",
}
-- The game's menus of a unit its secure buttons open (SecureTemplates' togglemenu: MENU_UNIT_<which>).
Element.MENUS = { "SELF", "TARGET", "FOCUS", "PET", "OTHERPET", "OTHERBATTLEPET", "PARTY", "PLAYER", "RAID_PLAYER",
                  "RAID", "VEHICLE", "BOSS", "ARENAENEMY", "ENEMY_PLAYER" }
Element.DEPTH = 12 -- how many frames up Of looks for the element a part stands in

local TEXT = Element.TEXT
local elements = {}                                    -- every element, in the order made
local owners = setmetatable({}, { __mode = "k" })      -- [an element's frame] = its window
local fighting = false                                 -- a fight is on, from its first moment to its end

function Element.Is(window)
    return type(window) == "table" and owners[window.frame] == window
end

-- A tick its module keeps itself ({ get, set }), or nil.
local function Theirs(window, what)
    local own = window.options.element
    return type(own) == "table" and type(own[what]) == "table" and own[what] or nil
end

function Element.Get(window, what)
    if not Element.Is(window) then return false end
    local theirs = Theirs(window, what)
    if theirs then return Core.Safe("element", theirs.get) == true end
    return window:Recall(what) == true
end

-- Whether Core does what a tick asks: ticked, and not one its module keeps itself.
local function Ours(window, what)
    return not Theirs(window, what) and Element.Get(window, what)
end

-- In sight whatever is ticked: unlocked, or filling the screen.
local function Kept(window)
    return window.unlocked or window.lifted or false
end

-------------------------------------------------------------------------------
--  Click-through
-------------------------------------------------------------------------------
-- A frame of it going through: whatever of the mouse it takes, lent off. Once: one taken already is left. within: it is
-- part of a frame spared while it is click-through (taken now for a fight it hides in).
local function Take(window, frame, within)
    if window.through[frame] or Plain(frame:IsForbidden()) then return end
    local lend = Core.Lend(frame)
    if Plain(frame:IsMouseClickEnabled()) then lend:SetClicks(false) end
    if Plain(frame:IsMouseMotionEnabled()) then lend:SetMotion(false) end
    if Plain(frame:IsMouseWheelEnabled()) then lend:SetWheel(false) end
    if not lend:Lent() then return end
    window.through[frame] = lend
    if within then window.within[frame] = true end
end

-- The frame and all it holds, but the box and the grip, which bring its menu and its size; sparing: but the frames its
-- module spares too (an element of New's), and all they hold.
local function Walk(window, frame, sparing, within)
    if frame == window.box or frame == window.grip then return end
    within = within or (window.spare and Core.Safe("element", window.spare, frame)) or false
    if within and sparing then return end
    Take(window, frame, within)
    for _, child in ipairs({ frame:GetChildren() }) do Walk(window, child, sparing, within) end
end

-- Every frame given back (a protected one in a fight once it is over: Lend's Return waits); only: those of a spared one.
local function Free(window, only)
    for frame, lend in pairs(window.through) do
        if not only or window.within[frame] then
            window.through[frame], window.within[frame] = nil, nil
            Core.Safe("element", lend.Return, lend)
        end
    end
end

-- Whether its clicks go through now: ticked, or hidden in a fight that is on; not while it sleeps, is unlocked or full.
local function Going(window)
    return not window.asleep and not Kept(window)
        and (Ours(window, "through") or (fighting and Ours(window, "fight")))
end

local function Through(window)
    if not Going(window) then return Free(window) end
    -- What it spares keeps the mouse while it is click-through, not in a fight it hides in.
    local sparing = not (fighting and Ours(window, "fight"))
    if sparing then Free(window, true) end
    -- Its frames, and what else its set holds (the quest log's items stand in a frame of their own).
    for _, frame in ipairs(window.rest and window.rest.frames or window.frames or { window.frame }) do
        Walk(window, frame, sparing)
    end
end

-- Frames made since (a row, a line), and what a fight kept: taken too. Every element, a moment after what asked.
local Again = Core.Later(function()
    for _, window in ipairs(elements) do Core.Safe("element", Through, window) end
end, 0.2, "element")

-------------------------------------------------------------------------------
--  Out of sight
-------------------------------------------------------------------------------
-- The set made for an element without one of its module's: its frame, the mouse looked for on it.
local function Made(window)
    local set = Core.Rest.New({ label = "element", frames = { unpack(window.frames or { window.frame }) } })
    for _, frame in ipairs(set.frames) do set:Area(frame) end
    set.made = true
    window.rest = set
    return set
end

function Element.Look(window)
    if not Element.Is(window) then return end
    local fight, mouse, through = Ours(window, "fight"), Ours(window, "mouse"), Ours(window, "through")
    local set = window.rest
    if not set and (fight or mouse) then set = Made(window) end
    if set then
        set:Keep(Kept(window))
        if set.made then set:Away(window.asleep) end
        set:Watch(set.made or through)
        set:Element(fight, mouse)
        -- Off again, a set of its own gave its alpha back: as its module keeps it.
        if set.made and not set.on then window.frame:SetAlpha(window.asleep and 0 or 1) end
    end
    Through(window)
end

function Element.LookAll()
    for _, window in ipairs(elements) do Core.Safe("element", Element.Look, window) end
end

function Element.Set(window, what, on)
    if not Element.Is(window) then return end
    local theirs = Theirs(window, what)
    if theirs then return Core.Safe("element", theirs.set, on and true or false) end
    window:Remember(what, on and true or nil)
    Element.Look(window)
end

function Element.Join(window, set)
    local own = window.rest
    if own == set then return end
    window.rest = set
    if own and own.made then
        own:Element(false, false) -- off: its frame's alpha given back, the module's set takes it
        own:Keep(false)
    end
    Element.Look(window)
end

function Element.Sleep(window, on)
    window.asleep = on and true or false
    local set = window.rest
    if set and set.made then set:Away(window.asleep) end
    if not (set and set.on) then window.frame:SetAlpha(window.asleep and 0 or 1) end
    if Element.Is(window) then Through(window) end
end

function Element.Away(window, on)
    window.lifted = on and true or false
    Element.Look(window)
end

-------------------------------------------------------------------------------
--  The menu
-------------------------------------------------------------------------------
local function Tip(line, title, text)
    if not (line and line.SetTooltip) then return end
    line:SetTooltip(Core.Guard("element", function(tooltip)
        GameTooltip_SetTitle(tooltip, title)
        GameTooltip_AddNormalLine(tooltip, text)
    end))
end

function Element.Lines(root, window)
    if not Element.Is(window) then return end
    root:CreateTitle(window.options.title or "")
    if not window.Unlock then -- the game's frames (New): its Edit Mode moves them
        local moves = root:CreateButton(TEXT.gameMoves, Core.Guard("element", function() end))
        if moves.SetEnabled then moves:SetEnabled(false) end
        Tip(moves, TEXT.gameMoves, TEXT.gameMovesTip)
    elseif not Core.EditMode.active then -- in Edit Mode every element is unlocked already
        local unlock = root:CreateButton(window.unlocked and TEXT.lock or TEXT.unlock, Core.Guard("element", function()
            window:Unlock(not window.unlocked)
        end))
        local locked = window:Locked() and not window.unlocked
        if locked and unlock.SetEnabled then unlock:SetEnabled(false) end
        Tip(unlock, TEXT.unlock, locked and TEXT.locked or TEXT.unlockTip)
    end
    for _, what in ipairs(Element.WHATS) do
        local box = root:CreateCheckbox(TEXT[what], Core.Guard("element", function() return Element.Get(window, what) end),
                                        Core.Guard("element", function()
                                            Element.Set(window, what, not Element.Get(window, what))
                                        end))
        Tip(box, TEXT[what], what == "through" and window.spare and TEXT.spareTip or TEXT[what .. "Tip"])
    end
end

function Element.Menu(owner, window)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu and Element.Is(window)) then return end
    return util.CreateContextMenu(owner, Core.Guard("element", function(_, root) Element.Lines(root, window) end))
end

function Element.RightClick(frame, window)
    frame:HookScript("OnMouseUp", Core.Guard("element", function(self, button)
        -- Without window: the element it stands in, at the click (a part a module made before the element was).
        if button == "RightButton" and Plain(self:IsMouseOver()) then Element.Menu(self, window or Element.Of(self)) end
    end))
end

-- Its title bar (Window.lua, made when first shown): a right click on it or its title opens the menu.
function Element.TitleBar(window)
    local bar = window.bar
    if not bar or window.barMenu then return end
    window.barMenu = true
    Element.RightClick(bar, window)
    Element.RightClick(bar.find, window)
end

function Element.Of(frame)
    local at = frame
    for _ = 1, Element.DEPTH do
        if type(at) ~= "table" then return nil end
        local window = owners[at]
        if window then return window end
        -- One of the game's frames no addon may touch (a menu of a unit opened from it): not ours, nor above it.
        if at.IsForbidden and Plain(at:IsForbidden()) then return nil end
        at = at.GetParent and at:GetParent()
    end
    return nil
end

-- The game's menu of a unit opened from a secure button of an element (the button, or one it stands in): its lines
-- after the game's.
local function Extend(owner, root)
    local window = type(owner) == "table" and Element.Of(owner)
    if not window then return end
    root:CreateDivider()
    Element.Lines(root, window)
end

if Menu and Menu.ModifyMenu then
    for _, which in ipairs(Element.MENUS) do Menu.ModifyMenu("MENU_UNIT_" .. which, Core.Guard("element", Extend)) end
end

-------------------------------------------------------------------------------
--  An element
-------------------------------------------------------------------------------
-- Called by Window.New for a window made with element = true, and by New.
function Element.Take(window)
    if Element.Is(window) then return end
    elements[#elements + 1] = window
    window.through, window.within = {}, {}
    local again = Core.Guard("element", function() if Going(window) then Again() end end)
    for _, frame in ipairs(window.frames or { window.frame }) do
        owners[frame] = window
        frame:HookScript("OnShow", again)
        frame:HookScript("OnSizeChanged", again)
    end
    Element.TitleBar(window)
    Element.Look(window)
end

-- Frames that are no window of ours, as one element (the game's action bars): what Element asks of a window, with its
-- ticks kept as a window's place is, in the profile by its module and key.
local kept = {}

local function Held(element)
    local places = Core.general and Core.general.places
    if type(places) == "table" then return places, element.name .. ":" .. element.key end
    return Core.Store(element.name), element.key
end

function kept:Recall(what)
    local held, key = Held(self)
    local place = held[key]
    return type(place) == "table" and place[what] or nil
end

function kept:Remember(what, value)
    local held, key = Held(self)
    local place = held[key]
    if type(place) ~= "table" then
        if not value then return end
        place = {}
        held[key] = place
    end
    place[what] = value or nil
end

function kept:Locked()
    return false
end

function Element.New(spec)
    local element = setmetatable({ frame = spec.frames[1], frames = spec.frames, name = spec.name, key = spec.key,
                                   spare = spec.spare, options = { title = spec.title, element = spec.element or true } },
                                 { __index = kept })
    Element.Take(element)
    return element
end

-- From a fight's first moment, while the game still lets protected frames change, to its end: an element hidden in a
-- fight lets the mouse through.
local function Fight(on)
    fighting = on
    for _, window in ipairs(elements) do
        if Ours(window, "fight") then Core.Safe("element", Through, window) end
    end
    if not on then Again() end -- what waited for the fight's end, and frames made in it
end
Core.On("PLAYER_REGEN_DISABLED", function() Fight(true) end)
Core.On("PLAYER_REGEN_ENABLED", function() Fight(false) end)
Core.On("PLAYER_ENTERING_WORLD", function() Fight(InCombatLockdown() == true) end)
