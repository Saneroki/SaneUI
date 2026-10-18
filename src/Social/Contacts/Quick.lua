local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Quick
--  Quick Join, as the game's tab of its friends list (Blizzard_QuickJoin): the
--  groups your friends, your guild and your communities are in or queued
--  with, that you may ask to join (C_SocialQueue). A row: who you know there,
--  in the game's colour of what they are to you (and how many more are with
--  them), what the group is queued for, and how many it is.
--
--  As the game's: a click chooses a group; Join Queue (Sign Up for a listed
--  group) asks the roles you would join as, those your class can play, ticked
--  as you last chose them in the group finder (GetLFGRoles), and asks the
--  group (C_SocialQueue.RequestToJoin). Not while you are in a group of your
--  own: the button says so. Send Message whispers the one you know; a right
--  click opens the same.
--
--  Its count is on the tab, Quick Join (2). Read anew when the game tells of a
--  change, only while the tab is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Contacts = ns.Board, ns.Contacts
local View = { name = Core.Word("QUICK_JOIN", "Quick Join") }
Contacts.Quick = View

local box, join, send
local shown
local chosen -- the group chosen: its GUID
local query
local groups = {}
local roles = {} -- the roles ticked in the menu of Join Queue: [TANK/HEALER/DAMAGER] = true

local function System() return rawget(_G, "C_SocialQueue") end

function View.Usable()
    local rules, rule = rawget(_G, "C_GameRules"), Enum and Enum.GameRule and Enum.GameRule.DisableQuickJoin
    return System() ~= nil and not (rules and rule and Core.Ask(rules.IsGameRuleActive, rule))
end

function View.Label()
    local system = System()
    local count = system and #(Core.Ask(system.GetAllGroups) or {}) or 0
    return count > 0 and ns.TEXT.quickCount:format(View.name, count) or View.name
end

-- A member as you know them: the name, the game's colour code for it, and how to whisper them.
local function Known(member)
    local relation = rawget(_G, "SocialQueueUtil_GetRelationshipInfo")
    local name, colour, kind
    if relation then name, colour, kind = Core.Ask(relation, member.guid, nil, member.clubId) end
    if not name then
        local _, _, _, _, _, player, realm = GetPlayerInfoByGUID(member.guid)
        name = player and (realm and realm ~= "" and player .. "-" .. realm or player) or Core.Word("UNKNOWNOBJECT", "Unknown")
    end
    return { name = name, colour = colour, bnet = kind == "bnfriend" }
end

