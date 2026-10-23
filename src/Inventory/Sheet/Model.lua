local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Model
--  The character's model in the hero's place of the doll (Doll.lua), as the
--  game's sheet shows it (Camelot's CharacterModelScene): Blizzard's model
--  scene for the character sheet (ModelSceneUtil.SetUpCharacterSheetScene: its
--  camera, the player's actor, a shapeshift form's look) on the doll's paper,
--  no backdrop, Model.LARGER times its place, its feet on the strap drawn
--  under the hero's column (the place's foot, Doll.GROUND). The game's scene
--  that takes the mouse (ModelSceneMixinTemplate, its orbit camera): dragged
--  with the left button it turns, the wheel zooms; left alone for Model.REST
--  seconds, it glides back to how it first stood. An item let go over it is
--  put on (the game's AutoEquipCursorItem), as on the game's sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Model = {}
ns.Model = Model

Model.LARGER = 1.5625 -- the scene against its place: a quarter larger, and a quarter again (Saneroki, 2026-10-23)
Model.REST = 10       -- seconds without a drag or a turn of the wheel before the model goes back to how it stood
Model.FEET = 0.08     -- where the feet stand in the scene, from its foot, when its camera cannot tell (of its height)

local TURN = 2 * math.pi
local scene, place
local home    -- how the camera first stood: { yaw, zoom }
local held    -- the left button down on the model: a drag, never rested from
local resting -- the timer that brings the model back

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Camera()
    return scene.GetActiveCamera and scene:GetActiveCamera()
end

-- Back to how the scene first stood: the camera's turn the short way round, its first distance; the game's camera
-- glides there.
local function Home()
    local camera = Camera()
    if held or not (camera and home) then return end
    local turns = math.floor((camera:GetYaw() - home.yaw) / TURN + 0.5)
    camera:SetYaw(home.yaw + turns * TURN)
    camera:SetZoomDistance(home.zoom)
end

-- The model touched: back home Model.REST seconds after the last drag or turn of the wheel.
local function Rest()
    if resting then resting:Cancel() end
    resting = C_Timer.NewTimer(Model.REST, function() ns.Safe("character", Home) end)
end

-- How far under the scene's middle its floor is drawn (height 0, where the scene's actors stand), in its units: the
-- game's camera looks level at its target from its distance, its field of view across the scene's diagonal.
local function FloorBelow()
    local camera = Camera()
    if not (camera and camera.GetTarget and scene.GetCameraFieldOfView) then return nil end
    local _, _, height = camera:GetTarget()
    local distance, fov = camera:GetZoomDistance(), scene:GetCameraFieldOfView()
    if not (height and distance and fov and distance > 0 and fov > 0) then return nil end
    local width, tall = scene:GetSize()
    return height / distance * math.sqrt(width * width + tall * tall) / (2 * math.tan(fov / 2))
end

-- The scene with its feet on its place's foot, centred across it; it takes the mouse only over its place.
local function Stand()
    local tall = scene:GetHeight()
    local below = FloorBelow()
    local up = below and below < tall / 2 and tall / 2 - below or tall * Model.FEET
    scene:ClearAllPoints()
    scene:SetPoint("BOTTOM", place, "BOTTOM", 0, -up)
    local side = (scene:GetWidth() - place:GetWidth()) / 2
    scene:SetHitRectInsets(side, side, math.max(0, tall - up - place:GetHeight()), up)
end

-- An item on the cursor let go over the model: put on where the game says it can be, as the game's sheet does
-- (CharacterModelSceneMixin: a drop, or the left button let go).
local function Dropped()
    local paperDoll = rawget(_G, "C_PaperDollInfo")
    if not (Game("CursorHasItem") and paperDoll and Core.Ask(paperDoll.CanAutoEquipCursorItem)) then return end
    Game("AutoEquipCursorItem")
end

local function Pressed(_, button)
    if button ~= "LeftButton" then return end
    held = true
    if resting then resting:Cancel() end
end

local function Released(_, button)
    if button ~= "LeftButton" then return end
    held = false
    Rest()
    Dropped()
end

-- The scene over its place (the hero's place on the doll, from under the level line down to the strap): Model.LARGER
-- times its size. The game's scripts turn and zoom it; ours are hooked on after them.
function Model.Build(over)
    local made, frame = pcall(CreateFrame, "ModelScene", nil, over, "ModelSceneMixinTemplate")
    if not made then return ns.Report("character", "this client has no model scene for the character: " .. tostring(frame)) end
    scene, place = frame, over
    local width, height = place:GetSize()
    scene:SetSize(width * Model.LARGER, height * Model.LARGER)
    scene:EnableMouse(true)
    scene:EnableMouseWheel(true)
    Stand()
    scene:HookScript("OnMouseDown", function(self, button) ns.Safe("character", Pressed, self, button) end)
    scene:HookScript("OnMouseUp", function(self, button) ns.Safe("character", Released, self, button) end)
    scene:HookScript("OnMouseWheel", function() ns.Safe("character", Rest) end)
    scene:SetScript("OnReceiveDrag", function() ns.Safe("character", Dropped) end)
end

-- The character as it looks now (shown, and when its model changed): the game's scene for the character sheet, its
-- camera as it first stands.
function Model.Refresh()
    if not scene then return end
    local util = rawget(_G, "ModelSceneUtil")
    if util and util.SetUpCharacterSheetScene then util.SetUpCharacterSheetScene(scene) end
    local camera = Camera()
    home = camera and camera.GetYaw and { yaw = camera:GetYaw(), zoom = camera:GetZoomDistance() } or nil
    Stand()
end
