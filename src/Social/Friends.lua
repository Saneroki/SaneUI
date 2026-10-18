local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Friends
--  The friends list's panel of the full screen (Board.lua), at its left:
--  everything the game's friends list (Blizzard_FriendsFrame, its Camelot copy)
--  holds, in one panel, so that its window is not needed.
--
--      head      you on Battle.net: your status, your BattleTag, how many
--                friends are online, the contacts menu (Contacts/Account.lua)
--      tabs      Friends, Recent Allies, Requests, Raid, Quick Join: the game's
--                tabs of its friends list and of the bar under it, those this
--                client has; a count in brackets where something waits
--      tools     the search box, and the filter of a list that has one
--      the list  of the tab chosen, with its buttons at the foot (Contacts/*.lua)
--
--  The ignore list (in the contacts menu, as the game's) stands in the list's
--  place while the tab Friends stays chosen. A list is made the first time it
--  is shown and told when it is shown and hidden: only the one shown listens to
--  the game, and nothing listens while the panel is hidden. What is typed into
--  the full window's search box (Board.Search) is typed into this one too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Layout, Contacts = ns.Board, ns.Layout, ns.Contacts
local Friends = {}
ns.Friends = Friends

-- The tabs, in the game's order: its friends list's own (Friends, Recent Allies, and the requests it shows
-- at its top), then those of the bar under it (Raid, Quick Join). Each is a list of Contacts.
local TABS = { "Friends", "Allies", "Requests", "Raid", "Quick" }

local panel, strip, tools, search, filter, group
local tabs = {}  -- [key] = the tab's button
local pages = {} -- [key] = the list's part of the panel ({ body, label }), once made
local current    -- the key of the list shown
local shown
local typed = "" -- what is in the search box

-- The tabs this client has, side by side, each as wide as its words and a little room; where they do not
-- fit, narrower, their words cut short (the whole of them in the tab's tooltip).
local function Arrange()
    local visible, words = {}, 0
    for _, key in ipairs(TABS) do
        local view, button = Contacts[key], tabs[key]
        local usable = not view.Usable or view.Usable()
        button:SetShown(usable and true or false)
        if usable then
            button.label = view.Label and view.Label() or view.name
            button.Text:SetWidth(0)
            button.Text:SetText(button.label)
            visible[#visible + 1] = button
            words = words + (button.Text:GetStringWidth() or 0)
        end
    end
    local room = Layout.FRIENDS_WIDTH - 2 * Layout.EDGE - 2 * (#visible - 1)
    local pad = math.max(8, math.min(2 * Layout.TAB_PAD, math.floor((room - words) / math.max(#visible, 1))))
    local scale = math.min(room / math.max(words + pad * #visible, 1), 1)
    local previous
    for _, button in ipairs(visible) do
        local width = math.floor(((button.Text:GetStringWidth() or 0) + pad) * scale)
        button:SetWidth(width)
        button.cut = scale < 1
        if button.cut then button.Text:SetWidth(width - 8) end
        button:ClearAllPoints()
        if previous then
            button:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT", 2, 0)
        else
            button:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", Layout.EDGE, 0)
        end
        previous = button
    end
end

-- The part of the panel a list fills, under the tabs (and the tools, for a list that can be searched).
local function Page(key)
    if pages[key] then return pages[key] end
    local view = Contacts[key]
    local body = CreateFrame("Frame", nil, panel.body)
    body:SetPoint("TOPLEFT", 0, -(Layout.TABS + (view.Search and Layout.TOOLS or 0)))
    body:SetPoint("BOTTOMRIGHT")
    body:Hide()
    local page = { body = body, label = key:lower() }
    pages[key] = page
    ns.Safe(page.label, view.Build, page)
    return page
end

-- This list in the panel's place, the one there before put away.
local function Present(key)
    if current == key then return end
    local before = current
    if before then
        pages[before].body:Hide()
        if shown then ns.Safe(before:lower(), Contacts[before].Show, false) end
    end
    current = key
    local view = Contacts[key]
    local page = Page(key)
    tools:SetShown(view.Search ~= nil)
    filter:SetShown(view.Filter ~= nil)
    search:ClearAllPoints()
    search:SetPoint("LEFT", Layout.EDGE + 6, 0)
    if view.Filter then search:SetPoint("RIGHT", filter, "LEFT", -8, 0) else search:SetPoint("RIGHT", -Layout.EDGE, 0) end
    page.body:Show()
    if view.Search then ns.Safe(page.label, view.Search, Core.Fuzzy.Query(typed)) end
    if shown then ns.Safe(page.label, view.Show, true) end
end

-- What the search box holds now, to the list shown.
local function Searched()
    local view = current and Contacts[current]
    if view and view.Search then ns.Safe(current:lower(), view.Search, Core.Fuzzy.Query(typed)) end
end

-- A list shown from elsewhere: a tab's (its tab chosen), or the ignore list (the tab Friends kept); focus: the
-- list takes the keys (Requests: the line to add a friend).
function Friends.Open(key, focus)
    if not panel then return end
    for index, other in ipairs(TABS) do
        if other == key then group:SelectAtIndex(index) end
    end
    Present(key)
    local view = Contacts[key]
    if focus and view.Focus then ns.Safe(key:lower(), view.Focus) end
end

local Relabel = Core.Later(function()
    ns.Safe("friends tabs", function()
        Arrange()
        -- A tab the game no longer has here (the system turned off): back to Friends.
        local view = current and Contacts[current]
        if view and view.Usable and not view.Usable() then Friends.Open("Friends") end
    end)
end)

function Friends.Build(holder)
    panel = holder
    Contacts.Account.Build(panel)
    -- The tabs, on a line of their own under the head.
    strip = CreateFrame("Frame", nil, panel.body)
    strip:SetPoint("TOPLEFT")
    strip:SetPoint("TOPRIGHT")
    strip:SetHeight(Layout.TABS)
    local buttons = {}
    for index, key in ipairs(TABS) do
        local button = CreateFrame("Button", nil, strip, "MinimalTabTemplate")
        button.key = key
        tabs[key], buttons[index] = button, button
        Core.Tip(button, function() return button.cut and button.label or nil end, nil, "ANCHOR_TOP")
    end
    group = CreateRadioButtonGroup()
    group:AddButtons(buttons)
    group:RegisterCallback(ButtonGroupBaseMixin.Event.Selected, function(_, button)
        if shown then Core.Sound("IG_CHARACTER_INFO_TAB") end
        Present(button.key)
    end, panel)
    -- The search box and the filter, under the tabs.
    tools = CreateFrame("Frame", nil, panel.body)
    tools:SetPoint("TOPLEFT", 0, -Layout.TABS)
    tools:SetPoint("TOPRIGHT", 0, -Layout.TABS)
    tools:SetHeight(Layout.TOOLS)
    filter = CreateFrame("DropdownButton", nil, tools, "WowStyle1FilterDropdownTemplate")
    filter:SetPoint("RIGHT", -Layout.EDGE, 0)
    filter:SetupMenu(function(_, root)
        local view = Contacts[current]
        if view and view.Filter then ns.Safe(current:lower(), view.Filter, root) end
    end)
    if filter.SetIsDefaultCallback then
        filter:SetIsDefaultCallback(function()
            local view = Contacts[current]
            return not (view and view.Filtered and view.Filtered())
        end)
        filter:SetDefaultCallback(function()
            local view = Contacts[current]
            if view and view.Unfilter then ns.Safe(current:lower(), view.Unfilter) end
        end)
    end
    search = CreateFrame("EditBox", nil, tools, "SearchBoxTemplate")
    search:SetHeight(20)
    -- The game tells of every SetText too (ours from the full window's box among them): the list is asked
    -- anew only when the words are other than those it was given.
    search:HookScript("OnTextChanged", function(box)
        local text = box:GetText() or ""
        if text == typed then return end
        typed = text
        Searched()
    end)
    Arrange()
    group:SelectAtIndex(1)
end

-- Shown, the head and the list shown listen to the game, and the tabs follow their counts; hidden, nothing does.
local EVENTS = { "BN_FRIEND_INVITE_ADDED", "BN_FRIEND_INVITE_REMOVED", "BN_FRIEND_INVITE_LIST_INITIALIZED",
                 "SOCIAL_QUEUE_UPDATE", "RECENT_ALLIES_SYSTEM_STATUS_UPDATED", "GROUP_JOINED", "GROUP_LEFT" }

function Friends.Show(on)
    shown = on
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Relabel) else Core.Off(event, Relabel) end
    end
    ns.Safe("account", Contacts.Account.Show, on)
    if current then ns.Safe(current:lower(), Contacts[current].Show, on) end
    if on then Relabel() end
end

-- The full window's search box: its words in this one, and the list shown finds them.
function Friends.Search(text)
    text = text or ""
    if text == typed then return end
    typed = text
    search:SetText(text)
    Searched()
end
