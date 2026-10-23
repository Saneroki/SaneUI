local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Cast
--  A unit's cast, under its plate's bar, without a gap: a bar as wide as the
--  plate's and as high as it, round at its ends like it, with a square icon
--  of the spell at its left end and the seconds left written inside the
--  icon; right of the icon, one line: the spell's name, then the name of its
--  target, cut short where the bar ends (its start always shows). Filling as
--  a cast goes on, emptying as a channel does. Its colour says whether it can
--  be interrupted, and whether by you now: Cast.READY while one of your
--  interrupts (Cast.KICKS) is ready and reaches the unit, else Cast.CAST (a
--  channel Cast.CHANNEL), Cast.LOCKED where it cannot be interrupted; looked
--  at again every Cast.LOOK seconds while it shows. Interrupted, the bar is
--  full in Cast.BROKEN for Cast.HOLD seconds and says so, and by whom where the
--  game names them.
--
--  What the game says of the cast (UnitCastingInfo, UnitChannelInfo: name,
--  icon, start and end, whether it can be interrupted; UnitSpellTargetName)
--  is read when it starts and changes (the unit's UNIT_SPELLCAST_* events,
--  Plate.lua). Its progress and seconds are worked out from its start and
--  end on the bar's own OnUpdate, only while it shows. Where the game hides
--  the start or end from addons (a secret value), ours stays away for that
--  cast and the game's own cast bar shows instead; otherwise the game's is
--  out of sight under ours (Plate.HIDDEN).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Cast = {}
ns.Cast = Cast

Cast.CAST = { 1, 0.72, 0.18 }    -- a cast's fill: it can be interrupted, not by you now
Cast.CHANNEL = { 0.35, 0.75, 1 } -- a channel's
Cast.READY = { 0.3, 0.9, 0.35 }  -- one you can interrupt now: an interrupt of yours ready, the unit in its reach
Cast.LOCKED = { 0.6, 0.6, 0.6 }  -- one that cannot be interrupted
Cast.BROKEN = { 1, 0.15, 0.1 }   -- an interrupted one, for a moment
Cast.HOLD = 1                    -- seconds an interrupted cast stays, in Cast.BROKEN
Cast.LOOK = 0.1                  -- seconds between looks at your interrupts while a cast shows
Cast.GLOBAL = 1.5                -- a cooldown no longer than this is the global one: the interrupt counts as ready
-- The classes' interrupts (every rank), from the game's tables: the spells classes learn that interrupt a cast.
Cast.KICKS = { 1766, 1767, 1768, 1769, 6552, 6554, 72, 1671, 1672, 2139, 8042, 8044, 8045, 8046, 10412, 10413, 10414,
               425609 }
Cast.INTERRUPTED = rawget(_G, "INTERRUPTED") or "Interrupted" -- the game's word
Cast.GAP = 3                     -- between the icon and the text
-- The events of a unit's casts; each reads the cast anew (Plate.lua registers them on each plate).
Cast.EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
                "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
                "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" }
local listened = {}
for _, event in ipairs(Cast.EVENTS) do listened[event] = true end
Cast.Heard = listened

local kicks = {} -- your interrupts: those of Cast.KICKS you know

