local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Menus
--  What the player chooses about the bag window's items and groups (kept by
--  Groups.lua), by the game's menus (MenuUtil) and by letting items go over a
--  group's head:
--      an item    Alt and a right click on it (a click the game's button does
--                 nothing with): Pinned; Junk (an item with a price); Put
--                 Into one of the groups (its own takes it out again) or a new
--                 one; Take Out of a group of the player's own
--      a group    a right click on its head: Rename, Move Up and Move Down
--                 (past the groups shown), Join With another (a group of the
--                 game's), Hide, Delete (one of the player's own, asked
--                 first), each group joined into it shown by itself again;
--                 New Group
--      a drop     an item let go over a group's head (dragged there, or picked
--                 up and clicked there) is put into that group: into Pinned it
--                 is pinned, into Junk marked as junk, into its own group taken
--                 out again; the item goes back to its slot
--      View       the window's dropdown: Groups, every group with a tick while
--                 it is shown; New Group
--  Each choice is kept at once and the window drawn anew.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Menus = {}
ns.Menus = Menus

local Contents, Groups = ns.Contents, ns.Groups
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

-------------------------------------------------------------------------------
--  New groups
-------------------------------------------------------------------------------
-- A group of the player's own made, named in the game's dialog; then (id) that item put into it.
local function New(id, natural)
    Core.AskText(TEXT.bagsNewAsk, nil, ACCEPT, "", function(text)
        local key = Groups.New(text)
        if not key then return end
        if id then Groups.PutInto(id, key, natural) end
        Changed()
    end, Groups.LETTERS)
end
local NewGroup = ns.Guard(function() New() end)

-------------------------------------------------------------------------------
--  An item's menu
-------------------------------------------------------------------------------
local item = {} -- what the open menu is about: id, name, natural, classed, worthless

local function IsPinned() return Groups.Pinned(item.id) end
local function TogglePin()
    Groups.Pin(item.id, not Groups.Pinned(item.id))
    Changed()
end
local function IsJunk() return Groups.Home(item.id, item.natural) == Groups.JUNK end
local function ToggleJunk()
    Groups.MarkJunk(item.id, not IsJunk(), item.natural, item.classed)
    Changed()
end
local function IsIn(key) return Groups.Home(item.id, item.natural) == key end
local function PutIn(key)
    Groups.PutInto(item.id, key, item.natural)
    Changed()
end
local function TakeOut()
    Groups.PutInto(item.id, nil, item.natural)
    Changed()
end
local Pinned = ns.Guard(IsPinned)
local Pin = ns.Guard(TogglePin)
local Junk = ns.Guard(IsJunk)
local MarkJunk = ns.Guard(ToggleJunk)
local In = ns.Guard(IsIn)
local Put = ns.Guard(PutIn)
local Out = ns.Guard(TakeOut)
local NewFor = ns.Guard(function() New(item.id, item.natural) end)

local function FillItem(_, root)
    root:CreateTitle(item.name)
    root:CreateCheckbox(TEXT.bagsPinned, Pinned, Pin)
    if not item.worthless then root:CreateCheckbox(Contents.GROUP.junk.word, Junk, MarkJunk) end
    local into = root:CreateButton(TEXT.bagsPutInto)
    for _, key in ipairs(Groups.list) do
        if Groups.Takes(key) then into:CreateRadio(Groups.Word(key), In, Put, key) end
    end
    into:CreateDivider()
    into:CreateButton(TEXT.bagsNew, NewFor)
    local home = Groups.Home(item.id, item.natural)
    if Groups.Own(home) then root:CreateButton(TEXT.bagsTakeOut:format(Groups.Word(home)), Out) end
end
local ItemMenu = ns.Guard(FillItem)

-- The menu of the item in a button of ours (Cells.lua: its holder carries the bag, the button the slot).
function Menus.Item(button)
    local slots = Contents.records[button:GetParent():GetID()]
    local record = slots and slots[button:GetID()]
    if not (record and record.item and rawget(_G, "MenuUtil")) then return end
    item.id, item.name, item.natural, item.worthless = record.item, record.name, record.natural, record.worthless
    item.classed = Contents.Classed(record)
    MenuUtil.CreateContextMenu(button, ItemMenu)
end

-------------------------------------------------------------------------------
--  A group's head
-------------------------------------------------------------------------------
local group -- the group the open menu is about

local function Rename()
    local key = group
    if Groups.FIXED[key] then return end
    local word = Groups.Word(key)
    local ask = Groups.Own(key) and TEXT.bagsRenameAsk or TEXT.bagsRenameGameAsk
    Core.AskText(ask, word, ACCEPT, word, function(text)
        if Groups.Rename(key, text) then Changed() end
    end, Groups.LETTERS)
