local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Setup
--  The nameplates' setup, step by step (Saneroki, 2026-11-16: "a step by step
--  window so the player goes through each step where it can see a fake
--  nameplate in the window and see how it looks with their setting. Each page
--  in the window groups together similar settings or information so each page
--  has its own purpose"). The module's own words and samples, handed to Core
--  (Core.Onboarding.Add); the window is the addon Onboarding's, read only when
--  it opens: by itself the first time the module is on, from the module's
--  options page (Set up step by step), or /sane setup nameplates.
--
--  The steps, in Saneroki's order (2026-11-16), each a few short lines that
--  start with a gold word ("A whole paragraph people will not read"), its
--  switches and a board of sample plates (Sample.lua) drawn anew after each
--  change, in the window's solid grey box:
--    intro    what this is
--    size     size, size by distance and how much
--    seen     how see-through each kind of plate is
--    which    whose plates show, and the keys that switch plates
--    danger   how strong it is (boss, elite, rare), aggro, threat
--    border   who it is to you: target, out of reach, party, guild ...;
--             class colours
--    line     what the bar says: quest, level, raid marker, item level,
--             health; the dispel icon
--    bar      mana, rage, energy, combo points, barrier, lost health
--    cast     the cast bar and its height, damage numbers
--    auras    how many debuffs, buffs, crowd control, where (eight places
--             round the bar, picked on a small bar), how large; damage
--             numbers rising over them
--    timers   the seconds left in the icons
--    look     what plates show (Plates show)
--  Size and Spells on it each took two pages where one held too many switches.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Setup = {}
ns.Setup = Setup

Setup.ROW = 44        -- a row of a board that lists samples (border, danger, which, seen)
Setup.TOP = 34        -- the first row's middle, from the board's top
Setup.LEFT = 24       -- a listed sample's left end
Setup.WORDS = 214     -- the words beside a listed sample: from the board's left
Setup.SIZE = 13       -- the boards' words (Look.SetFont)
Setup.FAINT = 0.25    -- a plate that would not show, drawn this solid
Setup.CLOSE = 1.6     -- the samples of the seconds left, this large: the numbers readable

local ICONS = "Interface\\Icons\\"
local function Icons(...)
    local list = {}
    for index = 1, select("#", ...) do list[index] = ICONS .. select(index, ...) end
    return list
end
-- The game's own icons for the samples' auras and casts.
Setup.DEBUFFS = Icons("Spell_Nature_StarFall", "Ability_Druid_Disembowel", "Spell_Shadow_ShadowWordPain",
    "Ability_Warrior_Sunder", "Spell_Nature_InsectSwarm", "Ability_ThunderClap", "Spell_Shadow_CurseOfTounges",
    "Spell_Fire_Immolation", "Spell_Nature_FaerieFire", "Ability_Hunter_SniperShot", "Spell_Shadow_AbominationExplosion",
    "Ability_Gouge")
Setup.BUFFS = Icons("Spell_Holy_PowerWordShield", "Spell_Nature_Regeneration", "Spell_Holy_WordFortitude",
    "Spell_Nature_Rejuvenation", "Spell_Holy_DevotionAura", "Spell_Frost_FrostArmor02")
Setup.CONTROL = Icons("Spell_Frost_FrostNova", "Spell_Nature_Polymorph", "Spell_Shadow_Possession",
    "Ability_Rogue_KidneyShot")
Setup.BOLT = ICONS .. "Spell_Shadow_ShadowBolt"
Setup.QUAKE = ICONS .. "Spell_Nature_Earthquake"
Setup.SKULL = 8 -- the raid marker the samples wear

-- Words in a colour ({ r, g, b }); in the game's gold without one.
local function Hued(colour, words)
    if not words then colour, words = Look.GOLD, colour end
    return "|cff" .. Core.Hex(colour[1], colour[2], colour[3]) .. words .. "|r"
end

-- A step's words: one line each, its first words in gold ({ "Gold", "the rest" }), so the page reads at a glance.
local function Lines(...)
    local lines = {}
    for index = 1, select("#", ...) do
        local line = select(index, ...)
        lines[index] = Hued(line[1]) .. "  " .. line[2]
    end
    return table.concat(lines, "\n")
