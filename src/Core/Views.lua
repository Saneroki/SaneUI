local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Views
--  A window with several views, each behind a tab, in the game's own style:
--  the tab system of its spellbook and its housing dashboard (TabSystemTemplate,
--  with the tabs that stand on what they belong to: TabSystemTopButtonTemplate;
--  as wide as the spellbook's, the game's sound when one is chosen). The tabs
--  stand in a row at the top of what the window holds (window.inside, under its
--  title bar), the views under them. A view is built the first time its tab is
--  chosen. The tab last chosen is kept with the window's place (tab) and is the
--  one shown when the window is made again.
--
--      Window.New(frame, { ..., tabs = {
--          { text = "Spells", build = function(view) end },  -- view: the frame to build that view in
--          { text = "Talents", build = function(view) end },
--      } })
--      window:Tab(index)          -- that view, its tab chosen
--      window.views[index]        -- a view, once built; window.view: the index of the one shown
--      window.tabs                -- the row of tabs (nil where the game has no tab system)
-------------------------------------------------------------------------------
local Window = Core.Window

Window.TABS = 32               -- the row's height: the game's tab's
Window.TAB_INSET = 22          -- the first tab from the window's left, as the spellbook's
Window.TAB_WIDTHS = { 100, 150 } -- a tab's narrowest and widest, as the spellbook's

-- That view on show, built if it never was, its tab chosen, and kept for the next time.
local function Choose(window, index)
    local tabs = window.options.tabs
    if not tabs[index] then index = 1 end
    if not window.views[index] then
        local view = CreateFrame("Frame", nil, window.inside)
        view:SetPoint("TOPLEFT", 0, -Window.TABS)
        view:SetPoint("BOTTOMRIGHT")
        window.views[index] = view
        if tabs[index].build then Core.Safe("window", tabs[index].build, view) end
    end
    for other, view in pairs(window.views) do view:SetShown(other == index) end
    window.view = index
    window:Remember("tab", index > 1 and index or nil)
    if window.tabs then window.tabs:SetTabVisuallySelected(index) end
end

local function Tab(window, index)
    Choose(window, index)
end

-- The row of the game's tabs: on top of the views, a tab for each; a click chooses it (and the game plays its
-- sound). Without the game's tab system the views are there all the same, chosen by window:Tab.
local function Row(window)
    local ok, row = pcall(CreateFrame, "Frame", nil, window.inside, "TabSystemTemplate")
    if not ok or not row then return nil end
    local pool = rawget(_G, "CreateFramePool")
    if pool then row.tabPool = pool("BUTTON", row, "TabSystemTopButtonTemplate") end
    row.minTabWidth, row.maxTabWidth = Window.TAB_WIDTHS[1], Window.TAB_WIDTHS[2]
    row:SetPoint("BOTTOMLEFT", window.inside, "TOPLEFT", Window.TAB_INSET, -Window.TABS)
    -- Chosen here, so the game's own showing of the choice is not needed (true).
    row:SetTabSelectedCallback(function(index)
        Core.Safe("window", Choose, window, index)
        return true
    end)
    for _, tab in ipairs(window.options.tabs) do row:AddTab(tab.text) end
    return row
end

-- Made by Window.New for a window with tabs.
function Window.Views(window)
    window.views, window.Tab = {}, Tab
    window.tabs = Row(window)
    Choose(window, window:Recall("tab") or 1)
end
