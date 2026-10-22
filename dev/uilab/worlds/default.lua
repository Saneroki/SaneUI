-- The lab's fake server: a character, their guild, what the guild and the world say in chat. The people are made up;
-- the items are the game's own (their IDs from Sane UI's data master, which gives names, icons and qualities).
-- A scene may change any of it before its addons load (Lab.world()).
--
-- Names are a first name and a surname, as WoW: Forever's are. Chat lines may hold {item:ID}, {spell:ID} and
-- {player:Name}: the lab puts the game's links there. `at` is seconds after the login; the script runs again
-- `loop` seconds after its last line.
return {
    realm = "Forever",
    player = {
        name = "Elwyn", surname = "Thornbury", class = "MAGE", race = "Human", sex = 2, level = 60, faction = "Alliance",
        health = 3480, healthMax = 3480, power = 6120, powerMax = 6120, powerType = 0,
        zone = "Stormwind City", subzone = "The Mage Quarter", mapID = 1453, money = 2846311,
        stats = { strength = 34, agility = 41, stamina = 196, intellect = 291, spirit = 142, armor = 1035,
            crit = 6.4, spellCrit = 9.8, spellPower = 412, regen = 22, hit = 1 },
        equipped = { [1] = 22498, [2] = 18814, [3] = 22499, [5] = 22496, [6] = 22502, [7] = 22497, [8] = 22500,
            [9] = 22503, [10] = 22501, [11] = 23062, [13] = 23046, [14] = 19379, [15] = 21583, [16] = 22589 },
        bags = {
            [0] = { size = 16, name = "Backpack", items = { [1] = 6948, [2] = { 13444, 12 }, [3] = { 8766, 20 },
                [4] = { 14047, 34 }, [6] = { 20725, 3 }, [7] = { 14344, 5 }, [9] = { 19883, 7 } } },
        },
    },
    guild = {
        name = "The Inkwell Society",
        motd = "Molten Core Thursday at 8. Bring fire resistance and flasks; sign up in the calendar.",
        info = "A guild of friends who raid twice a week and level alts in between.",
        ranks = { "Guild Master", "Officer", "Veteran", "Member", "Initiate" },
        playerRank = 1,
        members = {
            { name = "Mirabel", surname = "Ashgrove", rank = 0, level = 60, class = "PRIEST", zone = "Stormwind City", online = true, note = "Raid lead, healers", officerNote = "Bank access" },
            { name = "Elwyn", surname = "Thornbury", rank = 1, level = 60, class = "MAGE", zone = "Stormwind City", online = true, note = "Enchanting 300" },
            { name = "Brannoc", surname = "Steelvein", rank = 1, level = 60, class = "WARRIOR", zone = "Blackrock Mountain", online = true, note = "Main tank" },
            { name = "Tamsin", surname = "Reedwater", rank = 2, level = 60, class = "DRUID", zone = "Moonglade", online = true, note = "Herbalism, Alchemy", status = 1 },
            { name = "Corwin", surname = "Halewood", rank = 2, level = 60, class = "PALADIN", zone = "Ironforge", online = true, note = "Blacksmithing" },
            { name = "Isolde", surname = "Merrow", rank = 3, level = 58, class = "HUNTER", zone = "Winterspring", online = true, note = "Levelling" },
            { name = "Pell", surname = "Underbough", rank = 3, level = 60, class = "ROGUE", zone = "Burning Steppes", online = true, status = 2 },
            { name = "Wendeline", surname = "Fairholt", rank = 3, level = 52, class = "WARLOCK", zone = "Felwood", online = true, note = "Alt of Tamsin" },
            { name = "Odo", surname = "Brightkettle", rank = 3, level = 60, class = "PRIEST", zone = "Ironforge", online = false, lastOnline = 2, note = "Tailoring" },
            { name = "Ysolde", surname = "Crane", rank = 3, level = 47, class = "MAGE", zone = "Tanaris", online = false, lastOnline = 5 },
            { name = "Harlan", surname = "Mossfield", rank = 4, level = 31, class = "WARRIOR", zone = "Duskwood", online = true, note = "New, says hi" },
            { name = "Ebba", surname = "Quillfeather", rank = 4, level = 24, class = "DRUID", zone = "Darkshore", online = false, lastOnline = 1 },
            { name = "Rowan", surname = "Tallowmere", rank = 3, level = 60, class = "PALADIN", zone = "Eastern Plaguelands", online = false, lastOnline = 9 },
            { name = "Sabine", surname = "Larkspur", rank = 2, level = 60, class = "ROGUE", zone = "Stormwind City", online = true, note = "Engineering" },
        },
    },
    party = {
        { name = "Brannoc", surname = "Steelvein", class = "WARRIOR", race = "Dwarf", level = 60, health = 7850, healthMax = 8200, powerType = 1, power = 34, powerMax = 100, leader = true },
        { name = "Mirabel", surname = "Ashgrove", class = "PRIEST", race = "Human", level = 60, health = 3900, healthMax = 3900, power = 4400, powerMax = 6900 },
    },
    others = {
        { name = "Garrick", surname = "Pennywhistle", class = "ROGUE", level = 60 },
        { name = "Lysa", surname = "Bramblecote", class = "SHAMAN", level = 44 },
    },
    channels = { { id = 1, name = "General - Stormwind City" }, { id = 2, name = "Trade - City" }, { id = 4, name = "LookingForGroup" } },
    loop = 40,
    script = {
        { at = 1, kind = "SYSTEM", text = "Welcome to World of Warcraft!" },
        { at = 2, kind = "GUILD", from = "Mirabel Ashgrove", text = "Evening all! MC tonight, invites at quarter to." },
        { at = 4, kind = "GUILD", from = "Brannoc Steelvein", text = "Repaired and ready. Anyone got spare {item:13444}?" },
        { at = 6, kind = "CHANNEL", channel = 2, from = "Garrick Pennywhistle", text = "WTS {item:20725} and {item:14344}, whisper me" },
        { at = 8, kind = "WHISPER", from = "Tamsin Reedwater", text = "Could you make me a stack of water before the raid?" },
        { at = 10, kind = "PARTY", from = "Brannoc Steelvein", text = "Pulling in 5, mana check" },
        { at = 12, kind = "SAY", from = "Lysa Bramblecote", text = "Does anyone know where the mage trainer is?" },
        { at = 15, kind = "GUILD", from = "Harlan Mossfield", text = "Just hit 31! Thanks for the help in Duskwood, {player:Corwin Halewood}." },
        { at = 18, kind = "YELL", from = "Garrick Pennywhistle", text = "Onyxia's head is up in the square!" },
        { at = 21, kind = "OFFICER", from = "Mirabel Ashgrove", text = "Loot council after the raid, ten minutes." },
        { at = 24, kind = "CHANNEL", channel = 4, from = "Lysa Bramblecote", text = "LF2M Scarlet Monastery, need healer and tank" },
        { at = 27, kind = "EMOTE", from = "Pell Underbough", text = "waves at everyone." },
    },
}
