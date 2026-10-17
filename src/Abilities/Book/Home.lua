local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Home
--  A tab of our own in front of the spellbook's tabs, and its page: what your
--  trainer can teach you right now and what it costs, and which spells you get
--  from quests. It is the page the spellbook opens on.
--
--  The game's tabs are the game's: adding one of ours to them, or switching
--  them, would run our code inside the spellbook's (see Book.lua, "taint"). So
--  the Home tab is a button of this addon that only looks like a tab. It stands
--  where the row of the game's tabs begins, and that row is moved one tab to the
--  right (only its place is changed; it gets it back when Home goes). While Home
--  is on show:
--    - Book.lua parks every entry of the tab underneath off the screen, so the
--      page is empty paper and our rows are drawn on it;
--    - the game's own selected tab still thinks it is selected. A second button
--      of ours covers it, looking unselected; a click on it closes Home.
--  Clicking any other tab, searching, or the game jumping to a spell closes
--  Home as well. Home needs the pages to be ours: when Book.lua stands down,
--  the tab goes with it.
-------------------------------------------------------------------------------
local H = {}
ns.Home = H
local S, L, I, B = ns.Sources, ns.BookLayout, ns.BookItem, ns.Book
local Core = SaneUI.Core
local TEXT = ns.TEXT

local ICON = "Interface\\Icons\\INV_Misc_Rune_01" -- the hearthstone: "home" in this game
local TITLE = Core.Word("HOME", TEXT.home)

local book, paged      -- the game's frames
local tab, cover, pane -- ours: the Home tab, the stand-in over the game's selected tab, the page
local headers, empties, more = {}, {}, nil
local tabRow           -- the row of the game's tabs, moved to make room for Home (Core.Lend)
local SHIFT = 46       -- one tab and the gap after it
local SEARCH_WIDTH, SEARCH_GAP = 300, 10 -- the game's search box: its widest, and its room from the tabs
local LEVEL_HEIGHT = 22
local active = false   -- Home is the page on show
local underneath       -- the game's tab that was selected when Home was opened
local hiddenAt         -- when the spellbook was last hidden

