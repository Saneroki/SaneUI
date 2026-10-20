-- Runs the Navigation module against the stand-in client (wowstub.lua) on a small made-up world: the map's
-- spaces and the map tree, the camera's levels, what the game tells (Live), the map drawn each way in both
-- views, the views offered with and without the module Atlas (its index read, the level a zoom draws, the
-- block under a point, loaded when first drawn, the fall back when it fails), the mouse (drag, wheel, right
-- click, Ctrl-click), the game's minimap taken over ours and given back, the game's map kept closed and its
-- keys. The look itself can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/navigation.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1600, 900
Enum.UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4 }
function CreateVector2D(x, y)
    local vector = { x = x, y = y }
    function vector:SetXY(a, b) self.x, self.y = a, b end
    function vector:GetXY() return self.x, self.y end
    return vector
end
UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = CreateVector2D(x, y) } end }
function methods:GetLeft() return self._left or 0 end
function methods:GetBottom() return self._bottom or 0 end
function methods:GetCenter() return (self._width or 0) / 2, (self._height or 0) / 2 end
function methods:LockHighlight() self._lit = true end
function methods:UnlockHighlight() self._lit = false end
function methods:EnableMouse(on) self._mouse = on and true or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on and true or false end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:SetBlendMode(mode) self._blend = mode end
function methods:SetTexCoord(...) self._coords = { ... } end
function methods:AddMaskTexture(mask) self._mask = mask end
function methods:RemoveMaskTexture(mask) if self._mask == mask then self._mask = nil end end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetRotation(angle) self._rotation = angle end
function methods:SetDrawLayer(layer, sublevel) self._layer, self._sublevel = layer, sublevel end
function methods:OverrideText(text) self._override = text end
function methods:GetChildren()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == self and widget._kind ~= "Texture" and widget._kind ~= "FontString" then list[#list + 1] = widget end
    end
    return unpack(list)
end
-- An animation: the test moves its clock (as dev/tests/window.lua does). As in the game, a group may come
-- from an XML template (group.template), and a TextureCoordTranslation made in Lua has no SetOffset.
local function noop() end
function methods:CreateAnimationGroup(_, template)
    assert(template == nil or W.xmlTemplates[template] == "AnimationGroup", "no such animation template: " .. tostring(template))
    local group = { scripts = {}, playing = false, progress = 0, template = template }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress = true, 0 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha, group.SetLooping = noop, noop
    function group:CreateAnimation(kind)
        local animation = setmetatable({ SetSmoothing = noop, SetToAlpha = noop }, { __index = function(_, key)
            if kind == "TextureCoordTranslation" and key == "SetOffset" then return nil end
            return noop
        end })
        function animation:SetDuration(seconds) group.duration = seconds end
        function animation:GetProgress() return group.progress end
        function animation:GetSmoothProgress() return group.progress end
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate and self.scripts.OnUpdate() end
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished() end
    end
    self._group = self._group or group
    return group
end
local cursorX, cursorY = 100, 100
GetCursorPosition = function() return cursorX, cursorY end
local ctrl = false
IsControlKeyDown = function() return ctrl end
IsIndoors = function() return false end
GetPlayerFacing = function() return 1.5 end
IsInRaid = function() return false end
GetNumSubgroupMembers = function() return 1 end
UnitIsUnit = function(a, b) return a == b end

-- The made-up world, in yards: each map's top (X at y = 0), bottom (X at y = 1), left (Y at x = 0) and
-- right (Y at x = 1) edge, as the game's world positions are: X to the north, Y to the west; a continent's
-- rectangle on the world map (x0, x1, y0, y1).
local MAPS = {
    [947] = { kind = 1, parent = 0 },
    [1415] = { kind = 2, parent = 947, continent = 0, top = 4000, bottom = -16000, left = 4000, right = -4000,
               world = { 0.62, 0.94, 0.18, 0.82 } },
    -- Twice as many yards in a rectangle as large: drawn at half the scale, alike both ways, as the game's are
    [1414] = { kind = 2, parent = 947, continent = 1, top = 20000, bottom = -20000, left = 12000, right = -12000,
               world = { 0.06, 0.54, 0.18, 0.82 } },
    [1429] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000 },
    [9999] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000, swapped = true },
    [500] = { kind = 4, parent = 1429 }, -- a dungeon: no box
    -- An isle: a zone straight on the world map, on a world's map of its own (2991, as Zephras Isle), 2000 x 2500 yards
    [2521] = { kind = 3, parent = 947, continent = 2991, top = 1000, bottom = -1500, left = 1000, right = -1000,
               world = { 0.55, 0.59, 0.40, 0.44 } },
}
local player = { map = 1429, x = 0.75, y = 0.3 }
local waypoint, tracked = nil, false
C_Map = {
    GetWorldPosFromMapPos = function(map, position)
        local info = MAPS[map]
        if not info or not info.top then return nil end
        local north = info.top + position.y * (info.bottom - info.top)
        local west = info.left + position.x * (info.right - info.left)
        -- The game's vector: x is north, y is west; map 9999 says it the other way round.
        if info.swapped then return info.continent, CreateVector2D(west, north) end
        return info.continent, CreateVector2D(north, west)
    end,
    GetMapInfo = function(map)
        local info = MAPS[map]
        local name = ({ [1414] = "Kalimdor", [1429] = "Elwynn Forest", [2521] = "Zephras Isle" })[map]
        return info and { mapID = map, mapType = info.kind, parentMapID = info.parent, name = name } or nil
    end,
    GetAreaInfo = function(area) return area == 12 and "The Far Shore" or nil end,
    GetFallbackWorldMapID = function() return 947 end,
    GetMapChildrenInfo = function(map, kind)
        local list = {}
        for _, id in ipairs({ 1415, 1414, 1429, 2521 }) do
            if MAPS[id].parent == map and (not kind or MAPS[id].kind == kind) then list[#list + 1] = { mapID = id, mapType = MAPS[id].kind } end
        end
        return list
    end,
    GetMapRectOnMap = function(map, top)
        local rect = top == 947 and MAPS[map] and MAPS[map].world
        if rect then return rect[1], rect[2], rect[3], rect[4] end
    end,
    GetBestMapForUnit = function() return player.map end,
    GetPlayerMapPosition = function(map, unit)
        if unit == "party1" and (map == 1429 or map == 1415) then return CreateVector2D(0.5, 0.5) end
        if unit ~= "player" or map ~= player.map or not MAPS[map].top then return nil end
        return CreateVector2D(player.x, player.y)
    end,
    GetMapArtLayers = function(map)
        if not MAPS[map] or (not MAPS[map].top and map ~= 947) then return {} end
        return { { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 } }
    end,
    GetMapArtLayerTextures = function(map)
        local files = {}
        for index = 1, 12 do files[index] = map * 100 + index end
        return files
    end,
    GetMapInfoAtPosition = function(map, x, y)
        -- Elwynn's box on the continent's map: x from 0.375 to 0.625, y from 0.625 to 0.7
        if map == 1415 and x >= 0.375 and x <= 0.625 and y >= 0.625 and y <= 0.7 then return { mapID = 1429, mapType = 3 } end
        if map == 947 then
            for _, id in ipairs({ 1415, 1414, 2521 }) do
                local r = MAPS[id].world
                if x >= r[1] and x <= r[2] and y >= r[3] and y <= r[4] then return { mapID = id, mapType = MAPS[id].kind } end
            end
        end
        return { mapID = map, mapType = MAPS[map].kind }
    end,
    -- Elwynn's highlight under the mouse on the continent's map: file, atlas, the file's used part, its size
    -- and its top left corner on the map
    GetMapHighlightInfoAtPosition = function(map, x, y)
        if map == 1415 and x >= 0.375 and x <= 0.625 and y >= 0.625 and y <= 0.7 then
            return 4242, nil, 0.75, 0.5, 0.25, 0.075, 0.375, 0.625
        end
    end,
    HasUserWaypoint = function() return waypoint ~= nil end,
    GetUserWaypoint = function() return waypoint end,
    CanSetUserWaypointOnMap = function(map) return MAPS[map] and MAPS[map].kind == 3 or false end,
    SetUserWaypoint = function(point) waypoint = point end,
    ClearUserWaypoint = function() waypoint = nil end,
    GetUserWaypointHyperlink = function() return "|Hworldmap|h[Map Pin]|h" end,
}
C_SuperTrack = { IsSuperTrackingUserWaypoint = function() return tracked end,
                 SetSuperTrackedUserWaypoint = function(on) tracked = on end }
C_QuestLog = { GetQuestsOnMap = function(map) return map == 1429 and { { questID = 7, x = 0.4, y = 0.4 } } or nil end }
C_TaxiMap = { GetTaxiNodesForMap = function(map)
    if map ~= 1429 then return {} end
    return { { nodeID = 2, name = "Goldshire", position = CreateVector2D(0.2, 0.8), faction = 2, atlasName = "TaxiNode_Alliance" },
             { nodeID = 3, name = "Crossroads", position = CreateVector2D(0.8, 0.8), faction = 1, atlasName = "TaxiNode_Horde" } }
end }
C_VignetteInfo = {
    GetVignettes = function() return { "v1", "v2" } end,
    GetVignetteInfo = function(guid)
        return guid == "v1" and { name = "A rare", atlasName = "VignetteKill", objectGUID = "Creature-0-1-2-3-70-0000AB" } or nil
    end,
    GetVignettePosition = function(guid, map) return guid == "v1" and map == 1429 and CreateVector2D(0.6, 0.2) or nil end,
}
C_AreaPoiInfo = { GetAreaPOIForMap = function() return { 11 } end,
                  GetAreaPOIInfo = function(_, id) return { areaPoiID = id, name = "A point" } end }
local exploredParts = { { textureWidth = 300, textureHeight = 200, offsetX = 100, offsetY = 50, fileDataIDs = { 701, 702 } },
                        { textureWidth = 64, textureHeight = 64, offsetX = 0, offsetY = 0, fileDataIDs = { 703 }, isShownByMouseOver = true } }
C_MapExplorationInfo = { GetExploredMapTextures = function(map) return map == 1429 and exploredParts or {} end }

-- The quest log: two quests in Elwynn, one of them done; the game's arrow on none at first.
local questLog = {
    { title = "Elwynn Forest", isHeader = true },
    { title = "Wolves Across the Border", questID = 7, level = 6 },
    { title = "Kobold Camp Cleanup", questID = 8, level = 4 },
}
local complete, watched, focused, abandoned = { [8] = true }, {}, 0, nil
local doneQuests = { [5] = true }
C_QuestLog.GetNumQuestLogEntries = function() return #questLog end
C_QuestLog.GetInfo = function(index)
    local entry = questLog[index]
    return entry and { title = entry.title, isHeader = entry.isHeader, questID = entry.questID, level = entry.level,
                       questLogIndex = index } or nil
end
C_QuestLog.IsComplete = function(quest) return complete[quest] or false end
C_QuestLog.IsFailed = function() return false end
C_QuestLog.GetQuestObjectives = function(quest)
    return { { text = "Wolf meat: " .. (complete[quest] and "8/8" or "3/8"), finished = complete[quest] or false } }
end
C_QuestLog.GetQuestWatchType = function(quest) return watched[quest] and 0 or nil end
C_QuestLog.AddQuestWatch = function(quest) watched[quest] = true end
C_QuestLog.RemoveQuestWatch = function(quest) watched[quest] = nil end
C_QuestLog.GetTitleForQuestID = function(quest)
    for _, entry in ipairs(questLog) do if entry.questID == quest then return entry.title end end
end
C_QuestLog.GetLogIndexForQuestID = function(quest)
    for index, entry in ipairs(questLog) do if entry.questID == quest then return index end end
end
C_QuestLog.IsPushableQuest = function() return true end
C_QuestLog.GetMaxNumQuestsCanAccept = function() return 25 end
C_QuestLog.IsQuestFlaggedCompleted = function(quest) return doneQuests[quest] or false end
C_QuestLog.GetNextWaypointForMap = function() return nil end
C_QuestLog.GetNextWaypoint = function() return nil end
C_QuestLog.SetSelectedQuest = function(quest) abandoned = quest end
C_QuestLog.SetAbandonQuest = function() end
C_QuestLog.AbandonQuest = function() abandoned = "gone:" .. tostring(abandoned) end
GetQuestLogQuestText = function(index) return "The story of quest " .. index, "Kill eight wolves." end
C_SuperTrack.GetSuperTrackedQuestID = function() return focused end
C_SuperTrack.SetSuperTrackedQuestID = function(quest) focused = quest end
C_Map.GetMapLinksForMap = function() return {} end
Enum.FlightPathFaction = { Neutral = 0, Horde = 1, Alliance = 2 }
UnitFactionGroup = function() return "Alliance" end
UnitLevel = function() return 6 end
UnitRace = function() return "Human", "Human", 1 end
UnitClass = function(unit) return "Warrior", "WARRIOR", 1 end
IsInGroup = function() return false end
IsShiftKeyDown = function() return false end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
-- The game's scrolling list, as far as the quest log uses it: what it was given to show, drawn on demand.
W.templates.WowScrollBoxList = function(box)
    function box:SetDataProvider(provider) self.provider = provider end
    function box:Draw()
        self.rows = {}
        for index, entry in ipairs(self.provider.list) do
            self.rows[index] = W.NewWidget("Button", nil, self)
            self.view.draw(self.rows[index], entry)
        end
        return self.rows
    end
end
CreateScrollBoxListLinearView = function()
    local view = {}
    function view:SetElementExtentCalculator(fn) self.height = fn end
    function view:SetElementInitializer(kind, fn) self.kind, self.draw = kind, fn end
    return view
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.view = view end }
CreateDataProvider = function(list) return { list = list or {} } end
ScrollBoxConstants = { RetainScrollPosition = true }
function methods:CreateLine() return W.NewWidget("Line", nil, self) end
function methods:SetStartPoint(_, _, x, y) self._start = { x, y } end
function methods:SetEndPoint(_, _, x, y) self._end = { x, y } end
function methods:GetStringHeight() return 40 end
-- The game's quest area frame: what it was asked to draw.
local areaFrames = {}
do
    local made = CreateFrame
    CreateFrame = function(kind, ...)
        local frame = made(kind, ...)
        if kind == "QuestPOIFrame" then
            areaFrames[#areaFrames + 1] = frame
            function frame:SetMapID(map) self._map = map end
            function frame:DrawBlob(quest) self._quest = quest end
            function frame:DrawNone() self._quest = nil end
        end
        return frame
    end
end

-- The game's minimap: its cluster (an Edit Mode system with a selection box), the container, the minimap with
-- its zoom buttons and border.
local radii = { [0] = 240, 200, 160, 120, 80, 50 }
local ground, ignoreRotation, configs = true, false, 0
local cluster = W.NewWidget("Frame", "MinimapCluster", UIParent)
cluster._mouse, cluster._alpha = true, 1
function cluster:UpdateMinimapConfig() configs = configs + 1 end
cluster.Selection = W.NewWidget("Frame", nil, cluster)
cluster.Selection._mouse = true
cluster.ZoneTextButton = W.NewWidget("Button", nil, cluster)
cluster.ZoneTextButton._mouse = true
local container = W.NewWidget("Frame", nil, cluster)
local minimap = W.NewWidget("Minimap", "Minimap", container)
minimap._zoom, minimap._wheel, minimap._mouse = 2, true, true
minimap:SetSize(198, 198)
minimap:SetPoint("CENTER", container, "CENTER", 0, 0)
function minimap:GetZoom() return self._zoom end
function minimap:SetZoom(step) self._zoom = step end
function minimap:GetZoomLevels() return 6 end
function minimap:SetMaskTexture(mask) self._mask = mask end
function minimap:SetPassThroughButtons(...) self._through = { ... } end
function minimap:PingLocation(x, y) self._ping = { x, y } end
minimap.ZoomIn = W.NewWidget("Button", nil, minimap)
minimap.ZoomIn._mouse = true
local backdrop = W.NewWidget("Frame", "MinimapBackdrop", minimap)
rawset(_G, "MinimapCluster", cluster)
rawset(_G, "Minimap", minimap)
rawset(_G, "MinimapBackdrop", backdrop)
C_Minimap = {
    GetViewRadius = function() return radii[minimap._zoom] end,
    SetDrawGroundTextures = function(on) ground = on end,
    SetIgnoreRotateMinimap = function(on) ignoreRotation = on end,
}

-- The game's map and its panel functions, and the key bindings.
local worldMap = W.NewWidget("Frame", "WorldMapFrame", UIParent)
worldMap:Hide()
worldMap._map = 1415
function worldMap:GetMapID() return self._map end
rawset(_G, "WorldMapFrame", worldMap)
local panels = { shown = 0, hidden = 0 }
local function Run(frame, script) if frame._scripts[script] then frame._scripts[script](frame) end end
ShowUIPanel = function(frame) panels.shown = panels.shown + 1; frame._shown = true; Run(frame, "OnShow") end
HideUIPanel = function(frame) panels.hidden = panels.hidden + 1; frame._shown = false; Run(frame, "OnHide") end
local KEYS = { TOGGLEWORLDMAP = { "M" }, TOGGLEQUESTLOG = { "L" }, TOGGLEMINIMAP = { "CTRL-R" } }
GetBindingKey = function(action) return unpack(KEYS[action] or {}) end
local overrides = {}
SetOverrideBindingClick = function(_, _, key, button, click) overrides[key] = button .. ":" .. click end
ClearOverrideBindings = function() overrides = {} end

-- The terrain's data: a pack with four tiles round the player, one on the other continent, and one on the isle (its
-- middle: row and column 32 of its own grid, 2991).
local folder = io.popen("mktemp -d -t saneui-navigation-XXXXXX"):read("*l")
local packPath = folder .. "/SaneUI_Data_World"
os.execute(("mkdir -p '%s'"):format(packPath))
local ISLE_TILE = 2991 * 4096 + 32 * 64 + 32
local TILES = { [3104] = 801, [3105] = 802, [3168] = 803, [3169] = 804, [4096 + 2080] = 900, [ISLE_TILE] = 950 }
local rows = {}
for key, file in pairs(TILES) do rows[#rows + 1] = ("R[%d] = \"70245\\t\\t%d\""):format(key, file) end
table.sort(rows)
local out = assert(io.open(packPath .. "/Tiles.lua", "w"))
out:write('local S = SaneUI.Core.Data.Add(1, "Tiles", { game = "forever", hash = "00000001", build = 70245, key = "int", fields = { "minimap" }, types = { "int" }, patches = {} })\n'
    .. "if not S then return end\nlocal R = S.rows\n" .. table.concat(rows, "\n") .. "\n")
out:close()
-- The zone's explorable parts: one explored (701, 702), one not yet (711), one explored that shows only under the mouse (703).
out = assert(io.open(packPath .. "/Overlays.lua", "w"))
out:write('local S = SaneUI.Core.Data.Add(1, "Overlays", { game = "forever", hash = "00000002", build = 70245, key = "int", '
    .. 'fields = { "map", "x", "y", "width", "height", "files", "flags" }, types = { "int", "int", "int", "int", "int", "list int", "int" }, patches = {} })\n'
    .. "if not S then return end\nlocal R, I = S.rows, S.index\n"
    .. 'R[11] = "70245\\t\\t1429\\t100\\t50\\t300\\t200\\t701\\030702"\n'
    .. 'R[12] = "70245\\t\\t1429\\t600\\t300\\t200\\t200\\t711"\n'
    .. 'R[13] = "70245\\t\\t1429\\t0\\t0\\t64\\t64\\t703"\n'
    .. 'I.byMap = {}\nI.byMap[1429] = "11\\03012\\03013"\n')
out:close()
-- What the map shows of Core's data: an innkeeper who sells food, a rare, a creature that is neither, a herb; a
-- dungeon's entrance and a mailbox; a boat from Elwynn to the other continent; a flight; a boat's way round (the
-- game's path: a dock in Elwynn's east hall, x -8600 and y -450, a leap onto Kalimdor, a dock there, a leap back); a
-- zeppelin's way round to the isle (a tower in the east hall, x -8650 and y -400, a leap onto the isle's world map
-- 2991, a tower there, x -1000 and y 0, a leap back), its docks on the maps too.
local function Set(file, name, hash, key, fields, types, body)
    local handle = assert(io.open(file, "w"))
    handle:write(('local S = SaneUI.Core.Data.Add(1, "%s", { game = "forever", hash = "%s", build = 70245, key = "%s", '
        .. 'fields = { %s }, types = { %s }, patches = {} })\n'):format(name, hash, key, fields, types)
        .. "if not S then return end\nlocal R, I = S.rows, S.index\n" .. body)
    handle:close()
