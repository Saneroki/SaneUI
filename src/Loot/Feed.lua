local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Feed
--  What you receive rises over the world, without a window, where Edit Mode
--  placed it: a line a thing, its picture, its name in its quality's colour
--  with a thin dark outline (Kalam Bold, its hand-drawn font: Core.Look.HAND), how many
--  ("x3") and, faint, how many you carry now. A new line comes in at the foot
--  and pushes the older up; each stands a few seconds and fades. The same thing
--  again while its line stands adds to that line. What comes while the lines
--  are full waits its turn: nothing of a big pile goes unseen.
--
--  Read from the game's own lines (Chat.lua): loot, items pushed into your bags,
--  what you make, currencies; money you loot (switch Coins); what the others of
--  your group receive, named, from a quality on (switches Your group's, From).
--  The game says them of all you receive, so what is taken at once, by the
--  rules, by Shift or for a roll won, rises as well: on every profile the feed
--  is how you know what you looted.
--
--      Feed.Start(), Feed.Try()   -- listening; lines to look at (/sane loot try)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local S = ns.SIZE
local Feed = {}
ns.Feed = Feed

local MOST = 8      -- lines at a time
local HOLD = 5      -- seconds a line stands
local FADE = 1.2    -- seconds it takes to fade
local COIN = "Interface\\Icons\\INV_Misc_Coin_01"

local holder, placed
local lines = {}  -- shown, the oldest first
local waiting = {} -- what came while the lines were full, the oldest first
local spare = {}

local function Item(link)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" then return nil end
    local ok, name, _, quality, _, _, _, _, _, _, icon = pcall(info, link)
    if not ok then return nil end
    return Plain(name), Plain(quality), Plain(icon)
end

local function Carried(link)
    local count = rawget(_G, "C_Item") and C_Item.GetItemCount or rawget(_G, "GetItemCount")
    return count and Core.Ask(count, link) or nil
end

local function NewLine()
    local line = CreateFrame("Frame", nil, holder)
    line:SetSize(S.feed, S.feedLine)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(S.feedLine - 4, S.feedLine - 4)
    line.icon:SetPoint("LEFT")
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.text = line:CreateFontString(nil, "OVERLAY")
    line.text:SetFont(Core.Look.HAND, 15 * Core.Look.PX, "OUTLINE") -- its hand-drawn font, by Saneroki's word
    line.text:SetPoint("LEFT", line.icon, "RIGHT", S.gap, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    return line
end

local function Stack()
    for index, line in ipairs(lines) do
        line:ClearAllPoints()
        line:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, (#lines - index) * S.feedLine)
    end
end

-- The words of a line: who (the group's), the name, how many, and how many carried.
local function Words(entry)
    local text = entry.name or ""
    if entry.count and entry.count > 1 then text = ("%s x%d"):format(text, entry.count) end
    if entry.who then text = ("%s: %s"):format(entry.who, text) end
    if entry.carried and entry.carried > (entry.count or 1) then text = ("%s |cffb0b0b0(%d)|r"):format(text, entry.carried) end
    return text
end

local function Show(line)
    local entry = line.entry
    line.icon:SetTexture(entry.icon)
    line.text:SetText(Words(entry))
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and entry.quality and colors[entry.quality]
    if color then line.text:SetTextColor(color.r, color.g, color.b) else line.text:SetTextColor(1, 1, 1) end
    line:SetAlpha(1)
end

-- A line for what came; the same thing (by its link, and who) while its line stands adds to it.
local function Add(entry)
    if not holder then return end
    local now = GetTime()
    for _, line in ipairs(lines) do
        local was = line.entry
        if entry.key and was.key == entry.key and was.who == entry.who and now - line.born < HOLD then
            was.count = (was.count or 1) + (entry.count or 1)
            was.carried = entry.carried or was.carried
            line.born = now
            return Show(line)
        end
    end
    if #lines >= MOST then
        waiting[#waiting + 1] = entry
        return
    end
    local line = table.remove(spare) or NewLine()
    line.entry, line.born = entry, now
    lines[#lines + 1] = line
    Show(line)
    line:Show()
    holder:Show()
    Stack()
end

local function Tick()
    if Core.EditMode.active then return end -- the lines stand while they are being placed
    local now = GetTime()
    local gone = false
    for index = #lines, 1, -1 do
        local line = lines[index]
        local age = now - line.born
        if age >= HOLD + FADE then
            table.remove(lines, index)
            line:Hide()
            spare[#spare + 1] = line
            gone = true
        elseif age > HOLD then
            line:SetAlpha(math.max(0, 1 - (age - HOLD) / FADE))
        end
    end
    while #waiting > 0 and #lines < MOST do Add(table.remove(waiting, 1)) end
    if gone then
        Stack()
        if #lines == 0 then holder:Hide() end
    end
end

-------------------------------------------------------------------------------
--  What the game says
-------------------------------------------------------------------------------
local function Looted(text)
    local who, link, count = ns.Chat.Received(text)
    if not link or not ns.options.feed then return end
    local name, quality, icon = Item(link)
    if who then
        if not ns.options.feedGroup then return end
        if (quality or 0) < (tonumber(ns.options.feedQuality) or 0) then return end
    end
    Add({ key = link:match("item[%-?%d:]+") or link, who = who, name = name or link, quality = quality, icon = icon,
          count = count, carried = not who and Carried(link) or nil })
end

local function Money(text)
    if not (ns.options.feed and ns.options.feedMoney) then return end
    local copper = ns.Chat.Money(text)
    if not copper then return end
    Add({ name = Core.Coins(copper) or tostring(copper), icon = COIN, quality = 1 })
end

local function Currency(text)
    if not ns.options.feed then return end
    local link, count = ns.Chat.Currency(text)
    if not link then return end
    local currency = rawget(_G, "C_CurrencyInfo")
    local info = currency and currency.GetCurrencyInfoFromLink and Plain(currency.GetCurrencyInfoFromLink(link))
    if type(info) ~= "table" then info = {} end -- the game does not say: the name its line gave
    Add({ key = link, name = Plain(info.name) or link:match("%[(.-)%]") or link, icon = Plain(info.iconFileID),
          quality = Plain(info.quality) or 1,
          count = count, carried = Plain(info.quantity) })
end

-- Lines as they will look (/sane loot try; Edit Mode).
function Feed.Try()
    if not holder then return end
    Add({ name = ns.TEXT.feedView, icon = "Interface\\Icons\\INV_Misc_Bag_10", quality = 2, count = 2, carried = 7 })
    Add({ name = Core.Coins(1234) or "1234", icon = COIN, quality = 1 })
    Add({ who = "Saneroki", name = ns.TEXT.feedView, icon = "Interface\\Icons\\INV_Misc_QuestionMark", quality = 3 })
end

local function Edit(on)
    if on and ns.options.feed and #lines == 0 then Feed.Try() end
    if not on then
        local now = GetTime()
        for _, line in ipairs(lines) do line.born = math.min(line.born, now - HOLD) end -- they fade now
    end
end

function Feed.Start()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(S.feed, S.feedLine * 3)
    holder:SetFrameStrata("LOW")
    holder:Hide()
    holder:SetScript("OnUpdate", ns.Guard(Tick))
    placed = Core.Window.New(holder, { store = Core.Store(ns.name), key = "feedPlace", title = ns.TEXT.feedView,
                                        first = { point = "RIGHT", x = -300, y = -40 } })
    placed:Place()
    ns.On("CHAT_MSG_LOOT", ns.Guard(Looted))
    ns.On("CHAT_MSG_MONEY", ns.Guard(Money))
    ns.On("CHAT_MSG_CURRENCY", ns.Guard(Currency))
    Core.EditMode.Watch(ns.Guard(Edit))
end

function Feed.GiveBack()
    if not holder then return end
    for _, line in ipairs(lines) do
        line:Hide()
        spare[#spare + 1] = line
    end
    wipe(lines)
    wipe(waiting)
    holder:Hide()
end
