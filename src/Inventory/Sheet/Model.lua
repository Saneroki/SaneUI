local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Model
--  The character's model in the hero's place of the doll (Doll.lua), as the
--  game's sheet shows it (Camelot's CharacterModelScene): Blizzard's model
--  scene for the character sheet (ModelSceneUtil.SetUpCharacterSheetScene: its
--  camera, the player's actor, a shapeshift form's look), turned and zoomed
--  with the mouse or the game's buttons over it
--  (ModelSceneControlFrameTemplate), standing on the doll's own paper and
--  stony ground, no backdrop of the game's. An item let go over it is put on
--  (the game's AutoEquipCursorItem), as on the game's sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Model = {}
ns.Model = Model

Model.CONTROLS = 4 -- the turn and zoom buttons below the place's top

local scene

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- An item on the cursor let go over the model: put on where the game says it can be, as the game's sheet does
-- (CharacterModelSceneMixin: a drop, or the left button let go).
local function Dropped()
    local paperDoll = rawget(_G, "C_PaperDollInfo")
    if not (Game("CursorHasItem") and paperDoll and Core.Ask(paperDoll.CanAutoEquipCursorItem)) then return end
    Game("AutoEquipCursorItem")
end

local function Released(_, button)
    if button == "LeftButton" then Dropped() end
end

-- The scene filling its place (the hero's place on the doll).
function Model.Build(place)
    local made, frame = pcall(CreateFrame, "ModelScene", nil, place, "PanningModelSceneMixinTemplate")
    if not made then return ns.Report("character", "this client has no model scene for the character: " .. tostring(frame)) end
    scene = frame
    scene:SetAllPoints()
    scene:HookScript("OnMouseUp", function(self, button) ns.Safe("character", Released, self, button) end)
    scene:HookScript("OnReceiveDrag", function() ns.Safe("character", Dropped) end)
    local controls = select(2, pcall(CreateFrame, "Frame", nil, scene, "ModelSceneControlFrameTemplate"))
    if type(controls) == "table" and controls.SetModelScene then
        controls:SetPoint("TOP", place, "TOP", 0, -Model.CONTROLS)
        controls:SetModelScene(scene)
        controls:Show()
    end
end

-- The character as it looks now (shown, and when its model changed): the game's scene for the character sheet.
function Model.Refresh()
    if not scene then return end
    local util = rawget(_G, "ModelSceneUtil")
    if util and util.SetUpCharacterSheetScene then util.SetUpCharacterSheetScene(scene) end
end
