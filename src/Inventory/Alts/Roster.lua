local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Roster
--  Whose things the window shows: a dropdown on its title line (Snapshot.
--  Characters; Saneroki, 2026-10-30: a column saved for the items), its word
--  the chosen one's name in its class's colour. In its menu each character by
--  its class's icon and its whole name in its class's colour, its gold at the
--  right; the account's own bank last, where it holds something; under them
--  the gold of them all. A click chooses (Alts.Choose). While searching, each
--  says how many of what is found it has, and one that has none of it is
--  greyed. Its tooltip says the rest: the level and class, the realm, when it
--  was seen last, its gold to the copper.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Roster = {}
ns.Roster = Roster

Roster.WIDTH = 170  -- the dropdown on the title line
Roster.LEAST = 120  -- and on a narrow one
Roster.ROW = 22     -- a character's line in its menu
Roster.ICON = 16    -- its class's icon
Roster.CHECK = 22   -- the room left of a line's words: the menu's radio
Roster.APART = 18   -- between a line's name and what stands at its right
local GOLD = 10000  -- copper in a gold coin: the list shows whole gold (all of it under one), the tooltip and the total all
local BANK_ICON = "Interface\\Icons\\INV_Misc_Bag_08"
local NONE = "ff808080" -- a character without anything the search finds

local menu
local list, chosen, found = {}, nil, nil -- the characters; the key shown; [key] = how many the search finds (nil: no search)

-- The class's colour (RAID_CLASS_COLORS), or the game's white (also for a saved class of a wrong kind).
function Roster.Colour(class)
    local colours = rawget(_G, "RAID_CLASS_COLORS")
    local colour = colours and type(class) == "string" and colours[class]
    if colour then return colour.r, colour.g, colour.b end
    return 1, 1, 1
end

local function Hex(r, g, b)
    return ("ff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- A character's class's icon in a line of text; the account's bank's.
local function Icon(who)
    local size = Roster.ICON
    if who.key == ns.Snapshot.ACCOUNT then return ("|T%s:%d:%d|t "):format(BANK_ICON, size, size) end
    local atlas, markup = rawget(_G, "GetClassAtlas"), rawget(_G, "CreateAtlasMarkup")
    if not (atlas and markup and type(who.class) == "string") then return "" end
    return markup(atlas(who.class:lower()), size, size) .. " "
end

-- A character's name, in its class's colour (on the menu's dark), or the account's bank.
local function Name(who)
    if who.key == ns.Snapshot.ACCOUNT then return ns.Alts.TEXT.account end
    return who.name or "?"
end

-- What stands at a line's right: how many are found, else its gold.
local function Right(who)
    if found then
        local count = found[who.key] or 0
        return count > 0 and tostring(count) or ""
    end
    local money = who.key ~= ns.Snapshot.ACCOUNT and type(who.money) == "number" and who.money or nil
    if money and money >= GOLD then money = money - money % GOLD end
    return money and Core.Coins(money) or ""
end

local function Line(who)
    local colour = found and (found[who.key] or 0) == 0 and NONE or Hex(Roster.Colour(who.class))
    return Icon(who) .. "|c" .. colour .. Name(who) .. "|r"
end

-- A line's right, the line made as wide as its words and that.
local function Lay(button, words)
    local right = button:AttachFontString()
    right:ClearAllPoints()
    right:SetPoint("RIGHT")
    right:SetFontObject("GameFontHighlightSmall")
    right:SetText(words)
    local text = button.fontString
    local width = (text and text:GetUnboundedStringWidth() or 100) + right:GetUnboundedStringWidth()
    return width + Roster.CHECK + Roster.APART, Roster.ROW
end

local function IsChosen(key) return key == chosen end
local function Choose(key) ns.Alts.Choose(key) end
local Chosen = ns.Guard(IsChosen)
local Pick = ns.Guard(Choose)

-- A character's tooltip in the menu.
local function Tip(tooltip, who)
    for index, line in ipairs(ns.Alts.About(who)) do
        if index == 1 then tooltip:SetText(line[1], line[2], line[3], line[4]) else tooltip:AddLine(line[1], line[2], line[3], line[4]) end
    end
end

local function Fill(_, root)
    for _, who in ipairs(list) do
        local entry = root:CreateRadio(Line(who), Chosen, Pick, who.key)
        entry:SetResponse(MenuResponse.Close)
        entry:SetTooltip(ns.Guard(function(tooltip) Tip(tooltip, who) end))
        local right = Right(who)
        entry:AddInitializer(ns.Guard(function(button) return Lay(button, right) end))
    end
    if not found and #list > 1 then
        root:CreateDivider()
        root:CreateTitle(ns.Alts.TEXT.total .. ": " .. (Core.Coins(ns.Snapshot.Gold()) or ""))
    end
end
local Menu = ns.Guard(Fill)

-- The dropdown, in the title line; its place is the window's.
function Roster.Build(parent)
    menu = ns.Paper.Dropdown(parent, Roster.WIDTH, ns.Bags.BAR)
    menu:SetupMenu(Menu)
    Roster.menu = menu
    return menu
end

-- The dropdown as it is now: these characters (Snapshot.Characters), the one shown its word; counts: [key] = how many
-- the search finds, or nil while nothing is searched.
function Roster.Show(characters, key, counts)
    list, chosen, found = characters, key, counts
    local word = ""
    for _, who in ipairs(characters) do
        if who.key == key then
            local plain = who.key == ns.Snapshot.ACCOUNT
            word = plain and Name(who) or "|c" .. ns.Paper.InkHex(Roster.Colour(who.class)) .. Name(who) .. "|r"
        end
    end
    menu:OverrideText(word)
    menu:GenerateMenu()
end
