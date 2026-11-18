local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Board
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
--                  window of its own (Sheet/); skills and pvp only where the
--                  game has WoW: Forever's skill lines and PvP rank (none in
--                  Retail: those parts do not register)
--      vendor      the game's vendor window, seated in its panel while it is
--                  open (Talks.lua)
--      mail, letter  the game's mail window and a letter's, likewise
--      bags        the bags
--      bank        the bank, while the character is at a banker
--      alts        your alts: the other characters' snapshots
--  Each is a part in files of its own, listed after this one in the TOC, that
--  registers itself (Board.Part); the board lists the parts that are there.
--  The first layout puts the windows of Board.FIRST side by side, left to
--  right, each as wide as it asks (its least width), the last one taking what
--  is left (a window with nothing to show now, the bank away from a banker,
--  left out); the others are added from the dropdown Windows. At a vendor and
--  a banker and a mailbox the full screen comes with a layout of its own for that talk
--  (Talks.lua: Core's board's occasions, registered by Board.Occasion).
--
--  A panel is Core's (Board.lua: a plate in SaneUI's look, a head with its
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
--      Part.Width             how wide the first layout makes it (a part may lack it: its least width)
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
-- The side tabs' icons are WoW: Forever's own art; Retail has none of them, so there an icon of its own of the same
-- meaning.
local function SideTab(forever, retail)
    return Core.ForGame({ retail = "Interface/ICONS/" .. retail }) or "Interface/ICONS/" .. forever
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
    reputation = SideTab("INV_SideTab_Reputation2_c60", "Achievement_Reputation_01"),
    skills = "Interface/ICONS/Ability_Racial_JackofAllTrades",
    pvp = Honor,
    currency = SideTab("INV_SideTab_Currency_c60", "INV_Misc_Coin_02"),
    statistics = SideTab("INV_SideTab_Stats_c60", "Achievement_General"),
    vendor = "Interface/ICONS/INV_Misc_Coin_01",
    mail = "Interface/ICONS/INV_Letter_15", -- a letter has none: it comes with the mail
    bags = "Interface/ICONS/INV_Misc_Bag_08",
    bank = "Interface/ICONS/INV_Misc_Bag_09",
}

-- The windows that draw their own frame (Core's board, "bare"): the character's doll, its frame scaled with it
-- (Doll.lua). The others stand in the kit's heavy bronze (Core.Look, Doc/guides/interface-style.md, The kit).
Board.DRESS = { character = "bare" }
-- The windows that fill their body to its edges (they stood on the journal's page before the kit): their body set
-- inside the frame, Core's board's EDGE from its sides and bottom and under its head (Board.Body's size).
Board.FILLED = { stats = true, gear = true, titles = true, bags = true, bank = true }

-- The windows in the dropdown's order; those the first layout holds. The other characters' things are the bags'
-- window's too (its dropdown of the characters; Saneroki, 2026-11-15: "marge the Alts and Bags window into one").
Board.ORDER = { "character", "stats", "gear", "titles", "reputation", "skills", "pvp", "currency", "statistics", "vendor", "mail",
                "letter", "bags", "bank" }
Board.FIRST = { character = true, stats = true, bags = true, bank = true }

local layouts  -- Core's board, once the window is there (Board.Take)
local parts = {} -- [key] = { part, spec }: registered by the parts' files
local occasions = {} -- [name] = { title, default }: the talks the full screen has a layout for (Board.Occasion)

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
        key = key, title = title, least = least, width = part.Width, icon = Board.ICONS[key], dress = Board.DRESS[key],
        build = function(panel)
            if Board.FILLED[key] and panel.body then
                local edge = Core.Board.EDGE
                panel.body:ClearAllPoints()
                panel.body:SetPoint("TOPLEFT", edge, -(Core.Board.HEAD + edge))
                panel.body:SetPoint("BOTTOMRIGHT", -edge, edge)
            end
            ns.Safe(key, part.Build, panel)
        end,
        show = Step(key, part, "Show"), size = Step(key, part, "Size"), search = Step(key, part, "Search"),
        present = part.Present and function() return ns.Safe(key, part.Present) == true end or nil,
    } }
end

-- A talk the full screen has a layout of its own for (Talks.lua): its name, its tab's title and its layout until the
-- player changes it (function(width, height) returning a node of Core's board).
function Board.Occasion(name, title, default)
    occasions[name] = { title = title, default = function(width, height) return ns.Safe("board", default, width, height) end }
end

-- A talk began (its name) or ended (nil): its layout stands on the full screen while it is on.
function Board.Talk(name)
    if layouts then layouts:Occasion(name) end
end

-- Whether a part is registered and has something to show now (the vendor: while its window is open).
function Board.Present(key)
    local entry = parts[key]
    if not entry then return false end
    return not entry.spec.present or entry.spec.present()
end

-- The windows there are, in their order.
local function Windows()
    local list = {}
    for _, key in ipairs(Board.ORDER) do
        if parts[key] then list[#list + 1] = parts[key].spec end
    end
    return list
end

-- The first layout: the windows of Board.FIRST side by side, each as wide as it asks, the last taking
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
        local wide = spec.width or least[1]
        nodes[index] = { key = spec.key }
        shares[index] = wide
        if index < #list then rest = rest - wide end
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
        occasions = occasions,
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
-- doll's whole panel, or the bronze frame's inside under its head (Core's board: Board.HEAD, Board.EDGE).
function Board.Body(key, width, height)
    if Board.DRESS[key] == "bare" then return width, height end
    local edge = Core.Board.EDGE
    return width - 2 * edge, height - Core.Board.HEAD - 2 * edge
end

function Board.Least(key, width, height)
    if Board.DRESS[key] == "bare" then return { width, height } end
    local edge = Core.Board.EDGE
    return { width + 2 * edge, height + Core.Board.HEAD + 2 * edge }
end

-- A part's panel, once made (Core's board's).
function Board.Panel(key)
    return layouts and layouts.panels[key]
end
