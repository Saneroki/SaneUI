local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Gear
--  The equipment manager of the stats' window's sidebar (Sidebar.lua), as the
--  game's sheet has it (Camelot's EquipmentManagerPane): your gear sets
--  (C_EquipmentSet) in the game's cards (the set's icon in its frame, its name,
--  red while an item of it is lost, a tick on the set you wear, lit while
--  chosen or under the mouse). A click chooses a set, a double click puts it
--  on; under the list the game's buttons Equip and Save (the chosen set, Save
--  after a question) and New Set (its name asked; the game's question mark as
--  its icon). A right click on a set offers to rename or delete it.
--
--  The game's own sheet opens its icon picker for a new set (a frame of the
--  game's that our code must not show); here a new set takes the game's
--  question mark, and its icon is changed on the game's own sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Gear = {}
ns.Gear = Gear

-- The game's sizes (PaperDollFrame.xml): a card, its art, the icon; the list in the pane; the buttons.
Gear.ROW = 44
Gear.CARD = { 152, 49 }
Gear.ICON = 36
Gear.INSET = { 5, 8, 20, 105 }
Gear.BUTTON = { 99, 28 }
Gear.NEW = { 180, 34 }
Gear.QUESTION = 134400 -- the game's question mark (Interface\Icons\INV_Misc_QuestionMark)

local list, equip, save, new
local chosen -- the chosen set's ID

local function Sets()
    return rawget(_G, "C_EquipmentSet") or {}
end

local function Info(id)
    return Core.Ask(Sets().GetEquipmentSetInfo, id)
end

local function Errors(text)
    local errors = rawget(_G, "UIErrorsFrame")
    if errors and text then errors:AddMessage(text, 1.0, 0.1, 0.1, 1.0) end
end

-- The chosen set put on, as the game's Equip does (not with a locked item in it, nor while casting).
local function Wear(id)
    if not id then return end
    if Core.Ask(Sets().EquipmentSetContainsLockedItems, id) or UnitCastingInfo("player") then
        return Errors(Core.Word("ERR_CLIENT_LOCKED_OUT", "You can't do that right now."))
    end
    Core.Sound("IG_CHARACTER_INFO_TAB")
    Core.Ask(Sets().UseEquipmentSet, id)
end

local function Save()
    if not chosen then return end
    local id = chosen
    Core.Confirm(Core.Word("CONFIRM_SAVE_EQUIPMENT_SET", "Save %s with the items you wear now?"), (Info(id)), function()
        Core.Ask(Sets().SaveEquipmentSet, id)
    end)
end

local function New()
    Core.AskText(Core.Word("GEARSETS_POPUP_TEXT", "Name of the new set:"), nil, Core.Word("ACCEPT", "Accept"), nil, function(name)
        name = strtrim(name or "")
        if name ~= "" then Core.Ask(Sets().CreateEquipmentSet, name, Gear.QUESTION) end
    end, 16)
end

local function Rename(id)
    local name, icon = Info(id)
    Core.AskText(Core.Word("GEARSETS_POPUP_TEXT", "Name of the set:"), nil, Core.Word("ACCEPT", "Accept"), name, function(newName)
        newName = strtrim(newName or "")
        if newName ~= "" then Core.Ask(Sets().ModifyEquipmentSet, id, newName, icon) end
    end, 16)
end

local function Delete(id)
    Core.Confirm(Core.Word("CONFIRM_DELETE_EQUIPMENT_SET", "Delete the set %s?"), (Info(id)), function()
        Core.Ask(Sets().DeleteEquipmentSet, id)
    end, true)
end

-- The menu's two entries for a set.
local function Entries(root, id)
    root:CreateButton(Core.Word("RENAME", "Rename"), function() ns.Safe("character", Rename, id) end)
    root:CreateButton(Core.Word("DELETE", "Delete"), function() ns.Safe("character", Delete, id) end)
end

-- A right click on a set: the game's menu with rename and delete.
local function Menu(row)
    local util = rawget(_G, "MenuUtil")
    if not (util and util.CreateContextMenu) then return end
    local id = row.data.id
    util.CreateContextMenu(row, function(_, root) ns.Safe("character", Entries, root, id) end)
end

local function Clicked(row, which)
    if which == "RightButton" then return Menu(row) end
    chosen = row.data.id
    Gear.Refresh()
end

local function Doubled(row)
    Wear(row.data.id)
end

local function Lit(row, on)
    row.lit:SetShown(on)
end