end

local function You()
    local name = Core.Ask(UnitName, "player")
    return type(Core.Plain(name)) == "string" and name or "You"
end

local D40, D60 = Core.Distance(40), Core.Distance(60)

-------------------------------------------------------------------------------
--  The steps: their words and the switches each is about
-------------------------------------------------------------------------------
Setup.STEPS = {
    { key = "intro", title = "Set up your nameplates",
      text = Lines({ "Nameplates", "the bars over creatures and players near you, in Sane UI's dress." },
          { "This setup", "sets them up to your liking, a page for each part." },
          { "At the left", "a sample plate shows each choice at once." },
          { "Every choice", "counts at once, on the plates around you too. Close at any time: it stays." }),
      settings = {} },
    { key = "size", title = "Size",
      text = Lines({ "Nameplate size", "how large plates near you are." },
          { "Size by distance", "plates get smaller the farther away, so the near ones stand out." },
          { "How much", "100%: half the size at " .. D40 .. ", a quarter at " .. D60 .. ". 0%: all full size." },
          { "Your target", "always full size." }),
      settings = { "plateSize", "distance", "distanceStrength" } },
    { key = "seen", title = "See-through",
      text = Lines({ "See-through", "plates hide less of the world behind them." },
          { "Each kind", "its own slider: your target, foes, players you know or don't, critters." },
          { "0%", "solid. 100%: off, no plate." }),
      settings = { "targetTransparency", "transparency", "knownTransparency", "strangerTransparency",
                   "critterTransparency" } },
    { key = "which", title = "Which plates show",
      text = Lines({ "Players you don't know", "friendly players outside your party, raid, guild and friends." },
          { "Only players you know", "hides their plates, and their pets': towns stay clear." },
          { "Always shown", "your target, and anyone you could fight." },
          { "Critters", "rabbits, rats, pets: no plate, unless targeted or wanted by a quest." },
          { "Keys", "switch plates on and off as you play: click a box, press the key." }),
      settings = { "players", "critters",
                   { binding = "ALLNAMEPLATES", text = "Show or hide all plates" },
                   { binding = "FRIENDNAMEPLATES", text = "Show or hide friendly players" },
                   { binding = "NAMEPLATES", text = "Show or hide enemies" },
                   { binding = "SANEUI_NAMEPLATES_STRANGERS", text = "Show or hide players you don't know",
                     tip = "Only players you know, on or off: every player's plate, or only those you know." } } },
    { key = "danger", title = "Rank and danger",
      text = Lines({ "Thick gold", "a boss. Gold: an elite. Silver: a rare, or a rare elite." },
          { "A red glow", "you have its aggro; or a player who may attack you." },
          { "Threat", "in the bar: grey low, orange almost yours, red yours." }),
      settings = {} },
    { key = "border", title = "The border: who it is",
      text = Lines({ "Grey", "your target, in reach of your attacks." },
          { "Red", "out of reach of all your attacks." },
          { "Blue", "your party. Purple: your raid. Green: your guild. Pink: a friend. Orange: your focus." },
          { "Black", "anyone else." },
          { "Class colours", "a player's bar in their class's colour." }),
      settings = { "range", "classColour" } },
    { key = "line", title = "What the bar says",
      text = Lines({ "From the left", "quest, level, raid marker, item level, threat, name, health." },
          { "Quest", "a sword: kill it. A sack: loot it. Then how many are left." },
          { "Item level", "(i32) the average level of a player's gear. Higher is stronger." },
          { "Dispel", "the icon above the bar's end: something you can take off it." }),
      settings = { "quest", "level", "marker", "gear", "health", "percent", "dispel" } },
    { key = "bar", title = "On the bar",
      text = Lines({ "Along the bottom", "its mana (blue), rage (red) or energy (yellow)." },
          { "Combo points", "a row under the bar of the one you have them on (rogue, cat druid)." },
          { "Barrier", "the game's shield over the health." },
          { "Lost health", "hatched at the bar's end: maximum health taken away for a while." }),
      settings = { "power", "resource", "barrier", "lost" } },
    { key = "cast", title = "Casts and damage numbers",
      text = Lines({ "Under the bar", "what it casts, the seconds left, at whom." },
          { "Gold", "you can interrupt it. Grey: you cannot." },
          { "Damage numbers", "rise over it: white physical, red spells, green heals, larger when critical." }),
      settings = { "castBar", "castHeight", "combatText", "combatHeals", "combatSelf", "combatGame" } },
    { key = "auras", title = "Spells on it",
      text = Lines({ "Your debuffs", "what you put on it. Buffs: a foe's own. Crowd control: stuns, fears, roots." },
          { "Where", "click a dot round the small bar. Under it: below the cast bar." },
          { "How many", "0 shows none. Icon size: 100% as high as the bar." },
          { "Damage numbers", "rise over the bar and cover the icons above it." }),
      settings = { "debuffCount", { key = "debuffPlace", around = true, beside = true },
                   "buffCount", { key = "buffPlace", around = true, beside = true },
                   "controlCount", { key = "controlPlace", around = true, beside = true }, "auraSize" } },
    { key = "timers", title = "Time left in the icons",
      text = Lines({ "The seconds left", "of each debuff and buff, in its icon." },
          { "Just the number", "no s or m. More than a minute left reads 60." },
          { "Size and see-through", "for the number alone." }),
      settings = { "duration", "durationSize", "durationTransparency" } },
    { key = "look", title = "What plates show",
      text = Lines({ "Health bar and spells", "all of it: everything of the pages before." },
          { "Health bar only", "no auras around it." },
          { "Spells only", "no bar, no name: a faint dot where a plate is, a gold arrow over your target." },
          { "Done", "your plates are set." }),
      settings = { "style", "dot" } },
}

