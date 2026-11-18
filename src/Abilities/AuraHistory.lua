local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Aura history
--  A window of the full screen (Board.lua: the part "history", added from the
--  dropdown Windows or by /sane aurahistory): the buffs and debuffs seen on
--  whoever you can attack, newest on top. Core keeps them (Core.AuraLog): in a
--  fight the game hides most auras from addons, so the history holds what the
--  game shows, and Core looks at every unit again once the fight is over. A line:
--      the aura's icon   as the buffs on the unit frames: its tooltip (the aura's
--                        own while it is still on, else the spell's), a left or
--                        right click its menu (Combat's, through Core.AuraMarks: the marks, Add tracking)
--      its name          under it Buff or Debuff, its stacks
--      on                whom it was on, a boss with the game's skull; under it
--                        from whom
--      removable         its dispel type in the game's colour of it, Stealable
--      cast              whether the cast that gave it could be interrupted, where
--                        it was seen
--      came              when it came, to the second (Core.ClockAt)
--      lasts             its duration; under it On now, or how long it stayed
--  What a fight hides comes in two more kinds of lines (Core.AuraLog): your
--  casts in a fight of spells that put an aura on (Your cast in a fight), and
--  once a fight is over the spells the game's own meter holds of it (each
--  member's damage, healing, damage taken, dispels, interrupts: Damage in a
--  fight, ...), whom from and whom on, the fight's name under the time. And the
--  casts the SaneUI of your party or raid sends after each fight (Cast in a
--  fight, from that member), while Share casts in a fight with your group is on
--  (Core.AuraLog.Share). Their icons work as the others', the spell's tooltip.
--  Over the list the dropdown of what to show (all, buffs, debuffs, on bosses,
--  from fights) with Clear history in it; the full screen's search finds by the
--  aura's name, whom it was on or whom from. Filled only while its panel is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local History = {}
ns.AuraHistory = History

History.KEY = "history"
History.LEAST = { 660, 220 }
History.WANTS = { 820, 420 }
History.INSET = 10
History.HEAD = 26   -- the dropdown's line
History.TITLES = 18 -- the columns' words under it
History.ROW = 34    -- a line
History.ICON = 28
History.GAP = 8
-- The columns from the right, their widths; the name takes what is left.
History.COLUMNS = { { "lasts", 78 }, { "came", 72 }, { "cast", 104 }, { "removable", 92 }, { "on", 170 } }
History.SHOWS = { "all", "buffs", "debuffs", "bosses", "fights" }
History.SKULL = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t "

local T = ns.TEXT
local body, box, count, empty, menu, titles
local shown = false
local search = ""

local function Show()
    return ns.store and ns.store.auraHistoryShow or "all"
end

