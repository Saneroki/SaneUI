local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Cast
--  A unit's cast, under its plate's bar, without a gap: a bar as wide as the
--  plate's and as high as it, round at its ends like it, with a square icon
--  of the spell at its left end and the seconds left written inside the
--  icon; right of the icon, one line: the spell's name, then the name of its
--  target, cut short where the bar ends (its start always shows). Filling as
--  a cast goes on, emptying as a channel does. Its colour says whether it can
--  be interrupted: Cast.CAST (a channel Cast.CHANNEL), Cast.LOCKED where it
--  cannot. Interrupted, the bar is full in Cast.BROKEN and says so, and by
--  whom where the game names them; done or interrupted, it stays Cast.HOLD
--  seconds before it goes.
--
--  What the game says of the cast (UnitCastingInfo, UnitChannelInfo: name,
--  icon, start and end, whether it can be interrupted; UnitSpellTargetName)
--  is read when it starts and changes (the unit's UNIT_SPELLCAST_* events,
--  Plate.lua). The game may hide any of it from addons (secret values); the
--  bar takes them as they are: its fill runs from the cast's start to its
--  end (SetMinMaxValues) and is given the time now on its own OnUpdate, so
--  the game draws the progress whether we may read it or not; a cast that
--  cannot be interrupted lays a grey bar over it, seen by the game's answer
--  (SetAlphaFromBoolean). The seconds left need the end itself: where it is
--  hidden they come from the spell's cast time counted from when the cast
--  began (none for a channel), and the cast ends with the game's word that
--  it stopped. The game's own cast bar is out of sight (Plate.HIDDEN).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Cast = {}
ns.Cast = Cast

Cast.CAST = { 1, 0.72, 0.18 }    -- a cast's fill: it can be interrupted
Cast.CHANNEL = { 0.35, 0.75, 1 } -- a channel's
Cast.LOCKED = { 0.6, 0.6, 0.6 }  -- one that cannot be interrupted
Cast.BROKEN = { 1, 0.15, 0.1 }   -- an interrupted one
Cast.HOLD = 0.5                  -- seconds a cast stays after it was done or interrupted
Cast.WAIT = 1                    -- seconds past a reckoned end before a cast counts as done without the game's word
Cast.INTERRUPTED = rawget(_G, "INTERRUPTED") or "Interrupted" -- the game's word
Cast.GAP = 3                     -- between the icon and the text
-- The events of a unit's casts; each reads the cast anew (Plate.lua registers them on each plate).
Cast.EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
                "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
                "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" }
local listened = {}
for _, event in ipairs(Cast.EVENTS) do listened[event] = true end
Cast.Heard = listened

-- The fill's colours for the cast on a bar: a cast fills in its colour; a channel empties (its colour behind, the
-- dark filling from its end). A cast that cannot be interrupted is grey: the grey bar over the fill seen by the
-- game's answer, hidden or not.
local function Paint(bar)
    local cast = bar.cast
    local colour = cast.channel and Cast.CHANNEL or Cast.CAST
    local dark = ns.Bar.BACKGROUND
    for _, layer in ipairs({ bar.fill, bar.lock }) do
        layer:SetReverseFill(cast.channel)
        layer:SetMinMaxValues(cast.starts, cast.ends)
    end
    if cast.channel then
        bar.fill:SetStatusBarColor(dark[1], dark[2], dark[3])
        bar.background:SetVertexColor(colour[1], colour[2], colour[3], 1)
        bar.lock:SetStatusBarColor(dark[1], dark[2], dark[3])
        bar.lockBack:SetVertexColor(Cast.LOCKED[1], Cast.LOCKED[2], Cast.LOCKED[3], 1)
    else
        bar.fill:SetStatusBarColor(colour[1], colour[2], colour[3])
        bar.background:SetVertexColor(dark[1], dark[2], dark[3], dark[4])
        bar.lock:SetStatusBarColor(Cast.LOCKED[1], Cast.LOCKED[2], Cast.LOCKED[3])
        bar.lockBack:SetVertexColor(0, 0, 0, 0)
    end
    local locked = cast.locked
    if Core.Secret(locked) then
        if not pcall(bar.lock.SetAlphaFromBoolean, bar.lock, locked) then bar.lock:SetAlpha(0) end
    else
        bar.lock:SetAlpha(locked and 1 or 0)
    end
end

-- The bar at a moment of the cast (milliseconds, as the game counts its start and end).
local function Fill(bar, value)
    bar.fill:SetValue(value)
    bar.lock:SetValue(value)
end

-- A cast done: the bar as it ends (a cast full, a channel empty), no seconds, staying Cast.HOLD seconds.
local function Done(bar)
    local cast = bar.cast
    if not cast or cast.held then return end
    cast.held = GetTime() + Cast.HOLD
    Fill(bar, cast.ends)
    bar.timer:SetText("")
end

