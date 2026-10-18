local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Raid
--  The raid, as the game's tab Raid of its friends list (Blizzard_RaidFrame,
--  with the groups of Blizzard_RaidUI). Not in a raid: what a raid is, and
--  Convert to Raid for the leader of a party. In a raid: its eight groups one
--  under another, each with its members: the role, the name in its class
--  colour (red while dead, grey offline) with the leader's crown or an
--  assistant's mark, the level, class and where they are. Above the groups
--  the game's Everyone is Assistant (for the leader) and how many tanks,
--  healers and damage dealers there are.
--
--  As the game's: the leader and the assistants drag a member onto another
--  member to swap the two (SwapRaidSubgroup), or onto a group's line to move
--  them there (SetRaidSubgroup); a right click opens the game's own menu of a
--  raid member; the mouse on one shows the game's tooltip of them.
--
--  Raid Info shows the instances and world bosses you are saved to, with the
--  difficulty and the time left, as the game's window of it: shift-click links
--  one to the chat, the mouse on one shows its bosses, Extend Raid Lock where
--  this client can extend one. Back goes back to the groups.
--
--  Read anew when the game tells of a change, only while the tab is shown.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Layout, Contacts = ns.Board, ns.Layout, ns.Contacts
local View = { name = Core.Word("RAID", "Raid") }
Contacts.Raid = View

local GROUPS, SEATS = 8, 5 -- a raid's groups, and the places in one (the game's MAX_RAID_GROUPS, MEMBERSX_PER_GROUP)
local LEADER, ASSISTANT = "Interface\\GroupFrame\\UI-Group-LeaderIcon", "Interface\\GroupFrame\\UI-Group-AssistantIcon"
local ROLES = { "TANK", "HEALER", "DAMAGER" }

