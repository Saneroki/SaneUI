local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Bars
--  The reminder bars: invisible, like an action bar with no buttons, placed in
--  Edit Mode. Only the icons of what shows now can be seen, side by side and
--  centred on the bar's place, so a bar is as wide as what it holds. A bar's
--  frame is made when it first has something to show, or in Edit Mode, where
--  every bar stands, to be placed. Nothing on it takes the mouse.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bars = {}
ns.ReminderBars = Bars

Bars.SIZE = 36  -- an icon, square
Bars.GAP = 4    -- between icons
Bars.WIDE = 6   -- icons in a bar's box in Edit Mode
Bars.CROP = { 0.08, 0.92, 0.08, 0.92 } -- an icon's picture without the edge it is drawn with

local bars = {} -- [a bar's number] = { frame, window, row, icons, place }

local function Icon(bar, index)
    local icon = CreateFrame("Frame", nil, bar.row)
    icon:SetSize(Bars.SIZE, Bars.SIZE)
    icon:SetPoint("LEFT", bar.row, "LEFT", (index - 1) * (Bars.SIZE + Bars.GAP), 0)
    local edge = icon:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints(icon)
    edge:SetColorTexture(0, 0, 0, 0.9)
    icon.picture = icon:CreateTexture(nil, "ARTWORK")
    icon.picture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    icon.picture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    icon.picture:SetTexCoord(Bars.CROP[1], Bars.CROP[2], Bars.CROP[3], Bars.CROP[4])
    icon.left = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    icon.left:SetPoint("BOTTOM", icon, "BOTTOM", 0, 2)
    bar.icons[index] = icon
    return icon
end

local function Make(number, place)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("LOW")
    frame:SetSize(Bars.WIDE * (Bars.SIZE + Bars.GAP) - Bars.GAP, Bars.SIZE)
    frame:Hide()
    local window = Core.Window.New(frame, {
        store = ns.store, key = "reminderBar" .. number, title = ns.TEXT.reminderBar:format(place),
        first = { point = "CENTER", x = 0, y = 240 - (place - 1) * (Bars.SIZE + 2 * Bars.GAP) },
    })
    local row = CreateFrame("Frame", nil, window.inside)
    row:SetPoint("CENTER", frame, "CENTER", 0, 0)
    row:SetHeight(Bars.SIZE)
    window:Place()
    bars[number] = { frame = frame, window = window, row = row, icons = {}, place = place }
    return bars[number]
end

-- Seconds left as an icon says them: up to a minute by the second, then by the minute.
function Bars.Left(left)
    if left >= 60 then return math.ceil(left / 60) .. "m" end
    return tostring(math.ceil(left))
end

-- A bar with what shows now on it: list = { { icon, left }, ... }; place: its place among the bars, which names it.
function Bars.Fill(number, place, list)
    local bar = bars[number]
    local shows = list[1] ~= nil or Core.EditMode.active
    if not bar then
        if not shows then return end
        bar = Make(number, place)
    end
    if bar.place ~= place then
        bar.place = place
        bar.window:SetTitle(ns.TEXT.reminderBar:format(place))
    end
    for at, entry in ipairs(list) do
        local icon = bar.icons[at] or Icon(bar, at)
        icon.picture:SetTexture(entry.icon)
        icon.left:SetText(entry.left and Bars.Left(entry.left) or "")
        icon:Show()
    end
    for at = #list + 1, #bar.icons do bar.icons[at]:Hide() end
    bar.row:SetWidth(math.max(#list * (Bars.SIZE + Bars.GAP) - Bars.GAP, 1))
    bar.frame:SetShown(shows)
end

-- A bar deleted: its frame goes and its place is forgotten.
function Bars.Drop(number)
    local bar = bars[number]
    if bar then bar.frame:Hide() end
    bars[number] = nil
    ns.store["reminderBar" .. number] = nil
end

function Bars.Hide()
    for _, bar in pairs(bars) do bar.frame:Hide() end
end
