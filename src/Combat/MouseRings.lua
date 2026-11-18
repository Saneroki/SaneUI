local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Mouse Rings
--  Two see-through rings around the mouse, there only while they run: the
--  inner, thinner one the global cooldown, in white, the outer one your cast,
--  in your class's colour, a bright line with a soft glow leading its sweep. A
--  cast fills clockwise; a channel empties, as the game's cast bar does. At
--  rest no ring stands there.
--
--  They go around what you see, not around the point that clicks. The game's
--  cursor hangs from its tip at the top left corner of a square picture, so
--  the rings stand on the middle of what those pictures show, Rings.MIDDLE of
--  a side right of and below the tip, and the inner ring's hole holds every
--  cursor of the game whole. Both start and end on the line to the tip
--  (Rings.TURN), not straight up. All of it is measured in that picture's
--  side, in the screen's real pixels: the game's Cursor Size (Accessibility),
--  on Default the display's scale, for the cursor grows with neither the UI's
--  scale nor the screen's height. Read each time the rings come out, so a
--  change is seen with nothing listening for it.
--
--  The sweep is the game's own Cooldown widget with Core's rings (Shape.RING,
--  RING_WIDE) as its swipe. The game may hide cooldowns from addons (secret
--  values), and the widget takes hidden numbers only from its own code, so the
--  global cooldown goes in as the game's duration object, whatever it hides; a
--  cast by its plain start and end, the duration object only where those are
--  hidden. The line needs the plain numbers: on a hidden cast the ring runs
--  without it.
--
--  Nothing runs at rest: the holder that follows the mouse goes out of sight
--  when its rings are over, and its OnUpdate stops with it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Rings = {}
ns.MouseRings = Rings

-- A spell with nothing but the global cooldown, whose cooldown the game answers for every class; Forever's tables
-- have no spell of its own for it (61304), so a spell of no class on that cooldown alone.
Rings.SPELL = Core.ForGame({ forever = 29515, retail = 61304 })
Rings.LONGEST = 2                            -- seconds: longer is no global cooldown but a school locked by an interrupt
Rings.SIDES = { [0] = 32, 48, 64, 96, 128 }  -- the cursor picture's side by the game's Cursor Size (cursorSizePreferred)
Rings.MIDDLE = { 0.48, 0.47 }                -- the middle of what the cursors show: sides right of and below the tip
Rings.TURN = math.atan2(Rings.MIDDLE[1], Rings.MIDDLE[2]) -- radians from straight up to the tip, counter-clockwise
Rings.INNER = 0.875                          -- the rings' outer radii, in sides
Rings.OUTER = 1.25
Rings.HOLE = 0.81                            -- the outer ring's hole, a share of its radius (Core's RING_WIDE)
Rings.ALPHA = 0.8                            -- how solid the rings are
Rings.SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark" -- the game's: the leading line, and larger the glow around it
Rings.LINE = 0.6                             -- their sizes, shares of the outer ring's radius
Rings.GLOW = 0.9
Rings.GLOW_ALPHA = 0.5

local holder, cooldown, casting, sparks, spark, glow -- what follows the mouse, its two rings, the line and glow on a level above

-- The cursor picture's side in real pixels: the Cursor Size chosen, or on Default the largest the display's scale reaches.
local function Side()
    local chosen = Rings.SIDES[tonumber((Core.Ask(C_CVar.GetCVar, "cursorSizePreferred")))]
    if chosen then return chosen end
    local wished = Rings.SIDES[0] * (Core.Ask(rawget(_G, "GetScreenDPIScale")) or 1)
    local side = Rings.SIDES[0]
    for index = 1, #Rings.SIDES do
        if Rings.SIDES[index] <= wished then side = Rings.SIDES[index] end
    end
    return side
end

-- The rings' sizes and how far the holder stands from the tip, for the cursor as it is now.
local function Fit()
    local _, high = GetPhysicalScreenSize()
    local side = Side() * 768 / high / holder:GetEffectiveScale() -- real pixels to UI units
    local radius = side * Rings.OUTER
    holder.right, holder.down = side * Rings.MIDDLE[1], side * Rings.MIDDLE[2]
    holder.orbit = radius * (1 + Rings.HOLE) / 2 -- the middle of the outer ring's band
    cooldown:SetSize(2 * side * Rings.INNER, 2 * side * Rings.INNER)
    casting:SetSize(2 * radius, 2 * radius)
    spark:SetSize(radius * Rings.LINE, radius * Rings.LINE)
    glow:SetSize(radius * Rings.GLOW, radius * Rings.GLOW)
end

local function Place()
    local x, y = GetCursorPosition()
    local scale = holder:GetEffectiveScale()
    holder:ClearAllPoints()
    holder:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + holder.right, y / scale - holder.down)
end

local function Aim(light, x, y, turn)
    light:ClearAllPoints()
    light:SetPoint("CENTER", holder, "CENTER", x, y)
    light:SetRotation(turn)
end

-- The line and its glow at the head of the sweep, across the ring's band.
local function Lead()
    local share = casting:IsShown() and holder.span and (GetTime() - holder.from) / holder.span
    if not share or share <= 0 or share >= 1 then return sparks:Hide() end
    local angle = math.pi / 2 + Rings.TURN - share * 2 * math.pi
    local x, y = holder.orbit * math.cos(angle), holder.orbit * math.sin(angle)
    Aim(spark, x, y, angle - math.pi / 2)
    Aim(glow, x, y, angle - math.pi / 2)
    sparks:Show()
end

