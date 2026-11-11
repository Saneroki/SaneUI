-- Runs the Navigation module against the stand-in client (wowstub.lua) on a small made-up world: the map's
-- spaces and the map tree, the camera's levels, what the game tells (Live), the map drawn each way in both
-- views, the views offered and a saved one that is gone, the mouse (drag, wheel, right click, middle click,
-- Ctrl-click), the game's minimap taken over ours and given back, other addons' buttons
-- held in the satchel and given back, the satchel's page, the game's map kept closed and its
-- keys; played as Retail (W.Play), without Forever's data, what stands down and what the game's own does instead.
-- Then again as a Retail client from the start ("retail"): the game's own map tree, one map at a time
-- (Camera.Retail.lua). The look itself can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/navigation.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
W.retailRun = arg[1] == "retail" -- run again as a Retail client from the start (at the end; no local: the chunk has 200)

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
-- Strata and level as the game keeps them: a fixed one stays, whatever is asked; a frame without a strata of its own
-- has its parent's.
function methods:SetFrameLevel(level) if not self._fixedLevel then self._level = level end end
function methods:GetFrameLevel() return self._level or 1 end
function methods:SetFixedFrameLevel(on) self._fixedLevel = on and true or false end
function methods:IsFrameLevelFixed() return self._fixedLevel or false end
function methods:SetFixedFrameStrata(on) self._fixedStrata = on and true or false end
function methods:IsFrameStrataFixed() return self._fixedStrata or false end
function methods:SetBlendMode(mode) self._blend = mode end
function methods:SetTexCoord(...) self._coords = { ... } end
function methods:AddMaskTexture(mask) self._mask = mask end
function methods:RemoveMaskTexture(mask) if self._mask == mask then self._mask = nil end end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetFrameStrata(strata) if not self._fixedStrata then self._strata = strata end end
function methods:GetFrameStrata()
    local parent = self._parent
    return self._strata or (type(parent) == "table" and parent.GetFrameStrata and parent:GetFrameStrata()) or "MEDIUM"
end
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
    function group:Play(_, offset) self.playing, self.progress, self.offset = true, 0, offset end
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
    -- A city under the ground (as the Undercity), its map the box of the continent's tile 2340
    [1460] = { kind = 3, parent = 1415, continent = 0, top = -6400 / 3, bottom = -8000 / 3, left = -6400 / 3,
               right = -8000 / 3 },
}
if W.retailRun then
    -- Retail's tree: the Cosmic map over Azeroth, Outland beside Azeroth under it (a world of its own, 10000 yards
    -- square), and a battleground the tree hangs under Kalimdor in a world of its own (2000 yards square).
    MAPS[946] = { kind = 0, parent = 0 }
    MAPS[947].parent = 946
    MAPS[101] = { kind = 2, parent = 946, continent = 530, top = 5000, bottom = -5000, left = 5000, right = -5000 }
    MAPS[1459] = { kind = 3, parent = 1414, continent = 30, top = 1000, bottom = -1000, left = 1000, right = -1000 }
end
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
        for _, id in ipairs(W.retailRun and { 1415, 1414, 1429, 2521, 947, 101, 1459 } or { 1415, 1414, 1429, 2521 }) do
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
    -- Retail: the Cosmic map has art; Elwynn two layers, the second twice as detailed from 1.5 times its size on.
    GetMapArtLayers = function(map)
        local one = { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 }
        if W.retailRun and map == 946 then return { one } end
        if not MAPS[map] or (not MAPS[map].top and map ~= 947) then return {} end
        if W.retailRun and map == 1429 then
            one.minScale, one.maxScale = 1, 1.5
            return { one, { layerWidth = 2004, layerHeight = 1336, tileWidth = 256, tileHeight = 256, minScale = 1.5, maxScale = 3 } }
        end
        return { one }
    end,
    GetMapArtLayerTextures = function(map, layer)
        local files = {}
        for index = 1, (layer == 2 and 48 or 12) do files[index] = map * 100 + index + (layer == 2 and 50 or 0) end
        return files
    end,
    GetMapInfoAtPosition = function(map, x, y)
        -- Retail's Cosmic map: Azeroth on its left half, Outland on its right
        if map == 946 then return { mapID = x < 0.5 and 947 or 101, mapType = x < 0.5 and 1 or 2 } end
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
        -- Retail's Cosmic map: Azeroth's globe in a piece of an atlas, about its link's box on the map
        if map == 946 and x < 0.5 then return 0, "worldmap-highlight-cosmic-azeroth", 1, 1, 0.332, 0.495, 0.348, 0.25 end
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
-- The way to each quest as the game measures it (the done one nearer), its tag, a done one's words to turn it in.
local questDistance = { [7] = 400, [8] = 100 }
C_QuestLog.GetDistanceSqToQuest = function(quest) return questDistance[quest], true end
C_QuestLog.GetQuestTagInfo = function(quest) return quest == 7 and { tagName = "Elite", tagID = 1 } or nil end
C_QuestLog.IsEliteQuest = function() return false end
C_QuestLog.GetNextWaypointText = function() return nil end
GetQuestLogCompletionText = function(index) return index == 3 and "Report back to Marshal Dughan." or nil end
ObjectiveTrackerFrame = CreateFrame("Frame", "ObjectiveTrackerFrame", UIParent) -- the game's quest tracker
function methods:SetHitRectInsets(left, right, top, bottom) self._hit = { left, right, top, bottom } end
-- A quest's item, as the game's tracker shows it: [log index] = { link, picture, charges, shown when done }.
W.special = {}
GetQuestLogSpecialItemInfo = function(index)
    local item = W.special[index]
    if item then return item[1], item[2], item[3], item[4] end
    return nil
end
W.drivers = {} -- [frame] = the game's state driver of its visibility
RegisterStateDriver = function(frame, _, rule) W.drivers[frame] = rule end
UnregisterStateDriver = function(frame) W.drivers[frame] = nil end
BaseScrollBoxEvents = { OnScroll = "OnScroll" }
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._registered = { ... } end
function methods:GetRight() return self._right or 0 end
function methods:GetTop() return self._top or 0 end
function methods:SetJustifyH(side) self._justify = side end
function methods:SetWordWrap(on) self._wrap = on end
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
IsAltKeyDown = function() return false end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
-- The game's scrolling list, as far as the quest log uses it: what it was given to show, drawn on demand.
W.templates.WowScrollBoxList = function(box)
    function box:SetDataProvider(provider) self.provider = provider end
    function box:HasScrollableExtent() return self._long or false end -- longer than its room (the test says)
    function box:RegisterCallback(event, fn) self.scrolled = event == BaseScrollBoxEvents.OnScroll and fn or self.scrolled end
    function box:ForEachFrame(fn) for _, element in ipairs(self.rows or {}) do fn(element) end end
    function box:ScrollToElementData(row, alignment) self.brought, self.aligned = row, alignment end
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
ScrollBoxConstants = { RetainScrollPosition = true, AlignBegin = 0, AlignNearest = -1 }
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
function minimap:SetPassThroughButtons() error("the game blocks SetPassThroughButtons for addons") end
minimap._clicks = true
function minimap:SetMouseClickEnabled(on) self._clicks = on end
function minimap:IsMouseClickEnabled() return self._clicks end
function minimap:PingLocation(x, y) self._ping, self._pings = { x, y }, (self._pings or 0) + 1 end
-- Its own areas (the engine's quest, bonus objective and dig site blobs): each part's alpha as last set.
minimap._areas = {}
for _, name in ipairs({ "SetQuestBlobInsideAlpha", "SetQuestBlobOutsideAlpha", "SetQuestBlobRingAlpha",
    "SetTaskBlobInsideAlpha", "SetTaskBlobOutsideAlpha", "SetTaskBlobRingAlpha",
    "SetArchBlobInsideAlpha", "SetArchBlobOutsideAlpha", "SetArchBlobRingAlpha" }) do
    minimap[name] = function(self, alpha) self._areas[name] = alpha end
end
-- Whether every part of its own areas stands at that alpha (a field: the main chunk has no room for more locals).
function minimap._AreasAt(alpha)
    local count = 0
    for _, set in pairs(minimap._areas) do
        if set ~= alpha then return false end
        count = count + 1
    end
    return count == 9
end
minimap.ZoomIn = W.NewWidget("Button", nil, minimap)
minimap.ZoomIn._mouse = true
local backdrop = W.NewWidget("Frame", "MinimapBackdrop", minimap)
rawset(_G, "MinimapCluster", cluster)
rawset(_G, "Minimap", minimap)
rawset(_G, "MinimapBackdrop", backdrop)
-- Other addons' buttons round it (Strays.lua): an addon's (its global set by that addon, as the game tells by
-- issecurevariable), a frame of that addon too large for a button, and a button of the game's own on the cluster;
-- the game's addon compartment with two addons, the first the same addon. Kept in W (the chunk has 200 locals).
W.insecure = { PretendAddonButton = "PretendAddon", PretendAddonOverlay = "PretendAddon" }
function issecurevariable(name) return W.insecure[name] == nil, W.insecure[name] end
function methods:GetName() return self._name end
function methods:IsObjectType(kind) return self._kind == kind end
function methods:GetDrawLayer() return self._layer end
function methods:SetAttribute(name, value)
    self._attributes = self._attributes or {}
    self._attributes[name] = value
end
-- A texture's part of its file, as the game tells it: its corners, upper left, lower left, upper right, lower right.
function methods:GetTexCoord()
    local c = self._coords or {}
    if #c == 8 then return unpack(c) end
    local l, r, t, b = c[1] or 0, c[2] or 1, c[3] or 0, c[4] or 1
    return l, t, l, b, r, t, r, b
end
function methods:GetRegions()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == self and (widget._kind == "Texture" or widget._kind == "FontString") then list[#list + 1] = widget end
    end
    return unpack(list)
end
-- A scroll frame's place (the satchel's page): none past its range.
function methods:SetVerticalScroll(offset) self._scroll = offset end
function methods:GetVerticalScroll() return self._scroll or 0 end
function methods:GetVerticalScrollRange() return 0 end
W.stray = W.NewWidget("Button", "PretendAddonButton", minimap)
W.stray:SetSize(31, 31)
W.stray:SetPoint("TOPLEFT", minimap, "TOPLEFT", 4, -4)
-- Its art as the common minimap buttons have it: a dark round background, its picture, the golden ring over it.
for _, part in ipairs({ { "BACKGROUND", 136467, 20 }, { "ARTWORK", 133784, 17 }, { "OVERLAY", 136430, 53 } }) do
    local texture = W.stray:CreateTexture()
    texture:SetDrawLayer(part[1])
    texture:SetTexture(part[2])
    texture:SetSize(part[3], part[3])
end
W.overlay = W.NewWidget("Frame", "PretendAddonOverlay", minimap)
W.overlay:SetSize(198, 198)
W.gameButton = W.NewWidget("Button", "GameTimeFrame", cluster)
W.gameButton:SetSize(40, 40)
for _, frame in ipairs({ W.stray, W.overlay, W.gameButton }) do
    frame._mouse = true
    rawset(_G, frame._name, frame)
end
W.addons[#W.addons + 1] = { name = "PretendAddon", title = "|cff33ff99Pretend|r Addon", metadata = {} }
AddonCompartmentFrame = W.NewWidget("DropdownButton", "AddonCompartmentFrame", cluster)
AddonCompartmentFrame.registeredAddons = {
    { text = "Pretend Addon", icon = "Interface\\Icons\\INV_Misc_QuestionMark", func = function() end },
    { text = "Compartment Addon", icon = 134400, func = function(_, input) W.compartment = input.buttonName end },
}
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
UnitIsGhost = function() return false end
UnitCastingInfo = function() return nil end
UnitChannelInfo = function() return nil end
GetLootSourceInfo = function() return nil end
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
    .. 'R[79] = "70245\t\tThe First Boss\t\telite\t\t"\n'
    .. 'R[75] = "70245\t\tA Teacher\ttrainer\tnormal\t\tWarrior Trainer"\n'
    .. 'S.unverified = "69\\03070\\03071\\03072\\03073\\03074\\03075"\n')
Set(packPath .. "/Objects.lua", "Objects", "00000004", "int", '"name", "kind", "skill", "skillLevel"', '"text", "text", "int", "int"',
    'R[1617] = "70245\t\tSilverleaf\therb\t182\t1"\nR[1731] = "70245\t\tCopper Vein\tore\t186\t1"\n'
    .. 'I.byName = {}\nI.byName.Silverleaf = "1617"\nI.byName["Copper Vein"] = "1731"\n')
-- What a herb and a vein give: the herb; stone first, then the ore (the vein's picture is the ore's).
Set(packPath .. "/Drops.lua", "Drops", "0000000a", "text", '"items"', '"list tuple(item:int,how:text)"',
    'R["object:1617"] = "70245\t\t765\031gather"\nR["object:1731"] = "70245\t\t2835\031gather\0302770\031gather"\n')
Set(packPath .. "/Places.lua", "Places", "00000005", "int", '"kind", "name", "point", "to", "levelMin", "levelMax"',
    '"text", "text", "point", "int", "int", "int"',
    'R[1] = "70245\t\tdungeon\tThe Mines\t1429\03130\03130\t500\t18\t23"\n'
    .. 'R[2] = "70245\t\tmailbox\t\t1429\03170\03170\t\t\t"\n'
    .. 'S.unverified = "1\\0302"\n')
-- The boat's way round has its docks on the maps too: in the east hall, and on Kalimdor in the game's area 12.
Set(packPath .. "/Travel.lua", "Travel", "00000006", "int",
    '"kind", "name", "from", "to", "fromNode", "toNode", "length", "path", "docks", "dockAreas", "time", "wait", "side", '
    .. '"spell", "items", "reagent", "class"',
    '"text", "text", "point", "point", "int", "int", "number", "list tuple(x:number,y:number,map:int,stay:number,jump:bool,z:number)", '
    .. '"list point", "list int", "number", "number", "text", "int", "list int", "int", "int"',
    'R[1] = "70245\t\tboat\tTo the west\t1429\03190\03190\t1414\03150\03150\t\t\t"\n'
    .. 'R[2] = "70245\t\tflight\t\t\t\t2\t5\t6000"\n'
    .. 'R[3] = "70245\t\tboat\t\t\t\t\t\t3898.1\t-8600\031-450\0310\03160\030-8000\031-2000\0305000\031-9000\0311\031\0311'
    .. '\0306000\031-9500\031\03160\0305000\031-9000\030-8000\031-2000\0310\031\0311'
    .. '\t1429\03172.5\0316.7\0301414\03189.6\03135\t0\03012\t\t\talliance"\n'
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
    -- And one in the city on the Eastern Kingdoms' tile 2340, within one region too, on the city's map 1460 (13: x
    -- -2400, y -2200, from -40 to 60 yards).
    .. 'R[13] = "70245\t\tlift\t\t1460\03112.5\03150\t1460\03112.5\03150\t\t\t100'
    .. '\t-2400\031-2200\0310\031\031\031-40\030-2400\031-2200\031\031\031\03160\t\t\t3.5\t16"\n'
    -- A portal (12): its trigger on the west field of tile 6176 (world x -208.33, y -62.5, 10 yards), where it brings
    -- one on the city's building floor of tile 6179 (x -66.67, y -1666.67, 50 yards), on no zone map; the warriors'
    -- only (class 1: the character's here), as the mages' portals are theirs.
    .. 'R[12] = "70245\t\tportal\t\t\t\t\t\t1606'
    .. '\t-208.33\031-62.5\0311\031\031\03110\030-66.67\031-1666.67\031\031\031\03150\t\t\t\t\talliance\t\t\t\t1"\n'
    -- A portal a few yards across (14): on tile 6179 from the building's floor (world x -16.67, y -1616.67, 50 yards)
    -- up onto its roof (x -41.67, y -1641.67, 65 yards), of both sides.
    .. 'R[14] = "70245\t\tportal\t\t\t\t\t\t36'
    .. '\t-16.67\031-1616.67\0311\031\031\03150\030-41.67\031-1641.67\031\031\031\03165"\n'
    -- Teleports, each where it brings one on Kalimdor (world x 6400, y -9400: plane u 9400, v 6400, by the pin): a mage's
    -- with its reagent, the Alliance's; the Horde's to the same place; a druid's (u 9400, v 6500); an engineer's
    -- transporter (u 9500, v 6400); and one the set knows no place of.
    .. 'R[3003561] = "70245\t\tteleport\tTeleport: Stormwind\t\t\t\t\t\t6400\031-9400\0311\t\t\t\t\talliance\t3561\t\t17031"\n'
    .. 'R[3003567] = "70245\t\tteleport\tTeleport: Orgrimmar\t\t\t\t\t\t6400\031-9400\0311\t\t\t\t\thorde\t3567\t\t17031"\n'
    .. 'R[3018960] = "70245\t\tteleport\tTeleport: Moonglade\t\t\t\t\t\t6500\031-9400\0311\t\t\t\t\t\t18960"\n'
    .. 'R[3023442] = "70245\t\tteleport\tEverlook Transporter\t\t\t\t\t\t6400\031-9500\0311\t\t\t\t\t\t23442\t260820"\n'
    .. 'R[4297659] = "70245\t\tteleport\tTeleport: Dalaran\t\t\t\t\t\t\t\t\t\t\talliance\t1297659\t\t17031"\n'
    -- A flight from Goldshire (node 2) to a flight point the map has none of (99): its way over Elwynn, x -9000 to
    -- -9200 by y 100 (the routes leave it: no such flight point; the map draws it while the mouse is on Goldshire).
    .. 'R[15] = "70245\t\tflight\t\t\t\t2\t99\t300\t-9000\0310\030-9100\031100\030-9200\0310"\n'
    .. 'I.byFromNode = {}\nI.byFromNode[2] = "2\03015"\nI.byFromNode[20] = "5"\nI.byFromNode[21] = "6"\nI.byKind = {}\n'
    .. 'I.byKind.boat = "1\0303"\nI.byKind.flight = "2\0305\0306\03015"\nI.byKind.tram = "7"\nI.byKind.zeppelin = "4"\n'
    .. 'I.byKind.lift = "8\0309\03010\03011\03013"\nI.byKind.portal = "12\03014"\n'
    .. 'I.byKind.teleport = "3003561\0303003567\0303018960\0303023442\0304297659"\n'
    .. 'S.unverified = "8\\0309\\03010\\03011\\03013\\03012\\03014"\n')
-- Elwynn's area (12), and the fishing skill its waters ask (the older game's -70: not yet confirmed).
Set(packPath .. "/Zones.lua", "Zones", "0000001a", "int", '"area"', '"int"', 'R[1429] = "70245\t\t12"\n')
Set(packPath .. "/Fishing.lua", "Fishing", "0000001b", "int", '"skill"', '"int"', 'R[12] = "0\t\t-70"\nS.unverified = "12"\n')
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
    'R[700] = "70245\t\t801\030802\t901\030902"\nS.unverified = "700"\n')
