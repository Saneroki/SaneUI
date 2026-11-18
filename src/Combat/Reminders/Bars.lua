local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Bars
--  The reminder bars: invisible, like an action bar with no buttons, placed in
--  Edit Mode. Only the icons of what shows now can be seen, side by side and
--  centred on the bar's place, so a bar is as wide as what it holds. A bar's
--  frame is made when it first has something to show, or in Edit Mode, where
--  every bar stands, to be placed. Out of a fight its icons take the mouse as
--  the buffs above a unit frame do: on one the aura's tooltip, a left or right
--  click its menu, the marks, Edit tracked... on that tracking (Lists.Menu;
--  Saneroki, 2026-11-09: "The reminderbar icons should be clickable like the
--  buffs in the aura view"). In a fight and in Edit Mode nothing on a bar takes
--  the mouse: clicks go through to the world, the bar is dragged.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bars = {}
ns.ReminderBars = Bars

Bars.SIZE = 36  -- an icon, square
Bars.GAP = 4    -- between icons
Bars.WIDE = 6   -- icons in a bar's box in Edit Mode
Bars.CROP = { 0.08, 0.92, 0.08, 0.92 } -- an icon's picture without the edge it is drawn with

local bars = {} -- [a bar's number] = { frame, window, row, icons, place }

-- The aura of an icon's tracking, as its menu takes it: a buff or debuff on the first unit it watches by a token.
local function Spell(reminder)
    local unit = ns.Reminders.Units(reminder)[1]
    if unit == "group" or ns.Reminders.ROLES[unit] then unit = "player" end
    return { id = reminder.id, name = reminder.name, icon = reminder.icon, harmful = reminder.harmful, unit = unit,
             reminder = reminder }
end

local function Clicked(icon, button)
    if icon.reminder and (button == "LeftButton" or button == "RightButton") then
        ns.AuraLists.Menu(icon, Spell(icon.reminder))
    end
end

local function Entered(icon)
    local reminder = icon.reminder
    if reminder then Core.SpellSearch.Tip(icon, reminder.id, reminder.name) end
end

local function Left(icon)
    if GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
end

local OnClicked = ns.Guard(Clicked)
local OnEntered = ns.Guard(Entered)
local OnLeft = ns.Guard(Left)

-- An icon as the bars show one, on parent, that big: its picture in a thin dark edge, the seconds left at its foot in
-- that font (the nameplates' icons too, Plates.lua).
function Bars.Icon(parent, size, font)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)
    local edge = icon:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints(icon)
    edge:SetColorTexture(0, 0, 0, 0.9)
    icon.picture = icon:CreateTexture(nil, "ARTWORK")
    icon.picture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    icon.picture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    icon.picture:SetTexCoord(Bars.CROP[1], Bars.CROP[2], Bars.CROP[3], Bars.CROP[4])
    icon.left = icon:CreateFontString(nil, "OVERLAY", font)
    icon.left:SetPoint("BOTTOM", icon, "BOTTOM", 0, 2)
    return icon
end

local function Icon(bar, index)
    local icon = Bars.Icon(bar.row, Bars.SIZE, "NumberFontNormal")
    icon:SetPoint("LEFT", bar.row, "LEFT", (index - 1) * (Bars.SIZE + Bars.GAP), 0)
    icon:SetScript("OnMouseUp", OnClicked)
    icon:SetScript("OnEnter", OnEntered)
    icon:SetScript("OnLeave", OnLeft)
    icon:EnableMouse(false)
    icon.mouse = false
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

-- A bar with what shows now on it: list = { { icon, left, reminder }, ... }; place: its place among the bars, which
-- names it. Its icons take the mouse out of a fight and out of Edit Mode.
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
    local mouse = not InCombatLockdown() and not Core.EditMode.active
    for at, entry in ipairs(list) do
        local icon = bar.icons[at] or Icon(bar, at)
        icon.picture:SetTexture(entry.icon)
        icon.left:SetText(entry.left and Bars.Left(entry.left) or "")
        icon.reminder = entry.reminder
        local takes = mouse and entry.reminder ~= nil
        if icon.mouse ~= takes then
            icon.mouse = takes
            icon:EnableMouse(takes)
        end
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
