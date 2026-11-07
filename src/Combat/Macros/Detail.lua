local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Detail
--  The chosen step's settings, under the list: its kind, what it does, who it is
--  cast on, how often it comes up, when it runs, and the line the game gets.
--  Only what the step's kind uses shows. A spell's name has a + beside it, the
--  spell window (Spells.lua), and while it is typed in the best spells fly out
--  over the steps (the aura search's box).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Detail = {}
Macros.Detail = Detail

Detail.HEIGHT = 196
Detail.WORD = 74    -- the width of a setting's word
Detail.GAP = 4
Detail.BESIDE = 90  -- of the panel's width, what is not a line to fill in
Detail.CHOOSE = 30  -- of a name's line, the room of the + beside it
Detail.FINDS = 10   -- spells flying out over the steps, titles and finds, at most

local panel, kindMenu, unitMenu, unitWord, oftenMenu, oftenWord, what, whatWord, area, letters, insert, plus
local whenWord, writes, writesWord, choose, finder
local chips = {}
local macro, step
local field = 540   -- the width of a line to fill in

local function Word(text, tip)
    local word = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    word:SetWidth(Detail.WORD)
    word:SetJustifyH("LEFT")
    word:SetText(text)
    if tip then
        local spot = CreateFrame("Frame", nil, panel)
        spot:SetAllPoints(word)
        spot:EnableMouse(true)
        Core.Tip(spot, text, tip)
        word.spot = spot
    end
    return word
end

local function Menu(width, build)
    local menu = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    menu:SetWidth(width)
    menu:SetupMenu(ns.Guard(function(_, root) if step then build(root) end end))
    return menu
end

-- A radio of a dropdown that sets a field of the step.
local function Radio(root, text, key, value, tip)
    local radio = root:CreateRadio(text, ns.Guard(function() return step ~= nil and step[key] == value end),
                                   ns.Guard(function()
                                       step[key] = value
                                       Macros.Editor.Changed()
                                   end))
    if tip then radio:SetTooltip(ns.Guard(function(tooltip) GameTooltip_AddNormalLine(tooltip, tip) end)) end
end

local function Kinds(root)
    for _, kind in ipairs({ "spell", "item", "text" }) do
        root:CreateRadio(Macros.TEXT.kinds[kind], ns.Guard(function() return step ~= nil and step.kind == kind end),
                         ns.Guard(function()
                             if step.kind ~= kind then step.id, step.units = nil, {} end
                             step.kind = kind
                             Macros.Editor.Changed()
                         end))
    end
end

-- Who a step is cast on in words, in order ("Under the mouse, then Your target"); nil for the usual, your target.
function Detail.UnitsWords(target)
    local words = {}
    for _, unit in ipairs(Macros.Write.Units(target)) do
        for _, each in ipairs(Macros.TEXT.targets) do
            if each[1] == unit then words[#words + 1] = each[2] end
        end
    end
    return words[1] and table.concat(words, Macros.TEXT.unitsThen) or nil
end

-- A unit's place in the step's order; nil where it is not chosen.
local function Place(value)
    for index, unit in ipairs(Macros.Write.Units(step)) do
        if unit == value then return index end
    end
    return nil
end

-- Chosen: it goes after those chosen; chosen again: out, and those after it move up.
local function Toggle(value)
    local units = {}
    for _, unit in ipairs(Macros.Write.Units(step)) do units[#units + 1] = unit end
    local at = Place(value)
    if at then table.remove(units, at) else units[#units + 1] = value end
    step.units, step.unit = units, nil
    Macros.Editor.Changed()
end

-- A chosen line shows its place in the order where the game's line shows its circle (frame.leftTexture1, the
-- selected tick over it leftTexture2: MenuVariants.CreateRadio, both games). Asked as the line is drawn: a click
-- redraws the open menu's lines without making them anew.
local function Number(frame, at)
    local circle = rawget(frame, "leftTexture1")
    if not (at and circle and frame.AttachFontString) then return end
    circle:SetAlpha(0)
    local tick = rawget(frame, "leftTexture2")
    if tick then tick:SetAlpha(0) end
    local number = frame:AttachFontString()
    number:SetFontObject("GameFontNormal")
    number:SetPoint("CENTER", circle, "CENTER", 0, 0)
    number:SetText(at)
end

-- Cast on: several, in order (Saneroki, 2026-11-07): each line a radio of the game's that stays open on a click, a
-- chosen one numbered by its place.
local function Units(root)
    local refresh = rawget(_G, "MenuResponse") and MenuResponse.Refresh
    for _, target in ipairs(Macros.TEXT.targets) do
        local value = target[1]
        local radio = root:CreateRadio(target[2], ns.Guard(function() return step ~= nil and Place(value) ~= nil end),
                                       ns.Guard(function() Toggle(value) end))
        if refresh then radio:SetResponse(refresh) end
        radio:AddInitializer(ns.Guard(function(frame) Number(frame, Place(value)) end))
        radio:SetTooltip(ns.Guard(function(tooltip) GameTooltip_AddNormalLine(tooltip, target[3]) end))
    end
end

local function Oftens(root)
    for count = 1, Macros.Book.MOST_OFTEN do Radio(root, Macros.TEXT.oftenWord:format(count), "often", count) end
end

-- What was typed, or dropped on the box.
local function Typed(box, typed)
    if not typed or not step then return end
    step.what = box:GetText()
    step.id = nil
    Macros.Editor.Changed()
end

-- A spell chosen in the spell window or under the box: the step's, and its name in the box.
local function Chosen(entry)
    if not (step and step.kind == "spell" and entry and entry.name) then return end
    step.what, step.id = entry.name, entry.id
    what:SetText(entry.name)
    what:ClearFocus()
    Macros.Editor.Changed()
end

-- What flies out under the name's box: spells, for a spell's step only.
local function Find(text, done)
    if not (step and step.kind == "spell") then return done(nil) end
    return Macros.Spells.Find(text, done)
end

local function Dropped()
    local kind, first, _, spell = GetCursorInfo()
    if not step then return end
    if kind == "spell" and spell and step.kind == "spell" then
        step.what, step.id = Core.Ask(C_Spell.GetSpellName, spell) or step.what, spell
    elseif kind == "item" and step.kind == "item" then
        step.what, step.id = Core.Ask(C_Item.GetItemNameByID, first) or step.what, first
    else
        return
    end
    ClearCursor()
    what:SetText(step.what)
    Macros.Editor.Changed()
end

local function Added(word, value)
    if not step then return end
    if Macros.Conditions.OURS[word] then
        for _, condition in ipairs(step.when) do
            if condition.word == word then return end -- one of ours is there once
        end
    end
    step.when[#step.when + 1] = { word = word, value = value }
    Macros.Editor.Changed()
end

-- A chip: click for its opposite, right click to take it away. One of Sane Macros' own has no opposite.
local function ChipClick(chip, mouse)
    local condition = step.when[chip.index]
    if mouse == "RightButton" then
        table.remove(step.when, chip.index)
    elseif Macros.Conditions.OURS[condition.word] then
        return
    else
        condition.no = not condition.no or nil
    end
    Core.HideTip()
    Macros.Editor.Changed()
end

local function ChipEnter(chip)
    local condition = step.when[chip.index]
    local words, tip = Macros.Conditions.Words(condition)
    local how = Macros.Conditions.OURS[condition.word] and Macros.TEXT.whenTake or Macros.TEXT.whenFlip
    Core.ShowTip(chip, words, (tip and tip .. "\n" or "") .. how)
end

local function Chip(index)
    local chip = Macros.Button(panel, "", 60, 20)
    chip.index = index
    chip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    chip:SetScript("OnClick", ns.Guard(ChipClick))
    chip:HookScript("OnEnter", ns.Guard(ChipEnter))
    chip:HookScript("OnLeave", ns.Guard(Core.HideTip))
    chips[index] = chip
    return chip
end

-- The conditions, in lines beside their word, the + after them.
local function Chips()
    local width = field - 34
    local x, y = 0, 0
    for index, condition in ipairs(step.when) do
        local chip = chips[index] or Chip(index)
        chip:SetText((Macros.Conditions.Words(condition)))
        local wide = chip.label:GetStringWidth() + 18
        if x > 0 and x + wide > width then x, y = 0, y - 22 end
        chip:SetWidth(wide)
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", whenWord, "TOPRIGHT", x, y + 3)
        chip:Show()
        x = x + wide + Detail.GAP
    end
    for index = #step.when + 1, #chips do chips[index]:Hide() end
    plus:ClearAllPoints()
    plus:SetPoint("TOPLEFT", whenWord, "TOPRIGHT", x, y + 3)
end

function Detail.Fill(chosenMacro, chosenStep)
    macro, step = chosenMacro, chosenStep
    panel:SetShown(step ~= nil)
    if not step then return end
    local text = step.kind == "text"
    kindMenu:GenerateMenu()
    -- Open, it stays as it is: its lines ask the step as they are drawn, and a new one would not be the one shown.
    if not (unitMenu.IsMenuOpen and unitMenu:IsMenuOpen()) then unitMenu:GenerateMenu() end
    unitMenu:OverrideText(Detail.UnitsWords(step) or Macros.TEXT.targets[1][2])
    oftenMenu:GenerateMenu()
    unitMenu:SetShown(not text)
    unitWord:SetShown(not text)
    oftenMenu:SetShown(not macro.top)
    oftenWord:SetShown(not macro.top)
    what:SetShown(not text)
    whatWord:SetShown(not text)
    choose:SetShown(step.kind == "spell")
    finder:Show(nil)
    area:SetShown(text)
    letters:SetShown(text)
    insert:SetShown(text)
    writes:SetShown(not text)
    writesWord:SetShown(not text)
    if text then
        if not area.EditBox:HasFocus() then area.EditBox:SetText(step.what) end
        letters:SetText(Macros.TEXT.letters:format(#step.what))
    else
        whatWord:SetText(Macros.TEXT[step.kind])
        if not what:HasFocus() then what:SetText(step.what) end
        writes:SetText(Macros.Write.Line(step, macro.top))
    end
    Chips()
end

-- For the test: the spell's name box, the + beside it, the fly-out's search box.
function Detail.Parts()
    return { what = what, choose = choose, finder = finder, units = unitMenu }
end

-- The panel is that wide now.
function Detail.Width(wide)
    field = wide - Detail.BESIDE
    what:SetWidth(field - Detail.CHOOSE)
    area:SetWidth(field + 40)
    area.EditBox:SetWidth(field + 22)
    writes:SetWidth(field)
end

function Detail.Build(parent)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    local kindWord = Word(Macros.TEXT.kind, Macros.TEXT.kindTip)
    kindWord:SetPoint("TOPLEFT", 0, -6)
    kindWord:SetWidth(40)
    kindMenu = Menu(100, Kinds)
    kindMenu:SetPoint("LEFT", kindWord, "RIGHT", 0, 0)
    unitWord = Word(Macros.TEXT.target, Macros.TEXT.targetTip)
    unitWord:SetPoint("LEFT", kindMenu, "RIGHT", 10, 0)
    unitWord:SetWidth(50)
    unitMenu = Menu(130, Units)
    unitMenu:SetPoint("LEFT", unitWord, "RIGHT", 0, 0)
    oftenWord = Word(Macros.TEXT.often, Macros.TEXT.oftenTip)
    oftenWord:SetPoint("LEFT", unitMenu, "RIGHT", 10, 0)
    oftenWord:SetWidth(60)
    oftenMenu = Menu(90, Oftens)
    oftenMenu:SetPoint("LEFT", oftenWord, "RIGHT", 0, 0)

    whatWord = Word(Macros.TEXT.spell, Macros.TEXT.spellTip)
    whatWord:SetPoint("TOPLEFT", 0, -40)
    what = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    what:SetSize(field - Detail.CHOOSE, 22)
    what:SetPoint("LEFT", whatWord, "RIGHT", 6, 0)
    what:SetAutoFocus(false)
    what:SetScript("OnTextChanged", ns.Guard(Typed))
    what:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    what:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    what:SetScript("OnReceiveDrag", ns.Guard(Dropped))
    what:HookScript("OnMouseUp", ns.Guard(Dropped))
    choose = Macros.Button(panel, "+", 24, 22)
    choose:SetPoint("LEFT", what, "RIGHT", 6, 0)
    choose:SetScript("OnClick", ns.Guard(function()
        Core.HideTip()
        local chosen = step
        Macros.Spells.Open(function(entry) if step == chosen then Chosen(entry) end end)
    end))
    Core.Tip(choose, Macros.TEXT.spellPick, Macros.TEXT.spellPickTip)
    finder = ns.AuraSearch.Box(panel, 0, 0, { box = what, find = Find, pick = Chosen, width = 380, up = true,
                                              lines = Detail.FINDS, label = "macros" })

    area = CreateFrame("ScrollFrame", nil, panel, "InputScrollFrameTemplate")
    area:SetPoint("TOPLEFT", 4, -36)
    area:SetSize(field + 40, 72)
    area.hideCharCount = true
    if area.CharCount then area.CharCount:Hide() end
    area.EditBox:SetMaxLetters(0)
    area.EditBox:SetWidth(field + 22)
    area.EditBox:HookScript("OnTextChanged", ns.Guard(Typed))
    area.EditBox:HookScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    Core.Tip(area.EditBox, Macros.TEXT.text, Macros.TEXT.textTip)
    insert = Macros.Button(panel, "+", 24, 22)
    insert:SetPoint("TOPLEFT", area, "TOPRIGHT", 10, 2)
    insert:SetScript("OnClick", ns.Guard(function(self)
        Core.HideTip()
        Macros.Picker.Open(self, function(word, value)
            area.EditBox:SetFocus()
            area.EditBox:Insert("[" .. word .. (value and ":" .. value or "") .. "] ")
        end)
    end))
    Core.Tip(insert, Macros.TEXT.whenAdd, Macros.TEXT.textTip)
    letters = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    letters:SetPoint("TOPLEFT", insert, "BOTTOMLEFT", 0, -6)

    whenWord = Word(Macros.TEXT.when, Macros.TEXT.whenTip)
    whenWord:SetPoint("TOPLEFT", 0, -118)
    plus = Macros.Button(panel, "+", 24, 20)
    plus:SetScript("OnClick", ns.Guard(function(self)
        Core.HideTip()
        Macros.Picker.Open(self, Added, step ~= nil and step.kind ~= "text")
    end))
    Core.Tip(plus, Macros.TEXT.whenAdd, Macros.TEXT.whenTip)

    writesWord = Word(Macros.TEXT.writes, Macros.TEXT.writesTip)
    writesWord:SetPoint("TOPLEFT", 0, -172)
    writes = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    writes:SetPoint("LEFT", writesWord, "RIGHT", 6, 0)
    writes:SetWidth(field)
    writes:SetJustifyH("LEFT")
    writes:SetWordWrap(false)
end
