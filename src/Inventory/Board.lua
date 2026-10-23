local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Board
--  The full screen's windows, while the window stands full: on Core's board
--  (Core.Board), so they share the screen as you arrange them, in layouts
--  behind tabs in the full window's title bar (drag a window's head to move
--  it, the gap between two to share their room anew, its X to take it off;
--  the dropdown Windows adds one, and so does its icon's tab beside the
--  layouts' tabs, lit while it is on). The module's windows, in this order:
--      character   the character: the paper doll (Sheet/Sheet.lua)
--      stats       the character's stats, and the pet's (Sheet/Stats.lua)
--      gear        the gear sets: the game's equipment manager (Sheet/Gear.lua)
--      titles      the titles (Sheet/Titles.lua)
--      reputation, skills, pvp, currency, statistics
--                  what the game's character sheet has behind its tabs, each a
--                  window of its own (Sheet/)
--      bags        the bags
--      bank        the bank, while the character is at a banker
--      alts        your alts: the other characters' snapshots
--  Each is a part in files of its own, listed after this one in the TOC, that
--  registers itself (Board.Part); the board lists the parts that are there.
--  The first layout puts the windows of Board.FIRST side by side, left to
--  right, each as wide as it asks (its least width), the last one taking what
--  is left (a window with nothing to show now, the bank away from a banker,
--  left out); the others are added from the dropdown Windows.
--
--  A panel is Core's (Board.lua: a plate in Sane UI's look, a head with its
--  title and the X, the body under it); what is in it is its part's. A part
--  runs apart from the rest (ns.Safe): one that fails is noted and the others
--  go on; only the window's own work stands the module down.
--
--  A part is a table with:
--      Part.Build(panel)      makes what it holds in panel.body (panel.title, panel.head are there)
--      Part.Show(on)          its panel is shown (on) or hidden: listen to the game only while shown
--      Part.Size(w, h)        its panel's body is that wide and high now (a part may lack it)
--      Part.Search(text)      what is typed into the search box ("": nothing; a part may lack it)
--      Part.Present()         whether it has something to show now (a part may lack it: always)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = {}
ns.Board = Board

-- Each window's icon, for its tab of its own in the full window's title bar (Core's board: lit while the window
-- is on the board, a click puts it on or takes it off): the game's own icons for what it stands for (the
-- character sheet's side tabs', the bags', the portrait), a function where it is drawn (Board.lua's spec.icon).
local function Portrait(texture)
    local portrait = rawget(_G, "SetPortraitTexture")
    if portrait then portrait(texture, "player") end
end
local function Honor(texture)
    texture:SetTexture(UnitFactionGroup("player") == "Horde" and "Interface/ICONS/INV_SideTab_Honor_Horde_c60"
        or "Interface/ICONS/INV_SideTab_Honor_Alliance_c60")
end
Board.ICONS = {
    character = Portrait,
    stats = "Interface/ICONS/Spell_Nature_Strength",
    gear = function(texture) -- the game's sidebar icons (PaperDollFrameConstants.lua)
        texture:SetTexture("Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs")
        texture:SetTexCoord(0.015625, 0.53125, 0.46875, 0.60546875)
    end,
    titles = function(texture)
        texture:SetTexture("Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs")
        texture:SetTexCoord(0.015625, 0.53125, 0.32421875, 0.4609375)
    end,
    reputation = "Interface/ICONS/INV_SideTab_Reputation2_c60",
    skills = "Interface/ICONS/Ability_Racial_JackofAllTrades",
    pvp = Honor,
    currency = "Interface/ICONS/INV_SideTab_Currency_c60",
    statistics = "Interface/ICONS/INV_SideTab_Stats_c60",
    bags = "Interface/ICONS/INV_Misc_Bag_08",
    bank = "Interface/ICONS/INV_Misc_Bag_09",
    alts = "Interface/ICONS/INV_Misc_GroupNeedMore",
}

-- The windows in Sane UI's own look (Doc/guides/interface-style.md, Core.Journal): the character on its doll (its
-- own leather and paper, "bare"), the stats, the gear sets, the titles, the bags, the bank and the alts on the
-- journal's page. The others keep Core's dark plate for now.
Board.DRESS = { character = "bare", stats = "journal", gear = "journal", titles = "journal", bags = "journal",
                bank = "journal", alts = "journal" }

