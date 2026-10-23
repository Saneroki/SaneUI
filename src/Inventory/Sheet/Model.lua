local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Model
--  The character's model in the hero's place of the doll (Doll.lua), as the
--  game's sheet shows it (Camelot's CharacterModelScene): Blizzard's model
--  scene for the character sheet (ModelSceneUtil.SetUpCharacterSheetScene: its
--  camera, the player's actor, a shapeshift form's look) on the doll's paper,
--  no backdrop, every race at one scale (Model.SIZE: a full-grown character
--  fills its place, from under the level line down to Doll.GROUND; a gnome
--  stands as small as it is), its feet on the place's foot, hidden below the
--  foot of the hero's column (Doll.FOOT: the doll's picture drawn again over
--  it there, Sheet.lua; no clipping frame). The game's scene that takes the
--  mouse (ModelSceneMixinTemplate, its orbit camera): dragged with the left
--  button it turns, the wheel moves the camera into its head; left alone
--  for Model.REST seconds, it glides back to how it first stood. An item let
--  go over it is put on (the game's AutoEquipCursorItem), as on the game's
--  sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Model = {}
ns.Model = Model

-- The scene's size in the doll's pixels (1080p): a full-grown character (a night elf) fills its place, head to foot
-- (Saneroki, 2026-10-23). Its shape kept: the camera's scale goes with it.
Model.SIZE = { 272, 872 }
Model.REST = 10      -- seconds without a drag or a turn of the wheel before the model goes back to how it stood
-- When the scene cannot measure where it draws a point: its field of view across its diagonal, and the floor this
-- share of its height lower than that rule says (seen in the game, 2026-10-23).
Model.LOWER = 0.064

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

-- How far under the scene's middle it draws the point at that height under the camera's target, in its units: asked
-- of the scene (its projection, Transform3DPointTo2D). Its answer's units come from the target, drawn in its middle:
-- points or pixels (the same both ways), or shares of its width and height; anything else is not trusted.
local function Measured(height)
    local camera = Camera()
    if not (camera and camera.GetTarget and scene.Transform3DPointTo2D) then return nil end
    local x, y, z = camera:GetTarget()
    local midX, midY = scene:Transform3DPointTo2D(x, y, z)
    local _, at = scene:Transform3DPointTo2D(x, y, height)
    local width, tall = scene:GetSize()
    if not (midX and midY and at and midX > 0 and midY > 0 and width > 0 and tall > 0) then return nil end
    local unitX, unitY = midX * 2 / width, midY * 2 / tall
    local shares = math.abs(midX - 0.5) < 0.01 and math.abs(midY - 0.5) < 0.01
    if not shares and math.abs(unitX - unitY) > 0.05 * unitY then return nil end
    return math.abs(at - midY) / unitY
end

-- The same by the rule (Model.LOWER): the camera looks level at its target from its distance.
local function Ruled(height)
    local camera = Camera()
    if not (camera and camera.GetTarget and scene.GetCameraFieldOfView) then return nil end
    local _, _, z = camera:GetTarget()
    local distance, fov = camera:GetZoomDistance(), scene:GetCameraFieldOfView()
    if not (z and distance and fov and distance > 0 and fov > 0) then return nil end
    local width, tall = scene:GetSize()
    return (z - height) / distance * math.sqrt(width * width + tall * tall) / (2 * math.tan(fov / 2)) + tall * Model.LOWER
end

-- Every race at one scale on the scene's floor: the scene's own sizes and lifts per race taken out (its actors' sizes,
-- their scaling toward a man's, their heights). The one that gets the character's model stands it anew once loaded.
local Loaded
local function Even(actor)
    actor:SetRequestedScale(1)
    actor:SetNormalizedScaleAggressiveness(0)
    actor:SetPosition(0, 0, 0)
    actor:SetOnModelLoadedCallback(Loaded)
end

-- The zoom moves the camera into the head: its target goes with its distance (a target spline, which the game's
-- camera follows) so that, all the way in, the top of the model stands at the top of its place, under the level line.
-- A tall one's head stays about where it is and grows; a small one's comes up to it. At rest the scene draws the
-- height from the floor up to its target as `below` of its units; nearer, larger by as much as the distance shrinks.
local function Aim(floor, top, below)
    local camera, Spline = Camera(), rawget(_G, "CreateCatmullRomSpline")
    if not (camera and camera.SetTargetSpline and camera.GetMinZoomDistance and Spline and home and below) then return end
    local _, _, z = camera:GetTarget()
    local nearest = camera:GetMinZoomDistance()
    if not (z and nearest and z > floor and below > 0) then return end
    local target = top + (z - floor) * (1 - place:GetHeight() / below) * nearest / home.zoom
    local spline = Spline(3)
    spline:AddPoint(0, 0, 0)
    spline:AddPoint(0, 0, target - z)
    camera:SetTargetSpline(spline)
end

-- The scene with the character's feet on its place's foot (the bottom of its model, once loaded; else the floor),
-- centred across it; it takes the mouse only over its place. The model loaded, its zoom goes into its head.
local function Stand(actor)
    local tall, floor, top = scene:GetHeight(), 0, nil
    if actor and actor:IsLoaded() then
        local _, _, bottom, _, _, high = actor:GetActiveBoundingBox()
        local scale = actor:GetScale() or 1
        if bottom and high then floor, top = bottom * scale, high * scale end
    end
    local below = Measured(floor) or Ruled(floor)
    if top then Aim(floor, top, below) end
    local up = below and below < tall / 2 and tall / 2 - below or 0
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

Loaded = function(actor) ns.Safe("character", Stand, actor) end

-- The scene over its place (the hero's place on the doll, from under the level line down to the ground), Model.SIZE.
-- The game's scripts turn and zoom it; ours are hooked on after them.
function Model.Build(over)
    local made, frame = pcall(CreateFrame, "ModelScene", nil, over, "ModelSceneMixinTemplate")
    if not made then return ns.Report("character", "this client has no model scene for the character: " .. tostring(frame)) end
    scene, place = frame, over
    scene:SetSize(Model.SIZE[1] * Core.Journal.PX, Model.SIZE[2] * Core.Journal.PX)
    scene:EnableMouse(true)
    scene:EnableMouseWheel(true)
    Stand()
    scene:HookScript("OnMouseDown", function(self, button) ns.Safe("character", Pressed, self, button) end)
    scene:HookScript("OnMouseUp", function(self, button) ns.Safe("character", Released, self, button) end)
    scene:HookScript("OnMouseWheel", function() ns.Safe("character", Rest) end)
    scene:SetScript("OnReceiveDrag", function() ns.Safe("character", Dropped) end)
end

-- The character as it looks now (shown, and when its model changed): the game's scene for the character sheet, every
-- race at one scale, its camera as it first stands.
function Model.Refresh()
    if not scene then return end
    local util = rawget(_G, "ModelSceneUtil")
    if util and util.SetUpCharacterSheetScene then util.SetUpCharacterSheetScene(scene) end
    local camera = Camera()
    home = camera and camera.GetYaw and { yaw = camera:GetYaw(), zoom = camera:GetZoomDistance() } or nil
    local loaded
    local each, actors, first = scene:EnumerateActiveActors()
    if each then
        for actor in each, actors, first do
            Even(actor)
            if actor:IsLoaded() then loaded = actor end
        end
    end
    Stand(loaded)
end
