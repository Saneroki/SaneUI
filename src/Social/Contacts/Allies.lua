local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Allies
--  Recent allies, as the game's tab of its friends list (C_RecentAllies): the
--  players you grouped, traded or fought beside of late, in the game's order
--  (pinned ones first, a divider, then online, the latest, by name). A row has
--  the status icon, the name in its class colour (grey offline), the level and
--  class, where they are or what you did together last, and the game's pin
--  for one you pinned.
--
--  As the game's: the mouse on a row tells who they are and what you did
--  together; a right click opens the game's own menu of a recent ally (pin,
--  note, add as friend, ...); a click chooses one for Send Message and Invite.
--  Tab and list are there only where the game has the system. Until the game
--  has read your allies the list says it is loading; it is asked for when the
--  tab is shown (TryRequestRecentAlliesData) and followed while shown.
--
--  The filter keeps them by status and by what you did together (the game's
--  kinds of it, those this client has); the search box finds them by name,
--  where they are and what you did.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Contacts = ns.Board, ns.Contacts
local View = { name = Core.Word("CONTACTS_RECENT_ALLIES_TAB_NAME", "Recent Allies") }
Contacts.Allies = View

local box, send, invite
local shown
local chosen -- the ally chosen: their GUID
local query
local wanted, kinds = {}, {} -- the filter: statuses ticked; kinds of things done together ticked (the game's numbers)
local allies = {}

-- The kinds of things done together the game can filter by, in its order, with its words.
local KINDS = {
    { name = "Professions", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_PROFESSIONS", text = "Professions" },
    { name = "PvP", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_PVP", text = "PvP" },
    { name = "Raiding", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_RAIDING", text = "Raiding" },
    { name = "Dungeons", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_DUNGEONS", text = "Dungeons" },
    { name = "Delves", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_DELVE", text = "Delves" },
    { name = "Questing", word = "SOCIAL_UI_BATTLE_NET_FRIEND_TAG_LABEL_QUESTING", text = "Questing" },
}

local function System() return rawget(_G, "C_RecentAllies") end

function View.Usable()
    local system = System()
    return system ~= nil and system.IsSystemEnabled ~= nil and Core.Ask(system.IsSystemEnabled) == true
end

-- The kinds this client can filter by: { name, text, value }.
local function Kinds()
    local list, system = {}, System()
    local enum = Enum and Enum.RecentAlliesInteractionCategoryFilter
    if not enum or not system.SearchRecentAllies then return list end
    for _, kind in ipairs(KINDS) do
        local value = enum[kind.name]
        local supported = system.IsInteractionCategoryFilterSupportedForCurrentGameType
        if value and (not supported or Core.Ask(supported, value)) then
            list[#list + 1] = { name = kind.name, text = Core.Word(kind.word, kind.text), value = value }
        end
    end
    return list
end

-- One ally as a row shows it.
local function Ally(data)
    local character, state = data.characterData or {}, data.stateData or {}
    local interactions = data.interactionData and data.interactionData.interactions or {}
    local class = character.classID and C_CreatureInfo and C_CreatureInfo.GetClassInfo(character.classID)
    local last = interactions[1]
    return {
        guid = character.guid, name = character.name or "?", fullName = character.fullName or character.name,
        level = character.level, class = class and class.className, classFile = class and class.classFile,
        raceID = character.raceID, online = state.isOnline and true or false,
        status = Contacts.Status(state.isOnline, state.isAFK, state.isDND), location = state.currentLocation,
        pinned = state.pinExpirationDate ~= nil, pinUntil = state.pinExpirationDate,
        last = last and last.description, lastAt = last and last.timestamp,
        note = data.interactionData and data.interactionData.note, data = data,
    }
end

-- The allies the game has, as it sorts them; with kinds ticked, those the game finds for them.
local function Read()
    local system = System()
    local found = {}
    local raw
    if next(kinds) then
        local filters = {}
        for value in pairs(kinds) do filters[#filters + 1] = value end
        raw = system.SearchRecentAllies({ searchText = "", isOnline = false, isAFK = false, isDND = false,
                                          isOffline = false, interactionCategoryFilters = filters })
    else
        raw = system.GetRecentAllies()
    end
    for _, data in ipairs(raw or {}) do found[#found + 1] = Ally(data) end
    return found
end

local function Found(ally)
    if not Contacts.Wanted(wanted, ally.status) then return false end
    return not query or Core.Fuzzy.Match(query, ally.fullName, ally.location, ally.last, ally.note) ~= nil
end

local function Chosen()
    for _, ally in ipairs(allies) do
        if ally.guid == chosen then return ally end
    end
end

local function Buttons()
    local ally = Chosen()
    send:SetEnabled(ally ~= nil and ally.online)
    invite:SetEnabled(ally ~= nil and ally.online)
end

local function Update()
    if not shown then return end
    wipe(allies)
    local system = System()
    if not (system and system.IsRecentAllyDataReady and Core.Ask(system.IsRecentAllyDataReady)) then
        Board.Fill(box, {}, Core.Word("SEARCH_LOADING_TEXT", "Loading..."))
        return Buttons()
    end
    local elements, pinned = {}, false
    for _, ally in ipairs(Read()) do
        allies[#allies + 1] = ally
        if Found(ally) then
            -- A divider after the pinned ones, as the game's.
            if pinned and not ally.pinned then elements[#elements + 1] = { divider = true } end
            pinned = ally.pinned
            elements[#elements + 1] = ally
        end
    end
    Board.Fill(box, elements, (query or next(wanted) or next(kinds)) and ns.TEXT.noneFound or ns.TEXT.noAllies)
    Buttons()
end

local Changed = Core.Later(function() ns.Safe("recent allies", Update) end)

local function Draw(row, ally)
    Board.Row(row)
    row.ally = ally
    if ally.divider then return Contacts.Divider(row) end
    Contacts.Entry(row)
    local back = Contacts.BACKS[ally.online and "wow" or "offline"]
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:ClearAllPoints()
    row.icon:SetTexture(Contacts.STATUS .. ally.status)
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", 4, -3)
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 22, -4)
    row.top:SetPoint("TOPRIGHT", -30, -4)
    row.top:SetText(ally.fullName)
    local colour = ally.online and (ally.classFile and RAID_CLASS_COLORS[ally.classFile] or NORMAL_FONT_COLOR)
    if colour then row.top:SetTextColor(colour.r, colour.g, colour.b) else row.top:SetTextColor(Contacts.GRAY[1], Contacts.GRAY[2], Contacts.GRAY[3]) end
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    local who = Core.Word("FRIENDS_LEVEL_TEMPLATE", "Level %d %s"):format(ally.level or 0, ally.class or "")
    local what = ally.location or ally.last
    row.bottom:SetText(what and what ~= "" and who .. " - " .. what or who)
    row.right:SetText("")
    row.side:ClearAllPoints()
    row.side:SetSize(16, 16)
    row.side:SetPoint("RIGHT", -8, 0)
    row.side:SetShown(ally.pinned)
    if ally.pinned then row.side:SetAtlas("friendslist-recentallies-pin-yellow") end
    if row.invite then row.invite:Hide() end
    if ally.guid == chosen then row:LockHighlight() else row:UnlockHighlight() end
end

-- Who an ally is and what you did together, as the game's tooltip of its tab tells it.
local function Tip(row)
    local ally = row.ally
    if not ally or ally.divider then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT", 4, 0)
    GameTooltip:SetText(ally.fullName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    local race = ally.raceID and C_CreatureInfo and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(ally.raceID)
    GameTooltip:AddLine(Core.Word("FRIENDS_LEVEL_TEMPLATE", "Level %d %s"):format(ally.level or 0, (race and race.raceName or "") .. " " .. (ally.class or "")), 1, 1, 1)
    if ally.location then GameTooltip:AddLine(ally.location, 1, 1, 1) end
    if ally.note and ally.note ~= "" then
        GameTooltip:AddLine(("|T%s:14:14|t %s"):format(Contacts.NOTE, ally.note), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    if ally.last then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(Core.Word("RECENT_ALLY_RECENT_ACTIVITIES_LABEL", "Recent Activity"), ally.lastAt and Contacts.Ago(ally.lastAt) or "",
            NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, Contacts.GRAY[1], Contacts.GRAY[2], Contacts.GRAY[3])
        GameTooltip:AddLine(ally.last, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

-- The game's own menu of a recent ally, as its tab opens it.
local function Menu(row)
    local ally = row.ally
    local open = rawget(_G, "UnitPopup_OpenMenu")
    if not open then return end
    open(ally.online and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE",
         { recentAllyData = ally.data, name = ally.fullName, guid = ally.guid, isOffline = not ally.online, ownerFrame = row })
end

local function Click(row, button)
    if not row.ally or row.ally.divider then return end
    if button == "RightButton" then return Menu(row) end
    chosen = row.ally.guid
    Contacts.Mark(box, "guid", chosen)
    Buttons()
end

function View.Build(page)
    box = Board.List(page, function(row, ally)
        Draw(row, ally)
        row:SetScript("OnClick", function(self, button) ns.Safe("recent allies", Click, self, button) end)
        row:SetScript("OnEnter", function(self) ns.Safe("recent allies", Tip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end)
    send = Board.Button(page, Core.Word("SEND_MESSAGE", "Send Message"), 108, function()
        local ally = Chosen()
        if ally then Contacts.Tell(ally.fullName) end
    end)
    invite = Board.Button(page, Core.Word("INVITE", "Invite"), 100, function()
        local ally = Chosen()
        if ally then C_PartyInfo.InviteUnit(ally.fullName) end
    end, send)
end

function View.Show(on)
    shown = on
    if on then Core.On("RECENT_ALLIES_CACHE_UPDATE", Changed) else Core.Off("RECENT_ALLIES_CACHE_UPDATE", Changed) end
    if not on then return end
    local system = System()
    if system and system.TryRequestRecentAlliesData then system.TryRequestRecentAlliesData() end
    Update()
end

function View.Search(found)
    query = found
    Update()
end

function View.Filter(root)
    root:CreateTitle(ns.TEXT.status)
    Contacts.StatusMenu(root, wanted, Update)
    local list = Kinds()
    if #list == 0 then return end
    root:CreateTitle(Core.Word("RECENT_ALLIES_CATEGORIES_FILTER_LABEL", "Activities"))
    local function IsTicked(value) return kinds[value] == true end
    local function Tick(value)
        kinds[value] = not kinds[value] or nil
        Update()
    end
    for _, kind in ipairs(list) do root:CreateCheckbox(kind.text, IsTicked, Tick, kind.value) end
end

function View.Filtered() return next(wanted) ~= nil or next(kinds) ~= nil end

function View.Unfilter()
    wipe(wanted)
    wipe(kinds)
    Update()
end
