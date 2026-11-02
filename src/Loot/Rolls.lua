local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Rolls
--  When your group rolls for a thing (START_LOOT_ROLL), a card that is one
--  line of the loot window (Row.lua; Saneroki, 2026-11-02: the same design): a
--  bar as the nameplates' in the thing's quality colour, its picture at the
--  bar's end, its name; no A, no line under the name. At the bar's right end,
--  nearly as tall as all of it and over the time, the choices the game offers,
--  its own icons with no words (Need; Greed, or Transmog where the game offers
--  that; Disenchant where it does; Pass), a choice the game refuses faint and
--  grey with its reason in the tooltip; in front of them, as tall, the game's
--  green arrow on an upgrade (Saneroki, 2026-11-02: Core.Upgrade, the window's
--  small arrow made big, which it stands in for here). Over
--  the bar's foot the time left, a line as a nameplate's resource on its
--  health, running down, green at first and redder towards nothing, with the
--  seconds left on it. The cards stack up from where Edit Mode placed them, the
--  oldest at the foot, as near as the window's lines.
--
--  Who chose what: the game says it in its own lines (Chat.Rolled); each
--  choice counts them, a number on its icon. The mouse on the line or on an
--  icon lists them by choice and who of the group has still to roll (Saneroki,
--  2026-11-02), the list as it is now while the mouse stays. Those the game
--  tells apart only by its lines: everyone online counts as still to roll,
--  also one too far away to be asked. A choice of the game's to confirm (one
--  that binds) is its own question.
--
--  A card's three stages: open; closed, the player's part over (CANCEL_LOOT_ROLL:
--  chosen, or out of time) while the others may still choose: the whole card
--  faded to WAITING, so it can be ignored (Saneroki, 2026-11-02), the icons
--  faint but the one chosen, the time running on by the card's own clock;
--  gone-to-be, the game has said who got the thing (Chat.Rolled, "won" or
--  "none"): whole again, the icons and the time away, the winner at the bar's
--  right end for HOLD seconds. Said by nobody, a card goes LATE seconds after
--  its time.
--
--      Rolls.Start(), Rolls.Refresh()   -- the cards as the game's rolls are now
--      Rolls.Try()                      -- a card to look at (/sane loot try)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local S = ns.SIZE
local Rolls = {}
ns.Rolls = Rolls

local PASS, NEED, GREED, DISENCHANT, TRANSMOG = 0, 1, 2, 3, 4
local WORDS = { [PASS] = "pass", [NEED] = "need", [GREED] = "greed", [DISENCHANT] = "disenchant", [TRANSMOG] = "transmog" }
local ORDER = { NEED, GREED, TRANSMOG, DISENCHANT, PASS } -- as the choices stand on a card
local BY_WORD = {}
for kind, word in pairs(WORDS) do BY_WORD[word] = kind end
local TRY = 20 -- seconds a tried card stands
local TICK = 0.1
local HOLD = 5 -- seconds a card stands with who got the thing
local LATE = 5 -- seconds after its time a card waits for the game to say it; then it goes
local WAITING = 0.25 -- how much of a card shows while nothing is asked of the player
local FAINT = 0.35 -- a refused choice, as the game's (GroupLootFrame_DisableLootButton)
local ICON = "lootroll-toast-icon-%s-%s" -- the game's roll buttons: its atlases by the word of WORDS
local BETTER = S.better * 20 / 22 -- the big green arrow's width: the game's atlas is 20 by 22

local holder, placed
local cards = {}   -- shown, the oldest first
local spare = {}   -- made, not in use
local since = 0

-- An item's own part of its link, to tell one thing's lines from another's.
local function Key(link)
    return type(link) == "string" and link:match("item[%-?%d:]+") or link
end

-- Each icon on show of a card.
local function Icons(card, fn)
    for _, button in ipairs(card.choices) do
        if button:IsShown() then fn(button) end
    end
end

-------------------------------------------------------------------------------
--  A card
-------------------------------------------------------------------------------
-- Whether a name as the game's line gives it is that player's: the whole name (two players can share a first name),
-- with a realm ("Thrall-Draenor"), or only the first name.
local function Named(who, full, first)
    local bare = who:match("^[^%-]+") or who
    return who == full or bare == full or bare == first
