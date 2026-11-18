-- Runs the Tooltips module against the stand-in client (wowstub.lua): how a tooltip's lines are
-- sorted into a panel, when a panel is drawn, when the tooltip is left to the game, and that a
-- failure gives the game's own tooltips back.
-- The look itself can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/tooltips.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-- What the module needs of the client -----------------------------------------------------
local TYPE = { Item = 0, Spell = 1, Unit = 2, Corpse = 3, Object = 4, UnitAura = 7, Toy = 19, Quest = 23 }
local LINE = { None = 0, Blank = 1, QuestObjective = 8, SellPrice = 11, QuestTitle = 17, QuestPlayer = 18, NestedBlock = 19, ItemBinding = 20,
    EquipSlot = 21, Separator = 23, ItemLevel = 31, SpellPassive = 33, SpellDescription = 34 }
Enum.TooltipDataType, Enum.TooltipDataLineType = TYPE, LINE
Enum.TooltipDataItemBinding = { Soulbound = 3, BindOnPickup = 6, BindOnEquip = 7, BindOnUse = 8 }
local postCalls = {}
TooltipDataProcessor = {
    AllTypes = "ALL",
    AddTooltipPostCall = function(kind, fn) postCalls[#postCalls + 1] = { kind = kind, fn = fn } end,
}
GetLocale = function() return "enUS" end
IsAltKeyDown = function() return W.alt or false end
IsShiftKeyDown, IsControlKeyDown = function() return W.shift or false end, function() return W.ctrl or false end
PTR_IssueReporter = { BugTooltipString = "|c0042b1fePress %s to submit an issue for this %s" }
for _, name in ipairs({ "GameTooltipText", "GameTooltipHeaderText" }) do
    local font = W.NewWidget("Font", name)
    function font:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
    _G[name] = font
end
-- The game's PixelUtil (Blizzard_SharedXML/PixelUtil.lua), with one dot of the screen as large as a unit
-- of the interface, unless a test says otherwise (pixel).
local pixel = 1
PixelUtil = { GetPixelToUIUnitFactor = function() return pixel end }
function PixelUtil.GetNearestPixelSize(size, scale, least)
    local factor = PixelUtil.GetPixelToUIUnitFactor()
    local dots = math.floor(size * scale / factor + 0.5)
    if least and dots < least then dots = least end
    return dots * factor / scale
end
ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
local colors = {} -- every colour the module made: the first two are the background's gradient
CreateColor = function(r, g, b, a)
    local color = { r = r, g = g, b = b, a = a }
    function color:SetRGBA(nr, ng, nb, na) self.r, self.g, self.b, self.a = nr, ng, nb, na end
    colors[#colors + 1] = color
    return color
end
W.items[19019] = { name = "Thunderfury", quality = 4 }
W.spells[133] = { name = "Fireball" }
for _, id in ipairs({ 5, 75, 2383, 1243 }) do W.spells[id] = { name = "A spell" } end
C_Item.GetItemQualityByID = function(id) return W.items[id] and W.items[id].quality end
-- The auction house's list as you browse it (Core's Prices.lua), and the clock
browse = {}
C_AuctionHouse = { GetBrowseResults = function() return browse end }
time = function() return 100 * 86400 end
-- A spell's cast, cooldown and cost, and the chance of a critical strike (fire: 3)
local spellInfo = { [133] = { castTime = 2500 } }
C_Spell.GetSpellInfo = function(id) return spellInfo[id] end
GetSpellBaseCooldown = function() return 0, 1500 end
local spellCosts = { [133] = { { type = 0, name = "MANA", cost = 30 } } }
GetSpellPowerCost = function(id) return spellCosts[id] or {} end
MANA = "Mana"
SPELL_ON_NEXT_RANGED = "Shot at the next swing" -- worded otherwise than the English stand-in: the game's sentence is the one read
GetSpellCritChance = function(school) return school == nil and 6.2 or 4 end -- this client: one chance, no school asked
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end }
local units = { ["Player-1"] = "mouseover", ["Creature-1"] = "target" }
UnitTokenFromGUID = function(guid) return units[guid] end
UnitHealth, UnitHealthMax = function() return 40 end, function() return 100 end
local anchored = {}
GameTooltip_SetDefaultAnchor = function(tooltip, parent) -- the screen's corner
    tooltip:SetOwner(parent, "ANCHOR_NONE")
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 80)
end

-- The end of a frame: the tooltips the game filled are drawn.
local ns = {}
function frame()
    if ns.driver and ns.driver:IsShown() then ns.driver._scripts.OnUpdate(ns.driver, 0.02) end
end

