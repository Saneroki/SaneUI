local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Satchel
--  One button on the small map, in its lower corner at the screen's edge (the
--  window's grip has the corner away from it; the upper one where the window
--  stands in the screen's lower half): a leather satchel in the leather ring of
--  the found herbs (Found.Ring). Its click opens the satchel beside the window,
--  a page of the journal (Core.Journal) with, under their titles, large cells
--  that are easy to hit:
--
--      the zone  its title the zone and subzone you are in, as big as the boxes' numbers and
--                centred, without a rule (Saneroki, 2026-11-02), in the colour the game's minimap
--                gives them (friendly, hostile, contested, a sanctuary); under it four low boxes,
--                a big number over its word (Saneroki, 2026-11-02): your local time, the
--                realm's, the frame rate and the ping (to the world; home and world on the
--                box's tooltip); under them in two columns the time of day (Forever:
--                C_DateAndTime.IsDayTime), new mail and from whom, the calendar's invitations;
--                looked at again every second while the page is open. Then the game's Calendar (a secure button of ours over its
--                cell clicks the game's own calendar button, so the game opens its panel as
--                its own code: out of a fight only), Clock (the game's clock window: its alarm
--                and settings; while the alarm sounds, a click stops it) and Stopwatch (the
--                game's, on the screen), each ticked while open (Saneroki, 2026-10-25)
--      Sane UI   first the line of Core's sound profiles (AudioLine.lua; Saneroki, 2026-11-04):
--                Sound, the profile in use in a dropdown, a cogwheel with the game's sound
--                settings; then the quick switches Sane UI's modules offer (Core.Switches;
--                Saneroki, 2026-10-26): Speed Leveling on or off. A click is the module's own
--      AddOns    only while there are any (Saneroki, 2026-10-26): the buttons other addons hang round the minimap and the addons
--                the game's addon compartment lists (Strays.lua), each over its
--                title, A to Z, twice as large as the rest: its picture round,
--                cut inside its own frame, without the ring round it (Saneroki,
--                2026-10-25); a held button lies unseen over it, its clicks and
--                tooltip its own
--      Pins      every kind of pin the map can show here, in the pin filter's
--                order (ns.KINDS, ns.PIN_SECTIONS): a click switches it, as the
--                pin filter on the full map's bar does (their sizes stay there)
--      Tracking  what the game's own minimap tracks, as its tracking menu lists
--                it (the townsfolk, a hunter's beasts...): a click switches it as
--                that menu does; not Find Herbs, Find Minerals and Find Fish,
--                which Found herbs, Found ore and Found fishing pools switch
--                (Nodes.lua)
--
--  Beside its X, the button with the circling arrows that the game's minimap has
--  too (Core's Window.Swap; Saneroki, 2026-11-10: "so we have a toggle so we
--  can go back and forth"): the game's own minimap instead of ours (the switch
--  Show the game's minimap), and its button Sane UI window brings ours back.
--
--  A cell switched on shows its picture whole with a pencil tick, one switched
--  off faint and grey. Closed the first time the mouse leaves the page (Saneroki,
--  2026-11-02), its button counting as the page, a menu one of its cells opened
--  holding it; and by its X, Esc, the button again, or the window going to the
--  full screen. Where the screen is lower than the page, the wheel scrolls it.
--  Only on the small view, while the window is the minimap.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Journal = Core.Journal
local Satchel = {}
ns.Satchel = Satchel

Satchel.SIZE = 28          -- the button's ring across, in units
Satchel.INSET = 4          -- the button from the window's corner
Satchel.BAG = 133628       -- its picture: a leather satchel (INV_Misc_Bag_07, in both games)
Satchel.GAP = 6            -- between the window and the satchel
Satchel.LEAVE = 0.25       -- seconds off the page and its button before it closes: the way between the two is free
Satchel.COLUMNS = 6
Satchel.CELL = { 72, 58 }  -- a cell's width and height: compact (Saneroki, 2026-10-25)
Satchel.ICON = 28          -- a cell's picture, on the paper as it is (no pencil slot round it)
Satchel.ADDON = { 56, 84 } -- an addon's picture, twice the others' (Saneroki, 2026-10-25), and its row's height
Satchel.HEAD = 22          -- a section's title and its rule
Satchel.TITLE = 32         -- the zone's title over the boxes: as big as their numbers, no rule
Satchel.NOTE = 18          -- the line under an empty section's title
Satchel.AFTER = 6          -- room under a section
Satchel.ROOM = 0.8         -- the page takes at most so much of the screen's height; the wheel scrolls the rest
Satchel.FAINT = 0.4        -- a cell switched off: its picture so faint
Satchel.SPELL = { 0.0625, 0.9 } -- a tracking spell's icon cut inside its frame, as the game's menu cuts it
Satchel.TICK = "\226\136\154"   -- the pencil tick: Kalam's root sign
Satchel.ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask" -- an addon's picture cut round by it
Satchel.TRIM = 0.08        -- of an addon's picture cut off at each side: an icon's own frame
Satchel.BOX = { 102, 54 }  -- a box of the times, frame rate and ping: across (four fill the page's width) and high
Satchel.BOX_GAP = 8        -- between two boxes, and under them
Satchel.NUMBER = 40        -- a box's number and its word (Journal.Font's sizes)
Satchel.WORD = 15
Satchel.NUMBER_ROOM = 92   -- the number's widest: a longer one (a 12-hour clock's) comes out smaller
Satchel.NUMBER_AT = 2      -- the number's and the word's middles from the box's: the word a pixel or two under the
Satchel.WORD_AT = -13      -- digits, the two together in the box's middle (Saneroki, 2026-11-02)
Satchel.LINE = 16          -- a line under the boxes
Satchel.LABEL = 76         -- a line's words before its value
Satchel.EVERY = 1          -- seconds between two looks at the lines while the page is open
Satchel.CLOCK = 134376     -- the clock's picture (INV_Misc_PocketWatch_01) and the stopwatch's (Spell_Nature_TimeStop)
Satchel.STOPWATCH = 136106
Satchel.CALENDAR = "UI-HUD-Calendar-%d-Up" -- the game's calendar button's atlas for the day of the month
-- The zone's colour as the game's minimap gives it (Blizzard_Minimap, Minimap_Update), by C_PvP.GetZonePVPInfo.
Satchel.ZONE = { sanctuary = { 0.41, 0.8, 0.94 }, arena = { 1, 0.1, 0.1 }, friendly = { 0.1, 1, 0.1 },
                 hostile = { 1, 0.1, 0.1 }, contested = { 1, 0.7, 0 } }
-- The game's tracking entries its menu lists besides those of a spell (Blizzard_Minimap, OPTIONAL_FILTERS; Forever
-- has them as MinimapConstants.OPTIONAL_FILTERS, Retail keeps them to itself): Enum.MinimapTrackingFilter's names.
Satchel.OPTIONAL = { "Banker", "Auctioneer", "Barber", "TrainerProfession", "AccountCompletedQuests", "TrivialQuests",
                     "Transmogrifier", "Mailbox" }