-------------------------------------------------------------------------------
--  A button that looks like one of the spellbook's icon tabs
-------------------------------------------------------------------------------
local function MakeTab(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(44, 32)
    -- a little smaller than the frame around it, as the game's mask leaves its icons
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetSize(34, 33)
    button.Icon:SetPoint("BOTTOM", -1, 0)
    local function Art(atlas, y)
        local texture = button:CreateTexture(nil, "ARTWORK", nil, 1)
        texture:SetAtlas(atlas, true)
        texture:SetPoint("BOTTOM", 0, y)
        return texture
    end
    button.Normal = Art("spellbook-Tab-Frame-C60", 1)
    button.Active = Art("spellbook-Tab-Frame-Glow-C60", 1)
    button.Glow = Art("spellbook-Tab-Frame-glow-gradient-C60", 0)
    return button
end

local function Select(button, selected)
    button.Normal:SetShown(not selected)
    button.Active:SetShown(selected)
    button.Glow:SetShown(selected)
end

-- The game's tab that is selected, and its button. Read only.
local function SelectedTab()
    local tabs = book.CategoryTabSystem
    local id = tabs and tabs.selectedTabID
    return id, id and type(tabs.tabs) == "table" and tabs.tabs[id] or nil
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
local function Coins(copper)
    return Core.Coins(copper) or TEXT.copper:format(copper)
end

local function QuestNote(entry)
    local area = entry.quest.areas and entry.quest.areas[1]
    local name = area and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(area)
    return name and TEXT.questIn:format(name) or TEXT.fromQuest
end

local function Text(parent, font)
    local text = parent:CreateFontString(nil, "ARTWORK", font or "SystemFont_Med1")
    text:SetJustifyH("LEFT")
    text:SetTextColor(I.TextColor())
    text:SetAlpha(0.7)
    return text
end

-- The page's parts, made when first needed and used again (Core.Pool): the rows, and the small
-- headings of the quest section ("Level 10").
local rows = Core.Pool(function() return I.Create(pane) end)
local levels = Core.Pool(function() return Text(pane, "SystemFont_Large") end)

-- Two sections, laid out by the spellbook's own rule (Layout.lua): one on each page of the open
-- book, one under the other in the small spellbook. The quest rewards stand under the level
-- you get them at. What does not fit is counted, not shown.
local function Fill()
    local train, quests, total = {}, {}, 0
    for _, entry in ipairs(S.All()) do
        if entry.quest then
            quests[#quests + 1] = { entry = entry, note = QuestNote(entry) }
        elseif entry.state == "trainable" and not entry.skill then
            train[#train + 1] = { entry = entry, note = entry.cost and entry.cost > 0 and Coins(entry.cost) or nil }
            total = total + (entry.cost or 0)
        end
    end
    table.sort(train, L.ByLevel)
    table.sort(quests, L.ByLevel)

    local trainGroup = { key = "train", items = train, none = #train == 0 and TEXT.nothingToTrain,
        header = { own = "train", text = #train > 0 and TEXT.trainNowCost:format(Coins(total)) or TEXT.trainNow } }
    local questGroups = { { key = "quest", items = {}, none = #quests == 0 and TEXT.noQuests,
        header = { own = "quest", text = TEXT.fromQuests } } }
    local playerLevel = UnitLevel("player") or 1
    for _, item in ipairs(quests) do
        local last, level = questGroups[#questGroups], item.entry.level or 0
        if last.level ~= level then
            last = { level = level, gap = 0, items = {},
                     header = { level = true, height = LEVEL_HEIGHT, dim = level > playerLevel,
                                text = TEXT.level:format(level) } }
            questGroups[#questGroups + 1] = last
        end
        last.items[#last.items + 1] = item
    end

    -- The pages are Book.lua's: their size, how much fits, and how large an entry is drawn
    -- (no metrics before it first drew: then the game's own).
    local scale, metrics, pageHeight, rightAnchor, rightX, cellWidth = B.Layout()
    metrics = metrics or {}
    local showRanks = GetCVarBool("ShowAllSpellRanks") and true or false -- once, not per row
    local left = paged.ViewFrames[1]
    local width = cellWidth * scale
    local pages
    if (paged.viewsPerPage or 2) < 2 or not rightAnchor then
        local all = { trainGroup }
        for _, group in ipairs(questGroups) do all[#all + 1] = group end
        pages = { L.Paginate(all, width, pageHeight, metrics)[1] }
    else
        pages = { L.Paginate({ trainGroup }, width, pageHeight, metrics)[1], L.Paginate(questGroups, width, pageHeight, metrics)[1] }
    end

    local used, shown = 0, {}
    rows:Begin()
    levels:Begin()
    for index, view in ipairs(pages) do
        local anchor, dx = left, 0
        if index == 2 then anchor, dx = rightAnchor, rightX end
        for _, cell in ipairs(view) do
            local item = cell.item
            local x = cell.x + dx
            if item.level then
                local text = levels:Take()
                text:ClearAllPoints()
                text:SetPoint("TOPLEFT", anchor, "TOPLEFT", x + 8, -cell.y)
                text:SetText(item.text)
                text:SetAlpha(item.dim and 0.5 or 0.85)
                text:Show()
            elseif item.own then
                local header = headers[item.own]
                header.Text:SetText(item.text)
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, -cell.y)
                header:Show()
                shown[item.own] = { anchor = anchor, x = x, y = cell.y }
            else
                used = used + 1
                local row = rows:Take()
                row:SetScale(scale)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", anchor, "TOPLEFT", x / scale, -cell.y / scale)
                row:Show()
                I.Set(row, item.entry, nil, cellWidth, item.note, nil, showRanks)
            end
        end
    end
    rows:Done()
    levels:Done()
    for _, group in ipairs({ trainGroup, questGroups[1] }) do
        local at = shown[group.key]
        headers[group.key]:SetShown(at ~= nil)
        local empty = empties[group.key]
        empty:SetShown(at ~= nil and group.none and true or false)
        if at and group.none then
            empty:ClearAllPoints()
            empty:SetPoint("TOPLEFT", at.anchor, "TOPLEFT", at.x + 8, -(at.y + L.HEADER + (metrics.yPad or L.Y_PAD)))
            empty:SetText(group.none)
        end
    end
    local hidden = #train + #quests - used
    more:ClearAllPoints()
    more:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -(pageHeight - 14))
    more:SetShown(hidden > 0)
    if hidden > 0 then
        more:SetText(TEXT.more:format(hidden))
    end
    H.shown = used -- for the tests and /sane ab debug
end

-------------------------------------------------------------------------------
--  On and off
-------------------------------------------------------------------------------
local function Sync()
    if not pane then return end
    local on = active and B.Armed() and book:IsVisible() and true or false
    B.SetHome(on)
    -- Drawing the page underneath may have failed and given the pages back to the game: Home
    -- has gone with them then (BOOK_PAGES), and must not come back here.
    on = on and B.Armed()
    pane:SetShown(on)
    Select(tab, on)
    local _, button = SelectedTab()
    cover:SetShown(on and button ~= nil)
    if on and button then
        cover:ClearAllPoints()
        cover:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
        cover:SetFrameLevel(button:GetFrameLevel() + 5)
        cover.Icon:SetTexture(button.Icon and button.Icon:GetTexture())
    end
    if on then Fill() end
end

function H.Open()
    if not pane or not B.Armed() then return end
    active, underneath = true, (SelectedTab())
    Sync()
end

function H.Close()
    if not active then return end
    active = false
    Sync()
end

function H.IsOpen()
    return active
end

-- The game has drawn a tab: another one than the one under Home, or a search, takes Home's place.
local function OnDrawn()
    if not active then return end
    if book:IsInSearchResultsMode() or (SelectedTab()) ~= underneath then return H.Close() end
    Sync()
end

-- The spellbook opens on Home. Making it small or large hides and shows it within one frame:
-- that is not an opening, and the page you were on stays.
local function OnShown()
    if hiddenAt ~= GetTime() then
        active = ns.options.home and true or false
        underneath = (SelectedTab())
    end
    Sync()
end

local function Setup()
    book = PlayerSpellsFrame.SpellBookFrame
    paged = book.PagedSpellsFrame
    if pane or not book.CategoryTabSystem then return end

    pane = CreateFrame("Frame", "SaneUISpellbookHome", book)
    pane:SetAllPoints(paged)
    pane:SetFrameLevel(paged:GetFrameLevel() + 20)
    pane:Hide()
    for _, key in ipairs({ "train", "quest" }) do
        headers[key] = B.Header(pane)
        empties[key] = Text(pane)
    end
    more = Text(pane)

    tab = MakeTab(book)
    tab.Icon:SetTexture(ICON)
    tab:SetScript("OnClick", function()
        if active then return end
        Core.Sound("IG_SPELLBOOK_OPEN")
        ns.Safe("home", H.Open)
    end)
    Core.Tip(tab, TITLE, TEXT.homeTip)

    cover = MakeTab(book)
    Select(cover, false)
    cover:Hide()
    cover:SetScript("OnClick", function()
        Core.Sound("IG_SPELLBOOK_OPEN")
        ns.Safe("home", H.Close)
    end)

    -- Run after the game's own handlers and apart from them.
    EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Show", function() ns.Safe("home", OnShown) end, H)
    EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Hide", function() hiddenAt = GetTime() end, H)
    EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged",
        function() ns.Safe("home", OnDrawn) end, H)
end

-- The game fits its search box between the row of tabs and the buttons at the right only when
-- the row changes size or the spellbook opens (SpellBookFrameMixin:ResizeSearchBox). Moving the
-- row, or a window made narrower (Window.lua), is neither: the same sum is done here, and only
-- the box's width is set, as the game sets it. Its right edge stays where the game anchored it.
local function FitSearchBox()
    local box = book.SearchBox
    local left = ns.Plain(book.CategoryTabSystem:GetRight())
    local right = left and box and ns.Plain(box:GetRight())
    if right then box:SetWidth(math.max(math.min(right - left - SEARCH_GAP, SEARCH_WIDTH), 0)) end
end

-- The row one tab further right: its one point, moved.
local function Shift(frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, (x or 0) + SHIFT, y or 0)
end

-- Home stands where the row of the game's tabs begins; the row makes room for it (on) or gets
-- its place back. Only the row's place is changed. In a fight a frame of the game's may be
-- locked: then Home takes the gap in front of the row instead, and the row goes back once the
-- fight is over.
local function PlaceTabs(on)
    local tabs = book.CategoryTabSystem
    tabRow = tabRow or Core.Lend(tabs)
    if on and not tabRow:Lent() and tabs:GetNumPoints() == 1 then
        if tabRow:SetPoints(Shift) then FitSearchBox() end
    elseif not on and tabRow:Lent() then
        if Core.Locked(tabs) then
            Core.AfterCombat("Abilities: home tabs", PlaceTabs, false)
        elseif tabRow:Return() then
            FitSearchBox()
        end
    end
    tab:ClearAllPoints()
    if tabRow:Lent() then
        tab:SetPoint("BOTTOMLEFT", tabs, "BOTTOMLEFT", -SHIFT, 0)
    else
        tab:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMLEFT", -2, 0)
    end
end

-- Book.lua took the spellbook's pages (on) or gave them back to the game.
ns.Listen("BOOK_PAGES", function(on)
    if on then
        Setup()
        if tab then
            PlaceTabs(true)
            tab:Show()
        end
        return
    end
    active = false
    if pane then
        pane:Hide()
        tab:Hide()
        cover:Hide()
        PlaceTabs(false)
    end
end)
ns.Listen("BOOK_JUMP", H.Close)
ns.Listen("REFRESH", function()
    -- Not while the spellbook is closed (pane stays shown in it): it is filled when it opens.
    if pane and pane:IsVisible() then Fill() end
    -- The window may have another width now (Window.lua redraws after every change of size).
    if tabRow and tabRow:Lent() and book:IsVisible() then FitSearchBox() end
end)
