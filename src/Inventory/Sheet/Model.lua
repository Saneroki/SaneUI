local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Model
--  The character's model in the hero's place of the doll (Doll.lua), as the
--  game's sheet shows it (Camelot's CharacterModelScene): Blizzard's model
--  scene for the character sheet (ModelSceneUtil.SetUpCharacterSheetScene: its
--  camera, the player's actor, a shapeshift form's look), standing still on
--  the doll's paper: not turned, zoomed or moved (the game's scene that takes
--  no mouse, NonInteractableModelSceneMixinTemplate), no backdrop, a quarter
--  larger than the hero's place (Model.LARGER), its feet where the place's
--  foot is. An item let go over it is put on (the game's AutoEquipCursorItem),
--  as on the game's sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Model = {}
ns.Model = Model

Model.LARGER = 1.25 -- the scene against the hero's place: the model drawn this much larger

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

-- The scene over its place (the hero's place on the doll): Model.LARGER times its size, centred across it, its
-- foot at the place's foot; it takes the mouse only for an item let go over it.
function Model.Build(place)
    local made, frame = pcall(CreateFrame, "ModelScene", nil, place, "NonInteractableModelSceneMixinTemplate")
    if not made then return ns.Report("character", "this client has no model scene for the character: " .. tostring(frame)) end
    scene = frame
    local width, height = place:GetSize()
    scene:SetPoint("BOTTOM", place, "BOTTOM")
    scene:SetSize(width * Model.LARGER, height * Model.LARGER)
    scene:EnableMouse(true)
    scene:SetScript("OnMouseUp", function(self, button) ns.Safe("character", Released, self, button) end)
    scene:SetScript("OnReceiveDrag", function() ns.Safe("character", Dropped) end)
end

-- The character as it looks now (shown, and when its model changed): the game's scene for the character sheet.
function Model.Refresh()
    if not scene then return end
    local util = rawget(_G, "ModelSceneUtil")
    if util and util.SetUpCharacterSheetScene then util.SetUpCharacterSheetScene(scene) end
end
