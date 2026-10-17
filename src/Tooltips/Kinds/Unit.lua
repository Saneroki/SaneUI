local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Unit
--  The tooltip of a player or a creature:
--
--      SOMNIFERIE                    [portrait]   the name: a player's in the colour of the
--      <Dawnbreakers> Officer  [iLvl 50 - 60]     class, a creature's as the game colours it;
--      Human  ·  Alliance                         the guild as large, close under it, the rank
--      Arms Warrior 31/5/0  ·  Sergeant  ·  PvP   in it small (a creature: its title, a pet: its
--      ------------------------------------       owner); small: race and side (what a creature
--                                                 is, its family and faction), then spec and
--                                                 class, title, and what is true now (PvP, AFK,
--                                                 DND, dead; a creature's rank, tapped). The
--                                                 level on a plaque
--      Target  Ragnaros                           whom it targets
--      [======= 4,230   83% ========    ]          health as a bar, its numbers inside, and
--      [================_______________]          over its lower part its mana, rage or energy
--      [] [] [] [] []                             its buffs and debuffs
--      145 XP                      12 to level    a creature: what killing it gives you, and
--      ------------------------------------       how many such kills to your next level
--      The Defias Brotherhood                     what else the tooltip says: your quests
--       - Defias Pillager slain: 4/10      /      (a sword: to kill; a bag: to loot),
--      Item Level 61                              and other addons' lines
--
--  A creature says its class only when it is more than a plain fighter (Mage).
--  Round the portrait lies the dragon the game's target frame gives a creature
--  of rank: gold for an elite (and here for a player), gold and winged for a
--  boss, silver for a rare.
--
--  Name, guild, race, class and level are asked of the game, so the tooltip's
--  own lines that say the same are left out.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Read, TEXT = ns.Reader, ns.TEXT
local TYPE = Enum.TooltipDataType or {}
local LINE = Enum.TooltipDataLineType or {}

local QUEST_TITLE, QUEST_OBJECTIVE = LINE.QuestTitle or -1, LINE.QuestObjective or -1
local QUEST_PLAYER, OWNER = LINE.QuestPlayer or -1, LINE.UnitOwner or -1
local COLOR = ns.COLOR
local DETAIL, LIGHT, DONE, ASIDE = COLOR.DETAIL, COLOR.LIGHT, COLOR.DONE, COLOR.ASIDE
local GOLD, HEALTH, GONE = COLOR.GOLD, COLOR.HEALTH, COLOR.NEUTRAL -- GONE: the panel of a dead or offline unit
local FRIENDLY = 5 -- the reaction from which a unit is friendly to you (UnitReaction)
local function Code(color) return ns.Hex(color[1], color[2], color[3]) end
-- Inside a line: PvP, AFK and DND, dead or offline; a player's title (a PvP rank); the talent
-- points after the spec
local PVP_HEX, AWAY_HEX, GONE_HEX = Code(COLOR.RED), Code(COLOR.AWAY), Code(ASIDE)
local TITLE_HEX, POINTS_HEX = Code(COLOR.PROSE), Code(ASIDE)
-- A creature's rank (UnitClassification; worldboss for any boss): the dragon round its portrait
-- (Panel.lua has the art), and its words on the class line in the dragon's colour, the game's
-- words where it has them. A rare elite is a rare and an elite.
local GOLD_HEX, SILVER_HEX, PLAQUE_HEX = Code(GOLD), Code(COLOR.SILVER), Code(COLOR.PLAQUE)
local ELITE = { ns.Global("ELITE") or TEXT.ELITE, GOLD_HEX }
local RARE = { ns.Global("RARE") or TEXT.RARE, SILVER_HEX }
local RANKED = {
    worldboss = { dragon = "boss", { ns.Global("BOSS") or TEXT.BOSS, GOLD_HEX } },
    elite = { dragon = "elite", ELITE },
    rare = { dragon = "silver", RARE },
    rareelite = { dragon = "silver", RARE, ELITE },
}
-- The game's lines of what a dead creature yields (skinnable, herbs, ...): on the class line. And its
-- line saying it is a corpse: the class line says Dead already.
local SKINS = {}
for _, name in ipairs({ "UNIT_SKINNABLE_LEATHER", "UNIT_SKINNABLE_HERB", "UNIT_SKINNABLE_ROCK", "UNIT_SKINNABLE_BOLTS" }) do
    local text = ns.Global(name)
    if text then SKINS[text] = true end
end
SKINS[ns.Global("UNIT_SKINNABLE_LEATHER") or "Skinnable"] = true
local CORPSE = ns.Global("CORPSE") or "Corpse"
local NOT_FACTION = { [CORPSE] = true }
for text in pairs(SKINS) do NOT_FACTION[text] = true end

-- Whether a unit name ("mouseover") stands for the unit of this GUID; any does without a GUID.
local function Names(unit, guid)
    return unit ~= nil and (guid == nil or Plain(UnitGUID(unit)) == guid)
end

-- The unit a tooltip is about, as a name the game's functions take ("target", "party2",
-- "mouseover"). The game's own answer for the GUID first; else the name the tooltip was filled by,
-- or the unit under the mouse, whichever is that GUID. A dead creature's tooltip is a corpse's (the
-- game's data kind Corpse), which may not say whose: then it is the creature under the mouse, when
-- the names agree.
local function Token(ctx)
    local guid = Plain(ctx.data.guid)
    if guid and UnitTokenFromGUID then
        local unit = Plain(UnitTokenFromGUID(guid))
        if unit then return unit end
    end
    local tooltip, filled = ctx.tooltip, nil
    if tooltip.GetUnit then filled = Plain(select(2, tooltip:GetUnit())) end
    if Names(filled, guid) then return filled end
    if guid and Names("mouseover", guid) then return "mouseover" end
    if not guid and ctx.kind == TYPE.Corpse and Plain(UnitName("mouseover")) == ctx.L[1].left then return "mouseover" end
    return nil
end

-- How the game ranks a creature ("elite", "rare", ...; "worldboss" for any boss, a dungeon's too).
local function Rank(unit)
    if UnitIsBossMob and Plain(UnitIsBossMob(unit)) then return "worldboss" end
    return Plain(UnitClassification(unit))
end

-- The class line: the class (if any) and what is true of the unit now, joined by dots. Nil when
-- there is nothing to say. rank: a creature's (Rank, RANKED).
local parts = {}
local function Part(text, hex)
    parts[#parts + 1] = hex and ("|cff%s%s|r"):format(hex, text) or text
end
local function ClassLine(unit, player, rank, classWord, title, skin, skinHex)
    wipe(parts)
    if classWord then Part(classWord) end
    if title then Part(title, TITLE_HEX) end
    if not player then
        local ranked = RANKED[rank or ""]
        if ranked then
            for index = 1, #ranked do Part(ranked[index][1], ranked[index][2]) end
        end
        local tapped = rawget(_G, "UnitIsTapDenied")
        if tapped and Plain(tapped(unit)) then Part(TEXT.TAPPED, GONE_HEX) end -- somebody else's kill
    end
    if Plain(UnitIsPVP(unit)) then Part(TEXT.PVP, PVP_HEX) end
    if player then
        if Plain(UnitIsConnected(unit)) == false then Part(ns.Global("PLAYER_OFFLINE") or TEXT.OFFLINE, GONE_HEX)
        elseif Plain(UnitIsAFK(unit)) then Part(TEXT.AFK, AWAY_HEX)
        elseif Plain(UnitIsDND(unit)) then Part(TEXT.DND, AWAY_HEX) end
    end
    if Plain(UnitIsGhost(unit)) then Part(TEXT.GHOST, GONE_HEX)
    elseif Plain(UnitIsDead(unit)) then Part(ns.Global("DEAD") or TEXT.DEAD, GONE_HEX) end
    if skin then Part(skin, skinHex) end -- skinnable, or what gathering it needs: red while you cannot
    if #parts == 0 then return nil end
    return table.concat(parts, "  \194\183  ")
end

-- A player's title, as the game puts it to the name ("Sergeant" of "Sergeant Jaina"); nil without.
local function Title(unit, shown)
    local pvpName = rawget(_G, "UnitPVPName")
    local full = pvpName and Plain(pvpName(unit))
    if type(full) ~= "string" then return nil end
    -- The name in it: the whole one (first name and surname), else the first name alone
    local name = SaneUI.Core.FullName(unit)
    local at = name and full:find(name, 1, true)
    if not at then
        name = Plain(UnitName(unit))
        at = type(name) == "string" and full:find(name, 1, true)
    end
    if not at or full == name then return nil end
    local title = (full:sub(1, at - 1) .. full:sub(at + #name)):match("^[%s,]*(.-)[%s,]*$")
    -- Not again when the tooltip's name line already says it
    if title == "" or shown:find(title, 1, true) then return nil end
    return title
end

-- An objective's words and its count, as the game writes it ("0/7 Young Nightsaber slain",
-- "Candle: 1/4"): "Young Nightsaber slain", "0/7".
local function Split(text)
    text = text:match("^[%s%-]*(.-)%s*$")
    local count, words = text:match("^(%d+%s*/%s*%d+)%s+(.+)$")
    if count then return words, count end
    words, count = text:match("^(.-):%s*(%d+%s*/%s*%d+)$")
    if words then return words, count end
    return text, ""
end

-- One objective: what to kill (a sword) or loot (a sack), its count at the right; after what to
-- loot, how often it drops ("33%"; key: its own, for Read.Memo).
local function Objective(text, count, icon, chance, key)
    local row = Read.Text("sub", text, LIGHT[1], LIGHT[2], LIGHT[3])
    row.icon, row.right, row.rr, row.rg, row.rb = icon, count, GOLD[1], GOLD[2], GOLD[3]
    if chance then row.label = Read.Memo(key, TEXT.CHANCE, chance) end
end

-- Whether an objective is done: the game says so, or its count is full ("7/7").
local function Done(line, count)
    if line.data and Plain(line.data.completed) == true then return true end
    local have, need = count:match("^(%d+)%s*/%s*(%d+)$")
    return have ~= nil and tonumber(need) > 0 and tonumber(have) >= tonumber(need)
end

-- The quest section: what killing it gives you, then under the caption Quest its part in your
-- quests:
--   - the game's own quest lines: each quest's name, then what is still to kill (the objective
--     names the creature) or loot. A done objective is left out, and a quest (or a party
--     member's line) with none left, too;
--   - from Core's quest data (Quests.lua): what it drops for your quests, where the
--     game did not say so, and for every such thing, the game's line too, how often it drops; the
--     quests it takes back and offers, each name with a line under it like an objective's: Turn
--     in or In progress (the game's ?), Offers (the game's !); an item it drops that starts a
--     quest you can take (the !, the item's name, how often it drops).
--   Every quest's name has its level at the right, in the colour of how hard it is for you.
local shown, chances = {}, {}
-- A quest's name (Quests.Heading); the first one puts the caption Quest over the section's quests.
local captioned
local function QuestTitle(ctx, title, quest)
    if not captioned then
        captioned = true
        ctx.rule = false
        local caption = Read.Row()
        caption.kind, caption.left = "caption", TEXT.QUEST
    end
    return ns.Quests.Heading(title, quest)
end
local function QuestSection(ctx, unit, npc)
    captioned = false
    local L = ctx.L
    local xp, kills = ns.Numbers.Experience(unit)
    local list = ns.Quests.Of(npc)
    ctx.rule = true
    if xp then
        local row = Read.Text("sub", Read.Memo("xp", TEXT.XP, xp), DETAIL[1], DETAIL[2], DETAIL[3])
        if kills then row.right, row.rr, row.rg, row.rb = Read.Memo("kills", TEXT.KILLS, kills), DETAIL[1], DETAIL[2], DETAIL[3] end
    end
    wipe(shown)
    -- What the database knows it drops, by the objective's words: its chance, or false (none known)
    wipe(chances)
    for index = 1, list.n do
        local entry = list[index]
        if entry.kind == "drop" then chances[(Split(entry.text))] = entry.extra or false end
    end
    local drops = 0 -- the objectives with a chance so far: each its own memo
    -- A quest's name and a party member's line wait for an objective still to do.
    local name, last, title, titleQuest, player = L[1].left, nil, nil, nil, nil
    for index = 2, ctx.count do
        local line = L[index]
        local kind = line.type
        if not line.used and (kind == QUEST_TITLE or kind == QUEST_OBJECTIVE or kind == QUEST_PLAYER) then
            line.used = true
            if kind == QUEST_TITLE then
                title, player = line.left, nil
                titleQuest = line.data and Plain(line.data.id)
                if type(titleQuest) ~= "number" then titleQuest = nil end
            elseif kind == QUEST_PLAYER then
                player = line.left
            else
                local text, count = Split(line.left)
                if count == "" then count = line.right end
                shown[text] = true
                if not Done(line, count) then
                    if title then
                        QuestTitle(ctx, title, titleQuest)
                        title, last = nil, title
                    end
                    if player then
                        Read.Text("small", player, ASIDE[1], ASIDE[2], ASIDE[3]).indent = 18
                        player = nil
                    end
                    -- A sword where the objective names the creature, unless the database knows
                    -- it as a drop (Wolf Meat, on a wolf)
                    local chance = chances[text]
                    if chance then drops = drops + 1 end
                    Objective(text, count, (chance == nil and line.left:find(name, 1, true)) and "kill" or "loot", chance, "chance" .. drops)
                end
            end
        end
    end
    for index = 1, list.n do
        local entry = list[index]
        if entry.kind == "drop" then
            local text, count = Split(entry.text)
            if not shown[text] then
                shown[text] = true
                local title = ns.Quests.Title(entry.quest)
                if title ~= last then
                    QuestTitle(ctx, title, entry.quest)
                    last = title
                end
                if entry.extra then drops = drops + 1 end
                Objective(text, count, "loot", entry.extra, "chance" .. drops)
            end
        elseif entry.kind == "opener" then
            -- An item it drops that starts the quest: the !, the item's name and how often it drops
            QuestTitle(ctx, entry.text, entry.quest)
            last = entry.text
            local row = Read.Text("sub", ns.Quests.ItemName(entry.item) or TEXT.QUEST_ITEM, LIGHT[1], LIGHT[2], LIGHT[3])
            row.icon = "available"
            if entry.extra then
                drops = drops + 1
                row.label = Read.Memo("chance" .. drops, TEXT.CHANCE, entry.extra)
            end
            row.right, row.rr, row.rg, row.rb = TEXT.STARTS, DETAIL[1], DETAIL[2], DETAIL[3]
        else
            QuestTitle(ctx, entry.text, entry.quest)
            last = entry.text
            local row
            if entry.kind == "give" then
                row = Read.Text("sub", TEXT.OFFERS, LIGHT[1], LIGHT[2], LIGHT[3])
            else
                local color = entry.extra and DONE or DETAIL
                row = Read.Text("sub", entry.extra and TEXT.TURN_IN or TEXT.IN_PROGRESS, color[1], color[2], color[3])
            end
            row.icon = entry.kind == "give" and "available" or "active"
        end
    end
end

local function Unit(ctx)
    local unit = Token(ctx)
    if not unit then return Read.Generic() end
    local L, head, options = ctx.L, ctx.head, ctx.options
    local player = Plain(UnitIsPlayer(unit)) == true
    -- What the game says about it
    local className, class = UnitClass(unit)
    className, class = Plain(className), Plain(class)
    local level = Plain(UnitLevel(unit))
    local guild, guildRank
    if player and GetGuildInfo then
        guild, guildRank = GetGuildInfo(unit)
        guild, guildRank = Plain(guild), Plain(guildRank)
    end
    local race = player and Plain((UnitRace(unit))) or nil
    local creature = not player and Plain(UnitCreatureType(unit)) or nil
    local family = not player and UnitCreatureFamily and Plain(UnitCreatureFamily(unit)) or nil
    local sideName = Plain(select(2, UnitFactionGroup(unit))) -- the side, in the player's language
    local pvpWord = ns.Global("PVP") or TEXT.PVP -- the game's line says "Player vs. Player"; the panel says PvP
    local levelWord = level and (level > 0 and Read.Memo("level", "%d", level) or "??") or nil

    -- The tooltip's own lines that say the same: left out. Only the game's lines before its quest lines.
    local levelAt -- the line "Level 12 Humanoid": an NPC's title stands before it, its faction after it
    for index = 2, ctx.count do
        local line = L[index]
        local kind = line.type
        if kind == QUEST_TITLE or kind == QUEST_OBJECTIVE or kind == QUEST_PLAYER then break end
        if (line.own or not ctx.matched) and line.right == "" then
            local text = line.left
            local leveled = levelWord and Read.Family(line.lr, line.lg, line.lb) == "plain" and text:find(levelWord, 1, true)
            if leveled and not levelAt then levelAt = index end
            if text == guild or text == className or text == race or text == creature or text == family or text == sideName
                or text == pvpWord or text == TEXT.PVP or leveled then
                line.used = true
            end
        end
    end
    -- An NPC's title (Bowyer, <Flight Master>) or a pet's owner: its own line before the level line.
    -- Its faction (Stormwind): its own line right after the level line, unless that says something
    -- else the game says of a creature (skinnable, a corpse).
    local npcTitle, faction
    if not player then
        for index = 2, (levelAt or math.min(ctx.count, 4) + 1) - 1 do
            local line = L[index]
            if not line.used and not line.blank and line.right == "" and (line.own or not ctx.matched)
                and (levelAt or line.type == OWNER or line.left:match("^<.+>$")) then
                npcTitle, line.used = line.left, true
                break
            end
        end
        for index = (levelAt or ctx.count) + 1, math.min(ctx.count, (levelAt or ctx.count) + 2) do
            local line = L[index]
            local kind = line.type
            if kind == QUEST_TITLE or kind == QUEST_OBJECTIVE or kind == QUEST_PLAYER then break end
            if not line.used and not line.blank and line.right == "" and (line.own or not ctx.matched)
                and Read.Family(line.lr, line.lg, line.lb) == "plain" and not NOT_FACTION[line.left] then
                faction, line.used = line.left, true
                break
            end
        end
    end

    -- The header
    local title = Read.Title(true)
    local color = player and options.classColors and class and RAID_CLASS_COLORS[class] or nil
    if color then
        Read.Accent(color.r, color.g, color.b)
        title.lr, title.lg, title.lb = color.r, color.g, color.b
    else
        Read.AccentFromTitle()
    end
    -- Dead, a ghost or offline: the panel has no colour of its own
    if Plain(UnitIsDead(unit)) or Plain(UnitIsGhost(unit)) or (player and Plain(UnitIsConnected(unit)) == false) then
        Read.Accent(GONE[1], GONE[2], GONE[3])
    end
    -- A player's item level and talents: yours at once, another's once inspected (Inspect.lua)
    local guid = Plain(ctx.data.guid)
    local gear = player and levelWord and ns.Inspect.Level(unit, guid)
    local spec, points
    if player then spec, points = ns.Inspect.Talents(unit, guid) end

    -- Under the name, as large and close: the guild with the player's rank in it, small; a
    -- creature's title (<Flight Master>) or whose it is (a pet's owner)
    if guild then
        local row = Read.Text("title", Read.Memo("guild", "<%s>", guild), LIGHT[1], LIGHT[2], LIGHT[3])
        row.flush = true
        if guildRank and guildRank ~= "" then row.label, row.labelFont = guildRank, "detail" end
    elseif npcTitle then
        Read.Text("title", npcTitle, LIGHT[1], LIGHT[2], LIGHT[3]).flush = true
    end
    -- Small: the race and side (what a creature is, its family and its faction: Beast · Wolf,
    -- Humanoid · Stormwind), then the class line: the spec and class (Feral Combat Druid 0/31/20),
    -- the title, and what is true now: PvP, AFK, dead, ...
    local first = player and race or creature
    if player and race and sideName then
        first = Read.Memo("race", "%s  \194\183  %s", race, sideName)
    elseif not player and creature then
        local more = family ~= creature and family or nil
        if more and faction then
            first = Read.Memo("creature", "%s  \194\183  %s  \194\183  %s", creature, more, faction)
        elseif more or faction then
            first = Read.Memo("creature", "%s  \194\183  %s", creature, more or faction)
        end
    elseif not first then
        first = faction
    end
    -- A creature without a class of its own has its name for one: none then
    -- A creature's class: not for a friendly one (a vendor, a trainer), nor when it is only its name
    -- (the game's answer for a creature without a class)
    local classWord = className
    if classWord and not player and (classWord == L[1].left or classWord == Plain(UnitName(unit))
        or (Plain(UnitReaction(unit, "player")) or 0) >= FRIENDLY) then
        classWord = nil
    end
    -- What a dead creature yields, and its corpse line
    local skin, skinHex
    for index = 2, ctx.count do
        local line = L[index]
        if not line.used and (line.own or not ctx.matched) and line.right == "" then
            if line.left == CORPSE then
                line.used = true
            elseif SKINS[line.left] and not skin then
                skin, line.used = line.left, true
                skinHex = ns.Hex(line.lr or 0.8, line.lg or 0.8, line.lb or 0.8)
            end
        end
    end
    if classWord and spec then
        classWord = Read.Memo("spec", "%s %s |cff" .. POINTS_HEX .. "%s|r", spec, classWord, points)
    end
    if not first then first, classWord = classWord, nil end
    if first then Read.Text("detail", first, DETAIL[1], DETAIL[2], DETAIL[3]) end
    local rank = not player and Rank(unit) or nil
    local second = ClassLine(unit, player, rank, classWord, player and Title(unit, L[1].left) or nil, skin, skinHex)
    if second then Read.Text("detail", second, DETAIL[1], DETAIL[2], DETAIL[3]) end
    if options.icons then head.portrait = unit end
    -- The level on a gold plaque at the portrait's edge, in the colour of how hard the unit is for
    -- you; a player's item level before it
    head.badge = levelWord
    if gear then head.badge = Read.Memo("plaque", TEXT.PLAQUE, PLAQUE_HEX, gear, levelWord) end
    if levelWord then
        local difficulty = level > 0 and GetCreatureDifficultyColor and GetCreatureDifficultyColor(level) or COLOR.RED
        head.badgeR, head.badgeG, head.badgeB = difficulty.r or difficulty[1], difficulty.g or difficulty[2], difficulty.b or difficulty[3]
    end
    -- Without a portrait there is no plaque to hold it: the level stands right of the name.
    if head.badge and not head.portrait then
        title.right, title.rr, title.rg, title.rb = head.badge, head.badgeR, head.badgeG, head.badgeB
    end
    -- A dragon round the portrait: gold for a player and an elite, gold winged for a boss, silver for a
    -- rare and a rare elite; none for a creature without a rank
    local ranked = not player and RANKED[rank or ""]
    head.dragon = player and "elite" or ranked and ranked.dragon or nil

    -- Target, health, power, buffs: laid out here, filled and kept up to date by Live.lua, as long
    -- as the unit is this one (the GUID): "mouseover" is another unit, or none, once the mouse left it
    head.unit, head.guid = unit, Plain(UnitGUID(unit))
    head.hasTarget, head.hasAuras, head.power = ns.Live.Facts(unit)
    ctx.rule = true
    if head.hasTarget then
        local target = Read.Text("sub", ns.Global("TARGET") or TEXT.TARGET, DETAIL[1], DETAIL[2], DETAIL[3])
        target.live = "target"
    end
    local health = Read.Row()
    health.kind, health.live = "bar", "health"
    health.br, health.bg, health.bb = HEALTH[1], HEALTH[2], HEALTH[3]
    if head.power then
        local power = Read.Row()
        power.kind, power.live = "bar", "power" -- laid over the health bar's lower part
        local shade = PowerBarColor and (PowerBarColor[head.power] or PowerBarColor.MANA)
        if shade then power.br, power.bg, power.bb = shade.r, shade.g, shade.b end
    end
    if head.hasAuras then Read.Row().kind = "auras" end

    -- Experience and quests, then what else the tooltip says
    QuestSection(ctx, unit, not player and Read.NpcId(guid) or nil)
    ctx.rule = true
    Read.Rest()
end

if TYPE.Unit then ns.KINDS[TYPE.Unit] = Unit end
if TYPE.Corpse then ns.KINDS[TYPE.Corpse] = Unit end -- a dead creature's: the same panel
