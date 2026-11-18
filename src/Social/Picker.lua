local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Picker
--  The smiley right of the line you write in, and the list it opens: the
--  game's raid marks, to put into the line, and the emotes played most, to
--  do at once. The smiley is there while the line is (Input.lua).
--
--  The marks are the only pictures the game's chat draws from what a player
--  writes: {rt1} to {rt8}, the same in every language
--  (C_ChatInfo.ReplaceIconAndGroupExpressions). The server takes them out of
--  the game's own public channels (General, Trade, ...: the message's
--  suppressRaidIcons), so they are not offered while you write in one of those.
--
--  The emotes are done as the game's chat menu does them (PerformEmote), at
--  your target if you have one, as the typed command would be; each named by
--  its command in the game's language (/hello). None while chat is locked
--  down: the game refuses them to an addon then.
--
--  The list is the game's menu (MenuUtil), as the one on the chat's name; the
--  marks stand in one row in it, as small buttons (MenuTemplates).
--
--  An empty line loses the cursor to a press on the smiley, and the game puts
--  an empty line without the cursor to rest (ShouldDeactivateChatOnEditFocusLost);
--  the smiley would go with it, and the game closes a menu whose owner goes
--  (Saneroki, 2026-11-18: "While the input field is empty clicking the smiley
--  will close the input"). So the smiley stays for its own click (pressed),
--  the list belongs to the window, the line is opened again, and a mark
--  chosen goes into the line it was opened for (for), opened again if needed.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Picker = {}
ns.Picker = Picker

local ART = "Interface\\AddOns\\SaneUI_Social\\Art\\smiley.blp" -- SaneUI's own (dev/tools/smiley-art)
local FALLBACK = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"   -- the game's chat button, should ours be missing
local MARK = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d" -- as the game's chat draws them (ICON_LIST)
local MARKS, MARK_SIZE, MARK_GAP, MARK_PAD = 8, 20, 4, 10
local ROW_WIDTH, ROW_HEIGHT = 2 * MARK_PAD + MARKS * MARK_SIZE + (MARKS - 1) * MARK_GAP, MARK_SIZE + 6
-- The emotes, by the game's tokens (EMOTE<n>_TOKEN): greetings and thanks first.
Picker.EMOTES = { "HELLO", "WAVE", "BYE", "THANK", "WELCOME", "CHEER", "APPLAUD", "CONGRATULATE", "LAUGH",
                  "DANCE", "BOW", "HUG" }
local ZONE = Enum and Enum.PermanentChatChannelType and Enum.PermanentChatChannelType.Zone or 1

local button   -- the smiley
local holder   -- the window it stands in: the list's owner
local editBox  -- the line it belongs to now
local pressed  -- the line the smiley was pressed for, until its click is done
local listFor  -- the line the list was opened for

-- Whether what is written in that line can show the marks: not in one of the game's public channels.
function Picker.Marks(line)
    if line:GetChatType() ~= "CHANNEL" then return true end
    local _, name = GetChannelName(line:GetChannelTarget())
    local info = name and C_ChatInfo and Core.Ask(C_ChatInfo.GetChannelInfoFromIdentifier, name)
    return not (type(info) == "table" and Core.Plain(info.channelType) == ZONE)
end

-- An emote's command in the game's language ("/hello"), found once among the game's emotes.
local commands
function Picker.Command(token)
    if not commands then
        commands = {}
        for index = 1, rawget(_G, "MAXEMOTEINDEX") or 1000 do
            local known = rawget(_G, "EMOTE" .. index .. "_TOKEN")
            if known then commands[known] = rawget(_G, "EMOTE" .. index .. "_CMD1") end
        end
    end
    return commands[token] or ("/" .. token:lower())
end

-- The line in use again, the cursor in it: an empty one the game put to rest is opened anew.
local function Again(line)
    if line and not line:HasFocus() then ChatFrameUtil.ActivateChat(line) end
end

-- A mark goes into the line the list was opened for where the cursor is; the cursor stays in the line.
local function Mark(index)
    local line = listFor or editBox
    if not line then return end
    Again(line)
    if not line:IsShown() then return end
    line:Insert(("{rt%d}"):format(index))
end

local function Emote(token)
    local Perform = C_ChatInfo and C_ChatInfo.PerformEmote or rawget(_G, "DoEmote")
    if Perform then Perform(token) end
end

-- The row of marks: a button for each, its name as its tooltip. Made anew each time the list opens
-- (the menu lends the frame and takes back what was put on it).
local function Row(frame, _, menu)
    for index = 1, MARKS do
        local mark = MenuTemplates.AttachBasicButton(frame, MARK_SIZE, MARK_SIZE)
        mark:SetPoint("LEFT", MARK_PAD + (index - 1) * (MARK_SIZE + MARK_GAP), 0)
        mark:SetNormalTexture(MARK:format(index))
        mark:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        mark:SetScript("OnClick", ns.Guard(function()
            ns.Guarded(Mark, index)
            Menu.GetManager():CloseMenu(menu)
        end))
        local name = rawget(_G, "RAID_TARGET_" .. index)
        if name then MenuUtil.HookTooltipScripts(mark, ns.Guard(function(tooltip) GameTooltip_SetTitle(tooltip, name) end)) end
    end
end

-- The menu asks and tells outside our own guard.
local function Do(token) ns.Guarded(Emote, token) end
-- The row's size goes back to the menu, which makes its line that large.
local function Lay(...)
    ns.Guarded(Row, ...)
    return ROW_WIDTH, ROW_HEIGHT
end

local function Fill(_, root)
    root:CreateTitle(ns.TEXT.marks)
    local line = listFor or editBox
    if line and ns.Guarded(Picker.Marks, line) then
        root:CreateFrame():AddInitializer(ns.Guard(Lay))
    else
        root:CreateButton(ns.TEXT.noMarks):SetEnabled(false)
    end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.emotes)
    -- While chat is locked down (a fight, a dungeon) the game refuses emotes to our code, as it does messages.
    if ns.ChatLocked() then
        root:CreateButton(ns.TEXT.noEmotes):SetEnabled(false)
        return
    end
    for _, token in ipairs(Picker.EMOTES) do root:CreateButton(Picker.Command(token), ns.Guard(Do), token) end
