local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Views - Roster
--  The members (Guild › Roster). At its top the guild's head: its name, how
--  many members and how many online, the message of the day (a click changes
--  it, for those the game lets), and the buttons Invite to Guild, Guild
--  Information and the game's guild window. Under it the members' table: class
--  icon, name over class and rank, level, rank, zone (here: where you are),
--  note, when last online; online and offline apart under rows that fold them;
--  sorted by a click on a column's head (again: the other way, a third time:
--  online first, by rank); searched by name, note and zone. At the right the
--  member chosen: name, level, class, where, since when in the guild, the rank
--  with promote and demote (the game's own calls, as far as the game lets the
--  player), the notes (a click changes them), its history in the guild, and
--  Whisper and Invite.
--
--  The roster is Core's (Core.Data.Guild): the game's own, read anew when it
--  changes; its history is what Core noted since it first read it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Views, Layout, Kit, TEXT = ns.Views, ns.Layout, ns.Kit, ns.TEXT
local Roster = {}
Views.roster = Roster

local view, list, detail, head
local sortKey, descending = nil, false
local folded = { online = false, offline = false }
local search = ""
local chosen -- the key of the member chosen

local function Guild() return Core.Data.Guild end

-------------------------------------------------------------------------------
--  What the table shows (no frames: tested)
-------------------------------------------------------------------------------
-- The words of a member the search looks in (its name, note, officer's note, zone and rank), in small letters: made
-- once a member and kept while the roster is the same (Guild.Stamp), as every filling searches every member.
local words = setmetatable({}, { __mode = "k" }) -- [member] = its words
local wordsOf                                      -- the roster's stamp the words are of

local function Words(member)
    local stamp = Guild().Stamp()
    if stamp ~= wordsOf then
        wipe(words)
        wordsOf = stamp
    end
    local found = words[member]
    if not found then
        found = table.concat({ member.name or "", member.note or "", member.officerNote or "", member.zone or "",
                               member.rank or "" }, "\n"):lower()
        words[member] = found
    end
    return found
end

-- Whether a member has every word of the search in its name, note, officer's note, zone or rank.
function Roster.Matches(member, text)
    if not text or text == "" then return true end
    local hay = Words(member)
    for word in text:lower():gmatch("%S+") do
        if not hay:find(word, 1, true) then return false end
    end
    return true
end

-- A member's value under a sort key: under Last Online how long ago (online: before everyone), words in small
-- letters.
local function Value(member, key)
    if key == "away" then return member.online and -1 or (member.away or 9999) end
    local value = member[key]
    if type(value) == "string" then return value:lower() end
    return value
end

-- Each member's value under the key, made once before the sort (the sort compares a member many times): when any is
-- words, all are (a number as written, none as ""), else numbers (none as 0).
local function Keys(part, key)
    local keys, text = {}, false
    for _, member in ipairs(part) do
        local value = Value(member, key)
        keys[member] = value
        if type(value) == "string" then text = true end
    end
    for _, member in ipairs(part) do
        local value = keys[member]
        if text then
            keys[member] = type(value) == "string" and value or tostring(value or ""):lower()
        else
            keys[member] = value or 0
        end
    end
    return keys
end

local function Less(a, b, keys, down)
    local x, y = keys[a], keys[b]
    if x == y then return (a.name or "") < (b.name or "") end
    if down then return x > y end
    return x < y
end

-- The rows: a fold row for the online ones, them, a fold row for the offline ones, them; each part sorted.
function Roster.Rows(members, text, key, down, folds)
    local online, offline = {}, {}
    for _, member in ipairs(members) do
        if Roster.Matches(member, text) then
            local into = member.online and online or offline
            into[#into + 1] = member
        end
    end
    local function Sort(part)
        if key then
            local keys = Keys(part, key)
            table.sort(part, function(a, b) return Less(a, b, keys, down) end)
            return
        end
        table.sort(part, function(a, b)
            if a.rankIndex ~= b.rankIndex then return (a.rankIndex or 0) < (b.rankIndex or 0) end
            return (a.name or "") < (b.name or "")
        end)
    end
    Sort(online)
    Sort(offline)
    local rows = {}
    rows[#rows + 1] = { fold = "online", count = #online }
    if not folds.online then for _, member in ipairs(online) do rows[#rows + 1] = { member = member } end end
    rows[#rows + 1] = { fold = "offline", count = #offline }
    if not folds.offline then for _, member in ipairs(offline) do rows[#rows + 1] = { member = member } end end
    return rows, #online + #offline
end

-------------------------------------------------------------------------------
--  The table
-------------------------------------------------------------------------------
local myZone

local function Init(row, element)
    if not row.sub then
        row.sub = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        row.sub:SetJustifyH("LEFT")
        row.sub:SetWordWrap(false)
        row.fold = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.fold:SetPoint("LEFT", 8, 0)
        row.chosen = row:CreateTexture(nil, "BACKGROUND", nil, 1)
        row.chosen:SetAllPoints()
        row.chosen:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.25)
    end
    local cells = row.cells
    if element.fold then
        for _, cell in ipairs(cells) do cell:SetText("") end
        row.icon:Hide()
        row.sub:SetText("")
        row.chosen:Hide()
        row.back:SetColorTexture(1, 1, 1, 0.06)
        local word = element.fold == "online" and TEXT.groupOnline or TEXT.groupOffline
        row.fold:SetText((folded[element.fold] and "+  " or "-  ") .. word:format(element.count))
        row.fold:Show()
        return
    end
    local member = element.member
    row.fold:Hide()
    row.icon:Show()
    Kit.ClassIcon(row.icon, member.class)
    row.icon:SetDesaturated(not member.online)
    local name = cells.name
    name:ClearAllPoints()
    name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 4, 2)
    name:SetText(member.online and Kit.Colored(member.name, member.class) or ("|cff9d9d9d%s|r"):format(member.name))
    row.sub:ClearAllPoints()
    row.sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    row.sub:SetWidth(name:GetWidth())
    row.sub:SetText(table.concat({ member.className or "", member.rank or "" }, " · "))
    cells.level:SetText(member.level or "")
    cells.rank:SetText(member.rank or "")
    local zone = member.zone or ""
    if member.online and myZone and zone == myZone then zone = zone .. " |cff40c040(" .. TEXT.here .. ")|r" end
    cells.zone:SetText(member.online and zone or "")
    cells.note:SetText(member.note or "")
    cells.seen:SetText(member.online and ("|cff40c040%s|r"):format(TEXT.seenNow) or (Layout.AgoText(member.away) or ""))
    Kit.Stripe(row, element.index or 0)
    row.chosen:SetShown(member.key == chosen)
end

local function Fill()
    if not list then return end
    myZone = Core.Ask(GetRealZoneText)
    local rows, count = Roster.Rows(Guild().Roster(), search, sortKey, descending, folded)
    for index, element in ipairs(rows) do element.index = index end
    list:Fill(rows, "")
    local total = #Guild().Roster()
    head.shown:SetText(TEXT.shown:format(count, total))
end

local function Sort(key)
    if sortKey ~= key then
        sortKey, descending = key, false
    elseif not descending then
        descending = true
    else
        sortKey, descending = nil, false
    end
    list:Sorted(sortKey, descending)
    Fill()
end

-------------------------------------------------------------------------------
--  The member chosen
-------------------------------------------------------------------------------
local function RankName(index)
    local name = Core.Ask(rawget(_G, "GuildControlGetRankName"), (index or 0) + 1)
    return name or ("#" .. tostring(index))
end

local function Act(what, member)
    if InCombatLockdown() then return ns.Say(TEXT.inFight) end
    local util = rawget(_G, "C_GuildInfo")
    if what == "promote" and util and util.Promote then
        util.Promote(member.name)
    elseif what == "demote" and util and util.Demote then
        util.Demote(member.name)
    elseif what == "whisper" then
        local chat = rawget(_G, "ChatFrameUtil")
        if chat and chat.SendTell then chat.SendTell(member.name) elseif rawget(_G, "ChatFrame_SendTell") then ChatFrame_SendTell(member.name) end
    elseif what == "invite" then
        local party = rawget(_G, "C_PartyInfo")
        if party and party.InviteUnit then party.InviteUnit(member.name) end
    end
end

local function EditNote(member, public)
    local rights = Guild().Rights()
    if public and not rights.notes or not public and not rights.officerNotes then return end
    local ask = public and TEXT.noteAsk or TEXT.officerNoteAsk
    Core.AskText(ask, member.name, nil, public and member.note or member.officerNote, function(text)
        local util = rawget(_G, "C_GuildInfo")
        if util and util.SetNote and member.guid then
            util.SetNote(member.guid, text or "", public)
        elseif public and rawget(_G, "GuildRosterSetPublicNote") then
            GuildRosterSetPublicNote(member.index, text or "")
        elseif not public and rawget(_G, "GuildRosterSetOfficerNote") then
            GuildRosterSetOfficerNote(member.index, text or "")
        end
        ns.Say(TEXT.noted:format(member.name))
    end, 31)
end

local WHAT = { join = "newsJoin", leave = "newsLeave", up = "newsUp", down = "newsDown", level = "newsLevel" }

-- One line of a member's history in the guild.
function Roster.Event(event)
    local word = TEXT[WHAT[event.what] or ""]
    if not word then return nil end
    if event.what == "level" then return word:format(event.key, event.to or 0) end
    if event.what == "up" or event.what == "down" then return word:format(event.key, RankName(event.to)) end
    return word:format(event.key)
end

local function Detail()
    local member = chosen and Guild().Member(chosen)
    detail.empty:SetShown(member == nil)
    detail.body:SetShown(member ~= nil)
    if not member then return end
    local b = detail.body
    Kit.ClassIcon(b.icon, member.class)
    b.name:SetText(Kit.Colored(member.name, member.class))
    b.meta:SetText(("%s %d %s"):format(Core.Word("LEVEL", "Level"), member.level or 0, member.className or ""))
    b.where:SetText(member.online and ("|cff40c040%s|r · %s"):format(TEXT.seenNow, member.zone or "") or (Layout.AgoText(member.away) or ""))
    local today = math.floor((Core.Ask(GetServerTime) or 0) / 86400)
    local joined = member.joined and Core.Ask(date, "%Y-%m-%d", member.joined * 86400)
    b.joined:SetText(joined and TEXT.joinedOn:format(joined) or "")
    b.rank:SetText(member.rank or "")
    local rights = Guild().Rights()
    local myRank = Guild().Info().rankIndex or 99
    local up = member.rankIndex - 1
    local canUp = rights.promote and up > myRank
    local canDown = rights.demote and member.rankIndex > myRank and member.rankIndex < (Core.Ask(rawget(_G, "GuildControlGetNumRanks")) or 0) - 1
    b.promote:SetEnabled(canUp and true or false)
    b.demote:SetEnabled(canDown and true or false)
    b.up:SetText(canUp and TEXT.rankUp:format(RankName(up)) or "")
    b.down:SetText(canDown and TEXT.rankDown:format(RankName(member.rankIndex + 1)) or "")
    b.note:SetText(member.note ~= "" and member.note or "—")
    b.officerNote:SetShown(rights.viewOfficerNotes)
    b.officerLabel:SetShown(rights.viewOfficerNotes)
    b.officerNote:SetText(member.officerNote ~= "" and member.officerNote or "—")
    local lines = {}
    for _, event in ipairs(Guild().History(member.key, 4)) do
        local text = Roster.Event(event)
        local ago = Layout.AgoText(Layout.Ago(event.day, today))
        if text then lines[#lines + 1] = text .. (ago and ("  |cff808080%s|r"):format(ago) or "") end
    end
    b.history:SetText(#lines > 0 and table.concat(lines, "\n") or TEXT.noHistory)
    b.whisper:SetEnabled(member.online and member.key ~= Core.PlayerKey("player"))
    b.invite:SetEnabled(member.online and member.key ~= Core.PlayerKey("player"))
end

local function Label(parent, text, under, gap)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", under, "BOTTOMLEFT", 0, -(gap or 10))
    label:SetText(text)
    return label
end

local function Value(parent, under, font)
    local value = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    value:SetPoint("TOPLEFT", under, "BOTTOMLEFT", 0, -3)
    value:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    value:SetJustifyH("LEFT")
    return value
end

local function Button(parent, text, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, Layout.BUTTON)
    button:SetText(text)
    button:SetScript("OnClick", ns.Guard(click))
    return button
end

local function BuildDetail(parent)
    detail = Kit.Inset(parent)
    detail.empty = Kit.Empty(detail)
    detail.empty:SetText(TEXT.pickMember)
    local b = CreateFrame("Frame", nil, detail)
    b:SetAllPoints()
    detail.body = b
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(40, 40)
    b.icon:SetPoint("TOPLEFT", 10, -10)
    b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 8, -2)
    b.name:SetPoint("RIGHT", -8, 0)
    b.name:SetJustifyH("LEFT")
    b.meta = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    b.meta:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -3)
    b.where = Value(b, b.icon, "GameFontHighlightSmall")
    b.where:ClearAllPoints()
    b.where:SetPoint("TOPLEFT", b.icon, "BOTTOMLEFT", 0, -8)
    b.where:SetPoint("RIGHT", -8, 0)
    b.joined = Value(b, b.where, "GameFontDisableSmall")
    local rankLabel = Label(b, TEXT.colRank, b.joined)
    b.demote = Button(b, "-", 26, function()
        local member = chosen and Guild().Member(chosen)
        if member then Act("demote", member) end
    end)
    b.demote:SetPoint("TOPLEFT", rankLabel, "BOTTOMLEFT", 0, -4)
    b.promote = Button(b, "+", 26, function()
        local member = chosen and Guild().Member(chosen)
        if member then Act("promote", member) end
    end)
    b.promote:SetPoint("TOPRIGHT", b, "TOPRIGHT", -8, 0)
    b.promote:SetPoint("TOP", b.demote, "TOP")
    Core.Tip(b.promote, TEXT.promote)
    Core.Tip(b.demote, TEXT.demote)
    b.rank = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    b.rank:SetPoint("LEFT", b.demote, "RIGHT", 6, 0)
    b.rank:SetPoint("RIGHT", b.promote, "LEFT", -6, 0)
    b.up = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    b.up:SetPoint("TOPLEFT", b.demote, "BOTTOMLEFT", 0, -4)
    b.down = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    b.down:SetPoint("LEFT", b.up, "RIGHT", 10, 0)
    local noteLabel = Label(b, TEXT.note, b.up, 12)
    b.note = Value(b, noteLabel)
    local noteButton = CreateFrame("Button", nil, b)
    noteButton:SetAllPoints(b.note)
    noteButton:SetScript("OnClick", ns.Guard(function()
        local member = chosen and Guild().Member(chosen)
        if member then EditNote(member, true) end
    end))
    Core.Tip(noteButton, TEXT.note, TEXT.noteEdit)
    b.officerLabel = Label(b, TEXT.officerNote, b.note)
    b.officerNote = Value(b, b.officerLabel)
    local officerButton = CreateFrame("Button", nil, b)
    officerButton:SetAllPoints(b.officerNote)
    officerButton:SetScript("OnClick", ns.Guard(function()
        local member = chosen and Guild().Member(chosen)
        if member then EditNote(member, false) end
    end))
    local historyLabel = Label(b, TEXT.memberHistory, b.officerNote, 12)
    b.history = Value(b, historyLabel)
    b.history:SetJustifyV("TOP")
    b.whisper = Button(b, TEXT.whisper, 100, function()
        local member = chosen and Guild().Member(chosen)
        if member then Act("whisper", member) end
    end)
    b.whisper:SetPoint("BOTTOMLEFT", 8, 8)
    b.invite = Button(b, TEXT.invite, 100, function()
        local member = chosen and Guild().Member(chosen)
        if member then Act("invite", member) end
    end)
    b.invite:SetPoint("LEFT", b.whisper, "RIGHT", 4, 0)
    return detail
end

-------------------------------------------------------------------------------
--  The game's guild window
-------------------------------------------------------------------------------
--  The head's button opens the game's own guild window by the game's own micro menu button: a secure button of
--  ours (SecureActionButtonTemplate, type click) clicks it, so the game's panel manager runs the game's own path,
--  nothing of ours (Doc/guides/addon-standards.md, The game's panels; Doc/guides/windows.md, Combat). It lies over
--  the head's own button, on UIParent in the layer above the head's: a protected child would make our window
--  protected and locked in a fight, and the window comes to the front of its layer when clicked. Anchored, shown
--  and hidden out of a fight only: as a fight begins (the game says so before it locks) it goes, unanchored, so
--  nothing of ours is tied to it then, and the head's own button stands in (its click says so); once the fight is
--  over it is back over the head's button. Where the game has no micro menu button, the head's button opens the
--  game's window itself.
local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local game -- the secure button, once made

-- The layer above that one (the last stays the last); nil for one the game does not have.
local function Above(strata)
    for index, name in ipairs(STRATA) do
        if name == strata then return STRATA[math.min(index + 1, #STRATA)] end
    end
    return nil
end

-- Made once, out of a fight; nil without the game's micro menu button, or in a fight (then made at the next seat).
local function GameButton()
    if game then return game end
    local micro = rawget(_G, "GuildMicroButton")
    if type(micro) ~= "table" or not micro.Click or InCombatLockdown() then return nil end
    game = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate, SecureActionButtonTemplate")
    game:SetText(TEXT.gameWindow)
    game:RegisterForClicks("AnyUp")
    game:SetAttribute("useOnKeyDown", false) -- on the release, as it is registered, whatever the game's key-down setting says
    game:SetAttribute("type", "click")
    game:SetAttribute("clickbutton", micro)
    game:Hide()
    return game
end

-- Over the head's button while the head shows, out of a fight; else away.
local function Seat()
    local button = GameButton()
    if not button or InCombatLockdown() then return end
    button:ClearAllPoints()
    if not (head and head:IsVisible()) then return button:Hide() end
    local strata = Above(head:GetFrameStrata())
    if strata then button:SetFrameStrata(strata) end
    button:SetAllPoints(head.game)
    button:Show()
end
local seat = ns.Guard(Seat)

-- A fight begins: the secure button goes before the game locks it; the head's own stands in meanwhile.
local function FightBegins()
    if not game or InCombatLockdown() then return end
    game:Hide()
    game:ClearAllPoints()
end
ns.On("PLAYER_REGEN_DISABLED", function() ns.Safe("game window", FightBegins) end)
ns.On("PLAYER_REGEN_ENABLED", function() ns.Safe("game window", Seat) end)

-- The head's own button: in a fight it says so (the secure one is away then); where the game has no micro menu
-- button, it opens the game's window itself.
local function GameClicked()
    if InCombatLockdown() then return ns.Say(TEXT.inFight) end
    if not game and rawget(_G, "ToggleGuildFrame") then ToggleGuildFrame() end
end

-------------------------------------------------------------------------------
--  The head
-------------------------------------------------------------------------------
local function Head()
    local info = Guild().Info()
    head.name:SetText(info.name or "")
    head.counts:SetText(TEXT.membersOnline:format(info.total or 0, info.online or 0))
    head.motd:SetText((info.motd and info.motd ~= "") and info.motd or TEXT.noMotd)
    local rights = Guild().Rights()
    head.invite:SetShown(rights.invite)
end

local function BuildHead(parent)
    head = Kit.Inset(parent)
    head:SetHeight(58)
    head.name = head:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    head.name:SetPoint("TOPLEFT", 10, -10)
    head.counts = head:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    head.counts:SetPoint("TOPLEFT", head.name, "BOTTOMLEFT", 0, -4)
    head.motdLabel = head:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    head.motdLabel:SetPoint("TOPLEFT", 260, -10)
    head.motdLabel:SetText(TEXT.motd)
    head.motd = head:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    head.motd:SetPoint("TOPLEFT", head.motdLabel, "BOTTOMLEFT", 0, -4)
    head.motd:SetJustifyH("LEFT")
    head.motd:SetWordWrap(false)
    local motdButton = CreateFrame("Button", nil, head)
    motdButton:SetPoint("TOPLEFT", head.motdLabel, "TOPLEFT")
    motdButton:SetPoint("BOTTOMRIGHT", head.motd, "BOTTOMRIGHT")
    motdButton:SetScript("OnClick", ns.Guard(function()
        if not Guild().Rights().motd then return end
        local info = Guild().Info()
        Core.AskText(TEXT.motd .. ":", nil, nil, info.motd, function(text)
            local util = rawget(_G, "C_GuildInfo")
            if util and util.SetMOTD then util.SetMOTD(text or "") end
        end, 255)
    end))
    head.game = CreateFrame("Button", nil, head, "UIPanelButtonTemplate")
    head.game:SetSize(170, Layout.BUTTON)
    head.game:SetPoint("RIGHT", -10, 0)
    head.game:SetText(TEXT.gameWindow)
    head.game:SetScript("OnClick", ns.Guard(GameClicked))
    head:HookScript("OnShow", seat) -- shown or hidden by an ancestor too: the secure button follows
    head:HookScript("OnHide", seat)
    head.info = CreateFrame("Button", nil, head, "UIPanelButtonTemplate")
    head.info:SetSize(130, Layout.BUTTON)
    head.info:SetPoint("RIGHT", head.game, "LEFT", -4, 0)
    head.info:SetText(TEXT.guildInfo)
    Core.Tip(head.info, TEXT.guildInfo, function() return Guild().Info().text end)
    head.invite = CreateFrame("Button", nil, head, "UIPanelButtonTemplate")
    head.invite:SetSize(120, Layout.BUTTON)
    head.invite:SetPoint("RIGHT", head.info, "LEFT", -4, 0)
    head.invite:SetText(TEXT.inviteGuild)
    head.invite:SetScript("OnClick", ns.Guard(function()
        Core.AskText(TEXT.inviteAsk, nil, TEXT.invite, nil, function(name)
            local util = rawget(_G, "C_GuildInfo")
            if name and name ~= "" and util and util.Invite then util.Invite(name) end
        end, 48)
    end))
    head.motd:SetPoint("RIGHT", head.invite, "LEFT", -12, 0)
    head.shown = head:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    return head
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
function Roster.Build(frame)
    view = frame
    BuildHead(frame)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    local box = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    box:SetSize(Layout.DETAIL - 8, 20)
    box:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", -2, -6)
    box:SetAutoFocus(false)
    if box.Instructions then box.Instructions:SetText(TEXT.searchRoster) end
    box:HookScript("OnTextChanged", ns.Guard(function(self)
        search = self:GetText() or ""
        Fill()
    end))
    BuildDetail(frame)
    detail:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 2, -6)
    detail:SetPoint("BOTTOMRIGHT")
    detail:SetWidth(Layout.DETAIL)
    local inset = Kit.Inset(frame)
    inset:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
    inset:SetPoint("BOTTOMRIGHT", detail, "BOTTOMLEFT", -Layout.GAP, 0)
    head.shown:SetParent(inset)
    head.shown:SetPoint("BOTTOMRIGHT", inset, "TOPRIGHT", -4, 4)
    list = Kit.Table(inset, {
        columns = {
            { key = "name", text = TEXT.colName },
            { key = "level", text = TEXT.colLevel, width = 36, justify = "RIGHT" },
            { key = "rank", text = TEXT.colRank, width = 100 },
            { key = "zone", text = TEXT.colZone, width = 140 },
            { key = "note", text = TEXT.colNote, width = 120 },
            { key = "seen", text = TEXT.colSeen, width = 86 },
        },
        icon = true, row = Layout.TALL_ROW, init = Init,
        sort = function(key) Sort(key == "seen" and "away" or key) end,
        click = function(_, element, button)
            if element.fold then
                folded[element.fold] = not folded[element.fold]
                return Fill()
            end
            chosen = element.member.key
            if button == "RightButton" then
                local menu = rawget(_G, "MenuUtil")
                if menu and menu.CreateContextMenu then
                    menu.CreateContextMenu(view, ns.Guard(function(_, root)
                        local member = element.member
                        root:CreateTitle(member.name)
                        root:CreateButton(TEXT.whisper, ns.Guard(function() Act("whisper", member) end))
                        root:CreateButton(TEXT.invite, ns.Guard(function() Act("invite", member) end))
                    end))
                end
            end
            Fill()
            Detail()
        end,
    })
    list:SetPoint("TOPLEFT", 4, -4)
    list:SetPoint("BOTTOMRIGHT", -4, 4)
end

function Roster.Show(on)
    if on then Roster.Refresh() end
    Seat()
end

function Roster.Refresh()
    if not view then return end
    Head()
    Fill()
    Detail()
end

function Roster.Title()
    local info = Guild().Info()
    return TEXT.membersOnline:format(info.total or 0, info.online or 0)
end

function Roster.Search(text)
    search = text or ""
    Fill()
end
