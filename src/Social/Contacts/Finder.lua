local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts - Finder
--  The group finder, a tab of the friends list's panel (Friends.lua), as the
--  game's own browse view (Blizzard_GroupFinder_VanillaStyle, the finder of
--  this client): a line with the category to look in and a refresh button,
--  and under it a row for every group or player
--  listed there: the leader in their class colour (a player alone: their level
--  and class icon; a group: the leader's crown), the activity and the comment
--  under it, and how many are in it.
--
--  As the game's: a click chooses a listing, Send Message whispers to its
--  leader, Invite asks a player who is alone into your group (a group is
--  joined by whispering its leader: the game's finder has no request to join).
--  Listing yourself stays the game's: List yourself opens its finder there
--  (its comment is typed into its own secure box, no addon can write it).
--
--  Searching is a restricted call of the game's (C_LFGList.Search): it is only
--  made on a click of yours (a category chosen, the refresh button), never by
--  itself. Shown, the panel reads what the last search found, the game's own
--  finder's too, and follows its results while it is shown. The panel's search
--  box finds listings by their leader, activity and comment. Its tab is there
--  while the switch Group finder is on.
--
--  While chat is locked down (a fight, a dungeon) the game hides the listings
--  from addons: the rows read last stay, its line says so, and they are read
--  anew once it ends. Every part of a listing is read plain; one the game hides
--  a needed part of is left out.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Contacts, Layout = ns.Board, ns.Contacts, ns.Layout
local View = { name = Core.Word("GROUP_FINDER", "Group Finder") }
Contacts.Finder = View

local REFRESH = "Interface\\Buttons\\UI-RefreshButton"

local box, categories, send, invite, status
local shown
local category -- the category looked in (its id), once chosen
local state    -- "searching", "failed", or nil
local chosen   -- the listing chosen (its search result id)
local query    -- what the search box finds (Core.Fuzzy.Query), nil: all
local listings = {} -- the rows as last read

-- The game's finder is open to this character here.
local function Usable()
    if not (C_LFGList and C_LFGList.GetSearchResultInfo) then return false end
    local can = C_LFGInfo and C_LFGInfo.CanPlayerUsePremadeGroup
    return not can or Core.Ask(can) ~= false
end

-- An activity's name, short if it has one.
local function Activity(info)
    local ids = Core.Plain(info.activityIDs)
    if type(ids) ~= "table" then return "" end
    if #ids > 1 then return ns.TEXT.activities:format(#ids) end
    local id = Core.Plain(ids[1])
    local activity = id and C_LFGList.GetActivityInfoTable(id)
    return activity and (activity.shortName ~= "" and activity.shortName or activity.fullName) or "", activity
end

-- One listing as the game's browse view reads it, every part plain. The game hides them from addons while chat is
-- locked down: one whose state, size or age is hidden is left out, a part only shown (a name, a class) is none.
local function Listing(id)
    local info = Core.Plain(C_LFGList.GetSearchResultInfo(id))
    if type(info) ~= "table" or Core.Secret(info.isDelisted) or Core.Secret(info.numMembers) or Core.Secret(info.age) then
        return nil
    end
    if info.isDelisted then return nil end
    local activity, data = Activity(info)
    local leader = Core.Plain(C_LFGList.GetSearchResultLeaderInfo and C_LFGList.GetSearchResultLeaderInfo(id))
    local solo = (info.numMembers or 1) <= 1
    local player = solo and Core.Plain(C_LFGList.GetSearchResultPlayerInfo and C_LFGList.GetSearchResultPlayerInfo(id, 1))
    local class = type(leader) == "table" and Core.Plain(leader.classFilename) or nil
    if not class and type(player) == "table" then class = Core.Plain(player.classFilename) end
    return {
        id = id, leader = Core.Plain(info.leaderName), solo = solo, members = info.numMembers or 1,
        most = data and data.maxNumPlayers or 0, activity = activity, comment = Core.Plain(info.comment) or "",
        class = type(class) == "string" and class or nil, level = type(player) == "table" and Core.Plain(player.level) or nil,
        mine = Core.Plain(info.hasSelf) == true, age = info.age or 0,
    }
end

-- Every listing the last search found: yours first, then the newest.
local function Read()
    local found = {}
    if not Usable() then return found end
    local read = C_LFGList.GetFilteredSearchResults or C_LFGList.GetSearchResults
    local _, results = read()
    for _, id in ipairs(results or {}) do
        local listing = Core.Plain(id) and Listing(id)
        if listing then found[#found + 1] = listing end
    end
    table.sort(found, function(a, b)
        if a.mine ~= b.mine then return a.mine and true or false end
        return a.age < b.age
    end)
    return found
end

local function Found(listing)
    return not query or Core.Fuzzy.Match(query, listing.leader, listing.activity, listing.comment) ~= nil
end

local function Chosen()
    for _, listing in ipairs(listings) do
        if listing.id == chosen then return listing end
    end
end

-- A player alone can be invited by a leader, or by one who is in no group.
local function MayInvite()
    return not IsInGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

local function Buttons()
    local listing = Chosen()
    send:SetEnabled(listing ~= nil and listing.leader ~= nil and not listing.mine)
    invite:SetEnabled(listing ~= nil and listing.solo and listing.leader ~= nil and not listing.mine and MayInvite() and true or false)
end

-- What is said while there is no listing to show.
local function Empty()
    if not Usable() then return ns.TEXT.finderOff end
    if state == "searching" then return ns.TEXT.searching end
    if state == "failed" then return ns.TEXT.searchFailed end
    if query then return ns.TEXT.noGroupsFound end
    return category and ns.TEXT.noGroups or ns.TEXT.chooseCategory
end

local function Update()
    if not shown then return end
    -- Hidden from addons now (chat lockdown: a fight, a dungeon): the rows read last stay, the line says so.
    local locked = ns.ChatLocked()
    status:SetText(locked and ns.TEXT.finderLocked or "")
    if locked then return Buttons() end
    wipe(listings)
    local elements = {}
    for _, listing in ipairs(state == "searching" and {} or Read()) do
        listings[#listings + 1] = listing
        if Found(listing) then elements[#elements + 1] = listing end
    end
    Board.Fill(box, elements, Empty())
    Buttons()
end

local Changed = Core.Later(function() ns.Safe("group finder", Update) end)

local function Received()
    state = nil
    Changed()
end

local function Failed()
    state = "failed"
    Changed()
end

-- A search of the category chosen, in every activity the game offers in it (the game's browse view leaves out
-- those far from your level, unless told otherwise; this one searches them all). Only on a click. Searching only
-- once the game took it: a search it refuses (an error) leaves the list as it was.
local function Search()
    if not category or not Usable() then return end
    local activities = C_LFGList.GetAvailableActivities and C_LFGList.GetAvailableActivities(category) or nil
    C_LFGList.Search(category, 0, 0, nil, false, nil, activities)
    state, chosen = "searching", nil
    Update()
end

local function Category(id)
    local info = C_LFGList.GetLfgCategoryInfo and C_LFGList.GetLfgCategoryInfo(id)
    return info and info.name or tostring(id)
end

local function IsCategory(id) return id == category end
local function Choose(id)
    category = id
    ns.Safe("group finder", Search)
end

local function Categories(_, root)
    if not Usable() then return end
    for _, id in ipairs(C_LFGList.GetAvailableCategories() or {}) do
        root:CreateRadio(Category(id), ns.Guard(IsCategory), ns.Guard(Choose), id)
    end
end

local function Draw(row, listing)
    Board.Row(row)
    row.listing = listing
    row.back:SetColorTexture(1, 1, 1, listing.mine and 0.08 or 0.03)
    row.icon:ClearAllPoints()
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", 6, 0)
    if listing.solo and listing.class then
        row.icon:SetAtlas("groupfinder-icon-class-" .. listing.class:lower())
    else
        row.icon:SetAtlas("groupfinder-icon-leader")
    end
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", 34, -4)
    row.top:SetPoint("TOPRIGHT", -52, -4)
    local name = listing.leader or "?"
    if listing.solo and listing.level then name = name .. "  " .. GRAY_FONT_COLOR:WrapTextInColorCode(ns.TEXT.level:format(listing.level)) end
    row.top:SetText(name)
    local colour = listing.class and RAID_CLASS_COLORS[listing.class] or HIGHLIGHT_FONT_COLOR
    row.top:SetTextColor(colour.r, colour.g, colour.b)
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(listing.comment ~= "" and listing.activity .. " - " .. listing.comment or listing.activity)
    row.side:Hide()
    row.right:SetText(listing.most > 0 and ("%d / %d"):format(listing.members, listing.most) or tostring(listing.members))
    if listing.id == chosen then row:LockHighlight() else row:UnlockHighlight() end
end

local function Click(row)
    if not row.listing then return end
    chosen = row.listing.id
    box:ForEachFrame(function(other, element)
        if element.id == chosen then other:LockHighlight() else other:UnlockHighlight() end
    end)
    Buttons()
end

local function Send()
    local listing = Chosen()
    if listing and listing.leader then ChatFrameUtil.SendTell(listing.leader) end
end

local function Invite()
    local listing = Chosen()
    if listing and listing.leader then C_PartyInfo.InviteUnit(listing.leader) end
end

-- Its tab is offered while the switch Group finder is on; where the game's finder is closed to this
-- character, the list says so.
function View.Usable()
    return ns.options.boardFinder and true or false
end

function View.Build(page)
    -- Its own line above the list: the category to look in and the refresh button, at the right.
    local line = CreateFrame("Frame", nil, page.body)
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(Layout.LINE)
    local refresh = CreateFrame("Button", nil, line)
    refresh:SetSize(24, 24)
    refresh:SetPoint("RIGHT", -Layout.EDGE, 0)
    refresh:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
    refresh:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
    refresh:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local arrows = refresh:CreateTexture(nil, "ARTWORK", nil, 5)
    arrows:SetTexture(REFRESH)
    arrows:SetSize(12, 12)
    arrows:SetPoint("CENTER", -1, 0)
    refresh:SetScript("OnClick", function() ns.Safe("group finder", Search) end)
    Core.Tip(refresh, Core.Word("REFRESH", "Refresh"), ns.TEXT.refreshTip, "ANCHOR_TOP")
    categories = CreateFrame("DropdownButton", nil, line, "WowStyle1DropdownTemplate")
    categories:SetPoint("RIGHT", refresh, "LEFT", -4, 0)
    categories:SetWidth(150)
    categories:SetDefaultText(ns.TEXT.category)
    categories:SetupMenu(ns.Guard(Categories))
    -- At its left what it says while the game hides the listings (chat lockdown).
    status = line:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetPoint("LEFT", Layout.EDGE + 6, 0)
    status:SetPoint("RIGHT", categories, "LEFT", -6, 0)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(false)
    box = Board.List(page, function(row, listing)
        Draw(row, listing)
        if row.wired then return end -- its script once: the list hands its rows from one listing to another
        row.wired = true
        row:SetScript("OnClick", function(self) ns.Safe("group finder", Click, self) end)
    end, Layout.LINE + Layout.EDGE)
    -- Three buttons share the foot, as wide as the panel lets them be.
    local width = math.floor((Layout.FRIENDS_WIDTH - 2 * Layout.EDGE - 8) / 3)
    send = Board.Button(page, Core.Word("SEND_MESSAGE", "Send Message"), width, Send)
    invite = Board.Button(page, Core.Word("INVITE", "Invite"), width, Invite, send)
    Board.Button(page, ns.TEXT.listYourself, width, function() ns.OpenFinder(1) end, invite)
end

-- Shown, it reads what was found last and follows the game's results, and chat's lockdown beginning or ending (the
-- game tells of it before and after, so it is asked a frame later: Changed); hidden, it hears nothing.
local EVENTS = { LFG_LIST_SEARCH_RESULTS_RECEIVED = Received, LFG_LIST_SEARCH_RESULT_UPDATED = Changed,
                 LFG_LIST_SEARCH_FAILED = Failed, LFG_LIST_AVAILABILITY_UPDATE = Changed, GROUP_ROSTER_UPDATE = Changed,
                 ADDON_RESTRICTION_STATE_CHANGED = Changed }

function View.Show(on)
    shown = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    if not on then return end
    -- A search the tab was away for is waited for no more (its end went unheard): what the game has is read, and a
    -- later answer is heard again.
    if state == "searching" then state = nil end
    Update()
end

function View.Search(found)
    query = found
    Update()
end