-- What a unit is, for the game's unit functions.
local world = {
    mouseover = { player = true, name = "Jaina", surname = "Proudmoore", level = 60, class = { "Mage", "MAGE" }, race = "Human", guild = "Dawnbreakers",
        side = "Alliance", pvp = true, power = "MANA", target = true },
    target = { name = "Kobold", level = 5, creature = "Humanoid", kind = "elite", power = false },
    player = { player = true, name = "Sane", surname = "Lunatic", level = 60, class = { "Mage", "MAGE", 8 }, race = "Human", raceID = 1,
        side = "Alliance", power = "MANA" },
    mouseovertarget = { name = "Ragnaros", level = 63 },
}
local function unitOf(unit) return world[unit] or {} end
-- Inspecting another player: the questions asked of the server, and the answers it has
local inspected, gear = {}, { mouseover = 61 }
NotifyInspect = function(unit) inspected[#inspected + 1] = unit end
CanInspect = function(unit) return world[unit] ~= nil and world[unit].player end
CheckInteractDistance = function() return true end
C_PaperDollInfo = { GetInspectItemLevel = function(unit) return gear[unit] end }
GetAverageItemLevel = function() return 58.4, 57.6 end
ClearInspectPlayer = function() end
UnitExists = function(unit) return world[unit] ~= nil and (unit ~= "mouseovertarget" or world.mouseover.target) end
UnitIsPlayer = function(unit) return unitOf(unit).player or false end
UnitClass = function(unit) local class = unitOf(unit).class or {} return class[1], class[2], class[3] end
UnitLevel = function(unit) return unitOf(unit).level end
UnitName = function(unit) return unitOf(unit).name, unitOf(unit).surname end -- a Forever player: first name, surname
UnitRace = function(unit) return unitOf(unit).race, unitOf(unit).race, unitOf(unit).raceID end
UnitCreatureType = function(unit) return unitOf(unit).creature end
UnitClassification = function(unit) return unitOf(unit).kind or "normal" end
UnitFactionGroup = function(unit) return unitOf(unit).side, unitOf(unit).side end
UnitIsPVP = function(unit) return unitOf(unit).pvp or false end
UnitIsBossMob = function(unit) return unitOf(unit).boss or false end
UnitIsUnit = function(a, b) return a == b end
UnitReaction = function(unit) return unitOf(unit).reaction or 2 end
UnitPowerType = function(unit) return 0, unitOf(unit).power or nil end
UnitPowerMax = function(unit) return unitOf(unit).power and 100 or 0 end
UnitPower = function() return 50 end
GetGuildInfo = function(unit) return unitOf(unit).guild, unitOf(unit).guildRank end
UnitCanAttack = function(_, unit) return not unitOf(unit).player end
UnitIsConnected = function(unit) return not unitOf(unit).offline end
UnitIsAFK = function(unit) return unitOf(unit).afk or false end
UnitIsDND = function() return false end
UnitIsGhost = function() return false end
UnitIsDead = function(unit) return unitOf(unit).dead or false end
UnitCreatureFamily = function(unit) return unitOf(unit).family end
UnitIsTapDenied = function(unit) return unitOf(unit).tapped or false end
UnitPVPName = function(unit)
    local name = unitOf(unit).surname and (unitOf(unit).name .. " " .. unitOf(unit).surname) or unitOf(unit).name
    return unitOf(unit).title and (unitOf(unit).title .. " " .. name) or name
end
UnitXP, UnitXPMax, MAX_PLAYER_LEVEL = function() return 100 end, function() return 1000 end, 60
UnitHealthPercent, CurveConstants = function() return 83 end, { ScaleTo100 = 1 }
BreakUpLargeNumbers = function(number) return tostring(number) end
SetPortraitTexture = function(texture, unit) texture.portrait = unit end
W.methods.SetKeepModelOnHide = function(self, keep) self._keep = keep end -- a model frame keeps its model while hidden
GetCreatureDifficultyColor = function() return { r = 1, g = 1, b = 0 } end
GetQuestDifficultyColor = GetCreatureDifficultyColor
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
FACTION_BAR_COLORS = { [2] = { r = 1, g = 0, b = 0 } }
-- The game's colours of the kinds of debuff (the borders of debuffs)
AuraUtil = { GetDebuffDisplayInfoTable = function() return { Magic = { color = { r = 0.2, g = 0.6, b = 1 } } } end }
local auras = {} -- [unit] = { HELPFUL = { aura, ... }, HARMFUL = { ... } }
C_UnitAuras = {
    GetAuraDataByIndex = function(unit, index, filter) return auras[unit] and auras[unit][filter] and auras[unit][filter][index] end,
    GetAuraDataByAuraInstanceID = function(unit, id)
        for _, list in pairs(auras[unit] or {}) do for _, aura in ipairs(list) do if aura.auraInstanceID == id then return aura end end end
    end,
}
local quests = {} -- [quest] = { level = , on = , ready = , title = , objectives = }
C_QuestLog = {
    GetQuestDifficultyLevel = function(id) return quests[id] and quests[id].level end,
    IsOnQuest = function(id) return quests[id] and quests[id].on or false end,
    ReadyForTurnIn = function(id) return quests[id] and quests[id].ready or false end,
    IsQuestFlaggedCompleted = function() return false end,
}

indexed = false -- whether the game's data says where each of its lines stands

local WHITE, GOLD, GREEN = { 1, 1, 1 }, { 1, 0.82, 0 }, { 0, 1, 0 }

-- A tooltip as the game has one: lines with two sides, a size, padding, an alpha.
local function Tooltip(name)
    local tooltip = W.NewWidget("GameTooltip", name)
    tooltip.left, tooltip.right, tooltip.count, tooltip._shown = {}, {}, 0, false
    tooltip._width, tooltip._height, tooltip.padding = 100, 50, { 0, 0, 0, 0 }
    tooltip._owner = UIParent -- the game gave it an owner before it filled it
    -- The stand-in answers any capitalised name with a function: say what is not there.
    tooltip.IsEmbedded, tooltip.ItemTooltip, tooltip.CloseButton, tooltip.CompareHeader = false, false, false, false
    function tooltip:NumLines() return self.count end
    function tooltip:GetLeftLine(index) return self.left[index] end
    function tooltip:GetRightLine(index) return self.right[index] end
    function tooltip:GetPadding() return unpack(self.padding) end
    function tooltip:SetPadding(right, bottom, left, top)
        self._width, self._height = self._width - self.padding[1] + right, self._height - self.padding[2] + bottom
        self.padding = { right, bottom, left, top }
    end
    function tooltip:GetAnchorType() return self.anchor end
    function tooltip:SetOwner(owner, anchor) self._owner, self.anchor = owner, anchor end
    function tooltip:SetAnchorType(anchor) self.anchor = anchor end
    -- As in the game: Show is a function the frame has, and OnShow runs only when it was hidden.
    function tooltip:Show()
        local was = self._shown
        self._shown, self._alpha = true, 1
        if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
    end
    function tooltip:GetPrimaryTooltipData() return self.primary end
    function tooltip:GetPrimaryTooltipInfo() return self.info end
    function tooltip:GetUnit() return nil end
    function tooltip:SetShown(shown) if shown then self:Show() else self:Hide() end end
    function tooltip:FadeOut() self._fading = true end -- the game fades it, and hides it later
    -- The game fills it. rows: { left, right, left colour, right colour, type } each; data: what the
    -- addons are told (nil: lines somebody wrote in by hand).
    -- A row with nothing = true is a line of the data without text: the game adds no line for it,
    -- and says it stands where the last line does (TooltipDataHandler).
    function tooltip:Fill(data, rows, unsettled)
        if self._scripts.OnTooltipCleared then self._scripts.OnTooltipCleared(self) end
        if data then data.lines = {} end
        self.primary = data
        local index = 0
        for _, row in ipairs(rows) do
            if not row.nothing then
                index = index + 1
                for side, list in pairs({ [1] = self.left, [2] = self.right }) do
                    list[index] = list[index] or W.NewWidget("FontString", nil, self)
                    list[index]:SetText(row[side])
                    list[index]:SetTextColor(unpack(row[side + 2] or WHITE))
                    list[index]._shown = row[side] ~= nil
                end
            end
            if data and not row.added then
                -- The game says where a line stands (lineIndex), or it does not: both are tried.
                local info = { leftText = row[1], type = row[5] or 0, price = row.price, lineIndex = indexed and index or nil }
                for key, value in pairs(row.data or {}) do info[key] = value end
                data.lines[#data.lines + 1] = info
            end
        end
        self.count = index
        if data then for _, call in ipairs(postCalls) do call.fn(self, data) end end
        self:Show()
        if not unsettled then frame() end
    end
    return tooltip
end
local function tick(panel, elapsed) panel._scripts.OnUpdate(panel, elapsed or 0.02) end
-- What a panel shows: its head, and a row by its number.
local function head(panel) return panel.model.shown.head end
local function row(panel, index) return panel.model.shown.rows[index] or {} end
-- The rows of a panel, without the tiny line at its bottom that Alt shows more (it is tested by itself)
local function hinted(panel)
    local shown = panel.model.shown
    local last = shown.rows[shown.n]
    return shown.n > 0 and last.font == "hint" and last.left == "Hold ALT for more"
end
local function count(panel) return panel.model.shown.n - (hinted(panel) and 1 or 0) end
-- Its rows in short: a section's caption by its name in capitals, every other row by its kind
-- ("text", "strip", "bar", "auras"), a row with room above it with a "+" before
local function shape(panel)
    local list = {}
    for index = 1, count(panel) do
        local one = row(panel, index)
        list[index] = (one.space and "+" or "") .. (one.kind == "caption" and one.left:upper() or one.kind)
    end
    return table.concat(list, " ")
end

-- Core's data the module reads: a few made-up quests and drops (dev/tests/data/tooltips) compiled into set files
-- on the real schemas, read with Core at the login
local folder = io.popen("mktemp -d -t saneui-tooltips-XXXXXX"):read("*l")
check(folder and os.execute(("python3 -I '%s/dev/tests/data/sets.py' '%s/dev/tests/data/tooltips' '%s'"):format(root, root, folder)) == 0,
    "the tools compiled the sample quests, drops, nodes and disenchanting into set files")
-- The characters' saved file: two alts, one of them sharing your first name; a broken entry, and what one alt
-- wears slot by slot in a wrong shape
SaneUIData_Characters = { forever = { format = 1, characters = {
    ["Player-70-0000BEEF"] = { name = "Droopy Fairwind", class = "WARRIOR", level = 30, bags = "4500\03112\0304501\0311", bank = "4500\0318", slots = 12 },
    ["Player-70-0000CAFE"] = { name = "Sane Moonwhisper", class = "PRIEST", level = 12, worn = "4500\0311", slots = "5\0314500" },
    ["Player-70-0000DEAD"] = "not a character",
}, account = { bank = "4500\0315" } }, ["forever-beta"] = { format = 1, characters = { ["Player-70-0000BEEF"] = { name = "Beta", bags = "4502\0319" } } } }
-- Your own bags: the backpack with three of the first thing, a bag with two more
local bagItems = { [0] = { { itemID = 4500, stackCount = 3 } }, [1] = { {}, { itemID = 4500, stackCount = 2 } } }
C_Container = {
    GetContainerNumSlots = function(bag) return bagItems[bag] and #bagItems[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot) local info = bagItems[bag] and bagItems[bag][slot] return info and info.itemID and info or nil end,
}
GetInventoryItemID = function() return nil end
Enum.BankType = { Character = 0, Account = 2 }
GetMoney = function() return 12345 end

-- The addons: Core (with its data framework), then the module -------------------------------------------
-- Of Core only what the module uses: its tools, the kit (pools, pixels, a frame lent), the saved settings
-- and where they live (Profiles), Fuzzy for a text without its codes, the look and the setups (Setup.lua), the data
-- framework, and the inspections.
W.Load(root, "SaneUI", "Core/Core", {})
W.Load(root, "SaneUI", "Core/Kit", {})
W.Load(root, "SaneUI", "Core/Units", {})
W.Load(root, "SaneUI", "Core/Stats", {})
W.Load(root, "SaneUI", "Core/Serial", {})
W.Load(root, "SaneUI", "Core/Motion", {})
W.Load(root, "SaneUI", "Core/Saved", {})
W.Load(root, "SaneUI", "Core/Presets", {})
W.Load(root, "SaneUI", "Core/Profiles", {})
W.Load(root, "SaneUI", "Core/Fuzzy", {})
W.Load(root, "SaneUI", "Core/Look", {})       -- the kit's parts, for the setup's words (Setup.lua)
W.Load(root, "SaneUI", "Core/Onboarding", {}) -- where the module hands in its setup
for _, file in ipairs({ "Steps", "Codec", "Data", "Tally", "Drops", "Rhythm", "Prices", "Fees", "Characters" }) do W.Load(root, "SaneUI", "Core/Data/" .. file, {}) end
W.Load(root, "SaneUI", "Core/People", {}) -- aliases and notes of players
W.Load(root, "SaneUI", "Core/Inspect", {}) -- a player's item level and talents, paced inspections
W.AddSets(folder .. "/Sets") -- the set files, at the end of Core's TOC
local Core = SaneUI.Core
local Data = Core.Data
-- Saved by an earlier version (the first shape of the settings): by hand, no choice; the mouse switch of version 2.
SaneUIDB = { modules = { Tooltips = { options = { show = "never", cursor = true } } } }
W.Fire("ADDON_LOADED", "SaneUI")
W.Fire("ADDON_LOADED", "SaneUI_AuctionData")
-- The scheduler's frames (Steps.lua): reading the characters
local function Steps(frames)
    local steps = Core.Steps.frame
    for _ = 1, frames or 10 do
        W.ms = W.ms + 20
        if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
    end
    W.Wait(0) -- the next frame: Core tells a set's listeners then
end
local files = { "Tooltips", "Texts", "Model", "Read", "Live", "Inspect", "Numbers", "Quests", "Gathering", "Figures" }
for _, name in ipairs({ "Kinds/Gold", "Kinds/Inventory", "Kinds/Item", "Kinds/Spell", "Kinds/Unit", "Kinds/Aura", "Kinds/Quest",
    "Kinds/Object", "Pools", "Panel", "PriceGraph", "Host", "Setup" }) do
    files[#files + 1] = name
end
for _, file in ipairs(files) do
    W.Load(root, "SaneUI_Tooltips", "Tooltips/" .. file, ns)
end
check(SaneUI.Tooltips == ns and ns.addon == "SaneUI_Tooltips", "the module is an addon of its own")
check(ns.QuestFacts == nil and ns.Quests and Data.Set("Quests"):State() == "ready",
    "the module keeps no quest data of its own: it reads Core's, there with Core")
W.Fire("ADDON_LOADED", "SaneUI_Tooltips")
local options = ns.options
check(options == Core.Settings("Tooltips"), "the switches are the table Core keeps for the module")
check(options.cursor == "always" and options.classColors == true and options.icons == true and options.textSize == 14 and options.opacity == 97,
    "its settings: the mouse off, class colours and icons on, the text 14 high, the background almost solid")
check(options.show == "shift", "and tooltips shown while Shift is held (a saved value that is no choice of the option gets that)")
check(Core.Described("Tooltips", "cursor").choices[1][1] == "default" and Core.Described("Tooltips", "cursor").default == "default",
    "the mouse option at first: the game's place; one saved as switched on (an older version) is Always now")
options.cursor = "default"
options.show = "always" -- shown at once, until the key is tried (below)
check(options._version == 3, "the settings say which shape of them they are, with each copy")
check(#postCalls == 0, "nothing is asked of the game before the login")
local tip = Tooltip("GameTooltip")
GameTooltip = tip
-- The tooltip a chat link opens (the game's ItemRefTooltip): the mouse can be on it, and it has an X.
W.methods.EnableMouse = function(self, on) self._mouse = on end
W.methods.IsMouseEnabled = function(self) return self._mouse or false end
W.methods.SetHitRectInsets = function(self, ...) self._hit = { ... } end
W.methods.GetHitRectInsets = function(self) return unpack(self._hit or { 0, 0, 0, 0 }) end
local pinned = Tooltip("ItemRefTooltip")
ItemRefTooltip = pinned
pinned.CloseButton = W.NewWidget("Button", nil, pinned)
pinned:EnableMouse(true)
pinned.CloseButton:EnableMouse(true)
W.Fire("PLAYER_LOGIN")
local Prices = Core.Data.Series("Prices")
check(#postCalls == 1 and postCalls[1].kind == "ALL", "one listener for every kind of tooltip data")
check(Data.Set("Quests"):Ready() and Data.Set("Drops"):Ready() and Data.Set("Disenchants"):Ready(),
    "at the login Core's data the module reads is there (Quests, Drops, Disenchants)")
check(Data.Count(4500) == nil, "and Core reads the characters' data in steps; until they are done, nothing is counted")
check(tip._scripts.OnTooltipCleared and tip._scripts.OnShow and ns.Panel.All()[tip] == nil,
    "the tooltips that also show hints are hooked at login; their panels are only made when first needed")

-- Sentences of the game with gaps
check(("Durability 61 / 120"):match(ns.PATTERN.DURABILITY) == "61" and ("(53.8 damage per second)"):match(ns.PATTERN.DPS) == "53.8"
    and ("Requires Level 58"):match(ns.PATTERN.MIN_LEVEL) == "58" and not ("Requires Level 58 or so"):match(ns.PATTERN.MIN_LEVEL),
    "a sentence of the game with gaps becomes a pattern that finds what stands in the gaps")

-- A spell -----------------------------------------------------------------------------------
W.methods.SetShadowOffset = function(self, x, y) self._shadowX, self._shadowY = x, y end
W.methods.SetShadowColor = function(self, r, g, b, a) self._shadowColor = { r, g, b, a } end
W.methods.SetTextColor = function(self, r, g, b, a) self._color, self._textAlpha = { r, g, b }, a end
W.methods.SetVertexColor = function(self, r, g, b, a) self._color = { r, g, b, a } end
local elune = {
    { "Elune's Light", "Racial" },
    { "Instant", "3 min cooldown" },
    { "Increases your critical strike chance with all spells and attacks by 10% for 15 sec.", nil, GOLD, nil, LINE.SpellDescription },
    { "", "Racial", nil, nil, 0, added = true },
    { "|c0042b1fePress F6 to submit an issue for this spell", nil, nil, nil, 0, added = true },
}
tip:Fill({ type = TYPE.Spell, id = 5 }, elune)
local panel = ns.Panel.All()[tip]
check(panel:IsShown() and tip:GetAlpha() == 0, "a spell's tooltip gets a panel, and the game's tooltip is invisible under it")
check(tip.left[1]:GetAlpha() == 0 and tip.right[2]:GetAlpha() == 0 and tip.left[3]:GetAlpha() == 0,
    "and so is each of its lines, which keeps them hidden when the game sets the tooltip's alpha itself (as it does to fade it out)")
-- A strip's cells as one text: "Cast Instant, Cooldown 3 min"
local function cells(strip)
    local list = {}
    for index = 1, #strip, 2 do list[#list + 1] = strip[index] .. " " .. strip[index + 1] end
    return table.concat(list, ", ")
end
local COLOR = ns.COLOR
local function code(color) return ns.Hex(color[1], color[2], color[3]) end
local DETAIL_HEX = code(COLOR.DETAIL)
check(count(panel) == 5 and row(panel, 1).left == "Elune's Light" and row(panel, 1).font == "title" and row(panel, 1).caps
    and row(panel, 2).left == "|cff" .. DETAIL_HEX .. "Utility|r  \194\183  Racial" and head(panel).icon == 1000 + 5,
    "the header: name; what it is (neither hurting nor healing: utility) and rank; icon")
check(shape(panel) == "text text INFO strip +text",
    "the spell's own lines in one section, Info: its table, then a little apart the description; a line another addon "
    .. "added is not shown without Alt")
check(row(panel, 4).kind == "strip" and cells(row(panel, 4)) == "Mana ---, Cast Instant, CD 3 min, Range ---",
    "a spell that neither hurts nor heals: one row of four cells, cost, cast, cooldown, range, each from the game's sentence "
    .. "for it; --- for what its tooltip does not state")
check(row(panel, 5).left:find("^Increases") and row(panel, 5).prose and row(panel, 5).lr == COLOR.PROSE[1]
    and row(panel, 5).lb == COLOR.PROSE[3], "the description is a row, in the game's gold made lighter; the test realm's line about F6 is left out")
check(not head(panel).accent and row(panel, 1).lr == COLOR.TITLE[1] and COLOR.TITLE[1] < 1, "a white name gives a panel without a colour, and a softer white")
local shown = {}
for index = 1, panel.texts.taken do shown[#shown + 1] = panel.texts[index]._text end
check(shown[1] == "ELUNE'S LIGHT" and shown[3] == "|cff" .. DETAIL_HEX .. "Utility|r  \194\183  Racial" and shown[5] == "INFO"
    and shown[6] == "MANA" and shown[7] == "---" and shown[8] == "CAST" and shown[9] == "Instant" and shown[10] == "CD"
    and shown[11] == "3 min" and shown[14]:find("^Increases"),
    "drawn: the name in capitals, then the section's name, the table's captions, each over its value")
local function color(label) local r, g, b = label:GetTextColor() return r .. " " .. g .. " " .. b end
local NOTE = table.concat(COLOR.NOTE, " ")
local caption = panel.texts[8]
check(color(panel.texts[9]) == table.concat(COLOR.WHITE, " ") and color(caption) == NOTE and caption._textAlpha == 1,
    "the table's values white; its captions in the grey of a section's name")
local named = panel.texts[5]
check(color(named) == NOTE and math.abs(named._points[1][4] + named._width / 2 - panel:GetWidth() / 2) <= 1
    and panel.texts[3]._shadowX ~= 0 and caption._shadowX ~= 0,
    "a section's name in the same grey, in the middle; every text keeps its font's shadow")
local greys, rules = 0, {}
for index = 1, panel.lines.taken do
    local line = panel.lines[index]
    if line._color and table.concat({ line._color[1], line._color[2], line._color[3] }, " ") == NOTE and line._color[4] == 1 then
        greys = greys + 1
    end
    if line._height == 1 and line._width > 1 then rules[#rules + 1] = line end
end
check(#rules == 2 and rules[1]._points[1][4] == 12 and rules[2]._points[1][4] + rules[2]._width == panel:GetWidth() - 12
    and rules[1]._points[1][4] + rules[1]._width < panel.texts[5]._points[1][4],
    "a rule at each side of the section's name, from the panel's edge to the name, one hairline each (none round the "
    .. "line that Alt shows more)")
check(greys >= 3, "the rules and the lines between the table's cells all in the grey of a section's name")
local function size(label) return label.dressed and label.dressed.size end -- the size its font was given
check(size(panel.texts[1]) == 14 and size(panel.texts[14]) == 14 and size(panel.texts[9]) == 12 and size(panel.texts[8]) == 10,
    "name and lines in the text size, the table's values two smaller, captions as small as the game's small font")
check(panel.back._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\soft" and panel.back._points[1][4] == -8 and panel.back._points[2][4] == 8,
    "the panel has no border: its background is a shape with round corners and a soft edge, reaching a little past the panel")
check(colors[1].a == 0.97 and colors[2].a == 0.97 and colors[2].r > colors[1].r, "one gradient behind everything, as solid as the setting says, stronger at the top")
local topR = ns.Mix(COLOR.BACKDROP, COLOR.NEUTRAL, 0.28)
check(math.abs(colors[2].r - topR) < 1e-9 and colors[1].b > colors[1].r,
    "its colours from the game's own tooltip ground: at the top taken toward the panel's colour, at the bottom darker")

-- With Alt held: the technical details, then the lines other addons added, last
W.alt = true
tip:Fill({ type = TYPE.Spell, id = 5 }, elune)
check(shape(panel) == "text text INFO strip +text IDS text ADDONS text" and row(panel, 9).right == "Racial"
    and row(panel, 9).font == "small" and not hinted(panel),
    "with Alt, a line another addon added stands last, small, in a section of its own under the caption Addons")
W.alt = false
tip:Fill({ type = TYPE.Spell, id = 5 }, elune)
check(count(panel) == 5 and hinted(panel), "let go of Alt, and the details and the other addons' lines are gone again")
local hint = row(panel, 6)
check(hint.kind == "caption" and hint.left == "Hold ALT for more" and not hint.caps and hint.bare
    and ns.Panel.FONTS.hint.size < ns.Panel.FONTS.small.size,
    "without Alt a tiny grey line in the middle at the bottom, as written, without rules: that Alt shows more")

-- Filled again with the same lines
W.methods.SetJustifyH = function(self, side) self._justify = side end
local drawn = 0
local Draw = ns.Panel.Draw
ns.Panel.Draw = function(...) drawn = drawn + 1 return Draw(...) end
local function spell(cooldown)
    tip:Fill({ type = TYPE.Spell, id = 133 }, { { "Fireball", "Rank 2" }, { "30 Mana", "35 yd range" }, { "1.5 sec cast", cooldown },
        { "Hurls a fiery ball that causes 16 to 25 Fire damage.", nil, GOLD, nil, LINE.SpellDescription } })
end
spell()
check(drawn == 1 and count(panel) == 6 and cells(row(panel, 4)) == "Dmg 21, Mana 30 (30%), Cast 1.5 sec, Range 32 m",
    "a spell that hurts: a table, its first row what one cast does on average, its cost (also as a share of all your mana), "
    .. "its cast, its range")
check(shape(panel) == "text text INFO strip strip +text",
    "a table of two rows of four, under Info, then a little apart the description")
check(cells(row(panel, 5)) == "DPS 8.2, Per Mana 0.68, CD ---, Crit 6.2%",
    "its second row: per second of its cast, per point of mana, its cooldown (--- where it has none), the chance of a critical strike")
check(head(panel).accent and head(panel).ar == 1 and head(panel).ag == 0.5 and head(panel).ab == 0
    and row(panel, 2).left == "|cffFF8000Fire|r  \194\183  Rank 2",
    "a spell of fire has the colour the game's combat log gives fire, and says so under its name")
local described
for index = 1, panel.texts.taken do
    if panel.texts[index]._text == "Hurls a fiery ball that causes |cffFF800016|r to |cffFF800025|r Fire damage." then described = panel.texts[index] end
end
check(described, "the digits of its description are in that colour at full strength")
check(described and described._justify == "CENTER" and panel.texts[1]._justify == "LEFT", "the description stands in the middle; the other lines at the left")
spell()
tip:Hide()
spell()
check(drawn == 1 and tip:GetAlpha() == 0 and panel:IsShown(), "filled again with the same lines, nothing is drawn again, not even after it was hidden")
spell("8 sec cooldown")
check(drawn == 2 and cells(row(panel, 5)) == "DPS 8.2, Per Mana 0.68, CD 8 sec, Crit 6.2%", "a changed line is")

-- What fills a tooltip goes on writing into it, as the game does for a comparison
local comparison = { { "Fireball", "Rank 2" }, { "30 Mana", "35 yd range" }, { "1.5 sec cast", "8 sec cooldown" },
    { "Hurls a fiery ball that causes 16 to 25 Fire damage.", nil, GOLD, nil, LINE.SpellDescription },
    { "If you replace this item:", nil, nil, nil, 0, added = true } }
local function compare()
    tip:Hide()                                    -- the game hides it,
    tip:Fill({ type = TYPE.Spell, id = 133 }, comparison, true) -- fills it and tells us,
    check(panel:IsShown() and tip:GetAlpha() == 0, "between being filled and being drawn the old panel stands, and the tooltip is invisible")
    frame()                                       -- and the frame ends
end
W.alt = true -- (other addons' lines are shown with Alt)
compare()
check(drawn == 3 and count(panel) == 10 and row(panel, 9).left == "Addons" and row(panel, 10).font == "small",
    "lines written after the game told us are in the panel when it is first drawn")
compare()
compare()
check(drawn == 3 and panel:IsShown(), "and a tooltip that is hidden and filled the same way again and again is drawn once")
drawn = 1
spell("8 sec cooldown")

-- A line another addon adds after us
tip.count = tip.count + 1
tip.left[tip.count] = W.NewWidget("FontString", nil, tip)
tip.left[tip.count]:SetText("Learned from a trainer")
tick(panel)
check(drawn == 3 and count(panel) == 10 and row(panel, 9).kind == "caption" and row(panel, 10).left == "Learned from a trainer",
    "a line added after the panel was drawn is taken in on the next frame, in the section of other addons' lines")
W.alt = false

-- What a spell asks of you stands in its header, under what it is
tip:Fill({ type = TYPE.Spell, id = 75 }, { { "Shoot" }, { "Requires Ranged Weapon" }, { "Shoots.", nil, GOLD, nil, LINE.SpellDescription } })
check(shape(panel) == "text text text INFO text" and row(panel, 3).left == "Requires Ranged Weapon" and row(panel, 3).font == "sub"
    and row(panel, 3).lr == COLOR.DETAIL[1],
    "what a spell asks of you (a weapon) in its header, in a row of its own under what it is; no table where nothing is known "
    .. "(nor for a shot, without a ranged weapon)")
local RAGE_COST = { { type = 1, name = "RAGE", cost = 5 } }
spellCosts[6572] = RAGE_COST
W.spells[6572] = { name = "Revenge" }
tip:Fill({ type = TYPE.Spell, id = 6572 }, { { "Revenge", "Rank 1" }, { "5 Rage", "Melee Range" }, { "Instant", "5 sec cooldown" },
    { "Requires Defensive Stance", nil, { 1, 0.125, 0.125 } },
    { "Instantly counterattacks an enemy for 22 damage.", nil, GOLD, nil, LINE.SpellDescription } })
check(shape(panel) == "text text text INFO strip strip +text" and row(panel, 3).left == "Requires Defensive Stance"
    and row(panel, 3).lr == COLOR.RED[1] and row(panel, 3).lg == COLOR.RED[2],
    "a stance it needs under what it is, in red while you are not in it; then the table and the description")
check(cells(row(panel, 5)) == "Dmg 22, Rage 5, Cast Instant, Range Melee" and cells(row(panel, 6)) == "DPS 14.7, Per Rage 4.40, CD 5 sec, Crit 6.2%",
    "every fact in a cell of its own: what it does, its cost (rage), its cast, its range (Melee, short); per second, per point "
    .. "of rage, its cooldown, the chance of a critical strike")
check(head(panel).ar == COLOR.RED[1] and head(panel).ag == COLOR.RED[2] and row(panel, 2).left:find("Physical", 1, true),
    "a physical one is red")
tip:Fill({ type = TYPE.Spell, id = 2383 }, { { "Find Herbs" }, { "Passive", nil, nil, nil, LINE.SpellPassive }, { "Shows herbs.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left == "|cff" .. DETAIL_HEX .. "Utility|r  \194\183  Passive" and count(panel) == 4, "a passive spell says so under its name")
tip:Fill({ type = TYPE.Spell, id = 1243 }, { { "Renew" }, { "Heals the target of 45 damage over 15 sec.", nil, GOLD, nil, LINE.SpellDescription } })
check(head(panel).ag == COLOR.HEALTH[2] and head(panel).ag > head(panel).ar and row(panel, 2).left:find("Healing") and row(panel, 6).prose,
    "a spell that names no school but heals is green, and says Healing")
check(shape(panel) == "text text INFO strip strip +text" and cells(row(panel, 4)) == "Heal 45, Mana ---, Cast ---, Range ---"
    and cells(row(panel, 5)) == "HPS 3.0, Per Mana ---, CD ---, Duration 15 sec",
    "a heal over time: what it heals, per second of its time (not of the global cooldown); it lasts, so its last cell is how "
    .. "long; --- for what its tooltip does not state, and for what it does per point of a cost it does not have")
UnitDamage, UnitAttackSpeed, GetCritChance = function() return 40, 60 end, function() return 2.5 end, function() return 5 end
W.spells[6603] = { name = "Attack" }
tip:Fill({ type = TYPE.Spell, id = 6603 }, { { "Attack" }, { "Toggles attack.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 4)) == "Dmg 50, Mana ---, Speed 2.50, Range ---" and cells(row(panel, 5)) == "DPS 20.0, Per Mana ---, CD ---, Crit 5.0%"
    and row(panel, 2).left:find("Physical") and head(panel).ar == COLOR.RED[1] and head(panel).ag == COLOR.RED[2],
    "the melee swing: physical, in red; on average, its speed in the place of a cast, per second, the chance of a critical strike")
tip:Fill({ type = TYPE.Spell, id = 5 }, { { "Inner Fire" }, { "Increases armor by 50 for 10 min.", nil, GOLD, nil, LINE.SpellDescription } })
check(count(panel) == 4 and row(panel, 2).left == "|cff" .. DETAIL_HEX .. "Utility|r", "a spell that neither hurts nor heals has no numbers")
W.spells[853] = { name = "Hammer of Justice" }
tip:Fill({ type = TYPE.Spell, id = 853 }, { { "Hammer of Justice" }, { "Stuns the target for 3 sec.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left:find("CC") and head(panel).ab == 1, "a spell that takes control of the target is CC, in blue")
-- Facts the game writes without a number stand as written; a client's own wording of a sentence is the one read
W.spells[1510] = { name = "Volley" }
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled", "Melee Range" }, { "Rains arrows on the enemy.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 4)) == "Mana ---, Cast Channeled, CD ---, Range Melee", "facts without a number, as the game writes them; melee range just Melee")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Shot at the next swing" }, { "Rains arrows on the enemy.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 4)) == "Mana ---, Cast Shot at the next swing, CD ---, Range ---", "a fact found by the game's own sentence for it, not by the English one")
-- Where the data gives a line no kind, a sentence in the game's gold is taken for the description
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Rains arrows on all enemies in the area for a while.", nil, GOLD } })
check(row(panel, 5).prose and row(panel, 5).lr == COLOR.PROSE[1] and row(panel, 3).left == "Info",
    "a gold line of no kind that reads as a sentence is the description")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Needs a bow", nil, GOLD } })
check(count(panel) == 6 and not row(panel, 6).prose and row(panel, 5).left == "Details", "a short one is none: it is one of the details")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Reagents: Arrow" }, { "Tools: Blacksmith Hammer" } })
check(row(panel, 3).left == "Reagents: Arrow" and row(panel, 4).left == "Tools: Blacksmith Hammer" and row(panel, 5).left == "Info",
    "its reagents and tools in its header too, each in a row of its own")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Rains arrows on all enemies in the area for a while.", nil, GOLD, nil, LINE.QuestTitle } })
check(not row(panel, 6).prose, "nor is a line the data gives another kind")
W.spells[2948] = { name = "Scorch" }
tip:Fill({ type = TYPE.Spell, id = 2948 }, { { "Scorch" }, { "Scorches the enemy for 1.5 sec, causing 12 Fire damage.", nil, GOLD, nil, LINE.SpellDescription } })
local scorched = false
for index = 1, panel.texts.taken do
    if panel.texts[index]._text == "Scorches the enemy for |cffFF80001|r.|cffFF80005|r sec, causing |cffFF800012|r Fire damage." then scorched = true end
end
check(scorched, "only a description's digits are coloured: the point between them keeps the description's colour")
-- A description's numbers (Numbers.lua), asked directly
local Figures = ns.Numbers.Spell
spellInfo[348] = { castTime = 2000 }
local figures = Figures(348, "Burns the enemy for 11 Fire damage and then an additional 20 Fire damage over 15 sec.")
check(figures and figures.amount == 31 and figures.heal == false and math.abs(figures.perSecond - (11 + 20 * 2 / 15) / 2) < 1e-9,
    "right away and over time: all of it is what one cast does; per second while cast again and again, only the part over "
    .. "time that runs before the next cast counts")
figures = Figures(5143, "Launches Arcane Missiles at the enemy, causing 26 Arcane damage each second for 3 sec.")
check(figures and figures.amount == 78 and math.abs(figures.perSecond - 26) < 1e-9, "repeated each second: all of it, and per second its own amount")
figures = Figures(15237, "Causes an explosion of holy light around the caster, causing 29 to 34 Holy damage to all enemy targets within 10 yards "
    .. "and healing all party members within 10 yards for 54 to 63.")
check(figures and figures.amount == 31.5 and figures.heal == false, "the first amount decides; what comes after it is a second effect")
figures = Figures(2061, "Heals a friendly target for 1,193 to 1,237.")
check(figures and figures.amount == 1215 and figures.heal == true and figures.crit == 6.2, "a heal, with numbers written with a comma")
check(Figures(17, "Draws on your faith to absorb 44 damage. Lasts 30 sec.") == nil, "a shield has no figures")
local baseCooldown = GetSpellBaseCooldown
GetSpellBaseCooldown = function(id) if id == 2136 then return 8000, 1500 end return 0, 1500 end
figures = Figures(2136, "Blasts the enemy for 24 to 32 Fire damage.")
check(figures and figures.amount == 28 and figures.perSecond == 3.5, "a spell with a cooldown: per second of its cooldown")
GetSpellBaseCooldown = function() return 0 end
figures = Figures(2136, "Blasts the enemy for 24 to 32 Fire damage.")
check(figures and math.abs(figures.perSecond - 28 / 1.5) < 1e-9, "where the game gives no global cooldown for a spell, the usual one counts")
GetSpellBaseCooldown = baseCooldown

-- An item --------------------------------------------------------------------------------
local reaper = {
    { "Thunderfury", nil, { 0.64, 0.21, 0.93 } },
    { "Item Level 63", nil, GOLD, nil, LINE.ItemLevel },
    { "Binds when picked up", nil, nil, nil, LINE.ItemBinding, data = { bonding = 6 } },
    { "One-Hand", "Sword", nil, nil, LINE.EquipSlot },
    { "44 - 115 Damage", "Speed 1.90" },
    { "(53.8 damage per second)" },
    { "+5 Agility" },
    { "Requires Level 60" },
    { "Durability 61 / 120" },
    { "Chance on hit: Blasts your enemy with lightning.", nil, GREEN },
    { " ", nil, nil, nil, LINE.SellPrice, price = 25500 },
}
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(row(panel, 1).left == "Thunderfury" and not row(panel, 1).caps and row(panel, 2).left == "Sword \194\183 One-Hand" and head(panel).icon == 2000 + 19019,
    "an item: its name as it is written, kind and slot under it, its icon")
check(row(panel, 2).font == "detail" and row(panel, 2).lr == COLOR.ASIDE[1] and row(panel, 2).right == "Requires Level 60" and row(panel, 2).rr == COLOR.ASIDE[1],
    "kind and slot small and grey, the level it needs beside them")
check(head(panel).accent and head(panel).ar == 0.64 and row(panel, 1).lr == 0.64, "the panel and the name in the colour of its quality")
check(head(panel).badge == "iLvl 63", "its level under the icon")
check(panel.iconMask._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\icon-mask",
    "a square icon has round corners and an edge that fades out softly (a mask in its own shape)")
check(head(panel).tag == "" and row(panel, 9).left == "|cff" .. code(COLOR.RED) .. "BoP|r" and row(panel, 9).right == "",
    "nothing over the name: how it binds is the first row of Gold, short as players write it, red until it is bound")
check(shape(panel) == "text text INFO text text text bar GOLD text text",
    "an item's own lines in one section, Info (its numbers, what it does, its durability), then Gold")
check(row(panel, 4).font == "big" and row(panel, 4).left == "53.8 |cff" .. DETAIL_HEX .. "DPS|r",
    "a weapon's damage per second, large, first in Info")
check(row(panel, 4).label == "\194\183  44 - 115 dmg  \194\183  1.90 spd" and row(panel, 4).labelFont == "sub",
    "its hit's damage and its speed after it in the same line, smaller")
check(row(panel, 5).left == "+5 Agi" and row(panel, 6).lg == 1, "then its lines; what it does in green, in Info too")
check(row(panel, 7).kind == "bar" and row(panel, 7).inside and row(panel, 7).value == 61 and row(panel, 7).max == 120
    and row(panel, 7).left == "Durability" and row(panel, 7).right == "61 / 120", "its durability as a bar, last of its own lines")
local durable = panel.liveBars.inside
check(durable and durable:IsShown() and durable._height == 18 and durable.texts.LEFT._text == "Durability" and durable.texts.RIGHT._text == "61 / 120",
    "the word Durability inside the bar at its left, the numbers at its right, as high as a unit's health bar")
check(panel.barMask._points[1][5] == select(5, durable:GetPoint(1)), "with round corners, like a unit's bars")
check(count(panel) == 10 and row(panel, 10).left == "Vendor" and row(panel, 10).right == "25500c",
    "and under it what a vendor pays for it, in coins: alone, without advice")
reaper[3].data.bonding = 3
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(row(panel, 9).left == "|cff" .. DETAIL_HEX .. "Soulbound|r", "once it is bound to you, that is no longer red")
indexed = true
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(count(panel) == 10 and row(panel, 2).left == "Sword \194\183 One-Hand" and head(panel).badge == "iLvl 63", "the same when the game says where each of its lines stands")
table.insert(reaper, 10, { nothing = true, [5] = LINE.SellPrice, price = 25500 })
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
table.remove(reaper, 10)
check(count(panel) == 10 and row(panel, 6).left == "Chance on hit: Blasts your enemy with lightning.",
    "a line of the game's data without text takes nothing from the line before it, which has the same index")
indexed = false
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Plans: Gloves", nil, { 0.64, 0.21, 0.93 } }, { "Requires Blacksmithing (80)" },
    { " ", nil, nil, nil, LINE.NestedBlock, data = { tooltipType = TYPE.Item, tooltipID = 19019 } }, { "Veteran's Gloves", nil, GREEN }, { "115 Armor" },
    { " ", nil, nil, nil, LINE.SellPrice, price = 400 } })
check(row(panel, 3).kind == "caption" and row(panel, 3).left == "Creates" and row(panel, 4).left == "Veteran's Gloves" and row(panel, 4).font == "title"
    and row(panel, 4).icon == 2000 + 19019, "a recipe: what it makes under a caption, with that thing's icon")
check(row(panel, 5).left == "115 Arm" and row(panel, 7).left == "Vendor" and row(panel, 7).right == "400c" and shape(panel) == "text text CREATES text text GOLD text",
    "the thing's lines are left as they are, all of them in the section Creates; the price under Gold")
-- An item set: its name, its pieces and its bonuses one section, Set; the description after it its own
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Belt of Might", nil, { 0.64, 0.21, 0.93 } }, { "+9 Strength" },
    { "Equip: Improves your chance to hit by 1%.", nil, GREEN }, { " ", nil, nil, nil, LINE.Blank }, { "Equip: Increases defense by 3.", nil, GREEN },
    { " ", nil, nil, nil, LINE.Blank }, { "Battlegear of Might (2/8)", nil, GOLD }, { "  Belt of Might", nil, { 0.5, 0.5, 0.5 } },
    { "(3) Set: +20 Armor", nil, GREEN }, { "(5) Set: +5 Strength", nil, { 0.5, 0.5, 0.5 } }, { '"Forged in the deep."', nil, GOLD } })
check(shape(panel) == "text INFO text text +text SET text text text text INFO text",
    "its own lines under Info, the game's empty line between two effects a gap; a set with its pieces and bonuses "
    .. "in one section, Set; its description after it, under Info again")
-- Another addon's line right after one of the game's (as TooltipDataProcessor.AddLinePostCall writes
-- it), where the game says where each of its lines stands: in the section Addons, not among the item's
local belt = { { "Belt of Might", nil, { 0.64, 0.21, 0.93 } }, { "+9 Strength" },
    { "Upgrade: +12%", nil, GREEN, added = true }, { "Equip: Improves your chance to hit by 1%.", nil, GREEN },
    { "Seen in 3 shops", added = true } }
indexed = true
tip:Fill({ type = TYPE.Item, id = 19019 }, belt)
check(shape(panel) == "text INFO text text", "other addons' lines are not shown without Alt, wherever they wrote them in the tooltip")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 19019 }, belt)
check(shape(panel) == "text INFO text text IDS text ADDONS text text" and row(panel, 8).left == "Upgrade: +12%"
    and row(panel, 9).left == "Seen in 3 shops", "with Alt, other addons' lines all in one section, Addons, last, wherever they wrote them")
indexed = false
tip:Fill({ type = TYPE.Item, id = 19019 }, belt)
check(shape(panel) == "text INFO text text text IDS text ADDONS text",
    "where the game does not say where its lines stand (they are found by their words), only the lines after its last are known as another addon's")
W.alt = false

-- The game's line of the price, the look, the auction house (prices noted while you browse it), a trade good
local hatchet = { { "Skull Hatchet", nil, { 0.64, 0.21, 0.93 } }, { "Binds when equipped", nil, nil, nil, LINE.ItemBinding, data = { bonding = 7 } },
    { "Sell Price: 81c", added = true }, { "You haven't collected this appearance", nil, { 0.53, 0.53, 0.93 } },
    { " ", nil, nil, nil, LINE.SellPrice, price = 81 } }
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(head(panel).tag == "" and row(panel, 2).left == "Gold" and row(panel, 3).left == "|cff" .. code(COLOR.RED) .. "BoE|r"
    and row(panel, 3).right == "|cff8787EDUncollected|r",
    "under Gold first how it binds, and at the right whether you have its look, short, in the game's colour for it")
check(count(panel) == 4 and row(panel, 4).left == "Vendor" and row(panel, 4).right == "81c",
    "the game's own line of the price is left out: the panel has a row for it, under Gold; no auction price before you have seen one")
-- At the auction house the game's own code writes an auction's seller, its time left and your bid after the item's lines, as
-- another addon would (and at a vendor an item's repair cost, with its coins under it): those are the game's own all the same,
-- shown under Details, not hidden as another addon's lines, whether or not the game says where its lines stand
do
    local auction = { { "Skull Hatchet", nil, { 0.64, 0.21, 0.93 } }, { "Binds when equipped", nil, nil, nil, LINE.ItemBinding, data = { bonding = 7 } },
        { " ", added = true }, { "Seller: |cffffffffBob|r", nil, GOLD, added = true }, { "Time Left: |cffffffffLong|r", nil, GOLD, added = true },
        { "|cff20ff20High Bidder|r", nil, GOLD, added = true }, { "Seen in 3 shops", added = true } }
    for _, placed in ipairs({ true, false }) do
        indexed = placed
        tip:Fill({ type = TYPE.Item, id = 19019 }, auction)
        check(shape(panel) == "text DETAILS text text text GOLD text" and row(panel, 3).left == "Seller: |cffffffffBob|r"
            and row(panel, 4).left == "Time Left: |cffffffffLong|r" and row(panel, 5).left == "|cff20ff20High Bidder|r" and hinted(panel),
            "an auction's seller, time left and your bid stand under Details without Alt, not hidden as another addon's lines")
        W.alt = true
        tip:Fill({ type = TYPE.Item, id = 19019 }, auction)
        check(shape(panel) == "text DETAILS text text text GOLD text IDS text ADDONS text" and row(panel, 11).left == "Seen in 3 shops",
            "with Alt the same, and only another addon's line under Addons")
        W.alt = false
    end
    indexed = false
    tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Skull Hatchet", nil, { 0.64, 0.21, 0.93 } }, { "Repair cost:", added = true },
        { "12|A:coin-silver:0:0:2:0|a 34|A:coin-copper:0:0:2:0|a", added = true }, { "Seen in 3 shops", added = true } })
    check(shape(panel) == "text DETAILS text text" and row(panel, 3).left == "Repair cost:" and row(panel, 4).left:find("coin%-silver", 1) ~= nil,
        "at a vendor the repair cost and the coins under it are the game's too")
end
browse = { { itemKey = { itemID = 19019 }, minPrice = 98765 }, { itemKey = { itemID = 4 }, minPrice = 0 } }
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(Prices:Low(19019) == 98765 and count(panel) == 6 and row(panel, 2).kind == "caption" and row(panel, 2).left == "Gold"
    and row(panel, 4).left == "Vendor" and row(panel, 5).left == "AH profit" and row(panel, 5).right == "93826c",
    "browsing the auction house, its lowest price is noted and kept in the saved settings; the Gold section says what a sale "
    .. "there brings, after the house's cut of 5%")
check(row(panel, 6).left == "Sell on the AH for 98765c" and row(panel, 6).icon == nil and row(panel, 6).font == "row" and row(panel, 6).lg == COLOR.DONE[2],
    "and in one line, in green, what to do: it brings more there than at a vendor")
-- A row of the auction house's lists: the game fills the tooltip by the item's link without the vendor's price
-- (GetHyperlink's fourth argument, hideVendorPrice), which nothing else leaves out
tip.info = { getterName = "GetHyperlink", getterArgs = { "item:19019", nil, nil, true, n = 4 } }
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Buy if under 93826c" and row(panel, 6).right == "now 98765c" and row(panel, 6).lr == COLOR.RED[1],
    "an item the auction house lists to you: the most it is worth paying, red while the lowest price is over it")
-- The house fills its list of your own auctions the same way: the advice to buy only while it shows what it sells
AuctionHouseFrameDisplayMode = { Buy = {}, ItemBuy = {}, CommoditiesBuy = {}, Auctions = {} }
AuctionHouseFrame = { GetDisplayMode = function(self) return self.mode end, mode = AuctionHouseFrameDisplayMode.Auctions }
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Sell on the AH for 98765c", "in the house's list of your own auctions: what to do with it, no advice to buy")
AuctionHouseFrame.mode = AuctionHouseFrameDisplayMode.ItemBuy
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Buy if under 93826c", "in its list of what it sells: the advice to buy")
AuctionHouseFrame, AuctionHouseFrameDisplayMode = nil, nil
tip.info = { getterName = "GetHyperlink", getterArgs = { "item:19019", n = 1 } }
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Sell on the AH for 98765c", "the same item by its link anywhere else: what to do with it for gold")
tip.info = nil
W.alt = true
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Sell at" and row(panel, 6).right == "98700c" and row(panel, 7).left == "Sell on the AH for 98765c",
    "with Alt, the price to post it at, before the advice: under the lowest offer, in whole silver, as it does not stack")
check(row(panel, 8).left == "Lowest 98765c" and row(panel, 9).left:find("Seen %d", 1) == 1 and row(panel, 10).left:find("Cut 4938c", 1, true) == 1,
    "and small under the advice: the price it comes from, when it was seen, the house's cut and the deposit: " .. tostring(row(panel, 9).left))
local itemInfo = C_Item.GetItemInfo
C_Item.GetItemInfo = function(id) if id == 2589 then return "Linen Cloth", nil, nil, nil, nil, nil, nil, 20 end end
check(ns.Gold.PostAt({ current = 90, vendor = 100, item = 2589 }) == 106 and ns.Gold.PostAt({ current = 500, vendor = 0, item = 2589 }) == 499
    and ns.Gold.PostAt({ vendor = 100 }) == nil,
    "what stacks goes down by a copper, never so low that a sale, after the cut, brings less than a vendor pays; nothing without an offer seen")
check(ns.Gold.PostAt({ current = 500, vendor = 0, item = 19019 }) == 400 and ns.Gold.PostAt({ current = 90, vendor = 100, item = 19019 }) == 200
    and ns.Gold.PostAt({ current = 100, vendor = 0, item = 19019 }) == 100,
    "what does not stack moves by whole silver, and 1s is the least there is")
C_Item.GetItemInfo = itemInfo
-- How its price went (PriceGraph.lua): with Alt, at the end of the section
local function graphRow(on)
    for index = 1, on.model.shown.n do
        if on.model.shown.rows[index].kind == "graph" then return on.model.shown.rows[index], index end
    end
end
local function shownText(on, words)
    for index = 1, on.texts.taken do
        if on.texts[index]:IsShown() and on.texts[index]._text == words then return true end
    end
    return false
end
local graph, graphAt = graphRow(panel)
check(graph and graphAt == 11 and graph.range == "1w" and options.priceRange == "1w", "with Alt the graph ends the Gold section, a week at first")
check(panel:GetWidth() >= ns.Graph.WIDE and panel.strokes.taken == 0 and shownText(panel, "One price seen in this range"),
    "room for it; one price draws no line, and says so")
local home, serverNow = Prices.House("player"), GetServerTime()
local serverDay = math.floor(serverNow / 86400)
home.days[serverDay - 5], home.days[serverDay - 3] = "19019=90000,95000,1,1,1;", "19019=120000,130000,1,1,1;"
home.days[serverDay - 20] = "19019=50000,60000,1,1,1;"
Prices.Changed()
W.Wait(0)
check(graphRow(panel).stamp == Prices:Stamp() and panel.strokes.taken == 3,
    "a scan kept: the shown graph is drawn anew: two strokes of the lowest price, one of the market's (what the game lists has none)")
for index = 1, panel.strokes.taken do
    local stroke = panel.strokes[index]
    check(stroke:IsShown(), "(a line is shown)")
end
check(shownText(panel, "130000c") and shownText(panel, "90000c") and shownText(panel, "Lowest") and shownText(panel, "Market")
    and shownText(panel, "Ctrl: next range"), "the highest and lowest price of the range, what the lines are, and the key")
for _, word in ipairs({ "24h", "1w", "2w", "1m", "All" }) do check(shownText(panel, word), "a button: " .. word) end
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 0)
check(options.priceRange == "1w", "Ctrl let go changes nothing")
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(options.priceRange == "2w" and graphRow(panel).range == "2w", "Ctrl goes on to the next range, at once, and it is kept")
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 0)
W.Fire("MODIFIER_STATE_CHANGED", "RCTRL", 1)
W.Fire("MODIFIER_STATE_CHANGED", "RCTRL", 0)
check(options.priceRange == "1m" and panel.strokes.taken == 5, "the other Ctrl too; a longer range reaches further back")
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(options.priceRange == "All" and panel.strokes.taken == 5, "All: from the first price kept")
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(options.priceRange == "24h" and panel.strokes.taken == 0 and shownText(panel, "One price seen in this range"), "after All the first again")
Core.Set("Tooltips", "priceRange", "1w")
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(options.priceRange == "1w", "(another key changes nothing)")
check(panel.hits == nil, "the mouse cannot get to a tooltip that goes when it leaves: nothing there takes a click")
pinned:SetOwner(UIParent, "ANCHOR_PRESERVE")
pinned:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
local stays = ns.Panel.All()[pinned]
check(stays.hits and stays.hits[5]:IsShown() and #stays.hits == 5, "the chat link's tooltip stays: its buttons take the mouse")
stays.hits[3]._scripts.OnClick(stays.hits[3])
check(options.priceRange == "2w" and graphRow(stays).range == "2w" and graphRow(panel).range == "2w", "a click on one: every graph on show follows")
Core.Set("Tooltips", "priceRange", "1w")
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
pinned:Hide()
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
check(graphRow(panel) == nil and panel.graphRow == nil and panel.strokes.taken == 0, "Alt let go, the graph is gone")
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(options.priceRange == "1w", "and Ctrl does nothing to it")
options.show = "shift"
W.alt = true
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(options.priceRange == "1w", "nor while tooltips may not be seen")
options.show = "always"
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
home.days[serverDay - 5], home.days[serverDay - 3], home.days[serverDay - 20] = nil, nil, nil
Prices.Changed()
W.Wait(0)
-- When to buy and sell: what the scans learned of an item, with the house's cut and the post counted (Kinds/Gold.lua)
do
    local Rhythm, key = Core.Data.Rhythm, "19019"
    local function Stretch(at) return math.floor(date("*t", at).hour / 3) end
    local dear, cheap = Stretch(serverNow + 9 * 3600), Stretch(serverNow + 6 * 3600)
    local function Scans(days, watched, sold)
        local line
        for step = days * 8, 1, -1 do
            local at = serverNow - step * 3 * 3600
            local part = Stretch(at)
            line = Rhythm.Seen(line, at, part == dear and 2000 or part == cheap and 500 or 1000)
        end
        home.rhythm[key] = sold and Rhythm.Sold(line, serverNow, sold, sold * 1500) or line
        home.watched, home.watchedAt = watched, serverNow
        Prices.Changed()
    end
    local function Find(words)
        for index = 1, count(panel) do
            if tostring(row(panel, index).left):find(words) then return row(panel, index) end
        end
    end
    local function Fill(price, units, auctions)
        Prices.Take(home, key, serverNow, price, price, units or 10, auctions or 10, 1)
        Prices.Changed()
        tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
    end
    local buying = { getterName = "GetHyperlink", getterArgs = { "item:19019", nil, nil, true, n = 4 } }

    Scans(21, 7 * 86400, 70)
    tip.info = buying
    Prices.Offers(home, { [key] = { 900 * Prices.UNITS + 3, 1000 * Prices.UNITS + 2, 99999 * Prices.UNITS + 1 } })
    Fill(1000)
    local outlook = Prices:Outlook(19019)
    local worth = math.floor((math.floor((outlook.high - 1) * 0.95) - 100) / 1.1)
    check(outlook.highAt and outlook.high > 1500 and worth > 1000, "(the scans learned that one stretch is dear)")
    local advice = Find("^Buy if under")
    check(advice and advice.left == "Buy if under " .. worth .. "c" and advice.right == "now 1000c" and advice.lg == COLOR.DONE[2],
        "the most worth paying: what it fetches in its dear stretch, less the cut, the post and a margin, green while it costs less")
    local plan = Find("^Sell ")
    check(plan and plan.left:find(("%%d%%d:00%%-%%d%%d:00 for %dc$"):format(math.floor(outlook.high + 0.5))) and plan.lg == COLOR.DONE[2],
        "under it, when to sell and for how much: " .. tostring(plan and plan.left))
    check(plan.right == ("+%dc each"):format(math.floor(math.floor(outlook.high * 0.95) - 100 - 1000 + 0.5)), "and what one brings, all costs counted: " .. tostring(plan.right))
    check(Find("^5 on offer under " .. worth .. "c"), "and how many cost less than that, by the last scan")
    Fill(1800)
    advice = Find("^Buy if under")
    check(advice.lr == COLOR.RED[1] and not Find("^Sell ") and not Find("on offer under"), "too dear now: red, with no plan to sell")
    local wait = Find("^Buy %a+ %d%d:00%-%d%d:00 for %d+c$")
    check(wait and outlook.low < 800, "and when it will be cheap enough: " .. tostring(wait and wait.left))
    tip.info = nil
    Fill(1100)
    advice = Find("^Sell ")
    check(advice and advice.left:find("%d%d:00 for ") and advice.right:find("^%+%d+c more$") and advice.font == "row",
        "yours to sell, and a dear stretch ahead: the advice is to sell then, and what that brings more: " .. tostring(advice and advice.left))
    Fill(2000)
    check(Find("^Sell on the AH for 2000c"), "at the top already: sell now")
    tip.info = buying
    W.alt = true
    Fill(1000)
    check(Find("^Usually %d+c") and Find("^Dearest ") and Find("^Cheapest ") and Find("^Sells 10 a day at about 1500c"),
        "with Alt what the forecast stands on: what it usually costs, its dearest and cheapest time, what sells of it")
    tip.info = nil
    Fill(1000)
    check(Find("^Worth buying under " .. worth .. "c"), "and, away from the auction house's lists, what it is worth buying at")
    tip.info = buying
    W.alt = false

    Scans(21, 7 * 86400)
    Fill(1000)
    check(Find("^Buy if under").left == "Buy if under 950c" and not Find("^Sell "), "watched for days and nothing sold: not worth buying to sell on")
    W.alt = true
    Fill(1000)
    check(Find("^No sales seen"), "and it says so")
    W.alt = false

    Scans(1, 86400, 5)
    W.alt = true
    Fill(1000)
    check(Find("^Too few scans for a forecast yet") and Find("^Buy if under").left == "Buy if under 950c", "a day of scans is too little to say anything")
    W.alt, tip.info = false, nil

    -- The post, as much as others put in one auction: at the least 1s for an auction, at the least the deposit for one
    home.rhythm[key] = nil
    Fill(150, 1, 1)
    check(Find("^Sell to a vendor"), "cheap, one by one: a sale at the auction house leaves less than a vendor pays, the post counted")
    Fill(150, 200, 10)
    check(Find("^Sell on the AH for 150c"), "the same price in lots of twenty: the post is shared, and the auction house brings more")

    -- The neutral house: buy here and sell there, sell there, buy there; each by its fees
    local side = UnitFactionGroup
    UnitFactionGroup = function(unit) if unit == "npc" then return "Neutral" end return side(unit) end
    local neutral = Prices.House("npc")
    UnitFactionGroup = side
    local function There(usual, low)
        local line
        for step = 21 * 8, 1, -1 do line = Rhythm.Seen(line, serverNow - step * 3 * 3600, usual) end
        neutral.rhythm[key] = Rhythm.Sold(line, serverNow, 70, 70 * usual)
        neutral.watched, neutral.watchedAt = 7 * 86400, serverNow
        Prices.Take(neutral, key, serverNow, low, usual, 10, 10, 1)
    end
    local function Steady(usual, sold)
        local line
        for step = 21 * 8, 1, -1 do line = Rhythm.Seen(line, serverNow - step * 3 * 3600, usual) end
        home.rhythm[key] = sold and Rhythm.Sold(line, serverNow, sold * 7, sold * 7 * usual) or line
        home.watched, home.watchedAt = 7 * 86400, serverNow
    end
    Steady(1000, 10)
    There(5000, 4800)
    Prices.Offers(home, { [key] = { 1000 * Prices.UNITS + 3 } })
    Fill(1000)
    local route = Prices:Route(19019, 81)
    check(route and route.sale == math.floor(4999 * 0.85) - 100, "(a sale there, by its fees: its cut of 15%, a post of 1s)")
    local away = Find("^Sell at the neutral AH for 5000c")
    check(away and away.right:find("^%+%d+c more$") and away.lg == COLOR.DONE[2], "yours to sell, and the neutral house pays clearly more: the advice is to take it there")
    tip.info = buying
    Fill(1000)
    local most = math.floor(route.sale / 1.25)
    advice = Find("^Buy if under")
    check(advice and advice.left == "Buy if under " .. most .. "c" and advice.lg == COLOR.DONE[2], "on the house's list: worth what it brings there, a quarter left on top")
    plan = Find("^Sell at the neutral AH for 5000c")
    check(plan and plan.right == ("+%dc each"):format(route.sale - 1000), "and where to sell it, and what one brings after all of it")
    check(Find("^3 on offer under"), "and how many cost less")
    Steady(5000, 10)
    There(5000, 1000)
    W.alt = true
    Fill(4000)
    check(Find("^Buy at the neutral AH for 1000c"), "too dear here, and far cheaper there: buy it there")
    check(Find("^At the neutral AH: 1000c, usually 5000c"), "with Alt what the other house asks")
    W.alt, tip.info = false, nil
    Steady(1000, 10)
    There(1050, 1000)
    Fill(1000)
    check(not Find("neutral AH"), "about the same there, after its fees: no trip")
    neutral.rhythm[key], neutral.watched, neutral.watchedAt = nil, nil, nil
    Prices.Take(neutral, key, serverNow, 0, 0, 0, 0, 0)

    home.watched, home.watchedAt = nil, nil
    Prices.Offers(home, {})
    Prices.See(key)
    Prices.Changed()
end
browse = { { itemKey = { itemID = 19019, itemLevel = 60 }, minPrice = 500 }, { itemKey = { itemID = 19019, itemLevel = 70 }, minPrice = 900 } }
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
check(Prices:Low(19019) == 500, "an item listed in several rows (its kinds) has the lowest of them as its price")
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", { { itemKey = { itemID = 19019 }, minPrice = 700 } })
check(Prices:Low(19019) == 500, "also when more rows of the same list come")
Prices.See("19019", 98765)
hatchet[2].data.bonding = 6
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(count(panel) == 4 and row(panel, 4).left == "Vendor", "a thing that is bound when picked up has no auction price")
Prices.See("19019")
C_Item.GetItemInfoInstant = function(id) if id == 2589 then return id, "Trade Goods", "Cloth", "", 1, 7, 5 end end
W.items[2589] = { name = "Linen Cloth", quality = 1 }
W.spells[3908] = { name = "Tailoring" }
tip:Fill({ type = TYPE.Item, id = 2589 }, { { "Linen Cloth" }, { " ", nil, nil, nil, LINE.SellPrice, price = 13 } })
check(row(panel, 2).left == "Trade Goods \194\183 Cloth" and row(panel, 2).font == "detail", "a thing that is not worn says what it is")
check(row(panel, 3).kind == "caption" and row(panel, 3).left == "Professions" and row(panel, 4).left == "Used in"
    and row(panel, 4).right == "|T4908:0|t Tailoring" and row(panel, 5).left == "Gold" and row(panel, 6).left == "Vendor",
    "a trade good: under the caption Professions, the professions that use it, with their icons")
local named, before, after = panel.left[3], false, false
local nameLeft = named._points[1][4]
for index = 1, panel.lines.taken do
    local line = panel.lines[index]
    local x = line._points[1] and line._points[1][4]
    if x == 12 and math.abs(x + line._width - (nameLeft - 6)) < 1e-9 then before = true end -- up to the name, a gap before it
    if x and math.abs(x - (nameLeft + named._width + 6)) < 1e-9 and math.abs(x + line._width - (panel:GetWidth() - 12)) < 1e-9 then
        after = true
    end
end
check(named._justify == "CENTER" and math.abs(nameLeft + named._width / 2 - panel:GetWidth() / 2) <= 1 and before and after,
    "a section's name stands in the middle, and a rule runs from each side of the panel to it, a gap before the name")
-- A rule's light line is one hairline high: one unit of the interface, to whole dots of the screen.
local function hairline()
    local least
    for index = 1, panel.lines.taken do
        local height = panel.lines[index]._height
        if height > 0 and (not least or height < least) then least = height end
    end
    return least
end
check(hairline() == 1, "a hairline is one unit of the interface, where that is one dot of the screen")
pixel = 768 / 2160 -- a 4K screen at the interface's scale 1
panel.drawn = false -- (the same lines: drawn again only for the new screen)
tip:Fill({ type = TYPE.Item, id = 2589 }, { { "Linen Cloth" }, { " ", nil, nil, nil, LINE.SellPrice, price = 13 } })
check(math.abs(hairline() - 3 * pixel) < 1e-9, "and the nearest whole dots elsewhere: three on a 4K screen")
pixel = 1
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Plate", nil, { 0.64, 0.21, 0.93 } }, { "115 Armor" } })
check(row(panel, 2).left == "Info" and row(panel, 3).font == "big" and row(panel, 3).left == "115 Arm", "an armour's number is large too, in Info")
options.icons = false
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { "Epic" } })
check(head(panel).icon == nil and head(panel).accent, "the icons can be switched off")
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(row(panel, 1).right == "iLvl 63", "then its level stands right of its name: there is no plaque to hold it")
options.icons = true

