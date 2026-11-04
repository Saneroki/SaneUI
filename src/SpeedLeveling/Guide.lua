local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Guide
--  The guide shown and followed: one of the guides kept, run by Sane UI itself
--  (Run.lua), whether pasted as text or bought and opened for your account
--  (Unlock.lua) (Saneroki, 2026-10-25: Speed Leveling stands on its own; the
--  leveling guide Sane UI knows is needed for nothing). One picture of it for
--  the view, the player's ways through it, and what its steps at hand want for
--  the key (Wanted.lua, Key.lua) and for the quest givers (Quests.lua).
--
--      Guide.Picture()    nil (no guide), or { title, levels, at, place, total, hand = { step } }: at: the step shown,
--                         place: your place in the guide as it is numbered for you (they differ while you look back)
--                         step = { number, shown, chain, done, paused, lines = { { text, done, have, need, count } } }
--                         (shown: the number to show; chain: a class quest's name and how far, in place of its number;
--                         paused: shown, but the guide goes by the others (Run.Shown); text in our colours; count: a
--                         thing to do, its have and need when it has a number; a line on hold left out)
--      Guide.Listed()     every step of the guide the list shows, in order, by number, and where in that the step you
--                         are at stands
--      Guide.Line(number) a listed step as the list says it: { number, shown, text, done, paused, onHold } (done:
--                         Run.Ticked, as the game knows it)
--      Guide.Pause(number), Guide.Skip(number), Guide.Back(), Guide.Go(number)
--      Guide.Targets(), Guide.Uses()  what the steps at hand want found and used; nil without a guide
--      Guide.Things()     the things of the world the steps at hand name to pick up or use (names)
--      Guide.UseOn()      the items the steps at hand name to use, with their lines' words: { { item, words } }
--      Guide.Quests()     what the steps at hand take and hand in: { take = { [quest] = true }, handin = ...,
--                         gossip = { option IDs }, choose = ... } (Run.Quests)
--      Guide.Target()     where the arrow points: a place (Run.Way's), and the step there (the picture's)
--      Guide.Doing(step)  what that step asks you to do: "talk", "kill", "loot", "use", ... (the arrow's picture)
--      Guide.Kept()       the guides to choose from, kept and from packs: { { key, name, title, group, subgroup,
--                         mine, bought, pack } }, by group, subgroup and name (parts and dividers not listed)
--      Guide.AddAll(texts, bought)  each guide's text kept (one of the same group and name replaced; one with no step
--                         to follow for this character is not kept): names, problems
--      Guide.LoadPacks()  the guide packs of this game loaded (at the start); each hands its guides to Guide.Take
--      Guide.Remove(key), Guide.Choose(key), Guide.Chosen()
--      Guide.Empty()      while no guide is followed, the view's words for why (none kept, none for you); else nil
--      Guide.State()      "on", "paused" or "off": your setting, and off wherever Speed Leveling is off
--      Guide.Following()  whether the guide is followed now: one chosen, and on (not paused, not off)
--      Guide.Watch(fn)    fn() whenever the picture may have changed (once a frame at most)
--
--  Kept for the account (Core.Store): each guide's text packed (the game's
--  deflate and base64, C_EncodingUtil) with its head (Format.Head), so the list
--  needs no guide read; for each character (Core.Character, Run.lua) which
--  guide it follows and where it is in each.
--
--  Guide packs (Saneroki, 2026-10-26: the guides that come for each game, there
--  to choose without a paste): an addon of Sane UI's for one game, made on this
--  computer, its TOC "## X-SaneUI-Guides: 1", "## X-SaneUI-Games: <game>" and
--  "## LoadOnDemand: 1". Loaded at the start, it hands its guides over:
--  SaneUI.SpeedLeveling.TakeGuides(addon, { head }), each head Format.Head's
--  fields and zlib, its text zlib-packed in base64. Not kept: the pack holds
--  them; a guide kept under the same group and name goes before the pack's.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Guide = {}
ns.Guide = Guide

local EMPTY = {}
local DEFLATE, ZLIB = 0, 1 -- the game's Enum.CompressionMethod.Deflate and Zlib, should their names be missing
local shipped = {} -- [key] = a pack's guide: its head and its text packed (zlib), pack = the addon, order
local taken = 0    -- the packs' guides handed over so far (their order)

