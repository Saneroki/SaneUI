local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Sheet - Titles
--  The titles, a window of its own on the module's board (the key "titles",
--  Board.lua), as the game's sheet lists them (Camelot's TitleManagerPane): None first, then every title you know by
--  name, in lines (a light stripe on every other one, the game's tick and a
--  gold glow on the one you wear, a lighter glow under the mouse). A click wears that title (SetCurrentTitle, the game's own call).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Titles = {}
ns.Titles = Titles

-- A row, the tick's room; the list in the pane.
Titles.ROW, Titles.CHECK = ns.Style.Fit(22), ns.Style.Fit(18)
Titles.INSET = { 10, 4, 24, 10 }
Titles.TICK = 16 -- the tick on the title worn: the game's own (checkmark-minimal), this large
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

-- A line, made once: its stripe, its glow while worn and under the mouse, the tick, the name.
local function Parts(row)
    if row.text then return end
    local paper = ns.Style
    row:RegisterForClicks("LeftButtonUp")
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(paper.ZEBRA[1], paper.ZEBRA[2], paper.ZEBRA[3], paper.ZEBRA[4])
    row.chosen = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.chosen:SetAllPoints()
    row.chosen:SetColorTexture(paper.CHOSEN[1], paper.CHOSEN[2], paper.CHOSEN[3], paper.CHOSEN[4])
    local light = row:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(paper.SHADE[1], paper.SHADE[2], paper.SHADE[3], paper.SHADE[4])
    row.check = ns.Style.Texture(row, "check", "ARTWORK")
    row.check:SetSize(Titles.TICK, Titles.TICK)
    row.check:SetPoint("LEFT", 4 + (Titles.CHECK - Titles.TICK) / 2, 0)
    row.text = row:CreateFontString(nil, "ARTWORK")
    row.text:SetFontObject(paper.Font("SaneUITitlesName", 14))
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetPoint("LEFT", 4 + Titles.CHECK + 3, 0)
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

-- The window's body: the list on the page.
function Titles.Build(pane)
    list = ns.List.New(pane, { inset = Titles.INSET, extent = Extent, draw = Draw, paper = true })
end

local later = Core.Later(function() ns.Safe("character", Titles.Refresh) end)

function Titles.Show(on)
    if on then Core.On("KNOWN_TITLES_UPDATE", later) else Core.Off("KNOWN_TITLES_UPDATE", later) end
    if on then Core.OnUnit("UNIT_NAME_UPDATE", "player", later) else Core.OffUnit("UNIT_NAME_UPDATE", "player", later) end
    if on then Titles.Refresh() end
end

ns.Board.Part("titles", Core.Word("PAPERDOLL_SIDEBAR_TITLES", "Titles"), ns.Board.Least("titles", 240, 300), {
    Build = function(panel) Titles.Build(panel.body) end,
    Show = Titles.Show,
})
