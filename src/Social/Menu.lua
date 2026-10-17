local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Menu
--  The list behind the chat's name in the line to write in (and the window's
--  chat button): the chats you can write in right now, the one you write in
--  marked (Channels.lua); under them everything the window can show, each
--  with a tick; last the game's own channels, each with what it does on every
--  character (Join.lua). It is the game's menu (MenuUtil).
--
--  A choice writes where the edit box writes the game's own way: its
--  SetChatType, SetStickyType and SetChannelTarget, as the game's friends list
--  does for a whisper. That is our code changing the game's edit box: see the
--  README on taint.
-------------------------------------------------------------------------------
local Menu = {}
ns.Menu = Menu

local editBox -- the line the list was opened for

local function Writing(channel)
    if not editBox or editBox:GetChatType() ~= channel.kind then return false end
    return channel.kind ~= "CHANNEL" or editBox:GetChannelTarget() == channel.target
end

-- The game's own way to set where an edit box writes. Kept as the chat to come back to, like one
-- you have just written in.
local function Write(channel)
    if not editBox then return end
    editBox:SetChatType(channel.kind)
    editBox:SetStickyType(channel.kind)
    if channel.target then editBox:SetChannelTarget(channel.target) end
    ChatFrameUtil.ActivateChat(editBox) -- shows it, puts the cursor in it and writes the label anew
end

-- The menu asks and tells outside our own guard. A tick flipped is a switch set (Channels.Flip): the
-- window shows the list anew, and an open options page shows the switch as it is now.
local function IsWriting(channel) return ns.Guarded(Writing, channel) end
local function Choose(channel) ns.Guarded(Write, channel) end
local function IsShown(chat) return ns.Guarded(ns.Channels.Shown, chat.group) end
local function Switch(chat) ns.Guarded(ns.Channels.Flip, chat.group) end
-- The game's channels are apart from the window: a failure there is noted, the window stays.
local function IsWished(choice) return ns.Join.Wished(choice.name) == choice.wish end
local function Wish(choice) ns.Safe("channels", ns.Join.Wish, choice.name, choice.wish) end

local function Fill(_, root)
    root:CreateTitle(ns.TEXT.writeIn)
    for _, channel in ipairs(ns.Channels.List()) do
        root:CreateRadio(channel.text, IsWriting, Choose, channel)
    end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.showing)
    for _, chat in ipairs(ns.Channels.Showable()) do
        root:CreateCheckbox(chat.text, IsShown, Switch, chat)
    end
    -- Each of the game's channels opens the three choices of what it does on every character.
    local channels = ns.Safe("channels", ns.Join.List) or {}
    if #channels == 0 then return end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.everywhere)
    for _, channel in ipairs(channels) do
        local entry = root:CreateButton(channel.name)
        for _, choice in ipairs(ns.TEXT.wishes) do
            entry:CreateRadio(choice.text, IsWished, Wish, { name = channel.name, wish = choice.wish })
        end
    end
end

-- Opens the list at owner, for the line line (the edit box in our window, if one is).
function Menu.Open(owner, line)
    editBox = line
    MenuUtil.CreateContextMenu(owner, Fill)
end
