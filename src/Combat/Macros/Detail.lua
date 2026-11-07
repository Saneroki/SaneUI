local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Detail
--  The chosen step's settings, under the list: its kind, what it does, who it is
--  cast on, how often it comes up, when it runs, and the line the game gets.
--  Only what the step's kind uses shows.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Detail = {}
Macros.Detail = Detail

Detail.HEIGHT = 196
Detail.WORD = 74    -- the width of a setting's word
Detail.GAP = 4
Detail.BESIDE = 90  -- of the panel's width, what is not a line to fill in

local panel, kindMenu, unitMenu, unitWord, oftenMenu, oftenWord, what, whatWord, area, letters, insert, plus
local whenWord, writes, writesWord
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
                             if step.kind ~= kind then step.id, step.unit = nil, nil end
                             step.kind = kind
                             Macros.Editor.Changed()
                         end))
    end
end

local function Units(root)
    for _, target in ipairs(Macros.TEXT.targets) do
        Radio(root, target[2], "unit", target[1] ~= "" and target[1] or nil, target[3])
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
    unitMenu:GenerateMenu()
    oftenMenu:GenerateMenu()
    unitMenu:SetShown(not text)
    unitWord:SetShown(not text)
    oftenMenu:SetShown(not macro.top)
    oftenWord:SetShown(not macro.top)
    what:SetShown(not text)
    whatWord:SetShown(not text)
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

-- The panel is that wide now.
function Detail.Width(wide)
    field = wide - Detail.BESIDE
    what:SetWidth(field)
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
    what:SetSize(field, 22)
    what:SetPoint("LEFT", whatWord, "RIGHT", 6, 0)
    what:SetAutoFocus(false)
    what:SetScript("OnTextChanged", ns.Guard(Typed))
    what:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    what:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    what:SetScript("OnReceiveDrag", ns.Guard(Dropped))
    what:HookScript("OnMouseUp", ns.Guard(Dropped))

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
