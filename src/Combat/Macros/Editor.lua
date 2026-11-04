local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Editor
--  Sane Macros, in the game's macro window's stead (/macro, the game menu, /sane
--  macros, its key): on the left your macros, and under them the game's own,
--  marked W (Saneroki, 2026-11-03), as squares of their pictures with their names
--  under them, as the game's window shows its macros (Saneroki, 2026-11-04); on
--  the right the one chosen: its name, key and
--  bar button, its order, its steps, and under them the chosen step's settings.
--  A filter over the list (Saneroki, 2026-11-04: "a dropdown that is show all ...,
--  a general one ... and a per character one") shows this character's macros, the
--  general ones or all of the account's; a right click on one says whose it is.
--  Every change counts at once; in a fight it waits for the fight's end. A game's
--  macro opens in the game's macro window, as the button Game macros does.
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

Editor.WIDTH, Editor.HEIGHT = 920, 640
Editor.LEAST = { 800, 480 } -- the panel on the full screen at least this large
Editor.INSET = 12
Editor.LIST = 250    -- the macros' list, its scroll bar too
Editor.SQUARE = 44   -- a macro's picture in the list (the game's window: 36)
Editor.CELL = 52     -- a macro's room in the list: its picture, its name under it
Editor.ROW = 68      -- from one row of the list to the next
Editor.GAP = 6       -- between two macros in a row
Editor.HEAD = 22     -- the line over the game's macros
Editor.ICON = 36     -- the macro's picture
Editor.DRAG = "LeftButton"
Editor.BESIDE = 306  -- of the right side's width, what is not the name's box

local KEY = "macros"
local frame, window, built, page, onBoard
local list, child, empty, gameHead, right, picture, name, keyButton, placeButton, orderMenu, fresh, freshWord, flags, copy, delete
local filterMenu
local catcher
local lines = {}
local chosen     -- the macro shown
local step       -- the step chosen

local Fill

-- Where the game's character macros start: after the account's.
local function AccountMax()
    local consts = rawget(_G, "Constants") and Constants.MacroConsts
    return consts and consts.MAX_ACCOUNT_MACROS or 120
end

-- What the list shows: this character's macros ("own"), the general ones or all (Book.FILTERS), as this character
-- chose it last; all of them at first (Saneroki, 2026-11-04: "The filter should by default be on show all").
local function Filter()
    local filter = Macros.own and Macros.own.filter
    return Macros.Book.FILTER_WORDS[filter] and filter or "all"
end

