local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Menu
--  The list behind the chat's name in the line to write in (and the window's
--  chat button), in columns: the chats you can write in right now, the one you
--  write in marked (Channels.lua); everything the window can show, each with a
--  tick; the game's own channels, each with what it does on every character
--  (Join.lua). It is the game's menu (MenuUtil), in its grid.
--
--  It stays open while you choose: no choice closes it, and nor does the mouse
--  leaving the window, though the window's button goes out of sight then. Only
--  a click outside it or on the button it came from closes it (Toggle).
--
--  A choice writes where the edit box writes the game's own way: its
--  SetChatType, SetStickyType and SetChannelTarget, as the game's friends list
--  does for a whisper. That is our code changing the game's edit box: see the
--  README on taint.
-------------------------------------------------------------------------------
local Menu = {}
ns.Menu = Menu

local GAP = 16 -- between the columns

local editBox -- the line the list was opened for
local open    -- the list while it is open: the game's menu

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
local function Wished(choice) return ns.Join.Wished(choice.name) == choice.wish end
local function IsWished(choice) return ns.Safe("channels", Wished, choice) end
local function Wish(choice) ns.Safe("channels", ns.Join.Wish, choice.name, choice.wish) end

-- The game closes a menu when one of its radio lines is chosen; its check boxes leave it open by themselves.
local function WriteLine(root, channel)
    root:CreateRadio(channel.text, IsWriting, Choose, channel):SetResponse(MenuResponse.Refresh)
end

local function ShowLine(root, chat)
    root:CreateCheckbox(chat.text, IsShown, Switch, chat)
end

-- Each of the game's channels opens the three choices of what it does on every character.
local function ChannelLine(root, channel)
    local entry = root:CreateButton(channel.name)
    for _, choice in ipairs(ns.TEXT.wishes) do
        entry:CreateRadio(choice.text, IsWished, Wish, { name = channel.name, wish = choice.wish }):SetResponse(MenuResponse.Refresh)
    end
end

-- A column: its title, its lines and spacers down to the end of the longest. The game's grid runs down each column
-- and on at the top of the next, all equally long.
local function Column(root, title, list, rows, line)
    root:CreateTitle(title)
    for _, item in ipairs(list) do line(root, item) end
    for _ = #list + 1, rows do root:CreateSpacer() end
end

-- The game has closed it, or a list it opened: they all tell here.
local Gone = ns.Guard(function(menu)
    if menu == open then open = nil end
end)

local function Fill(_, root)
    local writes, shows = ns.Channels.List(), ns.Channels.Showable()
    local channels = ns.Safe("channels", ns.Join.List) or {}
    local rows = math.max(#writes, #shows, #channels)
    root:SetGridMode(MenuConstants.VerticalGridDirection, #channels > 0 and 3 or 2, GAP)
    root:AddMenuReleasedCallback(Gone)
    Column(root, ns.TEXT.writeIn, writes, rows, WriteLine)
    Column(root, ns.TEXT.showing, shows, rows, ShowLine)
    if #channels > 0 then Column(root, ns.TEXT.everywhere, channels, rows, ChannelLine) end
end

-- Closes the list; true if it was open.
function Menu.Close()
    if not open then return false end
    open:Close()
    return true
end

-- Opens the list at the mouse for the line line (the edit box in our window, if one is), or closes it if it is open.
-- It belongs to window, not to the button clicked: the game closes a menu whose owner goes, and the chat button goes
-- with the mouse.
function Menu.Toggle(window, line)
    if Menu.Close() then return end
    editBox = line
    open = MenuUtil.CreateContextMenu(window, function(menu, root) ns.Safe("the list", Fill, menu, root) end)
end

-- A press on a button of the list is the button's own (Toggle), not a click outside the list: the game would close
-- the list and the click open it again. As the game's own dropdown buttons do.
local Handles = ns.Guard(function(_, button, event)
    return event == "GLOBAL_MOUSE_DOWN" and button == "LeftButton"
end)

function Menu.Button(button)
    button.HandlesGlobalMouseEvent = Handles
end