-- Your interrupts made anew (your spells changed: Cast.Start listens).
function Cast.Learn()
    kicks = {}
    local known = rawget(_G, "IsPlayerSpell")
    for _, id in ipairs(Cast.KICKS) do
        if Core.Ask(known, id) then kicks[#kicks + 1] = id end
    end
end

-- Whether one of your interrupts is ready and reaches the unit: true, false, or nil where the game will not say (its
-- cooldowns hidden in a fight, say).
function Cast.Ready(unit)
    if #kicks == 0 then return false end
    local told = false
    for _, id in ipairs(kicks) do
        local cooldown = Core.Ask(C_Spell.GetSpellCooldown, id)
        local start = type(cooldown) == "table" and Plain(cooldown.startTime)
        local length = type(cooldown) == "table" and Plain(cooldown.duration)
        if type(start) == "number" and type(length) == "number" then
            told = true
            local ready = length <= Cast.GLOBAL or start + length <= GetTime()
            if ready and Core.Ask(C_Spell.IsSpellInRange, id, unit) ~= false then return true end
        end
    end
    if told then return false end
    return nil
end

-- The fill's colour for the cast on a bar: locked grey, else green while you can interrupt it now.
local function Paint(bar)
    local cast = bar.cast
    local colour = cast.locked and Cast.LOCKED or (bar.unit and Cast.Ready(bar.unit) and Cast.READY)
        or cast.channel and Cast.CHANNEL or Cast.CAST
    if colour ~= bar.colour then
        bar.colour = colour
        bar.fill:SetStatusBarColor(colour[1], colour[2], colour[3])
    end
end

-- The seconds left of the cast on a bar, its fill, its timer; hidden when it is over.
local function Tick(bar)
    local cast = bar.cast
    if not cast then return bar:Hide() end
    local now = GetTime()
    if cast.broken then
        if now >= cast.broken then
            bar.cast = nil
            return bar:Hide()
        end
        return
    end
    if not cast.looked or now - cast.looked >= Cast.LOOK then
        cast.looked = now
        Paint(bar)
    end
    local left = cast.ends - now
    if left <= 0 then
        bar.cast = nil
        return bar:Hide()
    end
    local length = cast.ends - cast.starts
    local done = length > 0 and (now - cast.starts) / length or 1
    bar.fill:SetValue(cast.channel and 1 - done or done)
    bar.timer:SetFormattedText(left < 10 and "%.1f" or "%.0f", left)
end
local OnUpdate = ns.Guard(function(bar) Tick(bar) end)

-- The cast bar under a plate's bar (made with the plate's dress, kept with it).
function Cast.Make(dress)
    local bar = CreateFrame("Frame", nil, dress)
    bar:SetPoint("TOPLEFT", dress, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", dress, "BOTTOMRIGHT", 0, 0)
    bar:SetFrameLevel((Plain(dress:GetFrameLevel()) or 1) + 2)
    local border = bar:CreateTexture(nil, "BACKGROUND", nil, -3)
    border:SetTexture(ns.Bar.WHITE)
    border:SetVertexColor(ns.Bar.BORDER[1], ns.Bar.BORDER[2], ns.Bar.BORDER[3], ns.Bar.BORDER[4])
    border:SetAllPoints(bar)
    local fill = CreateFrame("StatusBar", nil, bar)
    fill:SetStatusBarTexture(ns.Bar.FILL)
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(0)
    local background = fill:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(ns.Bar.WHITE)
    background:SetVertexColor(ns.Bar.BACKGROUND[1], ns.Bar.BACKGROUND[2], ns.Bar.BACKGROUND[3], ns.Bar.BACKGROUND[4])
    background:SetAllPoints(fill)
    bar.border, bar.fill = border, fill
    bar.outer = ns.Bar.Caps(bar, bar, border)
    bar.caps = ns.Bar.Caps(fill, fill, fill:GetStatusBarTexture(), background)
    -- The icon at the left end, inside the border, square; the seconds left inside it.
    local top = CreateFrame("Frame", nil, bar)
    top:SetAllPoints(bar)
    top:SetFrameLevel(fill:GetFrameLevel() + 2)
    local icon = top:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local timer = top:CreateFontString(nil, "OVERLAY")
    timer:SetPoint("CENTER", icon, "CENTER")
    local text = top:CreateFontString(nil, "OVERLAY")
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetPoint("LEFT", icon, "RIGHT", Cast.GAP, 0)
    text:SetPoint("RIGHT", bar, "RIGHT", -ns.Text.INSET, 0)
    for _, line in ipairs({ timer, text }) do
        local look = ns.Text.Font()
        if look.name then line:SetFontObject(look.name) end
        if look.file then line:SetFont(look.file, look.height, look.flags) end
        line:SetTextColor(1, 1, 1)
    end
    bar.icon, bar.timer, bar.text = icon, timer, text
    bar:SetScript("OnUpdate", OnUpdate)
    bar:Hide()
    dress.cast = bar
    Cast.Fit(dress)
end

-- Laid out for the dress's size (Plate's Fit): as high as its bar, the icon square at its left end, a pixel inside the
-- border, the caps a quarter of each height.
function Cast.Fit(dress)
    local bar = dress.cast
    if not bar then return end
    local height = Plain(dress:GetHeight()) or 0
    local edge = Core.Pixels(dress, 1)
    bar:SetHeight(height)
    local inner = math.max(height - 2 * edge, 1)
    bar.icon:ClearAllPoints()
    bar.icon:SetPoint("TOPLEFT", bar, "TOPLEFT", edge, -edge)
    bar.icon:SetSize(inner, inner)
    bar.fill:ClearAllPoints()
    bar.fill:SetPoint("TOPLEFT", bar.icon, "TOPRIGHT", 0, 0)
    bar.fill:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -edge, edge)
    ns.Bar.SizeCaps(bar.outer, height)
    ns.Bar.SizeCaps(bar.caps, inner)
