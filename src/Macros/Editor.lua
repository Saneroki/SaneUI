local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Editor
--  The window Sane Macros, in the game's macro window's stead (/macro, the game
--  menu, /sane macros, its key): on the left your macros, on the right the one
--  chosen: its name, key and bar button, its order, its steps, and under them the
--  chosen step's settings. Every change counts at once; in a fight it waits for
--  the fight's end. The frame is made at login, to stand for the game's window;
--  what it holds, when it is first shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Editor = {}
ns.Editor = Editor

Editor.WIDTH, Editor.HEIGHT = 880, 640
Editor.INSET = 12
Editor.LIST = 210    -- the macros' list
Editor.LINE = 24     -- a macro's line
Editor.ICON = 36     -- the macro's picture
Editor.DRAG = "LeftButton"

local frame, window, built
local list, child, empty, right, picture, name, keyButton, placeButton, orderMenu, fresh, freshWord, flags, copy, delete
local catcher
local lines = {}
local chosen     -- the macro shown
local step       -- the step chosen

local Fill

local function Index(wanted)
    for index, candidate in ipairs(chosen and chosen.steps or {}) do
        if candidate == wanted then return index end
    end
    return nil
end

-- A change to the macro chosen: it counts now, or at the fight's end, and shows.
function Editor.Changed()
    if chosen then ns.Press.Update(chosen) end
    Fill()
end

function Editor.Choose(macro)
    chosen = macro
    step = macro and macro.steps[1] or nil
    Fill()
end

function Editor.ChooseStep(wanted)
    step = wanted
    Fill()
end

-- A step after the line given, else after the one chosen, else at the end.
function Editor.AddStep(new, after)
    if not chosen then return end
    local at = (after or Index(step) or #chosen.steps) + 1
    table.insert(chosen.steps, at, new)
    step = new
    Editor.Changed()
end

function Editor.TakeStep(index)
    if not chosen or not chosen.steps[index] then return end
    local taken = table.remove(chosen.steps, index)
    if taken == step then step = chosen.steps[index] or chosen.steps[index - 1] end
    Editor.Changed()
end

local function Line(index)
    local line = CreateFrame("Button", nil, child)
    line:SetHeight(Editor.LINE)
    line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Editor.LINE)
    line:SetPoint("RIGHT", child, "RIGHT", 0, 0)
    line:EnableMouse(true)
    line.mark = line:CreateTexture(nil, "BACKGROUND")
    line.mark:SetAllPoints()
    line.mark:SetColorTexture(1, 1, 1, 0.1)
    line.flag = line:CreateFontString(nil, "OVERLAY", "GameFontRed")
    line.flag:SetPoint("RIGHT", -3, 0)
    line.flag:SetText("!")
    line.key = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    line.key:SetPoint("RIGHT", line.flag, "LEFT", -4, 0)
    line.name = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.name:SetPoint("LEFT", 4, 0)
    line.name:SetPoint("RIGHT", line.key, "LEFT", -4, 0)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line:SetScript("OnClick", ns.Guard(function() Editor.Choose(line.macro) end))
    lines[index] = line
    return line
end

