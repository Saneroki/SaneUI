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
--  Each step has its purpose, its words, the module's switches it is about,
--  and a board of sample plates (Sample.lua) drawn anew after each change:
--    look    what plates show (Plates show), a foe that is your target
--    line    what the bar says: quest, level, item level, health
--    border  who it is to you: target, out of reach, focus, party, guild ...
--    danger  how strong it is (boss, elite, rare), aggro, threat
--    auras   how many debuffs, buffs and crowd control
--    cast    the cast bar and the combat text (damage numbers)
--    bar     the power line, combo points, barriers, lost health
--    which   whose plates show (players you know, critters)
--    size    size, size by distance, transparency
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Setup = {}
ns.Setup = Setup

Setup.ROW = 44        -- a row of a board that lists samples (border, danger, which)
Setup.TOP = 30        -- the first row's middle, from the board's top
Setup.LEFT = 24       -- a listed sample's left end
Setup.WORDS = 200     -- the words beside a listed sample: from the board's left
Setup.SIZE = 13       -- the boards' words (Look.SetFont)
Setup.FAINT = 0.25    -- a plate that would not show, drawn this solid

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

-- A colour's words in that colour ({ r, g, b }).
local function Hued(colour, words)
    return "|cff" .. Core.Hex(colour[1], colour[2], colour[3]) .. words .. "|r"
end

local function You()
    local name = Core.Ask(UnitName, "player")
    return type(Core.Plain(name)) == "string" and name or "You"
end