Satchel.TEXT = {
    title = Core.Word("MINIMAP_LABEL", "Minimap"),
    tip = "Sound, addons, pins and tracking",
    addons = Core.Word("ADDONS", "AddOns"),
    pins = "Pins",
    tracking = Core.Word("TRACKING", "Tracking"),
    localTime = "Local time",
    realmTime = "Realm time",
    framerate = "FPS",
    latency = "Ping (ms)",
    homeWorld = "%d ms home, %d world", -- home and world on one line (Saneroki, 2026-10-26): the box's tooltip now
    switches = "Sane UI",
    dayTime = "Time of day",
    day = "Day",
    night = "Night",
    mail = "New mail",
    someone = "waiting",
    invites = "Invitations",
    calendar = "Calendar",
    calendarTip = "The game's calendar",
    clock = Core.Word("TIMEMANAGER_TITLE", "Clock"),
    clockTip = "The game's clock: its alarm and settings",
    alarm = "Alarm",
    alarmTip = "A click stops it",
    stopwatch = Core.Word("STOPWATCH_TITLE", "Stopwatch"),
    stopwatchTip = "The game's stopwatch, on the screen",
    fight = "After the fight: the game opens it only out of one",
    game = "Classic minimap",
    gameTip = "The game's own minimap instead of this one. The same button on it brings this one back.",
}

local button          -- the button on the small map
local panel, look, scroll, sheet
local cells, heads = {}, {} -- the cells and the sections' titles made so far, used again at each fill
local heading         -- the zone's title
local boxes = {}    -- the boxes made so far, used again
local rows = {}       -- the lines under the boxes: { label, value } font strings, used again
local shown = { figures = 0, lines = 0 } -- what the page shows of what changes: how many boxes and lines, whether the alarm sounds
local calendar        -- the secure button over the Calendar's cell (Cover)
local since = 0       -- seconds since the lines were last looked at
local predicted = {}  -- [tracking index] = on: switched here, until the game's tracking says so too (a spell's cast)
local small = false   -- the window stands small and is the minimap: the button shows
local came = false    -- the mouse has been on the page or its button since it opened (Gone)
local away = 0        -- seconds the mouse has been off them

-------------------------------------------------------------------------------
--  What it holds
-------------------------------------------------------------------------------
-- A function of the game's, where this client has it.
local function Game(name)
    local fn = rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

-- The zone you are in, its subzone after it, and its colour on the paper.
local function Zone()
    local zone, sub = Core.Plain(Core.Ask(Game("GetZoneText"))) or "", Core.Plain(Core.Ask(Game("GetSubZoneText"))) or ""
    local title = sub ~= "" and sub ~= zone and (zone ~= "" and zone .. ", " .. sub or sub) or zone
    local pvp = rawget(_G, "C_PvP")
    local kind = Core.Plain(Core.Ask(pvp and pvp.GetZonePVPInfo or Game("GetZonePVPInfo")))
    local colour = Satchel.ZONE[kind]
    if not colour then return title, nil end
    local r, g, b = Journal.Ink(colour[1], colour[2], colour[3])
    return title, { r, g, b }
end