-- The game's macros, the account's then the character's: { index, name, icon } each. With menu, all of them;
-- else as the filter says: its account macros are general ones, its character macros this character's.
local function GameList(menu)
    local list = {}
    local account, own = Core.Ask(GetNumMacros)
    local filter = menu and "all" or Filter()
    local function Add(index)
        local title, icon = Core.Ask(GetMacroInfo, index)
        if title then list[#list + 1] = { index = index, name = title, icon = icon } end
    end
    if filter ~= "own" then
        for index = 1, account or 0 do Add(index) end
    end
    if filter ~= "general" then
        for index = AccountMax() + 1, AccountMax() + (own or 0) do Add(index) end
    end
    return list
end

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

local GameClick

local function Picture(macro)
    return Macros.Press.MacroPicture(macro)
end

local function Short(key)
    return key and Macros.Reach.Short(key) or ""
end

local function MacroTip(line)
    if line.game then return Core.ShowTip(line, Macros.TEXT.gameLine, Macros.TEXT.gameLineTip) end
    local key = Macros.Book.KeyOf(line.macro)
    local text = Macros.TEXT.lineTip
    if key then text = Macros.TEXT.lineKey:format(Short(key)) .. "\n" .. text end
    Core.ShowTip(line, line.macro.name, text)
end

-- A macro in the list, as the game's window shows one: its picture on an empty slot, its name under it, the
-- game's light under the mouse and its gold light on the one chosen; a game's macro marked W, a key at the
-- picture's corner as on a bar button, and a red ! where the checks found something.
local function Line(index)
    local line = CreateFrame("Button", nil, child)
    line:SetSize(Editor.CELL, Editor.SQUARE + 18)
    line:EnableMouse(true)
    line:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    line:RegisterForDrag(Editor.DRAG)
    local square = Editor.SQUARE
    line.slot = line:CreateTexture(nil, "BACKGROUND")
    line.slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
    line.slot:SetTexCoord(0.140625, 0.84375, 0.140625, 0.84375)
    line.slot:SetSize(square * 45 / 36, square * 45 / 36)
    line.slot:SetPoint("TOP", 0, square * 9 / 72)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(square, square)
    line.icon:SetPoint("TOP")
    line.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    local lit = line:CreateTexture(nil, "HIGHLIGHT")
    lit:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    lit:SetBlendMode("ADD")
    lit:SetAllPoints(line.icon)
    line.mark = line:CreateTexture(nil, "OVERLAY")
    line.mark:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    line.mark:SetBlendMode("ADD")
    line.mark:SetAllPoints(line.icon)
    line.badge = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmallOutline") -- a game's macro: gold W
    line.badge:SetPoint("TOPLEFT", line.icon, "TOPLEFT", 3, -3)
    line.badge:SetText(Macros.TEXT.gameMark)
    line.flag = line:CreateFontString(nil, "OVERLAY", "GameFontRed")
    line.flag:SetPoint("TOPLEFT", line.icon, "TOPLEFT", 4, -2)
    line.flag:SetText("!")
    line.key = line:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    line.key:SetPoint("TOPRIGHT", line.icon, "TOPRIGHT", -2, -3)
    line.key:SetJustifyH("RIGHT")
    line.key:SetWidth(square - 6)
    line.key:SetWordWrap(false)
    line.name = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.name:SetPoint("TOP", line.icon, "BOTTOM", 0, -3)
    line.name:SetWidth(Editor.CELL)
    line.name:SetJustifyH("CENTER")
    line.name:SetWordWrap(false)
    line:SetScript("OnClick", ns.Guard(function(_, mouse)
        if line.game then return GameClick(line, mouse) end
        Editor.Choose(line.macro)
        if mouse == "RightButton" then Editor.Whose(line) end
    end))
    line:SetScript("OnDragStart", ns.Guard(function()
        Core.HideTip()
        if line.game then return Core.Ask(rawget(_G, "PickupMacro"), line.game.index) end
        Editor.Choose(line.macro)
        Editor.DragToBar()
    end))
    line:SetScript("OnDragStop", ns.Guard(function()
        if line.game then return Editor.DropGame() end
        Macros.Place.Drop()
    end))
    line:SetScript("OnEnter", ns.Guard(MacroTip))
    line:SetScript("OnLeave", ns.Guard(Core.HideTip))
    lines[index] = line
    return line
end

-- A macro of the list: one of ours (macro) or one of the game's (game, marked W).
local function Dress(line, macro, game)
    line.macro, line.game = macro, game
    line.badge:SetShown(game ~= nil)
    line.icon:SetTexture(macro and Picture(macro) or game.icon or Macros.Press.ICON)
    line.name:SetText(macro and macro.name or game.name)
    line.mark:SetShown(macro ~= nil and macro == chosen)
    line.key:SetText(macro and Short(Macros.Book.KeyOf(macro)) or "")
    line.flag:SetShown(macro ~= nil and ns.options.macroChecks and Macros.Check.Macro(macro).count > 0)
    line:Show()
end

-- How many macros stand in a row of the list.
local function Across()
    local wide = Editor.LIST - 24
    return math.max(1, math.floor((wide + Editor.GAP) / (Editor.CELL + Editor.GAP)))
end

-- The macro at that place of its group, from the group's top.
local function Put(line, at, top)
    local across = Across()
    local column, row = (at - 1) % across, math.floor((at - 1) / across)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", child, "TOPLEFT", column * (Editor.CELL + Editor.GAP), -(top + row * Editor.ROW))
end

local function Rows(count)
    return math.ceil(count / Across())
end

-- Yours in rows, then a line and the game's.
local function Lines()
    local count, top = 0, 4
    local own = Macros.Book.Shown(Filter())
    empty:SetText(Macros.Book.All()[1] and Macros.TEXT.noneHere or Macros.TEXT.none)
    empty:SetShown(own[1] == nil)
    if not own[1] then top = top + 34 end
    for at, macro in ipairs(own) do
        count = count + 1
        local line = lines[count] or Line(count)
        Dress(line, macro, nil)
        Put(line, at, top)
    end
    top = top + Rows(#own) * Editor.ROW
    local games = GameList()
    gameHead:SetShown(games[1] ~= nil)
    gameHead:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -top)
    if games[1] then top = top + Editor.HEAD end
    for at, game in ipairs(games) do
        count = count + 1
        local line = lines[count] or Line(count)
        Dress(line, nil, game)
        Put(line, at, top)
    end
    top = top + Rows(#games) * Editor.ROW
    for index = count + 1, #lines do lines[index]:Hide() end
    child:SetHeight(math.max(top, 1))
end

local function Head()
    picture.icon:SetTexture(Picture(chosen))
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

-- The picture window for the macro chosen (Icons.lua): the picture clicked is its own, Steps' picture none.
function Editor.ChoosePicture()
    local macro = chosen
    if not macro then return end
    Macros.Icons.Open(macro, function(picture)
        macro.icon = Macros.Book.Icon(picture)
        if chosen == macro then Editor.Changed() else Macros.Press.Update(macro) end
    end)
end

-- A game's macro let go over a bar button that has not taken it itself (Saneroki, 2026-11-04: the full screen's bars
-- took none, spells they did): the game's own PlaceAction puts it on the button under the mouse. A button that took it
-- left the cursor empty, and nothing more happens. Out of a fight.
function Editor.DropGame()
    if InCombatLockdown() or Core.Ask(rawget(_G, "GetCursorInfo")) ~= "macro" then return end
    local foci = (GetMouseFoci and GetMouseFoci()) or (GetMouseFocus and { GetMouseFocus() }) or {}
    for _, frame in ipairs(foci) do
        local action = type(frame) == "table" and Core.Plain(rawget(frame, "action"))
        if type(action) == "number" then
            Core.Ask(rawget(_G, "PlaceAction"), action)
            Core.Ask(rawget(_G, "ClearCursor"))
            return
        end
    end
end

-- A drag begins: the bar buttons take it.
function Editor.DragToBar()
    if chosen then Macros.Place.Start(Placed, Picture(chosen)) end
end

local function BeginPlacing()
    if not chosen then return end
    ns.Print(Macros.TEXT.placeAsk:format(chosen.name))
    Macros.Place.Start(Placed, Picture(chosen))
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

-- Whose a new macro is: as the filter shows, this character's own or a general one.
local function Owned(macro)
    Macros.Book.SetOwner(macro, Filter() == "own" and "character" or "general")
    return macro
end

local function NewFromGame(index)
    local title, icon, body = Core.Ask(GetMacroInfo, index)
    if title then Editor.Choose(Owned(Macros.Book.FromGame(title, body, icon))) end
end

-- The game's macros, the account's then the character's, as lines of a menu.
local function GameMacros(line)
    local list = GameList(true)
    for _, game in ipairs(list) do
        line:CreateButton(game.name, ns.Guard(function() NewFromGame(game.index) end))
    end
    if not list[1] then line:CreateTitle(Macros.TEXT.newFromNone) end
end

-- The game's own macro window (the button Game macros, a game's macro clicked), with that macro chosen there: ours
-- goes, the full screen too, and the game's comes (window:Native, Holder.lua). Its button Sane UI brings ours back.
function Editor.OpenGame(index)
    if not window then return end
    if onBoard then ns.Window.Back() end
    window:Native(true)
    local game = rawget(_G, "MacroFrame")
    if not (game and game:IsShown()) then Core.Ask(rawget(_G, "ShowMacroFrame")) end
    game = rawget(_G, "MacroFrame")
    if not (index and game and type(game.ChangeTab) == "function" and type(game.SelectMacro) == "function") then return end
    local tab, at = 1, index
    if index > AccountMax() then tab, at = 2, index - AccountMax() end
    Core.Ask(game.ChangeTab, game, tab)
    Core.Ask(game.SelectMacro, game, at, true)
