local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Falls
--  The fall meter, /sane falls: how far the character fell and what the
--  landing took, told in the chat after each fall. For finding out in the game
--  how high a fall the routes may take (Saneroki, 2026-11-16: "The fall damage
--  in this game is pretty low. You can fall quite far before you actually die";
--  the routes are to drop off ledges and cliffs one lands from alive). One
--  frame, looking at the character each frame while the meter is on; nothing
--  while it is off.
--
--  The game tells no height of the player (UnitPosition's is always 0), so a
--  fall's height comes from its time in the air (Falls.Height): the game's
--  gravity, Falls.GRAVITY, until its fastest fall, Falls.TERMINAL. A fall that
--  began with a jump (the jump key pressed just before it: JumpOrAscendStart,
--  watched from the first time the meter is on) has the jump's way up taken off,
--  so its height is the one below where the character stood. Slow Fall and the
--  like fall slower and give too great a height. The health it took is the most
--  the health fell from the fall's start until Falls.SETTLE after the landing
--  (the server sends the damage a moment later). A fall shallower than
--  Falls.LEAST that took nothing is not told (a slope, a step, a hop).
--
--      Falls.Toggle()                  on or off (/sane falls); off at first and after a /reload
--      Falls.Height(seconds, jumped)   the yards fallen in so many seconds in the air
--      Falls.Stop()                    off (Navigation giving back)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Falls = {}
ns.Falls = Falls

Falls.GRAVITY = 19.2911 -- yards a second a fall gets faster each second (the game's gravity)
Falls.TERMINAL = 60.148 -- yards a second at most: the game's fastest fall, after 3.1 seconds and 94 yards
Falls.JUMP = 7.9558     -- yards a second up a jump starts with (the game's): 0.41 seconds up to 1.64 yards
Falls.KEY = 0.3         -- seconds before the fall the jump key may have been pressed and the fall be a jump's
Falls.SETTLE = 0.8      -- seconds after the landing the health is still watched
Falls.LEAST = 3         -- yards: a fall shallower than this that took nothing is not told

local TEXT = {
    about = "the fall meter on or off: each fall told with its height and the health the landing took",
    on = "Fall meter on: after each fall, its height and the health the landing took. Walk or jump off: both count. /sane falls again turns it off.",
    off = "Fall meter off.",
    fall = "Fall: %.1f s in the air, %s down%s: %s.",
    jumped = " after a jump",
    nothing = "no damage",
    took = "took %d%% of your health (%d)",
    died = "it killed you",
    water = "into water",
    hidden = "the game hides your health now",
}

local frame, watching
local air, landed = nil, nil -- when the fall began, when it landed (nil: not falling, not watching a landing)
local seconds, jumped, swum  -- the fall's time in the air, whether a jump began it, whether it ended in water
local before, most, low      -- the health at its start, at most, the least since
local pressed = -math.huge   -- when the jump key was last pressed

local function Health()
    return Plain(UnitHealth("player")), Plain(UnitHealthMax("player"))
end

-- The yards fallen in so many seconds in the air: from standing (walked off an edge) by the game's gravity until its
-- fastest fall, then at that; after a jump, counted from the jump's top (its time up taken off) less its rise.
function Falls.Height(time, jump)
    local gravity, fastest, rise = Falls.GRAVITY, Falls.TERMINAL, 0
    if jump then
        time, rise = time - Falls.JUMP / gravity, Falls.JUMP * Falls.JUMP / (2 * gravity)
    end
    if time <= 0 then return 0 end
    local speeding = fastest / gravity -- seconds until the fastest fall
    local yards = time <= speeding and gravity * time * time / 2
        or fastest * speeding / 2 + fastest * (time - speeding)
    return math.max(0, yards - rise)
end

-- The fall that ended told in the chat; a shallow one that took nothing not.
local function Tell()
    local yards = Falls.Height(seconds, jumped)
    local lost = before and low and before - low
    local result
    if Plain(UnitIsDeadOrGhost("player")) == true then
        result = TEXT.died
    elseif lost and lost > 0 and most and most > 0 then
        result = TEXT.took:format(math.floor(lost / most * 100 + 0.5), lost)
    elseif yards < Falls.LEAST then
        return
    elseif swum then
        result = TEXT.water
    else
        result = lost and TEXT.nothing or TEXT.hidden
    end
    ns.Print(TEXT.fall:format(seconds, Core.Distance(yards), jumped and TEXT.jumped or "", result))
end

local function Began(now)
    air, landed = now, nil
    jumped = now - pressed <= Falls.KEY
    before, most = Health()
    low = before
end

-- Each frame while the meter is on: the character falling, landed, or the health after a landing settling.
local function Look()
    local now = GetTime()
    local falling = Plain(IsFalling()) == true
    if air or landed then
        local health = Health()
        if health and low and health < low then low = health end
    end
    if air and not falling then
        seconds, swum = now - air, Plain(IsSwimming()) == true
        air, landed = nil, now
    elseif landed and (falling or now - landed >= Falls.SETTLE) then
        landed = nil
        Tell()
        if falling then Began(now) end
    elseif not air and not landed and falling then
        Began(now)
    end
end

function Falls.Stop()
    if frame then frame:SetScript("OnUpdate", nil) end
    air, landed = nil, nil
end

function Falls.Toggle()
    if frame and frame:GetScript("OnUpdate") then
        Falls.Stop()
        return ns.Print(TEXT.off)
    end
    if not frame then
        frame = CreateFrame("Frame")
        watching = ns.Gently("fall meter", Look)
        if type(rawget(_G, "JumpOrAscendStart")) == "function" then
            hooksecurefunc("JumpOrAscendStart", ns.Gently("fall meter", function() pressed = GetTime() end))
        end
    end
    air, landed = nil, nil
    frame:SetScript("OnUpdate", watching)
    ns.Print(TEXT.on)
end

Core.Command("falls", TEXT.about, function()
    if ns.off then return ns.Print(ns.TEXT.stopped) end
    ns.Safe("fall meter", Falls.Toggle)
end, "fall")
