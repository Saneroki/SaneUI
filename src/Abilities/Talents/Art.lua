local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Talents - Art
--  What our talent trees stand on, as the game's class talents frame draws it
--  (Camelot: ClassTalents/Blizzard_ClassTalentsFrame.xml, ClassTalentsFrame-
--  Template's layers and animations; the class's art from Camelot's
--  ClassTalentUtil.lua, SpecializationVisuals and ClassVisuals):
--    - the game's stone (Talents-Background-c60), 701 high, along the frame's
--      foot, and over it your class's picture (talent-background-<class>) with
--      its two lights coming and going, the clouds drifting over it, the dust
--      in the air, all in the game's masks, timings and alphas
--    - the game's frame round the picture (Talents-inner-frame-c60) and its
--      dividers between the three trees
--    - the flash of the game's class light (talents-animations-class-<class>,
--      the grid burst, the titans' glow) when a change is applied
--  Each class has one picture in this client, named after the class, as the
--  game's tables name it; a picture or light the client lacks is left out.
--  The drifting and the lights run while the window is shown, and not at all
--  with Sane UI's animations switched off.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Class = Talents.Class
local Art = {}
ns.TalentsArt = Art

-- The game's places (ClassTalentsFrameTemplate): the class picture inside the stone (from its top, from its foot),
-- the frame round it, the dividers, the class light; the stone's height.
Art.STONE = 701
Art.PICTURE_TOP, Art.PICTURE_FOOT = -70, 36
Art.BORDER = { -2, 4, 2, -4 }
Art.DIVIDER_TOP = -4
Art.UPRIGHT = { 95, -60 }
Art.TITANS = { 100, -18 }
Art.BURST = 320
Art.FAR = { 800, 473 }
Art.CLOUDS = 1612 -- how far the clouds drift, in each loop
-- The game's pan offset of the trees (basePanOffsetX/Y, 49 and 24), less its class offset (ClassVisuals: 60 and
-- 31, the same for every class in this client).
Art.PAN = { 49 - 60, 24 - 31 }