-- The seconds left of the cast on a bar, its fill, its timer; done when its end (known or reckoned) has passed.
local function Tick(bar)
    local cast = bar.cast
    if not cast then return bar:Hide() end
    local now = GetTime()
    if cast.held then
        if now >= cast.held then
            bar.cast = nil
            return bar:Hide()
        end
        return
    end
    Fill(bar, now * 1000)
    local ends = cast.plainEnd or cast.reckoned
    if not ends then return bar.timer:SetText("") end
    local left = ends - now
    if left <= 0 then
        -- Its end known: done; only reckoned (from the spell's cast time): wait a little for the game's word.
        if cast.plainEnd or left < -Cast.WAIT then return Done(bar) end
        return bar.timer:SetText("")
    end
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
    -- The grey of a cast that cannot be interrupted: a bar of its own over the fill, as long, seen by the game's answer.
    local lock = CreateFrame("StatusBar", nil, bar)
    lock:SetAllPoints(fill)
    lock:SetFrameLevel(fill:GetFrameLevel() + 1)
    lock:SetStatusBarTexture(ns.Bar.FILL)
    lock:SetMinMaxValues(0, 1)
    lock:SetValue(0)
    lock:SetAlpha(0)
    local lockBack = lock:CreateTexture(nil, "BACKGROUND")
    lockBack:SetTexture(ns.Bar.WHITE)
    lockBack:SetAllPoints(lock)
    bar.border, bar.fill, bar.background, bar.lock, bar.lockBack = border, fill, background, lock, lockBack
    bar.outer = ns.Bar.Caps(bar, bar, border)
    bar.caps = ns.Bar.Caps(fill, fill, fill:GetStatusBarTexture(), background, lock:GetStatusBarTexture(), lockBack)
    -- The icon at the left end, inside the border, square; the seconds left inside it.
    local top = CreateFrame("Frame", nil, bar)
    top:SetAllPoints(bar)
    top:SetFrameLevel(fill:GetFrameLevel() + 3)
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

-- The cast as the game says it now: { starts, ends (milliseconds, hidden or not), channel, locked (hidden or not),
-- plainEnd or reckoned (seconds) }, its name, icon and target; nil where the unit casts nothing. Its name, icon and
-- target go to the bar as they are.
local function Read(unit)
    local channel = false
    local ok, name, _, icon, starts, ends, _, _, locked, spell = pcall(UnitCastingInfo, unit)
    if not ok or type(name) == "nil" then -- looked at with type() only: a hidden name is never compared
        channel = true
        ok, name, _, icon, starts, ends, _, locked, spell = pcall(UnitChannelInfo, unit)
        if not ok or type(name) == "nil" then return nil end
    end
    if type(starts) == "nil" or type(ends) == "nil" then return nil end
    local cast = { starts = starts, ends = ends, channel = channel, locked = locked }
    local plainEnd = Plain(ends)
    if type(plainEnd) == "number" then
        cast.plainEnd = plainEnd / 1000
    elseif not channel then
        -- Its end hidden: the spell's cast time from now (or from its start where that may be read).
        local id = Plain(spell)
        local data = id and Core.Ask(C_Spell.GetSpellInfo, id)
        local length = type(data) == "table" and Plain(data.castTime)
        local began = Plain(starts)
        if type(length) == "number" and length > 0 then
            cast.reckoned = (type(began) == "number" and began / 1000 or GetTime()) + length / 1000
        end
    end
    local target = nil
    local shown = Core.Ask(rawget(_G, "UnitShouldDisplaySpellTargetName"), unit)
    local spellTarget = rawget(_G, "UnitSpellTargetName")
    if shown ~= false and spellTarget then target = ns.Bar.Raw(spellTarget, unit) end
    return cast, name, icon, target
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
        bar.cast.held = GetTime() + Cast.HOLD
        bar.fill:SetReverseFill(false)
        bar.fill:SetStatusBarColor(Cast.BROKEN[1], Cast.BROKEN[2], Cast.BROKEN[3])
        bar.fill:SetMinMaxValues(0, 1)
        bar.fill:SetValue(1)
        bar.lock:SetAlpha(0)
        bar.timer:SetText("")
        local who = Interrupter(Plain(interruptedBy))
        if type(who) == "nil" or not pcall(bar.text.SetFormattedText, bar.text, "%s: %s", Cast.INTERRUPTED, who) then
            bar.text:SetText(Cast.INTERRUPTED)
        end
        return
    end
    local cast, name, icon, target = Read(unit)
    Game(dress, false)
    if not cast then
        -- Over: done (stopped, its channel ended) it stays a moment; failed it goes at once; interrupted it stays red.
        if bar.cast and not bar.cast.held and event ~= "UNIT_SPELLCAST_FAILED" then return Done(bar) end
        if not (bar.cast and bar.cast.held) then
            bar.cast = nil
            bar:Hide()
        end
        return
    end
    bar.cast = cast
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