-- A player ---------------------------------------------------------------------------------
auras.mouseover = { HELPFUL = { { icon = 11 }, { icon = 12 } }, HARMFUL = { { icon = 13 } } }
local jaina = { { "Jaina", nil, { 0.5, 0.5, 1 } }, { "Dawnbreakers" }, { "Level 60 Human Mage (Player)" }, { "Alliance" }, { "Player vs. Player" },
    { "Item Level 61", nil, nil, nil, 0, added = true } }
PVP = "Player vs. Player" -- the game's word for it
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 1).left == "Jaina" and row(panel, 1).caps and head(panel).ar == 0.25 and row(panel, 1).lr == 0.25, "a player: the name in capitals, name and panel in the colour of the class")
check(row(panel, 2).left == "<Dawnbreakers>" and row(panel, 2).font == "title" and row(panel, 2).flush,
    "under it the guild, as large as the name and close under it")
local RED_HEX, ASIDE_HEX, AWAY_HEX = code(COLOR.RED), code(COLOR.ASIDE), code(COLOR.AWAY)
local TITLE_HEX, PLAQUE_HEX = code(COLOR.PROSE), code(COLOR.PLAQUE)
check(row(panel, 3).left == "Human  \194\183  Alliance" and row(panel, 4).left == "Mage  \194\183  |cff" .. RED_HEX .. "PvP|r",
    "then the race and the side, and under it the class with what is true now: PvP in red, short")
