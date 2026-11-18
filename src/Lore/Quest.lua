local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Quest
--  Under the words, as wide as they are, on a plate of its own (Look.Plate):
--  the quest the NPC talks about (Saneroki, 2026-10-28). Its title in the
--  game's gold, then:
--    - offered: its objectives, the group it is for;
--    - in progress: what it asks for (items with how many, money);
--    - offered and handed in: its rewards, the ones to choose from first, then
--      what you get besides, then experience, money, honor and a title in one
--      line.
--  A reward's line says what it is without its tooltip (Rewards.lua). It is a
--  line of the group's loot rolls (Saneroki, 2026-11-11: "like the party roll
--  window for items. So that rolling on loot or choosing the quest reward looks
--  the same"): Core's bar of the nameplates' make (Shape.Bar) in its quality's
--  colour (a quest's own thing in the game's gold), its picture at the bar's left
--  end round with it, how many on it; the game's green arrow in front of the name
--  where it betters what you wear; the name in white in the game's outlined
--  nameplate font, what a vendor pays for all of it at the right; under the
--  name what it is (Leather · Chest), "Can't use" in red where you cannot;
--  under the value what it changes against what you wear: its item level and
--  the one worn, the stats that go up (white, +) and down (red), or that the slot
--  is empty. The tooltip is there too, with the game's
--  comparison, in sight over the faded interface (Quiet.Tips); under the mouse
--  its border is grey, as a loot line's. A click on a reward to choose chooses it
--  (its border gold); a double click hands the quest in with it; the right
--  button on it does nothing.
--  Anywhere else here a click is the talk's, as on the words (Talk.Click).
--
--      Quest.Draw(talk)   the talk's quest under the box, or nothing for a talk without one
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Quest = {}
ns.Quest = Quest

