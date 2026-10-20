local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Titles
--  The titles of the stats' window's sidebar (Sidebar.lua), as the game's
--  sheet lists them (Camelot's TitleManagerPane): None first, then every title
--  you know by name, in the game's rows (a stripe on every other one, a tick
--  and the game's bar on the one you wear, its blue light under the mouse). A
--  click wears that title (SetCurrentTitle, the game's own call).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Titles = {}
ns.Titles = Titles

-- The game's sizes (PaperDollFrame.xml): a row, the tick; the list in the pane as the game sets it in.
Titles.ROW, Titles.CHECK = 22, 16
Titles.INSET = { 10, 8, 30, 30 }
Titles.NONE = -1

local list
local current = Titles.NONE

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- The titles you know, by name, None first (the game's GetKnownTitles, sorted as its pane sorts them).
function Titles.Known()
    local known = {}
    for index = 1, Core.Ask(rawget(_G, "GetNumTitles")) or 0 do
        if Core.Ask(rawget(_G, "IsTitleKnown"), index) then
            local name = Core.Ask(rawget(_G, "GetTitleName"), index)
            if name then known[#known + 1] = { name = strtrim(name), id = index } end
        end
    end
    table.sort(known, function(a, b) return a.name < b.name end)
    table.insert(known, 1, { name = Core.Word("PLAYER_TITLE_NONE", "None"), id = Titles.NONE })
    return known
end

local function Wear(row)
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Game("SetCurrentTitle", row.data.id)
end

-- A row of the game's look (PlayerTitleButtonTemplate), made once.
local function Parts(row)
    if row.text then return end
    row:RegisterForClicks("LeftButtonUp")
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAtlas("UI-Character-Info-Line-Bounce2", true)
    row.stripe:SetPoint("CENTER")
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(Titles.CHECK, Titles.CHECK)
    row.check:SetPoint("LEFT", 6, 0)
    row.chosen = row:CreateTexture(nil, "ARTWORK")
    row.chosen:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
    row.chosen:SetBlendMode("ADD")
    row.chosen:SetAlpha(0.4)
    row.chosen:SetAllPoints()
    row:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue", "ADD")
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    row.text:SetPoint("LEFT", row.check, "RIGHT", 3, 0)
    row.text:SetPoint("RIGHT", -3, 0)
    row:SetScript("OnClick", function(self) ns.Safe("character", Wear, self) end)
end

local function Draw(row, data)
    Parts(row)
    row.data = data
    row.text:SetText(data.name)
    local worn = data.id == current
    row.check:SetShown(worn)
    row.chosen:SetShown(worn)
    row.stripe:SetShown(data.index % 2 == 0)
end

local function Extent()
    return Titles.ROW
end

-- The list as the game has your titles now, the one you wear ticked.
function Titles.Refresh()
    if not list then return end
    local now = Core.Ask(rawget(_G, "GetCurrentTitle")) or 0
    local most = Core.Ask(rawget(_G, "GetNumTitles")) or 0
    current = (now > 0 and now <= most and Core.Ask(rawget(_G, "IsTitleKnown"), now)) and now or Titles.NONE
    local known = Titles.Known()
    for index, data in ipairs(known) do data.index = index end
    ns.List.Fill(list, known)
end

-- The pane under the stone: the game's inside frame round the list.
function Titles.Build(pane)
    local border = pane:CreateTexture(nil, "BORDER")
    border:SetAtlas("common-insideframe")
    border:SetPoint("TOPLEFT", 1, 1)
    border:SetPoint("BOTTOMRIGHT", -4, 2)
    list = ns.List.New(pane, { inset = Titles.INSET, extent = Extent, draw = Draw })
end

-- Whether there is a title to choose (the game's sidebar greys its tab out with only None).
function Titles.Any()
    return #Titles.Known() > 1
end

local later = Core.Later(function() ns.Safe("character", Titles.Refresh) end)

function Titles.Show(on)
    if on then Core.On("KNOWN_TITLES_UPDATE", later) else Core.Off("KNOWN_TITLES_UPDATE", later) end
    if on then Core.OnUnit("UNIT_NAME_UPDATE", "player", later) else Core.OffUnit("UNIT_NAME_UPDATE", "player", later) end
    if on then Titles.Refresh() end
end