check(row(panel, 3).font == "detail" and row(panel, 4).font == "detail" and size(panel.texts[5]) == 10, "those in small letters")
check(head(panel).dragon == "elite" and panel.dragon:IsShown(), "a player has the gold dragon round the portrait")
check(head(panel).portrait == "mouseover" and panel.icon.portrait == "mouseover" and head(panel).badge == "60"
    and panel.iconMask._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\portrait-mask",
    "the portrait, round with a soft edge, the level under it")
local level
for index = 1, panel.texts.taken do if panel.texts[index]._text == "60" then level = panel.texts[index] end end
check(level and panel.plaque:IsShown() and panel.plaque._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\plaque" and level:GetTextColor() == 1
    and select(2, level:GetTextColor()) == 1 and level.dressed.flags == "OUTLINE",
    "the level stands on a gold plaque with a soft edge like the panel's, in the colour of how hard the unit is, outlined")
SaneUI.Core.People.Set("Jaina Proudmoore", "alias", "Saneroki")
SaneUI.Core.People.Set("Jaina Proudmoore", "note", "Raids on Fridays")
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 1).left == "Saneroki" and row(panel, 2).left == "<Dawnbreakers>" and row(panel, 3).left == "Jaina Proudmoore"
    and row(panel, 3).font == "sub" and row(panel, 4).left == "Raids on Fridays",
    "a player given an alias (the game's menu of a player): the alias for the name, the name small under the guild, then the note")
SaneUI.Core.People.Set("Jaina Proudmoore", "alias", nil)
SaneUI.Core.People.Set("Jaina Proudmoore", "note", nil)
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 1).left == "Jaina" and row(panel, 3).left == "Human  \194\183  Alliance", "without, as before")
for _, text in ipairs(panel.texts) do -- texts as wide as their letters, so the plaque's width can be seen
    function text:GetUnboundedStringWidth() return #(self._text or "") * 6 end
end
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
local narrow, plaqueLeft = select(4, panel.plaque:GetPoint(2)) - panel:GetWidth(), select(4, panel.plaque:GetPoint(1)) - panel:GetWidth()
check(row(panel, 5).left == "Status" and row(panel, 6).left == "Target" and row(panel, 6).live == "target", "under the caption Status: whom it targets")
check(row(panel, 7).kind == "bar" and row(panel, 7).live == "health", "under that the health bar")
check(row(panel, 8).kind == "bar" and row(panel, 8).live == "power" and row(panel, 8).bb == 1, "and the bar of its mana, in mana's colour")
check(panel.live.health._height == 18 and panel.live.power._height == 5 and panel.live.power._points[1][1] == "BOTTOMLEFT"
    and panel.live.power._points[1][2] == panel.live.health, "the mana lies over the lower part of the health bar, not under it")
check(#inspected == 1 and inspected[1] == "mouseover", "for its item level, the server is asked")
check(row(panel, 9).kind == "auras", "and its buffs")
check(count(panel) == 9, "the tooltip's own lines that say the same are left out; another addon's line is not shown without Alt")
W.alt = true
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(count(panel) == 13 and row(panel, 12).kind == "caption" and row(panel, 12).left == "Addons" and row(panel, 13).left == "Item Level 61"
    and row(panel, 13).font == "small", "with Alt, another addon's line stays, in its own section, last")
W.alt = false
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(#inspected == 1, "while the answer is on its way, the server is not asked again")
UnitGUID = function(unit) return unit == "mouseover" and "Player-1" or "Player-70-0000ABCD" end
-- The talents the inspection brings: three groups, the most points in Fire
Constants = { TraitConsts = { INSPECT_TRAIT_CONFIG_ID = -1 } }
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 70 } } end,
    GetGroupDisplayInfoByTreeID = function()
        return { { groupID = 1, displayName = "Arcane" }, { groupID = 2, displayName = "Fire" }, { groupID = 3, displayName = "Frost" } }
    end,
    GetGroupCurrencyInfo = function(config)
        if config ~= -1 then return {} end
        return { { traitNodeGroupID = 2, currencyInfos = { { spent = 31 } } }, { traitNodeGroupID = 3, currencyInfos = { { spent = 20 } } },
            { traitNodeGroupID = 1, currencyInfos = { { spent = 0 } } } }
    end,
}
local cleared = 0
ClearInspectPlayer = function() cleared = cleared + 1 end
W.Wait(0.5)
NotifyInspect("party1") -- another addon asks for somebody else meanwhile
table.remove(inspected)
W.Fire("INSPECT_READY", "Player-1")
check(cleared == 0, "the answer read, an inspection somebody else asked for since is not let go")
check(row(panel, 4).left == "Fire Mage |cff" .. ASIDE_HEX .. "0/31/20|r  \194\183  |cff" .. RED_HEX .. "PvP|r",
    "with the inspection the talents come too: the spec (the group with the most points) before the class, the points after it")
check(head(panel).badge == "|cff" .. PLAQUE_HEX .. "iLvl 61 -|r 60", "the answer comes: the plaque says the item level before the level at once")
check(select(4, panel.plaque:GetPoint(2)) - panel:GetWidth() == narrow and select(4, panel.plaque:GetPoint(1)) - panel:GetWidth() < plaqueLeft,
    "the plaque keeps its right side and reaches further left")
for _, text in ipairs(panel.texts) do text.GetUnboundedStringWidth = nil end
tip:Hide()
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(head(panel).badge == "|cff" .. PLAQUE_HEX .. "iLvl 61 -|r 60" and #inspected == 1, "and it is kept: the next time it is there at once, without asking")
check(panel.live.health and panel.live.power and panel.live.targetName:GetText() == "Ragnaros" and panel.live.healthText,
    "health, power and target are filled in")
check(panel.live.targetName._points[1][4] == 12 + (#"Target" * 6 + 1) + 6 and panel.live.targetName._justify == "LEFT",
    "the target's name right after the word Target (drawn while letters measured 6 each), not at the far side")
check(panel.live.healthText:GetParent():GetParent() == panel.live.health and panel.live.healthText._points[1][1] == "LEFT" and panel.live.healthText._points[1][5] == 0,
    "the health's numbers are written in the middle of its bar, on a layer of its own over the power bar")
check(panel.barMask._points[1][5] == select(5, panel.live.health:GetPoint(1)) and #panel.barMask._points == 2,
    "the two bars are one block with round corners")
panel.live.healthText.SetFormattedText = function(self, format, ...) self._text = format:format(...) end
-- A shown panel asks the unit nothing on its own: it listens for the unit's events (which the game sends for that unit
-- alone) and answers them on its next frame, however many came
do
    local asked, health = 0, UnitHealth
    UnitHealth = function(unit) asked = asked + 1 return health(unit) end
    for _ = 1, 10 do tick(panel, 0.2) end
    check(asked == 0 and panel.live.healthText._text ~= "40   83%", "a shown panel does not ask for the unit's health again and again")
    W.Fire("UNIT_HEALTH", "target")
    tick(panel)
    check(asked == 0, "another unit's event is not heard")
    W.Fire("UNIT_HEALTH", "mouseover")
    W.Fire("UNIT_HEALTH", "mouseover")
    tick(panel)
    check(asked == 1 and panel.live.healthText._text == "40   83%",
        "its health changed (twice in one frame: one look): the health anew, its current health and its share in percent")
    UnitHealth = health
end
-- In a fight the game hides the unit's health: a secret value, which nothing may compute with. The bar is given it
-- as it is; a client that leaves the share to us (no UnitHealthPercent) gets no share from a hidden number
-- (Core.Plain), and the panel stands and listens on
do
    local secret, scale, said = W.Secret(), CurveConstants.ScaleTo100, #W.printed
    local health, bar = UnitHealth, panel.live.health
    UnitHealth, CurveConstants.ScaleTo100 = function() return secret end, nil
    bar.SetValue = function(self, value) self._value = value end
    W.Fire("UNIT_HEALTH", "mouseover")
    tick(panel)
    local hidden = issecretvalue(bar._value) and panel.live.healthText._text == "" and #W.printed == said and not Core.errors["Tooltips: live values"]
    UnitHealth, CurveConstants.ScaleTo100, bar.SetValue = health, scale, nil
    W.Fire("UNIT_HEALTH", "mouseover")
    tick(panel)
    check(hidden and panel.live.healthText._text == "40   83%",
        "a hidden health: the bar takes it as it is, the text shows no share worked out from it, nothing fails; plain again, its share again")
end
world.mouseovertarget = { player = true, name = "Varian", surname = "Wrynn", level = 60, class = { "Mage", "MAGE" } }
W.Fire("UNIT_TARGET", "mouseover")
tick(panel)
check(panel.live.targetName:GetText() == "Varian Wrynn", "a player as the target by the whole name: first name and surname")
local isUnit = UnitIsUnit
UnitIsUnit = function(a, b) return (a == "mouseovertarget" and b == "player") or a == b end
W.Fire("UNIT_TARGET", "mouseover")
tick(panel)
check(panel.live.targetName:GetText() == "You" and panel.live.targetName:GetTextColor() == COLOR.RED[1]
    and select(2, panel.live.targetName:GetTextColor()) == COLOR.RED[2], "you as its target: the word for you, in the game's red")
UnitIsUnit = isUnit
world.mouseovertarget = { name = "Ragnaros", level = 63 }
W.Fire("UNIT_TARGET", "mouseover")
tick(panel)
-- The mouse has left the player: the game lets the tooltip fade out, and "mouseover" is somebody else
local guidOf = UnitGUID
UnitGUID = function(unit) return unit == "mouseover" and "Player-2" or guidOf(unit) end
UnitHealth = function() return 7 end
world.mouseover.target = false
W.Fire("UNIT_HEALTH", "mouseover")
W.Fire("UNIT_TARGET", "mouseover")
tick(panel)
check(panel.live.healthText._text == "40   83%" and count(panel) == 9 and row(panel, 6).live == "target",
    "once the mouse has left the unit, its panel stands still: no other unit's numbers, no row taken away")
UnitGUID, UnitHealth = guidOf, function() return 40 end
world.mouseover.target = true
-- The whole interface hidden (Alt-Z) and shown again: the panel, a child of UIParent, is unseen and seen again with
-- it, and the game runs its OnHide and OnShow for that too. So it stops listening for its unit meanwhile, and
-- listens again, its numbers read anew, once the interface is back
UIParent:Hide()
UnitHealth = function() return 25 end
W.Fire("UNIT_HEALTH", "mouseover")
local unseen = panel:IsShown() and not panel:IsVisible() and panel.liveUnit == nil and not panel.heard
UIParent:Show()
check(unseen and panel:IsVisible() and panel.liveUnit == "mouseover" and panel.live.healthText._text == "25   83%",
    "the interface hidden (Alt-Z): the panel is unseen with it and stops listening for its unit; shown again with it, it listens again, its health read anew at once")
UnitHealth = function() return 40 end
W.Fire("UNIT_HEALTH", "mouseover")
tick(panel)
-- A text or a bar that was given a number the game hides answers every question about its size
-- with a hidden number, for good. They must never be measured, nor used again for another line.
local hidden = { panel.live.healthText, panel.live.targetName }
for _, label in ipairs(hidden) do
    for _, question in ipairs({ "GetStringWidth", "GetUnboundedStringWidth", "GetStringHeight" }) do
        label[question] = function() error("a text that may hold a hidden number was asked for its size") end
    end
    for index = 1, #panel.texts do check(panel.texts[index] ~= label, "a text for a unit's numbers is not one of the texts that are measured") end
end
for use, bar in pairs(panel.liveBars) do
    if use ~= "health" and use ~= "power" then
        check(bar ~= panel.live.health and bar ~= panel.live.power, "a unit's bars are not the bars used for other things (an item's durability)")
    end
end
check(#panel.auraIcons == 3 and panel.auraIcons[1]._texture == 11 and panel.auraIcons[3]._texture == 13 and panel.auraIcons[3]:IsShown(), "its buffs, then its debuffs, as small icons")
check(panel.auraIcons[1].mask._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\aura-mask", "each with a soft edge")
do -- All of them, however many, in as many lines as they take; no Alt.
    local few, step = panel.live.aurasLines, ns.Panel.AURA + ns.Panel.AURA_GAP
    local three = auras.mouseover
    local many = { HELPFUL = {}, HARMFUL = {} }
    for index = 1, 30 do many.HELPFUL[index] = { icon = 100 + index } end
    for index = 1, 12 do many.HARMFUL[index] = { icon = 200 + index } end
    auras.mouseover = many
    W.Fire("UNIT_AURA", "mouseover", {})
    tick(panel)
    local shown = 0
    for _, icon in ipairs(panel.auraIcons) do shown = shown + (icon:IsShown() and 1 or 0) end
    check(shown == 42 and panel.auraIcons[42]._texture == 212, "every buff and debuff, the most the game keeps too")
    check(few == 1 and panel.live.aurasLines > 1, "going on in new lines")
    local tops, lastRight = {}, 0
    for _, icon in ipairs(panel.auraIcons) do
        local _, _, _, x, y = icon:GetPoint(1)
        tops[y] = true
        lastRight = math.max(lastRight, x + ns.Panel.AURA - panel.live.aurasLeft)
    end
    local lines = 0
    for _ in pairs(tops) do lines = lines + 1 end
    check(lines == panel.live.aurasLines and lastRight <= panel.live.aurasWidth, "and within the panel's width")
    local after = panel.live.aurasTop + panel.live.aurasLines * step
    check(after > panel.live.aurasTop + step, "the rows after them make room")
    auras.mouseover = three
    W.Fire("UNIT_AURA", "mouseover", {})
    tick(panel)
    check(panel.live.aurasLines == 1 and not panel.auraIcons[4]:IsShown(), "and back to one line")
end
world.mouseover.target = false
W.Fire("UNIT_TARGET", "mouseover")
tick(panel)
check(count(panel) == 8 and row(panel, 8).kind == "auras", "when it lets go of its target, the row for it goes")
W.Combat(true)
tick(panel)
check(count(panel) == 7 and not panel.auraIcons[1]:IsShown(), "a fight begins: a unit's buffs cannot be asked for in one, so no row for them")
-- Filled again in the fight, as the game refreshes a unit's tooltip: the panel is drawn, placed and shown as always.
-- No part of it is a protected frame (the game blocks those in a fight, and so does the stand-in)
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(panel:IsShown() and not panel:IsProtected() and not panel.front:IsProtected() and count(panel) == 7,
    "filled again in the fight: the panel is drawn and placed as always, no part of it protected")
W.Combat(false)
tick(panel)
check(count(panel) == 8 and row(panel, 8).kind == "auras" and panel.auraIcons[1]:IsShown(), "the fight over, the row for its buffs is back")
world.mouseover.target = true
options.classColors = false
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(head(panel).ar == 0.5 and row(panel, 1).lb == 1, "with class colours switched off a player has the colour the game gave the name")
world.mouseover.afk = true
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 4).left == "Fire Mage |cff" .. ASIDE_HEX .. "0/31/20|r  \194\183  |cff" .. RED_HEX .. "PvP|r  \194\183  |cff" .. AWAY_HEX .. "AFK|r",
    "a player who is away says so on the class line")
world.mouseover.offline = true
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(head(panel).ar == COLOR.NEUTRAL[1] and head(panel).ab == COLOR.NEUTRAL[3] and row(panel, 4).left:find("Offline"), "an offline player's panel has no colour of its own")
world.mouseover.offline = nil
world.mouseover.afk = nil
world.mouseover.title, world.mouseover.guildRank = "Sergeant", "Officer"
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 4).left == "Fire Mage |cff" .. ASIDE_HEX .. "0/31/20|r  \194\183  |cff" .. TITLE_HEX .. "Sergeant|r  \194\183  |cff" .. RED_HEX .. "PvP|r",
    "a player's title (a PvP rank) on the class line")
check(row(panel, 2).label == "Officer" and row(panel, 2).labelFont == "detail", "the player's rank in the guild, small, after the guild")
-- Retail's spec comes without talent points (Core.Inspect gives none there)
local talents = ns.Inspect.Talents
ns.Inspect.Talents = function() return "Guardian", nil end
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
check(row(panel, 4).left == "Guardian Mage  \194\183  |cff" .. TITLE_HEX .. "Sergeant|r  \194\183  |cff" .. RED_HEX .. "PvP|r",
    "a spec without points (Retail's): the spec before the class, nothing after them")
ns.Inspect.Talents = talents
world.mouseover.title, world.mouseover.guildRank = nil, nil
options.classColors = true

-- A creature
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" },
    { "The Kobold Menace", nil, GOLD, nil, LINE.QuestTitle }, { " - Kobold slain: 4/10", nil, nil, nil, LINE.QuestObjective },
    { " - Candle: 1/4", nil, nil, nil, LINE.QuestObjective }, { " - Old thing: 2/2", nil, nil, nil, LINE.QuestObjective, data = { completed = true } },
    { "Boars and Cats", nil, GOLD, nil, LINE.QuestTitle }, { "7/7 Kobold slain", nil, nil, nil, LINE.QuestObjective },
    { "Rival", nil, nil, nil, LINE.QuestPlayer }, { "Kobold slain: 3/5", nil, nil, nil, LINE.QuestObjective },
    { "Long Done", nil, GOLD, nil, LINE.QuestTitle }, { "Candle: 4/4", nil, nil, nil, LINE.QuestObjective } })
check(head(panel).unit == "target" and head(panel).ar == 1 and head(panel).ag == 0.1 and row(panel, 2).left == "Humanoid" and head(panel).badge == "5",
    "a creature: the colour the game gave its name, what it is, its level")
check(head(panel).dragon == "elite" and not head(panel).power, "an elite one has a dragon on the corner; no bar without power")
check(panel.dragon:IsShown() and panel.dragon._texture == "Interface\\HUD\\UIUnitFrameBoss2x" and panel.dragon._points[1][2] == panel.icon
    and panel.dragon._points[1][3] == "CENTER" and math.floor(panel.dragon._width) == 84,
    "the game's own gold dragon for an elite (from its target frame) lies round the portrait")
check(panel.icon._width == 64 and panel.icon._points[1][1] == "TOPLEFT" and panel.icon._points[1][4] == panel:GetWidth() + 10 - 64
    and panel.icon._points[1][5] == 10,
    "the portrait is large and stands out over the corner, where the dragon covers its edge")
check(row(panel, 3).left == "|cffFFD100Elite|r", "under what it is, its rank in the colour of its dragon")
check(row(panel, 4).left == "Status" and row(panel, 5).kind == "bar" and row(panel, 5).live == "health",
    "under Status its health, and no row for a target or buffs it has not")
check(row(panel, 6).kind == "caption" and row(panel, 6).left == "Quest" and row(panel, 7).left == "The Kobold Menace" and row(panel, 7).lg == 0.82,
    "a section of its own for your quests, under the caption Quest: the quest's name in gold")
check(row(panel, 8).icon == "kill" and row(panel, 8).left == "Kobold slain" and row(panel, 8).right == "4/10"
    and row(panel, 9).icon == "loot" and row(panel, 9).left == "Candle" and row(panel, 9).right == "1/4",
    "a sword before what you must kill it for, a sack before what you must loot, the count at the right")
check(row(panel, 10).left == "Boars and Cats" and row(panel, 11).left == "Rival" and row(panel, 12).left == "Kobold slain" and row(panel, 12).right == "3/5",
    "what is done is left out (the game says so, or its count is full); what is still to do stays")
check(count(panel) == 12, "and a quest with nothing left to do here is left out, its name too")
world.player.level = 4
world.target.class = { "Mage", "MAGE" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 6).left == "137 XP" and row(panel, 6).right == "Next level in 7" and row(panel, 6).font == "sub",
    "what killing it gives you (one level above you, elite: twice) and how many such kills to your next level")
-- Retail gives experience by other rules (its creatures' levels follow yours): no row for it there
W.Play("retail")
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
local experience = false
for index = 1, count(panel) do experience = experience or row(panel, index).left == "137 XP" end
check(not experience and ns.Numbers.Experience("target") == nil and row(panel, 3).left == "Mage  \194\183  |cffFFD100Elite|r",
    "in Retail a creature's panel has no experience row; the rest as in Forever")
W.Play("forever")
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 6).left == "137 XP", "back in Forever: the row again")
-- The rule's rows: at level 45 a creature fades to nothing 14 levels below you and is grey from 10 below
world.player.level, world.target.level = 45, 36
local gain, kills = ns.Numbers.Experience("target")
check(gain == 193 and kills == 5, "nine levels below you: (45 * 5 + 45) * (1 - 9/14), twice for an elite")
world.target.level = 35
check(ns.Numbers.Experience("target") == nil, "ten levels below you at 45: grey, nothing")
world.target.level, world.player.level = 50, 45
check(ns.Numbers.Experience("target") == math.floor(270 * 1.2 * 2 + 0.5), "above you: 5 % more a level, for four levels at most")
world.player.level, world.target.level = 4, 5
check(row(panel, 2).left == "Humanoid" and row(panel, 3).left == "Mage  \194\183  |cffFFD100Elite|r",
    "a creature that is more than a plain fighter says its class, before its rank")
world.target.dead = true
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 3).left == "Mage  \194\183  |cffFFD100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Dead|r" and row(panel, 6).left ~= "137 XP",
    "a dead one says so, and gives nothing any more")
world.target.dead = nil
world.target.family, world.target.tapped = "Wolf", true
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "<Tunnel Boss>" }, { "Level 5 Humanoid (Elite)" } })
check(row(panel, 2).left == "<Tunnel Boss>" and row(panel, 2).font == "title" and row(panel, 2).flush and row(panel, 3).left == "Humanoid  \194\183  Wolf",
    "a creature's title as large as its name, close under it; what it is and its family")
check(row(panel, 4).left == "Mage  \194\183  |cffFFD100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Tapped|r", "one somebody else has tapped says so")
world.target.family, world.target.tapped = nil, nil
world.target.class = { "Warrior", "WARRIOR" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Bowyer" }, { "Level 5 Humanoid (Elite)" },
    { "Stormwind" }, { "Skinnable" } })
check(row(panel, 2).left == "Bowyer" and row(panel, 2).font == "title" and row(panel, 3).left == "Humanoid  \194\183  Stormwind"
    and row(panel, 4).left == "Warrior  \194\183  |cffFFD100Elite|r  \194\183  |cffFFFFFFSkinnable|r",
    "an NPC's title is the line before its level line, its faction the one after it; a hostile creature says its class")
world.target.reaction = 5
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Bowyer" }, { "Level 5 Humanoid (Elite)" } })
check(row(panel, 4).left == "|cffFFD100Elite|r", "a friendly one does not")
world.target.reaction = nil
-- Core's quest data (the sample, dev/tests/data/tooltips): quest 60 asks for a candle (item 772, its second
-- objective) that this creature (NPC 1) drops 33% of the time; it takes quest 61 back and gives 62, 63, 64 and 70
quests[60] = { on = true, title = "The Kobold Menace",
    objectives = { { text = "4/10 Kobold Vermin slain", finished = false }, { text = "Candle: 1/4", finished = false } } }
