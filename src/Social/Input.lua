local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Input
--  The line you write in, at the bottom of our window.
--
--  It is the game's own edit box, not one of ours: only its place and its
--  look change. So everything it can do stays as it is and stays the game's
--  code: Enter and "/" open it, slash commands (/cast and the like must run
--  from the game's code, an addon's edit box may not), /w and /r, the
--  history, name completion, the label with the chat you write in.
--
--  The game tells when one of its edit boxes is shown, hidden or gets the
--  cursor ("ChatFrame.OnEditBoxShow" / "...Hide" / "...FocusGained"). Shown,
--  it is put into our window (Seat) and the window makes room above it;
--  hidden, the room is given back.
--
--  The line is only there while you write. One of the game's two chat styles
--  ("IM style") keeps its edit box on show when nobody writes, faded and
--  without the chat's name. Here such a line is made invisible and lets the
--  mouse through instead (Rest), and the window has its room back; when the
--  game gives it the cursor again, it is seen again (Rise). The game puts the
--  line to rest itself (its Deactivate, which we hook); one it shows empty and
--  without the cursor rests a frame later. So whenever the line can be seen,
--  the chat's name is in it. Our code never hides the edit box: hidden by an
--  addon, the game would tidy up its chat state under that addon's taint.
--
--  Its look (Dress): the game's border art is made invisible and a plain
--  round-cornered plate of ours lies behind it: the very fill of the
--  bubbles, same grey, same corners, as see-through as they are. And it is set
--  to wrap its text: when the text is wider than the line, the line grows
--  taller (Grow) and the window gives it more room. For that the chat's name
--  hangs on the line's top instead of its middle, and the text gets an inset
--  above and below. All of it is undone when our window goes (Release): what
--  is changed of the game's (the edit box's place, its layer, its alpha and
--  mouse at rest, its label's place, its border's alpha) is lent (Core.Lend),
--  each thing noted the first time it is changed and given back exactly.
--
--  A click on the chat's name, or on the window's button, opens the list of
--  the chats you can write in (Menu.lua). The smiley right of the line is
--  there while the line is (Picker.lua). The button on the name is a child of
--  the edit box, so it is above it and shown with it; nothing is written into
--  the edit box itself.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Input = {}
ns.Input = Input

local window, room  -- our window, and room(height or false): it makes or gives back the room for the line
local area          -- the part of the window the line stands at the bottom of: the chat's (Window.lua)
local given = false -- the height the window makes room for now; false: none
local seated        -- the edit box in our window now
local home = {}     -- [edit box] = its place, lent: in our window
local dressed = {}  -- [edit box] = its look, lent: its border's pieces (their alpha), its label (.header): ours now
local hooked = {}   -- [edit box] = true: it tells us of its text, its label and its rest
local drawn = {}    -- [edit box] = its layer, lent: drawn with our window
local resting = {}  -- [edit box] = its alpha and mouse, lent: at rest (invisible, the mouse goes through)
local label         -- the button on the edit box's label
local plate, ruler  -- the frame behind the line (of our window), and the text that measures the line's
local fill          -- that frame's fill (Core's Shape): drawn as your own bubbles are

local function Label(editBox)
    if not label then
        label = CreateFrame("Button")
        label:SetHeight(24)
        label:SetScript("OnClick", function(self) ns.Guarded(ns.Menu.Open, self, seated) end)
    end
    local header = editBox.header
    label:SetShown(header ~= nil)
    if not header then return end
    label:SetParent(editBox)
    label:ClearAllPoints()
    label:SetPoint("LEFT", header, "LEFT", -4, 0)
    label:SetPoint("RIGHT", header, "RIGHT", 4, 0)
end

-------------------------------------------------------------------------------
--  The line's look and height
-------------------------------------------------------------------------------
-- The pieces of the game's border around an edit box, by what they are called after its name.
local ART = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }

