local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Instances
--  The bar's button Dungeons (TopBar.lua): every dungeon and raid of Forever this year, as banners over the full map
--  under its title bar (Saneroki, 2026-11-15: "when the button is pressed you can see all the dungeons and raids that
--  are currently available in Forever ... sort them into dungeons and raids ... you can press on the banners with
--  name, level, amount of quests information on it. You have options to route to there, show it on the map and see
--  its instance maps").
--
--      the list     Core's set Instances: the game's group finder's dungeons and raids, and those Blizzard
--                   announced. Two sections, Dungeons and Raids, the lowest level first, then A to Z; every
--                   dungeon, a raid only from the year of the day it opens (one without: not announced for Forever,
--                   left out: Molten Core, Blackwing Lair, Zul'Gurub). Where the set is not there (Retail: its data
--                   comes later) the dungeons the game has maps of (Dungeons.List), A to Z, in one section
--      a banner     the game's own picture of the instance (Instances.ART: the Encounter Journal's, else its
--                   loading screen, cut to the banner), on it its name, its levels, how many of your quests lead
--                   inside, a raid's players and bosses and the day it opens; marked unconfirmed what the client does
--                   not hold yet. Under it three grey square buttons (the kit's normal ones) with the game's icons:
--                   Route (the map pin: at its entrance, the golden line leads there, Find.Pin), Show on the map (the
--                   golden glass: its entrance, Find.Show; the zone where only that is known) and Its maps (the
--                   dungeon mark: floor by floor, Dungeons.Show); one that cannot greyed, its tooltip says why. A
--                   click on the banner: its maps, else its entrance on the map
--      entrances    Core's set Places: its dungeon and raid entrances by the instance's map; else the set's zone
--      its quests   counted once, a job of Core's scheduler (Count): the quests of your side, race and class with an
--                   objective inside: a creature that stands there (the set Dungeons' enemies, its bosses by their
--                   names) or an item most of whose sources stand there (Core's Data.Drops). Wings of one instance
--                   (Dire Maul's, Blackrock Spire's) share its count
--      the room     the full map under the bar and beside the quest log where it stands over the map
--                   (Dungeons.Margins); as many banners a row as fit at their own size, each at most
--                   Instances.LARGEST of it; the wheel scrolls; a right click goes back to the map
--      the button   the bar's Dungeons: the banners, or the map again; while a dungeon's floor shows, the banners
--                   again (Instances.Toggle)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Instances = {}
ns.Instances = Instances

Instances.WIDTH, Instances.HEIGHT = 174, 96 -- a banner at its own size (the Encounter Journal's instance button)
Instances.LARGEST = 1.5   -- a banner drawn at most so much larger
Instances.GAP = 16        -- between two banners, across and down
Instances.BUTTON = 26     -- the grey square buttons under a banner (the kit's normal ones: Look.Square)
Instances.ICON = 16       -- their icons
Instances.SPACE = 4       -- between a banner and its buttons
Instances.APART = 10      -- between two of its buttons
Instances.HEAD = 44       -- a section's head and the room under it
Instances.SIDE = 12       -- room at the view's sides and foot
Instances.BAR = 22        -- the scroll bar's room at the right
Instances.SHADE = 0.6     -- of a banner's height, the dark under its words at its foot
Instances.SHADE_ALPHA = 0.85
Instances.FIRST = 100001  -- the set's own numbers (an announced instance the client does not hold yet) start here

Instances.TEXT = {
    dungeons = Core.Word("DUNGEONS", "Dungeons"),
    raids = Core.Word("RAIDS", "Raids"),
    maps = "Dungeons and raids",
    dungeon = "Dungeon", raid = "Raid",
    levels = "Level %d-%d", level = "Level %d",
    levelsTip = "level %d-%d", levelTip = "level %d",
    quests = "%d quests", quest = "1 quest",
    questsTip = "%d of your quests lead inside", questTip = "1 of your quests leads inside",
    shared = "%s, in all of %s", -- the count of an instance's wing: the whole instance's
    noQuests = "No quest of yours known to lead inside",
    players = "%d players", bosses = "%d bosses",
    opens = "Opens %d %s",
    entrance = "Its entrance: %s",
    route = "Route", show = "Show on the map", open = "Its maps",
    routeTip = "The map pin at its entrance: the golden line leads you there.",
    showTip = "Its entrance on the map.",
    zoneTip = "%s, where its entrance is.",
    openTip = "Its maps, floor by floor.",
    noEntrance = "Its entrance is not known yet.",
    noMaps = "No map of it yet.",
    clickMaps = "Click: its maps.", clickShow = "Click: its entrance on the map.",
    back = "Right click: back to the map.",
    none = "No dungeon or raid to show.",
}
Instances.MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
                     "November", "December" } -- where the game has no names of its own (CALENDAR_FULLDATE_MONTH_NAMES)

-- The game's own picture of each instance (by the set's key): the Encounter Journal's button (its picture the top left of
-- the file, as EncounterInstanceButtonTemplate cuts it), else a loading screen cut to the banner's shape (left, right,
-- top, bottom): Forever's own of its new dungeons (the client's Map gives each its loading screen), and for the two
-- raids the client does not hold yet the game's pictures of a great tree's glade (Hyjal Summit, by Nordrassil) and of
-- a druids' barrow gate (The Barrow Deeps). The rest: the Journal's empty button.
local JOURNAL = "Interface\\EncounterJournal\\UI-EJ-DUNGEONBUTTON-"
local SCREENS = "Interface\\Glues\\LoadingScreens\\"
local CAMELOT = SCREENS .. "Camelot160\\Main\\LoadScreen_Camelot_"
local JOURNAL_PART = { 0, 0.68359375, 0, 0.7421875 }
local NEW = { 0.1838, 0.8162, 0.19, 0.81 } -- Forever's loading screens (2992 x 1684): the middle of the picture between its bands
Instances.ART = {
    [1] = "WailingCaverns", [2] = "Scholomance", [3] = "RagefireChasm", [5] = "Deadmines", [7] = "ShadowFangKeep",
    [9] = "BlackfathomDeeps", [11] = "TheStockade", [13] = "Gnomeregan", [15] = "RazorfenKraul",
    [17] = "ScarletMonastery", [19] = "RazorfenDowns", [21] = "Uldaman", [23] = "ZulFarrak", [25] = "Maraudon",
    [27] = "SunkenTemple", [29] = "BlackrockDepths", [31] = "BlackrockSpire", [33] = "DireMaul", [35] = "DireMaul",
    [37] = "DireMaul", [39] = "Stratholme", [41] = "ZulGurub", [43] = "UpperBlackrockSpire", [45] = "Onyxia",
    [47] = "MoltenCore", [49] = "BlackwingLair",
    [3271] = { CAMELOT .. "Dalaran", NEW }, [3272] = { CAMELOT .. "RuinsofLordaeron", NEW },
    [3273] = { CAMELOT .. "OldIronforge", NEW }, [3274] = { CAMELOT .. "Excavation", NEW },
    [100001] = { SCREENS .. "LoadingScreen_EmeraldDreamway_wide", { 0.30, 0.7531, 0.29, 0.79 } },
    [100002] = { SCREENS .. "LoadingScreen_DruidOrderHall_Wide", { 0.42, 0.8731, 0.29, 0.79 } },
}
Instances.DEFAULT = "Default"

