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
-- The auction house's list as you browse it (Auction.lua), and the clock it dates prices by
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
    player = { player = true, name = "Tester", level = 60, class = { "Mage", "MAGE", 8 }, race = "Human", raceID = 1, side = "Alliance", power = "MANA" },
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
local function count(panel) return panel.model.shown.n end

-- The addons: Core, then the module -----------------------------------------------------------
-- Of Core only what the module uses: its tools, the kit (pools, pixels, a frame lent), the saved settings,
-- and Fuzzy for a text without its codes.
W.Load(root, "SaneUI", "Core/Core", {})
W.Load(root, "SaneUI", "Core/Kit", {})
W.Load(root, "SaneUI", "Core/Motion", {})
W.Load(root, "SaneUI", "Core/Saved", {})
W.Load(root, "SaneUI", "Core/Fuzzy", {})
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
Core.Store("Tooltips").options = { show = "never", cursor = true } -- saved by hand: no choice; the mouse switch of version 2
local files = { "Tooltips", "Texts", "Model", "Read", "Live", "Inspect", "Numbers", "Data/Quests", "Quests", "Auction" }
for _, name in ipairs({ "Kinds/Gold", "Kinds/Item", "Kinds/Spell", "Kinds/Unit", "Kinds/Aura", "Kinds/Quest", "Pools", "Panel", "Host" }) do
    files[#files + 1] = name
end
for _, file in ipairs(files) do
    W.Load(root, "SaneUI_Tooltips", "Tooltips/" .. file, ns)
end
check(SaneUI.Tooltips == ns and ns.addon == "SaneUI_Tooltips", "the module is an addon of its own")
local facts = ns.QuestFacts
local kobold = ns.Quests.Record(7)
check(type(facts) == "table" and facts.quest[7] == "1-2;+783!15;A;;Kobold Camp Cleanup" and facts.npc[197]:find("^g7,")
    and kobold.title == "Kobold Camp Cleanup" and kobold.from == 1 and kobold.level == 2 and kobold.after[1] == 783
    and kobold.closers[1] == 15 and kobold.side == "A" and not kobold.races and not kobold.classes,
    "the module's own quest facts are there: Marshal McBride gives Kobold Camp Cleanup, from level 1, of level 2, for the "
    .. "Alliance, after A Threat Within; closed once Investigate Echo Ridge, the next step, is taken")
check(facts.npc[3041]:find("H1718", 1, true) and facts.quest[113]:find("!H32!A162", 1, true)
    and #ns.Quests.Record(113).closers == 1 and ns.Quests.Record(113).closers[1] == 162,
    "what is one side's only is tagged (The Islander is given by Horde NPCs), and only the player's side counts (Alliance)")
local shaped = true
for _, text in pairs(facts.quest) do shaped = shaped and text:find("^[%d%-]*;[%+/!AH%d]*;[AH%d%.]*;[%d%.]*;") ~= nil end
for _, text in pairs(facts.npc) do shaped = shaped and text:find("^[gtds][AH%d%.,]+[gtds AH%d%.,]*$") ~= nil end
for _, text in pairs(facts.item) do shaped = shaped and text:find("^[nb][%d%.,]+[nb %d%.,]*$") ~= nil end
check(shaped, "every record of the facts has its shape: a quest's five fields, an NPC's and an item's groups")
W.Fire("ADDON_LOADED", "SaneUI_Tooltips")
local options = ns.options
check(options == Core.Settings("Tooltips"), "the switches are the table Core keeps for the module")
check(options.cursor == "always" and options.classColors == true and options.icons == true and options.textSize == 14 and options.opacity == 97,
    "its settings: the mouse off, class colours and icons on, the text 14 high, the background almost solid")
check(options.show == "always", "and tooltips shown always (a saved value that is no choice of the option gets that)")
check(Core.described.Tooltips.list[2].choices[1][1] == "default" and Core.described.Tooltips.list[2].default == "default",
    "the mouse option at first: the game's place; one saved as switched on (an older version) is Always now")
options.cursor = "default"
options.show = "always" -- shown at once, until the key is tried (below)
check(Core.Store("Tooltips").version == 3, "the settings say which version of them they are")
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
-- Prices seen at the auction house a month ago and more (and one without a day) are forgotten at the login
ns.store.prices, ns.store.seen = { [1] = 5, [2] = 6, [3] = 7 }, { [1] = 100 - 31, [2] = 100 - 30 }
W.Fire("PLAYER_LOGIN")
check(#postCalls == 1 and postCalls[1].kind == "ALL", "one listener for every kind of tooltip data")
check(tip._scripts.OnTooltipCleared and tip._scripts.OnShow and ns.Panel.All()[tip] == nil,
    "the tooltips that also show hints are hooked at login; their panels are only made when first needed")
check(ns.store.prices[1] == nil and ns.store.prices[2] == 6 and ns.store.prices[3] == nil and ns.store.seen[1] == nil,
    "an auction price not seen for more than 30 days is forgotten at the login: the saved prices do not only grow")

-- Sentences of the game with gaps
check(("Durability 61 / 120"):match(ns.PATTERN.DURABILITY) == "61" and ("(53.8 damage per second)"):match(ns.PATTERN.DPS) == "53.8"
    and ("Requires Level 58"):match(ns.PATTERN.MIN_LEVEL) == "58" and not ("Requires Level 58 or so"):match(ns.PATTERN.MIN_LEVEL),
    "a sentence of the game with gaps becomes a pattern that finds what stands in the gaps")

-- A spell -----------------------------------------------------------------------------------
tip:Fill({ type = TYPE.Spell, id = 5 }, {
    { "Elune's Light", "Racial" },
    { "Instant", "3 min cooldown" },
    { "Increases your critical strike chance with all spells and attacks by 10% for 15 sec.", nil, GOLD, nil, LINE.SpellDescription },
    { "", "Racial", nil, nil, 0, added = true },
    { "|c0042b1fePress F6 to submit an issue for this spell", nil, nil, nil, 0, added = true },
})
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
check(row(panel, 3).kind == "strip" and row(panel, 3).rule and cells(row(panel, 3)) == "Cast Instant, Cooldown 3 min",
    "one strip under a divider: the facts the tooltip's lines state, found by the game's sentences for them")
check(not cells(row(panel, 3)):find("Cost") and not cells(row(panel, 3)):find("Range"), "a fact the tooltip does not state has no cell")
check(row(panel, 4).left:find("^Increases") and row(panel, 4).rule and row(panel, 4).prose and row(panel, 4).lr == COLOR.PROSE[1]
    and row(panel, 4).lb == COLOR.PROSE[3], "the description is a row, in the game's gold made lighter; the test realm's line about F6 is left out")
check(row(panel, 5).right == "Racial" and row(panel, 5).font == "small" and row(panel, 5).rule, "a line another addon added is small and apart")
check(not head(panel).accent and row(panel, 1).lr == COLOR.TITLE[1] and COLOR.TITLE[1] < 1, "a white name gives a panel without a colour, and a softer white")
local shown = {}
for index = 1, panel.texts.taken do shown[#shown + 1] = panel.texts[index]._text end
check(shown[1] == "ELUNE'S LIGHT" and shown[3] == "|cff" .. DETAIL_HEX .. "Utility|r  \194\183  Racial" and shown[5] == "CAST" and shown[6] == "Instant"
    and shown[7] == "COOLDOWN" and shown[8] == "3 min",
    "drawn: the name in capitals, then the strip's captions, each over its value")
local function color(label) local r, g, b = label:GetTextColor() return r .. " " .. g .. " " .. b end
check(color(panel.texts[6]) == color(panel.texts[8]) and color(panel.texts[5]) == table.concat(COLOR.CAPTION, " "),
    "the values alike; the captions in the game's gold, darker")
local function size(label) return label.dressed and label.dressed.size end -- the size its font was given
check(size(panel.texts[1]) == 14 and size(panel.texts[9]) == 14 and size(panel.texts[6]) == 12 and size(panel.texts[5]) == 10 and size(panel.texts[11]) == 10,
    "name and lines in the text size, the strip's values two smaller, captions and another addon's lines as small as the game's small font")
check(panel.back._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\soft" and panel.back._points[1][4] == -8 and panel.back._points[2][4] == 8,
    "the panel has no border: its background is a shape with round corners and a soft edge, reaching a little past the panel")
check(colors[1].a == 0.97 and colors[2].a == 0.97 and colors[2].r > colors[1].r, "one gradient behind everything, as solid as the setting says, stronger at the top")
local topR = ns.Mix(COLOR.BACKDROP, COLOR.NEUTRAL, 0.28)
check(math.abs(colors[2].r - topR) < 1e-9 and colors[1].b > colors[1].r,
    "its colours from the game's own tooltip ground: at the top taken toward the panel's colour, at the bottom darker")

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
check(drawn == 1 and count(panel) == 5 and cells(row(panel, 3)) == "Mana 30 (30%), Range 35 yd, Cast 1.5 sec",
    "a spell that hurts: its facts in the order the game writes them, its cost also as a share of all your mana; no cooldown it has not")
check(row(panel, 3).kind == "strip" and row(panel, 4).kind == "strip" and not row(panel, 4).rule and row(panel, 5).rule,
    "under the strip a second one; then a divider")
check(cells(row(panel, 4)) == "DPS 8.2, Damage 21, Per Mana 0.68, Crit 6.2%",
    "what follows from them: per second of its cast, on average, per point of mana, the chance of a critical strike")
check(head(panel).accent and head(panel).ar == 1 and head(panel).ag == 0.5 and head(panel).ab == 0
    and row(panel, 2).left == "|cffff7f00Fire|r  \194\183  Rank 2",
    "a spell of fire has the colour the game's combat log gives fire, and says so under its name")
local described
for index = 1, panel.texts.taken do
    if panel.texts[index]._text == "Hurls a fiery ball that causes |cffff7f0016|r to |cffff7f0025|r Fire damage." then described = panel.texts[index] end
end
check(described, "the digits of its description are in that colour at full strength")
check(described and described._justify == "CENTER" and panel.texts[1]._justify == "LEFT", "the description stands in the middle; the other lines at the left")
spell()
tip:Hide()
spell()
check(drawn == 1 and tip:GetAlpha() == 0 and panel:IsShown(), "filled again with the same lines, nothing is drawn again, not even after it was hidden")
spell("8 sec cooldown")
check(drawn == 2 and cells(row(panel, 3)) == "Mana 30 (30%), Range 35 yd, Cast 1.5 sec, Cooldown 8 sec", "a changed line is")

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
compare()
check(drawn == 3 and count(panel) == 6 and row(panel, 6).font == "small", "lines written after the game told us are in the panel when it is first drawn")
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
check(drawn == 3 and count(panel) == 6 and row(panel, 6).left == "Learned from a trainer", "a line added after the panel was drawn is taken in on the next frame")

-- Lines that are no numbers of a spell stay rows
tip:Fill({ type = TYPE.Spell, id = 75 }, { { "Shoot" }, { "Requires Ranged Weapon" }, { "Shoots.", nil, GOLD, nil, LINE.SpellDescription } })
check(count(panel) == 4 and row(panel, 3).left == "Requires Ranged Weapon" and row(panel, 3).kind == "text",
    "a line that states none of the facts stays a row, and there is no strip (nor one of a shot, without a ranged weapon)")
tip:Fill({ type = TYPE.Spell, id = 2383 }, { { "Find Herbs" }, { "Passive", nil, nil, nil, LINE.SpellPassive }, { "Shows herbs.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left == "|cff" .. DETAIL_HEX .. "Utility|r  \194\183  Passive" and count(panel) == 3, "a passive spell says so under its name")
tip:Fill({ type = TYPE.Spell, id = 1243 }, { { "Renew" }, { "Heals the target of 45 damage over 15 sec.", nil, GOLD, nil, LINE.SpellDescription } })
check(head(panel).ag == COLOR.HEALTH[2] and head(panel).ag > head(panel).ar and row(panel, 2).left:find("Healing") and row(panel, 4).prose,
    "a spell that names no school but heals is green, and says Healing")
check(count(panel) == 4 and row(panel, 3).kind == "strip" and row(panel, 3).rule and cells(row(panel, 3)) == "HPS 3.0, Healing 45, Crit 6.2%",
    "a heal over time: what it heals, per second of its time (not of the global cooldown), your chance with spells; it costs "
    .. "nothing, so no cell for what it does per point of cost, and no strip of facts its tooltip does not state")
UnitDamage, UnitAttackSpeed, GetCritChance = function() return 40, 60 end, function() return 2.5 end, function() return 5 end
W.spells[6603] = { name = "Attack" }
tip:Fill({ type = TYPE.Spell, id = 6603 }, { { "Attack" }, { "Toggles attack.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 3)) == "DPS 20.0, Damage 50, Speed 2.50, Crit 5.0%" and row(panel, 2).left:find("Physical")
    and head(panel).ar == 1 and head(panel).ag == 1 and head(panel).ab == 0,
    "the melee swing: physical, in the combat log's colour for it; its damage per second, on average, its speed, the chance of a critical strike")
tip:Fill({ type = TYPE.Spell, id = 5 }, { { "Inner Fire" }, { "Increases armor by 50 for 10 min.", nil, GOLD, nil, LINE.SpellDescription } })
check(count(panel) == 3 and row(panel, 2).left == "|cff" .. DETAIL_HEX .. "Utility|r", "a spell that neither hurts nor heals has no numbers")
W.spells[853] = { name = "Hammer of Justice" }
tip:Fill({ type = TYPE.Spell, id = 853 }, { { "Hammer of Justice" }, { "Stuns the target for 3 sec.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left:find("CC") and head(panel).ab == 1, "a spell that takes control of the target is CC, in blue")
-- Facts the game writes without a number stand as written; a client's own wording of a sentence is the one read
W.spells[1510] = { name = "Volley" }
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled", "Melee Range" }, { "Rains arrows on the enemy.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 3)) == "Range Melee Range, Cast Channeled", "facts without a number, as the game writes them, in the game's order")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Shot at the next swing" }, { "Rains arrows on the enemy.", nil, GOLD, nil, LINE.SpellDescription } })
check(cells(row(panel, 3)) == "Cast Shot at the next swing", "a fact found by the game's own sentence for it, not by the English one")
-- Where the data gives a line no kind, a sentence in the game's gold is taken for the description
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Rains arrows on all enemies in the area for a while.", nil, GOLD } })
check(row(panel, 4).prose and row(panel, 4).lr == COLOR.PROSE[1], "a gold line of no kind that reads as a sentence is the description")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Reagents: Arrow", nil, GOLD } })
check(count(panel) == 4 and not row(panel, 4).prose, "a short one is none")
tip:Fill({ type = TYPE.Spell, id = 1510 }, { { "Volley" }, { "Channeled" }, { "Rains arrows on all enemies in the area for a while.", nil, GOLD, nil, LINE.QuestTitle } })
check(not row(panel, 4).prose, "nor is a line the data gives another kind")
W.spells[2948] = { name = "Scorch" }
tip:Fill({ type = TYPE.Spell, id = 2948 }, { { "Scorch" }, { "Scorches the enemy for 1.5 sec, causing 12 Fire damage.", nil, GOLD, nil, LINE.SpellDescription } })
local scorched = false
for index = 1, panel.texts.taken do
    if panel.texts[index]._text == "Scorches the enemy for |cffff7f001|r.|cffff7f005|r sec, causing |cffff7f0012|r Fire damage." then scorched = true end
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
check(head(panel).tag == "|cff" .. code(COLOR.RED) .. "BoP|r", "over the name how it binds, short as players write it, red until it is bound")
check(row(panel, 3).font == "big" and row(panel, 3).left == "53.8 |cff" .. DETAIL_HEX .. "DPS|r" and row(panel, 3).rule,
    "a weapon's damage per second, large, under a divider")
check(row(panel, 3).label == "\194\183  44 - 115 dmg  \194\183  1.90 spd" and row(panel, 3).labelFont == "sub",
    "its hit's damage and its speed after it in the same line, smaller")
check(row(panel, 4).left == "+5 Agility" and not row(panel, 4).rule and row(panel, 5).lg == 1 and row(panel, 5).rule, "then its lines; what it does, in green, stands apart")
check(row(panel, 6).kind == "bar" and row(panel, 6).short and row(panel, 6).value == 61 and row(panel, 6).max == 120
    and row(panel, 6).left == "61 / 120" and row(panel, 6).right == "" and row(panel, 6).rule, "at the bottom its durability as a small bar")
check(count(panel) == 7 and row(panel, 7).left == "Vendor" and row(panel, 7).right == "25500c" and row(panel, 7).rule,
    "and under a divider what a vendor pays for it, in coins: alone, without the Gold section's caption and advice")
reaper[3].data.bonding = 3
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(head(panel).tag == "|cff" .. DETAIL_HEX .. "Soulbound|r", "once it is bound to you, that is no longer red")
indexed = true
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
check(count(panel) == 7 and row(panel, 2).left == "Sword \194\183 One-Hand" and head(panel).badge == "iLvl 63", "the same when the game says where each of its lines stands")
table.insert(reaper, 10, { nothing = true, [5] = LINE.SellPrice, price = 25500 })
tip:Fill({ type = TYPE.Item, id = 19019 }, reaper)
table.remove(reaper, 10)
check(count(panel) == 7 and row(panel, 5).left == "Chance on hit: Blasts your enemy with lightning.",
    "a line of the game's data without text takes nothing from the line before it, which has the same index")
indexed = false
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Plans: Gloves", nil, { 0.64, 0.21, 0.93 } }, { "Requires Blacksmithing (80)" },
    { " ", nil, nil, nil, LINE.NestedBlock, data = { tooltipType = TYPE.Item, tooltipID = 19019 } }, { "Veteran's Gloves", nil, GREEN }, { "115 Armor" },
    { " ", nil, nil, nil, LINE.SellPrice, price = 400 } })
check(row(panel, 3).kind == "caption" and row(panel, 3).left == "Creates" and row(panel, 4).left == "Veteran's Gloves" and row(panel, 4).font == "title"
    and row(panel, 4).icon == 2000 + 19019, "a recipe: what it makes under a caption, with that thing's icon")
check(row(panel, 5).left == "115 Armor" and row(panel, 6).left == "Vendor" and row(panel, 6).right == "400c" and row(panel, 6).rule and count(panel) == 6,
    "the thing's lines are left as they are; the price under a divider")

-- The game's line of the price, the look, the auction house (prices noted while you browse it), a trade good
local hatchet = { { "Skull Hatchet", nil, { 0.64, 0.21, 0.93 } }, { "Binds when equipped", nil, nil, nil, LINE.ItemBinding, data = { bonding = 7 } },
    { "Sell Price: 81c", added = true }, { "You haven't collected this appearance", nil, { 0.53, 0.53, 0.93 } },
    { " ", nil, nil, nil, LINE.SellPrice, price = 81 } }
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(head(panel).tag == "|cff" .. code(COLOR.RED) .. "BoE|r  \194\183  |cff8787edUncollected|r", "whether you have its look, short, beside how it binds, in the game's colour for it")
check(count(panel) == 2 and row(panel, 2).left == "Vendor" and row(panel, 2).right == "81c",
    "the game's own line of the price is left out: the panel has a row for it; no auction price before you have seen one")
browse = { { itemKey = { itemID = 19019 }, minPrice = 98765 }, { itemKey = { itemID = 4 }, minPrice = 0 } }
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(ns.store.prices[19019] == 98765 and count(panel) == 5 and row(panel, 2).kind == "caption" and row(panel, 2).left == "Gold"
    and row(panel, 3).left == "Vendor" and row(panel, 4).left == "AH profit" and row(panel, 4).right == "93826c",
    "browsing the auction house, its lowest price is noted and kept in the saved settings; the Gold section says what a sale "
    .. "there brings, after the house's cut of 5%")
check(row(panel, 5).left == "Sell on the AH for 98765c" and row(panel, 5).icon == nil and row(panel, 5).font == "row" and row(panel, 5).lg == COLOR.DONE[2],
    "and in one line, in green, what to do: it brings more there than at a vendor")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(row(panel, 6).left == "Lowest 98765c" and row(panel, 7).left:find("Cut 4938c", 1, true) == 1,
    "with Alt, small under it: the price it comes from, the house's cut and the deposit")
W.alt = false
browse = { { itemKey = { itemID = 19019, itemLevel = 60 }, minPrice = 500 }, { itemKey = { itemID = 19019, itemLevel = 70 }, minPrice = 900 } }
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
check(ns.store.prices[19019] == 500, "an item listed in several rows (its kinds) has the lowest of them as its price")
W.Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", { { itemKey = { itemID = 19019 }, minPrice = 700 } })
check(ns.store.prices[19019] == 500, "also when more rows of the same list come")
ns.store.prices[19019] = 98765
hatchet[2].data.bonding = 6
tip:Fill({ type = TYPE.Item, id = 19019 }, hatchet)
check(count(panel) == 2 and row(panel, 2).left == "Vendor", "a thing that is bound when picked up has no auction price")
ns.store.prices[19019] = nil
C_Item.GetItemInfoInstant = function(id) if id == 2589 then return id, "Trade Goods", "Cloth", "", 1, 7, 5 end end
W.items[2589] = { name = "Linen Cloth", quality = 1 }
W.spells[3908] = { name = "Tailoring" }
local database = ns.QuestFacts
ns.QuestFacts = { quest = {}, npc = {}, item = {} } -- here without the quests that want linen cloth (below: an item's quests)
tip:Fill({ type = TYPE.Item, id = 2589 }, { { "Linen Cloth" }, { " ", nil, nil, nil, LINE.SellPrice, price = 13 } })
ns.QuestFacts = database
check(row(panel, 2).left == "Trade Goods \194\183 Cloth" and row(panel, 2).font == "detail", "a thing that is not worn says what it is")
check(row(panel, 3).kind == "caption" and row(panel, 3).left == "Professions" and row(panel, 4).left == "Used in"
    and row(panel, 4).right == "|T4908:0|t Tailoring" and row(panel, 5).left == "Vendor" and row(panel, 5).rule,
    "a trade good: under the caption Professions, the professions that use it, with their icons")
local named, ruled = panel.left[3], false
for index = 1, panel.lines.taken do
    local line = panel.lines[index]
    if line._points[1][4] == 12 + 6 then ruled = true end -- after the name (here measured 0 wide) and a gap
end
check(named._points[1][4] == 12 and named._justify == "LEFT" and ruled,
    "a section's name stands at the left, and a rule runs on after it")
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
tip:Fill({ type = TYPE.Item, id = 2589 }, { { "Linen Cloth" }, { " ", nil, nil, nil, LINE.SellPrice, price = 13 } })
check(math.abs(hairline() - 3 * pixel) < 1e-9, "and the nearest whole dots elsewhere: three on a 4K screen")
pixel = 1
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Plate", nil, { 0.64, 0.21, 0.93 } }, { "115 Armor" } })
check(row(panel, 2).font == "big" and row(panel, 2).left == "115 Armor", "an armour's number is large too")
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
for _, text in ipairs(panel.texts) do -- texts as wide as their letters, so the plaque's width can be seen
    function text:GetUnboundedStringWidth() return #(self._text or "") * 6 end
end
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
local narrow, plaqueLeft = select(4, panel.plaque:GetPoint(2)) - panel:GetWidth(), select(4, panel.plaque:GetPoint(1)) - panel:GetWidth()
check(row(panel, 5).left == "Target" and row(panel, 5).live == "target" and row(panel, 5).rule, "under a divider: whom it targets")
check(row(panel, 6).kind == "bar" and row(panel, 6).live == "health" and not row(panel, 6).rule, "under that the health bar")
check(row(panel, 7).kind == "bar" and row(panel, 7).live == "power" and row(panel, 7).bb == 1, "and the bar of its mana, in mana's colour")
check(panel.live.health._height == 18 and panel.live.power._height == 5 and panel.live.power._points[1][1] == "BOTTOMLEFT"
    and panel.live.power._points[1][2] == panel.live.health, "the mana lies over the lower part of the health bar, not under it")
check(#inspected == 1 and inspected[1] == "mouseover", "for its item level, the server is asked")
check(row(panel, 8).kind == "auras", "and its buffs")
check(count(panel) == 9 and row(panel, 9).left == "Item Level 61" and row(panel, 9).font == "small" and row(panel, 9).rule,
    "the tooltip's own lines that say the same are left out; another addon's line stays")
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
tick(panel, 0.2)
check(panel.live.healthText._text == "40   83%", "as its current health and its share in percent")
world.mouseovertarget = { player = true, name = "Varian", surname = "Wrynn", level = 60, class = { "Mage", "MAGE" } }
tick(panel, 0.2)
check(panel.live.targetName:GetText() == "Varian Wrynn", "a player as the target by the whole name: first name and surname")
local isUnit = UnitIsUnit
UnitIsUnit = function(a, b) return (a == "mouseovertarget" and b == "player") or a == b end
tick(panel, 0.2)
check(panel.live.targetName:GetText() == "You" and panel.live.targetName:GetTextColor() == COLOR.RED[1]
    and select(2, panel.live.targetName:GetTextColor()) == COLOR.RED[2], "you as its target: the word for you, in the game's red")
UnitIsUnit = isUnit
world.mouseovertarget = { name = "Ragnaros", level = 63 }
tick(panel, 0.2)
-- The mouse has left the player: the game lets the tooltip fade out, and "mouseover" is somebody else
local guidOf = UnitGUID
UnitGUID = function(unit) return unit == "mouseover" and "Player-2" or guidOf(unit) end
UnitHealth = function() return 7 end
world.mouseover.target = false
for _ = 1, 5 do tick(panel, 0.2) end
check(panel.live.healthText._text == "40   83%" and count(panel) == 9 and row(panel, 5).live == "target",
    "once the mouse has left the unit, its panel stands still: no other unit's numbers, no row taken away")
UnitGUID, UnitHealth = guidOf, function() return 40 end
world.mouseover.target = true
-- A text or a bar that was given a number the game hides answers every question about its size
-- with a hidden number, for good. They must never be measured, nor used again for another line.
local hidden = { panel.live.healthText, panel.live.targetName }
for _, label in ipairs(hidden) do
    for _, question in ipairs({ "GetStringWidth", "GetUnboundedStringWidth", "GetStringHeight" }) do
        label[question] = function() error("a text that may hold a hidden number was asked for its size") end
    end
    for index = 1, #panel.texts do check(panel.texts[index] ~= label, "a text for a unit's numbers is not one of the texts that are measured") end
end
for _, bar in ipairs(panel.bars) do check(bar ~= panel.live.health and bar ~= panel.live.power, "a unit's bars are not the bars used for other things") end
check(#panel.auraIcons == 3 and panel.auraIcons[1]._texture == 11 and panel.auraIcons[3]._texture == 13 and panel.auraIcons[3]:IsShown(), "its buffs, then its debuffs, as small icons")
check(panel.auraIcons[1].mask._texture == "Interface\\AddOns\\SaneUI_Tooltips\\Art\\aura-mask", "each with a soft edge")
world.mouseover.target = false
for _ = 1, 5 do tick(panel, 0.2) end
check(count(panel) == 8 and row(panel, 7).kind == "auras", "when it lets go of its target, the row for it goes")
W.combat = true
for _ = 1, 5 do tick(panel, 0.2) end
check(count(panel) == 7 and not panel.auraIcons[1]:IsShown(), "in a fight a unit's buffs cannot be asked for: no row for them")
W.combat = false
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
check(panel.icon._width == 64 and panel.icon._points[1][1] == "TOPRIGHT" and panel.icon._points[1][4] == 10 and panel.icon._points[1][5] == 10,
    "the portrait is large and stands out over the corner, where the dragon covers its edge")
check(row(panel, 3).left == "|cffffd100Elite|r", "under what it is, its rank in the colour of its dragon")
check(row(panel, 4).kind == "bar" and row(panel, 4).live == "health", "its health, and no row for a target or buffs it has not")
check(row(panel, 5).kind == "caption" and row(panel, 5).left == "Quest" and row(panel, 6).left == "The Kobold Menace" and row(panel, 6).lg == 0.82,
    "a section of its own for your quests, under the caption Quest: the quest's name in gold")
check(row(panel, 7).icon == "kill" and row(panel, 7).left == "Kobold slain" and row(panel, 7).right == "4/10"
    and row(panel, 8).icon == "loot" and row(panel, 8).left == "Candle" and row(panel, 8).right == "1/4",
    "a sword before what you must kill it for, a sack before what you must loot, the count at the right")
check(row(panel, 9).left == "Boars and Cats" and row(panel, 10).left == "Rival" and row(panel, 11).left == "Kobold slain" and row(panel, 11).right == "3/5",
    "what is done is left out (the game says so, or its count is full); what is still to do stays")
check(count(panel) == 11, "and a quest with nothing left to do here is left out, its name too")
world.player.level = 4
world.target.class = { "Mage", "MAGE" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 5).left == "137 XP" and row(panel, 5).right == "Next level in 7" and row(panel, 5).font == "sub",
    "what killing it gives you (one level above you, elite: twice) and how many such kills to your next level")
-- The rule's rows: at level 45 a creature fades to nothing 14 levels below you and is grey from 10 below
world.player.level, world.target.level = 45, 36
local gain, kills = ns.Numbers.Experience("target")
check(gain == 193 and kills == 5, "nine levels below you: (45 * 5 + 45) * (1 - 9/14), twice for an elite")
world.target.level = 35
check(ns.Numbers.Experience("target") == nil, "ten levels below you at 45: grey, nothing")
world.target.level, world.player.level = 50, 45
check(ns.Numbers.Experience("target") == math.floor(270 * 1.2 * 2 + 0.5), "above you: 5 % more a level, for four levels at most")
world.player.level, world.target.level = 4, 5
check(row(panel, 2).left == "Humanoid" and row(panel, 3).left == "Mage  \194\183  |cffffd100Elite|r",
    "a creature that is more than a plain fighter says its class, before its rank")
world.target.dead = true
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 3).left == "Mage  \194\183  |cffffd100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Dead|r" and row(panel, 5).left ~= "137 XP",
    "a dead one says so, and gives nothing any more")
world.target.dead = nil
world.target.family, world.target.tapped = "Wolf", true
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "<Tunnel Boss>" }, { "Level 5 Humanoid (Elite)" } })
check(row(panel, 2).left == "<Tunnel Boss>" and row(panel, 2).font == "title" and row(panel, 2).flush and row(panel, 3).left == "Humanoid  \194\183  Wolf",
    "a creature's title as large as its name, close under it; what it is and its family")
check(row(panel, 4).left == "Mage  \194\183  |cffffd100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Tapped|r", "one somebody else has tapped says so")
world.target.family, world.target.tapped = nil, nil
world.target.class = { "Warrior", "WARRIOR" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Bowyer" }, { "Level 5 Humanoid (Elite)" },
    { "Stormwind" }, { "Skinnable" } })
check(row(panel, 2).left == "Bowyer" and row(panel, 2).font == "title" and row(panel, 3).left == "Humanoid  \194\183  Stormwind"
    and row(panel, 4).left == "Warrior  \194\183  |cffffd100Elite|r  \194\183  |cffffffffSkinnable|r",
    "an NPC's title is the line before its level line, its faction the one after it; a hostile creature says its class")
world.target.reaction = 5
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Bowyer" }, { "Level 5 Humanoid (Elite)" } })
check(row(panel, 4).left == "|cffffd100Elite|r", "a friendly one does not")
world.target.reaction = nil
-- The module's own quest facts (Data/Quests.lua), here a few: quest 60 asks for a candle the
-- creature drops (its second objective), it takes quest 61 back and gives 62, 63, 64 and 70
local allFacts = ns.QuestFacts
ns.QuestFacts = { quest = {
    [60] = "1-2;;A;;The Kobold Menace", [61] = "1-3;;;;Report to Gryan",
    [62] = "1-11;;;8;Wanted: Hogger",  -- for mages, as you are
    [63] = "30-35;;;;Far Ahead",       -- too high a level for you
    [64] = "1-3;+65;;;After Another",  -- quest 65 must be done first
    [70] = "1-3;;;;For the Horde",     -- it gives that one to the Horde only (gH70)
}, npc = { [1] = "g62,63,64,H70 t61 dA60.2.33" }, item = {} } -- the candle drops for the Alliance (you), 33% of the time
quests[60] = { on = true, title = "The Kobold Menace",
    objectives = { { text = "4/10 Kobold Vermin slain", finished = false }, { text = "Candle: 1/4", finished = false } } }
quests[61] = { on = true, ready = true, title = "Report to Gryan" }
local askedLog = 0 -- how often the quest log was asked for a quest's objectives
C_QuestLog.GetQuestObjectives = function(id) askedLog = askedLog + 1 return quests[id] and quests[id].objectives end
C_QuestLog.GetTitleForQuestID = function(id) return quests[id] and quests[id].title end
units["Creature-0-1-2-3-1-4"] = "target"
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" },
    { "The Kobold Menace", nil, GOLD, nil, LINE.QuestTitle, data = { id = 60 } }, { "4/10 Kobold Vermin slain", nil, nil, nil, LINE.QuestObjective },
    { "Not ours", added = true } })