-- The line in our window, and in use (not at rest).
local function InUse(editBox)
    return editBox == seated and dressed[editBox] ~= nil and not resting[editBox]
end

-- The window makes room for a line that high, or gives the room back (false). Only when that
-- changes: the line's text changes with every key.
local function Give(height)
    if height == given then return end
    given = height
    room(height)
end

local function FontSize(editBox)
    local _, size = editBox:GetFont()
    return Core.Plain(size) or 14
end

-- The text's room left and right: the game counts the left one from the width of the chat's name,
-- which may be a name it hides (a whisper's, during messaging lockdown): then nil.
local function Insets(editBox)
    local left, right = editBox:GetTextInsets()
    return Core.Plain(left), Core.Plain(right)
end

-- The room above and below the text that puts one line in the middle of a line of the first height.
-- The game sets the insets anew with every change of the label, without these two.
local function Inset(editBox)
    local left, right = Insets(editBox)
    if not (left and right) then return end
    local pad = math.floor((Layout.INPUT_HEIGHT - FontSize(editBox)) / 2)
    editBox:SetTextInsets(left, right, pad, pad)
end

-- As tall as its text needs, and the window makes room for that.
local function Grow(editBox)
    local left, right = Insets(editBox)
    local width = (Core.Plain(editBox:GetWidth()) or 0) - (left or 15) - (right or 13)
    local height = Layout.INPUT_HEIGHT
    if width > 0 then
        ruler:SetFont(editBox:GetFont())
        ruler:SetWidth(width)
        ruler:SetText(editBox:GetText())
        height = Layout.InputHeight(ruler:GetStringHeight(), ruler:GetLineHeight())
    end
    editBox:SetHeight(height)
    Give(height)
end

-- The window's width changed, and the line's with it.
function Input.Grow()
    if seated and seated:IsShown() and not resting[seated] then Grow(seated) end
end

-- The line's fill follows the bubbles' (their transparency is a setting).
function Input.Paint()
    if fill then ns.Bubble.Paint(fill) end
end

local function Changed(editBox)
    if InUse(editBox) then ns.Guarded(Grow, editBox) end
end

-- The label's width is the text's left inset: both the insets and the height follow it.
local function Relabelled(editBox)
    if not InUse(editBox) then return end
    ns.Guarded(Inset, editBox)
    ns.Guarded(Grow, editBox)
end

-- Nobody writes in the line, and the game keeps it on show (IM style): out of sight instead, and the
-- room above it is the messages' again. Its alpha and mouse are lent, to give them back when it is in use
-- again or our window goes. Again and again if need be: the game makes a line at rest faded (not
-- invisible) each time.
local function Rest(editBox)
    local rest = resting[editBox] or Core.Lend(editBox)
    resting[editBox] = rest
    rest:SetAlpha(0)
    rest:SetMouse(false)
    if label then label:EnableMouse(false) end -- the button on the chat's name, unseen, would take clicks
    plate:Hide()
    ns.Picker.Show(nil)
    Give(false)
end

-- A line at rest is in use again: it can be seen and clicked. (The game sets its alpha itself too
-- when it gives it the cursor.)
local function Rise(editBox)
    if not resting[editBox] then return end
    resting[editBox] = nil -- what was lent for the rest: in use, it is seen and clicked
    editBox:SetAlpha(1)
    editBox:EnableMouse(true)
    if label then label:EnableMouse(true) end
end

-- The game has put the line to rest (Esc, sent, the cursor gone). In its classic style it hides the
-- line itself; in its IM style the line stays on show, and rests here.
local function Deactivated(editBox)
    if editBox == seated and editBox:IsShown() then ns.Guarded(Rest, editBox) end
end

local function Dress(editBox)
    if not dressed[editBox] then
        local look = {}
        local name = editBox:GetName()
        for _, piece in ipairs(ART) do
            local art = name and _G[name .. piece]
            if art then
                local lent = Core.Lend(art)
                lent:SetAlpha(0)
                look[#look + 1] = lent
            end
        end
        editBox:SetMultiLine(true)
        local header = editBox.header
        if header then
            -- Where it is in a line of the first height, but counted from the top: it stays on the first line.
            look.header = Core.Lend(header)
            look.header:SetPoints(function(region)
                region:ClearAllPoints()
                region:SetPoint("TOPLEFT", 15, -math.floor((Layout.INPUT_HEIGHT - (Core.Plain(region:GetHeight()) or 14)) / 2))
            end)
        end
        dressed[editBox] = look
    end
    if not hooked[editBox] then
        hooked[editBox] = true
        editBox:HookScript("OnTextChanged", Changed)
        if editBox.UpdateHeader then hooksecurefunc(editBox, "UpdateHeader", Relabelled) end
        if editBox.Deactivate then hooksecurefunc(editBox, "Deactivate", Deactivated) end
    end
    plate:ClearAllPoints()
    plate:SetPoint("TOPLEFT", editBox, "TOPLEFT", Layout.INPUT_INSET, -Layout.INPUT_INSET)
    plate:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -Layout.INPUT_INSET, Layout.INPUT_INSET)
    plate:Show()
    Input.Paint()
    Inset(editBox)
    ns.Picker.Show(editBox)
end

local function Undress(editBox, look)
    for _, lent in ipairs(look) do lent:Return() end
    editBox:SetMultiLine(false)
    editBox:SetHeight(Layout.INPUT_HEIGHT)
    local left, right = Insets(editBox)
    if left and right then editBox:SetTextInsets(left, right, 0, 0) end
    if look.header then look.header:Return() end
end

-- A text that wraps can hold line breaks (pasted ones); a chat message cannot. The game tells
-- before it sends, for just such last changes.
local function Sending(editBox)
    if not window or editBox ~= seated then return end
    local text = editBox:GetText()
    if text:find("[\r\n]") then editBox:SetText((text:gsub("[\r\n]+", " "))) end
end

-------------------------------------------------------------------------------
--  The edit box's place
-------------------------------------------------------------------------------
local function Place(editBox)
    editBox:ClearAllPoints()
    editBox:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", Layout.INPUT_LEFT, Layout.INPUT_BOTTOM)
    editBox:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -Layout.INPUT_RIGHT, Layout.INPUT_BOTTOM)
