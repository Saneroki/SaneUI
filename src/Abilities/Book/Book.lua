local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Book
--  Puts the spells you have not learned yet into the game's own spellbook.
--
--  The game's spell entries stay exactly what they are: they are made, filled
--  and clicked by Blizzard's code alone. That matters, because casting from the
--  spellbook only works while nothing an addon wrote is read on the way (the
--  game calls that "taint"; one addon-written value in the page number is enough
--  to break casting until /reload, and to block the action bars in combat).
--
--  So this file never calls a function of the spellbook that changes something,
--  and never writes a value on one of its frames. It does three things, all of
--  them plain placement ("put this frame there"), which leaves no trace in the
--  game's own bookkeeping:
--
--    1. It makes the first page's column very tall. The game then puts every
--       entry of a tab on "page 1" and makes all of them at once.
--    2. After each time the game has drawn the tab, it moves those entries to
--       where they belong on the real pages, with the grey ones of this addon
--       (Item.lua) in between. Entries of other pages wait far off the screen.
--    3. It shows page buttons of its own; the game's are moved off the screen,
--       because for the game there is only ever one page now.
--
--  One limit comes from the game: in a fight an addon may not move a frame
--  that carries one of the game's protected frames. A spellbook entry does so
--  after you opened its spell flyout. Such an entry is left where it is until
--  the fight is over (Locked).
--
--  If any of this fails, StandDown() gives the pages back to the game.
-------------------------------------------------------------------------------
local B = {}
ns.Book = B
local S, L, I = ns.Sources, ns.BookLayout, ns.BookItem
local Core = SaneUI.Core

local TALL = 60000  -- a column this high holds any tab on one page
local PARK = -8000  -- where entries of other pages wait: far below and left of the screen
local WATCH_FRAMES, WATCH_EVERY = 10, 0.2 -- the watcher (Watch): every frame for so many after a layout, then so often

local book, paged, view1, view2, nativePager -- the game's frames
local container, pager                       -- ours
local headers = {}                           -- our headings: "tab", "extra", "passive", "skills"
local armed, standDown, hooked = false, nil, false
local columnTaken, pagerTaken = false, false -- what of the game's we changed and must give back
local nativeHeight, nativePagerPoints
local lastHeader                             -- the last heading of the game's we saw; ours copy its look