check(row(panel, 5).left == "137 XP" and row(panel, 5).rule and row(panel, 6).kind == "caption" and row(panel, 6).left == "Quest"
    and row(panel, 7).left == "The Kobold Menace" and not row(panel, 7).rule,
    "experience, then the quests under the caption Quest")
check(row(panel, 7).right == "Level 2" and row(panel, 7).rr == 1 and row(panel, 7).rb == 0,
    "a quest's name has its level at the right (the game's line says which quest it is), in the colour of how hard it is")
check(row(panel, 8).icon == "kill" and row(panel, 8).left == "Kobold Vermin slain" and row(panel, 8).right == "4/10",
    "the game's objective: a sword before what to kill (it names the creature), the count at the right")
check(row(panel, 9).icon == "loot" and row(panel, 9).left == "Candle" and row(panel, 9).right == "1/4",
    "from our database: what it drops for the same quest, under it, with a sack")
check(row(panel, 9).label == "33%" and row(panel, 8).label == nil, "with how often it drops after its name; nothing after what to kill")
check(panel.after[9] and panel.after[9]._text == "33%" and panel.after[9]:IsShown() and panel.right[9]._text == "1/4",
    "the panel writes the chance after the name, and the count still at the right")
check(row(panel, 10).left == "Report to Gryan" and row(panel, 10).lg == 0.82 and row(panel, 10).right == "Level 3" and row(panel, 11).icon == "active"
    and row(panel, 11).left == "Turn in" and row(panel, 11).lr == COLOR.DONE[1] and row(panel, 11).right == "",
    "a quest of yours it takes back: its name like a quest's with its level, under it Turn in (ready, in green)")
