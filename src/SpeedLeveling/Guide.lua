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
--      Guide.Picture(count, shift)  nil (no guide), or { title, levels, at, place, total, hand = { step },
--                         ahead = { line }, shift }: count steps listed from the one after those at hand, moved by
--                         shift (back for less than 0; picture.shift: as far as it went); at: the step shown, place:
--                         your place in the guide (they differ while you look back)
--                         step = { number, done, lines = { { text, done, have, need, count } } },
--                         line = { number, text, done } (done: Run.Ticked, as the game knows it)
--                         (text in our colours; count: a thing to do, its have and need when it has a number)
--      Guide.Skip(number), Guide.Back(), Guide.Go(number)
--      Guide.Targets(), Guide.Uses()  what the steps at hand want found and used; nil without a guide
--      Guide.Things()     the things of the world the steps at hand name to pick up or use (names)
--      Guide.UseOn()      the items the steps at hand name to use, with their lines' words: { { item, words } }
--      Guide.Quests()     what the steps at hand take and hand in: { take = { [quest] = true }, handin = ...,
--                         gossip = { option IDs }, choose = ... } (Run.Quests)
--      Guide.Target()     where the arrow points: a place (Run.Way's), and the step there (the picture's)
--      Guide.Doing(step)  what that step asks you to do: "talk", "kill", "loot", "use", ... (the arrow's picture)
--      Guide.Kept()       the guides to choose from, kept and from packs: { { key, name, title, group, subgroup,
--                         mine, bought, pack } }, by group, subgroup and name (parts and dividers not listed)
--      Guide.AddAll(texts, bought)  each guide's text kept (one of the same group and name replaced): names, problems
--      Guide.LoadPacks()  the guide packs of this game loaded (at the start); each hands its guides to Guide.Take
--      Guide.Remove(key), Guide.Choose(key), Guide.Chosen()
--      Guide.Empty()      while no guide is followed, the view's words for why (none kept, none for you); else nil
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

Guide.AHEAD = 6   -- the steps after those at hand the picture lists, at most (the view may show fewer)

local EMPTY = {}
local DEFLATE, ZLIB = 0, 1 -- the game's Enum.CompressionMethod.Deflate and Zlib, should their names be missing
local shipped = {} -- [key] = a pack's guide: its head and its text packed (zlib), pack = the addon, order
local taken = 0    -- the packs' guides handed over so far (their order)
-- Our colours for names in a guide's words, by kind: the game's own font colours, these where it lacks one.
local COLOURS = {
    friend = { "GREEN_FONT_COLOR", "19FF19" }, foe = { "RED_FONT_COLOR", "FF2020" },
    loot = { "LIGHTBLUE_FONT_COLOR", "88AAFF" }, warn = { "NORMAL_FONT_COLOR", "FFD100" },
    pick = { "ORANGE_FONT_COLOR", "FF8040" }, buy = { "LIGHTYELLOW_FONT_COLOR", "FFFF9B" },
}

local watchers = {}
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
local hexes -- [kind] = our colour as eight hex digits, once made

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

-- A guide's words in our colours: its colour words, and its line breaks.
local function Paint(text)
    if type(text) ~= "string" then return "" end
    local words = Core.Neighbours.Format("guide")
    for kind, word in pairs(words and words.colours or EMPTY) do
        text = text:gsub("|c" .. word:gsub("%p", "%%%0"), "|c" .. Hex(kind))
    end
    return (text:gsub("\\n", "\n"))
end

-- A guide's words as plain small letters, their colours and pictures gone: to find a name in them.
function Guide.Bare(text)
    return (Paint(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):lower())
end

-- The names the guide's words colour as things to pick up or use.
local function Picked(text, into)
    local words = Core.Neighbours.Format("guide")
    local word = words and words.colours and words.colours.pick
    if type(text) ~= "string" or not word then return end
    for name in text:gmatch("|c" .. word:gsub("%p", "%%%0") .. "(.-)|r") do
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
        local words = ns.Run.Words(line)
        if words and (line.what ~= "place" or line.words) then
            lines[#lines + 1] = { text = Paint(words), done = state.done, count = ns.Format.DOING[line.what] or false,
                                  have = state.have, need = state.need, what = line.what,
                                  objective = line.what == "goal" and ns.Run.ObjectiveKind(line.quest, line.goal) or nil }
        end
    end
    return lines
end

function Guide.Picture(count, shift)
    local guide = ns.Run.Guide()
    if not guide then return nil end
    local title, levels = Split(Paint(guide.title or guide.name))
    local at = ns.Run.At()
    local picture = { title = title, levels = levels, at = math.min(at, #guide.steps),
                      place = math.min(ns.Run.Place(), #guide.steps), total = #guide.steps, hand = {}, ahead = {} }
    local last = at
    for _, index in ipairs(ns.Run.Hand()) do
        picture.hand[#picture.hand + 1] = { number = index, done = ns.Run.Ticked(index), lines = OurLines(index) }
        last = math.max(last, index)
    end
    local index = math.max(1, last + 1 + (shift or 0))
    picture.shift = index - (last + 1)
    while #picture.ahead < (count or Guide.AHEAD) and guide.steps[index] do
        if ns.Run.Listed(index) then
            local lines = OurLines(index)
            if lines[1] then
                picture.ahead[#picture.ahead + 1] = { number = index, text = lines[1].text, done = ns.Run.Ticked(index) }
            end
        end
        index = index + 1
    end
    return picture
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

-- A step at hand skipped: it counts as done, whichever of the steps at hand it is.
function Guide.Skip(number)
    ns.Run.Skip(number)
    Changed()
end

-- Whether the guide is followed now: on (not paused, not off; Saneroki, 2026-10-26) and one is chosen.
function Guide.Following()
    return (ns.options.follow or "on") == "on" and ns.Run.Guide() ~= nil
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
    for _, index in ipairs(ns.Run.Hand()) do
        for _, state in ipairs(ns.Run.Lines(index)) do
            if not state.done then Picked(ns.Run.Words(state.line), names) end
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
    local key = (group and group ~= "" and (group .. "\\") or "") .. name
    if only and only ~= "" then key = key .. " << " .. only end
    return key
end

-- Whether a kept guide is for this character in this game.
local function Mine(kept, who)
    if kept.only and kept.only ~= "" and not ns.Format.For(who, kept.only) then return false end
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
    if guide then guide.key = key end
    return guide
end

function Guide.Kept()
    local list, who, seen = {}, Who(), {}
    local function Add(key, kept, pack)
        if seen[key] or type(kept) ~= "table" or kept.part or kept.divider then return end
        seen[key] = true
        list[#list + 1] = { key = key, name = kept.name or key, title = kept.title, group = kept.group or "",
                            subgroup = kept.subgroup or "", mine = Mine(kept, who), bought = kept.bought == true,
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

-- A kept guide to follow; nil: none.
function Guide.Choose(key)
    local guide = key and Read(key)
    ns.Run.Use(guide and guide.mine and guide or nil)
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
            local key = KeyOf(head.group, head.name, head.only)
            local kept = Pack(text)
            kept.name, kept.group, kept.subgroup, kept.title = head.name, head.group, head.subgroup, head.title
            kept.only, kept.defaultFor, kept.after, kept.games = head.only, head.defaultFor, head.after, head.games
            kept.part, kept.bought = head.part, bought or nil
            store[key] = kept
            names[#names + 1] = head.name
            for _, problem in ipairs(found or EMPTY) do problems[#problems + 1] = head.name .. ", " .. problem end
            if not first and guide and not head.part and Mine(kept, who) then first = key end
        end
    end
    -- A character without a guide yet takes the first one for it.
    if first and not ns.Run.Guide() then Guide.Choose(first) end
    Changed()
    return names, problems
end

-- A kept guide forgotten (a pack's stays: the pack holds it).
function Guide.Remove(key)
    Store()[key] = nil
    if Guide.Chosen() == key then ns.Run.Use(nil) end
    Changed()
end

-- A guide by a name a guide's head gives ("Group\Name", or a name), kept or a pack's: its key. Of several, the one
-- for this character first, then one of the same group; a kept one before a pack's.
local function Find(name, group, who)
    if Entry(name) then return name end
    local found, rank
    for _, guides in ipairs({ Store(), shipped }) do
        for key, kept in pairs(guides) do
            if type(kept) == "table" and (kept.name == name or KeyOf(kept.group, kept.name) == name) then
                local this = (Mine(kept, who) and 0 or 2) + ((kept.group or "") == (group or "") and 0 or 1)
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
    if guide and guide.mine then
        ns.Run.Use(guide)
        return
    end
    local who = Who()
    for _, key in ipairs(Starts()) do
        local entry = Entry(key)
        if Mine(entry, who) and type(entry.defaultFor) == "string" and ns.Format.For(who, entry.defaultFor) then
            local read = Read(key)
            if read and read.mine then
                ns.Run.Use(read)
                return
            end
        end
    end
end

-- The guide run here is through: on to the one it names after it, the first kept one that is for this character.
local function Onward()
    local guide = ns.Run.Guide()
    if not guide or not ns.Run.Through() then return end
    local who = Who()
    for _, after in ipairs(guide.after) do
        local key = Find(after.name, guide.group, who)
        local next = key and (not after.only or ns.Format.For(who, after.only)) and Read(key)
        if next and next.mine then
            ns.Run.Use(next)
            return
        end
    end
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