end

local function Seat(editBox)
    home[editBox] = home[editBox] or Core.Lend(editBox)
    home[editBox]:SetPoints(Place)
    seated = editBox
    Rise(editBox)
    Label(editBox)
    Dress(editBox)
    Grow(editBox)
end

-- The game puts the line you write in above everything; ours is as high as the window it is in.
-- What it had is lent, to give back.
local function Lift(editBox)
    drawn[editBox] = drawn[editBox] or Core.Lend(editBox)
    drawn[editBox]:SetLayer(window:GetFrameStrata(), window:GetFrameLevel() + 10)
end

-- The window is drawn in another layer now (it fills the screen, or is back): a line in use goes with it.
function Input.Layer()
    if window and seated and drawn[seated] and not resting[seated] then Lift(seated) end
end

-- An empty line without the cursor is nobody's: it rests. One in use is drawn with our window.
local function Idle(editBox)
    if not window or not editBox:IsShown() or resting[editBox] then return end
    if not editBox:HasFocus() and editBox:GetText() == "" then
        Rest(editBox)
        return
    end
    Lift(editBox)
end

-- The game shows the line first and gives it the cursor after: look again when it is done.
local Check = Core.Later(function()
    if seated then ns.Guarded(Idle, seated) end
end)

local function Shown(editBox)
    if not window then return end
    Seat(editBox)
    Check()
end

-- The cursor came into a line. The game does not show a line at rest anew (it is on show): it is in
-- use again from here.
local function Focused(editBox)
    if resting[editBox] or editBox ~= seated then Shown(editBox) end