end
Set(packPath .. "/NPCs.lua", "NPCs", "00000003", "int", '"name", "services", "rank", "goods"', '"text", "list text", "text", "list text"',
    'R[69] = "70245\t\tAn Innkeeper\tinnkeeper\030vendor\tnormal\tfood"\n'
    .. 'R[70] = "70245\t\tAn Old Rare\t\trare\t"\n'
    .. 'R[71] = "70245\t\tA Wolf\t\tnormal\t"\n')
Set(packPath .. "/Objects.lua", "Objects", "00000004", "int", '"name", "kind"', '"text", "text"',
    'R[1617] = "70245\t\tSilverleaf\therb"\n')
Set(packPath .. "/Places.lua", "Places", "00000005", "int", '"kind", "name", "point", "to", "levelMin", "levelMax"',
    '"text", "text", "point", "int", "int", "int"',
    'R[1] = "70245\t\tdungeon\tThe Mines\t1429\03130\03130\t500\t18\t23"\n'
    .. 'R[2] = "70245\t\tmailbox\t\t1429\03170\03170\t\t\t"\n')
-- The boat's way round has its docks on the maps too: in the east hall, and on Kalimdor in the game's area 12.
Set(packPath .. "/Travel.lua", "Travel", "00000006", "int",
    '"kind", "name", "from", "to", "fromNode", "toNode", "length", "path", "docks", "dockAreas"',
    '"text", "text", "point", "point", "int", "int", "number", "list tuple(x:number,y:number,map:int,stay:number,jump:bool)", '
    .. '"list point", "list int"',
    'R[1] = "70245\t\tboat\tTo the west\t1429\03190\03190\t1414\03150\03150\t\t\t"\n'
    .. 'R[2] = "70245\t\tflight\t\t\t\t2\t5\t6000"\n'
    .. 'R[3] = "70245\t\tboat\t\t\t\t\t\t3898.1\t-8600\031-450\0310\03160\030-8000\031-2000\0305000\031-9000\0311\031\0311'
    .. '\0306000\031-9500\031\03160\0305000\031-9000\030-8000\031-2000\0310\031\0311'
    .. '\t1429\03172.5\0316.7\0301414\03189.6\03135\t0\03012"\n'
    .. 'R[4] = "70245\t\tzeppelin\t\t\t\t\t\t\t-8650\031-400\0310\03130\030-8000\031500\030-500\0310\0312991\031\0311'
    .. '\030-1000\0310\031\03130\030-500\0310\030-8000\031500\0310\031\0311\t1429\03170\03110\0302521\03150\03180\t0\0300"\n'
    .. 'I.byFromNode = {}\nI.byFromNode[2] = "2"\nI.byKind = {}\nI.byKind.boat = "1\0303"\nI.byKind.flight = "2"\n'
    .. 'I.byKind.zeppelin = "4"\n')
out = assert(io.open(packPath .. "/SaneUI_Data_World.toc", "w"))
out:write("## Title: Data: World\n## LoadOnDemand: 1\n## X-SaneUI-Sets: NPCs, Objects, Overlays, Places, Tiles, Travel\n## X-SaneUI-Format: 1\n"
    .. "## X-SaneUI-Game: forever\nNPCs.lua\nObjects.lua\nOverlays.lua\nPlaces.lua\nTiles.lua\nTravel.lua\n")
out:close()
W.AddPack(packPath)
local spawnsPath = folder .. "/SaneUI_Data_Spawns"
os.execute(("mkdir -p '%s'"):format(spawnsPath))
Set(spawnsPath .. "/Spawns.lua", "Spawns", "00000007", "text", '"points", "middles"',
    '"list point", "list tuple(map:int,x:number,y:number,size:number)"',
    'R["npc:69"] = "70245\t\t1429\03150\03150\t"\n'
    .. 'R["npc:70"] = "70245\t\t1429\03160\03120\t"\n'
    .. 'R["npc:71"] = "70245\t\t1429\03110\03110\t"\n'
    .. 'R["object:1617"] = "70245\t\t1429\03152\03150\t"\n')
