-- Runs Core's wire and the guild's records (Core/Data/Wire.lua, Core/Data/Guild.lua) and the Guild module against the
-- stand-in client (wowstub.lua): messages and blocks there and back, what is dropped, the roster read and its history,
-- members' records taken only from their owner and only when newer, this character's card, a window offered to
-- another module's board, the guild window's page with its views, the guild key. The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/guild.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the client needs to have for this
-------------------------------------------------------------------------------
-- Packing: a stand-in that is easy to read back (the game's is zlib and Base64).
local function Hex(text) return (text:gsub(".", function(c) return ("%02x"):format(c:byte()) end)) end
local function Unhex(text)
    if text:find("[^%x]") or #text % 2 == 1 then return nil end
    return (text:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end))
end
C_EncodingUtil = {
    CompressString = function(text) return "Z" .. text end,
    DecompressString = function(text) if text:sub(1, 1) == "Z" then return text:sub(2) end end,
    EncodeBase64 = Hex, DecodeBase64 = Unhex,
}
Enum = rawget(_G, "Enum") or {}
Enum.CompressionMethod = { Deflate = 0, Zlib = 1, Gzip = 2 }
Enum.SendAddonMessageResult = { Success = 0, AddonMessageThrottle = 3, ChannelThrottle = 8, AddOnMessageLockdown = 11 }
local sent, answer = {}, 0
C_ChatInfo = rawget(_G, "C_ChatInfo") or {}
C_ChatInfo.RegisterAddonMessagePrefix = function(prefix) C_ChatInfo.registered = prefix return true end
C_ChatInfo.SendAddonMessage = function(prefix, text, channel, target)
    sent[#sent + 1] = { prefix = prefix, text = text, channel = channel, target = target }
    return answer
end
C_ChatInfo.InChatMessagingLockdown = function() return false end

-- The guild: its roster as the game gives it, by index.
local members = {
    { "Tester Stub", "Officer", 1, 30, "Shaman", "Thunder Bluff", "me", "", true, 0, "SHAMAN" },
    { "Droopy Fairwind", "Guild Master", 0, 32, "Warrior", "Barrens", "the boss", "", true, 0, "WARRIOR" },
    { "Ann Brook", "Member", 2, 18, "Priest", "Barrens", "", "", true, 0, "PRIEST" },
    { "Sly Rook", "Member", 2, 24, "Rogue", "Duskwood", "alt of Ann", "", false, 0, "ROGUE" },
}
local function Copy(list) local out = {} for i, v in ipairs(list) do out[i] = v end return out end
local roster = {}
for i, m in ipairs(members) do roster[i] = Copy(m) end
IsInGuild = function() return true end
GetGuildInfo = function() return "The Order", "Officer", 1, "Stub" end
GetNumGuildMembers = function()
    local online = 0
    for _, m in ipairs(roster) do if m[9] then online = online + 1 end end
    return #roster, online
end
local partial = nil -- a roster the game gives only in part
GetGuildRosterInfo = function(index)
    if partial and index > partial then return nil end
    local m = roster[index]
    if not m then return nil end
    return m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], 0, 0, false, false, 0, "Player-1-" .. index
end
GetGuildRosterLastOnline = function(index) if roster[index] and not roster[index][9] then return 0, 0, 3, 2 end end
GuildControlGetRankName = function(index) return ({ "Guild Master", "Officer", "Member", "Initiate" })[index] end
GuildControlGetNumRanks = function() return 4 end
C_GuildInfo = { GuildRoster = function() C_GuildInfo.asked = (C_GuildInfo.asked or 0) + 1 end, GetMOTD = function() return "Raid at eight" end,
                GetInfoText = function() return "Be kind." end, IsGuildOfficer = function() return true end,
                CanViewOfficerNote = function() return true end, CanEditOfficerNote = function() return true end,
                Promote = function(name) C_GuildInfo.promoted = name end }
