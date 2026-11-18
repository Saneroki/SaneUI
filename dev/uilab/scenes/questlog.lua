-- The quest log: its list with a quest unfolded, its text and its big reward icons (QuestLog.lua)
-- The rest of Navigation stands in, the game's quest log is the scene's own: three quests in two zones, one to pick a
-- reward from, one that teaches a spell, one for a group, the items the game's own from the data master, and two ghosts
-- from a giver's exclamation mark on the map on top, one for a group. Two quests want an item used, their buttons at
-- the far end of their rows with their tooltips; the lab has not the game's secure template, so a click does nothing here.
-- In the console, LabQuestLog is the module's log: LabQuestLog.Text(1102) unfolds another quest, LabQuestLog.Text(nil)
-- folds it; LabOnScreen() shows its look on the screen alone, at its first place under the small map's stand-in at the
-- top right, LabOnScreen(true) back over the full map; LabRight() moves it to the right half.
Lab.TOC("src/Core/SaneUI.toc")
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)
ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
ns.options = ns.options or {}
ns.options.questLogRest = false -- the scene is to look at: never out of sight

ns.Pins = { ICONS = { offer = "questnormal" }, RED = { 1, 0.2, 0.15 }, Standing = function() return "offered" end,
            Changed = function() end }
ns.TopBar = { LogShown = function() return true end, Update = function() end }
ns.Areas = { Hover = function() end }
-- The small map at the screen's top right, as large as Navigation's (Window.lua): a plain square standing in, its
-- bottom what the quest log on the screen alone stands under at first (Window.Under).
local map = CreateFrame("Frame", nil, UIParent)
map:SetSize(200, 200)
map:SetPoint("TOPRIGHT")
map:SetFrameStrata("LOW")
local mapBack = map:CreateTexture(nil, "BACKGROUND")
mapBack:SetAllPoints()
mapBack:SetColorTexture(0.12, 0.16, 0.12, 0.9)
local mapWords = map:CreateFontString(nil, "ARTWORK", "GameFontDisable")
mapWords:SetPoint("CENTER")
mapWords:SetText("the small map")
ns.Window = { OpenTo = function() end, UNDER = 230, frame = map,
              Under = function() return UIParent:GetTop() - map:GetBottom() end }
ns.Coords = { Planes = function() return {} end, Zones = function() return {} end }
ns.Canvas = { DOUBLE = 0.3, LookAt = function() end }
ns.PinView = { Drop = function() end, Light = function() end }
ns.Live = { Quests = function() return {} end }

local QUESTS = {
    [1101] = {
        title = "The Fargodeep Mine", level = 7, zone = "Elwynn Forest", watched = true,
        special = { item = 6411, charges = 3 },
        objectives = { { text = "Gold Dust: 4/10", type = "item" },
                       { text = "Kobold Tunneler slain: 3/7", type = "monster" },
                       { text = "Candle Thief slain: 2/2", type = "monster", finished = true } },
        asks = "Bring 10 pieces of Gold Dust to Remy \"Two Times\" in Goldshire.",
        story = "Hey there, friend! You look like you can handle yourself, and I need someone with a strong arm.\n\n"
            .. "The kobolds in the Fargodeep Mine have been hoarding gold dust, and a fellow in my trade hears things. "
            .. "If you were to bring me a pouch or two, I would make it worth your while.\n\n\n"
            .. "Mind the candles they wear on their heads. They bite, and they burn.\n",
        xp = 2450, money = 12550,
        things = { { item = 2589, count = 4 }, { item = 6411 } },
        choices = { { item = 12784 }, { item = 873 }, { item = 13262, unusable = true } },
    },
    [1102] = {
        title = "Report to Sentinel Hill", level = 12, zone = "Elwynn Forest", complete = true,
        objectives = {}, turnIn = "Report back to Gryan Stoutmantle in Sentinel Hill.",
        asks = "Speak to Gryan Stoutmantle at Sentinel Hill.",
        story = "The People's Militia needs every able hand.",
        xp = 880, money = 900, spells = { 133 },
    },
    [1103] = {
        title = "A Long Way Down", level = 14, zone = "Westfall", group = 3, special = { item = 2589 },
        objectives = { { text = "Harvest Golem slain: 2/8", type = "monster" }, { text = "Speak to Salma", type = "event" } },
        asks = "Destroy 8 Harvest Golems.", story = "They march at night.", xp = 1250, money = 0,
    },
}
local ORDER = { "Elwynn Forest", 1101, 1102, "Westfall", 1103 }

-- Ghosts: quests of Core's data, as a click on their giver's exclamation mark adds them.
local GHOSTS = { [2001] = { name = "The Jasperlode Mine", level = 8 },
                 [2002] = { name = "Bounty on Murlocs", level = 9, groupSize = 5 } }
local Set = Core.Data.Set("Quests")
local get = Set.Get
Set.Get = function(self, quest, field)
    local ghost = GHOSTS[quest]
    if not ghost then return get(self, quest, field) end
    if field then return ghost[field] end
    return ghost
