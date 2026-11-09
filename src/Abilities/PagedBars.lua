local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Paged bars
--  Any of Action Bars 2 to 8 paged by your stance or form, as the game pages
--  its own Bar 1 (Saneroki, 2026-11-09: "this makes the bar into a paged bar
--  (like the first one, bar one native) or activate the stance / forms specific
--  page and change accordingly"). A checkbox beside each bar, for a class whose
--  stances or forms have rows of their own: ticked, the bar shows the row Bar 1
--  shows in the game in that stance or form, and its own out of it.
--
--  The rows are the game's, by its bonus bar ([bonusbar:n], row 6 + n): in WoW:
--  Forever (its client's SpellShapeshiftForm.BonusActionBar) Battle Stance 7,
--  Defensive Stance 8, Berserker Stance 9; Cat Form 7, Bear and Dire Bear Form 9;
--  Stealth 7. Shadowform, Moonkin, Travel and Aquatic Form have none: the bar
--  shows its own then. Bar 1 keeps its page here (Bar1.lua), so those rows are
--  free for a paged bar; with that switch off, Bar 1 shows the same row.
--
--  A druid's Bar 6 has its own checkbox, number and arrows (FormBar.lua): it is
--  not one of these. The choice is the character's own, kept with its
--  reservations, unticked at first.
--
--  As Bar 1's and the form bar's: a button asks for its own "actionpage" before
--  its bar's, so each of the twelve holds the row's page, and none on the bar's
--  own; the game's secure state driver turns them, in a fight too. The buttons
--  and their keys stay the game's own. A tick in a fight waits for its end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local PagedBars = {}
ns.PagedBars = PagedBars

-- Bars 2 to 8: their number, the game's frame and its buttons' names.
PagedBars.BARS = {
    { number = 2, bar = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton" },
    { number = 3, bar = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton" },
    { number = 4, bar = "MultiBarRight", prefix = "MultiBarRightButton" },
    { number = 5, bar = "MultiBarLeft", prefix = "MultiBarLeftButton" },
    { number = 6, bar = "MultiBar5", prefix = "MultiBar5Button" },
    { number = 7, bar = "MultiBar6", prefix = "MultiBar6Button" },
    { number = 8, bar = "MultiBar7", prefix = "MultiBar7Button" },
}
-- The classes whose stances or forms have rows of their own.
PagedBars.CLASSES = { WARRIOR = true, DRUID = true, ROGUE = true }
-- The row for each bonus bar, as the game gives Bar 1 (6 + n); "own" for the bar's own slots.
PagedBars.STATES = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; own"
PagedBars.FIRST_ROW, PagedBars.LAST_ROW = 7, 10
PagedBars.BOX = 20 -- the checkbox
PagedBars.GAP = 3  -- between it and the bar's first button

-- Run by the game's secure code: the row changed. Each of the twelve buttons holds its page, none on the bar's own.
PagedBars.ON_ROW = [[
    local page = tonumber(newstate)
    for index = 1, 12 do
        self:GetFrameRef("button" .. index):SetAttribute("actionpage", page)
    end
]]

local made = {}    -- [entry of BARS] = { header, box }, made once and out of a fight
local held = {}    -- [entry of BARS] = true: it is paged now

-- Whether this character's class has rows for its stances or forms.
function PagedBars.For()
    return PagedBars.CLASSES[ns.class] == true
end

-- Whether a bar is one of these for this character: not a druid's Bar 6, the form bar's.
local function Ours(entry)
    return not (entry.number == 6 and ns.FormBar.For())
end

-- Whether this character has that bar paged (ticked).
function PagedBars.On(number)
    local kept = ns.char and ns.char.pagedBars
    return type(kept) == "table" and kept[number] == true
end

local function Find(number)
    for _, entry in ipairs(PagedBars.BARS) do
        if entry.number == number then return entry end
    end
end

-- Beside the bar's first button, wherever Edit Mode puts the bar: left of a wide bar, above a tall one.
local function Place(entry)
    local box, first, bar = made[entry].box, rawget(_G, entry.prefix .. "1"), rawget(_G, entry.bar)
    box:ClearAllPoints()
    local width, height = Core.Plain(bar:GetWidth()) or 0, Core.Plain(bar:GetHeight()) or 0
    if height > width then
        box:SetPoint("BOTTOM", first, "TOP", 0, PagedBars.GAP)
    else
        box:SetPoint("RIGHT", first, "LEFT", -PagedBars.GAP, 0)
    end
end

local function Ticked(box)
    local entry = box.entry
    local on = box:GetChecked() and true or false
    Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    if InCombatLockdown() then ns.Print(ns.TEXT.pagedFight:format(entry.number)) end
    PagedBars.Set(entry.number, on)
end

local Resized = ns.Guard(function() PagedBars.Apply() end)

-- The header with the bar's twelve buttons and the checkbox; false where the game has them no more.
local function Make(entry)
    local bar = rawget(_G, entry.bar)
    if type(bar) ~= "table" then return false end
    local header = ns.Bar1.Header(entry.prefix, PagedBars.ON_ROW, "row")
    if not header then return false end
    local box = CreateFrame("CheckButton", nil, bar, "UICheckButtonTemplate")
    box.ignoreInLayout = true -- the bar sizes itself round its children: not round this one (the game's own page number does the same)
    box.entry = entry
    box:SetSize(PagedBars.BOX, PagedBars.BOX)
    box:SetFrameLevel(rawget(_G, entry.prefix .. "1"):GetFrameLevel() + 2)
    box:SetScript("OnClick", ns.Guard(Ticked))
    Core.Tip(box, ns.TEXT.pagedText, ns.TEXT.pagedTip:format(entry.number))
    made[entry] = { header = header, box = box }
    -- The game lays out a bar's rows after the login and in Edit Mode: placed again beside it then, out of a fight.
    bar:HookScript("OnSizeChanged", Resized)
    return true
end

local function Apply()
    local class = not ns.off and PagedBars.For()
    for _, entry in ipairs(PagedBars.BARS) do
        local mine = class and Ours(entry)
        if mine and not made[entry] then mine = Make(entry) end
        local parts = made[entry]
        if parts then
            parts.box:SetShown(mine and true or false)
            if mine then
                Place(entry)
                parts.box:SetChecked(PagedBars.On(entry.number))
            end
            local want = mine and PagedBars.On(entry.number)
            if want and not held[entry] then
                RegisterStateDriver(parts.header, "row", PagedBars.STATES)
                held[entry] = true
            elseif held[entry] and not want then
                UnregisterStateDriver(parts.header, "row")
                parts.header:SetAttribute("state-row", "own")
                held[entry] = nil
            end
        end
    end
end

-- As the character has them and the module not stood down; in a fight, once it is over.
function PagedBars.Apply()
    Core.AfterCombat("Abilities: paged bars", Apply)
end

-- A bar paged (on) or not, for this character; in a fight it changes once it is over.
function PagedBars.Set(number, on)
    if not ns.char then return end
    local kept = type(ns.char.pagedBars) == "table" and ns.char.pagedBars or {}
    kept[number] = on and true or nil
    ns.char.pagedBars = next(kept) and kept or nil
    PagedBars.Apply()
end

-- Whether a slot is on a row a paged bar can show now: such rows are seen though Bar 1 keeps its page (Bar1.Unseen).
function PagedBars.Shows(slot)
    if type(slot) ~= "number" or not next(held) then return false end
    return slot > (PagedBars.FIRST_ROW - 1) * ns.NUM_BUTTONS and slot <= PagedBars.LAST_ROW * ns.NUM_BUTTONS
end

-- Whether a bar is paged now (its number).
function PagedBars.Held(number)
    local entry = Find(number)
    return entry ~= nil and held[entry] == true
end

-- For the test: a bar's checkbox, once made.
function PagedBars.Box(number)
    local entry = Find(number)
    return entry and made[entry] and made[entry].box
end

-- Edit Mode may have turned a bar or moved its buttons: the checkboxes beside them again.
Core.EditMode.Watch(ns.Guard(function() PagedBars.Apply() end))