-- The walking data (pack Routes): two tiles round the player, their blocks as the game unpacks them (the
-- encoding stand-ins below hand back these tables). Tile 3104 (its north west corner at u 0, v -8533, 2.08 yards
-- a sample): a west hall (1) and an east hall (3), a wall between them (columns 128 to 159) with a door (2, rows
-- 100 to 119; the three one surface) and a channel of water (4, rows 200 to 209, a surface of its own, its opening
-- into the west hall written from its west side, into the east hall from the hall's west side); a corner of
-- another region nobody can walk to (5). Tile 3105, east of it: one hall (1), open into 3104's east hall.
local routesFolder = io.popen("mktemp -d -t saneui-routes-XXXXXX"):read("*l") -- loaded late: kept until the end
local routesPath = routesFolder .. "/SaneUI_Data_Routes"
os.execute(("mkdir -p '%s'"):format(routesPath))
local walkBlocks = {
    [3104] = { 1,
        { 3, 1, 1,   1, 2, 1,   1, 1, 7 },
        { 0, 0, 128, 256, 160,   128, 100, 32, 20, 160,   160, 0, 96, 240, 160,   128, 200, 32, 10, 160,   240, 248, 8, 8, 160 },
        { 0,   0,   2, 15, 2,   1, 0,   0 } },
    [3105] = { 1, { 1, 1, 1 }, { 0, 0, 64, 256, 160 }, { 1, 14 } },
}
Set(routesPath .. "/Walking.lua", "Walking", "00000008", "int", '"map", "links", "block"', '"int", "list int", "text"',
    'R[3104] = "70245\t\t0\t3105\tblock:3104"\nR[3105] = "70245\t\t0\t3104\tblock:3105"\n')
out = assert(io.open(routesPath .. "/SaneUI_Data_Routes.toc", "w"))
out:write("## Title: Data: Routes\n## LoadOnDemand: 1\n## X-SaneUI-Sets: Walking\n## X-SaneUI-Format: 1\n## X-SaneUI-Game: forever\nWalking.lua\n")
out:close()
W.AddPack(routesPath)
C_EncodingUtil = { DecodeBase64 = function(text) return text end, DecompressString = function(text) return text end,
                   DeserializeCBOR = function(text) return walkBlocks[tonumber(text:match("%d+"))] end }
out = assert(io.open(spawnsPath .. "/SaneUI_Data_Spawns.toc", "w"))
out:write("## Title: Data: Spawns\n## LoadOnDemand: 1\n## X-SaneUI-Sets: Spawns\n## X-SaneUI-Format: 1\n## X-SaneUI-Game: forever\nSpawns.lua\n")
out:close()
W.AddPack(spawnsPath)

W.LoadCore(root)
local Core = SaneUI.Core
-- Saved by an earlier version (the first shape of the settings): the view Overlay, which is gone.
SaneUIDB = { modules = { Navigation = { options = { view = "overlay" } } } }
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Navigation", "SaneUI_Navigation")
W.Fire("ADDON_LOADED", "SaneUI_Navigation")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Navigation == ns and not ns.off, "the module is made and started")
check(type(ns.OUTLINES) == "table", "the zones that have an outline are listed (Outlines.lua)")
check(ns.options.view == "terrain" and ns.View() == "terrain", "a saved view that is gone (Overlay) falls back to Scrying")
local viewOption = Core.Described(ns.name, "view")
check(#viewOption.choices == 2 and viewOption.choices[1][1] == "sketches" and viewOption.choices[2][1] == "terrain"
    and not ns.Offered("atlas"), "without the module Atlas two views are offered: Parchment and Scrying")
ns.options.view = "atlas" -- saved while the module was there
check(ns.View() == "terrain", "a saved Atlas without its module: the map is drawn as Scrying")
ns.Offer()
check(ns.options.view == "terrain", "and the setting falls back to Scrying")
ns.OUTLINES = { [0] = { [1429] = true } } -- the made-up world's zone has one

-- The textures shown, by file.
local function Shown()
    local shown = {}
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._shown and widget._texture then shown[widget._texture] = widget end
    end
    return shown
end
local function Count(shown, low, high)
    local count = 0
    for file in pairs(shown) do if type(file) == "number" and file >= low and file <= high then count = count + 1 end end
    return count
end
local function Overviews(shown, continent, kind)
    local count = 0
    for file in pairs(shown) do
        if type(file) == "string" and file:find("Art\\" .. (kind or "Terrain") .. "\\" .. continent .. "-", 1, true) then
            count = count + 1
        end
    end
    return count
end

-------------------------------------------------------------------------------
--  Coords
-------------------------------------------------------------------------------
local Coords = ns.Coords
local box = Coords.Box(1429)
check(box and box.continent == 0 and box.u == -1000 and box.v == -8500 and box.width == 2000 and box.height == 1500,
    "a map's box in the plane: u = -Y of its left edge, v = X of its top, its size in yards")
local swapped = Coords.Box(9999)
check(swapped and swapped.u == box.u and swapped.v == box.v and swapped.width == box.width and swapped.height == box.height,
    "which of the game's two numbers is north is read from the map itself")
check(Coords.Box(500) == false and Coords.Box(947) == false, "a dungeon and the world map have no box")
local u, v = Coords.ToPlane(box, 0.75, 0.3)
check(near(u, 500) and near(v, -8950), "a map point in the plane: east is +u, north is +v")
local x, y = Coords.ToMap(box, u, v)
check(near(x, 0.75) and near(y, 0.3), "and back")
local column, row = Coords.Tile(u, v)
check(column == 32 and row == 48 and Coords.TileKey(0, column, row) == 3104 and Coords.TileKey(1, 32, 32) == 4096 + 2080,
    "the terrain tile under a point, and its key in the set Tiles")
local left, top = Coords.Corner(column, row)
check(left <= u and u < left + Coords.TILE and top >= v and v > top - Coords.TILE, "a tile's corner: the point lies in its square")
check(Coords.ContinentOf(1429) == 1415 and Coords.ContinentOf(1415) == 1415 and Coords.ContinentOf(947) == nil,
    "the continent a map lies on, by its parents")