local SET = Core.Data.Set("Instances")
local PLACES = Core.Data.Set("Places")
local DUNGEONS = Core.Data.Set("Dungeons")
local ENCOUNTERS = Core.Data.Set("Encounters")
local NPCS = Core.Data.Set("NPCs")
local QUESTS = Core.Data.Set("Quests")
local MAPS = Core.Data.Set("Maps")
local NONE = {}
local TEXT = Instances.TEXT

local view, scroll, sheet, canvas
local heads, banners = {}, {} -- made as many as needed
local sections         -- what the view lists: { { title, entries... } }, made once the set is read (List)
local counts           -- quests per instance's map once counted; counting: the job meanwhile
local counting

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
-- Today as the set writes days (YYYY-MM-DD): the realm's calendar, else the computer's.
local function Today()
    local calendar = rawget(_G, "C_DateAndTime")
    local now = calendar and Core.Ask(calendar.GetCurrentCalendarTime)
    if type(now) == "table" and now.year and now.month and now.monthDay then
        return ("%04d-%02d-%02d"):format(now.year, now.month, now.monthDay)
    end
    return date("%Y-%m-%d")
end

-- "Opens 9 December" for a day still to come; nil for one gone (or none).
local function Opens(day, today)
    if type(day) ~= "string" or day <= today then return nil end
    local month, monthDay = tonumber(day:sub(6, 7)), tonumber(day:sub(9, 10))
    if not month or not monthDay then return nil end
    local names = rawget(_G, "CALENDAR_FULLDATE_MONTH_NAMES")
    local name = type(names) == "table" and type(names[month]) == "string" and names[month] or Instances.MONTHS[month]
    return TEXT.opens:format(monthDay, name or "")