-- A saved value as text; nil for anything else (a saved file may be damaged).
local function Text(value)
    return type(value) == "string" and value or nil
end
-- Our colours for names in a guide's words, by kind: the game's own font colours, these where it lacks one.
local COLOURS = {
    friend = { "GREEN_FONT_COLOR", "19FF19" }, foe = { "RED_FONT_COLOR", "FF2020" },
    loot = { "LIGHTBLUE_FONT_COLOR", "88AAFF" }, warn = { "NORMAL_FONT_COLOR", "FFD100" },
    pick = { "ORANGE_FONT_COLOR", "FF8040" }, buy = { "LIGHTYELLOW_FONT_COLOR", "FFFF9B" },
}

local watchers = {}
local later = {}   -- [guide's key] = what the guides after it take and hand in (Guide.Later), for the session
local Changed

local function Store()
    local store = Core.Store(ns.name)
    if type(store.guides) ~= "table" then store.guides = {} end
    return store.guides
end

local function Who()
    local _, race = Core.Ask(UnitRace, "player")
    local _, class = Core.Ask(UnitClass, "player")
    return { side = Plain(Core.Ask(UnitFactionGroup, "player")), race = Plain(race), class = Plain(class),
             level = Plain(Core.Ask(UnitLevel, "player")) or 1, game = Core.GAME }
end

-------------------------------------------------------------------------------
--  Colours
-------------------------------------------------------------------------------
local hexes  -- [kind] = our colour as eight hex digits, once made
local paints -- [kind] = { its colour word in a guide's text as a pattern, "|c" before it; "|c" and our colour }, once made
local picked -- the pattern of a name the colour word of a thing to pick up or use encloses; false: the format has none

local function Hex(kind)
    if not hexes then
        hexes = {}
        for name, colour in pairs(COLOURS) do
            local given = rawget(_G, colour[1])
            local r, g, b
            if type(given) == "table" and given.GetRGB then r, g, b = given:GetRGB() end
            if not r then r, g, b = Core.RGB(colour[2]) end
            hexes[name] = "ff" .. Core.Hex(r, g, b):lower()
        end
    end
    return hexes[kind]
end

-- Our warning colour, as a text's colour code has it ("ffffd100").
function Guide.WarnHex() return Hex("warn") end

-- The format's colour words by our kinds, as patterns, with our colour for each: Core's words do not change while the
-- game runs (Format.lua keeps its copy the same way), so they are asked once, not at every line painted.
local function Paints()
    if not paints then
        paints = {}
        local words = Core.Neighbours.Format("guide")
        for kind, word in pairs(words and words.colours or EMPTY) do
            local hex = type(word) == "string" and Hex(kind)
            if hex then paints[kind] = { "|c" .. word:gsub("%p", "%%%0"), "|c" .. hex } end
        end
        picked = paints.pick and (paints.pick[1] .. "(.-)|r") or false
    end
    return paints
end

-- A guide's words in our colours: its colour words, and its line breaks.
local function Paint(text)
    if type(text) ~= "string" then return "" end
    for _, paint in pairs(Paints()) do text = text:gsub(paint[1], paint[2]) end
    return (text:gsub("\\n", "\n"))
end

-- A guide's words as plain small letters, their colours and pictures gone: to find a name in them.
function Guide.Bare(text)
    return (Paint(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):lower())
end

-- The names the guide's words colour as things to pick up or use.
local function Picked(text, into)
    Paints()
    if type(text) ~= "string" or not picked then return end
    for name in text:gmatch(picked) do
        name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" then into[#into + 1] = name end
    end
end

-- "1-6 Durotar": the levels and the zone, split; a name without levels is all title.
local function Split(name)
    local levels, rest = (name or ""):match("^(%d+%s*%-%s*%d+)%s+(.+)$")
    return rest or name or "", levels
end

-------------------------------------------------------------------------------
--  The picture
-------------------------------------------------------------------------------
-- A step of the guide: its lines with words, places without words left out.
local function OurLines(index)
    local lines = {}
    for _, state in ipairs(ns.Run.Lines(index)) do
        local line = state.line
        local words = not state.onHold and ns.Run.Words(line)
        if words and (line.what ~= "place" or line.words) then
            lines[#lines + 1] = { text = Paint(words), done = state.done, count = ns.Format.DOING[line.what] or false,
                                  have = state.have, need = state.need, what = line.what,
                                  objective = line.what == "goal" and ns.Run.ObjectiveKind(line.quest, line.goal) or nil }
        end
    end
    return lines
end

-- The number a step is shown with: the guide's own, the steps of your professions apart (Gathering.lua); a step that
-- is not there (a number of another guide's list) by its number.
local function Shown(guide, index)
    local step = guide and guide.steps[index]
    return step and step.shown or index
end

function Guide.Picture()
    local guide = ns.Run.Guide()
    if not guide then return nil end
    local title, levels = Split(Paint(guide.title or guide.name))
    local picture = { title = title, levels = levels, at = math.min(ns.Run.At(), #guide.steps),
                      place = Shown(guide, math.min(ns.Run.Place(), #guide.steps)), total = guide.total or #guide.steps,
                      hand = {} }
    for _, index in ipairs(ns.Run.Shown()) do
        picture.hand[#picture.hand + 1] = { number = index, shown = Shown(guide, index), chain = guide.steps[index].chain,
                                            done = ns.Run.Ticked(index), paused = ns.Run.Paused(index),
                                            lines = OurLines(index) }
    end
    return picture
end

-- Whether a step has words to show.
local function Says(step)
    for _, line in ipairs(step.lines) do
        if ns.Run.Words(line) and (line.what ~= "place" or line.words) then return true end
    end
    return false
end

function Guide.Listed()
    local guide, list, at = ns.Run.Guide(), {}, 1
    if not guide then return list, at end
    local here = ns.Run.At()
    for index, step in ipairs(guide.steps) do
        if ns.Run.Listed(index) and Says(step) then
            list[#list + 1] = index
            if index <= here then at = #list end
        end
    end
    return list, at
end

function Guide.Line(number)
    local lines = OurLines(number)
    return { number = number, shown = Shown(ns.Run.Guide(), number), text = lines[1] and lines[1].text or "",
             done = ns.Run.Ticked(number), paused = ns.Run.Paused(number), onHold = ns.Run.OnHold(number) }
end

-- What a step asks you to do, in our words for the arrow's picture: "take", "handin" (a quest), "talk", "buy",
-- "train", "inn", "hearth", "fly", "kill", "loot", "use", or "go" (getting there is all). Its first thing to do not yet
-- done decides by its command (a quest's objective by the game's kind of it); else the first name its words colour.
local BY_WHAT = { take = "take", handin = "handin", shop = "buy", trainer = "train", learn = "train", bind = "inn",
                  hearth = "hearth", flightpath = "fly", fly = "fly", cast = "use", carry = "loot", kill = "kill" }
local BY_OBJECTIVE = { monster = "kill", item = "loot", object = "use" }
local BY_COLOUR = { foe = "kill", loot = "loot", pick = "use", friend = "talk", buy = "buy" }

-- The thing to do the first name coloured in words names: the colour that comes first.
local function ByColour(text)
    local first, doing
    text = text:lower()
    for kind, word in pairs(BY_COLOUR) do
        local at = text:find("|c" .. Hex(kind), 1, true)
        if at and (not first or at < first) then first, doing = at, word end
    end
    return doing
end

function Guide.Doing(step)
    for _, line in ipairs(step and step.lines or EMPTY) do
        if not line.done then
            local doing = BY_WHAT[line.what] or (line.objective and BY_OBJECTIVE[line.objective])
            if doing then return doing end
        end
    end
    for _, line in ipairs(step and step.lines or EMPTY) do
        local doing = not line.done and ByColour(line.text)
        if doing then return doing end
    end
    return "go"
end

-- Where the arrow points now: the place (as Run.Way takes it) and the step there (as the picture has it); nil for
-- nowhere.
function Guide.Target()
    local line, index = ns.Run.Target()
    if not line then return nil end
    return line, { number = index, lines = OurLines(index) }
end

-------------------------------------------------------------------------------
--  The player's ways through it
-------------------------------------------------------------------------------
function Guide.Go(number)
    ns.Run.Go(number)
    Changed()
end

function Guide.Back()
    ns.Run.Back()
    Changed()
end

-- A step at hand skipped (a right click): it counts as done, whichever of the steps at hand it is.
function Guide.Skip(number)
    ns.Run.Skip(number)
    Changed()
end

-- A step at hand paused (a click), or a paused one taken up again (Saneroki, 2026-11-04).
function Guide.Pause(number)
    ns.Run.Pause(number)
    Changed()
end

-- The guide on, paused or off. Off wherever Speed Leveling is off, that is outside the profile Speedleveling, whatever
-- the setting there says: nothing of it is to be seen then (Saneroki, 2026-10-30).
function Guide.State()
    return Core.Profiles.Leveling() and (ns.options.follow or "on") or "off"
end

-- Whether the guide is followed now: on (not paused, not off; Saneroki, 2026-10-26) and one is chosen.
function Guide.Following()
    return Guide.State() == "on" and ns.Run.Guide() ~= nil
end

function Guide.Targets()
    if not ns.options.guide or not Guide.Following() then return nil end
    return ns.Run.Targets()
end

function Guide.Uses()
    if not Guide.Following() then return nil end
    return ns.Run.Uses()
end

-- The items the steps at hand name to use, with the words of their lines (what each is used on).
function Guide.UseOn()
    if not ns.options.guide or not Guide.Following() then return nil end
    return ns.Run.UseOn()
end

function Guide.Things()
    if not Guide.Following() then return nil end
    local names = {}
    local steps = ns.Run.Guide().steps
    for _, index in ipairs(ns.Run.Hand()) do
        for _, name in ipairs(steps[index].things or EMPTY) do names[#names + 1] = name end
        for _, state in ipairs(ns.Run.Lines(index)) do
            if not (state.done or state.onHold) then Picked(ns.Run.Words(state.line), names) end
        end
    end
    return names
end

function Guide.Quests()
    if not Guide.Following() then return nil end
    return ns.Run.Quests()
end

-------------------------------------------------------------------------------
--  The guides kept
-------------------------------------------------------------------------------
-- A guide's text as kept: packed where the game packs, else as it is.
local function Pack(text)
    local encoding = rawget(_G, "C_EncodingUtil")
    local method = rawget(_G, "Enum") and Enum.CompressionMethod and Enum.CompressionMethod.Deflate or DEFLATE
    if encoding and encoding.CompressString and encoding.EncodeBase64 then
        local ok, packed = pcall(encoding.CompressString, text, method)
        local written = ok and type(packed) == "string" and Core.Ask(encoding.EncodeBase64, packed)
        if type(written) == "string" and written ~= "" then return { packed = written } end
    end
    return { text = text }
end

-- A guide's text again: as kept, or a pack's (zlib).
local function Unpack(kept)
    if type(kept.text) == "string" then return kept.text end
    local encoding = rawget(_G, "C_EncodingUtil")
    local methods = rawget(_G, "Enum") and Enum.CompressionMethod or EMPTY
    local written, method = kept.packed, methods.Deflate or DEFLATE
    if type(kept.zlib) == "string" then written, method = kept.zlib, methods.Zlib or ZLIB end
    if type(written) ~= "string" or not encoding then return nil end
    local bytes = Core.Ask(encoding.DecodeBase64, written)
    local text = type(bytes) == "string" and Core.Ask(encoding.DecompressString, bytes, method)
    return type(text) == "string" and text or nil
end

-- A guide's key: its group and its name, and for whom when its head says ("<<"): guides of one name for different
-- characters are kept apart.
local function KeyOf(group, name, only)
    group, only = Text(group), Text(only)
    local key = (group and group ~= "" and (group .. "\\") or "") .. name
    if only and only ~= "" then key = key .. " << " .. only end
    return key
end

-- Whether a kept guide is for this character in this game (what its record says of that counts only as words;
-- Format.Plays takes a list or nothing).
local function Mine(kept, who)
    local only = Text(kept.only)
    if only and only ~= "" and not ns.Format.For(who, only) then return false end
    return ns.Format.Plays(who, kept.games)
end

-- A guide by its key: kept (pasted or bought), else a pack's; nil for neither.
local function Entry(key)
    local kept = Store()[key]
    if type(kept) == "table" then return kept end
    return shipped[key]
end

-- A guide read for this character; nil for one not there or that cannot be read.
local function Read(key)
    local kept = Entry(key)
    if not kept then return nil end
    local text = Unpack(kept)
    if not text then return nil end
    local guide = ns.Format.Read(text, Who())
    if guide then
        guide.key = key
        -- No dungeon quests in a normal guide: also those Core's data knows where its text does not mark them.
        ns.Format.NoDungeonQuests(guide, ns.Lines.InDungeon)
    end
    return guide
end

-- Whether a guide read can be run here: for this character, and with a step to run (one read with none, a head alone
-- or every step somebody else's, would give the picture no step to show).
local function Runs(guide)
    return guide and guide.mine and guide.steps[1] ~= nil or false
end

-- The guides to choose from. A record's words count only where they are words, and one without a name is passed over
-- (a saved file may be damaged): no list and no menu fails on it.
function Guide.Kept()
    local list, who, seen = {}, Who(), {}
    local function Add(key, kept, pack)
        if seen[key] or type(kept) ~= "table" or kept.part or kept.divider or not Text(kept.name) then return end
        seen[key] = true
        list[#list + 1] = { key = key, name = kept.name, title = Text(kept.title), group = Text(kept.group) or "",
                            subgroup = Text(kept.subgroup) or "", mine = Mine(kept, who), bought = kept.bought == true,
                            pack = pack }
    end
    for key, kept in pairs(Store()) do Add(key, kept, false) end
    for key, kept in pairs(shipped) do Add(key, kept, true) end
    table.sort(list, function(a, b)
        if a.group ~= b.group then return a.group < b.group end
        if a.subgroup ~= b.subgroup then return a.subgroup < b.subgroup end
        return a.name < b.name
    end)
    return list
end

function Guide.Chosen()
    local guide = ns.Run.Guide()
    return guide and guide.key or nil
end

-- While no guide is followed, the words the view shows instead: none kept yet, or none of those kept is for this
-- character or this game. nil while one is followed.
function Guide.Empty()
    if ns.Run.Guide() then return nil end
    local kept = Guide.Kept()
    if not kept[1] then return ns.TEXT.noGuide end
    for _, guide in ipairs(kept) do
        if guide.mine then return ns.TEXT.noGuideChosen end
    end
    return ns.TEXT.noGuideHere
end

-- A kept guide to follow; nil: none, as is one that is not for this character or has no step for it.
function Guide.Choose(key)
    local guide = key and Read(key)
    ns.Run.Use(Runs(guide) and guide or nil)
    Changed()
end

-- Each guide's text kept by its group and name, for every character (what is for whom is read again for each).
function Guide.AddAll(texts, bought)
    local names, problems = {}, {}
    local store, who = Store(), Who()
    local first
    for _, text in ipairs(texts) do
        local head = ns.Format.Head(text)
        if head and not head.divider then
            local guide, found = ns.Format.Read(text, who)
            for _, problem in ipairs(found or EMPTY) do problems[#problems + 1] = head.name .. ", " .. problem end
            if not guide then
                problems[#problems + 1] = head.name .. ", nothing to follow in it: not kept"
            else
                -- Kept for the account (what is for whom is read again for each character); one with no step for
                -- this character now (every step another class's, or of a higher level) is never chosen for it.
                local key = KeyOf(head.group, head.name, head.only)
                local kept = Pack(text)
                kept.name, kept.group, kept.subgroup, kept.title = head.name, head.group, head.subgroup, head.title
                kept.only, kept.defaultFor, kept.after, kept.games = head.only, head.defaultFor, head.after, head.games
                kept.part, kept.bought = head.part, bought or nil
                store[key] = kept
                names[#names + 1] = head.name
                if not guide.steps[1] then
                    problems[#problems + 1] = head.name .. ", no step to follow for this character now: kept, not chosen"
                elseif not first and not head.part and Mine(kept, who) then
                    first = key
                end
            end
        end
    end
    later = {} -- the way after a guide may run through those kept now
    -- A character without a guide yet takes the first one for it.
    if first and not ns.Run.Guide() then Guide.Choose(first) end
    Changed()
    return names, problems
end

-- A kept guide forgotten (a pack's stays: the pack holds it).
function Guide.Remove(key)
    Store()[key] = nil
    later = {}
    if Guide.Chosen() == key then ns.Run.Use(nil) end
    Changed()
end

-- A guide by a name a guide's head gives ("Group\Name", or a name), kept or a pack's: its key. Of several, one of the
-- same group first, then the one for this character; a kept one before a pack's. A bare name stays in its group: one
-- there for somebody else is found, so After goes on to the next name (a normal guide's "35-36 Desolace" for hunters
-- never leads a warrior into the dungeon group's guide of that name).
local function Find(name, group, who)
    if Entry(name) then return name end
    local found, rank
    for _, guides in ipairs({ Store(), shipped }) do
        for key, kept in pairs(guides) do
            local named = type(kept) == "table" and Text(kept.name)
            if named and (named == name or KeyOf(kept.group, named) == name) then
                local this = ((kept.group or "") == (group or "") and 0 or 2) + (Mine(kept, who) and 0 or 1)
                if not rank or this < rank then found, rank = key, this end
            end
        end
    end
    return found
end

-------------------------------------------------------------------------------
--  Guide packs
-------------------------------------------------------------------------------
-- A pack hands its guides over as it is loaded: each a head with its text packed (zlib).
function Guide.Take(addon, guides)
    if type(guides) ~= "table" then return end
    for _, head in ipairs(guides) do
        if type(head) == "table" and type(head.name) == "string" and type(head.zlib) == "string" and not head.divider then
            taken = taken + 1
            head.pack, head.order = tostring(addon), taken
            if type(head.games) ~= "table" then head.games = {} end
            if type(head.after) ~= "table" then head.after = {} end
            shipped[KeyOf(head.group, head.name, head.only)] = head
        end
    end
end
ns.TakeGuides = ns.Guard(Guide.Take) -- what a pack calls (SaneUI.SpeedLeveling.TakeGuides)

-- The guide packs of this game (Sane UI's addons whose TOC says X-SaneUI-Guides), switched on for this character,
-- loaded: each hands its guides to Guide.Take as it loads.
function Guide.LoadPacks()
    local api = rawget(_G, "C_AddOns")
    if not (api and api.GetNumAddOns and api.LoadAddOn) then return end
    local character = Plain(Core.Ask(UnitGUID, "player"))
    for index = 1, Plain(Core.Ask(api.GetNumAddOns)) or 0 do
        local name = Plain(Core.Ask(api.GetAddOnInfo, index))
        if type(name) == "string" and name:find("^SaneUI_") and Core.Ask(api.GetAddOnMetadata, name, "X-SaneUI-Guides")
            and Core.ServesGame(name) and Core.Ask(api.GetAddOnEnableState, name, character) ~= 0
            and not Core.Ask(api.IsAddOnLoaded, name) then
            pcall(api.LoadAddOn, name)
        end
    end
end

-- The guides a character may start with, in order: those kept, then the packs' in the order they come.
local function Starts()
    local keys, packed = {}, {}
    for _, kept in ipairs(Guide.Kept()) do
        if not kept.pack then keys[#keys + 1] = kept.key end
    end
    for key, head in pairs(shipped) do
        if not head.part then packed[#packed + 1] = key end
    end
    table.sort(packed, function(a, b) return shipped[a].order < shipped[b].order end)
    for _, key in ipairs(packed) do keys[#keys + 1] = key end
    return keys
end

-- The guide a character starts with: the one it ran, else the first one whose head names it for its race or class.
local function Start()
    local notes = Core.Character(ns.name)
    local guide = type(notes.guide) == "string" and Read(notes.guide)
    if Runs(guide) then
        ns.Run.Use(guide)
        return
    end
    local who = Who()
    for _, key in ipairs(Starts()) do
        local entry = Entry(key)
        if Mine(entry, who) and type(entry.defaultFor) == "string" and ns.Format.For(who, entry.defaultFor) then
            local read = Read(key)
            if Runs(read) then
                ns.Run.Use(read)
                return
            end
        end
    end
end

-- The guide after one, read: the first it names that is kept and for this character; nil at the end of the way.
function Guide.After(guide)
    local who = Who()
    for _, after in ipairs(guide.after) do
        local key = Find(after.name, guide.group, who)
        local next = key and (not after.only or ns.Format.For(who, after.only)) and Read(key)
        if Runs(next) then return next end
    end
    return nil
end

-- What the guides after one take and hand in, all along the way their heads name (as Guide.After goes, by the heads
-- alone, each text only looked over: Format.Quests): a class quest a guide further on sees to is left to it
-- (ClassQuests.lua; Saneroki, 2026-11-04: a druid's Trial of the Sea Lion, taken at 16, is done by the guide at 24).
-- Kept per guide for the session. { take = { [quest] = true }, handin = { [quest] = true } }
function Guide.Later(guide)
    local key = guide and guide.key
    if not key then return { take = {}, handin = {} } end
    if later[key] then return later[key] end
    local found, who, seen = { take = {}, handin = {} }, Who(), { [key] = true }
    local names, group = guide.after, guide.group
    while names do
        local next
        for _, after in ipairs(names) do
            local name = Find(after.name, group, who)
            local entry = name and not seen[name] and Entry(name)
            if entry and Mine(entry, who) and (not after.only or ns.Format.For(who, after.only)) then
                next = entry
                seen[name] = true
                break
            end
        end
        if not next then break end
        for what, quests in pairs(ns.Format.Quests(Unpack(next))) do
            for quest in pairs(quests) do found[what][quest] = true end
        end
        names, group = next.after, next.group
    end
    later[key] = found
    return found
end

-- The guide run here is through: on to the one after it.
local function Onward()
    local guide = ns.Run.Guide()
    if not guide or not ns.Run.Through() then return end
    local next = Guide.After(guide)
    if next then ns.Run.Use(next) end
end

-------------------------------------------------------------------------------
--  Changes
-------------------------------------------------------------------------------
function Guide.Watch(fn) watchers[#watchers + 1] = fn end

local function Tell()
    for _, fn in ipairs(watchers) do ns.Safe("guide", fn) end
end
Changed = Core.Later(Tell)

-- The game changed: the guide moves on as far as done steps go, and on to the next guide once it is through.
local function Check()
    if not Guide.Following() then return ns.Run.Stop() end -- paused or off: it holds where it is, no place watched
    ns.Run.Check()
    if ns.Run.Through() then Onward() end
    ns.Run.Watch(Changed)
    Changed()
end
local checkSoon = Core.Later(Check, 0.2)
Guide.CheckSoon = checkSoon

-- Things the game tells only as they happen.
local function Saw(what)
    return function()
        if not Guide.Following() then return end
        ns.Run.Saw(what)
        checkSoon()
    end
end

local CHECKS = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_REMOVED", "BAG_UPDATE_DELAYED",
                 "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "PLAYER_MONEY", "SPELLS_CHANGED", "SKILL_LINES_CHANGED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS",
                 "PLAYER_ENTERING_WORLD", "UNIT_AURA", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
                 "UNIT_INVENTORY_CHANGED", "NEW_RECIPE_LEARNED" }

function Guide.Start()
    Guide.LoadPacks()
    Start()
    for _, event in ipairs(CHECKS) do
        if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
            ns.On(event, function(unit) if unit == "player" then checkSoon() end end)
        else
            ns.On(event, checkSoon)
        end
    end
    ns.On("HEARTHSTONE_BOUND", Saw("bind"))
    ns.On("TAXIMAP_OPENED", Saw("flightpath"))
    ns.On("MERCHANT_SHOW", Saw("shop"))
    ns.On("TRAINER_SHOW", Saw("trainer"))
    ns.On("PET_STABLE_SHOW", Saw("stable"))
    ns.On("PLAYER_UNGHOST", Saw("revive"))
    ns.On("PLAYER_CONTROL_LOST", Core.Later(function()
        if Core.Ask(rawget(_G, "UnitOnTaxi"), "player") then Saw("fly")() end
    end, 1))
    ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
        if unit ~= "player" or not Guide.Following() then return end
        spell = Plain(spell)
        if spell == ns.Run.HEARTH_SPELL or spell == ns.Run.RECALL then ns.Run.Saw("hearth") end
        if type(spell) == "number" then ns.Run.Saw("cast" .. spell) end
        checkSoon()
    end)
    Check()
end

function Guide.Stop()
    ns.Run.Stop()
end