quests[61] = { on = true, ready = true, title = "Report to Gryan" }
local askedLog = 0 -- how often the quest log was asked for a quest's objectives
C_QuestLog.GetQuestObjectives = function(id) askedLog = askedLog + 1 return quests[id] and quests[id].objectives end
C_QuestLog.GetTitleForQuestID = function(id) return quests[id] and quests[id].title end
units["Creature-0-1-2-3-1-4"] = "target"
local kobold = { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" },
    { "The Kobold Menace", nil, GOLD, nil, LINE.QuestTitle, data = { id = 60 } }, { "4/10 Kobold Vermin slain", nil, nil, nil, LINE.QuestObjective },
    { "Not ours", added = true } }
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, kobold)
W.Fire("LOADING_SCREEN_DISABLED")
Steps()
check(row(panel, 6).left == "137 XP" and row(panel, 5).live == "health" and row(panel, 7).kind == "caption" and row(panel, 7).left == "Quest"
    and row(panel, 8).left == "The Kobold Menace",
    "a creature with Core's quest data: experience (in Status, under its health), then the quests under the caption Quest")
check(row(panel, 8).right == "Level 2" and row(panel, 8).rr == 1 and row(panel, 8).rb == 0,
    "a quest's name has its level at the right (the game's line says which quest it is), in the colour of how hard it is")
check(row(panel, 9).icon == "kill" and row(panel, 9).left == "Kobold Vermin slain" and row(panel, 9).right == "4/10",
    "the game's objective: a sword before what to kill (it names the creature), the count at the right")
check(row(panel, 10).icon == "loot" and row(panel, 10).left == "Candle" and row(panel, 10).right == "1/4",
    "from Core's data: what it drops for the same quest, under it, with a sack")
check(row(panel, 10).label == "33%" and row(panel, 9).label == nil, "with how often it drops after its name; nothing after what to kill")
check(panel.after[10] and panel.after[10]._text == "33%" and panel.after[10]:IsShown() and panel.right[10]._text == "1/4",
    "the panel writes the chance after the name, and the count still at the right")
check(row(panel, 11).left == "Report to Gryan" and row(panel, 11).lg == 0.82 and row(panel, 11).right == "Level 3" and row(panel, 12).icon == "active"
    and row(panel, 12).left == "Turn in" and row(panel, 12).lr == COLOR.DONE[1] and row(panel, 12).right == "",
    "a quest of yours it takes back: its name like a quest's with its level, under it Turn in (ready, in green)")
check(row(panel, 13).left == "Wanted: Hogger" and row(panel, 13).right == "Level 11" and row(panel, 14).icon == "available" and row(panel, 14).left == "Offers",
    "a quest it offers you, the same way; not one too far above your level, nor one whose first quest you have not done, "
    .. "nor one it gives the other side only")
check(count(panel) == 14, "another addon's line is not shown without Alt")
W.alt = true
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, kobold)
check(count(panel) == 18 and row(panel, 17).kind == "caption" and row(panel, 17).left == "Addons" and row(panel, 18).left == "Not ours",
    "with Alt it stays, after the section and the details, in a section of its own")
W.alt = false
askedLog = 0
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(askedLog == 0 and count(panel) == 13, "read again (as a unit frame's tooltip is, many times a second), the quest log is not asked again")
quests[61].ready = false
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(askedLog == 1 and row(panel, 11).left == "In progress", "once the quest log changes, it is")
-- The game's own line for what the database knows it drops: the chance too, and a sack even where
-- the words name the creature
quests[60].objectives[2].text = "Kobold Candle: 1/4"
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" },
    { "The Kobold Menace", nil, GOLD, nil, LINE.QuestTitle }, { " - Kobold Candle: 1/4", nil, nil, nil, LINE.QuestObjective } })
check(row(panel, 9).icon == "loot" and row(panel, 9).left == "Kobold Candle" and row(panel, 9).label == "33%"
    and row(panel, 10).left == "Report to Gryan", "the game's own line for a drop gets its chance and a sack, and is not there twice")
quests[60].objectives[2].text = "Candle: 1/4"
quests[61].ready = true
-- What the game shows grey for your level an NPC does not offer (here grey: more than 2 below you).
-- NPC 3 gives quest 66, of level 1, and quest 62.
local function gives(npc, quest)
    local list = ns.Quests.Of(npc)
    for index = 1, list.n do
        if list[index].kind == "give" and list[index].quest == quest then return true end
    end
    return false
end
UnitQuestTrivialLevelRange = function() return 2 end
W.Fire("QUEST_LOG_UPDATE")
check(not gives(3, 66) and gives(3, 62), "a quest three levels below you is grey to the game (its range: 2): not offered")
UnitQuestTrivialLevelRange = function() return 3 end
W.Fire("QUEST_LOG_UPDATE")
check(gives(3, 66), "with a wider range it is")
UnitQuestTrivialLevelRange = nil
-- How often, below 1 % (NPC 2 drops the candle that rarely)
check(ns.Quests.Of(2).n == 1 and ns.Quests.Of(2)[1].kind == "drop" and ns.Quests.Of(2)[1].extra == "<1", "a chance below 1 % is shown as <1")
check(ns.Quests.Of(999).n == 0 and ns.Quests.Item(999).n == 0, "a creature or an item Core's data does not know has no quest list")
local unknown = ns.Quests.Item(999)
for id = 900001, 900400 do ns.Quests.Item(id) end
check(ns.Quests.Item(999) ~= unknown and ns.Quests.Item(999).n == 0,
    "what is kept of the lists has an end: past 400 items they are forgotten together, each made anew when asked")
-- A reader of the data that fails: noted and told once, what was found before it stays
local keys = Data.Set("Quests").Keys
Data.Set("Quests").Keys = function(self, index, value)
    if index == "byStartNPC" then error("broken") end
    return keys(self, index, value)
end
W.Fire("QUEST_LOG_UPDATE")
W.printed = {}
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(panel:IsShown() and count(panel) == 11 and row(panel, 8).left == "The Kobold Menace" and row(panel, 9).left == "Candle"
    and row(panel, 10).left == "Report to Gryan", "a failure in the quest list ends it there: what was found before it stays")