-------------------------------------------------------------------------------
--  The boards: each step's samples, made the first time it shows
-------------------------------------------------------------------------------
local boards = {} -- [step key] = its board on the stage

local function Board(stage, key)
    local board = boards[key]
    if board then return board end
    board = CreateFrame("Frame", nil, stage)
    board:SetAllPoints(stage)
    board.samples, board.lines = {}, {}
    boards[key] = board
    return board
end

local function SampleOf(board, index)
    local dress = board.samples[index]
    if not dress then
        dress = ns.Sample.New(board)
        board.samples[index] = dress
    end
    return dress
end

local function Wide(board)
    local width = board:GetWidth()
    return type(width) == "number" and width > 0 and width or 420
end

-- Words on the board, made the first time.
local function Line(board, index)
    local line = board.lines[index]
    if not line then
        line = board:CreateFontString(nil, "ARTWORK")
        Look.SetFont(line, Setup.SIZE)
        line:SetJustifyH("LEFT")
        line:SetWordWrap(true)
        board.lines[index] = line
    end
    return line
end

-- A sample filled and its point put at (x, y) from the board's top left, in the board's units whatever its scale.
local function Put(board, index, spec, point, x, y, scale, through)
    local dress = SampleOf(board, index)
    ns.Sample.Fill(dress, spec, scale, through)
    local own = dress:GetScale()
    dress:ClearAllPoints()
    dress:SetPoint(point, board, "TOPLEFT", x / own, -y / own)
    return dress
end

-- A list of samples, a row each, with its words beside it (rows: { spec, words, through }).
local function List(board, rows)
    for index, row in ipairs(rows) do
        local y = Setup.TOP + (index - 1) * Setup.ROW
        Put(board, index, row[1], "LEFT", Setup.LEFT, y, 1, row[3])
        local line = Line(board, index)
        line:ClearAllPoints()
        line:SetPoint("LEFT", board, "TOPLEFT", Setup.WORDS, -y)
        line:SetWidth(Wide(board) - Setup.WORDS - 12)
        line:SetText(row[2])
    end
end

-- Words under a sample (centred under it, as wide as the board allows).
local function Under(board, index, dress, words, below)
    local line = Line(board, index)
    line:ClearAllPoints()
    line:SetPoint("TOP", dress, "BOTTOM", 0, -(below or 10))
    line:SetWidth(math.max(Wide(board) - 40, 100))
    line:SetJustifyH("CENTER")
    line:SetText(words)
    return line
