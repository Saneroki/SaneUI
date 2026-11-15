local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Dungeons
--  The maps of the dungeons and raids, chosen in the full map's bar (TopBar.lua)
--  and shown over the map in its place: a dungeon's map is drawn by the game for
--  that dungeon alone, not where it lies in the world, so it has a view of its
--  own here.
--
--      the list     every map the game has of the kind Dungeon (C_Map.GetMapChildrenInfo), one per
--                   dungeon: the floors of one (its map group) are one entry, by the name of its
--                   lowest floor; and those of Core's set Dungeons the game has no map of (Forever's
--                   client has none: their floors are the set's, keyed "<instance>:<floor>"), A to Z
--      a floor      the game's floors of the dungeon (C_Map.GetMapGroupMembersInfo) or the set's,
--                   chosen in the bar's dropdown beside it; the first shown is its lowest
--      the art      the game's own map art of the floor (Art.Of; the set's: its tiles, the game's
--                   files), fitted into the view whole: on the full map into the room its bar and the
--                   quest log leave free (under the bar, beside the log where it stands over the view's
--                   left or right), so the whole floor is always in sight at the farthest zoom (Saneroki,
--                   2026-11-11)
--      the ground   the instance as it truly lies, under the art (Saneroki, 2026-11-15: "I want the terrain /
--                   Partchment toggle work for instance maps as well. We should have both."): the game's own minimap
--                   textures of its terrain and of its buildings' parts on that floor, each drawn by its file ID where
--                   Core's set DungeonGround lays it in the world (its middle, size and turn), inside the floor's box
--                   of the set Dungeons; the terrain cut at the floor's edges. As the map's view says (ns.View, the
--                   bar's view button): Parchment the art alone, Scrying the ground alone, Blended the art over the
--                   ground, whole at the whole floor and gone at Dungeons.BLEND[2] times nearer (the world map's
--                   curve, Canvas.Blend). A floor without ground keeps its art in every view (Retail's, until its
--                   data comes)
--      small map    inside a dungeon the small view is the game's own minimap (Canvas.lua); one notch of
--                   the wheel out past its widest step shows the dungeon's whole map there instead, its
--                   bosses and enemies at Dungeons.SMALL of their size; a notch in, a right or a middle
--                   click: the game's minimap again at its widest step. Kept through the full screen and
--                   back and into the next dungeon until then (Dungeons.Whole, Dungeons.Small)
--      the bosses   where Core's set Dungeons has them: the game's boss mark at each one's place and the
--                   boss's own 3D model standing on it (the game's model of its display), the same size at
--                   every zoom; a model that would reach past the view's edge is hidden (the engine does not
--                   cut it there), its mark stays. The tooltip, as a creature's (Core.TipLook: its model, the
--                   boss's dragon, ?? for its level): its name, the dungeon, Boss; then the sections Abilities
--                   and Loot (the set Bosses: the game's spell and item IDs, kept apart from the game's own
--                   encounters until the game confirms them), each with its icon and name as the game has them,
--                   an item in its quality's colour; and that it is not yet confirmed by the game. With Alt
--                   held, each ability's description and each item's details under its name: Uncollected, its
--                   effects (Use:, Equip:), then its stats.
--                   The mark shows only where no model stands (no look, or at the view's edge)
--      enemies      where the set has them, each enemy as a small red dot where it stands (under the bosses),
--                   its name in the tooltip
--      the mouse    on the full map the wheel zooms around the mouse (from the whole map up to
--                   Dungeons.NEAR times nearer), a drag moves it, a right click goes back to the map it
--                   was opened from (the map stays under the dungeon's view, as it was)
--      also         a pin that leads into a dungeon (Shift and a click on its entrance) opens its map here
--                   (Canvas.Show)
--      no player    Forever tells no place of the player inside an instance, nor of the party or raid
--                   (Saneroki, 2026-10-21): an instance's map has no arrow and no group, and no floor is
--                   chosen by where the player stands. What stands still there is drawn: the bosses (and
--                   the enemies, once Core's data has their places)
--
--  An instance's map keeps rules of its own, apart from the world map's and its indoor maps' (Indoors.lua).
--  Opening the full map inside a dungeon shows its map at once (Window.lua): the game tells which instance.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Dungeons = {}
ns.Dungeons = Dungeons

Dungeons.NEAR = 4   -- the nearest zoom: so many times the whole map's
Dungeons.LEVEL = 22 -- over the canvas' layers and marks (Canvas.LEVELS: up to 21), under the bar (TopBar: 30)
Dungeons.SPREAD = 3 -- the models' levels over their marks, by how far down each stands: all of them under the bar
Dungeons.BOSS = "vignettekillboss" -- a boss's mark: the game's own
Dungeons.BOSS_SIZE = 26
Dungeons.MODEL_WIDTH, Dungeons.MODEL_HEIGHT = 72, 88 -- a boss's model standing on its mark, in screen units, at
                                                     -- the whole map's zoom; it grows with the zoom (Saneroki, 2026-11-15:
                                                     -- "so you can see a bigger model by zooming the map")
Dungeons.MODEL_MOST = 0.6 -- a model at most so much of the view's height
Dungeons.FACING = 0.35 -- radians: the models turned a little from facing the view, so they read as figures
Dungeons.SMALL = 0.5 -- the small map's bosses' marks and models and enemies' dots: so much of their size
Dungeons.SIDE = 1 / 3 -- the quest log beside a floor on the full map takes at most so much of the view's width
Dungeons.BLEND = { 1, 2.5 } -- Blended: the art whole over the ground at this zoom (the whole floor) and farther, gone
                            -- at this zoom and nearer
Dungeons.TERRAIN, Dungeons.PARTS = "BACKGROUND", "BORDER" -- the ground's draw layers: its terrain, its buildings over it
                                                          -- (the art: ARTWORK)
Dungeons.TEXT = {
    dungeons = Core.Word("DUNGEONS", "Dungeons"),
    floor = "Floor",
    unverified = Core.UNCONFIRMED, -- (Core.Unconfirmed)
    enemy = "An enemy",
    boss = Core.Word("BOSS", "Boss"),
    abilities = Core.Word("ABILITIES", "Abilities"),
    loot = Core.Word("LOOT", "Loot"),
    more = "and %d more",
}
Dungeons.LINES = 10 -- abilities, and items, a boss's tooltip lists at most
Dungeons.ENEMY = "Interface\\COMMON\\Indicator-Red" -- an enemy's mark: the game's small red dot
Dungeons.ENEMY_SIZE = 10
Dungeons.ICON = 16  -- their icons' size in it
Dungeons.TEXT.uncollected = "Uncollected"

-- A sentence of the game with gaps ("%s Armor") as a pattern that finds it in a line; english where it has none.
local function Sentence(name, english)
    local words = rawget(_G, name)
    words = type(words) == "string" and words or english
    words = words:gsub("%%%d?%$?[%d%.]*[sdfg]", "\1"):gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%0")
    return "^" .. words:gsub("\1", ".-") .. "$"
end

-- The lines of an item's tooltip a boss's tooltip keeps with Alt held: its damage, its speed and damage per second,
-- its armour and block, its stats ("+5 Stamina") and its effects (Equip, Use, Chance on hit). Nothing else: no
-- price, slot, binding, requirements, durability, set, lore.
Dungeons.KEEP = {
    Sentence("DAMAGE_TEMPLATE", "%s - %s Damage"), Sentence("SINGLE_DAMAGE_TEMPLATE", "%s Damage"),
    Sentence("PLUS_DAMAGE_TEMPLATE", "+ %s - %s %s Damage"), Sentence("DPS_TEMPLATE", "(%s damage per second)"),
    Sentence("ARMOR_TEMPLATE", "%s Armor"), Sentence("SHIELD_BLOCK_TEMPLATE", "%s Block"),
    "^[%+%-]%s?%d",
}
Dungeons.EFFECTS = { "ITEM_SPELL_TRIGGER_ONEQUIP", "ITEM_SPELL_TRIGGER_ONUSE", "ITEM_SPELL_TRIGGER_ONPROC" }

local KINDS = rawget(_G, "Enum") and Enum.UIMapType or {}
local DUNGEON = KINDS.Dungeon or 4

local SET = Core.Data.Set("Dungeons")
local ENCOUNTERS = Core.Data.Set("Encounters")
local NPCS = Core.Data.Set("NPCs")
local BOSSES = Core.Data.Set("Bosses")
local ITEMS = Core.Data.Set("Items")
local GROUND = Core.Data.Set("DungeonGround")

local frame, content, over, canvas
local tiles = {}  -- the art's textures, made as many as needed
local grounds = {} -- the ground's textures, likewise
local laid        -- the ground of the floor shown is laid (its textures given their files): once a view first shows it
local share       -- how much of the art shows over the ground now (Shade)
local marks = {}  -- the bosses' marks, made as many as needed
local foes = {}   -- the enemies' marks, likewise
local fromData    -- the dungeons of the set, once walked (Walk); nil until then
local told        -- the game has told of a dungeon's map: the list is kept; else the game is asked again
local walking     -- the walk's job while it runs
local list        -- the dungeons, asked of the game once: { map = its first floor, name, floors = { { map, name } } }
local shown       -- the floor shown, nil while the map is
local floors      -- the floors of the dungeon shown (one at least)
local kept        -- what the floor shown is drawn from, gathered once (Gather): its art, bosses, enemies and instance
local NONE = {}
local zoom, panX, panY = 1, 0, 0 -- the zoom (1: whole), the art's middle from the room's, in screen units
local dragX, dragY -- where the cursor was at the last step of a drag
local onSmall = false -- the view stands on the small map (Dungeons.Small), not the full one
local wanted = false  -- the small map was wheeled out to a dungeon's whole map: kept until wheeled in (Dungeons.Out)
-- The room a floor is fitted into whole (Room): its size, its middle from the view's; the art's middle (Place).
local roomWidth, roomHeight, roomX, roomY = 1, 1, 0, 0
local midX, midY = 0, 0

-- The floors of a map's dungeon: the members of its map group, lowest first; only itself without a group.
local function Floors(map)
    local group = Core.Plain(Core.Ask(C_Map.GetMapGroupID, map))
    local members = group and Core.Ask(C_Map.GetMapGroupMembersInfo, group)
    local found = {}
    if type(members) == "table" then
        table.sort(members, function(a, b) return (a.relativeHeightIndex or 0) < (b.relativeHeightIndex or 0) end)
        for _, member in ipairs(members) do
            if member.mapID then found[#found + 1] = { map = member.mapID, name = member.name } end
        end
    end
    if #found == 0 then found[1] = { map = map } end
    return found
end

local function Name(map)
    local info = Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info.name or nil
end

-- A dungeon of the set as an entry of the list: its floors in their order, each keyed "<instance>:<floor>".
local function DataEntry(key, record)
    local floors = {}
    for _, floor in ipairs(type(record.floors) == "table" and record.floors or {}) do
        if floor.floor and floor.width and floor.height and floor.tile then
            floors[#floors + 1] = { map = key .. ":" .. floor.floor, name = floor.name, instance = key, data = floor }
        end
    end
    if #floors == 0 or not record.name then return nil end
    table.sort(floors, function(a, b) return a.data.floor < b.data.floor end)
    floors.name = record.name
    return { map = floors[1].map, name = record.name, floors = floors, instance = key }
end

-- The set walked once it is there (the scheduler's job): its dungeons kept, the list made again with them.
local function Walk()
    if fromData or walking then return end
    local found = {}
    walking = SET:Each(function(key, record)
        found[#found + 1] = DataEntry(key, record)
    end, function()
        walking, fromData, list = nil, found, nil
        ns.Safe("bar", ns.TopBar.Update)
    end)
    if walking == false then walking = nil end -- not there yet: its pack asked for, walked when it arrives
end

-- Every dungeon and raid the game has a map of, one entry each, and those of the set the game has none of, A to
-- Z; kept once the game told of one or the set was read (Forever's client has none of its own), asked again while
-- neither has.
function Dungeons.List()
    Walk()
    if list and (told or fromData) then return list end
    list = {}
    local root = ns.Coords.Top() -- (Retail's: also Outland's, Draenor's and the Shadowlands')
    local children = root and Core.Ask(C_Map.GetMapChildrenInfo, root, DUNGEON, true)
    local seen = {}
    for _, info in ipairs(type(children) == "table" and children or {}) do
        local map = info.mapID
        if map and info.mapType == DUNGEON and not seen[map] then
            local each = Floors(map)
            for _, floor in ipairs(each) do seen[floor.map] = true end
            local name = Name(each[1].map) or info.name
            if name and name ~= "" then
                each.name = name
                list[#list + 1] = { map = each[1].map, name = name, floors = each }
                told = true
            end
        end
    end
    -- The set's, but where the game has a map of the same name ("The Deadmines" for "Deadmines" too).
    local named = {}
    for _, entry in ipairs(list) do named[entry.name] = true end
    for _, entry in ipairs(fromData or {}) do
        if not named[entry.name] and not named["The " .. entry.name] then list[#list + 1] = entry end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- The dungeon of a map: its entry in the list, if it is one's floor (a map of the game, or "<instance>:<floor>"
-- of the set's), and that floor.
local function Entry(map)
    for _, entry in ipairs(Dungeons.List()) do
        for _, floor in ipairs(entry.floors) do
            if floor.map == map then return entry, floor end
        end
    end
    return nil
end

-- The instance the player is in: its map ID, the game's GetInstanceInfo's eighth answer (Core.Ask gives three).
local function Instance()
    local info = rawget(_G, "GetInstanceInfo")
    if type(info) ~= "function" then return nil end
    local ok, _, _, _, _, _, _, _, instance = pcall(info)
    instance = ok and Core.Plain(instance) or nil
    return type(instance) == "number" and instance or nil
end

-- The map of the dungeon the player is in: the game's map of it, or the set's dungeon of the instance the game
-- names, at its lowest floor (the game tells no place inside, so no floor by it); nil outside.
function Dungeons.Here()
    local map = Core.Plain(Core.Ask(C_Map.GetBestMapForUnit, "player"))
    if map and Entry(map) then return map end
    local entry = Entry(Dungeons.Key(Instance()))
    return entry and entry.floors[1].map or nil
end

-- The set's dungeon of an instance (its map ID, as the entrances name it): the key of its lowest floor, which
-- Dungeons.Show and Canvas.Show take; nil where the set has none (or is not there yet).
function Dungeons.Key(instance)
    if not instance then return nil end
    local lowest
    for _, floor in ipairs(SET:Get(instance, "floors") or {}) do
        if floor.floor and (not lowest or floor.floor < lowest) then lowest = floor.floor end
    end
    return lowest and (instance .. ":" .. lowest) or nil
end

-- A floor's art: the game's (Art.Of), or the set's tiles laid out as the game's art is.
local function ArtOf(map)
    local _, floor = Entry(map)
    if not floor or not floor.data then return ns.Art.Of(map) end
    if floor.art ~= nil then return floor.art end
    local data = floor.data
    local across, down = math.ceil(data.width / data.tile), math.ceil(data.height / data.tile)
    local files = {}
    for _, tile in ipairs(SET:Get(floor.instance, "tiles") or {}) do
        if tile.floor == data.floor and tile.row < down and tile.column < across then
            files[tile.row * across + tile.column + 1] = tile.file
        end
    end
    floor.art = next(files) and { across = across, down = down, width = data.width, height = data.height,
                                  tileWidth = data.tile, tileHeight = data.tile, files = files } or false
    return floor.art
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
-- The room of the view a floor is fitted into whole: on the full map all of it but its bar's row at the top
-- (TopBar.lua) and the quest log's side where the log stands over the view (its left or right, at most
-- Dungeons.SIDE of its width, with the bar's gap); the small map all of it. Measured as the view opens, when its size
-- changes and when the log comes or goes (Dungeons.Refit), not at each step of a drag.
local function Room()
    local width, height = frame:GetSize()
    width, height = width or 0, height or 0
    local top, left, right = 0, 0, 0
    if not onSmall then
        local bar = ns.TopBar
        top = bar.Top() + bar.INSET -- (the title bar stands over the map)
        local logLeft, logRight = ns.QuestLog.Box()
        local viewLeft, _, viewWidth = frame:GetRect()
        if logLeft and viewLeft and viewWidth then
            local scale = frame:GetEffectiveScale()
            logLeft, logRight = logLeft / scale - viewLeft, logRight / scale - viewLeft
            if logRight > 0 and logLeft < viewWidth then -- over the view: the side its middle is on
                if logLeft + logRight < viewWidth then left = logRight + bar.INSET
                else right = viewWidth - logLeft + bar.INSET end
            end
        end
        left, right = math.min(left, width * Dungeons.SIDE), math.min(right, width * Dungeons.SIDE)
    end
    roomWidth, roomHeight = width - left - right, height - top
    roomX, roomY = (left - right) / 2, -top / 2
end

-- The art's size on the screen at zoom 1: the whole map in the room, as large as fits.
local function Fit(art)
    if roomWidth <= 0 or roomHeight <= 0 then return 1 end
    return math.min(roomWidth / art.width, roomHeight / art.height)
end

-- How much of the art shows over the floor's ground (0 to 1), as the map's view says (ns.View): Parchment all of it,
-- Scrying none, Blended by the zoom (whole at Dungeons.BLEND[1] and farther, gone at BLEND[2] and nearer); all of it
-- where the floor has no ground.
function Dungeons.Share()
    if not (kept and kept.ground) then return 1 end
    local view = ns.View()
    if view == "terrain" then return 0 end
    if view ~= "blend" then return 1 end
    return ns.Canvas.Blend(1 / zoom, 1 / Dungeons.BLEND[1], 1 / Dungeons.BLEND[2])
end

-- A texture of the ground, made when first needed; placed to a fraction of a unit, so neighbours meet.
local function GroundTexture(index)
    local texture = grounds[index]
    if not texture then
        texture = content:CreateTexture(nil, Dungeons.TERRAIN)
        if texture.SetSnapToPixelGrid then
            texture:SetSnapToPixelGrid(false)
            texture:SetTexelSnappingBias(0)
        end
        grounds[index] = texture
    end
    return texture
end

-- The floor's ground laid into the art's frame (its units: the art's size across the floor's box), each row of the
-- set by its file where the set lays it: its middle and size, turned as a whole about its middle (yaw 90: north up).
-- The terrain under the buildings, cut at the floor's edges (it reaches past them); the buildings' parts in the set's
-- order (lowest first) over the sublevels of their draw layer. The textures past the ground's let go.
local function LayGround()
    local ground, art = kept and kept.ground, kept and kept.art
    local count = 0
    if ground and art then
        local north, south, west, east = ground.box[1], ground.box[2], ground.box[3], ground.box[4]
        local kx, ky = art.width / (west - east), art.height / (north - south)
        local k = math.sqrt(math.abs(kx * ky)) -- the same both ways: a floor's box has its art's proportions
        local parts, part = 0, 0
        for _, row in ipairs(ground.rows) do
            if not row.terrain then parts = parts + 1 end
        end
        for _, row in ipairs(ground.rows) do
            local x, y = (west - row.y) * kx, (north - row.x) * ky -- its middle, from the art's top left
            local width, height = row.width * k, row.height * k
            if row.terrain then
                local left, top = x - width / 2, y - height / 2
                local l, r = math.max(0, left), math.min(art.width, left + width)
                local t, b = math.max(0, top), math.min(art.height, top + height)
                if l < r and t < b and width > 0 and height > 0 then
                    count = count + 1
                    local texture = GroundTexture(count)
                    texture:SetDrawLayer(Dungeons.TERRAIN, 0)
                    texture:SetTexture(row.file, "CLAMP", "CLAMP", "TRILINEAR")
                    texture:SetTexCoord((l - left) / width, (r - left) / width, (t - top) / height, (b - top) / height)
                    texture:SetRotation(0)
                    texture:ClearAllPoints()
                    texture:SetPoint("TOPLEFT", content, "TOPLEFT", l, -t)
                    texture:SetSize(r - l, b - t)
                end
            else
                part, count = part + 1, count + 1
                local texture = GroundTexture(count)
                texture:SetDrawLayer(Dungeons.PARTS, math.min(7, -8 + math.floor((part - 1) * 16 / parts)))
                texture:SetTexture(row.file, "CLAMP", "CLAMP", "TRILINEAR")
                texture:SetTexCoord(0, 1, 0, 1)
                texture:SetRotation(math.rad((row.yaw or 90) - 90))
                texture:ClearAllPoints()
                texture:SetPoint("CENTER", content, "TOPLEFT", x, -y)
                texture:SetSize(width, height)
            end
        end
    end
    for index = count + 1, #grounds do
        grounds[index]:Hide()
        grounds[index]:SetTexture(nil)
    end
    laid = count
end

-- The art over the ground as much as the view wants it now (Dungeons.Share): the art's tiles so seen, the ground
-- shown while any of it shows through (laid the first time). Only when that changed, not at every step of a drag.
local function Shade()
    local now = Dungeons.Share()
    if now == share then return end
    share = now
    for _, texture in ipairs(tiles) do texture:SetAlpha(now) end
    if now < 1 and not laid then LayGround() end
    for index = 1, laid or 0 do grounds[index]:SetShown(now < 1) end
end

-- The map's view changed (the bar's view button, the settings): the floor shown drawn so.
function Dungeons.Restyle()
    if shown then Shade() end
end

-- The art where the zoom and the drag put it; never so far that it leaves the room's middle. Every frame of a drag:
-- what it places was gathered once (kept), it only moves it.
local function Place()
    local art = kept and kept.art
    if not art then return end
    Shade()
    local scale = Fit(art) * zoom
    local halfX, halfY = art.width * scale / 2, art.height * scale / 2
    panX, panY = math.max(-halfX, math.min(halfX, panX)), math.max(-halfY, math.min(halfY, panY))
    midX, midY = roomX + panX, roomY + panY
    content:SetScale(scale)
    content:ClearAllPoints()
    content:SetPoint("CENTER", frame, "CENTER", midX / scale, midY / scale)
    Dungeons.PlaceEnemies(art, scale)
    Dungeons.PlaceBosses(art, scale)
    ns.Safe("drawings", ns.Draw.Floor, frame, shown, art, scale, midX, midY, onSmall) -- your drawings and markers
end

-- The room measured anew and the floor placed in it (the view's size changed, the quest log came or went).
function Dungeons.Refit()
    if not shown then return end
    Room()
    Place()
end

-- The floor's art: its tiles row by row, the last ones cut at the art's edge (as Art.lua lays a map's); its ground
-- laid again once a view shows it (Shade, from Place).
local function Draw()
    for _, texture in ipairs(tiles) do texture:Hide() end
    for index = 1, laid or 0 do grounds[index]:Hide() end
    laid, share = nil, nil
    local art = kept and kept.art
    if not art then return end
    content:SetSize(art.width, art.height)
    local index = 0
    for row = 1, art.down do
        for column = 1, art.across do
            local file = art.files[(row - 1) * art.across + column]
            if file then
                index = index + 1
                local texture = tiles[index]
                if not texture then
                    texture = content:CreateTexture(nil, "ARTWORK")
                    tiles[index] = texture
                end
                local x, y = (column - 1) * art.tileWidth, (row - 1) * art.tileHeight
                local partX = math.min(1, (art.width - x) / art.tileWidth)
                local partY = math.min(1, (art.height - y) / art.tileHeight)
                texture:SetTexture(file)
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
                texture:SetSize(art.tileWidth * partX, art.tileHeight * partY)
                texture:SetTexCoord(0, partX, 0, partY)
                texture:Show()
            end
        end
    end
    Place()
end

local function Cursor()
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    return x / scale, y / scale
end

-- A drag's step: the art follows the cursor. Only while a drag goes on (Down, Up).
local function Update()
    if not dragX then return end
    local x, y = Cursor()
    panX, panY = panX + x - dragX, panY + y - dragY
    dragX, dragY = x, y
    Place()
end
local updating = ns.Guard(Update) -- made once: set at every drag

-- The wheel: nearer or farther around the point under the mouse, which stays where it is. On the small map the whole
-- map alone: a notch in is the game's minimap again (Out).
local function Wheel(_, delta)
    local art = kept and kept.art
    if not art then return end
    if onSmall then
        if delta > 0 then Dungeons.Out() end
        return
    end
    local was = zoom
    zoom = math.max(1, math.min(Dungeons.NEAR, zoom * ns.Camera.STEP ^ delta))
    if zoom == was then return end
    local x, y = Cursor()
    local left, bottom, width, height = frame:GetRect()
    if not left then return end
    local mouseX, mouseY = x - left - width / 2 - roomX, y - bottom - height / 2 - roomY
    local factor = zoom / was
    panX, panY = mouseX - (mouseX - panX) * factor, mouseY - (mouseY - panY) * factor
    Place()
end

-- The floor's point under the mouse: its map and the point on its art (0 to 1; past its edge beyond); nil while
-- none shows.
function Dungeons.Point()
    local art = kept and kept.art
    if not art or not shown then return nil end
    local x, y = Cursor()
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    local width, height = frame:GetSize()
    if not (left and bottom and width and height) then return nil end
    local scale = Fit(art) * zoom
    local px, py = x - left - width / 2, y - bottom - height / 2
    return shown, (px - midX) / (art.width * scale) + 0.5, 0.5 - (py - midY) / (art.height * scale)
end

-- A press: the left button drags the floor; while a tool of the palette is on (Draw.lua) the left button is the
-- tool's and the right one drags. Alt and a click puts a marker there (Markers.lua), as on the map.
local pressX, pressY, panning
local function Down(_, button)
    if onSmall then return end -- the small map's whole map is not dragged
    local tool = ns.Draw.Tool()
    if tool and button == "LeftButton" and not ns.Markers.Moving() then return ns.Draw.PressFloor() end
    if button ~= (tool and "RightButton" or "LeftButton") then return end
    dragX, dragY = Cursor()
    pressX, pressY, panning = dragX, dragY, button
    frame:SetScript("OnUpdate", updating)
end

local function Up(_, button)
    if button == "LeftButton" and ns.Draw.Busy() then return ns.Draw.Release() end
    local moved = false
    if button == panning then
        local x, y = Cursor()
        moved = pressX ~= nil and math.abs(x - pressX) + math.abs(y - pressY) > 4
        dragX, dragY, panning = nil, nil, nil
        frame:SetScript("OnUpdate", nil)
    end
    if button == "LeftButton" and not moved and not onSmall and (IsAltKeyDown() or ns.Markers.Moving()) then
        local map, x, y = Dungeons.Point()
        if not map or x < 0 or x > 1 or y < 0 or y > 1 then return end
        if ns.Markers.Moving() then return ns.Markers.Put({ map = map, x = x, y = y }) end
        return ns.Markers.New({ map = map, x = x, y = y })
    end
    if (button == "RightButton" and not moved) or (button == "MiddleButton" and onSmall) then
        if ns.Markers.Moving() then return ns.Markers.Stay() end
        Dungeons.Out()
    end
end

-- The small window's grip while the mouse is over its whole map, as over the map itself (Window.Hovered).
local function Entered()
    if onSmall then ns.Window.Hovered(true) end
end
local function Left()
    if onSmall then ns.Window.Hovered(false) end
end

-------------------------------------------------------------------------------
--  The bosses
-------------------------------------------------------------------------------
local tipped -- the mark or model whose tooltip shows, to draw it again once the game has loaded its items

-- An icon before words, in a tooltip's line.
local function Iconed(icon, words)
    if not icon then return words end
    return ("|T%s:%d:%d:0:0:64:64:5:59:5:59|t %s"):format(tostring(icon), Dungeons.ICON, Dungeons.ICON, words)
end

-- A tooltip nobody sees, that the game fills with an item's own lines (its stats, as on the item's tooltip), to be
-- read into the boss's; named, as the game's tooltip template names its lines by the frame's name.
local reader
local function Read(id)
    reader = reader or CreateFrame("GameTooltip", "SaneUINavigationReader", nil, "GameTooltipTemplate")
    reader:SetOwner(UIParent, "ANCHOR_NONE")
    reader:ClearLines()
    if not pcall(reader.SetItemByID, reader, id) then return 0 end
    return reader:NumLines() or 0
end

-- Whether a line of an item's tooltip is one of its effects (Use:, Equip:, Chance on hit:).
local function Effect(words)
    for _, name in ipairs(Dungeons.EFFECTS) do
        local start = rawget(_G, name)
        if type(start) == "string" and words:sub(1, #start) == start then return true end
    end
    return false
end

-- A line of an item's tooltip the boss's keeps (Dungeons.KEEP, or one of the game's effects).
local function Kept(words)
    for _, pattern in ipairs(Dungeons.KEEP) do
        if words:find(pattern) then return true end
    end
    return Effect(words)
end

-- Whether the player lacks the item's appearance (the game's collection; nil where it cannot tell).
local function Uncollected(id)
    local looks = rawget(_G, "C_TransmogCollection")
    if type(looks) ~= "table" then return nil end
    local _, source = Core.Ask(looks.GetItemInfo, id)
    local info = source and Core.Ask(looks.GetAppearanceInfoBySource, source)
    if type(info) ~= "table" or info.appearanceIsCollected == nil then return nil end
    return not info.appearanceIsCollected
end

-- With Alt held, an item's lines under its name, in their colours: "Uncollected" first while the player lacks its
-- appearance, then its effects (a recipe's Use: what it teaches), last its stats, damage and armour (Kept).
local effects, stats = {}, {} -- the lines of each kind, for one item: { words, r, g, b, other, r2, g2, b2 }
local function Shown(list)
    for _, line in ipairs(list) do
        if line[5] and line[5] ~= "" then
            GameTooltip:AddDoubleLine("    " .. line[1], line[5], line[2], line[3], line[4], line[6], line[7], line[8])
        else
            GameTooltip:AddLine("    " .. line[1], line[2], line[3], line[4], true)
        end
    end
end
-- An item's stats as Core's data has them, where the game's tooltip shows none (an item the game keeps hidden: its
-- stats learned in play, here or by the guild or the group): its damage and speed, armour, and each stat.
local STAT_WHITE = { 1, 1, 1 }
local function Recorded(id)
    local known = ITEMS:Ready() and ITEMS:Get(id)
    if not known then return end
    local white = STAT_WHITE
    if known.damageMin and known.damageMax then
        local words = (rawget(_G, "DAMAGE_TEMPLATE") or "%s - %s Damage"):format(known.damageMin, known.damageMax)
        local speed = known.speed and ("%s %.2f"):format(rawget(_G, "SPEED") or "Speed", known.speed) or nil
        stats[#stats + 1] = { words, white[1], white[2], white[3], speed, white[1], white[2], white[3] }
    end
    if known.armor then
        stats[#stats + 1] = { Core.StatLine((rawget(_G, "ARMOR_TEMPLATE") or "%s Armor"):format(known.armor)), white[1], white[2], white[3] }
    end
    if type(known.stats) == "table" then
        local keys = {}
        for key in pairs(known.stats) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local value, word = known.stats[key], rawget(_G, key)
            word = type(word) == "string" and Core.StatWord(word) or key
            stats[#stats + 1] = { ("%s%d %s"):format(value >= 0 and "+" or "", value, word), white[1], white[2], white[3] }
        end
    end
end

local function ItemDetails(id)
    local missing = Uncollected(id)
    local unknown = rawget(_G, "TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN")
    wipe(effects)
    wipe(stats)
    for index = 2, Read(id) do
        local left, right = _G["SaneUINavigationReaderTextLeft" .. index], _G["SaneUINavigationReaderTextRight" .. index]
        local words, other = left and left:GetText(), right and right:IsShown() and right:GetText()
        if words and words == unknown and missing == nil then
            missing = true -- the game's tooltip says so where its collection could not be asked
        elseif words and words ~= "" and Kept(words) then
            local r, g, b = left:GetTextColor()
            local r2, g2, b2
            if other then r2, g2, b2 = right:GetTextColor() end
            local list = Effect(words) and effects or stats
            list[#list + 1] = { words, r, g, b, other, r2, g2, b2 }
        end
    end
    if missing then
        local colour = rawget(_G, "TRANSMOGRIFY_FONT_COLOR")
        local r, g, b = 0.5, 0.5, 1
        if type(colour) == "table" then r, g, b = colour.r or r, colour.g or g, colour.b or b end
        GameTooltip:AddLine("    " .. Dungeons.TEXT.uncollected, r, g, b)
    end
    if #stats == 0 then Recorded(id) end
    Shown(effects)
    Shown(stats)
end

-- With Alt held, a spell's description under its name; asked of the game while it has not loaded it.
local function SpellDetails(id)
    local words = Core.Ask(C_Spell.GetSpellDescription, id)
    if type(words) ~= "string" or words == "" then
        Core.Ask(C_Spell.RequestLoadSpellData, id)
        return
    end
    GameTooltip:AddLine("    " .. words, 1, 0.82, 0, true)
end

-- A spell's line: its icon and name as the game has them; nil where the game does not know it.
-- mark: what goes before the name (Core.UNCONFIRMED_MARK for one not yet confirmed), after the icon.
local function SpellLine(id, mark)
    local info = Core.Ask(C_Spell.GetSpellInfo, id)
    if type(info) ~= "table" or not info.name then return nil end
    return Iconed(info.iconID, (mark or "") .. info.name)
end

-- An item's line, its words and colour: its icon and its name in its quality's colour; asked of the game while it
-- has not loaded it (nil meanwhile: the tooltip is drawn again once it has).
local function ItemLine(id, mark)
    local name, _, quality = Core.Ask(C_Item.GetItemInfo, id)
    if not name then
        Core.Ask(C_Item.RequestLoadItemDataByID, id)
        -- Meanwhile, and for an item the game keeps hidden, as Core's data has it (learned in play, shared)
        local known = ITEMS:Ready() and ITEMS:Get(id)
        if not (known and known.name) then return nil end
        name, quality = known.name, known.quality
        local r, g, b = 1, 1, 1
        local colour = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[quality]
        if type(colour) == "table" then r, g, b = colour.r or r, colour.g or g, colour.b or b end
        return Iconed(known.icon, (mark or "") .. name), r, g, b
    end
    local r, g, b = 1, 1, 1
    local colour = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[quality]
    if type(colour) == "table" then r, g, b = colour.r or r, colour.g or g, colour.b or b end
    return Iconed(Core.Ask(C_Item.GetItemIconByID, id), (mark or "") .. name), r, g, b
end
Dungeons.ItemLine = ItemLine
-- A rare's tooltip on the map is drawn as a boss's (PinView.lua): its abilities' and items' lines and details.
Dungeons.SpellLine, Dungeons.SpellDetails, Dungeons.ItemDetails = SpellLine, SpellDetails, ItemDetails

-- How often an item came from a boss of that name, in words (Core's Drops: the set Encounters names no creature, so its
-- name finds it among those that gave the item); nil where nobody counted it.
local function Rate(name, id)
    local drops = Core.Data.Drops()
    for _, entry in ipairs(drops:From(id)) do
        if entry.key:find("^npc:") and drops:Name(entry.key) == name then return ns.PinView.Often(entry) end
    end
    return nil
end

-- A boss's abilities or items (kind "a" or "l"): the set's, then those confirmed in play that it does not name (Core's
-- Data.ConfirmedParts: seen cast, looted from the boss).
local function Parts(encounter, field, kind)
    local list, seen = {}, {}
    for _, id in ipairs(BOSSES:Get(encounter, field) or {}) do
        if not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    local confirmed = Core.Data.ConfirmedParts and Core.Data.ConfirmedParts("Bosses", encounter) or {}
    for _, part in ipairs(confirmed) do
        local id = part:sub(1, 1) == kind and tonumber(part:sub(2))
        if id and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    return list
end

-- Up to Dungeons.LINES lines of a list under its title, and how many more there are; with Alt held, each one's
-- details under it (details: nil for none). One not yet confirmed by the game (kind: the part's letter,
-- Bosses:Unverified) has the red ! before its name; true when any shown is. right(id): the words at a line's right.
local function Listed(title, ids, line, details, encounter, kind, right)
    local shown, more, unconfirmed = 0, 0, false
    for _, id in ipairs(ids or {}) do
        if shown >= Dungeons.LINES then
            more = more + 1
        else
            local doubt = BOSSES:Unverified(encounter, kind .. id)
            local words, r, g, b = line(id, doubt and Core.UNCONFIRMED_MARK or nil)
            if words then
                if shown == 0 then Core.TipSection(GameTooltip, title) end
                shown = shown + 1
                local beside = right and right(id)
                if beside then
                    GameTooltip:AddDoubleLine(words, beside, r or 1, g or 1, b or 1, 1, 1, 1)
                else
                    GameTooltip:AddLine(words, r or 1, g or 1, b or 1)
                end
                if details then details(id) end
                if doubt then unconfirmed = true end
            end
        end
    end
    if more > 0 and shown > 0 then GameTooltip:AddLine(Dungeons.TEXT.more:format(more), 0.6, 0.6, 0.6) end
    return unconfirmed
end

-- A boss's tooltip, as a creature's (Core.TipLook): its name in the game's red of a foe, under it the dungeon and
-- Boss; its model in the portrait's place with the boss's dragon round it and ?? for its level; then its abilities
-- and its loot, each a section.
Dungeons.FOE = { 1, 0.3, 0.25 } -- a foe's name
local function BossTip(part)
    local mark = part.mark or part
    tipped = part
    GameTooltip:SetOwner(part, "ANCHOR_RIGHT")
    Core.TipLook(GameTooltip, { display = mark.display, dragon = "boss", badge = "??" })
    local foe = Dungeons.FOE
    GameTooltip:SetText(mark.name or "?", foe[1], foe[2], foe[3])
    local encounter = mark.encounter
    local place = encounter and SET:Get(ENCOUNTERS:Get(encounter, "instance") or 0, "name")
    if place then GameTooltip:AddLine(place, 1, 1, 1) end
    GameTooltip:AddLine(Dungeons.TEXT.boss, 1, 0.82, 0)
    local unconfirmed = false
    if encounter then
        local alt = IsAltKeyDown()
        unconfirmed = Listed(Dungeons.TEXT.abilities, Parts(encounter, "abilities", "a"), SpellLine, alt and SpellDetails,
            encounter, "a")
        unconfirmed = Listed(Dungeons.TEXT.loot, Parts(encounter, "loot", "l"), ItemLine, alt and ItemDetails, encounter, "l",
            function(id) return Rate(mark.name, id) end) or unconfirmed
    end
    if unconfirmed then Core.Unconfirmed(GameTooltip) end
    GameTooltip:Show()
end

local function TipGone()
    tipped = nil
    GameTooltip_Hide()
end

-- An item or spell the tooltip asked for has come from the game, or Alt was pressed or let go: the tooltip drawn
-- again, once on the next frame.
local Again = Core.Later(function()
    if tipped and tipped:IsMouseOver() and GameTooltip:GetOwner() == tipped then BossTip(tipped) end
end)
for _, event in ipairs({ "ITEM_DATA_LOAD_RESULT", "SPELL_DATA_LOAD_RESULT", "MODIFIER_STATE_CHANGED" }) do
    ns.On(event, function()
        if tipped then Again() end
    end)
end
-- Something confirmed in play, or an item's stats learned (here or shared): drawn again with it.
local function Changed()
    if tipped then Again() end
end
if Core.Data.OnConfirm then Core.Data.OnConfirm(Changed) end
ITEMS:OnStamp(Changed)

-- A boss's mark, and the frame for its model above it (made when a boss with a look first needs it).
local function Mark()
    local mark = CreateFrame("Frame", nil, over)
    mark:SetSize(Dungeons.BOSS_SIZE, Dungeons.BOSS_SIZE)
    mark.icon = mark:CreateTexture(nil, "ARTWORK")
    mark.icon:SetAllPoints()
    mark.icon:SetAtlas(Dungeons.BOSS)
    mark:EnableMouse(true)
    mark:SetScript("OnEnter", ns.Guard(BossTip))
    mark:SetScript("OnLeave", ns.Guard(TipGone))
    return mark
end

local function Model(mark)
    local model = CreateFrame("PlayerModel", nil, over)
    model:SetSize(Dungeons.MODEL_WIDTH, Dungeons.MODEL_HEIGHT)
    model.mark = mark
    model:EnableMouse(true)
    model:SetScript("OnEnter", ns.Guard(BossTip))
    model:SetScript("OnLeave", ns.Guard(TipGone))
    mark.model = model
    return model
end

-- A boss's model shown in its look (the game's creature display), standing on its mark; out of sight without a
-- look, or where it would reach past the view's edge. True while it shows.
local function Stand(mark, display, x, y)
    local model = mark.model
    if not display then
        if model then model:Hide() end
        return false
    end
    model = model or Model(mark)
    if model.display ~= display then
        model.display = display
        model:SetDisplayInfo(display)
        model:SetPortraitZoom(0)
        model:SetFacing(Dungeons.FACING)
    end
    local width, height = frame:GetSize()
    local share = onSmall and Dungeons.SMALL or 1
    -- as the map grows, the model with it (as large as the zoom makes the art), never taller than MODEL_MOST of the view
    local grow = math.max(1, math.min(zoom, (height or 0) * Dungeons.MODEL_MOST / (Dungeons.MODEL_HEIGHT * share)))
    local modelWidth, modelHeight = Dungeons.MODEL_WIDTH * share * grow, Dungeons.MODEL_HEIGHT * share * grow
    local half = modelWidth / 2
    local inside = x - half >= -width / 2 and x + half <= width / 2 and y >= -height / 2
        and y + modelHeight <= height / 2
    model:SetSize(modelWidth, modelHeight)
    model:ClearAllPoints()
    model:SetPoint("BOTTOM", frame, "CENTER", x, y)
    model:SetShown(inside)
    return inside
end

-- The bosses of a floor, as the set has them: { name, x, y } (0 to 1 on the floor's map), in their order.
function Dungeons.Bosses(map)
    local _, floor = Entry(map)
    if not floor or not floor.data then return {} end
    local found = {}
    for _, boss in ipairs(SET:Get(floor.instance, "bosses") or {}) do
        if boss.floor == floor.data.floor and boss.x and boss.y then
            found[#found + 1] = { encounter = boss.encounter, name = ENCOUNTERS:Get(boss.encounter, "name"),
                                  x = boss.x, y = boss.y, display = boss.display }
        end
    end
    return found
end

-- The enemies of a floor, as the set has them: { npc, x, y } (0 to 1 on the floor's map).
function Dungeons.Enemies(map)
    local _, floor = Entry(map)
    if not floor or not floor.data then return {} end
    local found = {}
    for _, enemy in ipairs(SET:Get(floor.instance, "enemies") or {}) do
        if enemy.floor == floor.data.floor and enemy.x and enemy.y then found[#found + 1] = enemy end
    end
    return found
end

-- A floor's ground as Core's set DungeonGround lays it: { rows (the set's, in drawing order), box (the floor's world:
-- north, south, west, east) }; nil where it has none (a floor of the game's own maps, a floor or an instance the set
-- has none for, the set not there).
function Dungeons.Ground(map)
    local _, floor = Entry(map)
    local data = floor and floor.data
    if not data or not (data.north and data.south and data.west and data.east) then return nil end
    if data.north == data.south or data.west == data.east then return nil end
    local rows = {}
    for _, row in ipairs(GROUND:Get(floor.instance, "ground") or NONE) do
        if row.floor == data.floor and row.file and row.x and row.y and row.width and row.height then
            rows[#rows + 1] = row
        end
    end
    if #rows == 0 then return nil end
    return { rows = rows, box = { data.north, data.south, data.west, data.east } }
end

-- What a floor is drawn from, gathered once as it is shown (Dungeons.Show; the set come since: Build) and kept until
-- the view goes (Close): its art, its ground, its bosses and enemies as the set has them, and its instance (the
-- enemies' tooltips). Each walks every dungeon's floors (Entry): not at every step of a drag (Place).
local function Gather(map)
    local _, floor = Entry(map)
    return { art = ArtOf(map), ground = Dungeons.Ground(map), bosses = Dungeons.Bosses(map),
             enemies = Dungeons.Enemies(map), instance = floor and floor.instance }
end

local function FoeTip(foe)
    GameTooltip:SetOwner(foe, "ANCHOR_RIGHT")
    local red = Dungeons.FOE
    local name = foe.npc and NPCS:Get(foe.npc, "name") or Dungeons.TEXT.enemy
    -- Where it stands is the set Dungeons' (its instance's entry), and so is whether that is confirmed
    local doubt = SET:Unverified(foe.instance)
    GameTooltip:SetText((doubt and Core.UNCONFIRMED_MARK or "") .. name, red[1], red[2], red[3])
    if foe.npc then
        local _, unsure = ns.PinView.Drops("npc:" .. foe.npc, ns.PinView.DROPS)
        doubt = doubt or unsure
    end
    if doubt then Core.Unconfirmed(GameTooltip) end
    GameTooltip:Show()
end

local function Foe()
    local foe = CreateFrame("Frame", nil, over)
    foe:SetSize(Dungeons.ENEMY_SIZE, Dungeons.ENEMY_SIZE)
    foe.icon = foe:CreateTexture(nil, "ARTWORK")
    foe.icon:SetAllPoints()
    foe.icon:SetTexture(Dungeons.ENEMY)
    foe:EnableMouse(true)
    foe:SetScript("OnEnter", ns.Guard(FoeTip))
    foe:SetScript("OnLeave", GameTooltip_Hide)
    return foe
end

-- Each enemy's mark where it stands, as the bosses' are placed, under them; those of no enemy hidden.
function Dungeons.PlaceEnemies(art, scale)
    local enemies = kept and kept.enemies or NONE
    local base = over:GetFrameLevel()
    local size = Dungeons.ENEMY_SIZE * (onSmall and Dungeons.SMALL or 1)
    for index, enemy in ipairs(enemies) do
        local foe = foes[index] or Foe()
        foes[index] = foe
        foe.npc, foe.instance = enemy.npc, kept.instance
        foe:SetSize(size, size)
        foe:ClearAllPoints()
        foe:SetPoint("CENTER", frame, "CENTER", midX + (enemy.x - 0.5) * art.width * scale,
            midY - (enemy.y - 0.5) * art.height * scale)
        foe:SetFrameLevel(base)
        foe:Show()
    end
    for index = #enemies + 1, #foes do foes[index]:Hide() end
end

-- Each boss's mark where it stands on the art as the zoom and the drag put it (scale: the art's), the same size at
-- every zoom, its model on it, growing with the zoom (Stand); one lower on the screen in front of one behind it; the
-- marks of no boss hidden.
function Dungeons.PlaceBosses(art, scale)
    local bosses = kept and kept.bosses or NONE
    local base = over:GetFrameLevel()
    local size = Dungeons.BOSS_SIZE * (onSmall and Dungeons.SMALL or 1)
    for index, boss in ipairs(bosses) do
        local mark = marks[index] or Mark()
        marks[index] = mark
        mark.name, mark.encounter, mark.display = boss.name, boss.encounter, boss.display
        local x, y = midX + (boss.x - 0.5) * art.width * scale, midY - (boss.y - 0.5) * art.height * scale
        mark:SetSize(size, size)
        mark:ClearAllPoints()
        mark:SetPoint("CENTER", frame, "CENTER", x, y)
        mark:SetFrameLevel(base + 1)
        mark:Show()
        -- The model is the boss; its mark only where no model stands (no look, or at the view's edge).
        local standing = Stand(mark, boss.display, x, y)
        mark.icon:SetShown(not standing)
        mark:EnableMouse(not standing)
        -- In front by how far down it stands (the top of the art behind), over the marks; a few levels only, so
        -- none comes over the bar above the map (and takes its clicks).
        if mark.model then mark.model:SetFrameLevel(base + 2 + math.floor(boss.y * Dungeons.SPREAD)) end
    end
    for index = #bosses + 1, #marks do
        marks[index]:Hide()
        if marks[index].model then marks[index].model:Hide() end
    end
end

-- Over the canvas, as large as it, under the bar; hidden until a dungeon is chosen.
function Dungeons.Build(canvasFrame)
    canvas = canvasFrame
    frame = CreateFrame("Frame", nil, canvas:GetParent())
    frame:SetAllPoints(canvas)
    frame:SetClipsChildren(true)
    Dungeons.frame = frame
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    local ground = frame:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints()
    local sea = ns.Canvas.GROUND
    ground:SetColorTexture(sea[1], sea[2], sea[3])
    content = CreateFrame("Frame", nil, frame)
    content:SetSize(1, 1)
    over = CreateFrame("Frame", nil, frame) -- over the art
    over:SetAllPoints()
    over:SetFrameLevel(content:GetFrameLevel() + 1)
    frame:SetScript("OnMouseWheel", ns.Guard(Wheel))
    frame:SetScript("OnMouseDown", ns.Guard(Down))
    frame:SetScript("OnMouseUp", ns.Guard(Up))
    frame:SetScript("OnEnter", ns.Guard(Entered))
    frame:SetScript("OnLeave", ns.Guard(Left))
    frame:SetScript("OnSizeChanged", ns.Guard(Dungeons.Refit))
    frame:Hide()
    -- The set arrived: walked into the list (Walk); the floor shown drawn again with its bosses.
    SET:OnStamp(ns.Guard(function()
        fromData, list = nil, nil
        Walk()
        if shown then
            kept = Gather(shown)
            Draw()
        end
    end))
    -- The ground's set arrived: the floor shown drawn again with its ground.
    GROUND:OnStamp(ns.Guard(function()
        if shown then
            kept = Gather(shown)
            Draw()
        end
    end))
    return frame
end

-- A dungeon's floor shown whole (map: any floor of it), on the small map (small) or the full one. False for a map
-- that is no dungeon's, or one without art.
local function Open(map, small)
    local entry, floor = Entry(map)
    if not entry or not ArtOf(map) then return false end
    map = floor.map
    shown, floors, onSmall = map, entry.floors, small
    kept = Gather(map)
    zoom, panX, panY, dragX = 1, 0, 0, nil
    frame:SetFrameLevel(canvas:GetFrameLevel() + Dungeons.LEVEL)
    frame:Show()
    Room()
    Draw()
    ns.Safe("bar", ns.TopBar.Update)
    return true
end

-- A dungeon's floor shown (map: any floor of it), whole, on the full map; the floors' dropdown with it. False for
-- a map that is no dungeon's, or one without art, or while the map is small.
function Dungeons.Show(map)
    if not frame or ns.Canvas.camera ~= ns.Window.full then return false end
    return Open(map, false)
end

-- The small map in a dungeon, wheeled out past the game's widest step (Canvas.lua, where the game's minimap alone is
-- the map: lost): the dungeon's whole map in its place, wished so until wheeled in again or clicked away (Out). False
-- where the game's dungeon has no map of ours (then the game's minimap stays).
function Dungeons.Whole()
    if not frame or ns.Canvas.camera ~= ns.Window.small then return false end
    local here = Dungeons.Here()
    if not here or not Open(here, true) then return false end
    wanted = true
    return true
end

-- At each layout of the small map (Canvas.Layout; lost: in an instance, the game's minimap alone is the map there):
-- the dungeon's whole map as it was wished, in the dungeon the player is in; gone outside one. True while it shows,
-- and the game's minimap stands out of sight under it.
function Dungeons.Small(lost)
    if not frame then return false end
    if not lost then
        if onSmall then Dungeons.Close() end
        return false
    end
    if onSmall then return true end
    if not wanted or shown then return false end
    local here = Dungeons.Here()
    return here and Open(here, true) or false
end

-- A loading screen: another dungeon, or none, so the small map's whole map is looked at anew (Small, at the layout).
ns.On("PLAYER_ENTERING_WORLD", function()
    if not onSmall then return end
    Dungeons.Close()
    ns.Canvas.Refresh()
end)

-- The map again: the dungeon's view goes (the window going small, a map chosen in the bar).
function Dungeons.Close()
    if not frame or not shown then return end
    shown, floors, kept, dragX, onSmall = nil, nil, nil, nil, false
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    for _, texture in ipairs(tiles) do texture:SetTexture(nil) end -- its files let go
    for _, texture in ipairs(grounds) do
        texture:Hide()
        texture:SetTexture(nil)
    end
    laid, share = nil, nil
    for _, foe in ipairs(foes) do foe:Hide() end
    ns.Safe("drawings", ns.Draw.FloorClear)
    for _, mark in ipairs(marks) do
        mark:Hide()
        if mark.model then
            mark.model:Hide()
            mark.model:ClearModel() -- its model let go
            mark.model.display = nil
        end
    end
    ns.Safe("bar", ns.TopBar.Update)
end

-- A right click: back to the map it was opened from. That map stays under the dungeon's view as it was (from the
-- bar, a pin's entrance, or the full map opened inside), so the view only goes. On the small map (a notch in too,
-- or the middle button) the game's minimap again, at its widest step, and no longer wished.
function Dungeons.Out()
    local small = onSmall
    if small then wanted = false end
    Dungeons.Close()
    if small then ns.Canvas.Refresh() end
end

-- A floor's name for your markers' cards (Markers.lua): its dungeon's, and the floor's where it has several; nil for a
-- map that is no dungeon's floor.
function Dungeons.Named(map)
    if map == nil then return nil end
    local entry, floor = Entry(map)
    if not entry then return nil end
    local name = entry.name or "?"
    if entry.floors and #entry.floors > 1 and floor and floor.name then name = name .. ", " .. floor.name end
    return name
end

-- The floor shown (nil: none), the floors of its dungeon, and whether it stands on the small map.
function Dungeons.Shown()
    return shown, floors, onSmall
end