check(Core.errors["Tooltips: quest data"] and #W.printed == 1 and not ns.off, "it is noted and told once")
Data.Set("Quests").Keys = nil -- the handle's own again
W.Fire("QUEST_LOG_UPDATE")
-- A dead creature: the corpse line goes (the class line says Dead), what it yields goes on the class line
world.target.dead, world.target.class = true, { "Kobold", "WARRIOR" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" }, { "Corpse" },
    { "Skinnable", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 3).left == "|cffFFD100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Dead|r  \194\183  |cffFF1A1ASkinnable|r" and count(panel) == 5,
    "a dead creature: Dead and Skinnable (in the game's colour for it) on the class line; no corpse line, no class that is only its name")
check(head(panel).ar == COLOR.NEUTRAL[1] and head(panel).ag == COLOR.NEUTRAL[2] and head(panel).ab == COLOR.NEUTRAL[3], "its panel has no colour of its own")
check(head(panel).portrait == "target" and panel.icon:IsShown() and head(panel).dragon == "elite" and panel.dragon:IsShown(),
    "and it keeps its portrait and its dragon")
-- The game fills a dead creature's tooltip as a corpse's: the same panel, also when it does not say whose
tip:Fill({ type = TYPE.Corpse, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Corpse" } })
check(head(panel).portrait == "target" and head(panel).dragon == "elite" and row(panel, 3).left:find("Dead"), "a corpse with its creature's number")
local hovered = world.mouseover
world.mouseover = world.target -- the dead kobold is under the mouse
tip:Fill({ type = TYPE.Corpse }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Corpse" } })
check(head(panel).portrait == "mouseover" and head(panel).dragon == "elite" and panel.icon:IsShown(), "a corpse that does not say whose: the creature under the mouse")
world.mouseover = hovered
world.target.dead = nil
world.player.level, world.target.class = 60, nil
world.target.kind = "rare"
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(head(panel).dragon == "silver", "a rare's is the silver one")
world.target.kind = "normal"
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(head(panel).dragon == nil and not panel.dragon:IsShown(), "a creature without a rank has none")
world.target.kind, world.target.boss = "elite", true
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(head(panel).dragon == "boss" and math.floor(panel.dragon._width) == 103, "a boss's the gold one with the great wing")
world.target.boss = nil
world.target.kind = "rareelite"
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(head(panel).dragon == "silver" and row(panel, 3).left == "|cff" .. code(COLOR.SILVER) .. "Rare|r  \194\183  |cffFFD100Elite|r",
    "a rare elite: the silver dragon, and both of its words, each in its dragon's colour")
world.target.kind = "elite"

-- A live 3D portrait (the option models): the game's model of the unit, in the portrait's place --
local given = {} -- the units a model was given
W.methods.SetUnit = function(self, unit)
    given[#given + 1] = unit
    if not unitOf(unit).far then self._model = unit end
    return not unitOf(unit).far
end
W.methods.ClearModel = function(self) self._model = nil end
W.methods.SetPortraitZoom = function(self, zoom) self._zoom = zoom end
W.methods.SetFrameLevel = function(self, level) self._level = level end
W.methods.GetFrameLevel = function(self) return self._level or 1 end
local kobold = { { "Kobold", nil, { 1, 0.1, 0.1 } } }
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
local figure = panel.figure
check(figure and figure._kind == "PlayerModel" and figure:IsShown() and given[#given] == "target" and figure._zoom == 1
    and figure._points[1][2] == panel.icon and not panel.icon:IsShown(),
    "a creature's portrait is its live 3D model, its face in view, where the flat picture stood")
local badge
for index = 1, panel.texts.taken do if panel.texts[index]._text == "5" then badge = panel.texts[index] end end
check(panel.dragon:GetParent() == panel.front and panel.plaque:GetParent() == panel.front and badge and badge:GetParent() == panel.front
    and figure:GetFrameLevel() > panel:GetFrameLevel() and panel.front:GetFrameLevel() > figure:GetFrameLevel(),
    "the dragon, the plaque and the level stand over the model")
local asked = #given
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(#given == asked and figure:IsShown(), "drawn again for the same unit, the model is not given it again (it would load anew)")
-- Hidden with its panel (the game hides the model frame with it) and filled again for the same unit, as when
-- the mouse comes back to it: the panel is not drawn anew, and the model still stands in the portrait's place.
-- (A model frame that does not keep its model loses it when hidden.)
tip:Hide()
if figure._scripts.OnHide then figure._scripts.OnHide(figure) end
if not figure._keep then figure._model = nil end
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1) -- a key: the shown panels seen or not anew (Gate)
check(figure._model == "target" and #given == asked and figure:IsShown() and figure:GetAlpha() == 1 and not panel.icon:IsShown(),
    "hidden and shown again for the same unit: its model stands at once, kept while hidden, not given anew")
-- The game refreshes a unit frame's tooltip several times a second, in one go: SetOwner hides it, SetUnit fills it again.
-- Its panel is not hidden meanwhile, nor the model in it (shown anew, it would start over: a blink): both stand as they
-- are until the end of the frame draws the panel anew. Hidden and not filled again, the panel goes at the end of the frame.
do
    local panelHides, figureHides = 0, 0
    panel.Hide = function(self) panelHides = panelHides + 1 return W.methods.Hide(self) end
    figure.Hide = function(self) figureHides = figureHides + 1 return W.methods.Hide(self) end
    tip:Hide()
    local stood = panel:IsShown() and figure:IsShown()
    tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold, true)
    stood = stood and panel:IsShown() and figure:IsShown()
    frame()
    check(stood and panelHides == 0 and figureHides == 0 and panel:IsShown() and figure:IsShown() and tip:GetAlpha() == 0,
        "hidden and filled again in one frame, as the game refreshes a unit frame's tooltip: the panel and its model stay shown throughout")
    tip:Hide()
    check(panel:IsShown() and panelHides == 0 and tip:GetAlpha() == 0, "hidden and not filled again, the panel stands until the end of the frame")
    frame()
    check(not panel:IsShown() and panelHides == 1 and tip:GetAlpha() == 1, "and goes then, the tooltip the game's own again")
    panel.Hide, figure.Hide = nil, nil
end
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { "Epic" } })
check(not figure:IsShown() and panel.icon:IsShown(), "an item has its icon, no model")
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(#given == asked and figure:IsShown() and not panel.icon:IsShown(), "the same unit after an item: its kept model, at once")
world.target.far = true -- out of sight: the game cannot draw its model
local sameGuid = UnitGUID
UnitGUID = function(unit) return unit == "target" and "Creature-0-0-0-0-9999-0" or sameGuid(unit) end -- another creature
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(figure:GetAlpha() == 0 and panel.icon:IsShown() and panel.icon.portrait == "target" and #given == asked + 1
    and figure._scripts.OnUpdate, "refused (not ready, perhaps): the flat picture meanwhile, the model asked for again in a moment")
local Panel = ns.Panel
for _ = 1, Panel.RETRIES do figure._scripts.OnUpdate(figure, Panel.RETRY) end
check(not figure:IsShown() and not figure._scripts.OnUpdate and panel.icon:IsShown() and #given == asked + 1 + Panel.RETRIES,
    "where the game still cannot draw it after its tries, the flat picture stays")
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(figure:GetAlpha() == 0 and #given == asked + 2 + Panel.RETRIES, "and the game is asked again at the next draw")
-- Refused at first, taken at the third try: the 3D model without Alt or a new draw.
world.target.far = nil
figure._scripts.OnUpdate(figure, Panel.RETRY / 2) -- (not yet: not asked)
check(#given == asked + 2 + Panel.RETRIES, "between two tries the game is not asked")
figure._scripts.OnUpdate(figure, Panel.RETRY / 2)
check(figure:IsShown() and figure:GetAlpha() == 1 and not panel.icon:IsShown() and not figure._scripts.OnUpdate
    and figure._model == "target" and panel.figured == figure,
    "taken at a later try: the live 3D model in the picture's place at once, no Alt and no new draw needed")
UnitGUID = sameGuid
asked = #given
options.models = false
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(not figure:IsShown() and panel.icon:IsShown() and #given == asked, "switched off: the flat picture, and no model is asked for")
options.models, options.show = true, "shift"
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(figure:IsShown() and figure:GetAlpha() == 0 and panel:GetAlpha() == 0, "unseen until Shift is held, the model too (by itself)")
W.shift = true
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(figure:GetAlpha() == 1 and panel:GetAlpha() == 1, "and seen with its panel")
W.shift, options.show = false, "always"
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
W.methods.SetUnit, W.methods.ClearModel = nil, nil -- the units below have the flat picture again
figure:Hide()

-- A thing's 3D model in its icon's place (the option models, Figures.lua): a mount's and a pet's by the
-- game's collections, gear on your own character. The icon stands until the game has loaded the model.
local loads = {} -- what the models were given, in order
W.methods.SetDisplayInfo = function(self, display) loads[#loads + 1] = "display " .. display end
W.methods.TryOn = function(self, link) loads[#loads + 1] = "try " .. link; return link:find("6006") and 1 or 0 end
W.methods.Dress = function(self) loads[#loads + 1] = "dress" end
W.methods.SetUnit = function(self, unit) loads[#loads + 1] = "unit " .. unit; return true end
W.methods.SetFacing = function(self, turn) self._turn = turn end
Enum.ItemTryOnReason = { Success = 0, WrongRace = 1 }
C_MountJournal = {
    GetMountFromItem = function(id) return id == 6001 and 7 or nil end,
    GetMountFromSpell = function(id) return id == 6101 and 8 or nil end,
    GetMountInfoExtraByID = function(mount) if mount == 7 then return 1234 end end,
    GetMountAllCreatureDisplayInfoByID = function(mount) if mount == 8 then return { { creatureDisplayID = 4321 } } end end,
}
C_PetJournal = { GetPetInfoByItemID = function(id) if id == 6002 then return "Cat", 1, 1, 99, "", "", false, false, true, false, true, 555 end end }
local WEAR = { [6003] = "INVTYPE_HEAD", [6004] = "INVTYPE_CLOAK", [6005] = "INVTYPE_FINGER", [6006] = "INVTYPE_CHEST", [6007] = "INVTYPE_FEET" }
local instant = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(id) if WEAR[id] then return id, "Armor", "Cloth", WEAR[id] end return id, "Misc", "Junk", "" end
C_Item.IsDressableItemByID = function(id) return WEAR[id] ~= nil and WEAR[id] ~= "INVTYPE_FINGER" end
for id = 6001, 6007 do W.items[id] = { name = "Thing " .. id, quality = 1 } end
local function loaded(model) model._scripts.OnModelLoaded(model) end -- the game has the model now
tip:Fill({ type = TYPE.Item, id = 6001 }, { { "Reins of the Wolf" } })
check(head(panel).model == 1234 and head(panel).modelKind == "display" and loads[#loads] == "display 1234",
    "a mount's item: the mount's model (the game's mount collection), given to the model frame")
check(figure:IsShown() and figure:GetAlpha() == 0 and panel.icon:IsShown() and panel.icon._texture == 2000 + 6001,
    "until the game has loaded it, the icon stands, the model unseen")
loaded(figure)
check(figure:GetAlpha() == 1 and not panel.icon:IsShown() and figure._turn == -0.5, "loaded, the model stands in the icon's place, a little from the side")
panel.drawn = false
tip:Fill({ type = TYPE.Item, id = 6001 }, { { "Reins of the Wolf" } })
check(#loads == 1 and figure:GetAlpha() == 1 and not panel.icon:IsShown(), "drawn again, the same model is not given again, and stands at once")
tip:Fill({ type = TYPE.Item, id = 6002 }, { { "Cat Carrier" } })
check(loads[#loads] == "display 555" and panel.icon:IsShown(), "a pet's item: the pet's model (its twelfth answer), the icon until it is loaded")
loaded(figure)
-- A piece of gear keeps its icon. With Alt held, your own character wearing it stands beside the panel, on a
-- stage of its own (Panel.Stage), as high as the panel, turning slowly round.
tip:Fill({ type = TYPE.Item, id = 6003 }, { { "Helm" } })
check(not figure:IsShown() and panel.icon:IsShown() and head(panel).model == nil and head(panel).dress == "item:6003" and panel.stage == nil,
    "a piece of gear: its icon, no model in its place; without Alt nothing more, nor a frame made for it")
W.alt = true
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
local stage = panel.stage
check(stage and stage.model._kind == "DressUpModel" and stage:IsShown() and loads[#loads - 1] == "unit player" and loads[#loads] == "try item:6003",
    "with Alt held: your own character trying it on (the item, where the tooltip does not give its link), on a stage of its own")
check(stage._height == panel:GetHeight() and stage._width == math.floor(panel:GetHeight() * 0.6 + 0.5) and stage._points[1][1] == "TOPRIGHT"
    and stage._points[1][2] == panel and stage._points[1][3] == "TOPLEFT" and stage._points[1][4] == -16,
    "as high as the panel, at its left, as far from it as two panels stand apart")
check(stage.back == nil, "see-through: no ground of its own behind your character")
check(stage.model:GetAlpha() == 0 and stage:GetFrameLevel() > panel:GetFrameLevel(), "your character unseen until the game has loaded it")
loaded(stage.model)
check(stage.model:GetAlpha() == 1 and stage.model._zoom == 0, "then you wearing it, the whole of you")
local facing = stage.model.facing
stage.model._scripts.OnUpdate(stage.model, 2.5)
check(math.abs(stage.model._turn - (facing + 2.5 * 0.1 * 2 * math.pi)) < 1e-9, "turning slowly round: a quarter of a turn in 2.5 seconds")
function tip:GetItem() return "Cloak", "|cffffffff|Hitem:6004::::|h[Cloak]|h|r" end
tip:Fill({ type = TYPE.Item, id = 6004 }, { { "Cloak" } })
check(loads[#loads - 1] == "dress" and loads[#loads] == "try |cffffffff|Hitem:6004::::|h[Cloak]|h|r" and stage.model:GetAlpha() == 1,
    "the next piece: your character dressed anew in what you wear, trying it on (its own link), at once")
tip.GetItem = nil
local asked = #loads
tick(panel)
tick(panel)
check(#loads == asked and stage:IsShown(), "once a frame the stage is looked at, but given nothing again while the piece is the same")
function panel:GetLeft() return 30 end
tick(panel)
check(stage._points[1][1] == "TOPLEFT" and stage._points[1][2] == panel and stage._points[1][3] == "TOPRIGHT" and stage._points[1][4] == 16,
    "no room at the panel's left on the screen: the stage stands at its right")
panel.GetLeft = nil
tick(panel)
check(stage._points[1][1] == "TOPRIGHT" and #loads == asked, "room again: at its left, and your character not dressed again for it")
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
check(not stage:IsShown() and panel.icon:IsShown(), "let go of Alt: the stage is gone, the icon stays")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 6005 }, { { "Ring" } })
check(#loads == asked and not stage:IsShown() and head(panel).dress == nil, "a ring is not seen on a character: no stage, with Alt or not")
tip:Fill({ type = TYPE.Item, id = 6006 }, { { "Robe" } })
asked = #loads
tick(panel)
check(loads[#loads] == "try item:6006" and #loads == asked and not stage:IsShown(),
    "where your character cannot try it on: no stage, and it is not tried on again every frame")
tip:Fill({ type = TYPE.Item, id = 6007 }, { { "Boots" } })
check(loads[#loads - 1] == "dress" and loads[#loads] == "try item:6007" and stage:IsShown(),
    "your character is kept while the stage is hidden: dressed anew, not asked for again")
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
W.spells[6101] = { name = "Swift Wolf" }
tip:Fill({ type = TYPE.Spell, id = 6101 }, { { "Swift Wolf" } })
check(head(panel).model == 4321 and loads[#loads] == "display 4321" and figure:IsShown(),
    "a spell that summons a mount: the mount's model (the first of its displays)")
options.models = false
asked = #loads
W.alt = true
tip:Fill({ type = TYPE.Item, id = 6003 }, { { "Helm" } })
check(#loads == asked and panel.icon:IsShown() and not figure:IsShown() and not stage:IsShown(),
    "switched off: the icon, and no model is asked for, not even with Alt")
W.alt = false
options.models, options.icons = true, false
tip:Fill({ type = TYPE.Item, id = 6003 }, { { "Helm" } })
check(#loads == asked and head(panel).model == nil and head(panel).dress == "item:6003",
    "without icons there is no picture and no model in its place; the stage still comes with Alt")
options.icons = true
check(Core.Described("Tooltips", "models").text == "3D model in tooltips"
    and Core.Described("Tooltips", "models").default == true, "the setting: 3D model in tooltips, ticked at first")
W.methods.SetDisplayInfo, W.methods.TryOn, W.methods.Dress, W.methods.SetUnit, W.methods.SetFacing = nil, nil, nil, nil, nil
C_MountJournal, C_PetJournal, C_Item.IsDressableItemByID, C_Item.GetItemInfoInstant = nil, nil, nil, instant
figure:Hide()
stage:Hide()

-- An item's quests, and the quests items start (Core's quest data, the sample) ------------------------
-- The candle (772) is wanted by quest 60's second objective and by four more: 90 (done long ago), 91 (for
-- later: from level 62), 92 (for paladins only: not yours), 93 (you can take it). The letter (5000) starts
-- quest 80; NPC 4 drops it, 3% of the time.
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].numRequired = 1, 4
quests[90] = { done = true }
local flagged = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = function(id) return quests[id] and quests[id].done or false end
W.items[772], W.items[5000] = { name = "Candle", quality = 1 }, { name = "Dusty Letter", quality = 1 }
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
check(row(panel, 2).left == "Info" and row(panel, 3).left == "Quest Item" and row(panel, 4).kind == "caption" and row(panel, 4).left == "Quest"
    and row(panel, 5).left == "Needed for" and row(panel, 5).font == "small" and row(panel, 5).right == "Questlog",
    "an item quests want: a section of its own under the caption Quest; Questlog over where you stand")
check(row(panel, 6).left == "The Kobold Menace" and row(panel, 6).icon == "active" and row(panel, 6).label == "[2]" and row(panel, 6).lg == 0.82
    and row(panel, 6).right == "In log  1/4" and row(panel, 6).rg == 0.82,
    "first the quest in your log: the ?, its name in gold, its level, In log and your count")
check(row(panel, 7).left == "Candle Light" and row(panel, 7).icon == "available" and row(panel, 7).right == "Available"
    and row(panel, 8).left == "Wax Works" and row(panel, 8).icon == nil and row(panel, 8).right == "Not yet" and row(panel, 8).lr == COLOR.DETAIL[1]
    and row(panel, 9).left == "Candles for Gryan" and row(panel, 9).icon == "check" and row(panel, 9).right == "Done" and row(panel, 9).rg == COLOR.DONE[2],
    "then one you can take (the !), one for later (dim), one you have done (a tick, Done in green); not one for another class")
check(count(panel) == 9, "and nothing else")
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].finished = 4, true
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
check(row(panel, 6).right == "In log  4/4" and row(panel, 6).rg == COLOR.DONE[2], "the count green once the objective is complete")
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].finished = 1, false
-- Wax (775) is wanted by quest 60 (its third objective), 90, 91, 93, and by 94 and 95, which you can take too
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 775 }, { { "Wax" }, { "Quest Item" } })
local more = row(panel, count(panel))
check(more.left == "Press ALT for +2 more" and more.font == "small" and row(panel, 9).left == "And Another",
    "of the quests not in your log three, and how many more Alt shows")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 775 }, { { "Wax" }, { "Quest Item" } })
check(row(panel, 11).left == "Candles for Gryan" and count(panel) == 13 and row(panel, 12).left == "IDs" and row(panel, 13).font == "small",
    "with Alt all of them (and the details under them, under IDs)")
W.alt = false
tip:Fill({ type = TYPE.Item, id = 5000 }, { { "Dusty Letter" }, { "This Item Begins a Quest" } })
check(row(panel, 2).kind == "caption" and row(panel, 2).left == "Quest" and row(panel, 3).left == "Starts" and row(panel, 4).left == "A Letter"
    and row(panel, 4).label == "[55]" and row(panel, 4).icon == "available" and row(panel, 4).right == "Available" and count(panel) == 4,
    "an item that starts a quest: Starts, the quest with its level and where you stand with it; the game's line that says less is left out")
quests[80] = { on = true }
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 5000 }, { { "Dusty Letter" }, { "This Item Begins a Quest" } })
check(row(panel, 4).icon == "active" and row(panel, 4).right == "In log", "once taken, it says so, with the ?")
quests[80], quests[90] = nil, nil
C_QuestLog.IsQuestFlaggedCompleted = flagged
-- Quests of the same name (the same quest at other places) come once; a quest for one race. Item 773 is
-- wanted by 93 and 96 (both Candle Light), 97 (for race 95), 98 (humans and dwarves), 99 (the Alliance).
W.Fire("QUEST_LOG_UPDATE")
local function wanted(item)
    local list, names = ns.Quests.Item(item), {}
    for index = 1, list.n do names[#names + 1] = list[index].text end
    return table.concat(names, ", ")
end
check(wanted(773) == "Candle Light, Old Kingdoms, For the Alliance", "a name comes once; a human takes the quests for humans "
    .. "and dwarves and for the Alliance, not the one for a race of this client")
world.player.raceID = 95
W.Fire("QUEST_LOG_UPDATE")
check(wanted(773) == "Candle Light, High Above, For the Alliance",
    "one of this client's own races (95, whose bit is above 2^31) takes its own quests and its whole side's, not another race's")
world.player.raceID = 1
W.Fire("QUEST_LOG_UPDATE")
-- What else an item asks of you: in its header
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Robe" }, { "Classes: Mage" }, { "Requires Tailoring (75)", nil, { 1, 0.13, 0.13 } }, { "Requires Level 20" } })
check(row(panel, 2).right == "Requires Level 20" and row(panel, 3).left == "" and row(panel, 3).right == "Classes: Mage"
    and row(panel, 3).font == "detail" and row(panel, 4).right == "Requires Tailoring (75)" and row(panel, 4).rr == COLOR.RED[1] and row(panel, 4).rg == COLOR.RED[2]
    and row(panel, 5).kind == "caption",
    "a class and a profession it asks for stand in the header at the right, under the level it needs: small, red while you lack it")
local cloth = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(id) if id == 772 then return id, "Armor", "Cloth" end end
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Robe" }, { "Classes: Mage" }, { "Requires Level 20" } })
check(row(panel, 2).left == "Armor \194\183 Cloth" and row(panel, 2).right == "Requires Level 20" and row(panel, 3).right == "Classes: Mage",
    "beside what it is, the level and the class one under the other")
C_Item.GetItemInfoInstant = cloth
-- A creature that drops an item that starts a quest you can take (NPC 4)
units["Creature-0-1-2-3-4-4"] = "target"
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-4-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
local letter
for index = 1, count(panel) do if row(panel, index).left == "Dusty Letter" then letter = index end end
check(letter and row(panel, letter - 1).left == "A Letter" and row(panel, letter - 1).right == "Level 55" and row(panel, letter).icon == "available"
    and row(panel, letter).label == "3%" and row(panel, letter).right == "Starts the quest",
    "a creature that drops an item that starts a quest you can take: the quest and its level, the item with the ! and how often it drops")
W.Fire("ADDON_LOADED", "Nothing")

-- Disenchanting (Core's data, the sample: an uncommon weapon of item level 5 to 15 gives 80% 1-2 Lesser Magic
-- Essence and 20% 1-2 Strange Dust): what its materials bring, at the prices seen, after the cut
W.items[7001] = { name = "Wolf Blade", quality = 2, level = 10, sell = 50 }
W.items[10938], W.items[10940] = { name = "Lesser Magic Essence", quality = 2 }, { name = "Strange Dust", quality = 1 }
local instantBefore = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(id) if id == 7001 then return id, "Weapon", "Swords", "INVTYPE_WEAPON", 1, 2, 7 end end
C_Item.GetItemInfo = function(id)
    local item = W.items[id]
    if item then return item.name, nil, item.quality, item.level, 1, nil, nil, 1, nil, nil, item.sell end
end
local blade = { { "Wolf Blade", nil, { 0.12, 1, 0 } }, { "Binds when equipped", nil, nil, nil, LINE.ItemBinding, data = { bonding = 7 } } }
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
local disenchant
for index = 1, count(panel) do if row(panel, index).left == "Disenchant" then disenchant = index end end
check(disenchant and row(panel, disenchant).right == "no prices seen" and row(panel, disenchant - 1).left == "Vendor",
    "an uncommon weapon: under Gold, after the vendor's price, Disenchant; without the materials' prices seen, it says so")
Prices.See("10938", 100)
Prices.See("10940", 40)
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
check(row(panel, disenchant).right == "125c",
    "with them: as often and as many as disenchanting gives each, at its lowest price after the cut (80% of 1.5 x 95, 20% of 1.5 x 38)")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
check(row(panel, disenchant + 1).left == "80%  1-2 Lesser Magic Essence" and row(panel, disenchant + 1).right == "95c"
    and row(panel, disenchant + 2).left == "20%  1-2 Strange Dust" and row(panel, disenchant + 2).font == "small",
    "with Alt each material under it: how often, how many, and what one brings")
W.alt = false
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
local last = count(panel)
check(row(panel, last).left ~= "Disenchant it for 125c", "a character without the spell gets no advice to disenchant")
rawset(_G, "IsPlayerSpell", function(id) return id == 13262 end)
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
check(row(panel, count(panel)).left == "Disenchant it for 125c", "with it, what disenchanting brings counts in the advice, at the prices now")
Prices.See("10938", 10)
Prices.See("10940", 4)
tip:Fill({ type = TYPE.Item, id = 7001 }, blade)
check(row(panel, count(panel)).left ~= "Disenchant it for 125c" and row(panel, disenchant).right == "12c",
    "the materials' prices fall, and the numbers with them: the advice is what the auction house lists now")
rawset(_G, "IsPlayerSpell", nil)
W.items[7001].quality = 1
tip:Fill({ type = TYPE.Item, id = 7002 }, { { "Plain Blade" } })
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
local plain = false
for index = 1, count(panel) do if row(panel, index).left == "Disenchant" then plain = true end end
check(not plain, "an item no row of disenchanting takes (another class, another level): no such row")
C_Item.GetItemInfoInstant, C_Item.GetItemInfo = instantBefore, nil
Prices.See("10938")
Prices.See("10940")

-- Your characters' things (Core's characters' data, read in steps since the login) --------------------
local saved = SaneUIData_Characters
local function aside(what)
    for _, broken in ipairs(saved.forever.broken or {}) do
        if broken.what == what then return broken end
    end
end
check(Data.Characters() and #Data.Characters() == 3 and aside("Player-70-0000DEAD")
    and saved["forever-beta"].characters["Player-70-0000BEEF"].name == "Beta",
    "Core has read the characters' saved file: yours and two alts; a broken entry is set aside, never wiped; another game version's part is left as it is")
check(Data.Worn("Player-70-0000CAFE")[5] == 4500 and Data.Worn("Player-70-0000BEEF") == nil and aside("Player-70-0000BEEF slots").value == 12
    and Data.Worn("account") == nil and Data.Worn("Player-70-0000DEAD") == nil,
    "what an alt wears, slot by slot; slots of a wrong shape set aside: not known; nothing for the account's bank or a broken entry")
check(saved.forever.characters[Core.charKey].slots == "" and next(Data.Worn(Core.charKey)) == nil,
    "you wear nothing: your slots are kept empty, read (told from an alt whose slots were never read)")
local me = Data.Character(Core.charKey)
check(me and me.name == "Sane Lunatic" and me.class == "MAGE" and type(me.level) == "number" and saved.forever.characters[Core.charKey].bags == "4500\0315",
    "you, kept by your GUID, with your whole name (first name and surname); your bags packed: one item, five of it")
world.player.surname = nil -- the game says the first name alone for a moment
W.Fire("PLAYER_LEVEL_UP")
Steps()
check(Data.Character(Core.charKey).name == "Sane Lunatic", "a first name alone never takes the place of the whole name")
world.player.surname = "Lunatic"
local function find(left)
    for index = 1, count(panel) do if row(panel, index).left == left then return index end end
end
W.items[4500] = { name = "Runecloth", quality = 1 }
tip:Fill({ type = TYPE.Item, id = 4500 }, { { "Runecloth" }, { "Extra", added = true } })
check(find("Inventory") == nil, "an item your characters have: no section Inventory without Alt")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 4500 }, { { "Runecloth" }, { "Extra", added = true } })
local at = find("Inventory")
check(at and row(panel, at).kind == "caption", "with Alt held, a section Inventory")
check(row(panel, at + 1).left == "Sane Lunatic" and row(panel, at + 1).right == "Bags 5" and row(panel, at + 1).lr == RAID_CLASS_COLORS.MAGE.r,
    "you first, by your whole name in your class's colour, with where you have it and how many")
check(row(panel, at + 2).left == "Droopy Fairwind" and row(panel, at + 2).right == "Bags 12  \194\183  Bank 8"
    and row(panel, at + 3).left == "Sane Moonwhisper" and row(panel, at + 3).right == "Worn 1",
    "then the others by name, each by first name and surname: one that shares your first name is another character")
check(row(panel, at + 4).left == "Account bank" and row(panel, at + 4).right == "Bank 5" and row(panel, at + 5).left == "Total"
    and row(panel, at + 5).right == "31", "the account's own bank last, then how many in all")
check(row(panel, at + 6).left == "IDs" and row(panel, at + 8).left == "Addons" and row(panel, at + 9).left == "Extra",
    "after it the details and other addons' lines")
bagItems[0][1].stackCount = 5
W.Fire("BAG_UPDATE", 0)
W.Fire("BAG_UPDATE_DELAYED")
check(row(panel, at + 1).right == "Bags 5", "a bag changes: nothing is read at once")
Steps()
check(row(panel, at + 1).right == "Bags 7" and row(panel, at + 5).right == "33" and saved.forever.characters[Core.charKey].bags == "4500\0317",
    "it is read in steps, kept, and the panel that is shown follows")
C_Bank = { CanViewBank = function() return true end, FetchPurchasedBankTabIDs = function(kind) return kind == 0 and { 6 } or {} end }
bagItems[6] = { { itemID = 4500, stackCount = 4 } }
W.Fire("BANKFRAME_OPENED")
Steps()
check(row(panel, at + 1).right == "Bags 7  \194\183  Bank 4" and saved.forever.characters[Core.charKey].bank == "4500\0314",
    "the bank, read while it is open")
local alt = Data.Items("Player-70-0000BEEF", "bags")
check(Data.Items(Core.charKey, "bank")[1].item == 4500 and Data.Items(Core.charKey, "bank")[1].count == 4
    and #alt == 2 and alt[1].item == 4500 and alt[1].count == 12 and alt[2].item == 4501 and #Data.Items("account", "bank") == 0,
    "what a character keeps in a place, item by item in the order kept; the account's own bank (read empty at this bank)")
check(Data.Items("account", "bags") == nil and Data.Items("Player-70-0000DEAD", "bags") == nil and Data.Items(Core.charKey, "mail") == nil,
    "nothing for a place or a character Core does not keep")
W.Fire("BANKFRAME_CLOSED")
bagItems[6] = nil
W.Fire("BAG_UPDATE", 6)
W.Fire("BAG_UPDATE_DELAYED")
Steps()
check(saved.forever.characters[Core.charKey].bank == "4500\0314", "closed, the bank is not read: what was seen of it stays")
tip:Fill({ type = TYPE.Item, id = 4501 }, { { "Thing" } })
at = find("Inventory")
check(at and row(panel, at + 1).left == "Droopy Fairwind" and row(panel, at + 1).right == "Bags 1" and not find("Total"),
    "an item one character has: no total")
tip:Fill({ type = TYPE.Item, id = 4502 }, { { "Other" } })
check(not find("Inventory"), "an item none of them has (another game version's part does not count): no section")
options.classColors = false
tip:Fill({ type = TYPE.Item, id = 4500 }, { { "Runecloth" } })
at = find("Inventory")
check(row(panel, at + 1).lr == COLOR.LIGHT[1], "with class colours switched off, the names are light")
options.classColors = true
W.alt = false
-- What you wear, slot by slot: kept beside the place worn; the ammo in its slot only (it lies in the bags).
INVSLOT_AMMO = 0
local wearing = { [0] = 2512, [1] = 6001, [16] = 6002 }
GetInventoryItemID = function(_, slot) return wearing[slot] end
W.Fire("PLAYER_EQUIPMENT_CHANGED", 1, false)
check(next(Data.Worn(Core.charKey)) == nil, "put on: nothing is read at once")
Steps()
local you = saved.forever.characters[Core.charKey]
check(you.slots == "0\0312512\0301\0316001\03016\0316002" and you.worn == "6001\0311\0306002\0311",
    "read in steps: your slots packed, slot by slot in order; the place worn as before, without the ammo")
local doll = Data.Worn(Core.charKey)
check(doll[0] == 2512 and doll[1] == 6001 and doll[16] == 6002 and Data.Worn(Core.charKey) == doll
    and Data.Count(6001)[Core.charKey].worn == 1 and Data.Count(2512) == nil,
    "Core gives them by the game's slot IDs, the same answer until something changes; only the place worn is counted")
wearing = {}
W.Fire("PLAYER_EQUIPMENT_CHANGED", 1, true)
Steps()
check(you.slots == "" and you.worn == nil and next(Data.Worn(Core.charKey)) == nil and Data.Count(6001) == nil,
    "everything taken off: the slots kept empty, the place worn gone")
INVSLOT_AMMO, GetInventoryItemID = nil, function() return nil end

-- A buff -------------------------------------------------------------------------------------
auras.player = { HELPFUL = { { isHelpful = true, dispelName = "Magic", duration = 1800, expirationTime = W.clock + 1000, sourceUnit = "mouseover", auraInstanceID = 7 } } }
tip.info = { getterName = "GetUnitBuff", getterArgs = { "player", 1 } }
do
    local shown = {}
    tip:Fill({ type = TYPE.Spell, id = 133 }, { { "Whirlwind" }, { "Hits enemies within 8 yards.", nil, GOLD, nil, LINE.SpellDescription } })
    for index = 1, count(panel) do shown[row(panel, index).left or ""] = true end
    check(shown["Hits enemies within 7 m."], "a description's yards as the setting Units says")
end
local fortitude = { { "Power Word: Fortitude" }, { "Increases Stamina by 26.", nil, GOLD, nil, LINE.SpellDescription }, { "17 minutes remaining" } }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, fortitude)
check(row(panel, 1).caps and row(panel, 2).left == "Buff  \194\183  Magic" and head(panel).ab == 1 and head(panel).icon == 1000 + 1243, "a buff: what it is under its name, in blue")
check(row(panel, 3).left == "Info" and row(panel, 4).prose, "its description, under Info")
check(shape(panel) == "text text INFO text DURATION bar" and row(panel, 6).live == "aura" and head(panel).auraID == 7
    and panel.live.auraEnds == W.clock + 1000, "then under Duration a bar that runs out with it")
W.alt = true
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Power Word: Fortitude" }, { "Increases Stamina by 26.", nil, GOLD, nil, LINE.SpellDescription },
    { "17 minutes remaining" }, { "Cast 4 times today", added = true } })
check(count(panel) == 10 and row(panel, 6).kind == "bar" and row(panel, 9).left == "Addons" and row(panel, 10).left == "Cast 4 times today",
    "with Alt, another addon's line comes after the bar, in a section of its own, not between the buff's lines and its bar")
W.alt = false
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, fortitude)
local timer = panel.live.aura
check(timer._height == 18 and timer.texts.LEFT._text == "17 minutes remaining" and timer.texts.RIGHT._text == "by Jaina Proudmoore" and timer.texts.LEFT:GetParent():GetParent() == timer,
    "inside it, the game's line for how long it still runs, and who cast it (first name and surname)")
check(panel.barMask._points[1][5] == select(5, timer:GetPoint(1)), "with round corners, like a unit's bars")

-- Another addon's ID line, among the buff's own lines and after them
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Power Word: Fortitude" }, { "Spell ID: 1459", nil, GOLD, nil, 0, added = true },
    { "Increases Stamina by 26.", nil, GOLD, nil, LINE.SpellDescription }, { "17 minutes remaining" }, { "IconID", "135932", nil, nil, 0, added = true } })
check(count(panel) == 6 and row(panel, 4).left == "Increases Stamina by 26." and panel.live.aura.texts.LEFT._text == "17 minutes remaining",
    "another addon's ID lines are left out (Alt shows the numbers), and the time is still found for the bar")
check(ns.Reader.IsIdLine({ left = "|TInterface\\Icons\\X:0|t |cffffd100Spell ID:|r", right = "|Hspell:1459|h1459|h" })
    and not ns.Reader.IsIdLine({ left = "|cffffd100Spell ID|r is a word", right = "" }),
    "an ID line is known also with colours, links and icons in it; a line that only names an ID is none")

-- Alt held: the technical details
W.alt = true
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
check(count(panel) == 8 and row(panel, 7).left == "IDs" and row(panel, 8).font == "small" and row(panel, 8).left == "Spell ID: 1243" and row(panel, 8).right == "Icon ID: 2243",
    "with Alt held a tooltip has its technical details at the bottom, small, under IDs: the spell's number at the left, its icon's at the right")
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
check(count(panel) == 6, "let go, they are gone")
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(count(panel) == 6, "(another key changes nothing)")
auras.player.HELPFUL[1] = { isHarmful = true, dispelName = "Magic", duration = 0, auraInstanceID = 8 }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Polymorph" }, { "Cannot attack or cast spells.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left == "Debuff  \194\183  Magic" and head(panel).ag == 0.6 and count(panel) == 4, "a debuff has the colour of its kind; without a time, no bar")
auras.player.HARMFUL = { { isHarmful = true, duration = 0, auraInstanceID = 9 } }
tip.info = { getterName = "GetUnitDebuffByAuraInstanceID", getterArgs = { "player", 9 } }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Curse of Nothing" } })
check(row(panel, 2).left == "Debuff" and head(panel).ar == 0.8 and head(panel).ag == 0 and head(panel).ab == 0,
    "a debuff the game names by its own number is found by it; nothing takes it away: the game's colour for that")
auras.player.HARMFUL = nil
tip.info = nil
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, fortitude)
check(shape(panel) == "text INFO text DETAILS text" and not head(panel).accent and panel:IsShown(),
    "a buff the game says nothing more about still gets its name and lines, each kind under its name")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
check(row(panel, 3).left == "Item ID: 19019" and row(panel, 3).right == "Icon ID: 21019", "an item's: its number and its icon's")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-4711-5" }, { { "Kobold" } })
check(row(panel, count(panel)).left == "NPC ID: 4711", "a creature's: its number")
tip:Fill({ type = TYPE.Quest, id = 77 }, { { "Wolves", nil, GOLD } })
check(row(panel, count(panel)).left == "Quest ID: 77" and row(panel, count(panel)).right == "", "anything else's: its number")
W.alt = false

-- A quest --------------------------------------------------------------------------------------
quests[77] = { level = 6, on = true }
tip:Fill({ type = TYPE.Quest, id = 77 }, { { "Wolves Across the Border", nil, GOLD }, { "Bring their paws to Eagan.", nil, WHITE },
    { "Tough Wolf Meat: 8/8", nil, nil, nil, LINE.QuestObjective, data = { completed = true } }, { "3/8 Wolf Paw", nil, nil, nil, LINE.QuestObjective } })
check(row(panel, 1).caps and head(panel).ag == 0.82 and row(panel, 2).left == "Level 6" and row(panel, 2).label == "\194\183  In progress" and row(panel, 2).lb == 0,
    "a quest: gold, its level in the colour of its difficulty, and where it stands for you")
check(row(panel, 3).left == "Info" and row(panel, 4).left == "Bring their paws to Eagan." and row(panel, 5).kind == "caption"
    and row(panel, 5).left == "Objectives", "what it says, under Info, then what there is to do under a caption")
check(row(panel, 6).left == "Tough Wolf Meat" and row(panel, 6).right == "8/8" and row(panel, 6).icon == "check" and row(panel, 6).lg == COLOR.DONE[2],
    "a thing that is done: ticked and green, its count at the right")
check(row(panel, 7).left == "Wolf Paw" and row(panel, 7).right == "3/8" and row(panel, 7).icon == "box" and count(panel) == 7, "a thing still to do: an empty box")
-- Lines of several other addons, with an empty line between them: never between the quest's text and its
-- objectives, but after everything of the panel's own, under one caption, the empty line a gap
W.alt = true
tip:Fill({ type = TYPE.Quest, id = 77 }, { { "Wolves Across the Border", nil, GOLD }, { "Bring their paws to Eagan.", nil, WHITE },
    { "Tough Wolf Meat: 8/8", nil, nil, nil, LINE.QuestObjective, data = { completed = true } }, { "3/8 Wolf Paw", nil, nil, nil, LINE.QuestObjective },
    { "Seen by 3 guild members", nil, GREEN, added = true }, { " ", added = true }, { "Worth 12 points", "A note", nil, nil, 0, added = true } })
check(row(panel, 7).left == "Wolf Paw" and row(panel, 8).left == "IDs" and row(panel, 9).left == "Quest ID: 77" and row(panel, 10).kind == "caption"
    and row(panel, 10).left == "Addons" and row(panel, 11).left == "Seen by 3 guild members" and row(panel, 11).font == "small"
    and row(panel, 11).lg == COLOR.ASIDE[2] and row(panel, 12).left == "Worth 12 points" and row(panel, 12).right == "A note" and row(panel, 12).space
    and count(panel) == 12,
    "other addons' lines: after the objectives and the details Alt shows, in one section of their own, small and quiet, an empty line between them a gap")
W.alt = false
quests[77].ready = true
tip:Fill({ type = TYPE.Quest, id = 77 }, { { "Wolves Across the Border", nil, GOLD } })
check(row(panel, 2).label == "\194\183  Ready to turn in" and count(panel) == 2, "ready to hand in, it says so")

-- Anything else
tip:Fill({ type = TYPE.Object, id = 1 }, { { "Battered Chest", nil, GOLD }, { "Locked", nil, { 1, 0.1, 0.1 } }, { " " }, { "Rusty hinges" },
    { "Opened here 12 times", nil, nil, nil, 0, added = true } })
check(row(panel, 1).caps and not head(panel).accent and row(panel, 2).lr == 1 and shape(panel) == "text text +text",
    "any other kind (a mailbox, a chest): its name, its lines in their colours under it, no sections, an empty line a gap; a panel "
    .. "without a colour of its own, whatever colour its name has; another addon's line only with Alt")
local plainR, plainG = ns.Mix(COLOR.BACKDROP, COLOR.NEUTRAL, 0.28)
check(math.abs(colors[2].r - plainR) < 1e-9 and math.abs(colors[2].g - plainG) < 1e-9, "its background the same as a dead unit's")

-- Too tall for the screen: the rest goes on in a second column beside the first, as wide, a groove between them
local long = { { "Long Scroll", nil, GOLD } }
for line = 1, 40 do long[#long + 1] = { "Line " .. line } end
UIParent._height = 100
tip:Fill({ type = TYPE.Object, id = 2 }, long)
local columnWidth = panel:GetWidth()
local columnsLeft = {}
for index = 1, panel.texts.taken do
    local label = panel.texts[index]
    if label:IsShown() and label._points[1] then columnsLeft[label._points[1][4]] = true end
end
local tallest = 100 - 2 * (ns.Panel.EDGE + 8)
check(panel:GetHeight() <= tallest and columnsLeft[12] and next(columnsLeft, nil) and panel.icon._points[1][1] == "TOPLEFT",
    "a tooltip too tall for the screen is no taller than it")
local ONE = 224 -- a column as wide as this panel would be in one
local grooves = 0
for index = 1, panel.lines.taken do
    local line = panel.lines[index]
    if line:IsShown() and line._height == panel:GetHeight() - 24 and line._points[1][4] % ONE == 0 then grooves = grooves + 1 end
end
local columns = panel:GetWidth() / ONE
check(columns == 3 and columnsLeft[12 + ONE] and columnsLeft[12 + 2 * ONE] and grooves == 2,
    "its rows go on in columns beside the first, each as wide as it, a groove between two columns")
UIParent._height = nil
long[2] = { "Line 1, changed" } -- (the same lines are not drawn again)
tip:Fill({ type = TYPE.Object, id = 2 }, long)
check(panel:GetWidth() < columnWidth, "with room on the screen, one column again")

-- Gathering: how likely a herb or an ore raises your skill (Gathering.lua; Core's data, the sample: Peacebloom
-- needs Herbalism 1, yellow from 25, grey from 100; Mithril Deposit Mining 175, 200, 275; both thorium veins give
-- Thorium Ore, the small one from 245)
local skillLines = { [182] = { skillID = 182, name = "Herbalism", rank = 160, modifier = 0, maxRank = 225 } }
C_SkillInfo = { GetSkillLineInfoByID = function(id) return skillLines[id] end }
W.Fire("SKILL_LINES_CHANGED")
local CHANCE = { "FF1A1A", "FF8040", "FFD100", "40BF40", "808080" } -- none, orange, yellow, green, grey (the game's)
local function bands(need, yellow, grey)
    return ("|cff%s%d|r  |cff%s%d|r  |cff%s%d|r  |cff%s%d|r"):format(CHANCE[2], need, CHANCE[3], yellow, CHANCE[4],
        math.ceil((yellow + grey) / 2), CHANCE[5], grey)
end
local function hex(one, at) return ns.Hex(row(one, at).lr, row(one, at).lg, row(one, at).lb) end
tip:Fill({ type = TYPE.Object }, { { "Peacebloom" }, { "Herbalism", nil, { 1, 1, 1 } } })
check(shape(panel) == "text PROFESSIONS text" and row(panel, 3).left == "Herbalism" and row(panel, 3).icon == "Interface\\Icons\\Trade_Herbalism"
    and row(panel, 3).label == "160/225" and row(panel, 3).labelFont == "small",
    "a herb: under Professions its skill, with its icon and your skill after it; the game's own line of the skill is left out")
check(hex(panel, 3) == CHANCE[5] and row(panel, 3).right == bands(1, 25, 100) and row(panel, 3).right:find("63", 1, true),
    "the skill in the colour of your chance (grey: 160 is past the herb's grey), at the right where each colour begins: "
    .. "what it needs, its own yellow and grey, green halfway between")
tip:Fill({ type = TYPE.Object }, { { "Peacebloom" }, { "Herbalism", nil, { 0.25, 0.75, 0.25 } } })
check(hex(panel, 3) == CHANCE[4], "where the game gives its line of the skill a colour of difficulty, that colour: it knows best")
tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Requires Mining 175", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 3).left == "Mining" and row(panel, 3).label == "Not learned" and hex(panel, 3) == CHANCE[1] and count(panel) == 3,
    "a vein without the profession: red, and not learned")
skillLines[186] = { skillID = 186, name = "Mining", rank = 170, modifier = 5, maxRank = 225 }
W.Fire("SKILL_LINES_CHANGED")
tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Mining" } })
check(hex(panel, 3) == CHANCE[2] and row(panel, 3).label == "170/225" and row(panel, 3).right == bands(175, 200, 275),
    "your skill changes: asked anew; with its bonus it reaches what the vein needs, and every time is a point: orange")
skillLines[186].rank = 205
W.Fire("SKILL_LINES_CHANGED")
tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Mining" } })
check(hex(panel, 3) == CHANCE[3], "from its yellow on: yellow")
skillLines[186].rank = 238
W.Fire("SKILL_LINES_CHANGED")
tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Mining" } })
check(hex(panel, 3) == CHANCE[4], "from halfway to its grey on: green")
skillLines[186].rank, skillLines[186].modifier = 160, 0
W.Fire("SKILL_LINES_CHANGED")
tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Requires Mining 175" } })
check(hex(panel, 3) == CHANCE[1], "below what it needs: red")
-- What came seldom, as Core counted it: on the vein, and on the rare item, with how often
do
    local Tally, Drops = Core.Data.Tally, Core.Data.Drops()
    local vein = "object:" .. Core.Data.Set("Objects"):Keys("byName", "Mithril Deposit")[1]
    for index = 1, 40 do
        Tally.Loot(vein, "gather", 0)
        Tally.Drop(vein, "gather", 3858, 0, 2)
        if index <= 3 then Tally.Drop(vein, "gather", 7910, 0, 1) end
    end
    Tally.Drop(vein, "gather", 12800, 0, 1)
    W.items[7910], W.items[12800] = { name = "Star Ruby", quality = 2 }, { name = "Azerothian Diamond", quality = 2 }
    tip:Fill({ type = TYPE.Object }, { { "Mithril Deposit" }, { "Mining" } })
    check(count(panel) == 5 and row(panel, 4).left == "Star Ruby  7.5% (3 of 40)" and row(panel, 4).font == "small"
        and row(panel, 5).left == "Azerothian Diamond  1 of 40", "a vein: its rare drops, a percent once enough came, until then how many of how many")
    tip:Fill({ type = TYPE.Item, id = 7910 }, { { "Star Ruby" } })
    local seldom = find("Professions")
    check(seldom and row(panel, seldom + 1).left == "Mithril Deposit  7.5% (3 of 40)", "the rare item: where it came from, how often")
    check(#Drops:Rare(vein) == 2, "what the tooltips read is Core's")
end
W.items[10620] = { name = "Thorium Ore", quality = 1 }
tip:Fill({ type = TYPE.Item, id = 10620 }, { { "Thorium Ore" } })
local gathering = find("Professions")
check(gathering and row(panel, gathering + 1).left == "Small Thorium Vein" and row(panel, gathering + 1).right == bands(245, 270, 345)
    and row(panel, gathering + 1).icon == "Interface\\Icons\\Trade_Mining" and hex(panel, gathering + 1) == CHANCE[1],
    "what a vein gives: under Professions the vein that gives it by its name, the easiest first, in the colour of your chance")
check(row(panel, gathering + 2).left == "Press ALT for +1 more" and row(panel, gathering + 2).font == "small", "and how many more Alt shows")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 10620 }, { { "Thorium Ore" } })
check(row(panel, gathering + 2).left == "Rich Thorium Vein" and row(panel, gathering + 2).right == bands(275, 300, 375), "with Alt, every vein that gives it")
W.alt = false
tip:Fill({ type = TYPE.Object }, { { "Battered Chest" }, { "Locked", nil, { 1, 0.1, 0.1 } } })
check(shape(panel) == "text text", "a thing in the world the data has no skill for: no section")

-- Lines somebody wrote in: a button's hint -------------------------------------------------------
tip:Hide()
frame()
check(not panel:IsShown() and tip:GetAlpha() == 1 and tip.left[1]:GetAlpha() == 1,
    "a hidden tooltip takes its panel with it at the end of the frame and is visible again, its lines too")
check(#panel._points == 0, "and the panel hangs on nothing any more (so no other panel can come to hang on it the wrong way round)")
tip:Fill(nil, { { "Close", nil, GOLD } })
check(not hinted(panel), "a button's hint has no line that Alt shows more: there is nothing more")
check(panel:IsShown() and tip:GetAlpha() == 0 and count(panel) == 1 and row(panel, 1).left == "Close" and not row(panel, 1).caps,
    "a tooltip somebody wrote lines into gets a panel too, its lines as they are written")
spell()
check(panel:IsShown() and cells(row(panel, 4)):find("Mana 30 (30%)", 1, true) ~= nil, "(a spell again)")
tip:Fill(nil, { { "Bowyer" }, { "Repairs" }, { Core.UNCONFIRMED, nil, { 0.5, 0.5, 0.5 } } })
local marks = {}
for index = 1, panel.texts.taken do
    local label = panel.texts[index]
    if label._text == "!" then marks[#marks + 1] = label end
end
check(shape(panel) == "text text UNCONFIRMED DATA" and not row(panel, 3).caps and row(panel, 3).bare and row(panel, 3).mark
    and row(panel, 3).left == "Unconfirmed Data" and #marks == 2
    and marks[1]._color[1] == ns.COLOR.RED[1] and marks[1]._points[1][4] < marks[2]._points[1][4],
    "a line Core marks as not confirmed by the game is a quiet note at the bottom, grey in the middle as written, no rules, "
    .. "a red ! at each side")
-- A creature that is no unit of the game's (Core.TipLook: a boss on a dungeon's map): a creature's panel
local GOLDEN = { 1, 0.82, 0 }
tip:Fill(nil, { { "Rattlegore", nil, { 1, 0.3, 0.25 } }, { "Scholomance" }, { "Boss", nil, GOLDEN }, { "Abilities", nil, GOLDEN },
    { "|T132338:16:16:0:0:64:64:5:59:5:59|t Cleave" }, { "    Hits the target and those beside it.", nil, GOLDEN },
    { "Loot", nil, GOLDEN }, { "|T1901:16:16|t Bone Blade" }, { "    +12 Strength" },
    { Core.UNCONFIRMED, nil, { 0.5, 0.5, 0.5 } } }, true)
Core.TipLook(tip, { display = 11622, dragon = "boss", badge = "??", sections = { [4] = true, [7] = true } })
frame()
check(shape(panel) == "text text text ABILITIES text text LOOT text text UNCONFIRMED DATA" and row(panel, 2).font == "title"
    and row(panel, 2).flush and row(panel, 3).font == "detail" and head(panel).accent and head(panel).ar == 1,
    "a boss on a dungeon's map: its name, as large under it the dungeon, small Boss; its sections under their dividers")
check(head(panel).model == 11622 and head(panel).modelKind == "display" and head(panel).dragon == "boss" and head(panel).badge == "??"
    and head(panel).badgeR == ns.COLOR.RED[1] and hinted(panel),
    "its model in the portrait's place, the boss's dragon round it, ?? on the plaque; Alt shows more")
check(row(panel, 5).icon == 132338 and row(panel, 5).left == "Cleave" and row(panel, 6).indent and row(panel, 6).font == "sub"
    and row(panel, 6).left == "Hits the target and those beside it." and row(panel, 9).left == "+12 Strength",
    "a row's icon at its start; the details with Alt set in under it, small")
-- A rare on the map (Core.TipLook by its creature): the game's model of that NPC, a rare's silver dragon, its level
W.methods.SetCreature = function(self, npc) self._creature = npc end
tip:Fill(nil, { { "Mother Fang", nil, { 1, 0.3, 0.25 } }, { "Rare" }, { "Beast" } }, true)
Core.TipLook(tip, { creature = 471, dragon = "silver", badge = "10" })
frame()
check(head(panel).model == "creature:471" and head(panel).modelKind == "creature" and head(panel).dragon == "silver"
    and head(panel).badge == "10" and panel.figure and panel.figure._creature == 471,
    "a rare on the map: its own model by its creature in the portrait's place, a rare's silver dragon, its level on the plaque")
W.methods.SetCreature = nil
tip:Fill(nil, { { "Close" }, { "Closes the window." } })
check(panel:IsShown() and tip:GetAlpha() == 0 and row(panel, 2).left == "Closes the window." and head(panel).icon == nil and not head(panel).strip,
    "lines written into it after a spell's are a hint, not that spell")
tip._scripts.OnTooltipCleared(tip)
tip.left[1]:SetText("Bags")
tick(panel)
frame()
check(panel:IsShown() and row(panel, 1).left == "Bags" and tip:GetAlpha() == 0, "lines written in without the tooltip being shown again are drawn on the next frame")

-- What is left to the game ----------------------------------------------------------------------
tip.insertedFrames = { {} }
spell()
check(not panel:IsShown() and tip:GetAlpha() == 1, "a tooltip that holds a frame a panel cannot show is the game's")
tip.insertedFrames = nil
tip.shownMoneyFrames = 1
spell()
check(not panel:IsShown(), "so is one with coins that are not an item's price")
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { " ", nil, nil, nil, LINE.SellPrice, price = 5 } })
check(panel:IsShown(), "but not one with an item's price")
for _, call in ipairs(postCalls) do call.fn(tip, { type = TYPE.Spell, id = 133, lines = {} }) end
frame()
check(panel:IsShown() and tip:GetAlpha() == 0 and row(panel, 1).left == "Thunderfury" and head(panel).icon == 2000 + 19019,
    "data the game adds to a filled tooltip changes neither what it is about nor whose it is")
