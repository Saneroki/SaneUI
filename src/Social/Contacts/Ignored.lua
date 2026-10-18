local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Ignored
--  The ignore list, as the game's window of it beside its friends list: the
--  players you ignore, and under them the Battle.net accounts whose invites
--  you block, each under the game's heading. Opened from the contacts menu
--  (the head's square button), in place of the friends list; Back goes back.
--
--  A click chooses one; Remove takes them off the list (C_FriendList.DelIgnore-
--  ByIndex, or C_BattleNet.SetBlocked); Ignore Player adds the player you have
--  targeted, or asks for a name in the game's dialog (C_FriendList.AddIgnore).
--  Read anew when the game tells of a change, only while it is shown; the
--  search box finds them by name.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Contacts = ns.Board, ns.Contacts
local View = { name = Core.Word("IGNORE_LIST", "Ignore List") }
Contacts.Ignored = View

local box, remove
local shown
local chosen -- the one chosen: "ignore:<index>" or "block:<id>"
local query
local listed = {}

local function Read()
    local ignored, blocked = {}, {}
    for index = 1, C_FriendList.GetNumIgnores and C_FriendList.GetNumIgnores() or 0 do
        local name = C_FriendList.GetIgnoreName(index)
        ignored[#ignored + 1] = { kind = "ignore", key = "ignore:" .. index, index = index, name = name or Core.Word("UNKNOWN", "Unknown") }
    end
    for index = 1, rawget(_G, "BNGetNumBlocked") and BNGetNumBlocked() or 0 do
        local id, name = BNGetBlockedInfo(index)
        if id then blocked[#blocked + 1] = { kind = "block", key = "block:" .. id, id = id, name = name or "?" } end
    end
    return ignored, blocked
end

local function Update()
    if not shown then return end
    local ignored, blocked = Read()
    wipe(listed)
    local elements = {}
    local function Part(title, list)
        local found = {}
        for _, entry in ipairs(list) do
            listed[#listed + 1] = entry
            if not query or Core.Fuzzy.Match(query, entry.name) then found[#found + 1] = entry end
        end
        if #found == 0 then return end
        elements[#elements + 1] = { kind = "title", name = title }
        for _, entry in ipairs(found) do elements[#elements + 1] = entry end
    end
    Part(Core.Word("IGNORED", "Ignored"), ignored)
    Part(Core.Word("BLOCKED_INVITES", "Blocked Invites"), blocked)
    Board.Fill(box, elements, query and ns.TEXT.noneFound or ns.TEXT.noIgnored)
    local any = false
    for _, entry in ipairs(listed) do any = any or entry.key == chosen end
    remove:SetEnabled(any)
end

local Changed = Core.Later(function() ns.Safe("ignore list", Update) end)

local function Draw(row, entry)
    Board.Row(row)
    row.entry = entry
    if entry.kind == "title" then return Contacts.Divider(row, entry.name) end
    Contacts.Entry(row)
    row.back:SetColorTexture(1, 1, 1, 0.03)
    row.icon:Hide()
    row.top:ClearAllPoints()
    row.top:SetPoint("LEFT", 12, 0)
    row.top:SetPoint("RIGHT", -8, 0)
    row.top:SetText(entry.name)
    row.top:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    row.bottom:SetText("")
    row.side:Hide()
    row.right:SetText("")
    if entry.key == chosen then row:LockHighlight() else row:UnlockHighlight() end
end

local function Click(row)
    local entry = row.entry
    if not entry or entry.kind == "title" then return end
    chosen = entry.key
    Contacts.Mark(box, "key", chosen)
    remove:Enable()
end

local function Remove()
    for _, entry in ipairs(listed) do
        if entry.key == chosen then
            if entry.kind == "ignore" then C_FriendList.DelIgnoreByIndex(entry.index) else C_BattleNet.SetBlocked(entry.id, false) end
            chosen = nil
            return
        end
    end
end

-- The friendly player targeted is ignored at once (as the game's button does); else a name is asked for.
local function Ignore()
    if UnitExists("target") and UnitIsPlayer("target") and UnitCanCooperate("player", "target") then
        local name, realm = UnitName("target")
        if name then return C_FriendList.AddIgnore(realm and realm ~= "" and name .. "-" .. realm or name) end
    end
    Core.AskText(Core.Word("ADD_IGNORE_LABEL", "Enter the name of the player you want to ignore:"), nil,
        Core.Word("ACCEPT", "Accept"), nil, function(text)
            text = strtrim(text or "")
            if text ~= "" then C_FriendList.AddIgnore(text) end
        end, 48)
end

function View.Build(page)
    box = Board.List(page, function(row, entry)
        Draw(row, entry)
        row:SetScript("OnClick", function(self) ns.Safe("ignore list", Click, self) end)
    end)
    local back = Board.Button(page, Core.Word("BACK", "Back"), 70, function() ns.Friends.Open("Friends") end)
    local ignore = Board.Button(page, Core.Word("IGNORE_PLAYER", "Ignore Player"), 116, Ignore, back)
    remove = Board.Button(page, Core.Word("REMOVE", "Remove"), 100, Remove, ignore)
    remove:Disable()
end

local EVENTS = { "IGNORELIST_UPDATE", "BN_BLOCK_LIST_UPDATED" }

function View.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if on then Update() end
end

function View.Search(found)
    query = found
    Update()
end