-- With the mouse, while a ring runs; out of sight when none does.
local function Follow()
    if cooldown:IsShown() or casting:IsShown() then
        Place()
        return Lead()
    end
    sparks:Hide()
    holder:Hide()
end

-- The holder out at the mouse, measured anew, before a ring starts in it.
local function Wake()
    if holder:IsShown() then return end
    Fit()
    Place()
    holder:Show()
end

local function Stop(ring)
    if not ring:IsShown() then return end
    ring:Clear()
    ring:Hide()
end

-- The global cooldown as the game says it now: started, running on, or over.
local function Global()
    local info = ns.options.mouseCooldown and Core.Ask(C_Spell.GetSpellCooldown, Rings.SPELL)
    local seconds = info and Plain(info.duration)
    if not info or not info.isActive or (seconds and seconds > Rings.LONGEST) then return Stop(cooldown) end
    local duration = C_Spell.GetSpellCooldownDuration(Rings.SPELL)
    if type(duration) == "nil" then return Stop(cooldown) end
    Wake()
    cooldown:SetCooldownFromDurationObject(duration)
    cooldown:Show()
end

-- A cast whose start and end are hidden, by the game's duration object where the game takes that from us.
local function Hidden(cast)
    local Duration = rawget(_G, cast.channel and "UnitChannelDuration" or "UnitCastingDuration")
    local duration = ns.UnitBar.Raw(Duration, "player")
    return type(duration) ~= "nil" and pcall(casting.SetCooldownFromDurationObject, casting, duration)
end

-- Your cast as the game says it now: started, delayed, or over.
local function Casting()
    local cast = ns.options.mouseCast and ns.UnitCast.Read("player")
    holder.span = nil
    if not cast then return Stop(casting) end
    Wake()
    casting:SetReverse(not cast.channel)
    local starts, ends = Plain(cast.starts), Plain(cast.ends)
    if starts and ends then
        holder.from, holder.span = starts / 1000, (ends - starts) / 1000
        casting:SetCooldown(holder.from, holder.span)
    elseif not Hidden(cast) then
        return Stop(casting)
    end
    casting:Show()
end

local function Heard(_, event)
    if event == "SPELL_UPDATE_COOLDOWN" then return Global() end
    Casting()
end

local function OnEvent(self, event) ns.Safe("mouse rings", Heard, self, event) end
local OnUpdate = ns.Guard(Follow)
local OnDone = ns.Guard(function(ring) ring:Hide() end)

-- Your class's colour, or white.
local function ClassColour()
    local _, class = UnitClass("player")
    local colours = rawget(_G, "RAID_CLASS_COLORS")
    local colour = class and colours and colours[class]
    if colour then return colour.r, colour.g, colour.b end
    return 1, 1, 1
end

local function Ring(art, r, g, b)
    local ring = CreateFrame("Cooldown", nil, holder, "CooldownFrameTemplate")
    ring:ClearAllPoints() -- the template fills its parent
    ring:SetPoint("CENTER")
    ring:SetSwipeTexture(art)
    ring:SetSwipeColor(r, g, b, Rings.ALPHA)
    ring:SetDrawEdge(false)
    ring:SetDrawBling(false)
    ring:SetHideCountdownNumbers(true)
    ring:SetReverse(true)
    ring:SetRotation(Rings.TURN) -- the widget turns as textures do, counter-clockwise
    ring:SetScript("OnCooldownDone", OnDone)
    ring:Hide()
    return ring
end

local function Light(sublevel, r, g, b)
    local light = sparks:CreateTexture(nil, "OVERLAY", nil, sublevel)
    light:SetTexture(Rings.SPARK)
    light:SetBlendMode("ADD")
    light:SetVertexColor(r, g, b, 1)
    return light
end

local function Build()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetFrameStrata("TOOLTIP")
    holder:SetSize(1, 1)
    holder:Hide()
    holder:SetScript("OnEvent", OnEvent)
    holder:SetScript("OnUpdate", OnUpdate)
    local r, g, b = ClassColour()
    cooldown, casting = Ring(Core.Shape.RING, 1, 1, 1), Ring(Core.Shape.RING_WIDE, r, g, b)
    sparks = CreateFrame("Frame", nil, holder)
    sparks:SetAllPoints(holder)
    sparks:SetFrameLevel(casting:GetFrameLevel() + 2)
    sparks:Hide()
    spark, glow = Light(0, r, g, b), Light(-1, r, g, b)
    glow:SetAlpha(Rings.GLOW_ALPHA)
    Rings.holder, Rings.cooldown, Rings.casting, Rings.sparks, Rings.spark, Rings.glow = holder, cooldown, casting, sparks, spark, glow
end

-- The rings as the settings say: built when first wanted, hearing only what a ring on needs.
function Rings.Apply()
    local global, cast = ns.options.mouseCooldown, ns.options.mouseCast
    if not holder then
        if not (global or cast) then return end
        Build()
    end
    holder:UnregisterAllEvents()
    if global then holder:RegisterEvent("SPELL_UPDATE_COOLDOWN") end
    if cast then
        holder:RegisterEvent("PLAYER_ENTERING_WORLD") -- a cast seen again after a loading screen
        for _, event in ipairs(ns.UnitCast.EVENTS) do pcall(holder.RegisterUnitEvent, holder, event, "player") end
    end
    Global()
    Casting()
end

-- Gone, and deaf, when the module stands down.
function Rings.Hide()
    if not holder then return end
    holder:UnregisterAllEvents()
    Stop(cooldown)
    Stop(casting)
    sparks:Hide()
    holder:Hide()
end
