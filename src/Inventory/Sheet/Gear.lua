local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Gear
--  The equipment manager, a window of its own on the module's board (the key
--  "gear", Board.lua) on the journal's page, as the game's sheet has it (Camelot's EquipmentManagerPane): your gear sets
--  (C_EquipmentSet) in lines on the journal's page (the set's icon in a pencil
--  slot, its name, red while an item of it is lost, the pencil's tick on the
--  set you wear, shaded while chosen or under the mouse). A click chooses a
--  set, a double click puts it on; under the list buttons drawn in pencil:
--  Equip and Save (the chosen set, Save after a question) and New Set (its
--  name asked; the game's question mark as its icon). As on the game's sheet, a save leaves out the slots the set
--  leaves out, and a new set the shirt and the tabard. A right click on a set
--  offers to rename or delete it.
--
--  The game's own sheet opens its icon picker for a new set (a frame of the
--  game's that our code must not show); here a new set takes the game's
--  question mark, and its icon is changed on the game's own sheet.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Gear = {}
ns.Gear = Gear

-- A set's line, its icon; the list in the pane (room under it for the buttons); a button, the gap between two.
local Fit = ns.Paper.Fit
Gear.ROW = Fit(40)
Gear.ICON = Fit(30)
Gear.INSET = { 10, 4, 24, Fit(30) + 20 }
Gear.BUTTON = Fit(26)
Gear.BUTTON_GAP = 8
Gear.TICK = "\226\136\154" -- the tick drawn by hand: Kalam's root sign (the style's checkbox)
Gear.QUESTION = 134400 -- the game's question mark (Interface\Icons\INV_Misc_QuestionMark)
Gear.LEFT_OUT = { 4, 19 } -- the slots a new set leaves out, as the game's sheet has it: the shirt, the tabard

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
    if Core.Ask(Sets().EquipmentSetContainsLockedItems, id) or Core.Ask(UnitCastingInfo, "player") then
        return Errors(Core.Word("ERR_CLIENT_LOCKED_OUT", "You can't do that right now."))
    end
    Core.Sound("IG_CHARACTER_INFO_TAB")
    Core.Ask(Sets().UseEquipmentSet, id)
end

-- The slots the save to come leaves out (the game notes them for its next save), as the game's sheet sets them: a
-- set's own (id), or for a new set (nil) the shirt and the tabard. The note is cleared again once saved (Saved).
local function LeaveOut(id)
    local sets = Sets()
    Core.Ask(sets.ClearIgnoredSlotsForSave)
    if not id then
        for _, slot in ipairs(Gear.LEFT_OUT) do Core.Ask(sets.IgnoreSlotForSave, slot) end
        return
    end
    local slots = Core.Ask(sets.GetIgnoredSlots, id)
    for slot, ignored in pairs(type(slots) == "table" and slots or {}) do
        if ignored then Core.Ask(sets.IgnoreSlotForSave, slot) else Core.Ask(sets.UnignoreSlotForSave, slot) end
    end
end

local function Saved()
    Core.Ask(Sets().ClearIgnoredSlotsForSave)
end

local function Save()
    if not chosen then return end
    local id = chosen
    Core.Confirm(Core.Word("CONFIRM_SAVE_EQUIPMENT_SET", "Save %s with the items you wear now?"), (Info(id)), function()
        LeaveOut(id)
        Core.Ask(Sets().SaveEquipmentSet, id)
        Saved()
    end)
end