check(row(panel, 12).left == "Wanted: Hogger" and row(panel, 12).right == "Level 11" and row(panel, 13).icon == "available" and row(panel, 13).left == "Offers",
    "a quest it offers you, the same way; not one too far above your level, nor one whose first quest you have not done, "
    .. "nor one it gives the other side only")
check(count(panel) == 14 and row(panel, 14).left == "Not ours" and row(panel, 14).rule, "another addon's line stays, after the section")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(askedLog == 1 and count(panel) == 12, "read again (as a unit frame's tooltip is, many times a second), the quest log is not asked again")
quests[61].ready = false
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(askedLog == 2 and row(panel, 10).left == "In progress", "once the quest log changes, it is")
-- The game's own line for what the database knows it drops: the chance too, and a sack even where
-- the words name the creature
quests[60].objectives[2].text = "Kobold Candle: 1/4"
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" },
    { "The Kobold Menace", nil, GOLD, nil, LINE.QuestTitle }, { " - Kobold Candle: 1/4", nil, nil, nil, LINE.QuestObjective } })
check(row(panel, 8).icon == "loot" and row(panel, 8).left == "Kobold Candle" and row(panel, 8).label == "33%"
    and row(panel, 9).left == "Report to Gryan", "the game's own line for a drop gets its chance and a sack, and is not there twice")