local pool = {}      -- our grey entries, reused
local managed = {}   -- [one of the game's entries] = { anchor, x, y, corner, view } where we put it
local views = {}     -- the pages of the tab on show, from Layout.Paginate
local perPage, page, pageKey = 2, 1, nil
local showRanks = false -- the game's "Show all spell ranks", read once per build for every grey entry
local style, cellWidth = {}, L.CELL_WIDTH
local counts = { native = 0, ghosts = 0 }
local heals, healStart = 0, 0
local watchFrames, watchWait = 0, 0 -- frames the watcher still looks at every one; time since its last look
local home = false   -- the Home page (Home.lua) is on show: every entry waits off the screen
local toggle         -- the checkbox next to the page buttons: hidden spells on or off
local expanded = {}  -- [spell name] = true: all its ranks are on show (until /reload)
local parked = {}    -- the game's entries of ranks that are folded away
local folds, foldHeaders = {}, {} -- our small buttons: "+" on a folded spell, the heading of an unfolded one
local FOLD_HEIGHT = 22

-- The page as it is right now (Measure): the spellbook can be resized (Window.lua) and compact.
local COMPACT = 0.75        -- how much smaller a compact entry is
local scale = 1             -- of every entry, the game's and ours
local metrics               -- columns and paddings for Layout.Paginate
local pageHeight = L.VIEW_HEIGHT
local rightAnchor, rightX   -- where the right page starts: the frame its entries hang on, and how far in

local function Gamepad()
    return InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled() and true or false
end

-------------------------------------------------------------------------------
--  Placing the game's entries. Only ClearAllPoints and SetPoint: no script of
--  the entry runs and nothing is written on it.
-------------------------------------------------------------------------------
-- In a fight the game forbids an addon to move a frame that holds a protected one. (Home.lua too.)
local function Locked(frame)
    return InCombatLockdown() and frame:IsProtected() and true or false
end
B.Locked = Locked

local function InPlace(frame, want)
    if frame:GetNumPoints() ~= 1 then return false end
    local _, relativeTo, _, x, y = frame:GetPoint(1)
    return relativeTo == want.anchor and math.abs((x or 0) - want.x) < 0.5 and math.abs((y or 0) - want.y) < 0.5
end

-- anchor nil: this entry belongs to another page. view: the page column it is on.
-- size: how large the entry is drawn (1: as the game made it). A frame counts the way to its
-- anchor in its own, scaled measure, so the page's numbers are divided by it.
local function Place(frame, anchor, x, y, view, size)
    size = size or 1
    local want = managed[frame]
    if not want then
        want = {}
        managed[frame] = want
    end
    want.view = view
    if anchor then
        want.anchor, want.x, want.y, want.corner = anchor, x / size, -y / size, "TOPLEFT"
    else
        want.anchor, want.x, want.y, want.corner = UIParent, PARK, PARK, "BOTTOMLEFT"
    end
    if Locked(frame) then return end
    if math.abs((frame:GetScale() or 1) - size) > 0.001 then frame:SetScale(size) end
    if InPlace(frame, want) then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", want.anchor, want.corner, want.x, want.y)
end

-------------------------------------------------------------------------------
--  Reading what the game has drawn
-------------------------------------------------------------------------------
-- The game's entries of the tab on show, as groups of a heading and its spells.
local function Collect()
    local groups, group, sample = {}, nil, nil
    local count = 0
    for _, frame in ipairs(paged:GetFrames()) do
        local data = frame.GetElementData and frame:GetElementData()
        if data then
            count = count + 1
            if data.isHeader then
                group = { header = { frame = frame }, items = {} }
                groups[#groups + 1] = group
                lastHeader = frame
            else
                if not group then
                    group = { items = {} }
                    groups[#groups + 1] = group
                end
                local info = frame.spellBookItemInfo
                -- By the trainer's name ("Instant Poison II" is "Instant Poison"): ranks fold, grey ones join them.
                local name = info and ns.Plain(info.name)
                if type(name) == "string" then
                    local sub = ns.Plain(info.subName)
                    name = ns.Data.FamilyName(name, type(sub) == "string" and sub or nil)
                end
                group.items[#group.items + 1] = { frame = frame, name = name or data.name }
                if info and not sample then sample = frame end
            end
        end
    end
    return groups, sample, count
end

-- The spellbook tab on show, when it is one of your own skill lines, and a word
-- that changes whenever another list is on show (the page number starts over then).
local function ActiveTab()
    -- every search is a new list, as it is for the game
    if book:IsInSearchResultsMode() then return nil, "search" .. tostring(paged.dataProvider) end
    local category = book:GetActiveCategoryMixin()
    if not category then return nil, "none" end
    local line = category.skillLineIndex
    if line and category.spellBank == Enum.SpellBookSpellBank.Player then return line, "line" .. line end
    return nil, "tab" .. tostring(category.tabID)
end

local function General()
    return Enum.SpellBookSkillLineIndex and Enum.SpellBookSkillLineIndex.General or 1
end

-- The first tab that is not "General": the spells no tab was found for are listed there.
local function FirstClassTab()
    local general = General()
    local first
    for _, category in ipairs(book.categoryMixins or {}) do
        local line = category.skillLineIndex
        if line and line ~= general and category.spellBank == Enum.SpellBookSpellBank.Player
           and (not first or line < first) then
            first = line
        end
    end
    return first
end

-- How the game's entries look right now. A skin changes colours and
-- fades the plates; the grey entries follow whatever a real one shows.
local function ReadStyle(sample)
    local look = {}
    if not sample then return look end
    local name, button = sample.Name, sample.Button
    if name and name.GetTextColor then
        local r, g, b = name:GetTextColor()
        look.text = { r, g, b }
    end
    if sample.Backplate then look.backplate = math.min(sample.Backplate:GetAlpha() or 0.25, 0.25) end
    if button and button.Border then
        look.border = button.Border:GetAlpha()
        look.borderDesaturation = button.Border.GetDesaturation and button.Border:GetDesaturation() or 0
    end
    if button and button.IconHighlight then look.highlight = (button.IconHighlight:GetAlpha() or 1) > 0.01 end
    return look
end

local function CopyText(target, source)
    if not (target and source) then return end
    local font, size, flags = source:GetFont()
    if font then target:SetFont(font, size, flags) end
    target:SetTextColor(source:GetTextColor())
end

-------------------------------------------------------------------------------
--  The ranks of one spell, folded into one entry
-------------------------------------------------------------------------------
-- With "Show all spell ranks" on, a spell with several ranks takes one place: the highest
-- rank you have, or the lowest one still to learn. A "+" on it unfolds the ranks into a
-- small section of their own under the tab's spells; a click on that section's heading
-- folds them away again. The game's entries of the other ranks wait off the screen.
-- Returns the tab's entries without the folded ranks, and the unfolded sections.
local function Fold(items)
    local families = {}
    for _, item in ipairs(items) do
        if item.name then
            families[item.name] = families[item.name] or {}
            table.insert(families[item.name], item)
        end
    end
    local out, open = {}, {}
    for _, item in ipairs(items) do
        local family = item.name and families[item.name]
        if not family or #family < 2 then
            out[#out + 1] = item
        elseif expanded[item.name] then
            if item == family[1] then
                open[#open + 1] = { gap = 0, items = family,
                                    header = { fold = item.name, text = item.name, height = FOLD_HEIGHT } }
            end
        else
            local keep = family[1]
            for _, member in ipairs(family) do
                if member.frame then keep = member end
            end
            if item == keep then
                item.more, item.family = #family - 1, true
                out[#out + 1] = item
            elseif item.frame then
                parked[#parked + 1] = item.frame
            end
        end
    end
    return out, open
end

local function SetExpanded(name, on)
    expanded[name] = on or nil
    PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
    B.Relayout()
end

-- The "+" in the corner of a folded spell. Above the game's entries, or they would take its clicks.
local function FoldButton(index)
    local button = folds[index]
    if not button then
        button = CreateFrame("Button", nil, container)
        button:SetSize(16, 16)
        button:SetFrameLevel(container:GetFrameLevel() + 30)
        button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
        button:SetScript("OnClick", function(self) SetExpanded(self.spell, true) end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(("Show all ranks of %s (%d more)"):format(self.spell, self.more))
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        folds[index] = button
    end
    return button
end

-- The heading of a spell's unfolded ranks: a "-" and the spell's name, in one button.
local function FoldHeader(index)
    local header = foldHeaders[index]
    if not header then
        header = CreateFrame("Button", nil, container)
        header:SetSize(L.VIEW_WIDTH, FOLD_HEIGHT)
        header:SetFrameLevel(container:GetFrameLevel() + 30)
        header.Minus = header:CreateTexture(nil, "ARTWORK")
        header.Minus:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
        header.Minus:SetSize(16, 16)
        header.Minus:SetPoint("LEFT", 2, 0)
        header.Text = header:CreateFontString(nil, "ARTWORK", "SystemFont_Large")
        header.Text:SetPoint("LEFT", header.Minus, "RIGHT", 6, 0)
        header:SetScript("OnClick", function(self) SetExpanded(self.spell, false) end)
        header:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetText("Fold the ranks away")
            GameTooltip:Show()
        end)
        header:SetScript("OnLeave", function() GameTooltip:Hide() end)
        foldHeaders[index] = header
    end
    return header
end

-------------------------------------------------------------------------------
--  Drawing one page
-------------------------------------------------------------------------------
local function Show()
    local first = (page - 1) * perPage
    local used, seen, shown = 0, {}, {}
    local usedFolds, usedHeaders = 0, 0

    for index, view in ipairs(views) do
        local position = index - first
        local anchor, dx = nil, 0
        if not home and position == 1 then
            anchor = view1
        elseif not home and position == 2 and perPage == 2 then
            anchor, dx = rightAnchor, rightX
        end
        for _, cell in ipairs(view) do
            local item = cell.item
            local x = cell.x + dx
            if anchor and item.more then
                usedFolds = usedFolds + 1
                local button = FoldButton(usedFolds)
                button.spell, button.more = item.name, item.more
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", anchor, "TOPLEFT", x + cellWidth * scale - 18, -cell.y - 2)
                button:Show()
            end
            if item.fold then
                if anchor then
                    usedHeaders = usedHeaders + 1
                    local header = FoldHeader(usedHeaders)
                    header.spell = item.fold
                    header.Text:SetText(item.text)
                    if style.text then header.Text:SetTextColor(style.text[1], style.text[2], style.text[3]) end
                    header:ClearAllPoints()
                    header:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, -cell.y)
                    header:Show()
                end
            elseif item.frame then
                -- the game's headings keep their size: they span the page
                Place(item.frame, anchor, x, cell.y, index, cell.header and 1 or scale)
                seen[item.frame] = true
            elseif anchor and item.own then
                local header = headers[item.own]
                header.Text:SetText(item.text)
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, -cell.y)
                shown[item.own] = true
            elseif anchor then
                used = used + 1
                local ghost = pool[used]
                if not ghost then
                    ghost = I.Create(container)
                    pool[used] = ghost
                end
                ghost:SetScale(scale)
                ghost:ClearAllPoints()
                ghost:SetPoint("TOPLEFT", anchor, "TOPLEFT", x / scale, -cell.y / scale)
                ghost:Show()
                I.Set(ghost, item.entry, style, cellWidth, nil, item.family, showRanks)
            end
        end
    end
    for _, frame in ipairs(parked) do
        Place(frame, nil)
        seen[frame] = true
    end
    for index = usedFolds + 1, #folds do folds[index]:Hide() end
    for index = usedHeaders + 1, #foldHeaders do foldHeaders[index]:Hide() end

    for index = used + 1, #pool do
        pool[index]:Hide()
        pool[index].entry = nil
    end
    for key, header in pairs(headers) do
        -- our headings take their look from one of the game's
        if shown[key] and lastHeader and lastHeader.Text then
            CopyText(header.Text, lastHeader.Text)
            if lastHeader.Backplate then header.Backplate:SetAlpha(lastHeader.Backplate:GetAlpha()) end
            if lastHeader.Border then header.Border:SetAlpha(lastHeader.Border:GetAlpha()) end
        end
        header:SetShown(shown[key] or false)
    end
    for frame in pairs(managed) do
        if not seen[frame] then managed[frame] = nil end
    end

    -- Our page buttons. They are our own copy of the game's template, so writing
    -- their numbers is harmless.
    pager.maxPages = math.max(1, math.ceil(#views / perPage))
    pager.currentPage = page
    pager:UpdateControls()
    CopyText(pager.PageText, nativePager.PageText)
    pager:SetShown(not home)
    toggle:SetShown(not home)
    toggle:SetChecked(ns.options.showHidden and true or false)
    CopyText(toggle.Text, nativePager.PageText)
    watchFrames = WATCH_FRAMES -- the game may lay its entries out again in the frames that follow
end

-- How large the pages are and how much fits on them. The numbers are the game's own for its
-- own two sizes (a page of 680 x 590 that starts 85 from the left and 45 from the top; the
-- right page 76 right of the middle), and follow the window when it has another size.
local function Measure()
    local compact = ns.options.compact
    scale = compact and COMPACT or 1
    local width, height = paged:GetWidth() or 0, paged:GetHeight() or 0
    local pagesShown = (paged.viewsPerPage or 2) < 2 and 1 or 2
    local pageWidth = L.VIEW_WIDTH
    pageHeight, rightAnchor, rightX = L.VIEW_HEIGHT, view2, 0
    if width > 300 and height > 200 then
        pageWidth, pageHeight = math.max(width / pagesShown - 126, 100), math.max(height - 62, 100)
        rightAnchor, rightX = view1, width / 2 - 9
    end
    local xPad, yPad = compact and 8 or L.X_PAD, compact and 4 or L.Y_PAD
    metrics = { xPad = xPad, yPad = yPad, cell = L.CELL * scale,
                columns = math.max(1, math.floor((pageWidth + xPad) / (cellWidth * scale + xPad))) }
end

-- For Home.lua, which draws on the same pages: scale, metrics, page height, the right page's
-- anchor and offset, and an entry's width.
function B.Layout()
    return scale, metrics, pageHeight, rightAnchor, rightX, cellWidth
end

-- Work out the pages of the tab on show, then draw the current one.
local function Build()
    if Gamepad() then return B.StandDown("a controller is in use") end
    -- Only at this height does the game make every entry of a tab; without them all, no layout.
    if view1:GetHeight() < TALL - 1 then return B.StandDown("something changed the spellbook's column") end

    local groups, sample, nativeCount = Collect()
    counts.native, counts.ghosts = nativeCount, 0
    style = ReadStyle(sample)
    cellWidth = sample and sample:GetWidth() or L.CELL_WIDTH
    if not cellWidth or cellWidth < 60 then cellWidth = L.CELL_WIDTH end
    Measure()

    local tab, key = ActiveTab()
    wipe(parked)
    if tab and ns.ready then
        showRanks = GetCVarBool("ShowAllSpellRanks") and true or false
        local hidePassives = GetCVarBool("spellBookHidePassives") and true or false
        local hidden = ns.options.showHidden

        local ghosts = {}
        for _, entry in ipairs(hidden and S.Unlearned(tab, showRanks) or {}) do
            ghosts[#ghosts + 1] = { entry = entry, name = entry.name, rank = entry.rank, level = entry.level }
        end
        if #ghosts > 0 then
            groups[1] = groups[1] or { items = {} }
            groups[1].items = L.Order(groups[1].items, ghosts)
            counts.ghosts = #ghosts
            -- A tab whose own spells are all hidden (passive ones, with "hide passives") has its
            -- heading on a page that does not exist for us: draw the heading ourselves.
            if not groups[1].header then
                local info = C_SpellBook.GetSpellBookSkillLineInfo(tab)
                if info and info.name then groups[1].header = { own = "tab", text = info.name } end
            end
        end

        -- Sections of ours follow the tab's own spells, in this order: the unfolded ranks,
        -- the passive spells, then what the game itself lists further down, then the rest.
        local at = math.min(#groups, 1)
        local function Section(group, last)
            if last then
                groups[#groups + 1] = group
            else
                at = at + 1
                table.insert(groups, at, group)
            end
        end
        local function Items(entries)
            local items = {}
            for _, entry in ipairs(entries) do items[#items + 1] = { entry = entry } end
            table.sort(items, L.ByLevel)
            counts.ghosts = counts.ghosts + #items
            return items
        end

        if showRanks and groups[1] then
            local folded, open = Fold(groups[1].items)
            groups[1].items = folded
            for _, group in ipairs(open) do Section(group) end
        end

        if hidden and tab == General() then
            -- Passive spells to come are all listed here, whichever tab the game files them in.
            local passives = hidePassives and {} or Items(S.UnlearnedPassives(showRanks))
            if #passives > 0 then Section({ header = { own = "passive", text = "Passive spells to learn" }, items = passives }) end
            local skills = Items(S.UnlearnedSkills())
            if #skills > 0 then Section({ header = { own = "skills", text = "Skills to learn" }, items = skills }, true) end
        end

        if hidden and tab == FirstClassTab() then
            local others = Items(S.Unlearned(nil, showRanks))
            if #others > 0 then Section({ header = { own = "extra", text = "Other spells to learn" }, items = others }, true) end
        end
    end

    views = L.Paginate(groups, cellWidth * scale, pageHeight, metrics)
    local columns = (paged.viewsPerPage or 2) < 2 and 1 or 2
    if key ~= pageKey then
        page, pageKey = 1, key
    elseif columns ~= perPage then
        -- small or large spellbook: keep the column that was on the left, as the game does
        page = math.ceil(((page - 1) * perPage + 1) / columns)
    end
    perPage = columns
    page = math.max(1, math.min(page, math.ceil(#views / perPage)))
    Show()
end

-------------------------------------------------------------------------------
--  Keeping it in place
-------------------------------------------------------------------------------
-- Runs a step of ours; an error gives the pages back to the game.
local function Run(fn)
    local ok, problem = xpcall(fn, Core.Trace)
    if ok then return end
    Core.NoteError(ns.name .. ": book", problem)
    B.StandDown("a problem, noted in the error log (/sane errors)")
end

function B.Relayout()
    if not armed or not paged:IsVisible() then return end
    Run(Build)
end

-- The Home page takes the pages (on) or gives them back. It can only while the pages are ours.
function B.SetHome(on)
    on = on and armed or false
    if home == on then return end
    home = on
    B.Relayout()
end

function B.Armed()
    return armed
end

-- Called by the game (through its event registry, which keeps our code apart from
-- its own) every time it has drawn the tab, and when the spellbook is opened.
function B.OnNative()
    B.Relayout()
end

-- Every entry the game has made stands where we put it. An entry we have not placed at
-- all counts as out of place, so a redraw we were not told about is caught here too.
local function AllInPlace()
    for _, frame in ipairs(paged:GetFrames()) do
        local want = managed[frame]
        if not want or not (InPlace(frame, want) or Locked(frame)) then return false end
    end
    return true
end

-- The game lays its entries out again on its own now and then: when the column is shown,
-- for one, often a frame or two after it said it drew. So for a few frames after each layout
-- of ours every frame is looked at, then five times a second while the spellbook is open (the
-- watcher is a script of our page frame: closed, it does not run).
local function Watch(_, elapsed)
    if not armed then return end
    if watchFrames > 0 then
        watchFrames = watchFrames - 1
    else
        watchWait = watchWait + (elapsed or 0)
        if watchWait < WATCH_EVERY then return end
    end
    watchWait = 0
    local ok, fine = pcall(AllInPlace)
    if ok and fine then return end
    local now = GetTime()
    if now - healStart > 2 then healStart, heals = now, 0 end
    heals = heals + 1
    if not ok or heals > 40 then
        return B.StandDown("something else keeps moving the spellbook's entries")
    end
    B.Relayout()
end

-- The game jumps to a spell (the spellbook button's "new spell" does): it turns its own
-- pages, of which there is only one now. Turn ours to the page that entry is on.
local function OnGoToSpell(_, spellID, knownSpellsOnly)
    if not armed or not C_SpellBook.FindSpellBookSlotForSpell then return end
    ns.Fire("BOOK_JUMP") -- the game wants a spell on show: Home steps aside
    local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(spellID, false, true, not knownSpellsOnly, not knownSpellsOnly)
    if not slot then return end
    for frame, want in pairs(managed) do
        local data = frame.GetElementData and frame:GetElementData()
        if data and data.slotIndex == slot and data.spellBank == bank and want.view then
            local target = math.ceil(want.view / perPage)
            if target ~= page then
                page = target
                Run(Show)
            end
            return
        end
    end
end

-------------------------------------------------------------------------------
--  Giving the pages back
-------------------------------------------------------------------------------
-- The column's height and the game's page buttons, as they were. In a fight the column
-- may be one of the frames an addon must not touch; then this waits for the fight's end.
local function GiveBack()
    if columnTaken and not Locked(view1) then
        view1:SetHeight(nativeHeight or L.VIEW_HEIGHT)
        columnTaken = false
    end
    if pagerTaken and not Locked(nativePager) then
        Core.Repoint(nativePager, nativePagerPoints)
        pagerTaken = false
    end
end

-- Leave the spellbook to the game. What is on screen is tidied one last time (the first
-- page, without grey entries). The game keeps its one long page for the tab on show until
-- it draws that tab afresh, which it does when you come back to it from another tab.
function B.StandDown(reason)
    if not armed then
        -- Not taken over yet, or a start that failed half way: what it took goes back.
        standDown = standDown or reason
        GiveBack()
        return
    end
    armed, standDown, home = false, reason, false
    ns.Fire("BOOK_PAGES", false)
    pcall(function()
        local groups = Collect()
        views, page = L.Paginate(groups, cellWidth), 1
        for index, view in ipairs(views) do
            local anchor = (index == 1 and view1) or (index == 2 and perPage == 2 and view2) or nil
            for _, cell in ipairs(view) do Place(cell.item.frame, anchor, cell.x, cell.y, index) end
        end
        -- every entry at the game's size again, also those of other pages and folded ranks
        for _, frame in ipairs(paged:GetFrames()) do
            if not Locked(frame) and frame:GetScale() ~= 1 then frame:SetScale(1) end
        end
    end)
    wipe(managed)
    container:Hide()
    GiveBack()
    ns.Print("left the spellbook's pages to the game (" .. reason .. "). Click another tab of the spellbook and come back: then the page is the game's own again.")
end

-------------------------------------------------------------------------------
--  Taking over, once the spellbook exists
-------------------------------------------------------------------------------
-- A heading in the look of the game's own, hidden until it is used. Home.lua makes its own too.
function B.Header(parent)
    local header = CreateFrame("Frame", nil, parent, "SpellBookHeaderTemplate")
    header:SetWidth(L.VIEW_WIDTH)
    header:Hide()
    return header
end

-- Our own frames, made once and before anything of the game's is changed. They are made into
-- locals and kept only when every one of them could be made: should the game lack one of the
-- templates, nothing is left half there. A name tells skins that these are not Blizzard's to restyle.
local function MakeFrames()
    local frame = CreateFrame("Frame", "SaneUISpellbook", paged)
    frame:Hide()
    frame:SetAllPoints(paged)
    frame:SetFrameLevel(view1:GetFrameLevel())

    local paging = CreateFrame("Frame", "SaneUISpellbookPager", frame, "PagingControlsHorizontalTemplate")
    paging.spacing = 8
    paging.prevPageSound, paging.nextPageSound = SOUNDKIT.IG_ABILITY_PAGE_TURN, SOUNDKIT.IG_ABILITY_PAGE_TURN
    paging:SetOverridePagedContentFrame(frame)
    function frame:OnPageChanged()
        page = paging.currentPage
        Run(Show)
    end

    local made = { tab = B.Header(frame), extra = B.Header(frame), passive = B.Header(frame), skills = B.Header(frame) }

    -- Unlearned spells on or off, where the pages are turned. The same switch as in the spellbook's
    -- menu and the options, with the same words and the same explanation when pointed at.
    local option = Core.Described(ns.name, "showHidden")
    local box = CreateFrame("CheckButton", "SaneUISpellbookShowHidden", frame, "UICheckButtonTemplate")
    box:SetSize(24, 24)
    box:SetFrameLevel(frame:GetFrameLevel() + 30)
    box:SetPoint("RIGHT", paging, "LEFT", -14, 0)
    box.Text:SetText(option.text)
    box.Text:ClearAllPoints()
    box.Text:SetPoint("RIGHT", box, "LEFT", -2, 0)
    -- Set through Core, which tells the module (its changed redraws the pages) and the options page.
    box:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
        self:SetChecked(Core.Set(ns.name, "showHidden", on) and true or false)
    end)
    box:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, option.text)
        GameTooltip_AddNormalLine(GameTooltip, option.tip, true)
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnUpdate", Watch)
    frame:SetScript("OnHide", function() ns.Drag.Cancel() end)
    container, pager, headers, toggle = frame, paging, made, box
end

local function Arm()
    if armed or standDown or not ns.options.book then return end
    if Gamepad() then
        standDown = "a controller is in use"
        return
    end
    book = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
    paged = book and book.PagedSpellsFrame
    local columns = paged and paged.ViewFrames
    if not (columns and columns[1] and paged.PagingControls and paged.GetFrames
            and book.GetActiveCategoryMixin and book.IsInSearchResultsMode and EventRegistry) then
        standDown = "this spellbook is not the one the addon knows"
        return
    end
    view1, view2, nativePager = columns[1], columns[2] or columns[1], paged.PagingControls
    if Locked(view1) or Locked(nativePager) then return end -- tried again when the fight is over

    if not container then MakeFrames() end

    -- All of these run after the game's own handler and apart from it.
    if not hooked then
        hooked = true
        EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged", B.OnNative, B)
        EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Show", B.OnNative, B)
        view1:HookScript("OnShow", B.OnNative)
        paged:HookScript("OnMouseWheel", function(_, delta)
            if armed and not home then pager:OnMouseWheel(delta) end
        end)
        if book.GoToSpell then pcall(hooksecurefunc, book, "GoToSpell", OnGoToSpell) end
    end

    -- Now the game's column and its page buttons. Their own height and place are only noted
    -- while they still have them, never what we gave them.
    local height = view1:GetHeight()
    if height and height < TALL - 1 then nativeHeight = height end
    view1:SetHeight(TALL)
    columnTaken = true
    if not pagerTaken then nativePagerPoints = Core.Points(nativePager) end
    Core.Repoint(pager, nativePagerPoints)
    nativePager:ClearAllPoints()
    nativePager:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", PARK, PARK)
    pagerTaken = true

    container:Show()
    armed = true
    ns.Fire("BOOK_PAGES", true)
    B.Relayout()
end

-- An error while taking over: it is not tried again, and what it took of the game's goes back.
local function TryArm()
    if not (ns.DB and ns.char) then return end
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
    if not (loaded and loaded("Blizzard_PlayerSpells")) then return end
    local ok, problem = xpcall(Arm, Core.Trace)
    if ok then return end
    ns.Report("book", problem)
    B.StandDown("an error while taking the pages over")
end

ns.On("PLAYER_LOGIN", TryArm)
ns.On("ADDON_LOADED", function(name)
    if name == "Blizzard_PlayerSpells" then TryArm() end
end)
-- What a fight held up: taking over, giving back, an entry that could not be moved.
ns.On("PLAYER_REGEN_ENABLED", function()
    if armed then
        B.Relayout()
    elseif standDown then
        if view1 then ns.Safe("book", GiveBack) end
    else
        TryArm()
    end
end)
ns.Listen("REFRESH", B.Relayout)

-- Why the pages are the game's right now; nil while they are ours. For the menu (Menu.lua) and
-- /sane ab debug: the reason of a fallback, the switch, or a start that has not come yet.
function B.Why()
    if armed then return nil end
    if standDown then return standDown end
    if not ns.options.book then return ("\"%s\" is off in the options"):format(Core.Described(ns.name, "book").text) end
    return "not taken yet"
end

-- One line for /sane ab debug.
function B.Describe()
    if armed then
        return ("spellbook: %d of the game's entries and %d grey ones on %d page(s), page %d on show."):format(
            counts.native, counts.ghosts, math.max(1, math.ceil(#views / perPage)), page)
    end
    return "spellbook: its pages are left to the game (" .. B.Why() .. ")."
end