end

-- The group's units, the player among them (a raid's list holds the player, a party's does not).
local function Group()
    local raid = IsInRaid()
    local units = raid and {} or { "player" }
    local count = Plain(raid and GetNumGroupMembers() or GetNumSubgroupMembers()) or 0
    for index = 1, count do units[#units + 1] = (raid and "raid" or "party") .. index end
    return units
end

-- Who of the group, online, has no line about this roll yet, by name.
local function Waiting(card)
    local names = {}
    for _, unit in ipairs(Group()) do
        local full, first = Core.FullName(unit), Core.Ask(UnitName, unit)
        local waits = full ~= nil and Plain(UnitIsConnected(unit))
        for _, chosen in pairs(card.chose) do
            for who in pairs(chosen) do
                if waits and Named(who, full, first) then waits = false end
            end
        end
        if waits then names[#names + 1] = full end
    end
    return names
end

-- One group of names in a tooltip: its word and how many, then the names; nothing when there are none.
local function Names(word, names)
    if #names == 0 then return end
    table.sort(names)
    GameTooltip:AddLine(("%s (%d)"):format(word, #names), 1, 1, 1)
    GameTooltip:AddLine(table.concat(names, ", "), 0.85, 0.85, 0.85, true)
end

-- Who chose what, then who has still to roll (nobody, once the roll is over).
local function Who(card)
    if not ns.options.tally then return end
    for _, kind in ipairs(ORDER) do
        local names = {}
        for name in pairs(card.chose[kind] or {}) do names[#names + 1] = name end
        Names(ns.TEXT[WORDS[kind]], names)
    end
    if not card.gone then Names(ns.TEXT.stillToRoll, Waiting(card)) end
end

local function ChoiceTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(button.word)
    if button.reason then GameTooltip:AddLine(button.reason, 1, 0.3, 0.3, true) end
    Who(button.card)
    GameTooltip:Show()
end

local function Choose(button)
    local card = button.card
    if button.reason or card.closed or card.sample or not card.rollID then return end
    RollOnLoot(card.rollID, button.kind)
end

-- An icon on the line: the game's, how many chose it on it; refused it still takes the mouse for its reason.
local function Choice(card)
    local button = CreateFrame("Button", nil, card.row)
    button:SetSize(S.choice, S.choice)
    button:SetFrameLevel(card.time:GetFrameLevel() + 1) -- over the time
    button:SetMotionScriptsWhileDisabled(true)
    button.card = card
    button.count = button:CreateFontString(nil, "OVERLAY")
    ns.Row.Font(button.count, 16)
    button.count:SetTextColor(1, 1, 1)
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 1)
    button:SetScript("OnClick", ns.Guard(Choose))
    button:SetScript("OnEnter", ns.Guard(ChoiceTip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- The choice's icon, as the game shows its buttons: pushed and lit by the mouse; refused, faint and grey, and so
-- every one but the player's own once the player's part is over.
local function Icon(button)
    local card, word = button.card, WORDS[button.kind]
    local off = button.reason or (card.closed and button.kind ~= card.picked)
    button:SetNormalAtlas(ICON:format(word, "up"))
    button:SetPushedAtlas(ICON:format(word, "down"))
    button:SetHighlightAtlas(ICON:format(word, "highlight"), "ADD")
    button:SetEnabled(not (button.reason or card.closed))
    button:SetAlpha(off and FAINT or 1)
    button:GetNormalTexture():SetDesaturated(off and true or false)
end

local function ThingTip(row)
    local card = row.card
    row.bar:SetLit(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if card.rollID and not card.sample and not card.closed and GameTooltip.SetLootRollItem then
        GameTooltip:SetLootRollItem(card.rollID)
    elseif card.link then
        GameTooltip:SetHyperlink(card.link)
    else
        GameTooltip:SetText(row.name:GetText() or "")
    end
    if row.line then ns.Row.Upgrade(row.line) end
    Who(card)
    GameTooltip:Show()
end

-- A tooltip of this card on show again, as the roll is now.
local function Retip(card)
    if GameTooltip:IsOwned(card.row) then return ThingTip(card.row) end
    for _, button in ipairs(card.choices) do
        if GameTooltip:IsOwned(button) then return ChoiceTip(button) end
    end
end

local function ThingUntip(row)
    row.bar:SetLit(false)
    GameTooltip_Hide()
end

-- A modified click on the line links the thing or tries it on, as anywhere in the game.
local function ThingClick(row)
    local card = row.card
    if card.link and IsModifiedClick() then HandleModifiedItemClick(card.link) end
end

local function NewCard()
    local card = CreateFrame("Frame", nil, holder)
    card:SetSize(S.roll, S.row)
    card.row = ns.Row.New(card)
    card.row.card, card.row.noAuto, card.row.noArrow = card, true, true
    card.row:SetPoint("TOPLEFT", card, "TOPLEFT")
    card.row:SetPoint("TOPRIGHT", card, "TOPRIGHT")
    card.row:SetScript("OnEnter", ns.Guard(ThingTip))
    card.row:SetScript("OnLeave", ns.Guard(ThingUntip))
    card.row:SetScript("OnClick", ns.Guard(ThingClick))
    card.time = ns.Row.Time(card.row)
    -- on the time's frame: over the time as the icons are, and gone with it when the result shows
    card.better = card.time:CreateTexture(nil, "OVERLAY")
    card.better:SetAtlas("bags-greenarrow")
    card.better:SetSize(BETTER, S.better)
    card.winner = card.row:CreateFontString(nil, "OVERLAY")
    ns.Row.Font(card.winner, 18)
    card.winner:SetPoint("RIGHT", card.row, "RIGHT", -S.row / 4, 0)
    card.choices = {}
    card.chose = {}
    return card
end

-- The choices the game offers for the thing, in their order: Need, Greed (or Transmog), Disenchant, Pass.
local function Offered(info)
    local function Reason(n)
        return n and n ~= 0 and Core.Word("LOOT_ROLL_INELIGIBLE_REASON" .. n, nil) or nil
    end
    local list = { { NEED, ns.TEXT.need, not info.canNeed and (Reason(info.reasonNeed) or "") or nil } }
    if info.canTransmog then
        list[#list + 1] = { TRANSMOG, ns.TEXT.transmog }
    else
        list[#list + 1] = { GREED, ns.TEXT.greed, not info.canGreed and (Reason(info.reasonGreed) or "") or nil }
    end
    if info.canDisenchant then list[#list + 1] = { DISENCHANT, ns.TEXT.disenchant } end
    list[#list + 1] = { PASS, ns.TEXT.pass }
    return list
end

local function Count(button)
    local count = 0
    for _ in pairs(button.card.chose[button.kind] or {}) do count = count + 1 end
    button.count:SetText(ns.options.tally and count > 0 and tostring(count) or "")
end

local function Dress(card, info)
    local offered = Offered(info)
    local step = S.choice + S.rowGap
    card.better:SetShown(info.upgrade ~= nil)
    card.better:ClearAllPoints()
    card.better:SetPoint("RIGHT", card.row, "RIGHT", -S.pad - #offered * step, 0)
    card.row.room = #offered * step + (info.upgrade and BETTER + S.rowGap or 0)
    card.row.lift = S.lift
    ns.Row.Set(card.row, info, false, false)
    card.link = info.link
    for index, entry in ipairs(offered) do
        local button = card.choices[index] or Choice(card)
        card.choices[index] = button
        button.kind, button.word, button.reason = entry[1], entry[2], entry[3]
        if button.reason == "" then button.reason = ns.TEXT.locked end
        button:ClearAllPoints()
        button:SetPoint("RIGHT", card.row, "RIGHT", -S.pad - (#offered - index) * step, 0)
        Icon(button)
        Count(button)
        button:Show()
    end
    for index = #offered + 1, #card.choices do card.choices[index]:Hide() end
end

-------------------------------------------------------------------------------
--  The stack
-------------------------------------------------------------------------------
local function Stack()
    for index, card in ipairs(cards) do
        card:ClearAllPoints()
        card:SetPoint("BOTTOM", holder, "BOTTOM", 0, (index - 1) * (S.row + S.rowGap))
    end
end

-- The roll is over: the choices and the time go, and who got the thing stands at the bar's right end for a while.
local function Finish(card, who, own)
    card.closed, card.gone = true, GetTime() + HOLD
    card:SetAlpha(1)
    card.time:Hide()
    for _, button in ipairs(card.choices) do button:Hide() end
    card.winner:SetText(who)
    if own then card.winner:SetTextColor(ns.Row.Gold()) else card.winner:SetTextColor(1, 1, 1) end
    card.winner:Show()
    card.row.room, card.row.lift = (tonumber(card.winner:GetStringWidth()) or 0) + S.gap, 0
    ns.Row.Set(card.row, card.row.line, false, false)
end

-- The seconds left on a card: the game's while the roll is the player's, then by the card's own clock.
local function Left(card, now)
    local left = not card.sample and not card.closed and Plain(GetLootRollTimeLeft(card.rollID))
    if left then card.ends = now + left / 1000 end
    return math.max(0, card.ends - now)
end

-- The time left on each card, its bar as long as the share of it; a card whose time has come goes (a tried one says
-- who got it first, and stands while Edit Mode is open).
local function Tick(_, elapsed)
    since = since + elapsed
    if since < TICK then return end
    since = 0
    local now = GetTime()
    for index = #cards, 1, -1 do
        local card = cards[index]
        if not card.gone then
            local left = Left(card, now)
            card.time:Left(card.total > 0 and math.min(1, left * 1000 / card.total) or 0, left)
        end
        if not (card.sample and Core.EditMode.active) then
            if card.sample and not card.gone and now >= card.ends then
                Finish(card, "Saneroki", true)
            elseif now >= (card.gone or card.ends + LATE) then
                Rolls.Remove(nil, card)
            end
        end
    end
end

local function Card()
    local card = table.remove(spare) or NewCard()
    wipe(card.chose)
    card.sample, card.rollID, card.total, card.ends = nil, nil, nil, nil
    card.closed, card.picked, card.gone = nil, nil, nil
    card:SetAlpha(1)
    card.time:Show()
    card.winner:Hide()
    cards[#cards + 1] = card
    card:Show()
    holder:Show()
    Stack()
    return card
end

-- What the game says of a roll's thing, as a line of the window with what may be chosen; nil once the roll is gone.
-- known: the game knows the item by now (else a moment later: Told).
local function Info(rollID)
    local icon, name, count, quality, _, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, _, _, canTransmog =
        GetLootRollItemInfo(rollID)
    name = Plain(name)
    if not name then return nil end
    local line = { kind = "item", icon = Plain(icon), name = name, count = Plain(count) or 1,
                   quality = Plain(quality) or 1, locked = false, canNeed = Plain(canNeed), canGreed = Plain(canGreed),
                   canDisenchant = Plain(canDisenchant), canTransmog = Plain(canTransmog),
                   reasonNeed = Plain(reasonNeed), reasonGreed = Plain(reasonGreed),
                   link = Plain(GetLootRollItemLink(rollID)) }
    line.known = ns.Slots.Facts(line)
    return line
end

local function Find(rollID)
    for index, card in ipairs(cards) do
        if card.rollID == rollID then return index, card end
    end
    return nil
end

function Rolls.Add(rollID, total)
    if not ns.Game.Rolls() or Find(rollID) then return end
    local info = Info(rollID)
    if not info then return end
    local card = Card()
    card.rollID, card.total = rollID, Plain(total) or 60000
    card.ends = GetTime() + card.total / 1000
    Dress(card, info)
    since = TICK
end

-- A roll's card away (by its roll, or the card itself: a tried one).
function Rolls.Remove(rollID, card)
    local index
    for i, shown in ipairs(cards) do
        if (card and shown == card) or (not card and shown.rollID == rollID) then index = i end
    end
    if not index then return end
    local gone = table.remove(cards, index)
    gone:Hide()
    spare[#spare + 1] = gone
    if #cards == 0 then holder:Hide() end
    Stack()
end

local function RemoveAll()
    for index = #cards, 1, -1 do Rolls.Remove(nil, cards[index]) end
end

-- The player's part is over (chosen, or out of time): the card waits for the others.
local function Over(rollID)
    local _, card = Find(rollID)
    if not card or card.closed then return end
    card.closed = true
    card:SetAlpha(WAITING)
    Icons(card, Icon)
end

-- The first card of that thing that has not been told its end, and that fits.
local function First(key, fits)
    for _, card in ipairs(cards) do
        if Key(card.link) == key and not card.gone and fits(card) then return card end
    end
    return nil
end

-- A chooser on a card.
local function Chose(card, kind, who)
    card.chose[kind] = card.chose[kind] or {}
    card.chose[kind][who] = true
    Icons(card, Count)
end

-- The game's line about a roll, on the card of that thing. Who got it, or everyone passed: the card shows it. The
-- player's own choice: counted, its icon stays lit. Another's: counted, on the first card whose chooser has not
-- chosen yet.
local function Heard(text)
    local found, who, choice, link = ns.Chat.Rolled(text)
    if not found then return end
    local key, kind = Key(link), BY_WORD[choice]
    local own = who == nil or who == ns.TEXT.you
    local card
    if choice == "won" or choice == "none" then
        card = First(key, function() return true end)
        if card and choice == "none" then Finish(card, ns.TEXT.allPassed)
        elseif card then Finish(card, who or ns.TEXT.you, own) end
    elseif kind and own then
        card = First(key, function(candidate) return candidate.picked == nil end)
        if card then
            card.picked = kind
            Chose(card, kind, Core.FullName("player") or ns.TEXT.you)
            Icons(card, Icon)
        end
    elseif kind then
        card = First(key, function(candidate)
            for _, names in pairs(candidate.chose) do
                if names[who] then return false end
            end
            return true
        end)
        if card then Chose(card, kind, who) end
    end
    if card then Retip(card) end
end

-- The game has told an item: a card that waited on it gets what it lacked (the green arrow, the line under the name).
local function Told()
    for _, card in ipairs(cards) do
        if not card.sample and not card.closed and not card.row.line.known then
            local info = Info(card.rollID)
            if info and info.known then Dress(card, info) end
        end
    end
end

-- The cards as the game's rolls are now: every roll it has open gets one while ours are chosen; none else.
function Rolls.Refresh()
    if not holder then return end
    if not ns.Game.Rolls() then return RemoveAll() end
    local ids = rawget(_G, "GetActiveLootRollIDs") and GetActiveLootRollIDs() or {}
    local duration = rawget(_G, "C_Loot") and C_Loot.GetLootRollDuration
    for _, rollID in ipairs(ids) do
        Rolls.Add(rollID, duration and Core.Ask(duration, rollID) or nil)
    end
end

-- A card as a roll will look (/sane loot try; Edit Mode).
function Rolls.Try()
    if not holder then return end
    local card = Card()
    card.sample, card.rollID, card.total, card.ends = true, -#cards, TRY * 1000, GetTime() + TRY
    Dress(card, { kind = "item", icon = "Interface\\Icons\\INV_Misc_QuestionMark",
                  name = ns.TEXT.rollsView, quality = 3, locked = false, canNeed = true, canGreed = true, known = true,
                  upgrade = "better" })
    card.chose[GREED] = { ["Saneroki"] = true }
    Icons(card, Count)
    since = TICK
end

local function Edit(on)
    if on and ns.Game.Rolls() and #cards == 0 then
        Rolls.Try()
    elseif not on then
        since = TICK
    end
end

function Rolls.Start()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(S.roll, S.row)
    holder:SetFrameStrata("MEDIUM")
    holder:Hide()
    holder:SetScript("OnUpdate", ns.Guard(Tick))
    placed = Core.Window.New(holder, { store = Core.Store(ns.name), key = "rollsPlace", title = ns.TEXT.rollsView,
                                        first = { point = "BOTTOM", x = 0, y = 330 } })
    placed:Place()
    ns.On("START_LOOT_ROLL", ns.Guard(Rolls.Add))
    ns.On("CANCEL_LOOT_ROLL", ns.Guard(Over))
    ns.On("CANCEL_ALL_LOOT_ROLLS", ns.Guard(RemoveAll))
    ns.On("CHAT_MSG_LOOT", ns.Guard(Heard))
    ns.On("GET_ITEM_INFO_RECEIVED", ns.Guard(Told))
    Core.EditMode.Watch(ns.Guard(Edit))
end

function Rolls.GiveBack()
    if holder then
        RemoveAll()
        holder:Hide()
    end
end
