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
--      ... }, cast = { icon, spell, target, time, locked }, numbers = true,
--      barrier and lost (shares of the bar), dispel ("Magic", "Curse",
--      "Disease", "Poison"), combo (your combo points on it)
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

-- The bar's colour for a made-up unit, as Bar.Colour has it: a player's class colour (with the setting Class colours
-- on; off, a foe red, a friend blue), the calm yellow, the hostile red, a friend's green.
local function Colour(spec)
    local Bar = ns.Bar
    if spec.player and (ns.options or {}).classColour == false then
        local colour = spec.hostile and Bar.HOSTILE or Bar.FRIENDLY
        return colour[1], colour[2], colour[3]
    end
    if spec.player and spec.class then
        local colours = rawget(_G, "RAID_CLASS_COLORS")
        local colour = colours and colours[spec.class]
        if colour then return colour.r, colour.g, colour.b end
    end
    if spec.calm then return Bar.CALM[1], Bar.CALM[2], Bar.CALM[3] end
    if spec.hostile then return Bar.HOSTILE[1], Bar.HOSTILE[2], Bar.HOSTILE[3] end
    return 0, 1, 0
end

-- The seconds left of the samples' auras, in turn: some over a minute, which show no number (Auras.LONG).
Sample.TIMES = { 12, 7, 45, 95, 3, 28, 300, 9, 52, 16, 600, 4 }

-- One aura icon of a kind ("own", "foes", "control"), made the first time and kept.
local function Icon(dress, kind, index)
    local list = dress.icons[kind]
    local icon = list[index]
    if not icon then
        icon = CreateFrame("Frame", nil, dress)
        icon.texture, icon.swipe, icon.count, icon.timer = ns.Auras.Look(icon)
        if icon.swipe.SetHideCountdownNumbers then icon.swipe:SetHideCountdownNumbers(true) end -- ours below
        list[index] = icon
    end
    return icon
end

-- The seconds left in a sample's icon as the plates show them: none over a minute, as large and see-through as the
-- settings say, none with Time left in the icons off.
local function Seconds(icon, seconds)
    local options, timer = ns.options or {}, icon.timer
    local shown = options.duration ~= false and seconds <= ns.Auras.LONG
    local file = rawget(_G, ns.Auras.NUMBER)
    file = type(file) == "table" and file.GetFont and file:GetFont()
    timer:SetFont(type(file) == "string" and file or "Fonts\\ARIALN.TTF",
        math.max(ns.Auras.SIZE * (tonumber(options.durationSize) or 50) / 100, 4), "OUTLINE")
    timer:SetText(shown and tostring(seconds) or "")
    timer:SetTextColor(1, 1, 1)
    timer:SetAlpha(1 - (tonumber(options.durationTransparency) or 0) / 100)
    timer:SetShown(shown)
end

-- A row of a kind's icons, at most that many, at their size (scale over Auras.SIZE), each placed by at(index): its
-- texture, a swipe of time gone, the seconds left.
local function Row(dress, kind, files, most, scale, at)
    local list = dress.icons[kind]
    local shown = math.min(most, #(files or {}))
    for index = 1, math.max(shown, #list) do
        local icon = index <= shown and Icon(dress, kind, index) or list[index]
        if index <= shown then
            icon.texture:SetTexture(files[index])
            icon:SetScale(scale)
            icon:ClearAllPoints()
            at(icon, index)
            local seconds = Sample.TIMES[(index + #kind) % #Sample.TIMES + 1]
            if icon.swipe and icon.swipe.SetCooldown then
                local long = math.max(seconds * 1.6, 10)
                icon.swipe:SetCooldown(GetTime() - (long - seconds), long)
            end
            Seconds(icon, seconds)
            icon.count:SetText(kind == "own" and index == 2 and "3" or "")
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- The auras around the bar as the containers stand (Auras.Place): each kind at its side, a row further out for each
-- kind before it there, at the setting's size, as many as the settings say (above the bar no more than fit over it);
-- none while the plates show the health bar only.
local function Auras(dress)
    local spec, Auras = dress.spec or {}, ns.Auras
    local on = ns.Style() ~= "bar"
    local size = Auras.Size(dress:GetHeight())
    local scale, step = size / Auras.SIZE, size + Auras.GAP
    local rows = { above = 0, left = 0, right = 0 }
    for _, kind in ipairs(Auras.KINDS) do
        local place = Auras.Where(kind)
        local out = rows[place]
        local most = Auras.Most(kind.count)
        if on and most > 0 then rows[place] = out + 1 end
        if place == "above" then most = math.min(most, Auras.Slots(dress:GetWidth(), size)) end
        if not on or (kind.key == "foes" and not spec.hostile) then most = 0 end
        local up = out * step
        Row(dress, kind.key, spec[kind.key == "own" and "debuffs" or kind.key == "foes" and "buffs" or "control"], most,
            scale, function(icon, index)
                local along = (index - 1) * step
                if place == "above" then
                    icon:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", along / scale, up / scale)
                elseif place == "left" then
                    icon:SetPoint("BOTTOMRIGHT", dress, "BOTTOMLEFT", -(Auras.GAP + along) / scale, up / scale)
                else
                    icon:SetPoint("BOTTOMLEFT", dress, "BOTTOMRIGHT", (Auras.GAP + along) / scale, up / scale)
                end
            end)
    end
    dress.auraSize, dress.auraRows = size, rows
    dress.arrow:ClearAllPoints()
    dress.arrow:SetPoint("BOTTOM", dress, "TOP", 0, math.max(rows.above, 1) * step)
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
    ns.Bar.Make(dress, true) -- its health marks made up too
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
    -- Its barrier, lost health and dispel type made up, as the settings say (none in Spells only; no dispel type in
    -- Health bar only, as on a plate).
    local bare = style == "spells"
    dress.marks:Sample({ barrier = not bare and options.barrier ~= false and spec.barrier or 0,
                         lost = not bare and options.lost ~= false and spec.lost or 0,
                         dispel = style ~= "bar" and options.dispel ~= false and spec.dispel or nil })
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
    local raid, marker = dress.raid, options.marker ~= false and spec.raid or nil -- the setting Raid markers
    if marker then raid:SetSpriteSheetCell(marker, 4, 4) end
    raid:SetShown(marker ~= nil)
    Text.Room(dress, "raid", marker and Text.size or nil)
    dress.holding = false
    Text.Layout(dress)
    dress.dot:SetShown(style == "spells" and options.dot == true and marker == nil)
    dress.arrow:SetShown(style == "spells" and spec.lit == "target")
    dress:SetSize(style ~= "spells" and dress.want or Sample.WIDE, Text.Height(dress))
    -- Your combo points under it, as a rogue's (the setting Combo points under the bar).
    if spec.combo and options.resource ~= false then
        ns.Resource.Show(dress, spec.combo)
        ns.Resource.Fit(dress)
    elseif dress.strip then
        dress.strip:Hide()
    end
    Cast(dress, spec.cast)
    Fit(dress)
    Numbers(dress, spec.numbers and options.combatText ~= false)
    dress:Show()
end
