local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - RareTracker
--  The Sane Rare tracker: a rare, a treasure or an event near you, told the
--  moment the game shows it, with the game's war horn and a notice below the
--  screen's top, left of its middle (the guide's arrow keeps the middle, a new
--  level's notice the right), in the look of what Sane UI tells over the world:
--  outlined words on a faint dark shade whose sides fade out.
--
--      found by     the game's marks near you (its vignettes, those it puts on the minimap: rares, treasures,
--                   events), and a rare creature itself as soon as the game shows it to you (its nameplate,
--                   your target, the mouse on it: UnitClassification rare or rareelite), for the rares the game
--                   gives no mark. Not inside an instance; never a dead one
--      the notice   at its left the rare's own 3D model (the game's model of its creature), for a treasure or an
--                   event the game's icon of its mark; its name in gold, under it what it is (Rare, Rare Elite,
--                   Treasure, Event) and its level, under that how far it is and which way (kept up to date)
--      the mouse    on it: the tooltip of its pin on the map (PinView.lua: a rare's abilities and loot); a click
--                   puts the game's map pin on it, and the golden line leads there (Planner.lua); a right click
--                   sends it away
--      how long     RareTracker.HOLD seconds, and as long as the mouse is on it; then it fades out. At most
--                   RareTracker.MOST at once, the newest at the top; the same thing told again only after
--                   RareTracker.AGAIN seconds
--      settings     Sane Rare tracker (on), what it tells of (rares, treasures, events), its sound
--      /sane testraretracker  a notice as a find brings it, with its sound: the nearest rare of Core's data on
--                   your map, else a made-up one ahead of you; "chest" a treasure's, "event" an event's
--
--      RareTracker.Found(find, test)  tells of a find: { kind, thing, name, map, x, y, level, elite, atlas };
--                                     test: whatever the settings say and whenever it was told last
--      RareTracker.Kind(atlas)        what a mark of the game's is: "rare", "treasure" or "event"
--      RareTracker.Hide()             every notice gone (the module stands down, the switch goes off)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live = ns.Coords, ns.Live
local RareTracker = {}
ns.RareTracker = RareTracker

RareTracker.LEFT = 340   -- left of the screen's middle, as far as a new level's notice stands right of it
RareTracker.WIDTH = 250  -- the shade, without its edges that fade out
RareTracker.EDGE = 60
RareTracker.HEIGHT = 72
RareTracker.GAP = 4      -- between two notices
RareTracker.PICTURE = 60 -- the model's square at the left; a mark's icon in it ICON
RareTracker.ICON = 40
RareTracker.PAD = 6
RareTracker.NAME, RareTracker.LINE = 19, 14 -- the words' sizes
RareTracker.DARK = 0.5   -- the shade
RareTracker.HOLD = 40
RareTracker.FADE_IN, RareTracker.FADE_OUT = 0.25, 1
RareTracker.MOST = 3
RareTracker.AGAIN = 300
RareTracker.LOOK = 0.5   -- seconds between two looks at where it is
RareTracker.REACH = 250  -- yards: a rare seen in person stands at the nearest point of Core's data within this
RareTracker.AHEAD = 80   -- yards: the made-up rare of the test, north-east of you
-- The sounds to choose from: the game's own (its sound kits), heard on the game's master channel. The war horn of a
-- garrison's invasion is the first.
RareTracker.SOUNDS = { horn = 44292, chime = 45142, warning = 8959 }

local FONT = "Interface\\AddOns\\SaneUI\\Fonts\\Expressway.ttf"
local GOLD = { 1, 0.82, 0 }
local SILVER = { 0.8, 0.82, 0.88 } -- a rare's rank, as its silver dragon
local LIGHT = { 0.95, 0.95, 0.95 }
-- The test's made-up rare where Core's data has none on your map: a creature both games have.
local SAMPLE = { thing = "npc:448", name = "Hogger", level = 11, elite = true }

RareTracker.TEXT = {
    rare = Core.Word("RARE", "Rare"),
    elite = Core.Word("ELITE", "Elite"),
    treasure = "Treasure",
    event = "Event",
    level = Core.Word("LEVEL", "Level"),
    near = "Near you",
    away = "%s %s", -- how far, which way
    ways = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" },
    click = "Click: the map pin there. Right click: away.",
    away1 = "Right click: away.",
    chest = "A treasure chest",
    anEvent = "Something going on",
    about = "a notice of the Sane Rare tracker as a find brings it, with its sound (chest, event: theirs)",
}
local TEXT = RareTracker.TEXT

local NPCS = Core.Data.Set("NPCs")
local holder        -- the hidden frame whose OnUpdate keeps the notices (only while one shows): RareTracker.holder
local shown = {}    -- the notices in sight, the newest first (RareTracker.shown, read only)
local spare = {}    -- notices let go, to be used again
local seen = {}     -- [thing] = GetTime() it was last told
local marked = {}   -- [the game's vignette GUID] = true: looked at already
local since = 0     -- seconds since the last look
RareTracker.shown = shown

-------------------------------------------------------------------------------
--  What a find is
-------------------------------------------------------------------------------
-- What a mark of the game's is, by its atlas: its treasures' have Loot in their name, its rares' Kill; the rest are
-- events and the like.
function RareTracker.Kind(atlas)
    atlas = type(atlas) == "string" and atlas:lower() or ""
    if atlas:find("loot", 1, true) or atlas:find("treasure", 1, true) then return "treasure" end
    if atlas:find("kill", 1, true) then return "rare" end
    return "event"
end

-- The creature or object a GUID names, as Core's data keys them ("npc:69", "object:1617").
local function Thing(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" then return "npc:" .. id end
    if kind == "GameObject" then return "object:" .. id end
    return nil
end

local function Creature(thing)
    return tonumber(type(thing) == "string" and thing:match("^npc:(%d+)$") or nil)
end

-- Whether a kind is wanted now: the switch on, the kind ticked, the module running, outside an instance.
local function Wanted(kind)
    local options = ns.options
    if ns.off or not options or options.rareTracker == false then return false end
    local kinds = options.rareKinds
    if type(kinds) == "table" and not kinds[kind] then return false end
    return Core.Ask(rawget(_G, "IsInInstance")) ~= true
end

-- Whether a thing may be told again: never told, or told RareTracker.AGAIN seconds ago.
local function Fresh(thing)
    local last = seen[thing]
    return not last or GetTime() - last >= RareTracker.AGAIN
end

-- The point of Core's data nearest the player where a thing stands on this map, within RareTracker.REACH; nil for none.
local function Nearest(thing, map)
    local data = Core.Data.Map and Core.Data.Map()
    local spawns = data and Core.Ask(data.Spawns, data, thing)
    local points = type(spawns) == "table" and spawns[map]
    local box = Coords.Box(map)
    local here = Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    if type(points) ~= "table" or not box or not here then return nil end
    local px, py = Core.Plain(here.x), Core.Plain(here.y)
    if not (px and py) then return nil end
    local best, bx, by = RareTracker.REACH, nil, nil
    for _, point in ipairs(points) do
        local yards = math.sqrt(((point[1] - px) * box.width) ^ 2 + ((point[2] - py) * box.height) ^ 2)
        if yards <= best then best, bx, by = yards, point[1], point[2] end
    end
    return bx, by
end

-------------------------------------------------------------------------------
--  Where it is, from you
-------------------------------------------------------------------------------
-- How far a find is and which way, in words; nil where that cannot be told (no place, another plane).
local function Where(find)
    if not (find.map and find.x and find.y) then return nil end
    local home, u, v = Coords.PlaneOf(find.map), nil, nil
    if home then u, v = Coords.MapToPlane(find.map, find.x, find.y, home) end
    local plane, pu, pv = Coords.Player()
    if not (u and pu) or plane ~= home then return nil end
    local east, north = u - pu, v - pv
    local yards = math.sqrt(east * east + north * north)
    local turn = math.deg(math.atan2(east, north)) % 360 -- from north, clockwise
    local way = TEXT.ways[math.floor((turn + 22.5) / 45) % 8 + 1]
    return TEXT.away:format(Core.Distance(yards), way)
end

-- What it is, and its level: "Rare Elite, Level 24", "Treasure".
local function What(find)
    local words = find.kind == "rare" and TEXT.rare or TEXT[find.kind] or TEXT.event
    if find.elite then words = words .. " " .. TEXT.elite end
    if find.level and find.level > 0 then words = ("%s, %s %d"):format(words, TEXT.level, find.level) end
    return words
end

-------------------------------------------------------------------------------
--  The notices
-------------------------------------------------------------------------------
-- A part of the dark behind it, left to right: its middle even, its edges fading out into the world.
local function Shade(parent, from, to)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and rawget(_G, "CreateColor") then
        texture:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, from), CreateColor(0, 0, 0, to))
    else
        texture:SetVertexColor(0, 0, 0, (from + to) / 2)
    end
    return texture
end

local function Words(parent, size)
    local words = parent:CreateFontString(nil, "OVERLAY")
    words:SetFont(FONT, size, "OUTLINE")
    words:SetJustifyH("LEFT")
    words:SetWordWrap(false)
    return words
end

local Let -- below

-- The mouse on a notice: its pin's tooltip, as on the map, and what a click does.
local function Entered(notice)
    local pin = notice.pin
    if not pin then return end
    ns.PinView.Tip(notice)
    GameTooltip:AddLine(pin.map and pin.x and TEXT.click or TEXT.away1, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function Left()
    ns.PinView.Untip()
end

local function Clicked(notice, mouse)
    local pin = notice.pin
    if mouse ~= "RightButton" and pin and pin.map and pin.x then ns.PinView.Drop(pin) end
    Let(notice)
end

local function Loaded(model)
    model:SetAlpha(1)
end

local function Make()
    local notice = CreateFrame("Button", nil, UIParent)
    notice:SetFrameStrata("HIGH")
    notice:SetSize(RareTracker.WIDTH, RareTracker.HEIGHT)
    -- In sight while a talk fades the interface out (Lore)
    if notice.SetIgnoreParentAlpha then notice:SetIgnoreParentAlpha(true) end
    notice:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local middle, left, right = Shade(notice, RareTracker.DARK, RareTracker.DARK), Shade(notice, 0, RareTracker.DARK),
        Shade(notice, RareTracker.DARK, 0)
    middle:SetAllPoints(notice)
    left:SetPoint("TOPRIGHT", notice, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", notice, "BOTTOMLEFT", 0, 0)
    left:SetWidth(RareTracker.EDGE)
    right:SetPoint("TOPLEFT", notice, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMLEFT", notice, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(RareTracker.EDGE)
    local made, model = pcall(CreateFrame, "PlayerModel", nil, notice)
    if made and model then
        notice.model = model
        model:SetSize(RareTracker.PICTURE, RareTracker.PICTURE)
        model:SetPoint("LEFT", notice, "LEFT", 0, 0)
        pcall(model.SetScript, model, "OnModelLoaded", ns.Guard(Loaded))
    end
    notice.icon = notice:CreateTexture(nil, "ARTWORK")
    notice.icon:SetSize(RareTracker.ICON, RareTracker.ICON)
    notice.icon:SetPoint("CENTER", notice, "LEFT", RareTracker.PICTURE / 2, 0)
    local at = RareTracker.PICTURE + RareTracker.PAD
    notice.name = Words(notice, RareTracker.NAME)
    notice.name:SetPoint("TOPLEFT", notice, "TOPLEFT", at, -RareTracker.PAD - 2)
    notice.name:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    notice.what = Words(notice, RareTracker.LINE)
    notice.what:SetPoint("TOPLEFT", notice.name, "BOTTOMLEFT", 0, -4)
    notice.what:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.where = Words(notice, RareTracker.LINE)
    notice.where:SetPoint("TOPLEFT", notice.what, "BOTTOMLEFT", 0, -3)
    notice.where:SetPoint("RIGHT", notice, "RIGHT", 0, 0)
    notice.where:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
    notice.fade = Core.Motion.Fade(notice)
    notice:SetScript("OnClick", ns.Guard(Clicked))
    notice:SetScript("OnEnter", ns.Guard(Entered))
    notice:SetScript("OnLeave", ns.Guard(Left))
    notice:Hide()
    return notice
end

-- The notices one under the other, the newest at the top.
local function Stack()
    for index, notice in ipairs(shown) do
        notice:ClearAllPoints()
        notice:SetPoint("TOP", UIParent, "TOP", -RareTracker.LEFT,
            -Core.TOAST_TOP - (index - 1) * (RareTracker.HEIGHT + RareTracker.GAP))
    end
end

-- A notice let go: out of sight, its tooltip with it, free for the next find.
function Let(notice)
    for index, each in ipairs(shown) do
        if each == notice then
            table.remove(shown, index)
            break
        end
    end
    if GameTooltip:GetOwner() == notice then Left() end
    notice:Hide()
    notice.pin, notice.find = nil, nil
    spare[#spare + 1] = notice
    Stack()
    if #shown == 0 and holder then holder:Hide() end
end

-- Every RareTracker.LOOK seconds while one shows: how far each is now, and those whose time is up fade out and go.
local function Look(_, elapsed)
    since = since + (elapsed or 0)
    if since < RareTracker.LOOK then return end
    since = 0
    local now = GetTime()
    for index = #shown, 1, -1 do
        local notice = shown[index]
        if notice.gone and now >= notice.gone then
            Let(notice)
        elseif not notice.gone and now >= notice.ends and not notice:IsMouseOver() then
            notice.gone = now + RareTracker.FADE_OUT
            notice.fade:To(0, RareTracker.FADE_OUT)
        else
            notice.where:SetText(Where(notice.find) or TEXT.near)
        end
    end
end

-- The notice's picture: the rare's own model, else its mark's icon (a rare's skull without a model).
local function Picture(notice, find)
    local npc = find.kind == "rare" and Creature(find.thing)
    local model = notice.model
    if model then
        pcall(model.ClearModel, model)
        model:SetAlpha(0)
        model:Hide()
    end
    notice.icon:SetAtlas(find.atlas or (find.kind == "rare" and ns.Pins.ICONS.rare) or ns.Pins.ICONS.treasure)
    notice.icon:Show()
    if not (npc and model and pcall(model.SetCreature, model, npc)) then return end
    pcall(model.SetPortraitZoom, model, 1)
    notice.icon:Hide()
    model:Show()
    local file = Core.Ask(model.GetModelFileID, model)
    if type(file) == "number" and file > 0 then model:SetAlpha(1) end -- the game had it already
end

local function Sound()
    local kit = RareTracker.SOUNDS[ns.options and ns.options.rareSound or "horn"]
    if kit then Core.Ask(PlaySound, kit, "Master") end
end
RareTracker.Sound = Sound

-- The facts Core's data has of a rare where the game told none: its name, its level, whether it is an elite.
local function Known(find)
    local npc = Creature(find.thing)
    if not npc then return end
    find.name = find.name or NPCS:Get(npc, "name")
    find.level = find.level or tonumber(NPCS:Get(npc, "levelMax") or NPCS:Get(npc, "levelMin"))
    if find.elite == nil then find.elite = NPCS:Get(npc, "rank") == "rareelite" end
end

function RareTracker.Found(find, test)
    if not (find and find.thing and find.kind) then return false end
    if not test and not (Wanted(find.kind) and Fresh(find.thing)) then return false end
    seen[find.thing] = GetTime()
    Known(find)
    for _, each in ipairs(shown) do
        if each.find and each.find.thing == find.thing then Let(each) break end -- told again: the old one goes
    end
    if #shown >= RareTracker.MOST then Let(shown[#shown]) end
    local notice = table.remove(spare) or Make()
    notice.find = find
    -- Its pin, for its tooltip and the map pin: as the map has it (an event a place)
    notice.pin = { kind = find.kind == "event" and "place" or find.kind, key = find.thing, name = find.name or "?",
                   map = find.map, x = find.x, y = find.y, live = true }
    notice.name:SetText(find.name or "?")
    notice.what:SetText(What(find))
    local colour = find.kind == "rare" and SILVER or find.kind == "treasure" and GOLD or LIGHT
    notice.what:SetTextColor(colour[1], colour[2], colour[3])
    notice.where:SetText(Where(find) or TEXT.near)
    Picture(notice, find)
    table.insert(shown, 1, notice)
    Stack()
    notice.ends, notice.gone = GetTime() + RareTracker.FADE_IN + RareTracker.HOLD, nil
    notice:Show()
    notice.fade:To(1, RareTracker.FADE_IN, 0)
    if not holder then
        holder = CreateFrame("Frame", nil, UIParent)
        holder:SetScript("OnUpdate", ns.Guard(Look))
        RareTracker.holder = holder
    end
    holder:Show()
    Sound()
    return true
end

function RareTracker.Hide()
    for index = #shown, 1, -1 do Let(shown[index]) end
end

-------------------------------------------------------------------------------
--  What the game shows
-------------------------------------------------------------------------------
-- One of the game's marks: told when it is on the minimap (near you) and not dead.
local function Vignette(guid)
    local info = Core.Ask(C_VignetteInfo.GetVignetteInfo, guid)
    if type(info) ~= "table" or Core.Plain(info.onMinimap) ~= true or Core.Plain(info.isDead) == true then return end
    marked[guid] = true
    local atlas = Core.Plain(info.atlasName)
    local kind = RareTracker.Kind(atlas)
    local id = Core.Plain(info.vignetteID)
    local thing = Thing(Core.Plain(info.objectGUID)) or ("vignette:" .. tostring(id or guid))
    if not (Wanted(kind) and Fresh(thing)) then return end
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local position = map and Core.Ask(C_VignetteInfo.GetVignettePosition, guid, map)
    local x, y = type(position) == "table" and Core.Plain(position.x), type(position) == "table" and Core.Plain(position.y)
    RareTracker.Found({ kind = kind, thing = thing, name = Core.Plain(info.name), atlas = atlas,
                        elite = type(atlas) == "string" and atlas:find("Elite", 1, true) ~= nil or nil,
                        map = map, x = x or nil, y = y or nil })
end

local function Vignettes()
    local list = Core.Ask(C_VignetteInfo.GetVignettes)
    for _, guid in ipairs(type(list) == "table" and list or {}) do
        if not marked[guid] then Vignette(guid) end
    end
end

-- A creature the game shows you: told when it is a rare, alive and no player's.
local function Unit(unit)
    local rank = Core.Ask(rawget(_G, "UnitClassification"), unit)
    if rank ~= "rare" and rank ~= "rareelite" then return end
    if Core.Ask(UnitExists, unit) ~= true or Core.Ask(UnitIsPlayer, unit) == true or Core.Ask(UnitIsDead, unit) == true then
        return
    end
    local thing = Thing(Core.Ask(UnitGUID, unit))
    if not (thing and Wanted("rare") and Fresh(thing)) then return end
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local x, y
    if map then x, y = Nearest(thing, map) end
    local level = Core.Ask(UnitLevel, unit)
    RareTracker.Found({ kind = "rare", thing = thing, name = Core.Ask(UnitName, unit), elite = rank == "rareelite",
                        level = type(level) == "number" and level > 0 and level or nil, map = map, x = x, y = y })
end

-------------------------------------------------------------------------------
--  The test
-------------------------------------------------------------------------------
-- A point so many yards north-east of the player on their map; nil where the game tells no place.
local function Ahead(map, yards)
    local box = map and Coords.Box(map)
    local here = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local x, y = here and Core.Plain(here.x), here and Core.Plain(here.y)
    if not (box and x and y) then return nil end
    local step = yards / math.sqrt(2)
    return math.min(math.max(x + step / box.width, 0), 1), math.min(math.max(y - step / box.height, 0), 1)
end

-- The nearest thing of Core's data on the map of a kind (a rare, a chest), with its place; nil for none.
local function NearestOf(map, want)
    local data = Core.Data.Map and Core.Data.Map()
    local places = data and map and Core.Ask(data.On, data, map)
    local here = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local px, py = here and Core.Plain(here.x), here and Core.Plain(here.y)
    if type(places) ~= "table" or not (px and py) then return nil end
    local best, found = math.huge, nil
    for _, place in ipairs(places) do
        if want(place) and place.x and place.y then
            local far = (place.x - px) ^ 2 + (place.y - py) ^ 2
            if far < best then best, found = far, place end
        end
    end
    return found
end

function RareTracker.Test(rest)
    rest = type(rest) == "string" and rest:lower() or ""
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    local find
    if rest == "chest" or rest == "treasure" then
        local place = NearestOf(map, function(place) return place.kind == "object" and place.what == "chest" end)
        find = { kind = "treasure", atlas = "VignetteLoot", thing = place and place.key or "object:0",
                 name = place and place.name or TEXT.chest, map = map, x = place and place.x, y = place and place.y }
    elseif rest == "event" then
        find = { kind = "event", atlas = "VignetteEvent", thing = "vignette:test", name = TEXT.anEvent, map = map }
    else
        local place = NearestOf(map, function(place)
            return place.kind == "npc" and type(place.what) == "table" and place.what.rare
        end)
        if place then
            find = { kind = "rare", thing = place.key, name = place.name, map = map, x = place.x, y = place.y }
        else
            find = { kind = "rare", thing = SAMPLE.thing, name = SAMPLE.name, level = SAMPLE.level, elite = SAMPLE.elite,
                     map = map }
        end
    end
    if find.map and not find.x then find.x, find.y = Ahead(find.map, RareTracker.AHEAD) end
    RareTracker.Found(find, true)
end

Core.Command("testraretracker", TEXT.about, function(rest)
    if ns.off then return ns.Print(ns.TEXT.stopped) end
    ns.Guarded(RareTracker.Test, rest)
end)

function RareTracker.Start()
    if rawget(_G, "C_VignetteInfo") then
        ns.On("VIGNETTE_MINIMAP_UPDATED", ns.Guard(function(guid, onMinimap)
            if onMinimap and guid and not marked[guid] then Vignette(guid) end
        end))
        ns.On("VIGNETTES_UPDATED", ns.Guard(Vignettes))
    end
    ns.On("NAME_PLATE_UNIT_ADDED", ns.Guard(Unit))
    ns.On("PLAYER_TARGET_CHANGED", ns.Guard(function() Unit("target") end))
    ns.On("UPDATE_MOUSEOVER_UNIT", ns.Guard(function() Unit("mouseover") end))
    -- A new place (a loading screen): the marks there looked at anew
    ns.On("PLAYER_ENTERING_WORLD", ns.Guard(function() wipe(marked) end))
end
