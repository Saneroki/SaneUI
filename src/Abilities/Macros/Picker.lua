local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Macros - Picker
--  The list behind the + button: the game's conditions by group, each with its
--  explanation. The same list serves a step's conditions and macro text. A
--  condition that needs a word more asks for it: a number from a short list, a
--  spell's or an item's name in a box. Macro text's list has the game's macro
--  commands over the conditions (Saneroki, 2026-11-07), each explained: a click
--  writes it on a line of its own where the cursor stands.
--
--  The commands are those the game runs in a fight, its secure ones
--  (Blizzard_ChatFrameBase, SlashCommands.lua: CheckAddSecureSlashCommand, and
--  CastSequenceManager.lua, CastRandomManager.lua), by the game's own word
--  (SLASH_<key>1), shown where the game has it (IsSecureCmd).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Picker = {}
Macros.Picker = Picker

Picker.NUMBERS = { stance = { 0, 1, 2, 3, 4, 5, 6 }, spec = { 1, 2, 3, 4 }, bar = { 1, 2, 3, 4, 5, 6 },
                   reset = { 3, 5, 10, 15, 20, 30, 60 } } -- reset: the cast sequence's pause, in seconds

-- The game's macro commands by group: key (the game's, SLASH_<key>1 its word), word (as the English client has it,
-- for where the game's is missing), takes (a name or a number follows), tip.
Picker.COMMANDS = {
    { name = "Fighting", items = {
        { key = "STARTATTACK", word = "/startattack", tip = "Starts your auto attack on your target, as a right click on a foe does." },
        { key = "STOPATTACK", word = "/stopattack", tip = "Stops your auto attack." },
        { key = "STOPCASTING", word = "/stopcasting", tip = "Stops the spell you are casting now, so the next line can cast at once." },
        { key = "CANCELQUEUEDSPELL", word = "/cancelqueuedspell", tip = "Takes back the spell that waits for the global cooldown to end." },
        { key = "STOPSPELLTARGET", word = "/stopspelltarget", tip = "Cancels a spell that waits for you to choose where it goes." },
        { key = "CANCELAURA", word = "/cancelaura", takes = true, tip = "Takes a buff of yours off, by its name." },
        { key = "CANCELFORM", word = "/cancelform", tip = "Leaves your form: a druid's shape, Ghost Wolf, Shadowform." },
        { key = "STOPMACRO", word = "/stopmacro", tip = "The lines after it do not run. With a condition, only while it holds: /stopmacro [nocombat]." },
    } },
    { name = "Casting", items = {
        { key = "CAST", word = "/cast", takes = true, tip = "Casts a spell by its name; with conditions, the first that holds: /cast [harm] Rend; Battle Shout." },
        { key = "USE", word = "/use", takes = true, tip = "Uses an item by its name, its number (item:6948) or its slot (13 and 14: your trinkets)." },
        { key = "CASTSEQUENCE", word = "/castsequence", takes = true, tip = "Casts a list in turn, going on only when one went off: /castsequence reset=target Rend, Hamstring." },
        { key = "CASTRANDOM", word = "/castrandom", takes = true, tip = "Casts one of a list at random, as a mount among your mounts." },
        { key = "USERANDOM", word = "/userandom", takes = true, tip = "Uses one item of a list at random." },
    } },
    { name = "Targeting", items = {
        { key = "TARGET", word = "/target", takes = true, tip = "Targets the nearest whose name begins so, or a unit: /target focus." },
        { key = "TARGET_EXACT", word = "/targetexact", takes = true, tip = "Targets only one of exactly that name." },
        { key = "TARGET_NEAREST_ENEMY", word = "/targetenemy", tip = "Targets the next foe, as Tab does." },
        { key = "TARGET_NEAREST_ENEMY_PLAYER", word = "/targetenemyplayer", tip = "Targets the next foe who is a player." },
        { key = "TARGET_NEAREST_FRIEND", word = "/targetfriend", tip = "Targets the next friend." },
        { key = "TARGET_NEAREST_FRIEND_PLAYER", word = "/targetfriendplayer", tip = "Targets the next friend who is a player." },
        { key = "TARGET_NEAREST_PARTY", word = "/targetparty", tip = "Targets the next member of your party." },
        { key = "TARGET_NEAREST_RAID", word = "/targetraid", tip = "Targets the next member of your raid." },
        { key = "TARGET_LAST_TARGET", word = "/targetlasttarget", tip = "Targets the one you had before." },
        { key = "TARGET_LAST_ENEMY", word = "/targetlastenemy", tip = "Targets the foe you had last." },
        { key = "TARGET_LAST_FRIEND", word = "/targetlastfriend", tip = "Targets the friend you had last." },
        { key = "CLEARTARGET", word = "/cleartarget", tip = "Clears your target." },
        { key = "ASSIST", word = "/assist", takes = true, tip = "Targets what that player has targeted; nothing after it: your target's target." },
        { key = "FOCUS", word = "/focus", takes = true, tip = "Makes a unit your focus; nothing after it: your target." },
        { key = "CLEARFOCUS", word = "/clearfocus", tip = "Clears your focus." },
    } },
    { name = "Pet", items = {
        { key = "PET_ATTACK", word = "/petattack", tip = "Sends your pet at your target." },
        { key = "PET_FOLLOW", word = "/petfollow", tip = "Calls your pet back to follow you." },
        { key = "PET_STAY", word = "/petstay", tip = "Your pet stays where it is." },
        { key = "PET_MOVE_TO", word = "/petmoveto", tip = "Sends your pet to a place you click." },
        { key = "PET_PASSIVE", word = "/petpassive", tip = "Your pet attacks nothing by itself." },
        { key = "PET_DEFENSIVE", word = "/petdefensive", tip = "Your pet attacks what attacks you or it." },
        { key = "PET_DEFENSIVEASSIST", word = "/petassist", tip = "Your pet attacks what you attack." },
        { key = "PET_AGGRESSIVE", word = "/petaggressive", tip = "Your pet attacks every foe near." },
        { key = "PET_DISMISS", word = "/petdismiss", tip = "Sends your pet away." },
    } },
    { name = "Gear and bars", items = {
        { key = "EQUIP", word = "/equip", takes = true, tip = "Puts on an item by its name." },
        { key = "EQUIP_TO_SLOT", word = "/equipslot", takes = true, tip = "Puts an item on in a slot: /equipslot 17 an off-hand's name." },
        { key = "EQUIP_SET", word = "/equipset", takes = true, tip = "Puts on an equipment set by its name." },
        { key = "CHANGEACTIONBAR", word = "/changeactionbar", takes = true, tip = "Turns Bar 1 to a page, 1 to 6." },
        { key = "SWAPACTIONBAR", word = "/swapactionbar", takes = true, tip = "Turns Bar 1 between two pages: /swapactionbar 1 2." },
        { key = "CLICK", word = "/click", takes = true, tip = "Clicks a button by its frame's name, as a press of it." },
    } },
    { name = "Group", items = {
        { key = "WORLD_MARKER", word = "/worldmarker", takes = true, tip = "Puts a world marker, 1 to 8, on the ground at the mouse: /worldmarker [@cursor] 1." },
        { key = "CLEAR_WORLD_MARKER", word = "/clearworldmarker", takes = true, tip = "Takes a world marker away, or all of them: /clearworldmarker 0." },
        { key = "MAINTANKON", word = "/maintank", takes = true, tip = "Makes a raid member a main tank." },
        { key = "MAINTANKOFF", word = "/maintankoff", takes = true, tip = "Ends a raid member's main tank mark." },
        { key = "MAINASSISTON", word = "/mainassist", takes = true, tip = "Makes a raid member a main assist." },
        { key = "MAINASSISTOFF", word = "/mainassistoff", takes = true, tip = "Ends a raid member's main assist mark." },
        { key = "DUEL", word = "/duel", tip = "Asks your target for a duel." },
        { key = "DUEL_CANCEL", word = "/yield", tip = "Gives up a duel." },
    } },
}

-- A command's word as the game has it; nil where the game does not run it (IsSecureCmd says no).
function Picker.Word(command)
    local word = rawget(_G, "SLASH_" .. command.key .. "1")
    if type(word) ~= "string" or word == "" then word = command.word end
    local known = rawget(_G, "IsSecureCmd")
    if known and not Core.Ask(known, word) then return nil end
    return word
end

-- The commands' groups, each command as a line that writes its word: given(word, takes).
local function Commands(root, given)
    root:CreateTitle(Macros.TEXT.commandsTitle)
    for _, group in ipairs(Picker.COMMANDS) do
        local line
        for _, command in ipairs(group.items) do
            local word = Picker.Word(command)
            if word then
                line = line or root:CreateButton(group.name)
                local entry = line:CreateButton(word, ns.Guard(function() given(word, command.takes) end))
                entry:SetTooltip(ns.Guard(function(tooltip)
                    GameTooltip_SetTitle(tooltip, word)
                    GameTooltip_AddNormalLine(tooltip, command.tip)
                end))
            end
        end
    end
    root:CreateTitle(Macros.TEXT.whenAdd)
end

-- A number from a short list, as a menu under the line.
local function Numbers(line, item, chosen)
    for _, number in ipairs(Picker.NUMBERS[item.word] or { 1, 2, 3 }) do
        line:CreateButton(tostring(number), ns.Guard(function() chosen(item.word, tostring(number)) end))
    end
end

-- A word in a box, once the line is clicked.
local function Ask(item, chosen)
    Core.AskText(Macros.TEXT.whenAsk, item.on, nil, nil, function(text)
        local value = text and text:match("^%s*(.-)%s*$")
        if value and value ~= "" then chosen(item.word, value) end
    end)
end

local function Line(group, item, chosen)
    local line
    if item.ask == "number" then
        line = group:CreateButton(item.on)
        Numbers(line, item, chosen)
    elseif item.ask then
        line = group:CreateButton(item.on, ns.Guard(function() Ask(item, chosen) end))
    else
        line = group:CreateButton(item.on, ns.Guard(function() chosen(item.word) end))
    end
    line:SetTooltip(ns.Guard(function(tooltip)
        GameTooltip_SetTitle(tooltip, item.on)
        GameTooltip_AddNormalLine(tooltip, item.tip)
    end))
end

-- Opens the list at owner; chosen(word, value) with what was picked. ours: Sane Macros' own words too (Once per
-- target), for a spell's or an item's step; never in macro text, which goes to the game as written. command(word,
-- takes): macro text's, the game's commands over the conditions.
function Picker.Open(owner, chosen, ours, command)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        if command then
            Commands(root, command)
        else
            root:CreateTitle(Macros.TEXT.whenAdd)
        end
        for _, group in ipairs(Macros.Conditions.Groups(ours)) do
            local line = root:CreateButton(group.name)
            for _, item in ipairs(group.items) do Line(line, item, chosen) end
        end
    end))
end