-- A card of the game's look (GearSetButtonTemplate), made once.
local function Parts(row)
    if row.text then return end
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function Card(atlas)
        local card = row:CreateTexture(nil, "BACKGROUND")
        card:SetAtlas(atlas)
        card:SetSize(Gear.CARD[1], Gear.CARD[2])
        card:SetPoint("TOPLEFT", 42, 0)
        return card
    end
    Card("UI-Character-Info-OutfitCard")
    row.lit = Card("UI-Character-Info-OutfitCard-Hover")
    row.chosen = Card("UI-Character-Info-OutfitCard-Selected")
    row.check = row:CreateTexture(nil, "BORDER")
    row.check:SetAtlas("UI-Character-Info-Icon-Tick", true)
    row.check:SetPoint("RIGHT", -23, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK", nil, -1)
    row.icon:SetSize(Gear.ICON, Gear.ICON)
    row.icon:SetPoint("LEFT", 4, 0)
    local frame = row:CreateTexture(nil, "ARTWORK")
    frame:SetAtlas("UI-Character-Info-OutfitIcon-Frame", true)
    frame:SetPoint("CENTER", row.icon)
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
    row.text:SetSize(98, 38)
    row.text:SetPoint("LEFT", 55, 0)
    row:SetScript("OnClick", function(self, which) ns.Safe("character", Clicked, self, which) end)
    row:SetScript("OnDoubleClick", function(self) ns.Safe("character", Doubled, self) end)
    row:SetScript("OnEnter", function(self) ns.Safe("character", Lit, self, true) end)
    row:SetScript("OnLeave", function(self) ns.Safe("character", Lit, self, false) end)
end

local function Draw(row, data)
    Parts(row)
    row.data = data
    row.text:SetText(data.name or "")
    local color = (data.lost or 0) > 0 and rawget(_G, "RED_FONT_COLOR") or rawget(_G, "NORMAL_FONT_COLOR")
    if color then row.text:SetTextColor(color.r, color.g, color.b) end
    row.icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.check:SetShown(data.worn and true or false)
    row.chosen:SetShown(data.id == chosen)
    row.lit:SetShown(row:IsMouseOver())
end

local function Extent()
    return Gear.ROW
end

-- Your sets as the game has them now (the game's order: by name), the chosen one's buttons.
function Gear.Refresh()
    if not list then return end
    local sets = {}
    for _, id in ipairs(Core.Ask(Sets().GetEquipmentSetIDs) or {}) do
        local name, icon, setID, worn, _, _, _, lost = Sets().GetEquipmentSetInfo(id)
        if name then sets[#sets + 1] = { id = setID or id, name = name, icon = icon, worn = worn, lost = lost } end
    end
    table.sort(sets, function(a, b) return a.name < b.name end)
    local found
    for _, set in ipairs(sets) do found = found or (set.id == chosen and set) end
    if not found then chosen = nil end
    ns.List.Fill(list, sets)
    local can = found and not found.worn
    equip:SetEnabled(can and true or false)
    save:SetEnabled(can and true or false)
end

-- Whether the game offers the equipment manager (its sidebar greys the tab out otherwise).
function Gear.Usable()
    local lfg = rawget(_G, "C_LFGInfo")
    return (Core.Ask(Sets().GetNumEquipmentSets) or 0) > 0 or (lfg and lfg.CanPlayerUseLFD and Core.Ask(lfg.CanPlayerUseLFD)) and true or false
end

function Gear.Build(pane)
    list = ns.List.New(pane, { inset = Gear.INSET, extent = Extent, draw = Draw })
    equip = CreateFrame("Button", nil, pane, "SharedButtonSmallTemplate")
    equip:SetSize(Gear.BUTTON[1], Gear.BUTTON[2])
    equip:SetPoint("BOTTOM", -50, 20)
    equip:SetText(Core.Word("EQUIPSET_EQUIP", "Equip"))
    equip:SetScript("OnClick", function() ns.Safe("character", Wear, chosen) end)
    save = CreateFrame("Button", nil, pane, "SharedButtonSmallTemplate")
    save:SetSize(Gear.BUTTON[1], Gear.BUTTON[2])
    save:SetPoint("BOTTOM", 50, 20)
    save:SetText(Core.Word("SAVE", "Save"))
    save:SetScript("OnClick", function() ns.Safe("character", Save) end)
    new = CreateFrame("Button", nil, pane, "PaperDollTertiaryButtonTemplate")
    new:SetSize(Gear.NEW[1], Gear.NEW[2])
    new:SetPoint("BOTTOM", 0, 50)
    new:SetText(Core.Word("PAPERDOLL_NEWEQUIPMENTSET", "New Set"))
    local plus = new:CreateTexture(nil, "ARTWORK")
    plus:SetAtlas("UI-Character-Info-Icon-Add", true)
    plus:SetPoint("LEFT", 13, 0)
    new:SetScript("OnClick", function() ns.Safe("character", New) end)
end

local later = Core.Later(function() ns.Safe("character", Gear.Refresh) end)
local EVENTS = { "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_EQUIPMENT_CHANGED" }

function Gear.Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if on then Gear.Refresh() end
end