end

local function Hidden(editBox)
    if not window or editBox ~= seated then return end
    plate:Hide()
    ns.Picker.Show(nil)
    Give(false)
end

-- What the game tells of its edit boxes, and what is done then.
local TOLD = {
    { "ChatFrame.OnEditBoxShow", Shown },
    { "ChatFrame.OnEditBoxHide", Hidden },
    { "ChatFrame.OnEditBoxFocusGained", Focused },
    { "ChatFrame.OnEditBoxPreSendText", Sending },
}

local listening
local function Listen()
    if listening then return end
    listening = true
    for _, told in ipairs(TOLD) do
        local step = told[2]
        EventRegistry:RegisterCallback(told[1], function(_, editBox) ns.Guarded(step, editBox) end, Input)
    end
end

-- The module stood down: nothing of the game's edit boxes is heard any more.
function Input.Forget()
    if not listening then return end
    listening = false
    for _, told in ipairs(TOLD) do EventRegistry:UnregisterCallback(told[1], Input) end
end

-- Our window is open: the game's edit boxes belong into it, at the bottom of chat, the chat's part of it
-- (without: the whole window). makeRoom(height or false) is the window's.
function Input.Take(frame, makeRoom, chat)
    window, room, area = frame, makeRoom, chat or frame
    if not plate then
        plate = CreateFrame("Frame", nil, frame)
        plate:SetFrameLevel(frame:GetFrameLevel() + 5) -- above the list, below the edit box
        fill = Core.Shape.New(plate, { radius = Layout.RADIUS }) -- the bubbles' plate, following the line's size
        fill:Follow()
        plate:Hide()
        ruler = ns.Ruler(frame) -- never seen (Bubble.lua)
        ns.Picker.Take(frame, area)
    end
    Listen()
    -- One that is shown already (the game's "IM style" keeps it on show).
    for _, name in ipairs(CHAT_FRAMES) do
        local editBox = _G[name .. "EditBox"]
        if editBox and editBox:IsShown() then
            Seat(editBox)
            Idle(editBox)
        end
    end
end

-- The window's button: closes the line as Esc does, or opens it as Enter does and shows where you
-- can write, the chat you write in marked.
function Input.Toggle(owner)
    if seated and seated:IsShown() and not resting[seated] then
        seated:ClearChat()
    else
        ChatFrameUtil.OpenChat(nil)
        ns.Menu.Open(owner, seated)
    end
end

-- One step of Release; the first failure is kept, and raised when all steps are done.
local problem
local function Try(step, ...)
    local ok, failed = xpcall(step, Core.Trace, ...)
    if not ok and not problem then problem = failed end
end

-- One edit box as the game had it, each thing by itself: its place first, then its look, its layer and,
-- if it was at rest, its alpha and the mouse.
local function Return(editBox)
    local place, look, layer, rest = home[editBox], dressed[editBox], drawn[editBox], resting[editBox]
    Try(place.Return, place)
    if look then Try(Undress, editBox, look) end
    -- The game may have set a layer of its own since (a line at rest is low): that one stays.
    if layer and editBox:GetFrameStrata() == window:GetFrameStrata() then Try(layer.Return, layer) end
    if rest then Try(rest.Return, rest) end
end

-- Our window is gone: every edit box is where the game had it, and looks as the game made it. Each
-- by itself, so one that fails keeps no other in our window.
function Input.Release()
    if not window then return end
    problem = nil
    for editBox in pairs(home) do Return(editBox) end
    wipe(home)
    wipe(dressed)
    wipe(drawn)
    wipe(resting)
    if label then
        label:Hide()
        label:SetParent(window)
    end
    plate:Hide()
    ns.Picker.Show(nil)
    local giveBack = given and room
    window, room, area, seated, given = nil, nil, nil, nil, false
    if giveBack then Try(giveBack, false) end
    if problem then error(problem, 0) end
end
