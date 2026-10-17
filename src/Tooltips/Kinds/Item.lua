local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Item
--  An item's tooltip:
--
--      BoE  ·  Uncollected             [icon]     how it binds, red until it is bound (or
--      Arcanite Reaper                            "Equipped" on what you wear); whether you
--      Axe · Two-Hand    Requires Level 58        have its look. Its name in the colour of
--                         Classes: Warrior        its quality; small: kind, slot, and at the
--      ------------------------------  iLvl 63    right the level it needs (red while too low)
--      53.8 DPS  ·  153 - 256 dmg  ·  3.80 spd    and under it what else it asks of you (a
--                                                 class, a profession's skill).
--                                                 A weapon's damage per second large, its hit
--      +13 Stamina                                and speed small; then its lines, in the
--      ------------------------------------       game's colours, a divider where their colour
--      Equip: ...                                 group changes
--      ------------------------------------
--      [====    ] 61 / 120                        its durability as a bar
--      ------------------------------------
--      QUEST ──────────────────────────────       the quest it starts and the quests that need it,
--      Needed for                                 each with where you stand with it: in your log
--      [?] The Kobold Menace [2]   In log  1/4    (your count), to take, for later, done
--      PROFESSIONS ────────────────────────       the professions that use it
--      Used in                     Tailoring
--      (other addons' lines, small)
--      GOLD ───────────────────────────────       what one brings in, and what to do with it
--      Vendor  ·  AH profit                       (Kinds/Gold.lua)
--
--  Each section is there only when something is known for it; Alt shows more (every quest, where
--  the prices come from). A recipe shows the thing it makes under a caption, with that thing's icon.
--  A comparison's changes ("+2.2 DPS") are shown without the sentence over them; what you wear
--  beside an item (a comparison) has no sections, only its vendor price (for one).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Coins = Core.Plain, Core.Coins
local Read, TEXT, PATTERN, LINES = ns.Reader, ns.TEXT, ns.PATTERN, ns.LINES
local TYPE = Enum.TooltipDataType or {}
local LINE = Enum.TooltipDataLineType or {}
local BIND = Enum.TooltipDataItemBinding or {}

local EQUIP_SLOT, BINDING, SELL_PRICE = LINE.EquipSlot or -1, LINE.ItemBinding or -1, LINE.SellPrice or -1
local ITEM_LEVEL, NESTED = LINE.ItemLevel or -1, LINE.NestedBlock or -1
-- How an item binds, short: [the game's kind of binding] = "BoE"
local BINDS = {}
for name, short in pairs(TEXT.BINDS) do
    if BIND[name] then BINDS[BIND[name]] = short end
end
-- Bound to nobody yet: the panel says so in red.
local UNBOUND = {}
for _, name in ipairs({ "BindOnPickup", "BindOnEquip", "BindOnUse" }) do
    if BIND[name] then UNBOUND[BIND[name]] = true end
end
local COLOR, Like = ns.COLOR, ns.Like
local RED, DETAIL, TITLE = COLOR.RED, COLOR.DETAIL, COLOR.TITLE
local GOLD, LIGHT, DONE, ASIDE = COLOR.GOLD, COLOR.LIGHT, COLOR.DONE, COLOR.ASIDE
local MONEY, DURABLE = COLOR.TITLE, COLOR.HEALTH
-- Colours inside a line: not bound yet, bound, what you wear, a word after a number
local function Code(color) return ns.Hex(color[1], color[2], color[3]) end
local RED_HEX, BOUND_HEX, EQUIPPED_HEX, LABEL_HEX = Code(RED), Code(DETAIL), Code(GOLD), Code(DETAIL)
-- After a weapon's damage per second: "·  1 - 3 dmg  ·  2.00 spd"
local DAMAGE_LINE = ("\194\183  %%s %s  \194\183  %%s %s"):format(TEXT.DMG, TEXT.SPD)
-- Kinds of binding an item cannot be sold at the auction house with
local AUCTIONLESS = {}
for _, name in ipairs({ "Quest", "Account", "BnetAccount", "Soulbound", "BindToAccount", "BindToBnetAccount", "BindOnPickup" }) do
    if BIND[name] then AUCTIONLESS[BIND[name]] = true end
end
-- A trade good's kind (Enum.ItemTradeGoodsSubclass) -> the professions that use it, by their
-- spells, which give their names and icons in the player's language
local TRADE_GOODS = Enum.ItemClass and Enum.ItemClass.Tradegoods or 7
local TAILORING, LEATHERWORKING, BLACKSMITHING, ENGINEERING = 3908, 2108, 2018, 4036
local COOKING, ALCHEMY, ENCHANTING = 2550, 2259, 7411
local CRAFTS = {
    [1] = { ENGINEERING }, [2] = { ENGINEERING }, [3] = { ENGINEERING }, -- parts, explosives, devices
    [5] = { TAILORING }, [6] = { LEATHERWORKING }, [7] = { BLACKSMITHING, ENGINEERING }, -- cloth, leather, metal and stone
    [8] = { COOKING }, [9] = { ALCHEMY }, [12] = { ENCHANTING }, -- meat, herbs, enchanting
}

-- Whether a line begins with these words. Every line is asked, on every read: no new string for it.
local function Starts(text, start)
    return text:find(start, 1, true) == 1
end

-- What an item sells for at a vendor. The game draws it with a frame of coins, not as text.
local function Price(model, lines)
    for index = 1, #lines do
        local line = Plain(lines[index])
        local price = type(line) == "table" and Plain(line.price)
        if type(price) == "number" and price > 0 then
            if price ~= model.price then model.price, model.coins = price, Coins(price) end
            model.priced = model.coins ~= nil
            return model.coins
        end
    end
    return nil
end

-- The professions a trade good is for, by its kind (the game says no more on this client): their
-- names with their icons, "|T..|t Tailoring", or nil.
local function Crafts(model, id)
    if not C_Item.GetItemInfoInstant then return nil end
    local _, _, _, _, _, class, subclass = C_Item.GetItemInfoInstant(id)
    local spells = Plain(class) == TRADE_GOODS and CRAFTS[Plain(subclass) or -1]
    if not spells then return nil end
    if model.craftsFor ~= id then
        model.craftsFor, model.crafts = id, nil
        for _, spell in ipairs(spells) do
            local name, icon = Plain(C_Spell.GetSpellName(spell)), Plain(C_Spell.GetSpellTexture(spell))
            if name then
                local one = icon and ("|T%s:0|t %s"):format(icon, name) or name
                model.crafts = model.crafts and ("%s   %s"):format(model.crafts, one) or one
            end
        end
    end
    return model.crafts
end

-- A section's caption: its name in small capitals and a rule after it, which set it off from what is above.
local function Caption(ctx, text)
    ctx.rule = false
    local row = Read.Row()
    row.kind, row.left = "caption", text
end

-- The Quest section (Quests.lua): the quest the item starts, then the quests that need it, each with
-- where you stand with it, at a glance: in your log (the ?, gold, your count), to take (the !),
-- for later (dim), done (a tick, grey). Its level small after its name. Without Alt the quests not
-- in your log are the first three, and how many more.
local STANDING = {
    log = { "active", GOLD, TEXT.IN_LOG, GOLD }, open = { "available", LIGHT, TEXT.AVAILABLE, LIGHT },
    soon = { nil, DETAIL, TEXT.NOT_YET, ASIDE }, done = { "check", ASIDE, TEXT.DONE_QUEST, DONE },
}
local OTHERS = 3 -- quests not in your log, shown without Alt
-- A heading over the quests (Starts, Needed for), small, with Questlog at the right: over the words
-- that say where you stand (Not yet: not yet in your quest log)
local function Heading(text)
    local row = Read.Text("small", text, ASIDE[1], ASIDE[2], ASIDE[3])
    row.right, row.rr, row.rg, row.rb = TEXT.QUESTLOG, ASIDE[1], ASIDE[2], ASIDE[3]
end
local function QuestRow(entry, index)
    local standing = STANDING[entry.state] or STANDING.soon
    local color = standing[2]
    local row = Read.Text("sub", entry.text, color[1], color[2], color[3])
    row.icon = standing[1]
    local level = ns.Quests.Level(entry.quest)
    if level then row.label, row.labelFont = Read.Memo("questLvl" .. level, "[%d]", level), "small" end
    local right, rightColor = standing[3], standing[4]
    if entry.state == "log" and entry.extra then
        right, rightColor = Read.Memo("inLog" .. index, TEXT.IN_LOG_COUNT, entry.extra), entry.done and DONE or GOLD
    end
    row.right, row.rr, row.rg, row.rb = right, rightColor[1], rightColor[2], rightColor[3]
end
local function QuestSection(ctx, list)
    if list.n == 0 then return end
    Caption(ctx, TEXT.QUEST)
    local alt, others, hidden, headed = IsAltKeyDown(), 0, 0, false
    for index = 1, list.n do
        local entry = list[index]
        if entry.kind == "opener" then
            Heading(TEXT.STARTS_HEAD)
            QuestRow(entry, index)
        else
            if not headed then
                headed = true
                Heading(TEXT.NEEDED_HEAD)
            end
            if entry.state ~= "log" then others = others + 1 end
            if entry.state == "log" or alt or others <= OTHERS then
                QuestRow(entry, index)
            else
                hidden = hidden + 1
            end
        end
    end
    if hidden > 0 then Read.Text("small", Read.Memo("questsMore", TEXT.ALT_MORE, hidden), ASIDE[1], ASIDE[2], ASIDE[3]).indent = 20 end
end

-- The Professions section: the professions that use a trade good (the module's own, by its kind).
local function ProfessionSection(ctx, id)
    local crafts = id and Crafts(ctx.model, id)
    if not crafts then return end
    Caption(ctx, TEXT.PROFESSIONS)
    local row = Read.Text("sub", TEXT.USED_IN, DETAIL[1], DETAIL[2], DETAIL[3])
    row.right, row.rr, row.rg, row.rb = crafts, LIGHT[1], LIGHT[2], LIGHT[3]
end

-- Whether a line says what else the item asks of you (a class, a profession's skill: PATTERN.REQUIRES).
local function Requirement(text)
    for _, pattern in ipairs(PATTERN.REQUIRES) do
        if text:match(pattern) then return true end
    end
    return false
end
local requires = {} -- the lines that do, for one read

local function White(line)
    return Like(line.lr, line.lg, line.lb, COLOR.WHITE)
end

-- A comparison's changes: "+2.2 damage per second" says "+2.2 DPS".
local deltaAt
local function Delta(row, line, index)
    if deltaAt and index > deltaAt then row.left = row.left:gsub(PATTERN.DPS_WORDS, TEXT.DPS) end
end

local function Item(ctx)
    local L, head, id = ctx.L, ctx.head, ctx.id
    local coins = ctx.lines and Price(ctx.model, ctx.lines) or nil

    -- What the lines are. Only the item's own, not those of a thing it makes.
    local slot, bind, level, required, dps, damage, armor, durability, now, most, look, begins
    local last = ctx.count
    deltaAt = nil
    wipe(requires)
    for index = 2, ctx.count do
        if L[index].type == NESTED then
            last = index - 1
            break
        end
    end
    for index = 2, ctx.count do
        local line = L[index]
        local kind, left = line.type, line.left
        if kind == SELL_PRICE or Starts(left, LINES.SELL) then
            line.used = true -- the coins' line, and the game's words for it: the price is written out below
            -- a stack's lowest and highest price under it
            for under = index + 1, math.min(index + 2, ctx.count) do
                local text = L[under].left:match("^%s+(.*)$")
                if text and (Starts(text, LINES.MINIMUM) or Starts(text, LINES.MAXIMUM)) then L[under].used = true end
            end
        elseif left == LINES.DELTA or left == LINES.DELTA_BOTH then
            -- The sentence over a comparison's changes: left out. The changes are the game's own lines.
            line.used, deltaAt = true, index
            for under = index + 1, ctx.count do
                if L[under].blank then break end
                L[under].own = true
            end
        elseif left == LINES.UNCOLLECTED or left == LINES.LOOK_KNOWN then
            look, line.used = line, true
        elseif left == LINES.STARTS_QUEST then
            begins = line
        elseif index > last then
            -- the thing a recipe makes: left to Rest
        elseif kind == EQUIP_SLOT and not slot then
            slot = line
        elseif kind == BINDING and not bind then
            bind = line
        elseif (kind == ITEM_LEVEL or left:match(PATTERN.ITEM_LEVEL)) and not level then
            level = tonumber(left:match("%d+"))
            line.used = true
        elseif line.right == "" and not Read.Added(line, index) then
            if not required and left:match(PATTERN.MIN_LEVEL) then
                required = line
            elseif Requirement(left) then
                requires[#requires + 1] = line
            elseif not dps and left:match(PATTERN.DPS) then
                dps = line
                local before = L[index - 1]
                if index > 2 and not before.used and before.right ~= "" then damage = before end
            elseif not armor and White(line) and left:match(PATTERN.ARMOR) then
                armor = line
            elseif not durability then
                local a, b = left:match(PATTERN.DURABILITY)
                now, most = tonumber(a), tonumber(b)
                if now and most and most > 0 then durability = line end
            end
        end
    end

    -- The header
    local title = Read.Title(false)
    local quality = id and Plain(C_Item.GetItemQualityByID(id))
    local color = quality and ITEM_QUALITY_COLORS[quality]
    if color then Read.Accent(color.r, color.g, color.b) else Read.AccentFromTitle() end
    head.icon = ctx.options.icons and id and Plain(C_Item.GetItemIconByID(id)) or nil
    if level then head.badge = Read.Memo("level", TEXT.ITEM_LEVEL, level) end
    -- Without an icon there is no plaque to hold it: the level stands right of the name.
    if head.badge and not head.icon then title.right = head.badge end

    -- Over the name, short: how it binds (BoE), red until it is bound, or "Equipped" on what you
    -- wear; whether you have its look
    local first, second
    if head.compared then
        first = Read.Memo("tagFirst", "|cff%s%s|r", EQUIPPED_HEX, head.tag:upper())
    elseif bind then
        local bonding = bind.data and Plain(bind.data.bonding)
        local word = bonding ~= nil and BINDS[bonding] or bind.left
        first = Read.Memo("tagFirst", "|cff%s%s|r", bonding ~= nil and UNBOUND[bonding] and RED_HEX or BOUND_HEX, word)
    end
    if bind then bind.used = true end
    if look then
        local hex = ns.Hex(look.lr or 0.5, look.lg or 0.5, look.lb or 1)
        second = Read.Memo("tagSecond", "|cff%s%s|r", hex, look.left == LINES.UNCOLLECTED and TEXT.UNCOLLECTED or TEXT.LOOK_KNOWN)
    end
    head.tag = first and second and Read.Memo("tag", "%s  \194\183  %s", first, second) or first or second or ""

    -- Under the name, small and grey: kind and slot (what it is, for a thing that is not worn),
    -- and the level it needs (red while yours is lower)
    local what = slot and (slot.right ~= "" and Read.Memo("slot", "%s \194\183 %s", slot.right, slot.left) or slot.left)
    if slot then
        slot.used = true
    elseif id and C_Item.GetItemInfoInstant then
        local _, kind, subkind = C_Item.GetItemInfoInstant(id)
        kind, subkind = Plain(kind), Plain(subkind)
        if type(kind) == "string" and kind ~= "" then
            what = type(subkind) == "string" and subkind ~= "" and subkind ~= kind and Read.Memo("slot", "%s \194\183 %s", kind, subkind) or kind
        end
    end
    -- At the right, one under the other: the level it needs, then what else it asks of you (a class,
    -- a profession's skill), each grey, or red while you do not have it
    if required then table.insert(requires, 1, required) end
    if what and #requires == 0 then Read.Text("detail", what, ASIDE[1], ASIDE[2], ASIDE[3]) end
    for index = 1, #requires do
        local line = requires[index]
        local color = Like(line.lr, line.lg, line.lb, RED) and RED or ASIDE
        local row = Read.Text("detail", index == 1 and what or "", ASIDE[1], ASIDE[2], ASIDE[3])
        row.right, row.rr, row.rg, row.rb = line.left, color[1], color[2], color[3]
        line.used = true
    end

    -- A weapon's or an armour's number. A weapon's in one line: "3.2 DPS  ·  1 - 3 dmg  ·  2.00 spd",
    -- its damage per second large, the hit's damage and its speed smaller.
    ctx.rule = true
    if dps then
        local row = Read.Text("big", Read.Memo("dps", "%s |cff%s%s|r", dps.left:match(PATTERN.DPS), LABEL_HEX, TEXT.DPS), TITLE[1], TITLE[2], TITLE[3])
        dps.used = true
        local hit = damage and damage.left:match("^%s*([%d,%.]+%s*%-%s*[%d,%.]+)")
        local speed = damage and damage.right:match("([%d,%.]+)")
        if hit and speed then
            row.label, row.labelFont = Read.Memo("damage", DAMAGE_LINE, hit, speed), "sub"
            damage.used = true
        elseif damage then
            Read.Text("sub", Read.Memo("damage", "%s  \194\183  %s", damage.left, damage.right), DETAIL[1], DETAIL[2], DETAIL[3])
            damage.used = true
        end
    end
    if armor then Read.Line(armor, "big") end

    -- Its quests. The game's line that it begins a quest is left out where the panel names the quest.
    local quests = ns.Quests.Item(id)
    if begins and quests.n > 0 and quests[1].kind == "opener" then begins.used = true end

    -- Its own lines; a recipe's product under a caption
    if durability then durability.used = true end
    ctx.tones = true
    if last < ctx.count then
        ctx.nested = TEXT.CREATES
        local made = L[last + 1].data
        local what = made and Plain(made.tooltipType)
        local which = made and Plain(made.tooltipID)
        if ctx.options.icons and which and what ~= nil and what == TYPE.Item then
            ctx.nestedIcon = Plain(C_Item.GetItemIconByID(which))
        end
    end
    ctx.each = Delta
    Read.Rest("own")
    ctx.each, ctx.tones = nil, false

    -- Its durability as a bar
    if durability then
        ctx.rule = true
        local row = Read.Row()
        row.kind, row.short, row.value, row.max = "bar", true, now, most
        row.br, row.bg, row.bb = DURABLE[1], DURABLE[2], DURABLE[3]
        row.left = Read.Memo("durability", "%d / %d", now, most)
        row.lr, row.lg, row.lb = DETAIL[1], DETAIL[2], DETAIL[3]
        row.right = ""
    end

    -- The quests that want it, the sections of what is known of it, and other addons' lines. What
    -- you wear beside it (a comparison) has none of that: its vendor price only.
    local bonding = bind and bind.data and Plain(bind.data.bonding)
    local bound = bonding ~= nil and AUCTIONLESS[bonding] or false
    if head.compared then
        ctx.rule = true
        Read.Rest("added")
        local each = ns.Gold.VendorEach(id, coins and ctx.model.price or nil)
        if each then
            ctx.rule = true
            local row = Read.Text("sub", TEXT.VENDOR, DETAIL[1], DETAIL[2], DETAIL[3])
            if each > 0 then
                row.right, row.rr, row.rg, row.rb = ns.Gold.Money(each), MONEY[1], MONEY[2], MONEY[3]
            else
                row.right, row.rr, row.rg, row.rb = TEXT.NO_VENDOR, DETAIL[1], DETAIL[2], DETAIL[3]
            end
        end
        ctx.rule = false
        return
    end
    QuestSection(ctx, quests)
    ProfessionSection(ctx, id)
    ctx.rule = true
    Read.Rest("added")
    ns.Gold.Section(ctx, id, coins and ctx.model.price or nil, bound)
    ctx.rule = false
end

if TYPE.Item then ns.KINDS[TYPE.Item] = Item end
if TYPE.Toy then ns.KINDS[TYPE.Toy] = Item end