local function New()
    Core.AskText(Core.Word("GEARSETS_POPUP_TEXT", "Name of the new set:"), nil, Core.Word("ACCEPT", "Accept"), nil, function(name)
        name = strtrim(name or "")
        if name == "" then return end
        LeaveOut(nil)
        Core.Ask(Sets().CreateEquipmentSet, name, Gear.QUESTION)
        Saved()
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

-- A line on the paper, made once: its shading while chosen and under the mouse, the icon in its pencil slot, the
-- name, the tick.
local function Parts(row)
    if row.text then return end
    local paper = ns.Paper
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.chosen = row:CreateTexture(nil, "BACKGROUND")
    row.chosen:SetAllPoints()
    row.chosen:SetColorTexture(paper.CHOSEN[1], paper.CHOSEN[2], paper.CHOSEN[3], paper.CHOSEN[4])
    row.lit = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.lit:SetAllPoints()
    row.lit:SetColorTexture(paper.SHADE[1], paper.SHADE[2], paper.SHADE[3], paper.SHADE[4])
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Gear.ICON, Gear.ICON)
    row.icon:SetPoint("LEFT", 6, 0)
    local slot = CreateFrame("Frame", nil, row)
    slot:SetAllPoints(row.icon)
    Core.Journal.Slot(slot, Gear.ICON * Core.Journal.SLOT_ICON)
    row.check = row:CreateFontString(nil, "ARTWORK")
    row.check:SetFontObject(paper.Font("SaneUIGearTick", 16, true))
    row.check:SetPoint("RIGHT", -8, 0)
    row.check:SetText(Gear.TICK)
    row.text = row:CreateFontString(nil, "ARTWORK")
    row.text:SetFontObject(paper.Font("SaneUIGearName", 14))
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.text:SetPoint("RIGHT", row.check, "LEFT", -6, 0)
    row:SetScript("OnClick", function(self, which) ns.Safe("character", Clicked, self, which) end)
    row:SetScript("OnDoubleClick", function(self) ns.Safe("character", Doubled, self) end)
    row:SetScript("OnEnter", function(self) ns.Safe("character", Lit, self, true) end)
    row:SetScript("OnLeave", function(self) ns.Safe("character", Lit, self, false) end)
end

local function Draw(row, data)
    Parts(row)
    row.data = data
    row.text:SetText(data.name or "")
    local red = (data.lost or 0) > 0 and rawget(_G, "RED_FONT_COLOR")
    if red then
        row.text:SetTextColor(Core.Journal.Ink(red.r, red.g, red.b))
    else
        row.text:SetTextColor(ns.Paper.INK[1], ns.Paper.INK[2], ns.Paper.INK[3])
    end
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

-- A button drawn in pencil on the paper (the style's buttons on the paper): a pencil box, its word in Kalam,
-- the box drawn stronger under the mouse, faded while it does nothing.
local function Faded(button)
    local on = button:IsEnabled()
    button.box:SetStrong(on and button:IsMouseOver())
    if not on then
        for _, part in ipairs(button.box.parts) do part:SetAlpha(0.35) end
    end
    button.text:SetAlpha(on and 1 or 0.45)
end

local function Pencil(pane, word, onClick)
    local button = CreateFrame("Button", nil, pane)
    button:SetHeight(Gear.BUTTON)
    button.box = Core.Journal.Box(button, 0.5)
    button.text = button:CreateFontString(nil, "ARTWORK")
    button.text:SetFontObject(ns.Paper.Font("SaneUIGearButton", 14))
    button.text:SetPoint("CENTER")
    button:SetFontString(button.text)
    button:SetText(word)
    button:SetScript("OnClick", function() ns.Safe("character", onClick) end)
    button:SetScript("OnEnter", function(self) ns.Safe("character", Faded, self) end)
    button:SetScript("OnLeave", function(self) ns.Safe("character", Faded, self) end)
    button:SetScript("OnEnable", function(self) ns.Safe("character", Faded, self) end)
    button:SetScript("OnDisable", function(self) ns.Safe("character", Faded, self) end)
    Faded(button)
    return button
end

-- The window's body: the list, and under it the three buttons sharing the list's width.
function Gear.Build(pane)
    list = ns.List.New(pane, { inset = Gear.INSET, extent = Extent, draw = Draw, paper = true })
    new = Pencil(pane, Core.Word("PAPERDOLL_NEWEQUIPMENTSET", "New Set"), New)
    equip = Pencil(pane, Core.Word("EQUIPSET_EQUIP", "Equip"), function() Wear(chosen) end)
    save = Pencil(pane, Core.Word("SAVE", "Save"), Save)
    local inset, gap = Gear.INSET, Gear.BUTTON_GAP
    new:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", inset[1], 12)
    new:SetPoint("RIGHT", pane, "CENTER", -gap / 2, 0)
    equip:SetPoint("BOTTOMLEFT", pane, "BOTTOM", gap / 2, 12)
    equip:SetPoint("RIGHT", save, "LEFT", -gap, 0)
    save:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -inset[1], 12)
    save:SetWidth(math.max(save.text:GetUnboundedStringWidth() + 24, Fit(64)))
end

local later = Core.Later(function() ns.Safe("character", Gear.Refresh) end)
local EVENTS = { "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_EQUIPMENT_CHANGED" }

function Gear.Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if on then Gear.Refresh() end
end

ns.Board.Part("gear", Core.Word("PAPERDOLL_EQUIPMENTMANAGER", "Equipment Manager"), ns.Board.Least("gear", 260, 300), {
    Build = function(panel) Gear.Build(panel.body) end,
    Show = Gear.Show,
})
