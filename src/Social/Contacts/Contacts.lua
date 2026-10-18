local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Contacts
--  What the lists of the friends list's panel (Friends.lua) share: the game's
--  colours and status icons of its friends list, a status read, how long ago
--  something was, the filter by status, a whisper, and the highlight of the
--  row chosen. Knows no panel; the lists are in the files after it.
--
--  Each list is a view of the panel, a table in Contacts:
--      View.name             the words on its tab (View.Label(): with a count, asked anew)
--      View.Usable()         its tab is offered (the game has that system here); none: always
--      View.Build(page)      makes what it holds in page.body; page.label names it in the error log
--      View.Show(on)         its page is shown (on) or hidden: it listens to the game only while shown
--      View.Search(query)    what the search box finds (Core.Fuzzy.Query; nil: all); a view without
--                            it has no search box
--      View.Filter(root)     its filter's menu (the game's MenuUtil description); View.Filtered() says
--                            whether it holds anything back, View.Unfilter() lets all through again;
--                            a view without it has no filter
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Contacts = {}
ns.Contacts = Contacts

Contacts.STATUS = "Interface\\FriendsFrame\\StatusIcon-" -- Online, Away, DnD, Offline
Contacts.DIVIDER = "Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider"
Contacts.NOTE = "Interface\\FriendsFrame\\UI-FriendsFrame-Note"
Contacts.BROADCAST = "Interface\\FriendsFrame\\BroadcastIcon"

-- The game's colours for its friends list, where this client has them; else those of its other clients.
local function Colour(name, r, g, b, a)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.r then return { colour.r, colour.g, colour.b, colour.a or a } end
    return { r, g, b, a }
end
Contacts.BNET = Colour("FRIENDS_BNET_NAME_COLOR", 0.510, 0.773, 1)
Contacts.WOW = Colour("FRIENDS_WOW_NAME_COLOR", 0.996, 0.882, 0.361)
Contacts.OTHER = Colour("FRIENDS_OTHER_NAME_COLOR", 0.502, 0.502, 0.502) -- a character you cannot group with
Contacts.GRAY = Colour("FRIENDS_GRAY_COLOR", 0.486, 0.518, 0.541)
Contacts.BACKS = { bnet = Colour("FRIENDS_BNET_BACKGROUND_COLOR", 0, 0.694, 0.941, 0.05),
                   wow = Colour("FRIENDS_WOW_BACKGROUND_COLOR", 1, 0.824, 0, 0.05),
                   offline = Colour("FRIENDS_OFFLINE_BACKGROUND_COLOR", 0.588, 0.588, 0.588, 0.05) }

-- The statuses, as the game names them in its friends list: the icon's name, and the words.
Contacts.STATUSES = {
    { key = "Online", text = Core.Word("FRIENDS_LIST_AVAILABLE", "Available") },
    { key = "Away", text = Core.Word("FRIENDS_LIST_AWAY", "Away") },
    { key = "DnD", text = Core.Word("FRIENDS_LIST_BUSY", "Busy") },
    { key = "Offline", text = Core.Word("FRIENDS_LIST_OFFLINE", "Offline") },
}

-- Where somebody is: online, away or busy (the game's status icons), or offline.
function Contacts.Status(online, afk, dnd)
    if not online then return "Offline" end
    if dnd then return "DnD" end
    if afk then return "Away" end
    return "Online"
end

-- The status icon with its words, for a line of text.
function Contacts.StatusText(status)
    for _, entry in ipairs(Contacts.STATUSES) do
        if entry.key == status then return ("|T%s%s:16:16:0:0|t %s"):format(Contacts.STATUS, status, entry.text) end
    end
    return status
end

-- The filter by status: a box for each, in a menu; wanted: the statuses ticked ([key] = true), none: all.
function Contacts.StatusMenu(root, wanted, changed)
    local function IsTicked(key) return wanted[key] == true end
    local function Tick(key)
        wanted[key] = not wanted[key] or nil
        changed()
    end
    for _, entry in ipairs(Contacts.STATUSES) do
        root:CreateCheckbox(Contacts.StatusText(entry.key), IsTicked, Tick, entry.key)
    end
end

-- Whether a status is let through by the boxes ticked (none ticked: every one).
function Contacts.Wanted(wanted, key)
    return next(wanted) == nil or wanted[key] == true
end

-- How long ago a moment was (seconds of the game's clock), in the game's words: "3 days". The game's own
-- reckoning where this client has it (its friends list's), else the same words of ours.
local SPANS = {
    { 31536000, "LASTONLINE_YEARS", "%d |4year:years;" },
    { 2592000, "LASTONLINE_MONTHS", "%d |4month:months;" },
    { 86400, "LASTONLINE_DAYS", "%d |4day:days;" },
    { 3600, "LASTONLINE_HOURS", "%d |4hour:hours;" },
    { 60, "LASTONLINE_MINUTES", "%d |4minute:minutes;" },
}
function Contacts.Ago(stamp)
    if type(stamp) ~= "number" then return "" end
    local game = rawget(_G, "FriendsFrame_GetLastOnline")
    if game then
        local ok, text = pcall(game, stamp)
        if ok and type(text) == "string" then return text end
    end
    local seconds = math.max(time() - stamp, 0)
    for _, span in ipairs(SPANS) do
        if seconds >= span[1] then return Core.Word(span[2], span[3]):format(math.floor(seconds / span[1])) end
    end
    return Core.Word("LASTONLINE_SECS", "< a minute")
end

-- A whisper to somebody, as the game's Send Message writes one: the line to write in opens with it.
function Contacts.Tell(name, bnet)
    if not name or name == "" then return end
    if bnet then ChatFrameUtil.SendBNetTell(name) else ChatFrameUtil.SendTell(name) end
end

-- The row of the element whose field is key keeps its highlight (it is the one chosen); the others lose it.
function Contacts.Mark(box, field, key)
    box:ForEachFrame(function(row, element)
        if key ~= nil and element[field] == key then row:LockHighlight() else row:UnlockHighlight() end
    end)
end

-- A line of a list that is no row of it: a divider (the game's), or a title over the rows under it.
function Contacts.Divider(row, title)
    row:EnableMouse(false)
    row.back:Hide()
    row.icon:ClearAllPoints()
    row.top:SetText("")
    row.bottom:SetText("")
    row.side:Hide()
    row.right:SetText("")
    row:UnlockHighlight()
    if row.invite then row.invite:Hide() end
    if title then
        row.icon:Hide()
        row.top:ClearAllPoints()
        row.top:SetPoint("BOTTOMLEFT", 6, 4)
        row.top:SetPoint("BOTTOMRIGHT", -6, 4)
        row.top:SetText(title)
        row.top:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
        return
    end
    row.icon:Show()
    row.icon:SetTexture(Contacts.DIVIDER)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetPoint("RIGHT", 0, 0)
    row.icon:SetHeight(16)
end

-- A row that is one (Board.Row): the mouse on it, its back shown.
function Contacts.Entry(row)
    row:EnableMouse(true)
    row.back:Show()
    row.icon:Show()
end

-- An atlas in a line of text, where this client draws one.
function Contacts.Atlas(atlas, size)
    local markup = rawget(_G, "CreateAtlasMarkup")
    return markup and markup(atlas, size, size) or ""
end
