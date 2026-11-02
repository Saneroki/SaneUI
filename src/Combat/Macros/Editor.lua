local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Editor
--  Sane Macros, in the game's macro window's stead (/macro, the game menu, /sane
--  macros, its key): on the left your macros, on the right the one chosen: its
--  name, key and bar button, its order, its steps, and under them the chosen
--  step's settings. Every change counts at once; in a fight it waits for the
--  fight's end.
--
--  It stands on the full screen, beside the action bars (the part macros of the
--  board), and opening it brings that screen. Where that cannot come (Edit Mode,
--  the full screen switched off) it is a window of its own, made at login to stand
--  for the game's window. What it holds is one page, made when first shown, that
--  goes where it is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Editor = {}
Macros.Editor = Editor

Editor.WIDTH, Editor.HEIGHT = 880, 640
Editor.LEAST = { 760, 480 } -- the panel on the full screen at least this large
Editor.INSET = 12
Editor.LIST = 210    -- the macros' list
Editor.LINE = 24     -- a macro's line
Editor.ICON = 36     -- the macro's picture
Editor.DRAG = "LeftButton"
Editor.BESIDE = 306  -- of the right side's width, what is not the name's box

local KEY = "macros"
local frame, window, built, page, onBoard
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
    if chosen then Macros.Press.Update(chosen) end
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
    line:RegisterForDrag(Editor.DRAG)
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
    line:SetScript("OnDragStart", ns.Guard(function()
        Editor.Choose(line.macro)
        Editor.DragToBar()
    end))
    line:SetScript("OnDragStop", ns.Guard(Macros.Place.Drop))
    lines[index] = line
    return line
end

