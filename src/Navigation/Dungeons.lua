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
--                   chosen in the bar's dropdown beside it; the first shown is the player's floor when
--                   inside
--      the art      the game's own map art of the floor (Art.Of; the set's: its tiles, the game's
--                   files), fitted into the view whole
--      the bosses   where Core's set Dungeons has them: the game's boss mark at each one's place and the
--                   boss's own 3D model standing on it (the game's model of its display), the same size at
--                   every zoom, its name (the set Encounters) in the tooltip; a model that would reach past
--                   the view's edge is hidden (the engine does not cut it there), its mark stays
--      the mouse    the wheel zooms around the mouse (from the whole map up to Dungeons.NEAR times
--                   nearer), a drag moves it, a right click goes back to the map, at the zone the
--                   dungeon lies in where the map can show it
--      also         a pin that leads into a dungeon (Shift and a click on its entrance) opens its map here
--                   (Canvas.Show)
--      the player   the game's arrow where the game tells the player's place on the floor shown (a floor
--                   of the set's: the player's place in the world, UnitPosition, in its box)
--
--  Opening the full map inside a dungeon shows its map at once (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Dungeons = {}
ns.Dungeons = Dungeons

Dungeons.NEAR = 4   -- the nearest zoom: so many times the whole map's
Dungeons.LOOK = 0.2 -- seconds between two looks at the player's place
Dungeons.LEVEL = 25 -- over the canvas' layers, under the bar (TopBar: 30)
Dungeons.BOSS = "vignettekillboss" -- a boss's mark: the game's own
Dungeons.BOSS_SIZE = 26
Dungeons.MODEL_WIDTH, Dungeons.MODEL_HEIGHT = 72, 88 -- a boss's model standing on its mark, in screen units
Dungeons.FACING = 0.35 -- radians: the models turned a little from facing the view, so they read as figures
Dungeons.TEXT = {
    dungeons = Core.Word("DUNGEONS", "Dungeons"),
    floor = "Floor",
    unverified = "Its place not yet confirmed by the game",
}

local KINDS = rawget(_G, "Enum") and Enum.UIMapType or {}
local DUNGEON = KINDS.Dungeon or 4

local SET = Core.Data.Set("Dungeons")
local ENCOUNTERS = Core.Data.Set("Encounters")

local frame, content, over, arrow, canvas
local tiles = {}  -- the art's textures, made as many as needed
local marks = {}  -- the bosses' marks, made as many as needed
local fromData    -- the dungeons of the set, once walked (Walk); nil until then
local told        -- the game has told of a dungeon's map: the list is kept; else the game is asked again
local walking     -- the walk's job while it runs
local list        -- the dungeons, asked of the game once: { map = its first floor, name, floors = { { map, name } } }
local shown       -- the floor shown, nil while the map is
local floors      -- the floors of the dungeon shown (one at least)
local zoom, panX, panY = 1, 0, 0 -- the zoom (1: whole), the art's middle from the view's, in screen units
local dragX, dragY -- where the cursor was at the last step of a drag
local nextLook = 0

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
-- Z; asked again while neither has told any.
function Dungeons.List()
    Walk()
    if list and told then return list end
    list = {}
    local root = ns.Coords.WorldMap()
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

-- The player in the world: x (north), y (west), from the game; nil where it tells none.
local function World()
    local position = rawget(_G, "UnitPosition")
    local x, y = Core.Ask(position, "player")
    x, y = Core.Plain(x), Core.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

-- The instance the player is in: its map ID, the game's GetInstanceInfo's eighth answer (Core.Ask gives three).
local function Instance()
    local info = rawget(_G, "GetInstanceInfo")
    if type(info) ~= "function" then return nil end
    local ok, _, _, _, _, _, _, _, instance = pcall(info)
    instance = ok and Core.Plain(instance) or nil
    return type(instance) == "number" and instance or nil
end

-- A world point on a floor of the set: 0 to 1 across its map from the top left; nil without its box.
local function OnFloor(data, x, y)
    if not (data.north and data.south and data.west and data.east) then return nil end
    if data.north == data.south or data.west == data.east then return nil end
    return (data.west - y) / (data.west - data.east), (data.north - x) / (data.north - data.south)
end

-- The floor the player is on, if it is a dungeon's: the game's map of it, or in a dungeon of the set the floor
-- whose box holds the player (the smallest; its first floor where none does or the game tells no place).
function Dungeons.Here()
    local map = Core.Plain(Core.Ask(C_Map.GetBestMapForUnit, "player"))
    if map and Entry(map) then return map end
    local entry = Entry(Dungeons.Key(Instance()))
    if not entry then return nil end
    local x, y = World()
    local best, area
    for _, floor in ipairs(x and entry.floors or {}) do
        local mapX, mapY = OnFloor(floor.data, x, y)
        if mapX and mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
            local size = math.abs((floor.data.north - floor.data.south) * (floor.data.west - floor.data.east))
            if not area or size < area then best, area = floor, size end
        end
    end
    return (best or entry.floors[1]).map
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
-- The art's size on the screen at zoom 1: the whole map in the view, as large as fits.
local function Fit(art)
    local width, height = frame:GetSize()
    if width <= 0 or height <= 0 then return 1 end
    return math.min(width / art.width, height / art.height)
end

-- The art where the zoom and the drag put it; never so far that it leaves the view's middle.
local function Place()
    local art = shown and ArtOf(shown)
    if not art then return end
    local scale = Fit(art) * zoom
    local halfX, halfY = art.width * scale / 2, art.height * scale / 2
    panX, panY = math.max(-halfX, math.min(halfX, panX)), math.max(-halfY, math.min(halfY, panY))
    content:SetScale(scale)
    content:ClearAllPoints()
    content:SetPoint("CENTER", frame, "CENTER", panX / scale, panY / scale)
    Dungeons.PlaceBosses(art, scale)
    nextLook = 0 -- the arrow with it, on the next frame
end

-- The floor's art: its tiles row by row, the last ones cut at the art's edge (as Art.lua lays a map's).
local function Draw()
    for _, texture in ipairs(tiles) do texture:Hide() end
    local art = ArtOf(shown)
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

-- The player's arrow on the floor shown, turned as the player faces; out of sight elsewhere.
local function Look()
    local x, y
    local _, floor = Entry(shown)
    if floor and floor.data then
        local worldX, worldY = World()
        if worldX then x, y = OnFloor(floor.data, worldX, worldY) end
        if x and (x < 0 or x > 1 or y < 0 or y > 1) then x, y = nil, nil end
    else
        local position = shown and Core.Ask(C_Map.GetPlayerMapPosition, shown, "player")
        x, y = position and Core.Plain(position.x), position and Core.Plain(position.y)
    end
    local art = shown and ArtOf(shown)
    if not x or not y or not art or (x == 0 and y == 0) then return arrow:Hide() end
    local facing = Core.Plain(Core.Ask(GetPlayerFacing))
    if facing then arrow:SetRotation(facing) end
    local scale = content:GetScale() -- the arrow is not in the art: the same size at every zoom
    arrow:ClearAllPoints()
    arrow:SetPoint("CENTER", frame, "CENTER", panX + (x - 0.5) * art.width * scale, panY - (y - 0.5) * art.height * scale)
    arrow:Show()
end

local function Cursor()
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    return x / scale, y / scale
end

local function Update(_, elapsed)
    if dragX then
        local x, y = Cursor()
        panX, panY = panX + x - dragX, panY + y - dragY
        dragX, dragY = x, y
        Place()
    end
    nextLook = nextLook - (elapsed or 0)
    if nextLook <= 0 then
        nextLook = Dungeons.LOOK
        Look()
    end
end

-- The wheel: nearer or farther around the point under the mouse, which stays where it is.
local function Wheel(_, delta)
    local art = shown and ArtOf(shown)
    if not art then return end
    local was = zoom
    zoom = math.max(1, math.min(Dungeons.NEAR, zoom * ns.Camera.STEP ^ delta))
    if zoom == was then return end
    local x, y = Cursor()
    local left, bottom, width, height = frame:GetRect()
    if not left then return end
    local mouseX, mouseY = x - left - width / 2, y - bottom - height / 2
    local factor = zoom / was
    panX, panY = mouseX - (mouseX - panX) * factor, mouseY - (mouseY - panY) * factor
    Place()
    Look()
end

local function Down(_, button)
    if button == "LeftButton" then dragX, dragY = Cursor() end
end

local function Up(_, button)
    if button == "LeftButton" then
        dragX, dragY = nil, nil
    elseif button == "RightButton" then
        Dungeons.Out()
    end
end

-------------------------------------------------------------------------------
--  The bosses
-------------------------------------------------------------------------------
local function BossTip(part)
    local mark = part.mark or part
    GameTooltip:SetOwner(part, "ANCHOR_RIGHT")
    GameTooltip:SetText(mark.name or "?", 1, 1, 1)
    GameTooltip:AddLine(Dungeons.TEXT.unverified, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- A boss's mark, and the frame for its model above it (made when a boss with a look first needs it).
local function Mark()
    local mark = CreateFrame("Frame", nil, over)
    mark:SetSize(Dungeons.BOSS_SIZE, Dungeons.BOSS_SIZE)
    mark.icon = mark:CreateTexture(nil, "ARTWORK")
    mark.icon:SetAllPoints()
    mark.icon:SetAtlas(Dungeons.BOSS)
    mark:EnableMouse(true)
    mark:SetScript("OnEnter", ns.Guard(BossTip))
    mark:SetScript("OnLeave", GameTooltip_Hide)
    return mark
end

local function Model(mark)
    local model = CreateFrame("PlayerModel", nil, over)
    model:SetSize(Dungeons.MODEL_WIDTH, Dungeons.MODEL_HEIGHT)
    model.mark = mark
    model:EnableMouse(true)
    model:SetScript("OnEnter", ns.Guard(BossTip))
    model:SetScript("OnLeave", GameTooltip_Hide)
    mark.model = model
    return model
end

-- A boss's model shown in its look (the game's creature display), standing on its mark; out of sight without a
-- look, or where it would reach past the view's edge.
local function Stand(mark, display, x, y)
    local model = mark.model
    if not display then
        if model then model:Hide() end
        return
    end
    model = model or Model(mark)
    if model.display ~= display then
        model.display = display
        model:SetDisplayInfo(display)
        model:SetPortraitZoom(0)
        model:SetFacing(Dungeons.FACING)
    end
    local width, height = frame:GetSize()
    local half = Dungeons.MODEL_WIDTH / 2
    local inside = x - half >= -width / 2 and x + half <= width / 2 and y >= -height / 2
        and y + Dungeons.MODEL_HEIGHT <= height / 2
    model:ClearAllPoints()
    model:SetPoint("BOTTOM", frame, "CENTER", x, y)
    model:SetShown(inside)
end

-- The bosses of the floor shown, as the set has them: { name, x, y } (0 to 1 on the floor's map), in their order.
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

-- Each boss's mark where it stands on the art as the zoom and the drag put it (scale: the art's), its model on
-- it, the same size at every zoom; one lower on the screen in front of one behind it; the marks of no boss hidden.
function Dungeons.PlaceBosses(art, scale)
    local bosses = shown and Dungeons.Bosses(shown) or {}
    local base = over:GetFrameLevel()
    for index, boss in ipairs(bosses) do
        local mark = marks[index] or Mark()
        marks[index] = mark
        mark.name = boss.name
        local x, y = panX + (boss.x - 0.5) * art.width * scale, panY - (boss.y - 0.5) * art.height * scale
        mark:ClearAllPoints()
        mark:SetPoint("CENTER", frame, "CENTER", x, y)
        mark:SetFrameLevel(base + 1)
        mark:Show()
        Stand(mark, boss.display, x, y)
        -- In front by how far down it stands (the top of the art behind), over the marks.
        if mark.model then mark.model:SetFrameLevel(base + 2 + math.floor(boss.y * 100)) end
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
    arrow = over:CreateTexture(nil, "OVERLAY", nil, 7)
    arrow:SetAtlas("UI-WorldMapArrow")
    arrow:SetSize(ns.Marks.ARROW, ns.Marks.ARROW)
    arrow:Hide()
    frame:SetScript("OnMouseWheel", ns.Guard(Wheel))
    frame:SetScript("OnMouseDown", ns.Guard(Down))
    frame:SetScript("OnMouseUp", ns.Guard(Up))
    frame:SetScript("OnSizeChanged", ns.Guard(Place))
    frame:Hide()
    -- The set arrived: walked into the list (Walk); the floor shown drawn again with its bosses.
    SET:OnStamp(ns.Guard(function()
        fromData, list = nil, nil
        Walk()
        if shown then Draw() end
    end))
    return frame
end

-- A dungeon's floor shown (map: any floor of it), whole, on the full map; the floors' dropdown with it. False for
-- a map that is no dungeon's, or one without art, or while the map is small.
function Dungeons.Show(map)
    if not frame or ns.Canvas.camera ~= ns.Window.full then return false end
    local entry, floor = Entry(map)
    if not entry or not ArtOf(map) then return false end
    map = floor.map
    shown, floors = map, entry.floors
    zoom, panX, panY, dragX = 1, 0, 0, nil
    frame:SetFrameLevel(canvas:GetFrameLevel() + Dungeons.LEVEL)
    frame:Show()
    frame:SetScript("OnUpdate", ns.Guard(Update))
    nextLook = 0
    Draw()
    ns.Safe("bar", ns.TopBar.Update)
    return true
end

-- The map again: the dungeon's view goes (the window going small, a map chosen in the bar).
function Dungeons.Close()
    if not frame or not shown then return end
    shown, floors, dragX = nil, nil, nil
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    for _, texture in ipairs(tiles) do texture:SetTexture(nil) end -- its files let go
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

-- A right click: back to the map, at the zone the dungeon lies in where the map can show it.
function Dungeons.Out()
    local info = shown and Core.Ask(C_Map.GetMapInfo, shown)
    Dungeons.Close()
    local parent = type(info) == "table" and info.parentMapID
    if parent and parent > 0 then ns.Canvas.Show(parent) end
end

-- The floor shown (nil: none), and the floors of its dungeon.
function Dungeons.Shown()
    return shown, floors
end
