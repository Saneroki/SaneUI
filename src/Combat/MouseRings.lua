local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Mouse Rings
--  Two thin rings around the mouse, there only while they run: the inner one
--  the global cooldown, in silver, the outer one your cast, in the game's gold,
--  a channel in its green. A cast fills from the top, clockwise; a channel
--  empties, as the game's cast bar does. At rest no ring stands there.
--
--  They go around what you see, not around the point that clicks. The game's
--  cursor hangs from its tip at the top left corner of a square picture, so
--  the rings stand on the middle of what those pictures show, Rings.MIDDLE of
--  a side right of and below the tip, and the inner ring's hole holds every
--  cursor of the game whole. All of it is measured in that picture's side, in
--  the screen's real pixels: the game's Cursor Size (Accessibility), on Default
--  the display's scale, for the cursor grows with neither the UI's scale nor
--  the screen's height. Read each time the rings come out, so a change is seen
--  with nothing listening for it.
--
--  The sweep is the game's own Cooldown widget with Core's ring (Shape.RING) as
--  its swipe. The game may hide cooldowns from addons (secret values), and the
--  widget takes hidden numbers only from its own code, so the global cooldown
--  goes in as the game's duration object, whatever it hides; a cast by its
--  plain start and end, the duration object only where those are hidden.
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
Rings.INNER = 0.875                          -- the rings' outer radii, in sides: the hole in Core's ring is 0.86 of that
Rings.OUTER = 1.125
Rings.SILVER = { 0.85, 0.87, 0.9, 0.85 }
Rings.GOLD = { 1, 0.82, 0, 0.9 }             -- the game's NORMAL_FONT_COLOR
Rings.GREEN = { 0.1, 1, 0.1, 0.9 }           -- its GREEN_FONT_COLOR

local holder, cooldown, casting -- the frame that follows the mouse, and the two rings in it

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
    holder.right, holder.down = side * Rings.MIDDLE[1], side * Rings.MIDDLE[2]
    cooldown:SetSize(2 * side * Rings.INNER, 2 * side * Rings.INNER)
    casting:SetSize(2 * side * Rings.OUTER, 2 * side * Rings.OUTER)
end

local function Place()
    local x, y = GetCursorPosition()
    local scale = holder:GetEffectiveScale()
    holder:ClearAllPoints()
    holder:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + holder.right, y / scale - holder.down)
end

-- With the mouse, while a ring runs; out of sight when none does.
local function Follow()
    if cooldown:IsShown() or casting:IsShown() then return Place() end
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
    if not cast then return Stop(casting) end
    local look = cast.channel and Rings.GREEN or Rings.GOLD
    Wake()
    casting:SetSwipeColor(look[1], look[2], look[3], look[4])
    casting:SetReverse(not cast.channel)
    local starts, ends = Plain(cast.starts), Plain(cast.ends)
    if starts and ends then
        casting:SetCooldown(starts / 1000, (ends - starts) / 1000)
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

local function Ring()
    local ring = CreateFrame("Cooldown", nil, holder)
    ring:SetPoint("CENTER")
    ring:SetSwipeTexture(Core.Shape.RING)
    ring:SetDrawEdge(false)
    ring:SetDrawBling(false)
    ring:SetHideCountdownNumbers(true)
    ring:SetReverse(true)
    ring:SetScript("OnCooldownDone", OnDone)
    ring:Hide()
    return ring
end

local function Build()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetFrameStrata("TOOLTIP")
    holder:SetSize(1, 1)
    holder:Hide()
    holder:SetScript("OnEvent", OnEvent)
    holder:SetScript("OnUpdate", OnUpdate)
    cooldown, casting = Ring(), Ring()
    local silver = Rings.SILVER
    cooldown:SetSwipeColor(silver[1], silver[2], silver[3], silver[4])
    Rings.holder, Rings.cooldown, Rings.casting = holder, cooldown, casting
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
    holder:Hide()
end