end

-- Of a spec, a copy with these changed.
local function As(spec, changes)
    local copy = {}
    for key, value in pairs(spec) do copy[key] = value end
    for key, value in pairs(changes or {}) do copy[key] = value end
    return copy
end

-- The samples' units.
local FOE = { name = "Thornspine Raider", above = 1, hostile = true, rank = "elite", health = 3150, most = 4800,
              power = { 60, 100, "RAGE" }, threat = { 1, 85 }, raid = Setup.SKULL }
local CREATURE = { name = "Mossback Lurker", above = 0, hostile = true, health = 1100, most = 1350 }
local function Player(name, class, extra) return As({ name = name, player = true, class = class, above = 0 }, extra) end

-- Your target: an elite casting at you, with auras of every kind.
local function Target()
    return As(FOE, { lit = "target", debuffs = Setup.DEBUFFS, buffs = Setup.BUFFS, control = { Setup.CONTROL[1] },
                     cast = { icon = Setup.BOLT, spell = "Shadow Bolt", target = You(), time = 2.5 } })
end

local function Share(key) return (tonumber((ns.options or {})[key]) or 0) / 100 end

local DRAW = {}

function DRAW.intro(board)
    local dress = Put(board, 1, Target(), "CENTER", Wide(board) / 2, 170)
    Under(board, 1, dress, "A plate of Sane UI: your target, an elite casting at you.", 50)
end

function DRAW.size(board)
    local options, Scale = ns.options or {}, ns.Scale
    local full, far = Scale.Full(), options.distance ~= false
    local middle = Wide(board) / 2
    local first = Put(board, 1, As(CREATURE, { lit = "target" }), "CENTER", middle, 90, full)
    Under(board, 1, first, "Your target: full size")
    local second = Put(board, 2, CREATURE, "CENTER", middle, 220, far and full * Scale.Size(40) or full)
    Under(board, 2, second, D40 .. " away")
    local third = Put(board, 3, CREATURE, "CENTER", middle, 330, far and full * Scale.Size(60) or full)
    Under(board, 3, third, D60 .. " away")
end

function DRAW.seen(board)
    -- Its share beside each, Off at 100% (no plate: drawn faint, as a plate that would not show).
    local function Through(key)
        if Share(key) >= 1 then return "  " .. Hued({ 0.6, 0.6, 0.6 }, "Off: no plate") end
        return "  " .. Hued(math.floor(Share(key) * 100 + 0.5) .. "%")
    end
    local function Seen(key) return Share(key) >= 1 and (1 - Setup.FAINT) or Share(key) end
    List(board, {
        { As(CREATURE, { lit = "target" }), "Your target" .. Through("targetTransparency"), Seen("targetTransparency") },
        { CREATURE, "Creatures and foes" .. Through("transparency"), Seen("transparency") },
        { Player("Bram Ironhold", "WARRIOR", { lit = "guild" }), "Players you know" .. Through("knownTransparency"),
          Seen("knownTransparency") },
        { Player("Corin Ashdale", "PALADIN"), "Players you don't know" .. Through("strangerTransparency"),
          Seen("strangerTransparency") },
        { { name = "Rabbit", level = 1, calm = true, health = 8, most = 8 }, "Critters" .. Through("critterTransparency"),
          Seen("critterTransparency") },
    })
end

function DRAW.which(board)
    local options = ns.options or {}
    local strangers, critters = options.players ~= false, options.critters ~= true
    local hidden, shown = Hued({ 0.6, 0.6, 0.6 }, "No plate"), Hued({ 0.25, 1, 0.25 }, "A plate")
    List(board, {
        { Player("Bram Ironhold", "WARRIOR", { lit = "guild" }), shown .. ": your party, raid, guild, friends" },
        { Player("Corin Ashdale", "PALADIN"), (strangers and hidden or shown) .. ": a player you don't know",
          strangers and (1 - Setup.FAINT) or nil },
        { Player("Vex Morrowgrim", "WARLOCK", { hostile = true, danger = true }), shown .. ": anyone you could fight" },
        { { name = "Rabbit", level = 1, calm = true, health = 8, most = 8 }, (critters and hidden or shown) .. ": a critter",
          critters and (1 - Setup.FAINT) or nil },
    })
