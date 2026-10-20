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
--                   lowest floor, A to Z
--      a floor      the game's floors of the dungeon (C_Map.GetMapGroupMembersInfo), chosen in the
--                   bar's dropdown beside it; the first shown is the player's floor when inside
--      the art      the game's own map art of the floor (Art.Of), fitted into the view whole
--      the mouse    the wheel zooms around the mouse (from the whole map up to Dungeons.NEAR times
--                   nearer), a drag moves it, a right click goes back to the map, at the zone the
--                   dungeon lies in where the map can show it
--      also         a pin that leads into a dungeon (Shift and a click on its entrance) opens its map here
--                   (Canvas.Show)
--      the player   the game's arrow where the game tells the player's place on the floor shown
--
--  Opening the full map inside a dungeon shows its map at once (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Dungeons = {}
ns.Dungeons = Dungeons

Dungeons.NEAR = 4   -- the nearest zoom: so many times the whole map's
Dungeons.LOOK = 0.2 -- seconds between two looks at the player's place
Dungeons.LEVEL = 25 -- over the canvas' layers, under the bar (TopBar: 30)
Dungeons.TEXT = {
    dungeons = Core.Word("DUNGEONS", "Dungeons"),
    floor = "Floor",
}

local KINDS = rawget(_G, "Enum") and Enum.UIMapType or {}
local DUNGEON = KINDS.Dungeon or 4

local frame, content, arrow, canvas
local tiles = {}  -- the art's textures, made as many as needed
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

-- Every dungeon and raid the game has a map of, one entry each, A to Z; asked again while the game has told none.
function Dungeons.List()
    if list and #list > 0 then return list end
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
            if name and name ~= "" then list[#list + 1] = { map = each[1].map, name = name, floors = each } end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- The dungeon of a map: its entry in the list, if it is one's floor.
local function Entry(map)
    for _, entry in ipairs(Dungeons.List()) do
        for _, floor in ipairs(entry.floors) do
            if floor.map == map then return entry end
        end
    end
    return nil
end

-- The floor the player is on, if it is a dungeon's.
function Dungeons.Here()
    local map = Core.Plain(Core.Ask(C_Map.GetBestMapForUnit, "player"))
    return map and Entry(map) and map or nil
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
    local art = shown and ns.Art.Of(shown)
    if not art then return end
    local scale = Fit(art) * zoom
    local halfX, halfY = art.width * scale / 2, art.height * scale / 2
    panX, panY = math.max(-halfX, math.min(halfX, panX)), math.max(-halfY, math.min(halfY, panY))
    content:SetScale(scale)
    content:ClearAllPoints()
    content:SetPoint("CENTER", frame, "CENTER", panX / scale, panY / scale)
    nextLook = 0 -- the arrow with it, on the next frame
end

-- The floor's art: its tiles row by row, the last ones cut at the art's edge (as Art.lua lays a map's).
local function Draw()
    for _, texture in ipairs(tiles) do texture:Hide() end
    local art = ns.Art.Of(shown)
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
    local position = shown and Core.Ask(C_Map.GetPlayerMapPosition, shown, "player")
    local x, y = position and Core.Plain(position.x), position and Core.Plain(position.y)
    local art = shown and ns.Art.Of(shown)
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
    local art = shown and ns.Art.Of(shown)
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
    local over = CreateFrame("Frame", nil, frame) -- over the art
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
    return frame
end

-- A dungeon's floor shown (map: any floor of it), whole, on the full map; the floors' dropdown with it. False for
-- a map that is no dungeon's, or one without art, or while the map is small.
function Dungeons.Show(map)
    if not frame or ns.Canvas.camera ~= ns.Window.full then return false end
    local entry = Entry(map)
    if not entry or not ns.Art.Of(map) then return false end
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
