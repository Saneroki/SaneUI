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
--                  list shows; at the foot what the keys do; as tall as the screen lets it be
--                  down from the field, and where more finds are than fit, a scroll bar at its
--                  right (the game's thin one: its thumb dragged, a click above or below it a
--                  page, the wheel three lines; Saneroki, 2026-11-15: "it should show a
--                  scroller on the side and expand down as much as possible")
--      what to do  a find taken (Enter, a click; Saneroki, 2026-11-15: "so you can first select
--                  the thing and then select what to do with the thing"): the list holds it at
--                  its top and under it what can be done with it, a row each with its picture:
--                  Show on the map, Put the map pin there, Where to get it, What drops it, Who
--                  sells it, Where to farm it, Who teaches it, In the quest log, its link in the
--                  chat, Whisper, Invite (what fits the find); one with only one thing to do
--                  (a zone, a dungeon) does it at once
--  A search that runs into an error says so in the list and stops nothing (ns.Gently: Saneroki,
--  2026-11-15, "The search fields everywhere in our addon needs to have a very greacefull error
--  handeling"); the next key searches again.
--
--  Keys, in the field:
--      typing          searched a moment after the last key (FindBox.WAIT)
--      Up, Down        the row before or after, round at the ends; in the empty field the words
--                      searched before (Find.History), newest first
--      Tab, Shift-Tab  the next row, the one before; Page Up, Page Down: a page of them
--      Enter           the lit row (else the first) taken: what to do with it listed (its places
--                      glowing on the map meanwhile); in that list, the lit thing done: Show on
--                      the map puts its places as glowing pins and the map at the nearest (a
--                      zone, a dungeon: its map whole), with the map pin there too where nearness
--                      was asked for; Where to get it and the rest search for it anew
--      Shift-Enter     a find's map pin at its nearest at once: the golden line leads there
--      Esc             back from what to do to the finds; the list away; again, the field
--                      emptied and the pins gone
--  The mouse: a click or a right click is Enter, Shift and a click Shift-Enter (on an item its
--  link into the chat); on a row its places on the map while it stays there (the map not moved).
--  The row under the mouse, or lit by the keys, has its tooltip at the list's right, level with
--  it (Saneroki, 2026-11-15: "When you mouse over an item or select it with the up and down arrows
--  its tooltip should be shown"): an item's and a spell's the game's own, an NPC's a creature's as
--  on the map's pins (PinView.Creature), a herb's or a chest's what it gives.
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
FindBox.ROWS = 14                        -- lines shown where the room is not known yet (as many as fit, else)
FindBox.MARGIN = 24                      -- units the list keeps free above the screen's bottom
FindBox.FOOT = 28                        -- the foot's room under the lines (what the keys do)
FindBox.BAR = 8                          -- the scroll bar's width, at the list's right
FindBox.THUMB = 24                       -- its thumb's least height
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
    keys = "Enter or a click: what to do with it   Shift-Enter: the map pin there",
    keysActs = "Enter or a click: do it   Esc: back to the finds",
    acts = "What to do",
    show = "Show on the map",
    pin = "Put the map pin there",
    sources = "Where to get it",
    sold = "Who sells it",
    drops = "What drops it",
    farm = "Where to farm it",
    teaches = "Who teaches it",
    link = "Link in the chat",
    linkPlace = "The map pin there, its link in the chat",
    whisper = Core.Word("WHISPER", "Whisper"),
    invite = Core.Word("INVITE", "Invite"),
    log = "In the quest log",
    noPlace = "Nothing on the map for it.",
    tipTake = "Enter or a click: what to do with it",
    tipPin = "Shift-Enter or Shift and a click: the map pin there",
    tipLink = "Shift and a click: its link in the chat",
    far = "far",
}
-- The pictures of what can be done (the game's own icons).
FindBox.ACT_ICONS = {
    show = "Interface\\Icons\\INV_Misc_Map_01",
    pin = "Interface\\Icons\\INV_Misc_Map02",
    sources = "Interface\\Icons\\INV_Misc_Bag_10",
    drops = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    sold = "Interface\\Icons\\INV_Misc_Coin_01",
    farm = "Interface\\Icons\\INV_Misc_Herb_01",
    teaches = "Interface\\Icons\\INV_Misc_Book_11",
    log = "Interface\\Icons\\INV_Misc_Book_08",
    link = "Interface\\Icons\\INV_Letter_15",
    whisper = "Interface\\Icons\\INV_Letter_15",
    invite = "Interface\\Icons\\Ability_Warrior_RallyingCry",
}

local field, box, words, clear, list, footer
local rows, titles = {}, {}  -- the list's buttons and title lines, made as many as needed
local lines = {}             -- what the list shows: { title, count, more } or { row }, in order
local finds = {}             -- the rows among them (each a line's find row), in order
local lit                    -- the place in finds of the row lit by the keys
local top = 0                -- the first line shown (the wheel)
local laid = FindBox.ROWS    -- the lines shown at the last layout: as many as fit
local scroller               -- the scroll bar: { track, thumb }
local answer                 -- the list's answer (Find.Ask)
local recalled               -- the place in the history of the words in the field (Up in the empty field)
local hovered                -- the row the mouse is on: its places on the map meanwhile
local chosen                 -- the row last taken (Enter, a click): its places on the map
local typed                  -- the words searched for the answer shown
local picked                 -- the row taken whose things to do the list shows (nil: the finds)
local Tip, Untip             -- a row's tooltip beside the list, and none (below)

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
    if not row or row.act then return end
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
    if row.act then
        -- a thing to do: its picture and its words, nothing far
        button.icon:SetTexture(row.icon)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon:SetDesaturated(false)
        button.name:SetText(row.text)
        button.name:SetTextColor(1, 0.82, 0)
        button.about:SetText("")
        button.far:SetText("")
        button.arrow:Hide()
        return button:Show()
    end
    local entry = row.entry
    Picture(button, entry)
    button.name:SetText(Lit(entry))
    button.name:SetTextColor(Colour(entry))
    button.about:SetText(About(row))
    Distance(button)
    button:Show()
end

-- The room for the lines, in units: from under the field down to the screen's bottom, FindBox.MARGIN kept free and
-- the foot's room under them (the field stands in the title bar at the screen's top).
local function Room()
    local bottom = field and Plain(field:GetBottom())
    if type(bottom) ~= "number" or bottom <= 0 then return FindBox.ROWS * FindBox.ROW end
    return math.max(4 * FindBox.ROW, bottom - 6 - FindBox.MARGIN - FindBox.FOOT - 6)
end

local function Height(line)
    return line.row and FindBox.ROW or FindBox.TITLE
end

-- The first line from which the rest fills the room to the end: the wheel and the scroll bar go no further.
local function Most()
    local room, used = Room(), 0
    for position = #lines, 1, -1 do
        used = used + Height(lines[position])
        if used > room then return position end
    end
    return 0
end

-- The scroll bar's track, as long as the list is tall but for its ends (as Scroller places it).
local function Track()
    return math.max(0, (Plain(list:GetHeight()) or 0) - 8 - FindBox.FOOT)
end

-- The scroll bar as the list stands: its thumb as long as the part shown is of all, where that part is.
local function Scroll(shown)
    if not scroller then return end
    local most = Most()
    local on = most > 0 and #lines > shown
    scroller.track:SetShown(on)
    if not on then return end
    local length = Track()
    local thumb = math.max(FindBox.THUMB, length * shown / #lines)
    local at = most > 0 and math.min(top, most) / most or 0
    scroller.thumb:SetHeight(thumb)
    scroller.thumb:ClearAllPoints()
    scroller.thumb:SetPoint("TOP", scroller.track, "TOP", 0, -(length - thumb) * at)
end

-- The lines from the first shown, as many as there is room for: titles and rows; room left at the right for the
-- scroll bar where they do not all fit.
local function Lay()
    for _, button in ipairs(rows) do button:Hide() end
    for _, title in ipairs(titles) do title:Hide() end
    top = math.max(0, math.min(top, Most()))
    local room = Room()
    local all = 0
    for _, line in ipairs(lines) do all = all + Height(line) end
    local right = all > room and (6 + FindBox.BAR + 6) or 6
    local y, usedRows, usedTitles, shown = -6, 0, 0, 0
    for position = top + 1, #lines do
        local line = lines[position]
        if -y - 6 + Height(line) > room then break end
        shown = shown + 1
        if line.row then
            usedRows = usedRows + 1
            local button = rows[usedRows] or FindBox.Row(usedRows)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", list, "TOPLEFT", 6, y)
            button.y = y -- (its tooltip level with it)
            button:SetPoint("TOPRIGHT", list, "TOPRIGHT", -right, y)
            Fill(button, line.row)
            if lit and finds[lit] == line.row then button:LockHighlight() else button:UnlockHighlight() end
            y = y - FindBox.ROW
        else
            usedTitles = usedTitles + 1
            local title = titles[usedTitles] or FindBox.Title(usedTitles)
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", list, "TOPLEFT", 12, y - 4)
            title:SetWidth(FindBox.LIST - 12 - right)
            local text = line.count and line.count > 1 and FindBox.TEXT.count:format(line.title, line.count) or line.title
            title.text:SetText(text)
            title.more:SetText(line.more and line.more > 0 and FindBox.TEXT.more:format(line.more) or "")
            title.text:SetTextColor(line.grey and 0.55 or 1, line.grey and 0.55 or 0.82, line.grey and 0.55 or 0)
            title:Show()
            y = y - FindBox.TITLE
        end
    end
    laid = math.max(shown, 1)
    footer:SetPoint("TOPLEFT", list, "TOPLEFT", 12, y - 4)
    list:SetHeight(-y + FindBox.FOOT)
    Scroll(shown)
end

-- The answer as the list's lines: the item or spell asked about first, then each group under its title.
local function Lines(found)
    wipe(lines)
    wipe(finds)
    lit, top, hovered, picked = nil, 0, nil, nil
    if Untip then Untip() end
    if footer then footer:SetText(FindBox.TEXT.keys) end
    if found and found.failed then
        lines[1] = { title = Core.SEARCH_FAILED, grey = true }
        return
    end
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
        Untip()
        if hovered then
            hovered = nil
            Restore()
        end
    end
end

-- An answer shown, while the field still holds the words it is for. Answers true (ns.Safe: false where it failed).
local function Answered(text, found)
    if box:GetText() ~= text then return true end
    answer, typed = found, text
    Lines(found)
    -- where to farm it: its places glow on the map at once (the map not moved)
    if found and found.farms and found.about then Find.Farms(found.farms, found.about.entry) end
    Open(found ~= nil and box:HasFocus() or (list and list:IsShown()))
    return true
end

-- A search that ran into an error (noted by ns.Safe): the list says so, the field goes on; the next key searches again.
local FAILED = { failed = true }
local function Failed()
    answer, typed = nil, nil
    Lines(FAILED)
    Open(box:HasFocus() or (list and list:IsShown()))
end

local function Ask(text)
    Find.Ask(text, function(found)
        if not ns.Safe("map search", Answered, text, found) then ns.Safe("map search", Failed) end
    end)
    return true
end

-- What is typed, searched; the answer shown while the field still holds those words.
local function Run()
    local text = box:GetText() or ""
    if text:match("^%s*$") then
        answer, typed = nil, nil
        Lines(nil)
        return Open(false)
    end
    if not ns.Safe("map search", Ask, text) then ns.Safe("map search", Failed) end
end
local Later = Core.Later(ns.Gently("map search", Run), FindBox.WAIT, "Navigation: map search")

-- The rows lit by the keys: one shown, the list scrolled to it.
local function Light(place)
    if #finds == 0 then return end
    lit = (place - 1) % #finds + 1
    local row = finds[lit]
    for position, line in ipairs(lines) do
        if line.row == row then
            if position <= top then top = math.max(position - 2, 0) end
            if position > top + laid then top = position - laid end
        end
    end
    Lay()
    Tip(row) -- (its tooltip, as under the mouse)
end

-------------------------------------------------------------------------------
--  Taking a row
-------------------------------------------------------------------------------
-- A find on the map (its places as glowing pins, the map at the nearest; the map pin too where nearness was asked for,
-- or asked: pin); the list away.
local function Show(row, pin)
    local entry = row.entry
    chosen, hovered = row, nil
    local shown = Find.Show(entry, row.role)
    if pin or (answer and answer.asked and answer.asked.near) then
        if not Find.Pin(entry) and pin then UIErrorsFrame:AddMessage(FindBox.TEXT.noPlace, 1, 0.1, 0.1) end
    elseif not shown and entry.kind ~= "zone" and entry.kind ~= "dungeon" then
        UIErrorsFrame:AddMessage(FindBox.TEXT.noPlace, 1, 0.1, 0.1)
    end
    Open(false)
    box:ClearFocus()
end

-- Words searched for a find (where to get it, who teaches it); the map at its best place to farm where that is asked,
-- else at its places (an item: where it drops).
local function Again(row, words, farm)
    local entry = row.entry
    local text = words .. (entry.name or "")
    box:SetText(text)
    box:SetCursorPosition(#text)
    Run()
    local best = farm and answer and answer.farms and answer[1] and answer[1].rows[1]
    if best then
        Find.Show(best.entry, best.role)
        chosen = best
    elseif entry.kind ~= "spell" then
        Find.Show(entry, row.role)
        chosen = row
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

-- What can be done with a find, in the order listed: on the map, the map pin; an item's ways to get it and its link;
-- a spell's trainers; a herb's, an ore's, a chest's places to farm; a place's link (the map pin there); a quest of the
-- log in the log; whisper and invite those who are people. Each { act = true, text, icon, run }.
local function Acts(row)
    local entry, acts = row.entry, {}
    local kind, icons = entry.kind, FindBox.ACT_ICONS
    local function Add(key, run)
        acts[#acts + 1] = { act = true, text = FindBox.TEXT[key], icon = icons[key], run = run }
    end
    local placed = kind ~= "item" and kind ~= "spell"
    local whole = kind == "zone" or kind == "dungeon"
    if placed then Add("show", function() Show(row, false) end) end
    if placed and not whole then Add("pin", function() Show(row, true) end) end
    if kind == "item" then
        Add("sources", function() Again(row, "where to get ") end)
        Add("drops", function() Again(row, "what drops ") end)
        Add("sold", function() Again(row, "who sells ") end)
        Add("farm", function() Again(row, "where to farm ", true) end)
        Add("link", function() Link(ItemLink(entry)) end)
    elseif kind == "spell" then
        Add("teaches", function() Again(row, "who teaches ") end)
    elseif kind == "object" and (entry.what == "herb" or entry.what == "ore" or entry.what == "chest") then
        Add("farm", function() Again(row, "where to farm ", true) end)
    end
    if placed and not whole then
        Add("linkPlace", function() if Find.Pin(entry) then Link(Core.Ask(C_Map.GetUserWaypointHyperlink)) end end)
        acts[#acts].icon = icons.link
    end
    if kind == "log" then Add("log", function() ns.QuestLog.Focus(entry.quest) end) end
    if entry.who and entry.online ~= false then
        Add("whisper", function() Tell(entry) end)
        if kind ~= "party" then Add("invite", function() Invite(entry) end) end
    end
    return acts
end

-- A find taken: the list holds it at its top and under it what can be done with it (its places glow on the map
-- meanwhile, the map not moved); one with a single thing to do does it at once.
local function Take(row)
    if not row then return end
    local entry = row.entry
    local acts = Acts(row)
    if #acts == 1 then return acts[1].run() end
    if not (entry.kind == "zone" or entry.kind == "dungeon") then Find.Preview(entry, row.role) end
    chosen, picked, hovered = row, row, nil
    wipe(lines)
    wipe(finds)
    lines[1] = { row = row }
    lines[2] = { title = FindBox.TEXT.acts }
    for _, act in ipairs(acts) do
        lines[#lines + 1] = { row = act }
        finds[#finds + 1] = act
    end
    lit, top = 1, 0
    footer:SetText(FindBox.TEXT.keysActs)
    Open(true)
    box:SetFocus()
end

-- Back from what to do to the finds, the one taken lit.
local function Back()
    local row = picked
    Lines(answer)
    for place, each in ipairs(finds) do if each == row then lit = place end end
    if lit then
        for position, line in ipairs(lines) do
            if line.row == row and position > laid then top = position - 2 end
        end
    end
    Open(true)
end

-- A row of the list taken: a find (what to do with it listed; Shift: its map pin at once) or a thing to do (done).
local function Chosen(row, shift)
    if not row then return end
    if row.act then return row.run() end
    if row == picked then return Back() end
    Find.Picked(row.entry, box:GetText()) -- (the words remembered)
    if shift and row.entry.kind ~= "zone" and row.entry.kind ~= "dungeon" and row.entry.kind ~= "item"
        and row.entry.kind ~= "spell" then
        return Show(row, true)
    end
    Take(row)
end

-------------------------------------------------------------------------------
--  A row's tooltip
-------------------------------------------------------------------------------
local function Hints(entry)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(FindBox.TEXT.tipTake, 0.5, 0.5, 0.5)
    if entry.kind == "item" then
        GameTooltip:AddLine(FindBox.TEXT.tipLink, 0.5, 0.5, 0.5)
    elseif entry.kind ~= "spell" and entry.kind ~= "zone" and entry.kind ~= "dungeon" then
        GameTooltip:AddLine(FindBox.TEXT.tipPin, 0.5, 0.5, 0.5)
    end
end

-- No tooltip of the list's.
function Untip()
    if list and GameTooltip:IsOwned(list) then GameTooltip:Hide() end
end

-- A find's tooltip at the list's right, level with its row: an item's and a spell's the game's own; an NPC's a
-- creature's as on the map's pins (PinView.Creature: its look, rank, kind, abilities and what it drops); a herb's, an
-- ore's or a chest's what it gives; any other its name; under them what it is and where, how far, and what the keys
-- and the mouse do. On a thing to do, the find's whose things they are.
function Tip(row)
    if row and row.act then row = picked end
    if not row or not list or Plain(list:IsShown()) ~= true then return Untip() end
    local entry = row.entry
    local y = 0
    for _, button in ipairs(rows) do
        if button.row == row and Plain(button:IsShown()) == true then y = button.y or 0 end
    end
    GameTooltip:SetOwner(list, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, y)
    if entry.kind == "item" and GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(entry.id)
    elseif entry.kind == "spell" and GameTooltip.SetSpellByID then
        GameTooltip:SetSpellByID(entry.spell)
    else
        local npc = entry.kind == "npc" and tonumber(entry.id)
        local unsure = entry.doubt
        if npc and ns.PinView.Creature then
            unsure = ns.Safe("map search", ns.PinView.Creature, npc, entry.name, entry.doubt) or unsure
        else
            GameTooltip:SetText(entry.name or "?", Colour(entry))
        end
        local about = About(row)
        if about ~= "" then GameTooltip:AddLine(about, 1, 0.82, 0, true) end
        if entry.kind == "log" then
            for _, objective in ipairs(Core.Ask(C_QuestLog.GetQuestObjectives, entry.quest) or {}) do
                if type(objective) == "table" and objective.text then
                    GameTooltip:AddLine("- " .. objective.text, 1, 1, 1, true)
                end
            end
        end
        if entry.kind == "object" and entry.thing and ns.PinView.Drops then
            -- (Safe answers one result: the step answers whether what it gives is unconfirmed)
            unsure = ns.Safe("map search", function() return select(2, ns.PinView.Drops(entry.thing, ns.PinView.DROPS)) end)
                or unsure
        end
        if entry.yards then GameTooltip:AddLine(Core.Distance(entry.yards), 1, 1, 1) end
        if unsure then GameTooltip:AddLine(Find.TEXT.unconfirmed, 0.5, 0.5, 0.5) end
    end
    Hints(entry)
    GameTooltip:Show()
end

-- The mouse on a row: its tooltip, its places on the map meanwhile (the map not moved); off it, the chosen one's again.
local function Entered(button)
    Tip(button.row)
    local row = button.row
    if row and not row.act and row ~= hovered and row.entry.kind ~= "zone" and row.entry.kind ~= "dungeon" then
        hovered = row
        ns.Find.Preview(row.entry, row.role)
    end
end
-- Off a row: the tooltip of the one lit by the keys again, else none.
local function Left()
    if lit and finds[lit] then return Tip(finds[lit]) end
    Untip()
end

local function Clicked(button, mouse)
    local row = button.row
    if not row then return end
    if mouse == "RightButton" then return Chosen(row, false) end
    if not row.act and row.entry.kind == "item" and IsModifiedClick("CHATLINK") then return Link(ItemLink(row.entry)) end
    Chosen(row, IsShiftKeyDown())
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
    button:SetScript("OnClick", ns.Gently("map search", Clicked))
    button:SetScript("OnEnter", ns.Gently("map search", Entered))
    button:SetScript("OnLeave", ns.Gently("map search", Left))
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
    if key == "PAGEDOWN" and #finds > 0 then Light(math.min((lit or 0) + math.max(laid - 2, 1), #finds)) end
    if key == "PAGEUP" and #finds > 0 then Light(math.max((lit or 1) - math.max(laid - 2, 1), 1)) end
end

local function Enter()
    local row = lit and finds[lit] or finds[1]
    if row then return Chosen(row, IsShiftKeyDown()) end
    box:ClearFocus()
end

local function Escape()
    if picked then return Back() end
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
    if scroller and scroller.drag then
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then scroller.drag = nil else Drag() end
    end
    elapsed = elapsed + (step or 0)
    if elapsed < FindBox.TICK then return end
    elapsed = 0
    for _, button in ipairs(rows) do
        if Plain(button:IsShown()) == true then Distance(button) end
    end
end

local function Wheel(_, delta)
    top = math.max(0, math.min(Most(), top - delta * 3))
    Lay()
end

-- The scroll bar's thumb dragged: the lines follow the cursor (the thumb's travel is all of them); a click on the
-- track above or below it, a page.
local function Drag()
    local drag = scroller and scroller.drag
    if not drag then return end
    local _, y = GetCursorPosition()
    local scale = Plain(scroller.track:GetEffectiveScale()) or 1
    local length = Track() - (Plain(scroller.thumb:GetHeight()) or 0)
    local most = Most()
    if length <= 0 or most <= 0 then return end
    local wanted = math.floor(drag.top + (drag.y - y / scale) / length * most + 0.5)
    wanted = math.max(0, math.min(most, wanted))
    if wanted ~= top then
        top = wanted
        Lay()
    end
end

local function Paged(_, mouse)
    if mouse ~= "LeftButton" or not scroller then return end
    local _, y = GetCursorPosition()
    local scale = Plain(scroller.track:GetEffectiveScale()) or 1
    local thumbTop = Plain(scroller.thumb:GetTop()) or 0
    local step = math.max(laid - 1, 1)
    top = math.max(0, math.min(Most(), top + (y / scale > thumbTop and -step or step)))
    Lay()
end

-- The scroll bar at the list's right, of the game's thin one's parts (its track, its small thumb).
local function Scroller()
    local Look = Core.Look
    local track = CreateFrame("Frame", nil, list)
    track:SetWidth(FindBox.BAR)
    track:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, -8)
    track:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -6, FindBox.FOOT)
    track:EnableMouse(true)
    local parts = { { "TOP", "minimal-scrollbar-track-top" }, { "MIDDLE", "minimal-scrollbar-track-middle" },
                    { "BOTTOM", "minimal-scrollbar-track-bottom" } }
    local pieces = {}
    for index, part in ipairs(parts) do
        local piece = track:CreateTexture(nil, "BACKGROUND")
        if not Look.Atlas(piece, part[2]) then piece:SetColorTexture(0, 0, 0, 0.5) end
        piece:SetWidth(FindBox.BAR)
        pieces[index] = piece
    end
    pieces[1]:SetPoint("TOP")
    pieces[1]:SetHeight(FindBox.BAR)
    pieces[3]:SetPoint("BOTTOM")
    pieces[3]:SetHeight(FindBox.BAR)
    pieces[2]:SetPoint("TOP", pieces[1], "BOTTOM")
    pieces[2]:SetPoint("BOTTOM", pieces[3], "TOP")
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(FindBox.BAR)
    thumb:SetHeight(FindBox.THUMB)
    thumb:SetPoint("TOP")
    local ends = { { "TOP", "minimal-scrollbar-small-thumb-top" }, { "MIDDLE", "minimal-scrollbar-small-thumb-middle" },
                   { "BOTTOM", "minimal-scrollbar-small-thumb-bottom" } }
    local bits = {}
    for index, part in ipairs(ends) do
        local bit = thumb:CreateTexture(nil, "ARTWORK")
        if not Look.Atlas(bit, part[2]) then bit:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.7) end
        bit:SetWidth(FindBox.BAR)
        bits[index] = bit
    end
    bits[1]:SetPoint("TOP")
    bits[1]:SetHeight(FindBox.BAR / 2)
    bits[3]:SetPoint("BOTTOM")
    bits[3]:SetHeight(FindBox.BAR / 2)
    bits[2]:SetPoint("TOP", bits[1], "BOTTOM")
    bits[2]:SetPoint("BOTTOM", bits[3], "TOP")
    thumb:SetScript("OnMouseDown", ns.Gently("map search", function()
        local _, y = GetCursorPosition()
        scroller.drag = { y = y / (Plain(track:GetEffectiveScale()) or 1), top = top }
    end))
    thumb:SetScript("OnMouseUp", ns.Gently("map search", function() scroller.drag = nil end))
    track:SetScript("OnMouseDown", ns.Gently("map search", Paged))
    track:Hide()
    scroller = { track = track, thumb = thumb }
end
function FindBox.Scroller() return scroller end -- (its track and thumb; for the tests)

-- The field on the title bar of the map's window (Core's, made once it was shown full), the list under it.
local function Build(handle)
    local bar = handle and handle.bar
    if field or not bar then return field end
    field = CreateFrame("Frame", nil, bar)
    field:SetHeight(FindBox.HEIGHT)
    field:SetPoint("CENTER", bar, "CENTER", 0, 0)
    field:SetFrameLevel(bar:GetFrameLevel() + 8) -- (over the map's controls and their shade, TopBar.lua)
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
    clear:SetScript("OnClick", ns.Gently("map search", FindBox.Clear))
    clear:Hide()
    -- A click anywhere on the plate puts the cursor in the field.
    field:EnableMouse(true)
    field:SetScript("OnMouseDown", ns.Gently("map search", function() box:SetFocus() end))

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
    Scroller()
    list:SetScript("OnMouseWheel", ns.Gently("map search", Wheel))
    list:SetScript("OnUpdate", ns.Gently("map search", Tick))
    list:SetScript("OnLeave", ns.Gently("map search", function()
        if hovered and Plain(list:IsMouseOver()) ~= true then
            hovered = nil
            Restore()
        end
        if not box:HasFocus() and Plain(list:IsMouseOver()) ~= true then Open(false) end
    end))
    list:Hide()

    box:SetScript("OnTextChanged", ns.Gently("map search", Changed))
    box:SetScript("OnEditFocusGained", ns.Gently("map search", Focused))
    box:SetScript("OnEditFocusLost", ns.Gently("map search", Unfocused))
    box:SetScript("OnArrowPressed", ns.Gently("map search", Arrow))
    box:SetScript("OnTabPressed", ns.Gently("map search", Tab))
    box:SetScript("OnKeyDown", ns.Gently("map search", Key))
    box:SetScript("OnEnterPressed", ns.Gently("map search", Enter))
    box:SetScript("OnEscapePressed", ns.Gently("map search", Escape))
    -- A click anywhere else (the map, the quest log) gives the keyboard back: the keys move you again.
    ns.On("GLOBAL_MOUSE_DOWN", ns.Gently("map search", function()
        if box:HasFocus() and Plain(field:IsMouseOver()) ~= true and Plain(list:IsMouseOver()) ~= true then
            box:ClearFocus()
        end
    end))
    field:Hide()
    return field
end

-- The field's width as the bar lets it be: in the room the map's controls leave between them (TopBar.Gap), in its
-- middle, FindBox.ROOM free at each side, laid anew when that room changes (a dungeon's floors come and go); without
-- them, in the bar's middle with as much room on both sides as the wider of what stands at them takes (the title at
-- the left; the buttons and the dropdown Classic windows at the right).
local Fit
local function Room(gap)
    local room = (Plain(gap:GetWidth()) or 0) - 2 * FindBox.ROOM
    field:SetWidth(math.max(FindBox.LEAST, math.min(FindBox.WIDTH, room > 0 and room or FindBox.WIDTH)))
end
function Fit(handle)
    local gap = ns.TopBar and ns.TopBar.Gap and ns.TopBar.Gap()
    if gap then
        field:ClearAllPoints()
        field:SetPoint("CENTER", gap, "CENTER", 0, 0)
        if not gap.fitted then
            gap.fitted = true
            gap:SetScript("OnSizeChanged", ns.Gently("map search", Room))
        end
        return Room(gap)
    end
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
