local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Form bar
--  A druid's Action Bar 6 swaps with the form (Saneroki, 2026-11-06): the same
--  keys cast a bear's spells in Bear Form and a cat's in Cat Form. Bar 6 as a
--  human and in Moonkin Form, Bar 9 in Bear Form, Bar 10 in Cat, Aquatic and
--  Travel Form (Prowl included). Bars 9 and 10 are rows of slots of their own
--  (97-108, 109-120), on none of Bar 1's six pages and of no other bar: in the
--  game the rows of Bar 1 in Bear Form and Moonkin Form, free because Bar 1
--  keeps its page here (Bar1.lua).
--
--  Beside the bar, as Bar 1 has its page number and arrows: the number of the
--  bar it shows, an arrow up and one down that turn it through 6, 9 and 10
--  without a change of form, and between them a checkbox, whether it swaps with
--  the form (ticked at first). The checkbox is the character's own, kept with
--  its reservations, not one of the profile, which another character may share.
--
--  A button asks for its own "actionpage" before its bar's, so each of the
--  twelve holds the row's page, and none on the bar's own. The buttons and
--  their keys stay the game's own, and the game's secure code turns them, the
--  arrows' clicks included, so it works in a fight; the checkbox waits for its
--  end. Until then the swapping goes on as it was. The rows of Bar 1's other
--  forms (Cat Form's, Prowl's) stay out of sight.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local FormBar = {}
ns.FormBar = FormBar

local BAR, PREFIX = "MultiBar5", "MultiBar5Button"
FormBar.NUMBER = 6 -- the bar's own number

-- The row for each form as a page, "own" for the bar's own slots: Bear Form's 9, Moonkin Form the bar's own, every
-- other form 10.
FormBar.STATES = "[bonusbar:3] 9; [bonusbar:4] own; [form] 10; own"
-- The rows the arrows turn through, in order, as the state says them.
FormBar.ROWS = { "own", "9", "10" }
FormBar.ARROW_SIZE = { 17, 14 } -- the game's page arrows of Bar 1
FormBar.BOX = 20                -- the checkbox

-- Run by the game's secure code: the form changed. The bar takes the form's row while it swaps with it.
FormBar.ON_FORM = [[
    if self:GetAttribute("swap") then self:SetAttribute("state-row", newstate) end
]]

-- The row shown changed: each of the twelve buttons holds its page, none on the bar's own.
FormBar.ON_ROW = [[
    local page = tonumber(newstate)
    for index = 1, 12 do
        self:GetFrameRef("button" .. index):SetAttribute("actionpage", page)
    end
]]

-- An arrow's click: the next row up (step 1) or down (step -1), round again past the last.
FormBar.ARROW = [[
    local header = self:GetFrameRef("header")
    local count = header:GetAttribute("rows")
    local now = tostring(header:GetAttribute("state-row") or "own")
    local at = 1
    for index = 1, count do
        if header:GetAttribute("row" .. index) == now then at = index end
    end
    at = at + self:GetAttribute("step")
    if at > count then at = 1 elseif at < 1 then at = count end
    header:SetAttribute("state-row", header:GetAttribute("row" .. at))
]]

local header       -- the frame of the game's secure code that turns the bar, made once and out of a fight
local pager        -- the number, the arrows and the checkbox beside the bar
local held = false -- the bar turns now

-- Whether this character has the form bar: a druid's.
function FormBar.For()
    return ns.class == "DRUID"
end

-- Whether its bar swaps with its form: ticked at first.
function FormBar.On()
    return ns.char ~= nil and ns.char.formBar ~= false
end

-- The bar's number for a row as the state says it.
local function Number(row)
    return tonumber(row) or FormBar.NUMBER
end

local function Shown(_, name, value)
    if name == "state-row" and pager then pager.number:SetText(Number(value)) end
end