quests[60].objectives[2].text = "Candle: 1/4"
quests[61].ready = true
-- What the game shows grey for your level an NPC does not offer (here grey: more than 2 below you)
local function gives(npc, quest)
    local list = ns.Quests.Of(npc)
    for index = 1, list.n do
        if list[index].kind == "give" and list[index].quest == quest then return true end
    end
    return false
end
ns.QuestFacts.quest[66] = "1;;;;Long Ago"
ns.QuestFacts.npc[1] = "g62,63,64,66,H70 t61 dA60.2.33"
UnitQuestTrivialLevelRange = function() return 2 end
W.Fire("QUEST_LOG_UPDATE")
check(not gives(1, 66) and gives(1, 62), "a quest three levels below you is grey to the game (its range: 2): not offered")
UnitQuestTrivialLevelRange = function() return 3 end
W.Fire("QUEST_LOG_UPDATE")
check(gives(1, 66), "with a wider range it is")
UnitQuestTrivialLevelRange = nil
-- How often, below 1 %
ns.QuestFacts.npc[2] = "d60.2.0"
check(ns.Quests.Of(2).n == 1 and ns.Quests.Of(2)[1].kind == "drop" and ns.Quests.Of(2)[1].extra == "<1", "a chance below 1 % is shown as <1")
ns.QuestFacts.quest[71] = 123 -- a broken record
ns.QuestFacts.npc[1] = "g71,62,63,64,H70 t61 dA60.2.33"
W.Fire("QUEST_LOG_UPDATE")
W.printed = {}
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
check(panel:IsShown() and count(panel) == 10 and row(panel, 7).left == "The Kobold Menace" and row(panel, 8).left == "Candle"
    and row(panel, 9).left == "Report to Gryan", "a broken record ends the list there: what was found before it stays")
