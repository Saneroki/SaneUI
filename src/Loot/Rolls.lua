local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Rolls
--  When your group rolls for a thing (START_LOOT_ROLL), a card of the
--  journal's paper in a pencil box: the thing's picture in its slot and its
--  name in its quality's ink across the top; under the name the choices the
--  game offers, each a pencil box with its word (Need; Greed, or Transmog where
--  the game offers that; Disenchant where it does; Pass), a choice the game
--  refuses faint with its reason in the tooltip; along the card's foot the
--  time left, a pencil line that shrinks. The cards stack up from where Edit
--  Mode placed them, the oldest at the foot.
--
--  Who chose what: the game says it in its own lines (Chat.Rolled); each
--  choice counts them ("Greed 2"), the mouse on it names them. A choice made,
--  the game takes the card away (CANCEL_LOOT_ROLL); a choice of the game's to
--  confirm (one that binds) is its own question.
--
--      Rolls.Start(), Rolls.Refresh()   -- the cards as the game's rolls are now
--      Rolls.Try()                      -- a card to look at (/sane loot try)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local J = Core.Journal
local S = ns.SIZE
local Rolls = {}
ns.Rolls = Rolls

local PASS, NEED, GREED, DISENCHANT, TRANSMOG = 0, 1, 2, 3, 4
local WORDS = { [PASS] = "pass", [NEED] = "need", [GREED] = "greed", [DISENCHANT] = "disenchant", [TRANSMOG] = "transmog" }
local BY_WORD = {}
for kind, word in pairs(WORDS) do BY_WORD[word] = kind end
local TRY = 20 -- seconds a tried card stands
local TICK = 0.1

local holder, placed
local cards = {}   -- shown, the oldest first
local spare = {}   -- made, not in use
local since = 0

-- An item's own part of its link, to tell one thing's lines from another's.
local function Key(link)
    return type(link) == "string" and link:match("item[%-?%d:]+") or link
end