-------------------------------------------------------------------------------
--  The steps: their words and the switches each is about
-------------------------------------------------------------------------------
Setup.STEPS = {
    { key = "look", title = "Your nameplates",
      text = "Over each creature and player near you the game shows a nameplate. Sane UI dresses it: one bar with "
          .. "everything on one line inside it, a border that tells who it is to you, and the spells on it around "
          .. "the bar.\nThis setup goes through it a part at a time. Each choice shows at once on the sample at the "
          .. "left, and on the plates around you.",
      settings = { "style", "dot" } },
    { key = "line", title = "What the bar says",
      text = "Inside the bar, from the left: how many a quest of yours still wants (a sword: to kill, a sack: to "
          .. "loot), the level in the colour of how hard it is for you (green easy, yellow even, red hard, a skull "
          .. "too strong to tell), a player's item level, your threat, the name and the health.\nItem level "
          .. "(\"i32\"): the average level of the gear a player wears; the higher, the stronger their gear. It "
          .. "shows once the game has let Sane UI inspect them: out of a fight, near enough.",
      settings = { "quest", "level", "gear", "health", "percent" } },
    { key = "border", title = "The border: who it is to you",
      text = "The thin line around the bar tells how a creature or player stands to you. Grey is your target "
          .. "while your attacks reach it, red when none of them does. Blue is someone in your party, green in your "
          .. "guild, purple in your raid, pink a friend, orange your focus. Anyone else has a black line.",
      settings = { "range" } },
    { key = "danger", title = "Rank and danger",
      text = "Behind the border a second line tells how strong it is: thick gold a boss, gold an elite, silver a "
          .. "rare (a rare elite too).\nA red glow around the bar: you have its aggro, it is after you; or it is "
          .. "a player who may attack you.\nYour threat inside the bar: grey while it is after someone else, "
          .. "orange when you are about to take its aggro, red while you have it.",
      settings = {} },
    { key = "auras", title = "Spells on it",
      text = "Around the bar: right above it the debuffs and damage over time you put on it, with the time each "
          .. "has left; at its left the buffs of a foe; at its right the crowd control on it (stuns, fears, "
          .. "roots), by anyone. Choose how many of each show; 0 shows none.",
      settings = { "debuffCount", "buffCount", "controlCount", "dispel" } },
    { key = "cast", title = "Casts and damage numbers",
      text = "Under the bar, what it casts: the spell's icon with the seconds left, the spell and at whom. "
          .. "Gold: you can interrupt it. Grey: you cannot.\nWhat it takes rises over its plate and fades: white "
          .. "for auto attacks and physical damage, red for spells, green for heals, larger for a critical hit.",
      settings = { "castBar", "combatText", "combatHeals", "combatSelf", "combatGame" } },
    { key = "bar", title = "On the bar",
      text = "Along the bottom of the bar a thin line: its mana, rage or energy. As a rogue, or a druid in cat "
          .. "form, your combo points stand in a row under the bar of the one you have them on.\nOn the bar "
          .. "itself: the game's shield over the health for what absorbs damage, and hatching where maximum "
          .. "health was taken away for a while.",
      settings = { "power", "resource", "barrier", "lost" } },
    { key = "which", title = "Which plates show",
      text = "Players you do not know, who cannot attack you and whom you cannot attack, have no plate, nor do "
          .. "their pets: towns stay clear. Your party, guild, friends, your target and anyone you could fight "
          .. "always have one.\nCritters (rabbits, rats, someone's pet) have none either, unless one is your "
          .. "target or a quest of yours wants it.",
      settings = { "players", "critters" } },
    { key = "size", title = "Size and transparency",
      text = ("Plates are their full size within %s and smaller the farther away: half at %s, a quarter at %s, "
          .. "so the near ones stand out. Your target's is always full size. See-through plates hide less of the "
          .. "world; your target's has a slider of its own.\nCome back here at any time: Sane UI's options, "
          .. "Nameplates, Set up step by step, or /sane setup nameplates."):format(Core.Distance(10),
          Core.Distance(40), Core.Distance(60)),
      settings = { "plateSize", "distance", "transparency", "targetTransparency" } },
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
    local width = board:GetWidth() > 0 and board:GetWidth() or 420
    for index, row in ipairs(rows) do
        local y = Setup.TOP + (index - 1) * Setup.ROW
        Put(board, index, row[1], "LEFT", Setup.LEFT, y, 1, row[3])
        local line = Line(board, index)
        line:ClearAllPoints()
        line:SetPoint("LEFT", board, "TOPLEFT", Setup.WORDS, -y)
        line:SetWidth(width - Setup.WORDS - 12)
        line:SetText(row[2])
    end
end

-- Words under a sample (centred under it, as wide as the board allows).
local function Under(board, index, dress, words, below)
    local line = Line(board, index)
    line:ClearAllPoints()
    line:SetPoint("TOP", dress, "BOTTOM", 0, -(below or 10))
    line:SetWidth(math.max((board:GetWidth() or 420) - 40, 100))
    line:SetJustifyH("CENTER")
    line:SetText(words)
    return line
end

-- The foe of the first step: your target, an elite casting at you, with auras of every kind.
local function Foe()
    return { name = "Thornspine Raider", above = 1, hostile = true, rank = "elite", health = 3150, most = 4800,
             power = { 60, 100, "RAGE" }, threat = { 1, 85 }, lit = "target", debuffs = Setup.DEBUFFS,
             buffs = Setup.BUFFS, control = { Setup.CONTROL[1] },
             cast = { icon = Setup.BOLT, spell = "Shadow Bolt", target = You(), time = 2.5 } }
end

local DRAW = {}

function DRAW.look(board)
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local dress = Put(board, 1, Foe(), "CENTER", middle, 150, nil)
    Under(board, 1, dress, "Your target: an elite foe casting at you, with your debuffs above it, its buffs at its "
        .. "left and the crowd control on it at its right.", 40)
end

function DRAW.line(board)
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local creature = Put(board, 1, { name = "Mossback Lurker", above = 0, hostile = true, quest = { "kill", "3/8" },
                                     health = 812, most = 1350 }, "CENTER", middle, 90)
    Under(board, 1, creature, "A creature a quest of yours wants: 3 of 8 still to kill.")
    local player = Put(board, 2, { name = "Aeryn Moonblade", player = true, class = "HUNTER", above = 1, gear = 32,
                                   health = 2140, most = 3050, power = { 2400, 3200, "MANA" } }, "CENTER", middle, 230)
    Under(board, 2, player, "Another player, with their item level.")
end

function DRAW.border(board)
    local Bar, options = ns.Bar, ns.options or {}
    local creature = { name = "Mossback Lurker", above = 0, hostile = true }
    local function As(extra)
        local spec = {}
        for key, value in pairs(creature) do spec[key] = value end
        for key, value in pairs(extra) do spec[key] = value end
        return spec
    end
    local function Player(name, class, lit) return { name = name, player = true, class = class, above = 0, lit = lit } end
    List(board, {
        { As({ lit = "target" }), Hued(Bar.TARGET, "Grey") .. ": your target, within reach of your attacks" },
        { As({ lit = "target", out = true }), Hued(Bar.FAR, "Red") .. ": out of reach of all your attacks"
            .. (options.range == false and " (switched off)" or "") },
        { As({ lit = "focus" }), Hued(Bar.FOCUS, "Orange") .. ": your focus" },
        { Player("Lyra Dawnwhisper", "PRIEST", "party"), Hued(Bar.KIN.party, "Blue") .. ": in your party" },
        { Player("Bram Ironhold", "WARRIOR", "guild"), Hued(Bar.KIN.guild, "Green") .. ": in your guild" },
        { Player("Seren Starfall", "MAGE", "raid"), Hued(Bar.KIN.raid, "Purple") .. ": in your raid" },
        { Player("Tavi Quickstep", "ROGUE", "friend"), Hued(Bar.KIN.friend, "Pink") .. ": on your friends list" },
        { As({}), Hued({ 0.6, 0.6, 0.6 }, "Black") .. ": anyone else" },
    })
end

function DRAW.danger(board)
    local Bar, Text = ns.Bar, ns.Text
    local function Foe(extra)
        local spec = { name = "Thornspine Raider", above = 1, hostile = true }
        for key, value in pairs(extra) do spec[key] = value end
        return spec
    end
    List(board, {
        { Foe({ name = "Gnarlroot the Ancient", level = 0, rank = "boss" }), Hued(Bar.RANKS.boss.colour, "Thick gold")
            .. ": a boss" },
        { Foe({ rank = "elite", above = 2 }), Hued(Bar.RANKS.elite.colour, "Gold") .. ": an elite" },
        { Foe({ name = "Duskwing", rank = "rare" }), Hued(Bar.RANKS.rare.colour, "Silver") .. ": a rare, a rare elite too" },
        { Foe({ threat = { 3, 100 } }), Hued(Bar.GLOW, "A red glow") .. ", red threat: you have its aggro" },
        { Foe({ threat = { 1, 85 } }), Hued(Text.THREAT[1], "Orange threat") .. ": you are about to take its aggro" },
        { Foe({ threat = { 0, 40 } }), Hued(Text.THREAT[0], "Grey threat") .. ": it is after someone else" },
        { { name = "Vex Morrowgrim", player = true, class = "WARLOCK", above = 0, hostile = true, danger = true },
          Hued(Bar.GLOW, "A glow on a player") .. ": they may attack you" },
    })
end

function DRAW.auras(board)
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local spec = Foe()
    spec.cast, spec.lit, spec.control = nil, nil, Setup.CONTROL
    local dress = Put(board, 1, spec, "CENTER", middle, 150)
    local Auras = ns.Auras
    local function Count(key) return Auras.Most(key) > 0 and ns.Style() ~= "bar" end
    local own = Line(board, 1)
    own:ClearAllPoints()
    own:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", 0, Auras.SIZE * dress:GetScale() + 6)
    own:SetWidth(200)
    own:SetText(Count("debuffCount") and "Your debuffs" or "")
    local buffs = Line(board, 2)
    buffs:ClearAllPoints()
    buffs:SetPoint("TOPRIGHT", dress, "BOTTOMLEFT", -Auras.GAP, -8)
    buffs:SetWidth(120)
    buffs:SetJustifyH("RIGHT")
    buffs:SetText(Count("buffCount") and "Its buffs" or "")
    local control = Line(board, 3)
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", dress, "BOTTOMRIGHT", Auras.GAP, -8)
    control:SetWidth(120)
    control:SetText(Count("controlCount") and "Crowd control" or "")
    if ns.Style() == "bar" then
        Under(board, 4, dress, "Plates show the health bar only (the first step): no auras around it.", 40)
    else
        Under(board, 4, dress, "", 40)
    end
end

function DRAW.cast(board)
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local spec = Foe()
    spec.debuffs, spec.buffs, spec.control, spec.numbers = nil, nil, nil, true
    local first = Put(board, 1, spec, "CENTER", middle, 130)
    local options = ns.options or {}
    Under(board, 1, first, options.castBar == false and "The game's own cast bar (Cast bar is off)."
        or Hued(Look.GOLD, "Gold") .. ": you can interrupt it.", 30)
    local locked = Foe()
    locked.debuffs, locked.buffs, locked.control, locked.lit, locked.threat = nil, nil, nil, nil, nil
    locked.name, locked.rank = "Gnarlroot the Ancient", "boss"
    locked.level = 0
    locked.cast = { icon = Setup.QUAKE, spell = "Ground Tremor", time = 3, locked = true }
    local second = Put(board, 2, locked, "CENTER", middle, 290)
    Under(board, 2, second, options.castBar == false and "" or Hued({ 0.7, 0.7, 0.7 }, "Grey") .. ": you cannot.", 30)
end

function DRAW.bar(board)
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local caster = Put(board, 1, { name = "Ilse Ashveil", player = true, class = "MAGE", above = 0, hostile = true,
                                   health = 2600, most = 2600, power = { 3900, 6000, "MANA" } }, "CENTER", middle, 100)
    Under(board, 1, caster, "Mana along the bottom of a mage's bar.")
    local fighter = Put(board, 2, { name = "Thornspine Raider", above = 1, hostile = true, health = 1900, most = 2400,
                                    power = { 45, 100, "RAGE" } }, "CENTER", middle, 240)
    Under(board, 2, fighter, "Rage along the bottom of a warrior's.")
end

function DRAW.which(board)
    local options = ns.options or {}
    local strangers, critters = options.players ~= false, options.critters ~= true
    local hidden, shown = Hued({ 0.6, 0.6, 0.6 }, "No plate"), Hued({ 0.25, 1, 0.25 }, "A plate")
    List(board, {
        { { name = "Bram Ironhold", player = true, class = "WARRIOR", above = 0, lit = "guild" },
          shown .. ": someone of your guild, party or friends" },
        { { name = "Corin Ashdale", player = true, class = "PALADIN", above = 0 },
          (strangers and hidden or shown) .. ": a player you do not know", strangers and (1 - Setup.FAINT) or nil },
        { { name = "Vex Morrowgrim", player = true, class = "WARLOCK", above = 0, hostile = true, danger = true },
          shown .. ": anyone you could fight" },
        { { name = "Rabbit", level = 1, calm = true, health = 8, most = 8 },
          (critters and hidden or shown) .. ": a critter", critters and (1 - Setup.FAINT) or nil },
    })
end

function DRAW.size(board)
    local options, Scale = ns.options or {}, ns.Scale
    local middle = (board:GetWidth() > 0 and board:GetWidth() or 420) / 2
    local full = Scale.Full()
    local far = options.distance ~= false
    local own = (tonumber(options.transparency) or 0) / 100
    local target = (tonumber(options.targetTransparency) or 0) / 100
    local spec = { name = "Mossback Lurker", above = 0, hostile = true, health = 1100, most = 1350 }
    local lit = {}
    for key, value in pairs(spec) do lit[key] = value end
    lit.lit = "target"
    local first = Put(board, 1, lit, "CENTER", middle, 80, full, target)
    Under(board, 1, first, "Your target")
    local second = Put(board, 2, spec, "CENTER", middle, 200, far and full * 0.5 or full, own)
    Under(board, 2, second, Core.Distance(40) .. " away")
    local third = Put(board, 3, spec, "CENTER", middle, 300, far and full * 0.25 or full, own)
    Under(board, 3, third, Core.Distance(60) .. " away")
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