local function Lines()
    local macros = ns.Book.All()
    for index, macro in ipairs(macros) do
        local line = lines[index] or Line(index)
        line.macro = macro
        line.name:SetText(macro.name)
        line.mark:SetShown(macro == chosen)
        line.key:SetText(ns.Book.KeyOf(macro) or "")
        line.flag:SetShown(ns.options.checks and ns.Check.Macro(macro).count > 0)
        line:Show()
    end
    for index = #macros + 1, #lines do lines[index]:Hide() end
    empty:SetShown(macros[1] == nil)
    child:SetHeight(math.max(#macros * Editor.LINE, 1))
end

local function Head()
    picture.icon:SetTexture(ns.Press.Picture(chosen.steps[1]))
    if not name:HasFocus() then name:SetText(chosen.name) end
    keyButton:SetText(ns.Book.KeyOf(chosen) or ns.TEXT.keyNone)
    local place = ns.Book.PlaceOf(chosen)
    if place then
        local bar, button = ns.Reach.Words(place)
        placeButton:SetText(bar .. ", " .. button)
    else
        placeButton:SetText(ns.TEXT.place)
    end
    orderMenu:GenerateMenu()
    fresh:SetChecked(chosen.fresh)
    fresh:SetShown(not chosen.top)
    freshWord:SetShown(not chosen.top)
end

local function Flags(found)
    if not found then return flags:SetText("") end
    local words = {}
    for _, word in ipairs(found.macro) do words[#words + 1] = word end
    for _, word in ipairs(step and found[step] or {}) do words[#words + 1] = word end
    flags:SetText(table.concat(words, "\n"))
end

function Fill()
    if not built then return end
    Lines()
    right:SetShown(chosen ~= nil)
    copy:SetEnabled(chosen ~= nil)
    delete:SetEnabled(chosen ~= nil)
    if not chosen then return end
    Head()
    local found = ns.options.checks and ns.Check.Macro(chosen) or nil
    ns.Steps.Fill(chosen, step, found)
    ns.Detail.Fill(chosen, step)
    Flags(found)
end

-- The key: the next key pressed, with its modifiers.
local MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }
local MOUSE = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function StopKey()
    if not catcher or not catcher:IsShown() then return end
    catcher:EnableKeyboard(false)
    catcher:Hide()
    Fill()
end

local function TakeKey(key)
    local words = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "")
                  .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    StopKey()
    local had = ns.Reach.SetKey(chosen, words)
    if had then ns.Print(ns.TEXT.keyOther:format(had.name)) end
    Fill()
end

local function KeyDown(_, key)
    if MODIFIERS[key] then return end
    if key == "ESCAPE" then return StopKey() end
    TakeKey(key)
end

local function MouseDown(_, mouse)
    if MOUSE[mouse] then return TakeKey(MOUSE[mouse]) end
    StopKey()
end

local function WaitForKey()
    if InCombatLockdown() then return ns.Print(ns.TEXT.noCombat) end
    if not catcher then
        catcher = CreateFrame("Frame", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:EnableMouse(true)
        catcher:SetScript("OnKeyDown", ns.Guard(KeyDown))
        catcher:SetScript("OnMouseDown", ns.Guard(MouseDown))
        ns.On("PLAYER_REGEN_DISABLED", StopKey)
    end
    catcher:Show()
    catcher:EnableKeyboard(true)
    catcher:SetPropagateKeyboardInput(false)
    keyButton:SetText(ns.TEXT.keyWait)
end

local function KeyClick(_, mouse)
    if not chosen then return end
    if mouse == "RightButton" then
        ns.Reach.TakeKey(chosen)
        return Fill()
    end
    WaitForKey()
end

local function Placed(place)
    if chosen then ns.Reach.SetPlace(chosen, place) end
    Fill()
end

local function BeginPlacing()
    if not chosen then return end
    ns.Print(ns.TEXT.placeAsk:format(chosen.name))
    ns.Place.Start(Placed)
end

local function PlaceClick(_, mouse)
    if not chosen then return end
    if mouse == "RightButton" then
        ns.Reach.TakePlace(chosen)
        return Fill()
    end
    BeginPlacing()
end

local function KeyTip(self)
    local key = chosen and ns.Book.KeyOf(chosen)
    local text = ns.TEXT.keyTip
    if key then
        local action = Core.Ask(GetBindingAction, key)
        local words = action and action ~= "" and Core.Ask(GetBindingName, action)
        text = text .. "\n" .. ns.TEXT.keyClear
        if words then text = text .. "\n" .. ns.TEXT.keyTaken:format(words) end
    end
    Core.ShowTip(self, ns.TEXT.key, text)
end

local function PlaceTip(self)
    local place = chosen and ns.Book.PlaceOf(chosen)
    if not place then return Core.ShowTip(self, ns.TEXT.place, ns.TEXT.placeTip) end
    local bar, button = ns.Reach.Words(place)
    Core.ShowTip(self, ns.TEXT.placed, ns.TEXT.placedTip:format(bar, button))
end

local function Order(root)
    local function Radio(text, tip, top)
        local radio = root:CreateRadio(text, ns.Guard(function() return chosen ~= nil and (chosen.top or false) == top end),
                                       ns.Guard(function()
                                           chosen.top = top or nil
                                           Editor.Changed()
                                       end))
        radio:SetTooltip(ns.Guard(function(tooltip) GameTooltip_AddNormalLine(tooltip, tip) end))
    end
    Radio(ns.TEXT.orderTurn, ns.TEXT.orderTurnTip, false)
    Radio(ns.TEXT.orderTop, ns.TEXT.orderTopTip, true)
end

local function NewFromGame(index)
    local title, _, body = Core.Ask(GetMacroInfo, index)
    if title then Editor.Choose(ns.Book.FromGame(title, body)) end
end

-- The game's macros, the account's then the character's, as lines of a menu.
local function GameMacros(line)
    local account, own = Core.Ask(GetNumMacros)
    local first = rawget(_G, "Constants") and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS or 120
    local any = false
    local function Add(index)
        local title = Core.Ask(GetMacroInfo, index)
        if title then
            any = true
            line:CreateButton(title, ns.Guard(function() NewFromGame(index) end))
        end
    end
    for index = 1, account or 0 do Add(index) end
    for index = first + 1, first + (own or 0) do Add(index) end
    if not any then line:CreateTitle(ns.TEXT.newFromNone) end
end

local function NewClick(self)
    MenuUtil.CreateContextMenu(self, ns.Guard(function(_, root)
        root:CreateButton(ns.TEXT.newEmpty, ns.Guard(function() Editor.Choose(ns.Book.New()) end))
        GameMacros(root:CreateButton(ns.TEXT.newFrom))
    end))
end

local function DeleteClick()
    if not chosen then return end
    local macro = chosen
    Core.Confirm(ns.TEXT.deleteAsk, macro.name, function()
        ns.Book.Delete(macro)
        ns.Press.Drop(macro)
        ns.Reach.Update()
        if chosen == macro then Editor.Choose(ns.Book.All()[1]) end
    end, true)
end

local function Button(parent, text, width, click, tip, tipText)
    local button = ns.Button(parent, text, width)
    button:SetScript("OnClick", ns.Guard(click))
    if tip then Core.Tip(button, tip, tipText) end
    return button
end

local function Left(inside, I)
    local head = inside:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", I, -I)
    head:SetText(ns.TEXT.macros)
    list = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    list:SetPoint("TOPLEFT", inside, "TOPLEFT", I, -I - 20)
    list:SetPoint("BOTTOM", inside, "BOTTOM", 0, I + 28)
    list:SetWidth(Editor.LIST - 24)
    child = CreateFrame("Frame", nil, list)
    child:SetSize(Editor.LIST - 24, 1)
    list:SetScrollChild(child)
    empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 4, -6)
    empty:SetWidth(Editor.LIST - 32)
    empty:SetJustifyH("LEFT")
    empty:SetText(ns.TEXT.none)
    local new = Button(inside, ns.TEXT.new, 66, NewClick, ns.TEXT.new, ns.TEXT.newTip)
    new:SetPoint("BOTTOMLEFT", I, I)
    copy = Button(inside, ns.TEXT.copy, 66, function() if chosen then Editor.Choose(ns.Book.Copy(chosen)) end end,
                  ns.TEXT.copy, ns.TEXT.copyTip)
    copy:SetPoint("LEFT", new, "RIGHT", 4, 0)
    delete = Button(inside, ns.TEXT.delete, 66, DeleteClick, ns.TEXT.delete, ns.TEXT.deleteTip)
    delete:SetPoint("LEFT", copy, "RIGHT", 4, 0)
end

local function Top()
    picture = CreateFrame("Button", nil, right)
    picture:SetSize(Editor.ICON, Editor.ICON)
    picture:SetPoint("TOPLEFT")
    picture.icon = picture:CreateTexture(nil, "ARTWORK")
    picture.icon:SetAllPoints()
    picture.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    picture:RegisterForDrag(Editor.DRAG)
    picture:SetScript("OnDragStart", ns.Guard(BeginPlacing))
    picture:SetScript("OnDragStop", ns.Guard(ns.Place.Drop))
    Core.Tip(picture, ns.TEXT.place, ns.TEXT.picture)

    name = CreateFrame("EditBox", nil, right, "InputBoxTemplate")
    name:SetSize(250, 22)
    name:SetPoint("LEFT", picture, "RIGHT", 12, 0)
    name:SetAutoFocus(false)
    name:SetScript("OnTextChanged", ns.Guard(function(self, typed)
        if typed and chosen then
            chosen.name = self:GetText()
            Lines()
        end
    end))
    name:SetScript("OnEnterPressed", ns.Guard(function(self) self:ClearFocus() end))
    name:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    Core.Tip(name, ns.TEXT.name, ns.TEXT.nameTip)

    keyButton = Button(right, ns.TEXT.keyNone, 120, KeyClick)
    keyButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    keyButton:SetPoint("LEFT", name, "RIGHT", 12, 0)
    keyButton:HookScript("OnEnter", ns.Guard(KeyTip))
    keyButton:HookScript("OnLeave", ns.Guard(Core.HideTip))
    placeButton = Button(right, ns.TEXT.place, 120, PlaceClick)
    placeButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    placeButton:SetPoint("LEFT", keyButton, "RIGHT", 6, 0)
    placeButton:HookScript("OnEnter", ns.Guard(PlaceTip))
    placeButton:HookScript("OnLeave", ns.Guard(Core.HideTip))

    local orderWord = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orderWord:SetPoint("TOPLEFT", 0, -50)
    orderWord:SetText(ns.TEXT.order)
    orderMenu = CreateFrame("DropdownButton", nil, right, "WowStyle1DropdownTemplate")
    orderMenu:SetWidth(240)
    orderMenu:SetPoint("LEFT", orderWord, "RIGHT", 10, 0)
    orderMenu:SetupMenu(ns.Guard(function(_, root) if chosen then Order(root) end end))
    fresh = CreateFrame("CheckButton", nil, right, "UICheckButtonTemplate")
    fresh:SetSize(24, 24)
    fresh:SetPoint("LEFT", orderMenu, "RIGHT", 12, 0)
    fresh:SetScript("OnClick", ns.Guard(function(self)
        if chosen then chosen.fresh = self:GetChecked() and true or false end
    end))
    Core.Tip(fresh, ns.TEXT.fresh, ns.TEXT.freshTip)
    freshWord = right:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    freshWord:SetPoint("LEFT", fresh, "RIGHT", 2, 0)
    freshWord:SetText(ns.TEXT.fresh)

    local stepsWord = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepsWord:SetPoint("TOPLEFT", 0, -88)
    stepsWord:SetText(ns.TEXT.steps)
    local add = Button(right, ns.TEXT.add, 100, function() Editor.AddStep(ns.Book.Step("spell")) end, ns.TEXT.add, ns.TEXT.addTip)
    add:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, -82)
end

local function Build()
    built = true
    local inside, I = window.inside, Editor.INSET
    Left(inside, I)
    right = CreateFrame("Frame", nil, inside)
    right:SetPoint("TOPLEFT", inside, "TOPLEFT", I * 2 + Editor.LIST, -I)
    right:SetPoint("BOTTOMRIGHT", inside, "BOTTOMRIGHT", -I, I)
    Top()
    flags = right:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    flags:SetPoint("BOTTOMLEFT")
    flags:SetPoint("BOTTOMRIGHT")
    flags:SetHeight(26)
    flags:SetJustifyH("LEFT")
    flags:SetJustifyV("TOP")
    local below = CreateFrame("Frame", nil, right)
    below:SetPoint("BOTTOMLEFT", 0, 30)
    below:SetPoint("BOTTOMRIGHT", 0, 30)
    below:SetHeight(ns.Detail.HEIGHT)
    ns.Detail.Build(below)
    local above = CreateFrame("Frame", nil, right)
    above:SetPoint("TOPLEFT", 0, -112)
    above:SetPoint("BOTTOMRIGHT", below, "TOPRIGHT", 0, 8)
    ns.Steps.Build(above)
end

local function Shown()
    if not built then Build() end
    if not chosen then Editor.Choose(ns.Book.All()[1]) else Fill() end
    Core.Sound("IG_CHARACTER_INFO_OPEN")
end

local function Hidden()
    ns.Place.Stop()
    StopKey()
    Core.Sound("IG_CHARACTER_INFO_CLOSE")
end

-- Something the checks read has changed: while the window shows, they look again.
local function Look()
    if frame and frame:IsShown() then Fill() end
end

-- Made at login, empty: it stands for the game's macro window from the start.
function Editor.Prepare()
    if frame then return end
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Editor.WIDTH, Editor.HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = ns.store, key = "place", title = ns.TEXT.title, edge = false, dock = false,
        sizable = false, first = { point = "CENTER", x = 0, y = 40 },
        native = { frame = function() return rawget(_G, "MacroFrame") end, addon = "Blizzard_MacroUI", hold = true },
        close = function() frame:Hide() end,
    })
    frame:HookScript("OnShow", ns.Guard(Shown))
    frame:HookScript("OnHide", ns.Guard(Hidden))
    window:Place()
    for _, event in ipairs({ "SPELLS_CHANGED", "BAG_UPDATE_DELAYED" }) do ns.On(event, Look) end
end

function Editor.Toggle()
    if ns.off or not frame then return end
    if frame:IsShown() then return frame:Hide() end
    if window:Open() == "native" then Core.Ask(rawget(_G, "ShowMacroFrame")) end
end

-- A switch of the module changed.
function Editor.Refresh()
    Fill()
end

function Editor.GiveBack()
    if window then window:GiveBack() end
    if frame then frame:Hide() end
end