-- Seconds as a player reads them: 45s, 2m 10s, 1h 5m.
local function Span(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    if seconds < 60 then return ("%ds"):format(seconds) end
    if seconds < 3600 then
        local rest = seconds % 60
        return rest > 0 and ("%dm %ds"):format(math.floor(seconds / 60), rest) or ("%dm"):format(seconds / 60)
    end
    local rest = math.floor(seconds % 3600 / 60)
    return rest > 0 and ("%dh %dm"):format(math.floor(seconds / 3600), rest) or ("%dh"):format(seconds / 3600)
end
History.Span = Span

-- The game's colour of a dispel type, as its debuff borders have it.
local function Tint(dispel)
    local colours = rawget(_G, "DebuffTypeColor")
    local colour = type(colours) == "table" and colours[dispel]
    if type(colour) == "table" and colour.r then return colour.r, colour.g, colour.b end
    return 1, 0.82, 0
end

-- Whether an entry is to show: of the kind chosen, found by the search.
local function Wanted(entry, kind)
    local aura = entry.kind ~= "fight" -- seen on a foe, or your cast of one
    if kind == "buffs" and (entry.harmful or not aura) then return false end
    if kind == "debuffs" and (not entry.harmful or not aura) then return false end
    if kind == "bosses" and not entry.boss then return false end
    if kind == "fights" and not entry.kind then return false end
    if search == "" then return true end
    for _, words in ipairs({ entry.name, entry.on, entry.from }) do
        if type(words) == "string" and words:lower():find(search, 1, true) then return true end
    end
    return false
end

-------------------------------------------------------------------------------
--  A line
-------------------------------------------------------------------------------
local function Spell(entry)
    return { id = entry.id, name = entry.name, icon = entry.icon, harmful = entry.harmful and true or false, unit = "target" }
end

-- The aura's tooltip: the aura's own while it is still on (as the buffs on the unit frames ask for it), else the spell's.
local function Entered(icon)
    local entry = icon.entry
    if not entry then return end
    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    local unit, instance = Core.AuraLog.Live(entry)
    if unit and instance then
        GameTooltip:SetUnitAuraByAuraInstanceID(unit, instance)
    elseif entry.id then
        GameTooltip:SetSpellByID(entry.id)
    else
        GameTooltip:SetText(entry.name or "")
    end
    GameTooltip:Show()
end

local function Left(icon)
    if GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
end

local function Clicked(icon, button)
    if icon.entry and icon.entry.name and (button == "LeftButton" or button == "RightButton") then
        Core.AuraMarks.Menu(icon, Spell(icon.entry))
    end
end

local OnEntered = ns.Guard(Entered)
local OnLeft = ns.Guard(Left)
local OnClicked = ns.Guard(Clicked)

local function Words(row, font, justify)
    local words = row:CreateFontString(nil, "OVERLAY", font)
    words:SetJustifyH(justify or "LEFT")
    words:SetWordWrap(false)
    return words
end

-- A line's parts, made the first time the list hands it out (the list keeps and reuses its lines).
local function Make(row)
    row.icon = CreateFrame("Frame", nil, row)
    row.icon:SetSize(History.ICON, History.ICON)
    row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.icon.parts = Core.AuraMarks.Paint(row.icon)
    row.icon:EnableMouse(true)
    row.icon:SetScript("OnEnter", OnEntered)
    row.icon:SetScript("OnLeave", OnLeft)
    row.icon:SetScript("OnMouseUp", OnClicked)
    row.cells = {}
    local right = 0
    for _, column in ipairs(History.COLUMNS) do
        local key, width = column[1], column[2]
        local top, under = Words(row, "GameFontHighlightSmall"), Words(row, "GameFontDisableSmall")
        top:SetPoint("TOPRIGHT", row, "TOPRIGHT", -right, -3)
        top:SetWidth(width - History.GAP)
        under:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, -2)
        under:SetWidth(width - History.GAP)
        row.cells[key] = { top = top, under = under }
        right = right + width
    end
    row.name = Words(row, "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", History.GAP, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", -right - History.GAP, 0)
    row.kind = Words(row, "GameFontDisableSmall")
    row.kind:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.kind:SetPoint("RIGHT", row.name, "RIGHT")
    row.shade = row:CreateTexture(nil, "BACKGROUND")
    row.shade:SetAllPoints(row)
    row.shade:SetColorTexture(1, 1, 1, 0.04)
end

local function Cell(row, key, top, under, r, g, b)
    local cell = row.cells[key]
    cell.top:SetText(top or "")
    cell.top:SetTextColor(r or 1, g or 1, b or 1)
    cell.under:SetText(under or "")
end

-- Every field of a line set anew: the list reuses its lines.
local function Draw(row, item)
    if not row.icon then Make(row) end
    local entry = item.entry
    row.icon.entry = entry
    row.icon.parts.picture:SetTexture(entry.icon or 134400) -- the game's question mark where none was told
    row.icon.parts.cooldown:Clear()
    row.icon.parts.count:SetText((entry.stacks or 0) > 1 and entry.stacks or "")
    row.shade:SetShown(item.index % 2 == 0)
    row.name:SetText(entry.name or "")
    local kind = entry.harmful and T.historyDebuff or T.historyBuff
    if entry.kind == "cast" then kind = entry.shared and T.historyCastShared or T.historyCast end
    if entry.kind == "fight" then kind = T["historyWhat_" .. (entry.what or "damage")] or T.historyWhat_damage end
    if (entry.stacks or 0) > 1 then kind = kind .. "  " .. T.historyStacks:format(entry.stacks) end
    row.kind:SetText(kind)
    local on = (entry.boss and History.SKULL or "") .. (entry.on or T.historyNobody)
    if (entry.hits or 1) > 1 then on = on .. " " .. T.historyMore:format(entry.hits - 1) end
    Cell(row, "on", on, entry.from and T.historyFrom:format(entry.from) or nil)
    if entry.dispel then
        local r, g, b = Tint(entry.dispel)
        Cell(row, "removable", entry.dispel, entry.steal and T.historySteal or nil, r, g, b)
    elseif entry.steal then
        Cell(row, "removable", T.historySteal, nil, 0.4, 0.7, 1)
    else
        Cell(row, "removable", T.historyNone, nil, 0.5, 0.5, 0.5)
    end
    if entry.cast == true then
        Cell(row, "cast", T.historyInterruptible, nil, 0.3, 1, 0.3)
    elseif entry.cast == false then
        Cell(row, "cast", entry.instant and T.historyInstant or T.historyLocked, nil, 1, 0.45, 0.35)
    else
        Cell(row, "cast", T.historyNone, nil, 0.5, 0.5, 0.5)
    end
    Cell(row, "came", entry.stamp and Core.ClockAt(entry.stamp, true) or T.historyNone,
         entry.fight and T.historyFight:format(entry.fight) or nil)
    local now, stayed = Core.Ask(rawget(_G, "time")) or 0, nil
    if Core.AuraLog.Live(entry) then
        stayed = T.historyOn
    elseif entry.gone and entry.stamp and (entry.lasts == 0 or entry.gone < (entry.ends or 0) - 1) then
        stayed = T.historyStayed:format(Span(entry.gone - entry.stamp))
    end
    local lasts = (entry.lasts or 0) > 0 and Span(entry.lasts) or (entry.kind and T.historyNone or T.historyLasting)
    Cell(row, "lasts", lasts, stayed)
    if entry.ends and not entry.gone and entry.ends < now and not Core.AuraLog.Live(entry) then
        row.cells.lasts.under:SetText("") -- out of sight before it went: nothing to tell
    end
end

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local function Fill()
    if not (shown and box) then return end
    local entries, kind, list = Core.AuraLog.Entries(), Show(), {}
    for index = #entries, 1, -1 do
        local entry = entries[index]
        if Wanted(entry, kind) then list[#list + 1] = { entry = entry, index = #list + 1 } end
    end
    box:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
    count:SetText(T.historyCount:format(#list))
    empty:SetShown(#list == 0)
    empty:SetText(#entries == 0 and T.historyEmpty or T.historyNoneFound)
    History.lines = list -- for the test
end
History.Fill = Fill
local Again = Core.Later(function() ns.Safe("aura history", Fill) end, 0, "aura history")

local function Choose(kind)
    ns.store.auraHistoryShow = kind
    Fill()
end

local function Clear()
    Core.Confirm(T.historyClearAsk, nil, ns.Guard(function()
        Core.AuraLog.Clear()
        Fill()
    end))
end

local function Menu(_, root)
    for _, kind in ipairs(History.SHOWS) do
        root:CreateRadio(T["historyShow_" .. kind], ns.Guard(function() return Show() == kind end),
                         ns.Guard(function() Choose(kind) end))
    end
    root:CreateDivider()
    root:CreateButton(T.historyClear, ns.Guard(Clear))
end

-- The columns' words over the list, at their columns' places.
local function Titles(parent)
    local line = CreateFrame("Frame", nil, parent)
    local right = 0
    for _, column in ipairs(History.COLUMNS) do
        local words = Words(line, "GameFontNormalSmall")
        words:SetPoint("RIGHT", line, "RIGHT", -right, 0)
        words:SetWidth(column[2] - History.GAP)
        words:SetText(T["historyColumn_" .. column[1]])
        right = right + column[2]
    end
    local name = Words(line, "GameFontNormalSmall")
    name:SetPoint("LEFT", line, "LEFT", History.ICON + History.GAP + 2, 0)
    name:SetText(T.historyColumn_name)
    return line
end

local Part = {}

function Part.Build(panel)
    body = panel.body
    local I = History.INSET
    menu = CreateFrame("DropdownButton", nil, body, "WowStyle1DropdownTemplate")
    menu:SetWidth(180)
    menu:SetPoint("TOPLEFT", I, -I + 2)
    menu:SetupMenu(ns.Guard(Menu))
    Core.Tip(menu, T.historyTitle, T.historyTip)
    History.menu = menu -- for the test
    count = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("TOPRIGHT", -I, -I - 4)
    titles = Titles(body)
    titles:SetPoint("TOPLEFT", I, -I - History.HEAD)
    titles:SetPoint("TOPRIGHT", -I - 18, -I - History.HEAD)
    titles:SetHeight(History.TITLES)
    box = CreateFrame("Frame", nil, body, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", I, -I - History.HEAD - History.TITLES)
    box:SetPoint("BOTTOMRIGHT", -I - 18, I)
    local bar = CreateFrame("EventFrame", nil, body, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(History.ROW)
    view:SetElementInitializer("Frame", function(row, item) ns.Safe("aura history", Draw, row, item) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    empty = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", box, "TOP", 0, -40)
    empty:SetWidth(History.LEAST[1] - 2 * I)
    History.box = box -- for the test
end

function Part.Show(on)
    shown = on
    if on then Fill() else Core.HideTip() end
end

function Part.Search(text)
    search = type(text) == "string" and text:lower() or ""
    Fill()
end

function Part.Leave()
    shown = false
end

ns.Board.Part(History.KEY, T.historyTitle, History.LEAST, Part, History.WANTS)

-- The switch Share casts in a fight with your group, to Core's log.
function History.Apply()
    Core.AuraLog.Share(ns.options.auraShare ~= false)
end

function History.Start()
    History.Apply()
    Core.AuraLog.Listen(function()
        if shown then Again() end
    end)
end

-- The full screen up, this window on it (Window.Open: once the screen stands full).
function History.Open()
    if ns.off then return end
    ns.Screen.Open(History.KEY)
end