tip.shownMoneyFrames = nil
issecretvalue = function(value) return value == "hidden" end
tip:Fill({ type = TYPE.Unit, guid = "hidden" }, { { "hidden" }, { "Level ??" } })
check(not panel:IsShown() and tip:GetAlpha() == 1, "and one with a line the game hides in a fight")
tip:Fill({ type = TYPE.Unit, guid = "hidden" }, { { "Somebody", nil, { "hidden", "hidden", "hidden" } }, { "Level ??" } })
check(panel:IsShown() and not head(panel).accent and head(panel).unit == nil and count(panel) == 2, "a unit the game does not name gets its lines on a grey panel")
issecretvalue = nil
local inner = Tooltip("Inner")
inner.IsEmbedded = true
inner:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
check(ns.Panel.All()[inner] == nil and inner:GetAlpha() == 1, "a tooltip inside another frame is never touched")
local scan = Tooltip("SomeAddonScanTooltip")
scan.anchor = "ANCHOR_NONE" -- owned, but placed nowhere: to read what the game says of a thing
scan:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
check(not ns.Panel.All()[scan]:IsShown() and scan:GetAlpha() == 1 and scan.left[1]:GetAlpha() == 1,
    "another addon's tooltip that nobody sees gets no panel drawn, and is left as it was")
check(ns.Panel.All()[scan].parts == nil, "its parts are not hidden one by one on every fill: that costs, many times a second")
-- A text's size the game hides (when what the panel hangs on is placed by something hidden): that
-- tooltip is the game's this time, and nothing stands down
spell("8 sec cooldown")
issecretvalue = function(value) return value == "hidden" end
for _, text in ipairs(panel.texts) do function text:GetStringHeight() return "hidden" end end
spell("10 sec cooldown")
check(not panel:IsShown() and tip:GetAlpha() == 1 and not ns.off, "a panel whose sizes the game hides is not shown: the tooltip is the game's, this time")
for _, text in ipairs(panel.texts) do text.GetStringHeight = nil end
issecretvalue = nil
spell("8 sec cooldown")
check(panel:IsShown() and tip:GetAlpha() == 0, "the next time it is drawn again")

-- The game's tooltip under the panel ------------------------------------------------------------
tip.anchor = "ANCHOR_RIGHT"
spell()
check(panel._width == 224 and panel._height > 50, "(a panel is at least 224 wide)")
check(tip._width == 100 and tip.padding[1] == 0, "the game's tooltip keeps its size: nothing of it is changed but its alpha")
check(panel._points[1][1] == "BOTTOMLEFT" and panel._points[1][2] == tip, "the panel hangs on the corner the tooltip hangs by")
tip.anchor = "ANCHOR_BOTTOMRIGHT"
tip:Show()
check(panel._points[1][1] == "TOPLEFT" and tip:GetAlpha() == 0, "shown by the game once more, it stays invisible and the panel follows its corner")
tip.anchor = "ANCHOR_NONE"
tip:SetPoint("TOP", UIParent, "TOP", 0, 0)
tip:SetPoint("RIGHT", UIParent, "LEFT", 0, 0)
tip:Show()
check(panel._points[1][1] == "TOPRIGHT", "a comparison tooltip is held by its top and one side: its panel hangs on that side")
tip:SetShown(true)
check(tip:GetAlpha() == 0, "nor when the game shows it with SetShown, as it does for a comparison")
tip._scripts.OnTooltipCleared(tip)
tip:Show()
check(tip:GetAlpha() == 0 and panel:IsShown(), "cleared and shown before it is filled, it does not show through beside the old panel")
spell()
tip._alpha = 0.6
tick(panel)
check(tip:GetAlpha() == 0, "nor does a fading tooltip show through")
tip:FadeOut()
check(not panel:IsShown() and tip:IsShown() and tip._fading and tip:GetAlpha() == 0 and tip.left[1]:GetAlpha() == 0,
    "the mouse has left it and the game lets it fade: the panel is gone at once, and the fading tooltip is not seen either")
tip:Hide()
frame()
check(tip.left[1]:GetAlpha() == 1, "once the game hides it, its parts are given back at the end of the frame")
tip:Fill({ type = TYPE.Spell, id = 133 }, { { "Fireball", "Rank 2" }, { "30 Mana", "35 yd range" } }, true)
tip:FadeOut()
frame()
check(not panel:IsShown(), "a draw that waited when the fade began is not made")
spell()
check(panel:IsShown() and tip:GetAlpha() == 0, "the next tooltip has its panel again")
local points = tip._points
tip._points = {} -- placed nowhere now (ANCHOR_NONE)
tick(panel)
check(not panel:IsShown() and tip:GetAlpha() == 1, "a tooltip that is placed nowhere any more is the game's again, and its panel stops")
tip._points = points
spell()
local shopping = Tooltip("ShoppingTooltip1")
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
local worn = ns.Panel.All()[shopping]
check(worn:IsShown() and head(worn).ar == 0.64, "any tooltip the game fills gets a panel of its own: the comparison too")
check(head(worn).tag == "" and worn:GetAlpha() == 1, "(no words over it: as bright as any)")
-- The game puts a comparison beside the tooltip it belongs to: its panel goes beside that one's panel.
tip.anchor = "ANCHOR_RIGHT"
spell()
shopping:ClearAllPoints()
shopping:SetPoint("TOP", tip, "TOP", 0, 0)
shopping:SetPoint("RIGHT", tip, "LEFT", 0, 0)
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(#worn._points == 1 and worn._points[1][1] == "TOPRIGHT" and worn._points[1][2] == panel and worn._points[1][3] == "TOPLEFT",
    "a comparison's panel stands beside the panel of the tooltip it belongs to, on the game's side, their tops in a line")
shopping:ClearAllPoints()
shopping:SetPoint("TOPLEFT", tip, "TOPRIGHT", 0, 0)
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(#worn._points == 1 and worn._points[1][1] == "TOPLEFT" and worn._points[1][2] == panel and worn._points[1][3] == "TOPRIGHT",
    "set on the other side, its panel is too")
check(tip._width == 100 and shopping._width == 100, "and no tooltip's size was changed for it, so the game places them the same way every time")
-- The game refreshes a comparison several times a second: SetOwner hides it, its points are
-- cleared, it is filled and shown, and only then placed again.
function worn:GetLeft() return 320 end
function worn:GetTop() return 540 end
shopping:Hide()
shopping:ClearAllPoints()
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
check(worn:IsShown() and #worn._points == 1 and worn._points[1][1] == "TOPLEFT" and worn._points[1][2] == UIParent
    and worn._points[1][3] == "BOTTOMLEFT" and worn._points[1][4] == 320 and worn._points[1][5] == 540 and shopping:GetAlpha() == 0,
    "refreshed, the comparison's panel stays where it stood (not on the corner of the game's tooltip, which has no place yet)")
shopping:SetPoint("TOP", tip, "TOP", 0, 0)
shopping:SetPoint("RIGHT", tip, "LEFT", 0, 0)
frame()
check(#worn._points == 1 and worn._points[1][2] == panel and worn._points[1][3] == "TOPLEFT",
    "and at the end of the frame it is beside the other panel again: one place, no jumping between two")
worn.GetLeft, worn.GetTop = nil, nil
-- The game places two comparisons by each other, now one way round, now the other; a panel cannot
-- hang on one that hangs on it (the game refuses such a point)
worn.SetPoint = function(self, point, relative, ...)
    if relative == panel then error("Cannot anchor to a region dependent on it") end
    return W.methods.SetPoint(self, point, relative, ...)
end
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(not ns.off and worn:IsShown() and #worn._points == 1 and worn._points[1][1] == "TOPRIGHT" and worn._points[1][2] == shopping,
    "a panel that cannot be placed beside the other panel hangs on its own tooltip's corner")
worn.SetPoint = nil
shopping.CompareHeader = W.NewWidget("Frame", nil, shopping)
shopping.CompareHeader.Label = W.NewWidget("FontString", nil, shopping.CompareHeader)
shopping.CompareHeader.Label:SetText("Equipped")
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(head(worn).tag == "|cffFFD100EQUIPPED|r" and worn.texts[1]._text == "|cffFFD100EQUIPPED|r" and worn.texts[2]._text == "Thunderfury",
    "what you wear says so at its top, inside the panel, where another item says how it binds")
check(worn:GetAlpha() == 0.85, "and stands back a little")
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Binds when picked up", nil, nil, nil, LINE.ItemBinding, data = { bonding = 3 } },
    { "", added = true }, { "If you replace this item, the following stat changes will occur:", nil, GOLD, added = true },
    { "|cff00ff00+2.2|r damage per second", added = true }, { "+3 Stamina", added = true } })
check(head(worn).tag == "|cffFFD100EQUIPPED|r" and count(worn) == 4 and row(worn, 2).left == "Info" and row(worn, 3).left == "|cff00ff00+2.2|r DPS"
    and row(worn, 3).font == "row" and row(worn, 4).left == "+3 Stam" and row(worn, 4).font == "row",
    "a comparison's changes without the sentence over them, as the game's own lines under Info, damage per second short")

-- What you wear beside what you look at, at places of the module's own: the game moves its
-- comparisons about several times a second (one on the other, then the other way round, hidden and
-- refilled); their panels stand at fixed places on the screen, a gap apart.
local second = Tooltip("ShoppingTooltip2")
tip.shoppingTooltips = { shopping, second }
UIParent.GetWidth = function() return 1000 end
local mainLeft, mainRight, mainTop = 300, 520, 600
function panel:GetLeft() return mainLeft end
function panel:GetRight() return mainRight end
function panel:GetTop() return mainTop end
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
local function placed(which) local point = which._points[1] or {} return #which._points == 1 and point[2] == UIParent and point[3] == "BOTTOMLEFT", point end
local function gameMoves(first, other) -- the game places its comparisons, one way or the other
    shopping:ClearAllPoints()
    second:ClearAllPoints()
    if first then
        shopping:SetPoint("TOP", tip, "TOP", 0, 0)
        shopping:SetPoint("LEFT", tip, "RIGHT", 0, 0)
        second:SetPoint("TOPLEFT", shopping, "TOPRIGHT", 0, 0)
    else
        second:SetPoint("LEFT", tip, "RIGHT", 0, 0)
        shopping:SetPoint("TOPLEFT", second, "TOPRIGHT", 0, 0)
    end