-- The animations that run while the window is shown (backgroundAnims): [texture's key] = its steps, each
-- { kind, order, ... } as the game's XML has them.
Art.LOOPS = {
    Clouds1 = { { "Translation", 1, x = 0 }, { "Translation", 2, x = -Art.CLOUDS, duration = 80 }, { "Translation", 3, x = Art.CLOUDS } },
    Clouds2 = { { "Translation", 1, x = Art.CLOUDS }, { "Translation", 2, x = -Art.CLOUDS, duration = 80 }, { "Translation", 3, x = Art.CLOUDS } },
    AirParticlesClose = {
        { "Alpha", 2, from = 0, to = 0.15, duration = 5 }, { "Alpha", 2, from = 0.15, to = 0, delay = 22, duration = 5 },
        { "Translation", 1, x = 300 }, { "Translation", 2, x = -600, duration = 27 }, { "Translation", 3, x = 600 },
        { "Rotation", 2, degrees = 20, duration = 27 },
    },
    AirParticlesFar = {
        { "Alpha", 2, from = 0, to = 0.14, duration = 5 }, { "Alpha", 2, from = 0.14, to = 0, delay = 31, duration = 5 },
        { "Translation", 1, x = 100 }, { "Translation", 2, x = -200, duration = 36 }, { "Translation", 3, x = 200 },
        { "Rotation", 2, degrees = -20, duration = 36 },
    },
    OverlayBackgroundRight = {
        { "Alpha", 1, from = 0, to = 0, duration = 5 }, { "Alpha", 2, from = 0, to = 0.7, duration = 5 },
        { "Alpha", 2, from = 0.7, to = 0, delay = 5, duration = 5 }, { "Alpha", 3, from = 0, to = 0, duration = 5 },
        { "Alpha", 4, from = 0, to = 0.2, duration = 5 }, { "Alpha", 4, from = 0.2, to = 0, delay = 5, duration = 5 },
    },
    OverlayBackgroundMid = {
        { "Alpha", 1, from = 0, to = 0, duration = 5 }, { "Alpha", 2, from = 0, to = 0.7, duration = 5 },
        { "Alpha", 2, from = 0.7, to = 0, delay = 5, duration = 5 }, { "Alpha", 3, from = 0, to = 0, duration = 5 },
        { "Alpha", 4, from = 0, to = 0.3, duration = 5 }, { "Alpha", 4, from = 0.3, to = 0, delay = 5, duration = 5 },
    },
}
-- The flash when a change is applied (commitFlashAnims), each step as above.
Art.FLASH = {
    ActivationExpandFx = { { "Scale", 1, from = 1, to = 20, duration = 1.4, smoothing = "IN" },
                           { "Alpha", 1, from = 0.65, to = 0, duration = 1.4, smoothing = "IN" } },
    ActivationClassFx = { { "Alpha", 1, from = 1, to = 0, duration = 1.2, smoothing = "OUT" } },
    ActivationClassFx2 = { { "Alpha", 1, from = 1, to = 0, duration = 1.2, smoothing = "OUT" } },
    ActivationClassFx3 = { { "Alpha", 1, from = 0.3, to = 0, duration = 0.3, smoothing = "OUT" },
                           { "Scale", 1, from = 1, to = 1.5, duration = 0.3 } },
    ActivationClassFx4 = { { "Alpha", 1, from = 0.2, to = 0, duration = 0.5, smoothing = "OUT" },
                           { "Scale", 1, from = 1, to = 1.5, duration = 0.5 } },
    ActivationTitansFX = { { "Alpha", 1, from = 0.7, to = 0, duration = 1, smoothing = "IN" },
                           { "Scale", 1, from = 1.3, to = 1.2, duration = 2 } },
}

local CLAMP = "CLAMPTOBLACKADDITIVE"
local loops = {}        -- [frame] = its running animations, each { group, targets }
local flashes = {}      -- [frame] = the flash: { group, targets }
local textures = {}     -- [frame] = { key = texture }: the art by the game's keys

local function Atlas(name)
    local textureInfo = rawget(_G, "C_Texture")
    return type(name) == "string" and textureInfo and textureInfo.GetAtlasInfo and Core.Ask(textureInfo.GetAtlasInfo, name) ~= nil
end

-- The player's class, as the game names its art ("mage", "warrior").
local function ClassName()
    local _, class = UnitClass("player")
    return type(class) == "string" and class:lower() or nil
end

-- A texture of the game's kind: its layer, atlas (at its own size or not), blending and alpha; free of the pixel grid
-- where the game's moving art is.
local function Texture(frame, level, sublevel, atlas, own, blend, alpha, drifting)
    local texture = frame:CreateTexture(nil, level, nil, sublevel)
    if atlas then texture:SetAtlas(atlas, own) end
    if blend then texture:SetBlendMode(blend) end
    if alpha then texture:SetAlpha(alpha) end
    if drifting then
        texture:SetTexelSnappingBias(0)
        texture:SetSnapToPixelGrid(false)
    end
    return texture
end

local function Mask(frame, atlas, ...)
    local mask = frame:CreateMaskTexture(nil, "BACKGROUND")
    mask:SetAtlas(atlas, false, nil, nil, CLAMP, CLAMP)
    for index = 1, select("#", ...) do select(index, ...):AddMaskTexture(mask) end
    return mask
end

local function Cover(region, over)
    region:SetPoint("TOPLEFT", over, "TOPLEFT")
    region:SetPoint("BOTTOMRIGHT", over, "BOTTOMRIGHT")
end

-- An animation group of the game's steps on these textures; the textures shown only while it plays (the game's
-- TargetsVisibleWhilePlayingAnimGroupTemplate).
local function Group(frame, art, steps, looping)
    local group = frame:CreateAnimationGroup()
    if looping then group:SetLooping("REPEAT") else group:SetToFinalAlpha(true) end
    local targets = {}
    for key, list in pairs(steps) do
        local target = art[key]
        if target then
            targets[#targets + 1] = target
            target:Hide()
            for _, step in ipairs(list) do
                local animation = group:CreateAnimation(step[1])
                animation:SetTarget(target)
                animation:SetOrder(step[2])
                animation:SetDuration(step.duration or 0)
                if step.delay then animation:SetStartDelay(step.delay) end
                if step.smoothing then animation:SetSmoothing(step.smoothing) end
                if step[1] == "Translation" then
                    animation:SetOffset(step.x or 0, step.y or 0)
                elseif step[1] == "Alpha" then
                    animation:SetFromAlpha(step.from)
                    animation:SetToAlpha(step.to)
                elseif step[1] == "Rotation" then
                    animation:SetDegrees(step.degrees)
                elseif step[1] == "Scale" then
                    animation:SetScaleFrom(step.from, step.from)
                    animation:SetScaleTo(step.to, step.to)
                end
            end
        end
    end
    return { group = group, targets = targets }
end

local function Shown(entry, on)
    for _, target in ipairs(entry.targets) do target:SetShown(on) end
end

-------------------------------------------------------------------------------
--  Made with the frame (Tree.lua)
-------------------------------------------------------------------------------
function Art.Build(frame)
    local art = {}
    textures[frame] = art
    local stone = Texture(frame, "BACKGROUND", 0, "Talents-Background-c60", false)
    stone:SetHorizTile(true)
    stone:SetHeight(Art.STONE)
    stone:SetPoint("BOTTOMLEFT")
    stone:SetPoint("BOTTOMRIGHT")
    frame.Background = stone

    -- Your class's picture, and its two lights, each in the game's mask.
    local picture = Texture(frame, "BACKGROUND", 1, nil)
    picture:SetPoint("TOPLEFT", stone, "TOPLEFT", 0, Art.PICTURE_TOP)
    picture:SetPoint("BOTTOMRIGHT", stone, "BOTTOMRIGHT", 0, Art.PICTURE_FOOT)
    frame.ClassBackground = picture
    art.ClassBackground = picture
    for _, key in ipairs({ "OverlayBackgroundRight", "OverlayBackgroundMid" }) do
        local light = Texture(frame, "BACKGROUND", 1, nil, false, "ADD", 0)
        Cover(light, picture)
        art[key] = light
    end
    Cover(Mask(frame, "talents-animations-mask-specart", art.OverlayBackgroundRight), picture)
    Cover(Mask(frame, "talents-animations-mask-specart-mid", art.OverlayBackgroundMid), picture)

    -- The clouds and the dust drifting over it.
    for _, key in ipairs({ "Clouds1", "Clouds2" }) do
        local cloud = Texture(frame, "BACKGROUND", 2, "talents-animations-clouds", true, "ADD", 0.05, true)
        cloud:SetPoint("TOPLEFT", picture, "TOPLEFT")
        art[key] = cloud
    end
    art.AirParticlesClose = Texture(frame, "BACKGROUND", 2, "talents-animations-particles", true, "ADD", 0, true)
    art.AirParticlesClose:SetPoint("CENTER", picture, "CENTER")
    art.AirParticlesFar = Texture(frame, "BACKGROUND", 2, "talents-animations-particles", false, "ADD", 0, true)
    art.AirParticlesFar:SetSize(Art.FAR[1], Art.FAR[2])
    art.AirParticlesFar:SetTexCoord(1, 0, 1, 0)
    art.AirParticlesFar:SetPoint("CENTER", picture, "CENTER")

    -- The class light that flashes when a change is applied.
    art.ActivationExpandFx = Texture(frame, "BACKGROUND", 3, "talents-animations-gridburst", false, "ADD", 0, true)
    art.ActivationExpandFx:SetSize(Art.BURST, Art.BURST)
    art.ActivationExpandFx:SetPoint("CENTER", picture, "CENTER")
    local filigree = Mask(frame, "talents-animations-mask-filigree-activate", art.ActivationExpandFx)
    filigree:SetAtlas("talents-animations-mask-filigree-activate", true, nil, nil, CLAMP, CLAMP)
    filigree:SetPoint("TOPLEFT", picture, "TOPLEFT")
    local classes = {}
    for index, key in ipairs({ "ActivationClassFx", "ActivationClassFx2", "ActivationClassFx3", "ActivationClassFx4" }) do
        local light = Texture(frame, "BACKGROUND", 3, nil, true, "ADD", 0, true)
        light:SetPoint("CENTER", index == 1 and picture or art.ActivationClassFx, "CENTER")
        art[key], classes[index] = light, light
    end
    art.classes = classes
    art.ActivationTitansFX = Texture(frame, "BACKGROUND", 3, "talents-animations-titans", true, "ADD", 0)
    art.ActivationTitansFX:SetPoint("CENTER", picture, "CENTER", Art.TITANS[1], Art.TITANS[2])
    Cover(Mask(frame, "talents-animations-mask-full", art.Clouds1, art.Clouds2, art.AirParticlesClose, art.AirParticlesFar,
        art.ActivationTitansFX, art.ActivationExpandFx, art.ActivationClassFx3, art.ActivationClassFx4), picture)

    -- The game's frame round the picture, and the dividers between the trees.
    local border = Texture(frame, "OVERLAY", 0, "Talents-inner-frame-c60", false)
    border:SetPoint("TOPLEFT", picture, "TOPLEFT", Art.BORDER[1], Art.BORDER[2])
    border:SetPoint("BOTTOMRIGHT", picture, "BOTTOMRIGHT", Art.BORDER[3], Art.BORDER[4])
    frame.BackgroundBorder = border
    local left = Texture(frame, "OVERLAY", 0, "Talents-divider-left-c60", true)
    left:SetPoint("TOPRIGHT", border, "TOP", 0, Art.DIVIDER_TOP)
    local right = Texture(frame, "OVERLAY", 0, "Talents-divider-right-c60", true)
    right:SetPoint("TOPLEFT", border, "TOP", 0, Art.DIVIDER_TOP)
    local leftUpright = Texture(frame, "OVERLAY", 0, "Talents-divider-vertical-c60", true)
    leftUpright:SetPoint("TOP", left, "CENTER", Art.UPRIGHT[1], Art.UPRIGHT[2])
    local rightUpright = Texture(frame, "OVERLAY", 0, "Talents-divider-vertical-c60", true)
    rightUpright:SetPoint("TOP", right, "CENTER", -Art.UPRIGHT[1], Art.UPRIGHT[2])

    -- Each drifting texture in a loop of its own, as the game's: their loops are of different lengths.
    local running = {}
    for key, steps in pairs(Art.LOOPS) do running[#running + 1] = Group(frame, art, { [key] = steps }, true) end
    loops[frame] = running
    local flash = Group(frame, art, Art.FLASH, false)
    flash.group:SetScript("OnFinished", ns.Guard(function() Shown(flash, false) end))
    flashes[frame] = flash
end

-------------------------------------------------------------------------------
--  The frame's methods (ClassTalentsFrameMixin's)
-------------------------------------------------------------------------------
-- The class's light and the trees' place: the same offset for every class in this client.
function Class:UpdateClassVisuals()
    local art, class = textures[self], ClassName()
    local light = class and "talents-animations-class-" .. class
    if art and Atlas(light) then
        for _, texture in ipairs(art.classes) do texture:SetAtlas(light, true) end
    end
    self:SetBasePanOffset(Art.PAN[1], Art.PAN[2])
    self:UpdateAllTalentButtonPositions()
    self:UpdateSpecBackground()
end

-- Your class's picture, its lights and the flash the game's frame shows when a change is applied.
function Class:UpdateSpecBackground()
    local art, class = textures[self], ClassName()
    local picture = class and "talent-background-" .. class
    if not (art and Atlas(picture)) then return end
    for _, key in ipairs({ "ClassBackground", "OverlayBackgroundRight", "OverlayBackgroundMid" }) do
        art[key]:SetAtlas(picture, false)
    end
    if self.BackgroundFlash then self.BackgroundFlash:SetAtlas(picture, false) end
end

function Class:SetBackgroundAnimationsPlaying(playing)
    playing = playing and not (Core.general and Core.general.animations == false)
    for _, entry in ipairs(loops[self] or {}) do
        Shown(entry, playing)
        if playing then entry.group:Play() else entry.group:Stop() end
    end
end

-- The flash of the class's light, played when a change is applied (and stopped).
function Art.Flash(frame, on)
    local entry = flashes[frame]
    if not entry then return end
    if on then
        Shown(entry, true)
        entry.group:Stop()
        entry.group:Play()
    else
        entry.group:Stop()
        Shown(entry, false)
    end
end