local roster, info -- the two parts: the groups, the instances you are saved to
local shown
local showing = "roster" -- or "info"
local query
local moving -- the member being dragged
local chosenLock -- the saved instance chosen (its index in the game's list)

function View.Usable()
    local rules, rule = rawget(_G, "C_GameRules"), Enum and Enum.GameRule and Enum.GameRule.DisableRaidGroups
    return not (rules and rule and Core.Ask(rules.IsGameRuleActive, rule))
end

-- The role icon of the game's group finder, in a line of text or on a texture.
local function RoleAtlas(role)
    local micro = rawget(_G, "GetMicroIconForRole")
    local ok, atlas = false, nil
    if micro then ok, atlas = pcall(micro, role) end
    return ok and atlas or ("UI-LFG-RoleIcon-" .. (role == "DAMAGER" and "DPS" or role == "HEALER" and "Healer" or "Tank") .. "-Micro-GroupFinder")
end

-------------------------------------------------------------------------------
--  The groups
-------------------------------------------------------------------------------

-- Every member of the raid by group, and how many of each role.
local function Members()
    local groups, roles = {}, { TANK = 0, HEALER = 0, DAMAGER = 0 }
    for group = 1, GROUPS do groups[group] = {} end
    for index = 1, GetNumGroupMembers() do
        local name, rank, group, level, class, classFile, zone, online, dead = GetRaidRosterInfo(index)
        if name and groups[group] then
            local role = Core.Ask(rawget(_G, "UnitGroupRolesAssigned"), "raid" .. index) or "NONE"
            if roles[role] then roles[role] = roles[role] + 1 end
            table.insert(groups[group], { kind = "member", index = index, name = name, rank = rank or 0, group = group,
                level = level, class = class, classFile = classFile, zone = zone, online = online and true or false,
                dead = dead and true or false, role = role, unit = "raid" .. index })
        end
    end
    return groups, roles
end

local function MayArrange() return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") end

local function Update()
    if not shown or showing ~= "roster" then return end
    local raid = IsInRaid()
    roster.line:SetShown(raid)
    roster.convert:SetShown(not raid)
    local convert = C_PartyInfo.AllowedToDoPartyConversion
    roster.convert:SetEnabled(convert and Core.Ask(convert, true) == true or (not convert and IsInGroup() and UnitIsGroupLeader("player")))
    local elements = {}
    if raid then
        local groups, roles = Members()
        for group = 1, GROUPS do
            local found = {}
            for _, member in ipairs(groups[group]) do
                if not query or Core.Fuzzy.Match(query, member.name, member.class, member.zone) then found[#found + 1] = member end
            end
            if not query or #found > 0 then
                elements[#elements + 1] = { kind = "group", group = group, count = #groups[group] }
                for _, member in ipairs(found) do elements[#elements + 1] = member end
            end
        end
        local counts = {}
        for _, role in ipairs(ROLES) do counts[#counts + 1] = Contacts.Atlas(RoleAtlas(role), 14) .. " " .. roles[role] end
        roster.roles:SetText(table.concat(counts, "   "))
        roster.assist:SetChecked(Core.Ask(rawget(_G, "IsEveryoneAssistant")) and true or false)
        roster.assist:SetEnabled(UnitIsGroupLeader("player"))
    end
    Board.Fill(roster.box, elements, raid and ns.TEXT.noneFound
        or Core.Word("RAID_DESCRIPTION", "A raid is a group of more than five players. The leader of a party turns it into a raid."))
    roster.infoButton:SetEnabled(((GetNumSavedInstances and GetNumSavedInstances() or 0) + (GetNumSavedWorldBosses and GetNumSavedWorldBosses() or 0)) > 0)
end

-- A member let go: onto another group's member, the two swap; onto another group's line, they move there.
local function Drop(member)
    local target
    roster.box:ForEachFrame(function(row, element)
        if row:IsMouseOver() then target = element end
    end)
    if not target or target.group == member.group or not MayArrange() then return end
    if target.kind == "member" then
        SwapRaidSubgroup(member.index, target.index)
    elseif target.count < SEATS then
        SetRaidSubgroup(member.index, target.group)
    end
end

local function DrawMember(row, member)
    Contacts.Entry(row)
    row.back:SetColorTexture(1, 1, 1, member.online and 0.04 or 0.02)
    row.icon:ClearAllPoints()
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 6, 0)
    row.icon:SetShown(member.role ~= "NONE")
    if member.role ~= "NONE" then row.icon:SetAtlas(RoleAtlas(member.role)) end
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 28, -4)
    row.top:SetPoint("TOPRIGHT", -8, -4)
    local mark = member.rank == 2 and LEADER or member.rank == 1 and ASSISTANT
    row.top:SetText(mark and ("%s |T%s:12:12|t"):format(member.name, mark) or member.name)
    local colour = not member.online and GRAY_FONT_COLOR or member.dead and RED_FONT_COLOR
        or (member.classFile and RAID_CLASS_COLORS[member.classFile]) or HIGHLIGHT_FONT_COLOR
    row.top:SetTextColor(colour.r, colour.g, colour.b)
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    local who = Core.Word("FRIENDS_LEVEL_TEMPLATE", "Level %d %s"):format(member.level or 0, member.class or "")
    local where = not member.online and Core.Word("FRIENDS_LIST_OFFLINE", "Offline") or member.dead and Core.Word("DEAD", "Dead") or member.zone
    row.bottom:SetText(where and where ~= "" and who .. " - " .. where or who)
    row.side:Hide()
    row.right:SetText("")
end

local function DrawGroup(row, group)
    Contacts.Divider(row, Core.Word("GROUP_NUMBER", "Group %d"):format(group.group))
    row:EnableMouse(true) -- a member is let go on it
    row.right:SetText(("%d/%d"):format(group.count, SEATS))
end

local function Draw(row, element)
    Board.Row(row)
    row.element = element
    row:UnlockHighlight()
    if element.kind == "group" then DrawGroup(row, element) else DrawMember(row, element) end
end

local function MemberTip(row)
    local member = row.element
    if not member or member.kind ~= "member" then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT", 4, 0)
    GameTooltip:SetUnit(member.unit)
    if MayArrange() then GameTooltip:AddLine(ns.TEXT.dragToMove, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true) end
    GameTooltip:Show()
end

local function MemberClick(row, button)
    local member = row.element
    if button ~= "RightButton" or not member or member.kind ~= "member" then return end
    local open = rawget(_G, "UnitPopup_OpenMenu")
    if open then open("RAID", { unit = member.unit, name = member.name, ownerFrame = row }) end
end

-------------------------------------------------------------------------------
--  Raid Info: the instances you are saved to
-------------------------------------------------------------------------------

local function Locks()
    local locks = {}
    for index = 1, GetNumSavedInstances and GetNumSavedInstances() or 0 do
        local name, _, reset, _, locked, extended, _, _, _, difficulty, _, _, noExtend = GetSavedInstanceInfo(index)
        locks[#locks + 1] = { kind = "instance", index = index, name = name or "?", reset = reset, locked = locked,
                              extended = extended, difficulty = difficulty, noExtend = noExtend }
    end
    for index = 1, GetNumSavedWorldBosses and GetNumSavedWorldBosses() or 0 do
        local name, _, reset = GetSavedWorldBossInfo(index)
        locks[#locks + 1] = { kind = "boss", index = index, name = name or "?", reset = reset, locked = true,
                              difficulty = Core.Word("RAID_INFO_WORLD_BOSS", "World Boss") }
    end
    return locks
end

local function Extendable()
    local locks = rawget(_G, "C_RaidLocks")
    return locks and Core.Ask(locks.IsRaidLockExtendFeatureSupported)
end

-- The button to extend the lock chosen, with the game's words for what it would do.
local function ExtendButton(locks)
    info.extend:SetShown(Extendable() and true or false)
    local lock
    for _, entry in ipairs(locks) do
        if entry.kind == "instance" and entry.index == chosenLock then lock = entry end
    end
    if not lock then
        info.extend:SetText(Core.Word("EXTEND_RAID_LOCK", "Extend Raid Lock"))
        return info.extend:Disable()
    end
    info.extend:SetEnabled(not lock.noExtend)
    if lock.extended then
        info.extend:SetText(Core.Word("UNEXTEND_RAID_LOCK", "Remove Lock Extension"))
    else
        info.extend:SetText(lock.locked and Core.Word("EXTEND_RAID_LOCK", "Extend Raid Lock") or Core.Word("REACTIVATE_RAID_LOCK", "Reactivate Raid Lock"))
    end
end

local function UpdateInfo()
    if not shown or showing ~= "info" then return end
    local locks = Locks()
    local elements = {}
    for _, lock in ipairs(locks) do
        if not query or Core.Fuzzy.Match(query, lock.name, lock.difficulty) then elements[#elements + 1] = lock end
    end
    Board.Fill(info.box, elements, query and ns.TEXT.noneFound or Core.Word("NO_RAID_INSTANCES_SAVED", "You are not saved to any instances."))
    ExtendButton(locks)
end

local function DrawLock(row, lock)
    Board.Row(row)
    Contacts.Entry(row)
    row.lock = lock
    row.back:SetColorTexture(1, 1, 1, 0.03)
    row.icon:Hide()
    local alive = lock.locked or lock.extended
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 8, -4)
    row.top:SetPoint("TOPRIGHT", -96, -4)
    row.top:SetText(lock.name)
    local colour = alive and NORMAL_FONT_COLOR or GRAY_FONT_COLOR
    row.top:SetTextColor(colour.r, colour.g, colour.b)
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(lock.extended and (lock.difficulty or "") .. " - " .. Core.Word("EXTENDED", "Extended") or lock.difficulty or "")
    row.side:Hide()
    row.right:SetText(alive and lock.reset and SecondsToTime(lock.reset, true, nil, 3) or Core.Word("RAID_INSTANCE_EXPIRES_EXPIRED", "Expired"))
    if lock.kind == "instance" and lock.index == chosenLock then row:LockHighlight() else row:UnlockHighlight() end
end

local function LockClick(row)
    local lock = row.lock
    if not lock then return end
    if lock.kind == "instance" and IsModifiedClick("CHATLINK") then
        return ChatFrameUtil.InsertLink(GetSavedInstanceChatLink(lock.index))
    end
    chosenLock = lock.kind == "instance" and lock.index or nil
    info.box:ForEachFrame(function(other, element)
        if element.kind == "instance" and element.index == chosenLock then other:LockHighlight() else other:UnlockHighlight() end
    end)
    ExtendButton(Locks())
end

local function LockTip(row)
    local lock = row.lock
    if not lock then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT", 4, 0)
    if lock.kind == "instance" and GameTooltip.SetInstanceLockEncountersComplete then
        GameTooltip:SetInstanceLockEncountersComplete(lock.index)
    else
        GameTooltip:SetText(lock.name)
    end
    GameTooltip:Show()
end

local function Extend()
    for _, lock in ipairs(Locks()) do
        if lock.kind == "instance" and lock.index == chosenLock then
            SetSavedInstanceExtend(lock.index, not lock.extended)
            RequestRaidInfo()
            return
        end
    end
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------

-- Which part is shown: the groups, or the instances you are saved to.
local function Showing(which)
    showing = which
    roster.body:SetShown(which == "roster")
    info.body:SetShown(which == "info")
    if which == "info" and RequestRaidInfo then RequestRaidInfo() end
    Update()
    UpdateInfo()
end

local function Part(page, name)
    local body = CreateFrame("Frame", nil, page.body)
    body:SetAllPoints()
    return { body = body, label = name }
end

function View.Build(page)
    roster, info = Part(page, "raid"), Part(page, "raid info")
    -- The line above the groups: Everyone is Assistant, how many of each role.
    roster.line = CreateFrame("Frame", nil, roster.body)
    roster.line:SetPoint("TOPLEFT", Layout.EDGE, -Layout.EDGE)
    roster.line:SetPoint("TOPRIGHT", -Layout.EDGE, -Layout.EDGE)
    roster.line:SetHeight(Layout.LINE)
    roster.assist = CreateFrame("CheckButton", nil, roster.line, "UICheckButtonTemplate")
    roster.assist:SetSize(24, 24)
    roster.assist:SetPoint("LEFT", 0, 0)
    roster.assist.Text:SetFontObject("GameFontNormalSmall")
    roster.assist.Text:SetText(Core.Word("ALL_ASSIST_LABEL", "Everyone is Assistant"))
    roster.assist:SetMotionScriptsWhileDisabled(true)
    roster.assist:SetScript("OnClick", function(self) ns.Safe("raid", C_PartyInfo.SetEveryoneIsAssistant, self:GetChecked() and true or false) end)
    Core.Tip(roster.assist, Core.Word("ALL_ASSIST_LABEL", "Everyone is Assistant"), Core.Word("ALL_ASSIST_DESCRIPTION", "Every member of the raid is an assistant."), "ANCHOR_TOP")
    roster.roles = roster.line:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    roster.roles:SetPoint("RIGHT", -4, 0)
    roster.box = Board.List(roster, function(row, element)
        Draw(row, element)
        row:RegisterForDrag("LeftButton")
        row:SetScript("OnClick", function(self, button) ns.Safe("raid", MemberClick, self, button) end)
        row:SetScript("OnEnter", function(self) ns.Safe("raid", MemberTip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnDragStart", function(self)
            local member = self.element
            if member and member.kind == "member" and MayArrange() then
                moving = member
                self:SetAlpha(0.5)
            end
        end)
        row:SetScript("OnDragStop", function(self)
            self:SetAlpha(1)
            local member = moving
            moving = nil
            if member then ns.Safe("raid", Drop, member) end
        end)
    end, Layout.LINE + Layout.EDGE)
    roster.infoButton = Board.Button(roster, Core.Word("RAID_INFO", "Raid Info"), 100, function() Showing("info") end)
    roster.convert = Board.Button(roster, Core.Word("CONVERT_TO_RAID", "Convert to Raid"), 130, function() C_PartyInfo.ConvertToRaid() end, roster.infoButton)
    info.box = Board.List(info, function(row, lock)
        DrawLock(row, lock)
        row:SetScript("OnClick", function(self) ns.Safe("raid info", LockClick, self) end)
        row:SetScript("OnEnter", function(self) ns.Safe("raid info", LockTip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end)
    local back = Board.Button(info, Core.Word("BACK", "Back"), 70, function() Showing("roster") end)
    info.extend = Board.Button(info, Core.Word("EXTEND_RAID_LOCK", "Extend Raid Lock"), 160, Extend, back)
    Showing("roster")
end

local Changed = Core.Later(function()
    ns.Safe("raid", Update)
    ns.Safe("raid info", UpdateInfo)
end)
local EVENTS = { "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "UPDATE_INSTANCE_INFO", "PLAYER_ROLES_ASSIGNED", "UNIT_CONNECTION" }

function View.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if on then Showing("roster") end
end

function View.Search(found)
    query = found
    Update()
    UpdateInfo()
end