-- What a group is queued for, in the game's words for a queue.
local function Queues(list)
    local names = rawget(_G, "SocialQueueUtil_GetQueueName")
    local words = {}
    for _, queue in ipairs(list or {}) do
        local name = names and queue.queueData and Core.Ask(names, queue.queueData)
        if name and name ~= "" then words[#words + 1] = name end
    end
    return table.concat(words, ", ")
end

local function Read()
    local system, found = System(), {}
    for _, guid in ipairs(Core.Ask(system.GetAllGroups) or {}) do
        local members = system.GetGroupMembers(guid) or {}
        local queues = system.GetGroupQueues(guid) or {}
        local canJoin, count = system.GetGroupInfo(guid)
        if members[1] then
            local listed = queues[1] and queues[1].queueData and queues[1].queueData.queueType == "lfglist"
            found[#found + 1] = { guid = guid, known = Known(members[1]), others = #members - 1, queued = Queues(queues),
                                  canJoin = canJoin and (count or 0) > 0, listed = listed, size = #members }
        end
    end
    return found
end

local function Chosen()
    for _, group in ipairs(groups) do
        if group.guid == chosen then return group end
    end
end

local function InGroup() return IsInGroup(rawget(_G, "LE_PARTY_CATEGORY_HOME")) end

local function Buttons()
    local group = Chosen()
    join:SetText(group and group.listed and Core.Word("SIGN_UP", "Sign Up") or Core.Word("JOIN_QUEUE", "Join Queue"))
    join:SetEnabled(group ~= nil and group.canJoin and not InGroup())
    send:SetEnabled(group ~= nil)
end

local function Update()
    if not shown then return end
    wipe(groups)
    local elements = {}
    for _, group in ipairs(Read()) do
        groups[#groups + 1] = group
        if not query or Core.Fuzzy.Match(query, group.known.name, group.queued) then elements[#elements + 1] = group end
    end
    Board.Fill(box, elements, query and ns.TEXT.noneFound or ns.TEXT.noQuick)
    Buttons()
end

local Changed = Core.Later(function() ns.Safe("quick join", Update) end)

local function Draw(row, group)
    Board.Row(row)
    Contacts.Entry(row)
    row.group = group
    local back = Contacts.BACKS.bnet
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:ClearAllPoints()
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", 6, 0)
    row.icon:SetAtlas("groupfinder-icon-leader")
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 34, -4)
    row.top:SetPoint("TOPRIGHT", -40, -4)
    local name = (group.known.colour or "") .. group.known.name .. (group.known.colour and "|r" or "")
    if group.others > 0 then name = name .. " " .. GRAY_FONT_COLOR:WrapTextInColorCode("+" .. group.others) end
    row.top:SetText(name)
    row.top:SetTextColor(Contacts.WOW[1], Contacts.WOW[2], Contacts.WOW[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(group.queued)
    row.side:Hide()
    row.right:SetText(tostring(group.size))
    if row.invite then row.invite:Hide() end
    if group.guid == chosen then row:LockHighlight() else row:UnlockHighlight() end
end

local function Whisper(group)
    if group then Contacts.Tell(group.known.name, group.known.bnet) end
end

local function Click(row, button)
    local group = row.group
    if not group then return end
    if button == "RightButton" then
        return MenuUtil.CreateContextMenu(row, function(_, root)
            root:CreateTitle(group.known.name)
            root:CreateButton(Core.Word("WHISPER", "Whisper"), function() Whisper(group) end)
        end)
    end
    chosen = group.guid
    Contacts.Mark(box, "guid", chosen)
    Buttons()
end

-- The roles you can play, and those you chose last in the group finder.
local function Roles()
    local can = { TANK = true, HEALER = true, DAMAGER = true }
    local available = (C_LFGList and C_LFGList.GetAvailableRoles) or rawget(_G, "GetAvailableRoles")
    if available then
        local ok, tank, healer, damage = pcall(available)
        if ok and tank ~= nil then can = { TANK = tank, HEALER = healer, DAMAGER = damage } end
    end
    local last = rawget(_G, "GetLFGRoles")
    if next(roles) == nil and last then
        local ok, _, tank, healer, damage = pcall(last)
        if ok then roles = { TANK = tank or nil, HEALER = healer or nil, DAMAGER = damage or nil } end
    end
    return can
end

local ROLE_WORDS = { { "TANK", "Tank" }, { "HEALER", "Healer" }, { "DAMAGER", "Damage" } }

-- Join Queue: the roles to join as, then the request; as the game's own role check before it asks.
local function Join(button)
    local group = Chosen()
    if not group or InGroup() then return end
    local can = Roles()
    MenuUtil.CreateContextMenu(button, function(_, root)
        root:CreateTitle(Core.Word("ROLE", "Role"))
        local function IsTicked(role) return roles[role] == true end
        local function Tick(role) roles[role] = not roles[role] or nil end
        for _, role in ipairs(ROLE_WORDS) do
            if can[role[1]] then root:CreateCheckbox(Core.Word(role[1], role[2]), IsTicked, Tick, role[1]) end
        end
        root:CreateButton(group.listed and Core.Word("SIGN_UP", "Sign Up") or Core.Word("JOIN_QUEUE", "Join Queue"), function()
            if not (roles.TANK or roles.HEALER or roles.DAMAGER) then
                return UIErrorsFrame:AddMessage(ns.TEXT.chooseRole, 1, 0.1, 0.1)
            end
            ns.Safe("quick join", System().RequestToJoin, group.guid, roles.TANK and true or false,
                roles.HEALER and true or false, roles.DAMAGER and true or false)
        end)
    end)
end

function View.Build(page)
    box = Board.List(page, function(row, group)
        Draw(row, group)
        row:SetScript("OnClick", function(self, button) ns.Safe("quick join", Click, self, button) end)
    end)
    join = Board.Button(page, Core.Word("JOIN_QUEUE", "Join Queue"), 110, Join)
    join:SetMotionScriptsWhileDisabled(true)
    Core.Tip(join, nil, function() return InGroup() and Core.Word("QUICK_JOIN_ALREADY_IN_PARTY", "You are already in a group.") or nil end, "ANCHOR_TOP")
    send = Board.Button(page, Core.Word("SEND_MESSAGE", "Send Message"), 108, function() Whisper(Chosen()) end, join)
end

local EVENTS = { "SOCIAL_QUEUE_UPDATE", "GROUP_JOINED", "GROUP_LEFT", "GROUP_ROSTER_UPDATE" }

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