-- The windows in the dropdown's order; those the first layout holds.
Board.ORDER = { "character", "stats", "gear", "titles", "reputation", "skills", "pvp", "currency", "statistics", "bags", "bank", "alts" }
Board.FIRST = { character = true, stats = true, bags = true, bank = true, alts = true }

local layouts  -- Core's board, once the window is there (Board.Take)
local parts = {} -- [key] = { part, spec }: registered by the parts' files

-- A part's steps, each by itself under the part's title.
local function Step(key, part, name)
    return function(_, ...)
        if part[name] then ns.Safe(key, part[name], ...) end
    end
end

-- A part's file registers it: its window's key (one of Board.ORDER), title, least size ({ width, height }, or
-- a function giving it) and the part itself.
function Board.Part(key, title, least, part)
    parts[key] = { part = part, spec = {
        key = key, title = title, least = least, icon = Board.ICONS[key], dress = Board.DRESS[key],
        build = function(panel) ns.Safe(key, part.Build, panel) end,
        show = Step(key, part, "Show"), size = Step(key, part, "Size"), search = Step(key, part, "Search"),
        present = part.Present and function() return ns.Safe(key, part.Present) == true end or nil,
    } }
end

-- The windows there are, in their order.
local function Windows()
    local list = {}
    for _, key in ipairs(Board.ORDER) do
        if parts[key] then list[#list + 1] = parts[key].spec end
    end
    return list
end

-- The first layout: the windows of Board.FIRST side by side, each as wide as its least width, the last taking
-- the rest of the room the board lays out in (the screen less Core's pads round and between the windows).
local function Default(width)
    local list = {}
    for _, spec in ipairs(Windows()) do
        if Board.FIRST[spec.key] and (not spec.present or spec.present()) then list[#list + 1] = spec end
    end
    if #list == 0 then return nil end
    if #list == 1 then return { key = list[1].key } end
    local pad = Core.Board.PAD
    local rest = width - pad * (#list + 1)
    local nodes, shares = {}, {}
    for index, spec in ipairs(list) do
        local least = spec.least
        if type(least) == "function" then least = least() end
        nodes[index] = { key = spec.key }
        shares[index] = least[1]
        if index < #list then rest = rest - least[1] end
    end
    shares[#list] = math.max(shares[#list], rest)
    return { split = "x", parts = nodes, shares = shares }
end

-- Core's window is made (Window.lua): its full screen is Core's board.
function Board.Take(window)
    layouts = Core.Board.New(window, {
        store = ns.store, key = "board", label = ns.name,
        windows = Windows,
        default = function(width, height) return ns.Safe("board", Default, width, height) end,
        changed = function() ns.Guarded(ns.Window.Reboard) end,
    })
    Board.layouts = layouts
end

-- Whether a window is on the layout shown; a window put on it (a key asked for it), as the dropdown Windows does,
-- only while it stands.
function Board.Has(key)
    return layouts and layouts:Has(key) or false
end

function Board.Add(key)
    if layouts and layouts.standing and not layouts:Has(key) then layouts:Toggle(key) end
end

-- The window stands full: what it holds (inside) is that wide and high.
function Board.Show(inside, width, height)
    if layouts then return layouts:Show(inside, width, height) end
end

-- The window is at its size, or on its way there: every panel out of sight.
function Board.Hide()
    if layouts then layouts:Hide() end
end

function Board.Search(text)
    if layouts then layouts:Search(text) end
end

-- A window's body (what its part fills) in its panel that large, and the panel round a body that large: the
-- journal's page in its leather, the doll's whole panel, or the dark plate's under its head.
function Board.Body(key, width, height)
    local dress = Board.DRESS[key]
    if dress == "journal" then return Core.Journal.Inner(width, height) end
    if dress == "bare" then return width, height end
    local edge = Core.Board.EDGE
    return width - 2 * edge, height - Core.Board.HEAD - 2 * edge
end

function Board.Least(key, width, height)
    local dress = Board.DRESS[key]
    if dress == "journal" then
        local w, h = Core.Journal.Outer(width, height)
        return { math.ceil(w), math.ceil(h) }
    end
    if dress == "bare" then return { width, height } end
    local edge = Core.Board.EDGE
    return { width + 2 * edge, height + Core.Board.HEAD + 2 * edge }
end

-- A part's panel, once made (Core's board's).
function Board.Panel(key)
    return layouts and layouts.panels[key]
end