end

function DRAW.danger(board)
    local Bar, Text = ns.Bar, ns.Text
    local foe = { name = "Thornspine Raider", above = 1, hostile = true }
    List(board, {
        { As(foe, { name = "Gnarlroot the Ancient", level = 0, rank = "boss" }), Hued(Bar.RANKS.boss.colour, "Thick gold")
            .. ": a boss" },
        { As(foe, { rank = "elite", above = 2 }), Hued(Bar.RANKS.elite.colour, "Gold") .. ": an elite" },
        { As(foe, { name = "Duskwing", rank = "rare" }), Hued(Bar.RANKS.rare.colour, "Silver") .. ": a rare, a rare elite too" },
        { As(foe, { threat = { 3, 100 } }), Hued(Bar.GLOW, "A red glow") .. ", red threat: you have its aggro" },
        { As(foe, { threat = { 1, 85 } }), Hued(Text.THREAT[1], "Orange threat") .. ": almost yours" },
        { As(foe, { threat = { 0, 40 } }), Hued(Text.THREAT[0], "Grey threat") .. ": it is after someone else" },
        { Player("Vex Morrowgrim", "WARLOCK", { hostile = true, danger = true }),
          Hued(Bar.GLOW, "A glow on a player") .. ": they may attack you" },
    })
end

function DRAW.border(board)
    local Bar, options = ns.Bar, ns.options or {}
    List(board, {
        { As(CREATURE, { lit = "target" }), Hued(Bar.TARGET, "Grey") .. ": your target, in reach" },
        { As(CREATURE, { lit = "target", out = true }), Hued(Bar.FAR, "Red") .. ": out of reach of all your attacks"
            .. (options.range == false and " (off)" or "") },
        { As(CREATURE, { lit = "focus" }), Hued(Bar.FOCUS, "Orange") .. ": your focus" },
        { Player("Lyra Dawnwhisper", "PRIEST", { lit = "party" }), Hued(Bar.KIN.party, "Blue") .. ": your party" },
        { Player("Bram Ironhold", "WARRIOR", { lit = "guild" }), Hued(Bar.KIN.guild, "Green") .. ": your guild" },
        { Player("Seren Starfall", "MAGE", { lit = "raid" }), Hued(Bar.KIN.raid, "Purple") .. ": your raid" },
        { Player("Tavi Quickstep", "ROGUE", { lit = "friend" }), Hued(Bar.KIN.friend, "Pink") .. ": a friend" },
        { CREATURE, Hued({ 0.6, 0.6, 0.6 }, "Black") .. ": anyone else" },
    })
end

function DRAW.line(board)
    local middle = Wide(board) / 2
    local creature = Put(board, 1, As(CREATURE, { quest = { "kill", "3/8" }, raid = Setup.SKULL, dispel = "Magic",
                                                  health = 812 }), "CENTER", middle, 100)
    Under(board, 1, creature, "A creature your quest wants (3 of 8 to go), a skull on it, a buff you can take off.", 14)
    local player = Put(board, 2, Player("Aeryn Moonblade", "HUNTER", { above = 1, gear = 32, health = 2140, most = 3050,
                                                                      power = { 2400, 3200, "MANA" }, dispel = "Poison" }),
        "CENTER", middle, 260)
    Under(board, 2, player, "Another player: their item level, a poison you can cure.", 14)
end

function DRAW.bar(board)
    local middle = Wide(board) / 2
    local mage = Put(board, 1, Player("Ilse Ashveil", "MAGE", { hostile = true, health = 2000, most = 2600,
                                                               power = { 3900, 6000, "MANA" }, barrier = 0.3 }),
        "CENTER", middle, 70)
    Under(board, 1, mage, "Mana, and a barrier over its health")
    local warrior = Put(board, 2, As(CREATURE, { name = "Thornspine Raider", health = 1500, most = 2400,
                                                 power = { 45, 100, "RAGE" }, lost = 0.25 }), "CENTER", middle, 180)
    Under(board, 2, warrior, "Rage, and maximum health lost for a while")
    local rogue = Put(board, 3, Player("Nyx Shadowstep", "ROGUE", { hostile = true, health = 1700, most = 2100,
                                                                   power = { 70, 100, "ENERGY" }, combo = 3 }),
        "CENTER", middle, 290)
    Under(board, 3, rogue, "Energy, and your combo points under it", 18)