local function Lines()
    local macros = Macros.Book.All()
    for index, macro in ipairs(macros) do
        local line = lines[index] or Line(index)
        line.macro = macro
        line.name:SetText(macro.name)
        line.mark:SetShown(macro == chosen)
        line.key:SetText(Macros.Book.KeyOf(macro) or "")
        line.flag:SetShown(ns.options.macroChecks and Macros.Check.Macro(macro).count > 0)
        line:Show()
    end
    for index = #macros + 1, #lines do lines[index]:Hide() end
    empty:SetShown(macros[1] == nil)
    child:SetHeight(math.max(#macros * Editor.LINE, 1))
end

local function Head()
    picture.icon:SetTexture(Macros.Press.Picture(chosen.steps[1]))
    if not name:HasFocus() then name:SetText(chosen.name) end
    keyButton:SetText(Macros.Book.KeyOf(chosen) or Macros.TEXT.keyNone)
    local place = Macros.Book.PlaceOf(chosen)
    if place then
        local bar, button = Macros.Reach.Words(place)
        placeButton:SetText(bar .. ", " .. button)
    else
        placeButton:SetText(Macros.TEXT.place)
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
    local found = ns.options.macroChecks and Macros.Check.Macro(chosen) or nil
    Macros.Steps.Fill(chosen, step, found)
    Macros.Detail.Fill(chosen, step)
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
    local had = Macros.Reach.SetKey(chosen, words)
    if had then ns.Print(Macros.TEXT.keyOther:format(had.name)) end
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
    if InCombatLockdown() then return ns.Print(Macros.TEXT.noCombat) end
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
    keyButton:SetText(Macros.TEXT.keyWait)
end

local function KeyClick(_, mouse)
    if not chosen then return end
    if mouse == "RightButton" then
        Macros.Reach.TakeKey(chosen)
        return Fill()
    end
    WaitForKey()
end

local function Placed(place)
    if chosen then Macros.Reach.SetPlace(chosen, place) end
    Fill()
end

-- A drag begins: the bar buttons take it.
function Editor.DragToBar()
    if chosen then Macros.Place.Start(Placed) end
end

local function BeginPlacing()
    if not chosen then return end
    ns.Print(Macros.TEXT.placeAsk:format(chosen.name))
    Macros.Place.Start(Placed)
end

local function PlaceClick(_, mouse)
    if not chosen then return end
    if mouse == "RightButton" then
        Macros.Reach.TakePlace(chosen)
        return Fill()
    end
    BeginPlacing()
end

local function KeyTip(self)
    local key = chosen and Macros.Book.KeyOf(chosen)
    local text = Macros.TEXT.keyTip
    if key then
        local action = Core.Ask(GetBindingAction, key)
        local words = action and action ~= "" and Core.Ask(GetBindingName, action)
        text = text .. "\n" .. Macros.TEXT.keyClear
        if words then text = text .. "\n" .. Macros.TEXT.keyTaken:format(words) end
    end
    Core.ShowTip(self, Macros.TEXT.key, text)
end

local function PlaceTip(self)
    local place = chosen and Macros.Book.PlaceOf(chosen)
    if not place then return Core.ShowTip(self, Macros.TEXT.place, Macros.TEXT.placeTip) end
    local bar, button = Macros.Reach.Words(place)
    Core.ShowTip(self, Macros.TEXT.placed, Macros.TEXT.placedTip:format(bar, button))
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
    Radio(Macros.TEXT.orderTurn, Macros.TEXT.orderTurnTip, false)
    Radio(Macros.TEXT.orderTop, Macros.TEXT.orderTopTip, true)
end

local function NewFromGame(index)
    local title, _, body = Core.Ask(GetMacroInfo, index)
    if title then Editor.Choose(Macros.Book.FromGame(title, body)) end
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
    if not any then line:CreateTitle(Macros.TEXT.newFromNone) end
end

local function NewClick(self)
    MenuUtil.CreateContextMenu(self, ns.Guard(function(_, root)
        root:CreateButton(Macros.TEXT.newEmpty, ns.Guard(function() Editor.Choose(Macros.Book.New()) end))
        GameMacros(root:CreateButton(Macros.TEXT.newFrom))
    end))
end

local function DeleteClick()
    if not chosen then return end
    local macro = chosen
    Core.Confirm(Macros.TEXT.deleteAsk, macro.name, function()
        Macros.Book.Delete(macro)
        Macros.Press.Drop(macro)
        Macros.Reach.Update()
        if chosen == macro then Editor.Choose(Macros.Book.All()[1]) end
    end, true)
end

local function Button(parent, text, width, click, tip, tipText)
    local button = Macros.Button(parent, text, width)
    button:SetScript("OnClick", ns.Guard(click))
    if tip then Core.Tip(button, tip, tipText) end
    return button
end

local function Left(inside, I)
    local head = inside:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", I, -I)
    head:SetText(Macros.TEXT.macros)
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
    empty:SetText(Macros.TEXT.none)
    local new = Button(inside, Macros.TEXT.new, 66, NewClick, Macros.TEXT.new, Macros.TEXT.newTip)
    new:SetPoint("BOTTOMLEFT", I, I)
    copy = Button(inside, Macros.TEXT.copy, 66, function() if chosen then Editor.Choose(Macros.Book.Copy(chosen)) end end,
                  Macros.TEXT.copy, Macros.TEXT.copyTip)
    copy:SetPoint("LEFT", new, "RIGHT", 4, 0)
    delete = Button(inside, Macros.TEXT.delete, 66, DeleteClick, Macros.TEXT.delete, Macros.TEXT.deleteTip)
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
    picture:SetScript("OnDragStart", ns.Guard(Editor.DragToBar))
    picture:SetScript("OnDragStop", ns.Guard(Macros.Place.Drop))
    Core.Tip(picture, Macros.TEXT.place, Macros.TEXT.picture)

    name = CreateFrame("EditBox", nil, right, "InputBoxTemplate")
    name:SetSize(Editor.WIDTH - 3 * Editor.INSET - Editor.LIST - Editor.BESIDE, 22)
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
    Core.Tip(name, Macros.TEXT.name, Macros.TEXT.nameTip)

    keyButton = Button(right, Macros.TEXT.keyNone, 120, KeyClick)
    keyButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    keyButton:SetPoint("LEFT", name, "RIGHT", 12, 0)
    keyButton:HookScript("OnEnter", ns.Guard(KeyTip))
    keyButton:HookScript("OnLeave", ns.Guard(Core.HideTip))
    placeButton = Button(right, Macros.TEXT.place, 120, PlaceClick)
    placeButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    placeButton:SetPoint("LEFT", keyButton, "RIGHT", 6, 0)
    placeButton:HookScript("OnEnter", ns.Guard(PlaceTip))
    placeButton:HookScript("OnLeave", ns.Guard(Core.HideTip))

    local orderWord = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orderWord:SetPoint("TOPLEFT", 0, -50)
    orderWord:SetText(Macros.TEXT.order)
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
    Core.Tip(fresh, Macros.TEXT.fresh, Macros.TEXT.freshTip)
    freshWord = right:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    freshWord:SetPoint("LEFT", fresh, "RIGHT", 2, 0)
    freshWord:SetText(Macros.TEXT.fresh)

    local stepsWord = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepsWord:SetPoint("TOPLEFT", 0, -88)
    stepsWord:SetText(Macros.TEXT.steps)
    local add = Button(right, Macros.TEXT.add, 100, function() Editor.AddStep(Macros.Book.Step("spell")) end, Macros.TEXT.add, Macros.TEXT.addTip)
    add:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, -82)
end

-- The page, made once, in parent.
local function Build(parent)
    built = true
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    local I = Editor.INSET
    Left(page, I)
    right = CreateFrame("Frame", nil, page)
    right:SetPoint("TOPLEFT", page, "TOPLEFT", I * 2 + Editor.LIST, -I)
    right:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -I, I)
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
    below:SetHeight(Macros.Detail.HEIGHT)
    Macros.Detail.Build(below)
    local above = CreateFrame("Frame", nil, right)
    above:SetPoint("TOPLEFT", 0, -112)
    above:SetPoint("BOTTOMRIGHT", below, "TOPRIGHT", 0, 8)
    Macros.Steps.Build(above)
