local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Conditions
--  The game's macro conditions in plain words. The game judges them: Sane Macros
--  only writes them, as the words between a macro's square brackets. Each entry
--  says what it means, and its opposite (the game's word with "no" before it).
--
--  An entry: word (the game's), on and off (the two sides in plain words), tip;
--  ask, a word to ask for what comes after the colon ("stance:2").
--
--  The game takes a word it does not know as true, without a sound. So the list
--  of words stands here (WORDS), for the check of macro text too.
--
--  An entry with ours is Sane Macros' own, not the game's: it never stands
--  between the brackets and has no opposite. Once per target (Saneroki,
--  2026-11-07: "/cast [if no rend] Rend", and "not only Rend"): the press may not
--  read a target's auras, so the step is written as the game's own cast sequence
--  (Write.lua), which waits after the cast until the target changes.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Conditions = {}
Macros.Conditions = Conditions

Conditions.GROUPS = {
    { name = "Fight", items = {
        { word = "combat", on = "In a fight", off = "Out of a fight",
          tip = "True while you are in combat." },
        { word = "channeling", on = "Channeling", off = "Not channeling",
          tip = "True while you channel any spell, like a drain or a rain of fire." },
        { word = "channeling", ask = "spell", on = "Channeling a certain spell", off = "Not channeling that spell",
          tip = "True while you channel the spell you name." },
    } },
    { name = "Keys and mouse", items = {
        { word = "mod:shift", on = "Shift held", off = "Shift not held", tip = "True while you hold Shift as you press." },
        { word = "mod:ctrl", on = "Ctrl held", off = "Ctrl not held", tip = "True while you hold Ctrl as you press." },
        { word = "mod:alt", on = "Alt held", off = "Alt not held", tip = "True while you hold Alt as you press." },
        { word = "mod", on = "Any of them held", off = "None of them held",
          tip = "True while you hold Shift, Ctrl or Alt." },
        { word = "btn:1", on = "Left click or a key", off = "Not a left click",
          tip = "True for a left click on the button. A key press counts as a left click." },
        { word = "btn:2", on = "Right click", off = "Not a right click",
          tip = "True for a right click on a macro's bar button. Give one step this and another Left click, and each mouse button does its own." },
        { word = "btn:3", on = "Middle click", off = "Not a middle click", tip = "True for a click of the mouse wheel." },
    } },
    { name = "Target", items = {
        { word = "exists", on = "Someone is there", off = "Nobody is there",
          tip = "True if there is anyone to cast on: your target, or whoever the step's Cast on names." },
        { word = "harm", on = "An enemy", off = "Not an enemy", tip = "True if the target can be attacked." },
        { word = "help", on = "A friend", off = "Not a friend", tip = "True if the target can be helped." },
        { word = "dead", on = "Dead", off = "Alive", tip = "True if the target is dead." },
        { word = "once", ours = true, on = "Once per target", off = "Once per target",
          tip = "Cast once on each target, as a Rend, a Hunter's Mark or a Faerie Fire. After the cast its turn does nothing until you change target or the fight ends, and the next press goes on. The game does not say when it runs out or misses. For a spell or an item, with Each press takes the next step." },
    } },
    { name = "Where you are", items = {
        { word = "indoors", on = "Indoors", off = "Not indoors", tip = "True inside a building or a cave, where mounts cannot go." },
        { word = "outdoors", on = "Outdoors", off = "Not outdoors", tip = "True under the open sky." },
        { word = "swimming", on = "Swimming", off = "Not swimming", tip = "True while you are in the water." },
        { word = "flying", on = "Flying", off = "Not flying", tip = "True while you are up in the air on a flying mount." },
        { word = "flyable", on = "Flying is allowed here", off = "No flying here", tip = "True where the game allows flying." },
        { word = "mounted", on = "Mounted", off = "Not mounted", tip = "True while you sit on a mount." },
        { word = "resting", on = "Resting", off = "Not resting", tip = "True in an inn or a city." },
        { word = "stealth", on = "In stealth", off = "Not in stealth", tip = "True while you are stealthed." },
    } },
    { name = "Stance and form", items = {
        { word = "stance", ask = "number", on = "In a stance or form", off = "Not in that stance or form",
          tip = "Name its number: its place on your stance bar, 0 for none. A warrior: 1 Battle, 2 Defensive, 3 Berserker." },
        { word = "stance", on = "In any stance or form", off = "In no stance or form", tip = "True in any stance, form or shape." },
    } },
    { name = "Group", items = {
        { word = "group", on = "In a group", off = "Not in a group", tip = "True in a party or a raid." },
        { word = "group:party", on = "In a party", off = "Not in a party", tip = "True in a party." },
        { word = "group:raid", on = "In a raid", off = "Not in a raid", tip = "True in a raid." },
    } },
    { name = "Pet", items = {
        { word = "pet", on = "You have a pet", off = "You have no pet", tip = "True while a pet of yours is out." },
        { word = "pet", ask = "name", on = "A certain pet", off = "Not that pet",
          tip = "True while this pet is out: its name, or its kind, like Imp or Bear." },
    } },
    { name = "What you know and wear", items = {
        { word = "known", ask = "spell", on = "You know a spell", off = "You do not know that spell",
          tip = "True if this character has learned the spell you name." },
        { word = "equipped", ask = "gear", on = "Wearing a kind of gear", off = "Not wearing that",
          tip = "True while you wear it: an item's name, or a kind like Shields, Daggers or Two-Handed Swords." },
        { word = "spec", ask = "number", on = "In a specialization", off = "Not in that specialization",
          tip = "Name its number: the place of your specialization, from the left.", game = "retail" },
    } },
    { name = "Bars and vehicles", items = {
        { word = "bar", ask = "number", on = "Bar 1 shows a page", off = "Bar 1 does not show that page",
          tip = "Name the page's number, 1 to 6." },
        { word = "vehicleui", on = "In a vehicle", off = "Not in a vehicle", tip = "True while the game shows a vehicle's bar." },
        { word = "canexitvehicle", on = "You can leave the vehicle", off = "You cannot leave a vehicle", tip = "True in a vehicle you can get out of." },
        { word = "overridebar", on = "The game replaced your bar", off = "Your bar is your own", tip = "True while the game shows a bar of its own in place of yours." },
        { word = "possessbar", on = "Controlling a creature", off = "Not controlling a creature", tip = "True while you control a creature and its bar shows." },
        { word = "extrabar", on = "The extra button is up", off = "No extra button", tip = "True while the game shows its extra action button." },
        { word = "petbattle", on = "In a pet battle", off = "Not in a pet battle", tip = "True in a pet battle.", game = "retail" },
    } },
}

-- Every word the game knows there, for the check of macro text, by what stands before a colon.
Conditions.WORDS = {}
for word in ([[combat exists help harm dead party raid group mod modifier btn button stance form stealth swimming
    mounted flying flyable advflyable indoors outdoors resting pet vehicleui unithasvehicleui canexitvehicle overridebar
    possessbar shapeshift extrabar petbattle bonusbar bar actionbar channeling equipped worn known spec talent
    pvptalent]]):gmatch("%S+") do
    Conditions.WORDS[word] = true
end

-- Sane Macros' own words (an entry with ours): [word] = true.
Conditions.OURS = {}
for _, group in ipairs(Conditions.GROUPS) do
    for _, item in ipairs(group.items) do
        if item.ours then Conditions.OURS[item.word] = true end
    end
end

-- What cannot hold together. Opposites of one word are found without a list.
Conditions.APART = { { "help", "harm" }, { "indoors", "outdoors" } }

-- The entries of this game, group by group; Sane Macros' own too where ours (a spell's or an item's step).
function Conditions.Groups(ours)
    local groups = {}
    for _, group in ipairs(Conditions.GROUPS) do
        local items = {}
        for _, item in ipairs(group.items) do
            if (not item.game or item.game == Core.GAME) and (ours or not item.ours) then items[#items + 1] = item end
        end
        if items[1] then groups[#groups + 1] = { name = group.name, items = items } end
    end
    return groups
end

-- A condition of a step as the game's word: "harm", "nocombat", "stance:2".
function Conditions.Text(condition)
    return (condition.no and "no" or "") .. condition.word .. (condition.value and ":" .. condition.value or "")
end

-- Its plain words, for a step's list. Unlisted words (from a game macro) show as they are.
function Conditions.Words(condition)
    for _, group in ipairs(Conditions.GROUPS) do
        for _, item in ipairs(group.items) do
            if item.word == condition.word and (item.ask ~= nil) == (condition.value ~= nil) then
                local words = condition.no and item.off or item.on
                return condition.value and words .. ": " .. condition.value or words, item.tip
            end
        end
    end
    return Conditions.Text(condition), nil
end

-- One word of a bracket, as the game reads it: without its "no", and what stands before the colon.
function Conditions.Stem(word)
    local bare = word:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local no = bare:sub(1, 2) == "no" and not Conditions.WORDS[(bare:gsub(":.*", ""))]
    if no then bare = bare:sub(3) end
    return (bare:gsub(":.*", "")), no
end
