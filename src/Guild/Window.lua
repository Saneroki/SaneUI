local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Window
--  Where the guild window's page (Page.lua) stands. With Social on (and the
--  switch On Social's Full Screen), on Social's full screen: offered to its
--  board as its guild window (Core.Board.Offer, the key guild), in place of the
--  game's guild window Social holds there otherwise; the guild key opens that
--  full screen with it (Core.Board.Open). Without Social, in a window of its
--  own (Core.Window.New, a panel: its title bar, moved by it, Esc closes it,
--  its place and size kept). The page is made once and moves between the two.
--
--      Window.Offer()    at the load: offered to Social's board (it lists it whether Social is there or not)
--      Window.Toggle()   the guild key, /sane guild: open it where it stands, or close it
--      Window.Rehome()   the switch changed: offered or withdrawn
--      Window.Leave()    the module stood down: closed, withdrawn
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, TEXT = ns.Layout, ns.TEXT
local Window = {}
ns.Window = Window

local BOARD, KEY = "Social", "guild"
local frame, window -- the window of its own, once made

local function OnSocial()
    return ns.options.social ~= false
end

-- Social's board's window for the guild: the page in its panel's body.
local SPEC = {
    key = KEY, title = TEXT.title, least = Layout.LEAST, icon = "Interface\\Icons\\INV_Epicguildtabard",
    want = function(width, height) return Layout.Want(width, height) end,
    present = function() return IsInGuild and IsInGuild() and true or false end,
    build = function(panel) ns.Guarded(ns.Page.Build, panel.body) end,
    show = function(panel, on)
        if on then
            if frame and frame:IsShown() then frame:Hide() end
            ns.Guarded(ns.Page.Into, panel.body)
        end
        ns.Guarded(ns.Page.Show, on)
    end,
    search = function(_, text) ns.Guarded(ns.Page.Search, text) end,
}

function Window.Offer()
    if OnSocial() then Core.Board.Offer(BOARD, SPEC) end
end

function Window.Rehome()
    if OnSocial() then Core.Board.Offer(BOARD, SPEC) else Core.Board.Withdraw(BOARD, KEY) end
end

-------------------------------------------------------------------------------
--  The window of its own
-------------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(1063, 760)
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = ns.store, key = "place", title = TEXT.title, sizable = true,
        minWidth = Layout.LEAST[1], minHeight = Layout.LEAST[2],
        first = { point = "CENTER", x = 0, y = 20, width = 1063, height = 760 },
        search = function(text) ns.Guarded(ns.Page.Search, text) end,
        close = function() frame:Hide() end,
    })
    -- Hooked, not set: Core's window hooked its own on these (Esc, its zone, letting go of a drag), which a set
    -- script would drop.
    frame:HookScript("OnShow", ns.Guard(function()
        ns.Page.Into(window.inside)
        ns.Page.Show(true)
        Core.Sound("IG_CHARACTER_INFO_OPEN")
    end))
    frame:HookScript("OnHide", ns.Guard(function()
        ns.Page.Show(false)
        Core.Sound("IG_CHARACTER_INFO_CLOSE")
    end))
    window:Place()
end

local function InGuild()
    return Core.Ask(rawget(_G, "IsInGuild")) == true
end

-- Open it where it stands, or close it: on Social's full screen (opened with the guild window in its layout, or
-- back from it), else the window of its own. Outside a guild nothing opens (there is nothing to show, and the
-- game's guild key opens the game's own window, where a guild is found): it is said; a window of its own still
-- open closes.
function Window.Toggle()
    if ns.off then return end
    if not InGuild() then
        if frame and frame:IsShown() then frame:Hide() else ns.Say(TEXT.noGuild) end
        return
    end
    if OnSocial() and Core.Board.Offered(BOARD, KEY) then
        if Core.Board.Standing(BOARD) and ns.Page.Shown() then return Core.Board.Close(BOARD) end
        if Core.Board.Open(BOARD, KEY) then return end
    end
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end

function Window.Leave()
    Core.Board.Withdraw(BOARD, KEY)
    if frame then frame:Hide() end
end