end
local function MoveBy(step)
    if Groups.Move(group, step, ns.Bags.drawn) then Changed() end
end
local function JoinInto(into)
    if Groups.Join(group, into) then Changed() end
end
local function HideGroup()
    if Groups.Hide(group, true) then Changed() end
end
local function DeleteGroup()
    local key = group
    Core.Confirm(TEXT.bagsDeleteAsk, Groups.Word(key), function()
        if Groups.Delete(key) then Changed() end
    end, true)
end
local function Separate(other)
    if Groups.Join(other, nil) then Changed() end
end
local Renamed = ns.Guard(Rename)
local Move = ns.Guard(MoveBy)
local Join = ns.Guard(JoinInto)
local Hide = ns.Guard(HideGroup)
local Delete = ns.Guard(DeleteGroup)
local Apart = ns.Guard(Separate)

local function FillHead(_, root)
    local key = group
    root:CreateTitle(Groups.Word(key))
    if not Groups.FIXED[key] then
        local shown = ns.Bags.drawn
        root:CreateButton(TEXT.bagsRename, Renamed)
        root:CreateButton(TEXT.bagsUp, Move, -1):SetEnabled(Groups.Move(key, -1, shown, true))
        root:CreateButton(TEXT.bagsDown, Move, 1):SetEnabled(Groups.Move(key, 1, shown, true))
        if Groups.Joins(key) then
            local join = root:CreateButton(TEXT.bagsJoin)
            for _, other in ipairs(Groups.list) do
                if Groups.TakesIn(other, key) then join:CreateButton(Groups.Word(other), Join, other) end
            end
        end
        root:CreateButton(Core.Word("HIDE", "Hide"), Hide)
        if Groups.Own(key) then root:CreateButton(Core.Word("DELETE", "Delete"), Delete) end
        local titled = false
        for _, other in ipairs(Groups.list) do
            if other ~= key and Groups.Shown(other) == key then
                if not titled then
                    root:CreateDivider()
                    root:CreateTitle(TEXT.bagsJoined)
                    titled = true
                end
                root:CreateButton(TEXT.bagsApart:format(Groups.Word(other)), Apart, other)
            end
        end
    end
    root:CreateDivider()
    root:CreateButton(TEXT.bagsNew, NewGroup)
end
local HeadMenu = ns.Guard(FillHead)

-- A right click on a group's head: its menu.
function Menus.Head(head, key)
    if not (key and rawget(_G, "MenuUtil")) then return end
    group = key
    MenuUtil.CreateContextMenu(head, HeadMenu)
end

-- Whether items can be let go over a group's head: Pinned, Junk and the groups items are put into.
function Menus.Takes(key)
    return key == Groups.PINNED or key == Groups.JUNK or key ~= nil and Groups.Takes(key)
end

-- The game's group of an item in the bags (nil: none of them holds it now).
local function Natural(id)
    for _, slots in pairs(Contents.records) do
        for _, record in pairs(slots) do
            if record.item == id then return record.natural end
        end
    end
end

-- The item on the cursor let go over a group's head: put into that group, back to its slot.
function Menus.Drop(key)
    if not Menus.Takes(key) then return false end
    local kind, id = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return false end
    Groups.PutInto(id, key, Natural(id))
    ClearCursor()
    Changed()
    return true
end

-- A group head's tooltip: what can be done there.
function Menus.Tip(head, key)
    local tip = GameTooltip
    tip:SetOwner(head, "ANCHOR_TOP")
    tip:SetText(Groups.Word(key), 1, 0.82, 0)
    if Menus.Takes(key) then Hint(tip, TEXT.bagsDropTip) end
    Hint(tip, TEXT.bagsHeadTip)
    Hint(tip, TEXT.bagsItemTip)
    tip:Show()
end

-------------------------------------------------------------------------------
--  The dropdown View
-------------------------------------------------------------------------------
local function IsShown(key) return not Groups.Hidden(key) end
local function ToggleShown(key)
    if Groups.Hide(key, not Groups.Hidden(key)) then Changed() end
end
local Shown = ns.Guard(IsShown)
local Show = ns.Guard(ToggleShown)

-- The groups at the foot of the dropdown View: each shown or hidden, a new one.
function Menus.View(root)
    root:CreateDivider()
    local groups = root:CreateButton(TEXT.bagsGroupsMenu)
    for _, key in ipairs(Groups.list) do
        if not Groups.FIXED[key] and not Groups.Into(key) then groups:CreateCheckbox(Groups.Word(key), Shown, Show, key) end
    end
    root:CreateButton(TEXT.bagsNew, NewGroup)
end