end

function GameClick(line, mouse)
    local game = line.game
    if mouse ~= "RightButton" then return Editor.OpenGame(game.index) end
    MenuUtil.CreateContextMenu(line, ns.Guard(function(_, root)
        root:CreateTitle(game.name)
        root:CreateButton(Macros.TEXT.gameOpen, ns.Guard(function() Editor.OpenGame(game.index) end))
        root:CreateButton(Macros.TEXT.gameTake, ns.Guard(function() NewFromGame(game.index) end))
    end))
end

local function NewClick(self)
    MenuUtil.CreateContextMenu(self, ns.Guard(function(_, root)
        root:CreateButton(Macros.TEXT.newEmpty, ns.Guard(function() Editor.Choose(Owned(Macros.Book.New())) end))
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
        if chosen == macro then Editor.Choose(Macros.Book.Shown(Filter())[1]) end
    end, true)
end

-- The filter changed: the list shows those, and the one chosen stays where it is still in it.
local function SetFilter(filter)
    Macros.own.filter = filter
    filterMenu:GenerateMenu()
    local shown = Macros.Book.Shown(filter)
    for _, macro in ipairs(shown) do
        if macro == chosen then return Fill() end
    end
    Editor.Choose(shown[1])
end

local function FilterWord(filter)
    if filter == "general" then return Macros.TEXT.filterGeneral end
    if filter == "all" then return Macros.TEXT.filterAll end
    return Macros.TEXT.filterOwn
end

local function FilterMenu(_, root)
    for _, filter in ipairs(Macros.Book.FILTERS) do
        root:CreateRadio(FilterWord(filter), ns.Guard(function() return Filter() == filter end),
                         ns.Guard(function() SetFilter(filter) end))
    end
end

-- A right click on a macro of the list: whose it is, every character's, this character's class's or its own.
function Editor.Whose(line)
    local macro = line.macro
    if not macro then return end
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    local choices = {
        { "general", Macros.TEXT.whoseGeneral },
        { "class", Macros.TEXT.whoseClass:format(names and names[Core.class] or Core.class or "") },
        { "character", Macros.TEXT.whoseCharacter:format(Core.charName or "") },
    }
    MenuUtil.CreateContextMenu(line, ns.Guard(function(_, root)
        root:CreateTitle(Macros.TEXT.whose)
        if not Macros.Book.Mine(macro) then root:CreateTitle(Macros.TEXT.whoseOther) end
        for _, choice in ipairs(choices) do
            local radio = root:CreateRadio(choice[2],
                ns.Guard(function() return Macros.Book.Mine(macro) and Macros.Book.Owner(macro) == choice[1] end),
                ns.Guard(function()
                    Macros.Book.SetOwner(macro, choice[1])
                    Fill()
                end))
            radio:SetTooltip(ns.Guard(function(tooltip) GameTooltip_AddNormalLine(tooltip, Macros.TEXT.whoseTip) end))
        end
    end))
end

local function Button(parent, text, width, click, tip, tipText)
    local button = Macros.Button(parent, text, width)
    button:SetScript("OnClick", ns.Guard(click))
    if tip then Core.Tip(button, tip, tipText) end
    return button
end

local function Left(inside, I)
    filterMenu = CreateFrame("DropdownButton", nil, inside, "WowStyle1DropdownTemplate")
    filterMenu:SetWidth(Editor.LIST - 24 - 90 - 8)
    filterMenu:SetPoint("TOPLEFT", I, -I + 4)
    filterMenu:SetupMenu(ns.Guard(FilterMenu))
    Core.Tip(filterMenu, Macros.TEXT.macros, Macros.TEXT.filterTip)
    Editor.filterMenu = filterMenu -- for the test
    list = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    list:SetPoint("TOPLEFT", inside, "TOPLEFT", I, -I - 26)
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
    gameHead = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gameHead:SetText(Macros.TEXT.gameMacros)
    local game = Macros.Button(inside, Macros.TEXT.gameWindow, 90, 18)
    game:SetPoint("TOPRIGHT", inside, "TOPLEFT", I + Editor.LIST - 24, -I + 2)
    game:SetScript("OnClick", ns.Guard(function() Editor.OpenGame() end))
    Core.Tip(game, Macros.TEXT.gameWindow, Macros.TEXT.gameWindowTip)
    Editor.gameButton = game
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
    picture:RegisterForClicks("LeftButtonUp")
    picture:SetScript("OnDragStart", ns.Guard(Editor.DragToBar))
    picture:SetScript("OnDragStop", ns.Guard(Macros.Place.Drop))
    picture:SetScript("OnClick", ns.Guard(Editor.ChoosePicture))
    -- The game's light under the mouse: it can be clicked.
    local lit = picture:CreateTexture(nil, "HIGHLIGHT")
    lit:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    lit:SetBlendMode("ADD")
    lit:SetAllPoints()
    Core.Tip(picture, Macros.TEXT.iconTitle, Macros.TEXT.picture)

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
    if not chosen then Editor.Choose(Macros.Book.Shown(Filter())[1]) else Fill() end
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
    Macros.Icons.Close()
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
    Macros.Icons.Close()
    Macros.Place.Stop()
    StopKey()
end

function Part.Size(width)
    Editor.Size(width)
end

ns.Board.Part(KEY, Macros.TEXT.title, Editor.LEAST, Part)

-- Something the checks or the game's macros read has changed: while the page shows, they look again.
local function Look()
    if (frame and frame:IsShown()) or onBoard then Fill() end
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
    for _, event in ipairs({ "SPELLS_CHANGED", "BAG_UPDATE_DELAYED", "UPDATE_MACROS" }) do ns.On(event, Look) end
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

function Editor.Line(index)
    return lines[index]
end

-- A switch of the module changed.
function Editor.Refresh()
    Fill()
end

function Editor.GiveBack()
    if window then window:GiveBack() end
    if frame then frame:Hide() end
end
