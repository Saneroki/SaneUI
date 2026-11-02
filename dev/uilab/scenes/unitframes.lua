-- Unit frames: Core and the module Combat from their TOCs, your frame, your target's and your focus's with their casts, your timers and your pet
-- The game's frames ours stand for are not loaded in the lab: a plain frame stands in for each. A cast runs over and
-- over on you and your target, your three timers stand still, by the game's functions standing in. The module's table
-- is LabCombat in the console: LabCast("Fireball") casts, LabCast() stops; Lab.Fire("MIRROR_TIMER_STOP", "BREATH") ends
-- the breath, "EXHAUSTION" the fatigue, "FEIGNDEATH" the feign death.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
-- The game's aura container for addons is not in the lab: a plain frame with what the module asks of it, its groups laid
-- out by the game's own flow layout. As many as the module allows show on every frame: LabAuras(buffs, control, debuffs, line)
-- sets how many.
local SAMPLES = {
    buffs = { "Spell_Nature_Thorns", "Spell_Nature_Regeneration", "Spell_Holy_WordFortitude", "Spell_Holy_PowerWordShield", "Spell_Nature_Rejuvenation" },
    control = { "Spell_Nature_Polymorph", "Spell_Frost_FrostNova", "Ability_Gouge", "Spell_Nature_Slow" },
    debuffs = { "Ability_Warrior_Sunder", "Spell_Shadow_ShadowWordPain", "Spell_Nature_Slow", "Spell_Shadow_CurseOfSargeras" },
}
local showing = { buffs = 4, control = 2, debuffs = 4 }
local containers = {}
local function AuraContainer(parent)
    local box = create("Frame", nil, parent)
    local flow = AnchorUtil.CreateFlowLayout()
    function flow:GetElementSize(_, element, group)
        local width, height = element:GetSize()
        return group.elementWidth or width, group.elementHeight or height
    end
    function flow:ApplyElementLayout(container, element, anchor, x, y)
        element:ClearAllPoints()
        element:SetPoint(anchor, container, anchor, x, y)
    end
    function flow:OnLayoutComplete(container, width, height) container:SetSize(width, height) end
    box.groups, box.order = {}, {}
    function box:SetFlowLayoutAnchorPoint(corner) flow:SetAnchorPoint(corner) end
    function box:SetFlowLayoutGrowthDirection(across, up) flow:SetGrowthDirection(across, up) end
    function box:SetFlowLayoutMaximumLineSize(line) flow:SetMaximumLineSize(line) end
    function box:AddAuraGroup(key, _, options)
        self.groups[key] = { options = options, frames = {} }
        self.order[#self.order + 1] = key
    end
    function box:SetAuraGroupFilterString() end
    function box:SetAuraGroupCandidateFilters() end
    function box:SetAuraGroupEnabled() end
    function box:SetUnit(unit) self.unit = unit end
    function box:SetEnabled() end
    function box:UpdateAllAuras()
        local group = self.groups.auto
        if not (group and self.kind) then return end -- Core's marks of what can be dispelled ask for one too
        for index = 1, math.max(showing[self.kind.key], #group.frames) do
            local icon = group.frames[index]
            if not icon then
                icon = create("Button", nil, self)
                function icon:SetIcon(region) self.picture = region end
                function icon:SetDurationCooldown(cooldown) self.cooldown = cooldown end
                function icon:SetApplicationCount(count) self.count = count end
                function icon:SetSpellName() end
                group.options.initializeFrame(icon)
                group.frames[index] = icon
            end
            icon:SetShown(index <= showing[self.kind.key])
            icon.picture:SetTexture("Interface\\Icons\\" .. SAMPLES[self.kind.key][index])
            icon.cooldown:SetCooldown(GetTime() - 10 * index, 60)
        end
        local elements = {}
        for index = 1, showing[self.kind.key] do elements[index] = group.frames[index] end
        local layout = group.options.layout
        flow:Apply(self, { { elements = elements, elementSpacing = layout.elementSpacing, lineSpacing = layout.lineSpacing,
                             elementWidth = layout.elementWidth, elementHeight = layout.elementHeight } })
    end
    containers[#containers + 1] = box
    return box
end
-- line (optional): each container's widest line, to try another than the module's.
function LabAuras(buffs, control, debuffs, line)
    showing.buffs, showing.control, showing.debuffs = buffs, control, debuffs
    for _, box in ipairs(containers) do
        if line and box.kind then box:SetFlowLayoutMaximumLineSize(line) end
        box:UpdateAllAuras()
    end
end

-- The lab takes a status bar's atlas for a file: here the atlas on its fill.
CreateFrame = function(kind, name, parent, ...)
    if kind == "AuraContainer" then return AuraContainer(parent) end
    local frame = create(kind, name, parent, ...)
    local fill = frame.SetStatusBarTexture
    if kind == "StatusBar" then
        frame.SetStatusBarTexture = function(self, asset)
            local art = type(asset) == "string" and asset:find("^ui%-")
            fill(self, art and "Interface\\Buttons\\WHITE8X8" or asset)
            if art then self:GetStatusBarTexture():SetAtlas(asset) end
        end
    end
    return frame
end
RegisterUnitWatch = function(frame) frame:Show() end
UnregisterUnitWatch = function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
SecureHandlerSetFrameRef = function() end
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

local cast -- { name, icon, starts, ends }
UnitCastingInfo = function(unit)
    if cast and unit == "player" then return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, "cast-1", false, 133 end
    if cast and unit == "target" then return "Shadow Bolt", "", 136197, cast.starts, cast.ends, false, "cast-2", true, 686 end
end
UnitChannelInfo = function() end

function LabCast(name, seconds)
    local now = GetTime() * 1000
    cast = name and { name = name, icon = 135812, starts = now, ends = now + (seconds or 3) * 1000 } or nil
    Lab.Fire(cast and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_STOP", "player", "cast-1", 133)
    Lab.Fire(cast and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_STOP", "target", "cast-2", 686)
end

local timers = { { "BREATH", 42000, 60000, -1, 0, "Breath" }, { "EXHAUSTION", 25000, 60000, -1, 0, "Fatigue" },
                 { "FEIGNDEATH", 200000, 360000, -1, 0, "Feign Death" } }
GetMirrorTimerInfo = function(index)
    if timers[index] then return unpack(timers[index]) end
    return "UNKNOWN", 0, 0, 0, 0, ""
end
GetMirrorTimerProgress = function(timer)
    for _, one in ipairs(timers) do
        if one[1] == timer then return one[2] end
    end
    return 0
end

-- Your pet, with a resource of its own.
local powerType, powerMost, power, unitName, exists = UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitExists
local health, healthMost = UnitHealth, UnitHealthMax
UnitExists = function(unit) return unit == "pet" or exists(unit) end
UnitHealth = function(unit, ...) if unit == "pet" then return 800 end return health(unit, ...) end
UnitHealthMax = function(unit, ...) if unit == "pet" then return 1000 end return healthMost(unit, ...) end
UnitPowerType = function(unit) if unit == "pet" then return 2, "FOCUS" end return powerType(unit) end
UnitPowerMax = function(unit, ...) if unit == "pet" then return 100 end return powerMost(unit, ...) end
UnitPower = function(unit, ...) if unit == "pet" then return 65 end return power(unit, ...) end
UnitName = function(unit) if unit == "pet" then return "Wolf" end return unitName(unit) end

Lab.TOC("src/Core/SaneUI.toc")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
Lab.OnLogin(function()
    SaneUI.Core.Set("Combat", "unitRest", false) -- the scene is to look at: never out of sight
    for _, timer in ipairs(timers) do Lab.Fire("MIRROR_TIMER_START", unpack(timer)) end
    local function Again()
        LabCast("Fireball")
        C_Timer.After(4, Again)
    end
    Again()
end)