local function Ticked(box)
    if InCombatLockdown() then
        box:SetChecked(FormBar.On())
        return ns.Print(ns.TEXT.formBarFight)
    end
    Core.Sound(box:GetChecked() and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    FormBar.Set(box:GetChecked())
end

local Turned = ns.Guard(function() Core.Sound("U_CHAT_SCROLL_BUTTON") end)

local function Arrow(step, atlas, title)
    local arrow = CreateFrame("Button", nil, pager, "SecureHandlerClickTemplate")
    arrow:SetSize(FormBar.ARROW_SIZE[1], FormBar.ARROW_SIZE[2])
    arrow:SetNormalAtlas(atlas .. "-up")
    arrow:SetPushedAtlas(atlas .. "-down")
    arrow:SetDisabledAtlas(atlas .. "-disabled")
    arrow:SetHighlightAtlas(atlas .. "-mouseover")
    arrow:RegisterForClicks("AnyUp")
    arrow:SetFrameRef("header", header)
    arrow:SetAttribute("step", step)
    arrow:SetAttribute("_onclick", FormBar.ARROW)
    arrow:HookScript("OnClick", Turned)
    Core.Tip(arrow, title, ns.TEXT.formBarArrowTip)
    return arrow
end

-- Beside the bar's first button, wherever Edit Mode puts the bar; in it, so it rests and shows with it. Out of a fight.
local function Pager()
    local bar, first = rawget(_G, BAR), rawget(_G, PREFIX .. "1")
    local frame = CreateFrame("Frame", nil, bar)
    pager = frame
    frame.ignoreInLayout = true -- the bar sizes itself round its children: not round this one (the game's own page number does the same)
    frame:SetSize(FormBar.BOX + 18, FormBar.BOX + 2 * FormBar.ARROW_SIZE[2] - 2)
    frame:SetPoint("RIGHT", first, "LEFT", -3, 0)
    frame:SetFrameLevel(first:GetFrameLevel() + 2)
    local box = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    box:SetSize(FormBar.BOX, FormBar.BOX)
    box:SetPoint("RIGHT")
    box:SetScript("OnClick", ns.Guard(Ticked))
    Core.Tip(box, ns.TEXT.formBarText, ns.TEXT.formBarTip)
    frame.box = box
    frame.up = Arrow(1, "ui-hud-actionbar-pageuparrow", ns.TEXT.formBarUp)
    frame.up:SetPoint("BOTTOM", box, "TOP", 0, -1)
    frame.down = Arrow(-1, "ui-hud-actionbar-pagedownarrow", ns.TEXT.formBarDown)
    frame.down:SetPoint("TOP", box, "BOTTOM", 0, 1)
    frame.number = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.number:SetPoint("RIGHT", box, "LEFT", 0, 0)
    frame.number:SetText(FormBar.NUMBER)
    return frame
end

-- The header with the bar's twelve buttons and the pager; false where the game has them no more: the bar stays the game's.
local function Make()
    if not rawget(_G, BAR) then return false end
    header = ns.Bar1.Header(PREFIX, FormBar.ON_ROW, "row")
    if not header then return false end
    header:SetAttribute("_onstate-form", FormBar.ON_FORM)
    header:SetAttribute("rows", #FormBar.ROWS)
    for index, row in ipairs(FormBar.ROWS) do header:SetAttribute("row" .. index, row) end
    header:HookScript("OnAttributeChanged", ns.Guard(Shown))
    Pager()
    return true
end

local function Apply()
    local want = not ns.off and FormBar.For()
    if want and not held then
        if not header and not Make() then return end
        header:SetAttribute("swap", FormBar.On())
        RegisterStateDriver(header, "form", FormBar.STATES)
        pager:Show()
        held = true
    elseif held and not want then
        UnregisterStateDriver(header, "form")
        -- The game's driver sets a state only when it changes: forgotten, so a driver set again sets it again.
        header:SetAttribute("state-form", nil)
        header:SetAttribute("state-row", "own")
        pager:Hide()
        held = false
    end
    if not held then return end
    local swap = FormBar.On()
    pager.box:SetChecked(swap)
    if header:GetAttribute("swap") == swap then return end
    header:SetAttribute("swap", swap)
    if swap then header:SetAttribute("state-row", header:GetAttribute("state-form") or "own") end
end

-- A druid's and the module not stood down; the checkbox as the character has it. In a fight, once it is over.
function FormBar.Apply()
    Core.AfterCombat("Abilities: form bar", Apply)
end

-- Whether the bar swaps with the form; not ticked, it stays on the row its arrows show.
function FormBar.Set(on)
    if on then ns.char.formBar = nil else ns.char.formBar = false end
    FormBar.Apply()
end

-- Whether the bar turns now: Bars 9 and 10 are on show then.
function FormBar.Held()
    return held
end

-- The number of the bar a slot of Bar 9 or 10 is on while the bar turns; nil for any other slot.
function FormBar.Number(slot)
    if not held or type(slot) ~= "number" then return nil end
    for _, row in ipairs(FormBar.ROWS) do
        local page = tonumber(row)
        if page and slot > (page - 1) * ns.NUM_BUTTONS and slot <= page * ns.NUM_BUTTONS then return page end
    end
    return nil
end

-- For the test: the pager beside the bar.
function FormBar.Pager()
    return pager
end
