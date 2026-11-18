local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Sparkles
--  Gold sparkles in the world on the herb or ore near you: the one the game
--  picks as what your interact key would use (its "soft interact" target). The
--  setting Sparkles on herbs and ore.
--
--  The game tells no addon where a thing of the world is, but it gives the
--  thing it picked a nameplate that follows it on the screen and grows and
--  shrinks with its distance. The sparkles are a frame of ours on that plate
--  (parented to it, so they follow it the same way), hanging below its bottom
--  edge, which is at the thing's top. Blizzard's plate is left as it is.
--
--  The game picks such a thing and gives it a plate only with its interact key on
--  (Options > Controls, softTargetInteract) and its plates for objects
--  (SoftTargetIconGameObject); how far it looks and in which directions are its
--  settings too. While the sparkles are on those are set as Forever's own
--  gamepad setup sets them (its Blizzard_Gamepad/Core.lua), where they reach less,
--  out of a fight; what each was is kept for the character, and put back when
--  the sparkles go off, unless it was changed since. A setting this client
--  lacks is passed over.
--
--  Without Core's herbs and ore (Nodes.Known: Retail, until its data comes) no
--  herb or ore can be told by its name: the sparkles stand down, the game's
--  settings are left as they are and the switch is not on the options page.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Nodes = ns.Nodes
local Sparkles = {}
ns.Sparkles = Sparkles

local ANY = Enum and Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
-- What the sparkles need of the game's settings: each its value, and whether a higher number is as good.
local SETTINGS = {
    { "softTargetInteract", tostring(ANY) },
    { "SoftTargetIconGameObject", "1" },
    { "SoftTargetInteractRange", "20", more = true },
    { "SoftTargetInteractArc", "1", more = true },
}
local WAIT = "navigation: sparkles" -- what waits for the fight's end
local UNIT = "softinteract"

Sparkles.COUNT = 7       -- sparkles at once
Sparkles.AREA = 56       -- the side of the area they twinkle in, at the plate's scale
Sparkles.DROP = 22       -- how far below the plate's bottom edge the area's middle is
Sparkles.SIZES = { 10, 20 } -- a sparkle's side, from and to
Sparkles.TIMES = { 0.7, 1.3 } -- the seconds of one twinkle, from and to
local STAR = "Interface\\Cooldown\\star4" -- the game's four-pointed star
local GOLD = { 1, 0.82, 0 } -- the game's gold (NORMAL_FONT_COLOR)

local frame, plate -- our frame, and the plate it is on now

local function Between(range)
    return range[1] + math.random() * (range[2] - range[1])
end

-- A sparkle somewhere else in the area, at another size, after each twinkle.
local function Move(star)
    local half, side = Sparkles.AREA / 2, Between(Sparkles.SIZES)
    star:SetSize(side, side)
    star:ClearAllPoints()
    star:SetPoint("CENTER", frame, "CENTER", (math.random() * 2 - 1) * half, (math.random() * 2 - 1) * half)
end

local function Twinkled(group)
    Move(group:GetParent())
end

-- One sparkle: the star in gold, light added to what is behind it; it grows in as it brightens and fades out.
local function Star(moved)
    local star = frame:CreateTexture(nil, "OVERLAY")
    star:SetTexture(STAR)
    star:SetBlendMode("ADD")
    star:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    star:SetAlpha(0)
    local group = star:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local time = Between(Sparkles.TIMES)
    local bright = group:CreateAnimation("Alpha")
    bright:SetFromAlpha(0)
    bright:SetToAlpha(1)
    bright:SetDuration(time * 0.4)
    bright:SetOrder(1)
    local grow = group:CreateAnimation("Scale")
    grow:SetScaleFrom(0.3, 0.3)
    grow:SetScaleTo(1, 1)
    grow:SetDuration(time * 0.4)
    grow:SetOrder(1)
    local fade = group:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(time * 0.6)
    fade:SetOrder(2)
    group:SetScript("OnLoop", moved)
    star.group = group
    return star
end