end
gameMoves(true)
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
second:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
local secondWorn = ns.Panel.All()[second]
local GAP, WIDE = 2 * ns.Panel.EDGE, 224 -- between two panels side by side: their soft edges just meet; a panel's width here
local fixed, point = placed(worn)
check(GAP == 16 and fixed and point[1] == "TOPLEFT" and point[4] == 520 + GAP and point[5] == 600,
    "the first comparison stands at a place of its own on the screen: a gap right of the item's panel (there is room), its top in a line")
fixed, point = placed(secondWorn)
check(fixed and point[1] == "TOPLEFT" and point[4] == 520 + GAP + WIDE + GAP and point[5] == 600, "the second a gap beside the first")
-- The game refreshes them: the other way round, the first hidden while the second is placed
gameMoves(false)
shopping:Hide()
second:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(select(2, placed(secondWorn))[4] == 520 + GAP + WIDE + GAP and select(2, placed(worn))[4] == 520 + GAP,
    "refreshed the other way round, the first hidden meanwhile: both stay where they were")
local wide = worn.GetWidth
worn.GetWidth = function() return 200 end -- the first a little narrower for a moment
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(select(2, placed(secondWorn))[4] == 520 + GAP + WIDE + GAP, "nor does the second move when the first is narrower for a moment")
worn.GetWidth = wide
-- The item's panel wobbles: not followed. It moves and stays: followed, once
local placedAt = secondWorn._points[1]
mainLeft, mainRight = 340, 560
tick(panel)
mainLeft, mainRight = 300, 520
tick(panel)
W.Wait(0.5)
tick(panel)
check(secondWorn._points[1] == placedAt and select(2, placed(worn))[4] == 520 + GAP, "a wobble of the item's panel moves nothing")
mainLeft, mainRight = 400, 620
tick(panel)
W.Wait(0.05)
tick(panel)
check(select(2, placed(worn))[4] == 520 + GAP, "a move is not followed at once")
W.Wait(0.1)
tick(panel)
check(select(2, placed(worn))[4] == 620 + GAP and select(2, placed(secondWorn))[4] == 620 + GAP + WIDE + GAP,
    "once the item's panel has stood still in its new place for a moment, its comparisons follow, once")
-- Something else at the right edge of the screen: the side anew, where they fit
mainLeft, mainRight = 700, 920
tip:Fill({ type = TYPE.Item, id = 2589 }, { { "Linen Cloth" } })
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
fixed, point = placed(worn)
check(fixed and point[1] == "TOPRIGHT" and point[4] == 700 - GAP and select(2, placed(secondWorn))[1] == "TOPRIGHT"
    and select(2, placed(secondWorn))[4] == 700 - GAP - WIDE - GAP, "another thing near the right edge: on the left, where they fit")
-- The game fills the comparisons before it tells of the item they belong to: the item's panel is drawn first
-- all the same, so they stand beside where it stands for this item, not where it stood for the last one (here
-- the item's panel stands where what it shows puts it)
function panel:GetLeft() return row(panel, 1).left == "Linen Cloth" and 700 or 300 end
function panel:GetRight() return row(panel, 1).left == "Linen Cloth" and 920 or 520 end
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
frame()
fixed, point = placed(worn)
check(fixed and point[1] == "TOPLEFT" and point[4] == 520 + GAP,
    "filled before the item they belong to, its comparisons stand beside its panel as drawn for that item, at once")
-- A tooltip the game fills while the end of the frame draws the others waits in a queue of its own and is
-- drawn the next frame: never left waiting, unseen
local seat, meanwhile = ns.Host.Seat, false
ns.Host.Seat = function(tooltip, which)
    seat(tooltip, which)
    if tooltip == tip and not meanwhile then
        meanwhile = true
        second:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
    end
end
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
frame()
ns.Host.Seat = seat
check(meanwhile and secondWorn.pending and ns.driver:IsShown(), "a tooltip filled while the others are drawn waits for the next frame")
frame()
check(not secondWorn.pending and secondWorn:IsShown() and second:GetAlpha() == 0, "and is drawn then, not left waiting unseen")
-- The game refreshes the item's tooltip as a bag's button does several times a second: it hides it (and so its
-- comparisons) and fills it again in one go. The comparisons keep their layout: the second stays where it was
-- while the first is a little narrower for a moment
local thunderfury = { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }
local function refresh(main, rows)
    tip:Hide()
    shopping:Hide()
    second:Hide()
    shopping:Fill({ type = TYPE.Item, id = 19019 }, thunderfury, true)
    second:Fill({ type = TYPE.Item, id = 19019 }, thunderfury, true)
    tip:Fill({ type = TYPE.Item, id = main }, rows, true)
    frame()
end
worn.GetWidth = function() return 200 end
refresh(19019, thunderfury)
worn.GetWidth = wide
check(select(2, placed(worn))[4] == 520 + GAP and select(2, placed(secondWorn))[4] == 520 + GAP + WIDE + GAP,
    "the item's tooltip refreshed (hidden and filled again in one go): its comparisons keep their places")
-- A piece of gear with Alt held, its comparisons on the left: refreshed, the item's panel is drawn before them,
-- and the stage of your character already keeps to the other side, where it stood
function panel:GetLeft() return row(panel, 1).left == "Helm" and 700 or 300 end
function panel:GetRight() return row(panel, 1).left == "Helm" and 920 or 520 end
W.alt = true
shopping:Fill({ type = TYPE.Item, id = 19019 }, thunderfury, true)
second:Fill({ type = TYPE.Item, id = 19019 }, thunderfury, true)
tip:Fill({ type = TYPE.Item, id = 6003 }, { { "Helm" } }, true)
frame()
tick(panel)
local right = stage._points[1] and stage._points[1][1]
refresh(6003, { { "Helm" } })
check(right == "TOPLEFT" and stage:IsShown() and stage._points[1][1] == "TOPLEFT" and stage._points[1][3] == "TOPRIGHT",
    "with Alt over gear whose comparisons stand at the left, refreshed: your character stays at the panel's right")
W.alt = false
panel.GetLeft, panel.GetRight, panel.GetTop, UIParent.GetWidth = nil, nil, nil, nil
second:Hide()
tip.shoppingTooltips = nil

-- How wide a panel is: as wide as what it holds, in steps of 8, from 224 to 432; where a row's two
-- sides do not both fit, the right one gives way
W.methods.GetUnboundedStringWidth = function(self) return #(self._text or "") * 6 end
W.methods.SetWordWrap = function(self, on) self._wrap = on end
tip:Fill(nil, { { "Close" }, { string.rep("a", 40), "bb" } })
check(panel._width == 296, "a row 268 wide (its sides an em apart) makes a panel of 296: with the margins, up to the next step of 8")
tip:Fill(nil, { { "Close" }, { string.rep("a", 100), "bb" } })
check(panel._width == 432 and panel.left[2]._width == 381 and panel.right[2]._width == 13 and panel.right[2]._wrap == false,
    "never wider than 432: the right side keeps its words on one line, the left side has the rest of the room")
W.methods.GetUnboundedStringWidth, W.methods.SetWordWrap = nil, nil

-- The settings for the look
options.textSize = 18
SaneUI.Core.described.Tooltips.changed("textSize", 18)
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(size(worn.texts[2]) == 18 and size(worn.texts[1]) == 16, "a changed text size draws the same lines anew, larger")
options.textSize = 14
options.opacity = 50
SaneUI.Core.described.Tooltips.changed("opacity", 50)
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } })
check(colors[1].a == 0.5, "and a changed opacity a fainter background")
options.opacity = 97

-- The setup, step by step (Setup.lua; Saneroki, 2026-11-18): one step, the module's own switches (the mouse and the 3D
-- model as a plain Yes or No), and your own tooltip as the sample, drawn by the panels' own code over the world, anew
-- after each change, seen whatever the option show says. (In a function of its own: the main chunk is at 200 locals.)
;(function()
    local Setup = ns.Setup
    local guide = Core.Onboarding.Guide("Tooltips")
    check(guide and guide.title == "Tooltips" and #guide.steps == 1 and guide.steps[1].key == "tooltips",
        "the tooltips' setup, handed to Core: one step")
    local settings = guide.steps[1].settings
    check(settings[1] == "show" and settings[2].key == "cursor" and settings[3].key == "models" and settings[4] == "opacity",
        "when they show, at the mouse, the 3D model, the opacity")
    check(settings[2].choices[1][1] == "always" and settings[2].choices[2][1] == "default" and settings[2].choices[1][2] == "Yes"
        and settings[3].choices[1][1] == true and settings[3].choices[2][1] == false and settings[3].choices[2][2] == "No",
        "the mouse and the 3D model as a plain Yes or No")
    check(Core.Described("Tooltips", "opacity").unit == "%" and type(Core.Described("Tooltips", "setup").button) == "function",
        "the opacity in percent; a button on the options page opens the setup")
    -- Your character's tooltip, filled by the game into the setup's own tooltip (Reader), which nobody sees.
    units["Player-2"] = "player"
    local reader = Tooltip(Setup.READER)
    Setup.reader = reader
    local filled = 0
    function reader:SetUnit(unit)
        filled = filled + 1
        self.filledWith = unit
        self:Fill({ type = TYPE.Unit, guid = "Player-2" }, { { "Sane", nil, { 0.5, 0.5, 1 } }, { "Level 60 Human Mage (Player)" } })
    end
    W.methods.SetUnit = function(self, unit) self._unit = unit return true end -- the model frame takes your character
    local stage = CreateFrame("Frame", nil, UIParent)
    local was = { show = options.show, cursor = options.cursor, models = options.models, opacity = options.opacity }
    W.shift = false
    Core.Set("Tooltips", "show", "shift")
    Core.Set("Tooltips", "cursor", "default")
    local function Stage() guide.Stage(stage, guide.steps[1], 1) end
    Stage()
    local board = Setup.Board()
    local sample = board and board.sample
    check(sample and sample:IsShown() and sample:GetParent() == board and board:GetParent() == stage and filled == 1
        and reader.filledWith == "player" and head(sample).unit == "player", "the sample: your own tooltip, read from the game's, on the stage")
    local listed = false
    for _, other in pairs(ns.Panel.All()) do listed = listed or other == sample end
    check(not listed and not reader:IsShown() and sample:GetFrameStrata() == stage:GetFrameStrata(),
        "not one of the tooltips' panels: nothing that runs the tooltips touches it; the tooltip read from hidden again")
    check(sample:GetAlpha() == 1, "seen though Shift is not held: a sample")
    local said = board.words:GetText()
    check(said:find("Hold ", 1, true) and said:find("Shift", 1, true) and said:find(Setup.TEXT.corner, 1, true),
        "the band says it: hold Shift; in the corner")
    local point = sample._points[1] or {}
    check(not board.pointer:IsShown() and point[1] == "BOTTOMRIGHT" and point[2] == board.world and point[4] == -Setup.MARGIN,
        "No: in the corner, where the game puts tooltips")
    check(sample.figure and sample.figure:IsShown() and sample.figure._unit == "player", "3D model: your character in the portrait's place")
    Core.Set("Tooltips", "cursor", "always")
    Stage()
    point = sample._points[1] or {}
    check(board.pointer:IsShown() and point[1] == "TOPLEFT" and point[2] == board.pointer and filled == 2
        and board.words:GetText():find(Setup.TEXT.mouse, 1, true), "Yes: beside the mouse pointer, read anew")
    Core.Set("Tooltips", "models", false)
    Stage()
    check(not sample.figure:IsShown() and sample.icon:IsShown() and sample.icon.portrait == "player", "No 3D model: the portrait")
    Core.Set("Tooltips", "opacity", 40)
    Stage()
    check(colors[1].a == 0.4, "the opacity: the sample's background as solid as chosen")
    Core.Set("Tooltips", "show", "always")
    Stage()
    check(board.words:GetText():find(Setup.TEXT.always, 1, true), "Always: the band says they show at once")
    -- The world cut to the stage's shape, between the loading screen's bars.
    local cut = {}
    Setup.Cut({ SetTexCoord = function(_, ...) cut = { ... } end }, 408, 478)
    local aspect = (cut[2] - cut[1]) * Setup.WORLD_SIZE[1] / ((cut[4] - cut[3]) * Setup.WORLD_SIZE[2])
    check(math.abs(aspect - 408 / 478) < 1e-9 and cut[3] == 0.19 and cut[4] == 0.81 and math.abs(cut[1] + cut[2] - 1) < 1e-9,
        "the world: the loading screen's middle, as high as between its bars, in the stage's shape")
    check(board.world:IsShown() and board.world._texture == Setup.WORLD.forever, "Forever's own loading screen behind it")
    -- The module stood down: nothing to show but that.
    ns.off = true
    Stage()
    check(not sample:IsShown() and board.words:GetText() == Setup.TEXT.off, "stood down: no sample, the band says why")
    ns.off = nil
    W.methods.SetUnit = nil
    for key, value in pairs(was) do Core.Set("Tooltips", key, value) end
    board:Hide()
    frame()
end)()

-- The tooltip a chat link opens ------------------------------------------------------------------
-- On a screen of 1000 by 800 the tooltip, 100 by 50, stands in the middle once it is placed there.
function pinned:GetLeft() return 450 end
function pinned:GetRight() return 550 end
function pinned:GetTop() return 425 end
function pinned:GetBottom() return 375 end
local THUNDERFURY = { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }
pinned:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 80) -- where the game has it at first
pinned:Fill({ type = TYPE.Item, id = 19019 }, THUNDERFURY)
local stuck = ns.Panel.All()[pinned]
check(#pinned._points == 1 and pinned._points[1][1] == "CENTER" and pinned._points[1][2] == UIParent and pinned._points[1][3] == "CENTER",
    "a chat link's tooltip opens in the middle of the screen")
check(stuck:IsShown() and #stuck._points == 1 and stuck._points[1][1] == "CENTER" and stuck._points[1][2] == pinned
    and stuck._points[1][3] == "CENTER", "and its panel stands in its middle, whichever of the two is larger")
check(stuck.close == nil, "the panel has no X of its own")
function stuck:GetLeft() return 500 - self._width / 2 end
function stuck:GetRight() return 500 + self._width / 2 end
function stuck:GetTop() return 400 + self._height / 2 end
function stuck:GetBottom() return 400 - self._height / 2 end
pinned:Show()
local edge = 25 - stuck._height / 2
check(stuck._width == 224 and pinned._hit and pinned._hit[1] == -62 and pinned._hit[2] == -62 and pinned._hit[3] == edge and pinned._hit[4] == edge
    and pinned._width == 100, "the tooltip takes the mouse where its panel is seen (its area for the mouse), its size unchanged")
check(pinned.CloseButton._mouse == false and tip._hit == nil, "the game's X under it takes no click; a tooltip the mouse cannot be on is left as it is")
pinned._scripts.OnMouseUp(pinned, "LeftButton")
check(pinned:IsShown(), "a press that began somewhere else closes nothing")
pinned._scripts.OnMouseDown(pinned, "LeftButton")
pinned._scripts.OnDragStart(pinned, "LeftButton")
pinned._scripts.OnMouseUp(pinned, "LeftButton")
check(pinned:IsShown() and stuck:IsShown(), "nor does one that dragged it")
pinned._scripts.OnMouseDown(pinned, "RightButton")
pinned._scripts.OnMouseUp(pinned, "RightButton")
frame()
check(not pinned:IsShown() and not stuck:IsShown(), "a click on it closes it, as the game's X does; its panel is gone at the end of the frame")
check(pinned._hit[1] == 0 and pinned._hit[3] == 0 and pinned.CloseButton._mouse == true, "and the tooltip's area for the mouse and its X are the game's again")
pinned:ClearAllPoints()
pinned:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10) -- dragged somewhere, the last time
pinned:Fill({ type = TYPE.Item, id = 19019 }, THUNDERFURY)
check(#pinned._points == 1 and pinned._points[1][1] == "CENTER" and stuck:IsShown(), "opened again, it is in the middle again")
pinned:Hide()
frame()

-- Seen only while a key is held (the option show) -----------------------------------------------
options.show = "shift"
spell("2 sec cooldown")
check(panel:IsShown() and panel:GetAlpha() == 0 and tip:GetAlpha() == 0,
    "with Shift chosen, a tooltip is filled and its panel drawn as always, but nothing of it is seen")
W.shift = true
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(panel:GetAlpha() == 1 and tip:GetAlpha() == 0, "Shift pressed: its panel is seen at once")
W.shift = false
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
check(panel:GetAlpha() == 0, "let go: unseen again")
tip.insertedFrames = { true } -- a frame inside: the panel cannot show it, the tooltip is the game's
spell("3 sec cooldown")
check(not panel:IsShown() and tip:GetAlpha() == 0, "a tooltip left to the game is unseen the same way")
W.shift = true
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(tip:GetAlpha() == 1, "and seen while Shift is held")
tip.insertedFrames = nil
options.show = "shiftalt"
spell("4 sec cooldown")
check(panel:GetAlpha() == 0, "with Shift and Alt chosen, Shift alone is not enough")
W.alt = true
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
check(panel:IsShown() and panel:GetAlpha() == 1, "both are")
W.shift, W.alt = false, false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
options.show = "always"
spell("5 sec cooldown")
check(panel:GetAlpha() == 1 and tip:GetAlpha() == 0, "Always: seen at once, as before")

-- The mouse -------------------------------------------------------------------------------------
GameTooltip_SetDefaultAnchor(tip, UIParent)
check(tip.anchor == "ANCHOR_NONE", "the game puts a tooltip in the corner of the screen")
options.cursor = "always"
GameTooltip_SetDefaultAnchor(tip, UIParent)
check(tip.anchor == "ANCHOR_CURSOR_RIGHT" and tip._owner == UIParent, "with Always chosen, at the mouse")
options.cursor = "ctrl"
GameTooltip_SetDefaultAnchor(tip, UIParent)
spell("6 sec cooldown")
check(tip.anchor == "ANCHOR_NONE" and panel:IsShown(), "with Ctrl chosen, in the corner while Ctrl is not held")
W.ctrl = true
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(tip.anchor == "ANCHOR_CURSOR_RIGHT" and tip:NumLines() == 4, "Ctrl pressed: the shown tooltip goes to the mouse at once, its lines kept")
check(panel:IsShown() and row(panel, 1).left == "Fireball", "(its panel with it)")
W.ctrl = false
W.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 0)
check(tip.anchor == "ANCHOR_NONE" and tip._points[1][1] == "BOTTOMRIGHT" and tip._points[1][4] == -20 and tip._points[1][5] == 80,
    "let go: back where the game had put it")
W.ctrl = true
GameTooltip_SetDefaultAnchor(tip, UIParent)
check(tip.anchor == "ANCHOR_CURSOR_RIGHT", "a tooltip the game places while Ctrl is held goes to the mouse")
W.ctrl = false
W.printed = {}
tip.IsForbidden = function() error("the game changed this") end
GameTooltip_SetDefaultAnchor(tip, UIParent)
check(not ns.off and Core.errors["Tooltips: the mouse switch"] and #W.printed == 1, "an error in the switch for the mouse is noted and told; it stands nothing down")
tip.IsForbidden = nil
options.cursor = "default"

-- Retail: what it lacks of Forever's hidden, every kind still drawn, nothing noted ---------------------
do
    W.Play("retail")
    local before = 0
    for _ in pairs(Core.errors) do before = before + 1 end
    tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
    check(panel:IsShown() and tip:GetAlpha() == 0 and row(panel, 1).left == "Thunderfury", "Retail: an item's panel")
    spell()
    check(panel:IsShown() and row(panel, 1).left == "Fireball", "Retail: a spell's panel")
    tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
    check(panel:IsShown() and head(panel).unit == "mouseover", "Retail: a player's panel")
    tip:Fill({ type = TYPE.Object }, { { "Peacebloom" }, { "Herbalism", nil, { 1, 0.5, 0.25 } } })
    check(panel:IsShown() and row(panel, 1).left == "Peacebloom", "Retail: a thing of the world's panel")
    local after = 0
    for _ in pairs(Core.errors) do after = after + 1 end
    check(after == before and not ns.off, "Retail: no error noted, nothing stood down")
    W.Play("forever")
end

-- A failure: the game's own tooltips are back ------------------------------------------------------
spell()
check(panel:IsShown() and tip:GetAlpha() == 0, "(a panel once more)")
-- A live value that fails (a unit the game does not let us ask about) stands nothing down
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
local health = UnitHealth
UnitHealth = function() error("not for addons") end
W.Fire("UNIT_HEALTH", "mouseover")
tick(panel)
W.Fire("UNIT_HEALTH", "mouseover")
tick(panel)
UnitHealth = health
check(not ns.off and panel:IsShown() and Core.errors["Tooltips: live values"] and Core.errors["Tooltips: live values"].count == 1,
    "a live value that fails is noted once; the panel keeps what it was drawn with, and the tooltips go on")
W.printed = {}
local texture = C_Spell.GetSpellTexture
C_Spell.GetSpellTexture = function() error("the game changed this") end
spell()
check(not ns.off and not panel:IsShown() and tip:GetAlpha() == 1, "an error in the reader of one kind (a spell's) gives that tooltip back as it was")
local kept = Core.errors["Tooltips: Spell tooltips are the game's own"]
check(kept and kept.text:find("the game changed this") and #W.printed == 1, "it is noted and said once")
C_Spell.GetSpellTexture = texture
spell()
check(not panel:IsShown() and tip:GetAlpha() == 1 and #W.printed == 1, "spells stay the game's own until the next /reload")
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { "Unique" } })
check(panel:IsShown() and tip:GetAlpha() == 0 and worn:IsShown(), "every other kind is still drawn")
local counted = ns.Panel.Draw
ns.Panel.Draw = function() error("the game changed that") end
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { "Unique-Equipped" } })
check(ns.off and not panel:IsShown() and tip:GetAlpha() == 1 and tip.padding[1] == 0,
    "an error anywhere else takes the panels away and gives the tooltips back as they were")
check(not worn:IsShown() and shopping:GetAlpha() == 1, "all of them")
kept = Core.errors["Tooltips: the game's own tooltips are back"]
check(kept and kept.text:find("the game changed that") and #W.printed == 2, "it is noted and said once")
ns.Panel.Draw = counted
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
check(not panel:IsShown() and tip:GetAlpha() == 1 and #W.printed == 2, "after that the tooltips stay the game's until the next /reload")
options.cursor = "always"
GameTooltip_SetDefaultAnchor(tip, UIParent)
check(tip.anchor == "ANCHOR_CURSOR_RIGHT", "the switch for the mouse still works")
-- Standing down while a tooltip waits to be drawn: nothing waits any more, and the frame that would draw it
-- stops (its OnUpdate would only do nothing, every frame)
ns.off = nil
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Epic" } }, true)
local waited = ns.driver:IsShown()
ns.StandDown("a test")
check(waited and ns.off and not ns.driver:IsShown() and not worn:IsShown(),
    "standing down while a tooltip waits to be drawn: the frame that would draw it stops, the tooltip is the game's")

-- An update with new files and only a /reload: part of the module is missing ---------------------
local whole = ns.Model
ns.Model, ns.off = nil, nil
W.printed = {}
wipe(Core.errors)
ns.OnLogin()
check(ns.off and #W.printed == 1 and W.printed[1]:find("restart the game") and #postCalls == 1 and next(Core.errors) == nil,
    "a module that is not whole asks for a restart of the game: no listener for the game's tooltips, and no error")
ns.Model = whole

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Tooltips: all %d checks passed.\n"):format(passed))
