local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Model
--  The character's model in the left pane, as the game's sheet shows it
--  (Camelot's CharacterModelScene): Blizzard's model scene for the character
--  sheet (ModelSceneUtil.SetUpCharacterSheetScene: its camera, the player's
--  actor, a shapeshift form's look), turned and zoomed with the mouse or the
--  game's buttons over it (ModelSceneControlFrameTemplate), on the race's
--  background (DressUpTexturePath, in four parts, greyed as the game greys it)
--  under the game's overlay. An item let go over it is put on (the game's
--  AutoEquipCursorItem), as on the game's sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Model = {}
ns.Model = Model

Model.CONTROLS = 40 -- the turn and zoom buttons below the left pane's top
-- The race's background in four parts, as the game cuts it: [part] = { width, height, texture coordinates }.
-- The right parts are 80 wide and the bottom ones 130 high; the top left takes the rest.
Model.RIGHT, Model.LOW = 80, 130
Model.COORDS = {
    { 0.171875, 1, 0.0392156862745098, 1 },
    { 0, 0.296875, 0.0392156862745098, 1 },
    { 0.171875, 1, 0, 0.62 },
    { 0, 0.296875, 0, 0.62 },
}

local scene, parts

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- The background's four parts on the scene, placed as the game's XML places them.
local function Background()
    parts = {}
    for index, coords in ipairs(Model.COORDS) do
        local part = scene:CreateTexture(nil, "BACKGROUND")
        part:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        parts[index] = part
    end
    local right, low = Model.RIGHT, Model.LOW
    parts[1]:SetPoint("TOPLEFT")
    parts[1]:SetPoint("BOTTOMRIGHT", -(right - 1), low - 1)
    parts[2]:SetWidth(right)
    parts[2]:SetPoint("TOPRIGHT")
    parts[2]:SetPoint("BOTTOMRIGHT", 0, low - 1)
    parts[3]:SetHeight(low)
    parts[3]:SetPoint("BOTTOMLEFT")
    parts[3]:SetPoint("BOTTOMRIGHT", -(right - 1), 0)
    parts[4]:SetSize(right, low)
    parts[4]:SetPoint("BOTTOMRIGHT")
    local overlay = scene:CreateTexture(nil, "BORDER")
    overlay:SetAtlas("UI-Character-Info-RaceBG-Overlay")
    overlay:SetAllPoints()
end

-- An item on the cursor let go over the model: put on, as the game's sheet does.
local function Dropped()
    if Game("CursorHasItem") then Game("AutoEquipCursorItem") end
end

-- The scene below the pane's top strip, filling the rest of the left pane.
function Model.Build(pane, strip)
    local made, frame = pcall(CreateFrame, "ModelScene", nil, pane, "PanningModelSceneMixinTemplate")
    if not made then return ns.Report("character", "this client has no model scene for the character: " .. tostring(frame)) end
    scene = frame
    scene:SetPoint("TOPLEFT", strip, "BOTTOMLEFT")
    scene:SetPoint("TOPRIGHT", strip, "BOTTOMRIGHT")
    scene:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT")
    Background()
    scene:HookScript("OnMouseUp", function() ns.Safe("character", Dropped) end)
    scene:HookScript("OnReceiveDrag", function() ns.Safe("character", Dropped) end)
    local controls = select(2, pcall(CreateFrame, "Frame", nil, scene, "ModelSceneControlFrameTemplate"))
    if type(controls) == "table" and controls.SetModelScene then
        controls:SetPoint("TOP", pane, "TOP", 0, -Model.CONTROLS)
        controls:SetModelScene(scene)
        controls:Show()
    end
end

-- The character as it looks now (shown, and when its model changed): the game's scene for the character
-- sheet, and its race's background.
function Model.Refresh()
    if not scene then return end
    local util = rawget(_G, "ModelSceneUtil")
    if util and util.SetUpCharacterSheetScene then util.SetUpCharacterSheetScene(scene) end
    local _, race = UnitRace("player")
    local path = race and Game("DressUpTexturePath", race)
    if not path then return end
    for index, part in ipairs(parts) do
        part:SetTexture(path .. index)
        part:SetDesaturated(true)
    end
end