-------------------------------------------------------------------------------
--  A card
-------------------------------------------------------------------------------
local function ChoiceTip(button)
    local card = button.card
    button.box:SetStrong(true)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(button.word)
    if button.reason then GameTooltip:AddLine(button.reason, 1, 0.3, 0.3, true) end
    if ns.options.tally then
        local names = {}
        for name in pairs(card.chose[button.kind] or {}) do names[#names + 1] = name end
        table.sort(names)
        if #names > 0 then
            GameTooltip:AddLine(ns.TEXT.chose:format(button.word), 1, 1, 1)
            for _, name in ipairs(names) do GameTooltip:AddLine(name, 0.85, 0.85, 0.85) end
        end
    end
    GameTooltip:Show()
end

local function ChoiceUntip(button)
    button.box:SetStrong(false)
    GameTooltip_Hide()
end

local function Choose(button)
    local card = button.card
    if button.reason or card.sample or not card.rollID then return end
    RollOnLoot(card.rollID, button.kind)
end

local function Choice(card)
    local button = CreateFrame("Button", nil, card)
    button:SetSize(S.choice, 20)
    button.card = card
    button.text = button:CreateFontString(nil, "ARTWORK")
    J.Font(button.text, 12, true)
    button.text:SetPoint("CENTER")
    button.box = J.Box(button, 0.45)
    button:SetScript("OnClick", ns.Guard(Choose))
    button:SetScript("OnEnter", ns.Guard(ChoiceTip))
    button:SetScript("OnLeave", ns.Guard(ChoiceUntip))
    return button
end

local function ThingTip(frame)
    local card = frame:GetParent()
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    if card.rollID and not card.sample and GameTooltip.SetLootRollItem then
        GameTooltip:SetLootRollItem(card.rollID)
    elseif card.link then
        GameTooltip:SetHyperlink(card.link)
    else
        GameTooltip:SetText(card.name:GetText() or "")
    end
    GameTooltip:Show()
end

-- A modified click on the picture links it or tries it on, as anywhere in the game.
local function ThingClick(frame)
    local card = frame:GetParent()
    if card.link and IsModifiedClick() then HandleModifiedItemClick(card.link) end
end

local function NewCard()
    local card = CreateFrame("Frame", nil, holder)
    card:SetSize(S.card[1], S.card[2])
    card:EnableMouse(true)
    J.Paper(card)
    J.Box(card, 0.6, "BORDER")
    local size = S.card[2] - 2 * S.gap - 4
    card.thing = CreateFrame("Button", nil, card)
    card.thing:SetSize(size, size)
    card.thing:SetPoint("LEFT", S.gap + 2, 1)
    J.Slot(card.thing, 1)
    local inset = size * J.SLOT_ICON
    card.icon = card.thing:CreateTexture(nil, "ARTWORK")
    card.icon:SetPoint("TOPLEFT", inset, -inset)
    card.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    card.count = card.thing:CreateFontString(nil, "OVERLAY")
    card.count:SetFont(J.FONT_BOLD, 11 * J.PX, "OUTLINE")
    card.count:SetPoint("BOTTOMRIGHT", -1, 1)
    card.thing:SetScript("OnEnter", ns.Guard(ThingTip))
    card.thing:SetScript("OnLeave", GameTooltip_Hide)
    card.thing:SetScript("OnClick", ns.Guard(ThingClick))
    card.name = card:CreateFontString(nil, "ARTWORK")
    J.Font(card.name, 13, true)
    card.name:SetJustifyH("LEFT")
    card.name:SetWordWrap(false)
    card.name:SetPoint("TOPLEFT", card.thing, "TOPRIGHT", S.gap, 0)
    card.name:SetPoint("RIGHT", card, "RIGHT", -S.gap, 0)
    card.choices = {}
    card.time = J.Rule(card, "ARTWORK")
    card.time:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", S.gap, 3)
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

local function Words(button)
    local count = 0
    for _ in pairs(button.card.chose[button.kind] or {}) do count = count + 1 end
    if ns.options.tally and count > 0 then
        button.text:SetText(("%s %d"):format(button.word, count))
    else
        button.text:SetText(button.word)
    end
end

local function Dress(card, info)
    card.icon:SetTexture(info.icon)
    card.count:SetText(info.count and info.count > 1 and info.count or "")
    card.name:SetText(info.name or "")
    card.name:SetTextColor(ns.Row.Color(info.quality))
    card.link = info.link
    local offered = Offered(info)
    local right = -S.gap
    for index = #offered, 1, -1 do
        local entry = offered[index]
        local button = card.choices[index] or Choice(card)
        card.choices[index] = button
        button.kind, button.word, button.reason = entry[1], entry[2], entry[3]
        if button.reason == "" then button.reason = ns.TEXT.locked end
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", right, S.gap + 3)
        right = right - S.choice - 2
        button:SetAlpha(button.reason and J.FAINT[4] or 1)
        Words(button)
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
        card:SetPoint("BOTTOM", holder, "BOTTOM", 0, (index - 1) * (S.card[2] + S.cardGap))
    end
end

-- The time left on each card, its line as long as the share of it.
local function Tick(_, elapsed)
    since = since + elapsed
    if since < TICK then return end
    since = 0
    local now = GetTime()
    local full = S.card[1] - 2 * S.gap
    for _, card in ipairs(cards) do
        local left, total
        if card.sample then
            left, total = math.max(0, card.ends - now) * 1000, TRY * 1000
        else
            left, total = Plain(GetLootRollTimeLeft(card.rollID)) or 0, card.total
        end
        local share = total and total > 0 and math.min(1, math.max(0, left / total)) or 0
        card.time:SetWidth(math.max(1, full * share))
        card.time:SetShown(share > 0)
    end
    for index = #cards, 1, -1 do
        local card = cards[index]
        if card.sample and now >= card.ends and not Core.EditMode.active then Rolls.Remove(card.rollID, card) end
    end
end

local function Card()
    local card = table.remove(spare) or NewCard()
    wipe(card.chose)
    card.sample, card.rollID, card.total, card.ends = nil, nil, nil, nil
    cards[#cards + 1] = card
    card:Show()
    holder:Show()
    Stack()
    return card
end

-- What the game says of a roll's thing, as a table; nil once the roll is gone.
local function Info(rollID)
    local icon, name, count, quality, _, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, _, _, canTransmog =
        GetLootRollItemInfo(rollID)
    name = Plain(name)
    if not name then return nil end
    return { icon = Plain(icon), name = name, count = Plain(count) or 1, quality = Plain(quality) or 1,
             canNeed = Plain(canNeed), canGreed = Plain(canGreed), canDisenchant = Plain(canDisenchant),
             canTransmog = Plain(canTransmog), reasonNeed = Plain(reasonNeed), reasonGreed = Plain(reasonGreed),
             link = Plain(GetLootRollItemLink(rollID)) }
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

-- The game's line about a choice: counted on the card of that thing (the first whose chooser has not chosen yet).
local function Heard(text)
    local found, who, choice, link = ns.Chat.Rolled(text)
    if not found or not who or not BY_WORD[choice] then return end
    local key = Key(link)
    for _, card in ipairs(cards) do
        if Key(card.link) == key then
            local already = false
            for _, names in pairs(card.chose) do already = already or names[who] end
            if not already then
                local kind = BY_WORD[choice]
                card.chose[kind] = card.chose[kind] or {}
                card.chose[kind][who] = true
                for _, button in ipairs(card.choices) do
                    if button:IsShown() then Words(button) end
                end
                return
            end
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
    card.sample, card.rollID, card.ends = true, -#cards, GetTime() + TRY
    Dress(card, { icon = "Interface\\Icons\\INV_Misc_QuestionMark", name = ns.TEXT.rollsView, quality = 3,
                  canNeed = true, canGreed = true })
    card.chose[GREED] = { ["Saneroki"] = true }
    for _, button in ipairs(card.choices) do
        if button:IsShown() then Words(button) end
    end
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
    holder:SetSize(S.card[1], S.card[2])
    holder:SetFrameStrata("MEDIUM")
    holder:Hide()
    holder:SetScript("OnUpdate", ns.Guard(Tick))
    placed = Core.Window.New(holder, { store = Core.Store(ns.name), key = "rollsPlace", title = ns.TEXT.rollsView,
                                        first = { point = "BOTTOM", x = 0, y = 330 } })
    placed:Place()
    ns.On("START_LOOT_ROLL", ns.Guard(Rolls.Add))
    ns.On("CANCEL_LOOT_ROLL", ns.Guard(function(rollID) Rolls.Remove(rollID) end))
    ns.On("CANCEL_ALL_LOOT_ROLLS", ns.Guard(RemoveAll))
    ns.On("CHAT_MSG_LOOT", ns.Guard(Heard))
    Core.EditMode.Watch(ns.Guard(Edit))
end

function Rolls.GiveBack()
    if holder then
        RemoveAll()
        holder:Hide()
    end
end