end

local function Entry(index) return ORDER[index] end
C_QuestLog.GetNumQuestLogEntries = function() return #ORDER end
C_QuestLog.GetMaxNumQuestsCanAccept = function() return 25 end
C_QuestLog.GetInfo = function(index)
    local entry = Entry(index)
    if type(entry) == "string" then return { isHeader = true, title = entry } end
    local quest = QUESTS[entry]
    return { title = quest.title, level = quest.level, questID = entry, suggestedGroup = quest.group }
end
C_QuestLog.GetLogIndexForQuestID = function(id)
    for index, entry in ipairs(ORDER) do if entry == id then return index end end
    return nil
end
C_QuestLog.GetTitleForQuestID = function(id) return QUESTS[id] and QUESTS[id].title end
C_QuestLog.IsComplete = function(id) return QUESTS[id].complete end
C_QuestLog.IsFailed = function() return false end
C_QuestLog.GetQuestWatchType = function(id) return QUESTS[id].watched and 1 or nil end
C_QuestLog.GetQuestObjectives = function(id) return QUESTS[id].objectives end
C_QuestLog.GetDistanceSqToQuest = function(id) return id, true end
C_QuestLog.GetQuestTagInfo = function() return nil end
C_QuestLog.GetNextWaypointText = function() return nil end
GetQuestDifficultyColor = function() return { r = 1, g = 0.82, b = 0 } end
GetQuestLogCompletionText = function(index) return QUESTS[Entry(index)].turnIn end
-- A quest's item, as the game's tracker asks for it.
local function Special(index)
    local quest = QUESTS[Entry(index)]
    return quest and quest.special
end
GetQuestLogSpecialItemInfo = function(index)
    local special = Special(index)
    if not special then return nil end
    local _, link, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(special.item)
    return link or ("|Hitem:%d|h|h"):format(special.item), icon, special.charges
end
GameTooltip.SetQuestLogSpecialItem = function(self, index) self:SetItemByID(Special(index).item) end
-- The game's state driver, which the lab has not: it only hides the items' tray in a fight.
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
GetQuestLogQuestText = function(index)
    local quest = QUESTS[Entry(index)]
    return quest.story, quest.asks
end

-- Its rewards, by the quest's ID, as the game gives them.
GetQuestLogRewardXP = function(id) return QUESTS[id].xp end
GetQuestLogRewardMoney = function(id) return QUESTS[id].money end
local function Thing(list, index)
    local entry = list and list[index]
    if not entry then return nil end
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(entry.item)
    return name, icon, entry.count or 1, quality, not entry.unusable, entry.item
end
GetNumQuestLogRewards = function(id) return #(QUESTS[id].things or {}) end
GetQuestLogRewardInfo = function(index, id) return Thing(QUESTS[id].things, index) end
GetNumQuestLogChoices = function(id) return #(QUESTS[id].choices or {}) end
GetQuestLogChoiceInfo = function(index, id) return Thing(QUESTS[id].choices, index) end
-- An amount of money as the game writes it, with its coin icons (the lab does not).
C_CurrencyInfo.GetCoinTextureString = function(copper)
    local function Coin(amount, kind)
        return amount > 0 and ("%d|TInterface\\MoneyFrame\\UI-%sIcon:14:14:2:0|t "):format(amount, kind) or ""
    end
    return Coin(math.floor(copper / 10000), "Gold") .. Coin(math.floor(copper / 100) % 100, "Silver")
        .. Coin(copper % 100, "Copper")
end
C_QuestInfoSystem.GetQuestRewardCurrencies = function() return {} end
C_QuestInfoSystem.GetQuestRewardSpells = function(id) return QUESTS[id].spells or {} end
C_QuestInfoSystem.GetQuestRewardSpellInfo = function(_, spell)
    local info = C_Spell.GetSpellInfo(spell)
    return info and { name = info.name, texture = info.iconID }
end
C_SpellBook.IsSpellInSpellBook = function() return false end
GameTooltip.SetQuestLogItem = function(self, list, index, id)
    local entry = (list == "choice" and QUESTS[id].choices or QUESTS[id].things)[index]
    self:SetItemByID(entry.item)
end

Lab.Addon("SaneUI_Navigation", "src/Navigation/QuestLog.lua")

Lab.OnLogin(function()
    local QuestLog = ns.QuestLog
    LabQuestLog = QuestLog
    QuestLog.Build()
    ns.store.questLogSort = "zone"
    QuestLog.Lay(true)
    QuestLog.Preview({ 2001, 2002 }, 1429, 0.4, 0.4)
    QuestLog.Text(1101)
    LabOnScreen = function(back)
        QuestLog.Lay(back)
        QuestLog.Text(1101)
    end
    LabRight = function()
        QuestLog.handle.frame:ClearAllPoints()
        QuestLog.handle.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -30)
        QuestLog.handle.options.docked()
    end
end)