local function Build()
    frame = CreateFrame("Frame")
    frame:SetSize(Sparkles.AREA, Sparkles.AREA)
    frame:Hide()
    frame.stars = {}
    local moved = ns.Guard(Twinkled)
    for index = 1, Sparkles.COUNT do frame.stars[index] = Star(moved) end
end

local function Off()
    if not frame or not plate then return end
    for _, star in ipairs(frame.stars) do star.group:Stop() end
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(nil)
    plate = nil
end

local function On(target)
    if plate == target then return end
    if not frame then Build() end
    Off()
    plate = target
    frame:SetParent(target)
    frame:SetPoint("CENTER", target, "BOTTOM", 0, -Sparkles.DROP)
    frame:Show()
    for index, star in ipairs(frame.stars) do
        Move(star)
        -- Each one later than the last, so they do not twinkle together.
        star.group:Play(false, -(index - 1) * Sparkles.TIMES[2] / Sparkles.COUNT)
    end
end

-- The plate of the thing the game picked, if that is a herb or ore and its plate can be ours to hang on.
local function Target()
    if not ns.options.nodeSparkles or ns.off then return nil end
    if not Core.Ask(rawget(_G, "UnitIsGameObject"), UNIT) then return nil end
    local node = Nodes.Find(Core.Plain(Core.Ask(UnitName, UNIT)))
    local plates = rawget(_G, "C_NamePlate")
    if not node or not plates then return nil end
    local found = Core.Ask(plates.GetNamePlateForUnit, UNIT)
    if not found or (found.IsForbidden and found:IsForbidden()) then return nil end
    return found
end

local function Update()
    local target = Target()
    if target then On(target) else Off() end
end
local updating = Core.Later(function() ns.Guarded(Update) end)

-------------------------------------------------------------------------------
--  The game's settings
-------------------------------------------------------------------------------
local function Same(a, b)
    return a == b or (tonumber(a) ~= nil and tonumber(a) == tonumber(b))
end

-- Each setting as the sparkles need it, what it was kept (the first time only).
local function Set(kept)
    for _, setting in ipairs(SETTINGS) do
        local name, value = setting[1], setting[2]
        local now = Core.Plain(Core.Ask(C_CVar.GetCVar, name))
        local enough = now and (Same(now, value) or (setting.more and tonumber(now) and tonumber(now) > tonumber(value)))
        if now and not enough then
            Core.Ask(C_CVar.SetCVar, name, value)
            if Same(Core.Plain(Core.Ask(C_CVar.GetCVar, name)), value) and not kept[name] then
                kept[name] = { was = now, set = value }
            end
        end
    end
end

-- Each kept setting back as it was, unless it was changed since the sparkles set it.
local function PutBack(kept)
    for name, entry in pairs(kept) do
        if type(entry) == "table" and Same(Core.Plain(Core.Ask(C_CVar.GetCVar, name)), entry.set) then
            Core.Ask(C_CVar.SetCVar, name, entry.was)
        end
        kept[name] = nil
    end
end

-- The settings as the switch says, out of a fight.
function Sparkles.Settings()
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Sparkles.Settings) end
    local character = Core.Character(ns.name)
    if type(character.interact) ~= "table" then character.interact = {} end
    if ns.options.nodeSparkles and not ns.off and Nodes.Known() then
        Set(character.interact)
    else
        PutBack(character.interact)
    end
    updating()
end

function Sparkles.Start()
    ns.On("PLAYER_SOFT_INTERACT_CHANGED", updating)
    ns.On("NAME_PLATE_UNIT_ADDED", updating)
    -- At once: the plate goes to another unit next.
    ns.On("NAME_PLATE_UNIT_REMOVED", Update)
    -- After the game's settings came in for the character (Sync may write them at login too).
    Core.Later(function() ns.Guarded(Sparkles.Settings) end, 5)()
end

-- The module stood down: no sparkles, the game's settings as they were.
function Sparkles.GiveBack()
    Off()
    Sparkles.Settings()
end