end

-- The lowest level first, then the highest, then A to Z.
local function Before(a, b)
    if (a.low or 0) ~= (b.low or 0) then return (a.low or 0) < (b.low or 0) end
    if (a.high or 0) ~= (b.high or 0) then return (a.high or 0) < (b.high or 0) end
    return a.name < b.name
end

-- The view's sections from the set (Dungeons, Raids), else the game's dungeon maps in one.
local function List()
    if sections then return sections end
    if not SET:Ready() then
        local section = { title = TEXT.maps }
        for _, each in ipairs(ns.Dungeons.List()) do
            section[#section + 1] = { key = each.map, name = each.name, floor = each.floors[1].map, fallback = true }
        end
        return { section }
    end
    local today = Today()
    local year = today:sub(1, 4)
    sections = { { title = TEXT.dungeons, kind = "dungeon" }, { title = TEXT.raids, kind = "raid" } }
    for _, section in ipairs(sections) do
        for _, key in ipairs(SET:Keys("byKind", section.kind)) do
            local record = SET:Get(key)
            local opens = type(record) == "table" and record.opens
            if type(record) == "table" and type(record.name) == "string"
                and (section.kind == "dungeon" or type(opens) == "string" and opens:sub(1, 4) <= year) then
                local floor = record.map and ns.Dungeons.Key(record.map)
                section[#section + 1] = {
                    key = key, name = record.name, kind = record.kind, map = record.map, low = record.levelMin,
                    high = record.levelMax, players = record.players, bosses = record.bosses, zone = record.zone,
                    opens = Opens(opens, today), doubt = SET:Unverified(key),
                    floor = floor and ns.Dungeons.Named(floor) and floor or nil,
                }
            end
        end
        table.sort(section, Before)
    end
    -- An instance's wings (one map, several entries): their count is the whole instance's.
    local seen = {}
    for _, section in ipairs(sections) do
        for _, entry in ipairs(section) do
            if entry.map then seen[entry.map] = (seen[entry.map] or 0) + 1 end
        end
    end
    for _, section in ipairs(sections) do
        for _, entry in ipairs(section) do entry.wing = entry.map and seen[entry.map] > 1 or nil end
    end
    return sections
end

-- Where its entrance stands: Core's places of the instance's map, each { map, x, y } (0 to 1); kept.
local function Entrances(entry)
    if entry.spots then return entry.spots end
    local spots = {}
    if entry.map then
        for _, kind in ipairs({ "dungeon", "raid" }) do
            for _, key in ipairs(PLACES:Keys("byKind", kind)) do
                local place = PLACES:Get(key)
                local point = type(place) == "table" and place.instance == entry.map and place.point
                if type(point) == "table" and point.map and point.x and point.y then
                    spots[#spots + 1] = { map = point.map, x = point.x / 100, y = point.y / 100 }
                end
            end
        end
    end
    entry.spots = spots
    return spots
end

-- The find the map's search shows and pins (Find.Show, Find.Pin): a place at its entrances; nil where none is known.
local function Found(entry)
    local spots = Entrances(entry)
    if #spots == 0 then return nil end
    return { kind = "place", group = "zone", key = "instance:" .. tostring(entry.key), what = entry.kind or "dungeon",
             name = entry.name, role = entry.kind == "raid" and TEXT.raid or TEXT.dungeon, spots = spots,
             low = entry.low, high = entry.high }
end

-- A zone map's name, as the game has it.
local function MapName(map)
    local info = map and Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info.name or nil
end

-- An instance's name by its map (the game's Map table, Core's sets Maps and Dungeons: no zone map's ID).
local function InstanceName(map)
    return map and (MAPS:Get(map, "name") or DUNGEONS:Get(map, "name")) or nil
end

-------------------------------------------------------------------------------
--  Its quests
-------------------------------------------------------------------------------
-- Whether a quest is one you may take: of your side, your race and your class, or of everyone's.
local function Yours(record, side, race, class)
    if record.side and record.side ~= side then return false end
    local function Holds(list, value)
        if type(list) ~= "table" or #list == 0 then return true end
        for _, each in ipairs(list) do if each == value then return true end end
        return false
    end
    return Holds(record.races, race) and Holds(record.classes, class)
end

-- The quests of yours with an objective inside each instance of the list, counted once as a job: then the banners
-- say so. Waits for Core's quests where they are not read yet.
local function Count()
    if counts or counting or not SET:Ready() then return end
    local inside, named, maps = {}, {}, {}
    for _, section in ipairs(List()) do
        for _, entry in ipairs(section) do
            if entry.map and not maps[entry.map] then
                maps[entry.map] = true
                for _, enemy in ipairs(DUNGEONS:Get(entry.map, "enemies") or NONE) do
                    if enemy.npc then inside[enemy.npc] = entry.map end
                end
                for _, boss in ipairs(DUNGEONS:Get(entry.map, "bosses") or NONE) do
                    local name = boss.encounter and ENCOUNTERS:Get(boss.encounter, "name")
                    if name then named[name] = entry.map end
                end
            end
        end
    end
    local function Where(npc)
        return inside[npc] or named[NPCS:Get(npc, "name") or false]
    end
    -- The instance most of an item's sources stand in (more than half of them).
    local drops, items = Core.Data.Drops(), {}
    local function Source(item)
        if items[item] ~= nil then return items[item] or nil end
        local tally, total = {}, 0
        for _, source in ipairs(drops:From(item) or NONE) do
            total = total + 1
            local npc = type(source.key) == "string" and tonumber(source.key:match("^npc:(%d+)$"))
            local map = npc and Where(npc)
            if map then tally[map] = (tally[map] or 0) + 1 end
        end
        local found = false
        for map, many in pairs(tally) do
            if many * 2 > total then found = map end
        end
        items[item] = found
        return found or nil
    end
    local side = string.lower(Core.Plain(Core.Ask(UnitFactionGroup, "player")) or "")
    local _, _, race = Core.Ask(UnitRace, "player")
    local _, _, class = Core.Ask(UnitClass, "player")
    local found = {}
    counting = true
    local job = QUESTS:Each(function(_, record)
        if not Yours(record, side, race, class) then return end
        local hit = {}
        for _, objective in ipairs(type(record.objectives) == "table" and record.objectives or NONE) do
            local map
            if objective.kind == "kill" and objective.what then map = Where(objective.what)
            elseif objective.kind == "loot" and objective.what then map = Source(objective.what) end
            if map and not hit[map] then
                hit[map] = true
                found[map] = (found[map] or 0) + 1
            end
        end
    end, function(problem)
        counting = nil
        if problem then return end -- (kept by the walk's own label; the banners go on without)
        counts = found
        ns.Safe("dungeons", Instances.Refresh)
    end)
    if job == false then -- Core's quests not read yet: counted once they are
        counting = nil
        Core.Data.WhenReady(QUESTS, ns.Guard(function() Count() end))
    elseif counting then
        counting = job -- (unless it ended at once)
    end
end

-- How many of your quests lead into an entry's instance; nil while not counted.
function Instances.Quests(entry)
    if not counts or not entry.map then return nil end
    return counts[entry.map] or 0
end

-------------------------------------------------------------------------------
--  A banner
-------------------------------------------------------------------------------
-- Its words under its name: its levels and how many of your quests lead inside (a raid: its players there, its quests
-- under them), and the day it opens; the rest in its tooltip.
local function Words(entry)
    local first, second = {}, {}
    if entry.low and entry.high and entry.low ~= entry.high then first[#first + 1] = TEXT.levels:format(entry.low, entry.high)
    elseif entry.low then first[#first + 1] = TEXT.level:format(entry.low) end
    local quests = Instances.Quests(entry)
    quests = quests and quests > 0 and (quests == 1 and TEXT.quest or TEXT.quests:format(quests)) or nil
    if entry.kind == "raid" and entry.players then
        first[#first + 1] = TEXT.players:format(entry.players)
        second[#second + 1] = quests
    else
        first[#first + 1] = quests
    end
    if entry.opens then second[#second + 1] = entry.opens end
    local text = table.concat(first, "  ·  ")
    if #second > 0 then text = text .. (text ~= "" and "\n" or "") .. table.concat(second, "  ·  ") end
    return text
end

-- What its buttons can do: its entrance on the map (or its zone), its maps.
local function Can(entry)
    return Found(entry) ~= nil, Found(entry) ~= nil or entry.zone ~= nil, entry.floor ~= nil
end

local function Route(entry)
    local find = Found(entry)
    if not find then return end
    Instances.Close()
    ns.Find.Show(find)
    ns.Find.Pin(find)
end

local function ShowIt(entry)
    local find = Found(entry)
    if not find and not entry.zone then return end
    Instances.Close()
    if find then return ns.Find.Show(find) end
    ns.Find.Clear()
    ns.Canvas.Show(entry.zone)
end

local function OpenMaps(entry)
    if not entry.floor then return end
    Instances.Close()
    ns.Dungeons.Show(entry.floor)
end

local function Tip(banner)
    local entry = banner.entry
    if not entry then return end
    GameTooltip:SetOwner(banner, "ANCHOR_RIGHT")
    GameTooltip:SetText((entry.doubt and Core.UNCONFIRMED_MARK or "") .. entry.name, Look.GOLD[1], Look.GOLD[2], Look.GOLD[3])
    local about = {}
    if entry.kind then about[#about + 1] = entry.kind == "raid" and TEXT.raid or TEXT.dungeon end
    if entry.low and entry.high and entry.low ~= entry.high then about[#about + 1] = TEXT.levelsTip:format(entry.low, entry.high)
    elseif entry.low then about[#about + 1] = TEXT.levelTip:format(entry.low) end
    if entry.players then about[#about + 1] = TEXT.players:format(entry.players) end
    if entry.bosses then about[#about + 1] = TEXT.bosses:format(entry.bosses) end
    if #about > 0 then GameTooltip:AddLine(table.concat(about, ", "), 1, 1, 1) end
    if entry.opens then GameTooltip:AddLine(entry.opens, 1, 1, 1) end
    local quests = Instances.Quests(entry)
    if quests then
        local words = quests == 0 and TEXT.noQuests or quests == 1 and TEXT.questTip or TEXT.questsTip:format(quests)
        if entry.wing and quests > 0 then words = TEXT.shared:format(words, InstanceName(entry.map) or entry.name) end
        GameTooltip:AddLine(words, 1, 1, 1, true)
    end
    local spots = Entrances(entry)
    local where = MapName(spots[1] and spots[1].map or entry.zone)
    if where then GameTooltip:AddLine(TEXT.entrance:format(where), 1, 1, 1) end
    local _, showable, maps = Can(entry)
    if maps or showable then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(maps and TEXT.clickMaps or TEXT.clickShow, 0.6, 0.6, 0.6)
    end
    if entry.doubt then Core.Unconfirmed(GameTooltip) end
    GameTooltip:Show()
end

local function Entered(banner)
    banner.outline:SetStrong(true)
    Tip(banner)
end

local function Left(banner)
    banner.outline:SetStrong(false)
    GameTooltip:Hide()
end

-- The banner clicked: its maps, else its entrance on the map.
local function Clicked(banner)
    local entry = banner.entry
    if not entry then return end
    if entry.floor then return OpenMaps(entry) end
    ShowIt(entry)
end

local function ButtonTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
    GameTooltip:SetText(button.title, 1, 1, 1)
    GameTooltip:AddLine(button.tip, nil, nil, nil, true)
    GameTooltip:Show()
end

-- A grey square button under the banner, the game's icon on it (greyed while it cannot act).
local function Action(banner, icon, words, fn)
    local button = Look.Square(banner.holder, Instances.BUTTON)
    button:Icon(Look.Has(icon) and icon or "common-search-magnifyingglass", Instances.ICON)
    button.title = words
    button:SetMotionScriptsWhileDisabled(true) -- (a greyed one still says why)
    button:SetScript("OnClick", ns.Guard(function() if banner.entry then fn(banner.entry) end end))
    button:SetScript("OnEnter", ns.Guard(ButtonTip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

local function Banner()
    local banner = CreateFrame("Button", nil, sheet)
    banner.holder = sheet
    banner.art = banner:CreateTexture(nil, "BACKGROUND")
    banner.art:SetPoint("TOPLEFT", 1, -1)
    banner.art:SetPoint("BOTTOMRIGHT", -1, 1)
    banner.shade = banner:CreateTexture(nil, "BORDER")
    banner.shade:SetPoint("BOTTOMLEFT", 1, 1)
    banner.shade:SetPoint("BOTTOMRIGHT", -1, 1)
    banner.shade:SetColorTexture(0, 0, 0, 1)
    if rawget(_G, "CreateColor") and banner.shade.SetGradient then
        Core.Safe("dungeons", banner.shade.SetGradient, banner.shade, "VERTICAL", CreateColor(0, 0, 0, Instances.SHADE_ALPHA),
            CreateColor(0, 0, 0, 0))
    else
        banner.shade:SetAlpha(Instances.SHADE_ALPHA / 2)
    end
    banner.outline = Look.Outline(banner, "ARTWORK")
    banner.outline.fill:Hide() -- (the picture is its inside)
    banner.info = banner:CreateFontString(nil, "OVERLAY")
    Look.SetFont(banner.info, 14, false, Look.INK)
    banner.info:SetPoint("BOTTOMLEFT", 7, 6)
    banner.info:SetPoint("BOTTOMRIGHT", -7, 6)
    banner.info:SetJustifyH("LEFT")
    banner.name = banner:CreateFontString(nil, "OVERLAY")
    Look.SetFont(banner.name, 18, true, Look.GOLD)
    banner.name:SetPoint("BOTTOMLEFT", banner.info, "TOPLEFT", 0, 3)
    banner.name:SetPoint("BOTTOMRIGHT", banner.info, "TOPRIGHT", 0, 3)
    banner.name:SetJustifyH("LEFT")
    banner.name:SetWordWrap(true)
    banner:RegisterForClicks("LeftButtonUp")
    banner:SetScript("OnClick", ns.Guard(Clicked))
    banner:SetScript("OnEnter", ns.Guard(Entered))
    banner:SetScript("OnLeave", ns.Guard(Left))
    banner.route = Action(banner, "Waypoint-MapPin-Untracked", TEXT.route, Route) -- (the marker card's map pin)
    banner.show = Action(banner, "glues-characterSelect-icon-search", TEXT.show, ShowIt) -- (the kit's golden glass)
    banner.open = Action(banner, "dungeon", TEXT.open, OpenMaps) -- (the map's own entrance mark)
    return banner
end

-- Its picture: the Journal's, else the loading screen's part, else the Journal's empty button.
local function Picture(banner, entry)
    local art = Instances.ART[entry.key]
    if entry.fallback then art = nil end
    if type(art) == "table" then
        banner.art:SetTexture(art[1])
        banner.art:SetTexCoord(art[2][1], art[2][2], art[2][3], art[2][4])
    else
        banner.art:SetTexture(JOURNAL .. (art or Instances.DEFAULT))
        banner.art:SetTexCoord(JOURNAL_PART[1], JOURNAL_PART[2], JOURNAL_PART[3], JOURNAL_PART[4])
    end
end

-- A banner given its entry: its picture, its words, its buttons as they can.
local function Fill(banner, entry)
    banner.entry = entry
    Picture(banner, entry)
    banner.name:SetText((entry.doubt and Core.UNCONFIRMED_MARK or "") .. entry.name)
    banner.info:SetText(Words(entry))
    local routable, showable, maps = Can(entry)
    local where = MapName(entry.zone)
    banner.route.tip = routable and TEXT.routeTip or TEXT.noEntrance
    banner.show.tip = routable and TEXT.showTip or showable and TEXT.zoneTip:format(where or "?") or TEXT.noEntrance
    banner.open.tip = maps and TEXT.openTip or TEXT.noMaps
    for button, can in pairs({ [banner.route] = routable, [banner.show] = showable, [banner.open] = maps }) do
        button:SetEnabled(can)
        button.icon:SetDesaturated(not can)
        button.icon:SetAlpha(can and 1 or 0.4)
    end
end

-- A banner and its buttons where the layout puts them, that size.
local function Place(banner, x, y, width, height)
    banner:ClearAllPoints()
    banner:SetPoint("TOPLEFT", sheet, "TOPLEFT", x, -y)
    banner:SetSize(width, height)
    banner.shade:SetHeight(height * Instances.SHADE)
    local size, apart = Instances.BUTTON, Instances.APART
    local left = x + (width - 3 * size - 2 * apart) / 2 -- the three in the middle under it
    for index, button in ipairs({ banner.route, banner.show, banner.open }) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", sheet, "TOPLEFT", left + (index - 1) * (size + apart), -(y + height + Instances.SPACE))
        button:Show()
    end
    banner:Show()
end

local function Hidden(banner)
    banner:Hide()
    banner.entry = nil
    banner.art:SetTexture(nil) -- its file let go
    for _, button in ipairs({ banner.route, banner.show, banner.open }) do button:Hide() end
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
-- The sections laid out in the room: each under its head, its banners in rows, as many a row as fit at their size
-- (at least one), as large as the row allows up to Instances.LARGEST, each row in the middle of the room.
function Instances.Layout()
    if not view or not view:IsShown() then return end
    local top, left, right = ns.Dungeons.Margins(view)
    local side = Instances.SIDE
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", view, "TOPLEFT", left + side, -top)
    scroll:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -(right + side + Instances.BAR), side)
    local width = math.max(1, (view:GetWidth() or 0) - left - right - 2 * side - Instances.BAR)
    local gap = Instances.GAP
    local across = math.max(1, math.floor((width + gap) / (Instances.WIDTH + gap)))
    local scale = math.min(Instances.LARGEST, (width - (across - 1) * gap) / across / Instances.WIDTH)
    local bannerWidth, bannerHeight = Instances.WIDTH * scale, Instances.HEIGHT * scale
    local rowHeight = bannerHeight + Instances.SPACE + Instances.BUTTON + gap
    local y, used, shown = 0, 0, 0
    for index, section in ipairs(List()) do
        local head = heads[index]
        if not head then
            head = Look.Head(sheet, "")
            head:SetWidth(Look.HEAD * 6)
            heads[index] = head
        end
        head:SetShown(#section > 0)
        if #section > 0 then
            head.text:SetText(section.title)
            head:ClearAllPoints()
            head:SetPoint("TOP", sheet, "TOP", 0, -y)
            y = y + Instances.HEAD
            for number, entry in ipairs(section) do
                used = used + 1
                local banner = banners[used] or Banner()
                banners[used] = banner
                Fill(banner, entry)
                local column, row = (number - 1) % across, math.floor((number - 1) / across)
                local inRow = math.min(across, #section - row * across) -- each row in the middle, a short one too
                local x0 = math.max(0, (width - (inRow * bannerWidth + (inRow - 1) * gap)) / 2)
                Place(banner, x0 + column * (bannerWidth + gap), y + row * rowHeight, bannerWidth, bannerHeight)
            end
            y = y + math.ceil(#section / across) * rowHeight
            shown = shown + #section
        end
    end
    for index = #List() + 1, #heads do heads[index]:Hide() end
    for index = used + 1, #banners do Hidden(banners[index]) end
    view.none:SetShown(shown == 0)
    sheet:SetSize(width, math.max(1, y))
end

-- The words on the banners again (their quests counted, the set come).
function Instances.Refresh()
    if view and view:IsShown() then Instances.Layout() end
end

-- The quest log came or went, the window's size changed: laid out anew.
function Instances.Refit()
    Instances.Refresh()
end

-- Over the canvas as large as it, as a dungeon's floor is (Dungeons.Build), under the bar; hidden until the bar's button.
function Instances.Build(canvasFrame)
    canvas = canvasFrame
    view = CreateFrame("Frame", nil, canvas:GetParent())
    view:SetAllPoints(canvas)
    view:SetFrameLevel(canvas:GetFrameLevel() + ns.Dungeons.LEVEL)
    view:EnableMouse(true) -- (the map under it takes no clicks)
    Instances.frame = view
    local ground = view:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints()
    local sea = ns.Canvas.GROUND
    ground:SetColorTexture(sea[1], sea[2], sea[3])
    scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate") -- (its bar at its right: Instances.BAR)
    scroll:EnableMouseWheel(true) -- the wheel over the banners scrolls them (the template's script takes it)
    sheet = CreateFrame("Frame", nil, scroll)
    sheet:SetSize(1, 1)
    scroll:SetScrollChild(sheet)
    view.none = view:CreateFontString(nil, "OVERLAY")
    Look.SetFont(view.none, 18, false, Look.FAINT)
    view.none:SetPoint("CENTER")
    view.none:SetText(TEXT.none)
    view:SetScript("OnSizeChanged", ns.Guard(Instances.Refit))
    view:SetScript("OnMouseUp", ns.Guard(function(_, button) if button == "RightButton" then Instances.Close() end end))
    view:Hide()
    -- The set arrived or changed: listed anew.
    SET:OnStamp(ns.Guard(function()
        sections, counts = nil, nil
        Instances.Refresh()
        if view:IsShown() then Count() end
    end))
    return view
end

-- The banners over the full map (a dungeon's floor goes); false while the map is small.
function Instances.Open()
    if not view or ns.Canvas.camera ~= ns.Window.full then return false end
    ns.Dungeons.Close()
    sections = nil -- listed anew: a raid's day may have come (its count stays)
    view:SetFrameLevel(canvas:GetFrameLevel() + ns.Dungeons.LEVEL) -- (the canvas' level follows its window's)
    view:Show()
    Instances.Layout()
    Count()
    ns.Safe("bar", ns.TopBar.Update)
    return true
end

-- The map again.
function Instances.Close()
    if not view or not view:IsShown() then return end
    view:Hide()
    for _, banner in ipairs(banners) do
        if banner.entry then banner.art:SetTexture(nil) end -- the pictures let go while hidden
    end
    ns.Safe("bar", ns.TopBar.Update)
end

-- The bar's button: the banners; the map again while they show; the banners again from a dungeon's floor.
function Instances.Toggle()
    if view and view:IsShown() then return Instances.Close() end
    Instances.Open()
end

function Instances.Shown()
    return view ~= nil and view:IsShown() or false
end
