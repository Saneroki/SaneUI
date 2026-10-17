local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Finder
--  The group finder of the full screen (Board.lua), as the game's own browse
--  view (Blizzard_GroupFinder_VanillaStyle, the finder of this client): a
--  category to look in, a refresh button, and a row for every group or player
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
--  finder's too, and follows its results while it is shown. The search box of
--  the full window finds listings by their leader, activity and comment.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board = ns.Board
local Finder = {}
ns.Finder = Finder

local REFRESH = "Interface\\Buttons\\UI-RefreshButton"

local panel, box, categories, send, invite
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
    local ids = info.activityIDs or {}
    if #ids > 1 then return ns.TEXT.activities:format(#ids) end
    local activity = ids[1] and C_LFGList.GetActivityInfoTable(ids[1])
    return activity and (activity.shortName ~= "" and activity.shortName or activity.fullName) or "", activity
end

-- One listing as the game's browse view reads it.
local function Listing(id)
    local info = C_LFGList.GetSearchResultInfo(id)
    if not info or info.isDelisted then return nil end
    local activity, data = Activity(info)
    local leader = C_LFGList.GetSearchResultLeaderInfo and C_LFGList.GetSearchResultLeaderInfo(id)
    local solo = (info.numMembers or 1) <= 1
    local player = solo and C_LFGList.GetSearchResultPlayerInfo and C_LFGList.GetSearchResultPlayerInfo(id, 1)
    return {
        id = id, leader = Core.Plain(info.leaderName), solo = solo, members = info.numMembers or 1,
        most = data and data.maxNumPlayers or 0, activity = activity, comment = Core.Plain(info.comment) or "",
        class = (leader and leader.classFilename) or (player and player.classFilename), level = player and player.level,
        mine = info.hasSelf, age = info.age or 0,
    }
end

-- Every listing the last search found: yours first, then the newest.
local function Read()
    local found = {}
    if not Usable() then return found end
    local read = C_LFGList.GetFilteredSearchResults or C_LFGList.GetSearchResults
    local _, results = read()
    for _, id in ipairs(results or {}) do
        local listing = Listing(id)
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

-- A search of the category chosen, in every activity the game offers in it, as the game's browse view
-- searches when none is ticked. Only on a click.
local function Search()
    if not category or not Usable() then return end
    local activities = C_LFGList.GetAvailableActivities and C_LFGList.GetAvailableActivities(category) or nil
    state, chosen = "searching", nil
    C_LFGList.Search(category, 0, 0, nil, false, nil, activities)
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
        root:CreateRadio(Category(id), IsCategory, Choose, id)
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

function Finder.Build(holder)
    panel = holder
    panel.title:SetText(ns.TEXT.finder)
    local refresh = CreateFrame("Button", nil, panel.head)
    refresh:SetSize(24, 24)
    refresh:SetPoint("RIGHT", -ns.Layout.EDGE, 0)
    refresh:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
    refresh:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
    refresh:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local arrows = refresh:CreateTexture(nil, "ARTWORK", nil, 5)
    arrows:SetTexture(REFRESH)
    arrows:SetSize(12, 12)
    arrows:SetPoint("CENTER", -1, 0)
    refresh:SetScript("OnClick", function() ns.Safe("group finder", Search) end)
    Core.Tip(refresh, Core.Word("REFRESH", "Refresh"), ns.TEXT.refreshTip, "ANCHOR_TOP")
    categories = CreateFrame("DropdownButton", nil, panel.head, "WowStyle1DropdownTemplate")
    categories:SetPoint("RIGHT", refresh, "LEFT", -4, 0)
    categories:SetWidth(150)
    categories:SetDefaultText(ns.TEXT.category)
    categories:SetupMenu(Categories)
    box = Board.List(panel, function(row, listing)
        Draw(row, listing)
        row:SetScript("OnClick", function(self) ns.Safe("group finder", Click, self) end)
    end)
    send = Board.Button(panel, Core.Word("SEND_MESSAGE", "Send Message"), 122, Send)
    invite = Board.Button(panel, Core.Word("INVITE", "Invite"), 122, Invite, send)
    Board.Button(panel, ns.TEXT.listYourself, 122, function() ns.OpenFinder(1) end, invite)
end

-- Shown, it reads what was found last and follows the game's results; hidden, it hears nothing.
local EVENTS = { LFG_LIST_SEARCH_RESULTS_RECEIVED = Received, LFG_LIST_SEARCH_RESULT_UPDATED = Changed,
                 LFG_LIST_SEARCH_FAILED = Failed, LFG_LIST_AVAILABILITY_UPDATE = Changed, GROUP_ROSTER_UPDATE = Changed }

function Finder.Show(on)
    shown = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    if on then Update() end
end

function Finder.Search(text)
    query = Core.Fuzzy.Query(text)
    Update()
end
