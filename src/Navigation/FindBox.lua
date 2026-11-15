local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - FindBox
--  The full map's search (Saneroki, 2026-11-15: "a big searchfield in the title bar up
--  there where you can search for stuff ... and it will show it to you or put a pin on the
--  map"): a large field in the middle of the full map's title bar, and under it the list of
--  what it finds (Find.lua reads the words and knows the world). Only while the map fills
--  the screen.
--
--      the field   a dark plate with round ends and the gold trim (Core's skin, as Sane UI's
--                  panels), the game's magnifier at its left, the words in the game's font a
--                  size up, its own words while empty; the game's clear mark at its right
--                  while it holds words; a click into it, or /sane map find <words>
--      the list    under the field, on the same dark plate: the finds in groups under their
--                  titles (how many each; nearness asked: one list, nearest first), a row each:
--                  its picture (an item's own, an NPC's map icon, a member's class), its name
--                  (the letters typed in gold; an item in its quality's colour, an enemy of
--                  your side red, a flight point not found yet red, who is offline grey), under
--                  it what it is and where (its zone, its levels), at the right how far it is
--                  and an arrow the way to it from where you face, kept up to date while the
--                  list shows; at the foot what Enter, Shift and a right click do
--
--  Keys, in the field:
--      typing          searched a moment after the last key (FindBox.WAIT)
--      Up, Down        the row before or after, round at the ends; in the empty field the words
--                      searched before (Find.History), newest first
--      Tab, Shift-Tab  the next row, the one before; Page Up, Page Down: a page of them
--      Enter           the lit row (else the first) on the map: its places as glowing pins, the
--                      map at the nearest (a zone, a dungeon: its map whole); where nearness was
--                      asked for, the map pin there too; an item or a spell: what it comes
--                      from, listed under it (its vendors, what drops it, the trainers)
--      Shift-Enter     the game's map pin at the nearest: the golden line leads there
--      Ctrl-Enter      as Enter, the list kept open
--      Esc             the list away; again, the field emptied and the pins gone
--  The mouse: a click is Enter, Shift and a click Shift-Enter (on an item its link into the
--  chat), Ctrl and a click Ctrl-Enter, a right click its menu; on a row its tooltip, and its
--  places on the map while it stays there (the map not moved).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Find = ns.Find
local FindBox = {}
ns.FindBox = FindBox

FindBox.WIDTH, FindBox.HEIGHT = 560, 26 -- the field: as wide as the bar lets it be, at most this
FindBox.LEAST = 240                     -- and at least
FindBox.ROOM = 24                        -- units kept free beside it on the bar
FindBox.LIST = 620                       -- the list's width
FindBox.ROW, FindBox.TITLE = 34, 22      -- a find's row, a group's title
FindBox.ICON = 24
FindBox.ROWS = 14                        -- rows shown at once (a group's title counts), more on the wheel
FindBox.WAIT = 0.12                      -- seconds after the last key before searching
FindBox.TICK = 0.25                      -- seconds between two looks at how far the finds are
FindBox.ARROW = 16
FindBox.FAR = 90                         -- a row's room at its right: how far, and the arrow
FindBox.TEXT = {
    empty = "Search the world: a name, nearest warrior trainer, who sells Linen Cloth",
    reading = "Reading the world...",
    nothing = "Nothing found.",
    more = "%d more",
    count = "%s (%d)",
    keys = "Enter: on the map   Shift-Enter: the map pin   Right click: more",
    show = "Show on the map",
    pin = "Put the map pin there",
    sources = "Where to get it",
    sold = "Who sells it",
    drops = "What drops it",
    link = "Link in the chat",
    linkPlace = "The map pin there, its link in the chat",
    whisper = Core.Word("WHISPER", "Whisper"),
    invite = Core.Word("INVITE", "Invite"),
    log = "In the quest log",
    noPlace = "Nothing on the map for it.",
    tipShow = "Enter or a click: on the map",
    tipPin = "Shift-Enter or Shift and a click: the map pin there",
    tipMenu = "Right click: more",
    tipSources = "Enter or a click: where to get it",
    tipLink = "Shift and a click: its link in the chat",
    far = "far",
}

local field, box, words, clear, list, footer
local rows, titles = {}, {}  -- the list's buttons and title lines, made as many as needed
local lines = {}             -- what the list shows: { title, count, more } or { row }, in order
local finds = {}             -- the rows among them (each a line's find row), in order
local lit                    -- the place in finds of the row lit by the keys
local top = 0                -- the first line shown (the wheel)
local answer                 -- the list's answer (Find.Ask)
local recalled               -- the place in the history of the words in the field (Up in the empty field)
local hovered                -- the row the mouse is on: its places on the map meanwhile
local chosen                 -- the row last taken (Enter, a click): its places on the map
local typed                  -- the words searched for the answer shown

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
-- A find's colour: an item's quality's, red for an enemy of your side and a flight point not found, grey offline.
local function Colour(entry)
    if entry.kind == "item" and entry.quality then
        local items = rawget(_G, "C_Item")
        local r, g, b = Core.Ask(items and items.GetItemQualityColor, entry.quality)
        if type(r) == "number" then return r, g, b end
    end
    if entry.foe or entry.unknown then return 1, 0.35, 0.3 end
    if entry.online == false then return 0.55, 0.55, 0.55 end
    return 1, 1, 1
end

-- The words typed, lit in gold in a find's name where they stand in it (Core's Fuzzy, the first set of words); a word
-- found only in what the thing is (warrior in Warrior Trainer) lights nothing.
local function Lit(entry)
    local set = answer and answer.asked and answer.asked.sets and answer.asked.sets[1]
    local name = entry.name or "?"
    if not set or #set == 0 then return name end
    local spots, low, one = {}, entry.lowName or name:lower(), {}
    for _, word in ipairs(set) do
        if low:find(word, 1, true) and Core.Fuzzy.Rank(word, name, low, one) then
            for _, spot in ipairs(one) do spots[#spots + 1] = spot end -- (Rank gives each word's spots anew)
        end
    end
    return #spots > 0 and Core.Fuzzy.Highlight(name, spots) or name
end

-- What a find is and where: its words (or the row's own: Sells it for 5s), its nearest point's zone, its levels.
local function About(row)
    local entry, parts = row.entry, {}
    local role = row.role or entry.role
    if entry.kind == "item" and not role then
        -- an item: its kind as the game names it (Trade Goods, Cloth), and the level it asks
        local items = rawget(_G, "C_Item")
        local _, kind, sort = Core.Ask(items and items.GetItemInfoInstant or rawget(_G, "GetItemInfoInstant"), entry.id)
        if type(kind) == "string" then parts[#parts + 1] = (type(sort) == "string" and sort ~= kind) and (kind .. ", " .. sort) or kind end
        if entry.low and entry.low > 1 then parts[#parts + 1] = Find.TEXT.level:format(entry.low) end
    end
    if role and role ~= entry.name then parts[#parts + 1] = role end
    local point = entry.nearest
    local zone = point and point.map and Find.MapName(point.map)
    if entry.kind == "member" or entry.kind == "friend" or entry.kind == "farm" then zone = nil end -- (said already)
    if zone and zone ~= role then parts[#parts + 1] = zone end
    local low, high = entry.low, entry.high
    if entry.kind == "npc" and low and low > 0 then
        parts[#parts + 1] = (high and high ~= low) and Find.TEXT.levelRange:format(low, high) or Find.TEXT.level:format(low)
    end
    if entry.kind == "place" and low and high then parts[#parts + 1] = Find.TEXT.levels:format(low, high) end
    if entry.foe then parts[#parts + 1] = Find.TEXT.foe end
    return table.concat(parts, "  ·  ")
end

-- How far a row's find is and its arrow the way there from where you face; "far" on another continent, nothing where
-- it has no place.
local function Distance(button)
    local row = button.row
    if not row then return end
    local yards = Find.Measure(row.entry)
    local entry = row.entry
    if yards then
        button.far:SetText(Core.Distance(yards))
        button.far:SetTextColor(1, 1, 1)
        local facing = Plain(Core.Ask(GetPlayerFacing))
        if facing and entry.du and (math.abs(entry.du) + math.abs(entry.dv) > 0) then
            -- the way in the plane (Glints.lua: ahead is -sin, cos of the facing), turned from where you face
            button.arrow:SetRotation(math.atan2(-entry.du, entry.dv) - facing)
            button.arrow:Show()
        else
            button.arrow:Hide()
        end
    else
        button.far:SetText(entry.nearest and FindBox.TEXT.far or "")
        button.far:SetTextColor(0.55, 0.55, 0.55)
        button.arrow:Hide()
    end
end

-- A row's picture: an item's or spell's own, a member's class circle, else its map icon.
local function Picture(button, entry)
    local icon = button.icon
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetDesaturated(entry.online == false)
    if (entry.kind == "item" or entry.kind == "farm") and type(entry.icon) == "number" then
        icon:SetTexture(entry.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    elseif entry.kind == "spell" then
        local spells = rawget(_G, "C_Spell")
        icon:SetTexture(Core.Ask(spells and spells.GetSpellTexture, entry.spell) or 134400)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    elseif entry.coords then
        icon:SetTexture(entry.icon)
        icon:SetTexCoord(unpack(entry.coords))
    elseif entry.kind == "zone" or entry.kind == "dungeon" then
        icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        local look = Find.Look(entry)
        if type(look) == "number" then icon:SetTexture(look) else icon:SetAtlas(look) end
    end
end

local function Fill(button, row)
    button.row = row
    local entry = row.entry
    Picture(button, entry)
    button.name:SetText(Lit(entry))
    button.name:SetTextColor(Colour(entry))
    button.about:SetText(About(row))
    Distance(button)
    button:Show()
end

-- The lines from the first shown, as many as there is room for: titles and rows.
local function Lay()
    for _, button in ipairs(rows) do button:Hide() end
    for _, title in ipairs(titles) do title:Hide() end
    local y, usedRows, usedTitles, shown = -6, 0, 0, 0
    for position = top + 1, #lines do
        if shown >= FindBox.ROWS then break end
        local line = lines[position]
        shown = shown + 1
        if line.row then
            usedRows = usedRows + 1
            local button = rows[usedRows] or FindBox.Row(usedRows)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", list, "TOPLEFT", 6, y)
            button:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, y)
            Fill(button, line.row)
            if lit and finds[lit] == line.row then button:LockHighlight() else button:UnlockHighlight() end
            y = y - FindBox.ROW
        else
            usedTitles = usedTitles + 1
            local title = titles[usedTitles] or FindBox.Title(usedTitles)
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", list, "TOPLEFT", 12, y - 4)
            local text = line.count and line.count > 1 and FindBox.TEXT.count:format(line.title, line.count) or line.title
            title.text:SetText(text)
            title.more:SetText(line.more and line.more > 0 and FindBox.TEXT.more:format(line.more) or "")
            title.text:SetTextColor(line.grey and 0.55 or 1, line.grey and 0.55 or 0.82, line.grey and 0.55 or 0)
            title:Show()
            y = y - FindBox.TITLE
        end
    end
    footer:SetPoint("TOPLEFT", list, "TOPLEFT", 12, y - 4)
    list:SetHeight(-y + 28)
end

-- The answer as the list's lines: the item or spell asked about first, then each group under its title.
local function Lines(found)
    wipe(lines)
    wipe(finds)
    lit, top, hovered = nil, 0, nil
    local spelled = found and found.asked and found.asked.spelled
    if spelled then lines[#lines + 1] = { title = Find.TEXT.spelled:format(spelled), grey = true } end
    if found and found.about then
        lines[#lines + 1] = { row = found.about }
        finds[#finds + 1] = found.about
    end
    for _, group in ipairs(found or {}) do
        lines[#lines + 1] = { title = group.title, count = (group.all or #group.rows), more = group.more,
                              grey = found.close }
        for _, row in ipairs(group.rows) do
            lines[#lines + 1] = { row = row }
            finds[#finds + 1] = row
        end
    end
    if found and found.reading and #finds == 0 then lines[#lines + 1] = { title = FindBox.TEXT.reading, grey = true } end
    if found and not found.reading and #finds == 0 then lines[#lines + 1] = { title = FindBox.TEXT.nothing, grey = true } end
end

-- The mouse gone from the rows: the map as it was before, the chosen find's (or the places to farm the answer named).
local function Restore()
    if chosen then return Find.Preview(chosen.entry, chosen.role) end
    if answer and answer.farms and answer.about then return Find.Farms(answer.farms, answer.about.entry) end
    Find.Clear()
end

local function Open(on)
    if not list then return end
    if on and #lines > 0 then
        Lay()
        list:Show()
    else
        list:Hide()
        if hovered then
            hovered = nil
            Restore()
        end
    end
end

-- What is typed, searched; the answer shown while the field still holds those words.
local function Run()
    local text = box:GetText() or ""
    if text:match("^%s*$") then
        answer, typed = nil, nil
        Lines(nil)
        return Open(false)
    end
    Find.Ask(text, function(found)
        if box:GetText() ~= text then return end
        answer, typed = found, text
        Lines(found)
        -- where to farm it: its places glow on the map at once (the map not moved)
        if found and found.farms and found.about then Find.Farms(found.farms, found.about.entry) end
        Open(found ~= nil and box:HasFocus() or (list and list:IsShown()))
    end)
end
local Later = Core.Later(function() ns.Guarded(Run) end, FindBox.WAIT, "Navigation: map search")

-- The rows lit by the keys: one shown, the list scrolled to it.
local function Light(place)
    if #finds == 0 then return end
    lit = (place - 1) % #finds + 1
    local row = finds[lit]
    for position, line in ipairs(lines) do
        if line.row == row then
            if position <= top then top = math.max(position - 2, 0) end
            if position > top + FindBox.ROWS then top = position - FindBox.ROWS end
        end
    end
    Lay()
end

-------------------------------------------------------------------------------
--  Taking a row
-------------------------------------------------------------------------------
-- A row taken: on the map (and the map pin, with Shift or where nearness was asked); an item or a spell its sources
-- listed first; Ctrl keeps the list open.
local function Take(row, shift, ctrl)
    if not row then return end
    local entry = row.entry
    Find.Picked(entry, box:GetText())
    local farmable = entry.kind == "object" and (entry.what == "herb" or entry.what == "ore" or entry.what == "chest")
    if (entry.kind == "item" or entry.kind == "spell" or farmable) and not shift and not (answer and answer.about == row) then
        local text = entry.kind == "spell" and "who teaches " .. entry.name
            or farmable and "where to farm " .. entry.name or "where to get " .. entry.name
        box:SetText(text)
        box:SetCursorPosition(#text)
        Run()
        -- a herb, an ore: the map at its best place to farm (its glow kept); an item: its places and its vendors
        local best = farmable and answer and answer.farms and answer[1] and answer[1].rows[1]
        Find.Show(best and best.entry or entry, best and best.role or row.role)
        chosen = best or row
        return
    end
    chosen = row
    hovered = nil
    local shown = Find.Show(entry, row.role)
    if shift or (answer and answer.asked and answer.asked.near) then
        if not Find.Pin(entry) and shift then UIErrorsFrame:AddMessage(FindBox.TEXT.noPlace, 1, 0.1, 0.1) end
    elseif not shown and entry.kind ~= "zone" and entry.kind ~= "dungeon" then
        UIErrorsFrame:AddMessage(FindBox.TEXT.noPlace, 1, 0.1, 0.1)
    end
    if not ctrl then
        Open(false)
        box:ClearFocus()
    end
end

-- Into the chat: an item's link where a chat box takes it, else a new one opened with it.
local function Link(link)
    if not link then return end
    local chat = rawget(_G, "ChatFrameUtil")
    if chat and chat.InsertLink and chat.InsertLink(link) then return end
    local open = (chat and chat.OpenChat) or rawget(_G, "ChatFrame_OpenChat")
    if open then open(link) end
end

local function ItemLink(entry)
    local items = rawget(_G, "C_Item")
    local _, link = Core.Ask(items and items.GetItemInfo or rawget(_G, "GetItemInfo"), entry.id)
    return link
end

-- Whisper and invite a member, a friend or one of your group.
local function Tell(entry)
    local chat = rawget(_G, "ChatFrameUtil")
    if chat and chat.SendTell then chat.SendTell(entry.who) elseif rawget(_G, "ChatFrame_SendTell") then ChatFrame_SendTell(entry.who) end
end
local function Invite(entry)
    local party = rawget(_G, "C_PartyInfo")
    if party and party.InviteUnit then party.InviteUnit(entry.who) end
end

-- A row's menu: on the map, the map pin; an item's ways to get it and its link; a place's link (the map pin there);
-- a quest of the log in the log; whisper and invite those who are people.
local function Menu(button)
    local row = button.row
    if not row or not rawget(_G, "MenuUtil") then return end
    local entry = row.entry
    MenuUtil.CreateContextMenu(button, ns.Guard(function(_, root)
        root:CreateTitle(entry.name or "")
        root:CreateButton(FindBox.TEXT.show, ns.Guard(function() Take(row, false, false) end))
        if entry.kind ~= "zone" and entry.kind ~= "dungeon" then
            root:CreateButton(FindBox.TEXT.pin, ns.Guard(function() Take(row, true, false) end))
        end
        if entry.kind == "item" then
            for _, way in ipairs({ { FindBox.TEXT.sources, "where to get " }, { FindBox.TEXT.sold, "who sells " },
                                   { FindBox.TEXT.drops, "what drops " } }) do
                root:CreateButton(way[1], ns.Guard(function()
                    box:SetText(way[2] .. entry.name)
                    box:SetFocus()
                    Run()
                end))
            end
            root:CreateButton(FindBox.TEXT.link, ns.Guard(function() Link(ItemLink(entry)) end))
        elseif entry.kind ~= "zone" and entry.kind ~= "dungeon" and entry.kind ~= "spell" then
            root:CreateButton(FindBox.TEXT.linkPlace, ns.Guard(function()
                if Find.Pin(entry) then Link(Core.Ask(C_Map.GetUserWaypointHyperlink)) end
            end))
        end
        if entry.kind == "log" then
            root:CreateButton(FindBox.TEXT.log, ns.Guard(function() ns.QuestLog.Focus(entry.quest) end))
        end
        if entry.who and entry.online ~= false then
            root:CreateButton(FindBox.TEXT.whisper, ns.Guard(function() Tell(entry) end))
            if entry.kind ~= "party" then root:CreateButton(FindBox.TEXT.invite, ns.Guard(function() Invite(entry) end)) end
        end
    end))
end

-------------------------------------------------------------------------------
--  A row's tooltip
-------------------------------------------------------------------------------
local function Hints(entry)
    GameTooltip:AddLine(" ")
    if entry.kind == "item" or entry.kind == "spell" then
        GameTooltip:AddLine(FindBox.TEXT.tipSources, 0.5, 0.5, 0.5)
    else
        GameTooltip:AddLine(FindBox.TEXT.tipShow, 0.5, 0.5, 0.5)
        if entry.kind ~= "zone" and entry.kind ~= "dungeon" then GameTooltip:AddLine(FindBox.TEXT.tipPin, 0.5, 0.5, 0.5) end
    end
    if entry.kind == "item" then GameTooltip:AddLine(FindBox.TEXT.tipLink, 0.5, 0.5, 0.5) end
    GameTooltip:AddLine(FindBox.TEXT.tipMenu, 0.5, 0.5, 0.5)
end

local function Tip(button)
    local row = button.row
    if not row then return end
    local entry = row.entry
    GameTooltip:SetOwner(list, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0)
    if entry.kind == "item" and GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(entry.id)
    elseif entry.kind == "spell" and GameTooltip.SetSpellByID then
        GameTooltip:SetSpellByID(entry.spell)
    else
        GameTooltip:SetText(entry.name or "?", Colour(entry))
        local about = About(row)
        if about ~= "" then GameTooltip:AddLine(about, 1, 0.82, 0, true) end
        if entry.kind == "log" then
            for _, objective in ipairs(Core.Ask(C_QuestLog.GetQuestObjectives, entry.quest) or {}) do
                if type(objective) == "table" and objective.text then
                    GameTooltip:AddLine("- " .. objective.text, 1, 1, 1, true)
                end
            end
        end
        if entry.yards then GameTooltip:AddLine(Core.Distance(entry.yards), 1, 1, 1) end
        if entry.doubt then GameTooltip:AddLine(Find.TEXT.unconfirmed, 0.5, 0.5, 0.5) end
    end
    Hints(entry)
    GameTooltip:Show()
end

-- The mouse on a row: its tooltip, its places on the map meanwhile (the map not moved); off it, the chosen one's again.
local function Entered(button)
    Tip(button)
    local row = button.row
    if row and row ~= hovered and row.entry.kind ~= "zone" and row.entry.kind ~= "dungeon" then
        hovered = row
        ns.Find.Preview(row.entry, row.role)
    end
end
local function Left()
    GameTooltip_Hide()
end

local function Clicked(button, mouse)
    if mouse == "RightButton" then return Menu(button) end
    local row = button.row
    if row and row.entry.kind == "item" and IsModifiedClick("CHATLINK") then return Link(ItemLink(row.entry)) end
    Take(row, IsShiftKeyDown(), IsControlKeyDown())
end

function FindBox.Row(place)
    local button = CreateFrame("Button", nil, list)
    button:SetHeight(FindBox.ROW)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local light = button:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.14)
    button:SetHighlightTexture(light)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(FindBox.ICON, FindBox.ICON)
    button.icon:SetPoint("LEFT", 6, 0)
    button.arrow = button:CreateTexture(nil, "ARTWORK")
    button.arrow:SetAtlas("UI-WorldMapArrow")
    button.arrow:SetSize(FindBox.ARROW, FindBox.ARROW)
    button.arrow:SetPoint("RIGHT", -6, 0)
    button.far = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    button.far:SetPoint("RIGHT", button.arrow, "LEFT", -4, 0)
    button.far:SetJustifyH("RIGHT")
    -- The name over what it is, both by their tops (two anchors of one height: the game and the lab agree), room at
    -- the right for how far and the arrow.
    local left = 6 + FindBox.ICON + 8
    button.name = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    button.name:SetPoint("TOPLEFT", left, -4)
    button.name:SetPoint("TOPRIGHT", -FindBox.FAR, -4)
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(false)
    button.about = button:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    button.about:SetPoint("TOPLEFT", left, -19)
    button.about:SetPoint("TOPRIGHT", -FindBox.FAR, -19)
    button.about:SetJustifyH("LEFT")
    button.about:SetWordWrap(false)
    button:SetScript("OnClick", ns.Guard(Clicked))
    button:SetScript("OnEnter", ns.Guard(Entered))
    button:SetScript("OnLeave", ns.Guard(Left))
    rows[place] = button
    return button
end

function FindBox.Title(place)
    local title = CreateFrame("Frame", nil, list)
    title:SetSize(FindBox.LIST - 24, FindBox.TITLE)
    title.text = title:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    title.text:SetPoint("LEFT")
    title.more = title:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    title.more:SetPoint("RIGHT")
    local rule = title:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.25)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", 0, 2)
    rule:SetPoint("BOTTOMRIGHT", 0, 2)
    titles[place] = title
    return title
end

-------------------------------------------------------------------------------
--  The field
-------------------------------------------------------------------------------
-- The words searched before, back in the field (Up: older, Down: newer; past the newest, empty again).
local function Recall(step)
    local history = Find.History()
    if #history == 0 then return end
    recalled = math.max(0, math.min(#history, (recalled or 0) + step))
    local text = recalled > 0 and history[recalled] or ""
    box:SetText(text)
    box:SetCursorPosition(#text)
    Run()
end

local function Arrow(_, key)
    if key ~= "UP" and key ~= "DOWN" then return end
    if (box:GetText() == "" or recalled) and (not list:IsShown() or not lit) and key == "UP" then return Recall(1) end
    if recalled and not lit and key == "DOWN" then return Recall(-1) end
    if not list:IsShown() and #lines > 0 then Open(true) end
    if key == "DOWN" then Light((lit or 0) + 1) else Light((lit or 2) - 1) end
end

local function Tab()
    if #finds == 0 then return end
    if IsShiftKeyDown() then Light((lit or 2) - 1) else Light((lit or 0) + 1) end
end

local function Key(_, key)
    if key == "PAGEDOWN" and #finds > 0 then Light(math.min((lit or 0) + FindBox.ROWS - 2, #finds)) end
    if key == "PAGEUP" and #finds > 0 then Light(math.max((lit or 1) - FindBox.ROWS + 2, 1)) end
end

local function Enter()
    local row = lit and finds[lit] or finds[1]
    if row then return Take(row, IsShiftKeyDown(), IsControlKeyDown()) end
    box:ClearFocus()
end

local function Escape()
    if list:IsShown() then
        Open(false)
        box:ClearFocus()
        return
    end
    FindBox.Clear()
end

-- The field emptied: no list, no pins.
function FindBox.Clear()
    if not box then return end
    chosen, hovered, recalled = nil, nil, nil
    box:SetText("")
    box:ClearFocus()
    Lines(nil)
    Open(false)
    Find.Clear()
end

local function Changed(_, user)
    clear:SetShown((box:GetText() or "") ~= "")
    words:SetShown((box:GetText() or "") == "" and not box:HasFocus())
    if user then
        recalled = nil
        Later()
    end
end

local function Focused()
    words:Hide()
    Find.Prepare() -- Core's sets read now, while the words are typed
    if #lines > 0 then Open(true) end
end

-- Focus gone: the list too, unless the mouse is on it (a click on a row takes focus first).
local function Unfocused()
    words:SetShown((box:GetText() or "") == "")
    if list and Plain(list:IsMouseOver()) ~= true then Open(false) end
end

-- How far the finds are, a few times a second while the list shows.
local elapsed = 0
local function Tick(_, step)
    elapsed = elapsed + (step or 0)
    if elapsed < FindBox.TICK then return end
    elapsed = 0
    for _, button in ipairs(rows) do
        if Plain(button:IsShown()) == true then Distance(button) end
    end
end

local function Wheel(_, delta)
    local most = math.max(0, #lines - FindBox.ROWS)
    top = math.max(0, math.min(most, top - delta * 3))
    Lay()
end

-- The field on the title bar of the map's window (Core's, made once it was shown full), the list under it.
local function Build(handle)
    local bar = handle and handle.bar
    if field or not bar then return field end
    field = CreateFrame("Frame", nil, bar)
    field:SetHeight(FindBox.HEIGHT)
    field:SetPoint("CENTER", bar, "CENTER", 0, 0)
    field:SetFrameLevel(bar:GetFrameLevel() + 5)
    field.skin = Core.Skin.New(field, { radius = FindBox.HEIGHT / 2 })
    local glass = field:CreateTexture(nil, "OVERLAY")
    glass:SetAtlas("common-search-magnifyingglass")
    glass:SetSize(14, 14)
    glass:SetPoint("LEFT", 12, 0)
    box = CreateFrame("EditBox", nil, field)
    box:SetPoint("TOPLEFT", glass, "TOPRIGHT", 6, 6)
    box:SetPoint("BOTTOMRIGHT", -28, 0)
    box:SetFontObject("GameFontHighlightMedium")
    box:SetAutoFocus(false)
    box:SetMaxLetters(120)
    words = field:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    words:SetPoint("LEFT", glass, "RIGHT", 8, 0)
    words:SetPoint("RIGHT", -28, 0)
    words:SetJustifyH("LEFT")
    words:SetWordWrap(false)
    words:SetText(FindBox.TEXT.empty)
    clear = CreateFrame("Button", nil, field)
    clear:SetSize(18, 18)
    clear:SetPoint("RIGHT", -8, 0)
    local mark = clear:CreateTexture(nil, "ARTWORK")
    mark:SetAtlas("common-search-clearbutton")
    mark:SetSize(12, 12)
    mark:SetPoint("CENTER")
    mark:SetAlpha(0.6)
    clear:SetHighlightAtlas("common-search-clearbutton", "ADD")
    clear:SetScript("OnClick", ns.Guard(FindBox.Clear))
    clear:Hide()
    -- A click anywhere on the plate puts the cursor in the field.
    field:EnableMouse(true)
    field:SetScript("OnMouseDown", ns.Guard(function() box:SetFocus() end))

    list = CreateFrame("Frame", nil, field)
    list:SetPoint("TOP", field, "BOTTOM", 0, -6)
    list:SetWidth(FindBox.LIST)
    list:SetFrameStrata("DIALOG")
    list:SetToplevel(true)
    list:EnableMouse(true)
    list:EnableMouseWheel(true)
    list.skin = Core.Skin.New(list, { radius = 8 })
    footer = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetText(FindBox.TEXT.keys)
    list:SetScript("OnMouseWheel", ns.Guard(Wheel))
    list:SetScript("OnUpdate", ns.Guard(Tick))
    list:SetScript("OnLeave", ns.Guard(function()
        if hovered and Plain(list:IsMouseOver()) ~= true then
            hovered = nil
            Restore()
        end
        if not box:HasFocus() and Plain(list:IsMouseOver()) ~= true then Open(false) end
    end))
    list:Hide()

    box:SetScript("OnTextChanged", ns.Guard(Changed))
    box:SetScript("OnEditFocusGained", ns.Guard(Focused))
    box:SetScript("OnEditFocusLost", ns.Guard(Unfocused))
    box:SetScript("OnArrowPressed", ns.Guard(Arrow))
    box:SetScript("OnTabPressed", ns.Guard(Tab))
    box:SetScript("OnKeyDown", ns.Guard(Key))
    box:SetScript("OnEnterPressed", ns.Guard(Enter))
    box:SetScript("OnEscapePressed", ns.Guard(Escape))
    -- A click anywhere else (the map, the quest log) gives the keyboard back: the keys move you again.
    ns.On("GLOBAL_MOUSE_DOWN", function()
        if box:HasFocus() and Plain(field:IsMouseOver()) ~= true and Plain(list:IsMouseOver()) ~= true then
            box:ClearFocus()
        end
    end)
    field:Hide()
    return field
end

-- The field's width as the bar lets it be: in its middle, as much room on both sides as the wider of what stands at
-- them takes (the title at the left; the buttons and the dropdown Classic windows at the right).
local function Fit(handle)
    local bar = handle.bar
    local width = Plain(bar:GetWidth()) or FindBox.WIDTH
    local left = bar.find and Plain(bar.find:GetWidth()) or 0
    local right = 0
    for _, button in ipairs(handle.buttons and handle.buttons.list or {}) do
        if Plain(button:IsShown()) == true then right = right + (Plain(button:GetWidth()) or 0) end
    end
    local menu = handle.edge and handle.edge.classic
    if menu and Plain(menu:IsShown()) == true then right = right + (Plain(menu:GetWidth()) or 0) end
    local room = width - 2 * math.max(left, right) - 2 * FindBox.ROOM
    field:SetWidth(math.max(FindBox.LEAST, math.min(FindBox.WIDTH, room)))
end

local pending -- words to search once the map stands full (/sane map find, the key): "" for the field alone

-- In sight while the map fills the screen (Window.lua, once it stands), out of it on the way and while small; small,
-- its words and pins stay for the next time.
function FindBox.SetShown(on, handle)
    if on then Build(handle) end
    if not field then return end
    if on then Fit(handle) end
    field:SetShown(on and true or false)
    if not on then
        Open(false)
        if box:HasFocus() then box:ClearFocus() end
    elseif pending then
        local text = pending
        pending = nil
        FindBox.Search(text)
    end
end

-- The field taken, with those words searched (nil or "": the field alone, its words as they were); the map filled
-- first where it is small, the search once it stands (SetShown).
function FindBox.Search(text)
    if not field or not field:IsShown() then
        pending = text or ""
        ns.Window.Full()
        return
    end
    if text and text ~= "" then box:SetText(text) end
    box:SetFocus()
    if text and text ~= "" then Run() end
end

-- The key Search the map (the game's key bindings, Sane UI): the full map, the cursor in its field.
BINDING_NAME_SANEUI_MAP_FIND = "Search the map"
function FindBox.Key()
    if ns.off then return end
    FindBox.Search(nil)
end

function FindBox.Hide()
    if field then FindBox.SetShown(false) end
    Find.Clear()
end