end

-- The list, the window's (the smiley may go with an empty line); that line open again for a mark.
function Picker.Open()
    local line = editBox or pressed
    pressed = nil
    listFor = line
    Again(line)
    MenuUtil.CreateContextMenu(holder or button, ns.Guard(Fill))
end

-- The smiley, made with our window: at the line's right end, before the grip, on its first line's
-- height and staying at the bottom when the line grows; in the part of the window the line is in (area: the
-- chat's, Window.lua). Out of sight until the line is there.
function Picker.Take(frame, area)
    if button then return end
    holder = frame
    button = CreateFrame("Button", nil, frame)
    button:SetSize(Layout.FACE, Layout.FACE)
    button:SetPoint("BOTTOMRIGHT", area or frame, "BOTTOMRIGHT", -Layout.GRIP_ROOM, Layout.INPUT_BOTTOM + (Layout.INPUT_HEIGHT - Layout.FACE) / 2)
    button:SetFrameLevel(frame:GetFrameLevel() + Layout.INPUT_LEVEL) -- with the line, above the list
    for _, kind in ipairs({ "Normal", "Pushed" }) do
        local art = button:CreateTexture()
        if not art:SetTexture(ART) then art:SetTexture(FALLBACK) end -- false: the file is missing
        if kind == "Pushed" then art:SetVertexColor(0.75, 0.75, 0.75) end -- pressed, a little darker
        button["Set" .. kind .. "Texture"](button, art)
    end
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetScript("OnMouseDown", ns.Guard(function() pressed = editBox end))
    button:SetScript("OnClick", function() ns.Guarded(Picker.Open) end)
    Core.Tip(button, ns.TEXT.picker, nil, "ANCHOR_TOP")
    button:Hide()
end

-- The line is there to write in (line), or gone (nil).
function Picker.Show(line)
    editBox = line
    if not button then return end
    -- The line rests because the smiley took its cursor: the smiley stays for its click (Open).
    if line == nil and pressed and Core.Plain(button:IsMouseOver()) == true then return end
    button:SetShown(line ~= nil)
end