-- An item the game keeps hidden (903), as Core's data has it: its stats learned in play.
Set(dungeonsPath .. "/Items.lua", "Items", "0000000e", "int", '"name", "quality", "icon", "armor", "stats"',
    '"text", "int", "int", "int", "map text int"',
    'R[903] = "70245\t\tHidden Blade\t3\t1903\t50\tITEM_MOD_STAMINA_SHORT\0317"\n')
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
-- it far off, as the Undercity is to the ruins by its sewers). Tile 6179 east of that: the ground (1, 10 yards, region
-- 7) deep under a city's building, its floor (2, 50 yards, region 8), its roof (3, 65 yards, region 9) and a deck east
-- of the roof (4, 59 yards, region 10) a building's. Tile 2340 of the Eastern Kingdoms (its north west corner at u
-- 2133, v -2133), a city under the ground as the Undercity is: the ruins over it (1, 60 yards, region 11) and its long
-- hall (2, -40 yards, columns 0 to 239, rows 112 to 143, a building's floor) of the same region, joined far off.
-- Tiles 2592 to 2595 of the Eastern Kingdoms (row 40, columns 32 to 35; 2592's north west corner at u 0, v -4267), with
-- the coarse layer (the field gates, walkGates below): four fields in a row (region 20, 10 yards high), each open into
-- the next along all its edge; 2593 cut in two by a wall (columns 128 to 143) but at its north end, a door (rows 0 to
-- 15; the halves one surface, the door another, joined by the openings written). Tile 2600 alone, gates only: its
-- costs as numbers to read.
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
    [6179] = { 1, { 1, 1, 7,   1, 3, 8,   1, 3, 9,   1, 3, 10 },
               { 0, 0, 256, 256, 40,   0, 0, 64, 64, 200,   16, 16, 32, 32, 260,   52, 16, 8, 32, 236 }, { 0, 0, 0, 0 } },
    [2340] = { 1, { 1, 1, 11,   1, 3, 11 }, { 0, 0, 256, 256, 240,   0, 112, 240, 32, -160 }, { 0, 0 } },
    [2592] = { 1, { 1, 1, 20 }, { 0, 0, 256, 256, 40 }, { 1, 2 } },
    [2593] = { 1, { 2, 1, 20,   1, 1, 20 }, { 0, 0, 128, 256, 40,   144, 0, 112, 256, 40,   128, 0, 16, 16, 40 },
               { 5, -2, 0, 15, 10, 4,   1, 2,   4, -2, 0, 15, 5 } },
    [2594] = { 1, { 1, 1, 20 }, { 0, 0, 256, 256, 40 }, { 2, 9, 2 } },
    [2595] = { 1, { 1, 1, 20 }, { 0, 0, 256, 256, 40 }, { 1, 4 } },
    [2600] = { 1, { 1, 1, 21 }, { 0, 0, 256, 256, 40 }, { 0 } },
}
-- Their gates (dev/tools/walk-gates' field): one along each border between two of them; through 2593 by its door 718
-- yards from its west gate's middle to its east one's, across 2594 533. 2600's way between its two gates 400 yards,
-- 8 up, 2 down, 100 swum (400 + 2^13 x 8 + 2^23 x 2 + 2^33 x 100), a rider's 520 dry.
local walkGates = {
    [2592] = { 1, 0, 1, {}, { 0, 255, 1 }, {}, {}, {} },
    [2593] = { 1, 0, 3, {}, { 0, 255, 1 }, {}, { 0, 255, 1 }, { 2, 1, 2, 718, 0 } },
    [2594] = { 1, 0, 1, {}, { 0, 255, 1 }, {}, { 0, 255, 1 }, { 2, 1, 2, 533, 0 } },
    [2595] = { 1, 0, 1, {}, {}, {}, { 0, 255, 1 }, {} },
    [2600] = { 1, 0, 1, { 0, 255, 1 }, {}, { 0, 255, 1 }, {}, { 2, 1, 2, 859010302352, 1, 1, 520 } },
}
Set(routesPath .. "/Walking.lua", "Walking", "00000008", "int", '"map", "links", "block", "gates"',
    '"int", "list int", "text", "text"',
    'R[3104] = "70245\t\t0\t3105\tblock:3104"\nR[3105] = "70245\t\t0\t3104\tblock:3105"\nR[6176] = "70245\t\t1\t\tblock:6176"\n'
    .. 'R[6177] = "70245\t\t1\t\tblock:6177"\nR[6178] = "70245\t\t1\t\tblock:6178"\nR[6179] = "70245\t\t1\t\tblock:6179"\n'
    .. 'R[2340] = "70245\t\t0\t\tblock:2340"\n'
    .. 'R[2592] = "70245\t\t0\t2593\tblock:2592\tgates:2592"\nR[2593] = "70245\t\t0\t2592\0302594\tblock:2593\tgates:2593"\n'
    .. 'R[2594] = "70245\t\t0\t2593\0302595\tblock:2594\tgates:2594"\nR[2595] = "70245\t\t0\t2594\tblock:2595\tgates:2595"\n'
    .. 'R[2600] = "70245\t\t0\t\tblock:2600\tgates:2600"\n')
W.AddSets(routesPath)
C_EncodingUtil = { DecodeBase64 = function(text) return text end, DecompressString = function(text) return text end,
                   DeserializeCBOR = function(text)
                       return (text:find("^gates:") and walkGates or walkBlocks)[tonumber(text:match("%d+"))]
                   end }
W.AddSets(spawnsPath)

-- The game's callback events (MINIMAP_PING among them): only RegisterEventCallback takes them, no frame's RegisterEvent.
W.callbacks = {}
RegisterEventCallback = function(event, fn) W.callbacks[event] = fn return true end
-- The game's flight map (Taxi.lua follows its OnShow and OnHide); the talk closed, the game hides it.
TaxiFrame = CreateFrame("Frame", "TaxiFrame", UIParent)
TaxiFrame:Hide()
CloseTaxiMap = function() TaxiFrame:Hide() end
if W.retailRun then W.Play("retail") end
W.LoadCore(root)
local Core = SaneUI.Core
-- Saved by an earlier version (the first shape of the settings): the view Overlay, which is gone.
SaneUIDB = { modules = { Navigation = { options = { view = "overlay" } } } }
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Navigation", "SaneUI_Navigation")
-- Treasure, herbs and ore show only up close (Pins.CLOSER yards): the tests' small canvas looks at them from farther
-- out, so the limit is lifted here and tested on its own below (the cloud's test).
local CLOSER = ns.Pins.CLOSER
ns.Pins.CLOSER = math.huge
W.Fire("ADDON_LOADED", "SaneUI_Navigation")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Navigation == ns and not ns.off, "the module is made and started")
-- A button another addon makes in its own login handler, after Navigation's: held on the next frame, before another
-- addon that gathers minimap buttons looks a second later and takes it off the minimap (Strays.AGAIN).
;(function()
    local late = W.NewWidget("Button", "LateAddonButton", minimap)
    late:SetSize(32, 32)
    late._mouse = true
    rawset(_G, "LateAddonButton", late)
    W.insecure.LateAddonButton, W.late = "LateAddon", late
    W.Wait(0)
    check(late:GetParent() ~= minimap and not late:GetParent()._shown,
        "a button another addon makes at the login itself is held on the next frame, out of sight")
    late:Hide() -- its addon hides it: left out of the satchel the rest of the run
end)()

-------------------------------------------------------------------------------
--  Retail from the start: the game's own map tree, one map at a time (Camera.Retail.lua)
-------------------------------------------------------------------------------
if W.retailRun then (function()
    local Coords, Camera, Canvas, Window = ns.Coords, ns.Camera, ns.Canvas, ns.Window
    check(Core.RETAIL and Camera.Wanted and Camera.DEEP, "Retail: the map's own camera, one map at a time")
    check(ns.options.view == "sketches" and ns.View() == "sketches" and not ns.Several()
        and Core.Settle(ns.name, {}).view == "sketches", "one view in Retail: Parchment, the view a first load starts in")
    check(Coords.PlaneOf(1429) == 1415 and Coords.PlaneOf(1459) == 1459 and Coords.Box(1459).continent == 30,
        "a map whose box lies in another world than its continent's (a battleground) is a plane of its own")
    local sheet = Coords.Box(946)
    check(sheet and sheet.continent == -1 and sheet.width == Coords.SHEET and near(sheet.height, Coords.SHEET * 668 / 1002)
        and Coords.PlaneOf(946) == 946 and Coords.Box(947) == false,
        "the top of the tree, the Cosmic map, is a sheet of its own of its art's shape; Azeroth still has no box of its own")
    check(Coords.Top() == 946 and #Coords.Elsewhere() == 1 and Coords.Elsewhere()[1] == 101, "Outland beside Azeroth")

    local frame, small = Canvas.frame, Window.small
    -- The textures shown whose files lie between low and high (the made-up art: a map's ID times 100 and the tile's
    -- number; its second layer's 50 on).
    local function Drawn(low, high)
        local count = 0
        for _, widget in ipairs(W.frames) do
            local file = widget._kind == "Texture" and widget._shown and widget._texture
            if type(file) == "number" and file >= low and file <= high then count = count + 1 end
        end
        return count
    end
    frame._width, frame._height = 200, 200
    Canvas.Use(small)
    Canvas.Open()
    local tracker
    for _, widget in ipairs(W.frames) do if widget._parent == frame and widget._scripts.OnUpdate then tracker = widget end end
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(small.shown == 1429 and small.map == 1415 and small.level == "zone" and Canvas.view.shown == 1429 and small.follow,
        "the small view follows the player on the map the player is on, Elwynn, in its continent's plane")
    check(Canvas.view.layer == 2 and Drawn(142951, 142998) > 0 and Drawn(142901, 142912) == 0 and Drawn(141501, 141512) == 0
        and Drawn(94701, 94712) == 0, "close in: Elwynn's more detailed layer alone, nothing of its continent's or Azeroth's")

    -- Right click: one map out, each whole, up to the top of the tree.
    local function Right()
        frame._scripts.OnMouseDown(frame, "RightButton")
        frame._scripts.OnMouseUp(frame, "RightButton")
    end
    Right()
    check(small.shown == 1415 and small.level == "continent" and near(small.k, small.fit) and not small.follow
        and Drawn(141501, 141512) > 0 and Drawn(142901, 142998) == 0, "right click: the continent whole, its art alone")
    Right()
    check(small.shown == 947 and small.level == "world" and small.map == 1415 and Drawn(94701, 94712) > 0
        and Drawn(141501, 141512) == 0, "again: Azeroth whole, in the continent's plane")
    Right()
    check(small.shown == 946 and small.map == 946 and small.level == "world" and Drawn(94601, 94612) > 0
        and Drawn(94701, 94712) == 0, "again: the Cosmic map, on its sheet")
    Right()
    check(small.shown == 946, "at the top a right click does nothing more")

    -- The mouse over Azeroth on it: the game's highlight, a piece of an atlas (448 by 423 of a 1024 file), whole.
    local texture = rawget(_G, "C_Texture")
    C_Texture = { GetAtlasInfo = function(atlas)
        if atlas ~= "worldmap-highlight-cosmic-azeroth" then return nil end
        return { width = 448, height = 423, leftTexCoord = 1 / 1024, rightTexCoord = 449 / 1024, topTexCoord = 1 / 1024,
                 bottomTexCoord = 424 / 1024 }
    end }
    cursorX, cursorY = 100 + (sheet.width * 0.4 - small.u) * small.k, 100 + (-sheet.height / 2 - small.v) * small.k
    frame._mouseOver = true
    frame._scripts.OnEnter(frame)
    local hover, light
    for _, widget in ipairs(W.frames) do
        if widget._parent == frame and widget ~= tracker and widget._scripts.OnUpdate then hover = widget end
    end
    hover._scripts.OnUpdate(hover, 0.016)
    for _, widget in ipairs(W.frames) do if widget._atlas == "worldmap-highlight-cosmic-azeroth" then light = widget end end
    check(light and light._shown and light._coords[1] == 0 and light._coords[2] == 1 and light._coords[3] == 0
        and light._coords[4] == 1 and near(light._width, 448 * sheet.width / 1002 * small.k + Canvas.OVERLAP, 0.01),
        "Azeroth under the mouse on the Cosmic map: its piece of the atlas whole, as large as the game has it")
    frame._mouseOver = false
    C_Texture = texture

    -- A click goes into the map the game says is under the mouse.
    local function Click(u, v)
        cursorX, cursorY = 100 + (u - small.u) * small.k, 100 + (v - small.v) * small.k
        frame._scripts.OnMouseDown(frame, "LeftButton")
        frame._scripts.OnMouseUp(frame, "LeftButton")
    end
    Click(sheet.width * 0.75, -sheet.height / 2)
    check(small.shown == 101 and small.map == 101 and small.level == "continent", "a click on the Cosmic map's right half: Outland")
    Right()
    Click(sheet.width * 0.25, -sheet.height / 2)
    check(small.shown == 947 and small.level == "world", "on its left half: Azeroth")
    local box = small.box
    Click(box.u + 0.3 * box.width, box.v - 0.5 * box.height)
    check(small.shown == 1414 and small.map == 1414 and small.level == "continent", "on Azeroth Kalimdor, in its own plane")
    Right()
    box = small.box
    check(small.shown == 947 and small.map == 1414, "Azeroth again, now in Kalimdor's plane")
    Click(box.u + 0.78 * box.width, box.v - 0.5 * box.height)
    check(small.shown == 1415, "the Eastern Kingdoms")
    box = small.box
    Click(box.u + 0.5 * box.width, box.v - 0.66 * box.height)
    check(small.shown == 1429 and small.level == "zone" and near(small.k, small.fit), "and Elwynn whole")
    check(small:Fit(1459) and small.map == 1459 and small.shown == 1459, "a battleground: shown in its own plane")

    -- The wheel within the map shown: out no farther than whole, in as near as Camera.DEEP units to a pixel of its art.
    small:Fit(1429)
    Canvas.Layout()
    frame._scripts.OnMouseWheel(frame, -1)
    W.Wait(0)
    check(near(small.k, small.fit) and small.shown == 1429 and small.layer == 1, "out from whole: it stays whole, its first layer")
    local found = false
    for _, pin in ipairs(ns.Pins.For(Canvas.view, false)) do found = found or pin.key == "quest:7" end
    check(found, "the pins of the map shown: Elwynn's quest")
    for _ = 1, 40 do
        frame._scripts.OnMouseWheel(frame, 1)
        W.Wait(0)
    end
    check(near(small.near, Camera.DEEP * 1002 / 2000) and near(small.k, small.near) and small.layer == 2
        and Drawn(142951, 142998) > 0, "in: as near as four units to a pixel of its art, in its more detailed layer")
    small:Fit(1415)
    Canvas.Layout()
    found = false
    for _, pin in ipairs(ns.Pins.For(Canvas.view, false)) do found = found or pin.key == "quest:7" end
    check(not found, "on the continent, as the game's own continent map, no quest of the log")

    -- Following again, into another zone: the view goes onto the map the player is on now.
    player.map, player.x, player.y = 1460, 0.5, 0.5
    small.follow = true
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(small.shown == 1460 and small.level == "zone" and small.map == 1415, "following, the view goes onto the map the player walked into")
    player.map, player.x, player.y = 1429, 0.75, 0.3

    -- The full map, the first time: the map the player is on, whole, as the game's own map opens.
    Window.Toggle()
    frame._width, frame._height = 1600, 868
    Window.frame._group:Run(1)
    local full = Window.full
    check(Canvas.camera == full and full.shown == 1429 and full.level == "zone" and near(full.k, full.fit),
        "the full map opens on the map the player is on, whole")

    local problems = {}
    for label, problem in pairs(Core.errors) do
        if label:find("Navigation", 1, true) then problems[#problems + 1] = label .. ": " .. tostring(problem.text) end
    end
    check(#problems == 0, "nothing of Navigation went wrong on the way: " .. table.concat(problems, "; "))
    print = nil -- the stand-in's print; use the real one for the summary
    io.write(("Navigation in Retail: all %d checks passed.\n"):format(passed))
    os.exit(0)
end)() end
check(type(ns.OUTLINES) == "table", "the zones that have an outline are listed (Outlines.lua)")
check(type(ns.COASTS) == "table", "the tiles on a coast are listed (Coasts.lua)")
check(ns.options.view == "terrain" and ns.View() == "terrain", "a saved view that is gone (Overlay) falls back to Scrying")
local viewOption = Core.Described(ns.name, "view")
check(#viewOption.choices == 3 and viewOption.choices[1][1] == "sketches" and viewOption.choices[2][1] == "blend"
    and viewOption.choices[3][1] == "terrain" and not ns.Offered("atlas") and #ns.VIEWS == 3,
    "three views are offered: Parchment, Blended and Scrying")
check(viewOption.default == "terrain" and ns.Fallback() == "terrain" and ns.Several()
    and Core.Settle(ns.name, {}).view == "terrain", "a first load starts as Scrying")
ns.options.view = "atlas" -- saved while the painted map was there (gone 2026-11-09)
check(ns.View() == "terrain", "a saved Atlas, a view that is gone: the map is drawn as Scrying")
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
check(camera.map == 1415 and camera.u == camera.world.u + camera.world.width,
    "dragged far off its continent, over the sea: the middle stays on the world map")
-- Dragged from the Eastern Kingdoms over Kalimdor at a zone's zoom (Saneroki, 2026-11-09): no continent to choose
-- first, the camera moves into Kalimdor's plane, the same on the screen, its zone's level kept.
;(function()
    camera:Show(1415, 0, -5000, 0.5)
    camera.follow = false
    local overU, overV = lu + 2000 * link.su, lv - 2000 * link.sv -- Kalimdor's (-10000, 18000), in the Eastern Kingdoms' plane
    camera:Pan((camera.u - overU) * camera.k, (camera.v - overV) * camera.k)
    check(camera.map == 1414 and camera.level == "zone" and near(camera.k, 0.5 * link.su) and near(camera.u, -10000)
        and near(camera.v, 18000), "dragged over the other continent at a zone's zoom: into its plane, the same on the screen")
    camera:Pan(10, 10)
    check(camera.map == 1414, "a drag within it: still there")
    local back = Coords.Link(1415, 1414)
    camera:Pan((camera.u - (back.du + back.su * 0)) * camera.k, (camera.v - (back.dv + back.sv * -5000)) * camera.k)
    check(camera.map == 1415 and near(camera.u, 0) and near(camera.v, -5000) and near(camera.k, 0.5),
        "and back over the Eastern Kingdoms: their plane again, at the zoom it had")
    camera.follow = true
    camera:Look(overU, overV)
    check(camera.map == 1415, "a view that follows the player stays in its plane")
    camera.follow = false
end)()
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
-- The game hiding the facing (a secret value, in a fight): read through Core.Plain, so the player is still placed and
-- the facing is not known, nothing computed with the secret.
GetPlayerFacing = function() return W.Secret() end
lmap, lu2, _, facing = Live.Player()
check(lmap == 1415 and near(lu2, 500) and facing == nil, "Live: the facing a secret value: the player placed, the facing not known")
GetPlayerFacing = function() return 1.5 end
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
check(minimap:IsMouseClickEnabled() == false,
    "its left and right clicks go through to our map")
check(ground == false and ignoreRotation == true and backdrop._alpha == 0 and minimap.ZoomIn._alpha == 0 and not minimap.ZoomIn._mouse,
    "its ground off, its rotation ignored, its border and zoom buttons out of sight")
check(minimap._AreasAt(0), "its own quest areas and the ring round its edge off with its ground: ours lie under it")
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
check(arrow and arrow._shown and arrow._points[1][1] == "CENTER" and near(arrow._points[1][4], 0) and near(arrow._points[1][5], 0),
    "our arrow on the player in the middle, over the game's minimap too")
check(minimap._level == frame:GetFrameLevel() + Hybrid.LEVEL and minimap._strata == frame:GetFrameStrata()
    and arrow._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.marks and Hybrid.LEVEL < Canvas.LEVELS.marks
    and Hybrid.LEVEL > Canvas.LEVELS.art,
    "the game's minimap above the map's layers, in the canvas' layer, under our marks: set each time it is placed")
check(minimap._mask == Hybrid.MASK, "a square view: the game's minimap square")
-- Retail's game switches its own hybrid minimap off at a loading screen (its OnHide draws the ground again and follows
-- the rotation) before we hear of it: ours set anew, with the view laid out again.
ground, ignoreRotation = true, false
W.Fire("PLAYER_ENTERING_WORLD")
check(ground == false and ignoreRotation == true and minimap._shown and minimap._zoom == 2,
    "the game drew its ground and followed the rotation again at a loading screen: ours set anew")
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
do
    local x, y, half = Hybrid.Square()
    check(x and near(x, -Canvas.edge.x) and near(y, -Canvas.edge.y) and near(half, 100),
        "the square it covers, in the holder's units: the view's middle, half its side (the party's marks stand down there)")
end
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
    -- A hall the game counts as outdoors (one may ride there: Ironforge's, the Undercity), where its minimap shows the
    -- indoor plan all the same (its view's radius one of the indoor steps'): the indoor map there too.
    ;(function()
        local step = minimap._zoom
        local was = radii[step]
        radii[step] = ns.Live.OUTDOORS[step] * 0.6
        Canvas.Layout()
        check(ns.Live.Indoors() and Picture("Indoors\\500001-1"),
            "a hall the game counts as outdoors (Ironforge's), its minimap showing its indoor plan: the indoor map over the zone")
        radii[step] = was
        Canvas.Layout()
        check(not ns.Live.Indoors() and not Picture("Indoors\\500001-1"),
            "out of it, the minimap showing the ground again: no indoor map")
    end)()
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
check(arrow._shown and arrow._rotation == 1.5, "our arrow shows, turned as the player faces")
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

-- A middle click: back on the player, following, at the game's middle step (Hybrid.HOME), its dots in sight.
;(function()
    small.follow, small.native, small.k = false, nil, 3
    small:Look(small.u + 300, small.v)
    Canvas.Layout()
    frame._scripts.OnMouseDown(frame, "MiddleButton")
    frame._scripts.OnMouseUp(frame, "MiddleButton")
    local _, u, v = Live.Player()
    check(small.follow and small.native == Hybrid.HOME and near(small.k, 100 / radii[Hybrid.HOME]) and near(small.u, u)
        and near(small.v, v) and minimap._shown and minimap._zoom == Hybrid.HOME,
        "a middle click: back on the player and following, at the game's middle step, its minimap's dots in sight")
    for _ = 1, Hybrid.HOME do frame._scripts.OnMouseWheel(frame, -1) W.Wait(0) end
    check(small.native == 0, "and out to the widest step again")
end)()

-- Other addons' buttons held (Strays.lua), and the satchel (Satchel.lua): its button on the small map opens a page of
-- the addons' buttons, the pins and the game's tracking.
;(function()
    local Satchel = ns.Satchel
    check(W.stray:GetParent() ~= minimap and not W.stray:GetParent()._shown and W.overlay:GetParent() == minimap
        and W.gameButton:GetParent() == cluster,
        "another addon's button on the minimap is held out of sight; its larger frame and the game's own button stay")
    local button = Satchel.button
    check(button and button._shown and button._parent == frame and not Satchel.Shown(), "the satchel's button on the small map")
    button._scripts.OnClick(button, "LeftButton")
    check(Satchel.Shown(), "a click opens the satchel")
    local function Cells()
        local found, count = {}, {}
        for _, widget in ipairs(W.frames) do
            if widget._shown and widget.item then
                found[widget.item.title] = widget
                count[widget.item.title] = (count[widget.item.title] or 0) + 1
            end
        end
        return found, count
    end
    local cells, count = Cells()
    local held = cells["Pretend Addon"]
    check(held and held.item.button == W.stray and W.stray:GetParent() == held.spot and near(W.stray._scale, Satchel.ADDON[1] / 31) and near(held.spot._width, Satchel.ADDON[1])
        and count["Pretend Addon"] == 1,
        "the addon's own button in its cell, twice as large as a pin's picture, under its title without colours, once")
    check(W.stray._alpha == 0 and held.picture._shown and held.picture._texture == 133784 and held.picture._mask == held.round
        and near(held.picture._coords[1], Satchel.TRIM),
        "its button unseen over its picture: the picture alone, round, cut inside its frame, without its ring")
    W.stray:SetAlpha(1)
    check(W.stray._alpha == 0, "its addon showing it again (a fade): unseen again")
    check(cells["Compartment Addon"] and cells["Compartment Addon"].item.entry and cells["Compartment Addon"].picture._shown,
        "the game's compartment's other addon in a cell of its own, its picture over its title")
    local entry = cells["Compartment Addon"]
    entry._scripts.OnClick(entry, "RightButton")
    check(W.compartment == "RightButton", "a click on it is its addon's own, with its mouse button")
    W.stray:ClearAllPoints()
    W.stray:SetPoint("CENTER", minimap, "CENTER", 60, 60)
    check(W.stray._points[1][2] == held.spot and W.stray:GetParent() == held.spot, "its addon placing it again: back in its cell")

    local flight = cells["Flight points"]
    check(flight and flight.tick._shown and flight.picture._alpha == 1, "a pin shown on the map: its picture whole, ticked")
    flight._scripts.OnClick(flight, "LeftButton")
    flight = Cells()["Flight points"]
    check(not ns.Pins.Shows("flight") and flight and not flight.tick._shown and flight.picture._alpha == Satchel.FAINT,
        "a click: the map no longer shows it, its cell faint, without the tick")
    flight._scripts.OnClick(flight, "LeftButton")
    check(ns.Pins.Shows("flight"), "and again: shown")

    local switches, finders = #gather.switches, { gather.tracking[1].active, gather.tracking[2].active }
    gather.tracking[3] = { name = "Track Beasts", spellID = 1494, active = false, type = "spell", texture = 132328 }
    gather.tracking[4] = { name = "Find Fish", spellID = 43308, active = false, type = "spell", texture = 133888 }
    Satchel.Fill()
    cells = Cells()
    local beasts = cells["Track Beasts"]
    check(beasts and not cells["Find Herbs"] and not cells["Find Minerals"] and not cells["Find Fish"]
        and cells["Found fishing pools"] and not beasts.tick._shown,
        "the game's tracking, but the finders Found herbs, Found ore and Found fishing pools switch")
    beasts._scripts.OnClick(beasts, "LeftButton")
    check(gather.tracking[3].active and Cells()["Track Beasts"].tick._shown, "a click switches it as the game's menu does")
    gather.tracking[3], gather.tracking[4] = nil, nil
    gather.tracking[1].active, gather.tracking[2].active = finders[1], finders[2]
    for index = #gather.switches, switches + 1, -1 do gather.switches[index] = nil end

    button._scripts.OnClick(button, "LeftButton")
    check(not Satchel.Shown() and W.stray:GetParent() ~= held.spot and not W.stray:GetParent()._shown,
        "the button again closes it: the addon's button waits out of sight again")
end)()

-- An addon whose button fixes its strata and level (the game keeps them then), and whose marks of places in the world
-- stand on the minimap too, named by their number in their pool: its button above the page in its cell, so a click
-- is its own; its marks no buttons, left on the minimap. Kept in W for the giving back.
;(function()
    local Satchel = ns.Satchel
    local own = W.NewWidget("Button", "PinAddonButton", minimap)
    own:SetSize(31, 31)
    own:SetPoint("CENTER", minimap, "CENTER", 80, 0)
    own:SetFrameStrata("MEDIUM")
    own:SetFixedFrameStrata(true)
    own:SetFrameLevel(8)
    own:SetFixedFrameLevel(true)
    W.fixed, W.marks, W.others = own, {}, { [own] = true } -- others: other addons' frames the test made
    for index = 1, 3 do
        local mark = W.NewWidget("Button", "PinAddonFrame" .. index, minimap)
        mark:SetSize(16, 16)
        mark:SetPoint("CENTER", minimap, "CENTER", index * 10, 0)
        W.marks[mark], W.others[mark] = true, true
    end
    own._mouse = true
    rawset(_G, own._name, own)
    W.insecure[own._name] = "PinAddon"
    for mark in pairs(W.marks) do
        mark._mouse = true
        rawset(_G, mark._name, mark)
        W.insecure[mark._name] = "PinAddon"
    end
    W.addons[#W.addons + 1] = { name = "PinAddon", title = "Pin Addon", metadata = {} }
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
    local found, count = nil, 0
    for _, widget in ipairs(W.frames) do
        if widget._shown and widget.item and widget.item.title == "Pin Addon" then found, count = widget, count + 1 end
    end
    check(found and count == 1 and found.item.button == own and own:GetParent() == found.spot
        and own:GetFrameStrata() == Satchel.frame:GetFrameStrata() and own:GetFrameLevel() > found:GetFrameLevel()
        and own:GetFrameLevel() ~= 8 and not own:IsFrameStrataFixed() and not own:IsFrameLevelFixed(),
        "a button whose addon fixed its strata and level: in its cell above the page, once, so its clicks are its own")
    local stayed = true
    for mark in pairs(W.marks) do
        stayed = stayed and mark:GetParent() == minimap and mark._points[1][2] == minimap and mark._alpha == 1
    end
    check(stayed, "that addon's numbered marks on the minimap: no buttons, left where they stand")
    Satchel.Close()
end)()

-- Each addon's picture under its own title (Saneroki, 2026-11-11: "The icons and names sometimes don't match"). A button
-- made through code another addon loaded for all (the game says that one set its global) is named by the loaded addon
-- its own name holds; its picture the texture it shows (not a hidden or faded one), refreshed while the page is open;
-- a button with none, its addon's own icon; a compartment's atlas whole, not cut as a file.
;(function()
    local Satchel = ns.Satchel
    local function Button(name, setter, art)
        local button = W.NewWidget("Button", name, minimap)
        button:SetSize(31, 31)
        button:SetPoint("CENTER", minimap, "CENTER", -80, 0)
        button._mouse = true
        rawset(_G, name, button)
        W.insecure[name], W.others[button] = setter, true
        for _, part in ipairs(art) do
            local texture = button:CreateTexture()
            texture:SetDrawLayer(part[1])
            texture:SetTexture(part[2])
            texture:SetSize(part[3], part[3])
            if part[4] == "hidden" then texture:Hide() elseif part[4] == "faded" then texture:SetAlpha(0) end
            button[part[5] or part[2]] = texture
        end
        return button
    end
    W.addons[#W.addons + 1] = { name = "OtherAddon", title = "Other Addon", metadata = {} }
    W.addons[#W.addons + 1] = { name = "QuietAddon", title = "Quiet Addon", metadata = {} } -- installed, not loaded
    W.addons[#W.addons + 1] = { name = "IconlessAddon", title = "Iconless Addon",
                                metadata = { IconTexture = "Interface\\AddOns\\IconlessAddon\\Icon" } }
    -- The shared code standing as an addon of its own, loaded: its name first in the button's, the owner's after it.
    W.addons[#W.addons + 1] = { name = "SharedIcon", title = "Shared Icon", metadata = {} }
    W.loaded.OtherAddon, W.loaded.IconlessAddon, W.loaded.SharedIcon = true, true, true
    local other = Button("SharedIconOtherAddon", "SharedIcon", {
        { "BACKGROUND", 136467, 20 }, { "ARTWORK", 136243, 18, nil, "icon" }, { "ARTWORK", 999, 26, "hidden" },
        { "ARTWORK", 998, 24, "faded" }, { "OVERLAY", 136430, 53 } })
    local quiet = Button("QuietAddonHelper", "PinAddon", { { "ARTWORK", 136244, 18 } })
    local bare = Button("IconlessAddonButton", "IconlessAddon", { { "BACKGROUND", 136467, 30 }, { "OVERLAY", 136430, 30 } })
    local registered = AddonCompartmentFrame.registeredAddons
    local first = #registered + 1
    registered[first] = { text = "Other Addon", icon = 134400, func = function() end }
    registered[first + 1] = { text = "Sheet Icon Addon", icon = "pretend-sheet-icon", func = function() end }
    local texture = rawget(_G, "C_Texture")
    C_Texture = { GetAtlasInfo = function(atlas) return atlas == "pretend-sheet-icon" and {} or nil end }
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
    local function Cells()
        local found, count = {}, {}
        for _, widget in ipairs(W.frames) do
            if widget._shown and widget.item then
                found[widget.item.title] = widget
                count[widget.item.title] = (count[widget.item.title] or 0) + 1
            end
        end
        return found, count
    end
    local cells, count = Cells()
    local cell = cells["Other Addon"]
    check(cell and cell.item.button == other and count["Other Addon"] == 1 and other:GetParent() == cell.spot,
        "a button another addon's shared code made: under the title of the loaded addon its name holds last, once "
        .. "(its compartment entry left out)")
    check(cells["Pin Addon"] and count["Pin Addon"] == 2 and quiet:GetParent() ~= minimap,
        "one whose name holds only an addon not loaded: the addon the game says set it")
    check(cell.picture._texture == 136243, "its picture the texture it shows, not a hidden or faded larger one")
    local plain = cells["Iconless Addon"]
    check(plain and plain.item.button == bare and plain.picture._texture == "Interface\\AddOns\\IconlessAddon\\Icon"
        and near(plain.picture._coords[1], Satchel.TRIM), "a button showing no picture of its own: its addon's own icon")
    local sheet = cells["Sheet Icon Addon"]
    check(sheet and sheet.picture._atlas == "pretend-sheet-icon" and sheet.picture._coords[1] == 0
        and sheet.picture._coords[2] == 1, "a compartment's addon with an atlas for its icon: the atlas whole, not cut")
    other.icon:SetTexture(136245)
    Satchel.frame._scripts.OnUpdate(Satchel.frame, Satchel.EVERY)
    check(cells["Other Addon"].picture._texture == 136245, "its addon changing its picture: the satchel's too, within a second")
    Satchel.Close()
    C_Texture = texture
    registered[first + 1], registered[first] = nil, nil
    for _, button in ipairs({ other, quiet, bare }) do button:Hide() end -- out of the satchel the rest of the run
end)()

-- The satchel's sound line (AudioLine.lua): first in its section Sane UI, Core's sound profile in use in a dropdown,
-- the game's sound settings and the profile's buttons under a cogwheel.
;(function()
    local Satchel, Line, Audio = ns.Satchel, ns.AudioLine, Core.Audio
    local button = Satchel.button
    button._scripts.OnClick(button, "LeftButton")
    check(Satchel.Shown() and not (Line.line and Line.line._shown), "a client without the game's sound settings: no line")
    Satchel.Close()
    local added = {}
    for _, kind in ipairs(Audio.KINDS) do
        for _, name in ipairs({ kind.on, kind.volume }) do
            if not W.cvarInfo[name] then W.cvarInfo[name], added[#added + 1] = { default = "1", category = 7 }, name end
        end
    end
    W.cvars.Sound_MusicVolume = "0.4"
    MinimalSliderWithSteppersMixin = { Label = { Right = 3 }, Event = { OnValueChanged = "OnValueChanged" } }
    button._scripts.OnClick(button, "LeftButton")
    local line, profiles, cog = Line.line, Line.profiles, Line.cog
    local head
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._shown and widget._text == Satchel.TEXT.switches then head = widget end
    end
    check(line and line._shown and head and near(-line._points[1][5], -head._points[1][5] + Satchel.HEAD)
        and profiles.label._text == "All sound on" and cog.icon._atlas == nil and cog.icon._texture == Line.COG_FILE,
        "the line under the title Sane UI: the profile in use, the first of the account's; a cogwheel beside it")

    profiles:GenerateMenu()
    local names = {}
    for index, item in ipairs(profiles._items) do names[index] = item.text end
    check(table.concat(names, ", ") == "All sound on, Music off, Music and Ambience off, All sound off" and profiles._items[1].checked("All sound on"),
        "its dropdown: the profiles, the one in use first and chosen")
    profiles._items[2].fn(profiles._items[2].data)
    W.Wait(0)
    profiles:GenerateMenu()
    check(W.cvars.Sound_EnableMusic == "0" and profiles.label._text == "Music off" and profiles._items[1].text == "Music off"
        and profiles._items[2].text == "All sound on", "one chosen: set at once, named on the line, first in the list now")

    cog:GenerateMenu()
    local rows, buttons = {}, {}
    for _, item in ipairs(cog._items) do
        if item.checked then rows[item.data] = item elseif item.fn then buttons[item.text] = item end
    end
    check(cog._items[1].title == "Music off" and rows.all and rows.music and rows.sfx and rows.dialog and rows.ambience
        and rows.music.text == "Music" and rows.all.checked(rows.all.data) and not rows.music.checked(rows.music.data)
        and buttons.Save and buttons.Load and buttons.New and buttons.Delete and not buttons.Delete.disabled,
        "the cogwheel: the profile's name, a checkbox per sound as the game has it now, then Save, Load, New and Delete")
    local slider = { points = {} }
    function slider:SetWidth(width) self.width = width end
    function slider:ClearAllPoints() self.points = {} end
    function slider:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function slider:Init(value, low, high, steps, labels) self.value, self.low, self.high, self.steps, self.labels = value, low, high, steps, labels end
    function slider:RegisterCallback(_, fn, owner) self.fn, self.owner = fn, owner end
    function slider:UnregisterCallback(_, owner) if self.owner == owner then self.fn, self.owner = nil, nil end end
    local row = { fontString = { GetUnboundedStringWidth = function() return 40 end } }
    function row:AttachTemplate(template) self.template = template return slider end
    local width, height = rows.music.inits[1](row)
    check(row.template == "MinimalSliderWithSteppersTemplate" and near(slider.value, 40) and slider.low == 0 and slider.high == 100
        and slider.steps == Line.STEPS and slider.labels[3](40) == "40%" and width > 40 + slider.width and height == Line.ROW,
        "each sound's slider at its right: its volume now, 0 to 100 % in the game's steps")
    slider.fn(nil, 65)
    rows.music.fn(rows.music.data)
    W.Wait(0)
    check(W.cvars.Sound_MusicVolume == "0.65" and W.cvars.Sound_EnableMusic == "1"
        and profiles.label._text:find("Music off", 1, true) and profiles.label._text:find(Line.TEXT.changed, 1, true),
        "moved and ticked: the game's sound at once; the line says the profile in use differs now")
    check(buttons.Load.fn() == MenuResponse.Refresh and W.cvars.Sound_EnableMusic == "0" and W.cvars.Sound_MusicVolume == "0.4",
        "Load: the profile set again, the menu stays open with its rows read anew")
    W.Wait(0)
    check(profiles.label._text == "Music off", "and the line names it plainly again")
    slider.fn(nil, 20)
    check(buttons.Save.fn() == MenuResponse.Refresh and not Audio.Changed(), "Save: the settings now kept in the profile")

    buttons.New.fn()
    local dialog = W.popups[#W.popups]
    function dialog:IsShown() return not self.closed end
    dialog.data.callback("Quiet raid")
    W.Wait(0)
    check(dialog.which == "GENERIC_INPUT_BOX" and Audio.Current() == "Quiet raid" and profiles.label._text == "Quiet raid",
        "New: a name asked in the game's dialog; the new profile in use")
    local page = Satchel.frame
    local function Away() return false end
    local pageMouse, buttonMouse = page.IsMouseOver, button.IsMouseOver
    page.IsMouseOver, button.IsMouseOver = Away, Away
    page._scripts.OnUpdate(page, Satchel.LEAVE * 4)
    check(Satchel.Shown(), "while that dialog shows, the satchel stays open")
    dialog.closed = true
    page._scripts.OnUpdate(page, Satchel.LEAVE * 4)
    page._scripts.OnUpdate(page, Satchel.LEAVE * 4)
    check(not Satchel.Shown(), "closed: the mouse away, the satchel goes as ever")
    page.IsMouseOver, button.IsMouseOver = pageMouse, buttonMouse

    button._scripts.OnClick(button, "LeftButton")
    cog:GenerateMenu()
    for _, item in ipairs(cog._items) do if item.text == Line.TEXT.delete then buttons.Delete = item end end
    buttons.Delete.fn()
    dialog = W.popups[#W.popups]
    check(dialog.which == "GENERIC_CONFIRMATION" and dialog.data.text_arg1 == "Quiet raid", "Delete asks first, naming the profile")
    dialog.data.callback()
    W.Wait(0)
    check(Audio.Current() == "All sound on" and profiles.label._text == "All sound on" and #Audio.Names() == 4,
        "deleted: the first profile in use")
    while #Audio.Names() > 1 do Audio.Delete() end
    cog:GenerateMenu()
    for _, item in ipairs(cog._items) do if item.text == Line.TEXT.delete then buttons.Delete = item end end
    check(buttons.Delete.disabled, "the last profile: Delete is off")
    Satchel.Close()

    for _, name in ipairs(added) do W.cvarInfo[name], W.cvars[name] = nil, nil end
    W.cvars.Sound_MusicVolume, W.cvars.Sound_EnableMusic = nil, nil
    MinimalSliderWithSteppersMixin = nil
    Core.Store(Core.name).audio = nil
end)()

-- The satchel's first section: the zone you are in, under it your times, the frame rate, the latency, new mail; the
-- game's calendar (a secure button of ours clicks the game's own), clock and stopwatch.
;(function()
    local Satchel = ns.Satchel
    local firing = false
    local game = {
        GetZoneText = function() return "Elwynn Forest" end, GetSubZoneText = function() return "Goldshire" end,
        C_PvP = { GetZonePVPInfo = function() return "friendly" end }, GetGameTime = function() return 17, 5 end,
        GetNetStats = function() return 0, 0, 35, 41 end, HasNewMail = function() return true end,
        GetLatestThreeSenders = function() return "Mirabel", "Tobin" end,
        TimeManagerFrame = W.NewWidget("Frame", "TimeManagerFrame", UIParent),
        StopwatchFrame = W.NewWidget("Frame", "StopwatchFrame", UIParent),
        TimeManager_IsAlarmFiring = function() return firing end,
        TimeManager_TurnOffAlarm = function() firing = false end,
    }
    game.TimeManager_Toggle = function() game.TimeManagerFrame:SetShown(not game.TimeManagerFrame:IsShown()) end
    game.Stopwatch_Toggle = function() game.StopwatchFrame:SetShown(not game.StopwatchFrame:IsShown()) end
    game.TimeManagerFrame:Hide()
    game.StopwatchFrame:Hide()
    for name, value in pairs(game) do rawset(_G, name, value) end
    local function Shown()
        local texts, cells = {}, {}
        for _, widget in ipairs(W.frames) do
            if widget._shown and widget._kind == "FontString" and widget._text then texts[widget._text] = widget end
            if widget._shown and widget.item then cells[widget.item.title] = widget end
        end
        return texts, cells
    end
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
    local texts, cells = Shown()
    local title = texts["Elwynn Forest, Goldshire"]
    local r, g = Core.Journal.Ink(0.1, 1, 0.1)
    check(title and near(title._color[1], r) and near(title._color[2], g),
        "the satchel's first section: the zone and subzone you are in, in the friendly colour on the paper")
    check(title._points[1][1] == "TOP" and title._points[1][3] == "TOP", "centred over the boxes")
    ;(function()
        local sizes = {}
        title.SetFont = function(_, _, size) sizes[#sizes + 1] = size end
        title.GetStringWidth = function() return Satchel.COLUMNS * Satchel.CELL[1] * 2 end
        Satchel.Fill()
        title.SetFont, title.GetStringWidth = nil, nil
        check(near(sizes[1], Satchel.NUMBER * Core.Journal.PX) and sizes[2] < sizes[1] / 2 and sizes[2] > sizes[1] / 2.1,
            "as big as the boxes' numbers; a long name comes out smaller, on one line")
        Satchel.Fill()
    end)()
    for _, widget in ipairs(W.frames) do
        if widget._shown and widget._parent == title._parent and widget._texture and widget._kind == "Texture" then
            check(-widget._points[1][5] > Satchel.TITLE + Satchel.BOX[2], "no rule between the title and the boxes")
        end
    end
    check(texts[Satchel.TEXT.localTime] and texts["17:05"] and texts[Satchel.TEXT.framerate] and texts["60"]
        and texts[Satchel.TEXT.latency] and texts["41"] and texts["Mirabel, Tobin"],
        "under it four boxes: the local and the realm's time, the frame rate, the ping to the world; under them who "
        .. "sent new mail")
    local box = texts["41"]:GetParent()
    check(texts["17:05"]:GetParent() ~= box and box._width == Satchel.BOX[1] and box._height == Satchel.BOX[2]
        and box._height < box._width and box.word == texts[Satchel.TEXT.latency] and texts["17:05"]:GetParent().tip == nil,
        "a box, wider than it is high: its number, its word under it")
    box._scripts.OnEnter(box)
    check(GameTooltip._owner == box and GameTooltip._text == "35 ms home, 41 world",
        "the ping's box tells home and world on one line")
    box._scripts.OnLeave(box)
    check(cells[Satchel.TEXT.calendar] and cells[Satchel.TEXT.clock] and cells[Satchel.TEXT.stopwatch]
        and Satchel.calendar._attributes.type == "click" and Satchel.calendar._attributes.clickbutton == W.gameButton,
        "the game's calendar, clock and stopwatch; the calendar's secure button clicks the game's own")
    -- A fight: the calendar's secure button lets go of its cell as the game tells of the fight (it says so before it locks
    -- the frames), is left as it stands while the fight lasts (the page filled anew in it may not touch it: the game would
    -- block that), and covers the cell again once the fight is over.
    ;(function()
        local calendar = Satchel.calendar
        check(calendar._shown and calendar.cell == cells[Satchel.TEXT.calendar] and calendar._points[1][2] == calendar.cell,
            "the calendar's secure button over its cell")
        W.Fire("PLAYER_REGEN_DISABLED")
        W.combat = true
        Satchel.Fill()
        check(not calendar._shown and calendar.cell == nil and #calendar._points == 0 and not ns.off,
            "a fight: it let go of the cell as the game told of it; the page filled anew in the fight leaves it be")
        W.Combat(false)
        local _, now = Shown()
        check(calendar._shown and calendar.cell == now[Satchel.TEXT.calendar] and calendar._points[1][2] == calendar.cell,
            "the fight over: over its cell again")
    end)()
    local watch = cells[Satchel.TEXT.stopwatch]
    watch._scripts.OnClick(watch, "LeftButton")
    check(game.StopwatchFrame._shown and Shown() and select(2, Shown())[Satchel.TEXT.stopwatch].tick._shown,
        "a click shows the game's stopwatch, its cell ticked")
    firing = true
    rawset(_G, "HasNewMail", function() return false end)
    Satchel.frame._scripts.OnUpdate(Satchel.frame, Satchel.EVERY)
    texts, cells = Shown()
    local alarm = cells[Satchel.TEXT.alarm]
    check(alarm and alarm.tick._shown and not texts[Satchel.TEXT.mail],
        "a second later: the alarm sounds, the clock's cell says so; the mail read, its line gone")
    alarm._scripts.OnClick(alarm, "LeftButton")
    check(not firing and select(2, Shown())[Satchel.TEXT.clock], "a click stops the alarm, as the game's clock does")
    local clock = select(2, Shown())[Satchel.TEXT.clock]
    clock._scripts.OnClick(clock, "LeftButton")
    check(game.TimeManagerFrame._shown and not Satchel.Shown(), "a click opens the game's clock window, the satchel out of its way")
    for name in pairs(game) do rawset(_G, name, nil) end
    rawset(_G, "HasNewMail", nil)
    game.StopwatchFrame:Hide()
end)()

-- The satchel goes the first time the mouse leaves it, its button counting as the page: the way between the two is
-- free, a menu one of its cells opened holds it, and a page the mouse has not come to yet waits.
;(function()
    local Satchel = ns.Satchel
    local button = Satchel.button
    local function Tick(seconds) Satchel.frame._scripts.OnUpdate(Satchel.frame, seconds) end
    local function Over(frame, on)
        frame._mouseOver = on
        Tick(0.01)
    end
    button._scripts.OnClick(button, "LeftButton")
    local page = Satchel.frame
    Tick(Satchel.LEAVE * 4)
    check(Satchel.Shown(), "the mouse not on it yet: the satchel waits")
    Over(button, true)
    button._mouseOver = false
    Tick(Satchel.LEAVE * 0.8)
    Over(page, true)
    check(Satchel.Shown(), "from its button to the page: the way between them is free")
    page._mouseOver = false
    Tick(Satchel.LEAVE * 0.8)
    Over(page, true)
    page._mouseOver = false
    Tick(Satchel.LEAVE * 0.8)
    check(Satchel.Shown(), "back on it in time: the count starts anew")
    Tick(Satchel.LEAVE * 0.2)
    check(not Satchel.Shown(), "the mouse off it: gone")
    button._scripts.OnClick(button, "LeftButton")
    check(Satchel.Shown(), "the button opens it again")
    Over(button, true)
    Tick(Satchel.LEAVE * 4)
    check(Satchel.Shown(), "the mouse resting on the button holds it")
    button._mouseOver = false
    Tick(Satchel.LEAVE)
    check(not Satchel.Shown(), "off the button without coming to the page: gone too")
    -- A menu lies outside the page: the game's own kind and the older dropdown list hold it.
    button._scripts.OnClick(button, "LeftButton")
    Over(page, true)
    page._mouseOver = false
    local menu, open = rawget(_G, "Menu"), true
    rawset(_G, "Menu", { GetManager = function() return { IsAnyMenuOpen = function() return open end } end })
    Tick(Satchel.LEAVE * 2)
    check(Satchel.Shown(), "a menu open: it stays")
    open = false
    rawset(_G, "DropDownList1", W.NewWidget("Frame", "DropDownList1", UIParent))
    Tick(Satchel.LEAVE * 2)
    check(Satchel.Shown(), "an addon's dropdown list open: it stays")
    DropDownList1:Hide()
    Tick(Satchel.LEAVE)
    check(not Satchel.Shown(), "the menus closed: gone")
    rawset(_G, "Menu", menu)
    rawset(_G, "DropDownList1", nil)
    -- A hidden answer of the game's (IsMouseOver may give one) reads as off the page, never as an error.
    button._scripts.OnClick(button, "LeftButton")
    Over(page, true)
    page.IsMouseOver = function() return W.Secret() end
    Tick(Satchel.LEAVE)
    check(not Satchel.Shown() and not ns.off, "a hidden answer: off the page")
    page.IsMouseOver = nil
    page._mouseOver = false
end)()

-- The satchel's Sane UI section: the quick switches the modules offer (Core.Offer), a click their module's own; and
-- the AddOns section only while other addons have buttons for it.
;(function()
    local Satchel = ns.Satchel
    local function Shown()
        local texts, cells = {}, {}
        for _, widget in ipairs(W.frames) do
            if widget._shown and widget._text then texts[widget._text] = widget end
            if widget._shown and widget.item then cells[widget.item.title] = widget end
        end
        return texts, cells
    end
    local state, clicked = "on", nil
    Core.Offer("test", { title = "Test guide", icon = 132328,
                         State = function() return state end, Tip = function() return "Its tip" end,
                         Click = function(mouse) clicked = mouse end })
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
    local texts, cells = Shown()
    local guide = cells["Test guide"]
    check(texts[Satchel.TEXT.switches] and guide and guide.tick._shown and guide.picture._alpha == 1,
        "the Sane UI section: a module's switch, on: whole and ticked")
    guide._scripts.OnClick(guide, "RightButton")
    check(clicked == "RightButton", "a click on it is its module's own, with its mouse button")
    state = "off"
    Core.SwitchChanged()
    W.Wait(0.1)
    local off = select(2, Shown())["Test guide"]
    check(off and not off.tick._shown and off.picture._alpha == Satchel.FAINT, "off: faint")
    -- No other addon's button to show: no AddOns section at all.
    local list = ns.Strays.List
    ns.Strays.List = function() return {} end
    Satchel.Fill()
    check(not Shown()[Satchel.TEXT.addons], "no addon's button to show: no AddOns section")
    ns.Strays.List = list
    Satchel.Fill()
    check(Shown()[Satchel.TEXT.addons], "with one: the section is there")
    state = nil -- the module gone: its switch is not listed
    Satchel.Fill()
    check(not Shown()[Satchel.TEXT.switches], "no switch offered: no Sane UI section")
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
end)()

-- A drag: no longer following, the game's minimap goes. With the box Follow me ticked, as at first, it stays while
-- the player stands, and the moment the player walks it is back on the player, no delay, the mouse on it or not.
;(function()
    check(ns.options.followMap and Core.Described(ns.name, "followMap").default == true
        and not Core.Described(ns.name, "followAgain"), "Follow me ticked at first; no number of seconds beside it")
    local wasX = player.x
    frame._scripts.OnMouseDown(frame, "LeftButton")
    cursorX = cursorX + 30
    frame._scripts.OnUpdate(frame, 0.016)
    check(not small.follow and not minimap._shown and near(small.u, 500 - 30 / small.k), "a drag: the map moves, it no longer follows")
    player.x = wasX + 0.002
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not small.follow, "not with the mouse button held on the map, the player walking")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    check(not frame._scripts.OnUpdate, "the button up: nothing runs any more")
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    W.Wait(Canvas.AGAIN + 1)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not small.follow, "the player standing: it stays where it was dragged, however long")
    player.x = wasX
    frame._mouseOver = true
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    frame._mouseOver = false
    check(small.follow and near(small.u, 500) and minimap._shown,
        "the player walks: back on the player at once, the mouse on the map or not, the game's minimap with it")

    -- Not ticked: on the player it stays on the player; moved away it stays there, the player walking, however long.
    Core.Set(ns.name, "followMap", false)
    player.x = wasX + 0.002
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    local _, u = ns.Live.Player()
    check(small.follow and near(small.u, u) and minimap._shown, "not ticked: a minimap on the player keeps following")
    local wasCursor = cursorX
    frame._scripts.OnMouseDown(frame, "LeftButton")
    cursorX = cursorX + 30
    frame._scripts.OnUpdate(frame, 0.016)
    frame._scripts.OnMouseUp(frame, "LeftButton")
    cursorX = wasCursor
    local stood = small.u
    player.x = wasX
    W.Wait(Canvas.AGAIN + 1)
    tracker._scripts.OnUpdate(tracker, 0.016)
    player.x = wasX + 0.002
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not small.follow and small.u == stood and not minimap._shown,
        "not ticked: a minimap moved away stays there, the player walking, however long")
    -- In an instance the game tells no place: the game's minimap comes back all the same, it is the map there.
    player.map = 500
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(small.follow and minimap._shown and not Canvas.Laid(), "not ticked, in an instance: the game's minimap, the map there")
    check(not Shown()[Canvas.SEA], "in an instance the sea in its colour alone: no waves")
    player.map, player.x = 1429, wasX
    tracker._scripts.OnUpdate(tracker, 0.016)
    Core.Set(ns.name, "followMap", true)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(small.follow and near(small.u, 500) and Canvas.Laid(), "out of it, ticked again: on the player")
end)()

-- Core's button Sane UI on the game's minimap only while that is the game's own, not inside our map. In an instance,
-- where the game tells no place of the player in our planes: the game's minimap alone, with its own ground. The zone
-- in the middle asked of the game a few times a second, not at each step. A zone entered: the pins placed anew only.
;(function()
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == minimap and widget._kind == "Button" and widget ~= minimap.ZoomIn and widget ~= W.late
            and not W.others[widget] then sane = widget end
    end
    check(sane and not sane._shown and minimap._shown, "inside our map the game's minimap carries no button Sane UI")
    local step = minimap._zoom
    player.map = 500 -- a dungeon: its map has no box, so the game tells no place of the player in our planes
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(minimap._shown and ground == true and minimap._zoom == step and not Canvas.Laid()
        and Count(Shown(), 801, 804) == 0 and Overviews(Shown(), 0) == 0,
        "in an instance: the game's minimap alone, its own ground on, at the view's step; nothing of ours but the sea")
    check(minimap._AreasAt(0), "there its own quest areas and their ring off: the pin filter's Quest areas on the minimap is at first")
    ns.SwitchPin("minimapArea")
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(minimap._AreasAt(Hybrid.AREA), "switched on: its own quest areas there too")
    ns.SwitchPin("minimapArea")
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(minimap._AreasAt(0), "and off again")
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

-- A plain click in a zone pings there, in the click itself (the game blocks a ping from a timer); a double click puts
-- the map pin there too (its first click pinged); Ctrl and a click puts it there.
;(function()
    cursorX, cursorY = 120, 110
    minimap._ping = nil
    local step = minimap._zoom
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    check(minimap._ping and near(minimap._ping[1], 20) and near(minimap._ping[2], 10) and minimap._zoom == step,
        "a click: the game's ping where it was clicked (its yards from the player, in its minimap's units), in the click")
    do
        -- Past the view the game's minimap has (step 2: 160 yards): at the nearest step that reaches it for the moment
        -- (step 0: 240 yards), then back at its own.
        local steps = {}
        local zoom = minimap.SetZoom
        minimap._zoom = 2
        function minimap:SetZoom(each) steps[#steps + 1] = each return zoom(self, each) end
        minimap._ping = nil
        check(ns.Ping.Send(small.map, small.u + 220, small.v) and near(minimap._ping[1], 220 * 100 / 240)
            and near(minimap._ping[2], 0) and steps[1] == 0 and steps[2] == 2 and minimap._zoom == 2,
            "a ping farther than the game's minimap reaches: at its nearest step that reaches it, then its own step again")
        check(not ns.Ping.Send(small.map, small.u + 300, small.v) and #steps == 2, "past its widest view: no ping")
        minimap.SetZoom = zoom
        minimap._zoom = step
    end
    waypoint, minimap._pings = nil, 0
    W.Wait(1) -- the first click long past: the next is no second of it
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    W.Wait(0.1)
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    W.Wait(0.6) -- 1.7 seconds in all: the clock as the tests below were written for
    check(waypoint and waypoint.uiMapID == 1429 and minimap._pings == 1 and not tracked,
        "a double click: the game's map pin there, not yet followed; one ping, its first click's")
    waypoint = nil
end)()
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
-- A zone the game names under the mouse but gives no world position for (no box): no place to pin, no error.
;(function()
    local at = C_Map.GetMapInfoAtPosition
    C_Map.GetMapInfoAtPosition = function(map, x, y)
        if map == 1415 then return { mapID = 9998, mapType = 3 } end
        return at(map, x, y)
    end
    ctrl = true
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    ctrl = false
    C_Map.GetMapInfoAtPosition = at
    check(waypoint == nil and not ns.off, "Ctrl-click over a zone the game gives no world position for: no map pin, no error")
end)()

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
    check(arrow._shown and arrow._points[1][2] == holder and near(arrow._points[1][4], (u - Canvas.view.u) * full.k)
        and near(arrow._points[1][5], (v - Canvas.view.v) * full.k),
        "full: our arrow on the player, over the game's minimap there too")
    local x, y, half = Hybrid.Square()
    check(x and near(x, minimap._points[1][4]) and near(y, minimap._points[1][5]) and near(half, minimap._width / 2),
        "full: the square it covers, on the player")
    local chosen = Core.Copy(ns.options.pins)
    chosen.minimap = nil
    Core.Set(ns.name, "pins", chosen)
    check(not minimap._shown and not ns.Pins.Shows("minimap"), "the pin filter's Minimap dots off: not there")
    chosen = Core.Copy(chosen)
    chosen.minimap = true
    Core.Set(ns.name, "pins", chosen)
    check(minimap._shown, "on again: there")
    check(not Hybrid.Ping(0, 0), "a click on the full map is no ping: the game's minimap is not in its middle there")
    -- A middle click: on the player and following, where the game's middle step's square takes Hybrid.ROOM of it.
    local was = { u = full.u, v = full.v, k = full.k, follow = full.follow }
    full.follow, full.k = false, full.k / 3
    frame._scripts.OnMouseDown(frame, "MiddleButton")
    frame._scripts.OnMouseUp(frame, "MiddleButton")
    check(full.follow and math.abs(full.k - 868 * Hybrid.ROOM / (2 * radii[Hybrid.HOME])) < 1e-4 and near(full.u, u)
        and minimap._shown and minimap._zoom == Hybrid.HOME,
        "full, a middle click: on the player, near enough that the game's middle step shows around the player")
    full.u, full.v, full.k, full.follow = was.u, was.v, was.k, was.follow
    Canvas.Layout()
    check(not ns.Satchel.button._shown, "full: no satchel button, the small map's alone")
end
-- The group's pings are not heard: MINIMAP_PING is one of the game's callback events with restrictions, whose
-- callback the game blocks for an addon (a blocked action at every login); the game's minimap draws them itself.
;(function()
    local listened = false
    for _, widget in ipairs(W.frames) do listened = listened or widget._events.MINIMAP_PING ~= nil end
    check(not W.callbacks.MINIMAP_PING and not listened, "MINIMAP_PING: no callback of ours, no frame's event")
end)()
local bar
for _, widget in ipairs(W.frames) do if widget.key == "terrain" then bar = widget._parent end end
check(bar and bar._shown, "full: the view buttons")
shown = Shown()
check(Count(shown, 801, 804) == 4 and Count(shown, 142901, 142912) == 0 and Count(shown, 141501, 141512) == 0
    and Overviews(shown, 0, "Sketches") == 0, "Scrying up close: the tiles, no map art")
do -- The sea's waves over the view's rectangle, laid by the plane: a corner's texture coordinate is a whole number of
   -- copies from the plane's own, so a layout anywhere goes on with the same waves; a copy SEA_SIZE units wide.
    local waves, view, size = shown[Canvas.SEA], Canvas.view, Canvas.SEA_SIZE
    local c, corner = waves and waves._coords, waves and waves._points[1]
    local function Whole(x) return near(x, math.floor(x + 0.5)) end
    check(c and corner and near(waves._alpha, Canvas.WAVE[4]) and c[1] >= 0 and c[1] < 1 and c[3] >= 0 and c[3] < 1
        and near(c[2] - c[1], (view.right - view.left) * view.k / size)
        and near(c[4] - c[3], (view.top - view.bottom) * view.k / size)
        and Whole(c[1] - view.left * view.k / size) and Whole(c[3] + view.top * view.k / size)
        and corner[1] == "TOPLEFT" and corner[2] == waves._parent and near(corner[4], (view.left - view.u) * view.k)
        and near(corner[5], (view.top - view.v) * view.k),
        "Scrying: the sea's waves over the whole view, on the holder, laid by the plane, a copy SEA_SIZE units wide")
end
local function Button(key)
    for _, widget in ipairs(W.frames) do if widget.key == key and widget._scripts.OnClick then return widget end end
end
check(Button("terrain")._lit and not Button("sketches")._lit, "the view chosen is lit")
check(Button("sketches")._shown and Button("blend")._shown and Button("terrain")._shown and not Button("atlas")
    and Button("blend")._points[1][2] == Button("sketches") and Button("terrain")._points[1][2] == Button("blend"),
    "three buttons in a row, no Atlas")
Button("sketches")._scripts.OnClick(Button("sketches"))
shown = Shown()
check(ns.options.view == "sketches" and Button("sketches")._lit and Count(shown, 801, 804) == 0
    and Count(shown, 141501, 141512) > 0 and Overviews(shown, 0, "Sketches") > 0 and Count(shown, 142901, 142912) > 0,
    "Sketches: the continent's map, the stitched map over it, the zone's own map over that")
check(not shown[Canvas.SEA], "Sketches: the paper past the map, no waves")
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
    check(shown[Canvas.SEA] and near(shown[Canvas.SEA]._alpha, Canvas.WAVE[4] * (1 - faded)),
        "Blended between: the waves faded as the sea's colour goes over into the paper")
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
-- The pins drawn now, by the thing each stands for (Core's: its thing; a marker of one thing's spawns: "gathered:" and
-- its first pin's; laid: also those laid out past the canvas' edge, out of sight there).
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
check(full.level == "zone" and count == 13, "the zone's pins: 13 things, each its own pin (two near each other side by side)")
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
    -- The game's pins are kept in parts: the part that changed is read again, the others kept (a zone's level asks the
    -- game for some twenty maps, several questions each).
    local flight, rare, log = Pin("flight:2"), Pin("npc:70"), Pin("quest:7")
    Pins.Changed("vignettes")
    check(flight and rare and log and Pin("flight:2") == flight and Pin("quest:7") == log and Pin("npc:70") ~= rare,
        "a rare came or went: the game's vignettes read again, its quests and flight points kept")
    rare = Pin("npc:70")
    Pins.Changed("flights")
    check(Pin("flight:2") ~= flight and Pin("quest:7") == log and Pin("npc:70") == rare, "a flight point found: the flight points alone")
    flight = Pin("flight:2")
    Pins.Changed("zone")
    check(Pin("flight:2") == flight and Pin("quest:7") == log and Pin("npc:70") ~= rare, "a zone entered: its vignettes alone")
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
    GameTooltip._lines = nil
    if marker then marker._scripts.OnEnter(marker) end
    local herb = marker and marker.pin.gathered[1]
    check(#now == 2 and riders == 1 and marker and #marker.pin.gathered == 2
        and GameTooltip._text == "|A:" .. herb.atlas .. ":16:16|a " .. herb.name and GameTooltip._lines == nil
        and marker.icon._atlas == herb.atlas,
        "herbs of a kind in one cell of the gather's grid: one goes on, the other rides with it; one marker of both in "
        .. "their own icon, its tooltip naming what is there once with its icon, no sentence about the click")
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
        and teacher.pin.role == "Warrior Trainer" and not teacher.pin.lines,
        "a trainer: its title says what it trains (no plain Trainer), a class's trainer the class book")
    check(giver.pin.role == Pins.TEXT.questGiver and giver.pin.name ~= giver.pin.role and not pins["npc:72"].pin.lines[1][1]:find(giver.pin.name, 1, true),
        "an NPC's pin is named by what it is, never by its own name: a quest giver without a title")
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
check(pins["flight:2"].pin.tint == Pins.RED and pins["flight:2"].icon._vertex[2] == Pins.RED[2]
    and pins["flight:2"].pin.lines[1] == Pins.TEXT.undiscovered,
    "one this character has not found (no flight master opened yet): red, its tooltip says so")
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
    local every = ns.DockWatch.TEXT.about:format(ns.DockWatch.Clock(Core.Data.Ships():Table(3).round))
    check(lines and lines[1] == every and lines[2] == Pins.TEXT.ports and lines[3] == "1. The Far Shore, Kalimdor"
        and lines[4] == "2. Elwynn Forest (this port)" and lines[5] == Pins.TEXT.openMap and not lines[6],
        "its tooltip: how often it sails (no ride yet); its ports in the order it travels to them, this one last, the "
        .. "area and the zone in the game's words; the game's own way, not unconfirmed")
    check(dock.UpdateTooltip, "kept up while it shows: the game's tooltip asks its owner again and again")
    GameTooltip._lines = nil
    dock:UpdateTooltip()
    check(not GameTooltip._lines, "within the same second nothing drawn again")
    W.Wait(1)
    dock:UpdateTooltip()
    check(GameTooltip._lines and GameTooltip._lines[1] == every, "a second later: drawn again")
    -- A way round three ports, stopping twice in a row at the second: from there the third, the first, then back.
    local record = { docks = { { map = 1429 }, { map = 1414 }, { map = 1415 } }, dockAreas = { 0, 12, 0 } }
    local round = { stops = { { dock = 1 }, { dock = 2 }, { dock = 2 }, { dock = 3 } } }
    local ports = Pins.Ports(record, round, 2)
    check(ports and #ports == 3 and ports[1].map == 1415 and ports[2].map == 1429 and ports[3].map == 1414
        and ports[3].area == 12 and ports[3].here and not ports[1].here and not ports[1].area,
        "a way of three ports: from its second the third, the first, and the second last; a port it stops at twice in a row once")
    check(Pins.Ports(record, nil, 2) == nil and Pins.Ports(record, round, 4) == nil, "none without its timetable or a stop there")
end
-- An innkeeper and a herb 40 yards apart would cover each other at this zoom: side by side in a cloud (Pins.Spread),
-- each its own pin in its own icon, pushed from its place, no marker with the game's plus.
pins = Drawn()
local inn, silverleaf = pins["npc:69"], pins["object:1617"]
local apart = inn and silverleaf and math.sqrt((inn.x - silverleaf.x) ^ 2 + (inn.y - silverleaf.y) ^ 2) or 0
check(inn and silverleaf and not pins["gathered:npc:69"] and inn.icon._atlas == "innkeeper"
    and silverleaf.icon._atlas == "professions_tracking_herb"
    and apart >= math.max(inn._width, silverleaf._width) * Pins.SPACE - 0.01
    and (inn.pin.sx ~= 0 or inn.pin.sy ~= 0 or silverleaf.pin.sx ~= 0 or silverleaf.pin.sy ~= 0),
    "an innkeeper and a herb that would cover each other: side by side in a cloud, each in its own icon, not the plus")
GameTooltip._lines = nil
inn._scripts.OnEnter(inn)
check(GameTooltip._text == Core.UNCONFIRMED_MARK .. "Innkeeper", "each its own tooltip: the innkeeper's, its red ! (not yet confirmed)")
inn._scripts.OnLeave(inn)
-- What a thing gives, on its pin's tooltip: how often, as Core counted it; the likeliest first, at most so many lines
;(function()
    local Tally, Pelt, Charm, Gem, Hide, Note = Core.Data.Tally, 3000, 3001, 3002, 3003, 3004
    W.methods.AddDoubleLine = function(self, left, right) self:AddLine(left .. " | " .. right) end
    local onQuest, itemInfo = rawget(C_QuestLog, "IsOnQuest"), C_Item.GetItemInfo
    C_Item.GetItemInfo = function(id)
        if W.items[id] then return W.items[id].name, nil, W.items[id].quality end
    end
    for id, name in pairs({ [Pelt] = "Wolf Pelt", [Charm] = "Fang Charm", [Gem] = "Moon Gem", [Hide] = "Thick Hide", [Note] = "Torn Note" }) do
        W.items[id] = { name = name, quality = id == Charm and 3 or 1 }
    end
    for index = 1, 40 do
        Tally.Loot("npc:70", "loot", 0)
        Tally.Drop("npc:70", "loot", Pelt, 0, 1)
        if index <= 3 then Tally.Drop("npc:70", "loot", Charm, 0, 1) end
    end
    Tally.Drop("npc:70", "loot", Gem, 0, 1)
    Tally.Loot("npc:70", "skin", 0)
    Tally.Drop("npc:70", "skin", Hide, 0, 1)
    Tally.Loot("npc:70", "loot", 77)
    Tally.Drop("npc:70", "loot", Note, 77, 1)
    local rare = pins["npc:70"]
    local function Tipped(pin)
        GameTooltip._lines = nil
        pin._scripts.OnEnter(pin)
        return GameTooltip._lines or {}
    end
    local lines = Tipped(rare)
    local text = table.concat(lines, "\n")
    check(lines[1] == ns.PinView.TEXT.rare and lines[2] == Pins.TEXT.dropsCorpse
        and text:find("Thick Hide (skinned) | 1 of 1", 1, true),
        "a rare's tooltip: Rare under its name, what it drops under its heading; another way said; too few, how many of how many")
    check(text:find("Wolf Pelt | 100% (40 of 40)", 1, true) and text:find("Fang Charm | 7.5% (3 of 40)", 1, true)
        and text:find("Moon Gem | 1 of 40", 1, true), "how often each came, a percent once enough did")
    check(not text:find("Torn Note", 1, true), "an item only for those on a quest: not while you are not")
    C_QuestLog.IsOnQuest = function(quest) return quest == 77 end
    check(table.concat(Tipped(rare), "\n"):find("Torn Note | 1 of 1", 1, true), "while you are, it is")
    C_QuestLog.IsOnQuest = onQuest
    local most = ns.PinView.DROPS
    ns.PinView.DROPS = 2
    lines = Tipped(rare)
    check(#lines == 5 and lines[5] == ns.Dungeons.TEXT.more:format(2), "at most so many lines, and how many more")
    ns.PinView.DROPS = most
    rare._mouseOver = true
    W.items[Gem] = nil
    GameTooltip._lines = nil
    rare._scripts.OnEnter(rare)
    W.items[Gem] = { name = "Moon Gem", quality = 1 }
    GameTooltip._lines = nil
    W.Fire("ITEM_DATA_LOAD_RESULT", Gem, true)
    W.Wait(0)
    check(table.concat(GameTooltip._lines or {}, "\n"):find("Moon Gem", 1, true), "an item the game had not loaded: the tooltip drawn again once it has")
    rare._mouseOver = false
    rare._scripts.OnLeave(rare)
    check(ns.PinView.Often({ chance = 0, drops = 0, loots = 0 }) == Pins.TEXT.dropUnder
        and ns.PinView.Often({ chance = 12, listed = true, drops = 1, loots = 2 }) == "12%"
        and ns.PinView.Often({ drops = 0, loots = 0 }) == nil, "a 0 of the set is under 1 %, the set's chance stands alone, nothing known says nothing")
    for index = 1, 4 do
        Tally.Loot("object:1617", "gather", 0)
        if index == 1 then Tally.Drop("object:1617", "gather", Gem, 0, 1) end
    end
    lines = Tipped(Drawn()["object:1617"])
    check(table.concat(lines, "\n"):find("Moon Gem | 1 of 4", 1, true), "the herb's own pin in the cloud: what it gives")
    W.methods.AddDoubleLine, C_Item.GetItemInfo = nil, itemInfo
end)()
-- What your quests still ask for, at every spawn Core knows of it; no glow until the mouse is on the quest in the log
;(function()
    local Quests, Spawns, Creatures, Drops = Core.Data.Set("Quests"), Core.Data.Set("Spawns"), Core.Data.Set("CreatureSpawns"),
                                             Core.Data.Drops()
    local Facts, Goals, PinView, QuestLog = Core.Data.Set("NPCs"), ns.Goals, ns.PinView, ns.QuestLog
    local get, spawned, name, from, objectives = Quests.Get, Spawns.Get, Facts.Get, Drops.From, C_QuestLog.GetQuestObjectives
    local unverified, read = Creatures.Unverified, Quests.Ready
    local asked = {
        { index = 1, kind = "kill", what = 900 },  -- at two far points of CreatureSpawns, nothing in Spawns
        { index = 2, kind = "loot", what = 5000 }, -- from a likely creature, an unlikely one, one of no known chance, an object
        { index = 3, kind = "talk", what = 904 },
        { index = 4, kind = "kill", what = 75 },   -- a trainer of Spawns, with a pin of its own
        { index = 5, kind = "explore", what = 44 },
        { index = 6, kind = "kill", what = 905 },  -- finished
    }
    local open = { { text = "Boars slain: 2/9" }, { text = "Tusks: 0/4" }, { text = "Speak with him" }, { text = "The teacher" },
                   { text = "Find it" }, { text = "Done: 1/1", finished = true } }
    Quests.Get = function(self, id, field)
        if id == 7 and not field then return { objectives = asked } end
        return get(self, id, field)
    end
    local PLACES = { [900] = { { map = 1429, x = 20, y = 80 }, { map = 1429, x = 90, y = 90 } }, [901] = { { map = 1429, x = 70, y = 30 } },
                     [902] = { { map = 1429, x = 30, y = 15 } }, [903] = { { map = 1429, x = 15, y = 40 } },
                     [904] = { { map = 1429, x = 65, y = 75 } }, [905] = { { map = 1429, x = 5, y = 5 } } }
    Creatures.Get = function(self, id, field) return field == "points" and PLACES[id] or nil end
    Creatures.Unverified = function(self, id) return id == 900 end
    Spawns.Get = function(self, key, field)
        if key == "object:1618" and field == "points" then return { { map = 1429, x = 45, y = 92 } } end
        return spawned(self, key, field)
    end
    Facts.Get = function(self, id, field)
        if id == 900 and field == "name" then return "Boar" end
        return name(self, id, field)
    end
    Drops.From = function(self, item)
        if item ~= 5000 then return from(self, item) end
        return { { key = "npc:901", how = "loot", rate = 80 }, { key = "npc:902", how = "loot", rate = 10 },
                 { key = "zone:1429", how = "fish", rate = 9 }, { key = "npc:906", how = "skin", rate = 8 },
                 { key = "npc:903", how = "loot", rate = 0 }, { key = "object:1618", how = "gather", rate = 0 } }
    end
    C_QuestLog.GetQuestObjectives = function(quest) return quest == 7 and open or objectives(quest) end
    local function Buttons(thing)
        local list = {}
        for _, widget in ipairs(W.frames) do
            local pin = widget._kind == "Button" and widget._shown and widget.pin
            if pin and pin.kind == "goal" and pin.thing == thing then list[#list + 1] = widget end
        end
        return list
    end
    local function Again()
        Pins.Changed("quests")
        Canvas.Layout()
    end
    Pins.DataChanged()
    Canvas.Layout()
    local boars, spot = Buttons("npc:900"), Buttons("npc:901")[1]
    check(#boars == 2 and boars[1].pin.key ~= boars[2].pin.key and boars[1].pin.key:find("^goal:npc:900@1429:")
        and boars[1].icon._texture == QuestLog.SWORD and boars[1]._width == Pins.SIZE.goal,
        "a creature to kill: a pin at each of its spawns, from CreatureSpawns, the quest log's sword")
    check(spot and spot.icon._texture == QuestLog.SACK and #Buttons("object:1618") == 1 and #Buttons("npc:903") == 1,
        "an item to loot: the sack on what gives it; what gives it where no chance is known kept too")
    check(#Buttons("npc:902") == 0 and #Buttons("npc:906") == 0,
        "not what gives it far less often than the likeliest, nor what gives it another way (a skin)")
    check(Buttons("npc:904")[1] and Buttons("npc:904")[1].icon._texture == Goals.SPEAK, "a creature to speak to: the speech bubble")
    check(#Buttons("npc:905") == 0, "an objective done: no pin")
    check(not boars[1].glow._shown and not spot.glow._shown and not pins["quest:7"].glow._shown or pins["quest:7"].pin.focused,
        "no glow at rest")
    check(#Buttons("npc:75") == 1, "what your quest asks for that is more besides: the sword at its spawn")
    for _, widget in ipairs(W.frames) do
        local pin = widget._kind == "Button" and widget._shown and widget.pin
        check(not (pin and pin.kind == "service" and pin.thing == "npc:75"), "and not its own pin as well")
    end
    -- The mouse on the quest in the log: its pins glow a little, the others do not; off it, none
    local other = pins["flight:2"]
    PinView.Light(7)
    check(boars[1].glow._shown and spot.glow._shown and boars[1].glow._alpha == PinView.LIT_ALPHA
        and boars[1].glow._width == Pins.SIZE.goal * PinView.LIT, "the mouse on its quest: its pins glow a little")
    check(pins["quest:7"].glow._shown and not other.glow._shown, "the quest's own mark too, no other pin")
    Pins.Changed("quests")
    Canvas.Layout()
    check(Buttons("npc:900")[1].glow._shown, "and through a new layout, while the mouse stays")
    PinView.Light(nil)
    check(not boars[1].glow._shown and not spot.glow._shown, "off it: none")
    -- A tooltip: what stands there, its quests, the game's words now; unconfirmed
    GameTooltip._lines = nil
    boars[1]._scripts.OnEnter(boars[1])
    local lines = table.concat(GameTooltip._lines or {}, "\n")
    check(GameTooltip._text:find("Boar", 1, true) and GameTooltip._text:find(Core.UNCONFIRMED_MARK, 1, true)
        and lines:find("- Boars slain: 2/9", 1, true) and lines:find(Pins.TEXT.open, 1, true)
        and GameTooltip._lines[#GameTooltip._lines] == Pins.TEXT.unverified,
        "its tooltip: the thing with its red !, the quest, the objective in the game's words, Unconfirmed Data")
    boars[1]._scripts.OnLeave(boars[1])
    -- A count going up changes no pin; an objective done takes its own away
    local same = Buttons("npc:900")[1].pin
    open[1].text = "Boars slain: 3/9"
    Again()
    check(Buttons("npc:900")[1].pin == same, "a kill counted: the same pins, not made again")
    GameTooltip._lines = nil
    boars[1]._scripts.OnEnter(boars[1])
    check(table.concat(GameTooltip._lines or {}, "\n"):find("- Boars slain: 3/9", 1, true), "but the tooltip says it")
    boars[1]._scripts.OnLeave(boars[1])
    open[1].finished = true
    Again()
    check(#Buttons("npc:900") == 0 and #Buttons("npc:901") == 1, "an objective done: its pins go, the others stay")
    open[1].finished = nil
    -- Near each other: one creature's spawns in one spot a marker of their own, in its picture, never with other
    -- things (those stand beside it in the cloud)
    PLACES[900] = { { map = 1429, x = 70, y = 30 }, { map = 1429, x = 70.3, y = 30 }, { map = 1429, x = 25.2, y = 55 } }
    PLACES[901] = { { map = 1429, x = 70.1, y = 30 } }
    Pins.DataChanged()
    Canvas.Layout()
    local marker
    for _, widget in ipairs(W.frames) do
        local pin = widget._kind == "Button" and widget._shown and widget.pin
        if pin and pin.gathered and pin.gathered[1].kind == "goal" then marker = marker or widget end
        if pin and pin.gathered then
            local goals, others = 0, 0
            for _, each in ipairs(pin.gathered) do
                if each.kind == "goal" then goals = goals + 1 else others = others + 1 end
            end
            check(goals == 0 or others == 0, "objectives gather among themselves alone")
        end
    end
    check(marker and #marker.pin.gathered >= 2 and marker.icon._texture == marker.pin.gathered[1].texture
        and marker.plus == false, "a creature's spawns close together: one marker in its picture, not the plus")
    PinView.Light(7)
    check(marker.glow._shown, "a marker holding the quest's pins glows with them")
    PinView.Light(nil)
    GameTooltip._lines = nil
    marker._scripts.OnEnter(marker)
    check(table.concat(GameTooltip._lines or {}, "\n"):find("- Boars slain: 3/9", 1, true), "its tooltip says what they are for")
    marker._scripts.OnLeave(marker)
    -- The filter's switch; on a save from before there was one, on
    ns.SwitchPin("goal")
    Canvas.Layout()
    check(not Pins.Shows("goal") and #Buttons("npc:904") == 0, "switched off in the pin filter: no objectives' pins")
    local own
    for _, widget in ipairs(W.frames) do
        local pin = widget._kind == "Button" and widget._shown and widget.pin
        own = own or pin and pin.kind == "service" and pin.thing == "npc:75"
    end
    check(own, "the thing's own pin back")
    ns.SwitchPin("goal")
    check(Core.Settle(ns.name, { pins = { quest = true } }).pins.goal, "settings saved before they came: on")
    -- A game without Core's quests: none
    Quests.Ready = function() return false end
    Pins.DataChanged()
    Canvas.Layout()
    check(#Buttons("npc:904") == 0 and next(Goals.Wanted()) == nil, "without Core's quests no objectives' pins")
    Quests.Ready, Quests.Get, Spawns.Get, Creatures.Get, Facts.Get, Drops.From = read, get, spawned, nil, name, from
    Creatures.Unverified, C_QuestLog.GetQuestObjectives = unverified, objectives
    Pins.DataChanged()
    Canvas.Layout()
end)()
check(Canvas.LEVELS.pins > Hybrid.LEVEL and Hybrid.LEVEL > Canvas.MAP and Canvas.LEVELS.pins + ns.PinView.LEVELS + 1 < Canvas.LEVELS.marks
    and pins["quest:7"]._level > pins["place:2"]._level and pins["quest:7"]._level < frame:GetFrameLevel() + Canvas.LEVELS.marks
    and pins["place:2"]._level > frame:GetFrameLevel() + Hybrid.LEVEL,
    "every pin over the map and the game's minimap, a quest over a service, all under the player's arrow")
check(pins["quest:7"]._level > pins["npc:72"]._level and pins["npc:72"]._level > pins["flight:2"]._level
    and pins["flight:2"]._level > pins["place:2"]._level,
    "a higher kind always over a lower one: a quest in your log, a quest to take, a flight point, a service")
-- Closer in the cloud parts: each at its own place again.
Canvas.ZoomTo(inn.pin.pu, inn.pin.pv, 3)
pins, count = Drawn()
check(full.k > 0.4 and pins["npc:69"] and pins["object:1617"] and pins["npc:69"].pin.sx == 0 and pins["npc:69"].pin.sy == 0
    and pins["object:1617"].pin.sx == 0 and pins["object:1617"].pin.sy == 0,
    "zoomed in: they part, each at its own place (no longer pushed aside)")
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
    "a place of Core's data: its facts, marked as not yet confirmed by the game (its set's file lists it unverified)")
;(function()
    -- Confirmed in play (Data.Confirm: a watcher, or a guild or group member's message): the note goes.
    check(Core.Data.Confirm("Places", 1) and not Core.Data.Set("Places"):Unverified(1), "the entrance confirmed in play")
    W.Wait(0)
    pins = Drawn()
    GameTooltip._lines = nil
    pins["place:1"]._scripts.OnEnter(pins["place:1"])
    check(GameTooltip._lines and GameTooltip._lines[1] == "Level 18 to 23" and not GameTooltip._lines[2],
        "confirmed, its pin's tooltip no longer says Unconfirmed Data")
end)()
-- Further out than a zone: only travel and places.
full:Show(1415, 0, -9250, 0.05)
Canvas.Layout()
pins = Drawn()
check(full.level == "continent" and pins["flight:2"] and pins["place:1"] and not pins["quest:7"] and not pins["npc:69"],
    "a continent whole: its flight points, entrances, ways and places; no quests or services")

-- The quest log at the full map's left: sorted by proximity at first, a click on its title the next way (Level,
-- Zone, Type); quests, objectives; a quest chosen.
local QuestLog = ns.QuestLog
check(QuestLog.Shown(), "full, the quest log stands at the map's left")
local logBox
for _, widget in ipairs(W.frames) do if widget.provider and widget.view and widget.Draw then logBox = widget end end
local rows = logBox:Draw()
check(QuestLog.Sort() == "proximity" and #rows == 5 and rows[1].row.quest == 8 and rows[2].row.done
    and rows[3].row.turnIn and rows[3].text._text == "- Report back to Marshal Dughan." and rows[4].row.quest == 7
    and rows[5].row.kind == "objective" and not rows[5].row.done,
    "sorted by proximity at first, no headers: the nearest quest first, every objective, a done one's turn in last")
check(rows[1].row.complete and rows[1].state._text == "", "a quest done: no Complete at its right")
check(QuestLog.handle.options.title == "|cffffffff2/25|r Proximity",
    "its title bar: how many quests of how many and how they are sorted, nothing more")
do
    local sortButton = QuestLog.handle.bar.find
    GameTooltip._lines = nil
    sortButton._scripts.OnEnter(sortButton)
    check(GameTooltip._text == "Sorted by proximity" and GameTooltip._lines
        and GameTooltip._lines[1] == "A click sorts them by level. A click beside these words hides the list.",
        "its title's tip: how they are sorted, how a click sorts them")
    sortButton._scripts.OnLeave(sortButton)
    questDistance[7] = 50
    W.Wait(QuestLog.RESORT)
    rows = logBox:Draw()
    check(rows[1].row.quest == 7 and rows[3].row.quest == 8, "the player walked on: the nearest first again, a moment later")
    questDistance[7] = 400
    sortButton._scripts.OnClick(sortButton)
    rows = logBox:Draw()
    check(QuestLog.Sort() == "level" and ns.store.questLogSort == "level" and rows[1].row.quest == 8 and rows[4].row.quest == 7
        and QuestLog.handle.options.title:find("Level", 1, true), "a click on the title: sorted by level, the lowest first; kept")
    sortButton._scripts.OnClick(sortButton)
    rows = logBox:Draw()
    check(QuestLog.Sort() == "zone" and #rows == 6 and rows[1].row.kind == "header" and rows[1].mark._shown
        and rows[2].row.quest == 7 and rows[3].row.kind == "objective" and rows[4].row.quest == 8 and rows[4].row.complete
        and rows[5].row.done and rows[6].row.turnIn,
        "again: by zone, the game's own, its headers with their fold marks; each quest with its objectives")
end
check(rows[2].text._text == "[6+] Wolves Across the Border", "a quest with its level, a + for one meant for a group")
;(function()
    -- An objective: how many, the game's sword or sack, what; words without a count as they are.
    local objectives = C_QuestLog.GetQuestObjectives
    local function Line(text, kind)
        C_QuestLog.GetQuestObjectives = function() return { { text = text, type = kind, finished = false } } end
        QuestLog.Refresh()
        return logBox:Draw()[3].text._text
    end
    local sword, sack = "|T" .. QuestLog.SWORD .. ":16:16|t", "|T" .. QuestLog.SACK .. ":16:16|t"
    check(Line("Nightstalker slain: 4/7", "monster") == "- 4/7 " .. sword .. ": Nightstalker", "a kill: its count, the sword, who")
    check(Line("4/7 Nightstalker slain", "monster") == "- 4/7 " .. sword .. ": Nightstalker", "with the count written first too")
    check(Line("Gold Dust: 4/10", "item") == "- 4/10 " .. sack .. ": Gold Dust", "a thing to loot: the sack")
    check(Line("Sealed Crate: 0/1", "object") == "- 0/1 " .. sack .. ": Sealed Crate", "a thing to find too")
    check(Line("Honor gained: 3/5", "reputation") == "- 3/5: Honor gained", "another kind: its count, no picture")
    check(Line("Speak to Salma", "event") == "- Speak to Salma", "no count: as the game has it")
    C_QuestLog.GetQuestObjectives = objectives
    QuestLog.Refresh()
    rows = logBox:Draw()
end)()
;(function()
    -- What makes a +: the game's tag of a group, its elite (Forever's own), a group it suggests; any other tag none.
    local tag, elite, info, list = C_QuestLog.GetQuestTagInfo, C_QuestLog.IsEliteQuest, C_QuestLog.GetInfo, logBox:Draw()
    local function Level()
        QuestLog.Refresh()
        return logBox:Draw()[2].text._text:match("^%\[(.-)%\]")
    end
    C_QuestLog.GetQuestTagInfo = function() return nil end
    check(Level() == "6", "no tag: no +")
    C_QuestLog.GetQuestTagInfo = function() return { tagName = "PvP", tagID = 41 } end
    check(Level() == "6", "a tag that is no group's: no +")
    C_QuestLog.GetQuestTagInfo = function() return { tagName = "Dungeon", tagID = 81 } end
    check(Level() == "6+", "a dungeon's: a +")
    C_QuestLog.GetQuestTagInfo = function() return { tagName = "", tagID = 0, isElite = true } end
    check(Level() == "6+", "an elite's: a +")
    C_QuestLog.GetQuestTagInfo = function() return nil end
    C_QuestLog.IsEliteQuest = function() return true end
    check(Level() == "6+", "the game calls it elite: a +")
    C_QuestLog.IsEliteQuest = elite
    C_QuestLog.GetInfo = function(index)
        local entry = info(index)
        if type(entry) == "table" and not entry.isHeader then entry.suggestedGroup = 3 end
        return entry
    end
    check(Level() == "6+", "a group suggested: a +")
    C_QuestLog.GetInfo = function(index)
        local entry = info(index)
        if type(entry) == "table" and not entry.isHeader then entry.suggestedGroup = 1 end
        return entry
    end
    check(Level() == "6", "one player suggested: no +")
    C_QuestLog.GetQuestTagInfo, C_QuestLog.GetInfo = tag, info
    QuestLog.Refresh()
    rows = logBox:Draw()
end)()
check(not rows[2].icon._shown and not rows[4].icon._shown and rows[2].left == 0
    and rows[2].text._points[1][1] == "LEFT" and rows[2].text._points[1][4] == 0 and rows[3].left == QuestLog.INDENT,
    "no mark before a quest: its words at the very start of its row, its objectives a little in")
;(function()
    -- The game's own log has its headers folded: each zone's quests are listed under it all the same.
    local info = C_QuestLog.GetInfo
    C_QuestLog.GetInfo = function(index)
        local entry = info(index)
        if entry and entry.isHeader then entry.isCollapsed = true end
        return entry
    end
    QuestLog.Refresh()
    local listed = logBox:Draw()
    check(#listed == 6 and not listed[1].row.collapsed and listed[2].row.quest == 7 and listed[4].row.quest == 8,
        "the game's own log's headers folded: the quests under their zone all the same")
    C_QuestLog.GetInfo = info
    QuestLog.Refresh()
    listed = logBox:Draw()
    listed[1]._scripts.OnClick(listed[1], "LeftButton")
    listed = logBox:Draw()
    check(#listed == 1 and listed[1].row.collapsed and listed[1].mark._atlas == "campaign_headericon_closed"
        and ns.store.questLogFolds["Elwynn Forest"], "a click on a zone over the full map: folded, its quests not listed; kept")
    listed[1]._scripts.OnClick(listed[1], "LeftButton")
    listed = logBox:Draw()
    check(#listed == 6 and not listed[1].row.collapsed and not ns.store.questLogFolds["Elwynn Forest"], "again: open")
    -- The folds saved in another shape (an older version's): nothing folded, no error; the next fold makes them anew.
    ns.store.questLogFolds = true
    QuestLog.Refresh()
    listed = logBox:Draw()
    listed[1]._scripts.OnClick(listed[1], "LeftButton")
    check(#listed == 6 and type(ns.store.questLogFolds) == "table" and ns.store.questLogFolds["Elwynn Forest"]
        and #logBox:Draw() == 1, "the folds saved in another shape: nothing folded, no error; a click makes them anew")
    listed = logBox:Draw()
    listed[1]._scripts.OnClick(listed[1], "LeftButton")
    ns.store.questLogFolds = nil
end)()
do
    local was, saved = { map = full.map, u = full.u, v = full.v, k = full.k, follow = full.follow }, waypoint
    local u, v = Coords.MapToPlane(1429, 0.4, 0.4, Coords.PlaneOf(1429))
    waypoint = nil
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    check(focused == 0 and not waypoint, "a click waits a moment for a second one")
    W.Wait(ns.Canvas.DOUBLE)
    check(focused == 7 and not waypoint and full.map == Coords.PlaneOf(1429) and near(full.u, u) and near(full.v, v)
        and full.k == was.k and not full.follow,
        "a click: the game's arrow leads to it, the map moves to its objective at the zoom it has; no map pin")
    QuestLog.Text(nil)
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = was.follow
    Canvas.Layout()
    focused = 0
    rows = logBox:Draw()
    local element = rows[2]
    element._scripts.OnClick(element, "LeftButton")
    rows = logBox:Draw()
    rows[2]._scripts.OnClick(rows[2], "LeftButton") -- the list's rows drawn anew between: another button, the same quest
    check(waypoint and waypoint.uiMapID == 1429 and near(waypoint.position.x, 0.4) and near(waypoint.position.y, 0.4)
        and focused == 7 and near(full.u, u) and near(full.v, v), "a double click: the same, and the game's map pin on its objective")
    W.Wait(ns.Canvas.DOUBLE * 2)
    rows = logBox:Draw()
    local unfolded = false
    for _, each in ipairs(rows) do unfolded = unfolded or each.row.kind == "text" end
    check(not unfolded, "and its text as it was: no text unfolds for a double click")
    -- A quest not on the player's map, nor found zone by zone: the map the game names for it.
    local best, planes = C_Map.GetBestMapForUnit, ns.Coords.Planes
    C_Map.GetBestMapForUnit, ns.Coords.Planes = function() return 12 end, function() return {} end
    GetQuestUiMapID = function() return 1429 end
    waypoint = nil
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    check(waypoint and waypoint.uiMapID == 1429, "elsewhere: on the map the game names for the quest")
    C_Map.GetBestMapForUnit, ns.Coords.Planes, GetQuestUiMapID = best, planes, nil
    waypoint = saved
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = was.follow
    Canvas.Layout()
end
rows = logBox:Draw()
check(rows[2]._lit and not rows[4]._lit, "the quest clicked lit in the list")
-- A watched quest has no tick; a quest's item at the far end of its row; the log mirrored on the screen's right half.
;(function()
    watched[7] = true
    QuestLog.Refresh()
    rows = logBox:Draw()
    check(not rows[2].mark._shown and not rows[4].mark._shown, "a watched quest: no tick")
    watched[7] = nil
    local function Items()
        local list = {}
        for _, widget in ipairs(W.frames) do
            if widget._template == "SecureActionButtonTemplate" and widget._attributes and widget._attributes.type == "item" then
                list[#list + 1] = widget
            end
        end
        return list
    end
    logBox._left, logBox._right, logBox._top, logBox._bottom = 20, 300, 800, 100
    W.special[2] = { "|cffffffff|Hitem:5000:0:0|h[Torch]|h|r", 134400, 3 }
    W.special[3] = { "|Hitem:5001|h[Spent]|h", 134401, 1 }
    QuestLog.Refresh()
    rows = logBox:Draw()
    local function Laid(wanted)
        for index, element in ipairs(rows) do
            local middle = wanted or (760 - index * 20)
            element.GetCenter = function() return 0, middle end
        end
    end
    Laid()
    W.Wait(0)
    local quest = rows[2] -- by zone yet: the header, then this quest
    check(quest.row.item == 5000 and logBox.view.height(nil, quest.row) == QuestLog.ITEM and not rows[4].row.item,
        "a quest with its item, its row as high as the item; a quest done has none, unless the game keeps it")
    local items = Items()
    check(#items == 1 and items[1]._shown and items[1]._attributes.item == "item:5000" and items[1]._attributes.type == "item"
        and items[1].count._text == 3, "its button uses that item, and says how many charges it has")
    local point = items[1]._points[#items[1]._points]
    check(items[1]._parent._parent == UIParent, "its button no part of the log: a fight may not lock the log")
    check(point[1] == "RIGHT" and point[4] == 300 and point[5] == 720, "at the list's right, beside its row")
    local state = quest.state._points[1]
    check(state[1] == "RIGHT" and state[4] == -(QuestLog.ITEM + 4), "its row's words keep clear of it")
    check(items[1]._attributes.useOnKeyDown == false and #items[1]._registered == 1 and items[1]._registered[1] == "AnyUp",
        "a click acts on its release, any button, as on the game's tracker, whatever the game's option for keys says")

    -- The mouse on it: the game's tooltip of what is carried, and it counts as the mouse on the log.
    ;(function()
        local tip, was = {}, {}
        for _, name in ipairs({ "SetOwner", "SetQuestLogSpecialItem", "SetItemByID", "Show" }) do
            was[name] = GameTooltip[name]
            GameTooltip[name] = function(_, a, b) tip[#tip + 1] = { name, a, b } end
        end
        local window = QuestLog.handle.frame
        window._scripts.OnUpdate = nil
        items[1]._scripts.OnEnter(items[1])
        check(tip[1][1] == "SetOwner" and tip[1][2] == items[1] and tip[1][3] == "ANCHOR_RIGHT"
            and tip[2][1] == "SetQuestLogSpecialItem" and tip[2][2] == 2 and tip[3][1] == "Show",
            "the mouse on it: the game's tooltip of what is carried, by its quest's place in the log")
        check(window._scripts.OnUpdate, "and the mouse on it counts as the mouse on the log")
        wipe(tip)
        local index = C_QuestLog.GetLogIndexForQuestID
        C_QuestLog.GetLogIndexForQuestID = function() return nil end
        items[1]._scripts.OnEnter(items[1])
        C_QuestLog.GetLogIndexForQuestID = index
        check(tip[2][1] == "SetItemByID" and tip[2][2] == 5000, "its quest gone from the log, a fight holding the button: the item as such")

        -- The list changed under the mouse: the tooltip says what the button under it uses now.
        wipe(tip)
        GameTooltip._owner = items[1]
        W.special[2] = { "|Hitem:5002|h[Rod]|h", 134402, 2 }
        W.Fire("BAG_UPDATE_DELAYED")
        rows = logBox:Draw()
        Laid()
        W.Wait(0)
        check(items[1]._attributes.item == "item:5002" and items[1].count._text == 2 and tip[2][1] == "SetQuestLogSpecialItem",
            "another item under the mouse: its button and its tooltip follow")
        GameTooltip._owner = nil
        for name, fn in pairs(was) do GameTooltip[name] = fn end
    end)()
    items[1]._scripts.OnLeave(items[1])

    -- A bag changed: the game tells of no charge lost or item come, so the rows are compared with it; no redraw for nothing.
    ;(function()
        local refresh, drawn = QuestLog.Refresh, 0
        QuestLog.Refresh = function(...) drawn = drawn + 1; return refresh(...) end
        W.Fire("BAG_UPDATE_DELAYED")
        check(drawn == 0, "a bag changed, the quests' items as they were: nothing drawn anew")
        W.special[2][3] = 1
        W.Fire("BAG_UPDATE_DELAYED")
        check(drawn == 1, "a charge lost: drawn anew")
        rows = logBox:Draw()
        Laid()
        W.Wait(0)
        check(items[1].count._text == "", "and its count follows")
        W.special[2] = nil
        W.Fire("BAG_UPDATE_DELAYED")
        check(drawn == 2, "the item gone: drawn anew")
        rows = logBox:Draw()
        Laid()
        W.Wait(0)
        check(not items[1]._shown, "the item gone from the bags: its button goes")
        W.special[2] = { "|cffffffff|Hitem:5000:0:0|h[Torch]|h|r", 134400, 3 }
        W.Fire("BAG_UPDATE_DELAYED")
        check(drawn == 3, "an item come into the bags: drawn anew")
        rows = logBox:Draw()
        Laid()
        W.Wait(0)
        check(items[1]._shown and items[1]._attributes.item == "item:5000" and items[1].count._text == 3, "and its button is back")
        QuestLog.Refresh = refresh
    end)()

    -- The link's modifier: with the chat's box open it links the item and uses nothing, with it closed a click uses it.
    ;(function()
        local button, links = items[1], #W.links
        local press, release = button._scripts.PreClick, button._scripts.PostClick
        W.modifier = "CHATLINK"
        press(button, "LeftButton")
        check(button._attributes.type == "item", "Shift and a click, the chat's box closed: it uses the item")
        release(button, "LeftButton")
        check(#W.links == links, "and writes nothing")
        ChatFrameUtil.GetActiveWindow = function() return {} end
        press(button, "LeftButton")
        check(button._attributes.type == "", "the box open: the click uses nothing")
        release(button, "LeftButton")
        check(#W.links == links + 1 and W.links[#W.links] == "|cffffffff|Hitem:5000:0:0|h[Torch]|h|r", "and links it")
        check(button._attributes.type == "item", "the next click uses it again, whatever comes next")
        W.combat = true
        press(button, "LeftButton")
        check(button._attributes.type == "item", "in a fight the game locks what it does: nothing set")
        release(button, "LeftButton")
        check(button._attributes.type == "item", "nor after it")
        check(#W.links == links + 1, "and the click used the item alone: no link written beside it")
        W.combat = false
        ChatFrameUtil.GetActiveWindow, W.modifier = nil, nil
    end)()

    -- Scrolled away: its button goes with it; a fight holds them as they stand, and they follow once it is over.
    Laid(900)
    logBox.scrolled()
    W.Wait(0)
    check(not items[1]._shown and items[1]._parent.Hide and not items[1]._parent._shown, "its row scrolled out of the list: its button away")
    Laid()
    W.combat = true
    logBox.scrolled()
    W.Wait(0)
    check(not items[1]._shown, "in a fight it stays as it was")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(items[1]._shown and items[1]._parent._shown and W.drivers[items[1]._parent] == "[combat] hide; show",
        "once over it follows; over the full map a fight takes it out of sight, by the game's driver")
    W.special[2], W.special[3] = nil, nil
    QuestLog.Refresh()
    logBox:Draw()
    W.Wait(0)
    check(not items[1]._shown and not items[1]._parent._shown and not W.drivers[items[1]._parent], "no item any more: no button")
    W.special[2] = { "|Hitem:5000|h[Torch]|h", 134400, 1 }

    -- On the screen's right half: mirrored, as soon as it stands there.
    local log = QuestLog.handle
    log.frame.GetCenter = function() return 1200, 400 end
    log:Place()
    rows = logBox:Draw()
    Laid()
    W.Wait(0)
    quest = rows[2]
    check(quest.text._points[1][1] == "RIGHT" and quest.text._justify == "RIGHT" and rows[1].text._points[1][1] == "RIGHT"
        and rows[3].text._points[1][4] == -QuestLog.INDENT, "on the screen's right half: its words at the right, right aligned")
    check(log.titleSide == "RIGHT" and log.bar.title._points[1][1] == "RIGHT", "its title too")
    point = items[1]._points[#items[1]._points]
    check(point[1] == "LEFT" and point[4] == 20 and point[5] == 720, "and its item at the list's left")
    QuestLog.Text(7)
    local unfolded, headed
    for _, element in ipairs(logBox:Draw()) do
        if element.row.kind == "text" then unfolded = element end
        if element.row.kind == "section" then headed = element end
    end
    check(unfolded and unfolded.text._points[1][1] == "TOPRIGHT" and unfolded.text._justify == "RIGHT"
        and headed.text._points[1][1] == "BOTTOMRIGHT" and headed.text._justify == "RIGHT",
        "a quest's text right aligned too, its headings and all")
    -- Sized with its text open (a grip dragged, a step a frame): read anew once the size rests, not at every step.
    local refresh, refreshed = QuestLog.Refresh, 0
    QuestLog.Refresh = function(...) refreshed = refreshed + 1 return refresh(...) end
    local panel = logBox._parent
    for _ = 1, 5 do panel._scripts.OnSizeChanged(panel, 300, 400) end
    check(refreshed == 0, "sized five times with a quest's text open: not read anew at every step")
    W.Wait(QuestLog.REFLOW)
    check(refreshed == 1, "but once, as the size rests")
    QuestLog.Refresh = refresh
    QuestLog.Text(nil)
    log.frame.GetCenter = nil
    log:Place()
    rows = logBox:Draw()
    check(rows[2].text._points[1][1] == "LEFT" and rows[2].text._justify == "LEFT" and log.titleSide == "LEFT",
        "back on the left half: as it was")
    W.special[2] = nil
    QuestLog.Refresh()
    rows = logBox:Draw()
    W.Wait(0)
end)()
-- A click unfolds a quest's text under it, one quest's at a time; the right button: its text, the map at its objective.
do
    -- The first row of the open quest's text, where in the list it stands, and all of them.
    local function Text()
        rows = logBox:Draw()
        local first, at, parts = nil, nil, {}
        for index, element in ipairs(rows) do
            if element.row.part then
                first, at = first or element, at or index
                parts[#parts + 1] = element
            end
        end
        return first, at, parts
    end
    local function Words(parts)
        local words = {}
        for _, element in ipairs(parts) do words[#words + 1] = element.text._text or "" end
        return table.concat(words, "\n")
    end
    local function Click(element)
        element._scripts.OnClick(element, "LeftButton")
        W.Wait(ns.Canvas.DOUBLE)
    end
    check(not Text(), "no text under a quest at first")
    logBox._height = 200
    Click(rows[2])
    local said, at, parts = Text()
    check(said and said.row.quest == 7 and at == 4 and #parts == 4 and parts[1].row.kind == "section"
        and parts[1].text._text == "Description" and parts[2].row.kind == "text" and parts[2].text._wrap
        and parts[2].text._text == "The story of quest 2" and parts[3].row.kind == "section"
        and parts[3].text._text == "Quest Objectives" and parts[4].text._text == "Kill eight wolves.",
        "a click: its text unfolds under it and its objectives, its story first, each part under its heading")
    check(parts[2].text._points[1][1] == "TOPLEFT" and logBox.view.height(nil, parts[2].row) == 40 + QuestLog.ROOM
        and logBox.view.height(nil, parts[1].row) == QuestLog.SECTION, "the words' row as high as they take")
    check(parts[1].back._shown and parts[1].rule._shown and parts[4].back._shown and not rows[2].back._shown
        and not rows[2].rule._shown and not parts[2].light._shown, "on a panel of its own, the quest's row without")
    check(logBox.brought == said.row and logBox.aligned == ScrollBoxConstants.AlignNearest, "and brought into sight")
    Click(rows[2])
    check(not Text(), "a click again: folded away")
    Click(rows[4])
    said, at = Text()
    check(said and said.row.quest == 8 and at == 7, "another quest: its text, under its objectives and its turn in")
    Click(rows[2])
    said, at = Text()
    check(said and said.row.quest == 7 and at == 4, "and another: one quest's at a time")
    said, at, parts = Text()
    parts[2]._scripts.OnClick(parts[2], "LeftButton")
    check(not Text(), "a click on the text itself folds it away too")
    logBox._height = 20
    Click(rows[2])
    said = Text()
    check(logBox.brought == said.row and logBox.aligned == ScrollBoxConstants.AlignBegin, "taller than the list: from its start")
    logBox._height = nil
    QuestLog.Text(nil)
    rows = logBox:Draw()
    -- Its rewards, as the game has them: experience and coin in words, the things as big icons with their names.
    GetQuestLogRewardXP = function() return 450 end
    GetQuestLogRewardMoney = function() return 1250 end
    local currency = rawget(_G, "C_CurrencyInfo")
    C_CurrencyInfo = { GetCoinTextureString = function(money) return money .. " coins" end }
    ITEM_QUALITY_COLORS = { [2] = { r = 0.1, g = 1, b = 0 } }
    GetNumQuestLogRewards = function() return 3 end
    GetQuestLogRewardInfo = function(index, quest)
        if quest ~= 7 then return nil end
        if index == 1 then return "Wolf Cloak", 133, 2, 2, true, 901 end
        if index == 2 then return "Old Sword", 135, 1, 1, false, 902 end
        return nil, nil, nil, nil, nil, 903 -- not known to the game yet
    end
    GetNumQuestLogChoices = function() return 3 end
    GetQuestLogChoiceInfo = function(index)
        if index <= 3 then return ({ "Boots", "Gloves", "Belt" })[index], 134, 1, nil, true, 910 + index end
    end
    local system, book, bank = rawget(_G, "C_QuestInfoSystem"), rawget(_G, "C_SpellBook"), Enum.SpellBookSpellBank
    C_QuestInfoSystem = { GetQuestRewardSpells = function() return { 77, 78 } end,
                          GetQuestRewardSpellInfo = function(_, spell) return { texture = 136, name = "Spell " .. spell } end,
                          GetQuestRewardCurrencies = function()
                              return { { currencyID = 5, name = "Token", texture = 137, quality = 2, totalRewardAmount = 3 } }
                          end }
    C_SpellBook = { IsSpellInSpellBook = function(spell) return spell == 78 end }
    Enum.SpellBookSpellBank = { Player = 0 }
    logBox._width = 300
    Click(rows[2])
    said, at, parts = Text()
    local kinds = {}
    for _, element in ipairs(parts) do kinds[#kinds + 1] = element.row.kind end
    check(table.concat(kinds, " ") == "section text section text section text reward reward text reward reward",
        "its story, what it asks, then what it gives: " .. table.concat(kinds, " "))
    check(parts[1].text._text == "Description" and parts[3].text._text == "Quest Objectives" and parts[5].text._text == "Rewards"
        and parts[6].text._text == "450 experience    1250 coins" and parts[9].text._text == QuestLog.TEXT.choices,
        "experience and coin in words, then what to choose from")
    local first = parts[7].row
    check(#first.things == 2 and first.things[1].name == "Wolf Cloak" and first.things[2].name == "Old Sword"
        and #parts[8].row.things == 2 and parts[8].row.things[1].name == "Token" and parts[8].row.things[2].name == "Spell 77"
        and #parts[10].row.things == 2 and parts[10].row.things[1].name == "Boots" and #parts[11].row.things == 1,
        "two side by side, its currency and the spell not known yet too; a thing not known yet left out for now")
    local cell = parts[7].cells[1]
    check(cell._shown and first.width == 138 and logBox.view.height(nil, first) == QuestLog.REWARD + QuestLog.GAP
        and cell._points[1][1] == "TOPLEFT" and cell._points[1][4] == QuestLog.INSET
        and parts[7].cells[2]._points[1][4] == QuestLog.INSET + 142, "each in its half of the row")
    check(cell.icon._width == 40 and cell.icon._height == 40 and cell.name._text == "Wolf Cloak" and cell.count._text == 2
        and cell.rim._shown and cell.rim._vertex[2] == 1 and cell.name._color[1] == 0.1,
        "a big icon, its name and how many, its rim and name in its quality's colour")
    local sword = parts[7].cells[2]
    check(sword.icon._vertex[2] == 0 and sword.count._text == "" and not sword.rim._shown and sword.name._color[1] == 1,
        "one this character cannot use: its icon red, as the game has it; one of a kind: no number")
    ;(function()
        local tip = {}
        local was = {}
        for _, name in ipairs({ "SetOwner", "SetQuestLogItem", "SetItemByID", "SetSpellByID", "SetCurrencyByID", "Show" }) do
            was[name] = GameTooltip[name]
            GameTooltip[name] = function(_, a, b, c) tip[#tip + 1] = { name, a, b, c } end
        end
        local compared
        GameTooltip_ShowCompareItem = function() compared = true end
        cell._scripts.OnEnter(cell)
        check(tip[1][1] == "SetOwner" and tip[1][2] == cell and tip[1][3] == "ANCHOR_RIGHT" and tip[2][1] == "SetQuestLogItem"
            and tip[2][2] == "reward" and tip[2][3] == 1 and tip[2][4] == 7 and compared and tip[3][1] == "Show",
            "the mouse on a reward: the game's tooltip of it, by the quest's ID, compared with what is worn")
        wipe(tip)
        compared = false
        parts[8].cells[1]._scripts.OnEnter(parts[8].cells[1])
        check(tip[2][1] == "SetCurrencyByID" and tip[2][2] == 5 and not compared, "of a currency")
        wipe(tip)
        parts[8].cells[2]._scripts.OnEnter(parts[8].cells[2])
        check(tip[2][1] == "SetSpellByID" and tip[2][2] == 77 and not compared, "of a spell")
        wipe(tip)
        parts[10].cells[1]._scripts.OnEnter(parts[10].cells[1])
        check(tip[2][2] == "choice" and tip[2][3] == 1, "of a thing to choose from")
        for name, fn in pairs(was) do GameTooltip[name] = fn end
        GameTooltip_ShowCompareItem = nil
    end)()
    ;(function()
        -- As on the game's own rewards: a modified click links it, a plain one does nothing, not even folding.
        local linked
        HandleModifiedItemClick = function(link) linked = link end
        GetQuestLogItemLink = function(list, index, quest) return list .. index .. "/" .. quest end
        local modified = IsModifiedClick
        IsModifiedClick = function() return false end
        cell._scripts.OnClick(cell, "LeftButton")
        check(linked == nil and Text(), "a plain click on a reward: nothing, its text stays")
        IsModifiedClick = function() return true end
        cell._scripts.OnClick(cell, "LeftButton")
        check(linked == "reward1/7", "a modified click: the game's own for its link")
        IsModifiedClick, HandleModifiedItemClick, GetQuestLogItemLink = modified, nil, nil
    end)()
    ;(function()
        -- An item the game did not know yet: read again once it does, once however many came; none is waited for then.
        local refresh, drawn = QuestLog.Refresh, 0
        local info = GetQuestLogRewardInfo
        GetQuestLogRewardInfo = function(index, quest)
            if index == 3 then return "Late Ring", 139, 1, 2, true, 903 end
            return info(index, quest)
        end
        QuestLog.Refresh = function(...) drawn = drawn + 1 return refresh(...) end
        W.Fire("ITEM_DATA_LOAD_RESULT", 903, true)
        W.Fire("ITEM_DATA_LOAD_RESULT", 904, true)
        W.Wait(0)
        check(drawn == 1, "an item the text waited for arrived: read again once")
        local _, _, shown = Text()
        check(shown[8].row.things[1].name == "Late Ring" and shown[8].row.things[2].name == "Token", "and there it is")
        W.Fire("ITEM_DATA_LOAD_RESULT", 905, true)
        W.Wait(0)
        QuestLog.Refresh = refresh
        check(drawn == 1, "another item: the list not drawn anew for it")
        GetQuestLogRewardInfo = info
    end)()
    -- Narrow: one to a row; mirrored: from the other side, the plate turned round.
    logBox._width = 200
    QuestLog.Refresh()
    said, at, parts = Text()
    check(#parts[7].row.things == 1 and parts[7].row.width == 180, "too narrow for two: one to a row, as wide as the row")
    logBox._width = nil
    GetNumQuestLogRewards, GetNumQuestLogChoices = nil, nil
    C_QuestInfoSystem, C_SpellBook, ITEM_QUALITY_COLORS = system, book, nil
    Enum.SpellBookSpellBank = bank
    GetQuestLogRewardXP, GetQuestLogRewardMoney, C_CurrencyInfo = nil, nil, currency
    GetQuestLogRewardInfo, GetQuestLogChoiceInfo = nil, nil
    QuestLog.Text(nil)
    rows = logBox:Draw()
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
    said, at, parts = Text()
    check(said and Words(parts):find("Kill eight wolves.", 1, true), "Quest Details: its text under it")
    local index = C_QuestLog.GetLogIndexForQuestID
    C_QuestLog.GetLogIndexForQuestID = function() return nil end
    QuestLog.Refresh()
    check(not Text(), "a quest gone from the log: its text gone too")
    C_QuestLog.GetLogIndexForQuestID = index
    rows = logBox:Draw()
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
;(function()
    -- Shift is the link's modifier too, unless the player changed it.
    local insert = ChatFrameUtil.InsertLink
    GetQuestLink = function() return "[quest]" end
    W.modifier = "CHATLINK"
    IsShiftKeyDown = function() return true end
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    check(not watched[7] and W.links[#W.links] == "[quest]", "the chat's box open: Shift and a click links it, no watching")
    ChatFrameUtil.InsertLink = function() return false end
    rows[2]._scripts.OnClick(rows[2], "LeftButton")
    IsShiftKeyDown = function() return false end
    ChatFrameUtil.InsertLink, GetQuestLink, W.modifier = insert, nil, nil
    check(watched[7], "nothing takes the link: Shift and a click watches it")
end)()
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
        and not shown[4].remove._shown, "its quest in the log on top, with the red X; the log's own below")
    check(shown[2].icon._atlas == Pins.ICONS.offer and shown[2].icon._vertex[2] == Pins.RED[2]
        and shown[2].icon._alpha == 1 and shown[2].text._alpha == 1,
        "a ghost: its exclamation mark red, for later too, nothing see through")
    ;(function()
        local shade = rawget(_G, "GetQuestDifficultyColor")
        GetQuestDifficultyColor = function(level, _, quest)
            return quest == 101 and level == 30 and { r = 0.25, g = 0.75, b = 0.25 } or { r = 1, g = 1, b = 1 }
        end
        local Quests, get = Core.Data.Set("Quests"), Core.Data.Set("Quests").Get
        Quests.Get = function(self, id, field)
            if id == 101 and field == "groupSize" then return 5 end
            return get(self, id, field)
        end
        QuestLog.Refresh()
        local row = logBox:Draw()[2]
        check(row.text._color[1] == 0.25 and row.text._color[2] == 0.75, "its title in its level's colour, as any quest's")
        check(row.text._text == "[30+] A Quest for Later", "with a + for a group the data knows of")
        Quests.Get = get
        GetQuestDifficultyColor = shade
        QuestLog.Refresh()
    end)()
    check(shown[1].remove._shown and shown[1].row.ghosts, "the red X over them too")
    local said = {}
    for _, element in ipairs(shown) do
        if element.row.part and element.row.quest == 101 then said[#said + 1] = element.text._text or "" end
    end
    said = table.concat(said, "\n")
    check(shown[3].row.part and said:find(Pins.TEXT.needsLevel:format(60), 1, true)
        and said:find(QuestLog.TEXT.level:format(30), 1, true)
        and said:find(QuestLog.TEXT.givenBy:format("A Waiting Giver"), 1, true),
        "under it what the data knows: why not yet (the level it asks), its level, who gives it")
    ;(function()
        -- What the data knows it gives: big icons too, the tooltip the item's own. Items the game tells of in a burst, while
        -- the text waits for one: drawn again once, on the next frame.
        local Quests, refresh, drawn = Core.Data.Set("Quests"), QuestLog.Refresh, 0
        local get = Quests.Get
        Quests.Get = function(self, id, field)
            local record = get(self, id, field)
            if id == 101 and not field then
                record.rewardItems = { { item = 905, count = 2 } }
                record.objectives = { { kind = "kill", text = "Bears", count = 3 } }
            end
            return record
        end
        QuestLog.Refresh()
        local cell
        for _, element in ipairs(logBox:Draw()) do
            if element.row.kind == "reward" then cell = element.cells[1] end
        end
        check(cell and cell.thing.item == 905 and cell.name._text == "#905" and cell.count._text == 2,
            "a preview's rewards as big icons too, by what the data knows")
        local asks
        for _, element in ipairs(logBox:Draw()) do
            if element.row.kind == "text" and element.text._text:find("Bears", 1, true) then asks = element.text._text end
        end
        check(asks == "- 0/3 |T" .. QuestLog.SWORD .. ":16:16|t: Bears", "its objectives written as the log's")
        local tips, tip = {}, GameTooltip.SetItemByID
        GameTooltip.SetItemByID = function(_, item) tips[1] = item end
        cell._scripts.OnEnter(cell)
        GameTooltip.SetItemByID = tip
        check(tips[1] == 905, "with the item's own tooltip")
        QuestLog.Refresh = function(...) drawn = drawn + 1 return refresh(...) end
        for item = 1, 3 do W.Fire("ITEM_DATA_LOAD_RESULT", item, true) end
        local before = drawn
        W.Wait(0)
        QuestLog.Refresh = refresh
        Quests.Get = get
        check(before == 0 and drawn == 1, "a burst of items told by the game: the preview's words drawn again once")
    end)()
    shown[2].remove._scripts.OnClick(shown[2].remove)
    shown = logBox:Draw()
    check(shown[1].row.kind == "header" and shown[1].text._text ~= QuestLog.TEXT.previews and #shown == 6
        and not shown[1].remove._shown, "its red X: out of the log again")
    ;(function()
        local function Ghosts()
            local found = {}
            for _, element in ipairs(logBox:Draw()) do
                if element.row.kind == "preview" then found[#found + 1] = element end
            end
            return found
        end
        QuestLog.Preview({ 100, 101 }, 1429, 0.4, 0.4)
        local ghosts, menus = Ghosts(), #W.menus
        check(#ghosts == 2, "two ghosts")
        ghosts[1]._scripts.OnClick(ghosts[1], "RightButton")
        ghosts = Ghosts()
        check(#ghosts == 1 and ghosts[1].row.quest == 101 and #W.menus == menus, "the right button on a ghost: out at once, no menu")
        QuestLog.Preview({ 100 }, 1429, 0.4, 0.4)
        local header = logBox:Draw()[1]
        header.remove._scripts.OnClick(header.remove)
        check(#Ghosts() == 0 and logBox:Draw()[1].text._text ~= QuestLog.TEXT.previews, "the red X over them: all out at once")
        QuestLog.Preview({ 101 }, 1429, 0.4, 0.4)
        local index = C_QuestLog.GetLogIndexForQuestID
        C_QuestLog.GetLogIndexForQuestID = function(quest) if quest == 101 then return 9 end return index(quest) end
        QuestLog.Refresh()
        C_QuestLog.GetLogIndexForQuestID = index
        check(#Ghosts() == 0, "one taken from its giver meanwhile goes by itself")
    end)()
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = was.follow
    Canvas.Layout()
end
-- A double click on any pin puts the game's map pin where it stands, on the full map and the small one; a click is
-- the pin's own where it has one (Shift and a click on one that leads into another map opens that map, a quest
-- giver's on the full map shows its quests), else the map's: a ping there.
do
    local was = { map = full.map, u = full.u, v = full.v, k = full.k, follow = full.follow }
    full:Show(1415, 0, -9250, 0.4)
    Canvas.Layout()
    local saved = waypoint
    local function Click(button)
        button._scripts.OnMouseDown(button, "LeftButton")
        button._scripts.OnMouseUp(button, "LeftButton")
    end
    local function Double(button)
        Click(button)
        W.Wait(0.1)
        Click(button)
    end
    local mailbox = Drawn()["place:2"]
    local sent, pings = nil, 0
    local send = ns.Ping.Send
    ns.Ping.Send = function(map, u, v) sent, pings = { map, u, v }, pings + 1 return true end
    waypoint = nil
    W.Wait(1)
    Click(mailbox)
    check(not waypoint and sent and sent[1] == full.map, "a click on a pin with nothing of its own: the map's, a ping there")
    W.Wait(1)
    pings = 0
    Double(mailbox)
    W.Wait(0.6) -- the clock as the tests below were written for
    check(waypoint and waypoint.uiMapID == mailbox.pin.map and near(waypoint.position.x, mailbox.pin.x)
        and near(waypoint.position.y, mailbox.pin.y) and pings == 1,
        "a double click on a pin: the game's map pin where it stands; one ping, its first click's")
    ns.Ping.Send = send
    local opened
    local show = ns.Canvas.Show
    ns.Canvas.Show = function(map) opened = map return true end
    local entrance = Drawn()["place:1"]
    waypoint = nil
    W.Wait(1)
    IsShiftKeyDown = function() return true end
    Click(entrance)
    IsShiftKeyDown = function() return false end
    check(opened == 500 and not waypoint, "Shift and a click on an entrance: its map opens, no map pin")
    Double(entrance)
    check(waypoint and waypoint.uiMapID == 1429, "a double click on it: the map pin there, as on every pin")
    local previewed
    local preview = ns.QuestLog.Preview
    ns.QuestLog.Preview = function(quests) previewed = quests end
    local giver = Drawn()["npc:72"]
    Canvas.Use(ns.Window.small)
    waypoint = nil
    W.Wait(1)
    Click(giver)
    check(not waypoint and not previewed, "on the small map a click on a quest giver's pin: the quest log stays shut")
    Canvas.Use(full)
    W.Wait(1)
    Click(giver)
    check(previewed and previewed[1] == 100 and not waypoint, "on the full map: its quests in the quest log")
    W.Wait(0.1)
    Click(giver)
    check(waypoint and waypoint.uiMapID == giver.pin.map, "and a double click: the map pin at the giver too")
    W.Wait(1)
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

-- The quest areas on the minimap: none at first, though the full map has them (Saneroki, 2026-11-09); the pin
-- filter's Quest areas on the minimap brings them.
;(function()
    local was = focused
    focused = 7
    local function Area()
        for _, widget in ipairs(areaFrames) do if widget._shown then return widget end end
    end
    W.SmallAndBack(function()
        small:Show(1415, 500, -8950, 0.5)
        Canvas.Layout()
        check(Canvas.view.level == "zone" and not Area() and not ns.Pins.Shows("minimapArea"),
            "the small view at a zone, the arrow leading to a quest: no quest area drawn on it at first")
        ns.SwitchPin("minimapArea")
        local area = Area()
        if area then area._parent._scripts.OnUpdate(area._parent) end
        check(area and area._quest == 7, "Quest areas on the minimap ticked: its area on the minimap too")
        ns.SwitchPin("minimapArea")
        check(not Area(), "and gone again when it is not")
    end)
    check(Area(), "the full map again: the quest's area there")
    focused = was
    Canvas.Layout()
end)()

-- The box Follow me left of the pin filter: on at first. Ticked, the full map on the player and following; dragged
-- away, it follows again as the player walks on once the mouse has left it alone for Canvas.AGAIN (not while the player
-- stands, nor sooner); a map chosen in the bar's selector counts as the mouse; the full map opens on the player. Not
-- ticked: it stays where it is left.
;(function()
    local box, pinMenu
    for _, widget in ipairs(W.frames) do
        if widget._kind == "CheckButton" and widget.title == ns.TEXT.followMap then box = widget end
        if widget._override == ns.TopBar.TEXT.pins then pinMenu = widget end
    end
    check(box and box._checked and ns.options.followMap and box.Text._text == ns.TEXT.followMap
        and box._points[1][2] == box.Text and box.Text._points[1][1] == "RIGHT" and box.Text._points[1][2] == pinMenu,
        "the box Follow me, its words between it and the pin filter: on at first")
    check(ns.TEXT.followMapTip:find(Canvas.AGAIN .. " seconds", 1, true), "its tip says how long the full map waits")
    box._checked = false
    box._scripts.OnClick(box)
    check(not ns.options.followMap and not full.follow, "not ticked: the full map no longer follows")
    full:Look(full.u + 400, full.v)
    Canvas.Layout()
    box._checked = true
    box._scripts.OnClick(box)
    local _, u, v = Live.Player()
    check(ns.options.followMap and full.follow and near(full.u, u) and near(full.v, v) and box._checked,
        "ticked: the full map on the player, following")
    cursorX, cursorY = 800, 434
    frame._scripts.OnMouseDown(frame, "LeftButton")
    cursorX = 700
    frame._scripts.OnUpdate(frame, 0.016)
    frame._scripts.OnMouseUp(frame, "LeftButton")
    cursorX = 800
    check(not full.follow, "dragged away: no longer following")
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not full.follow, "the player standing: it stays where it was dragged")
    local wasX = player.x
    player.x = wasX + 0.002
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not full.follow, "the player walks on, the mouse on the map a moment ago: it stays, so it can be looked around")
    player.x = wasX + 0.004
    W.Wait(Canvas.AGAIN)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    _, u, v = Live.Player()
    check(full.follow and near(full.u, u) and near(full.v, v),
        "the player walks on once the mouse left it alone for Canvas.AGAIN: back on the player, following")
    -- A map chosen in the bar's selector: the same wait, not the first step away from it.
    local kept = { k = full.k, u = full.u, v = full.v }
    check(Canvas.Show(1429) and not full.follow, "a map chosen: shown, no longer following")
    player.x = wasX + 0.006
    W.Wait(Canvas.LOOK)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(not full.follow, "a map chosen, the player walking: it stays")
    full.u, full.v, full.k, full.follow = kept.u, kept.v, kept.k, true
    Canvas.Layout()
    tracker._scripts.OnUpdate(tracker, 0.016)
    _, u, v = Live.Player()
    -- Back small and full again after a drag: it opens on the player.
    frame._scripts.OnMouseDown(frame, "LeftButton")
    cursorX = 700
    frame._scripts.OnUpdate(frame, 0.016)
    frame._scripts.OnMouseUp(frame, "LeftButton")
    cursorX = 800
    W.SmallAndBack()
    check(full.follow and near(full.u, u) and near(full.v, v), "ticked, the full map opens on the player")
    box._checked = false
    box._scripts.OnClick(box)
    local stood = full.u
    player.x = wasX
    frame._mouseOver = true -- the full map fills the screen: the mouse is on it
    W.Wait(Canvas.AGAIN + 1)
    tracker._scripts.OnUpdate(tracker, 0.016)
    tracker._scripts.OnUpdate(tracker, 0.016)
    frame._mouseOver = false
    check(not ns.options.followMap and not full.follow and full.u == stood and not box._checked,
        "not ticked: the map stays where it is, the player walking or not")
    box._checked = true
    box._scripts.OnClick(box)
    tracker._scripts.OnUpdate(tracker, 0.016)
    check(ns.options.followMap and full.follow, "ticked again, as at first")
end)()

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
    local box
    for _, widget in ipairs(W.frames) do if widget.provider and widget.view and widget.Draw then box = widget end end
    local sort = log.bar.find
    sort._scripts.OnClick(sort)
    local rows = box:Draw()
    check(ns.QuestLog.Sort() == "type" and #rows == 7 and rows[1].row.kind == "header" and rows[1].text._text == "Normal"
        and not rows[1].mark._shown and rows[2].row.quest == 8 and rows[5].text._text == "Elite" and rows[6].row.quest == 7,
        "a click on the title: by type, under the game's tag of each (none: Normal, first), no fold marks")
    sort._scripts.OnClick(sort)
    check(ns.QuestLog.Sort() == "proximity", "and round again: by proximity")
    box._width = 300
    check(not log.buttons._shown and log.bar._height == ns.QuestLog.BAR and log.top == ns.QuestLog.BAR,
        "no pin and no close button on its title bar, which is low: the first row right under its words")
    check(ObjectiveTrackerFrame._parent ~= UIParent and not ObjectiveTrackerFrame._parent._shown,
        "the game's quest tracker out of sight, lent to a hidden frame")
    W.SmallAndBack(function()
        check(log.frame._shown and log.frame._strata == "LOW" and log.bar and not log.skin,
            "the map small: it stays on the screen, without a background or a border")
        local transparent = true
        for _, widget in ipairs(W.frames) do
            if widget._parent == log.frame and widget._kind == "Texture" and widget._shown then transparent = false end
        end
        check(transparent, "nothing drawn behind it but its list")
        check(not log.buttons._shown and not log.frame._mouse and not box._wheel,
            "no pin, no close button; clicked through, the mouse wheel the game's while its list fits")
        local point = log.frame._points[1]
        check(log.options.key == "questLogSmallPlace" and point[1] == "TOPLEFT" and point[3] == "TOPLEFT" and point[4] == 0
            and point[5] == 0, "at a place of its own: at first the screen's top left corner")
        rows = box:Draw()
        check(#rows == 4 and rows[1].row.quest == 8 and rows[2].row.turnIn and rows[3].row.quest == 7
            and not rows[4].row.done, "the objectives done left out, a done quest's turn in kept")
        check(rows[1]._hit and rows[1]._hit[2] > 0 and rows[2]._hit[2] > 0, "only its rows' words take the mouse")

        -- At rest out of sight (Core.Rest), on the screen alone; the rest of what that does: window.lua.
        local general, animations = Core.general, Core.general.animations
        general.animations = false
        Core.Set(ns.name, "questLogRest", false)
        check(log.frame._alpha == 1, "Hide the quest log at rest off: always in sight")
        Core.Set(ns.name, "questLogRest", true)
        check(log.frame._alpha == 0 and log.frame._shown, "on: out of sight at rest, shown still, so it can be seen again")
        W.Combat(true)
        check(log.frame._alpha == 1, "in a fight in sight")
        W.Combat(false)
        check(log.frame._alpha == 0, "after it out of sight")
        IsInGroup = function() return true end
        W.Fire("GROUP_ROSTER_UPDATE")
        check(log.frame._alpha == 1, "in a group in sight")
        Core.Set(ns.name, "questLogRestGroup", true)
        check(log.frame._alpha == 0, "In a group too: out of sight in a group as well")
        Core.Set(ns.name, "questLogRestGroup", false)
        check(log.frame._alpha == 1, "off again: in sight in a group")
        IsInGroup = function() return false end
        W.Fire("GROUP_ROSTER_UPDATE")
        check(log.frame._alpha == 0, "alone out of sight")
        rows[1]:GetScript("OnEnter")(rows[1])
        check(log.frame._alpha == 1, "the mouse on its words: in sight")
        rows[1]:GetScript("OnLeave")(rows[1])
        log.frame._mouseOver = true
        local rest = ns.QuestLog.Rest()
        local watch = rest.hover.watch.frame
        watch:GetScript("OnUpdate")(watch, 1)
        check(log.frame._alpha == 1, "and while it is on the window")
        log.frame._mouseOver = false
        watch:GetScript("OnUpdate")(watch, 1)
        check(log.frame._alpha == 0, "off it, out of sight")
        log.bar.find:GetScript("OnEnter")(log.bar.find)
        check(log.frame._alpha == 1, "the mouse on its title bar's words too")
        log.bar.find:GetScript("OnLeave")(log.bar.find)
        watch:GetScript("OnUpdate")(watch, 1)
        check(log.frame._alpha == 0, "and off them")
        general.animations = animations
        local inset
        for _, each in ipairs(box._points) do if each[1] == "TOPLEFT" then inset = each end end
        check(log.titleInset == ns.QuestLog.EDGE_SMALL and inset[4] == ns.QuestLog.EDGE_SMALL,
            "its list and its title close to the screen's edge")
        ns.store.questLogSort = "zone"
        ns.store.questLogFolds = { ["Elwynn Forest"] = true }
        ns.QuestLog.Refresh()
        rows = box:Draw()
        check(#rows == 5 and rows[2].row.kind == "quest" and not rows[1].row.collapsed,
            "by zone the quests under each zone, one folded over the full map too")
        ns.store.questLogFolds = nil
        rows[1]._scripts.OnClick(rows[1], "LeftButton")
        check(rows[1].row.kind == "header" and not rows[1].mark._shown and #box:Draw() == #rows,
            "its headers without their fold marks; a click folds none")
        ns.store.questLogSort = "proximity"
    end)
    check(log.frame._shown and log.frame._strata == "DIALOG" and not log.buttons._shown and log.frame._mouse and box._wheel
        and log.options.key == "questLogPlace", "and comes back with it, at its place over the full map")
    rows = box:Draw()
    check(#rows == 5 and rows[2].row.done and rows[1]._hit[2] == 0, "every objective again, its rows whole")
    check(not log.titleInset, "its title as every title's again")
    -- The full map's bar's button is its one switch, for both looks.
    local switch
    for _, widget in ipairs(W.frames) do if widget._text == ns.TopBar.TEXT.questLog then switch = widget end end
    switch._scripts.OnClick(switch)
    check(not log.frame._shown and ObjectiveTrackerFrame._parent ~= UIParent, "the bar's button: off, and the game's quest tracker stays gone")
    local away = ObjectiveTrackerFrame._parent
    ObjectiveTrackerFrame:SetParent(UIParent)
    check(ObjectiveTrackerFrame._parent == away, "the game's frame manager takes it back (an Edit Mode layout applied): out of sight again at once")
    W.SmallAndBack(function() check(not log.frame._shown, "and off on the screen alone too") end)
    Core.Set(ns.name, "nativeMap", true)
    check(ObjectiveTrackerFrame._parent == UIParent, "the game's map and quest log chosen, ours off: the game's quest tracker back")
    ObjectiveTrackerFrame:SetParent(GameTooltip)
    check(ObjectiveTrackerFrame._parent == GameTooltip, "and its manager may place it then: the hook leaves it alone")
    ObjectiveTrackerFrame:SetParent(UIParent)
    switch._scripts.OnClick(switch)
    check(log.frame._shown and ObjectiveTrackerFrame._parent ~= UIParent, "ours on: gone again while it shows")
    Core.Set(ns.name, "nativeMap", false)
    check(log.frame._shown and ObjectiveTrackerFrame._parent ~= UIParent, "the game's no longer chosen: gone for good")
    -- In Edit Mode the tracker is the game's, to be seen and placed; ours again as Edit Mode closes. (With the map
    -- small: Edit Mode sends a window that fills the screen back to its corner.)
    W.SmallAndBack(function()
        EventRegistry:TriggerEvent("EditMode.Enter")
        check(ObjectiveTrackerFrame._parent == UIParent, "Edit Mode: the game's quest tracker back, to be placed")
        EventRegistry:TriggerEvent("EditMode.Exit")
        check(ObjectiveTrackerFrame._parent ~= UIParent and not ObjectiveTrackerFrame._parent._shown,
            "Edit Mode closed: out of sight again")
    end)
    -- A click on the title bar beside its words folds the list away, and opens it again.
    do
        local line, panel, back = log.bar, box._parent, nil
        for _, widget in ipairs(W.frames) do
            if widget._parent == log.frame and widget._kind == "Texture" and widget._shown and widget._layer == nil then back = back or widget end
        end
        local function Click()
            line._mouseOver = true
            line._scripts.OnMouseDown(line, "LeftButton")
            line._scripts.OnMouseUp(line, "LeftButton")
            line._mouseOver = false
        end
        Click()
        check(ns.QuestLog.Folded() and ns.store.questLogFolded and not panel._shown and not log.frame._mouse and log.bar._shown,
            "beside the words: only its title bar stays, nothing else takes the mouse; kept")
        check(log.options.title == "|cffffffff2/25|r Proximity", "its title goes on telling")
        ns.QuestLog.Text(7)
        check(not ns.QuestLog.Folded() and panel._shown and log.frame._mouse, "a quest's text asked for: open again")
        ns.QuestLog.Text(nil)
        Click()
        Click()
        check(not ns.QuestLog.Folded() and not ns.store.questLogFolded and panel._shown and log.frame._mouse,
            "and again: back as it was")
    end
    box._width = nil
end)()

-- The quest timers (Saneroki, 2026-11-06): a strip at the top of the log, over the list, a line for each timed quest,
-- the soonest first, counted down, red in its last minute; in sight while the log rests out of sight, is folded or
-- switched off; gone where the game's tracker is back. Forever's read from C_QuestLog.GetQuestTimers, Retail's from
-- C_QuestLog.GetTimeAllowed.
;(function()
    local QuestLog, log, game = ns.QuestLog, ns.QuestLog.handle, W.retailRun and "retail" or "forever"
    local box, strip
    for _, widget in ipairs(W.frames) do
        if widget.provider and widget.view and widget.Draw then box = widget end
        if widget.lines and widget._parent == UIParent then strip = widget end
    end
    local function Top()
        for _, each in ipairs(box._points) do if each[1] == "TOPLEFT" then return each[5] end end
    end
    local function Running()
        local count = 0
        for _, ticker in ipairs(W.tickers) do if not ticker._cancelled then count = count + 1 end end
        return count
    end
    local function Changed()
        W.Fire("QUEST_LOG_UPDATE")
        W.Wait(0)
    end
    check(strip and not strip._shown and Top() == 0, "no timed quest: no timers, the list right under the title bar")
    W.Play("forever")
    local running, idle = { { questID = 7, questTimer = 125 }, { questID = 8, questTimer = 61 } }, Running()
    C_QuestLog.GetQuestTimers = function() return running end
    Changed()
    local lines = strip.lines
    check(strip._shown and strip._strata == "DIALOG" and lines[1]._shown and lines[2]._shown
        and lines[1]._text == "|cffffffff1:01|r  Kobold Camp Cleanup"
        and lines[2]._text == "|cffffffff2:05|r  Wolves Across the Border",
        "Forever: a line for each of the game's timers, the soonest first, its time left, then the quest")
    check(Top() == -(2 * QuestLog.TIMER + QuestLog.TIMERS_ROOM) and Running() == idle + 1,
        "the list under them; counted down")
    W.Wait(QuestLog.CLOCK)
    check(lines[1]._text == "|cffff33331:00|r  Kobold Camp Cleanup" and lines[2]._text == "|cffffffff2:04|r  Wolves Across the Border",
        "a second later one second less, the last minute in Failed's red")
    QuestLog.Fold(true)
    check(strip._shown, "the list folded away: the timers stay")
    QuestLog.Fold(false)
    W.SmallAndBack(function()
        local general, animations = Core.general, Core.general.animations
        general.animations = false
        Core.Set(ns.name, "questLogRest", false)
        Core.Set(ns.name, "questLogRest", true)
        check(log.frame._alpha == 0 and strip._shown and strip._alpha ~= 0 and strip._strata == "LOW",
            "the log at rest out of sight on the screen alone: its timers in sight")
        general.animations = animations
        EventRegistry:TriggerEvent("EditMode.Enter")
        check(not strip._shown, "Edit Mode: the game's quest tracker back, with its own timers; ours gone")
        EventRegistry:TriggerEvent("EditMode.Exit")
        check(strip._shown, "and back as it closes")
    end)
    local switch
    for _, widget in ipairs(W.frames) do if widget._text == ns.TopBar.TEXT.questLog then switch = widget end end
    switch._scripts.OnClick(switch)
    check(not log.frame._shown and strip._shown, "the log switched off: its timers stay")
    switch._scripts.OnClick(switch)
    check(log.frame._shown and strip._shown, "and on again")
    W.Play("retail")
    C_QuestLog.GetTimeAllowed = function(quest) if quest == 7 then return 300, 100 end end
    Changed()
    check(not C_QuestLog.GetQuestTimers and strip._shown and lines[1]._text == "|cffffffff3:20|r  Wolves Across the Border"
        and not lines[2]._shown and Top() == -(QuestLog.TIMER + QuestLog.TIMERS_ROOM),
        "Retail: from each quest's time allowed and how much of it went by; one line, the list under it")
    W.Play(game)
    wipe(running)
    C_QuestLog.GetQuestTimers, C_QuestLog.GetTimeAllowed = nil, nil
    Changed()
    check(not strip._shown and Top() == 0 and Running() == idle, "no timer left: the strip gone, the list up again, no counting")
end)()

-- The route's golden line: the parts in view, under the pins.
ns.Route.Show({ legs = { { kind = "walk", points = { { map = 1415, u = 500, v = -8950 }, { map = 1415, u = 0, v = -9250 } } },
                         { kind = "boat", points = { { map = 1415, u = 0, v = -9250 }, { map = 1415, u = 50000, v = 0 } } } } })
local lines = {}
for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown then lines[#lines + 1] = widget end end
check(#lines == 6 and lines[1]._start and near(lines[1]._end[1] - lines[1]._start[1], -500 * full.k),
    "the way drawn: each leg's segments as lines (an edge, the gold, its glint), the second leg reaching into view too")
check(lines[1]._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.route and Canvas.LEVELS.route < Hybrid.LEVEL
    and Canvas.LEVELS.route < Canvas.LEVELS.pins, "the line over the map, under the game's dots and the pins")
check(lines[3]._group and lines[3]._group.template == ns.Route.GLINT_PULSE and lines[3]._group.playing
    and not lines[1]._group, "the glint pulses by the template of Route.xml (the game makes that animation only from XML)")
ns.Route.Show(nil)
lines = 0
for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown then lines = lines + 1 end end
check(lines == 0, "no way: no line")
-- The mouse on a flight point's pin or a dock's (Paths.lua): its ways drawn over the map, over the golden line and
-- under the pins; off it, gone.
;(function()
    local function Shown()
        local found = {}
        for _, widget in ipairs(W.frames) do if widget._kind == "Line" and widget._shown then found[#found + 1] = widget end end
        return found
    end
    ns.Paths.Show({ kind = "flight", id = 2, map = 1429, name = "Goldshire" })
    local drawn = Shown()
    check(#drawn == 4 and drawn[1]._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.paths
        and Canvas.LEVELS.paths > Canvas.LEVELS.route and Canvas.LEVELS.paths < Canvas.LEVELS.pins
        and near(drawn[2]._start[2], (-9000 - full.v) * full.k) and near(drawn[2]._end[2], (-9100 - full.v) * full.k),
        "a flight point's pin under the mouse: its flights with a way drawn (an edge and the line each part), over the "
        .. "golden line, under the pins")
    ns.Paths.Hide()
    check(#Shown() == 0, "the mouse off it: gone")
    ns.Paths.Show({ kind = "flight", id = 3, map = 1429 })
    check(#Shown() == 0, "a flight point with no flight of the set: nothing drawn")
    ns.Paths.Show({ kind = "travel", way = 3, dock = 1, map = 1429 })
    drawn = Shown()
    check(#drawn >= 2, "a dock's pin under the mouse: its boat's way round drawn, leaps left out")
    ns.Paths.Show({ kind = "travel", gathered = { {} }, map = 1429 })
    check(#Shown() == 0, "a gathered marker: none")
end)()
-- The zone under the mouse named at the top of the full map (Label.lua): its name and levels, as the game's map
-- writes them, and the fishing skill its waters ask (Elwynn's -70: from 1, every cast from 25), with the red mark
-- of what the game has not confirmed; yellow while your skill (10 and a pole's 5) lets fish get away.
;(function()
    local at, levels, colours, skills = C_Map.GetMapInfoAtPosition, C_Map.GetMapLevels, rawget(_G, "QuestDifficultyColors"),
        rawget(_G, "C_SkillInfo")
    C_Map.GetMapInfoAtPosition = function(map, x, y)
        local info = at(map, x, y)
        if info and info.mapID == 1429 then info.name = "Elwynn Forest" end
        return info
    end
    C_Map.GetMapLevels = function(map) if map == 1429 then return 1, 10, 0, 0 end end
    QuestDifficultyColors = { difficult = { r = 1, g = 1, b = 0 }, impossible = { r = 1, g = 0.1, b = 0.1 },
                              standard = { r = 0.25, g = 0.75, b = 0.25 } }
    C_SkillInfo = { GetSkillLineInfoByID = function(line) if line == 356 then return { rank = 10, modifier = 5 } end end }
    local camera = Canvas.camera
    Canvas.camera = Window.full
    ns.Label.Show(1415, 0.5, 0.65)
    local name, under
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:find("^Elwynn Forest") then
            name = widget
        end
    end
    for _, widget in ipairs(name and name._parent._children or {}) do if widget ~= name then under = widget end end
    check(name and name._shown ~= false and name._parent._shown and name._text == "Elwynn Forest |cffFFFF00(1-10)|r",
        "the zone under the mouse named over the full map, its levels after it in the colour of how hard they are")
    check(under and under._text == "|cffFFFF00" .. ns.TEXT.fishing:format(1, 25) .. "|r",
        "under it the fishing skill its waters ask, yellow while fish get away, no red mark (not wanted there)")
    -- Forever tells no zone's levels: those of its enemies (Core's CreatureSpawns and NPCs, stood in for here): wolves
    -- at 2, boars at 5 and 6, murlocs at 9 and 10, ten points each, two guards at 55 (the high end cut); a rabbit (a
    -- critter), a pet seen at 7 to 30 and a rare left out.
    C_Map.GetMapLevels = function() end
    local Creatures, Facts = Core.Data.Set("CreatureSpawns"), Core.Data.Set("NPCs")
    local each, get = Creatures.Each, Facts.Get
    local function Points(n)
        local list = {}
        for i = 1, n do list[i] = { map = 1429, x = i, y = i } end
        return list
    end
    local spawns = { [901] = Points(10), [902] = Points(10), [903] = Points(10), [904] = Points(2), [905] = Points(20),
                     [906] = Points(30), [907] = Points(5) }
    local facts = { [901] = { levelMin = 2, levelMax = 2, kind = "beast" }, [902] = { levelMin = 5, levelMax = 6, kind = "beast" },
                    [903] = { levelMin = 9, levelMax = 10, kind = "humanoid" }, [904] = { levelMin = 55, kind = "humanoid" },
                    [905] = { levelMin = 1, kind = "critter" }, [906] = { levelMin = 7, levelMax = 30, kind = "beast" },
                    [907] = { levelMin = 10, kind = "beast", rank = "rare" } }
    local walks = 0
    Creatures.Each = function(_, fn, done)
        walks = walks + 1
        for id, points in pairs(spawns) do fn(id, { points = points }) end
        done(nil)
        return { Stop = function() end }
    end
    Facts.Get = function(_, id, field)
        local fact = facts[id]
        if field then return fact and fact[field] end
        return fact
    end
    ns.Label.Hide()
    ns.Label.Show(1415, 0.5, 0.65)
    check(name._text == "Elwynn Forest |cffFFFF00(2-10)|r" and walks == 1,
        "the game telling no levels: those of the zone's enemies, the bulk by spawn, no red mark")
    ns.Label.Hide()
    ns.Label.Show(1415, 0.5, 0.65)
    check(walks == 1, "worked out once, not at every look")
    Creatures.Each, Facts.Get = each, get
    ns.Label.Show(1415, 0.9, 0.1)
    check(not name._parent._shown, "over no zone: no label")
    ns.Label.Show(1415, 0.5, 0.65)
    Canvas.camera = Window.small
    ns.Label.Show(1415, 0.5, 0.65)
    check(not name._parent._shown, "the small map: no room for it")
    Canvas.camera = Window.full
    ns.Label.Show(1415, 0.5, 0.65)
    ns.Art.Unlight()
    check(not name._parent._shown, "the highlight out of sight: the label too")
    Canvas.camera = camera
    C_Map.GetMapInfoAtPosition, C_Map.GetMapLevels, QuestDifficultyColors, C_SkillInfo = at, levels, colours, skills
end)()
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
-- A corner of the way drawn as a curve: its pieces end to end from the part before to the part after, cutting the
-- corner Route.STRAY units deep and no deeper, each turning little from the one before; the art running on from piece
-- to piece, every glint started at the pulse's moment. A turn of under Route.BEND degrees stays a corner. The player
-- on the curve: the pieces behind them go, the head meets the line where they are.
;(function()
    local view, scale = Canvas.view, ns.PinScale("route")
    local function At(x, y) return { map = view.map, u = view.u + x / view.k, v = view.v + y / view.k } end
    local function Glints()
        local list = {}
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Line" and widget._shown and widget._group
                and widget._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.route then
                list[#list + 1] = widget
            end
        end
        return list
    end
    local function Gap(a, b) return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2) end
    -- How far a point lies from the way: east from (-60, 0) to (0, 0), then north to (0, 60).
    local function Off(p)
        local x, y = math.max(-60, math.min(0, p[1])), math.max(0, math.min(60, p[2]))
        return math.min(math.sqrt((p[1] - x) ^ 2 + p[2] ^ 2), math.sqrt(p[1] ^ 2 + (p[2] - y) ^ 2))
    end
    local way = { legs = { { kind = "walk", points = { At(-60, 0), At(0, 0), At(0, 60) } } } }
    ns.Route.Show(way)
    local glints = Glints()
    local joined, flowing, inStep, gentle, nearest, farthest = true, true, true, true, math.huge, 0
    for index, glint in ipairs(glints) do
        nearest = math.min(nearest, Gap(glint._start, { 0, 0 }))
        farthest = math.max(farthest, Off(glint._start), Off(glint._end))
        if glint._group.offset == nil or not near(glint._group.offset, GetTime() % ns.Route.PULSE) then inStep = false end
        local after = glints[index + 1]
        if after then
            if Gap(glint._end, after._start) > 1e-6 then joined = false end
            if not near(glint._coords[2], after._coords[1]) then flowing = false end
            local a = math.atan2(glint._end[2] - glint._start[2], glint._end[1] - glint._start[1])
            local b = math.atan2(after._end[2] - after._start[2], after._end[1] - after._start[1])
            if math.abs(math.deg(b - a)) > 1.5 * ns.Route.BEND then gentle = false end
        end
    end
    check(#glints > 4 and joined and Gap(glints[1]._start, { -60, 0 }) < 1e-6 and Gap(glints[#glints]._end, { 0, 60 }) < 1e-6
        and gentle, "a right angle of the way: a curve, its pieces end to end, each turning little from the one before")
    check(math.abs(nearest - ns.Route.STRAY * scale) < 0.01 and farthest <= ns.Route.STRAY * scale + 1e-6,
        "the curve cuts the corner Route.STRAY units deep, and strays no farther from the way")
    local xml = io.open("src/Navigation/Route.xml"):read("*a")
    check(flowing and inStep and tonumber(xml:match('duration="([%d.]+)"')) == ns.Route.PULSE,
        "its art runs on from piece to piece, every glint started at the pulse's moment (Route.xml's)")
    ns.Route.Show({ legs = { { kind = "walk", points = { At(-60, 0), At(0, 0),
        At(60 * math.cos(math.rad(ns.Route.BEND / 2)), 60 * math.sin(math.rad(ns.Route.BEND / 2))) } } } })
    check(#Glints() == 2, "a turn of under Route.BEND degrees: a corner still")
    -- The player south of the way, 54 units along it: on the curve's first half.
    way.cut = { leg = 1, index = 1, t = 0 }
    ns.Route.Show(way)
    local spot, cut = At(-6, 0), way.cut
    cut.t, cut.map, cut.u, cut.v, cut.pu, cut.pv = 0.9, view.map, spot.u, spot.v, spot.u, view.v - 10 / view.k
    ns.Route.Cut(way)
    glints = Glints()
    local headLine, drawn = glints[#glints], glints[1]
    check(#glints > 2 and Gap(headLine._end, drawn._start) < 1e-6 and Off(drawn._start) <= ns.Route.STRAY * scale
        and Gap(headLine._start, { -6, -10 }) < 1e-6 and near(headLine._coords[2], drawn._coords[1]),
        "the player on the curve: drawn from where they are on it, the head meeting it there, its art running on")
    ns.Route.Show(nil)
end)()
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
-- Under the game's minimap its own blip stands for the member, moved at each frame: ours stands down there, at once
-- (each step of the tracker, not at the next look at the party), and comes back past its square.
do
    local square, inside = Hybrid.Square, Canvas.Inside
    Canvas.Inside = function() return true end -- the member within the canvas
    Hybrid.Square = function() return blip.x + 3, blip.y - 3, 10 end
    ns.Marks.Group(Canvas.view, GetTime() + 10.1)
    check(not blip._shown and blip.x, "the member under the game's minimap: its own dot alone, not ours")
    Hybrid.Square = function() return blip.x + 30, blip.y, 10 end
    ns.Marks.Fit()
    check(blip._shown, "past its square: ours")
    Hybrid.Square = function() return nil end
    ns.Marks.Group(Canvas.view, GetTime() + 10.2)
    check(blip._shown, "the game's minimap out of sight: ours")
    Hybrid.Square, Canvas.Inside = square, inside
    ns.Marks.Fit()
end
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
    local lines = GameTooltip._lines
    check(lines and lines[1]:find("^Sails about every ") and lines[2] == Pins.TEXT.ports and lines[3] == "1. Elwynn Forest"
        and lines[4]:find("^2%. .+ %(this port%)$"), "its tooltip: how often it flies, its two ports, where it flies to first")
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
    -- Off the isle, over the Eastern Kingdoms' coast beside it in view: the pin on them, not off the isle's map.
    local coastU, coastV = Coords.FromWorldMap(2521, 0.63, 0.42)
    full:Look(Coords.FromWorldMap(2521, 0.6, 0.42)) -- dragged a little east, over the sea between them
    Canvas.Layout()
    check(full.map == 2521 and full.level == "zone", "dragged off the isle over the sea: still on the isle's plane")
    waypoint = nil
    ctrl = true
    local can = C_Map.CanSetUserWaypointOnMap
    C_Map.CanSetUserWaypointOnMap = function() return true end -- a continent's map takes one here
    cursorX, cursorY = 800 + (coastU - full.u) * full.k, 434 + (coastV - full.v) * full.k
    frame._scripts.OnMouseDown(frame, "LeftButton")
    frame._scripts.OnMouseUp(frame, "LeftButton")
    ctrl, C_Map.CanSetUserWaypointOnMap = false, can
    check(waypoint and waypoint.uiMapID == 1415 and near(waypoint.position.x, 0.01 / 0.32) and near(waypoint.position.y, 0.24 / 0.64),
        "Ctrl-click over the other continent beside it: the map pin on that one")
    waypoint = nil
    player.map, player.x, player.y = 1429, 0.75, 0.3
    full:Show(was.map, was.u, was.v, was.k)
    full.follow = false
    Canvas.Layout()
end

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
-- Pressed in the middle of a drag on the map: the window hidden over the canvas, its OnHide runs as the game runs it (a
-- parent's hide reaches its shown children), and the drag ends with it.
frame._scripts.OnMouseDown(frame, "LeftButton")
check(frame._scripts.OnUpdate ~= nil, "a drag begun on the map")
key._scripts.OnClick(key, "minimap", true)
check(not Window.frame._shown and frame._shown and frame._scripts.OnUpdate == nil,
    "the window hidden over it: the drag ends, the canvas' OnHide run for its parent's hide")
key._scripts.OnClick(key, "minimap", true)
check(Window.frame._shown, "and shown again")
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
check(not Hybrid.Taken() and minimap:GetParent() == container and minimap._wheel and minimap:IsMouseClickEnabled()
    and ground == true and ignoreRotation == false and configs > 0, "Show the game's minimap: its place, wheel, clicks, ground, rotation and mask back")
check(minimap._AreasAt(Hybrid.AREA), "and its own quest areas")
check(W.stray:GetParent() == minimap and W.stray._points[1][1] == "TOPLEFT" and W.stray._points[1][2] == minimap
    and W.stray._scale == 1 and W.stray._alpha == 1, "and the other addon's button back on it, where, as large and as seen as its addon had it")
check(W.fixed:GetParent() == minimap and W.fixed:GetFrameStrata() == "MEDIUM" and W.fixed._level == 8
    and W.fixed:IsFrameStrataFixed() and W.fixed:IsFrameLevelFixed(), "the button whose addon fixed its strata and level: both as they were, fixed again")
check(cluster._alpha == 1 and cluster._mouse and cluster.ZoneTextButton._mouse and backdrop._alpha == 1 and minimap.ZoomIn._mouse,
    "its cluster, border and buttons back")
;(function()
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == minimap and widget._kind == "Button" and widget ~= minimap.ZoomIn and widget ~= W.late
            and not W.others[widget] then sane = widget end
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
check(W.stray:GetParent() ~= minimap and ns.Satchel.button._shown, "the other addon's button held again, the satchel's button back")
-- The satchel's button with the circling arrows, as on the game's minimap: there and back (Saneroki, 2026-11-10).
;(function()
    local Satchel = ns.Satchel
    Satchel.button._scripts.OnClick(Satchel.button, "LeftButton")
    local swap = Satchel.swap
    check(Satchel.Shown() and swap and swap._shown and swap._parent == Satchel.frame and swap._points[1][1] == "RIGHT",
        "the satchel has the button that swaps the minimaps, beside its X")
    swap._scripts.OnClick(swap, "LeftButton")
    check(ns.options.nativeMinimap and not Satchel.Shown() and not Hybrid.Taken() and Window.frame._alpha == 0,
        "its click: the game's minimap, kept as the dropdown keeps it; ours rests and the satchel is gone")
    local sane
    for _, widget in ipairs(W.frames) do
        if widget._parent == minimap and widget._kind == "Button" and widget ~= minimap.ZoomIn and widget ~= W.late
            and not W.others[widget] then sane = widget end
    end
    check(sane and sane._shown, "on the game's minimap its button Sane UI window")
    sane._scripts.OnClick(sane, "LeftButton")
    check(not ns.options.nativeMinimap and Hybrid.Taken() and Window.frame._alpha == 1 and Satchel.button._shown,
        "and that one brings ours back, with the satchel's button")
end)()

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
-- A set file the game cannot unpack (its base64, deflate or CBOR raising): no ground there, and no error.
;(function()
    local decode = C_EncodingUtil.DecodeBase64
    C_EncodingUtil.DecodeBase64 = function() error("Usage: C_EncodingUtil.DecodeBase64(text)") end
    Walk.Forget()
    check(Walk.Tile(3104) == nil and Walk.Unpack("x") == nil, "a tile's block the game cannot unpack: no ground there, no error")
    C_EncodingUtil.DecodeBase64 = decode
    Walk.Forget()
end)()
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
-- The coarse layer (Gates.lua) on tiles 2592 to 2595: each gate the same on both its tiles, what the walks between a
-- part's gates cost (each yard up a little more, a yard swum at its price, of the way on foot and a rider's the
-- cheaper), the parts and edges of a walking tile; a tile's openings worked out only once needed.
;(function()
    local Gates = ns.Gates
    local light = Walk.Tile(2600)
    check(light and light.opens == nil and light.links ~= nil and light.surface[1] == 1, "a tile unpacked: its openings not yet")
    Walk.Links(light)
    check(type(light.opens) == "table" and #light.opens[1] == 0 and light.links == nil, "worked out once needed")
    local west, middle, alone = Gates.Tile(2592), Gates.Tile(2593), Gates.Tile(2600)
    check(west and middle and west.count == 1 and middle.count == 2 and middle.side[1] == 1 and middle.side[2] == 3
        and middle.first[2] == 0 and middle.last[2] == 255 and middle.part[2] == 1,
        "a tile's gates: the east side's first, then the west's, each its stretch and its part")
    check(west.id[1] == middle.id[2] and middle.byId[west.id[1]] == 2 and select(1, Gates.Ends(west.id[1])) == 2592
        and select(2, Gates.Ends(west.id[1])) == 2593 and select(3, Gates.Ends(west.id[1])) == 1,
        "a gate the same on both its tiles, and the tiles it lies between")
    check(near(middle.u[1], 2 * Coords.TILE) and near(middle.v[1], -8 * Coords.TILE - 128 * s),
        "a gate's point: the middle of its stretch, on the border")
    check(Gates.Cost(middle, 2, 1, 1.5) == 718 and Gates.Cost(middle, 1, 2, 1.5) == 718,
        "the walk between two gates of one part: as the coarse layer has it (through the door)")
    check(Gates.Cost(alone, 1, 2, 1) == 502 and Gates.Cost(alone, 2, 1, 1) == 500.5 and Gates.Cost(alone, 1, 2, 1.5) == 520,
        "each yard up a quarter more (8 one way, 2 the other), a yard swum at its price; a rider's dry way where cheaper")
    check(Gates.Tile(3104) == nil and Gates.Tile(9999) == nil, "a tile without the coarse layer, or without ground: none")
    local parts, walled = Gates.Parts(Walk.Tile(2593)), Walk.Tile(2593)
    local edgeWest, edgeEast = Gates.Edges(walled, 3), Gates.Edges(walled, 1)
    check(parts[1] == 1 and parts[2] == 1 and parts[3] == 1 and #edgeWest == 3 and edgeWest[1] == 1 and edgeWest[3] == 255
        and #edgeEast == 3 and edgeEast[1] == 2, "a walking tile's parts (its halves and door one) and its edges")
end)()
-- A walk across them: priced by the coarse layer (rectangle by rectangle only on the start's tile and the end's,
-- through the walled one by its gates), then drawn along that way through the door; a start priced again in one plan
-- goes out of its tile as the first time; a tile whose coarse layer was made from another block is crossed rectangle
-- by rectangle.
;(function()
    local Gates = ns.Gates
    local top = -8 * Coords.TILE
    local su, sv, eu, ev = 128 * s, top - 128 * s, 3 * Coords.TILE + 128 * s, top - 128 * s
    local cost, rest, found = Search.Price(1415, su, sv, eu, ev, nil, nil, 1.5)
    check(cost and math.abs(cost - 1784.33) < 0.5 and rest == 0 and found.way and #found.way.u == 3
        and found.way.tiles[2593] and found.way.tiles[2594],
        "priced by the coarse layer: into the gate, through the walled tile and across the next by their gates' costs")
    local points, drawn = Search.Walk(1415, su, sv, eu, ev, nil, nil, 1.5, found)
    local door = false
    for index = 1, #(points or {}), 2 do
        local column, row = (points[index] - Coords.TILE) / s, (top - points[index + 1]) / s
        if column >= 127.5 and column <= 144.5 and row <= 16.5 then door = true end
    end
    check(points and door and drawn >= 1674 and drawn <= 1790 and near(points[1], su) and near(points[#points], ev),
        "drawn along that way, rectangle by rectangle: through the door, from the start to the end")
    local memo = {}
    local first = Search.Price(1415, su, sv, eu, ev, nil, nil, 1.5, memo)
    local again = Search.Price(1415, su, sv, eu, ev, nil, nil, 1.5, memo)
    local kept
    for _, start in pairs(memo) do kept = start end
    check(first and again and math.abs(first - again) < 0.01 and kept and kept.uses == 2 and kept.exits,
        "priced again in one plan: from the ways out of its tile found then, at the same cost")
    walkGates[2592][3] = 2
    Gates.Forget()
    local stale = Search.Price(1415, su, sv, eu, ev, nil, nil, 1.5)
    check(stale and stale > 1674 and stale < 1800, "a coarse layer made from another block: that tile rectangle by rectangle")
    walkGates[2592][3] = 1
    Gates.Forget()
end)()
-- The journey: the pin far away (Elwynn's south west, 1750 yards), a flight point near the player and one near
-- the pin, both known: walk, fly, walk.
C_TaxiMap.GetTaxiNodesForMap = function(map)
    if map ~= 1415 then return {} end
    return { { nodeID = 2, name = "Near", position = CreateVector2D(0.575, 0.6445), faction = 2, atlasName = "TaxiNode_Alliance" },
             { nodeID = 5, name = "Far", position = CreateVector2D(0.39, 0.699), faction = 0, atlasName = "TaxiNode_Neutral" } }
end
Core.Character(ns.name).flightPoints = { [2] = true, [5] = true }
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
-- The way asked for (the guide's arrow, Core.Ways) to where the pin leads: the pin's way, no second search. What it
-- tells: the walk to the flight, then the flight at the flight point, then the last walk; a way of its own once the
-- pin is gone, never drawn; none once nothing is asked.
;(function()
    local Ways, walk, flight, last = Core.Ways, shownWay.legs[1], shownWay.legs[2], shownWay.legs[3]
    local start, pinned = { player.map, player.x, player.y }, waypoint
    check(Ways.Ahead() == nil, "nothing asked: no way")
    Ways.Aim(1429, 0.05, 0.99)
    check(#Core.Steps.Jobs() == 0, "asked to where the pin leads: no second search")
    local ahead = Ways.Ahead()
    check(ahead and ahead.ride == "flight" and ahead.to == "Far" and not ahead.here and ahead.yards > Planner.THERE,
        "on the walk: the flight next, where it brings one, the yards to it")
    -- A place of a plane, as the player stands.
    local function Stand(u, v)
        player.map, player.x, player.y = 1415, (u + 4000) / 8000, (4000 - v) / 20000
        W.Wait(1)
    end
    local at = walk.points[#walk.points]
    Stand(at.u + 2, at.v)
    ahead = Ways.Ahead()
    check(ahead and ahead.ride == "flight" and ahead.here, "at the flight point: the flight to take, here")
    -- No pin any more: the way is its own, and nothing of it is drawn.
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    check(shownWay == nil and #Core.Steps.Jobs() == 1, "the pin gone: its line goes, the way asked for is searched alone")
    Frames(8)
    ahead = Ways.Ahead()
    check(shownWay == nil and ahead and ahead.ride == "flight" and ahead.here, "found without a pin, and not drawn")
    Ways.Aim()
    check(Ways.Ahead() == nil and #Core.Steps.Jobs() == 0, "nothing asked any more: no way")
    -- The way there with the route off in the pin filter: it needs no line.
    local route = ns.Pins.Shows
    ns.Pins.Shows = function(kind) if kind == "route" then return false end return route(kind) end
    Ways.Aim(1429, 0.05, 0.99)
    Frames(8)
    ahead = Ways.Ahead()
    check(shownWay == nil and ahead and ahead.ride == "flight", "the route off in the filter: the way asked for all the same")
    ns.Pins.Shows = route
    -- Landed: on the last walk nothing but the walk is left, the yards along it to the place.
    local long = 0
    for index = 2, #last.points do
        local a, b = last.points[index - 1], last.points[index]
        long = long + math.sqrt((b.u - a.u) ^ 2 + (b.v - a.v) ^ 2)
    end
    Stand(last.points[1].u, last.points[1].v)
    ahead = Ways.Ahead()
    check(ahead and not ahead.ride and not ahead.here and math.abs(ahead.yards - long) < Planner.THERE,
        "on the last walk: no ride, the yards along it")
    Ways.Aim()
    -- Back where the player stood, the pin's way anew.
    player.map, player.x, player.y, waypoint = start[1], start[2], start[3], pinned
    W.Wait(1)
    Planner.Update()
    Frames(8)
end)()
-- A target no journey reaches (a plane of its own nothing leads to): searched once, not again every Planner.AGAIN
-- seconds while it stands; again for another target.
;(function()
    MAPS[777] = { kind = 2, parent = 947, continent = 77, top = 1000, bottom = -1000, left = 1000, right = -1000 }
    local Ways = Core.Ways
    Ways.Aim(777, 0.5, 0.5)
    check(#Core.Steps.Jobs() == 1, "a way asked for onto a plane nothing leads to: searched")
    Frames(8)
    check(#Core.Steps.Jobs() == 0 and Ways.Ahead() == nil, "none found")
    W.Wait(Planner.AGAIN + 1)
    Ways.Ahead()
    check(#Core.Steps.Jobs() == 0, "and not searched again while the target stands")
    Ways.Aim(777, 0.6, 0.6)
    check(#Core.Steps.Jobs() == 1, "another target there: searched again")
    Frames(8)
    Ways.Aim()
    MAPS[777] = nil
end)()
-- At a flight master (TAXIMAP_OPENED) what this character has found is what the game tells then: its flight map's
-- (Current and Reachable; Unreachable not, the game's flight map leaves those out) and every plane's, as the game's maps
-- mark them. Only the found are flown; on the map the found one as the game draws it.
;(function()
    local nodes, all, mapID = C_TaxiMap.GetTaxiNodesForMap, C_TaxiMap.GetAllTaxiNodes, rawget(_G, "GetTaxiMapID")
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        local list = nodes(map)
        for _, info in ipairs(list) do info.isUndiscovered = info.nodeID ~= 2 end
        return list
    end
    GetTaxiMapID = function() return 1415 end
    C_TaxiMap.GetAllTaxiNodes = function() return { { nodeID = 2, state = 0 }, { nodeID = 5, state = 2 } } end
    W.Fire("TAXIMAP_OPENED", 1)
    W.Wait(0)
    Frames(8)
    check(Planner.Knows(2) and not Planner.Knows(5),
        "at a flight master: the one it stands at found, one its flight map leaves out not")
    check(shownWay and #shownWay.legs == 1 and shownWay.legs[1].kind == "walk",
        "a flight point not found is not flown to: on foot, planned again at once")
    -- The continent's flight points on the map (Near found, Far not), the pins made anew as the game said.
    local pins = {}
    for _, pin in ipairs(Pins.For({ map = 1415, level = "continent", k = 0.01, left = -4000, right = 4000, top = 4000,
                                    bottom = -16000 }, false)) do pins[pin.key] = pin end
    check(pins["flight:2"] and not pins["flight:2"].tint and not pins["flight:2"].lines and pins["flight:5"]
        and pins["flight:5"].tint == Pins.RED, "on the map the flight point found as the game draws it, the other red")
    C_TaxiMap.GetTaxiNodesForMap, C_TaxiMap.GetAllTaxiNodes, GetTaxiMapID = nodes, all, mapID
end)()
-- Unknown flight points are not flown from: on foot all the way.
Core.Character(ns.name).flightPoints = {}
ns.Planner.Update()
Frames(8)
check(shownWay and #shownWay.legs == 1 and shownWay.legs[1].kind == "walk", "without the flight points known: on foot")
-- A pin across the walled tile (2593): the walk priced by the coarse layer, drawn along its way through the door.
;(function()
    local top = -8 * Coords.TILE
    local su, sv, eu, ev = 128 * s, top - 128 * s, 3 * Coords.TILE + 128 * s, top - 128 * s
    local before = { player.map, player.x, player.y, waypoint }
    player.map, player.x, player.y = 1415, (su + 4000) / 8000, (4000 - sv) / 20000
    waypoint = { uiMapID = 1415, position = CreateVector2D((eu + 4000) / 8000, (4000 - ev) / 20000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local leg = shownWay and #shownWay.legs == 1 and shownWay.legs[1]
    local door = false
    for _, point in ipairs(leg and leg.points or {}) do
        local column, row = (point.u - Coords.TILE) / s, (top - point.v) / s
        if column >= 127.5 and column <= 144.5 and row <= 16.5 then door = true end
    end
    check(leg and leg.kind == "walk" and door, "a pin across a walled tile: one walk, drawn through its door")
    -- The way asked for, with the pin somewhere else: through that door all the same, turned along the line, never
    -- straight at the place through the wall, and the line on the map stays the pin's. The yards are the line's.
    local lead, rest = leg.points[1], Planner.LEAD
    for index = 2, #leg.points do
        local a, b = leg.points[index - 1], leg.points[index]
        local length = math.sqrt((b.u - a.u) ^ 2 + (b.v - a.v) ^ 2)
        if length >= rest then
            lead = { u = a.u + (b.u - a.u) * rest / length, v = a.v + (b.v - a.v) * rest / length }
            break
        end
        rest = rest - length
    end
    local long = 0
    for index = 2, #leg.points do
        local a, b = leg.points[index - 1], leg.points[index]
        long = long + math.sqrt((b.u - a.u) ^ 2 + (b.v - a.v) ^ 2)
    end
    local straight = math.sqrt((eu - su) ^ 2 + (ev - sv) ^ 2)
    waypoint = { uiMapID = 1415, position = CreateVector2D((su + 200 + 4000) / 8000, (4000 - sv) / 20000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local pinWay = shownWay
    Core.Ways.Aim(1415, (eu + 4000) / 8000, (4000 - ev) / 20000)
    Frames(8)
    local ahead = Core.Ways.Ahead()
    local way = ahead and ahead.way
    local yards = ahead and ahead.yards
    check(shownWay == pinWay and ahead and not ahead.ride and math.abs(yards - long) < 1 and long > straight + 10,
        "the pin elsewhere: the way asked for is its own, as long as the walk through the door, and not drawn")
    check(way and math.abs(way - math.atan2(su - lead.u, lead.v - sv)) < 1e-3,
        "the arrow turned to the line a little ahead of the player")
    Core.Ways.Aim()
    player.map, player.x, player.y, waypoint = before[1], before[2], before[3], before[4]
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- A yard swum at its price, the character's own speeds: from the west hall to the east hall at row 170 the channel's
-- way is the shorter (256 yards, 67 of them swum), the door's the dry one (323 yards). On foot (the game's 7 yards a
-- second, 4.72 swimming) the walk swims; a rider (14) goes round by the door, and so does the character once it was
-- seen riding, mounted or not (not on a flight's mount).
;(function()
    local s = Walk.SAMPLE
    local au, av, bu, bv = 100 * s, -8533.33 - 170 * s, 200 * s, -8533.33 - 170 * s
    local function Swims(list) -- the rows of a walk's points: one in the channel (rows 200 to 209)
        for _, row in ipairs(list) do if row > 199 then return true end end
        return false
    end
    local function Rows(flat)
        local list = {}
        for index = 2, #(flat or {}), 2 do list[#list + 1] = (-8533.33 - flat[index]) / s end
        return list
    end
    local function Drawn()
        local leg, list = shownWay and #shownWay.legs == 1 and shownWay.legs[1], {}
        if not (leg and leg.kind == "walk") then return nil end
        for _, point in ipairs(leg.points) do list[#list + 1] = (-8533.33 - point.v) / s end
        return list
    end
    check(Swims(Rows(Search.Walk(1415, au, av, bu, bv, nil, nil, 7 / 4.72)))
        and not Swims(Rows(Search.Walk(1415, au, av, bu, bv, nil, nil, 14 / 4.72))),
        "a yard swum at its price: on foot (7 yards a second, 4.72 swimming) the channel's way, a rider's (14) by the door")
    local speed, mounted, taxi, char = GetUnitSpeed, rawget(_G, "IsMounted"), rawget(_G, "UnitOnTaxi"), Core.Character(ns.name)
    local ride, before = char.ride, { player.map, player.x, player.y, waypoint }
    char.ride = nil
    GetUnitSpeed, IsMounted = function() return 0, 7, 0, 4.72 end, function() return false end
    player.map, player.x, player.y = 1415, (au + 4000) / 8000, (4000 - av) / 20000
    waypoint = { uiMapID = 1415, position = CreateVector2D((bu + 4000) / 8000, (4000 - bv) / 20000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local onFoot = Drawn()
    GetUnitSpeed, IsMounted, UnitOnTaxi = function() return 0, 14, 0, 4.72 end, function() return true end,
        function() return true end
    Planner.Track(1415, au, av, GetTime() + 1)
    local flown = char.ride
    UnitOnTaxi = function() return false end
    Planner.Track(1415, au, av, GetTime() + 1.3)
    local kept = char.ride
    GetUnitSpeed, IsMounted = function() return 0, 7, 0, 4.72 end, function() return false end
    ns.Planner.Update()
    Frames(8)
    local rider = Drawn()
    check(onFoot and Swims(onFoot) and flown == nil and kept == 14 and rider and not Swims(rider),
        "the planner by the character's speeds: on foot it swims; seen riding (not on a flight), it rides round, unmounted too")
    GetUnitSpeed, IsMounted, UnitOnTaxi, char.ride = speed, mounted, taxi, ride
    player.map, player.x, player.y, waypoint = before[1], before[2], before[3], before[4]
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
end)()
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
-- Back in the town at the dock (100 yards south of the pier, by the way the boat leaves by): not aboard, a new pin is
-- planned from the player, on foot to the pier.
player.x, player.y = 0.725, 0.2 / 1.5
waypoint = { uiMapID = 1414, position = CreateVector2D(21500 / 24000, 0.3375) }
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
Frames(8)
check(shownWay and #shownWay.legs == 3 and shownWay.legs[1].kind == "walk" and shownWay.legs[2].kind == "boat"
    and near(shownWay.legs[1].points[1].u, 450) and near(shownWay.legs[1].points[1].v, -8700),
    "in the town at the dock, not on the boat: planned from the player, on foot to the pier")
-- The boat is the Alliance's (its towns'): a Horde character has no way across the sea, and no line.
UnitFactionGroup = function() return "Horde" end
Planner.Update()
Frames(8)
check(shownWay == nil, "the boat is the other side's: no way across the sea for a Horde character, no line")
UnitFactionGroup = function() return "Alliance" end
Planner.Update()
Frames(8)
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
    arrive, leave, here = Ships:Next(3, 1, leaves + 2 * round - 30)
    check(arrive and math.abs(arrive - (leaves + 2 * round - 60)) < 1 and here, "two rounds later: standing at its first dock")
    check(Ships:Next(3, 1, kept.seen + Ships.GUESS * round + 1) == nil,
        "its round only estimated, some seconds off each round: its times hold only for Ships.GUESS rounds after the ride")
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
    -- Its round known now: its times kept for good, worked out from the clock (after a /reload or a login too,
    -- Saneroki 2026-11-09), until a ride corrects them.
    local known = Ships:Table(3).round
    local far = Ships:Next(3, 1, kept.epoch + 1000 * known + 10)
    check(far and math.abs(far - (kept.epoch + 1001 * known - 60)) < 0.01,
        "its round known: a thousand rounds after the ride its times still there, from the clock")
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
    local timer, timed = DockWatch.Timer(3, 1)
    check(timer == rows[1].status and timed and DockWatch.Timer(3, 9) == nil and DockWatch.Timer(2, 1) == nil,
        "its dock pin's tooltip says the same (DockWatch.Timer); none for a dock it has not, nor a flight")
    local tram = DockWatch.Timer(7, 2)
    check(tram == DockWatch.TEXT.trams:format(Clock(120)) or (tram and tram:find("leaves in", 1, true)),
        "a station of the tram: its next train, or how often one comes")
    local width, height = UIParent._width, UIParent._height
    UIParent:SetSize(1600, 900)
    DockWatch.Update()
    local overlay = ns.TripView.frame
    local point = overlay and overlay._points[1]
    check(overlay and overlay:IsShown() and point and point[1] == "CENTER" and point[3] == "TOP"
        and near(point[5], -(SaneUI.Core.TOAST_TOP + ns.TripView.ABOVE)),
        "waiting at its dock: the overlay, high up the screen, level with a toast")
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
    check(TripView.frame and TripView.frame:IsShown() and lines.title == "Alpha to Gamma" and lines.next:find("^Next: Beta in 0:2[01]$")
        and lines.left:find("^1:0[01]$") and TripView.exit:IsShown(), "its overlay, with the game's Request Stop")
    check(Core.TopTaken(), "the overlay takes the toast's place: what only stands there makes way")
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
    -- The way out: the game's leave button out of sight and without clicks, never hidden by us; ours wherever it offers one.
    local leave, canLeave, left = CreateFrame("Button"), false, 0
    leave.CanExitVehicle = function() return canLeave end
    leave.Update = function() end
    leave.IsMouseEnabled = function(self) return self._mouse end
    leave:EnableMouse(true)
    MainMenuBarVehicleLeaveButton = leave
    VehicleExit = function() left = left + 1 end
    leave:Show()
    TripView.Update()
    check(leave:GetAlpha() == 0 and not leave:IsMouseEnabled() and leave:IsShown() and not TripView.frame:IsShown(),
        "the game's leave button out of sight while ours stands in for it, and still shown to the game")
    canLeave = true
    leave:Update()
    check(TripView.frame:IsShown() and TripView.exit:IsShown(), "in a vehicle: the way out, heard from the game's button")
    TripView.exit._scripts.OnClick(TripView.exit)
    check(left == 1 and TripView.exit:IsEnabled(), "its click leaves the vehicle")
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(leave:GetAlpha() == 1 and leave:IsMouseEnabled(), "in Edit Mode the game's button is back, to be placed")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(leave:GetAlpha() == 0, "and away again after it")
    Core.Set(ns.name, "tripView", false)
    check(leave:GetAlpha() == 1 and leave:IsMouseEnabled() and not TripView.frame:IsShown(),
        "the setting off: the game's button is back, ours gone")
    Core.Set(ns.name, "tripView", true)
    check(leave:GetAlpha() == 0 and TripView.exit:IsShown(), "the setting on: ours stands in again")
    canLeave = false
    leave:Update()
    check(not TripView.frame:IsShown() and not Core.TopTaken(), "out of the vehicle: nothing, the toast's place free")
    Planner.Track(1415, -1000, 1000, GetTime() + 200)
    check(shownWay == nil, "after the flight, without a map pin: no line")
    -- A whole flight: its pace learnt for this character.
    Fly()
    for _ = 1, 50 do W.Wait(1) end
    trip = Trips:Now()
    check(trip.next == 3 and not Trips:CanLand() and TripView.exit:IsShown(), "past its last stop the way out is there too, as the game's")
    TripView.exit._scripts.OnClick(TripView.exit)
    check(not Trips:Now().landing and not TripView.exit:IsEnabled(), "pressed there: no stop asked for, the flight goes on to its end")
    for _ = 1, 32 do W.Wait(1) end
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
        and TripView.Lines(trip).title == "Deeprun Tram: Stormwind City to Ironforge" and not TripView.exit:IsShown(),
        "on the tram: how far along, how long to the station, no way out")
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
-- Bound near the pin (Kalimdor, u 9400, v 6400): the line never takes the hearthstone (the player's to spend: Saneroki,
-- 2026-11-06), the boat; the chat tells once a pin that the hearthstone is quicker; nothing while it cools down, nor
-- once bound elsewhere (each a pin of its own, 20 yards on).
Core.Character(ns.name).hearth = { map = 1414, u = 9400, v = 6400, name = bindName }
local cooldown = 0
C_Item.GetItemCount = function(id) return id == Planner.HEARTHSTONE and 1 or 0 end
C_Item.GetItemCooldown = function() return cooldown > 0 and GetTime() or 0, cooldown, 1 end
;(function()
    local before = #W.printed
    local function Pin(u)
        waypoint = { uiMapID = 1414, position = CreateVector2D(u / 24000, 0.3375) }
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        Frames(8)
        local kinds = {}
        for index, leg in ipairs(shownWay and shownWay.legs or {}) do kinds[index] = leg.kind end
        return table.concat(kinds, " ")
    end
    local kinds = Pin(21500)
    local said = W.printed[#W.printed] or ""
    check(kinds:find("boat") and not kinds:find("hearth"), "a pin near the hearthstone's place: the line by the boat, never the hearthstone")
    check(#W.printed == before + 1 and said:find(Planner.TEXT.to:format(Planner.TEXT.stone, bindName), 1, true)
        and said:find(" min sooner.", 1, true), "the chat tells that the hearthstone is quicker, and how much")
    Planner.Update()
    Frames(8)
    check(#W.printed == before + 1, "told once a pin")
    cooldown = 1800
    kinds = Pin(21480)
    check(kinds:find("boat") and not kinds:find("hearth") and #W.printed == before + 1,
        "while the hearthstone cools down: the boat, nothing told")
    cooldown, bindName = 0, "Harbour Inn"
    kinds = Pin(21460)
    check(kinds:find("boat") and not kinds:find("hearth") and #W.printed == before + 1, "bound elsewhere since: the boat, nothing told")
end)()
-- Used: its place is where it brought the character (x 0.5, y 0.5 of Elwynn).
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", Planner.HOMEWARD)
player.x, player.y = 0.5, 0.5
W.Wait(3)
home = Core.Character(ns.name).hearth
check(home.map == 1415 and near(home.u, 0) and near(home.v, -9250) and home.name == "Harbour Inn",
    "the hearthstone's place: learnt where it brought the character")
player.x, player.y = 0.75, 0.3
-- The teleports this character has (Core's set Travel, kind teleport), each from the player to where it brings one, by
-- the pin on Kalimdor: a mage's only while it knows the spell and has its reagent, of its own side; a druid's; an
-- engineer's transporter while it is in the bags, usable and not cooling down; one the set knows no place of, once Core
-- learnt it where it brought the character. And the shaman's Astral Recall, to the hearthstone's place.
;(function()
    local known, held, usable, cooling = {}, {}, {}, {}
    local isKnown, count, itemCooldown = C_SpellBook.IsSpellKnown, C_Item.GetItemCount, C_Item.GetItemCooldown
    local hearth = Core.Character(ns.name).hearth
    C_SpellBook.IsSpellKnown = function(id) return known[id] == true end
    C_Item.GetItemCount = function(id) return held[id] or 0 end
    C_Item.IsUsableItem = function(id) return usable[id] ~= false end
    C_Item.GetItemCooldown = function(id) return cooling[id] and GetTime() or 0, cooling[id] or 0, 1 end
    local function Route()
        Planner.Update()
        Frames(8)
        local kinds = {}
        for index, leg in ipairs(shownWay and shownWay.legs or {}) do kinds[index] = leg.kind end
        local first = shownWay and shownWay.legs[1]
        return table.concat(kinds, " "), first and first.points[#first.points]
    end
    waypoint = { uiMapID = 1414, position = CreateVector2D(21500 / 24000, 0.3375) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    local kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport") and not kinds:find("hearth"),
        "nothing to teleport with, no hearthstone: the boat")
    -- A mage: its teleport only with the spell known and its reagent in the bags
    known[3561] = true
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport"), "a mage's teleport known, but no reagent in the bags: the boat")
    held[17031] = 1
    local there
    kinds, there = Route()
    check(kinds == "teleport walk" and there.map == 1414 and near(there.u, 9400) and near(there.v, 6400),
        "with its reagent: the teleport to where it brings one, then on foot to the pin")
    check(shownWay.legs[1].points[1].map == 1415, "the teleport's line from where the player is")
    -- Its line from one plane onto another: where it begins, the player is on it; brought there by it, on it there.
    local planned = shownWay
    Planner.Track(1415, 500, -8950, GetTime() + 250)
    Frames(8)
    local cut = shownWay and shownWay.cut
    check(shownWay == planned and cut.leg == 1 and cut.gap < 1, "where the teleport's line begins: on it, no new plan")
    Planner.Track(1414, 9400, 6400, GetTime() + 260)
    Frames(8)
    check(shownWay == planned and cut.gap < 1 and (cut.leg == 2 or cut.t == 1),
        "brought there by it, on the other plane: on the line there, no new plan")
    known[3561] = nil
    known[3567] = true
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport"), "the other side's teleport (known all the same): not taken")
    known[3567] = nil
    -- A druid's: no reagent
    known[18960] = true
    kinds, there = Route()
    check(kinds == "teleport walk" and near(there.u, 9400) and near(there.v, 6500), "a druid's teleport: taken, no reagent asked")
    known[18960] = nil
    -- An engineer's transporter: held, usable, its cooldown counted
    held[260820] = 1
    kinds, there = Route()
    check(kinds == "teleport walk" and near(there.u, 9500) and near(there.v, 6400), "an engineer's transporter in the bags: taken")
    cooling[260820] = 4 * 3600
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport"), "while it cools down (hours): the boat")
    cooling[260820], usable[260820] = nil, false
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport"), "one the game says the character cannot use (its level, its skill): the boat")
    held[260820], usable[260820] = nil, nil
    -- Teleport: Dalaran, whose place the set has not: no way until Core learnt it, where it brought the character
    known[1297659] = true
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("teleport"), "a teleport the set knows no place of: none")
    W.place = { -9000, 860, 0, 0 }
    W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 1297659)
    W.Wait(0.3)
    W.place = { 6400, -9300, 0, 1 }
    W.Wait(0.3)
    W.place = nil
    Frames(8)
    kinds, there = Route()
    check(kinds == "teleport walk" and there.map == 1414 and near(there.u, 9300) and near(there.v, 6400),
        "learnt where it brought the character (Core's learned data): the teleport there, then on foot")
    known[1297659] = nil
    -- A shaman's Astral Recall: to the hearthstone's place, without the hearthstone: never the line's, the chat tells
    -- that it is quicker; nothing while it cools down (each a pin of its own)
    Core.Character(ns.name).hearth = { map = 1414, u = 9400, v = 6400, name = bindName }
    known[Planner.RECALL] = true
    local before = #W.printed
    waypoint = { uiMapID = 1414, position = CreateVector2D(21440 / 24000, 0.3375) }
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("hearth") and #W.printed == before + 1
        and (W.printed[#W.printed] or ""):find(Planner.TEXT.to:format(Planner.TEXT.recall, bindName), 1, true),
        "Astral Recall known, no hearthstone: the boat; the chat tells that Astral Recall is quicker")
    local spellCooldown = C_Spell.GetSpellCooldown
    C_Spell.GetSpellCooldown = function(id)
        if id == Planner.RECALL then return { startTime = GetTime(), duration = 900, isEnabled = true } end
    end
    waypoint = { uiMapID = 1414, position = CreateVector2D(21420 / 24000, 0.3375) }
    kinds = Route()
    check(kinds:find("boat") and not kinds:find("hearth") and #W.printed == before + 1,
        "while Astral Recall cools down: the boat, nothing told")
    C_Spell.GetSpellCooldown, known[Planner.RECALL] = spellCooldown, nil
    C_SpellBook.IsSpellKnown, C_Item.GetItemCount, C_Item.GetItemCooldown, C_Item.IsUsableItem = isKnown, count, itemCooldown, nil
    Core.Character(ns.name).hearth = hearth
end)()
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
    local bu, bv = 3 * Coords.TILE + 32 * s, -32 * s -- under a city's building (tile 6179)
    check(select(2, Walk.Floor(1414, bu, bv, true, 40)) == 2 and select(2, Walk.Floor(1414, bu, bv, false, 40)) == 3,
        "indoors the lowest of a building's floors (its own, not the ground deep under the city), outdoors its roof")
    check(select(2, Walk.Nearest(1414, bu, bv, 10, 8, Walk.LAND)) == 2, "on foot: a building's floor too")
    check(select(2, Walk.Landing(1414, 3 * Coords.TILE + 47.5 * s, -32 * s, 59, 20)) == 4,
        "a lift's end lands beside its shaft at its height (the deck), not on the roof just over it")
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
-- A floor no way leaves (the mesa of tile 6176): a walk from it goes from the floor under it (Search.ASIDE more, not
-- counted); the player over it outdoors stands on it by the guess (the highest) and gets the same line; after a leap
-- (a portal) the floor is chosen anew, not followed from the one before.
;(function()
    local s = Walk.SAMPLE
    local function At(column, row) return column * s, -row * s end
    local function Over(points, step)
        for index = 1, points and #points or 0, step do
            if -points[index + 1] / s <= 8.5 then return true end
        end
        return false
    end
    local mu, mv = At(176, 48) -- on the mesa, over the field east of the hill
    local wu, wv = At(30, 64) -- the field west of the hill
    local points, cost = Search.Walk(1414, mu, mv, wu, wv, { 6176, 5, guess = true })
    check(points and #points > 4 and Over(points, 2) and near(points[1], mu) and near(points[#points - 1], wu)
        and cost < Search.ASIDE, "from a floor no way leaves (the mesa), a guess: from the field under it, over the "
        .. "hill's path, at its own cost")
    points = Search.Walk(1414, mu, mv, wu, wv, { 6176, 5 })
    check(points and not Over(points, 2), "the same floor known (the player is up there): from it, straight, not over the hill")
    local function Pin(u, v)
        waypoint = { uiMapID = 1414, position = CreateVector2D((u + 12000) / 24000, (20000 - v) / 40000) }
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        Frames(8)
        return shownWay and shownWay.legs[1]
    end
    local function Stand(u, v)
        player.map, player.x, player.y = 1414, (u + 12000) / 24000, (20000 - v) / 40000
    end
    Stand(mu, mv)
    local leg = Pin(wu, wv)
    local line = {}
    for index, point in ipairs(leg and leg.points or {}) do line[index * 2 - 1], line[index * 2] = point.u, point.v end
    check(leg and #shownWay.legs == 1 and leg.kind == "walk" and #leg.points > 2 and Over(line, 2),
        "the player outdoors over the mesa (its floor the guess): the line from the field under it, over the hill's path")
    -- On the west field (one floor), then 137 yards on in a moment, to the cave's place under the hill: the floor there
    -- chosen anew (outdoors the hill: east to the pin straight), not followed into the cave by its mouth.
    local cu, cv = At(96, 64)
    local eu, ev = At(200, 64)
    Stand(wu, wv)
    Pin(eu, ev)
    Planner.Track(1414, wu, wv, GetTime() + 600)
    Stand(cu, cv)
    Planner.Track(1414, cu, cv, GetTime() + 601)
    Planner.Update()
    Frames(8)
    leg = shownWay and shownWay.legs[1]
    check(leg and leg.kind == "walk" and #leg.points == 2 and near(leg.points[1].u, cu) and near(leg.points[2].u, eu),
        "after a leap: the floor chosen anew there (the hill), not followed into the cave")
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- A portal (Core's set Travel, 12): from the west field of tile 6176 to the city's building floor on tile 6179 (its own
-- region, no walk there): on foot to its trigger, through it, on foot to the pin; after the leap through it the floor
-- followed is where it brings one (the building's, not the roof over it the guess outdoors would take).
;(function()
    local s = Walk.SAMPLE
    local function At(tile, column, row) return tile * Coords.TILE + column * s, -row * s end
    local pu, pv = At(0, 20, 100) -- the player on the west field
    local tu, tv = 62.5, -208.33 -- the portal's trigger (its record's)
    local au, av = 1666.67, -66.67 -- where it brings one: the building's floor, under its roof
    local eu, ev = At(3, 56, 40) -- the pin on the building's floor, past its roof
    player.map, player.x, player.y = 1414, (pu + 12000) / 24000, (20000 - pv) / 40000
    waypoint = { uiMapID = 1414, position = CreateVector2D((eu + 12000) / 24000, (20000 - ev) / 40000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local legs, kinds = shownWay and shownWay.legs or {}, {}
    for index, leg in ipairs(legs) do kinds[index] = leg.kind end
    local portal = legs[2]
    check(table.concat(kinds, " ") == "walk portal walk" and near(portal.points[1].u, tu) and near(portal.points[1].v, tv)
        and near(portal.points[2].u, au) and near(portal.points[2].v, av),
        "a pin past a portal: on foot to its trigger, through it, on foot to the pin")
    Planner.Track(1414, tu, tv, GetTime() + 700)
    player.x, player.y = (au + 12000) / 24000, (20000 - av) / 40000
    Planner.Track(1414, au, av, GetTime() + 701)
    local floor = Planner.Floor()
    check(floor and floor[1] == 6179 and floor[2] == 2 and not floor.guess,
        "through the portal: the floor followed is the building's where it brings one, not its roof")
    -- A slow portal (a thousand seconds): the walk straight to the pin looks quicker, but no walk is found from the
    -- field's region to the building's (none of its floors within Search.FAR yards of the pin): it is none, and the
    -- journey chosen again takes the portal all the same.
    local portalTime = Planner.PORTAL
    Planner.PORTAL = 1000
    player.map, player.x, player.y = 1414, (pu + 12000) / 24000, (20000 - pv) / 40000
    Planner.Update()
    Frames(8)
    legs, kinds = shownWay and shownWay.legs or {}, {}
    for index, leg in ipairs(legs) do kinds[index] = leg.kind end
    check(table.concat(kinds, " ") == "walk portal walk",
        "a walk between regions not found: none, the journey chosen again goes through the portal")
    Planner.PORTAL = portalTime
    -- The portal is the Alliance's (its ends' guards): a Horde character goes without it.
    UnitFactionGroup = function() return "Horde" end
    Planner.Update()
    Frames(8)
    local through = false
    for _, leg in ipairs(shownWay and shownWay.legs or {}) do through = through or leg.kind == "portal" end
    check(shownWay and not through, "the portal the other side's: a Horde character's line goes without it")
    UnitFactionGroup = function() return "Alliance" end
    -- The portal is one class's (the warriors' here, as the mages' are theirs): a druid goes without it.
    local unitClass = UnitClass
    UnitClass = function() return "Druid", "DRUID", 11 end
    Planner.Update()
    Frames(8)
    through = false
    for _, leg in ipairs(shownWay and shownWay.legs or {}) do through = through or leg.kind == "portal" end
    check(shownWay and not through, "a portal of another class (the mages'): a druid's line goes without it")
    UnitClass = unitClass
    Planner.Update()
    Frames(8)
    through = false
    for _, leg in ipairs(shownWay and shownWay.legs or {}) do through = through or leg.kind == "portal" end
    check(through, "the portal of the character's own class: taken again")
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- Dead (Corpse.lua): the pin one had kept, the pin put where one fell and followed by the game's arrow; released, a
-- ghost: onto the corpse where the game tells it, and the route there neither flies nor casts; alive again: the pin
-- one had back as it was. A pin set while dead stays one's own; none before, none after.
;(function()
    local dead, ghost, deathInfo = UnitIsDeadOrGhost, UnitIsGhost, rawget(_G, "C_DeathInfo")
    local corpse
    C_DeathInfo = { GetCorpseMapPosition = function(map) return map == 1429 and corpse or nil end }
    player.map, player.x, player.y = 1429, 0.5, 0.5
    ns.Live.SetWaypoint(1429, 0.2, 0.3)
    UnitIsDeadOrGhost = function() return true end
    W.Fire("PLAYER_DEAD")
    local map, x, y = ns.Live.Waypoint()
    check(map == 1429 and near(x, 0.5) and near(y, 0.5) and tracked and Core.Character(ns.name).corpse.pin.x == 0.2,
        "dead: the pin one had kept, the pin where one fell, followed by the game's arrow")
    UnitIsGhost = function() return true end
    player.x, player.y = 0.9, 0.9
    W.Fire("PLAYER_ALIVE")
    map, x, y = ns.Live.Waypoint()
    check(near(x, 0.5) and near(y, 0.5), "released, the game not yet telling the corpse: the pin stays where one fell")
    corpse = CreateVector2D(0.52, 0.48)
    W.Wait(ns.Corpse.AGAIN + 0.01)
    map, x, y = ns.Live.Waypoint()
    check(near(x, 0.52) and near(y, 0.48) and tracked and ns.Planner.Ghost(),
        "a moment later: the pin on the corpse as the game tells it; a ghost's route takes no flight nor teleport")
    UnitIsDeadOrGhost, UnitIsGhost = dead, ghost
    W.Fire("PLAYER_UNGHOST")
    map, x, y = ns.Live.Waypoint()
    check(map == 1429 and near(x, 0.2) and near(y, 0.3) and not tracked and Core.Character(ns.name).corpse == nil,
        "alive again: the pin one had back as it was (not followed), the saved corpse forgotten")
    UnitIsDeadOrGhost = function() return true end
    W.Fire("PLAYER_DEAD")
    ns.Live.SetWaypoint(1429, 0.7, 0.7)
    UnitIsDeadOrGhost = dead
    W.Fire("PLAYER_ALIVE") -- raised by another before the release
    map, x, y = ns.Live.Waypoint()
    check(near(x, 0.7) and near(y, 0.7) and Core.Character(ns.name).corpse == nil, "a pin set while dead stays one's own")
    ns.Live.ClearWaypoint()
    UnitIsDeadOrGhost = function() return true end
    W.Fire("PLAYER_DEAD")
    check(ns.Live.Waypoint() == 1429, "no pin before: dead, one at the corpse all the same")
    W.Fire("PLAYER_ENTERING_WORLD") -- a /reload while dead
    check(Core.Character(ns.name).corpse.pin == false, "a /reload while dead: what one had stays kept (none)")
    UnitIsDeadOrGhost = dead
    W.Fire("PLAYER_ALIVE")
    check(ns.Live.Waypoint() == nil, "and alive again: none")
    C_DeathInfo = deathInfo
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- At a flight master (Taxi.lua): the game's flight map opens tiny and clear, ours fills the screen at its map with the
-- flight points large, over all and never gathered; Near (here) glowing, Far's tooltip its cost, the mouse
-- on it its way there drawn, a click flies there; the master left: the game's back as it was, ours in its corner.
-- Shift held as it opens: the game's own. Ours closed while it is open: the game's closes too.
;(function()
    local nodes, all, mapID = C_TaxiMap.GetTaxiNodesForMap, C_TaxiMap.GetAllTaxiNodes, rawget(_G, "GetTaxiMapID")
    local routes, slotOf, take, cost = rawget(_G, "GetNumRoutes"), rawget(_G, "TaxiGetNodeSlot"), TakeTaxiNode,
        rawget(_G, "TaxiNodeCost")
    local wasFull = Window.handle.edge.full
    -- The game's coin words (Core.Coins): 1s50c.
    GOLD_AMOUNT_TEXTURE, SILVER_AMOUNT_TEXTURE, COPPER_AMOUNT_TEXTURE = "%dg", "%ds", "%dc"
    if wasFull then
        Window.Back()
        Window.frame._group:Run(1)
    end
    -- The continent's two flight points, Near (here) and Far, the master's map the continent's.
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        if map == 1429 then -- (a zone's own flight points, where the view is at a zone's level)
            return { { nodeID = 2, name = "Near", position = CreateVector2D(0.5, 0.5), faction = 0, atlasName = "TaxiNode_Neutral" },
                     { nodeID = 5, name = "Far", position = CreateVector2D(0.6, 0.3), faction = 0, atlasName = "TaxiNode_Neutral" },
                     { nodeID = 6, name = "Locked", position = CreateVector2D(0.45, 0.6), faction = 0, atlasName = "TaxiNode_Neutral" } }
        end
        if map ~= 1415 then return {} end
        return { { nodeID = 2, name = "Near", position = CreateVector2D(0.575, 0.6445), faction = 0, atlasName = "TaxiNode_Neutral" },
                 { nodeID = 5, name = "Far", position = CreateVector2D(0.39, 0.699), faction = 0, atlasName = "TaxiNode_Neutral" } }
    end
    C_TaxiMap.GetAllTaxiNodes = function(map)
        if map ~= 1463 then return {} end
        return { { nodeID = 2, slotIndex = 1, state = 0, position = CreateVector2D(0.575, 0.6445) },
                 { nodeID = 5, slotIndex = 2, state = 1, position = CreateVector2D(0.39, 0.699) },
                 { nodeID = 6, slotIndex = 3, state = 2, position = CreateVector2D(0.55, 0.7) } }
    end
    GetTaxiMapID = function() return 1463 end -- (Forever's flight map of the Eastern Kingdoms: a map of its own)
    TaxiNodeCost = function(slot) return slot == 2 and 150 or 0 end
    GetNumRoutes = function(slot) return slot == 2 and 1 or 0 end
    TaxiGetNodeSlot = function(slot, hop, source) return source and 1 or 2 end
    local taken
    TakeTaxiNode = function(slot) taken = slot end
    TaxiFrame:Show()
    Window.frame._group:Run(1)
    local scale = TaxiFrame._scale
    check(ns.Taxi.On() and scale == Core.Holder.TINY and TaxiFrame._alpha == 0 and TaxiFrame:IsShown()
        and Window.handle.edge.full and Canvas.camera == full,
        "a flight master: the game's flight map open but tiny and clear (its talk goes on), ours fills the screen")
    -- Our map as it always opens, never at the master's own map (Forever's are maps of their own); then Elwynn whole in
    -- the test's small canvas, its flight points in view.
    check(not full.shown and full.level == "world" and near(full.k, full.far),
        "the full map as always, zoomed out to the world whole (both continents), not the master's map")
    -- Zoomed in a little, over the other continent (Kalimdor, the view's plane): this continent's flight points still
    -- there while it is in view (each continent in view gives its own map's pins at that zoom).
    full:ZoomAt(1, 0, 0)
    full:ZoomAt(1, 0, 0)
    full:ZoomAt(1, 0, 0)
    Canvas.Layout()
    local middle = {}
    for _, pin in ipairs(ns.Pins.For(Canvas.view, false)) do if pin.taxi then middle[pin.taxi] = true end end
    check(full.level == "continent" and full.map == 1414 and middle[2] and middle[5],
        "the middle zoom over the other continent: this one's flight points still there")
    ns.Canvas.Fit(full, 1429, frame._width, frame._height)
    Canvas.Layout()
    local here, there, locked
    for _, widget in ipairs(W.frames) do
        local pin = widget._kind == "Button" and rawget(widget, "pin")
        if pin and pin.taxi == 2 then here = widget elseif pin and pin.taxi == 5 then there = widget
        elseif pin and pin.taxi == 6 then locked = widget end
    end
    check(here and there and near(there._width, ns.Taxi.SIZE * ns.PinScale("flight")) and here.pin.here
        and here.glow._shown and not there.pin.gathered and not there.pin.dim,
        "its flight points large (Taxi.SIZE), you are at the glowing one, the one to fly to clear")
    check(there._level == there._parent._level + 1 + ns.PinView.LEVELS, "over every other pin")
    check(locked and locked.pin.dim and locked.pin.tint == ns.Pins.RED and not there.pin.tint and not here.pin.tint
        and locked.pin.lines[1][1] == ns.TEXT.taxiFar,
        "one the master does not fly to (not found yet): red, as everywhere on the map, and says so")
    -- At each one's right its name and what the flight costs, sized by the zoom, on a layer under every pin.
    local label = there.label
    check(label and label._text == "Far  1s50c" and label._shown ~= false and here.label._text == "Near"
        and locked.label._text == "Locked" and label._parent._level < there._level and label._parent._level < here._level,
        "a flight point's name and price at its right (the one you stand at, the one not flown to: the name), under the pins")
    local near = label.size
    ns.Canvas.Fit(full, ns.Coords.WorldMap(), frame._width, frame._height)
    Canvas.Layout()
    local far = there.label.size
    ns.Canvas.Fit(full, 1429, frame._width, frame._height)
    Canvas.Layout()
    check(near == ns.PinView.LABEL.MAX and far == ns.PinView.LABEL.MIN and there.label.size == near,
        "the names' size follows the zoom: the smallest at the world, the largest close in")
    local lines = there.pin.lines
    check(lines and lines[1] == "1s50c" and lines[2][1] == ns.TEXT.taxiFly
        and here.pin.lines[1][1] == ns.TEXT.taxiHere, "the tooltip: what the flight costs, a click flies there; here: you are")
    there._scripts.OnEnter(there)
    local drawn = 0
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Line" and widget._shown and widget._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.paths then
            drawn = drawn + 1
        end
    end
    check(drawn == 2, "the mouse on it: its way there drawn, hop by hop (no path in the set: straight)")
    there._scripts.OnLeave(there)
    check(ns.PinView.Act(there.pin) and taken == 2, "a click flies there (TakeTaxiNode, its slot)")
    check(ns.PinView.Act(here.pin) and taken == 2, "a click where you stand: nothing, no ping either")
    TaxiFrame:Hide() -- the flight taken: the game closes its map
    Window.frame._group:Run(1)
    check(not ns.Taxi.On() and TaxiFrame._scale == 1 and TaxiFrame._alpha == 1 and not Window.handle.edge.full,
        "the master left: the game's flight map back as it was, ours in its corner again")
    IsShiftKeyDown = function() return true end
    TaxiFrame:Show()
    check(not ns.Taxi.On() and TaxiFrame._scale ~= Core.Holder.TINY and not Window.handle.edge.full,
        "Shift held as it opens: the game's own flight map")
    IsShiftKeyDown = function() return false end
    TaxiFrame:Hide()
    -- The switch Show the game's map is the world map's: the flight master's is ours all the same.
    Core.Set(ns.name, "nativeMap", true)
    TaxiFrame:Show()
    Window.frame._group:Run(1)
    check(ns.Taxi.On() and TaxiFrame._scale == Core.Holder.TINY and Window.handle.edge.full,
        "Show the game's map on: a flight master's map is ours all the same")
    TaxiFrame:Hide()
    Window.frame._group:Run(1)
    Core.Set(ns.name, "nativeMap", false)
    TaxiFrame:Show()
    Window.frame._group:Run(1)
    Window.Back()
    Window.frame._group:Run(1)
    check(not TaxiFrame:IsShown() and not ns.Taxi.On() and TaxiFrame._scale == 1 and not Window.handle.edge.full,
        "ours closed while the master is open: the game's closes too")
    C_TaxiMap.GetTaxiNodesForMap, C_TaxiMap.GetAllTaxiNodes, GetTaxiMapID = nodes, all, mapID
    GetNumRoutes, TaxiGetNodeSlot, TakeTaxiNode, TaxiNodeCost = routes, slotOf, take, cost
    GOLD_AMOUNT_TEXTURE, SILVER_AMOUNT_TEXTURE, COPPER_AMOUNT_TEXTURE = nil, nil, nil
    ns.Pins.Changed("flights")
    if wasFull then
        Window.Toggle()
        Window.frame._group:Run(1)
    end
end)()
-- Flight points and ways of travel (Pins.WORLD) at every zoom: never gathered, at the world too (each continent's), each
-- to be hovered; on the full map a click keeps a flight point's ways drawn (its pin glowing) after the mouse left it,
-- again lets go, a double click only pins; the full screen closed, none kept (Saneroki, 2026-11-11).
;(function()
    local Pins, Paths = ns.Pins, ns.Paths
    local wasFull = Window.handle.edge.full
    if not wasFull then
        Window.Toggle()
        Window.frame._group:Run(1)
    end
    local together = Pins.Spread({ { kind = "flight", key = "a", pu = 0, pv = 0, order = 6 },
                                   { kind = "travel", key = "b", pu = 0, pv = 0, order = 5 },
                                   { kind = "flight", key = "c", pu = 0, pv = 0, order = 6 } }, 1)
    check(#together == 3 and not together[1].gathered and not together[2].gathered and together[1].sx == 0
        and together[2].sx ^ 2 + together[2].sy ^ 2 > 0 and together[3].sx ^ 2 + together[3].sy ^ 2 > 0,
        "flight points and ways of travel on one spot: each its own pin, side by side round the first")
    -- Near pins of one icon one marker in it (two trainers), parted as you zoom in; another icon beside them (a
    -- vendor); flight points never combined (each to be hovered for its ways).
    local function Near(k)
        return Pins.Spread({ { kind = "service", key = "t1", atlas = "trainer", pu = 0, pv = 0, order = 2 },
                             { kind = "service", key = "t2", atlas = "trainer", pu = 0.1, pv = 0, order = 2 },
                             { kind = "service", key = "v1", atlas = "vendor", pu = 0.05, pv = 0, order = 2 },
                             { kind = "flight", key = "f1", atlas = "TaxiNode_Neutral", pu = 0, pv = 0.05, order = 6 },
                             { kind = "flight", key = "f2", atlas = "TaxiNode_Neutral", pu = 0, pv = 0.06, order = 6 } }, k)
    end
    local far, close = Near(1), Near(1000)
    local marker
    for _, each in ipairs(far) do if each.gathered then marker = each end end
    check(#far == 4 and marker and #marker.gathered == 2 and marker.gathered[1].atlas == "trainer"
        and marker.gathered[2].atlas == "trainer" and #close == 5,
        "two trainers close together: one marker in their icon (the vendor and each flight point their own), apart close in")
    for _ = 1, 3 do if full.level ~= "world" then full:StepOut() end end
    Canvas.Layout()
    local kinds, flights = {}, 0
    for _, pin in ipairs(Pins.For(Canvas.view, false)) do
        kinds[pin.kind] = true
        if pin.kind == "flight" then flights = flights + 1 end
    end
    local others = false
    for kind in pairs(kinds) do if not Pins.WORLD[kind] then others = true end end
    check(full.level == "world" and flights > 0 and kinds.travel and not others,
        "zoomed out to the world: the flight points and the ships' docks (from the zones' maps) still there, nothing else")
    -- Treasure, herbs and ore only up close (Pins.CLOSER yards high at most): Elwynn 3000 yards high, then 1000.
    Pins.CLOSER = CLOSER
    local function Herbs(span)
        full:Show(1415, 0, -9250, full.height / span)
        Canvas.Layout()
        local count = 0
        for _, each in ipairs(Pins.For(Canvas.view, false)) do
            local first = each.gathered and each.gathered[1] or each
            if first.kind == "herb" then count = count + 1 end
        end
        return count
    end
    check(Herbs(3000) == 0 and Herbs(1000) > 0, "herbs (treasure, ore) only up close: none 3000 yards high, there 1000 high")
    Pins.CLOSER = math.huge
    ns.Canvas.Fit(full, 1429, frame._width, frame._height) -- Elwynn whole again, in its own plane
    Canvas.Layout()
    local pin = { kind = "flight", id = 2, map = 1429, key = "flight:2", name = "Near" }
    local function Drawn()
        local count = 0
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Line" and widget._shown and widget._parent._level == frame:GetFrameLevel() + Canvas.LEVELS.paths then
                count = count + 1
            end
        end
        return count
    end
    check(Paths.Toggle(pin) and Paths.Active(pin) and Drawn() == 4, "a click on a flight point: its flights drawn")
    Paths.Show(pin)
    Paths.Hide()
    check(Paths.Active(pin) and Drawn() == 4, "the mouse off it: still drawn (active)")
    check(not Paths.Toggle({ kind = "service", key = "npc:69" }), "a pin with no ways: no click of these")
    Paths.Toggle(pin)
    check(not Paths.Active(pin) and Drawn() == 0, "clicked again: let go")
    -- Two clicks on it, as a double click: kept drawn by the first, let go by the second, the map pin there.
    Canvas.Press("LeftButton")
    Canvas.Release("LeftButton", pin)
    check(Paths.Active(pin), "one click (the full map): kept drawn")
    Canvas.Press("LeftButton")
    Canvas.Release("LeftButton", pin)
    check(not Paths.Active(pin), "a double click: not kept, it only pins")
    Paths.Toggle(pin)
    Window.Back()
    Window.frame._group:Run(1)
    check(not Paths.Active(pin) and Drawn() == 0, "the full screen closed: none kept")
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    if wasFull then
        Window.Toggle()
        Window.frame._group:Run(1)
    end
end)()
-- A portal a few yards across between floors one over the other (14: from the building's floor of tile 6179 up onto
-- its roof, 35 yards on, as the Wizard's Sanctum's go up and down its tower): a hop between two looks, no leap of
-- Planner.LEAP yards; the floor followed after it is the roof's, where it brings one, not the floor under it.
;(function()
    local s = Walk.SAMPLE
    local function At(column, row) return 3 * Coords.TILE + column * s, -row * s end
    local fu, fv = At(8, 8)     -- its trigger, on the building's floor
    local ru, rv = At(20, 20)   -- where it brings one: the roof
    local eu, ev = At(200, 200) -- a pin on the ground east of the building
    player.map, player.x, player.y = 1414, (fu + 12000) / 24000, (20000 - fv) / 40000
    waypoint = { uiMapID = 1414, position = CreateVector2D((eu + 12000) / 24000, (20000 - ev) / 40000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local now = GetTime() + 800
    Planner.Track(1414, fu, fv, now)
    local before = Planner.Floor()
    player.x, player.y = (ru + 12000) / 24000, (20000 - rv) / 40000
    Planner.Track(1414, ru, rv, now + 0.3)
    local floor = Planner.Floor()
    check(before and before[1] == 6179 and before[2] == 2 and floor and floor[1] == 6179 and floor[2] == 3,
        "through a portal a few yards across, up onto the roof: the floor followed is the roof's, not the floor under it")
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- A pin on ground of its own far from any floor one walks on (the mesa of tile 6177, 133 yards north of the courtyard;
-- its lift, 8, out of the way): the walk to it ends only as near as one walks, so it is none and the journey looks for
-- another way; none goes, and the line runs as near as one walks (the courtyard's edge), then straight to the pin, not
-- straight from where it starts. (Without the hearthstone, and as the game's walking data covers every continent: no
-- walk is off it, as the docks of these tests are, whose walks would stay as guessed.)
;(function()
    local s, Lifts = Walk.SAMPLE, ns.Lifts
    local function At(column, row) return Coords.TILE + column * s, -row * s end
    local cu, cv = At(136, 136) -- on the courtyard, over no hall
    local mu, mv = At(240, 64)  -- on the mesa, far from its edges
    local all, walk, price, hearth = Lifts.All, Search.Walk, Search.Price, Core.Character(ns.name).hearth
    Lifts.Forget()
    Lifts.All = function() return {} end
    Search.Walk = function(...)
        local points, cost, rest = walk(...)
        if not points and cost == "off" then return nil end
        return points, cost, rest
    end
    Search.Price = function(...)
        local cost, rest, found = price(...)
        if not cost and rest == "off" then return nil end
        return cost, rest, found
    end
    Core.Character(ns.name).hearth = nil
    player.map, player.x, player.y = 1414, (cu + 12000) / 24000, (20000 - cv) / 40000
    waypoint = { uiMapID = 1414, position = CreateVector2D((mu + 12000) / 24000, (20000 - mv) / 40000) }
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local leg = shownWay and shownWay.legs[1]
    local points = leg and leg.points or {}
    local edge = points[#points - 1]
    check(shownWay and #shownWay.legs == 1 and leg.kind == "walk" and #points >= 3 and edge
        and math.abs(-edge.v / s - 128) < 0.5 and near(points[#points].u, mu) and near(points[#points].v, mv),
        "a pin on a mesa no lift reaches, far from the courtyard: as near as one walks (its edge), then straight to it")
    Lifts.All, Search.Walk, Search.Price, Core.Character(ns.name).hearth = all, walk, price, hearth
    Lifts.Forget()
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- Journeys: a pin nobody can walk to still gets its line (as near as one walks, then straight); across three planes
-- (the isle, the Eastern Kingdoms, Kalimdor), by the zeppelin (never the hearthstone), then the boat; a flight over two
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
    -- From the isle to Kalimdor: the zeppelin to the Eastern Kingdoms, on foot to the boat, the boat, on foot; the
    -- hearthstone home to the Eastern Kingdoms first is quicker, but by less than Planner.SOONER: nothing told.
    player.map, player.x, player.y = 2521, 0.5, 0.4
    local before = #W.printed
    legs = Pin(1414, 0.875, 0.325)
    check(Kinds(legs) == "walk zeppelin walk boat walk" and legs[2].points[#legs[2].points].map == 1415
        and legs[4].points[#legs[4].points].map == 1414,
        "from the isle to Kalimdor: the zeppelin to a third plane, the Eastern Kingdoms, then the boat; never the hearthstone")
    check(#W.printed == before, "the hearthstone home a minute quicker: nothing told (not worth its cooldown)")
    -- Two flights one after the other (Alpha to Beta to Gamma, the set's flights 5 and 6): one leg, along both ways.
    local nodes = C_TaxiMap.GetTaxiNodesForMap
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        if map ~= 1415 then return {} end
        return { { nodeID = 20, name = "Alpha", position = CreateVector2D(0.5, 0.2), faction = 0 },
                 { nodeID = 21, name = "Beta", position = CreateVector2D(0.5, 0.15), faction = 0 },
                 { nodeID = 22, name = "Gamma", position = CreateVector2D(0.375, 0.15), faction = 0 } }
    end
    local known = Core.Character(ns.name).flightPoints
    Core.Character(ns.name).flightPoints = { [20] = true, [21] = true, [22] = true }
    player.map, player.x, player.y = 1415, 0.5, 0.205
    legs = Pin(1415, 0.375, 0.145)
    local flight = legs[2]
    check(Kinds(legs) == "walk flight walk" and #flight.points == 3 and near(flight.points[2].v, 1000) and near(flight.points[3].u, -1000),
        "two flights one after the other: one leg along both their ways, taking off and landing once")
    -- The Legacy perk Frequent Flier: flights 20 % faster. A pin east of Beta (u 1820, v 1000) as quick on foot as by
    -- the flight from Alpha with the walks to and from it: on foot without the perk, by the flight with it (its spell
    -- known, or its aura on the character).
    local isKnown = C_SpellBook.IsSpellKnown
    local function Perk(spell, aura)
        C_SpellBook.IsSpellKnown = function(id) return spell and id == Planner.FLIER end
        C_UnitAuras = aura and { GetPlayerAuraBySpellID = function(id) if id == Planner.FLIER then return { spellId = id } end end }
            or nil
        Planner.Update()
        Frames(8)
        return Kinds(shownWay and shownWay.legs or {}), Planner.Pace()
    end
    Pin(1415, 0.5 + 1820 / 8000, 0.15)
    local kinds, pace = Perk(false, false)
    check(kinds == "walk" and pace == 1, "without Frequent Flier: a pin as quick on foot as by the flight, on foot")
    kinds, pace = Perk(true, false)
    check(kinds == "walk flight walk" and pace == Planner.FASTER and Planner.FASTER == 1.2,
        "with it (its spell known): the flight 20 % faster, so the flight")
    kinds, pace = Perk(false, true)
    check(kinds == "walk flight walk" and pace == Planner.FASTER, "with its aura on the character: the same")
    C_SpellBook.IsSpellKnown, C_UnitAuras = isKnown, nil
    C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flightPoints = nodes, known
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
    -- A plan made before the walking data came (Travel there, Walking not): its lifts' ends have no landing and no
    -- floor. Ridden on such a lift, the line goes on without a floor from it, and nothing breaks.
    local nearest = Lifts.Near
    Stand(fu, fv)
    legs = Pin(1414, mu, mv)
    local bare = { {}, {}, time = 1 } -- the lift at hand, as Lifts.Near finds it: its ends without landings
    Lifts.Near = function(...) return nearest(...) and bare or nil end
    Wait(800, -133.33, 2)
    Go(legs[3].points, 1, math.min(4, #legs[3].points))
    Lifts.Near = nearest
    check(Kinds(legs) == "walk lift walk" and legs[2].rode,
        "ridden on a lift whose ends have no landing (a plan made before the walking data came): the line goes on, nothing breaks")
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
    check(pin and pin.icon._atlas == "poi-door-up" and GameTooltip._text == Core.UNCONFIRMED_MARK .. Pins.WAY_WORDS.lift
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
-- A lift within one region whose city reaches farther from it than Lifts.SPREAD yards (13, on the Eastern Kingdoms'
-- tile 2340, its ends on the city's map 1460: the Undercity, whose Royal Quarter lies so far from its lifts): the
-- whole city stands below its upper level, on the city's map. From the lift's foot to the hall's far end on foot (as
-- from where Teleport: Undercity lands to the Royal Quarter, not up the lift and round); from there to the ruins on
-- foot to the lift, up it, on foot to the pin.
;(function()
    local Lifts, s = ns.Lifts, Walk.SAMPLE
    local function At(column, row) return 4 * Coords.TILE + column * s, -4 * Coords.TILE - row * s end
    local function Spot(map, u, v)
        local info = MAPS[map]
        return (-u - info.left) / (info.right - info.left), (v - info.top) / (info.bottom - info.top)
    end
    local function Route(from, to)
        waypoint = nil
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        player.map, player.x, player.y = 1415, Spot(1415, from[1], from[2])
        waypoint = { uiMapID = 1460, position = CreateVector2D(Spot(1460, to[1], to[2])) }
        shownWay = nil
        W.Fire("USER_WAYPOINT_UPDATED")
        W.Wait(0)
        Frames(8)
        local legs, kinds = shownWay and shownWay.legs or {}, {}
        for index, leg in ipairs(legs) do kinds[index] = leg.kind end
        local last = legs[#legs] and legs[#legs].points[#legs[#legs].points]
        local ends = last and math.abs(last.u - to[1]) < 0.5 and math.abs(last.v - to[2]) < 0.5
        return legs, table.concat(kinds, " "), ends
    end
    local lift, level
    for _, each in ipairs(Lifts.All()) do
        if each.key == 13 then lift = each end
    end
    for _, each in ipairs(Lifts.Levels(1415)) do
        if lift and each.alone == lift then level = each end
    end
    local foot, far, ruins = { At(48, 128) }, { At(230, 128) }, { At(40, 40) }
    check(lift and Lifts.Landed(lift[1]) and Lifts.Landed(lift[2]) and lift[1].region == 11 and lift[2].region == 11
        and level and level.stacked and level.maps[1460]
        and (far[1] - lift.u) ^ 2 + (far[2] - lift.v) ^ 2 > Lifts.SPREAD ^ 2,
        "a lift within one region on its city's map, the city's hall reaching farther from it than Lifts.SPREAD yards")
    local indoors = IsIndoors
    IsIndoors = function() return true end
    local _, kinds, ends = Route(foot, far)
    check(kinds == "walk" and ends, "from the lift's foot to the hall's far end: on foot, all the way in the city")
    local legs
    legs, kinds, ends = Route(far, ruins)
    check(kinds == "walk lift walk" and legs[2].near == lift[1] and legs[2].far == lift[2] and ends,
        "from the hall's far end to the ruins over the city: on foot to the lift, up it, on foot to the pin")
    IsIndoors = indoors
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- No walk follows another at a flight point: one this character knows on the mesa of tile 6177, 6 yards from its edge
-- over the field and 14 from lift 8, its regions the field's and the mesa's (within Planner.REGION yards). From the
-- field to a pin on the mesa the line walked to it, took off and came straight down again (Planner.BOARD seconds,
-- quicker than the lift's wait and ride) and walked on from the mesa's floor there; one comes down at a flight point
-- only after a flight now, and the lift is the way.
;(function()
    local s = Walk.SAMPLE
    local function Spot(column, row) return (Coords.TILE + column * s + 12000) / 24000, (20000 + row * s) / 40000 end
    local nodes, known = C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flightPoints
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        if map ~= 1414 then return nodes(map) end
        return { { nodeID = 30, name = "Cliff", position = CreateVector2D(Spot(131, 70)), faction = 0 } }
    end
    Core.Character(ns.name).flightPoints = { [30] = true }
    player.map, player.x, player.y = 1414, Spot(40, 64)
    waypoint = { uiMapID = 1414, position = CreateVector2D(Spot(200, 60)) }
    shownWay = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local kinds = {}
    for index, leg in ipairs(shownWay and shownWay.legs or {}) do kinds[index] = leg.kind end
    check(table.concat(kinds, " ") == "walk lift walk",
        "a flight point between two levels a lift joins: never up and straight down at it to walk on; the lift")
    C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flightPoints = nodes, known
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- No ride brings one back to where the rides since the last walk began: from the field of tile 6177 to a pin on it
-- whose walk straight there is a long way round (priced twenty times what the search found, as behind a shut gate),
-- the line walked to the foot of lift 8, rode up the mesa's cliff and straight down again, and walked on from its foot
-- (a walk after a walk). Now the one walk.
;(function()
    local s = Walk.SAMPLE
    local function Spot(u, v) return (u + 12000) / 24000, (20000 - v) / 40000 end
    local fu, fv = Coords.TILE + 40 * s, -64 * s
    local pu, pv = Coords.TILE + 40 * s, -200 * s
    local price, hearth = Search.Price, Core.Character(ns.name).hearth
    Search.Price = function(map, u1, v1, u2, v2, ...)
        local cost, rest, found = price(map, u1, v1, u2, v2, ...)
        if cost and math.abs(u1 - fu) < 0.5 and math.abs(v1 - fv) < 0.5 and math.abs(u2 - pu) < 0.5
            and math.abs(v2 - pv) < 0.5 then
            cost = cost * 20
        end
        return cost, rest, found
    end
    Core.Character(ns.name).hearth = nil
    player.map, player.x, player.y = 1414, Spot(fu, fv)
    waypoint = { uiMapID = 1414, position = CreateVector2D(Spot(pu, pv)) }
    shownWay = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local kinds = {}
    for index, leg in ipairs(shownWay and shownWay.legs or {}) do kinds[index] = leg.kind end
    check(table.concat(kinds, " ") == "walk",
        "a walk straight there a long way round: never up a lift and straight down again to walk on; the one walk")
    Search.Price, Core.Character(ns.name).hearth = price, hearth
    player.map, player.x, player.y = 1429, 0.75, 0.3
    waypoint = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
end)()
-- A walk to a lift's end ends on its own level (Lifts.Heights: within Walk.RISE yards of its landing's height, nearer
-- it than the other end's): from the hall of tile 6178 to the upper end of lift 11, on the courtyard over the hall (one
-- region, joined to it only far off), the search ended on the hall under it, where the lift's foot is, and a journey
-- rode down and up again from there as though it had come down the lift. Now it ends on the courtyard: none there.
;(function()
    local s, Lifts = Walk.SAMPLE, ns.Lifts
    local lift
    for _, each in ipairs(Lifts.All()) do
        if each.key == 11 then lift = each end
    end
    local low, high = Lifts.Heights(lift[1]), Lifts.Heights(lift[2])
    check(low and high and low[1] == -32 and low[2] == -8 and high[1] == -2 and high[2] == 22,
        "each end of a lift: the heights of its own level, within Walk.RISE yards of its landing's")
    local hu, hv, hall = 2 * Coords.TILE + 110 * s, -70 * s, { 6178, 2 }
    local top, foot = lift[2], lift[1]
    check(Search.Price(1414, hu, hv, top.pu, top.pv, hall)
        and not Search.Price(1414, hu, hv, top.pu, top.pv, hall, nil, nil, nil, high)
        and Search.Price(1414, hu, hv, foot.pu, foot.pv, hall, nil, nil, nil, low),
        "from the hall to the lift's upper end: on its level only (the courtyard: no way there), not on the hall under "
        .. "it; to its foot on the hall")
end)()
-- Of the journeys whose walks were all priced, the quickest is drawn. Alpha and Beta known (the set's flight 5), the
-- player 100 yards south of Alpha, the pin 2000 yards north of Beta, each walk priced at its guess times a factor:
-- first the flight, its walk on from Beta 1.7 times its guess (so the journey is chosen again), then the walk straight
-- there, 1.55 times its guess (under Planner.WORSE times: it stays), dearer as priced than the flight with its walks.
-- The line was the walk; now the flight.
;(function()
    local price, nodes, known = Search.Price, C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flightPoints
    local count, hearth = C_Item.GetItemCount, Core.Character(ns.name).hearth
    C_TaxiMap.GetTaxiNodesForMap = function(map)
        if map ~= 1415 then return {} end
        return { { nodeID = 20, name = "Alpha", position = CreateVector2D(0.5, 0.2), faction = 0 },
                 { nodeID = 21, name = "Beta", position = CreateVector2D(0.5, 0.15), faction = 0 } }
    end
    Core.Character(ns.name).flightPoints = { [20] = true, [21] = true }
    C_Item.GetItemCount = function() return 0 end
    Core.Character(ns.name).hearth = nil
    local priced = {}
    Search.Price = function(map, u1, v1, u2, v2)
        local times = 1
        if math.abs(v2 - 3000) < 1 then times = math.abs(v1 - 1000) < 1 and 1.7 or 1.55 end
        local cost = times * math.sqrt((u2 - u1) ^ 2 + (v2 - v1) ^ 2) * Planner.DETOUR
        priced[#priced + 1] = times
        return cost, 0, { points = { u1, v1, u2, v2 }, cost = cost, rest = 0 }
    end
    player.map, player.x, player.y = 1415, 0.5, 0.205
    waypoint = { uiMapID = 1415, position = CreateVector2D(0.5, 0.05) }
    shownWay = nil
    W.Fire("USER_WAYPOINT_UPDATED")
    W.Wait(0)
    Frames(8)
    local legs, kinds = shownWay and shownWay.legs or {}, {}
    for index, leg in ipairs(legs) do kinds[index] = leg.kind end
    check(table.concat(kinds, " ") == "walk flight walk" and table.concat(priced, " ") == "1 1.7 1.55"
        and near(legs[2].points[#legs[2].points].v, 1000),
        "the flight priced, chosen again, the walk straight there priced dearer: of the journeys priced whole, the flight")
    Search.Price, C_TaxiMap.GetTaxiNodesForMap, Core.Character(ns.name).flightPoints = price, nodes, known
    C_Item.GetItemCount, Core.Character(ns.name).hearth = count, hearth
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
    check(chosen.foundHerb and chosen.foundOre and chosen.foundFish and ns.options.nodeTurns == nil,
        "found herbs, ore and fishing pools: on (brought up to date from an older shape, its seconds let go)")
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
    -- In turn while you move: every 15 yards at first, at your speed (15 yards a second: 1 second; 7 a second: not
    -- yet after 2 seconds).
    local count = #gather.switches
    W.Wait(5)
    check(ns.options.nodeYards == 15 and #gather.switches == count, "standing still: no turn")
    gather.speed = 7
    W.Wait(2)
    check(#gather.switches == count, "moving 14 yards: no turn yet")
    gather.speed = 15
    W.Wait(1.01)
    check(#gather.switches == count + 1 and gather.tracking[2].active, "moving 15 yards: Find Minerals in turn")
    -- Find Fish learnt: herbs, ore, fish and round again.
    gather.tracking[3] = { name = "Find Fish", spellID = 43308, active = false }
    W.Fire("SPELLS_CHANGED")
    local turns = {}
    for _ = 1, 3 do
        W.Wait(1.01)
        turns[#turns + 1] = Nodes.Active()
    end
    check(table.concat(turns, " ") == "fish herb ore" and #gather.switches == count + 4, "Find Fish known: it takes its turn after ore")
    -- The global cooldown keeps a turn waiting.
    local cooldown = C_Spell.GetSpellCooldown
    C_Spell.GetSpellCooldown = function() return { startTime = GetTime(), duration = 1.5 } end
    W.Wait(2)
    check(#gather.switches == count + 4, "the global cooldown running: no turn")
    C_Spell.GetSpellCooldown = cooldown
    W.Wait(Nodes.LOOK + 0.01)
    check(#gather.switches == count + 5 and Nodes.Active() == "fish", "over: the turn at once")
    -- Found fishing pools off: Find Fish gives way and is left out of the turns.
    chosen = Core.Copy(ns.options.pins)
    chosen.foundFish = nil
    Core.Set(ns.name, "pins", chosen)
    check(Nodes.Active() == "herb", "Found fishing pools off: Find Herbs in its place")
    turns = {}
    for _ = 1, 2 do
        W.Wait(1.01)
        turns[#turns + 1] = Nodes.Active()
    end
    check(table.concat(turns, " ") == "ore herb", "the turns without Find Fish")
    -- Dying takes the tracking: alive again, the finder back on as soon as it can be cast.
    gather.speed = 0
    count = #gather.switches
    for _, entry in ipairs(gather.tracking) do entry.active = false end
    W.Fire("MINIMAP_UPDATE_TRACKING")
    local dead = UnitIsDeadOrGhost
    UnitIsDeadOrGhost = function() return true end
    W.Fire("PLAYER_ALIVE") -- your spirit released: a ghost
    W.Wait(Nodes.REVIVE + 1)
    check(#gather.switches == count and not Nodes.Active(), "a ghost: no finder (none can be cast), the tries run out")
    UnitIsDeadOrGhost = dead
    W.Fire("PLAYER_UNGHOST")
    W.Wait(Nodes.LOOK + 0.01)
    check(#gather.switches == count + 1 and Nodes.Active() == "herb", "alive again: Find Herbs back on")
    W.Wait(Nodes.REVIVE + 1)
    check(#gather.switches == count + 1, "and only once")
    -- One kind wanted: no turns, and it alone comes back.
    chosen = Core.Copy(ns.options.pins)
    chosen.foundHerb = nil
    Core.Set(ns.name, "pins", chosen)
    check(Nodes.Active() == "ore", "Found herbs off too: Find Minerals alone")
    count = #gather.switches
    gather.speed = 7
    W.Wait(3)
    gather.speed = 0
    check(#gather.switches == count, "one finder wanted: no turns")
    for _, entry in ipairs(gather.tracking) do entry.active = false end
    W.Fire("MINIMAP_UPDATE_TRACKING")
    W.Fire("PLAYER_ALIVE") -- resurrected where you died
    W.Wait(Nodes.LOOK + 0.01)
    check(Nodes.Active() == "ore", "resurrected: Find Minerals back on")
    gather.tracking[3] = nil
    chosen = Core.Copy(chosen)
    chosen.foundHerb, chosen.foundFish = true, true
    Core.Set(ns.name, "pins", chosen)
    W.Fire("SPELLS_CHANGED")
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
    local saved, sent = waypoint, nil
    local send = ns.Ping.Send
    ns.Ping.Send = function(map, u, v) sent = { map, u, v } return true end
    waypoint = nil
    W.Wait(1.6) -- the clock as the tests below were written for
    spot._scripts.OnClick(spot)
    local entry = spot.entry
    check(not waypoint and sent and sent[1] == entry.plane and sent[2] == entry.u and sent[3] == entry.v,
        "a click: a ping where it is, in the click")
    sent = nil
    spot._scripts.OnDoubleClick(spot)
    check(waypoint and waypoint.uiMapID == 1429 and waypoint.position.x > 0 and waypoint.position.x < 1
        and waypoint.position.y > 0 and waypoint.position.y < 1 and not sent,
        "a double click: the game's map pin where it is, on its zone's map; no second ping")
    ns.Ping.Send = send
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

-- Far sparkles (Glints.lua): each found herb marked on the screen in its direction however far, with its yards;
-- one behind you at the edge you would turn to; none while the left mouse button turns the camera.
;(function()
    local Found, Glints, Nodes = ns.Found, ns.Glints, ns.Nodes
    local held, facing, saved = {}, 0, GetPlayerFacing
    IsMouseButtonDown = function(button) return held[button] or false end
    GetPlayerFacing = function() return facing end
    GetCameraZoom = function() return 10 end
    CreateColor = function(r, g, b, a) return { r, g, b, a } end
    WorldFrame = W.NewWidget("Frame", "WorldFrame", nil)
    W.methods.SetFormattedText = function(self, format, ...) self._text = format:format(...) end
    local holder = Glints.frame
    holder._width, holder._height = 1600, 900
    local plane, pu, pv = Coords.Player()
    local herb = Nodes.Find("Silverleaf")
    local list = Found.Each()
    local function Add(du, dv)
        list[#list + 1] = { u = pu + du, v = pv + dv, plane = plane, kind = "herb", node = herb, seen = 0, swept = 0 }
    end
    local function Marks(elapsed)
        holder._scripts.OnUpdate(holder, elapsed or Glints.TICK)
        local shown = {}
        for _, widget in ipairs(W.frames) do
            if widget._parent == holder and widget._shown then shown[#shown + 1] = widget end
        end
        return shown
    end
    local function Parts(mark)
        local parts = {}
        for _, widget in ipairs(W.frames) do
            if widget._parent == mark then
                if widget._kind == "FontString" then parts.text, parts.under = widget._text, widget._points[1][5] end
                if widget._texture == 3765 then parts.icon = widget end
                -- The ring with its point, turned from pointing up (counterclockwise, as the game turns).
                if widget._kind == "Texture" and widget._texture == Glints.RING then parts.turn = widget._rotation end
            end
        end
        return parts
    end
    check(holder and holder._shown and holder._strata == "BACKGROUND", "far sparkles: a frame of ours under every window")
    Add(0, 60)     -- straight ahead
    Add(40, 80)    -- ahead, to the right (east, facing north)
    Add(-10, -50)  -- behind you, to the left
    Add(5, 10)     -- within the close sparkles' reach
    local marks = Marks()
    check(#marks == 3, "the three beyond the close sparkles' reach marked, the near one left to them")
    local by = {}
    for _, mark in ipairs(marks) do by[Parts(mark).text] = mark end
    local ahead, right, behind = by["55"], by["82"], by["47"]
    check(ahead and right and behind and marks[1] == behind, "each with how far it is, in meters, the nearest first")
    local at, turn = ahead._points[1], Parts(ahead).turn
    check(at[2] == holder and math.abs(at[4]) < 1e-6 and at[5] > 0 and at[5] < 450 and Parts(ahead).icon
        and math.abs(turn) < 1e-6, "one straight ahead: its herb's picture in the screen's middle, its ring pointing up")
    turn = Parts(right).turn
    check(right._points[1][4] > 0 and right._points[1][4] < 800 - Glints.EDGE and turn < 0 and turn > -math.pi / 2,
        "one ahead to the right: right of the middle, on the screen, its ring pointing up and to the right")
    turn = Parts(behind).turn
    check(math.abs(behind._points[1][4] + (800 - Glints.EDGE)) < 1e-6 and turn > math.pi / 2,
        "one behind you to the left: at the left edge, its ring pointing down and to the left")
    local ring
    for _, widget in ipairs(W.frames) do if widget._parent == behind and widget._texture == Glints.RING then ring = widget end end
    check(Parts(ahead).under < 0 and Parts(behind).under < -Found.OUTER * ring._width - 2,
        "the yards under the ring, and under its point while that points down")
    W.foci = { WorldFrame }
    held.LeftButton = true
    check(#Marks(0.3) == 0, "the left mouse button turning the camera: none (your facing tells nothing then)")
    held.LeftButton = false
    check(#Marks() == 0, "the button let go, standing: still none (the camera is not behind you yet)")
    gather.speed = 7
    check(#Marks(Glints.SETTLE + 0.1) == 3, "moved on a while: back (the camera has swung behind you)")
    gather.speed = 0
    held.LeftButton = true
    Marks(0.3)
    held.RightButton = true
    check(#Marks() == 3, "the right button down too: back at once (it turns you with the camera)")
    held.LeftButton, held.RightButton, W.foci = false, false, {}
    held.LeftButton = true
    check(#Marks(0.1) == 3, "a short click (a target, a herb): no camera turn")
    held.LeftButton = false
    Core.Set(ns.name, "nodeGlints", false)
    check(not holder._shown, "the setting off: nothing drawn, nothing asked")
    Core.Set(ns.name, "nodeGlints", true)
    check(holder._shown and #Marks() == 3, "on again: marked again")
    for index = #list, 1, -1 do if list[index].seen == 0 then table.remove(list, index) end end
    check(#Marks() == 0, "none found: none marked")
    -- Nothing found at all: the frame rests (nothing asked each frame), until Found tells of one.
    local rest = {}
    for index = #list, 1, -1 do rest[#rest + 1] = table.remove(list, index) end
    Marks()
    check(not holder._shown, "nothing found: the frame at rest")
    Add(0, 60)
    Glints.Found()
    check(holder._shown and #Marks() == 1, "one found (Found tells of it): running again, marked")
    table.remove(list)
    for index = #rest, 1, -1 do list[#list + 1] = rest[index] end
    Marks()
    GetPlayerFacing = saved
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
    check(GameTooltip._text == "The First Boss" and lines[3] == Dungeons.TEXT.abilities and lines[4]:find("Cleave", 1, true)
        and lines[4]:find("132338", 1, true) and lines[5] == Dungeons.TEXT.loot and lines[6]:find("Item 901", 1, true)
        and lines[6]:find("1901", 1, true) and lines[7] == Dungeons.TEXT.unverified and lines[7] == Core.UNCONFIRMED
        and asked[1] == 902,
        "its tooltip: the boss's name as the game's encounters have it, its abilities and loot with their icons as the "
        .. "game has them (a spell it does not know left out, an item not loaded asked for), not yet confirmed")
    local look = Core.LookOf(GameTooltip)
    check(lines[1] == "Deep Halls" and lines[2] == Dungeons.TEXT.boss and look and look.dragon == "boss" and look.badge == "??"
        and look.display == marks[1].display,
        "drawn as a creature's: under its name the dungeon and Boss; its model, the boss's dragon, ?? for its level")
    check(lines[4] == "|T132338:16:16:0:0:64:64:5:59:5:59|t " .. Core.UNCONFIRMED_MARK .. "Cleave"
        and lines[6]:find("|t " .. Core.UNCONFIRMED_MARK .. "Item 901", 1, true),
        "each ability and item not yet confirmed: the red ! between its icon and its name")
    loaded[902] = true
    GameTooltip._lines = nil -- (the stand-in keeps its lines; the game's tooltip starts anew at SetOwner)
    W.Fire("ITEM_DATA_LOAD_RESULT", 902, true)
    Frames(1)
    lines = GameTooltip._lines or {}
    check(lines[7] and lines[7]:find("Item 902", 1, true), "the item come: the tooltip drawn again with it")
    -- How often an item came from this boss, at its line's right: Core's counts, the boss found by its name
    W.methods.AddDoubleLine = function(self, left, right) self:AddLine(left .. " | " .. right) end
    for index = 1, 4 do
        Core.Data.Tally.Loot("npc:79", "loot", 0)
        if index > 1 then Core.Data.Tally.Drop("npc:79", "loot", 901, 0, 1) end
    end
    GameTooltip._lines = nil
    marks[1]._scripts.OnEnter(marks[1])
    lines = GameTooltip._lines or {}
    check(lines[6]:find("Item 901", 1, true) and lines[6]:find(" | 75% (3 of 4)", 1, true) and not lines[7]:find(" | ", 1, true),
        "a boss's loot: how often each item came from it, nothing where nobody counted")
    -- Alt held: each ability's description under its name, each item's own tooltip read for its lines.
    local describe, read = C_Spell.GetSpellDescription, {}
    C_Spell.GetSpellDescription = function(id) return id == 801 and "Hits the target and those beside it." or "" end
    -- An item's own tooltip as the game fills it: only its damage, damage per second, stats and effects are kept,
    -- and that its look is not collected.
    local ITEM_LINES = { "Item", "Binds when picked up", { "Two-Hand", "Axe" }, { "41 - 77 Damage", "Speed 3.60" },
        "(16.4 damage per second)", "+12 Strength", "Durability 100 / 100", "Requires Level 40",
        "Equip: Improves your chance to hit by 1%.", "You haven't collected this appearance", "Sell Price: 5",
        '"Forged in the deep."' }
    ITEM_SPELL_TRIGGER_ONEQUIP, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN = "Equip:", "You haven't collected this appearance"
    W.methods.SetItemByID = function(self, id)
        read[#read + 1] = id
        for index, line in ipairs(ITEM_LINES) do
            local left, right = W.NewWidget("FontString"), W.NewWidget("FontString")
            left:SetText(type(line) == "table" and line[1] or line)
            right:SetText(type(line) == "table" and line[2] or nil)
            right:SetShown(type(line) == "table")
            _G["SaneUINavigationReaderTextLeft" .. index], _G["SaneUINavigationReaderTextRight" .. index] = left, right
        end
        self.NumLines = function() return #ITEM_LINES end
    end
    W.methods.AddDoubleLine = function(self, left, right) self:AddLine(left .. " | " .. right) end
    IsAltKeyDown = function() return true end
    GameTooltip._lines = nil
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
    Frames(1)
    lines = GameTooltip._lines or {}
    check(lines[4] and lines[4]:find("Cleave", 1, true) and lines[5] == "    Hits the target and those beside it."
        and lines[6] == Dungeons.TEXT.loot and read[1] == 901 and read[2] == 902,
        "Alt held: the tooltip drawn again, an ability's description under it, the items' own tooltips read")
    check(lines[8] == "    " .. Dungeons.TEXT.uncollected and lines[9] == "    Equip: Improves your chance to hit by 1%."
        and lines[10] == "    41 - 77 Damage | Speed 3.60" and lines[11] == "    (16.4 damage per second)"
        and lines[12] == "    +12 Strength" and lines[13] and lines[13]:find("Item 902", 1, true),
        "an item's details: Uncollected first, then its effects, last its damage, speed, damage per second and stats; no "
        .. "binding, slot, durability, requirement, price or lore")
    IsAltKeyDown = function() return false end
    GameTooltip._lines = nil
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
    Frames(1)
    check((GameTooltip._lines or {})[5] == Dungeons.TEXT.loot, "Alt let go: the names only again")
    -- Confirmed in play (Core's watchers, or a guild or group member's message): what the tooltip shows of the boss is
    -- no longer unconfirmed; an item looted from the boss that the set does not name joins its loot.
    local Data = Core.Data
    check(Data.Confirm("Bosses", 700, "a801") and Data.Confirm("Bosses", 700, "l901") and Data.Confirm("Bosses", 700, "l902")
        and not Data.Confirm("Bosses", 700, "l901") and not Data.Confirm("Bosses", 9999, "l1"),
        "each ability and item confirmed once; a boss the set does not have, never")
    GameTooltip._lines = nil
    Frames(1)
    lines = GameTooltip._lines or {}
    check(lines[#lines] ~= Dungeons.TEXT.unverified and lines[7] and lines[7]:find("Item 902", 1, true)
        and lines[4] == "|T132338:16:16:0:0:64:64:5:59:5:59|t Cleave" and not lines[7]:find(Core.UNCONFIRMED_MARK, 1, true),
        "everything it shows confirmed: no red !, no Unconfirmed Data")
    check(Data.Confirm("Bosses", 700, "l903"), "an item looted from the boss that the set does not name: confirmed too")
    GameTooltip._lines = nil
    Frames(1)
    lines = GameTooltip._lines or {}
    check(lines[8] and lines[8]:find("Hidden Blade", 1, true) and lines[8]:find("1903", 1, true)
        and lines[#lines] ~= Dungeons.TEXT.unverified,
        "it joins the loot, named as Core's data has it while the game keeps it hidden")
    -- With Alt: the game's tooltip of it shows nothing, so its stats as Core's data has them (learned in play).
    W.methods.SetItemByID = function(self, id)
        local left = W.NewWidget("FontString")
        left:SetText(id == 903 and "Hidden Blade" or "Item")
        _G.SaneUINavigationReaderTextLeft1, _G.SaneUINavigationReaderTextRight1 = left, W.NewWidget("FontString")
        self.NumLines = function() return 1 end
    end
    IsAltKeyDown = function() return true end
    GameTooltip._lines = nil
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
    Frames(1)
    lines = GameTooltip._lines or {}
    local blade
    for index, line in ipairs(lines) do if line:find("Hidden Blade", 1, true) then blade = index end end
    check(blade and lines[blade + 1] == "    50 Arm" and lines[blade + 2] == "    +7 ITEM_MOD_STAMINA_SHORT",
        "Alt over an item the game keeps hidden: its armour and stats as Core's data has them")
    IsAltKeyDown = function() return false end
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
    Frames(1)
    C_Spell.GetSpellDescription, W.methods.SetItemByID = describe, nil
    ITEM_SPELL_TRIGGER_ONEQUIP, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN = nil, nil
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
        local itemInfo = C_Item.GetItemInfo
        C_Item.GetItemInfo = function() return "A Fang", nil, 1 end
        Core.Data.Tally.Loot("npc:71", "loot", 0)
        Core.Data.Tally.Drop("npc:71", "loot", 766, 0, 1)
        GameTooltip._lines = nil
        foes[1]._scripts.OnEnter(foes[1])
        check(GameTooltip._lines and GameTooltip._lines[1] == Pins.TEXT.dropsCorpse and GameTooltip._lines[2]:find("A Fang | 1 of 1", 1, true),
            "and what it drops, as on a pin")
        C_Item.GetItemInfo = itemInfo
    end
    local model = marks[1].model
    check(model and model._kind == "PlayerModel" and model._display == 4203 and model._shown
        and model._points[1][1] == "BOTTOM" and near(model._points[1][4], marks[1]._points[1][4])
        and model._level > marks[1]._level and not marks[1].icon._shown,
        "its own model in its look, standing on its mark, over it; the mark's icon gone under it")
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
    check(not model._shown and marks[1]._shown and marks[1].icon._shown and stepping and not view._scripts.OnUpdate,
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

-------------------------------------------------------------------------------
--  Retail: Core holds none of Forever's data there (its sets refused), and the game lacks Forever's own (W.Play)
-------------------------------------------------------------------------------
;(function()
    -- Forever's art indexes are read in Forever only (their TOC lines).
    local handle = assert(io.open(root .. "/src/Navigation/SaneUI_Navigation.toc"))
    local toc = handle:read("*a")
    handle:close()
    local function Left()
        local left = {}
        for line in toc:gmatch("[^\n]+") do
            local file, conditions = line:match("^([%w%.]+%.lua)%s*(.*)$")
            if file and not W.Allowed(conditions) then left[#left + 1] = file end
        end
        table.sort(left)
        return table.concat(left, " ")
    end
    check(Left() == "", "Forever reads every file of the module")
    W.Play("retail")
    check(Left() == "Coasts.lua Outlines.lua", "Retail leaves Forever's outlines and coasts out")

    -- Its sets refused: the land, herbs and ore, the ways, the places.
    local Nodes = ns.Nodes
    local silverleaf = Nodes.Find("Silverleaf")
    local SETS = { "Tiles", "Objects", "Travel", "Spawns", "Places" }
    for _, name in ipairs(SETS) do Core.Data.Set(name).State = function() return "refused", "another game's" end end
    local together, view, sounds = Nodes.TOGETHER, ns.options.view, C_CVar.GetCVar("softTargetInteract")
    Nodes.TOGETHER = Core.RETAIL
    check(Core.RETAIL and not ns.Offered("terrain") and not ns.Offered("blend") and ns.Offered("sketches")
        and ns.Fallback() == "sketches",
        "Retail without Core's terrain: Scrying and Blended not offered, Parchment the fallback")
    Core.Set(ns.name, "view", "terrain")
    check(ns.View() == "sketches", "a saved Scrying drawn as Parchment")
    ns.Offer()
    local listed = {}
    for _, choice in ipairs(viewOption.choices) do listed[#listed + 1] = choice[1] end
    listed = table.concat(listed, " ")
    check(ns.options.view == "sketches" and listed:find("^sketches") and not listed:find("terrain") and not listed:find("blend"),
        "and the setting falls back to it; the views offered: no Scrying, no Blended")
    local pins = {}
    for _, choice in ipairs(Core.Described(ns.name, "pins").choices) do pins[choice[1]] = true end
    check(pins.log and pins.flight and pins.place and pins.rare and pins.foundHerb and pins.group and not pins.quest
        and not pins.low and not pins.later and not pins.done and not pins.service and not pins.herb and not pins.ore
        and not pins.book, "the pin kinds only Core's data has: not in the setting's list")
    local filter
    for _, widget in ipairs(W.frames) do
        if widget._generator and widget._override == ns.TopBar.TEXT.pins then filter = widget end
    end
    filter:GenerateMenu()
    local rows = {}
    for _, item in ipairs(filter._items or {}) do if type(item.text) == "string" then rows[#rows + 1] = item.text end end
    rows = table.concat(rows, "\n")
    check(rows:find("Flight points", 1, true) and rows:find("Found herbs", 1, true) and not rows:find("Possible herbs", 1, true)
        and not rows:find("Services", 1, true) and not rows:find(ns.TEXT.offers, 1, true), "nor in the pin filter")
    local function Hidden(key)
        local option = Core.Described(ns.name, key)
        return option.hidden and option.hidden() and true or false
    end
    check(Hidden("tripView") and Hidden("dockTimes") and Hidden("nodeSparkles") and Hidden("nodeGlints") and Hidden("nodeYards")
        and not Hidden("nativeMinimap") and Core.Described(ns.name, "nodeSparkles").header == nil,
        "the switches of what Retail cannot have are not on the options page, nor the section Herbs and ore")
    -- One view alone: it is the map, as a first load has it, with no button on the bar and no setting.
    local logButton
    for _, widget in ipairs(W.frames) do if widget._text == ns.TopBar.TEXT.questLog then logButton = widget end end
    local afterLog
    for _, widget in ipairs(W.frames) do
        if widget._points and widget._points[1] and widget._points[1][2] == logButton and widget ~= logButton then afterLog = widget end
    end
    check(not ns.Several() and not Button("sketches")._shown and not Button("blend")._shown and not Button("terrain")._shown
        and Hidden("view") and viewOption.default == "sketches"
        and Core.Settle(ns.name, {}).view == "sketches" and afterLog and afterLog._override,
        "one view: Parchment, a first load's too; no view buttons, the map selector right of the quest log's; no setting")

    -- The map: Parchment, the game's own art; the game's minimap its own ground in the small view, its dots only full.
    Canvas.Refresh()
    local shown = Shown()
    check(Count(shown, 801, 804) == 0 and Overviews(shown, 0) == 0 and Overviews(shown, 0, "Sketches") == 0,
        "no terrain, no overview, no stitched map")
    small.follow, small.native = true, 2
    Hybrid.Place(small, 200, 200, true, false)
    check(Hybrid.Taken() and ground == true, "the small view: the game's minimap with its own ground, the land as it lies")
    -- That ground would cover the golden line: the line stands over it, under the pins.
    local at = Canvas.view
    ns.Route.Show({ legs = { { kind = "walk", points = { { map = at.map, u = at.u, v = at.v },
                                                         { map = at.map, u = at.u + 40, v = at.v + 40 } } } } })
    local line
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Line" and widget._shown and widget._parent._parent._parent == Canvas.frame then line = widget end
    end
    check(line and line._parent._level > minimap._level
        and line._parent._level < Canvas.frame:GetFrameLevel() + Canvas.LEVELS.pins,
        "the golden line over the game's own ground, under the pins")
    ns.Route.Show(nil)
    Hybrid.Place(full, 1600, 866, true, false)
    check(ground == false, "the full map: its dots only")

    -- Given back where the game's code sets no mask: the engine's round one.
    local config = cluster.UpdateMinimapConfig
    cluster.UpdateMinimapConfig = false -- (the stand-in's frames answer every other name with a function)
    Core.Set(ns.name, "nativeMinimap", true)
    check(not Hybrid.Taken() and minimap._mask == Hybrid.ROUND,
        "the game's minimap given back round, where the game sets no mask")
    cluster.UpdateMinimapConfig = config
    Core.Set(ns.name, "nativeMinimap", false)
    check(Hybrid.Taken() and minimap._mask == Hybrid.MASK, "taken again: square")

    -- Herbs and ore: both finders at once, no turns; no sparkles, no far ones, the game's settings as they were.
    local setTracking = C_Minimap.SetTracking
    C_Minimap.SetTracking = function(index, on)
        gather.tracking[index].active = on
        gather.switches[#gather.switches + 1] = { index = index, on = on }
    end
    gather.tracking[1].active, gather.tracking[2].active = false, false
    W.Fire("MINIMAP_UPDATE_TRACKING")
    Nodes.Apply()
    check(gather.tracking[1].active and gather.tracking[2].active,
        "Retail's tracking holds both: Find Herbs and Find Minerals on")
    local chosen = Core.Copy(ns.options.pins)
    chosen.foundOre = nil
    Core.Set(ns.name, "pins", chosen)
    check(gather.tracking[1].active and not gather.tracking[2].active, "Found ore off: Find Minerals off, Find Herbs stays")
    chosen = Core.Copy(chosen)
    chosen.foundOre = true
    Core.Set(ns.name, "pins", chosen)
    local count = #gather.switches
    gather.speed = 7
    W.Wait(3)
    gather.speed = 0
    check(gather.tracking[1].active and gather.tracking[2].active and #gather.switches == count,
        "both on again, and no turns while moving")
    W.Wait(Nodes.QUIET + 0.01)
    C_Minimap.SetTracking = setTracking
    ns.Sparkles.Settings()
    ns.Glints.Update()
    check(C_CVar.GetCVar("softTargetInteract") == "1" and C_CVar.GetCVar("SoftTargetIconGameObject") == "0"
        and not ns.Glints.frame._shown and not Nodes.Known(), "no sparkles (the game's settings as they were) and no far ones")
    check(not Nodes.TooHard(silverleaf), "a game that tells no skill line's rank: no herb greyed")

    -- The continents beside the world map (Outland), under the map over it: in the selector, drawn by their own map.
    local children = C_Map.GetMapChildrenInfo
    MAPS[946] = { kind = 0, parent = 0 }
    MAPS[947].parent = 946
    MAPS[101] = { kind = 2, parent = 946, continent = 530, top = 5000, bottom = -5000, left = 5000, right = -5000 }
    C_Map.GetMapChildrenInfo = function(map, kind, all)
        if map ~= 946 then return children(map, kind, all) end
        local list = {}
        for _, id in ipairs({ 947, 101 }) do
            if not kind or MAPS[id].kind == kind then list[#list + 1] = { mapID = id, mapType = MAPS[id].kind } end
        end
        return list
    end
    local elsewhere = Coords.Elsewhere()
    check(Coords.Top() == 946 and #elsewhere == 1 and elsewhere[1] == 101, "the map over the world map, and its other continent")
    local selector
    for _, widget in ipairs(W.frames) do
        if widget._generator then
            widget:GenerateMenu()
            if widget._items[1] and widget._items[1].text == "#947" then selector = widget end
        end
    end
    check(selector and selector._items[#selector._items].text == "#101", "the map selector lists it after the world's")
    local camera = Canvas.camera
    check(Canvas.Show(101) and camera.map == 101 and Count(Shown(), 10101, 10112) > 0,
        "shown: its own map drawn, though the world map does not hold it")
    MAPS[946], MAPS[101], MAPS[947].parent, C_Map.GetMapChildrenInfo = nil, nil, 0, children
    check(Canvas.Show(1415) and camera.map == 1415 and Coords.Top() == 947 and #Coords.Elsewhere() == 0,
        "and back: the world map the top again")

    -- Back to Forever.
    W.Play("forever")
    for _, name in ipairs(SETS) do Core.Data.Set(name).State = nil end
    Nodes.TOGETHER = together
    ns.Offer()
    Core.Set(ns.name, "view", view)
    ns.Sparkles.Settings()
    ns.Glints.Update()
    check(Button("sketches")._shown and Button("terrain")._shown and Button("terrain")._points[1][2] == Button("blend"),
        "Forever again: the view buttons in their row")
    check(ns.Offered("terrain") and ns.View() == view and Core.Described(ns.name, "nodeSparkles").header == ns.TEXT.nodes
        and Core.Described(ns.name, "pins").choices[4][1] == "quest" and not Hidden("tripView") and not Hidden("nodeYards")
        and C_CVar.GetCVar("softTargetInteract") == sounds and not ns.off,
        "Forever again: every view, kind and switch back, the sparkles' settings set, the module running")
end)()

-- The Sane Rare tracker (RareTracker.lua): a rare's tooltip on the map as a dungeon boss's; the game's mark of a rare near
-- you told at once by a notice and the war horn; the mouse, a click and a right click on it, its time; each told once;
-- what it tells of, its switch, an instance; a rare seen in person; the test command.
;(function()
    local RareTracker, PinView, TEXT = ns.RareTracker, ns.PinView, ns.RareTracker.TEXT
    local NPCS = Core.Data.Set("NPCs")
    local saved = { IsAltKeyDown = rawget(_G, "IsAltKeyDown"), IsInInstance = rawget(_G, "IsInInstance"), PlaySound = PlaySound,
                    info = C_VignetteInfo.GetVignetteInfo, spellInfo = C_Spell.GetSpellInfo,
                    spellWords = C_Spell.GetSpellDescription }
    local alt, played, asked = false, {}, nil
    IsAltKeyDown = function() return alt end
    PlaySound = function(kit, channel) played[#played + 1] = { kit, channel } end
    W.methods.SetCreature = function(self, npc) asked, self._creature = npc, npc end
    C_Spell.GetSpellInfo = function(id) if id == 133 then return { name = "Fireball", iconID = 135812 } end end
    C_Spell.GetSpellDescription = function(id) if id == 133 then return "Hurls a ball of fire." end end
    -- Core's NPCs know more of the rare than the test's set holds: its rank, level, kind, side, ability, its respawn
    local facts = { rank = "rareelite", levelMax = 24, kind = "beast", alliance = "neutral", abilities = { 133 }, respawn = 2700 }
    NPCS.Get = function(self, key, field)
        if key == 70 and facts[field] ~= nil then return facts[field] end
        return getmetatable(self).__index.Get(self, key, field)
    end

    -- Its tooltip on the map, as a boss's
    local rare = CreateFrame("Button", nil, UIParent) -- as the rare's pin on the map: its button holds the pin
    rare.pin = { kind = "rare", key = "npc:70", name = "A rare", live = true }
    rare._mouseOver = true
    GameTooltip._lines = nil
    PinView.Tip(rare)
    local look, lines = Core.LookOf(GameTooltip), GameTooltip._lines or {}
    check(look and look.creature == 70 and look.dragon == "silver" and look.badge == "24",
        "a rare's tooltip as a dungeon boss's: its own model by its creature, a rare's silver dragon, its level on the plaque")
    check(lines[1] == PinView.TEXT.rare .. " " .. PinView.TEXT.elite and lines[2] == "Beast"
        and lines[3] == PinView.TEXT.respawn:format(rawget(_G, "SecondsToTime") and SecondsToTime(2700) or "45 min"),
        "under its name: Rare Elite, its kind, when it comes back")
    check(lines[4] == ns.Dungeons.TEXT.abilities and lines[5]:find("Fireball", 1, true)
        and lines[5]:find("135812", 1, true), "then its abilities, a section, each with the game's icon and name")
    alt = true
    GameTooltip._lines = nil
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
    check(table.concat(GameTooltip._lines or {}, "\n"):find("    Hurls a ball of fire.", 1, true),
        "Alt held: drawn again, each ability's description under it")
    alt = false
    W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
    rare._mouseOver = false
    PinView.Untip()
    rare.pin = nil

    -- The game's marks on the minimap: the rare told at once, then the chest. The small map's window 220 under the top
    local window, camera, top, right = ns.Window.frame, ns.Canvas.camera, UIParent._top, UIParent._right
    local windowBottom, windowShown = window._bottom, window._shown
    UIParent._top, window._bottom, window._shown, ns.Canvas.camera = 900, 680, true, ns.Window.small
    C_VignetteInfo.GetVignetteInfo = function(guid)
        if guid == "v1" then
            return { name = "A rare", atlasName = "VignetteKillElite", objectGUID = "Creature-0-1-2-3-70-0000AB", onMinimap = true }
        end
        if guid == "v2" then
            return { name = "A chest", atlasName = "VignetteLoot", objectGUID = "GameObject-0-1-2-3-1617-0000AC", onMinimap = true }
        end
    end
    W.Fire("VIGNETTE_MINIMAP_UPDATED", "v1", true)
    local shown = RareTracker.shown
    local notice = shown[1]
    check(#shown == 1 and notice._shown and notice.name:GetText() == "A rare" and notice.what:GetText() == "Rare Elite, Level 24",
        "the game's mark of a rare near you: a notice at once, its name, Rare Elite and its level")
    local holder = RareTracker.holder
    check(holder._points[1][1] == "TOPRIGHT" and holder._points[1][2] == UIParent and holder._points[1][4] == -RareTracker.EDGE
        and holder._points[1][5] == -(220 + RareTracker.BELOW) and notice._points[1][1] == "TOPRIGHT"
        and notice._points[1][2] == holder and notice._points[1][5] == 0,
        "at the screen's right edge under the minimap, the shade's fading edge ending at the screen's")
    check(asked == 70 and notice.model._creature == 70 and notice.model._shown and not notice.icon._shown,
        "the rare's own 3D model at its left, by its creature")
    check(played[#played][1] == RareTracker.SOUNDS.horn and played[#played][2] == "Master", "and the game's war horn")
    check(notice.where:GetText():find("^%d+ m north%-west$"), "how far it is and which way: " .. tostring(notice.where:GetText()))
    W.Fire("VIGNETTES_UPDATED")
    check(#shown == 2 and shown[1].find.kind == "treasure" and shown[1].name:GetText() == "A chest" and shown[2] == notice
        and shown[1].icon._shown and shown[1]._points[1][5] == 0
        and shown[2]._points[1][5] == -(RareTracker.HEIGHT + RareTracker.GAP),
        "the chest on the minimap too: its notice over the rare's, the game's icon of its mark; the rare told once")
    check(not RareTracker.Found({ kind = "rare", thing = "npc:70", name = "A rare" }), "told again only after a while")

    -- The mouse on it: its pin's tooltip; a double click: the map pin there; a drag moves them; a right click: away
    notice._mouseOver = true
    GameTooltip._lines = nil
    notice._scripts.OnEnter(notice)
    check(GameTooltip:GetOwner() == notice and Core.LookOf(GameTooltip).creature == 70
        and GameTooltip._lines[#GameTooltip._lines] == TEXT.click, "the mouse on it: its tooltip as on the map, and what a click does")
    notice._mouseOver = false
    notice._scripts.OnLeave(notice)
    ns.Live.ClearWaypoint()
    notice._scripts.OnClick(notice, "LeftButton")
    check(ns.Live.Waypoint() == nil and #shown == 2 and notice._shown, "a click alone: nothing")
    notice._scripts.OnDoubleClick(notice, "LeftButton")
    local map, x, y = ns.Live.Waypoint()
    check(map == 1429 and near(x, 0.6) and near(y, 0.2) and #shown == 2 and notice._shown,
        "a double click: the game's map pin where it stands, the notice stays")
    holder._right, holder._top, UIParent._right = 1500, 700, 1600
    notice._scripts.OnDragStart(notice)
    notice._scripts.OnDragStop(notice)
    check(ns.store.rareTracker and ns.store.rareTracker.right == 100 and ns.store.rareTracker.top == 200
        and holder._points[1][4] == -100 and holder._points[1][5] == -200 and notice._points[1][2] == holder,
        "a drag with the left button: the notices kept where they are let go")
    ns.store.rareTracker = { right = 100, top = 600 }
    RareTracker.Found({ kind = "treasure", thing = "object:98", name = "A crate" })
    check(#shown == 3 and shown[1]._points[1][1] == "BOTTOMRIGHT" and shown[3]._points[1][5] == 2 * (RareTracker.HEIGHT
        + RareTracker.GAP), "let go in the screen's lower half: the others over the newest")
    SlashCmdList.SANEUI("testraretracker reset")
    check(ns.store.rareTracker == nil and holder._points[1][4] == -RareTracker.EDGE
        and holder._points[1][5] == -(220 + RareTracker.BELOW) and shown[3]._points[1][1] == "TOPRIGHT",
        "/sane testraretracker reset: under the minimap again")
    shown[1]._scripts.OnClick(shown[1], "RightButton")
    notice._scripts.OnClick(notice, "RightButton")
    check(#shown == 1 and not notice._shown and ns.Live.Waypoint() == 1429, "a right click: away, the map pin as it was")
    shown[1]._scripts.OnClick(shown[1], "RightButton")
    check(#shown == 0, "each away")

    -- The test command: Core's nearest rare on your map; its time, then it fades out and goes
    SlashCmdList.SANEUI("testraretracker")
    check(#shown == 1 and shown[1].find.thing == "npc:70" and shown[1].name:GetText() == "An Old Rare"
        and shown[1].find.x and RareTracker.holder._shown, "/sane testraretracker: a notice of the nearest rare of Core's data")
    W.Wait(RareTracker.FADE_IN + RareTracker.HOLD + 0.1)
    RareTracker.holder._scripts.OnUpdate(RareTracker.holder, 1)
    check(#shown == 1 and shown[1].gone, "its time up: it fades out")
    W.Wait(RareTracker.FADE_OUT + 0.1)
    RareTracker.holder._scripts.OnUpdate(RareTracker.holder, 1)
    check(#shown == 0 and not RareTracker.holder._shown, "and goes")
    SlashCmdList.SANEUI("testraretracker chest")
    check(#shown == 1 and shown[1].find.kind == "treasure" and shown[1].find.x and shown[1].what:GetText() == TEXT.treasure,
        "chest: a treasure's notice")
    RareTracker.Hide()

    -- What it tells of, its switch, an instance
    Core.Set(ns.name, "rareKinds", { rare = true })
    check(not RareTracker.Found({ kind = "treasure", thing = "object:99", name = "A box" }), "a kind not ticked: not told")
    Core.Set(ns.name, "rareKinds", { rare = true, treasure = true, event = true })
    SlashCmdList.SANEUI("testraretracker event")
    Core.Set(ns.name, "rareTracker", false)
    check(#shown == 0 and not RareTracker.Found({ kind = "treasure", thing = "object:99", name = "A box" }),
        "switched off: every notice gone, nothing told")
    Core.Set(ns.name, "rareTracker", true)
    IsInInstance = function() return true, "party" end
    check(not RareTracker.Found({ kind = "treasure", thing = "object:99", name = "A box" }), "never inside an instance")
    IsInInstance = saved.IsInInstance
    local count = #played
    Core.Set(ns.name, "rareSound", "chime")
    check(#played == count + 1 and played[#played][1] == RareTracker.SOUNDS.chime, "a sound chosen: it plays once")
    Core.Set(ns.name, "rareSound", "horn")

    -- A rare seen in person, which the game gives no mark: its nameplate
    local units = {}
    for _, name in ipairs({ "UnitExists", "UnitIsPlayer", "UnitIsDead", "UnitClassification", "UnitGUID", "UnitLevel", "UnitName" }) do
        units[name] = rawget(_G, name)
    end
    UnitExists = function(unit) return unit == "nameplate1" end
    UnitIsPlayer, UnitIsDead = function() return false end, function() return false end
    UnitClassification = function(unit) return unit == "nameplate1" and "rare" or "normal" end
    UnitGUID = function(unit) return unit == "nameplate1" and "Creature-0-1-2-3-71-0000AD" or nil end
    UnitLevel = function() return 30 end
    UnitName = function() return "Another Rare" end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    check(#shown == 1 and shown[1].find.thing == "npc:71" and shown[1].name:GetText() == "Another Rare"
        and shown[1].what:GetText() == "Rare, Level 30" and shown[1].where:GetText() == TEXT.near,
        "a rare's nameplate: told, its level as the game shows it, near you (Core's data knows no point of it)")
    for name, fn in pairs(units) do _G[name] = fn end

    UIParent._top, UIParent._right, window._bottom, window._shown, ns.Canvas.camera = top, right, windowBottom, windowShown, camera
    NPCS.Get, W.methods.SetCreature = nil, nil
    IsAltKeyDown, PlaySound, C_VignetteInfo.GetVignetteInfo = saved.IsAltKeyDown, saved.PlaySound, saved.info
    C_Spell.GetSpellInfo, C_Spell.GetSpellDescription = saved.spellInfo, saved.spellWords
end)()

-- A failure stands the module down: everything given back.
ns.StandDown("a test")
check(#ns.RareTracker.shown == 0 and not ns.RareTracker.holder._shown, "standing down: the Sane Rare tracker's notices gone")
check(ns.off and not Window.frame:IsShown() and not Hybrid.Taken() and next(overrides) == nil and minimap:GetParent() == container,
    "standing down: the window goes, the game's minimap and keys are back")
check(C_CVar.GetCVar("softTargetInteract") == "1" and C_CVar.GetCVar("Sound_EnableSFX") == "1" and not gather.overlay._shown,
    "and the interact key's settings as they were, no found herbs drawn")
check(W.stray:GetParent() == minimap and W.stray._points[1][2] == minimap and not ns.Satchel.button._shown,
    "and the other addon's button back on the game's minimap, the satchel's button gone")

check(os.execute(("lua5.1 '%s/dev/tests/navigation.lua' retail"):format(root)) == 0,
    "as a Retail client from the start the map is the game's own map tree, one map at a time")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Navigation: all %d checks passed.\n"):format(passed))