CanGuildPromote = function() return true end
CanGuildDemote = function() return true end
CanGuildInvite = function() return true end
CanEditPublicNote = function() return true end
CanEditMOTD = function() return true end
UnitClass = function() return "Shaman", "SHAMAN" end
UnitRace = function() return "Tauren", "Tauren", 6 end
UnitSex = function() return 3 end
UnitLevel = function() return 30 end
local worn = { [1] = 16854, [5] = 2139, [16] = 1001 }
GetInventoryItemID = function(_, slot) return worn[slot] end
GetInventoryItemLink = function(_, slot) return worn[slot] and ("|Hitem:" .. worn[slot] .. "|h[x]|h") end
C_Item = rawget(_G, "C_Item") or {}
C_Item.GetDetailedItemLevelInfo = function(link) local id = tonumber(link:match("item:(%d+)")) return id and (id % 40) + 10 end
-- The skill lines as this client gives them (C_SkillInfo, a table each): a header, two professions (category 11), a
-- weapon (category 6).
local skills = {
    { skillID = 11, name = "Professions", isHeader = true, rank = 0, maxRank = 0, skillLineCategoryID = 0, parentSkillLineID = 0 },
    { skillID = 165, name = "Leatherworking", isHeader = false, rank = 138, maxRank = 225, skillLineCategoryID = 11, parentSkillLineID = 0 },
    { skillID = 393, name = "Skinning", isHeader = false, rank = 150, maxRank = 225, skillLineCategoryID = 11, parentSkillLineID = 0 },
    { skillID = 43, name = "Swords", isHeader = false, rank = 140, maxRank = 150, skillLineCategoryID = 6, parentSkillLineID = 0 },
}
C_SkillInfo = { GetNumSkillLines = function() return #skills end, GetSkillLineInfo = function(index) return skills[index] end }
TRADE_SKILLS = "Professions"
GetBindingKey = function(action) if action == "TOGGLEGUILDTAB" then return "J" end end
-- The search box's instructions (the roster's box is made from the game's template).
W.templates.SearchBoxTemplate = function(box) box.Instructions = W.NewWidget("FontString", nil, box) end
-- The game's micro menu button for the guild (the secure button clicks it).
CreateFrame("Button", "GuildMicroButton", UIParent)
local overrides = {}
SetOverrideBinding = function(_, _, key, command) overrides[key] = command end
ClearOverrideBindings = function() for key in pairs(overrides) do overrides[key] = nil end end
RAID_CLASS_COLORS = { SHAMAN = { r = 0, g = 0.44, b = 0.87 }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
CLASS_ICON_TCOORDS = { SHAMAN = { 0.25, 0.49, 0.25, 0.5 }, WARRIOR = { 0, 0.25, 0, 0.25 } }
GetRealZoneText = function() return "Barrens" end
GetPlayerInfoByGUID = function() return "Priest", "PRIEST" end

-- Lists: the game's scrolling list, drawn at once whenever what it shows changes.
local function Relay(box)
    if not (box and box.view and box.view.draw) then return end
    box.rows = {}
    for index, element in ipairs(box.provider.list) do
        local row = W.NewWidget("Button", nil, box)
        box.rows[index] = row
        box.view.draw(row, element)
    end
end
CreateScrollBoxListLinearView = function()
    local view = {}
    function view:SetElementExtent(extent) self.extent = extent end
    function view:SetElementInitializer(kind, fn) self.kind, self.draw = kind, fn end
    return view
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.view = view end }
ScrollBoxConstants = { RetainScrollPosition = true, NoScrollInterpolation = true }
CreateDataProvider = function(list)
    local provider = { list = {} }
    function provider:Flush() self.list = {} Relay(self.box) end
    function provider:InsertTable(more) for _, entry in ipairs(more) do self.list[#self.list + 1] = entry end Relay(self.box) end
    for _, entry in ipairs(list or {}) do provider.list[#provider.list + 1] = entry end
    return provider
end
local retained = {} -- each list's last SetDataProvider: whether it kept where it was scrolled to
W.templates.WowScrollBoxList = function(box)
    function box:SetDataProvider(provider, retain)
        self.provider, provider.box, retained[self] = provider, self, retain
        Relay(self)
    end
end

-------------------------------------------------------------------------------
--  Core
-------------------------------------------------------------------------------
W.LoadCore(root)
local Core = SaneUI.Core
SaneUIDB = {}
W.Fire("ADDON_LOADED", "SaneUI")
local Steps, Wire, Guild = Core.Steps, Core.Wire, Core.Data.Guild

-- One frame of the game: the timers due, then the scheduler's and the wire's work.
local function Frame(seconds)
    W.Wait(seconds or 0.02)
    if Steps.frame:IsShown() and Steps.frame._scripts.OnUpdate then Steps.frame._scripts.OnUpdate(Steps.frame, 0.016) end
    local pump = Wire.frame
    if pump and pump:IsShown() and pump._scripts.OnUpdate then pump._scripts.OnUpdate(pump, 0.016) end
end
local function Frames(n) for _ = 1, n or 10 do Frame() end end
-- What was sent, handed to this client as if another player had sent it.
local function Deliver(from, list, channel)
    for _, message in ipairs(list) do W.Fire("CHAT_MSG_ADDON", message.prefix, message.text, channel or message.channel, from) end
end

-------------------------------------------------------------------------------
--  The wire
-------------------------------------------------------------------------------
check(Wire.Sign() == "f", "this client's game version is told by its sign: f for Forever")
check(Wire.Text("G", { "h", "a\tb", n = 2 }) == "G1\tf\th\ta b", "a message: kind and protocol, sign, fields cut by tabs; a tab in a field is a space")
local kind, protocol, sign, fields = Wire.Read("G1\tf\th\tone\t\tthree")
check(kind == "G" and protocol == 1 and sign == "f" and fields[1] == "h" and fields[2] == "one" and fields[3] == "" and fields[4] == "three",
    "read back: its kind, protocol, sign and fields, an empty one kept")
check(Wire.Read("nonsense") == nil and Wire.Read(("x"):rep(300)) == nil, "what is no message of ours, or too long, is read as none")

local heard = {}
Wire.Listen("T", function(sender, f, channel, name) heard[#heard + 1] = { sender = sender, fields = f, channel = channel, name = name } end)
check(C_ChatInfo.registered == "SaneUI", "listening registers the prefix SaneUI with the game")
check(Wire.Send("T", { "x", ("y"):rep(260), n = 2 }, "GUILD") == false, "a message over 255 bytes is not sent")
check(Wire.Send("T", { "hello", n = 1 }, "NOWHERE") == false and Wire.Send("T", { "x", n = 1 }, "WHISPER") == false,
    "nothing goes to an unknown channel, and no whisper without its target")
check(Wire.Send("T", { "hello", n = 1 }, "GUILD"), "a message is queued")
check(#sent == 0, "nothing is sent before the next frame")
Frames(1)
check(#sent == 1 and sent[1].prefix == "SaneUI" and sent[1].channel == "GUILD" and sent[1].text == "T1\tf\thello", "the next frame it goes to the guild")
Deliver("Droopy Fairwind", sent)
Frames(2)
check(#heard == 1 and heard[1].sender == "Droopy Fairwind" and heard[1].fields[1] == "hello" and heard[1].channel == "GUILD",
    "another member's message is heard, from its sender's key, after the scheduler took it in")
heard = {}
Deliver("Tester Stub", sent)
Deliver("Droopy", sent)
W.Fire("CHAT_MSG_ADDON", "SaneUI", "T1\tb\thello", "GUILD", "Ann Brook")
W.Fire("CHAT_MSG_ADDON", "SaneUI", "T2\tf\thello", "GUILD", "Ann Brook")
W.Fire("CHAT_MSG_ADDON", "OtherPrefix", "T1\tf\thello", "GUILD", "Ann Brook")
Frames(2)
check(#heard == 0, "dropped: the player's own message, a sender named without its surname, another game version, another protocol, another prefix")

-- The budget: ten at once, then one a second.
Frame(10) -- quiet for a while: the budget is whole again
sent = {}
for i = 1, 14 do Wire.Send("T", { i, n = 1 }, "GUILD") end
Frames(1)
check(#sent == 10, "ten go at once")
Frame(0.5)
check(#sent == 10, "then none before a second has passed")
Frame(0.6)
check(#sent == 11, "one a second after that")
answer = 3 -- the game says: too much
Frame(1.1)
check(#sent == 12 and Wire.Waiting() == 3, "a throttle keeps the message and waits")
answer = 0
Frame(1.1)
check(Wire.Waiting() == 3, "after a throttle the rate is halved: a second is not enough")
for _ = 1, 10 do Frame(1) end
check(Wire.Waiting() == 0, "and everything goes in the end")
sent = {}

-- The game refuses a message for good (no guild, the target offline): dropped, counted, and /sane data says so.
answer = 2
Wire.Send("T", { "to nobody", n = 1 }, "GUILD")
Frame(1)
check(Wire.Waiting() == 0 and Wire.refused == 1, "a message the game refused for good is dropped, and counted")
answer = 0
W.printed = {}
SlashCmdList.SANEUI("data")
local refusedSaid = false
for _, line in ipairs(W.printed) do
    if tostring(line):find("1 refused by the game", 1, true) then refusedSaid = true end
end
check(refusedSaid, "/sane data says how many the game refused since the login")
sent = {}

-- Blocks: packed, cut into parts, put together again.
local blocks = {}
Wire.ListenBlock("T", function(sender, text, channel) blocks[#blocks + 1] = { sender = sender, text = text, channel = channel } end)
local long = ("the quick brown fox; "):rep(30)
check(Wire.SendBlock("T", long, "GUILD"), "a block is queued")
for _ = 1, 10 do Frame(1) end
check(#sent > 1, "it goes in several parts")
local parts = sent
sent = {}
table.insert(parts, 1, table.remove(parts)) -- the last part comes first
Deliver("Droopy Fairwind", parts)
Frames(2)
check(#blocks == 1 and blocks[1].text == long and blocks[1].sender == "Droopy Fairwind", "the parts, in any order, give the block back whole")
blocks = {}
Deliver("Droopy Fairwind", { parts[1], parts[2] })
Frames(2)
check(#blocks == 0, "a block with parts missing is not told")
check(Wire.SendBlock("T", ("x"):rep(5000), "GUILD") == false, "a block larger than 4 KB packed is not sent (the stand-in packs nothing)")
-- A block whose parts do not all fit in the queue is not queued at all: a block in part is of no use.
Wire.QUEUE = 3
Wire.Send("T", { "a", n = 1 }, "GUILD")
Wire.Send("T", { "b", n = 1 }, "GUILD")
check(Wire.SendBlock("T", long, "GUILD") == false and Wire.Waiting() == 2, "a block whose parts do not all fit in the queue is not queued")
Wire.QUEUE = 300
for _ = 1, 5 do Frame(1) end
sent = {}
-- Part numbers that are no whole numbers (tonumber takes "nan" and "2.5") are dropped, from anybody, never an error.
blocks = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "P1\tf\tT\t7\tnan\t2\t\t5a", "WHISPER", "Evil Stranger")
for _, number in ipairs({ "1", "3", "4", "2.5" }) do
    W.Fire("CHAT_MSG_ADDON", "SaneUI", "P1\tf\tT\t8\t" .. number .. "\t4\t" .. (number == "1" and "1" or "") .. "\t5a", "WHISPER", "Evil Other")
end
Frames(3)
check(#blocks == 0 and Core.errors["data job wire: inbox"] == nil, "parts numbered NaN or 2.5 are dropped, without an error")

-- Another addon's prefix (one Sane UI knows, Core.Neighbours): heard in its own words, sent through the same queue.
local others = {}
check(Wire.Hear("OtherMaps", function(sender, text, channel) others[#others + 1] = { sender = sender, text = text, channel = channel } end)
    and C_ChatInfo.registered == "OtherMaps" and Wire.Hear(Wire.PREFIX, function() end) == false,
    "another addon's prefix heard, registered with the game; never our own that way")
W.Fire("CHAT_MSG_ADDON", "OtherMaps", "RT~1~1~1~hello", "PARTY", "Droopy Fairwind")
W.Fire("CHAT_MSG_ADDON", "NobodysMaps", "RT~1~1~1~hello", "PARTY", "Droopy Fairwind")
W.Fire("CHAT_MSG_ADDON", "OtherMaps", "mine", "PARTY", "Tester Stub")
Frames(2)
check(#others == 1 and others[1].text == "RT~1~1~1~hello" and others[1].sender == "Droopy Fairwind" and others[1].channel == "PARTY",
    "told as it came; a prefix nobody listens to and the player's own not")
Frame(10)
sent = {}
check(Wire.Say("OtherMaps", "RT~2~1~1~drawn", "INSTANCE_CHAT") and not Wire.Say("OtherMaps", ("x"):rep(300), "PARTY")
    and not Wire.Say(Wire.PREFIX, "x", "PARTY") and not Wire.Say("OtherMaps", "x", "WHISPER"),
    "said on its prefix; too long, our own prefix, a whisper to nobody: not")
Frames(2)
check(#sent == 1 and sent[1].prefix == "OtherMaps" and sent[1].text == "RT~2~1~1~drawn" and sent[1].channel == "INSTANCE_CHAT",
    "sent in turn on its prefix, in its own words")
sent = {}

-- A sender of too many is not heard for a while.
heard = {}
for i = 1, 95 do W.Fire("CHAT_MSG_ADDON", "SaneUI", "T1\tf\tspam" .. i, "GUILD", "Sly Rook") end
Frames(3)
check(#heard == Wire.PER_MINUTE, "a sender is heard 90 times a minute, no more")
heard = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "T1\tf\tlater", "GUILD", "Sly Rook")
Frames(2)
check(#heard == 0, "and not at all for a while after")

-------------------------------------------------------------------------------
--  The guild's records
-------------------------------------------------------------------------------
W.Fire("PLAYER_LOGIN")
W.Fire("LOADING_SCREEN_DISABLED")
Guild.Allow("card", true)
Guild.Start()
Frames(5)
check(rawget(_G, "SaneUIData_Guild") and SaneUIData_Guild.forever and SaneUIData_Guild.forever.guilds, "the guild's saved variable is there, keyed by game version")
check(Guild.Key() == "The Order-Stub", "the guild's key is its name and realm")
check(#Guild.Roster() == 4 and Guild.Member("Ann Brook").level == 18 and Guild.Member("Sly Rook").away == 3,
    "the roster as the game gives it: every member by key, the days since an offline one was online")
check(Guild.Info().motd == "Raid at eight" and Guild.Info().online == 3 and Guild.Info().total == 4, "the guild's message of the day and counts")
check(#Guild.History() == 0, "the first read of a guild notes no history: it is where the history starts")
check(Guild.Member("Droopy Fairwind").joined == nil, "nor anybody's day of joining: it is not known")
check(SaneUIData_Guild.forever.guildFormat == 1 and SaneUIData_Guild.forever.format == 1,
    "the guilds' format is kept apart from the data framework's")

-- The roster changes.
roster[3][4] = 20                                 -- Ann reached level 20
roster[4][3], roster[4][2] = 1, "Officer"         -- Sly was promoted
table.remove(roster, 2)                           -- Droopy left
roster[#roster + 1] = { "Mel Stone", "Initiate", 3, 5, "Mage", "Mulgore", "", "", true, 0, "MAGE" } -- Mel joined
Guild.Read()
local whats = {}
for _, event in ipairs(Guild.History()) do whats[event.what .. ":" .. event.key] = event end
check(whats["level:Ann Brook"] and whats["level:Ann Brook"].from == 18 and whats["level:Ann Brook"].to == 20, "a level reached is noted, from and to")
check(whats["up:Sly Rook"] and whats["up:Sly Rook"].to == 1, "a promotion is noted with the new rank")
check(whats["leave:Droopy Fairwind"] and whats["join:Mel Stone"], "who left and who joined are noted")
check(Guild.Member("Mel Stone").joined == math.floor(GetServerTime() / 86400), "who joined later has its day")
check(#Guild.History("Ann Brook") == 1, "a member's own history")
-- A roster the game gives only in part is no reason to think members left.
local function Leaves()
    local count = 0
    for _, event in ipairs(Guild.History()) do if event.what == "leave" then count = count + 1 end end
    return count
end
local before = Leaves()
partial = 2
Guild.Read()
check(Leaves() == before and before == 1, "a roster the game gives only in part notes nobody leaving")
partial = nil
Guild.Read()
roster[#roster + 1] = { "Droopy Fairwind", "Guild Master", 0, 32, "Warrior", "Barrens", "the boss", "", true, 0, "WARRIOR" }
Guild.Read()

-- This character's card.
local card = Guild.ReadCard(Guild.Card())
check(card and card.class == "SHAMAN" and card.race == 6 and card.level == 30, "the card says who the character is")
check(card.worn[1].item == 16854 and card.worn[16].item == 1001 and card.worn[5].level == 2139 % 40 + 10, "what it wears, slot by slot, with item levels")
check(card.professions[1].name == "Leatherworking" and card.professions[1].rank == 138 and card.professions[2].name == "Skinning"
    and #card.professions == 2, "its professions with their ranks, from the game's skill lines (no weapon skill)")
check(math.abs(card.itemLevel - ((16854 % 40 + 10) + (2139 % 40 + 10) + (1001 % 40 + 10)) / 3) < 0.06, "its item level: the average of what it wears")

-- Published: kept as our own and sent to the guild; another member's taken from it only when newer.
sent = {}
Guild.Publish("card", Guild.Card())
for _ = 1, 10 do Frame(1) end
local ownText = Guild.Record("Tester Stub", "card")
check(ownText ~= nil, "this character's card is kept as its own record")
check(#sent >= 1 and sent[1].channel == "GUILD", "and sent to the guild as a block")
local cardParts = sent
sent = {}
Deliver("Droopy Fairwind", cardParts)
Frames(2)
local droopy, stampOfDroopy = Guild.Record("Droopy Fairwind", "card")
check(droopy == ownText and stampOfDroopy, "a member's card is kept under its sender's key: a member publishes only its own")
Deliver("Droopy Fairwind", cardParts)
Frames(2)
local _, again = Guild.Record("Droopy Fairwind", "card")
check(again == stampOfDroopy, "the same card again changes nothing")
Deliver("Nobody There", cardParts, "WHISPER")
Frames(2)
check(Guild.Record("Nobody There", "card") == nil, "a whisper from somebody not in the guild is not taken")
-- A stamp from far ahead is no record.
Wire.SendBlock("G", "card\031" .. (GetServerTime() + 3 * 86400) .. "\031" .. ownText, "GUILD")
for _ = 1, 5 do Frame(1) end
local future = sent
sent = {}
Deliver("Ann Brook", future)
Frames(2)
check(Guild.Record("Ann Brook", "card") == nil, "a record stamped days ahead of this client's clock is not taken")
-- An unknown kind is not kept.
Wire.SendBlock("G", "secret\031" .. GetServerTime() .. "\031x", "GUILD")
for _ = 1, 5 do Frame(1) end
local odd = sent
sent = {}
Deliver("Ann Brook", odd)
Frames(2)
check(next(Guild.Records("secret")) == nil, "a kind the guild does not keep is not kept")

-- A hello: who has a newer record is asked for it by a whisper.
sent = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\th\t0\t9.9\tcard=" .. GetServerTime() + 10, "GUILD", "Mel Stone")
Frames(3)
local asked
for _, message in ipairs(sent) do
    if message.channel == "WHISPER" and message.target == "Mel Stone" and message.text == "G1\tf\ta\tcard" then asked = true end
end
check(asked, "a member that says it has a card we lack is asked for it, by a whisper")
check(Guild.Peers()["Mel Stone"] and Guild.Peers()["Mel Stone"].version == "9.9", "and is known to run Sane UI, with its version")
-- Asked ourselves: we answer the one who asked with our own, once a minute at most however often it asks.
local function Given(name)
    local count = 0
    for _, message in ipairs(sent) do
        if message.channel == "WHISPER" and message.target == name and message.text:find("^P1") then count = count + 1 end
    end
    return count
end
sent = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\ta\tcard", "WHISPER", "Droopy Fairwind")
for _ = 1, 5 do Frame(1) end
check(Given("Droopy Fairwind") > 0, "a member that asks for our card gets it, whispered")
sent = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\ta\tcard", "WHISPER", "Droopy Fairwind")
for _ = 1, 5 do Frame(1) end
check(Given("Droopy Fairwind") == 0, "asked again at once, it does not go again")
Frame(Guild.ASK_GAP)
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\ta\tcard", "WHISPER", "Droopy Fairwind")
for _ = 1, 5 do Frame(1) end
check(Given("Droopy Fairwind") > 0, "a minute later it does")
Guild.Allow("card", false)
sent = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\ta\tcard", "WHISPER", "Mel Stone")
for _ = 1, 5 do Frame(1) end
check(#sent == 0, "with sharing off, nobody gets it")
Guild.Allow("card", true)
for _ = 1, 10 do Frame(1) end
sent = {}
-- Switched off before it went, what waits of a kind is dropped: nothing of it is sent.
Guild.Kind("note", 200)
Guild.Allow("note", true)
Guild.Publish("note", "the raid is at eight")
check(Wire.Waiting() > 0, "a record published waits to be sent")
Guild.Allow("note", false)
for _ = 1, 5 do Frame(1) end
check(Wire.Waiting() == 0 and #sent == 0, "switched off before it went, it is dropped")

-- Sync asks the guild (a fresh hello), once a minute at most; a member's fresh hello is answered by a whisper to it.
local function Hellos(fresh, channel, target)
    local count = 0
    for _, message in ipairs(sent) do
        if message.text:find("^G1\tf\th\t" .. fresh) and message.channel == channel and message.target == target then count = count + 1 end
    end
    return count
end
Frame(Guild.SYNC)
sent = {}
Guild.Sync()
Guild.Sync()
for _ = 1, 3 do Frame(1) end
check(Hellos("1", "GUILD") == 1, "Sync asks the guild by a fresh hello, once however often it is pressed")
sent = {}
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\th\t1\t9.9", "GUILD", "Mel Stone")
W.Fire("CHAT_MSG_ADDON", "SaneUI", "G1\tf\th\t1\t9.9", "GUILD", "Mel Stone")
for _ = 1, 8 do Frame(1) end
check(Hellos("0", "WHISPER", "Mel Stone") == 1 and Hellos("0", "GUILD") == 0, "a fresh hello is answered once, whispered to the one who asked")

-- A skill-up makes the card anew a while later, not at once: skills rise in runs.
local function Published()
    local count = 0
    for _, message in ipairs(sent) do if message.channel == "GUILD" and message.text:find("^P1") then count = count + 1 end end
    return count
end
sent = {}
skills[2].rank = 139
W.Fire("SKILL_LINES_CHANGED")
for _ = 1, 10 do Frame(1) end
check(Published() == 0, "a skill-up is not sent at once")
for _ = 1, Guild.SKILLS do Frame(1) end
check(Published() > 0, "but a while later, in the card made anew")

-- A roster a fifth smaller at once is believed only when a read a while later still says it; who left takes what
-- it shared along.
local droopyRow
for index, member in ipairs(roster) do
    if member[1] == "Droopy Fairwind" then droopyRow = table.remove(roster, index) break end
end
Guild.Read()
check(Leaves() == 1 and Guild.Record("Droopy Fairwind", "card") ~= nil, "a roster a fifth smaller at once is not believed yet")
Frame(Guild.SHRINK_WAIT)
Guild.Read()
check(Leaves() == 2 and Guild.Record("Droopy Fairwind", "card") == nil, "a while later it is: the member left, and its card with it")
roster[#roster + 1] = droopyRow
Guild.Read()

-- In a fight the roster is not read: once the fight is over, however often the game said it changed.
W.Combat(true)
for _, member in ipairs(roster) do if member[1] == "Ann Brook" then member[4] = 21 end end
W.Fire("GUILD_ROSTER_UPDATE", false)
W.Fire("GUILD_ROSTER_UPDATE", false)
for _ = 1, 3 do Frame(1) end
check(Guild.Member("Ann Brook").level == 20, "in a fight the roster is not read")
W.Combat(false)
Frames(3)
check(Guild.Member("Ann Brook").level == 21, "once it is over, it is")
-- A view that shows the roster has it asked of the game whenever the game lets again; never on a timer.
local askedBefore = C_GuildInfo.asked or 0
Guild.Watch(true)
W.Fire("GUILD_ROSTER_UPDATE", true)
W.Fire("GUILD_ROSTER_UPDATE", false)
check(C_GuildInfo.asked == askedBefore + 2, "while a view shows the roster, it is asked for at once and when the game lets")
Guild.Watch(false)
W.Fire("GUILD_ROSTER_UPDATE", true)
check(C_GuildInfo.asked == askedBefore + 2, "else not")
Frames(3)

-------------------------------------------------------------------------------
--  A window offered to another module's board
-------------------------------------------------------------------------------
local Board = Core.Board
local own = { { key = "talks" }, { key = "guild", title = "the game's" } }
local window = { Refresh = function() end, edge = { Fill = function(self, on) self.full = on end } }
local board = Board.New(window, { label = "Testing", windows = function() return own end })
Board.Offer("Testing", { key = "guild", title = "ours" })
Board.Offer("Testing", { key = "extra", title = "more" })
check(Board.Offered("Testing", "guild").title == "ours", "an offered window is found by its board's label and key")
check(Board.Open("Testing", "guild") and window.edge.full == true, "opening it fills the board's window")
check(Board.Open("Nowhere", "guild") == false, "a board that is not there opens nothing")
Board.Withdraw("Testing", "extra")
check(Board.Offered("Testing", "extra") == nil, "withdrawn, it is offered no more")
check(board ~= nil, "the board stands")

-------------------------------------------------------------------------------
--  The module
-------------------------------------------------------------------------------
local ns = W.LoadAddon(root, "Guild", "SaneUI_Guild")
check(SaneUI.Guild == ns and ns.addon == "SaneUI_Guild", "the module is an addon of its own")
W.Fire("ADDON_LOADED", "SaneUI_Guild")
W.Fire("PLAYER_LOGIN")
Frames(3)
check(Board.Offered("Social", "guild") ~= nil, "its window is offered to Social's board as the guild window")
check(overrides.J == "SANEUI_GUILD_TOGGLE", "the guild key opens ours (an override binding on the game's own key)")
IsInGuild = function() return false end
W.Fire("PLAYER_GUILD_UPDATE", "player")
check(next(overrides) == nil, "outside a guild the guild key opens the game's window, where a guild is found")
local told = #W.printed
ns.Window.Toggle()
check(ns.Page.Frame() == nil and #W.printed == told + 1 and tostring(W.printed[#W.printed]):find(ns.TEXT.noGuild, 1, true),
    "and ours (/sane guild, our key elsewhere) opens nothing there: it says so")
IsInGuild = function() return true end
W.Fire("PLAYER_GUILD_UPDATE", "player")
check(overrides.J == "SANEUI_GUILD_TOGGLE", "in a guild again, ours")
Frames(3)

-- On Social's board out of a guild: ticked, the window stands and says why it holds nothing; the page is built there
-- for the first time, its views with no guild at all. Social's own guild window, and its first layout, as Board.lua
-- has them. The window closed again, the rest of this file has the window of its own.
;(function()
    -- The board's panels fade in by the game's animations: here they are there at once.
    local function Inert(known) return setmetatable(known, { __index = function() return function() end end }) end
    function W.methods:CreateAnimationGroup()
        return Inert({ CreateAnimation = function() return Inert({ GetProgress = function() return 1 end }) end })
    end
    local inGuild, info, count = IsInGuild, GetGuildInfo, GetNumGuildMembers
    local function Join(joined)
        IsInGuild = joined and inGuild or function() return false end
        GetGuildInfo = joined and info or function() return nil end
        GetNumGuildMembers = joined and count or function() return 0, 0 end
        W.Fire("PLAYER_GUILD_UPDATE", "player")
        W.Wait(1)
        Frames(3)
    end
    Join(false)
    local own = { { key = "talks", title = "Conversations" }, { key = "friends", title = "Friends List" },
                  { key = "guild", title = "Guild", present = function() return false end } }
    local stood = {}
    W.caught = stood
    local frame = CreateFrame("Frame", nil, UIParent)
    local store = { layouts = { chosen = 1, tabs = { { tree = { split = "x", shares = { 0.3, 0.3, 0.4 },
        parts = { { key = "talks" }, { key = "guild" }, { key = "friends" } } } } } } }
    local board, handle
    local function Lay() if handle.edge.full then board:Show(handle.inside, 1920, 1048) else board:Hide() end end
    handle = Core.Window.New(frame, { store = store, key = "place", title = "Social", dock = true,
        edge = { expand = true, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true },
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, docked = function() if board then Lay() end end })
    board = Board.New(handle, { store = store, key = "layouts", label = "Social", windows = function() return own end, changed = Lay,
        default = function(width, height)
            local wanted = Board.Offered("Social", "guild").want(width, height)
            if wanted then return { split = "x", parts = { { key = "talks" }, { key = "guild" } }, shares = { 1, 1 } } end
            return { split = "x", parts = { { key = "talks" }, { key = "friends" } }, shares = { 1, 1 } }
        end })
    handle:Place()
    function frame:GetLeft() return 810 end
    function frame:GetBottom() return 440 end
    check(Board.Open("Social"), "Social's full screen comes")

    local panel = board.panels.guild
    check(panel and panel:IsShown() and ns.Page.Frame() and ns.Page.Frame():IsVisible() and board.rects.friends and board.rects.talks,
        "a layout that holds the guild window shows it out of a guild too: its tick and its tab are never without effect")
    local page = ns.Page.Frame()
    check(page.empty:IsShown() and page.empty:GetText():find(ns.TEXT.noGuild, 1, true) and not page.body:IsShown()
        and not page.tabs:IsShown() and not page.viewTitle:IsShown() and not page.subs:IsShown(),
        "it says you are not in a guild, with no tabs or views behind that")
    check(page.synced:GetText() == "" and not page.dot:IsShown() and not page.sync:IsEnabled(), "and nothing of a guild in its head")
    check(#page.empty._points == 2, "the words stay inside the panel, however narrow it is")
    check(#stood == 0 and not ns.off and Core.errors["Guild: view"] == nil and Core.errors["Guild: view: overview"] == nil,
        "the page and its view built with no guild, without an error: " .. tostring(stood[1]))

    board:Toggle("guild")
    check(not panel:IsShown() and not board:Has("guild") and board.rects.friends, "unticked, it goes")
    board:Toggle("guild")
    check(panel:IsShown() and board:Has("guild"), "ticked, it is back")

    Join(true)
    check(not page.empty:IsShown() and page.body:IsShown() and page.tabs:IsShown() and page.viewTitle:IsShown()
        and page.name:GetText() == "The Order" and page.synced:GetText() ~= "" and page.dot:IsShown() and page.sync:IsEnabled(),
        "a guild joined while it shows: the page fills")
    Join(false)
    check(page.empty:IsShown() and not page.body:IsShown() and not page.tabs:IsShown(), "and left, it says so again")

    store.layouts.tabs[1].tree = nil
    Lay()
    check(not board:Has("guild") and not panel:IsShown() and board.rects.friends,
        "the first layout has no guild window out of a guild: the friends list has its room")
    Join(true)
    check(board:Has("guild") and panel:IsShown(), "a guild joined while the full screen stands: the first layout has it")
    Join(false)
    check(not board:Has("guild"), "and left, it has it no more")
    check(#stood == 0 and not ns.off, "nothing went wrong on the way: " .. tostring(stood[1]))

    Join(true)
    Board.Close("Social")
    frame:Hide()
    W.caught = nil
    check(not Board.Standing("Social") and Board.Open("Social") == false, "its window closed, the guild window stands in a window of its own")
end)()

-- What its views show, without frames.
local Layout = ns.Layout
local left, middle, right = Layout.Overview(1100)
check(left == Layout.LEFT_COLUMN and right == Layout.RIGHT_COLUMN and middle > 300, "wide, the overview has three columns")
left, middle, right = Layout.Overview(700)
check(right == 0 and middle >= 200, "narrow, its right column folds")
local laid = ns.Kit.Columns({ { width = 40 }, {}, { width = 60 } }, 400)
check(laid[1].width == 40 and laid[3].width == 60 and laid[2].width == 400 - 100 - 24 and laid[2].x == 52,
    "a table's columns: the fixed ones as wide as given, the other the rest")
local Roster = ns.Views.roster
local rows, count = Roster.Rows(Guild.Roster(), "", nil, false, {})
check(rows[1].fold == "online" and rows[#rows - 0].member or rows[#rows].fold, "the roster: a fold row for those online first")
check(count == #Guild.Roster(), "every member counted")
local onlineRows = {}
for _, row in ipairs(rows) do if row.member and row.member.online then onlineRows[#onlineRows + 1] = row.member.name end end
check(onlineRows[1] == "Droopy Fairwind", "online, by rank first: the guild master on top")
rows = Roster.Rows(Guild.Roster(), "barr", nil, false, {})
local matched = 0
for _, row in ipairs(rows) do if row.member then matched = matched + 1 end end
check(matched == 2, "searched by zone: the two in the Barrens")
for _, member in ipairs(roster) do if member[1] == "Sly Rook" then member[6] = "Barrens" end end
Guild.Read()
rows = Roster.Rows(Guild.Roster(), "barr", nil, false, {})
matched = 0
for _, row in ipairs(rows) do if row.member then matched = matched + 1 end end
check(matched == 3, "a member moved: the search finds the roster as it is now")
for _, member in ipairs(roster) do if member[1] == "Sly Rook" then member[6] = "Duskwood" end end
Guild.Read()
rows = Roster.Rows(Guild.Roster(), "", "level", true, { offline = true })
check(rows[2].member.level >= rows[3].member.level, "sorted by level, highest first")
check(rows[#rows].fold == "offline", "folded, the offline ones are not listed")
local zones = ns.Views.overview.Zones(Guild.Roster())
check(zones[1].zone == "Barrens" and #zones[1].members == 2, "who is where: the zone with most first")
local race = ns.Views.overview.Race(Guild.Roster(), 3)
check(#race == 3 and race[1].name == "Droopy Fairwind" and race[1].level == 32, "the race: the highest level first")
local characters = ns.Views.equipment.Characters(Guild.Roster(), Guild.Records("card"), "")
ns.Views.equipment.Sort(characters, "itemLevel", true)
check(characters[1].itemLevel ~= nil and characters[#characters].itemLevel == nil, "equipment: those who share first, by item level")
check(Roster.Event({ what = "level", key = "Ann Brook", to = 20 }) == "Ann Brook reached level 20", "a line of a member's history")

-- The window of its own (Social is not loaded here): its page with the views.
local caught = {}
W.caught = caught
ns.Window.Toggle()
Frames(3)
check(#caught == 0, "opened without an error: " .. tostring(caught[1]))
check(ns.Page.Frame() ~= nil, "its page is built")

-- The guild's chat in the overview: each line with its time of day as the setting Units says.
ns.Page.Choose(1, 1)
Frames(2)
local realDate = date
date = function(format, at)
    if format == "*t" then local t = realDate("*t", at) t.hour, t.min = 23, 59 return t end
    if format == "%H:%M" then return "23:59" end
    return realDate(format, at)
end
local function ChatRow(text)
    for _, row in ipairs(W.frames) do
        if row.element and row.element.text == text and row.cells and row.cells.time then return row end
    end
    return nil
end
W.Fire("CHAT_MSG_GUILD", "Raid at eight?", "Ann Brook", "", "", "", "", 0, 0, "", 0, 0, "Player-1-3")
local line = ChatRow("Raid at eight?")
check(line and line.cells.time:GetText() == "23:59", "a line of the guild's chat with its time of day: 24 hours, as the setting Units says")
Core.general.units = "imperial"
W.Fire("CHAT_MSG_GUILD", "Sure.", "Ann Brook", "", "", "", "", 0, 0, "", 0, 0, "Player-1-3")
line = ChatRow("Sure.")
check(line and line.cells.time:GetText() == "11:59 PM", "Imperial: 12 hours")
Core.general.units = nil
date = realDate
-- The 12.x client may hand the line's parts out as secret values: a secret text or name makes no line (nothing of
-- it is computed with: Core.Plain), a secret GUID still one; no error.
local chatBox = ChatRow("Sure.")._parent
local had = #chatBox.provider.list
W.Fire("CHAT_MSG_GUILD", W.Secret(), "Ann Brook", "", "", "", "", 0, 0, "", 0, 0, "Player-1-3")
W.Fire("CHAT_MSG_GUILD", "Who said that?", W.Secret(), "", "", "", "", 0, 0, "", 0, 0, "Player-1-3")
W.Fire("CHAT_MSG_GUILD", "Who was that?", "Ann Brook", "", "", "", "", 0, 0, "", 0, 0, W.Secret())
check(#chatBox.provider.list == had + 1 and ChatRow("Who was that?") ~= nil and ChatRow("Who said that?") == nil
      and Core.errors["Guild: guild chat"] == nil, "a line the game hands out as secret values: none of a secret text or name, one of a secret GUID, no error")
local escape = rawget(_G, "SaneUIEscape")
check(escape and escape:IsShown(), "Esc closes it while it shows: Core's window keeps its own scripts on it")
ns.Page.Choose(2, 1)
Frames(2)
check(#caught == 0, "the roster shown without an error: " .. tostring(caught[1]))
-- The button The Game's Guild Window: the game's own micro menu button clicked by a secure button of ours, over the
-- head's own, on UIParent; away in a fight (the head's own stands in), back after it; away with the view.
local function SecureGame()
    for _, frame in ipairs(W.frames) do
        if frame._template and frame._template:find("SecureActionButtonTemplate", 1, true) and frame._text == ns.TEXT.gameWindow then
            return frame
        end
    end
    return nil
end
local secure = SecureGame()
check(secure and secure._parent == UIParent and secure._shown, "the game's guild window: a secure button of ours on UIParent, shown with the roster")
check(secure:GetAttribute("type") == "click" and secure:GetAttribute("clickbutton") == GuildMicroButton
      and secure:GetAttribute("useOnKeyDown") == false, "it clicks the game's own micro menu button, on the release")
local bed = secure._points[1] and secure._points[1][2]
check(bed and bed._text == ns.TEXT.gameWindow and bed._template == "UIPanelButtonTemplate" and secure._points[2][2] == bed,
    "it lies over the head's own button")
W.Fire("PLAYER_REGEN_DISABLED") -- the game says so before it locks
W.combat = true                 -- then the stand-in refuses every touch of the secure button
check(not secure._shown and #secure._points == 0, "a fight begins: it goes, unanchored, before the game locks it")
bed._scripts.OnClick(bed)
check(ns.Page.Frame().status:GetText() == ns.TEXT.inFight, "in the fight the head's own button says so")
-- The roster left and shown anew in the fight: the secure button is left alone (the stand-in refuses a touch, as the
-- game does) and the module stands.
ns.Page.Choose(1, 1)
ns.Page.Choose(2, 1)
Frames(2)
check(not secure._shown and #secure._points == 0 and #caught == 0 and not ns.off
      and Core.errors["Guild: game window"] == nil and Core.errors["Guild: view: roster"] == nil,
    "the roster shown anew in the fight: the secure button is left alone until it is over")
W.Combat(false)
check(secure._shown and secure._points[1] and secure._points[1][2] == bed, "over, it is back over the head's button")
local kept = false
for _, retain in pairs(retained) do kept = kept or retain == true end
check(kept, "its lists are filled anew where they were scrolled to")
-- The window closed with the roster on show: the secure button (on UIParent, not under the window) goes with the
-- head, whose OnHide runs under the window's; opened again, the head's OnShow under it seats the button anew.
local headFrame = bed:GetParent()
ns.Window.Toggle()
local went = headFrame:IsShown() and not headFrame:IsVisible() and not secure._shown and #secure._points == 0
ns.Window.Toggle()
Frames(2)
check(went and secure._shown and secure._points[1] and secure._points[1][2] == bed,
    "the window closed, the secure button goes by the head's OnHide under it; opened again, its OnShow seats it anew")
ns.Page.Choose(2, 2)
Frames(2)
check(#caught == 0, "the equipment shown without an error: " .. tostring(caught[1]))
check(not secure._shown, "another view: the secure button is away")
for index = 3, 8 do ns.Page.Choose(index, 1) end
Frames(2)
check(#caught == 0, "every tab shown without an error: " .. tostring(caught[1]))
check(Core.errors["Guild: list"] == nil, "and their rows drawn without one")
ns.Window.Toggle()
check(not escape:IsShown(), "closed, Esc has nothing of it any more")
ns.Window.Toggle()
Frames(2)
check(escape:IsShown(), "opened again, Esc closes it again")
check(not ns.off, "the module did not stand down")

-- Retail: the same window and views; the doll has no ranged slot there, as the game's own paper doll.
local Equipment, paperDoll = ns.Views.equipment, rawget(_G, "C_PaperDollInfo")
local function Held() return table.concat(Equipment.Weapons(), ",") end
C_PaperDollInfo = { IsRangedSlotShown = function() return not Core.RETAIL end }
check(Held() == "16,17,18", "Forever: the doll's weapons, the ranged slot among them")
W.Play("retail")
check(Held() == "16,17", "Retail: no ranged slot, as the game's own paper doll")
ns.Window.Toggle()
ns.Window.Toggle()
Frames(2)
for index = 1, 8 do ns.Page.Choose(index, 1) end
ns.Page.Choose(2, 2)
Frames(2)
check(escape:IsShown() and #caught == 0 and not ns.off, "Retail: the window and every tab shown without an error: " .. tostring(caught[1]))
W.Play("forever")
C_PaperDollInfo = paperDoll
check(Held() == "16,17,18", "a client that cannot say keeps the ranged slot")
W.caught = nil

-- Standing down: the guild key is the game's again, the window offered no more, the roster no more asked for.
ns.StandDown("a test")
check(next(overrides) == nil, "the guild key opens the game's window again")
check(Board.Offered("Social", "guild") == nil, "Social's own guild window is back")
local askedThen = C_GuildInfo.asked
W.Fire("GUILD_ROSTER_UPDATE", true)
check(C_GuildInfo.asked == askedThen, "and the roster is no more asked for")

io.write(("Guild: all %d checks passed.\n"):format(passed))