check(Core.errors["Tooltips: quest facts"] and #W.printed == 1 and not ns.off, "it is noted and told once")
ns.QuestFacts = { quest = {}, npc = {}, item = {} }
-- A dead creature: the corpse line goes (the class line says Dead), what it yields goes on the class line
world.target.dead, world.target.class = true, { "Kobold", "WARRIOR" }
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" }, { "Corpse" },
    { "Skinnable", nil, { 1, 0.1, 0.1 } } })
check(row(panel, 3).left == "|cffffd100Elite|r  \194\183  |cff" .. ASIDE_HEX .. "Dead|r  \194\183  |cffff1919Skinnable|r" and count(panel) == 4,
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
check(head(panel).dragon == "silver" and row(panel, 3).left == "|cff" .. code(COLOR.SILVER) .. "Rare|r  \194\183  |cffffd100Elite|r",
    "a rare elite: the silver dragon, and both of its words, each in its dragon's colour")
world.target.kind = "elite"

-- A live 3D portrait (the option models): the game's model of the unit, in the portrait's place --
local given = {} -- the units a model was given
W.methods.SetUnit = function(self, unit) given[#given + 1] = unit; return not unitOf(unit).far end
W.methods.SetPortraitZoom = function(self, zoom) self._zoom = zoom end
W.methods.SetParent = function(self, parent) self._parent = parent end
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
figure:Hide() -- with its panel
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(#given == asked + 1 and figure:IsShown(), "once hidden, it forgets the unit, and is given it again when shown")
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" }, { "Epic" } })
check(not figure:IsShown() and panel.icon:IsShown(), "an item has its icon, no model")
world.target.far = true -- out of sight: the game cannot draw its model
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(not figure:IsShown() and panel.icon:IsShown() and panel.icon.portrait == "target", "where the game cannot draw the model, the flat picture")
world.target.far = nil
options.models = false
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(not figure:IsShown() and panel.icon:IsShown() and #given == asked + 2, "switched off: the flat picture, and no model is asked for")
options.models, options.show = true, "shift"
panel.drawn = false
tip:Fill({ type = TYPE.Unit, guid = "Creature-1" }, kobold)
check(figure:IsShown() and figure:GetAlpha() == 0 and panel:GetAlpha() == 0, "unseen until Shift is held, the model too (by itself)")
W.shift = true
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(figure:GetAlpha() == 1 and panel:GetAlpha() == 1, "and seen with its panel")
W.shift, options.show = false, "always"
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
W.methods.SetUnit = nil -- the units below have the flat picture again
figure:Hide()

-- An item's quests, and the quests items start (the module's quest facts) ---------------------
ns.QuestFacts = { quest = { [60] = "1-2;;A;;The Kobold Menace", [80] = "1-55;;;;A Letter",
    [90] = "1-5;;;;Candles for Gryan", -- done long ago
    [91] = "62;;;;Wax Works",          -- for later: from level 62
    [92] = "1-10;;;2;Holy Candles",    -- for paladins only: not yours
    [93] = "1-58;;;;Candle Light" },   -- you can take it
    -- the candle is wanted by quest 60's second objective and by four more; the letter starts quest 80
    item = { [772] = "n60.2,90.1,91.1,92.1,93.1", [5000] = "b80" },
    npc = { [1] = "s5000.80.3" } }     -- the kobold drops the letter, 3% of the time
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].numRequired = 1, 4
quests[90] = { done = true }
local flagged = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = function(id) return quests[id] and quests[id].done or false end
W.items[772], W.items[5000] = { name = "Candle", quality = 1 }, { name = "Dusty Letter", quality = 1 }
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
check(row(panel, 3).kind == "caption" and row(panel, 3).left == "Quest" and row(panel, 4).left == "Needed for" and row(panel, 4).font == "small"
    and row(panel, 4).right == "Questlog", "an item quests want: a section of its own under the caption Quest; Questlog over where you stand")
check(row(panel, 5).left == "The Kobold Menace" and row(panel, 5).icon == "active" and row(panel, 5).label == "[2]" and row(panel, 5).lg == 0.82
    and row(panel, 5).right == "In log  1/4" and row(panel, 5).rg == 0.82,
    "first the quest in your log: the ?, its name in gold, its level, In log and your count")
check(row(panel, 6).left == "Candle Light" and row(panel, 6).icon == "available" and row(panel, 6).right == "Available"
    and row(panel, 7).left == "Wax Works" and row(panel, 7).icon == nil and row(panel, 7).right == "Not yet" and row(panel, 7).lr == COLOR.DETAIL[1]
    and row(panel, 8).left == "Candles for Gryan" and row(panel, 8).icon == "check" and row(panel, 8).right == "Done" and row(panel, 8).rg == COLOR.DONE[2],
    "then one you can take (the !), one for later (dim), one you have done (a tick, Done in green); not one for another class")
check(count(panel) == 8, "and nothing else")
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].finished = 4, true
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
check(row(panel, 5).right == "In log  4/4" and row(panel, 5).rg == COLOR.DONE[2], "the count green once the objective is complete")
quests[60].objectives[2].numFulfilled, quests[60].objectives[2].finished = 1, false
ns.QuestFacts.item[772] = "n60.2,90.1,91.1,93.1,94.1,95.1"
ns.QuestFacts.quest[94], ns.QuestFacts.quest[95] = "1-58;;;;One More", "1-58;;;;And Another"
W.Fire("QUEST_LOG_UPDATE")
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
local more = row(panel, count(panel))
check(more.left == "Press ALT for +2 more" and more.font == "small" and row(panel, 8).left == "And Another",
    "of the quests not in your log three, and how many more Alt shows")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 772 }, { { "Candle" }, { "Quest Item" } })