end

function DRAW.cast(board)
    local middle = Wide(board) / 2
    local options = ns.options or {}
    local caster = Put(board, 1, As(CREATURE, { name = "Thornspine Mystic", above = 1, health = 1900, most = 2400,
                                                power = { 4200, 6000, "MANA" }, threat = { 0, 30 }, numbers = true,
                                                cast = { icon = Setup.BOLT, spell = "Shadow Bolt", target = You(),
                                                         time = 2.5 } }), "CENTER", middle, 150)
    Under(board, 1, caster, options.castBar == false and "The game's own cast bar (Cast bar off)."
        or Hued("Gold") .. ": you can interrupt it.", 34)
    local boss = Put(board, 2, { name = "Gnarlroot the Ancient", level = 0, rank = "boss", hostile = true,
                                 cast = { icon = Setup.QUAKE, spell = "Ground Tremor", time = 3, locked = true } },
        "CENTER", middle, 320)
    Under(board, 2, boss, options.castBar == false and "" or Hued({ 0.7, 0.7, 0.7 }, "Grey") .. ": you cannot.", 34)
end

function DRAW.auras(board)
    local Auras = ns.Auras
    local spec = As(Target(), { control = Setup.CONTROL, numbers = true })
    spec.lit = nil
    -- It casts only while a kind stands under the bar: those icons stand under the cast bar's place.
    if select(2, Auras.Below(1)) == 0 then spec.cast = nil end
    local dress = Put(board, 1, spec, "CENTER", Wide(board) / 2, 220)
    local words = {}
    for _, kind in ipairs(Auras.KINDS) do
        local name = kind.key == "own" and "Your debuffs" or kind.key == "foes" and "Its buffs" or "Crowd control"
        local most = Auras.Most(kind.count)
        local place = (ns.TEXT[Auras.Where(kind)] or ""):lower()
        words[#words + 1] = Hued(name) .. ": " .. (most > 0 and (most .. ", " .. place) or "none")
    end
    if ns.Style() == "bar" then words[#words + 1] = "Plates show the health bar only (the last page): no spells." end
    -- Under the icons under the bar where there are some, and the cast bar's place over them.
    local under, rows = Auras.Below(dress:GetHeight())
    local cast = rows > 0 and (ns.options or {}).castBar ~= false and ns.Cast.Height(dress) or 0
    Under(board, 1, dress, table.concat(words, "\n"), 24 + cast + under)
end

function DRAW.timers(board)
    local spec = As(FOE, { debuffs = Setup.DEBUFFS, buffs = Setup.BUFFS, control = Setup.CONTROL })
    spec.raid = nil
    local dress = Put(board, 1, spec, "CENTER", Wide(board) / 2, 180, Setup.CLOSE)
    Under(board, 1, dress, "The seconds left in each icon, the number alone. Over a minute: 60.", 30)
end

function DRAW.look(board)
    local dress = Put(board, 1, Target(), "CENTER", Wide(board) / 2, 170)
    Under(board, 1, dress, "Your target, an elite casting at you, as your plates show it.", 50)
end

-- The step's board on the stage, the others out of sight; drawn anew as the settings in use say.
local function Stage(stage, step)
    for key, board in pairs(boards) do board:SetShown(key == step.key) end
    local draw = DRAW[step.key]
    if not draw then return end
    local board = Board(stage, step.key)
    draw(board)
    board:Show()
end

-- For the tests: a step's board, once drawn.
function Setup.Board(key) return boards[key] end

Core.Onboarding.Add(ns.name, {
    title = ns.TEXT.title,
    steps = Setup.STEPS,
    Stage = function(stage, step, index) ns.Safe("setup sample", Stage, stage, step, index) end,
})
