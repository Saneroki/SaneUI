local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Inventory
--  An item's Inventory section (Kinds/Item.lua): who of your characters has
--  it, and where, from Core's characters' data (Data.Count; Doc/guides/data.md,
--  *Characters*). Each character by its whole name, first name and surname,
--  in its class's colour: you first, then the others by name; the account's
--  own bank last.
--
--      INVENTORY ──────────────────────────
--      Sane Lunatic         Bags 12  ·  Bank 8
--      Droopy Fairwind                  Worn 1
--      Account bank                     Bank 5
--      Total                                26    with two or more
--
--  Without Alt the first five, and how many more Alt shows. Nothing until Core
--  has read the characters (the pack Characters loaded), nothing for an item
--  none of them has.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Data = Core.Data
local Read, TEXT = ns.Reader, ns.TEXT
local COLOR = ns.COLOR
local DETAIL, LIGHT, ASIDE = COLOR.DETAIL, COLOR.LIGHT, COLOR.ASIDE
local Inventory = {}
ns.Inventory = Inventory

local SHOWN = 5 -- owners shown without Alt
local ACCOUNT = "account" -- the account's own bank in a count (Data.Count)
local PLACES = { { "bags", TEXT.BAGS }, { "bank", TEXT.BANK }, { "worn", TEXT.WORN } }
local JOIN = { "%s", "%s  \194\183  %s", "%s  \194\183  %s  \194\183  %s" }
local NONE = {}

-- The memos' names, made once: a tooltip is read several times a second (Read.Memo)
local keys = {}
local function Key(row, part)
    local names = keys[row]
    if not names then
        names = { [0] = "owned" .. row }
        for index = 1, #PLACES do names[index] = ("owned%d.%d"):format(row, index) end
        keys[row] = names
    end
    return names[part]
end

-- Where an owner has it: "Bags 12  ·  Bank 8"
local function Where(row, places)
    local a, b, c, n = nil, nil, nil, 0
    for index, place in ipairs(PLACES) do
        local count = places[place[1]]
        if count then
            n = n + 1
            local text = Read.Memo(Key(row, index), "%s %d", place[2], count)
            if n == 1 then a = text elseif n == 2 then b = text else c = text end
        end
    end
    if n == 0 then return "" end
    return Read.Memo(Key(row, 0), JOIN[n], a, b, c)
end

-- One read's tally, used again
local seen = { rows = 0, hidden = 0, owners = 0 }

-- An owner's row, or only counted while Alt is not held and enough are shown
local function Owner(key, places)
    seen.owners = seen.owners + 1
    if not seen.alt and seen.rows >= SHOWN then
        seen.hidden = seen.hidden + 1
        return
    end
    seen.rows = seen.rows + 1
    local name, r, g, b = TEXT.ACCOUNT_BANK, LIGHT[1], LIGHT[2], LIGHT[3]
    if key ~= ACCOUNT then
        local who = Data.Character(key)
        name = who and who.name or "?"
        local class = seen.colors and who and who.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[who.class]
        if class then r, g, b = class.r, class.g, class.b end
    end
    local row = Read.Text("sub", name, r, g, b)
    row.right, row.rr, row.rg, row.rb = Where(seen.rows, places), DETAIL[1], DETAIL[2], DETAIL[3]
end

function Inventory.Section(ctx, id)
    local count = id and Data.Count(id)
    if not count then return end
    Read.Caption(TEXT.INVENTORY)
    seen.rows, seen.hidden, seen.owners = 0, 0, 0
    seen.alt, seen.colors = IsAltKeyDown(), ctx.options.classColors
    local me = Core.charKey
    if me and type(count[me]) == "table" then Owner(me, count[me]) end
    for _, who in ipairs(Data.Characters() or NONE) do
        if who.key ~= me and type(count[who.key]) == "table" then Owner(who.key, count[who.key]) end
    end
    if type(count[ACCOUNT]) == "table" then Owner(ACCOUNT, count[ACCOUNT]) end
    if seen.hidden > 0 then
        Read.Text("small", Read.Memo("ownedMore", TEXT.ALT_MORE, seen.hidden), ASIDE[1], ASIDE[2], ASIDE[3]).indent = 20
    end
    if seen.owners > 1 then
        local row = Read.Text("sub", TEXT.TOTAL, DETAIL[1], DETAIL[2], DETAIL[3])
        row.right, row.rr, row.rg, row.rb = Read.Memo("ownedTotal", "%d", count.total), LIGHT[1], LIGHT[2], LIGHT[3]
    end
end