check(row(panel, 10).left == "Candles for Gryan" and count(panel) == 11, "with Alt all of them (and the details under them)")
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
-- Quests of the same name (the same quest at other places) come once; a quest for one race
local facts = ns.QuestFacts
facts.quest[96], facts.quest[97], facts.quest[98], facts.quest[99] = "1-58;;;;Candle Light", "1-20;;95;;High Above",
    "1-20;;1.3;;Old Kingdoms", "1-20;;A;;For the Alliance"
facts.item[773] = "n93.1,96.1,97.1,98.1,99.1"
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
facts.item[773] = nil
ns.QuestFacts.item[772] = "n60.2"
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
-- A creature that drops an item that starts a quest you can take
tip:Fill({ type = TYPE.Unit, guid = "Creature-0-1-2-3-1-4" }, { { "Kobold", nil, { 1, 0.1, 0.1 } }, { "Level 5 Humanoid (Elite)" } })
local letter
for index = 1, count(panel) do if row(panel, index).left == "Dusty Letter" then letter = index end end
check(letter and row(panel, letter - 1).left == "A Letter" and row(panel, letter - 1).right == "Level 55" and row(panel, letter).icon == "available"
    and row(panel, letter).label == "3%" and row(panel, letter).right == "Starts the quest",
    "a creature that drops an item that starts a quest you can take: the quest and its level, the item with the ! and how often it drops")
