local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Lore): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. Lore is the world's words
--  (Doc/ideas/Lore.md). Built first (Saneroki, 2026-10-28): talking to an NPC
--  as a scene over the world, in place of the game's gossip and quest windows
--  (Doc/ideas/Dialogue.md).
--    Native.lua   the game's gossip and quest windows held out of sight while
--                 ours shows the talk; given back in a fight, and at once for a
--                 talk ours does not show
--    Quiet.lua    the game's interface faded out while you talk; the tooltips
--                 of the talk's rewards, the game's questions and its error
--                 lines stay in sight
--    Rewards.lua  a quest's rewards, each item read for you: what it is (cloth,
--                 leather, mail, plate, a weapon, its slot), whether you can use
--                 it, what a vendor pays for it, what it changes against what you
--                 wear (item level, stats)
--    Look.lua     the fonts and shades the talk's parts share, the frame they
--                 stand in
--    Box.lua      the NPC's face, name and words, low in the middle of the screen
--    Answers.lua  what you can answer, in a column beside the words
--    Quest.lua    under the words: a quest's objectives, what it asks for, its
--                 rewards to choose from and to get
--    Keys.lua     Space goes on while the talk shows
--    Talk.lua     the talk as the game tells it (gossip, a quest's greeting,
--                 offer, progress, reward): the words a paragraph at a time, the
--                 answers, what Continue does
--  Standing down, the game's own windows are back and the interface in sight.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Lore", ns)

-- The game's own word where it has one.
local function Game(name, words)
    local text = rawget(_G, name)
    return type(text) == "string" and text or words
end

ns.TEXT = {
    talkHeader = "Talks",
    talkHeaderTip = "Talking to an NPC as a scene over the world, in place of the game's gossip and quest windows.",
    talk = "Talks as a scene",
    talkTip = "The NPC's face, name and words low in the middle of the screen, see-through over the world, a paragraph at a time; what you can answer in a column beside them; a quest's objectives and rewards under the words. A click on the words goes on, a right click goes back. Off: the game's own gossip and quest windows. A talk begun in a fight is the game's own, and a fight ends ours.",
    quiet = "Fade out the interface while talking",
    quietTip = "The bars, frames, minimap and chat fade out while you talk and come back when the talk ends (at once when a fight begins). The tooltips of the rewards, the game's questions and its error lines stay in sight.",
    shade = "Shade behind the words",
    shadeTip = "How dark the soft shade behind the words, the answers and the rewards is. 0: the words alone over the world.",
    size = "Size",
    sizeTip = "How large the talk is on the screen.",
    onward = "Words go on by themselves",
    onwardTip = "The next paragraph comes once the one shown is read, at your reading speed; the last one waits for you. Off: Space or a click on the words goes on.",
    speed = "Reading speed",
    speedTip = "How many words a minute you read, for the words that go on by themselves.",
    space = "Space goes on",
    spaceTip = "While a talk shows, Space shows the next paragraph; on the last one it does what needs no choosing: it accepts the quest offered, hands in a quest whose reward is chosen (or that has one or none to choose), takes the only answer there is, or says goodbye. Space jumps again once the talk ends.",

    -- The answers (Talk.lua).
    goodbye = Game("GOODBYE", "Goodbye"),
    accept = Game("ACCEPT", "Accept"),
    decline = Game("DECLINE", "Decline"),
    complete = Game("COMPLETE_QUEST", "Complete Quest"),
    notDone = "Not done yet",
    choose = "Choose a reward first",
    pay = "Complete Quest, paying %s",

    -- The quest under the words (Quest.lua).
    objectives = Game("QUEST_OBJECTIVES", "Quest Objectives"),
    asks = "It asks for",
    rewards = Game("REWARDS", "Rewards"),
    chooseOne = "Choose one",
    youGet = "You also get",
    youGetOnly = "You get",
    group = "For a group of %d",
    experience = "%s experience",
    honor = "%d honor",
    title = "The title %s",
    spell = "You learn %s",

    -- What a reward is (Rewards.lua).
    cantUse = "Can't use",
    emptySlot = "Your slot is empty",
    itemLevel = Game("ITEM_LEVEL_ABBR", "iLvl"),
    noValue = "Sells for nothing",
    sells = "Sells for %s",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the game's own talk windows are back, the interface in sight"

local OPTIONS = {
    { key = "talk", default = true, text = ns.TEXT.talk, tip = ns.TEXT.talkTip,
      header = ns.TEXT.talkHeader, headerTip = ns.TEXT.talkHeaderTip },
    { key = "quiet", default = true, text = ns.TEXT.quiet, tip = ns.TEXT.quietTip, parent = "talk" },
    { key = "shade", default = 30, min = 0, max = 100, step = 5, unit = "%", text = ns.TEXT.shade, tip = ns.TEXT.shadeTip,
      parent = "talk" },
    { key = "size", default = 100, min = 70, max = 150, step = 5, unit = "%", text = ns.TEXT.size, tip = ns.TEXT.sizeTip,
      parent = "talk" },
    { key = "onward", default = true, text = ns.TEXT.onward, tip = ns.TEXT.onwardTip, parent = "talk" },
    { key = "speed", default = 230, min = 100, max = 500, step = 10, text = ns.TEXT.speed, tip = ns.TEXT.speedTip,
      parent = "onward" },
    { key = "space", default = true, text = ns.TEXT.space, tip = ns.TEXT.spaceTip, parent = "talk" },
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "talk" then
        ns.Guarded(ns.Talk.Switched)
    elseif key == "quiet" then
        ns.Guarded(ns.Talk.Quieted)
    elseif key == "space" then
        ns.Guarded(ns.Keys.Update)
    elseif key == "shade" or key == "size" then
        ns.Guarded(ns.Talk.Redraw)
    end
end })

-- Standing down: no key of ours, the interface in sight, our talk hidden, the game's windows its own again.
function ns.GiveBack()
    ns.Safe("give back", ns.Keys.GiveBack)
    ns.Safe("give back", ns.Quiet.GiveBack)
    ns.Safe("give back", ns.Talk.GiveBack)
    ns.Native.GiveBack()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Talk.Start()
end