end

-- The page is that wide now: what it holds takes the room.
function Editor.Size(width)
    if not built then return end
    local wide = width - 3 * Editor.INSET - Editor.LIST
    name:SetWidth(wide - Editor.BESIDE)
    Macros.Steps.Width(wide - 24)
    Macros.Detail.Width(wide)
end

-- The page in parent, on show there.
local function Into(parent, width)
    if not built then Build(parent) end
    page:SetParent(parent)
    page:ClearAllPoints()
    page:SetAllPoints(parent)
    page:Show()
    Editor.Size(width)
    if not chosen then Editor.Choose(Macros.Book.All()[1]) else Fill() end
end

-- Whether its place is on the full screen now: it was brought there, or stands there already.
local function ToBoard()
    ns.Window.Open(KEY)
    return ns.Window.Full() == true
end

local function Shown()
    -- Opened by the game or a key: on the full screen where that can come, and the window of its own stays shut.
    if ToBoard() then
        frame.moved = true
        return frame:Hide()
    end
    Into(window.inside, Editor.WIDTH)
    Core.Sound("IG_CHARACTER_INFO_OPEN")
end

local function Hidden()
    Macros.Place.Stop()
    StopKey()
    if frame.moved then
        frame.moved = nil
        return
    end
    Core.Sound("IG_CHARACTER_INFO_CLOSE")
end

-- The part on the board (Board.lua): the page in its panel's body.
local Part = {}
local body

function Part.Build(panel)
    body = panel.body
end

function Part.Show(on)
    onBoard = on
    if on then
        if frame and frame:IsShown() then frame:Hide() end
        return Into(body, body:GetWidth())
    end
    Macros.Place.Stop()
    StopKey()
end

function Part.Size(width)
    Editor.Size(width)
end

ns.Board.Part(KEY, Macros.TEXT.title, Editor.LEAST, Part)

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
        kind = "panel", store = Macros.store, key = "place", title = Macros.TEXT.title, edge = false, dock = false,
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
    if onBoard then return ns.Window.Back() end
    if window:Open() == "native" then Core.Ask(rawget(_G, "ShowMacroFrame")) end
end

-- For the test.
function Editor.Shown()
    return frame ~= nil and frame:IsShown()
end

function Editor.Page()
    return page
end

-- A switch of the module changed.
function Editor.Refresh()
    Fill()
end

function Editor.GiveBack()
    if window then window:GiveBack() end
    if frame then frame:Hide() end
end