end

-- The game's own cast bar on the plate seen (true: ours cannot show this cast) or out of sight under ours.
local function Game(dress, seen)
    local part = dress.frame and rawget(dress.frame, "CastBarsContainer")
    if type(part) == "table" and part.SetAlpha then part:SetAlpha(seen and 1 or 0) end
end

-- The cast as the game says it now: { starts, ends (seconds), channel, locked }, its name, icon and target; false
-- where the game hides its start or end; nil where the unit casts nothing.
local function Read(unit)
    local channel = false
    local ok, name, _, icon, starts, ends, _, _, locked = pcall(UnitCastingInfo, unit)
    if not ok or type(name) == "nil" then -- looked at with type() only: a hidden name is never compared
        channel = true
        ok, name, _, icon, starts, ends, _, locked = pcall(UnitChannelInfo, unit)
        if not ok or type(name) == "nil" then return nil end
    end
    starts, ends = Plain(starts), Plain(ends)
    if type(starts) ~= "number" or type(ends) ~= "number" then return false end
    local target = nil
    local shown = Core.Ask(rawget(_G, "UnitShouldDisplaySpellTargetName"), unit)
    local spellTarget = rawget(_G, "UnitSpellTargetName")
    if shown ~= false and spellTarget then target = ns.Bar.Raw(spellTarget, unit) end
    return { starts = starts / 1000, ends = ends / 1000, channel = channel, locked = Plain(locked) == true },
        name, icon, target
end

-- Who interrupted a cast, by the GUID the game gives: a name, or nil.
local function Interrupter(guid)
    if type(guid) ~= "string" or guid == "" then return nil end
    local token = Core.Ask(rawget(_G, "UnitTokenFromGUID"), guid)
    local name = token and ns.Bar.Raw(UnitName, token)
    if type(name) ~= "nil" then return name end
    local _, _, _, _, _, player = Core.Ask(rawget(_G, "GetPlayerInfoByGUID"), guid)
    return player
end

-- A unit's cast on its plate, as the game says it now (an event of its casts with its cast, spell and who
-- interrupted it; a plate filled anew).
function Cast.Update(dress, unit, event, _, _, interruptedBy)
    local bar = dress.cast
    if not bar then return end
    if (ns.options or {}).castBar == false or not unit then
        bar.cast = nil
        bar:Hide()
        return Game(dress, unit ~= nil)
    end
    if event == "UNIT_SPELLCAST_INTERRUPTED" and bar.cast then
        -- A moment in red, then gone.
        bar.cast.broken = GetTime() + Cast.HOLD
        bar.colour = Cast.BROKEN
        bar.fill:SetStatusBarColor(Cast.BROKEN[1], Cast.BROKEN[2], Cast.BROKEN[3])
        bar.fill:SetValue(1)
        bar.timer:SetText("")
        local who = Interrupter(Plain(interruptedBy))
        if type(who) == "nil" or not pcall(bar.text.SetFormattedText, bar.text, "%s: %s", Cast.INTERRUPTED, who) then
            bar.text:SetText(Cast.INTERRUPTED)
        end
        return
    end
    local cast, name, icon, target = Read(unit)
    if cast == false then -- hidden from addons: the game's own shows this one
        bar.cast = nil
        bar:Hide()
        return Game(dress, true)
    end
    Game(dress, false)
    if not cast then
        if not (bar.cast and bar.cast.broken) then
            bar.cast = nil
            bar:Hide()
        end
        return
    end
    bar.cast, bar.unit, bar.colour = cast, unit, nil
    Paint(bar)
    bar.icon:SetTexture(icon)
    if type(target) ~= "nil" then
        if not pcall(bar.text.SetFormattedText, bar.text, "%s  %s", name, target) then bar.text:SetText(name) end
    else
        bar.text:SetText(name)
    end
    Tick(bar)
    bar:Show()
end

function Cast.Start()
    ns.On("SPELLS_CHANGED", Core.Later(Cast.Learn))
    Cast.Learn()
end