ns.QuestFacts = { quest = {}, npc = {}, item = {} }
W.Fire("ADDON_LOADED", "Nothing")

-- A buff -------------------------------------------------------------------------------------
auras.player = { HELPFUL = { { isHelpful = true, dispelName = "Magic", duration = 1800, expirationTime = W.clock + 1000, sourceUnit = "mouseover", auraInstanceID = 7 } } }
tip.info = { getterName = "GetUnitBuff", getterArgs = { "player", 1 } }
local fortitude = { { "Power Word: Fortitude" }, { "Increases Stamina by 26.", nil, GOLD, nil, LINE.SpellDescription }, { "17 minutes remaining" } }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, fortitude)
check(row(panel, 1).caps and row(panel, 2).left == "Buff  \194\183  Magic" and head(panel).ab == 1 and head(panel).icon == 1000 + 1243, "a buff: what it is under its name, in blue")
check(row(panel, 3).prose and row(panel, 3).rule, "its description")
check(count(panel) == 4 and row(panel, 4).kind == "bar" and row(panel, 4).live == "aura" and row(panel, 4).rule and head(panel).auraID == 7
    and panel.live.auraEnds == W.clock + 1000, "then a bar that runs out with it")
local timer = panel.live.aura
check(timer._height == 18 and timer.texts.LEFT._text == "17 minutes remaining" and timer.texts.RIGHT._text == "by Jaina Proudmoore" and timer.texts.LEFT:GetParent():GetParent() == timer,
    "inside it, the game's line for how long it still runs, and who cast it (first name and surname)")
check(panel.barMask._points[1][5] == select(5, timer:GetPoint(1)), "with round corners, like a unit's bars")

-- Another addon's ID line, among the buff's own lines and after them
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Power Word: Fortitude" }, { "Spell ID: 1459", nil, GOLD, nil, 0, added = true },
    { "Increases Stamina by 26.", nil, GOLD, nil, LINE.SpellDescription }, { "17 minutes remaining" }, { "IconID", "135932", nil, nil, 0, added = true } })
check(count(panel) == 4 and row(panel, 3).left == "Increases Stamina by 26." and panel.live.aura.texts.LEFT._text == "17 minutes remaining",
    "another addon's ID lines are left out (Alt shows the numbers), and the time is still found for the bar")
check(ns.Reader.IsIdLine({ left = "|TInterface\\Icons\\X:0|t |cffffd100Spell ID:|r", right = "|Hspell:1459|h1459|h" })
    and not ns.Reader.IsIdLine({ left = "|cffffd100Spell ID|r is a word", right = "" }),
    "an ID line is known also with colours, links and icons in it; a line that only names an ID is none")

