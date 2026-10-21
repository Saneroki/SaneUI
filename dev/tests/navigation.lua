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
    GetAreaInfo = function(area) return ({ [12] = "The Far Shore", [1519] = "Stormwind City", [1537] = "Ironforge" })[area] end,
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
-- The flight master's: a flight taken, a stop asked for (Core's Data.Trips hooks both once the world is there).
TakeTaxiNode = function() end
TaxiRequestEarlyLanding = function() end
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
    function box:HasScrollableExtent() return self._long or false end -- longer than its room (the test says)
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
-- The finders the game lists for the character (Nodes.lua): one of them on at a time, as the game has it; each
-- switch noted with whether the effect sounds were on at that moment.
local gather = { tracking = { { name = "Find Herbs", spellID = 2383, active = false },
                              { name = "Find Minerals", spellID = 2580, active = false } },
                 switches = {}, dots = {}, asked = 0, speed = 0, plate = W.NewWidget("Frame", nil, UIParent) }
C_Minimap.GetNumTrackingTypes = function() return #gather.tracking end
C_Minimap.GetTrackingInfo = function(index) return gather.tracking[index] end
C_Minimap.SetTracking = function(index, on)
    for each, entry in ipairs(gather.tracking) do
        if each == index then entry.active = on elseif on then entry.active = false end
    end
    gather.switches[#gather.switches + 1] = { index = index, on = on, sounds = C_CVar.GetCVar("Sound_EnableSFX") }
end
-- Its answers to a pretend mouse (Found.lua): every dot within 8 units of the point asked, its middle in the
-- minimap's units from its own middle.
function minimap:GetCenter() return 600, 400 end
function minimap:SetUsingSoftCursor(on) self._soft = on end
function minimap:UpdateMouseoverAtPoint(x, y) self._at, gather.asked = { x - 600, y - 400 }, gather.asked + 1 end
C_TooltipInfo = { GetMinimapMouseover = function()
    local lines = {}
    for _, dot in ipairs(gather.dots) do
        if (dot[1] - minimap._at[1]) ^ 2 + (dot[2] - minimap._at[2]) ^ 2 <= 64 then lines[#lines + 1] = { leftText = dot[3] } end
    end
    return { lines = lines }
end }
W.cvarInfo.Sound_EnableSFX = { default = "1", scope = "account" }
W.cvarInfo.softTargetInteract = { default = "1", scope = "character" }
W.cvarInfo.SoftTargetIconGameObject = { default = "0", scope = "character" }
W.cvarInfo.SoftTargetInteractRange = { default = "10", scope = "character" }
W.cvarInfo.SoftTargetInteractArc = { default = "0", scope = "character" }
W.cvarInfo.rotateMinimap = { default = "0", scope = "character" }
GetUnitSpeed = function() return gather.speed end
IsStealthed = function() return false end
UnitIsDeadOrGhost = function() return false end
UnitCastingInfo = function() return nil end
UnitChannelInfo = function() return nil end
GetLootSourceInfo = function() return nil end
C_Timer.NewTimer = function(delay, fn)
    local timer = {}
    function timer:Cancel() self.cancelled = true end
    C_Timer.After(delay, function() if not timer.cancelled then fn(timer) end end)
    return timer
end
C_Timer.NewTicker = function(every, fn)
    local timer = {}
    function timer:Cancel() self.cancelled = true end
    local function Tick()
        if timer.cancelled then return end
        fn(timer)
        C_Timer.After(every, Tick)
    end
    C_Timer.After(every, Tick)
    return timer
end
-- The thing the game picked for the interact key, and its plate (Sparkles.lua).
UnitIsGameObject = function(unit) return unit == "softinteract" and gather.soft ~= nil end
C_NamePlate = { GetNamePlateForUnit = function(unit) if unit == "softinteract" and gather.soft then return gather.plate end end }

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

-- The terrain's data: a set with four tiles round the player, one on the other continent, and one on the isle (its
-- middle: row and column 32 of its own grid, 2991).
local folder = io.popen("mktemp -d -t saneui-navigation-XXXXXX"):read("*l")
local packPath = folder .. "/World"
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
Set(packPath .. "/NPCs.lua", "NPCs", "00000003", "int", '"name", "services", "rank", "goods", "title"',
    '"text", "list text", "text", "list text", "text"',
    'R[69] = "70245\t\tAn Innkeeper\tinnkeeper\030vendor\tnormal\tfood\t"\n'
    .. 'R[70] = "70245\t\tAn Old Rare\t\trare\t\t"\n'
    .. 'R[71] = "70245\t\tA Wolf\t\tnormal\t\t"\n'
    .. 'R[72] = "70245\t\tA Quest Giver\t\tnormal\t\t"\n'
    .. 'R[73] = "70245\t\tAn Old Friend\t\tnormal\t\t"\n'
    .. 'R[74] = "70245\t\tA Waiting Giver\t\tnormal\t\t"\n'
    .. 'R[75] = "70245\t\tA Teacher\ttrainer\tnormal\t\tWarrior Trainer"\n')
Set(packPath .. "/Objects.lua", "Objects", "00000004", "int", '"name", "kind", "skill", "skillLevel"', '"text", "text", "int", "int"',
    'R[1617] = "70245\t\tSilverleaf\therb\t182\t1"\nR[1731] = "70245\t\tCopper Vein\tore\t186\t1"\n'
    .. 'I.byName = {}\nI.byName.Silverleaf = "1617"\nI.byName["Copper Vein"] = "1731"\n')
-- What a herb and a vein give: the herb; stone first, then the ore (the vein's picture is the ore's).
Set(packPath .. "/Drops.lua", "Drops", "0000000a", "text", '"items"', '"list tuple(item:int,how:text)"',
    'R["object:1617"] = "70245\t\t765\031gather"\nR["object:1731"] = "70245\t\t2835\031gather\0302770\031gather"\n')
Set(packPath .. "/Places.lua", "Places", "00000005", "int", '"kind", "name", "point", "to", "levelMin", "levelMax"',
    '"text", "text", "point", "int", "int", "int"',
    'R[1] = "70245\t\tdungeon\tThe Mines\t1429\03130\03130\t500\t18\t23"\n'
    .. 'R[2] = "70245\t\tmailbox\t\t1429\03170\03170\t\t\t"\n')
-- The boat's way round has its docks on the maps too: in the east hall, and on Kalimdor in the game's area 12.
Set(packPath .. "/Travel.lua", "Travel", "00000006", "int",
    '"kind", "name", "from", "to", "fromNode", "toNode", "length", "path", "docks", "dockAreas", "time", "wait"',
    '"text", "text", "point", "point", "int", "int", "number", "list tuple(x:number,y:number,map:int,stay:number,jump:bool,z:number)", '
    .. '"list point", "list int", "number", "number"',
    'R[1] = "70245\t\tboat\tTo the west\t1429\03190\03190\t1414\03150\03150\t\t\t"\n'
    .. 'R[2] = "70245\t\tflight\t\t\t\t2\t5\t6000"\n'
    .. 'R[3] = "70245\t\tboat\t\t\t\t\t\t3898.1\t-8600\031-450\0310\03160\030-8000\031-2000\0305000\031-9000\0311\031\0311'
    .. '\0306000\031-9500\031\03160\0305000\031-9000\030-8000\031-2000\0310\031\0311'
    .. '\t1429\03172.5\0316.7\0301414\03189.6\03135\t0\03012"\n'
    .. 'R[4] = "70245\t\tzeppelin\t\t\t\t\t\t\t-8650\031-400\0310\03130\030-8000\031500\030-500\0310\0312991\031\0311'
    .. '\030-1000\0310\031\03130\030-500\0310\030-8000\031500\0310\031\0311\t1429\03170\03110\0302521\03150\03180\t0\0300"\n'
    -- Two flights with their ways (Alpha to Beta to Gamma, 1000 yards each) and the tram (2000 yards in 50 seconds, a
    -- train from each station every 120): its entrances on the continent's map, by the player (u 600, v -8900) and far
    -- in the north (u 0, v 0).
    .. 'R[5] = "70245\t\tflight\t\t\t\t20\t21\t1000\t0\0310\0301000\0310"\n'
    .. 'R[6] = "70245\t\tflight\t\t\t\t21\t22\t1000\t1000\0310\0301000\0311000"\n'
    .. 'R[7] = "70245\t\ttram\tDeeprun Tram\t\t\t\t\t2000\t0\0310\031369\0302000\0310'
    .. '\t1415\03157.5\03164.5\0301415\03150\03120\t1519\0301537\t50\t120"\n'
    -- Three lifts, each its car's two ends (the lower first) with their heights, its ride and the time between two
    -- departures from an end, on the city map 1456: on Kalimdor's tile 6177 up the mesa's cliff (8: world x -133.33,
    -- y -800, from 10 to 80 yards) and down into the hall under the courtyard (9: x -400, y -933.33, from 10 to -20);
    -- one on the isle where the walking data has none (10).
    .. 'R[8] = "70245\t\tlift\t\t1456\03140\03156.7\t1456\03140\03156.7\t\t\t70'
    .. '\t-133.33\031-800\0311\031\031\03110\030-133.33\031-800\031\031\031\03180\t\t\t10\t30"\n'
    .. 'R[9] = "70245\t\tlift\t\t1456\03146.7\03170\t1456\03146.7\03170\t\t\t30'
    .. '\t-400\031-933.33\0311\031\031\031-20\030-400\031-933.33\031\031\031\03110\t\t\t3.5\t16"\n'
    .. 'R[10] = "70245\t\tlift\t\t2521\03120\03120\t2521\03120\03120\t\t\t20'
    .. '\t500\031600\0312991\031\031\0310\030500\031600\031\031\031\03120\t\t\t2\t6"\n'
    -- And one on tile 6178 within one region, from a hall up to the courtyard over it (11: x -133.33, y -1333.33,
    -- from -20 to 10 yards), on no zone map.
    .. 'R[11] = "70245\t\tlift\t\t\t\t\t\t30'
    .. '\t-133.33\031-1333.33\0311\031\031\031-20\030-133.33\031-1333.33\031\031\031\03110\t\t\t3.5\t16"\n'
    .. 'I.byFromNode = {}\nI.byFromNode[2] = "2"\nI.byFromNode[20] = "5"\nI.byFromNode[21] = "6"\nI.byKind = {}\n'
    .. 'I.byKind.boat = "1\0303"\nI.byKind.flight = "2\0305\0306"\nI.byKind.tram = "7"\nI.byKind.zeppelin = "4"\n'
    .. 'I.byKind.lift = "8\0309\03010\03011"\n')
W.AddSets(packPath)
local spawnsPath = folder .. "/Spawns"
os.execute(("mkdir -p '%s'"):format(spawnsPath))
Set(spawnsPath .. "/Spawns.lua", "Spawns", "00000007", "text", '"points", "middles"',
    '"list point", "list tuple(map:int,x:number,y:number,size:number)"',
    'R["npc:69"] = "70245\t\t1429\03150\03150\t"\n'
    .. 'R["npc:70"] = "70245\t\t1429\03160\03120\t"\n'
    .. 'R["npc:71"] = "70245\t\t1429\03110\03110\t"\n'
    .. 'R["object:1617"] = "70245\t\t1429\03152\03150\t"\n'
    .. 'R["npc:72"] = "70245\t\t1429\03180\03140\t"\n'
    .. 'R["npc:73"] = "70245\t\t1429\03185\03115\t"\n'
    .. 'R["npc:74"] = "70245\t\t1429\03150\03185\t"\n'
    .. 'R["npc:75"] = "70245\t\t1429\03140\03160\t"\n')
-- The quests they give: one this character can take (100), one it has done (5, doneQuests below).
local questsPath = folder .. "/Quests"
os.execute(("mkdir -p '%s'"):format(questsPath))
Set(questsPath .. "/Quests.lua", "Quests", "00000009", "int", '"name", "minLevel", "startNPCs", "level"',
    '"text", "int", "list int", "int"',
    'R[100] = "70245\t\tA Quest to Take\t1\t72\t5"\nR[5] = "70245\t\tAn Old Quest\t1\t73\t"\n'
    .. 'R[101] = "70245\t\tA Quest for Later\t60\t74\t30"\n'
    .. 'I.byStartNPC = {}\nI.byStartNPC[72] = "100"\nI.byStartNPC[73] = "5"\nI.byStartNPC[74] = "101"\n')
LOCALIZED_CLASS_NAMES_MALE = { WARRIOR = "Warrior", MAGE = "Mage" }
GetQuestGreenRange = function() return 5 end
W.AddSets(questsPath)
-- The indoor map of a building (the set Indoors): one at the player's place (world x -8950, y -500: plane u 500,
-- v -8950, terrain tile 3104), turned 90 degrees so its own axes lie along the plane's, two floors one above the other,
-- and around them a street under the sky (open), as a city is one building.
local indoorsPath = io.popen("mktemp -d -t saneui-indoors-XXXXXX"):read("*l") .. "/Indoors"
os.execute(("mkdir -p '%s'"):format(indoorsPath))
Set(indoorsPath .. "/Indoors.lua", "Indoors", "0000000a", "int", '"groups", "placed", "tiles"',
    '"list tuple(group:int,file:text,left:number,bottom:number,right:number,top:number,low:number,high:number,outdoor:bool,open:bool)", '
    .. '"list tuple(map:int,x:number,y:number,z:number,yaw:number,scale:number)", "list int"',
    'R[500001] = "70245\t\t0\031500001-0\031-10\031-10\03110\03110\031-1\0315\031\031\0301\031500001-1\031-10\031-10\03110\03110\0315\03112\031\031'
    .. '\0302\031500001-2\031-60\031-60\03160\03160\031-1\03112\031\0311'
    .. '\t0\031-8950\031-500\0310\03190\0311\t3104"\nI.byTile = {}\nI.byTile[3104] = "500001"\n')
