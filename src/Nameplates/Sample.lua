local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Sample
--  A made-up plate for the setup (Setup.lua), drawn by the plates' own code:
--  the dress as Plate.lua makes it (Bar.Make, Text.Make, Marks.Make,
--  Cast.Make) on a frame of the setup window's, filled from a made-up unit
--  instead of one of the game's, through the same pieces a plate shows them
--  with (Text.ShowLevel, ShowName, ShowHealth ...; Bar.Border, Bar.Glow): what
--  a setting changes on the plates in the world, it changes on the sample.
--  Its auras are the game's own icons in the plates' look (Auras.Look), placed
--  as the containers place theirs and as many as the settings say; its cast
--  bar runs a made-up cast again and again; what it takes rises over it as
--  the combat text does over a plate. All of it stops while the window is
--  shut (its scripts run only while it shows).
--
--  A made-up unit, what a plate shows of it (each may be left out):
--      name, level (0: a skull) or above (its level that much over yours),
--      player = true, class = "HUNTER", hostile (you can attack it), calm (a
--      creature that does not attack on sight), rank ("boss", "elite",
--      "rare"), health, most, power = { now, most, "MANA" }, threat =
--      { kind, share } (Text.THREAT), lit ("target", "focus", "guild",
--      "party", "raid", "friend"), out (out of your reach), danger (a player
--      who may attack you), quest = { "kill", "3/8" }, gear (an item level),
--      raid (a raid marker's number), debuffs, buffs, control = { icon file,
--      ... }, cast = { icon, spell, target, time, locked }, numbers = true
--  Its scripts fail softly (ns.Gently): a sample that goes wrong never stands
--  the plates in the world down.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sample = {}
ns.Sample = Sample

Sample.WIDE = 120   -- a plate without its line (Spells only): about the game's own bar
Sample.PAUSE = 0.8  -- seconds a done cast stays full before it starts again
Sample.MOST = 2     -- the samples' scale at most (a larger Nameplate size still shows on the plates in the world)
Sample.EVERY = 0.55 -- seconds between two numbers rising over a sample
-- What rises over a sample, in turn: the words, the combat text's colour, a critical hit (larger) or a word (smaller).
Sample.NUMBERS = {
    { "347", "WHITE" }, { "1.2k", "SPELL", crit = true }, { "+120", "HEAL" }, { "86", "WHITE" },
    { (rawget(_G, "PARRY") or "Parry"), "WHITE", small = true }, { "512", "SPELL" }, { "+64", "HEAL" },
}

-- A unit's level: its own, or that much over yours (at least 1).
local function Level(spec)
    if spec.level then return spec.level end
    if not spec.above then return nil end
    local mine = Core.Ask(UnitLevel, "player")
    return math.max((type(mine) == "number" and mine or 1) + spec.above, 1)
end

-- The bar's colour for a made-up unit: a player's class colour, the calm yellow, the hostile red, a friend's green.
local function Colour(spec)
    local Bar = ns.Bar
    if spec.player and spec.class then
        local colours = rawget(_G, "RAID_CLASS_COLORS")
        local colour = colours and colours[spec.class]
        if colour then return colour.r, colour.g, colour.b end
    end
    if spec.calm then return Bar.CALM[1], Bar.CALM[2], Bar.CALM[3] end
    if spec.hostile then return Bar.HOSTILE[1], Bar.HOSTILE[2], Bar.HOSTILE[3] end
    return 0, 1, 0
end

-- One aura icon of a kind ("own", "foes", "control"), made the first time and kept.
local function Icon(dress, kind, index)
    local list = dress.icons[kind]
    local icon = list[index]
    if not icon then
        icon = CreateFrame("Frame", nil, dress)
        icon.texture, icon.swipe, icon.count = ns.Auras.Look(icon)
        list[index] = icon
    end
    return icon
end