Quest.PAD = 14
Quest.ROW = 38    -- a reward's line, high: a loot line's (Loot's SIZE.row)
Quest.LINE_PAD = 4 -- over and under its words inside its bar, as a loot line's
Quest.GAP = 6     -- between its picture and its words
Quest.ARROW = 14  -- the green arrow of an upgrade, in front of its name
Quest.NAME, Quest.SMALL = 18, 13 -- its words' sizes, in 1080p pixels (Shape.BarFont), as a loot line's
Quest.SPACE = 3   -- between two lines
Quest.HEAD = 10   -- above a heading

local frame, plate, title
local heads, texts, rows = {}, {}, {}
local used -- how many of each are drawn this time
local y    -- where the next part goes, from the top

local SOFT = { 0.88, 0.88, 0.88 } -- the words under a reward's name, as a loot line's
local Shape = Core.Shape

local function Colour(name, fallback)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.GetRGB then return { colour:GetRGB() } end
    return fallback
end

local Coins, Number = ns.Look.Coins, ns.Look.Number

-------------------------------------------------------------------------------
--  Parts, made when first needed and reused
-------------------------------------------------------------------------------
local function Head(words)
    used.heads = used.heads + 1
    local head = heads[used.heads]
    if not head then
        head = ns.Look.Text(frame, "head")
        head:SetTextColor(1, 0.82, 0)
        heads[used.heads] = head
    end
    y = y - Quest.HEAD
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    head:SetText(words)
    head:Show()
    y = y - (Core.Plain(head:GetStringHeight()) or 12) - 4
end

local function Words(words, colour)
    used.texts = used.texts + 1
    local text = texts[used.texts]
    if not text then
        text = ns.Look.Text(frame, "reward")
        text:SetWidth(ns.Box.WIDTH - Quest.PAD * 2)
        text:SetSpacing(2)
        texts[used.texts] = text
    end
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    text:SetText(words)
    text:SetTextColor(unpack(colour or { 1, 1, 1 }))
    text:Show()
    y = y - (Core.Plain(text:GetStringHeight()) or 12) - 4
end

-- What it changes against what you wear, in one line: on a bar of the thing's own colour (a green one for an uncommon
-- thing) a rise is in white with its +, the green arrow before the name says it is better; a drop in the game's red.
local function Change(entry)
    if entry.cantUse then return "" end
    if entry.empty then return ns.TEXT.emptySlot end
    local parts = {}
    if entry.level then
        local level = ("%s %d"):format(ns.TEXT.itemLevel, entry.level)
        if entry.worn and entry.worn ~= entry.level then
            local up = entry.level > entry.worn
            level = level .. (up and " (+%d)" or " |cffff2020(%d)|r"):format(entry.level - entry.worn)
        end
        parts[#parts + 1] = level
    end
    for index, stat in ipairs(entry.changes or {}) do
        if index > ns.Rewards.STATS then break end
        local amount = stat.amount == math.floor(stat.amount) and ("%d"):format(stat.amount) or ("%.1f"):format(stat.amount)
        if stat.amount > 0 then amount = "+" .. amount end
        parts[#parts + 1] = (stat.amount > 0 and "%s %s" or "|cffff2020%s %s|r"):format(amount, stat.name)
    end
    return table.concat(parts, "  ")
end

local function Enter(row)
    local entry = row.entry
    if not entry then return end
    ns.Quiet.Tips(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    row.bar:SetLit(true)
    if entry.spell then
        GameTooltip:SetSpellByID(entry.spell)
    elseif entry.currency then
        GameTooltip:SetQuestCurrency(entry.kind, entry.index)
    else
        GameTooltip:SetQuestItem(entry.kind, entry.index)
        local compare = rawget(_G, "GameTooltip_ShowCompareItem")
        if compare then compare(GameTooltip) end
    end
    GameTooltip:Show()
end

local function Leave(row)
    row.bar:SetLit(false)
    GameTooltip:Hide()
    ns.Quiet.Tips(false)
end

local function Row()
    used.rows = used.rows + 1
    local row = rows[used.rows]
    if row then return row end
    row = CreateFrame("Button", nil, frame)
    row:SetSize(ns.Box.WIDTH - Quest.PAD * 2, Quest.ROW)
    row.bar = Shape.Bar(row, Quest.ROW)
    -- The picture at the bar's left end, inside its border, as tall as its fill, round with it (the fill's caps).
    local inner, pixel = row.bar.inner, row.bar.pixel
    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(inner, inner)
    row.holder:SetPoint("TOPLEFT", row, "TOPLEFT", pixel, -pixel)
    row.icon = row.holder:CreateTexture(nil, "ARTWORK")
    row.icon:SetAllPoints(row.holder)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    Shape.Caps(row.icon, row.holder, inner)
    row.count = row.holder:CreateFontString(nil, "OVERLAY")
    Shape.BarFont(row.count, Quest.SMALL)
    row.count:SetTextColor(1, 1, 1)
    row.count:SetPoint("BOTTOMRIGHT", row.holder, "BOTTOMRIGHT", -2, 1)
    -- the game's own sign of an upgrade (its bags have it): a green arrow in front of the name
    row.upgrade = row:CreateTexture(nil, "OVERLAY")
    row.upgrade:SetAtlas("bags-greenarrow")
    row.upgrade:SetSize(Quest.ARROW, Quest.ARROW)
    row.left = pixel + inner + Quest.GAP
    row.right = Quest.ROW * Shape.BAR_ROUND -- clear of the bar's round right end
    local function Line(size, justify)
        local text = row:CreateFontString(nil, "ARTWORK")
        Shape.BarFont(text, size)
        text:SetJustifyH(justify)
        text:SetWordWrap(false)
        return text
    end
    row.name = Line(Quest.NAME, "LEFT")
    row.value = Line(Quest.SMALL, "RIGHT")
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -row.right, -Quest.LINE_PAD - 2)
    row.what = Line(Quest.SMALL, "LEFT")
    row.what:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", row.left, Quest.LINE_PAD)
    row.change = Line(Quest.SMALL, "RIGHT")
    row.change:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -row.right, Quest.LINE_PAD)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", ns.Guard(function(self, button) ns.Talk.Click(button, self.entry) end))
    row:SetScript("OnDoubleClick", ns.Guard(function(self, button)
        if button == "LeftButton" and self.entry and self.entry.kind == "choice" then
            ns.Talk.Choose(self.entry.index, true)
        end
    end))
    row:SetScript("OnEnter", ns.Guard(Enter))
    row:SetScript("OnLeave", ns.Guard(Leave))
    rows[used.rows] = row
    return row
end

-- Whether it betters what you wear: a higher item level, or a slot you wear nothing in.
local function Better(entry)
    if entry.cantUse then return false end
    return entry.empty == true or (entry.level ~= nil and entry.worn ~= nil and entry.level > entry.worn)
end