-- Alt held: the technical details
W.alt = true
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 1)
check(count(panel) == 5 and row(panel, 5).font == "small" and row(panel, 5).rule and row(panel, 5).left == "Spell ID: 1243" and row(panel, 5).right == "Icon ID: 2243",
    "with Alt held a tooltip has its technical details at the bottom, small: the spell's number at the left, its icon's at the right")
W.alt = false
W.Fire("MODIFIER_STATE_CHANGED", "LALT", 0)
check(count(panel) == 4, "let go, they are gone")
W.Fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(count(panel) == 4, "(another key changes nothing)")
auras.player.HELPFUL[1] = { isHarmful = true, dispelName = "Magic", duration = 0, auraInstanceID = 8 }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Polymorph" }, { "Cannot attack or cast spells.", nil, GOLD, nil, LINE.SpellDescription } })
check(row(panel, 2).left == "Debuff  \194\183  Magic" and head(panel).ag == 0.6 and count(panel) == 3, "a debuff has the colour of its kind; without a time, no bar")
auras.player.HARMFUL = { { isHarmful = true, duration = 0, auraInstanceID = 9 } }
tip.info = { getterName = "GetUnitDebuffByAuraInstanceID", getterArgs = { "player", 9 } }
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, { { "Curse of Nothing" } })
check(row(panel, 2).left == "Debuff" and head(panel).ar == 0.8 and head(panel).ag == 0 and head(panel).ab == 0,
    "a debuff the game names by its own number is found by it; nothing takes it away: the game's colour for that")
auras.player.HARMFUL = nil
tip.info = nil
tip:Fill({ type = TYPE.UnitAura, id = 1243 }, fortitude)
check(count(panel) == 3 and not head(panel).accent and panel:IsShown(), "a buff the game says nothing more about still gets its name and lines")
W.alt = true
tip:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury" } })
check(row(panel, 2).left == "Item ID: 19019" and row(panel, 2).right == "Icon ID: 21019", "an item's: its number and its icon's")
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
check(row(panel, 3).left == "Bring their paws to Eagan." and row(panel, 3).rule and row(panel, 4).kind == "caption" and row(panel, 4).left == "Objectives",
    "what it says, then what there is to do under a caption")
check(row(panel, 5).left == "Tough Wolf Meat" and row(panel, 5).right == "8/8" and row(panel, 5).icon == "check" and row(panel, 5).lg == COLOR.DONE[2],
    "a thing that is done: ticked and green, its count at the right")
check(row(panel, 6).left == "Wolf Paw" and row(panel, 6).right == "3/8" and row(panel, 6).icon == "box" and count(panel) == 6, "a thing still to do: an empty box")
quests[77].ready = true
tip:Fill({ type = TYPE.Quest, id = 77 }, { { "Wolves Across the Border", nil, GOLD } })
check(row(panel, 2).label == "\194\183  Ready to turn in" and count(panel) == 2, "ready to hand in, it says so")

-- Anything else
tip:Fill({ type = TYPE.Object, id = 1 }, { { "Mithril Deposit", nil, GOLD }, { "Requires Mining 175", nil, { 1, 0.1, 0.1 } }, { " " }, { "Gathered here 12 times", nil, nil, nil, 0, added = true } })
check(row(panel, 1).caps and not head(panel).accent and row(panel, 2).lr == 1 and row(panel, 2).rule and row(panel, 3).font == "small" and count(panel) == 3,
    "any other kind (a mailbox, a herb): its name, its lines in their colours, an empty line being a divider; a panel without "
    .. "a colour of its own, whatever colour its name has")
local plainR, plainG = ns.Mix(COLOR.BACKDROP, COLOR.NEUTRAL, 0.28)
check(math.abs(colors[2].r - plainR) < 1e-9 and math.abs(colors[2].g - plainG) < 1e-9, "its background the same as a dead unit's")

-- Lines somebody wrote in: a button's hint -------------------------------------------------------
tip:Hide()
check(not panel:IsShown() and tip:GetAlpha() == 1 and tip.left[1]:GetAlpha() == 1, "a hidden tooltip takes its panel with it and is visible again, its lines too")
check(#panel._points == 0, "and the panel hangs on nothing any more (so no other panel can come to hang on it the wrong way round)")
tip:Fill(nil, { { "Close", nil, GOLD } })
check(panel:IsShown() and tip:GetAlpha() == 0 and count(panel) == 1 and row(panel, 1).left == "Close" and not row(panel, 1).caps,
    "a tooltip somebody wrote lines into gets a panel too, its lines as they are written")
spell()
check(panel:IsShown() and cells(row(panel, 3)):find("Mana 30 (30%)", 1, true) == 1, "(a spell again)")
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
check(tip.left[1]:GetAlpha() == 1, "once the game hides it, its parts are given back")
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
check(head(worn).tag == "|cffffd100EQUIPPED|r" and worn.texts[1]._text == "|cffffd100EQUIPPED|r" and worn.texts[2]._text == "Thunderfury",
    "what you wear says so at its top, inside the panel, where another item says how it binds")
check(worn:GetAlpha() == 0.85, "and stands back a little")
shopping:Fill({ type = TYPE.Item, id = 19019 }, { { "Thunderfury", nil, { 0.64, 0.21, 0.93 } }, { "Binds when picked up", nil, nil, nil, LINE.ItemBinding, data = { bonding = 3 } },
    { "", added = true }, { "If you replace this item, the following stat changes will occur:", nil, GOLD, added = true },
    { "|cff00ff00+2.2|r damage per second", added = true }, { "+3 Stamina", added = true } })
check(head(worn).tag == "|cffffd100EQUIPPED|r" and count(worn) == 3 and row(worn, 2).left == "|cff00ff00+2.2|r DPS" and row(worn, 2).font == "row"
    and row(worn, 2).rule and row(worn, 3).left == "+3 Stamina" and row(worn, 3).font == "row",
    "a comparison's changes without the sentence over them, as the game's own lines, damage per second short")

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
check(not pinned:IsShown() and not stuck:IsShown(), "a click on it closes it, as the game's X does")
check(pinned._hit[1] == 0 and pinned._hit[3] == 0 and pinned.CloseButton._mouse == true, "and the tooltip's area for the mouse and its X are the game's again")
pinned:ClearAllPoints()
pinned:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10) -- dragged somewhere, the last time
pinned:Fill({ type = TYPE.Item, id = 19019 }, THUNDERFURY)
check(#pinned._points == 1 and pinned._points[1][1] == "CENTER" and stuck:IsShown(), "opened again, it is in the middle again")
pinned:Hide()

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

-- A failure: the game's own tooltips are back ------------------------------------------------------
spell()
check(panel:IsShown() and tip:GetAlpha() == 0, "(a panel once more)")
-- A live value that fails (a unit the game does not let us ask about) stands nothing down
tip:Fill({ type = TYPE.Unit, guid = "Player-1" }, jaina)
local health = UnitHealth
UnitHealth = function() error("not for addons") end
tick(panel, 1)
tick(panel, 1)
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