-- A row of a kind's icons, at most that many, each placed by at(index): its texture and a swipe of time gone.
local function Row(dress, kind, files, most, at)
    local list = dress.icons[kind]
    local shown = math.min(most, #(files or {}))
    for index = 1, math.max(shown, #list) do
        local icon = index <= shown and Icon(dress, kind, index) or list[index]
        if index <= shown then
            icon.texture:SetTexture(files[index])
            icon:ClearAllPoints()
            at(icon, index)
            -- Each a little further gone than the last, so the swipes differ.
            if icon.swipe and icon.swipe.SetCooldown then
                local long = 18 + index * 6
                icon.swipe:SetCooldown(GetTime() - long * (0.2 + 0.1 * index), long)
            end
            icon.count:SetText(kind == "own" and index == 2 and "3" or "")
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- The auras around the bar as the containers stand (Auras.Make, Auras.Place) and as many as the settings say; none
-- while the plates show the health bar only.
local function Auras(dress)
    local spec, Auras = dress.spec or {}, ns.Auras
    local on = ns.Style() ~= "bar"
    local step = Auras.SIZE + Auras.GAP
    local own = on and math.min(Auras.Slots(dress:GetWidth()), Auras.Most("debuffCount")) or 0
    Row(dress, "own", spec.debuffs, own, function(icon, index)
        icon:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", (index - 1) * step, 0)
    end)
    local foes = on and spec.hostile and Auras.Most("buffCount") or 0
    Row(dress, "foes", spec.buffs, foes, function(icon, index)
        icon:SetPoint("BOTTOMRIGHT", dress, "BOTTOMLEFT", -(Auras.GAP + (dress.outside or 0)) - (index - 1) * step, 0)
    end)
    local control = on and Auras.Most("controlCount") or 0
    Row(dress, "control", spec.control, control, function(icon, index)
        icon:SetPoint("BOTTOMLEFT", dress, "BOTTOMRIGHT", Auras.GAP + (index - 1) * step, 0)
    end)
end

-- Laid out for its size, as a plate is (Plate.lua's Fit): the bar, the cast bar, the auras.
local function Fit(dress)
    ns.Bar.Fit(dress)
    ns.Cast.Fit(dress)
    Auras(dress)
end
local Fitted = ns.Gently("setup sample", Fit)

-- The made-up cast, again and again: filling over its time, the seconds left in its icon, a moment full at its end.
local function Tick(bar)
    local cast = bar.sample
    if not cast then return end
    local time = cast.time or 2
    local at = GetTime() % (time + Sample.PAUSE)
    local share = math.min(at / time, 1)
    bar.fill:SetValue(share)
    bar.lock:SetValue(share)
    if share < 1 then bar.timer:SetFormattedText("%.1f", time - at) else bar.timer:SetText("") end
end
local Ticking = ns.Gently("setup sample", Tick)

-- What it takes rising over it, as the combat text does over a plate: a number every Sample.EVERY seconds, in the
-- combat text's font and colours, rising and fading; heals only with the setting Heals on.
local function Rise(holder, elapsed)
    local CombatText = ns.CombatText
    holder.clock = holder.clock + elapsed
    holder.wait = holder.wait - elapsed
    if holder.wait <= 0 then
        holder.wait = Sample.EVERY
        local entry
        for _ = 1, #Sample.NUMBERS do
            holder.turn = holder.turn % #Sample.NUMBERS + 1
            entry = Sample.NUMBERS[holder.turn]
            if entry[2] ~= "HEAL" or (ns.options or {}).combatHeals ~= false then break end
            entry = nil
        end
        local line = entry and holder.lines[holder.turn % #holder.lines + 1]
        if line then
            local size = CombatText.HEIGHT * (entry.crit and CombatText.CRIT or entry.small and CombatText.SMALL or 1)
            line:SetFont(CombatText.FONT, size, CombatText.FLAGS)
            if not line:GetFont() then line:SetFontObject("GameFontHighlight") end -- the font not there: the game's
            local colour = CombatText[entry[2]] or CombatText.WHITE
            line:SetTextColor(colour[1], colour[2], colour[3])
            line:SetText(entry[1])
            line.born, line.lane = holder.clock, CombatText.LANES[holder.turn % #CombatText.LANES + 1]
            line:Show()
        end
    end
    for _, line in ipairs(holder.lines) do
        if line:IsShown() then
            local age = holder.clock - line.born
            if age >= CombatText.TIME then
                line:Hide()
            else
                line:ClearAllPoints()
                line:SetPoint("BOTTOM", holder, "TOP", line.lane, CombatText.ABOVE + CombatText.RISE * age / CombatText.TIME)
                line:SetAlpha(age > CombatText.TIME - CombatText.FADE and (CombatText.TIME - age) / CombatText.FADE or 1)
            end
        end
    end
end
local Rising = ns.Gently("setup sample", Rise)

local function Numbers(dress, on)
    local holder = dress.numbers
    if not on then
        if holder then holder:Hide() end
        return
    end
    if not holder then
        holder = CreateFrame("Frame", nil, dress)
        holder:SetAllPoints(dress)
        holder:SetFrameLevel((Core.Plain(dress:GetFrameLevel()) or 1) + 20)
        holder.lines, holder.clock, holder.wait, holder.turn = {}, 0, 0, 0
        for index = 1, 4 do
            local line = holder:CreateFontString(nil, "OVERLAY")
            line:Hide()
            holder.lines[index] = line
        end
        holder:SetScript("OnUpdate", Rising)
        dress.numbers = holder
    end
    holder:Show()
end

-- A sample on parent: a dress of the plates' own, out of sight until filled.
function Sample.New(parent)
    local dress = CreateFrame("Frame", nil, parent)
    dress.edge, dress.icons = 0, { own = {}, foes = {}, control = {} }
    dress:SetSize(Sample.WIDE, 16)
    ns.Bar.Make(dress)
    ns.Text.Make(dress)
    ns.Marks.Make(dress)
    ns.Cast.Make(dress)
    dress.cast:SetScript("OnUpdate", Ticking) -- the made-up cast's own clock, not a unit's
    dress:SetScript("OnSizeChanged", Fitted)
    dress:Hide()
    return dress
end

-- The cast bar running a made-up cast in the game's cast art (grey where it cannot be interrupted), or none.
local function Cast(dress, cast)
    local bar, Cast = dress.cast, ns.Cast
    if not cast or (ns.options or {}).castBar == false then
        bar.sample = nil
        bar:Hide()
        return
    end
    bar.sample = cast
    for _, layer in ipairs({ bar.fill, bar.lock }) do
        layer:SetReverseFill(false)
        layer:SetMinMaxValues(0, 1)
        layer:SetStatusBarTexture(cast.locked and Cast.ART.locked or Cast.ART.cast)
        layer:SetStatusBarColor(1, 1, 1)
    end
    bar.lock:SetAlpha(cast.locked and 1 or 0)
    bar.lockBack:Hide()
    local dark = ns.Bar.BACKGROUND
    bar.background:SetTexture(ns.Bar.WHITE)
    bar.background:SetVertexColor(dark[1], dark[2], dark[3], dark[4])
    bar.icon:SetTexture(cast.icon)
    if cast.target then bar.text:SetFormattedText("%s  %s", cast.spell, cast.target) else bar.text:SetText(cast.spell) end
    Tick(bar)
    bar:Show()
end

-- The sample filled from a made-up unit (above) as the settings in use say, at that scale (the setting Nameplate
-- size: Scale.Full, kept under Sample.MOST), and that see-through (a share, 0 solid).
function Sample.Fill(dress, spec, scale, through)
    local Text, Bar, options = ns.Text, ns.Bar, ns.options or {}
    local style = ns.Style()
    dress.spec = spec
    dress:SetScale(math.min(scale or ns.Scale.Full(), Sample.MOST))
    dress:SetAlpha(1 - (through or 0))
    dress.health:SetShown(style ~= "spells")
    dress.top:SetShown(style ~= "spells")
    dress.foot:SetShown(false)
    -- The bar: health, colour, rank, glow, power, border.
    local r, g, b = Colour(spec)
    local most = spec.most or 1000
    dress.health:SetMinMaxValues(0, most)
    dress.health:SetValue(spec.health or most)
    dress.health:SetStatusBarColor(r, g, b)
    ns.Marks.Hue(dress, r, g, b)
    dress.marks:Switch(false, false, false)
    dress.marks:Set(nil)
    dress.rank = Bar.RANKS[spec.rank] or Bar.PLAIN
    local colour = dress.rank.colour
    if colour then dress.rankLine:SetVertexColor(colour[1], colour[2], colour[3], colour[4]) end
    dress.rankLine:SetShown(colour ~= nil and style ~= "spells")
    dress.danger = spec.danger == true
    local power = dress.power
    local mana = spec.power and options.power ~= false and spec.power
    if mana then
        power:SetStatusBarColor(Bar.PowerColour(mana[3]))
        power:SetMinMaxValues(0, mana[2])
        power:SetValue(mana[1])
    end
    power:SetShown(mana and true or false)
    Bar.Border(dress, spec.lit, spec.out and options.range ~= false)
    -- The line, laid out once (Text.Layout), and the plate as wide as it wants.
    dress.holding = true
    local quest = spec.quest and options.quest ~= false and not spec.player and spec.quest or nil
    Text.ShowQuest(dress, quest and quest[1], quest and quest[2])
    Text.ShowLevel(dress, Level(spec), spec.hostile == true)
    Text.ShowGear(dress, spec.player and spec.gear or nil)
    Text.ShowName(dress, spec.name or "")
    Text.ShowThreat(dress, spec.threat and spec.threat[1], spec.threat and spec.threat[2])
    Text.ShowHealth(dress, spec.health or most, most)
    local raid = dress.raid
    if spec.raid then raid:SetSpriteSheetCell(spec.raid, 4, 4) end
    raid:SetShown(spec.raid ~= nil)
    Text.Room(dress, "raid", spec.raid and Text.size or nil)
    dress.holding = false
    Text.Layout(dress)
    dress.dot:SetShown(style == "spells" and options.dot == true and spec.raid == nil)
    dress.arrow:SetShown(style == "spells" and spec.lit == "target")
    dress:SetSize(style ~= "spells" and dress.want or Sample.WIDE, Text.Height(dress))
    Cast(dress, spec.cast)
    Fit(dress)
    Numbers(dress, spec.numbers and options.combatText ~= false)
    dress:Show()
end