local function Reward(entry, chosen)
    local row = Row()
    row.entry = entry
    row.icon:SetTexture(entry.icon)
    row.icon:SetVertexColor(1, entry.cantUse and 0.35 or 1, entry.cantUse and 0.35 or 1)
    row.count:SetText((entry.count or 1) > 1 and Number(entry.count) or "")
    if entry.kind == "required" then row.bar:Paint(Shape.Gold()) else row.bar:Paint(Shape.Quality(entry.quality or 1)) end
    row.name:SetText(entry.name or "")
    row.name:SetTextColor(1, 1, 1)
    local what = entry.what or ""
    if entry.cantUse then
        what = (what ~= "" and what .. "  " or "") .. "|cffff2020" .. ns.TEXT.cantUse .. "|r"
    end
    row.what:SetText(what)
    row.what:SetTextColor(unpack(SOFT))
    row.value:SetText(entry.value and (entry.value > 0 and Coins(entry.value) or ns.TEXT.noValue) or "")
    row.value:SetTextColor(1, 1, 1)
    row.change:SetText(Change(entry))
    row.change:SetTextColor(1, 1, 1)
    -- The name after the green arrow where there is one, short of the value; what it is short of what it changes.
    local better = Better(entry)
    row.upgrade:SetShown(better)
    local named = row.left + (better and Quest.ARROW + Quest.GAP / 2 or 0)
    row.name:ClearAllPoints()
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", named, -Quest.LINE_PAD)
    row.upgrade:ClearAllPoints()
    row.upgrade:SetPoint("RIGHT", row.name, "LEFT", -Quest.GAP / 2, 0)
    local width = row:GetWidth()
    row.name:SetWidth(math.max(60, width - named - row.right - (Core.Plain(row.value:GetStringWidth()) or 0) - Quest.GAP))
    row.what:SetWidth(math.max(60, width - row.left - row.right - (Core.Plain(row.change:GetStringWidth()) or 0) - Quest.GAP))
    row.bar:SetChosen(chosen == true)
    row.bar:SetLit(false)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, y)
    row:Show()
    y = y - Quest.ROW - Quest.SPACE
end

-------------------------------------------------------------------------------
--  The quest
-------------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Button", nil, ns.Look.Root())
    frame:SetWidth(ns.Box.WIDTH)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnClick", ns.Guard(function(_, button) ns.Talk.Click(button) end))
    plate = ns.Look.Plate(frame)
    title = ns.Look.Text(frame, "name")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", Quest.PAD, -Quest.PAD)
    title:SetWidth(ns.Box.WIDTH - Quest.PAD * 2)
    local gold = Colour("NORMAL_FONT_COLOR", { 1, 0.82, 0 })
    title:SetTextColor(unpack(gold))
end

local function Summary(rewards)
    local parts = {}
    if rewards.xp > 0 then parts[#parts + 1] = ns.TEXT.experience:format(Number(rewards.xp)) end
    if rewards.money > 0 then parts[#parts + 1] = Coins(rewards.money) end
    if rewards.honor > 0 then parts[#parts + 1] = ns.TEXT.honor:format(rewards.honor) end
    if type(rewards.title) == "string" and rewards.title ~= "" then parts[#parts + 1] = ns.TEXT.title:format(rewards.title) end
    if #parts > 0 then Words(table.concat(parts, "     ")) end
end

local function Rewards(talk)
    local rewards = talk.quest.rewards
    if not rewards then return end
    local others = #rewards.items + #rewards.currencies + #rewards.spells
    local any = #rewards.choices + others > 0 or rewards.xp > 0 or rewards.money > 0 or rewards.honor > 0
        or (type(rewards.title) == "string" and rewards.title ~= "")
    if not any then return end
    Head(ns.TEXT.rewards)
    if #rewards.choices > 0 then
        if #rewards.choices > 1 then Words(ns.TEXT.chooseOne, ns.Look.GREY) end
        for _, entry in ipairs(rewards.choices) do Reward(entry, talk.choice == entry.index) end
    end
    if others > 0 then
        Words(#rewards.choices > 0 and ns.TEXT.youGet or ns.TEXT.youGetOnly, ns.Look.GREY)
        for _, entry in ipairs(rewards.items) do Reward(entry) end
        for _, entry in ipairs(rewards.currencies) do Reward(entry) end
        for _, entry in ipairs(rewards.spells) do Reward(entry) end
    end
    Summary(rewards)
end

function Quest.Draw(talk)
    if not frame then Build() end
    if not talk.quest then
        frame:Hide()
        ns.Box.Place(nil)
        return
    end
    used = { heads = 0, texts = 0, rows = 0 }
    local quest = talk.quest
    title:SetText(talk.title or "")
    y = -Quest.PAD - (Core.Plain(title:GetStringHeight()) or 18)
    if quest.objectives and quest.objectives ~= "" then
        Head(ns.TEXT.objectives)
        Words(quest.objectives)
    end
    if quest.group and quest.group > 0 then Words(ns.TEXT.group:format(quest.group), ns.Look.GREY) end
    local required = quest.required
    if required and (#required.items > 0 or required.money > 0) then
        Head(ns.TEXT.asks)
        for _, entry in ipairs(required.items) do Reward(entry) end
        if required.money > 0 then Words(Coins(required.money)) end
    end
    Rewards(talk)
    for index = used.heads + 1, #heads do heads[index]:Hide() end
    for index = used.texts + 1, #texts do texts[index]:Hide() end
    for index = used.rows + 1, #rows do rows[index]:Hide() end
    frame:SetHeight(-y + Quest.PAD)
    plate:Fit()
    frame:Show()
    ns.Box.Place(frame)
end
