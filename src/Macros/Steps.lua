local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Steps
--  A macro's steps in a list, one line each: its number, picture, what it does
--  and when, how often it comes up, a mark if something is wrong, on or off,
--  delete. A click chooses a line (Detail.lua shows it), a drag moves it, and a
--  spell, an item or a game's macro dropped on the list becomes a step.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Steps = {}
ns.Steps = Steps

Steps.LINE = 36
Steps.ICON = 28
Steps.WIDTH = 610  -- the list's width: the window's right side, less its scroll bar
Steps.WORDS = 430  -- of a line, the width of its words

local box, child, empty, drop
local rows = {}
local shown        -- the macro shown
local lifted       -- the line being dragged

-- The place the cursor stands at in the list, as a line's number.
local function Under()
    local _, y = GetCursorPosition()
    local top = child:GetTop()
    if not top then return nil end
    local line = math.floor((top - y / child:GetEffectiveScale()) / Steps.LINE) + 1
    return math.max(1, math.min(line, #shown.steps))
end

local function Moving()
    local line = Under()
    if line then drop:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(line - 1) * Steps.LINE) end
end

local function Lift(row)
    lifted = row.index
    drop:Show()
    row:SetScript("OnUpdate", ns.Guard(Moving))
end

local function Let(row)
    row:SetScript("OnUpdate", nil)
    drop:Hide()
    local line = lifted and Under()
    if line and ns.Book.Move(shown, lifted, line) then ns.Editor.Changed() end
    lifted = nil
end

-- What the cursor holds, as a step.
local function FromCursor()
    local kind, first, _, spell = GetCursorInfo()
    if kind == "spell" then
        local name = spell and rawget(_G, "C_Spell") and Core.Ask(C_Spell.GetSpellName, spell)
        return name and ns.Book.Step("spell", name, spell)
    elseif kind == "item" then
        local name = rawget(_G, "C_Item") and Core.Ask(C_Item.GetItemNameByID, first)
        return ns.Book.Step("item", name or "", first)
    elseif kind == "macro" then
        local _, _, body = Core.Ask(GetMacroInfo, first)
        return ns.Book.Step("text", body or "")
    end
    return nil
end

Steps.FromCursor = FromCursor

-- Something let go on the list: a step at the end, or after the line it fell on.
local function Drop(row)
    local step = shown and FromCursor()
    if not step then return end
    ClearCursor()
    ns.Editor.AddStep(step, row and row.index)
end

local function Row(index)
    local row = CreateFrame("Button", nil, child)
    row.index = index
    row:SetHeight(Steps.LINE)
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Steps.LINE)
    row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    row:EnableMouse(true)
    row:RegisterForDrag("LeftButton")
    row.mark = row:CreateTexture(nil, "BACKGROUND")
    row.mark:SetAllPoints()
    row.mark:SetColorTexture(1, 1, 1, 0.1)
    row.number = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.number:SetPoint("LEFT", 4, 0)
    row.number:SetWidth(18)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Steps.ICON, Steps.ICON)
    row.icon:SetPoint("LEFT", 24, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.take = CreateFrame("Button", nil, row, "UIPanelCloseButtonNoScripts")
    row.take:SetSize(22, 22)
    row.take:SetPoint("RIGHT", -2, 0)
    row.take:SetScript("OnClick", ns.Guard(function() ns.Editor.TakeStep(row.index) end))
    Core.Tip(row.take, ns.TEXT.stepTake)
    row.on = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.on:SetSize(24, 24)
    row.on:SetPoint("RIGHT", row.take, "LEFT", -2, 0)
    row.on:SetScript("OnClick", ns.Guard(function(self)
        shown.steps[row.index].off = not self:GetChecked() or nil
        ns.Editor.Changed()
    end))
    Core.Tip(row.on, ns.TEXT.stepOn, ns.TEXT.stepOnTip)
    row.often = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.often:SetPoint("RIGHT", row.on, "LEFT", -6, 0)
    row.flag = CreateFrame("Button", nil, row)
    row.flag:SetSize(16, 16)
    row.flag:SetPoint("RIGHT", row.often, "LEFT", -6, 0)
    row.flag.text = row.flag:CreateFontString(nil, "OVERLAY", "GameFontRedLarge")
    row.flag.text:SetPoint("CENTER")
    row.flag.text:SetText("!")
    row.flag:SetScript("OnEnter", ns.Guard(function(self) Core.ShowTip(self, ns.TEXT.problems:format(#self.words), table.concat(self.words, "\n")) end))
    row.flag:SetScript("OnLeave", ns.Guard(Core.HideTip))

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetWidth(Steps.WORDS)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.when = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.when:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.when:SetWidth(Steps.WORDS)
    row.when:SetJustifyH("LEFT")
    row.when:SetWordWrap(false)

    row:SetScript("OnClick", ns.Guard(function() ns.Editor.ChooseStep(shown.steps[row.index]) end))
    row:SetScript("OnDragStart", ns.Guard(Lift))
    row:SetScript("OnDragStop", ns.Guard(Let))
    row:SetScript("OnReceiveDrag", ns.Guard(Drop))
    Core.Tip(row, nil, ns.TEXT.stepDrag)
    rows[index] = row
    return row
end

-- A step in words: what it does, the first line of macro text.
local function Name(step)
    if step.kind == "text" then return step.what:match("^%s*([^\n]+)") or ns.TEXT.stepEmpty end
    return step.what ~= "" and step.what or ns.TEXT.stepEmpty
end

-- When it runs, and on whom, in plain words.
local function When(step)
    local words = {}
    for _, target in ipairs(ns.TEXT.targets) do
        if step.unit and target[1] == step.unit then words[1] = target[2] end
    end
    for _, condition in ipairs(step.when) do words[#words + 1] = (ns.Conditions.Words(condition)) end
    return table.concat(words, ", ")
end

function Steps.Fill(macro, chosen, found)
    shown = macro
    local steps = macro and macro.steps or {}
    for index, step in ipairs(steps) do
        local row = rows[index] or Row(index)
        row.mark:SetShown(step == chosen)
        row.number:SetText(index)
        row.icon:SetTexture(ns.Press.Picture(step))
        row.icon:SetDesaturated(step.off and true or false)
        row.name:SetText(Name(step))
        row.name:SetAlpha(step.off and 0.5 or 1)
        row.when:SetText(When(step))
        row.often:SetText(not macro.top and step.often > 1 and step.often .. "×" or "")
        row.on:SetChecked(not step.off)
        local words = found and found[step]
        row.flag.words = words
        row.flag:SetShown(words ~= nil)
        row:Show()
    end
    for index = #steps + 1, #rows do rows[index]:Hide() end
    empty:SetShown(macro ~= nil and not steps[1])
    child:SetHeight(math.max(#steps * Steps.LINE, 1))
end

function Steps.Build(parent)
    box = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    box:SetPoint("TOPLEFT")
    box:SetPoint("BOTTOMRIGHT", -24, 0)
    child = CreateFrame("Frame", nil, box)
    child:SetSize(Steps.WIDTH, 1)
    box:SetScrollChild(child)
    empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOPLEFT", 8, -10)
    empty:SetWidth(Steps.WIDTH - 16)
    empty:SetJustifyH("LEFT")
    empty:SetText(ns.TEXT.stepsNone)
    drop = child:CreateTexture(nil, "OVERLAY")
    drop:SetHeight(2)
    drop:SetColorTexture(1, 0.82, 0, 1)
    drop:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    drop:Hide()
    -- Let go on the list's empty part: a step at the end.
    box:EnableMouse(true)
    box:SetScript("OnReceiveDrag", ns.Guard(function() Drop(nil) end))
    box:SetScript("OnMouseUp", ns.Guard(function() Drop(nil) end))
end
