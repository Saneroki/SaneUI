local _, ns = ...
local D = ns.Data

-- The spells quests give, by class and spell ID. Each row is one way to the reward:
-- { raceIDs = { the game's race IDs }, level = the level its first quest needs,
--   area = the zone (AreaTable ID) where it starts, or areas = { several }, quests = { the quests that give it } }.
-- The first row that names your race is yours (Trainer.lua, D.AddQuestSpells).
local QuestSpells = {
    WARRIOR = {
        [71] = { -- Defensive Stance
            { raceIDs = { 2, 6, 8 }, level = 10, area = 17, quests = { 1498 } },
            { raceIDs = { 5 }, level = 10, area = 85, quests = { 1819 } },
            { raceIDs = { 1 }, level = 10, area = 1519, quests = { 1665 } },
            { raceIDs = { 3, 7 }, level = 10, area = 1537, quests = { 1678 } },
            { raceIDs = { 4 }, level = 10, area = 1657, quests = { 1683 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94003 } },
        },
        [355] = { -- Taunt
            { raceIDs = { 2, 6, 8 }, level = 10, area = 17, quests = { 1498 } },
            { raceIDs = { 5 }, level = 10, area = 85, quests = { 1819 } },
            { raceIDs = { 1 }, level = 10, area = 1519, quests = { 1665 } },
            { raceIDs = { 3, 7 }, level = 10, area = 1537, quests = { 1678 } },
            { raceIDs = { 4 }, level = 10, area = 1657, quests = { 1683 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94003 } },
        },
        [7386] = { -- Sunder Armor
            { raceIDs = { 2, 6, 8 }, level = 10, area = 17, quests = { 1498 } },
            { raceIDs = { 5 }, level = 10, area = 85, quests = { 1819 } },
            { raceIDs = { 1 }, level = 10, area = 1519, quests = { 1665 } },
            { raceIDs = { 3, 7 }, level = 10, area = 1537, quests = { 1678 } },
            { raceIDs = { 4 }, level = 10, area = 1657, quests = { 1683 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94003 } },
        },
        [2458] = { -- Berserker Stance
            { raceIDs = { 1, 2, 3, 4, 5, 6, 7, 8, 95, 96 }, level = 30, area = 17, quests = { 1719 } },
        },
        [20252] = { -- Intercept
            { raceIDs = { 1, 2, 3, 4, 5, 6, 7, 8, 95, 96 }, level = 30, area = 17, quests = { 1719 } },
        },
    },
    PALADIN = {
        [635] = { -- Holy Light
            { raceIDs = { 5 }, level = 2, area = 85, quests = { 90902 } },
        },
        [7328] = { -- Redemption
            { raceIDs = { 3 }, level = 12, area = 1537, quests = { 1785 } },
            { raceIDs = { 1 }, level = 12, area = 1519, quests = { 1788 } },
            { raceIDs = { 5 }, level = 12, area = 85, quests = { 94441 } },
        },
        [5502] = { -- Sense Undead
            { raceIDs = { 1, 3 }, level = 20, areas = { 1519, 1537 }, quests = { 1652 } },
        },
        [13819] = { -- Summon Warhorse
            { raceIDs = { 1, 3 }, level = 40, area = 1519, quests = { 1661 } },
        },
        [23214] = { -- Summon Charger
            { raceIDs = { 1, 3 }, level = 60, area = 1519, quests = { 7647 } },
        },
    },
    HUNTER = {
        [1515] = { -- Tame Beast
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6082 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6088 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6085 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6102 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94013 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94864 } },
        },
        [5149] = { -- Beast Training
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6081 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6089 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6086 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6103 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94050 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94793 } },
        },
        [883] = { -- Call Pet
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6081 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6089 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6086 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6103 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94050 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94793 } },
        },
        [2641] = { -- Dismiss Pet
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6081 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6089 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6086 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6103 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94050 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94793 } },
        },
        [6991] = { -- Feed Pet
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6081 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6089 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6086 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6103 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94050 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94793 } },
        },
        [982] = { -- Revive Pet
            { raceIDs = { 2, 8 }, level = 10, area = 14, quests = { 6081 } },
            { raceIDs = { 6 }, level = 10, area = 215, quests = { 6089 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 6086 } },
            { raceIDs = { 4 }, level = 10, area = 141, quests = { 6103 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94050 } },
            { raceIDs = { 1 }, level = 10, area = 12, quests = { 94793 } },
        },
    },
    ROGUE = {
        [2842] = { -- Poisons
            { raceIDs = { 1, 3, 4, 7, 95 }, level = 20, area = 1519, quests = { 2359 } },
            { raceIDs = { 2, 5, 8 }, level = 20, area = 1637, quests = { 2480 } },
        },
    },
    PRIEST = {
        [13908] = { -- Desperate Prayer
            { raceIDs = { 3 }, level = 10, areas = { 12, 1, 1519, 1537, 1657, 141 }, quests = { 5635, 5637, 5638, 5639, 5640, 5634, 5636 } },
        },
        [13896] = { -- Feedback
            { raceIDs = { 1 }, level = 20, areas = { 1519, 1537, 1657 }, quests = { 5676, 5677, 5678 } },
        },
        [10797] = { -- Starshards
            { raceIDs = { 4 }, level = 10, areas = { 1657, 12, 141, 1, 1519, 1537 }, quests = { 5627, 5628, 5629, 5630, 5631, 5632, 5633 } },
        },
        [2651] = { -- Elune's Grace
            { raceIDs = { 4 }, level = 20, areas = { 1657, 1519, 1537 }, quests = { 5672, 5673, 5674, 5675 } },
        },
        [2652] = { -- Touch of Weakness
            { raceIDs = { 5 }, level = 10, areas = { 1497, 14, 215, 1637, 1638 }, quests = { 5658, 5660, 5661, 5662, 5663 } },
        },
        [9035] = { -- Hex of Weakness
            { raceIDs = { 8 }, level = 10, areas = { 1637, 14, 215, 1497 }, quests = { 5652, 5654, 5655, 5656, 5657 } },
        },
        [18137] = { -- Shadowguard
            { raceIDs = { 8 }, level = 20, areas = { 1638, 1497, 1637 }, quests = { 5642, 5643, 5680 } },
        },
        [1277370] = { -- Divine Grace
            { raceIDs = { 1 }, level = 10, areas = { 1519, 12 }, quests = { 94773, 94774, 94775, 94776, 94777, 94778, 94779 } },
        },
        [1277331] = { -- Chastise
            { raceIDs = { 3 }, level = 20, areas = { 1537, 1519, 1657 }, quests = { 5641, 5645, 5647 } },
        },
        [1277324] = { -- Dark Sacrifice
            { raceIDs = { 5 }, level = 20, areas = { 1638, 1637, 1497 }, quests = { 5644, 5646, 5679 } },
        },
        [1277455] = { -- Confounding Flash
            { raceIDs = { 7 }, level = 10, areas = { 1537, 1 }, quests = { 94817, 94821, 94822, 94823, 94824, 94825, 94826 } },
        },
        [1277462] = { -- Contingency Plan
            { raceIDs = { 7 }, level = 20, area = 1537, quests = { 94818, 94819, 94820 } },
        },
    },
    SHAMAN = {
        [8071] = { -- Stoneskin Totem
            { raceIDs = { 2, 6 }, level = 4, areas = { 14, 215 }, quests = { 1518, 1521 } },
            { raceIDs = { 8 }, level = 4, area = 14, quests = { 1518 } },
            { raceIDs = { 3 }, level = 4, area = 1, quests = { 94375 } },
            { raceIDs = { 96 }, level = 3, area = 16593, quests = { 92468 } },
        },
        [3599] = { -- Searing Totem
            { raceIDs = { 2, 6, 8 }, level = 10, area = 17, quests = { 1527 } },
            { raceIDs = { 3 }, level = 10, area = 1, quests = { 94468 } },
            { raceIDs = { 96 }, level = 10, area = 16593, quests = { 97257 } },
        },
        [5394] = { -- Healing Stream Totem
            { raceIDs = { 2, 6, 8 }, level = 20, area = 17, quests = { 96 } },
            { raceIDs = { 3 }, level = 20, area = 38, quests = { 94505 } },
        },
    },
    MAGE = {
        [28272] = { -- Polymorph: Pig
            { raceIDs = { 1, 2, 3, 4, 5, 6, 7, 8, 95, 96 }, level = 60, area = 16, quests = { 9364 } },
        },
        [10140] = { -- Conjure Water Rank 7
            { raceIDs = { 1, 2, 3, 4, 5, 6, 7, 8, 95, 96 }, level = 60, area = 2557, quests = { 7463 } },
        },
    },
    WARLOCK = {
        [688] = { -- Summon Imp
            { raceIDs = { 5 }, level = 1, area = 85, quests = { 1470 } },
            { raceIDs = { 2, 8 }, level = 1, area = 14, quests = { 1485 } },
            { raceIDs = { 1 }, level = 1, area = 12, quests = { 1598 } },
            { raceIDs = { 7 }, level = 1, area = 1, quests = { 1599 } },
        },
        [697] = { -- Summon Voidwalker
            { raceIDs = { 5 }, level = 10, area = 1497, quests = { 1471 } },
            { raceIDs = { 2, 8 }, level = 10, area = 1637, quests = { 1504 } },
            { raceIDs = { 1, 7 }, level = 10, area = 1519, quests = { 1689 } },
        },
        [712] = { -- Summon Succubus
            { raceIDs = { 5 }, level = 20, area = 1497, quests = { 1474 } },
            { raceIDs = { 2, 8 }, level = 20, area = 1637, quests = { 1513 } },
            { raceIDs = { 1, 7 }, level = 20, area = 1519, quests = { 1739 } },
        },
        [713] = { -- Summon Incubus
            { raceIDs = { 5 }, level = 20, area = 1497, quests = { 65597 } },
            { raceIDs = { 2, 8 }, level = 20, area = 1637, quests = { 65604 } },
            { raceIDs = { 1, 7 }, level = 20, area = 17, quests = { 65603 } },
        },
        [691] = { -- Summon Felhunter
            { raceIDs = { 1, 2, 5, 7, 8 }, level = 30, area = 17, quests = { 1795 } },
        },
        [5784] = { -- Summon Felsteed
            { raceIDs = { 1, 2, 5, 7, 8 }, level = 40, area = 17, quests = { 4490 } },
        },
        [1122] = { -- Inferno
            { raceIDs = { 1, 2, 5, 7, 8 }, level = 50, area = 361, quests = { 7603 } },
        },
        [18540] = { -- Ritual of Doom
            { raceIDs = { 1, 2, 5, 7, 8 }, level = 60, area = 4, quests = { 7583 } },
        },
        [23161] = { -- Summon Dreadsteed
            { raceIDs = { 1, 2, 5, 7, 8 }, level = 60, area = 46, quests = { 7631 } },
        },
    },
    DRUID = {
        [5487] = { -- Bear Form
            { raceIDs = { 4 }, level = 10, area = 1657, quests = { 6001 } },
            { raceIDs = { 6 }, level = 10, area = 1638, quests = { 6002 } },
            { raceIDs = { 95, 96 }, level = 10, area = 16593, quests = { 94638 } },
        },
        [18960] = { -- Teleport: Moonglade
            { raceIDs = { 4 }, level = 10, area = 1657, quests = { 5921 } },
            { raceIDs = { 6 }, level = 10, area = 1638, quests = { 5922 } },
            { raceIDs = { 96 }, level = 10, area = 1638, quests = { 94913 } },
            { raceIDs = { 95 }, level = 10, area = 1519, quests = { 94914 } },
        },
        [768] = { -- Cat Form
            { raceIDs = { 4, 95 }, level = 20, area = 1657, quests = { 98397 } },
            { raceIDs = { 6, 96 }, level = 20, area = 1638, quests = { 98362 } },
        },
        [8946] = { -- Cure Poison
            { raceIDs = { 4 }, level = 14, area = 1657, quests = { 6125 } },
            { raceIDs = { 6 }, level = 14, area = 1638, quests = { 6130 } },
        },
        [1066] = { -- Aquatic Form
            { raceIDs = { 4 }, level = 16, area = 1657, quests = { 5061 } },
            { raceIDs = { 6 }, level = 16, area = 1638, quests = { 31 } },
        },
    },
}

-- Your race is known at login (Trainer.lua, D.Fill).
D.AtLogin(function() D.AddQuestSpells(QuestSpells) end)
