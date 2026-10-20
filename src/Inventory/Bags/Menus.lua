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

local function Changed()
    if ns.Bags then ns.Bags.Refresh() end
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
-- A category of the player's own made, named in the game's dialog; then (item) that item put into it.
local function New(item)
    Core.AskText(TEXT.bagsNewAsk, nil, ACCEPT, "", function(text)
        local key = Categories.New(text, Categories.OWN_ICON)
        if not key then return end
        if item then Categories.Assign(item, key) end
        Changed()
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
    Categories.MarkJunk(item.id, not IsJunk())
    if not IsJunk() and item.quality == ns.Contents.POOR then
        -- A grey item unmarked: kept out of Junk by putting it where its kind goes.
        Categories.Assign(item.id, Categories.CATCH_ALL)
    end
    Changed()
end
local function IsIn(key) return item.category == key end
local function PutIn(key)
    Categories.Assign(item.id, key)
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
    local key = about.key
    if about.group then key = Categories.Members(about.group)[step < 0 and 1 or #Categories.Members(about.group)] end
    Categories.Move(key, step)
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
local function Off()
    Categories.SwitchOff(about.key, true)
    if ns.Bags.Viewing() == "cat:" .. about.key then ns.Bags.Choose(nil) end
    Changed()
end
local function SetIcon(file)
    Categories.SetIcon(about.key, file)
    Changed()
end
local function IsIcon(file) return Categories.Icon(about.key) == file end
local function DeleteIt()
    local key = about.key
    Core.Confirm(TEXT.bagsDeleteAsk, Categories.Word(key), function()
        Categories.Delete(key)
        if ns.Bags.Viewing() == "cat:" .. key then ns.Bags.Choose(nil) end
        Changed()
    end, true)
end
local function HideFixed()
    ns.Bags.SetOption(ns.Bags.SHOW[about.key], false)
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
local SwitchOff = ns.Guard(Off)
local Iconed = ns.Guard(IsIcon)
local Iconize = ns.Guard(SetIcon)
local Delete = ns.Guard(DeleteIt)
local HideIt = ns.Guard(HideFixed)
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
        root:CreateButton(Core.Word("HIDE", "Hide"), HideIt)
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
    if key ~= Categories.CATCH_ALL and key ~= Categories.JUNK then root:CreateButton(TEXT.bagsOff, SwitchOff) end
    if Categories.Own(key) then
        local icons = root:CreateButton(TEXT.bagsIcon)
        for _, file in ipairs(Categories.ICONS) do icons:CreateRadio(Icon(file, 20), Iconed, Iconize, file) end
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

-- Whether items can be let go over a category: Pinned, Junk, the categories items are put into.
function Menus.Takes(key)
    return key == Categories.PINNED or key ~= nil and Categories.Takes(key)
end

-- The item on the cursor let go over a category: put into it (Pinned: pinned), back to its slot.
function Menus.Drop(key)
    if not Menus.Takes(key) then return false end
    local kind, id = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return false end
    if key == Categories.PINNED then
        Categories.Pin(id, true)
    elseif key == Categories.JUNK then
        Categories.MarkJunk(id, true)
    else
        Categories.Assign(id, key)
    end
    ClearCursor()
    Changed()
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