W.AddSets(indoorsPath)
-- The maps of dungeons the game has none of (the sets Dungeons and Encounters): tested with the dungeons' view.
do
local dungeonsPath = io.popen("mktemp -d -t saneui-dungeons-XXXXXX"):read("*l") .. "/DungeonMaps"
os.execute(("mkdir -p '%s'"):format(dungeonsPath))
-- Deep Halls (instance 90): its upper floor 300 by 200 yards (12 tiles), the lower one 150 by 100 (2 tiles), a
-- boss on each.
local upper = {}
for row = 0, 2 do
    for column = 0, 3 do upper[#upper + 1] = ("1\031%d\031%d\031%d"):format(row, column, 9001 + row * 4 + column) end
end
Set(dungeonsPath .. "/Dungeons.lua", "Dungeons", "0000000b", "int", '"name", "floors", "tiles", "bosses", "enemies"',
    '"text", "list tuple(floor:int,name:text,width:int,height:int,tile:int,north:number,south:number,west:number,east:number)", '
    .. '"list tuple(floor:int,row:int,column:int,file:int)", "list tuple(encounter:int,floor:int,x:number,y:number,display:int)", '
    .. '"list tuple(npc:int,floor:int,x:number,y:number)"',
    'R[90] = "70245\t\tDeep Halls\t1\031Upper\0311002\031668\031256\031100\031-100\031150\031-150'
    .. '\0302\031Lower\0311002\031668\031256\03150\031-50\03175\031-75\t'
    .. table.concat(upper, "\030") .. '\0302\0310\0310\0319101\0302\0310\0311\0319102'
    .. '\t700\0311\0310.25\0310.5\0314203\030701\0312\0310.5\0310.5'
    .. '\t71\0311\0310.75\0310.25\03071\0312\0310.1\0310.9"\n')
Set(dungeonsPath .. "/Encounters.lua", "Encounters", "0000000c", "int", '"name", "instance", "order"', '"text", "int", "int"',
    'R[700] = "70245\t\tThe First Boss\t90\t0"\nR[701] = "70245\t\tThe Second Boss\t90\t1"\n')
-- What the first boss casts and drops (the set Bosses, apart from the game's encounters: not yet confirmed).
Set(dungeonsPath .. "/Bosses.lua", "Bosses", "0000000d", "int", '"abilities", "loot"', '"list int", "list int"',
    'R[700] = "70245\t\t801\030802\t901\030902"\n')
W.AddSets(dungeonsPath)
end
-- The walking data (the set Walking): two tiles round the player, their blocks as the game unpacks them (the
-- encoding stand-ins below hand back these tables). Tile 3104 (its north west corner at u 0, v -8533, 2.08 yards
-- a sample): a west hall (1) and an east hall (3), a wall between them (columns 128 to 159) with a door (2, rows
-- 100 to 119; the three one surface) and a channel of water (4, rows 200 to 209, a surface of its own, its opening
-- into the west hall written from its west side, into the east hall from the hall's west side); a corner of
-- another region nobody can walk to (5). Tile 3105, east of it: one hall (1), open into 3104's east hall. Tile 6176
-- on Kalimdor (its north west corner at u 0, v 0), floors one over the other: a field (1) west of a cave (2, 5
-- yards high) under a hill (3, 40 yards), open into the cave by its mouth (rows 60 to 67) and up the hill by a path
-- (rows 0 to 7); the hill one surface with a field east of it (4), which the cave does not reach; on that field a
-- mesa (5, 80 yards) of a region of its own, nobody can walk onto. Tile 6177 east of it (its own regions, no way
-- across): a field (1, 10 yards high, region 3) and a courtyard (2, the same surface) south east of it; a mesa (3,
-- 80 yards, region 4) beside the field, north of the courtyard; a hall (4, region 5) 20 yards under the courtyard.
-- Tile 6178 east of it: a courtyard (1, 10 yards, region 6) over a hall (2, -20 yards) of the same region (joined to
-- it far off, as the Undercity is to the ruins by its sewers).
local routesFolder = io.popen("mktemp -d -t saneui-routes-XXXXXX"):read("*l") -- kept until the end
local routesPath = routesFolder .. "/Routes"
os.execute(("mkdir -p '%s'"):format(routesPath))
local walkBlocks = {
    [3104] = { 1,
        { 3, 1, 1,   1, 2, 1,   1, 1, 7 },
        { 0, 0, 128, 256, 160,   128, 100, 32, 20, 160,   160, 0, 96, 240, 160,   128, 200, 32, 10, 160,   240, 248, 8, 8, 160 },
        { 0,   0,   2, 15, 2,   1, 0,   0 } },
    [3105] = { 1, { 1, 1, 1 }, { 0, 0, 64, 256, 160 }, { 1, 14 } },
    [6176] = { 1,
        { 1, 1, 1,   1, 1, 1,   2, 1, 1,   1, 1, 2 },
        { 0, 0, 64, 128, 40,   64, 0, 64, 128, 20,   64, 0, 64, 128, 160,   128, 0, 128, 128, 40,   160, 32, 32, 32, 320 },
        { 8, -2, 60, 67, 5, -2, 0, 7, 10,   0,   0,   0,   0 } },
    [6177] = { 1,
        { 2, 1, 3,   1, 1, 4,   1, 1, 5 },
        { 0, 0, 128, 256, 40,   128, 128, 128, 128, 40,   128, 0, 128, 128, 320,   144, 144, 96, 96, -80 },
        { 0, 0, 0, 0 } },
    [6178] = { 1, { 1, 1, 6,   1, 1, 6 }, { 0, 0, 256, 128, 40,   64, 32, 128, 64, -80 }, { 0, 0 } },
}
Set(routesPath .. "/Walking.lua", "Walking", "00000008", "int", '"map", "links", "block"', '"int", "list int", "text"',
    'R[3104] = "70245\t\t0\t3105\tblock:3104"\nR[3105] = "70245\t\t0\t3104\tblock:3105"\nR[6176] = "70245\t\t1\t\tblock:6176"\n'
    .. 'R[6177] = "70245\t\t1\t\tblock:6177"\nR[6178] = "70245\t\t1\t\tblock:6178"\n')
W.AddSets(routesPath)
C_EncodingUtil = { DecodeBase64 = function(text) return text end, DecompressString = function(text) return text end,
                   DeserializeCBOR = function(text) return walkBlocks[tonumber(text:match("%d+"))] end }
W.AddSets(spawnsPath)

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
check(type(ns.COASTS) == "table", "the tiles on a coast are listed (Coasts.lua)")
check(ns.options.view == "terrain" and ns.View() == "terrain", "a saved view that is gone (Overlay) falls back to Scrying")
local viewOption = Core.Described(ns.name, "view")
check(#viewOption.choices == 3 and viewOption.choices[1][1] == "sketches" and viewOption.choices[2][1] == "blend"
    and viewOption.choices[3][1] == "terrain" and not ns.Offered("atlas"),
    "without the module Atlas three views are offered: Parchment, Blended and Scrying")
ns.options.view = "atlas" -- saved while the module was there
check(ns.View() == "terrain", "a saved Atlas without its module: the map is drawn as Scrying")
ns.Offer()
check(ns.options.view == "terrain", "and the setting falls back to Scrying")
ns.OUTLINES = { [0] = { [1429] = true } } -- the made-up world's zone has one
ns.COASTS = {} -- and none of its tiles lies on a coast, but where a check says so

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
-- A battleground's map: hung under a zone of the continent by the game's map tree, its box in a world of its own.
;(function()
    MAPS[1459] = { kind = 6, parent = 1429, continent = 30, top = 500, bottom = -500, left = 400, right = -400 }
    local camera = ns.Camera.New()
    camera.width, camera.height = 200, 200
    camera:Show(1415)
    check(Coords.Box(1459) and Coords.Box(1459).continent == 30 and Coords.PlaneOf(1459) == 1415 and not Coords.InPlane(1459)
        and Coords.InPlane(1429) and Coords.MapToPlane(1459, 0.5, 0.5, 1415) == nil and not camera:Fit(1459)
        and camera:Fit(1429), "a map whose box lies in another instance than its plane: no place there, nor a fit")
    MAPS[1459] = nil
end)()

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

-- Core's data is there from the login, with Core; the map's places are read in steps after the loading screen.
local Tiles = Core.Data.Set("Tiles")
W.Fire("LOADING_SCREEN_DISABLED")
local steps = Core.Steps.frame
local function Frames(count)
    for _ = 1, count do
        W.Wait(0)
        if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
    end
end
check(Core.Data.Map():On(1429) == nil, "Core's places first asked for: nil while they are read")
Frames(16)
os.execute(("rm -rf '%s'"):format(folder))
check(#W.fileErrors == 0, "the set files ran" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))
check(Tiles:Ready() and Tiles:Get(3104, "minimap") == 801, "the set Tiles answers")

-- Core's places on the map (Data.Map), read in steps: by map, what each is.
local places = Core.Data.Map():On(1429)
local byKey = {}
for _, place in ipairs(places or {}) do byKey[place.key] = place end
check(places and #places == 12 and byKey["npc:69"] and byKey["npc:70"] and byKey["object:1617"] and byKey["place:1"]
    and byKey["place:2"] and byKey["travel:1"] and byKey["travel:3:1"] and byKey["travel:4:1"] and not byKey["npc:71"]
    and byKey["npc:72"] and byKey["npc:72"].what.quests[1] == 100 and byKey["npc:73"],
    "Core's places on a map: its NPCs with a service, rares and quest givers (with their quests), objects, places and "
    .. "ways; a creature that is none of them is not")
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
for _, widget in ipairs(W.frames) do if widget._atlas == "UI-WorldMapArrow" and not arrow then arrow = widget end end -- the marks', not a dungeon's
check(arrow and not arrow._shown, "our arrow is out of sight while the game's minimap shows its own")
check(minimap._level == frame:GetFrameLevel() + Hybrid.LEVEL and minimap._strata == frame:GetFrameStrata()
    and arrow._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.marks and Hybrid.LEVEL < Canvas.LEVELS.marks
    and Hybrid.LEVEL > Canvas.LEVELS.art,
    "the game's minimap above the map's layers, in the canvas' layer, under our marks: set each time it is placed")
check(minimap._mask == Hybrid.MASK, "a square view: the game's minimap square")
frame._width = 240
Canvas.Layout()
check(minimap._width == 200 and minimap._height == 200 and near(small.k, 100 / 160) and minimap._mask == Hybrid.MASK
    and minimap._points[1][2] == Canvas.frame and minimap._points[1][1] == "CENTER",
    "a view wider than high: the game's minimap square, as large as its shorter side, in its middle, the game's own "
    .. "square its mask (nothing of it past the window); the map at its scale")
frame._width, frame._height = 1000, 20
Canvas.Layout()
check(minimap._shown and minimap._width == 20, "however thin a view: the square of its shorter side")
frame._width, frame._height = 200, 200
Canvas.Layout()
check(minimap._shown and minimap._mask == Hybrid.MASK, "square again: shown, square")
IsIndoors = function() return true end
W.Fire("ZONE_CHANGED_INDOORS")
Canvas.Layout()
check(minimap._shown and ground == false, "indoors: the game's minimap without its own ground (no indoor plan on black)")
-- Our own indoor map instead: the building the player stands in, the floor at the player's height.
do
    local height, before = 3, UnitPosition
    UnitPosition = function() return -8950, -500, height, 0 end
    Core.Data.Prepare("Indoors")
    Frames(8)
    Canvas.Layout()
    local function Picture(file)
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Texture" and type(widget._texture) == "string" and widget._texture:find(file, 1, true) and widget._shown then
                return widget
            end
        end
    end
    local ground = Picture("Indoors\\500001-0")
    local c = ground and ground._coords
    check(ground and not Picture("Indoors\\500001-1") and not Picture("Indoors\\500001-2") and c and near(c[1], 0) and near(c[2], 0) and near(c[3], 0)
        and near(c[4], 1) and near(c[5], 1) and near(c[6], 0) and near(c[7], 1) and near(c[8], 1)
        and near(ground._width, 20 * Canvas.view.k), "indoors, the building the player stands in: its floor at the "
        .. "player's height, its picture turned with the building, as large as it is")
    height = 8
    ns.Indoors.Track(Canvas.view, GetTime() + 10)
    check(Picture("Indoors\\500001-1") and not Picture("Indoors\\500001-0"), "up the stairs: the floor above")
    -- Out on the street around it (40 yards east in the building's own x): no indoor map, though the game says indoors.
    UnitPosition = function() return -8950, -540, height, 0 end
    ns.Indoors.Track(Canvas.view, GetTime() + 12)
    check(not Picture("Indoors\\500001-1") and not Picture("Indoors\\500001-2"),
        "on a street of the building (a city's): no indoor map, the map's own art")
    UnitPosition = function() return -8950, -500, height, 0 end
    ns.Indoors.Track(Canvas.view, GetTime() + 14)
    check(Picture("Indoors\\500001-1") and not Picture("Indoors\\500001-2"), "back inside: its floor again, the street not drawn")
    ;(function()
        local asked, at = 0, UnitPosition
        UnitPosition = function(...)
            asked = asked + 1
            return at(...)
        end
        ns.Indoors.Track(Canvas.view, GetTime() + 20)
        local still = asked == 1 and Picture("Indoors\\500001-1")
        UnitPosition = function() return -8950, -500, height, 1 end -- the same yards, on the other continent's grid
        ns.Indoors.Track(Canvas.view, GetTime() + 30)
        check(still and not Picture("Indoors\\500001-1") and not Picture("Indoors\\500001-0"),
            "standing still the tracker looks no further; on another continent than the view's: no indoor map")
        UnitPosition = at
    end)()
    IsIndoors = function() return false end
    Canvas.Layout()
    check(not Picture("Indoors\\500001-1"), "outdoors: no indoor map")
    UnitPosition = before
end
IsIndoors = function() return false end
W.Fire("ZONE_CHANGED_INDOORS")
Canvas.Layout()
check(Count(shown, 801, 804) > 0 and Overviews(shown, 0) > 0, "Scrying under it: the terrain's tiles over its overview")
local cut = shown[801] and shown[801]._mask
check(cut and cut._kind == "MaskTexture" and cut._texture == ns.Terrain.PATH:format(0, 6, 4) and near(cut._width, 8 * 1600 / 3 * small.k),
    "each tile cut at the coast by its block's overview, laid over the whole block: the water cut away alike at every zoom")
do
    local coastsBefore = ns.COASTS
    ns.COASTS = { [0] = { [3105] = true } }
    Canvas.Layout()
    shown = Shown()
    local own = shown[802] and shown[802]._mask
    check(own and own._texture == ns.Terrain.COAST:format(3105) and near(own._width, 1600 / 3 * small.k)
        and shown[801]._mask._texture == ns.Terrain.PATH:format(0, 6, 4),
        "a tile on a coast cut by its own finer mask, over the tile alone; the others by their block's")
    ns.COASTS = coastsBefore
    Canvas.Layout()
end

-- The wheel walks the game's steps, then our map goes on alone. Each notch in a frame of its own (W.Wait(0)): two in
-- one frame are laid out once there (below).
frame._scripts.OnMouseWheel(frame, 1)
W.Wait(0)
check(small.native == 3 and near(small.k, 100 / 120) and minimap._zoom == 3, "a notch in: the game's next step")
for _ = 1, 3 do frame._scripts.OnMouseWheel(frame, -1) W.Wait(0) end
check(small.native == 0 and near(small.k, 100 / 240), "out to the game's widest step")
frame._scripts.OnMouseWheel(frame, -1)
W.Wait(0)
check(small.native == nil and near(small.k, 100 / 240 / Camera.STEP) and not minimap._shown,
    "out past it: our map alone, a notch farther, the game's minimap out of sight")
tracker._scripts.OnUpdate(tracker, 0.016)
check(arrow._shown and arrow._rotation == 1.5, "our arrow shows instead, turned as the player faces")
frame._scripts.OnMouseWheel(frame, 1)
W.Wait(0)
check(small.native == 0 and minimap._shown, "in again: the game's widest step, its minimap back")
for _ = 1, 5 do frame._scripts.OnMouseWheel(frame, 1) W.Wait(0) end
check(small.native == 5 and near(small.k, 2), "in to the game's narrowest step")
frame._scripts.OnMouseWheel(frame, 1)
W.Wait(0)
check(small.native == nil and near(small.k, 2 * Camera.STEP) and not minimap._shown,
    "in past it: our map alone, a notch nearer, the game's minimap out of sight")
for _ = 1, 10 do frame._scripts.OnMouseWheel(frame, 1) W.Wait(0) end
check(small.native == nil and small.k == Camera.NEAR and Camera.NEAR == 4 * 2,
    "on in to its own nearest zoom: four times the game's narrowest step")
for _ = 1, 6 do frame._scripts.OnMouseWheel(frame, -1) W.Wait(0) end
check(small.native == nil and small.k > 2, "out again: our map alone while nearer than the narrowest step")
frame._scripts.OnMouseWheel(frame, -1)
W.Wait(0)
check(small.native == 5 and near(small.k, 2) and minimap._shown, "then the game's narrowest step, its minimap back")
for _ = 1, 5 do frame._scripts.OnMouseWheel(frame, -1) W.Wait(0) end
check(small.native == 0, "and out through its steps to the widest")
-- A fast spin: two notches in one frame laid out once there, the first at once (never later), the second added up
-- in the camera and laid out on the next frame.
;(function()
    local placed, place = 0, ns.Terrain.Place
    ns.Terrain.Place = function(...)
        placed = placed + 1
        return place(...)
    end
    frame._scripts.OnMouseWheel(frame, 1)
    local first = placed == 1 and minimap._zoom == 1
    frame._scripts.OnMouseWheel(frame, 1)
    local once = placed == 1 and small.native == 2 and minimap._zoom == 1
    W.Wait(0)
    local later = placed == 2 and minimap._zoom == 2
    W.Wait(0)
    ns.Terrain.Place = place
    check(first and once and later and placed == 2,
        "two notches in one frame: laid out once in it (the first at once), the second on the next frame")
    for _ = 1, 2 do frame._scripts.OnMouseWheel(frame, -1) W.Wait(0) end
    check(small.native == 0 and minimap._zoom == 0, "and back out, a notch a frame")
end)()

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

-- Core's button Sane UI on the game's minimap only while that is the game's own, not inside our map. In an instance,
-- where the game tells no place of the player in our planes: the game's minimap alone, with its own ground. The zone
-- in the middle asked of the game a few times a second, not at each step. A zone entered: the pins placed anew only.
;(function()
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == minimap and widget._kind == "Button" and widget ~= minimap.ZoomIn then sane = widget end
    end
    check(sane and not sane._shown and minimap._shown, "inside our map the game's minimap carries no button Sane UI")
    local step = minimap._zoom
    player.map = 500 -- a dungeon: its map has no box, so the game tells no place of the player in our planes
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(minimap._shown and ground == true and minimap._zoom == step and not Canvas.Laid()
        and Count(Shown(), 801, 804) == 0 and Overviews(Shown(), 0) == 0,
        "in an instance: the game's minimap alone, its own ground on, at the view's step; nothing of ours but the sea")
    IsInGroup = function() return true end
    tracker._scripts.OnUpdate(tracker, 0.016)
    local blips = 0
    for _, widget in ipairs(W.frames) do if widget._atlas == ns.Marks.BLIP and widget.x then blips = blips + 1 end end
    IsInGroup = function() return false end
    check(blips == 0, "nor the party's marks of ours there: the game's minimap shows the party itself")
    frame._scripts.OnMouseWheel(frame, 1)
    W.Wait(0)
    check(minimap._shown and minimap._zoom == step + 1 and ground == true, "the wheel walks its steps there")
    frame._scripts.OnMouseWheel(frame, -1)
    W.Wait(0)
    player.map = 1429
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(minimap._shown and ground == false and minimap._zoom == step and Canvas.Laid() and Count(Shown(), 801, 804) > 0,
        "out of it: its ground off again, our map back under it")
    local asked, at = 0, C_Map.GetMapInfoAtPosition
    C_Map.GetMapInfoAtPosition = function(...)
        asked = asked + 1
        return at(...)
    end
    for _ = 1, 5 do -- five steps within one Canvas.LOOK of the last layout (the test's clock stands still)
        player.x = player.x + 0.00001
        tracker._scripts.OnUpdate(tracker, 0.016)
    end
    local within = asked
    -- A Canvas.LOOK later (the game's clock seen ahead, so the test's own keeps its phase): one more step, one ask.
    local clock = GetTime
    GetTime = function() return clock() + Canvas.LOOK end
    player.x = player.x + 0.00001
    tracker._scripts.OnUpdate(tracker, 0.016)
    local later = asked
    -- Then a step within a LOOK of that ask, over another zone, and the view stands still: the zone it owes asked once
    -- the LOOK has passed, and the map laid out for it.
    C_Map.GetMapInfoAtPosition = function(map, x, y)
        asked = asked + 1
        if map == 1415 then return { mapID = 9999, mapType = 3 } end
        return at(map, x, y)
    end
    player.x = player.x + 0.00001
    tracker._scripts.OnUpdate(tracker, 0.016)
    local owed = asked == later
    GetTime = function() return clock() + 2 * Canvas.LOOK end
    tracker._scripts.OnUpdate(tracker, 0.016)
    local settled = Canvas.view.zone == 9999
    C_Map.GetMapInfoAtPosition, GetTime = at, clock
    player.x = 0.75
    tracker._scripts.OnUpdate(tracker, 0.016) -- the view back on the player
    Canvas.Layout()
    check(within == 0 and later == 1, "following, the zone in the middle asked of the game once a Canvas.LOOK, not at each step")
    check(owed and settled and Canvas.view.zone == 1429,
        "the view stopped within a LOOK of its last ask: the zone it owes asked once the LOOK has passed, laid out for it")
    local placed, pinned, place, pin = 0, 0, ns.Terrain.Place, ns.PinView.Place
    ns.Terrain.Place = function(...)
        placed = placed + 1
        return place(...)
    end
    ns.PinView.Place = function(...)
        pinned = pinned + 1
        return pin(...)
    end
    W.Fire("ZONE_CHANGED")
    W.Wait(0)
    local zoned = placed == 0 and pinned >= 1
    W.Fire("MAP_EXPLORATION_UPDATED")
    W.Wait(0)
    ns.Terrain.Place, ns.PinView.Place = place, pin
    check(zoned and placed == 1, "a zone entered: the pins placed anew, not the whole map; what is explored lays it out")
end)()

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
for _, widget in ipairs(W.frames) do if widget._kind == "Button" and widget.icon and widget._scripts.OnClick then pin = widget end end
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
-- Settings of before: the switch Route to the map pin is the pin filter's kind now, as the minimap's dots are.
do
    local settled = Core.Settle(ns.name, { route = false, pins = { quest = true } })
    check(settled.pins.quest and not settled.pins.route and settled.pins.minimap and settled.route == nil,
        "older settings: a route switched off stays off in the pin filter, the minimap's dots on")
    settled = Core.Settle(ns.name, { pins = { quest = true } })
    check(settled.pins.route and settled.pins.minimap, "a route that was on: on in the pin filter")
    check(settled.pins.log and settled.pins.low and settled.pins.later and not settled.pins.done,
        "the quests split: those in your log as Quests were, the low ones and those for later on")
end
-- The game's minimap's dots on the full map too: around the player at the map's own zoom, its widest step whose
-- square takes at most Hybrid.ROOM of the canvas' shorter side, kept on the player; the pin filter's Minimap dots.
do
    tracker._scripts.OnUpdate(tracker, 0.016)
    local step
    for each = 0, 5 do
        if 2 * radii[each] * full.k <= 868 * Hybrid.ROOM then step = each break end
    end
    local map, u, v = Live.Player()
    check(step and minimap._shown and minimap._zoom == step and near(minimap._width, 2 * radii[step] * full.k)
        and minimap._points[1][2] == holder and near(minimap._points[1][4], (u - Canvas.view.u) * full.k)
        and near(minimap._points[1][5], (v - Canvas.view.v) * full.k) and minimap._mask == Hybrid.MASK,
        "full: the game's minimap around the player at the map's zoom, at the widest step that fits, on the player")
    local chosen = Core.Copy(ns.options.pins)
    chosen.minimap = nil
    Core.Set(ns.name, "pins", chosen)
    check(not minimap._shown and not ns.Pins.Shows("minimap"), "the pin filter's Minimap dots off: not there")
    chosen = Core.Copy(chosen)
    chosen.minimap = true
    Core.Set(ns.name, "pins", chosen)
    check(minimap._shown, "on again: there")
    check(not Hybrid.Ping(0, 0), "a click on the full map is no ping: the game's minimap is not in its middle there")
end
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
check(Button("sketches")._shown and Button("blend")._shown and Button("terrain")._shown and not Button("atlas")._shown
    and Button("blend")._points[1][2] == Button("sketches") and Button("terrain")._points[1][2] == Button("blend"),
    "three buttons in a row: no Atlas without its module")
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
-- Blended: the art over the terrain, faded by the zoom.
check(Canvas.Blend(Canvas.BLEND[1]) == 1 and Canvas.Blend(Canvas.BLEND[2]) == 0
    and near(Canvas.Blend(math.sqrt(Canvas.BLEND[1] * Canvas.BLEND[2])), 0.5),
    "Blended: the art whole far out, gone close in, half at the zoom's middle step between")
do
    Button("blend")._scripts.OnClick(Button("blend"))
    shown = Shown()
    local artLayer = shown[94701] and shown[94701]._parent
    check(ns.options.view == "blend" and Button("blend")._lit and artLayer and artLayer._alpha == 1
        and Overviews(shown, 0) == 0, "Blended at the world: the art alone, as Parchment")
    local high = Canvas.view.span * full.k
    full:Show(1415, 500, -8950, high / 3000)
    Canvas.Layout()
    shown = Shown()
    local faded = Canvas.Blend(Canvas.view.span)
    check(faded > 0 and faded < 1 and near(artLayer._alpha, faded) and Count(shown, 141501, 141512) > 0
        and Overviews(shown, 0) > 0, "Blended between: the terrain under, the art over it, faded")
    full:Show(1415, 500, -8950, high / 800)
    Canvas.Layout()
    shown = Shown()
    check(artLayer._alpha == 0 and Count(shown, 141501, 141512) == 0 and Count(shown, 801, 804) > 0,
        "Blended close in: the terrain alone, the art not drawn")
end
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
-- The pins drawn now, by the thing each stands for (Core's: its thing; a gathered marker: "gathered:" and its first
-- pin's; laid: also those laid out past the canvas' edge, out of sight there).
local function Drawn(laid)
    local list, count = {}, 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Button" and widget.pin and (widget._shown or laid) then
            local pin, first = widget.pin, widget.pin.gathered and widget.pin.gathered[1]
            list[first and "gathered:" .. (first.thing or first.key) or pin.thing or pin.key] = widget
            count = count + 1
        end
    end
    return list, count
end
-- Elwynn whole (2000 x 1500 yards round u 0, v -9250), 0.4 units a yard: the zone's level.
full:Show(1415, 0, -9250, 0.4)
Canvas.Layout()
local pins, count = Drawn()
check(full.level == "zone" and count == 12, "the zone's pins: 13 things, two of them near each other gathered into one")
-- (a function of its own: the main chunk has as many locals as Lua lets it)
;(function()
    -- A thing of Core's data with several points on a map: a pin at each, each its own key, the thing's apart (one
    -- Silverleaf more, 540 yards west of the first; and a mailbox that is an object, in the zone's south west).
    local reader = Core.Data.Map()
    local read = reader.On
    local riding = false
    reader.On = function(self, map)
        local list = read(self, map)
        if map ~= 1429 or not list then return list end
        local more = {}
        for index, place in ipairs(list) do more[index] = place end
        more[#more + 1] = { kind = "object", key = "object:1617", id = 1617, what = "herb", name = "Silverleaf", x = 0.25, y = 0.55 }
        more[#more + 1] = { kind = "object", key = "object:1685", id = 1685, what = "mailbox", name = "Mailbox", x = 0.1, y = 0.9 }
        if riding then
            more[#more + 1] = { kind = "object", key = "object:1617", id = 1617, what = "herb", name = "Silverleaf",
                                x = 0.245, y = 0.5533 }
        end
        return more
    end
    Pins.DataChanged()
    Canvas.Layout()
    local function Pin(thing, small, pu, pv)
        local list = {}
        for _, pin in ipairs(Pins.For(Canvas.view, small, pu, pv)) do
            if (pin.thing or pin.key) == thing then list[#list + 1] = pin end
        end
        return list[1], list
    end
    local _, herbs = Pin("object:1617")
    local alone
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Button" and widget._shown and widget.pin and widget.pin.thing == "object:1617" then alone = widget end
    end
    check(#herbs == 2 and herbs[1].key ~= herbs[2].key and herbs[1].key:find("^object:1617@1429:")
        and alone and (alone.pin.key == herbs[1].key or alone.pin.key == herbs[2].key),
        "a herb at two places on a map: a pin at each, each its own key, the thing's kept apart; the far one drawn alone")
    check(Pin("object:1685", true, -800, -9850) and not Pin("object:1685", true, 800, -8600),
        "a mailbox that is an object: on the small map only near the player, as every service")
    -- The log changed: Core's quest givers read again with what the game tells; its objects, places and ways kept.
    local place, herb, giver, quest = Pin("place:1"), Pin("object:1617"), Pin("npc:72"), Pin("quest:7")
    Pins.Changed("quests")
    check(place and Pin("place:1") == place and herb and Pin("object:1617") == herb and giver and Pin("npc:72") ~= giver
        and quest and Pin("quest:7") ~= quest, "the log changed: the quest givers' pins read again, the rest of Core's kept")
    giver, quest = Pin("npc:72"), Pin("quest:7")
    Pins.Changed("waypoint")
    check(Pin("npc:72") == giver and Pin("quest:7") ~= quest, "the arrow led elsewhere: only what the game tells read again")
    -- One more Silverleaf, 10 yards from the second, in its cell of the gather's grid: it rides with it to the gathering
    -- (not sorted nor gathered on its own), the two one marker, its tooltip counting both.
    riding = true
    Pins.DataChanged()
    Canvas.Layout()
    local _, now = Pin("object:1617")
    local riders = 0
    for _, pin in ipairs(now) do riders = riders + (pin.with and #pin.with or 0) end
    local marker
    for _, widget in ipairs(W.frames) do
        local first = widget._kind == "Button" and widget._shown and widget.pin and widget.pin.gathered and widget.pin.gathered[1]
        if first and first.thing == "object:1617" then marker = widget end
    end
    if marker then marker._scripts.OnEnter(marker) end
    check(#now == 2 and riders == 1 and marker and #marker.pin.gathered == 2 and GameTooltip._text == Pins.TEXT.gathered:format(2),
        "herbs of a kind in one cell of the gather's grid: one goes on, the other rides with it; one marker of both")
    reader.On = read
    Pins.DataChanged()
    Canvas.Layout()
end)()
do
    local giver = pins["npc:72"]
    check(giver and giver.pin.kind == "quest" and giver.pin.offer and giver.icon._atlas == Pins.ICONS.offer
        and giver._alpha == 1 and not giver.pin.grey and not giver.pin.tint and giver.pin.click == "preview"
        and giver.pin.lines[1][1] == "A Quest to Take (level 5)",
        "a quest offer: the game's yellow exclamation mark, not see-through; its tooltip names it")
    local waiting = pins["npc:74"]
    check(waiting and waiting.pin.kind == "later" and not waiting.pin.grey and waiting.pin.tint == Pins.RED
        and waiting.icon._atlas == Pins.ICONS.later
        and waiting.pin.lines[1][1] == "A Quest for Later (level 30)"
        and waiting.pin.lines[2][1]:find(Pins.TEXT.needsLevel:format(60), 1, true),
        "a quest for later: the question mark in red, its tooltip saying why (the level it asks)")
    local laterKind
    for _, kind in ipairs(ns.KINDS) do if kind[1] == "later" then laterKind = kind end end
    check(ns.KindLabel(laterKind) == "|A:questturnin:16:16:0:0:255:51:38|a " .. ns.TEXT.later,
        "the pin filter's row for quests for later: the question mark in red before its words")
    local teacher = pins["npc:75"]
    check(teacher and teacher.pin.kind == "service" and teacher.icon._atlas == "class"
        and teacher.pin.lines[1] == "Warrior Trainer" and not teacher.pin.lines[2],
        "a trainer: its title says what it trains (no plain Trainer), a class's trainer the class book")
    check(not pins["npc:73"], "a giver of quests you have done only: no pin while Done quests is off (the default)")
    local chosen = Core.Copy(ns.options.pins)
    chosen.done = true
    Core.Set(ns.name, "pins", chosen)
    local old = Drawn()["npc:73"]
    check(old and old.pin.kind == "done" and old.pin.grey and old.pin.lines[1] == Pins.TEXT.done
        and old.pin.lines[2][1] == "An Old Quest", "Done quests on: its pin, grey, its tooltip naming the quests you did")
    chosen = Core.Copy(chosen)
    chosen.done = nil
    Core.Set(ns.name, "pins", chosen)
    check(Pins.Standing({ level = 1 }, 999) == "offered", "a quest at your level gives experience")
    UnitLevel = function() return 20 end
    Canvas.Layout()
    check(Pins.Standing({ level = 10 }, 999) == "low" and select(2, Pins.Standing({ level = 10 }, 999)) == Pins.TEXT.low,
        "past the game's green range below you: too low, it gives no experience")
    ;(function()
        -- The game's own trivial range for the player first, as its quest colours ask it; its green range after.
        UnitQuestTrivialLevelRange = function(unit) return unit == "player" and 12 or 0 end
        check(Pins.Standing({ level = 10 }, 999) == "offered",
            "the game's trivial range for you first: a quest ten levels below you still gives experience where it says so")
        UnitQuestTrivialLevelRange = nil
    end)()
    W.Fire("PLAYER_LEVEL_UP")
    W.Wait(0)
    Canvas.Layout()
    local low = Drawn()["npc:72"]
    check(low and low.pin.kind == "low" and low.pin.grey and not low.pin.tint and low.icon._atlas == Pins.ICONS.grey,
        "its quest too low now: the giver's mark grey")
    UnitLevel = function() return 6 end
    W.Fire("PLAYER_LEVEL_UP")
    W.Wait(0)
    Canvas.Layout()
end
check(pins["quest:7"] and pins["quest:7"].pin.name == "Wolves Across the Border" and not pins["quest:7"].pin.complete
    and pins["quest:7"].pin.kind == "log" and pins["quest:7"].icon._atlas == Pins.ICONS.log,
    "a quest in your log on the map where the game says, in progress: the yellow question mark, no disc")
local questPoint = pins["quest:7"]._points[1]
check(near(questPoint[4], (-200 - 0) * 0.4) and near(questPoint[5], (-9100 + 9250) * 0.4),
    "placed where the game says, on the canvas' holder (a drag moves it with the map)")
check(pins["flight:2"] and pins["flight:2"].icon._atlas == "TaxiNode_Alliance" and not pins["flight:3"],
    "the flight points of the player's side, in the game's own atlas; the other side's not")
check(pins["npc:70"] and pins["npc:70"].pin.live and pins["npc:70"].pin.name == "A rare",
    "the rare the game shows nearby: its own pin, hiding the one of Core's data for the same creature")
check(pins["place:1"] and pins["place:1"].icon._atlas == "dungeon" and pins["place:1"].pin.to == 500
    and pins["place:2"] and pins["place:2"].icon._atlas == "mailbox" and pins["travel:1"]
    and pins["npc:70"].icon._atlas == Pins.ICONS.rare,
    "Core's places: a dungeon's entrance that opens its map, a mailbox, a boat; the rare in its kind's icon (a skull)")
-- Alt held over the rare's pin: its 3D model beside the tooltip, by its creature; Alt let go, or the mouse off it: gone.
;(function()
    local rare, alt, asked = pins["npc:70"], false, nil
    local wasAlt = rawget(_G, "IsAltKeyDown")
    IsAltKeyDown = function() return alt end
    W.methods.SetCreature = function(self, npc) asked, self._creature = npc, npc end
    W.methods.ClearModel = function(self) self._creature = nil end
    rare._mouseOver = true
    rare._scripts.OnEnter(rare)
    local model
    for _, widget in ipairs(W.frames) do if widget._kind == "PlayerModel" and widget._parent == UIParent then model = widget end end
    check(not (model and model._shown), "without Alt: the tooltip alone")
    alt = true
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
    for _, widget in ipairs(W.frames) do if widget._kind == "PlayerModel" and widget._parent == UIParent then model = widget end end
    check(model and model._shown and asked == 70 and model._creature == 70 and model._points[1][2] == GameTooltip,
        "Alt held: the rare's 3D model beside the tooltip, the game's model of its creature")
    model._scripts.OnModelLoaded(model)
    check(model:GetAlpha() == 1, "seen once the game has loaded it")
    alt = false
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
    check(not model._shown, "Alt let go: gone")
    alt = true
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
    rare._mouseOver = false
    rare._scripts.OnLeave(rare)
    check(not model._shown, "the mouse off the pin: gone")
    IsAltKeyDown, W.methods.SetCreature, W.methods.ClearModel = wasAlt, nil, nil
end)()
do
    local dock = pins["travel:3:1"]
    check(dock and dock.icon._atlas == "flightmasterferry" and dock.pin.name == Pins.WAY_WORDS.boat
        and dock.pin.to == 1414 and dock.pin.click == "map", "a boat's dock, the game's boat icon, opening the map it sails to")
    GameTooltip._lines = nil
    dock._scripts.OnEnter(dock)
    local lines = GameTooltip._lines
    check(lines and lines[1] == "To The Far Shore, Kalimdor" and lines[2] == Pins.TEXT.openMap and not lines[3],
        "its tooltip: where it sails to, the area and the zone in the game's words; the game's own way, not unconfirmed")
end
local marker = pins["gathered:npc:69"]
check(marker and #marker.pin.gathered == 2 and marker.icon._atlas == "innkeeper" and not marker.count
    and not pins["object:1617"], "an innkeeper and a herb 40 yards apart cover each other at this zoom: one marker in the "
    .. "first one's icon, no number")
check(Canvas.LEVELS.pins > Hybrid.LEVEL and Hybrid.LEVEL > Canvas.MAP and Canvas.LEVELS.pins + ns.PinView.LEVELS + 1 < Canvas.LEVELS.marks
    and pins["quest:7"]._level > pins["place:2"]._level and pins["quest:7"]._level < frame:GetFrameLevel() + Canvas.LEVELS.marks
    and pins["place:2"]._level > frame:GetFrameLevel() + Hybrid.LEVEL,
    "every pin over the map and the game's minimap, a quest over a service, all under the player's arrow")
check(pins["quest:7"]._level > pins["npc:72"]._level and pins["npc:72"]._level > pins["flight:2"]._level
    and pins["flight:2"]._level > pins["place:2"]._level,
    "a higher kind always over a lower one: a quest in your log, a quest to take, a flight point, a service")
-- A click on the marker zooms in until they part.
local release = marker._scripts.OnMouseUp
marker._scripts.OnMouseDown(marker, "LeftButton")
release(marker, "LeftButton")
pins, count = Drawn()
check(full.k > 0.4 and pins["npc:69"] and pins["object:1617"] and pins["npc:69"].icon._atlas == "innkeeper"
    and pins["object:1617"].icon._atlas == "professions_tracking_herb", "a click on it zooms in: they part, each in its own icon")
-- The filter: services off.
local chosen = {}
for key, on in pairs(ns.options.pins) do chosen[key] = on end
chosen.service = nil
Core.Set(ns.name, "pins", chosen)
pins = Drawn()
check(not pins["npc:69"] and not pins["place:2"] and pins["object:1617"] and pins["quest:7"], "the filter: services off, the rest stays")
chosen.service = true
Core.Set(ns.name, "pins", chosen)
-- Each kind's size: a slider at its right in the pin filter (the game's slider, lent to the row by the menu),
-- kept in the setting pinSizes; the pins of that kind drawn at it.
do
    MinimalSliderWithSteppersMixin = { Label = { Right = 3 }, Event = { OnValueChanged = "OnValueChanged" } }
    local filter
    for _, widget in ipairs(W.frames) do
        if widget._generator then
            widget:GenerateMenu()
            for _, item in ipairs(widget._items or {}) do
                if type(item.text) == "string" and item.text:find("Possible herbs", 1, true) then filter = widget end
            end
        end
    end
    local rows = {}
    for _, item in ipairs(filter and filter._items or {}) do
        for _, kind in ipairs(ns.KINDS) do if item.text == ns.KindLabel(kind, ns.TopBar.ICON) then rows[kind[1]] = item end end
    end
    local herbs, route, minimapRow, area = rows.herb, rows.route, rows.minimap, rows.area
    check(herbs and herbs.text == "|A:professions_tracking_herb:24:24|a Possible herbs" and rows.foundHerb and rows.foundOre and rows.log and rows.quest and rows.low
        and rows.later and rows.done, "the pin filter: each kind with its icon large before its words; the quests in your log, "
        .. "the quest offers, the low ones and those for later each a row of their own")
    -- The sections: each title, then its kinds; every kind once.
    local titles, under, count = {}, {}, 0
    local current
    for _, item in ipairs(filter and filter._items or {}) do
        if item.title then
            titles[#titles + 1] = item.title
            current = item.title
        else
            for _, kind in ipairs(ns.KINDS) do
                if item.text == ns.KindLabel(kind, ns.TopBar.ICON) then under[kind[1]] = current count = count + 1 end
            end
        end
    end
    check(#titles == #ns.PIN_SECTIONS and titles[1] == "Around you" and titles[2] == "Quests" and count == #ns.KINDS
        and under.route == "Around you" and under.group == "Around you" and under.log == "Quests"
        and under.area == "Quests" and under.flight == "Travel" and under.service == "Towns and services"
        and under.treasure == "Rares and treasures" and under.foundOre == "Gathering",
        "the pin filter in sections under their titles: around you, quests, travel, towns, rares and treasures, gathering")
    local slider = { points = {} }
    function slider:SetWidth(width) self.width = width end
    function slider:ClearAllPoints() self.points = {} end
    function slider:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function slider:Init(value, low, high, steps, labels) self.value, self.low, self.high, self.steps, self.labels = value, low, high, steps, labels end
    function slider:RegisterCallback(event, fn, owner) self.event, self.fn, self.owner = event, fn, owner end
    function slider:UnregisterCallback(_, owner) if self.owner == owner then self.fn, self.owner = nil, nil end end
    local row = { fontString = { GetUnboundedStringWidth = function() return 40 end } }
    function row:AttachTemplate(template) self.template = template return slider end
    local width, height
    if herbs and herbs.inits[1] then width, height = herbs.inits[1](row) end
    check(herbs and #herbs.inits == 1 and row.template == "MinimalSliderWithSteppersTemplate" and slider.value == 100
        and slider.low == ns.PIN_SIZES.low and slider.high == ns.PIN_SIZES.high and slider.labels[3](150) == "150%"
        and width > 40 + slider.width and height == ns.TopBar.ROW,
        "the pin filter: a size slider at each kind's right, from its smallest to its largest size")
    local tallWidth, tallHeight
    if minimapRow and minimapRow.inits[1] then tallWidth, tallHeight = minimapRow.inits[1](row) end
    check(route and #route.inits == 1 and minimapRow and #minimapRow.inits == 1 and tallHeight == ns.TopBar.ROW
        and tallWidth < width and #rows.low.inits == 1,
        "the route's line has a size too, as each quest row has; the game's minimap's dots none (the game draws them), "
        .. "their row as tall as the others")
    local opacity = { points = {} }
    for name, fn in pairs(slider) do if type(fn) == "function" then opacity[name] = fn end end
    local areaRow = { fontString = row.fontString }
    function areaRow:AttachTemplate() return opacity end
    area.inits[1](areaRow)
    check(opacity.low == ns.PIN_OPACITY.low and opacity.high == 100, "the quest areas' slider: their opacity, up to 100 %")
    opacity.fn(nil, 40)
    check(ns.options.pinSizes.area == 40 and ns.PinScale("area") == 0.4, "kept: the areas drawn so see-through")
    opacity.fn(nil, 100)
    slider.fn(nil, 151.2)
    local herb = Drawn()["object:1617"]
    check(ns.options.pinSizes.herb == 150 and ns.PinScale("herb") == 1.5 and herb and near(herb._width, Pins.SIZE.herb * 1.5),
        "moved: kept in its steps (150 %), the herbs drawn at it")
    slider.fn(nil, 100)
    check(ns.options.pinSizes.herb == nil and near(Drawn()["object:1617"]._width, Pins.SIZE.herb), "back at 100 %: nothing kept")
    ;(function()
        -- The menu's sliders are its pool's: one that showed the herbs' size, laid out for another kind's row, would
        -- tell the herbs' callback that kind's size as its Init sets it. Ours is let go first.
        slider.fn(nil, 150)
        function slider:Init(value) if self.fn then self.fn(nil, value) end self.value = value end
        rows.ore.inits[1](row)
        check(ns.options.pinSizes.herb == 150 and slider.value == 100 and slider.owner,
            "a slider of the menu's pool that showed the herbs' size, laid out for Possible ore: the herbs keep theirs")
        local sizes = Core.Copy(ns.options.pinSizes)
        sizes.herb = nil
        Core.Set(ns.name, "pinSizes", sizes)
    end)()
    MinimalSliderWithSteppersMixin = nil
end
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
check(rows[2].icon._shown and rows[2].icon._atlas == Pins.ICONS.log and rows[4].icon._atlas == Pins.ICONS.log
    and not rows[1].icon._shown and not rows[3].icon._shown,
    "each quest with its mark at the left, as its pin on the map has it: the yellow question mark")
;(function()
    -- A header folded: the game lists its quests all the same, our log not (as the game's own log has it).
    local info = C_QuestLog.GetInfo
    C_QuestLog.GetInfo = function(index)
        local entry = info(index)
        if entry and entry.isHeader then entry.isCollapsed = true end
        return entry
    end
    QuestLog.Refresh()
    local folded = logBox:Draw()
    check(#folded == 1 and folded[1].row.kind == "header" and folded[1].row.collapsed,
        "a header folded: its quests and their objectives not listed")
    C_QuestLog.GetInfo = info
    QuestLog.Refresh()
end)()
do
    local was, saved = { map = full.map, u = full.u, v = full.v, k = full.k }, waypoint
    waypoint = nil
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    check(focused == 7 and waypoint and waypoint.uiMapID == 1429 and near(waypoint.position.x, 0.4) and near(waypoint.position.y, 0.4)
        and full.map == was.map and full.u == was.u and full.v == was.v and full.k == was.k,
        "a click: the game's map pin on its objective, the game's arrow leads to it; the map stays as it is")
    waypoint = saved
end
rows = logBox:Draw()
check(rows[2]._lit and not rows[4]._lit, "the quest clicked lit in the list")
-- The right button: its text below the list, the map at its objective; the text's X closes it.
do
    local function Story()
        for _, widget in ipairs(W.frames) do
            if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:find("The story of quest", 1, true) then
                return widget
            end
        end
    end
    local said = Story()
    local details = said and said._parent._parent._parent
    check(not (details and details._shown), "a click shows no text below the list")
    rows[2]._scripts.OnClick(rows[2], "RightButton")
    local items = {}
    for _, item in ipairs(W.menus[#W.menus]) do if item.text then items[item.text] = item end end
    check(W.menus[#W.menus][1].title == "Wolves Across the Border" and items[QuestLog.TEXT.details] and items[QuestLog.TEXT.showMap]
        and items[QuestLog.TEXT.watch] and items[QuestLog.TEXT.share] and items[QuestLog.TEXT.abandon],
        "the right button's menu: its text, the map at it, and the game's watch, share and abandon")
    items[QuestLog.TEXT.showMap].fn()
    check(Canvas.camera == full and full.level == "zone" and near(full.u, -200) and near(full.v, -9100),
        "Show Map: the map at its objective, in the middle")
    items[QuestLog.TEXT.details].fn()
    said = Story()
    details = said and said._parent._parent._parent
    check(details and details._shown and said._text:find("Kill eight wolves.", 1, true), "Quest Details: its objectives and story below the list")
    local close
    for _, widget in ipairs(W.frames) do
        if widget._parent == details and widget._kind == "Button" and not widget._text then close = widget end
    end
    close._scripts.OnClick(close)
    check(not details._shown, "its X: the text away again")
end
-- No scroll bar at rest; the mouse on a list longer than its room: at the side the window stands at.
do
    local log, bar = QuestLog.handle.frame, nil
    for _, widget in ipairs(W.frames) do if widget._kind == "EventFrame" and widget._parent == logBox._parent then bar = widget end end
    check(bar and not bar._shown, "no scroll bar at rest")
    log._mouseOver = true
    log._scripts.OnEnter(log)
    check(not bar._shown, "the mouse on it, the list short: none still")
    logBox._long = true
    log._scripts.OnUpdate(log)
    log._scripts.OnEnter(log)
    check(bar._shown and bar._points[1][1] == "TOPRIGHT" and bar._points[1][2] == logBox and bar._points[1][3] == "TOPLEFT",
        "the list longer than its room: the scroll bar, at the left of the list (the window stands at the screen's left)")
    QuestLog.handle.zone = "RIGHT"
    log._scripts.OnEnter(log)
    check(bar._shown and bar._points[1][1] == "TOPLEFT" and bar._points[1][3] == "TOPRIGHT", "docked at the right edge: at its right")
    QuestLog.handle.zone = nil
    log._mouseOver = false
    log._scripts.OnUpdate(log)
    check(not bar._shown and not log._scripts.OnUpdate, "the mouse gone: the scroll bar too")
    logBox._long = nil
end
;(function()
    -- The look while the mouse is on the quest log: one guard, made once, set again at each coming of the mouse.
    local log = QuestLog.handle.frame
    log._mouseOver = true
    log._scripts.OnEnter(log)
    local look = log._scripts.OnUpdate
    log._mouseOver = false
    look(log)
    log._mouseOver = true
    log._scripts.OnEnter(log)
    check(look and log._scripts.OnUpdate == look, "the mouse back on the quest log: the same look as before, made once")
    log._mouseOver = false
    log._scripts.OnUpdate(log)
end)()
rows[2]._scripts.OnEnter(rows[2])
local blob
for _, widget in ipairs(areaFrames) do if widget._shown and widget._map == 1429 then blob = widget end end
check(blob and not blob._quest and near(blob._width, 2000 * full.k),
    "the mouse over it: its zone's area frame placed at once, the area not drawn into its old rectangle")
blob._parent._scripts.OnUpdate(blob._parent)
check(blob._quest == 7 and not blob._parent._scripts.OnUpdate,
    "the next frame: its area as the game shades it, over its zone, laid out at its new place and size")
rows[2]._scripts.OnLeave(rows[2])
-- The quest's pin now with the glow of the quest the arrow leads to.
pins = Drawn()
check(pins["quest:7"].pin.focused and pins["quest:7"].glow._shown, "its pin glowing: the quest the arrow leads to")
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
-- A click on a quest giver's pin: its quest in the log, greyed out under Not in your log, what the data knows of
-- it below; its red X takes it out again.
do
    local was = { map = full.map, u = full.u, v = full.v, k = full.k, follow = full.follow }
    full:Show(1415, 0, -9250, 0.4)
    Canvas.Layout()
    local giver = Drawn()["npc:74"]
    giver._scripts.OnMouseDown(giver, "LeftButton")
    giver._scripts.OnMouseUp(giver, "LeftButton")
    local shown = logBox:Draw()
    check(shown[1].row.kind == "header" and shown[1].text._text == QuestLog.TEXT.previews and shown[2].row.kind == "preview"
        and shown[2].row.quest == 101 and shown[2].text._text == "[30] A Quest for Later" and shown[2].remove._shown
        and not shown[4].remove._shown, "its quest in the log on top, greyed out, with the red X; the log's own below")
    local said
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:find("A Quest for Later|r", 1, true) then
            said = widget._text
        end
    end
    check(said and said:find(Pins.TEXT.needsLevel:format(60), 1, true) and said:find(QuestLog.TEXT.level:format(30), 1, true)
        and said:find(QuestLog.TEXT.givenBy:format("A Waiting Giver"), 1, true),
        "below it what the data knows: why not yet (the level it asks), its level, who gives it")
    ;(function()
        -- Items the game tells of in a burst: the words drawn again once, on the next frame.
        local details, drawn = QuestLog.Details, 0
        QuestLog.Details = function(...) drawn = drawn + 1 return details(...) end
        for item = 1, 3 do W.Fire("ITEM_DATA_LOAD_RESULT", item, true) end
        local before = drawn
        W.Wait(0)
        QuestLog.Details = details
        check(before == 0 and drawn == 1, "a burst of items told by the game: the preview's words drawn again once")
    end)()
    shown[2].remove._scripts.OnClick(shown[2].remove)
    shown = logBox:Draw()
    check(shown[1].row.kind == "header" and shown[1].text._text ~= QuestLog.TEXT.previews and #shown == 5,
        "its red X: out of the log again")
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = was.follow
    Canvas.Layout()
end
-- A click on any pin puts the game's map pin where it stands, on the full map and the small one; Shift and a click
-- on one that leads into another map opens that map instead.
do
    local was = { map = full.map, u = full.u, v = full.v, k = full.k, follow = full.follow }
    full:Show(1415, 0, -9250, 0.4)
    Canvas.Layout()
    local saved = waypoint
    local mailbox = Drawn()["place:2"]
    waypoint = nil
    mailbox._scripts.OnMouseDown(mailbox, "LeftButton")
    mailbox._scripts.OnMouseUp(mailbox, "LeftButton")
    check(waypoint and waypoint.uiMapID == mailbox.pin.map and near(waypoint.position.x, mailbox.pin.x)
        and near(waypoint.position.y, mailbox.pin.y), "a click on a pin: the game's map pin where it stands")
    local opened
    local show = ns.Canvas.Show
    ns.Canvas.Show = function(map) opened = map return true end
    local entrance = Drawn()["place:1"]
    waypoint = nil
    IsShiftKeyDown = function() return true end
    entrance._scripts.OnMouseDown(entrance, "LeftButton")
    entrance._scripts.OnMouseUp(entrance, "LeftButton")
    IsShiftKeyDown = function() return false end
    check(opened == 500 and not waypoint, "Shift and a click on an entrance: its map opens, no map pin")
    entrance._scripts.OnMouseDown(entrance, "LeftButton")
    entrance._scripts.OnMouseUp(entrance, "LeftButton")
    check(waypoint and waypoint.uiMapID == 1429, "a plain click on it: the map pin there, as on every pin")
    local previewed
    local preview = ns.QuestLog.Preview
    ns.QuestLog.Preview = function(quests) previewed = quests end
    local giver = Drawn()["npc:72"]
    Canvas.Use(ns.Window.small)
    waypoint = nil
    giver._scripts.OnMouseDown(giver, "LeftButton")
    giver._scripts.OnMouseUp(giver, "LeftButton")
    check(waypoint and not previewed, "on the small map a quest giver's pin: the map pin only, the quest log stays shut")
    Canvas.Use(full)
    giver._scripts.OnMouseDown(giver, "LeftButton")
    giver._scripts.OnMouseUp(giver, "LeftButton")
    check(previewed and previewed[1] == 100, "on the full map: the map pin, and its quests in the quest log")
    ns.QuestLog.Preview = preview
    ns.Canvas.Show = show
    waypoint = saved
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = was.follow
    Canvas.Layout()
end
-- The window small and full again, as the tests below go there, the small view left as it was.
function W.SmallAndBack(between)
    local kept = { u = small.u, v = small.v, k = small.k, level = small.level, map = small.map, follow = small.follow,
                   native = small.native }
    local width, height = frame._width, frame._height
    Window.Toggle()
    frame._width, frame._height = 200, 200
    Window.frame._group:Run(1)
    if between then between() end
    Window.Toggle()
    frame._width, frame._height = width, height
    Window.frame._group:Run(1)
    for key, value in pairs(kept) do small[key] = value end
end

-- The dungeons' maps: chosen in the bar, over the map, by floor; the mouse; back to the map.
;(function()
    local Dungeons = ns.Dungeons
    check(Window.handle.edge.full and Canvas.camera == full, "the map fills the screen")
    -- As in Forever's client, which has no dungeon map of its own: the list kept once Core's set was read, the
    -- game not asked again at each look.
    local asked, children = 0, C_Map.GetMapChildrenInfo
    C_Map.GetMapChildrenInfo = function(map, kind, all)
        if kind == 4 then asked = asked + 1 end
        return children(map, kind, all)
    end
    Dungeons.List()
    Dungeons.List()
    Dungeons.List()
    C_Map.GetMapChildrenInfo = children
    check(asked <= 1, "no dungeon map of the game's, Core's set read: the dungeons' list kept, not asked again")
    -- This made-up client tells of dungeons of its own from here on (and no longer after): the kept list (an upvalue
    -- of List's) asked anew.
    local function Forget()
        for index = 1, 64 do
            local name = debug.getupvalue(Dungeons.List, index)
            if name == nil then return end
            if name == "list" then return debug.setupvalue(Dungeons.List, index, nil) end
        end
    end
    local old = { children = C_Map.GetMapChildrenInfo, info = C_Map.GetMapInfo, art = C_Map.GetMapArtLayers }
    local names = { [500] = "Hollow Keep", [501] = "Hollow Keep", [600] = "Ashen Vault" }
    C_Map.GetMapChildrenInfo = function(map, kind, all)
        if map == 947 and kind == 4 and all then
            return { { mapID = 500, mapType = 4 }, { mapID = 600, mapType = 4 }, { mapID = 501, mapType = 4 } }
        end
        return old.children(map, kind, all)
    end
    C_Map.GetMapInfo = function(map)
        if names[map] then return { mapID = map, mapType = 4, parentMapID = map == 600 and 1415 or 1429, name = names[map] } end
        return old.info(map)
    end
    C_Map.GetMapArtLayers = function(map)
        if names[map] then return { { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 } } end
        return old.art(map)
    end
    C_Map.GetMapGroupID = function(map) return (map == 500 or map == 501) and 7 or nil end
    C_Map.GetMapGroupMembersInfo = function(group)
        if group ~= 7 then return nil end
        return { { mapID = 501, relativeHeightIndex = 1, name = "The Lower Hall" },
                 { mapID = 500, relativeHeightIndex = 0, name = "The Upper Hall" } }
    end
    -- The game's dungeons (those of Core's set, below, may be in the list too).
    Forget()
    local list = {}
    for _, entry in ipairs(Dungeons.List()) do if not entry.instance then list[#list + 1] = entry end end
    check(#list == 2 and list[1].name == "Ashen Vault" and list[2].name == "Hollow Keep" and list[2].map == 500
        and #list[2].floors == 2 and list[2].floors[2].map == 501, "the dungeons: one entry each, its floors lowest first, A to Z")
    local menu, floors
    for _, widget in ipairs(W.frames) do
        if widget._generator and widget._override == Dungeons.TEXT.dungeons then menu = widget end
        if widget._generator and widget._override == Dungeons.TEXT.floor then floors = widget end
    end
    menu:GenerateMenu()
    local keep
    for _, item in ipairs(menu._items) do if item.text == "Hollow Keep" then keep = item end end
    check(#menu._items >= 2 and menu._items[1].text == "Ashen Vault" and keep and not keep.checked(),
        "the bar's dropdown Dungeons lists them, A to Z")
    local was = { full.map, full.u, full.v, full.k, full.level } -- the map the dungeon is opened from
    keep.fn()
    local tiles = 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._shown and type(widget._texture) == "number"
            and widget._texture > 50000 and widget._texture <= 50012 then tiles = tiles + 1 end
    end
    check(Dungeons.Shown() == 500 and Dungeons.frame._shown and tiles == 12 and menu._override == "Hollow Keep"
        and keep.checked() and floors._shown and floors._override == "The Upper Hall",
        "chosen: its map over the map, its lowest floor in the game's art, its floors beside it")
    floors:GenerateMenu()
    check(#floors._items == 2 and floors._items[1].checked() and floors._items[2].text == "The Lower Hall", "its floors, lowest first")
    floors._items[2].fn()
    check(Dungeons.Shown() == 501 and floors._override == "The Lower Hall", "another floor chosen")
    Dungeons.frame._scripts.OnMouseUp(Dungeons.frame, "RightButton")
    check(not Dungeons.Shown() and not Dungeons.frame._shown and full.map == was[1] and full.u == was[2] and full.v == was[3]
        and full.k == was[4] and full.level == was[5] and menu._override == Dungeons.TEXT.dungeons and not floors._shown,
        "a right click: back to the map it was opened from, as it was")
    check(Canvas.Show(600) and Dungeons.Shown() == 600 and not floors._shown,
        "a pin into a dungeon opens its map here; with one floor, no floors' dropdown")
    W.SmallAndBack(function()
        check(not Dungeons.Shown() and not Dungeons.Show(600), "the map small: the dungeon's view goes, and opens only on the full map")
        player.map = 500
    end)
    check(Dungeons.Shown() == 500, "inside a dungeon the full map opens on its map")
    player.map = 1429
    Dungeons.Close()
    C_Map.GetMapChildrenInfo, C_Map.GetMapInfo, C_Map.GetMapArtLayers = old.children, old.info, old.art
    C_Map.GetMapGroupID, C_Map.GetMapGroupMembersInfo = nil, nil
    Forget()
end)()

-- The quest log, a window of its own over the full map: pinned, on the screen while the map is small too.
;(function()
    local log = ns.QuestLog.handle
    check(log and log.frame._shown and log.frame._strata == "DIALOG" and Canvas.frame._points[1] and Window.FullSize() == 1600,
        "full: the quest log a window of its own over the map, which takes the whole screen")
    local pin = log.own and log.own[1]
    check(pin and pin.picture._atlas == ns.QuestLog.PIN_OFF and not ns.QuestLog.Pinned(), "its title bar's pin, grey: not pinned")
    pin._scripts.OnClick(pin)
    check(ns.QuestLog.Pinned() and pin.picture._atlas == ns.QuestLog.PIN, "a click pins it: lit")
    W.SmallAndBack(function()
        check(log.frame._shown and log.frame._strata == "LOW" and log.bar and not log.skin,
            "the map small: pinned, it stays on the screen, without a background or a border")
        local transparent = true
        for _, widget in ipairs(W.frames) do
            if widget._parent == log.frame and widget._kind == "Texture" and widget._shown then transparent = false end
        end
        check(transparent, "nothing drawn behind it but its list")
        pin._scripts.OnClick(pin)
        check(not ns.QuestLog.Pinned() and not log.frame._shown, "unpinned: it goes with the full map")
    end)
    check(log.frame._shown and log.frame._strata == "DIALOG", "and comes back with it")
end)()

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
        and Canvas.view.continent == 2991 and Canvas.view.zone == 2521
        and ((arrow._shown and near(arrow._points[1][4], 0)) or (minimap._shown and near(minimap._points[1][4], 0))),
        "standing on the isle: the view follows the player into its plane, a zone, the arrow there (ours or the game's minimap's)")
    local onIsle = Drawn(true)
    local tower = onIsle["travel:4:2"]
    check(tower and tower.icon._atlas == "vehicle-air-horde" and tower.pin.home == 2521 and tower.pin.to == 1429
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
check(#viewOption.choices == 4 and viewOption.choices[4][1] == "atlas" and Button("atlas")._shown
    and Button("atlas")._points[1][2] == Button("terrain") and not W.loaded.SaneUI_Atlas,
    "with the module four views are offered: its button after Scrying's, its choice; nothing loaded yet")
Button("atlas")._scripts.OnClick(Button("atlas"))
shown = Shown()
check(ns.options.view == "atlas" and not Painted.Offered() and ns.View() == "terrain" and Count(shown, 801, 804) == 4,
    "the module cannot be loaded: the map shows Scrying at once")
check(Core.errors["Navigation: atlas"] and Core.errors["Navigation: atlas"].text:find("could not be loaded (CORRUPT)", 1, true),
    "the problem is kept and told")
W.Wait(0)
check(ns.options.view == "terrain" and not Button("atlas")._shown and #viewOption.choices == 3 and Button("terrain")._lit,
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
check(near(full.k, Camera.NEAR * 3) and Camera.Near() == Camera.NEAR * 3, "Atlas zooms three times nearer than the other views")
Button("terrain")._scripts.OnClick(Button("terrain"))
check(full.k == Camera.NEAR and Size(Blocks(Shown(), 0)) == 0, "Scrying: its own nearest zoom, no painted blocks")
Button("atlas")._scripts.OnClick(Button("atlas"))
-- The module stood down (an error of its own, caught by Core's guards): Scrying, its button and choice gone.
Atlas.off = true
Canvas.Refresh()
check(ns.View() == "terrain" and Size(Blocks(Shown(), 0)) == 0, "the module stood down: the map shows Scrying")
W.Wait(0)
check(ns.options.view == "terrain" and not Button("atlas")._shown and #viewOption.choices == 3,
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
check(not worldMap._shown and worldMap._alpha == 1 and panels.hidden == 0,
    "on the next frame: hidden by its own Hide, never by the game's panel functions (their slots stay the game's)")
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
-- On the window's way nothing lays the map out again (held): a refresh waits for the window to stand, the wheel and
-- a press do nothing.
;(function()
    local placed, place = 0, ns.Terrain.Place
    ns.Terrain.Place = function(...)
        placed = placed + 1
        return place(...)
    end
    local k = full.k
    Canvas.Refresh()
    Canvas.frame._scripts.OnMouseWheel(Canvas.frame, 1)
    Canvas.frame._scripts.OnMouseDown(Canvas.frame, "LeftButton")
    local still = Window.handle.edge.away and placed == 0 and full.k == k and not Canvas.frame._scripts.OnUpdate
    Canvas.frame._scripts.OnMouseUp(Canvas.frame, "LeftButton")
    Window.frame._group:Run(1)
    ns.Terrain.Place = place
    check(still and placed > 0, "on the window's way nothing lays the map out (a refresh, the wheel, a press); where it stands, it is")
end)()
check(not Window.handle.edge.away, "back in its corner")
Core.Set(ns.name, "nativeMinimap", true)
check(not Hybrid.Taken() and minimap:GetParent() == container and minimap._wheel and #minimap._through == 0
    and ground == true and ignoreRotation == false and configs > 0, "Show the game's minimap: its place, wheel, clicks, ground, rotation and mask back")
check(cluster._alpha == 1 and cluster._mouse and cluster.ZoneTextButton._mouse and backdrop._alpha == 1 and minimap.ZoomIn._mouse,
    "its cluster, border and buttons back")
;(function()
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == minimap and widget._kind == "Button" and widget ~= minimap.ZoomIn then sane = widget end
    end
    check(sane and sane._shown and minimap._shown, "the game's own minimap again: its button Sane UI on it, back to ours")
end)()
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
check(classicMenu and classicMenu:IsShown() and #classicMenu._items == 3 and classicMenu._items[1].title ~= nil and classicMenu._items[2].checked() == false
    and classicMenu._items[3].checked() == false, "full, the dropdown Classic windows: the game's minimap and map, neither chosen")
;(function()
    local before = panels.shown
    classicMenu._items[3].fn()
    check(ns.options.nativeMap and not worldMap._shown and panels.shown == before and Window.handle.edge.away,
        "the game's map chosen: kept, not opened by our code (its own key opens it), ours goes back")
    local said = W.printed[#W.printed] or ""
    check(said:find(ns.TEXT.classicMap, 1, true) and said:find(", M.", 1, true), "and the chat says its key")
end)()
Window.frame._group:Run(1)
check(overrides.M == nil and Window.frame._alpha == 1, "its key is the game's now; our small window stays the minimap")
Window.Toggle()
Window.frame._group:Run(1)
check(classicMenu._items[3].checked() == true, "the corner still fills the screen with ours, the game's map ticked")
classicMenu._items[3].fn()
check(not ns.options.nativeMap and overrides.M == "SaneUINavigationKey:map" and Window.handle.edge.full,
    "chosen again: ours is the map again, the window stays full")
classicMenu._items[2].fn()
Window.frame._group:Run(1)
check(ns.options.nativeMinimap and not Hybrid.Taken() and Window.frame._alpha == 0, "the game's minimap chosen: kept, ours rests")
Core.Set(ns.name, "nativeMinimap", false)

-------------------------------------------------------------------------------
--  Routes: the walking data, the walk between two points, the journey with a flight, a boat, the hearthstone
-------------------------------------------------------------------------------
local Walk, Search, Planner = ns.Walk, ns.Search, ns.Planner
check(Walk.Ready() and Walk.Known(), "the walking data is there, with Core")
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
check(ending and (-8533.33 - ending[#ending - 2]) / s <= 240.01 and near(ending[#ending - 1], 244 * s)
    and near(ending[#ending], -8533.33 - 252 * s),
    "to a place nobody can walk to: the walk where one can, nearest to it, then straight to the place itself")
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
do
    -- Off the map's edge, or refused by the game: no map pin, and no error.
    local before = waypoint
    local set = C_Map.SetUserWaypoint
    check(Live.SetWaypoint(1429, 1.2, 0.5) == false and Live.SetWaypoint(1429, 0 / 0, 0.5) == false and waypoint == before,
        "a map pin off the map's edge (or at no number): none, and nothing asked of the game")
    C_Map.SetUserWaypoint = function() error("Usage: local wasSet = C_Map.SetUserWaypoint(point)") end
    check(Live.SetWaypoint(1429, 0.5, 0.5) == false and waypoint == before, "one the game refuses: none, no error")
    C_Map.SetUserWaypoint = set
end
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
-- round: its runs at the game's transports' speed, its stays; its leaps take no time, the one from its last point
-- back to its first too) and the trip.
local Ships = Core.Data.Ships()
local run = Ships.Run
local d12, d34 = math.sqrt(600 ^ 2 + 1550 ^ 2), math.sqrt(1000 ^ 2 + 500 ^ 2)
local round = run(d12 + d34) + run(d34) + 120
do
local ship = Planner.Ship(Core.Data.Set("Travel"):Get(3))
check(near(run(2000), 60 + 1100 / 30) and near(run(400), 40), "a run: speeding up, at full speed, slowing down")
check(#ship == 2 and ship[1].world == 0 and ship[2].world == 1 and ship[1].ways[ship[2]] and ship[2].ways[ship[1]],
    "a boat's way: a dock on each continent, a way from each to the other")
check(near(ship[1].ways[ship[2]].seconds, round / 2 + run(d12 + d34))
    and near(ship[2].ways[ship[1]].seconds, round / 2 + run(d34)) and near(ship[2].ways[ship[1]].trip, run(d34)),
    "each the wait for it and the trip; back by the leap to its first point")
local three = Planner.Ship({ kind = "boat", wait = 600, path = { { x = 0, y = 0, map = 0, stay = 60 },
    { x = 1000, y = 0, stay = 60 }, { x = 2000, y = 0, stay = 60 }, { x = 1000, y = 100 } } })
local stretch = (600 - 180) / (2 * run(1000) + run(math.sqrt(1000 ^ 2 + 100 ^ 2)))
check(#three == 3 and near(three[1].ways[three[3]].seconds, 300 + 2 * run(1000) * stretch + 60)
    and near(three[1].ways[three[2]].seconds, 300 + run(1000) * stretch),
    "three docks: past the one between, its stay counted; its time once round, known, stretches its runs")
local twice = Planner.Ship({ kind = "boat", path = { { x = 0, y = 0, map = 0, stay = 30 }, { x = 500, y = 0 },
    { x = 1000, y = 0, stay = 60 }, { x = 500, y = 50 }, { x = 0, y = 0, stay = 30 } } })
check(#twice == 2 and near(twice[1].ways[twice[2]].seconds - twice[2].ways[twice[1]].seconds,
    (1000 - 2 * math.sqrt(500 ^ 2 + 50 ^ 2)) / Ships.SPEED), "a dock stopped at twice is one dock, left from the stop that sails soonest")
check(#Planner.Ship({ kind = "flight", path = { { x = 0, y = 0, stay = 1 }, { x = 9, y = 9 } } }) == 0, "a flight has no docks")
end
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
-- The boat's times on this realm, learnt on a ride (Core's Data.Ships): it leaves its first dock at server time
-- leaves; the player stands on it, its place in the world moving with it along its first run (at the game's
-- transports' speed: speeding up, at full speed, slowing down). A function of its own: the test's main chunk has
-- room for no more locals.
local function Rides()
    local timetable = Ships:Table(3)
    check(timetable and #timetable.stops == 2 and not timetable.known and near(timetable.round, round)
        and near(timetable.stops[1].leave, 0) and near(timetable.stops[2].arrive, run(d12 + d34))
        and timetable.stops[2].area == 12, "the boat's timetable: when it comes to each dock and leaves it, its round estimated")
    check(Ships:Next(3, 1) == nil, "its times here not known before a ride")
    local yards = d12 + d34
    local function At(seconds) -- yards sailed so many seconds after leaving
        local ramp = Ships.SPEED / Ships.ACCEL
        if seconds <= 0 then return 0 end
        if seconds < ramp then return Ships.ACCEL * seconds ^ 2 / 2 end
        local left = run(yards) - seconds
        if left > ramp then return Ships.SPEED ^ 2 / (2 * Ships.ACCEL) + Ships.SPEED * (seconds - ramp) end
        return yards - Ships.ACCEL * math.max(0, left) ^ 2 / 2
    end
    local leaves = W.serverStart + W.clock + 20.4
    local function Ride(start)
        return function()
            local s = At(W.serverStart + W.clock - start)
            if s <= d12 then
                local f = s / d12
                return { -8600 + 600 * f, -450 - 1550 * f, 5, 0 }
            end
            local f = (s - d12) / d34
            return { 5000 + 1000 * f, -9000 - 500 * f, 5, 1 }
        end
    end
    W.place = Ride(leaves)
    local learnt, aboardKey, aboardStop, aboardLeft
    Ships:OnLearn(function(key) learnt = key end)
    for _ = 1, 60 do
        W.Wait(1)
        Ships.Now()
    end
    aboardKey, aboardStop, aboardLeft = Ships:Aboard()
    local now = W.serverStart + W.clock
    check(aboardKey == 3 and aboardStop == 2 and math.abs(aboardLeft - (leaves + run(yards) - now)) < 1.5,
        "aboard: the boat, its next dock and the seconds until it arrives")
    W.Wait(0)
    local store = Core.Store(Core.name).ships
    local kept = store and store["Stub Realm"] and store["Stub Realm"][3]
    check(learnt == 3 and kept and math.abs(kept.epoch - leaves) < 1 and kept.rides == 1 and kept.seen,
        "a ride: when the boat left its first dock, kept for this realm")
    local arrive, leave, here = Ships:Next(3, 2)
    check(arrive and math.abs(arrive - (leaves + run(yards))) < 1 and near(leave - arrive, 60) and not here,
        "then when it comes to the next dock, and leaves it")
    arrive, leave, here = Ships:Next(3, 1, leaves + 10 * round - 30)
    check(arrive and math.abs(arrive - (leaves + 10 * round - 60)) < 1 and here, "ten rounds later: standing at its first dock")
    check(Ships:Next(3, 1, now + Ships.TRUST + 1) == nil, "a ride's times not trusted after a while")
    -- Three rounds later, a ride again, the boat 10 seconds a round slower than estimated: its round corrected.
    W.place = nil
    W.Wait(20)
    local again = leaves + 3 * (round + 10)
    W.place = Ride(again)
    W.Wait(again - 1 - (W.serverStart + W.clock))
    for _ = 1, 60 do
        W.Wait(1)
        Ships.Now()
    end
    W.Wait(0)
    kept = store["Stub Realm"][3]
    check(kept.rides == 2 and math.abs(kept.round - (round + 10)) < 1 and Ships:Table(3).known
        and math.abs(Ships:Table(3).round - (round + 10)) < 1, "a second ride corrects the estimated round")
    -- The dock watch (DockWatch.lua): aboard, where it lands and when; at its dock, where it goes and when it comes.
    local DockWatch = ns.DockWatch
    local function Clock(seconds)
        seconds = math.floor(seconds + 0.5)
        return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
    end
    local rows = DockWatch.Rows()
    now = W.serverStart + W.clock
    local trip = Core.Data.Trips():Now()
    local lines = trip and ns.TripView.Lines(trip)
    local _, _, sailing = Ships:Aboard()
    check(#rows == 0 and trip and trip.kind == "boat" and trip.key == 3 and #trip.stops == 2 and sailing
        and math.abs(trip.left - sailing) < 1.1 and lines.title:find("The Far Shore", 1, true),
        "aboard: the trip is the boat's, to where it lands, and in how long; the dock watch steps aside")
    W.place = { -8580, -470, 5, 0 }
    W.Wait(5)
    rows = DockWatch.Rows()
    now = W.serverStart + W.clock
    local comes = again + Ships:Table(3).round - 60 - now
    check(#rows == 1 and rows[1].name:find("To The Far Shore", 1, true) and rows[1].known
        and rows[1].status == DockWatch.TEXT.coming:format(Clock(comes), Clock(comes + 60)),
        "at its dock: where it goes, when it arrives and leaves")
    check(rows[1].last and near(rows[1].leave - rows[1].last, Ships:Table(3).round),
        "the wait drawn from when it last left this dock to when it comes again")
    local width, height = UIParent._width, UIParent._height
    UIParent:SetSize(1600, 900)
    DockWatch.Update()
    local overlay = ns.TripView.frame
    local point = overlay and overlay._points[1]
    check(overlay and overlay:IsShown() and point and point[1] == "CENTER" and point[3] == "BOTTOM" and near(point[5], 600),
        "waiting at its dock: the overlay, two thirds up the screen")
    UIParent:SetSize(width, height)
    Core.Set(ns.name, "dockTimes", false)
    check(not overlay:IsShown(), "not while its setting is off")
    Core.Set(ns.name, "dockTimes", true)
    W.place = { -8000, 2000, 5, 0 }
    DockWatch.Update()
    check(#DockWatch.Rows() == 0 and not overlay:IsShown(), "away from every dock: nothing")
    store["Stub Realm"][3] = nil
    W.place = { -8580, -470, 5, 0 }
    rows = DockWatch.Rows()
    check(#rows == 1 and not rows[1].known and rows[1].status:find("ride it once", 1, true),
        "its times not known: how often it sails")
    W.place = nil
    DockWatch.Update()
end
Rides()
-- The trip (Core's Data.Trips) and its view (TripView.lua): a flight of two hops taken at the flight master (Alpha,
-- Beta, Gamma: the set's flights 20 to 21 and 21 to 22, 2000 yards), flown at 25 yards a second; then the tram.
local function Flights()
    local Trips, TripView = Core.Data.Trips(), ns.TripView
    local onTaxi = false
    UnitOnTaxi = function() return onTaxi end
    GetTaxiMapID = function() return 1429 end
    C_TaxiMap.GetAllTaxiNodes = function()
        return { { slotIndex = 1, nodeID = 20 }, { slotIndex = 2, nodeID = 21 }, { slotIndex = 9, nodeID = 22 } }
    end
    GetNumRoutes = function(slot) return slot == 9 and 2 or 0 end
    TaxiGetNodeSlot = function(_, hop, source) return ({ { 1, 2 }, { 2, 9 } })[hop][source and 1 or 2] end
    local names = { [1] = "Alpha", [2] = "Beta", [9] = "Gamma" }
    TaxiNodeName = function(slot) return names[slot] end
    local function Fly()
        local start = W.clock
        W.place = function()
            local s = math.min(2000, (W.clock - start) * 25)
            if s <= 1000 then return { s, 0, 100, 0 } end
            return { 1000, s - 1000, 100, 0 }
        end
        TakeTaxiNode(9)
        onTaxi = true
        W.Fire("PLAYER_CONTROL_LOST")
    end
    -- Without a map pin: the flight's way alone on the map.
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Fly()
    local trip = Trips:Now()
    check(trip and trip.kind == "flight" and #trip.stops == 3 and trip.stops[1].name == "Alpha" and trip.stops[2].name == "Beta"
        and trip.stops[3].name == "Gamma" and near(trip.yards, 2000) and trip.next == 2 and near(trip.left, 2000 / Trips.PACE),
        "a flight taken at the flight master: its stops and its way, its time at the guessed pace until measured")
    for _ = 1, 20 do W.Wait(1) end
    trip = Trips:Now()
    check(math.abs(trip.at - 500) < 26 and math.abs(trip.left - 60) < 1 and math.abs(trip.nextLeft - 20) < 1
        and trip.canLand and Trips:CanLand(), "on its way: how far along, the time to the next stop and to the end at its own pace")
    Frames(2)
    local lines = TripView.Lines(trip)
    check(TripView.frame and TripView.frame:IsShown() and lines.title == "Alpha to Gamma" and lines.next == "Next: Beta in 0:20"
        and lines.left == "1:00" and TripView.exit:IsShown(), "its overlay, with the game's Request Stop")
    Planner.Track(1415, 0, 500, GetTime() + 100)
    Frames(2)
    local leg = shownWay and shownWay.legs[1]
    check(leg and leg.flying and #shownWay.legs == 1 and near(leg.points[1].u, 0) and math.abs(leg.points[1].v - 500) < 30
        and near(leg.points[#leg.points].u, -1000) and near(leg.points[#leg.points].v, 1000),
        "on the map: the flight's way on from where the player is")
    TripView.exit._scripts.OnClick(TripView.exit)
    trip = Trips:Now()
    check(trip.landing and #trip.stops == 2 and trip.stops[2].name == "Beta" and not Trips:CanLand()
        and TripView.Lines(trip).next == "Landing at Beta", "Request Stop: the flight ends at the next flight point")
    for _ = 1, 20 do W.Wait(1) end
    onTaxi = false
    W.Fire("PLAYER_CONTROL_GAINED")
    Frames(2)
    check(Trips:Now() == nil and not Core.Character(Core.name).trip and not Core.Character(Core.name).flightPaces
        and not TripView.frame:IsShown(), "landed early: the trip ends, nothing learnt from it")
    Planner.Track(1415, -1000, 1000, GetTime() + 200)
    check(shownWay == nil, "after the flight, without a map pin: no line")
    -- A whole flight: its pace learnt for this character.
    Fly()
    for _ = 1, 82 do W.Wait(1) end
    onTaxi = false
    W.Fire("PLAYER_CONTROL_GAINED")
    local paces = Core.Character(Core.name).flightPaces
    check(paces and #paces == 1 and math.abs(paces[1] - 25) < 0.5, "a flight flown to its end: its pace kept for this character")
    -- The tram: a place in its map moving along its stations' line at its speed (2000 yards in 50 seconds).
    local start = W.clock
    W.place = function() return { (W.clock - start) * 40, 0, -4, 369 } end
    for _ = 1, 10 do W.Wait(1) end
    trip = Trips:Now()
    check(trip and trip.kind == "tram" and trip.next == 2 and math.abs(trip.at - 400) < 41 and math.abs(trip.left - 40) < 1.1
        and TripView.Lines(trip).title == "Deeprun Tram: Stormwind City to Ironforge",
        "on the tram: how far along, how long to the station")
    local trams = Core.Store(Core.name).trams
    local learnt = trams and trams["Stub Realm"] and trams["Stub Realm"][7]
    check(learnt and math.abs(learnt.epoch - (W.serverStart + start)) < 1.5,
        "a tram ride: when its train left the station, kept for this realm")
    W.place = nil
    W.Wait(3)
    check(Trips:Now() == nil, "off the tram: no trip")
    -- Waiting at its first station: the next train, to the other station; it stands there its wait less its run.
    W.place = { 30, 0, -4, 369 }
    W.Wait(3)
    local rows = ns.DockWatch.Rows()
    local now = W.serverStart + W.clock
    check(Trips:Now() == nil and #rows == 1 and rows[1].kind == "tram" and rows[1].known and near(rows[1].leave - rows[1].arrive, 70)
        and rows[1].leave > now and rows[1].leave - now <= 120 and rows[1].name:find("Ironforge", 1, true),
        "waiting at the tram's station: when the next train comes and leaves, to the other station")
    TripView.Update()
    check(TripView.frame:IsShown(), "the overlay while waiting for the tram")
    W.place = nil
    W.Wait(3)
end
Flights()
-- A pin far in the north (u 0, v -200): on foot to the tram's entrance by the player, the tram (the walks inside and
-- the loading screens, half the time between two trains, its run), on foot from the other entrance to the pin.
;(function()
    waypoint = { uiMapID = 1415, position = CreateVector2D(0.5, 0.21) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local legs = shownWay and shownWay.legs or {}
    local tram = legs[2]
    check(#legs == 3 and legs[1].kind == "walk" and tram.kind == "tram" and legs[3].kind == "walk",
        "a pin far away by the tram: on foot to its entrance, the tram, on foot to the pin")
    local down, up, ending = tram.points[1], tram.points[#tram.points], legs[3].points[#legs[3].points]
    check(#tram.points == 2 and down.map == 1415 and near(down.u, 600) and near(down.v, -8900) and up.map == 1415
        and near(up.u, 0) and near(up.v, 0) and not tram.ship and near(ending.u, 0) and near(ending.v, -200),
        "the tram straight from entrance to entrance (its tunnel has no plane), then to the pin")
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
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
do
    local chosen = Core.Copy(ns.options.pins)
    chosen.route = nil
    Core.Set(ns.name, "pins", chosen)
    check(shownWay == nil, "the pin filter's Route to the map pin off: no line")
    chosen = Core.Copy(chosen)
    chosen.route = true
    Core.Set(ns.name, "pins", chosen)
    W.Wait(0)
    Frames(8)
    check(shownWay ~= nil, "on again: planned anew, the line again")
end
Live.ClearWaypoint()
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
check(shownWay == nil, "the pin taken away: no line")
-- Floors one over the other (Kalimdor's tile 6176): chosen where nothing is known of before, followed through the
-- openings the walker went by, each a start or an end of a walk of its own; a pin off the walking data reached on a
-- floor near it, the rest straight; a start off it, straight onto it.
;(function()
    local s = Walk.SAMPLE
    local function At(column, row) return column * s, -row * s end
    local cu, cv = At(96, 64) -- in the cave, under the hill
    check(#Walk.Under(1414, cu, cv) == 2, "two floors under a point of the cave: the cave's and the hill's")
    check(select(2, Walk.Floor(1414, cu, cv, false, 40)) == 3 and select(2, Walk.Floor(1414, cu, cv, true, 40)) == 2,
        "nothing known of before: outdoors the highest floor (the hill), indoors the lowest (the cave)")
    local gu, gv = At(176, 70)
    check(select(2, Walk.Floor(1414, cu, cv, false, 40, 8)) == 2 and Walk.Floor(1414, gu, gv, false, 40, 80) == nil,
        "not followed: the floor near the height the walker had (the cave's), none so near (off the mesa): none")
    local fu, fv = At(60, 64)
    local tu, tv = At(66, 64)
    local _, into = Walk.Follow(1414, tu, tv, 6176, 1, fu, fv)
    local pu, pv = At(60, 4)
    local hu, hv = At(66, 4)
    local _, up = Walk.Follow(1414, hu, hv, 6176, 1, pu, pv)
    check(into == 2 and up == 3, "followed from the field: by the cave's mouth into the cave, by the path onto the hill")
    local key, stays = Walk.Follow(1414, cu, cv, 6176, 2, At(70, 64))
    check(key == 6176 and stays == 2, "on through the cave: the cave, not the hill over it")
    local ru, rv = At(176, 48)
    local regions = Walk.Regions(1414, ru, rv, 0)
    check(regions and regions[1] and regions[2], "the regions of the floors under a point: the field's and the mesa's")
    -- From the cave to the field beyond the hill: out by its mouth and up the path; from the hill, straight east.
    local eu, ev = At(200, 64)
    local points = Search.Walk(1414, cu, cv, eu, ev, { 6176, 2 })
    local mouth, path = false, false
    for index = 1, #points or 0, 2 do
        local column, row = points[index] / s, -points[index + 1] / s
        if math.abs(column - 64) < 1 and row >= 59 and row <= 68 then mouth = true end
        if row <= 8.5 then path = true end
    end
    check(points and mouth and path and near(points[1], cu) and near(points[#points], ev),
        "from the cave's floor: out by its mouth, up the hill's path, to the field beyond it")
    points = Search.Walk(1414, cu, cv, eu, ev)
    check(points and #points == 4, "nothing known of the start's floor: the shortest of its floors (the hill), straight")
    -- A pin on the mesa: the field under it (the walk's own region). One beside the field, off the walking data: to
    -- the field's edge, then straight to it. A start beside it: straight onto it first.
    local mu, mv = At(176, 48)
    points = Search.Walk(1414, eu, ev, mu, mv)
    check(points and #points == 4 and near(points[3], mu) and near(points[4], mv), "a pin on a mesa nobody walks onto: the field under it")
    local ou, ov = At(200, 134)
    points = Search.Walk(1414, eu, ev, ou, ov)
    check(points and near(points[#points - 3], ou) and near(points[#points - 2], -128 * s) and near(points[#points - 1], ou)
        and near(points[#points], ov),
        "a pin beside the walking data: to the floor nearest it, then straight to the pin")
    points = Search.Walk(1414, ou, ov, eu, ev)
    check(points and near(points[1], ou) and near(points[2], ov) and near(points[4], -128 * s) and near(points[#points], ev),
        "a start beside it: from the start straight onto the floor, then on")
    -- The planner from the player in the cave (indoors) to the field: its first walk from the cave's floor.
    local indoors = IsIndoors
    IsIndoors = function() return true end
    player.map, player.x, player.y = 1414, (cu + 12000) / 24000, (20000 - cv) / 40000
    waypoint = { uiMapID = 1414, position = CreateVector2D((eu + 12000) / 24000, (20000 - ev) / 40000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local leg = shownWay and shownWay.legs[1]
    mouth = false
    for _, point in ipairs(leg and leg.points or {}) do
        if math.abs(point.u / s - 64) < 1 and -point.v / s >= 59 and -point.v / s <= 68 then mouth = true end
    end
    check(leg and #shownWay.legs == 1 and leg.kind == "walk" and mouth and near(leg.points[1].u, cu)
        and near(leg.points[#leg.points].u, eu), "the player in the cave: the line from the cave's floor, out by its mouth")
    -- The line always from the player: walking along it, the parts behind are gone, a line runs from the player's
    -- arrow to it; off it by Planner.OFF yards, planned again from there.
    local first, second = leg.points[1], leg.points[2]
    local wu, wv = first.u + (second.u - first.u) * 0.5, first.v + (second.v - first.v) * 0.5 + 3
    Planner.Track(1414, wu, wv, GetTime() + 500)
    local cut = shownWay.cut
    check(cut and cut.leg == 1 and cut.index == 1 and math.abs(cut.t - 0.5) < 0.1 and math.abs(cut.gap - 3) < 1
        and cut.pu == wu and cut.pv == wv, "walking along it: where along the line the player is (the cut)")
    local camera = Canvas.camera
    local was = { camera.map, camera.u, camera.v, camera.k }
    camera:Show(1414, wu, wv)
    Canvas.Layout()
    local view = Canvas.view
    local hx, hy = (wu - view.u) * view.k, (wv - view.v) * view.k
    local headed, behind = false, false
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Line" and widget._shown and widget._start then
            if near(widget._start[1], hx) and near(widget._start[2], hy) then headed = true end
            if near(widget._start[1], (first.u - view.u) * view.k) and near(widget._start[2], (first.v - view.v) * view.k) then
                behind = true
            end
        end
    end
    check(Canvas.Laid() and headed and not behind, "the line drawn from the player's arrow, nothing of it behind them")
    camera:Show(was[1], was[2], was[3], was[4])
    Canvas.Layout()
    local before = shownWay
    player.x, player.y = (wu + 12000) / 24000, (20000 - (wv - 60)) / 40000
    Planner.Track(1414, wu, wv - 60, GetTime() + 520)
    Frames(8)
    check(shownWay ~= before and shownWay and near(shownWay.legs[1].points[1].v, wv - 60),
        "off the line by more than Planner.OFF yards: planned again from where the player is")
    IsIndoors = indoors
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- Journeys: a pin nobody can walk to still gets its line (as near as one walks, then straight); across three planes
-- (the isle, the Eastern Kingdoms, Kalimdor), by the hearthstone or the zeppelin, then the boat; a flight over two
-- flight points one leg; a new pin while aboard a boat the plan did not have: planned from where it lands.
;(function()
    local s = Walk.SAMPLE
    local function Pin(map, x, y)
        waypoint = { uiMapID = map, position = CreateVector2D(x, y) }
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        Frames(8)
        return shownWay and shownWay.legs or {}
    end
    local function Kinds(legs)
        local list = {}
        for index, leg in ipairs(legs) do list[index] = leg.kind end
        return table.concat(list, " ")
    end
    -- In the corner of tile 3104 nobody can walk to (region 7), 25 yards past the east hall: to the hall's edge, then
    -- straight to it.
    local legs = Pin(1429, (244 * s + 1000) / 2000, (-8500 - (-8533.33 - 252 * s)) / 1500)
    local walk = legs[1]
    local points = walk and walk.points or {}
    local edge = points[#points - 1]
    check(#legs == 1 and walk.kind == "walk" and near(points[1].u, 500) and edge and math.abs((-8533.33 - edge.v) / s - 240) < 0.1
        and near(points[#points].v, -8533.33 - 252 * s), "a pin nobody can walk to: as near as one walks, then straight to it")
    -- From the isle to Kalimdor: the hearthstone home to the Eastern Kingdoms, on foot to the boat, the boat, on foot;
    -- without it, the zeppelin to the Eastern Kingdoms first.
    player.map, player.x, player.y = 2521, 0.5, 0.4
    legs = Pin(1414, 0.875, 0.325)
    check(Kinds(legs) == "hearth walk boat walk" and legs[1].points[2].map == 1415 and legs[3].points[#legs[3].points].map == 1414,
        "from the isle to Kalimdor: the hearthstone to a third plane, the Eastern Kingdoms, then the boat")
    -- Its line from one plane onto another: where it begins, the player is on it; brought home, on it there.
    local planned = shownWay
    Planner.Track(2521, 0, 0, GetTime() + 600)
    Frames(8)
    local cut = shownWay and shownWay.cut
    check(shownWay == planned and cut.leg == 1 and cut.gap < 1, "where the hearthstone's line begins: on it, no new plan")
    Planner.Track(1415, 0, -9250, GetTime() + 610)
    Frames(8)
    check(shownWay == planned and cut.gap < 1 and (cut.leg == 2 or cut.t == 1),
        "brought home by it, on the other plane: on the line there, no new plan")
    local count = C_Item.GetItemCount
    C_Item.GetItemCount = function() return 0 end
    Planner.Update()
    Frames(8)
    legs = shownWay and shownWay.legs or {}
    check(Kinds(legs) == "walk zeppelin walk boat walk" and legs[2].points[#legs[2].points].map == 1415,
        "without the hearthstone: the zeppelin to the Eastern Kingdoms, on foot to the boat, the boat")
    C_Item.GetItemCount = count
    -- Two flights one after the other (Alpha to Beta to Gamma, the set's flights 5 and 6): one leg, along both ways.
    local nodes = C_TaxiMap.GetTaxiNodesForMap
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        if map ~= 1415 then return {} end
        return { { nodeID = 20, name = "Alpha", position = CreateVector2D(0.5, 0.2), faction = 0 },
                 { nodeID = 21, name = "Beta", position = CreateVector2D(0.5, 0.15), faction = 0 },
                 { nodeID = 22, name = "Gamma", position = CreateVector2D(0.375, 0.15), faction = 0 } }
    end
    local known = Core.Character(ns.name).flights
    Core.Character(ns.name).flights = { [20] = true, [21] = true, [22] = true }
    player.map, player.x, player.y = 1415, 0.5, 0.205
    legs = Pin(1415, 0.375, 0.145)
    local flight = legs[2]
    check(Kinds(legs) == "walk flight walk" and #flight.points == 3 and near(flight.points[2].v, 1000) and near(flight.points[3].u, -1000),
        "two flights one after the other: one leg along both their ways, taking off and landing once")
    C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flights = nodes, known
    -- Aboard the boat (Core's Data.Trips found the ride), the plan without it: a pin on Kalimdor is planned from the
    -- pier the boat comes to, its way on in front.
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    local d12 = math.sqrt(600 ^ 2 + 1550 ^ 2)
    local left = W.serverStart + W.clock - 45 -- it left its dock 45 seconds ago: at full speed now
    W.place = function()
        local seconds = W.serverStart + W.clock - left
        local sailed = Core.Data.Ships().SPEED ^ 2 / 2 + Core.Data.Ships().SPEED * (seconds - Core.Data.Ships().SPEED)
        local f = math.min(1, sailed / d12)
        return { -8600 + 600 * f, -450 - 1550 * f, 5, 0 }
    end
    for _ = 1, 6 do W.Wait(1) end
    local trip = Core.Data.Trips():Now()
    player.map, player.x, player.y = 1415, 0.6, 0.62
    legs = Pin(1414, 0.875, 0.325)
    local ride = legs[1]
    local last = ride and ride.points[#ride.points]
    check(trip and trip.kind == "boat" and Kinds(legs) == "boat walk" and ride.ship and last.map == 1414 and near(last.u, 9500)
        and near(last.v, 6000) and near(legs[2].points[#legs[2].points].u, 9000),
        "aboard a boat the plan did not have: its way on in front, planned from the pier it comes to")
    W.place = nil
    W.Wait(3)
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- Lifts (Core's set Travel, Lifts.lua), on Kalimdor's tile 6177: lift 8 up the mesa's cliff from the field, lift 9 down
-- from the courtyard into the hall under it. Each end on its landing; the levels they join, side by side and stacked;
-- a pin on the mesa or in the hall reached by its lift (walk, lift, walk), never by a walk between two levels a lift
-- joins; out of the hall again; the floor after a ride (and not without one); a pin on the courtyard over the hall by
-- the map it is on; the lifts on the map.
;(function()
    MAPS[1456] = { kind = 3, parent = 1414, continent = 1, top = 1000, bottom = -1000, left = 0, right = -2000 }
    local Lifts, s = ns.Lifts, Walk.SAMPLE
    local function At(column, row) return Coords.TILE + column * s, -row * s end
    local function Pin(map, u, v)
        local info = MAPS[map]
        waypoint = { uiMapID = map, position = CreateVector2D((-u - info.left) / (info.right - info.left),
                                                             (v - info.top) / (info.bottom - info.top)) }
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        Frames(8)
        return shownWay and shownWay.legs or {}
    end
    local function Kinds(legs)
        local list = {}
        for index, leg in ipairs(legs) do list[index] = leg.kind end
        return table.concat(list, " ")
    end
    local function Stand(u, v)
        player.map, player.x, player.y = 1414, (u + 12000) / 24000, (20000 - v) / 40000
    end
    local function Close(point, u, v) return math.abs(point.u - u) < 0.5 and math.abs(point.v - v) < 0.5 end
    local lifts = {}
    for _, lift in ipairs(Lifts.All()) do lifts[lift.key] = lift end
    local up, down, isle = lifts[8], lifts[9], lifts[10]
    check(up and down and isle and up.map == 1414 and isle.map == 2521 and near(up.u, 800) and Lifts.Landed(up[1])
        and Lifts.Landed(up[2]) and up[1].region == 3 and up[2].region == 4 and Lifts.Landed(down[1])
        and Lifts.Landed(down[2]) and down[1].region == 5 and down[2].region == 3 and not Lifts.Landed(isle[1]),
        "each end of a lift on its landing, the floor by its shaft at its height (the field's and the mesa's, the hall's "
        .. "and the courtyard's); none where the walking data has no floor")
    local levels = Lifts.Levels(1414)
    local beside, stacked
    for _, level in ipairs(levels) do
        if level.lower == 3 then beside = level elseif level.lower == 5 then stacked = level end
    end
    check(#levels == 3 and beside and beside.upper == 4 and not beside.stacked and stacked and stacked.upper == 3
        and stacked.stacked and stacked.maps[1456], "the levels the lifts join: the mesa beside the field, the courtyard over the hall")
    check(Lifts.Joined({ [3] = true }, { [4] = true }, 1414) and Lifts.Joined({ [5] = true }, { [3] = true }, 1414)
        and not Lifts.Joined({ [4] = true }, { [5] = true }, 1414), "joined: two levels one lift joins")
    -- From the field to the mesa: walk to the lift, up, walk on; no walk between the field and the mesa.
    local fu, fv = At(40, 64)
    Stand(fu, fv)
    local mu, mv = At(200, 60)
    local legs = Pin(1414, mu, mv)
    local lift = legs[2]
    check(Kinds(legs) == "walk lift walk" and Close(legs[1].points[#legs[1].points], 800, -133.33) and lift.near == up[1]
        and lift.far == up[2] and Close(legs[3].points[#legs[3].points], mu, mv),
        "a pin on the mesa: on foot to the lift, up it, on foot to the pin")
    -- Into the hall under the courtyard: the pin stands in it (the lift's lower level under the courtyard there).
    local hu, hv = At(200, 200)
    legs = Pin(1414, hu, hv)
    check(Kinds(legs) == "walk lift walk" and legs[2].near == down[2] and legs[2].far == down[1]
        and Close(legs[3].points[#legs[3].points], hu, hv), "a pin in the hall: on foot to the lift, down it, on foot to the pin")
    -- On the courtyard beyond the hall: on its map (the lifts'), over the city its lift goes down to; on another, where
    -- its floor is.
    local cu, cv = At(250, 250)
    check(Kinds(Pin(1414, cu, cv)) == "walk" and Kinds(Pin(1456, cu, cv)) == "walk lift walk",
        "a pin on the courtyard beside the hall: on the courtyard; on the lifts' own map, in the hall beside it")
    -- Out of the hall: from its floor (indoors the lowest under the player) to the lift, up, to the field.
    local indoors = IsIndoors
    IsIndoors = function() return true end
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Stand(At(190, 210))
    legs = Pin(1414, fu, fv)
    check(Kinds(legs) == "walk lift walk" and legs[2].near == down[1] and legs[2].far == down[2],
        "out of the hall: on foot to the lift, up it, on foot to the pin")
    IsIndoors = indoors
    -- A lift within one region (11, on tile 6178: the hall under the courtyard, one region as the Undercity is with the
    -- ruins over it): its levels told apart by height round it, joining no two regions; a pin in the hall by the lift
    -- (no walk ending on the courtyard over it), one on the courtyard beyond the hall on foot, and out of the hall.
    local alone, one = lifts[11], nil
    for _, level in ipairs(levels) do
        if level.alone then one = level end
    end
    check(alone and Lifts.Landed(alone[1]) and Lifts.Landed(alone[2]) and alone[1].region == 6 and alone[2].region == 6
        and one and one.alone == alone and one.lower == 6 and one.upper == 6 and one.stacked and one.split == -5
        and not Lifts.Joined({ [6] = true }, { [6] = true }, 1414),
        "a lift within one region: the levels round it stacked, told apart by height; it joins no two regions")
    local function In6178(column, row) return 2 * Coords.TILE + column * s, -row * s end
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Stand(In6178(20, 20))
    local inU, inV = In6178(100, 64)
    legs = Pin(1414, inU, inV)
    check(Kinds(legs) == "walk lift walk" and legs[2].near == alone[2] and legs[2].far == alone[1]
        and Close(legs[3].points[#legs[3].points], inU, inV),
        "a pin in the hall under the courtyard of its region: on foot to the lift, down it, on foot to the pin")
    check(Kinds(Pin(1414, In6178(230, 110))) == "walk", "a pin on the courtyard beyond the hall: on foot")
    IsIndoors = function() return true end
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Stand(In6178(110, 70))
    legs = Pin(1414, In6178(20, 20))
    check(Kinds(legs) == "walk lift walk" and legs[2].near == alone[1] and legs[2].far == alone[2],
        "out of that hall: on foot to the lift, up it, on foot to the pin")
    IsIndoors = indoors
    -- The floor after a ride: at the lift as long as it rides, then on along the line past it: on the mesa now, and a pin
    -- there is a walk; at it as long, then back the way one came: not.
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Stand(fu, fv)
    legs = Pin(1414, mu, mv)
    local clock = GetTime() + 1000
    local function Go(points, first, last)
        for index = first, last, first <= last and 1 or -1 do
            local point = points[index]
            for _ = 1, 4 do
                clock = clock + 0.25
                Stand(point.u, point.v)
                Planner.Track(1414, point.u, point.v, clock)
            end
        end
    end
    local function Wait(u, v, seconds)
        for _ = 1, seconds * 4 do
            clock = clock + 0.25
            Planner.Track(1414, u, v, clock)
        end
    end
    local walk = legs[1].points
    Go(walk, 1, #walk)
    Wait(800, -133.33, 11)
    Go(walk, #walk, 1)
    local back = not legs[2].rode
    Go(walk, 1, #walk)
    Wait(800, -133.33, 11)
    Go(legs[3].points, 1, math.min(4, #legs[3].points))
    local rode = legs[2].rode
    local there = legs[3].points[math.min(4, #legs[3].points)]
    check(back and rode and Kinds(Pin(1414, there.u + 10, there.v + 10)) == "walk",
        "after a ride on the line's lift, on its other level: a pin there is a walk; not after going back without one")
    -- The lifts on the map: a place each at its shaft on its map, a lift; its pin named so, not yet confirmed by the game.
    local onMap = {}
    for _, place in ipairs(Core.Data.Map():On(1456) or {}) do onMap[place.key] = place end
    check(onMap["travel:8"] and onMap["travel:8"].what == "lift" and onMap["travel:9"] and #Core.Data.Map():On(1456) == 2,
        "the lifts on the map: one place each, at its shaft")
    local was, using = { full.map, full.u, full.v, full.k }, Canvas.camera
    Canvas.Use(full)
    full:Show(2521, -600, 500, 0.5)
    Canvas.Layout()
    local pin = Drawn(true)["travel:10"]
    GameTooltip._text, GameTooltip._lines = nil, nil
    if pin then pin._scripts.OnEnter(pin) end
    check(pin and pin.icon._atlas == "poi-door-up" and GameTooltip._text == Pins.WAY_WORDS.lift
        and GameTooltip._lines and GameTooltip._lines[1] == Pins.TEXT.unverified,
        "a lift's pin: its look, named a lift, not yet confirmed by the game")
    full:Show(was[1], was[2], was[3], was[4])
    Canvas.Use(using)
    Canvas.Layout()
    MAPS[1456] = nil
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
ns.Route.Show = show

os.execute(("rm -rf '%s'"):format(routesFolder))

-- (a function of its own: the main chunk has as many locals as Lua lets it)
;(function()
-- Herbs and ore (Nodes.lua): known by their names, each in the picture of what it gives.
local Nodes, Found = ns.Nodes, ns.Found
W.items[765], W.items[2770], W.items[2835] = { name = "Silverleaf" }, { name = "Copper Ore" }, { name = "Rough Stone" }
C_Item.GetItemInfoInstant = function(id) return id, nil, nil, nil, 3000 + id, 7, id == 765 and 9 or 7 end
local silverleaf, vein = Nodes.Find("Silverleaf"), Nodes.Find("Copper Vein")
check(silverleaf and silverleaf.kind == "herb" and vein and vein.kind == "ore" and Nodes.Find("A Wolf") == nil,
    "a herb and an ore known by their names, nothing else")
check(Nodes.Picture(silverleaf) == 3765 and Nodes.Picture(vein) == 5770, "each in the picture of its herb, its ore (not the stone)")
-- The finder that is on: asked of the game once, again only after the game says its tracking changed.
do
    local info, asked = C_Minimap.GetTrackingInfo, 0
    C_Minimap.GetTrackingInfo = function(index) asked = asked + 1 return info(index) end
    W.Fire("MINIMAP_UPDATE_TRACKING")
    Nodes.Active()
    local once = asked
    Nodes.Active()
    check(once > 0 and asked == once, "the finder that is on asked of the game once, not each time it is wanted")
    W.Fire("MINIMAP_UPDATE_TRACKING")
    Nodes.Active()
    check(asked > once, "asked again once the game says its tracking changed")
    C_Minimap.GetTrackingInfo = info
end

-- The pin filter's Found herbs and Found ore switch the finders, silently.
do
    local chosen = Core.Copy(ns.options.pins)
    check(chosen.foundHerb and chosen.foundOre, "found herbs and ore: on (brought up to date from an older shape)")
    chosen.foundHerb = nil
    Core.Set(ns.name, "pins", chosen)
    check(gather.tracking[2].active and not gather.tracking[1].active and gather.switches[#gather.switches].sounds == "0",
        "Found herbs off: Find Minerals comes on, the effect sounds off for it")
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 2580)
    W.Wait(Nodes.AFTER + 0.01)
    check(C_CVar.GetCVar("Sound_EnableSFX") == "1" and ns.store.sounds == nil, "its cast through: the sounds as they were")
    chosen = Core.Copy(chosen)
    chosen.foundOre = nil
    Core.Set(ns.name, "pins", chosen)
    check(not gather.tracking[2].active and not gather.tracking[1].active, "Found ore off too: no finder")
    W.Wait(Nodes.AFTER + 0.01)
    check(C_CVar.GetCVar("Sound_EnableSFX") == "1", "the sounds back after it, no cast to wait for")
    chosen = Core.Copy(chosen)
    chosen.foundHerb, chosen.foundOre = true, true
    Core.Set(ns.name, "pins", chosen)
    check(gather.tracking[1].active and not gather.tracking[2].active, "both on again: Find Herbs")
    W.Wait(Nodes.QUIET + 0.01)
    check(C_CVar.GetCVar("Sound_EnableSFX") == "1", "no cast heard of: the sounds back after a while all the same")
    -- In turn while you move.
    local count = #gather.switches
    W.Wait(ns.options.nodeTurns + 1)
    check(#gather.switches == count, "standing still: no turn")
    gather.speed = 7
    W.Wait(ns.options.nodeTurns + 1)
    check(#gather.switches == count + 1 and gather.tracking[2].active, "moving: Find Minerals in turn after the setting's seconds")
    gather.speed = 0
    W.Wait(Nodes.QUIET + 0.01)
end

-- Found herbs (Found.lua): the game's minimap gather.asked, the herb drawn on its dot in its picture.
gather.tracking[1].active, gather.tracking[2].active = true, false
W.Fire("MINIMAP_UPDATE_TRACKING") -- as the game says when its tracking changed
for _, widget in ipairs(W.frames) do
    if widget._parent == minimap and widget._scripts.OnUpdate then gather.overlay = widget end
end
check(gather.overlay and gather.overlay._shown, "a frame of ours over the game's minimap")
local function Sweeps(count)
    for _ = 1, count do
        gather.overlay._scripts.OnUpdate(gather.overlay, 0.016)
        W.Wait(Found.REST)
    end
end
local function Pictures()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == gather.overlay and widget._kind == "Texture" and widget._shown and widget._texture == 3765 then
            list[#list + 1] = widget
        end
    end
    return list
end
gather.dots[1] = { 20, 30, "Silverleaf" }
Sweeps(40)
local herbs = Pictures()
local point = herbs[1] and herbs[1]._points[1]
check(#herbs == 1 and point and math.abs(point[4] - 20) < 1.5 and math.abs(point[5] - 30) < 1.5 and minimap._soft == false,
    "the herb on its dot, in its picture; the minimap's soft cursor off again")
do
    local spot
    for _, widget in ipairs(W.frames) do
        if widget._parent == gather.overlay and widget._kind == "Button" and widget._shown then spot = widget end
    end
    check(spot and spot._points[1][1] == "TOPLEFT" and spot._points[1][2] == herbs[1], "the picture takes the mouse, as a pin does")
    spot._scripts.OnEnter(spot)
    check(GameTooltip._text == "Silverleaf", "its tooltip names the herb")
    local saved = waypoint
    waypoint = nil
    spot._scripts.OnClick(spot)
    check(waypoint and waypoint.uiMapID == 1429 and waypoint.position.x > 0 and waypoint.position.x < 1
        and waypoint.position.y > 0 and waypoint.position.y < 1, "a click: the game's map pin where it is, on its zone's map")
    waypoint = saved
end
gather.dots[1] = nil
Sweeps(40)
check(#Pictures() == 0, "gathered (no dot any more): gone")
check(gather.asked > 0, "gather.asked the game's minimap")
-- One of the finder's own kind left behind (gathered by another while you went on, 1000 yards west): gone once too
-- far, as those of the other kind; back there, not drawn.
gather.dots[1] = { 20, 30, "Silverleaf" }
Sweeps(40)
check(#Pictures() == 1, "a herb on the game's minimap: drawn")
gather.dots[1] = nil
player.x = 0.25
Sweeps(40)
player.x = 0.75
gather.overlay._scripts.OnUpdate(gather.overlay, 0.016)
check(#Pictures() == 0, "a herb left far behind, out of the minimap's reach: forgotten, not drawn when back")
Sweeps(40)

-- Sparkles (Sparkles.lua): the game's settings for its interact key, the sparkles on the herb's gather.plate.
check(C_CVar.GetCVar("softTargetInteract") == "3" and C_CVar.GetCVar("SoftTargetIconGameObject") == "1"
    and C_CVar.GetCVar("SoftTargetInteractRange") == "20", "the interact key's settings as the sparkles need them")
gather.soft = "Silverleaf"
local unitName = UnitName
UnitName = function(unit) if unit == "softinteract" then return gather.soft end return unitName(unit) end
W.Fire("PLAYER_SOFT_INTERACT_CHANGED")
W.Wait(0)
local sparkles
for _, widget in ipairs(W.frames) do if widget._parent == gather.plate then sparkles = widget end end
check(sparkles and sparkles._shown, "a herb picked: sparkles on its gather.plate")
gather.soft = nil
W.Fire("PLAYER_SOFT_INTERACT_CHANGED")
W.Wait(0)
check(not sparkles._shown, "nothing picked: no sparkles")
Core.Set(ns.name, "nodeSparkles", false)
check(C_CVar.GetCVar("softTargetInteract") == "1" and C_CVar.GetCVar("SoftTargetIconGameObject") == "0"
    and C_CVar.GetCVar("SoftTargetInteractRange") == "10", "the sparkles off: the settings as they were")
Core.Set(ns.name, "nodeSparkles", true)
end)()

-- The dungeons of Core's set Dungeons, which the game has no map of (Forever's client has none): their floors, the
-- game's tiles, the bosses' marks with their names (the set Encounters); no player inside (the game tells no place).
;(function()
    local Dungeons = ns.Dungeons
    -- A model's look, as the game keeps it.
    W.methods.SetDisplayInfo = function(self, display) self._display, self._cleared = display, nil end
    W.methods.ClearModel = function(self) self._cleared = true end
    if Canvas.camera ~= Window.full then
        Window.Toggle()
        Window.frame._group:Run(1)
    end
    Dungeons.List()
    Frames(12)
    local entry
    for _, each in ipairs(Dungeons.List()) do if each.name == "Deep Halls" then entry = each end end
    check(entry and #entry.floors == 2 and entry.floors[1].map == "90:1" and entry.floors[2].map == "90:2"
        and entry.floors[2].name == "Lower" and Dungeons.Key(90) == "90:1" and Dungeons.Key(91) == nil,
        "a dungeon of Core's set in the list: its floors keyed by its instance, lowest first")
    local function Shown(low, high)
        local count = 0
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Texture" and widget._shown and type(widget._texture) == "number"
                and widget._texture >= low and widget._texture <= high then count = count + 1 end
        end
        return count
    end
    local function Marks()
        local found = {}
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Texture" and widget._atlas == Dungeons.BOSS and widget._parent._shown then
                found[#found + 1] = widget._parent
            end
        end
        return found
    end
    Dungeons.frame._width, Dungeons.frame._height = 1600, 868 -- as large as the canvas
    check(Canvas.Show("90:1") and Dungeons.Shown() == "90:1" and Shown(9001, 9012) == 12,
        "its upper floor shown, in the game's tiles the set names")
    local marks = Marks()
    check(#marks == 1 and marks[1]._points[1][4] < 0 and near(marks[1]._points[1][5], 0),
        "its boss's mark where it stands: a quarter across, half down")
    -- The game's spells and items: one spell it does not know; one item loaded, one it loads on asking.
    local loaded, asked = { [901] = true }, {}
    local spellInfo, itemInfo, itemIcon, request = C_Spell.GetSpellInfo, C_Item.GetItemInfo, C_Item.GetItemIconByID,
        C_Item.RequestLoadItemDataByID
    C_Spell.GetSpellInfo = function(id) return id == 801 and { name = "Cleave", iconID = 132338 } or nil end
    C_Item.GetItemInfo = function(id) if loaded[id] then return "Item " .. id, nil, 4 end end
    C_Item.GetItemIconByID = function(id) return 1000 + id end
    C_Item.RequestLoadItemDataByID = function(id) asked[#asked + 1] = id end
    ITEM_QUALITY_COLORS = { [4] = { r = 0.64, g = 0.21, b = 0.93 } }
    GameTooltip._lines = nil
    marks[1]._mouseOver = true
    marks[1]._scripts.OnEnter(marks[1])
    local lines = GameTooltip._lines or {}
    check(GameTooltip._text == "The First Boss" and lines[1] == Dungeons.TEXT.abilities and lines[2]:find("Cleave", 1, true)
        and lines[2]:find("132338", 1, true) and lines[3] == Dungeons.TEXT.loot and lines[4]:find("Item 901", 1, true)
        and lines[4]:find("1901", 1, true) and lines[5] == Dungeons.TEXT.unverified and asked[1] == 902,
        "its tooltip: the boss's name as the game's encounters have it, its abilities and loot with their icons as the "
        .. "game has them (a spell it does not know left out, an item not loaded asked for), not yet confirmed")
    loaded[902] = true
    GameTooltip._lines = nil -- (the stand-in keeps its lines; the game's tooltip starts anew at SetOwner)
    W.Fire("ITEM_DATA_LOAD_RESULT", 902, true)
    Frames(1)
    lines = GameTooltip._lines or {}
    check(lines[5] and lines[5]:find("Item 902", 1, true), "the item come: the tooltip drawn again with it")
    marks[1]._mouseOver = false
    C_Spell.GetSpellInfo, C_Item.GetItemInfo, C_Item.GetItemIconByID, C_Item.RequestLoadItemDataByID =
        spellInfo, itemInfo, itemIcon, request
    -- Its enemies where they stand, each a small red dot under the bosses, its name in its tooltip.
    do
        local foes = {}
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Texture" and widget._texture == Dungeons.ENEMY and widget._parent._shown then
                foes[#foes + 1] = widget._parent
            end
        end
        check(#foes == 1 and foes[1]._points[1][4] > 0 and foes[1]._points[1][5] > 0 and foes[1]._level < marks[1]._level,
            "its enemy on this floor where it stands (three quarters across, a quarter down), under the boss's mark")
        foes[1]._scripts.OnEnter(foes[1])
        check(GameTooltip._text == "A Wolf", "its tooltip: the creature's name")
    end
    local model = marks[1].model
    check(model and model._kind == "PlayerModel" and model._display == 4203 and model._shown
        and model._points[1][1] == "BOTTOM" and near(model._points[1][4], marks[1]._points[1][4])
        and model._level > marks[1]._level, "its own model in its look, standing on its mark, over it")
    local bar
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Button" and widget._text == ns.TopBar.TEXT.questLog and not bar then bar = widget._parent end
    end
    check(bar and model._level <= marks[1]._level + 1 + Dungeons.SPREAD and model._level < bar._level,
        "a few levels over its mark only: under the bar over the map, whose clicks it never takes")
    check(not Dungeons.frame._scripts.OnUpdate, "nothing runs each frame while it rests")
    GameTooltip._text = nil
    model._scripts.OnEnter(model)
    check(GameTooltip._text == "The First Boss", "the model's tooltip: the boss")
    -- Dragged 560 to the left: the boss past the view's left edge, its model would reach out of the view.
    local view = Dungeons.frame
    local wasX = cursorX
    view._scripts.OnMouseDown(view, "LeftButton")
    local stepping = view._scripts.OnUpdate
    cursorX = wasX - 560
    view._scripts.OnUpdate(view, 0.01)
    view._scripts.OnMouseUp(view, "LeftButton")
    check(not model._shown and marks[1]._shown and stepping and not view._scripts.OnUpdate,
        "a model that would reach past the view's edge: hidden, its mark stays; the drag's step only while it drags")
    view._scripts.OnMouseDown(view, "LeftButton")
    check(view._scripts.OnUpdate == stepping, "the drag's step: one guarded function, made once")
    cursorX = wasX
    view._scripts.OnUpdate(view, 0.01)
    view._scripts.OnMouseUp(view, "LeftButton")
    check(model._shown, "dragged back: shown again")
    local before, instance = UnitPosition, rawget(_G, "GetInstanceInfo")
    UnitPosition = function() return 0, 0, 0, 0 end
    GetInstanceInfo = function() return "Deep Halls", "party", 1, "", 5, 0, false, 90 end
    local arrow
    for _, widget in ipairs(W.frames) do
        local up = widget._parent
        while up and up ~= view do up = up._parent end
        if up and widget._atlas == "UI-WorldMapArrow" then arrow = widget end
    end
    check(not arrow and Dungeons.Here() == "90:1",
        "inside: the dungeon the game names, at its lowest floor; no arrow (the game tells no place in an instance)")
    check(Dungeons.Show("90:2") and Shown(9101, 9102) == 2 and Shown(9001, 9012) == 0 and #Marks() == 1,
        "the lower floor: its own tiles and boss")
    check(not Marks()[1].model or not Marks()[1].model._shown, "a boss without a look: its mark alone")
    UnitPosition, GetInstanceInfo = before, instance
    Dungeons.Close()
    check(#Marks() == 0 and not model._shown and model._cleared, "closed: no marks, the models let go")
    W.methods.SetDisplayInfo, W.methods.ClearModel = nil, nil
end)()

-- A failure stands the module down: everything given back.
ns.StandDown("a test")
check(ns.off and not Window.frame:IsShown() and not Hybrid.Taken() and next(overrides) == nil and minimap:GetParent() == container,
    "standing down: the window goes, the game's minimap and keys are back")
check(C_CVar.GetCVar("softTargetInteract") == "1" and C_CVar.GetCVar("Sound_EnableSFX") == "1" and not gather.overlay._shown,
    "and the interact key's settings as they were, no found herbs drawn")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Navigation: all %d checks passed.\n"):format(passed))
