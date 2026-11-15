local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Menus
--  What the player chooses about the bag window's items and categories (kept
--  by Categories.lua), by the game's menus (MenuUtil), by letting items go
--  over a category and by the game's dialogs:
--      an item      Alt and a right click on it (a click the game's button
--                   does nothing with): Pinned; Junk (an item with a price,
--                   while the junk marker is on); Put Into a category (or a
--                   new one); Take Out of the category it was put into
--      a category   a right click on its row in the sidebar or on its head:
--                   Rename (no name: its own again), Move Up, Move Down,
--                   Create Group With another, Add to Group, Ungroup, Hide in
--                   All Items (or Show), Switch Off; the player's own: Icon,
--                   Delete (asked first)
--      a group      Rename, Move Up, Move Down, Hide in All Items, Disband
--      Pinned, Recent   Hide (shown again in the dropdown View); Recent: Clear
--      a drop       an item let go over a category's row or head (dragged
--                   there, or picked up and clicked there) is put into it:
--                   over Pinned it is pinned, over Junk marked as junk; it
--                   goes back to its slot
--      a new one    Add Category (the sidebar's foot): its name asked in the
--                   game's dialog; its icon chosen in its menu
--  Each choice is kept at once and the window drawn anew.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Menus = {}
ns.Menus = Menus

local Categories = ns.Categories
local TEXT = ns.TEXT
local ACCEPT = Core.Word("ACCEPT", "Accept")

-- A choice kept: the bags drawn anew, and the bank and the alts (their items by category, an item's choice).
local function Changed()
    if ns.Bags then ns.Bags.Refresh() end
    if ns.Bank then ns.Bank.Refresh() end
    if ns.Alts then ns.Alts.Changed() end
end

-- The game's green line for what a click does.
local function Hint(tip, text)
    local add = rawget(_G, "GameTooltip_AddInstructionLine")
    if add then add(tip, text, true) else tip:AddLine(text, 0.1, 1, 0.1, true) end
end
Menus.Hint = Hint

local function Icon(file, size)
    local markup = rawget(_G, "CreateTextureMarkup")
    if not markup then return "" end
    return markup(file, 64, 64, size or 16, size or 16, 0.08, 0.92, 0.08, 0.92) .. " "
end

-------------------------------------------------------------------------------
--  New categories
-------------------------------------------------------------------------------
-- A category of the player's own: its icon chosen in Core's icon chooser (Saneroki, 2026-11-15: "When you create a
-- custom category, can we add a picutre chooser to it?"), the game's icons by group, searched; closed without a
-- choice, it keeps the one it has.
local function ChooseIcon(key)
    if not Categories.Own(key) then return end
    Core.Icons.Open({
        label = "bags", title = TEXT.bagsIconTitle:format(Categories.Word(key)), chosen = Categories.Icon(key),
        chosenWord = TEXT.bagsIconChosen, clickWord = TEXT.bagsIconClick,
        pick = function(file)
            if not file or not Categories.Own(key) then return end
            Categories.SetIcon(key, file)
            Changed()
        end,
    })
end
Menus.ChooseIcon = ChooseIcon

-- A category of the player's own made, named in the game's dialog, its icon chosen next; then (item) that item put
-- into it.
local function New(item)
    Core.AskText(TEXT.bagsNewAsk, nil, ACCEPT, "", function(text)
        local key = Categories.New(text, Categories.OWN_ICON)
        if not key then return end
        if item then Categories.Assign(item, key) end
        Changed()
        ChooseIcon(key)
    end, Categories.LETTERS)
end
local NewCategory = ns.Guard(function() New() end)

function Menus.Add()
    New()
end

-------------------------------------------------------------------------------
--  An item's menu
-------------------------------------------------------------------------------
local item = {} -- what the open menu is about: id, name, worthless

local function IsPinned() return Categories.Pinned(item.id) end
local function TogglePin()
    Categories.Pin(item.id, not Categories.Pinned(item.id))
    Changed()
end
local function IsJunk() return Categories.Assigned(item.id) == Categories.JUNK or item.category == Categories.JUNK end
local function ToggleJunk()
    Categories.MarkJunk(item.id, not IsJunk(), item.quality)
    Changed()
end
local function IsIn(key) return item.category == key end
local function PutIn(key)
    Categories.File(item.id, key)
    Changed()
end
local function TakeOut()
    Categories.Assign(item.id, nil)
    Changed()
end
local Pinned = ns.Guard(IsPinned)
local Pin = ns.Guard(TogglePin)
local Junk = ns.Guard(IsJunk)
local MarkJunk = ns.Guard(ToggleJunk)
local In = ns.Guard(IsIn)
local Put = ns.Guard(PutIn)
local Out = ns.Guard(TakeOut)
local NewFor = ns.Guard(function() New(item.id) end)

local function FillItem(_, root)
    root:CreateTitle(item.name)
    root:CreateCheckbox(Categories.Word(Categories.PINNED), Pinned, Pin)
    if not item.worthless and Categories.Marker() then
        root:CreateCheckbox(Categories.Word(Categories.JUNK), Junk, MarkJunk)
    end
    local into = root:CreateButton(TEXT.bagsPutInto)
    for _, key in ipairs(Categories.order) do
        if Categories.Takes(key) and key ~= Categories.JUNK and not Categories.Off(key) then
            local file = Categories.Icon(key)
            into:CreateRadio(Icon(file) .. Categories.Word(key), In, Put, key)
        end
    end
    into:CreateDivider()
    into:CreateButton(TEXT.bagsNew, NewFor)
    local assigned = Categories.Assigned(item.id)
    if assigned and assigned ~= Categories.JUNK then
        root:CreateButton(TEXT.bagsTakeOut:format(Categories.Word(assigned)), Out)
    end
end
local ItemMenu = ns.Guard(FillItem)

-- The menu of the item a button of ours draws (Cells.Record).
function Menus.Item(button)
    local record = ns.Cells.Record(button)
    if not (record and record.item and rawget(_G, "MenuUtil")) then return end
    item.id, item.name, item.worthless = record.item, record.name, record.worthless
    item.category, item.quality = record.category, record.quality
    MenuUtil.CreateContextMenu(button, ItemMenu)
end

-------------------------------------------------------------------------------
--  A category's or a group's menu
-------------------------------------------------------------------------------
local about = {} -- what the open menu is about: key or group

local function Rename()
    local key, group = about.key, about.group
    local word = group and Categories.GroupWord(group) or Categories.Word(key)
    local ask = (group or Categories.Own(key)) and TEXT.bagsRenameAsk or TEXT.bagsRenameGameAsk
    Core.AskText(ask, word, ACCEPT, word, function(text)
        if group then Categories.RenameGroup(group, text) else Categories.Rename(key, text) end
        Changed()
    end, Categories.LETTERS)
end
local function MoveBy(step)
    if about.group then Categories.MoveGroup(about.group, step) else Categories.Move(about.key, step) end
    Changed()
end
local function With(other)
    Categories.GroupWith(about.key, other)
    Changed()
end
local function Into(group)
    Categories.Join(about.key, group)
    Changed()
end
local function Apart()
    Categories.Ungroup(about.key)
    Changed()
end
local function Disband()
    Categories.Disband(about.group)
    Changed()
end
local function IsHidden() return Categories.Hidden(about.group or about.key) end
local function ToggleHidden()
    Categories.Hide(about.group or about.key, not IsHidden())
    Changed()
end
local function IsOff() return Categories.Off(about.key) end
local function ToggleOff()
    Categories.SwitchOff(about.key, not IsOff())
    Changed()
end
local function PickIcon()
    ChooseIcon(about.key)
end
local function DeleteIt()
    local key = about.key
    Core.Confirm(TEXT.bagsDeleteAsk, Categories.Word(key), function()
        Categories.Delete(key)
        Changed()
    end, true)
end
-- Pinned and Recent hidden in All Items, or shown there again: the window's settings Show Pinned Items, Show Recent
-- Items (their rows stay in the sidebar, greyed).
local function IsFixedHidden() return (ns.options or {})[ns.Bags.SHOW[about.key]] == false end
local function ToggleFixed()
    Core.Set(ns.name, ns.Bags.SHOW[about.key], IsFixedHidden())
end
local function ClearRecent()
    ns.Recent.Clear()
    Changed()
end
local Renamed = ns.Guard(Rename)
local Move = ns.Guard(MoveBy)
local Group = ns.Guard(With)
local Join = ns.Guard(Into)
local Ungroup = ns.Guard(Apart)
local Undo = ns.Guard(Disband)
local Hidden = ns.Guard(IsHidden)
local Hide = ns.Guard(ToggleHidden)
local Offed = ns.Guard(IsOff)
local SwitchOff = ns.Guard(ToggleOff)
local Iconize = ns.Guard(PickIcon)
local Delete = ns.Guard(DeleteIt)
local FixedHidden = ns.Guard(IsFixedHidden)
local HideFixed = ns.Guard(ToggleFixed)
local Clear = ns.Guard(ClearRecent)

local function FillRow(_, root)
    local key, group = about.key, about.group
    if group then
        root:CreateTitle(Categories.GroupWord(group))
        root:CreateButton(TEXT.bagsRename, Renamed)
        root:CreateButton(TEXT.bagsUp, Move, -1)
        root:CreateButton(TEXT.bagsDown, Move, 1)
        root:CreateCheckbox(TEXT.bagsHideAll, Hidden, Hide)
        root:CreateButton(TEXT.bagsDisband, Undo)
        return
    end
    root:CreateTitle(Categories.Word(key))
    if key == Categories.PINNED or key == Categories.RECENT then
        root:CreateCheckbox(TEXT.bagsHideAll, FixedHidden, HideFixed)
        if key == Categories.RECENT then root:CreateButton(TEXT.bagsClear, Clear) end
        return
    end
    root:CreateButton(TEXT.bagsRename, Renamed)
    local def = Categories.DEF[key]
    if not (def and def.last) then
        root:CreateButton(TEXT.bagsUp, Move, -1)
        root:CreateButton(TEXT.bagsDown, Move, 1)
    end
    if Categories.Groupable(key) then
        local mine = Categories.GroupOf(key)
        if mine then
            root:CreateButton(TEXT.bagsUngroup:format(Categories.GroupWord(mine)), Ungroup)
        else
            local with = root:CreateButton(TEXT.bagsGroupWith)
            local groups, seen = {}, {}
            for _, other in ipairs(Categories.order) do
                local theirs = Categories.GroupOf(other)
                if other ~= key and Categories.Groupable(other) and not theirs and not Categories.Off(other) then
                    with:CreateButton(Categories.Word(other), Group, other)
                elseif theirs and not seen[theirs] then
                    seen[theirs] = true
                    groups[#groups + 1] = theirs
                end
            end
            if #groups > 0 then
                local add = root:CreateButton(TEXT.bagsAddToGroup)
                for _, other in ipairs(groups) do add:CreateButton(Categories.GroupWord(other), Join, other) end
            end
        end
    end
    root:CreateCheckbox(TEXT.bagsHideAll, Hidden, Hide)
    if key ~= Categories.CATCH_ALL and key ~= Categories.JUNK then root:CreateCheckbox(TEXT.bagsOff, Offed, SwitchOff) end
    if Categories.Own(key) then
        root:CreateButton(TEXT.bagsIcon, Iconize)
        root:CreateButton(Core.Word("DELETE", "Delete"), Delete)
    end
end
local RowMenu = ns.Guard(FillRow)

-- A right click on a category's or group's row (the sidebar) or head (the items): its menu.
function Menus.Row(owner, key, group)
    if not ((key or group) and rawget(_G, "MenuUtil")) then return end
    about.key, about.group = key, group
    MenuUtil.CreateContextMenu(owner, RowMenu)
end

-- A switched-off category's row clicked (greyed in the sidebar): switched on again.
function Menus.SwitchOn(key)
    if not (key and Categories.Off(key)) then return end
    Categories.SwitchOff(key, false)
    Changed()
end

-- Whether items can be let go over a category: Pinned, Junk, the categories items are put into, a group
-- ("group:<group>", one of whose members takes them).
function Menus.Takes(key)
    if type(key) == "string" and key:find("^group:") then
        for _, member in ipairs(Categories.Members(key:sub(7))) do
            if Categories.Takes(member) then return true end
        end
        return false
    end
    return key == Categories.PINNED or key ~= nil and Categories.Takes(key)
end

-- The item on the cursor put into the bags: one taken out of a bag (its slot locked while it is held) back to its
-- slot; one from elsewhere (the bank, what is worn) into the first free slot of the ordinary bags that takes it;
-- with none free, back where it came from.
local function Stow(id)
    local container = rawget(_G, "C_Container") or {}
    local carried = ns.Bags.Carried()
    for _, record in ipairs(carried.slots) do
        if record.item == id and record.locked then return ClearCursor() end
    end
    local pickup = container.PickupContainerItem or rawget(_G, "PickupContainerItem")
    local holding = rawget(_G, "CursorHasItem")
    if pickup and holding then
        for _, record in ipairs(carried.slots) do
            -- only the ordinary bags: a quiver's, a soul or herb bag's slot (the game's bag family) would refuse
            -- the item with an error, the keyring's and the reagent bag's too
            if not record.item and record.kind == "bags" then
                Core.Ask(pickup, record.bag, record.slot)
                if not Core.Ask(holding) then return end
            end
        end
    end
    ClearCursor()
end

-- The item on the cursor let go over a category (its head, its row, its empty slot, one of its items): put into it
-- (Pinned: pinned; Junk: marked as junk; any other: assigned to it, which takes a junk mark off; anywhere but
-- Pinned: unpinned, Categories.File), then back to its slot; stow: in the bags' window, an item from elsewhere goes
-- into the bags (Stow).
function Menus.Drop(key, stow)
    if not Menus.Takes(key) then return false end
    local kind, id = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return false end
    Categories.File(id, key)
    if stow then Stow(id) else ClearCursor() end
    Changed()
    return true
end

-- The item on the cursor let go over the page's paper (no slot, no head): into the bags (stow), in the category
-- the rules give it (what the player put it into, or marked it as, taken off; unpinned: out of Pinned too).
function Menus.Home(stow)
    local kind, id = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return false end
    Categories.Pin(id, false)
    Categories.Assign(id, nil)
    if stow then Stow(id) else ClearCursor() end
    Changed()
    return true
end

-- The item on the cursor offered to be destroyed (the waste bin, Junk's first slot), in the game's own dialog as
-- when it is dropped into the world (the game's DELETE_ITEM_CONFIRM: a rare or better item but an heirloom is typed
-- out, a quest item says so); its Yes is the game's DeleteCursorItem. Nothing on the cursor: nothing.
function Menus.Destroy()
    local kind, id, link = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return false end
    local show = rawget(_G, "StaticPopup_Show")
    if not show then return false end
    -- Its quality and class (the twelfth answer: beyond Core.Ask's three, so asked as Contents does).
    local items = rawget(_G, "C_Item")
    local info = items and items.GetItemInfo or rawget(_G, "GetItemInfo")
    local ok, name, _, quality, _, _, _, _, _, _, _, _, class = pcall(info, link or id)
    if not ok then name, quality, class = nil, nil, nil end
    quality, class = Core.Plain(quality), Core.Plain(class)
    local qualities = Enum and Enum.ItemQuality or {}
    local good = type(quality) == "number" and quality >= (qualities.Rare or 3) and quality ~= (qualities.Heirloom or 7)
    local quest = class == (Enum and Enum.ItemClass and Enum.ItemClass.Questitem or 12)
    local which = good and (quest and "DELETE_GOOD_QUEST_ITEM" or "DELETE_GOOD_ITEM")
        or (quest and "DELETE_QUEST_ITEM" or "DELETE_ITEM")
    show(which, Core.Plain(name) or (type(link) == "string" and link:match("%[(.-)%]")) or tostring(id))
    return true
end

-- A category head's tooltip: what can be done there.
function Menus.Tip(owner, key, group)
    local tip = GameTooltip
    tip:SetOwner(owner, "ANCHOR_TOP")
    tip:SetText(group and Categories.GroupWord(group) or Categories.Word(key), 1, 0.82, 0)
    if key == Categories.PINNED then tip:AddLine(TEXT.bagsPinnedTip, 1, 1, 1, true) end
    if key == Categories.RECENT then tip:AddLine(TEXT.bagsRecentTip, 1, 1, 1, true) end
    if Menus.Takes(key) then Hint(tip, TEXT.bagsDropTip) end
    Hint(tip, TEXT.bagsHeadTip)
    tip:Show()
end