local continents = Coords.Continents()
check(#continents == 2 and continents[1] == 1415 and continents[2] == 1414, "the continents, as the game lists them")
-- The world map: Eastern Kingdoms (8000 x 20000 yards) on its x 0.62 to 0.94, y 0.18 to 0.82
local whole = Coords.WorldBox(1415)
check(whole and near(whole.width, 8000 / 0.32) and near(whole.height, 20000 / 0.64) and near(whole.u, -4000 - 0.62 * 25000)
    and near(whole.v, 4000 + 0.18 * 31250), "the world map's box in a continent's plane, from that continent's rectangle on it")
local link = Coords.Link(1414, 1415)
local wx, wy = Coords.ToWorldMap(1414, -12000, 20000) -- Kalimdor's top left corner
local lu, lv = Coords.FromWorldMap(1415, wx, wy)
check(link and near(link.du + link.su * -12000, lu) and near(link.dv + link.sv * 20000, lv) and near(wx, 0.06) and near(wy, 0.18)
    and near(link.su, 0.5) and near(link.sv, 0.5), "one continent's plane in another's, through the world map")
check(Coords.Link(1415, 1415).su == 1 and Coords.Link(1415, 1415).du == 0, "a continent in its own plane: as it is")
check(Coords.PlaneAt(1415, lu + 10, lv - 10) == 1414 and Coords.ZoneAt(1415, 500, -8950) == 1429
    and Coords.ZoneAt(1415, 3000, 0) == nil, "the continent and the zone under a point, as the game's maps say")
local mu, mv = Coords.MapToPlane(1429, 0.75, 0.3, 1415)
check(near(mu, 500) and near(mv, -8950), "a point of a zone in its continent's plane")
local map, pu, pv = Coords.Player()
check(map == 1415 and near(pu, 500) and near(pv, -8950), "where the player is: the continent and the point in its plane")
player.map = 500
local inMap, inU = Coords.Player()
check(inMap == 1415 and inU == nil, "in a dungeon without a box: its continent, no point")
player.map = 1429
-- The isle: on no continent, a plane of its own, linked through the world map like a continent; its own zone.
check(Coords.ContinentOf(2521) == nil and Coords.PlaneOf(2521) == 2521 and Coords.PlaneOf(1429) == 1415
    and Coords.PlaneOf(500) == 1415 and Coords.PlaneOf(947) == nil, "the plane a map lies in: its continent's, else its own")
local planeList = Coords.Planes()
check(#planeList == 3 and planeList[1] == 1415 and planeList[2] == 1414 and planeList[3] == 2521
    and #Coords.Continents() == 2, "the planes: the continents, then the isle; the continents as they were")
local isleLink = Coords.Link(2521, 1415)
local cornerU, cornerV = Coords.FromWorldMap(1415, 0.55, 0.40)
check(isleLink and near(isleLink.du + isleLink.su * -1000, cornerU) and near(isleLink.dv + isleLink.sv * 1000, cornerV),
    "the isle in a continent's plane, through the world map")
local isleU, isleV = Coords.MapToPlane(2521, 0.6, 0.88, 2521)
check(near(isleU, 200) and near(isleV, -1200), "a point of the isle in its own plane")
check(Coords.Alone(2521) and not Coords.Alone(1415) and not Coords.Alone(1429) and not Coords.Alone(947),
    "the isle is a plane of its own that is no continent; a continent and its zone are not")
do
    local isleZones, elwynnZones = Coords.Zones(2521), Coords.Zones(1415)
    check(#isleZones == 1 and isleZones[1].map == 2521 and isleZones[1].box.width == 2000 and #elwynnZones == 1
        and elwynnZones[1].map == 1429, "the isle's zones: itself; a continent's as they were")
    check(Coords.ZoneAt(2521, 0, 0) == 2521 and Coords.ZoneAt(2521, 5000, 0) == nil,
        "the zone under a point of the isle: the isle itself, where it lies")
    local overU, overV = Coords.FromWorldMap(1415, 0.57, 0.42)
    check(Coords.PlaneAt(1415, overU, overV) == 2521 and Coords.PlaneAt(1415, Coords.FromWorldMap(1415, 0.6, 0.1)) == nil,
        "on the world map over the isle: its plane; over the sea none")
    player.map, player.x, player.y = 2521, 0.5, 0.4
    local isleMap, onU, onV = Coords.Player()
    check(isleMap == 2521 and near(onU, 0) and near(onV, 0), "on the isle: its plane and the point in it, as on a continent")
    player.map, player.x, player.y = 1429, 0.75, 0.3
end

-------------------------------------------------------------------------------
--  Camera
-------------------------------------------------------------------------------
local Camera = ns.Camera
local camera = Camera.New()
camera.width, camera.height = 1600, 900
check(camera:Show(1415, 500, -8950), "a camera looks at a continent")
check(near(camera.k, 900 / Camera.START) and camera.level == "zone", "about a zone high, the first time: the zone's level")
check(near(camera.fit, math.min(1600 / 8000, 900 / 20000) * Camera.FIT) and near(camera.far, math.min(1600 / whole.width, 900 / whole.height) * Camera.FIT),
    "it fits the continent, and farther out the world")
local mouseX, mouseY = 200, -100
camera.follow = false
local aimU, aimV = camera.u + mouseX / camera.k, camera.v + mouseY / camera.k
camera:ZoomAt(2, mouseX, mouseY)
check(near(camera.u + mouseX / camera.k, aimU) and near(camera.v + mouseY / camera.k, aimV),
    "the wheel zooms around the point under the mouse: it stays where it is")
camera.follow = true
local middleU = camera.u
camera:ZoomAt(1, mouseX, mouseY)
check(camera.u == middleU, "a view that follows the player zooms around its middle")
camera:ZoomAt(100, 0, 0)
check(camera.k == Camera.NEAR, "no nearer than its own nearest zoom")
camera:ZoomAt(-100, 0, 0)
check(camera.k == camera.far and camera.level == "world", "out to the whole world")
camera:Look(camera.u, camera.v, camera.fit * 0.9)
check(camera.level == "world", "the world is left only past the continent's fit: some slack")
camera:Look(500, -8950, camera.fit * 1.01)
check(camera.level == "continent" and camera.map == 1415, "in again over the same continent: its level")
check(camera:StepOut() and camera.level == "world", "right click on a continent: the world whole")
-- Over Kalimdor on the world map, zoomed in: the camera moves into Kalimdor's plane, the same on the screen.
camera:Look(lu + 2000 * link.su, lv - 2000 * link.sv)
local screenK = camera.fit * 1.2
camera:Look(camera.u, camera.v, screenK)
check(camera.map == 1414 and camera.level ~= "world" and near(camera.k, screenK * link.su),
    "in again over another continent: its plane, at the same size on the screen")
camera:Show(1415, 500, -8950, 0.4)
check(camera.level == "zone" and camera:StepOut() and camera.level == "continent" and near(camera.k, camera.fit),
    "right click in a zone: its continent whole")
check(camera:Fit(1429) and camera.level == "zone" and not camera.follow, "a map fitted into the view: a zone")
check(camera:Fit(947) and camera.level == "world", "and the world")
camera:Show(1415, 0, -5000, 0.5)
camera:Pan(50, -100)
check(near(camera.u, -100) and near(camera.v, -4800) and not camera.follow, "a drag moves the middle against the mouse and stops following")
camera:Pan(-1e6, 0)
check(camera.u == camera.box.u + camera.box.width, "the middle stays on the continent")
-- The isle (2000 x 2500 yards, a yard of it half a yard of the Eastern Kingdoms' on the world map): a zone out to the
-- world, no continent's level between; off it at the world, the world left over a continent at that one's zoom.
do
    local isleView = Camera.New()
    isleView.width, isleView.height = 1600, 900
    check(isleView:Show(2521, 0, 0, 2) and isleView.alone and isleView.level == "zone", "a camera on the isle: a zone")
    isleView:Look(0, 0, isleView.fit)
    check(isleView.level == "zone" and near(isleView.fit, 900 / 2500 * Camera.FIT), "the isle whole: still the zone's level")
    check(isleView:StepOut() and isleView.level == "world", "right click on the isle: the world whole, no continent between")
    isleView:Show(2521, 0, 0, 0.001)
    isleView.follow = false
    check(isleView.map == 2521 and isleView.level == "world", "far out on the isle: the world, in the isle's plane")
    local toIsle = Coords.Link(1415, 2521)
    isleView:Look(toIsle.du + toIsle.su * 500, toIsle.dv + toIsle.sv * -8950)
    check(isleView.map == 1415 and isleView.level == "world", "at the world over the Eastern Kingdoms: their plane, still the world")
    isleView:Look(500, -8950, isleView.fit * 1.2)
    check(isleView.map == 1415 and isleView.level == "continent", "zoomed in: the continent's level, at the continent's own zoom")
    isleView:StepOut()
    isleView:Look(isleLink.du + isleLink.su * 0, isleLink.dv + isleLink.sv * -250, 0.7)
    check(isleView.map == 2521 and isleView.level == "zone" and near(isleView.k, 0.35) and near(isleView.u, 0)
        and near(isleView.v, -250), "in again over the isle from the world: its plane, at the same size on the screen")
    check(camera:Fit(2521) and camera.map == 2521 and camera.level == "zone" and camera.alone, "the isle fitted into a view: its plane, a zone")
    camera:Show(1415, 0, -5000, 0.5)
    check(not camera.alone and camera.level == "zone", "and back on a continent: as ever")
end

-------------------------------------------------------------------------------
--  Live
-------------------------------------------------------------------------------
local Live = ns.Live
local lmap, lu2, _, facing = Live.Player()
check(lmap == 1415 and near(lu2, 500) and facing == 1.5, "Live: the player, with the facing")
check(#Live.Group(1429) == 1 and Live.Group(1429)[1].unit == "party1", "Live: the party on a map")
check(Live.Quests(1429)[1].questID == 7 and #Live.Quests(1415) == 0, "Live: the quests on a map")
check(Live.Flights(1429)[1].name == "Goldshire", "Live: the flight points")
check(#Live.Vignettes(1429) == 1 and Live.Vignettes(1429)[1].info.name == "A rare", "Live: rares nearby, where the game places them")
check(Live.Points(1429)[1].name == "A point", "Live: the game's own points")
check(#Live.Explored(1429) == 2 and #Live.Explored(1415) == 0, "Live: the explored parts")
local told = {}
ns.Listen("LIVE", function(what) told[#told + 1] = what end)
W.Fire("QUEST_LOG_UPDATE")
W.Fire("QUEST_POI_UPDATE")
W.Fire("QUEST_LOG_UPDATE")
check(#told == 0, "a burst of the game's events: nothing at once")
W.Wait(0)
check(#told == 1 and told[1] == "quests", "and one message on the next frame")

-------------------------------------------------------------------------------
--  The window, the minimap taken
-------------------------------------------------------------------------------
local Window, Canvas, Hybrid = ns.Window, ns.Canvas, ns.Hybrid
check(Window.frame and Canvas.frame and Window.frame:GetFrameStrata() == "LOW", "built at login, in the game's minimap's layer")
check(Hybrid.Taken() and minimap:GetParent() == Canvas.frame and minimap._mask == Hybrid.MASK and not minimap._wheel,
    "the game's minimap is over our map, square, its wheel ours")
check(minimap._through and minimap._through[1] == "LeftButton" and minimap._through[2] == "RightButton",
    "its left and right clicks go through to our map")
check(ground == false and ignoreRotation == true and backdrop._alpha == 0 and minimap.ZoomIn._alpha == 0 and not minimap.ZoomIn._mouse,
    "its ground off, its rotation ignored, its border and zoom buttons out of sight")
check(cluster._alpha == 0 and not cluster._mouse and not cluster.ZoneTextButton._mouse and cluster.Selection._mouse,
    "the rest of the game's minimap out of sight and without clicks, but Edit Mode's selection")
check(minimap._zoom == 2 and Window.small.native == 2, "the small view starts at the step the player had")
radii[0] = 250
W.Fire("PLAYER_ENTERING_WORLD")
check(near(Hybrid.Zoom(0, 200), 100 / 250) and minimap._zoom == 2, "after a loading screen its steps are measured again, its step as it was")
radii[0] = 240
W.Fire("PLAYER_ENTERING_WORLD")

-- The terrain's data arrives after the loading screen.
local Tiles = Core.Data.Set("Tiles")
W.Fire("LOADING_SCREEN_DISABLED")
local steps = Core.Steps.frame
local function Frames(count)
    for _ = 1, count do
        W.Wait(0)
        if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
    end
end
local before = Core.Data.Map():On(1429)
check(before and #before == 0, "Core's places asked for before their packs are there: none yet, the packs asked for")
Frames(16)
os.execute(("rm -rf '%s'"):format(folder))
check(#W.fileErrors == 0, "the pack's file ran" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))
check(Tiles:Ready() and Tiles:Get(3104, "minimap") == 801, "the pack is loaded: the set Tiles answers")

-- Core's places on the map (Data.Map), read once their packs are there: by map, what each is.
local places = Core.Data.Map():On(1429)
local byKey = {}
for _, place in ipairs(places or {}) do byKey[place.key] = place end
check(places and #places == 8 and byKey["npc:69"] and byKey["npc:70"] and byKey["object:1617"] and byKey["place:1"]
    and byKey["place:2"] and byKey["travel:1"] and byKey["travel:3:1"] and byKey["travel:4:1"] and not byKey["npc:71"],
    "Core's places on a map: its NPCs with a service and rares, objects, places and ways; a creature that is neither is not")
check(near(byKey["npc:69"].x, 0.5) and byKey["npc:69"].what.services[1] == "innkeeper" and byKey["npc:70"].what.rare
    and byKey["object:1617"].what == "herb" and byKey["place:1"].what == "dungeon" and byKey["place:1"].to == 500
    and byKey["travel:1"].what == "boat", "each at its point (0 to 1), with what it is")
do
    local onKalimdor = {}
    for _, place in ipairs(Core.Data.Map():On(1414)) do onKalimdor[place.key] = place end
    check(#Core.Data.Map():On(1414) == 2 and onKalimdor["travel:1"] and #Core.Data.Map():On(12345) == 0,
        "a way between two maps stands at both ends; a map without places has none")
    local dock, across = byKey["travel:3:1"], onKalimdor["travel:3:2"]
    check(dock and near(dock.x, 0.725) and near(dock.y, 0.067) and dock.what == "boat" and dock.id == 3
        and #dock.towards == 1 and dock.towards[1].map == 1414 and dock.towards[1].area == 12 and dock.to == 1414
        and across and near(across.x, 0.896) and across.towards[1].map == 1429 and not across.towards[1].area
        and across.to == 1429,
        "a boat at each of its docks, one place each: where it goes from there, with the game's area there")
end
check(Core.Data.Map():Spawns("npc:69")[1429][1][1] == 0.5, "a thing's points by map")

-- Small: 200 x 200, following the player at the game's step 2 (radius 160 yards).
local frame = Canvas.frame
frame._width, frame._height = 200, 200
Canvas.Use(Window.small)
Canvas.Open()
local small = Window.small
local tracker
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget._scripts.OnUpdate then tracker = widget end
end
check(tracker, "the tracker runs while the window shows")
tracker._scripts.OnUpdate(tracker, 0.016)
check(near(small.u, 500) and near(small.v, -8950) and near(small.k, 100 / 160), "the small view follows the player, at the step's zoom")
check(minimap._shown and minimap._width == 200 and minimap._zoom == 2, "the game's minimap shows in its middle, as large as the view")
local shown = Shown()
local arrow
for _, widget in ipairs(W.frames) do if widget._atlas == "UI-WorldMapArrow" then arrow = widget end end
check(arrow and not arrow._shown, "our arrow is out of sight while the game's minimap shows its own")
check(minimap._level == frame:GetFrameLevel() + Hybrid.LEVEL and minimap._strata == frame:GetFrameStrata()
    and arrow._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.marks and Hybrid.LEVEL < Canvas.LEVELS.marks
    and Hybrid.LEVEL > Canvas.LEVELS.art,
    "the game's minimap above the map's layers, in the canvas' layer, under our marks: set each time it is placed")
check(minimap._mask == Hybrid.MASK, "a square view: the game's minimap square")
frame._width = 240
Canvas.Layout()
check(minimap._width == 240 and minimap._height == 240 and near(small.k, 120 / 160),
    "a view wider than high: the game's minimap as large as its longer side, so it covers all of it")
check(minimap._mask == Hybrid.MASKS:format("wide", 26),
    "cut to a band as high as the view (200 of 240: 26 of 32 steps), so nothing of it shows past the window")
check(Hybrid.Mask(100, 300) == Hybrid.MASKS:format("tall", 10) and Hybrid.Mask(300, 300) == Hybrid.MASK
    and Hybrid.Mask(1000, 20) == nil and Hybrid.Mask(320, 10) == Hybrid.MASKS:format("wide", 1),
    "a tall view a band down it; never a band larger than the view; too thin for the narrowest band, none")
frame._width, frame._height = 1000, 20
Canvas.Layout()
check(not minimap._shown, "a view too thin for any band: the game's minimap out of sight, our map alone")
frame._width, frame._height = 200, 200
Canvas.Layout()
check(minimap._shown and minimap._mask == Hybrid.MASK, "square again: shown, square")
check(Count(shown, 801, 804) > 0 and Overviews(shown, 0) > 0, "Scrying under it: the terrain's tiles over its overview")
local cut = shown[801] and shown[801]._mask
check(cut and cut._kind == "MaskTexture" and cut._texture == ns.Terrain.PATH:format(0, 6, 4) and near(cut._width, 8 * 1600 / 3 * small.k),
    "each tile cut at the coast by its block's overview, laid over the whole block: the water cut away alike at every zoom")

-- The wheel walks the game's steps, then our map goes on alone.
frame._scripts.OnMouseWheel(frame, 1)
check(small.native == 3 and near(small.k, 100 / 120) and minimap._zoom == 3, "a notch in: the game's next step")
frame._scripts.OnMouseWheel(frame, -1)
frame._scripts.OnMouseWheel(frame, -1)
frame._scripts.OnMouseWheel(frame, -1)
check(small.native == 0 and near(small.k, 100 / 240), "out to the game's widest step")
frame._scripts.OnMouseWheel(frame, -1)
check(small.native == nil and near(small.k, 100 / 240 / Camera.STEP) and not minimap._shown,
    "out past it: our map alone, a notch farther, the game's minimap out of sight")
tracker._scripts.OnUpdate(tracker, 0.016)
check(arrow._shown and arrow._rotation == 1.5, "our arrow shows instead, turned as the player faces")
frame._scripts.OnMouseWheel(frame, 1)
check(small.native == 0 and minimap._shown, "in again: the game's widest step, its minimap back")

-- A drag: no longer following, the game's minimap goes; it follows again after a while without the mouse.
frame._scripts.OnMouseDown(frame, "LeftButton")
cursorX = cursorX + 30
frame._scripts.OnUpdate(frame, 0.016)
check(not small.follow and not minimap._shown and near(small.u, 500 - 30 / small.k), "a drag: the map moves, it no longer follows")
frame._scripts.OnMouseUp(frame, "LeftButton")
check(not frame._scripts.OnUpdate, "the button up: nothing runs any more")
W.Wait(ns.options.followAgain + 1)
frame._mouseOver = true
tracker._scripts.OnUpdate(tracker, 0.016)
check(not small.follow, "not while the mouse is on the map")
frame._mouseOver = false
W.Wait(0.2)
tracker._scripts.OnUpdate(tracker, 0.016)
tracker._scripts.OnUpdate(tracker, 0.016)
check(small.follow and near(small.u, 500) and minimap._shown, "then it follows again, the game's minimap with it")

-- A plain click on the game's minimap pings; Ctrl and a click puts the map pin there.
cursorX, cursorY = 120, 110
frame._scripts.OnMouseDown(frame, "LeftButton")
frame._scripts.OnMouseUp(frame, "LeftButton")
check(minimap._ping and minimap._ping[1] == 20 and minimap._ping[2] == 10, "a click: the game's ping, where it was clicked")
ctrl = true
cursorX, cursorY = 100, 100
frame._scripts.OnMouseDown(frame, "LeftButton")
frame._scripts.OnMouseUp(frame, "LeftButton")
ctrl = false
check(waypoint and waypoint.uiMapID == 1429 and near(waypoint.position.x, 0.75) and near(waypoint.position.y, 0.3) and not tracked,
    "Ctrl-click: the game's map pin on the zone there, not yet followed, as the game's map does")
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
local pin
for _, widget in ipairs(W.frames) do if widget._kind == "Button" and widget.icon and not widget.disc then pin = widget end end
check(pin and pin._shown and pin.icon._atlas == "Waypoint-MapPin-Untracked", "the pin shows, as the game's")
pin._scripts.OnClick(pin, "LeftButton")
check(tracked, "a click on it: the game's arrow leads there")
ctrl = true
pin._scripts.OnClick(pin, "LeftButton")
ctrl = false
check(waypoint == nil, "Ctrl-click on it: gone")

-- Right click: one map out.
small:Show(1415, 500, -8950, 0.5)
small.native = nil
Canvas.Layout()
check(small.level == "zone", "close in: the zone's level")
frame._scripts.OnMouseDown(frame, "RightButton")
frame._scripts.OnMouseUp(frame, "RightButton")
check(small.level == "continent" and near(small.k, small.fit), "right click: its continent whole")

-- The continent whole: the zone under the mouse lights up, and a click opens it.
local hover, light
cursorX, cursorY = 100 + (0 - small.u) * small.k, 100 + (-9250 - small.v) * small.k
frame._mouseOver = true
frame._scripts.OnEnter(frame)
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget ~= tracker and widget._scripts.OnUpdate then hover = widget end
end
check(hover, "the mouse over the map: a look at what is under it")
hover._scripts.OnUpdate(hover, 0.016)
for _, widget in ipairs(W.frames) do if widget._texture == 4242 then light = widget end end
check(light and light._shown and light._blend == "ADD" and light._coords[2] == 0.75 and light._coords[4] == 0.5
    and near(light._width, 2000 * small.k + Canvas.OVERLAP, 0.01),
    "the zone under it lights up in the game's highlight, added onto the map, as large as the game says")
frame._scripts.OnMouseDown(frame, "LeftButton")
frame._scripts.OnMouseUp(frame, "LeftButton")
check(small.level == "zone" and near(small.u, 0) and near(small.v, -9250) and not small.follow and not light._shown,
    "a click opens it: the zone whole in the view, as the game's map does")
hover._scripts.OnUpdate(hover, 0.016)
check(not light._shown, "at a zone nothing lights up")
frame._mouseOver = false
hover._scripts.OnUpdate(hover, 0.016)
check(not hover._scripts.OnUpdate, "off the map the look stops")
frame._scripts.OnMouseDown(frame, "RightButton")
frame._scripts.OnMouseUp(frame, "RightButton")
check(small.level == "continent", "right click: its continent again")

-------------------------------------------------------------------------------
--  The full screen: the same map, its own camera; the views at every zoom
-------------------------------------------------------------------------------
Window.Toggle()
local clock = Window.frame._group
check(clock and clock.playing, "the map key fills the screen")
local holder
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget._width == 1 and widget._height == 1 then holder = widget end
end
check(holder and holder:GetScale() == 1 and frame._parent._groups == nil and not minimap._shown,
    "on its way the map stays in sight, first as the small view showed it; the game's minimap out of sight")
clock:Run(0.5)
local midway = holder:GetScale()
check(midway > 1 and midway < (868 / Camera.START) / small.k, "half way the map has zoomed part of the way to the full view")
frame._width, frame._height = 1600, 868
clock:Run(1)
check(holder:GetScale() == 1, "standing, it is laid out anew for the full view")
local full = Window.full
check(Canvas.camera == full and near(full.u, 500) and near(full.k, 868 / Camera.START), "full: its own camera, at the player the first time")
local bar
for _, widget in ipairs(W.frames) do if widget.key == "terrain" then bar = widget._parent end end
check(bar and bar._shown, "full: the view buttons")
shown = Shown()
check(Count(shown, 801, 804) == 4 and Count(shown, 142901, 142912) == 0 and Count(shown, 141501, 141512) == 0
    and Overviews(shown, 0, "Sketches") == 0, "Scrying up close: the tiles, no map art")
local function Button(key)
    for _, widget in ipairs(W.frames) do if widget.key == key and widget._scripts.OnClick then return widget end end
end
check(Button("terrain")._lit and not Button("sketches")._lit, "the view chosen is lit")
check(Button("sketches")._shown and Button("terrain")._shown and not Button("atlas")._shown
    and Button("terrain")._points[1][2] == Button("sketches"), "two buttons in a row: no Atlas without its module")
Button("sketches")._scripts.OnClick(Button("sketches"))
shown = Shown()
check(ns.options.view == "sketches" and Button("sketches")._lit and Count(shown, 801, 804) == 0
    and Count(shown, 141501, 141512) > 0 and Overviews(shown, 0, "Sketches") > 0 and Count(shown, 142901, 142912) > 0,
    "Sketches: the continent's map, the stitched map over it, the zone's own map over that")
local outline = shown[142901] and shown[142901]._mask
local framed = true
for file = 141501, 141512 do if shown[file] and (not shown[file]._mask or shown[file]._mask._texture ~= ns.Art.EDGE) then framed = false end end
check(outline and outline._texture == ns.Art.OUTLINE:format(1429) and near(outline._width, 2000 * full.k) and framed,
    "the zone's map cut to its outline, laid over its box; the continent's with its paper frame faded off")
check(shown[701] and shown[702] and shown[703] and shown[711] and not shown[711]._vertex and shown[711]._mask == outline,
    "every part of the zone's map, explored or not: the full map, cut to the zone's outline too")
-- Out to the world: every view stays as chosen.
full:Fit(947)
Canvas.Layout()
shown = Shown()
check(Count(shown, 94701, 94712) > 0 and Count(shown, 801, 804) == 0 and Overviews(shown, 0, "Sketches") > 0
    and Overviews(shown, 1, "Sketches") > 0, "Sketches at the world: the world map, both continents stitched over it")
Button("terrain")._scripts.OnClick(Button("terrain"))
shown = Shown()
check(Overviews(shown, 0) > 0 and Overviews(shown, 1) > 0 and Count(shown, 94701, 94712) == 0,
    "Terrain at the world: every continent's overview, no art")
full:Fit(1415)
Button("terrain")._scripts.OnClick(Button("terrain"))
shown = Shown()
check(full.level == "continent" and Overviews(shown, 0) > 0 and Overviews(shown, 1) > 0,
    "at a continent the other one too, where it is in view")
local tilesBefore = ns.Terrain.CAP
full:Show(1415, 500, -8950, 0.3)
ns.Terrain.CAP = 2
Canvas.Layout()
shown = Shown()
check(Count(shown, 801, 804) == 0 and Overviews(shown, 0) > 0, "too many tiles in view: the overview alone, still terrain")
ns.Terrain.CAP = tilesBefore

-------------------------------------------------------------------------------
--  Pins: the game's and Core's, one per thing, filtered, gathered; always over the map
-------------------------------------------------------------------------------
local Pins = ns.Pins
-- The pins drawn now, by key (laid: also those laid out past the canvas' edge, out of sight there).
local function Drawn(laid)
    local list, count = {}, 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Button" and widget.pin and (widget._shown or laid) then
            list[widget.pin.key] = widget
            count = count + 1
        end
    end
    return list, count
end
-- Elwynn whole (2000 x 1500 yards round u 0, v -9250), 0.4 units a yard: the zone's level.
full:Show(1415, 0, -9250, 0.4)
Canvas.Layout()
local pins, count = Drawn()
check(full.level == "zone" and count == 9, "the zone's pins: 10 things, two of them near each other gathered into one")
check(pins["quest:7"] and pins["quest:7"].pin.name == "Wolves Across the Border" and not pins["quest:7"].pin.complete
    and pins["quest:7"].disc._atlas == ns.PinView.DISC and pins["quest:7"].icon._atlas == ns.PinView.IN_PROGRESS,
    "the game's quest on its map, in the game's quest disc and mark")
local questPoint = pins["quest:7"]._points[1]
check(near(questPoint[4], (-200 - 0) * 0.4) and near(questPoint[5], (-9100 + 9250) * 0.4),
    "placed where the game says, on the canvas' holder (a drag moves it with the map)")
check(pins["flight:2"] and pins["flight:2"].icon._atlas == "TaxiNode_Alliance" and not pins["flight:3"],
    "the flight points of the player's side, in the game's own atlas; the other side's not")
check(pins["npc:70"] and pins["npc:70"].pin.live and pins["npc:70"].pin.name == "A rare",
    "the rare the game shows nearby: its own pin, hiding the one of Core's data for the same creature")
check(pins["place:1"] and pins["place:1"].icon._atlas == "Dungeon" and pins["place:1"].pin.to == 500
    and pins["place:2"] and pins["place:2"].icon._atlas == "Mailbox" and pins["travel:1"],
    "Core's places: a dungeon's entrance that opens its map, a mailbox, a boat")
do
    local dock = pins["travel:3:1"]
    check(dock and dock.icon._atlas == "TaxiNode_Continent_Neutral" and dock.pin.name == Pins.WAY_WORDS.boat
        and dock.pin.to == 1414 and dock.pin.click == "map", "a boat's dock, in the game's atlas, opening the map it sails to")
    GameTooltip._lines = nil
    dock._scripts.OnEnter(dock)
    local lines = GameTooltip._lines
    check(lines and lines[1] == "To The Far Shore, Kalimdor" and lines[2] == Pins.TEXT.openMap and not lines[3],
        "its tooltip: where it sails to, the area and the zone in the game's words; the game's own way, not unconfirmed")
end
local marker = pins["gathered:npc:69"]
check(marker and #marker.pin.gathered == 2 and marker.count._text == 2 and not pins["object:1617"],
    "an innkeeper and a herb 40 yards apart cover each other at this zoom: one marker with their number")
check(Canvas.LEVELS.pins > Hybrid.LEVEL and Hybrid.LEVEL > Canvas.MAP and Canvas.LEVELS.pins + ns.PinView.LEVELS + 1 < Canvas.LEVELS.marks
    and pins["quest:7"]._level > pins["place:2"]._level and pins["quest:7"]._level < frame:GetFrameLevel() + Canvas.LEVELS.marks
    and pins["place:2"]._level > frame:GetFrameLevel() + Hybrid.LEVEL,
    "every pin over the map and the game's minimap, a quest over a service, all under the player's arrow")
-- A click on the marker zooms in until they part.
local release = marker._scripts.OnMouseUp
marker._scripts.OnMouseDown(marker, "LeftButton")
release(marker, "LeftButton")
pins, count = Drawn()
check(full.k > 0.4 and pins["npc:69"] and pins["object:1617"] and pins["npc:69"].icon._atlas == "Innkeeper"
    and pins["object:1617"].icon._atlas == "Professions_Tracking_Herb", "a click on it zooms in: they part, each in the game's look")
-- The filter: services off.
local chosen = {}
for key, on in pairs(ns.options.pins) do chosen[key] = on end
chosen.service = nil
Core.Set(ns.name, "pins", chosen)
pins = Drawn()
check(not pins["npc:69"] and not pins["place:2"] and pins["object:1617"] and pins["quest:7"], "the filter: services off, the rest stays")
chosen.service = true
Core.Set(ns.name, "pins", chosen)
-- A tooltip: the quest's objectives as the game tells them.
pins = Drawn()
GameTooltip._lines = nil
pins["quest:7"]._scripts.OnEnter(pins["quest:7"])
check(GameTooltip._lines and GameTooltip._lines[1] == "- Wolf meat: 3/8" and GameTooltip._lines[2] == Pins.TEXT.open,
    "a quest's tooltip: its objectives as the game tells them, and what a click does")
GameTooltip._lines = nil
pins["place:1"]._scripts.OnEnter(pins["place:1"])
check(GameTooltip._lines and GameTooltip._lines[1] == "Level 18 to 23" and GameTooltip._lines[2] == Pins.TEXT.unverified,
    "a place of Core's data: its facts, marked as not yet confirmed by the game")
-- Further out than a zone: only travel and places.
full:Show(1415, 0, -9250, 0.05)
Canvas.Layout()
pins = Drawn()
check(full.level == "continent" and pins["flight:2"] and pins["place:1"] and not pins["quest:7"] and not pins["npc:69"],
    "a continent whole: its flight points, entrances, ways and places; no quests or services")

-- The quest log at the full map's left: zones, quests, objectives; a quest chosen.
local QuestLog = ns.QuestLog
check(QuestLog.Shown(), "full, the quest log stands at the map's left")
local logBox
for _, widget in ipairs(W.frames) do if widget.provider and widget.view and widget.Draw then logBox = widget end end
local rows = logBox:Draw()
check(#rows == 5 and rows[1].row.kind == "header" and rows[2].row.quest == 7 and rows[3].row.kind == "objective"
    and rows[4].row.quest == 8 and rows[4].row.complete and rows[4].state._text == QuestLog.TEXT.complete,
    "its zone, each quest with its objectives; a quest done says so")
check(rows[2].text._text == "[6] Wolves Across the Border", "a quest with its level")
rows[2]._scripts.OnClick(rows[2], "LeftButton")
check(focused == 7 and Canvas.camera == full and full.level == "zone" and near(full.u, -200) and near(full.v, -9100),
    "a click: the game's arrow leads to it, the map shows its place in the middle")
rows = logBox:Draw()
check(rows[2]._lit and not rows[4]._lit, "the chosen quest lit in the list")
rows[2]._scripts.OnEnter(rows[2])
local blob
for _, widget in ipairs(areaFrames) do if widget._shown and widget._quest then blob = widget end end
check(blob and blob._quest == 7 and blob._map == 1429 and near(blob._width, 2000 * full.k),
    "the mouse over it: its area as the game shades it, over its zone")
rows[2]._scripts.OnLeave(rows[2])
-- The quest's pin now on the game's brown disc.
pins = Drawn()
check(pins["quest:7"].pin.focused and pins["quest:7"].disc._atlas == ns.PinView.DISC_FOCUSED, "its pin on the disc of the quest the arrow leads to")
-- Shift and a click watches it; the right button's menu; abandoned only after a question.
IsShiftKeyDown = function() return true end
rows[2]._scripts.OnClick(rows[2], "LeftButton")
IsShiftKeyDown = function() return false end
check(watched[7], "Shift and a click: watched")
local popups = #W.popups
rows[4]._scripts.OnClick(rows[4], "RightButton")
local menu = W.menus[#W.menus]
local abandonItem
for _, item in ipairs(menu or {}) do if item.text == QuestLog.TEXT.abandon then abandonItem = item end end
abandonItem.fn()
check(#W.popups == popups + 1 and abandoned == nil, "the right button's menu: Abandon asks first")
W.popups[#W.popups].data.callback()
check(abandoned == "gone:8", "and abandons once it is answered")
-- Its pin chosen likewise: a click on a quest's pin leads the arrow to it.
focused = 0
pins = Drawn()
pins["quest:7"]._scripts.OnMouseDown(pins["quest:7"], "LeftButton")
pins["quest:7"]._scripts.OnMouseUp(pins["quest:7"], "LeftButton")
check(focused == 7, "a click on a quest's pin: the arrow leads to it")

-- The route's golden line: the parts in view, under the pins.
ns.Route.Show({ legs = { { kind = "walk", points = { { map = 1415, u = 500, v = -8950 }, { map = 1415, u = 0, v = -9250 } } },
                         { kind = "boat", points = { { map = 1415, u = 0, v = -9250 }, { map = 1415, u = 50000, v = 0 } } } } })
local lines = {}
for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown then lines[#lines + 1] = widget end end
check(#lines == 6 and lines[1]._start and near(lines[1]._end[1] - lines[1]._start[1], -500 * full.k),
    "the way drawn: each leg's segments as lines (an edge, the gold, its glint), the second leg reaching into view too")
check(lines[1]._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.route and Canvas.LEVELS.route < Canvas.LEVELS.pins,
    "the line over the map, under the pins")
check(lines[3]._group and lines[3]._group.template == ns.Route.GLINT_PULSE and lines[3]._group.playing
    and not lines[1]._group, "the glint pulses by the template of Route.xml (the game makes that animation only from XML)")
ns.Route.Show(nil)
lines = 0
for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown then lines = lines + 1 end end
check(lines == 0, "no way: no line")
-- What stands on the map keeps inside the canvas by itself: a segment reaching past its edge is cut there (its
-- lines' thickness inside), pins past it are out of sight; the map moved a little (no layout), both follow.
do
    local view, half = Canvas.view, frame._width / 2
    ns.Route.Show({ legs = { { kind = "walk", points = { { map = view.map, u = view.u, v = view.v },
        { map = view.map, u = view.u + 2 * half / view.k, v = view.v } } } } })
    local glint
    for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown and widget._group then glint = widget end end
    local inset = (ns.Route.THICK + 3) / 2
    check(glint and near(glint._start[1], 0) and near(glint._end[1], half - inset)
        and near(glint._coords[2], (half - inset) / ns.Route.PERIOD), "a segment past the canvas' edge: cut at it")
    local u = full.u
    full.u = u + 20 / full.k
    Canvas.Moved()
    check(Canvas.view.u == view.u and near(glint._end[1], half + 20 - inset), "the map moved: the cut follows the edge")
    local right, count = true, 0
    for _, button in pairs(Drawn(true)) do
        count = count + 1
        if button._shown ~= Canvas.Inside(button.x, button.y, button.half) then right = false end
    end
    check(count > 0 and right, "and the pins: each shown while wholly inside")
    full.u = u
    Canvas.Moved()
    ns.Route.Show(nil)
end
frame._mouseOver = true
frame._scripts.OnEnter(frame)
check(ns.Window.handle.options.grip == "hover" and ns.Window.handle.hovered,
    "the mouse on the map: the grip that sizes the small window is seen (Core's grip, outside Edit Mode too)")
frame._mouseOver = false
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget._scripts.OnUpdate and widget ~= tracker then widget._scripts.OnUpdate(widget, 0.016) end
end
check(not ns.Window.handle.hovered, "off the map: unseen again")

-- The party: the game's blip in the class' colour, where the game tells.
IsInGroup = function() return true end
ns.Marks.Group(Canvas.view, GetTime() + 10)
local blip
for _, widget in ipairs(W.frames) do if widget._atlas == ns.Marks.BLIP and widget.x then blip = widget end end
check(blip and blip._vertex and near(blip._vertex[1], 0.78), "the party member on the map, in the class' colour")
check(blip._shown == Canvas.Inside(blip.x, blip.y, ns.Marks.MEMBER / 2), "shown while wholly inside the canvas")
IsInGroup = function() return false end
ns.Marks.Group(Canvas.view, GetTime() + 20)
check(not blip._shown and not blip.x, "out of the group: gone")

-- Zephras Isle, drawn as a continent is, as a zone: standing on it the view follows the player into its plane; its
-- pins, its map in the selector; out to the world and in again over it by a click; the map pin put on it.
do
    local was = { map = full.map, u = full.u, v = full.v, k = full.k }
    player.map, player.x, player.y = 2521, 0.5, 0.4
    full:Show(1415, 0, -9250, 0.5)
    full.follow = true
    Canvas.Layout()
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(full.map == 2521 and full.level == "zone" and near(full.u, 0) and near(full.v, 0) and Canvas.view.map == 2521
        and Canvas.view.continent == 2991 and Canvas.view.zone == 2521 and arrow._shown and near(arrow._points[1][4], 0),
        "standing on the isle: the view follows the player into its plane, a zone, the arrow there")
    local onIsle = Drawn(true)
    local tower = onIsle["travel:4:2"]
    check(tower and tower.icon._atlas == "TaxiNode_Continent_Horde" and tower.pin.home == 2521 and tower.pin.to == 1429
        and near(tower._points[1][5], -1000 * full.k), "its pins: the zeppelin's tower, opening the map it flies to")
    check(not tower._shown and -1000 * full.k + tower.half < -frame._height / 2,
        "laid out past the canvas' bottom edge, the tower is out of sight there")
    GameTooltip._lines = nil
    tower._scripts.OnEnter(tower)
    check(GameTooltip._lines and GameTooltip._lines[1] == "To Elwynn Forest", "its tooltip: where it flies to")
    shown = Shown()
    local isleCut = shown[950] and shown[950]._mask
    check(isleCut and isleCut._texture == ns.Terrain.PATH:format(2991, 4, 4) and Overviews(shown, 2991) > 0,
        "Scrying on the isle: its own tiles, cut by its block's overview, over its overview")
    ns.OUTLINES[2991] = { [2521] = true }
    Button("sketches")._scripts.OnClick(Button("sketches"))
    shown = Shown()
    local framed, cut = 0, 0
    for _, widget in ipairs(W.frames) do
        local file = widget._kind == "Texture" and widget._shown and widget._texture
        if type(file) == "number" and file >= 252101 and file <= 252112 and widget._mask then
            if widget._mask._texture == ns.Art.EDGE then framed = framed + 1 end
            if widget._mask._texture == ns.Art.OUTLINE:format(2521) then cut = cut + 1 end
        end
    end
    check(framed > 0 and cut > 0 and Count(shown, 94701, 94712) > 0 and Overviews(shown, 2991, "Sketches") > 0,
        "Parchment on the isle: the world's map, the isle's own with its paper frame faded off, its stitched map, "
        .. "and its map cut to its outline over them")
    ns.OUTLINES[2991] = nil
    Button("terrain")._scripts.OnClick(Button("terrain"))
    local selector, zones
    for _, widget in ipairs(W.frames) do
        if widget._generator then
            widget:GenerateMenu()
            if widget._items[1] and widget._items[1].text == "#947" then selector = widget end
        end
    end
    for _, widget in ipairs(W.frames) do
        if widget._generator and widget._points[1] and widget._points[1][2] == selector then zones = widget end
    end
    local listed = selector and selector._items or {}
    check(#listed == 4 and listed[2].text == "#1415" and listed[3].text == "Kalimdor" and listed[4].text == "Zephras Isle"
        and listed[4].checked() and selector._override == "Zephras Isle",
        "the map selector: the world, the continents, then the isle, which it says the map shows")
    zones:GenerateMenu()
    check(#zones._items == 1 and zones._items[1].text == "Zephras Isle" and zones._items[1].checked()
        and zones._override == "Zephras Isle", "its zones: the isle itself")
    frame._scripts.OnMouseDown(frame, "RightButton")
    frame._scripts.OnMouseUp(frame, "RightButton")
    check(full.level == "world" and not full.follow, "right click on the isle: the world whole")
    local link = Coords.Link(2521, full.map)
    cursorX = 800 + (link.du + link.su * 0 - full.u) * full.k
    cursorY = 434 + (link.dv + link.sv * -250 - full.v) * full.k
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    check(full.map == 2521 and full.level == "zone" and near(full.u, 0) and near(full.v, -250),
        "a click on the isle at the world opens it, as the game's map does")
    ctrl = true
    cursorX, cursorY = 800 + 100 * full.k, 434
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    ctrl = false
    check(waypoint and waypoint.uiMapID == 2521 and near(waypoint.position.x, 0.55) and near(waypoint.position.y, 0.5),
        "Ctrl-click on the isle: the map pin on it")
    waypoint = nil
    player.map, player.x, player.y = 1429, 0.75, 0.3
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = false
    Canvas.Layout()
end

-------------------------------------------------------------------------------
--  The view Atlas: the module SaneUI_Atlas, found at login, loaded when first drawn
-------------------------------------------------------------------------------
local Painted = ns.Painted
-- The module's index, as dev/tools/atlas writes it with the art: four levels; around the player (row 195,
-- column 131 at level 0) every block but the player's own; lines the reading passes over.
local atlasFolder = io.popen("mktemp -d -t saneui-atlas-XXXXXX"):read("*l")
out = assert(io.open(atlasFolder .. "/Index.lua", "w"))
out:write([[
local _, ns = ...
ns.INDEX = { levels = 4,
    [0] = {
        [0] = { [194] = "125-140", [195] = "125-130,132-140", [196] = "125-140", [197] = "125 - 140",
                [198] = "125-140,x,7-", [199] = "125-140", [300] = "1-2", row = "1", [190] = 5 },
        [1] = { [96] = "60-70", [97] = "60-70", [98] = "60-70", [99] = "60-70" },
        [2] = { [47] = "30-35", [48] = "30-35", [49] = "30-35", [50] = "30-35" },
        [3] = { [23] = "14-18", [24] = "14-18", [25] = "14-18" },
        [9] = { [1] = "1" },
    },
    [1] = { [0] = { [128] = "128,250-300" } },
    oops = { [0] = { [1] = "1" } },
}
]])
out:close()
-- In the addon list, switched off for this character: not offered.
local atlasAddon = { name = "SaneUI_Atlas", title = "Atlas", metadata = { Title = "Atlas", LoadOnDemand = "1" },
                     loadable = false, reason = "DEMAND_LOADED", enabled = 0 }
W.addons[#W.addons + 1] = atlasAddon
check(not Painted.Find() and not ns.Offered("atlas"), "the module Atlas switched off for this character: not offered")
-- Switched on, but the game cannot load it: offered at first, then Scrying again once it was tried.
atlasAddon.enabled = 2
check(Painted.Find() and ns.Offered("atlas"), "the module Atlas in the addon list, switched on: found without loading it")
ns.Offer()
check(#viewOption.choices == 3 and viewOption.choices[3][1] == "atlas" and Button("atlas")._shown
    and Button("atlas")._points[1][2] == Button("terrain") and not W.loaded.SaneUI_Atlas,
    "with the module three views are offered: its button after Scrying's, its choice; nothing loaded yet")
Button("atlas")._scripts.OnClick(Button("atlas"))
shown = Shown()
check(ns.options.view == "atlas" and not Painted.Offered() and ns.View() == "terrain" and Count(shown, 801, 804) == 4,
    "the module cannot be loaded: the map shows Scrying at once")
check(Core.errors["Navigation: atlas"] and Core.errors["Navigation: atlas"].text:find("could not be loaded (CORRUPT)", 1, true),
    "the problem is kept and told")
W.Wait(0)
check(ns.options.view == "terrain" and not Button("atlas")._shown and #viewOption.choices == 2 and Button("terrain")._lit,
    "on the next frame its button and choice go, the setting is Scrying again")
-- The game can load it: drawn over the terrain.
W.onDemand.SaneUI_Atlas = function()
    local private = {}
    assert(loadfile(root .. "/src/Atlas/Atlas.lua"))("SaneUI_Atlas", private)
    assert(loadfile(atlasFolder .. "/Index.lua"))("SaneUI_Atlas", private)
    atlasAddon.loadable, atlasAddon.reason = true, nil
end
check(Painted.Find(), "found again")
ns.Offer()
full:Show(1415, 500, -8950, 2)
Button("atlas")._scripts.OnClick(Button("atlas"))
os.execute(("rm -rf '%s'"):format(atlasFolder))
local Atlas = SaneUI.Atlas
check(W.loaded.SaneUI_Atlas and Atlas and not Atlas.off and Atlas.Ready() and Painted.Ready() and Button("atlas")._lit,
    "the view Atlas drawn the first time: the module loaded, its index read (SaneUI.Atlas)")

-- Its index and its grid.
check(Atlas.Levels() == 4 and Atlas.INDEX == nil, "the index read: its levels, its strings let go")
local function Has(continent, level, row, column) return Atlas.Has(Atlas.Key(continent, level, row, column)) end
check(Has(0, 0, 194, 125) and Has(0, 0, 194, 140) and Has(0, 0, 195, 130) and not Has(0, 0, 195, 131) and Has(0, 0, 195, 132)
    and not Has(0, 0, 194, 124) and not Has(0, 0, 194, 141), "single columns and ranges; a block not listed is not there")
check(Has(0, 0, 197, 133) and Has(0, 0, 198, 125) and not Has(0, 0, 198, 7) and not Has(0, 0, 190, 5),
    "spaces in a range are read, what is no column or range is passed over")
check(not Has(0, 9, 1, 1) and Has(1, 0, 128, 128) and Has(1, 0, 128, 255) and not Has(1, 0, 128, 256) and not Has(0, 0, 1, 1),
    "a level past the index' levels, columns past the grid, rows past it and keys that are no continent: passed over")
check(Atlas.Key(0, 0, 0, 1) ~= Atlas.Key(0, 0, 1, 0) and Atlas.Key(1, 0, 0, 0) ~= Atlas.Key(0, 1, 0, 0)
    and Atlas.Key(0, 15, 255, 255) < Atlas.Key(1, 0, 0, 0), "one number per block")
check(near(Atlas.Span(0), 1600 / 12) and near(Atlas.Span(3), 8 * 1600 / 12) and Atlas.Cells(0) == 256 and Atlas.Cells(2) == 64
    and Atlas.Cells(9) == 1, "a block spans a quarter tile at level 0, twice as much each level up")
-- The player at x = -8950 (north), y = -500 (west): row 195, column 131 at level 0; the terrain's tile 48, 32 at 2.
local blockRow, blockColumn = Atlas.Cell(0, -8950, -500)
local tileRow, tileColumn = Atlas.Cell(2, -8950, -500)
check(blockRow == 195 and blockColumn == 131 and tileRow == 48 and tileColumn == 32 and select(2, Atlas.Cell(1, -8950, -500)) == 65,
    "the block under a position, counted from the grid's north-west corner as the terrain's tiles")
local cornerX, cornerY = Atlas.Corner(0, 195, 131)
check(cornerX >= -8950 and cornerX - Atlas.Span(0) < -8950 and cornerY >= -500 and cornerY - Atlas.Span(0) < -500
    and Atlas.File(0, 3, 24, 16) == "Interface\\AddOns\\SaneUI_Atlas\\Art\\0\\3\\24_16",
    "a block's north-west corner holds the position; its file")

-- The level a zoom draws: the coarsest whose art has as many pixels a yard as the screen (3.84 at level 0).
check(Painted.Level(5, 4, 512, Atlas.Span) == 0 and Painted.Level(3.84, 4, 512, Atlas.Span) == 0
    and Painted.Level(1.9, 4, 512, Atlas.Span) == 1 and Painted.Level(1, 4, 512, Atlas.Span) == 1
    and Painted.Level(0.9, 4, 512, Atlas.Span) == 2 and Painted.Level(0.01, 4, 512, Atlas.Span) == 3
    and Painted.Level(0.01, 2, 512, Atlas.Span) == 1, "the level for a zoom: never finer than needed, never past the last")

-- Drawn: at 2 units a yard on a screen of 2160 pixels for 768 units, 5.6 pixels a yard: level 0, level 1 under it.
local function Blocks(shownNow, level)
    local list = {}
    for file, texture in pairs(shownNow) do
        local row, column = tostring(file):match("^Interface\\AddOns\\SaneUI_Atlas\\Art\\0\\" .. level .. "\\(%d+)_(%d+)$")
        if row then list[row .. "_" .. column] = texture end
    end
    return list
end
local function Size(list) local n = 0 for _ in pairs(list) do n = n + 1 end return n end
shown = Shown()
local fine, coarse = Blocks(shown, 0), Blocks(shown, 1)
check(Count(shown, 801, 804) == 4 and Size(fine) == 4 * 9 - 1 and fine["195_130"] and not fine["195_131"] and not fine["193_130"]
    and coarse["97_65"] and Size(Blocks(shown, 2)) == 0, "Atlas: the terrain, over it every listed block of level 0 in view, level 1 under them")
local block = fine["195_130"]
check(block._sublevel == 1 and coarse["97_65"]._sublevel == 0 and near(block._points[1][4], (266 + 2 / 3 - 500) * 2)
    and near(block._points[1][5], (-8933 - 1 / 3 + 8950) * 2) and near(block._width, 1600 / 12 * 2 + Canvas.OVERLAP),
    "each block where its corner lies, as large as its yards; the coarser level under the finer")
full:Show(1415, 500, -8950, 0.5)
Canvas.Layout()
shown = Shown()
check(Size(Blocks(shown, 0)) == 0 and Size(Blocks(shown, 1)) > 0 and Size(Blocks(shown, 2)) > 0,
    "farther out a coarser level, about as many blocks")
Painted.CAP = 60
Canvas.Layout()
shown = Shown()
check(Size(Blocks(shown, 1)) == 0 and Size(Blocks(shown, 2)) > 0 and Size(Blocks(shown, 3)) > 0,
    "more blocks in view than the cap: a coarser level")
Painted.CAP = 400
-- Three times nearer than the other views; back to Scrying, no nearer than its own.
full:ZoomAt(100, 0, 0)
check(near(full.k, Camera.NEAR * 3) and Camera.Near() == 6, "Atlas zooms three times nearer than the other views")
Button("terrain")._scripts.OnClick(Button("terrain"))
check(full.k == Camera.NEAR and Size(Blocks(Shown(), 0)) == 0, "Scrying: its own nearest zoom, no painted blocks")
Button("atlas")._scripts.OnClick(Button("atlas"))
-- The module stood down (an error of its own, caught by Core's guards): Scrying, its button and choice gone.
Atlas.off = true
Canvas.Refresh()
check(ns.View() == "terrain" and Size(Blocks(Shown(), 0)) == 0, "the module stood down: the map shows Scrying")
W.Wait(0)
check(ns.options.view == "terrain" and not Button("atlas")._shown and #viewOption.choices == 2,
    "and its button and choice go")

-- Back to the corner: the small view as it was left.
Window.Toggle()
frame._width, frame._height = 200, 200
Window.frame._group:Run(1)
check(Canvas.camera == small and small.level == "continent", "back small: its own camera, where it was")

-------------------------------------------------------------------------------
--  The game's map and keys
-------------------------------------------------------------------------------
check(overrides.M == "SaneUINavigationKey:map" and overrides.L == "SaneUINavigationKey:quests"
    and overrides["CTRL-R"] == "SaneUINavigationKey:minimap", "the game's map, quest log and minimap keys open ours")
local key = rawget(_G, "SaneUINavigationKey")
key._scripts.OnClick(key, "minimap", true)
key._scripts.OnClick(key, "minimap", false)
check(not Window.frame._shown, "the minimap key hides our window (its release does nothing more)")
key._scripts.OnClick(key, "minimap", true)
check(Window.frame._shown, "and shows it again")
-- Another way to the game's map: closed on the next frame, ours opened at its map.
worldMap._map = 1429
ShowUIPanel(worldMap)
check(worldMap._shown and worldMap._alpha == 0, "the game's map shows: out of sight at once")
W.Wait(0)
check(not worldMap._shown and worldMap._alpha == 1 and panels.hidden == 1, "on the next frame: closed by the game's panel function")
check(full.level == "zone" and near(full.u, 0) and Window.frame._group.playing, "ours opens, at the zone it was asked for")
Window.frame._group:Run(1)
-- In a fight the game's map stays.
W.combat = true
ShowUIPanel(worldMap)
W.Wait(0)
check(worldMap._shown and worldMap._alpha == 1, "in a fight: the game's map stays open, as the game's")
W.combat = false
HideUIPanel(worldMap)
-- The switch Show the game's map: no longer caught, its keys the game's.
Core.Set(ns.name, "nativeMap", true)
check(overrides.M == nil and overrides["CTRL-R"], "Show the game's map: its keys are the game's again")
ShowUIPanel(worldMap)
W.Wait(0)
check(worldMap._shown, "and it opens as the game's")
HideUIPanel(worldMap)
Core.Set(ns.name, "nativeMap", false)

-- The switch Show the game's minimap: given back, exactly (the map back in its corner first).
Window.Toggle()
Window.frame._group:Run(1)
check(not Window.handle.edge.away, "back in its corner")
Core.Set(ns.name, "nativeMinimap", true)
check(not Hybrid.Taken() and minimap:GetParent() == container and minimap._wheel and #minimap._through == 0
    and ground == true and ignoreRotation == false and configs > 0, "Show the game's minimap: its place, wheel, clicks, ground, rotation and mask back")
check(cluster._alpha == 1 and cluster._mouse and cluster.ZoneTextButton._mouse and backdrop._alpha == 1 and minimap.ZoomIn._mouse,
    "its cluster, border and buttons back")
check(overrides["CTRL-R"] == nil, "and its key")
check(Window.frame._shown and Window.frame._alpha == 0 and not Canvas.frame._mouse and not Canvas.frame._wheel and not Canvas.Laid(),
    "the small window rests out of sight, lets the mouse through to the game's minimap and holds no texture")
key._scripts.OnClick(key, "minimap", true)
check(Window.frame._shown, "the game's minimap key is the game's: our resting window stays")
-- The corner still fills the screen with our map, and it rests again once it is back.
Window.Toggle()
check(Window.frame._alpha == 1 and Canvas.frame._mouse, "the corner: our map comes into sight on its way to the full screen")
Window.frame._group:Run(1)
check(Canvas.camera == full and Canvas.Laid() and Window.frame._alpha == 1, "and stands full, laid out")
Window.Toggle()
Window.frame._group:Run(1)
check(Window.frame._alpha == 0 and not Canvas.frame._mouse and not Canvas.Laid(), "back in its corner it rests again")
-- Edit Mode shows it, to be arranged.
EventRegistry:TriggerEvent("EditMode.Enter")
check(Window.frame._alpha == 1 and Canvas.Laid(), "in Edit Mode it is in sight")
EventRegistry:TriggerEvent("EditMode.Exit")
check(Window.frame._alpha == 0 and not Canvas.Laid(), "and rests again once Edit Mode closes")
Core.Set(ns.name, "nativeMinimap", false)
check(Hybrid.Taken() and Window.frame._alpha == 1 and Canvas.frame._mouse and Canvas.Laid(), "off again: taken again, our small window back")

-- The dropdown Classic windows: both kept choices, ticked while chosen, chosen again to come back.
Window.Toggle()
Window.frame._group:Run(1)
local classicMenu = Window.handle.edge.classic
check(classicMenu and classicMenu:IsShown() and #classicMenu._items == 2 and classicMenu._items[1].checked() == false
    and classicMenu._items[2].checked() == false, "full, the dropdown Classic windows: the game's minimap and map, neither chosen")
classicMenu._items[2].fn()
check(ns.options.nativeMap and worldMap._shown and Window.handle.edge.away, "the game's map chosen: kept, opened at once, ours goes back")
Window.frame._group:Run(1)
HideUIPanel(worldMap)
check(overrides.M == nil and Window.frame._alpha == 1, "its key is the game's now; our small window stays the minimap")
Window.Toggle()
Window.frame._group:Run(1)
check(classicMenu._items[2].checked() == true, "the corner still fills the screen with ours, the game's map ticked")
classicMenu._items[2].fn()
check(not ns.options.nativeMap and overrides.M == "SaneUINavigationKey:map" and Window.handle.edge.full,
    "chosen again: ours is the map again, the window stays full")
classicMenu._items[1].fn()
Window.frame._group:Run(1)
check(ns.options.nativeMinimap and not Hybrid.Taken() and Window.frame._alpha == 0, "the game's minimap chosen: kept, ours rests")
Core.Set(ns.name, "nativeMinimap", false)

-------------------------------------------------------------------------------
--  Routes: the walking data, the walk between two points, the journey with a flight, a boat, the hearthstone
-------------------------------------------------------------------------------
local Walk, Search, Planner = ns.Walk, ns.Search, ns.Planner
check(Walk.Ready() == false and Core.Data.Set("Walking"):State() == "loading", "the walking data is asked for when first needed")
Frames(4)
check(Walk.Ready(), "and loads (the pack Routes)")
local hall = Walk.Tile(3104)
check(hall and hall.count == 5 and hall.kind[4] == Walk.WATER and hall.region[5] == 7 and select(5, Walk.Rect(hall, 1)) == 40,
    "a tile unpacked: its rectangles, their kinds, regions and heights")
local function Openings(tile, index)
    local list = {}
    Walk.Openings(tile, index, function(side, first, last, next, other) list[#list + 1] = { side, first, last, next.key, other } end)
    table.sort(list, function(a, b) return a[1] * 1000 + a[2] < b[1] * 1000 + b[2] end)
    return list
end
local west, east = Openings(hall, 1), Openings(hall, 3)
check(#west == 2 and west[1][1] == 1 and west[1][2] == 100 and west[1][3] == 119 and west[1][5] == 2
    and west[2][2] == 200 and west[2][3] == 209 and west[2][5] == 4,
    "the west hall: into the door along their shared edge (worked out: one surface), into the channel (written once, from it)")
check(#east == 3 and east[1][1] == 1 and east[1][4] == 3105 and east[1][2] == 0 and east[1][3] == 239
    and east[2][1] == 3 and east[2][5] == 2 and east[3][1] == 3 and east[3][5] == 4,
    "the east hall: into the next tile along all its edge, back into the door and the channel")
check(#Openings(Walk.Tile(3105), 1) == 1 and Openings(Walk.Tile(3105), 1)[1][4] == 3104, "and the next tile's hall back into it")
local s = Walk.SAMPLE
local under = Walk.Under(1415, 50 * s, -8533.33 - 50 * s)
check(#under == 1 and under[1][2] == 1, "the rectangle under a point")
check(select(2, Walk.Nearest(1415, 140 * s, -8533.33 - 205 * s, 40)) == 4
    and select(2, Walk.Nearest(1415, 140 * s, -8533.33 - 205 * s, 40, nil, Walk.LAND)) == 1,
    "the nearest rectangle: in the channel the water's, of land only the west hall's")
-- From the west hall to the east hall, both at row 50: through the door (rows 100 to 119), not through the wall.
local points, cost = Search.Walk(1415, 100 * s, -8533.33 - 50 * s, 200 * s, -8533.33 - 50 * s)
local through = false
for index = 1, #points, 2 do
    local row = (-8533.33 - points[index + 1]) / s
    if row >= 99 and row <= 121 then through = true end
end
check(points and through and cost > 100 * s and #points >= 6, "a walk from hall to hall goes through the door, around the wall")
local ending = Search.Walk(1415, 100 * s, -8533.33 - 50 * s, 244 * s, -8533.33 - 252 * s)
check(ending and (-8533.33 - ending[#ending]) / s <= 240.01, "to a place nobody can walk to: the walk ends where one can, nearest to it")
local far = Search.Walk(1415, 200 * s, -8533.33 - 50 * s, (256 + 30) * s, -8533.33 - 50 * s)
check(far and #far == 4, "into the next tile: a straight walk where nothing is in the way")
-- The journey: the pin far away (Elwynn's south west, 1750 yards), a flight point near the player and one near
-- the pin, both known: walk, fly, walk.
C_TaxiMap.GetTaxiNodesForMap = function(map)
    if map ~= 1415 then return {} end
    return { { nodeID = 2, name = "Near", position = CreateVector2D(0.575, 0.6445), faction = 2, atlasName = "TaxiNode_Alliance" },
             { nodeID = 5, name = "Far", position = CreateVector2D(0.39, 0.699), faction = 0, atlasName = "TaxiNode_Neutral" } }
end
Core.Character(ns.name).flights = { [2] = true, [5] = true }
local shownWay
local show = ns.Route.Show
ns.Route.Show = function(way) shownWay = way return show(way) end
Live.SetWaypoint(1429, 0.05, 0.99)
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
check(shownWay and #shownWay.legs == 3 and shownWay.legs[1].kind == "walk" and shownWay.legs[2].kind == "flight"
    and shownWay.legs[3].kind == "walk", "a pin far away: on foot to a known flight point, the flight, on foot to the pin")
check(#shownWay.legs[1].points >= 2 and near(shownWay.legs[2].points[1].u, 600) and near(shownWay.legs[3].points[2].u, -900),
    "each leg from where it starts to where it ends")
-- Unknown flight points are not flown from: on foot all the way.
Core.Character(ns.name).flights = {}
ns.Planner.Update()
Frames(8)
check(shownWay and #shownWay.legs == 1 and shownWay.legs[1].kind == "walk", "without the flight points known: on foot")
-- A boat's way (Core's set Travel, 3): a dock on each continent; each way between them the wait for it (half its
-- way once round: its sailing at the guessed speed, its stays, its leaps, the one from its last point back to its
-- first) and the trip.
local ship = Planner.Ship(Core.Data.Set("Travel"):Get(3))
local sail, leap = Planner.SAIL, Planner.LEAP
local d12, d34 = math.sqrt(600 ^ 2 + 1550 ^ 2), math.sqrt(1000 ^ 2 + 500 ^ 2)
local round = (d12 + 2 * d34) / sail + 120 + 3 * leap
check(#ship == 2 and ship[1].world == 0 and ship[2].world == 1 and ship[1].ways[ship[2]] and ship[2].ways[ship[1]],
    "a boat's way: a dock on each continent, a way from each to the other")
check(near(ship[1].ways[ship[2]].seconds, round / 2 + (d12 + d34) / sail + leap)
    and near(ship[2].ways[ship[1]].seconds, round / 2 + d34 / sail + 2 * leap),
    "each the wait for it and the trip; back by the leap to its first point")
local three = Planner.Ship({ wait = 600, path = { { x = 0, y = 0, map = 0, stay = 60 }, { x = 1000, y = 0, stay = 60 },
    { x = 2000, y = 0, stay = 60 }, { x = 1000, y = 100 } } })
local speed = (2000 + math.sqrt(1000 ^ 2 + 100 ^ 2)) / (600 - 180 - leap)
check(#three == 3 and near(three[1].ways[three[3]].seconds, 300 + 2000 / speed + 60)
    and near(three[1].ways[three[2]].seconds, 300 + 1000 / speed),
    "three docks: past the one between, its stay counted; its time once round, learnt, sets its speed")
local twice = Planner.Ship({ path = { { x = 0, y = 0, map = 0, stay = 30 }, { x = 500, y = 0 }, { x = 1000, y = 0, stay = 60 },
    { x = 500, y = 50 }, { x = 0, y = 0, stay = 30 } } })
check(#twice == 2 and near(twice[1].ways[twice[2]].seconds - twice[2].ways[twice[1]].seconds,
    (1000 - 2 * math.sqrt(500 ^ 2 + 50 ^ 2)) / sail), "a dock stopped at twice is one dock, left from the stop that sails soonest")
-- A pin on the other continent (Kalimdor, u 9500, v 6500): on foot to the dock, the boat, on foot to the pin.
waypoint = { uiMapID = 1414, position = CreateVector2D(21500 / 24000, 0.3375) }
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
local boat = shownWay and shownWay.legs[2]
check(shownWay and #shownWay.legs == 3 and shownWay.legs[1].kind == "walk" and boat.kind == "boat"
    and shownWay.legs[3].kind == "walk", "a pin across the sea: on foot to the dock, the boat, on foot to the pin")
local crosses = false
for _, point in ipairs(boat and boat.points or {}) do crosses = crosses or point.map == 1414 end
local first, last, ending = boat.points[1], boat.points[#boat.points], shownWay.legs[3].points[#shownWay.legs[3].points]
check(first.map == 1415 and near(first.u, 450) and near(first.v, -8600) and crosses and last.map == 1414
    and near(last.u, 9500) and near(last.v, 6000) and ending.map == 1414 and near(ending.u, 9500) and near(ending.v, 6500),
    "the boat's way from the pier, across its leap onto the other continent, to its dock there; then to the pin")
-- Aboard: at sea on the boat's way, past its dock (x -8300, y -1225): the line is at the boat and stays.
player.x, player.y = 1.1125, -0.2 / 1.5
local before = shownWay
Planner.Track(1415, 1225, -8300, GetTime() + 10)
check(shownWay == before and before.at == 2, "aboard the boat: the line is at its leg, not planned anew")
-- A new pin meanwhile (u 9000, v 7000): planned from where the boat lands, its way kept in front.
waypoint = { uiMapID = 1414, position = CreateVector2D(21000 / 24000, 0.325) }
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
check(shownWay ~= before and #shownWay.legs == 2 and shownWay.legs[1] == boat and shownWay.legs[2].kind == "walk"
    and shownWay.legs[2].points[1].map == 1414 and near(shownWay.legs[2].points[1].u, 9500),
    "a new pin while aboard: planned from where the boat lands")
-- A pin on the isle (u 200, v -1200; the canvas' map pin mark there too): on foot to the zeppelin's tower, the
-- zeppelin, a straight walk to the pin (no walking data there).
player.x, player.y = 0.75, 0.3
waypoint = { uiMapID = 2521, position = CreateVector2D(0.6, 0.88) }
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
local zeppelin = shownWay and shownWay.legs[2]
check(shownWay and #shownWay.legs == 3 and shownWay.legs[1].kind == "walk" and zeppelin.kind == "zeppelin"
    and shownWay.legs[3].kind == "walk", "a pin on the isle: on foot to the tower, the zeppelin, on foot to the pin")
local up, down, walked = zeppelin.points[1], zeppelin.points[#zeppelin.points], shownWay.legs[3].points
check(up.map == 1415 and near(up.u, 400) and near(up.v, -8650) and down.map == 2521 and near(down.u, 0)
    and near(down.v, -1000) and #walked == 2 and walked[2].map == 2521 and near(walked[2].u, 200) and near(walked[2].v, -1200),
    "the zeppelin from its tower onto the isle's plane, then straight to the pin")
check(pin.x and pin._shown == Canvas.Inside(pin.x, pin.y, ns.Marks.PIN / 2), "the map pin's mark on the isle, shown while inside")
-- Standing on the isle: the canvas' tracker hands the planner the player's place in the isle's plane.
player.map, player.x, player.y = 2521, 0.5, 0.4
do
    local isleMap, isleU, isleV = Live.Player()
    Planner.Track(isleMap, isleU, isleV, GetTime() + 20)
end
Frames(8)
check(shownWay and #shownWay.legs == 1 and shownWay.legs[1].kind == "walk" and shownWay.legs[1].points[1].map == 2521
    and near(shownWay.legs[1].points[1].u, 0) and near(shownWay.legs[1].points[1].v, 0),
    "on the isle: off the line, planned again from there, on foot")
player.map, player.x, player.y = 1429, 0.75, 0.3
-- The hearthstone: its place learnt where it is bound, with the game's name of it.
local bindName = "Lakeside Inn"
GetBindLocation = function() return bindName end
player.x, player.y = 0.75, 0.3
W.Fire("HEARTHSTONE_BOUND")
local home = Core.Character(ns.name).hearth
check(home and home.map == 1415 and near(home.u, 500) and near(home.v, -8950) and home.name == bindName,
    "the hearthstone's place: learnt where it is bound")
-- Bound near the pin (Kalimdor, u 9400, v 6400): the hearthstone, then on foot; not while it cools down, nor once bound
-- elsewhere.
Core.Character(ns.name).hearth = { map = 1414, u = 9400, v = 6400, name = bindName }
local cooldown = 0
C_Item.GetItemCount = function(id) return id == Planner.HEARTHSTONE and 1 or 0 end
C_Item.GetItemCooldown = function() return cooldown > 0 and GetTime() or 0, cooldown, 1 end
waypoint = { uiMapID = 1414, position = CreateVector2D(21500 / 24000, 0.3375) }
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
check(shownWay and #shownWay.legs == 2 and shownWay.legs[1].kind == "hearth" and shownWay.legs[1].points[2].map == 1414
    and shownWay.legs[2].kind == "walk", "a pin near the hearthstone's place: the hearthstone, then on foot")
cooldown = 1800
Planner.Update()
Frames(8)
check(shownWay and shownWay.legs[2] and shownWay.legs[2].kind == "boat", "while the hearthstone cools down: the boat")
cooldown, bindName = 0, "Harbour Inn"
Planner.Update()
Frames(8)
check(shownWay and shownWay.legs[2] and shownWay.legs[2].kind == "boat", "bound elsewhere since: the boat")
-- Used: its place is where it brought the character (x 0.5, y 0.5 of Elwynn).
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", Planner.HOMEWARD)
player.x, player.y = 0.5, 0.5
W.Wait(3)
home = Core.Character(ns.name).hearth
check(home.map == 1415 and near(home.u, 0) and near(home.v, -9250) and home.name == "Harbour Inn",
    "the hearthstone's place: learnt where it brought the character")
player.x, player.y = 0.75, 0.3
-- The setting off, or the pin gone: no line.
Core.Set(ns.name, "route", false)
check(shownWay == nil, "the setting Route to the map pin off: no line")
Core.Set(ns.name, "route", true)
Live.ClearWaypoint()
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
check(shownWay == nil, "the pin taken away: no line")
ns.Route.Show = show
os.execute(("rm -rf '%s'"):format(routesFolder))

-- A failure stands the module down: everything given back.
ns.StandDown("a test")
check(ns.off and not Window.frame:IsShown() and not Hybrid.Taken() and next(overrides) == nil and minimap:GetParent() == container,
    "standing down: the window goes, the game's minimap and keys are back")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Navigation: all %d checks passed.\n"):format(passed))