-- The boxes under the zone's title, as the game tells them now: { number, word, tip }.
local function Figures()
    local list = {}
    local function Add(number, word, tip) if number then list[#list + 1] = { number, word, tip } end end
    Add(Core.ClockAt(), Satchel.TEXT.localTime)
    local hour, minute = Core.Ask(Game("GetGameTime"))
    if hour and minute then Add(Core.Clock(hour, minute), Satchel.TEXT.realmTime) end
    local rate = Core.Plain(Core.Ask(Game("GetFramerate")))
    if type(rate) == "number" then Add(tostring(math.floor(rate + 0.5)), Satchel.TEXT.framerate) end
    local stats = Game("GetNetStats")
    if stats then
        local _, _, home, world = stats()
        home, world = Core.Plain(home), Core.Plain(world)
        local ping = type(world) == "number" and world or home -- the world's: what your actions wait for
        if type(ping) == "number" then
            local both = type(home) == "number" and type(world) == "number"
            Add(tostring(ping), Satchel.TEXT.latency, both and Satchel.TEXT.homeWorld:format(home, world) or nil)
        end
    end
    return list
end

-- The lines under the boxes, as the game tells them now: { words, value }.
local function Lines()
    local list = {}
    local function Add(label, value) if value then list[#list + 1] = { label, value } end end
    local times = rawget(_G, "C_DateAndTime")
    if times and times.IsDayTime then
        Add(Satchel.TEXT.dayTime, Core.Ask(times.IsDayTime) and Satchel.TEXT.day or Satchel.TEXT.night)
    end
    if Core.Plain(Core.Ask(Game("HasNewMail"))) then
        local senders = {}
        for _, name in ipairs({ Core.Ask(Game("GetLatestThreeSenders")) }) do
            name = Core.Plain(name)
            if type(name) == "string" and name ~= "" then senders[#senders + 1] = name end
        end
        Add(Satchel.TEXT.mail, #senders > 0 and table.concat(senders, ", ") or Satchel.TEXT.someone)
    end
    local dates = rawget(_G, "C_Calendar")
    local invites = Core.Plain(Core.Ask(dates and dates.GetNumPendingInvites))
    if type(invites) == "number" and invites > 0 then Add(Satchel.TEXT.invites, tostring(invites)) end
    return list
end

-- Whether the game's alarm sounds now (its clock window's, Blizzard_TimeManager).
local function Alarm()
    local firing = Game("TimeManager_IsAlarmFiring")
    return firing and firing() and true or false
end

-- The game's calendar, clock and stopwatch, where this client has them (the clock's only once the game loaded it).
local function Tools()
    local list = {}
    local function Open(name) local frame = rawget(_G, name) return frame ~= nil and frame:IsShown() end
    if calendar then
        list[#list + 1] = { time = "calendar", title = Satchel.TEXT.calendar, tip = Satchel.TEXT.calendarTip,
                            art = Satchel.CALENDAR:format(tonumber(date("%d")) or 1), ticked = Open("CalendarFrame") }
    end
    if rawget(_G, "TimeManagerFrame") and Game("TimeManager_Toggle") then
        local alarm = Alarm()
        list[#list + 1] = { time = "clock", title = alarm and Satchel.TEXT.alarm or Satchel.TEXT.clock,
                            tip = alarm and Satchel.TEXT.alarmTip or Satchel.TEXT.clockTip, art = Satchel.CLOCK,
                            ticked = alarm or Open("TimeManagerFrame") }
    end
    if rawget(_G, "StopwatchFrame") and Game("Stopwatch_Toggle") then
        list[#list + 1] = { time = "stopwatch", title = Satchel.TEXT.stopwatch, tip = Satchel.TEXT.stopwatchTip,
                            art = Satchel.STOPWATCH, ticked = Open("StopwatchFrame") }
    end
    return list
end
-- The quick switches Sane UI's modules offer (Core.Switches): Speed Leveling on or off.
local function Switches()
    local list = {}
    for _, switch in ipairs(Core.Switches()) do
        list[#list + 1] = { switch = switch, title = switch.title, icon = switch.icon, on = switch.state ~= "off" }
    end
    return list
end

-- The kinds of pin the map can show here, in the pin filter's order.
local function Pins()
    local order, list = {}, {}
    for index, section in ipairs(ns.PIN_SECTIONS) do order[section[1]] = index end
    for index, kind in ipairs(ns.KINDS) do
        if ns.KindOffered(kind) then
            list[#list + 1] = { pin = kind, title = kind[2], on = ns.Pins.Shows(kind[1]),
                                rank = (order[kind.section] or #ns.PIN_SECTIONS + 1) * 1000 + index }
        end
    end
    table.sort(list, function(a, b) return a.rank < b.rank end)
    return list
end

-- The game's tracking entries its own menu shows: a spell's, and its optional ones.
local function Optional()
    local constants = rawget(_G, "MinimapConstants")
    if constants and type(constants.OPTIONAL_FILTERS) == "table" then return constants.OPTIONAL_FILTERS end
    local filters, set = Enum and Enum.MinimapTrackingFilter, {}
    for _, name in ipairs(Satchel.OPTIONAL) do
        if filters and filters[name] then set[filters[name]] = true end
    end
    return set
end

local function Listed(index, optional)
    if not C_Minimap.GetTrackingFilter then return true end
    local filter = Core.Ask(C_Minimap.GetTrackingFilter, index)
    return type(filter) == "table" and (optional[filter.filterID] or filter.spellID) and true or false
end

-- What the game's minimap tracks, as its menu lists it, but the finders Found herbs, Found ore and Found fishing
-- pools switch.
local function Tracking()
    local list, optional = {}, Optional()
    local finders = ns.Nodes.KIND
    for index = 1, Core.Plain(Core.Ask(C_Minimap.GetNumTrackingTypes)) or 0 do
        local info = Core.Ask(C_Minimap.GetTrackingInfo, index)
        if type(info) == "table" and not finders[Core.Plain(info.spellID) or 0] and Listed(index, optional) then
            local on = Core.Plain(info.active) and true or false
            if predicted[index] ~= nil then
                if predicted[index] == on then predicted[index] = nil else on = predicted[index] end
            end
            list[#list + 1] = { track = index, title = Core.Plain(info.name) or "", texture = info.texture,
                                spell = info.type == "spell", on = on }
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  The cells
-------------------------------------------------------------------------------
local function Tip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(text or "")
    GameTooltip:Show()
end

local function Entered(cell)
    cell.shade:Show()
    local item = cell.item
    if item and item.entry and not ns.Strays.Hover(item.entry, cell, true) then Tip(cell, item.title) end
    if item and item.switch then
        Tip(cell, item.switch.title)
        if item.switch.tip then GameTooltip:AddLine(item.switch.tip, 1, 1, 1, true) end
        GameTooltip:Show()
    end
    if item and item.time then
        Tip(cell, item.title)
        local fight = item.time == "calendar" and InCombatLockdown()
        GameTooltip:AddLine(fight and Satchel.TEXT.fight or item.tip, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function Left(cell)
    cell.shade:Hide()
    local item = cell.item
    if not (item and item.entry and ns.Strays.Hover(item.entry, cell, false)) then GameTooltip:Hide() end
end

-- A tracking entry switched as the game's menu switches it; shown so at once (a spell's takes its cast).
local function Track(index, on)
    predicted[index] = on
    local util = rawget(_G, "MinimapUtil")
    if util and util.SetTrackingFilterByFilterIndex then
        util.SetTrackingFilterByFilterIndex(index, on)
    else
        C_Minimap.SetTracking(index, on)
    end
end

local function Clicked(cell, mouse)
    local item = cell.item
    if not item then return end
    if item.entry then return ns.Strays.Click(item.entry, mouse) end
    if item.switch then return item.switch.Click(mouse, cell) end -- its module tells Core, which fills the satchel anew
    if item.pin then
        ns.SwitchPin(item.pin[1]) -- the setting's change fills the satchel anew (Navigation.lua)
    elseif item.track then
        Track(item.track, not item.on)
        Satchel.Fill()
    elseif item.time == "clock" then
        -- Its alarm stopped as the game's clock button stops it; else its window, out of the satchel's way.
        if Alarm() then
            TimeManager_TurnOffAlarm()
            Satchel.Fill()
        else
            TimeManager_Toggle()
            if TimeManagerFrame:IsShown() then Satchel.Close() else Satchel.Fill() end
        end
    elseif item.time == "stopwatch" then
        Stopwatch_Toggle()
        Satchel.Fill()
    end
    -- The calendar's own click comes only in a fight (out of one the secure button over it takes it): nothing then.
end

local function Cell(index)
    local cell = cells[index]
    if cell then return cell end
    cell = CreateFrame("Button", nil, sheet)
    cell:SetWidth(Satchel.CELL[1])
    cell:RegisterForClicks("AnyUp")
    cell.shade = cell:CreateTexture(nil, "BACKGROUND")
    cell.shade:SetAllPoints()
    cell.shade:SetColorTexture(Journal.SHADE[1], Journal.SHADE[2], Journal.SHADE[3], Journal.SHADE[4])
    cell.shade:Hide()
    cell.spot = CreateFrame("Frame", nil, cell)
    cell.spot:SetPoint("TOP", 0, -3)
    cell.picture = cell.spot:CreateTexture(nil, "ARTWORK")
    cell.picture:SetAllPoints()
    cell.round = cell.spot:CreateMaskTexture() -- an addon's picture is cut round by it
    cell.round:SetTexture(Satchel.ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    cell.round:SetAllPoints(cell.picture)
    cell.tick = cell:CreateFontString(nil, "OVERLAY")
    Journal.Font(cell.tick, 16, true, Journal.INK)
    cell.tick:SetPoint("BOTTOMLEFT", cell.spot, "TOPRIGHT", -3, -9)
    cell.tick:SetText(Satchel.TICK)
    cell.name = cell:CreateFontString(nil, "OVERLAY")
    Journal.Font(cell.name, 12, false, Journal.INK)
    cell.name:SetPoint("TOP", cell.spot, "BOTTOM", 0, -2)
    cell.name:SetWidth(Satchel.CELL[1] - 4)
    cell.name:SetMaxLines(2)
    cell.name:SetJustifyH("CENTER")
    cell:SetScript("OnEnter", ns.Guard(Entered))
    cell:SetScript("OnLeave", ns.Guard(Left))
    cell:SetScript("OnClick", ns.Guard(Clicked))
    cells[index] = cell
    return cell
end

-- A picture: an atlas where the game has one by that name, else a file.
local function Picture(texture, art)
    local atlases = rawget(_G, "C_Texture")
    if type(art) == "string" and atlases and atlases.GetAtlasInfo(art) then
        texture:SetAtlas(art)
    else
        texture:SetTexture(art)
    end
end

-- An addon's picture round (cut round, on), or box as it is (off).
local function Round(cell, on)
    if (cell.rounded or false) == on then return end
    cell.rounded = on
    if on then cell.picture:AddMaskTexture(cell.round) else cell.picture:RemoveMaskTexture(cell.round) end
end

-- The picture a held button shows (Strays.Picture), as it shows it: its file or atlas, its part, its colour. One cut
-- to the whole of its file is cut inside its frame, as the rest of the satchel's addons (Satchel.TRIM).
local function Copy(icon, art)
    if not art then return Picture(icon, 134400) end
    local atlas = art:GetAtlas()
    if atlas then icon:SetAtlas(atlas) else icon:SetTexture(art:GetTexture()) end
    local left, top, _, _, _, _, right, bottom = art:GetTexCoord()
    if left == 0 and top == 0 and right == 1 and bottom == 1 then
        icon:SetTexCoord(Satchel.TRIM, 1 - Satchel.TRIM, Satchel.TRIM, 1 - Satchel.TRIM)
    elseif left then
        icon:SetTexCoord(art:GetTexCoord())
    end
    local r, g, b = art:GetVertexColor()
    if r then icon:SetVertexColor(r, g, b) end
    icon:SetDesaturated(art:IsDesaturated() and true or false)
end

-- A cell let go: a held button on it back out of sight (Strays.Place), the cell hidden.
local function Empty(cell)
    local item = cell.item
    if item and item.button then ns.Strays.Place(item.button) end
    cell.item = nil
    cell:Hide()
end

-- A cell holding item (a held button, a compartment's addon, a kind of pin, a tracking entry), its picture size
-- across, the cell height high.
local function Dress(cell, item, size, height)
    cell.item = item
    cell:SetHeight(height)
    cell.spot:SetSize(size, size)
    cell.name:SetText(item.title)
    local icon = cell.picture
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetDesaturated(false)
    icon:Show()
    Round(cell, item.button ~= nil or item.entry ~= nil)
    if item.button then
        -- Its own button unseen over its picture, its clicks and tooltip its own.
        Copy(icon, ns.Strays.Picture(item.button))
        ns.Strays.Place(item.button, cell.spot, size)
    end
    local pin = item.pin
    if pin then
        Picture(icon, pin.texture or pin.icon)
        if pin.tint then icon:SetVertexColor(pin.tint[1] / 255, pin.tint[2] / 255, pin.tint[3] / 255) end
        if pin.grey then icon:SetDesaturated(true) end
    elseif item.track then
        Picture(icon, item.texture)
        if item.spell then icon:SetTexCoord(Satchel.SPELL[1], Satchel.SPELL[2], Satchel.SPELL[1], Satchel.SPELL[2]) end
    elseif item.entry then
        Picture(icon, item.icon or 134400) -- a compartment's addon without a picture: the game's question mark
        icon:SetTexCoord(Satchel.TRIM, 1 - Satchel.TRIM, Satchel.TRIM, 1 - Satchel.TRIM)
    elseif item.time then
        Picture(icon, item.art)
    elseif item.switch then
        Picture(icon, item.icon or 134400)
        icon:SetTexCoord(Satchel.SPELL[1], Satchel.SPELL[2], Satchel.SPELL[1], Satchel.SPELL[2])
    end
    local switch = item.on ~= nil -- a pin, a tracking entry, a switch: on or off
    local off = switch and not item.on
    if off then icon:SetDesaturated(true) end
    icon:SetAlpha(off and Satchel.FAINT or 1)
    cell.tick:SetShown(switch and item.on or item.ticked or false)
    cell.name:SetAlpha(off and Journal.FAINT[4] or 1)
    cell:Show()
end

-- A section's title over its rule at y on the sheet, in its colour (graphite unless given); the line under it if it
-- holds nothing.
local function Head(index, title, y, note, colour)
    local head = heads[index]
    if not head then
        head = { text = sheet:CreateFontString(nil, "OVERLAY"), rule = Journal.Rule(sheet),
                 note = sheet:CreateFontString(nil, "OVERLAY") }
        Journal.Font(head.text, 15, true, Journal.INK)
        Journal.Font(head.note, 12, false, Journal.FAINT)
        head.note:SetJustifyH("LEFT")
        heads[index] = head
    end
    colour = colour or Journal.INK
    head.text:SetTextColor(colour[1], colour[2], colour[3], 1)
    head.text:SetText(title)
    head.text:ClearAllPoints()
    head.text:SetPoint("TOPLEFT", sheet, "TOPLEFT", 2, -y)
    head.text:Show()
    head.rule:ClearAllPoints()
    head.rule:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -(y + Satchel.HEAD - 6))
    head.rule:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", 0, -(y + Satchel.HEAD - 6))
    head.rule:Show()
    head.note:SetShown(note ~= nil)
    if note then
        head.note:ClearAllPoints()
        head.note:SetPoint("TOPLEFT", sheet, "TOPLEFT", 2, -(y + Satchel.HEAD))
        head.note:SetPoint("RIGHT", sheet, "RIGHT", 0, 0)
        head.note:SetText(note)
    end
end

-- Words in bold at size, smaller where they are wider than room.
local function Fit(text, words, size, room, colour)
    Journal.Font(text, size, true, colour)
    text:SetText(words)
    local wide = text:GetStringWidth() or 0
    if wide > room then Journal.Font(text, size * room / wide, true, colour) end
end

-- The zone's title at the sheet's top, as big as the boxes' numbers, in its colour. Returns where the sheet goes on.
local function Title(words, colour)
    if not heading then
        heading = sheet:CreateFontString(nil, "OVERLAY")
        heading:SetPoint("TOP", sheet, "TOP", 0, 0)
    end
    Fit(heading, words, Satchel.NUMBER, Satchel.COLUMNS * Satchel.CELL[1] - 8, colour)
    return Satchel.TITLE
end

local function BoxEntered(box)
    if box.tip then Tip(box, box.tip) end
end

local function BoxLeft(box)
    if box.tip then GameTooltip:Hide() end
end

local function Box(index)
    local box = boxes[index]
    if box then return box end
    box = CreateFrame("Frame", nil, sheet)
    box:SetSize(Satchel.BOX[1], Satchel.BOX[2])
    box:EnableMouse(true)
    Journal.Box(box, 0.5)
    box.number = box:CreateFontString(nil, "OVERLAY")
    Journal.Font(box.number, Satchel.NUMBER, true, Journal.INK)
    box.number:SetPoint("CENTER", 0, Satchel.NUMBER_AT)
    box.word = box:CreateFontString(nil, "OVERLAY")
    Journal.Font(box.word, Satchel.WORD, false, Journal.FAINT)
    box.word:SetPoint("CENTER", 0, Satchel.WORD_AT)
    box:SetScript("OnEnter", ns.Guard(BoxEntered))
    box:SetScript("OnLeave", ns.Guard(BoxLeft))
    boxes[index] = box
    return box
end

-- A box's words as the game tells them now.
local function Tell(box, figure)
    Fit(box.number, figure[1], Satchel.NUMBER, Satchel.NUMBER_ROOM)
    box.word:SetText(figure[2])
    box.tip = figure[3]
end

-- The boxes from y on, side by side. Returns where the sheet goes on.
local function Boxes(figures, y)
    for index, figure in ipairs(figures) do
        local box = Box(index)
        box:ClearAllPoints()
        box:SetPoint("TOPLEFT", sheet, "TOPLEFT", (index - 1) * (Satchel.BOX[1] + Satchel.BOX_GAP), -y)
        Tell(box, figure)
        box:Show()
    end
    for index = #figures + 1, #boxes do boxes[index]:Hide() end
    shown.figures = #figures
    return y + (#figures > 0 and Satchel.BOX[2] + Satchel.BOX_GAP or 0)
end

-- The lines under the boxes from y on, in two columns: each its words faint, its value in graphite. Returns where
-- the sheet goes on.
local function Rows(lines, y)
    local column = Satchel.COLUMNS * Satchel.CELL[1] / 2
    for index, line in ipairs(lines) do
        local row = rows[index]
        if not row then
            row = { label = sheet:CreateFontString(nil, "OVERLAY"), value = sheet:CreateFontString(nil, "OVERLAY") }
            Journal.Font(row.label, 12, false, Journal.FAINT)
            Journal.Font(row.value, 12, false, Journal.INK)
            row.value:SetWordWrap(false)
            rows[index] = row
        end
        local x, top = ((index - 1) % 2) * column + 2, y + math.floor((index - 1) / 2) * Satchel.LINE
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", sheet, "TOPLEFT", x, -top)
        row.value:ClearAllPoints()
        row.value:SetPoint("TOPLEFT", sheet, "TOPLEFT", x + Satchel.LABEL, -top)
        row.value:SetWidth(column - Satchel.LABEL - 6)
        row.label:SetText(line[1])
        row.value:SetText(line[2])
        row.label:Show()
        row.value:Show()
    end
    for index = #lines + 1, #rows do
        rows[index].label:Hide()
        rows[index].value:Hide()
    end
    shown.lines = #lines
    return y + math.ceil(#lines / 2) * Satchel.LINE + 4
end

-- The secure button over the Calendar's cell (or none): placed and shown out of a fight only, and while the cell lies
-- wholly in the page's view (the button stands on UIParent: the page's scroll cuts the cells, not it). At a fight's
-- start it lets go of the cell (Satchel.Start): the page is then free to move, and the cell's own click does nothing.
local function Cover(cell)
    if not calendar or InCombatLockdown() then return end
    local top, bottom = cell and cell:GetTop(), cell and cell:GetBottom()
    local seen = top and bottom and top <= (scroll:GetTop() or 0) + 1 and bottom >= (scroll:GetBottom() or 0) - 1
    calendar.cell = seen and cell or nil
    calendar:ClearAllPoints()
    if not seen then return calendar:Hide() end
    calendar:SetAllPoints(cell)
    calendar:SetFrameLevel(cell:GetFrameLevel() + 5)
    calendar:Show()
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- Beside the window, toward the screen's middle: under it where it stands in the screen's upper half, else over it;
-- its edge at the window's on the side of the screen's edge it is nearer.
local function Anchor()
    local window = ns.Window.frame
    local x, y = window:GetCenter()
    local midX, midY = UIParent:GetCenter()
    local side = (x or 0) > (midX or 0) and "RIGHT" or "LEFT"
    panel:ClearAllPoints()
    if (y or 0) > (midY or 0) then
        panel:SetPoint("TOP" .. side, window, "BOTTOM" .. side, 0, -Satchel.GAP)
    else
        panel:SetPoint("BOTTOM" .. side, window, "TOP" .. side, 0, Satchel.GAP)
    end
end

-- The calendar's cell, while the page shows one.
local function CalendarCell()
    for _, cell in ipairs(cells) do
        if cell.item and cell.item.time == "calendar" then return cell end
    end
    return nil
end

local function Wheel(_, delta)
    local most = scroll:GetVerticalScrollRange() or 0
    scroll:SetVerticalScroll(math.min(math.max(scroll:GetVerticalScroll() - delta * Satchel.CELL[2], 0), most))
    Cover(CalendarCell())
end

-- Whether the mouse is on the page or its button, or in a menu a cell opened (an addon's, a switch's: outside the page),
-- or a dialog of the sound line shows.
local function Held()
    return Core.Plain(panel:IsMouseOver()) or Core.Plain(button:IsMouseOver()) or Core.MenuOpen() or ns.AudioLine.Held()
end

-- Whether the mouse has left: been on the page or its button since it opened, and off them for Satchel.LEAVE seconds.
local function Gone(elapsed)
    if Held() then
        came, away = true, 0
    elseif came then
        away = away + elapsed
    end
    return away >= Satchel.LEAVE
end

-- Each frame while the page is open: closed once the mouse has left. Every Satchel.EVERY seconds: its boxes and
-- lines as the game tells them now; the page laid out anew where one came or went, or the alarm began or stopped.
local function Look(_, elapsed)
    if Gone(elapsed) then return Satchel.Close() end
    since = since + elapsed
    if since < Satchel.EVERY then return end
    since = 0
    local figures, lines = Figures(), Lines()
    if #figures ~= shown.figures or #lines ~= shown.lines or Alarm() ~= shown.alarm then return Satchel.Fill() end
    for index, figure in ipairs(figures) do Tell(boxes[index], figure) end
    for index, line in ipairs(lines) do rows[index].value:SetText(line[2]) end
    if calendar and not calendar.cell then Cover(CalendarCell()) end -- its cell's place not known at the layout
end

local function Build()
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    Satchel.frame = panel
    look = Journal.Dress(panel, Satchel.TEXT.title)
    look.close:SetScript("OnClick", ns.Guard(function() Satchel.Close() end))
    -- The game's minimap instead of ours, as the dropdown Classic windows chooses it (Window.lua): the window rests
    -- out of sight, and the satchel goes with it.
    look.swap = Core.Window.Swap(panel, Satchel.TEXT.game, Satchel.TEXT.gameTip, function()
        Satchel.Close()
        Core.Set(ns.name, "nativeMinimap", true)
    end)
    look.swap:SetPoint("RIGHT", look.close, "LEFT", -2, 0)
    look.swap:SetFrameLevel(look.close:GetFrameLevel())
    Satchel.swap = look.swap
    scroll = CreateFrame("ScrollFrame", nil, look.content)
    scroll:SetAllPoints()
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(Wheel))
    sheet = CreateFrame("Frame", nil, scroll)
    sheet:SetSize(Satchel.COLUMNS * Satchel.CELL[1], 1)
    scroll:SetScrollChild(sheet)
    panel:SetScript("OnUpdate", ns.Guard(Look))
    ns.On("MINIMAP_UPDATE_TRACKING", function() Satchel.Fill() end)
    Core.OnSwitches(function() Satchel.Fill() end)
    for _, event in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" }) do
        ns.On(event, function() Satchel.Fill() end)
    end
end

-- What it holds, laid out anew (opened, a switch changed, a button given back); nothing while it is closed.
function Satchel.Fill()
    if not panel or not panel:IsShown() then return end
    -- Each: its title, what it holds, the line while it holds nothing, its pictures' size and its rows' height; the
    -- zone's its colour, its boxes and its lines too; Sane UI's the sound line first.
    local zone, colour = Zone()
    local sections = {
        { zone, Tools(), nil, Satchel.ICON, Satchel.CELL[2], colour = colour, figures = Figures(), lines = Lines() },
        { Satchel.TEXT.switches, Switches(), nil, Satchel.ICON, Satchel.CELL[2], audio = ns.AudioLine.Offered() },
        -- Only while other addons have buttons for it (Saneroki, 2026-10-26).
        { Satchel.TEXT.addons, ns.Strays.List(), nil, Satchel.ADDON[1], Satchel.ADDON[2] },
        { Satchel.TEXT.pins, Pins(), nil, Satchel.ICON, Satchel.CELL[2] },
        { Satchel.TEXT.tracking, Tracking(), nil, Satchel.ICON, Satchel.CELL[2] },
    }
    for _, cell in ipairs(cells) do Empty(cell) end
    for _, head in ipairs(heads) do
        head.text:Hide()
        head.rule:Hide()
        head.note:Hide()
    end
    ns.AudioLine.Hide()
    local y, used, titled = 0, 0, 0
    for _, section in ipairs(sections) do
        local items, size, height = section[2], section[4], section[5]
        if #items > 0 or section[3] or section.lines or section.audio then
            if section.figures then
                y = Boxes(section.figures, Title(section[1], section.colour))
            else
                titled = titled + 1
                Head(titled, section[1], y, #items == 0 and section[3] or nil, section.colour)
                y = y + Satchel.HEAD
            end
            if section.lines then y = Rows(section.lines, y) end
            if section.audio then y = ns.AudioLine.Place(sheet, y) end
            if #items == 0 and section[3] then y = y + Satchel.NOTE end
            for index, item in ipairs(items) do
                used = used + 1
                local cell = Cell(used)
                local column, row = (index - 1) % Satchel.COLUMNS, math.floor((index - 1) / Satchel.COLUMNS)
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", sheet, "TOPLEFT", column * Satchel.CELL[1], -(y + row * height))
                Dress(cell, item, size, height)
            end
            y = y + math.ceil(#items / Satchel.COLUMNS) * height + Satchel.AFTER
        end
    end
    y = math.max(y - Satchel.AFTER, 1) -- no room under the last section: the page's own margin is there
    local width = Satchel.COLUMNS * Satchel.CELL[1]
    sheet:SetSize(width, y)
    local _, chrome = Journal.Outer(width, 0)
    local room = (tonumber(UIParent:GetHeight()) or 768) * Satchel.ROOM - chrome
    panel:SetSize(Journal.Outer(width, math.max(math.min(y, room), 1)))
    shown.alarm = Alarm()
    since = 0
    Wheel(nil, 0) -- the scroll within the new height; the calendar's secure button over its cell
end

function Satchel.Open()
    if not small then return end
    if not panel then Build() end
    came, away = false, 0
    ns.Strays.Look()
    Anchor()
    panel:Show()
    panel:Raise()
    Satchel.Fill()
    Core.Escape(panel, function() ns.Guarded(Satchel.Close) end)
end

function Satchel.Close()
    if not panel or not panel:IsShown() then return end
    Cover(nil)
    panel:Hide()
    Core.Escape(panel, nil)
    for _, cell in ipairs(cells) do Empty(cell) end -- the held buttons wait out of sight again
end

function Satchel.Toggle()
    if panel and panel:IsShown() then Satchel.Close() else Satchel.Open() end
end

function Satchel.Shown()
    return panel ~= nil and panel:IsShown()
end

-------------------------------------------------------------------------------
--  The button
-------------------------------------------------------------------------------
local function ButtonTip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(Satchel.TEXT.title)
    GameTooltip:AddLine(Satchel.TEXT.tip, 1, 1, 1)
    GameTooltip:Show()
end

function Satchel.Build(canvas)
    button = CreateFrame("Button", nil, canvas)
    button:SetSize(Satchel.SIZE, Satchel.SIZE)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(Satchel.BAG)
    icon:SetPoint("CENTER")
    ns.Found.Round(icon, button:CreateMaskTexture())
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(ns.Found.RING)
    ns.Found.Ring(ring, icon, Satchel.SIZE * ns.Found.HOLE / ns.Found.OUTER)
    button:SetScript("OnClick", ns.Guard(Satchel.Toggle))
    button:SetScript("OnEnter", ns.Guard(ButtonTip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:Hide()
    Satchel.button = button
    -- The Calendar's secure button (Cover): it clicks the game's own calendar button (out of sight with the
    -- minimap's cluster, but there), so the game opens its calendar panel as its own code; ours may not.
    local game = rawget(_G, "GameTimeFrame")
    if game then
        calendar = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
        calendar:SetFrameStrata("DIALOG")
        calendar:RegisterForClicks("LeftButtonUp")
        calendar:SetAttribute("type", "click")
        calendar:SetAttribute("clickbutton", game)
        calendar:SetAttribute("useOnKeyDown", false) -- on the release, as it is registered
        calendar:SetScript("OnEnter", ns.Guard(function() if calendar.cell then Entered(calendar.cell) end end))
        calendar:SetScript("OnLeave", ns.Guard(function() if calendar.cell then Left(calendar.cell) end end))
        calendar:HookScript("PostClick", ns.Guard(function() C_Timer.After(0.1, ns.Guard(Satchel.Fill)) end))
        calendar:Hide()
        Satchel.calendar = calendar
        -- A fight: it lets go of the cell before the game locks it (the page moves freely meanwhile); after: back.
        ns.On("PLAYER_REGEN_DISABLED", function()
            calendar.cell = nil
            calendar:Hide()
            calendar:ClearAllPoints()
        end)
        ns.On("PLAYER_REGEN_ENABLED", function() if Satchel.Shown() then Satchel.Fill() end end)
    end
end

-- Over what stands on the map (Canvas.lua lays the levels).
function Satchel.Stack(level)
    if button then button:SetFrameLevel(level) end
end

-- The window stands small and is the minimap (on), or not (full, on its way, resting, gone): the button in the
-- corner at the screen's edge, or gone with the satchel.
function Satchel.Place(on)
    small = on and true or false
    if not button then return end
    if not small then
        Satchel.Close()
        return button:Hide()
    end
    local window = ns.Window.frame
    local x, y = window:GetCenter()
    local midX, midY = UIParent:GetCenter()
    local corner = ((y or 0) > (midY or 0) and "BOTTOM" or "TOP") .. ((x or 0) > (midX or 0) and "RIGHT" or "LEFT")
    local dx = corner:find("RIGHT") and -Satchel.INSET or Satchel.INSET
    local dy = corner:find("TOP") and -Satchel.INSET or Satchel.INSET
    button:ClearAllPoints()
    button:SetPoint(corner, button:GetParent(), corner, dx, dy)
    button:Show()
    if panel and panel:IsShown() then Anchor() end
end

-- The module stood down: the button and the satchel go.
function Satchel.Hide()
    Satchel.Place(false)
end
