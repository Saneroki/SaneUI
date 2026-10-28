local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Window
--  The loot window: a page of the journal (Core.Journal) whose title is what
--  is looted (the corpse's name, Fishing, Loot), a line for each thing it
--  holds (Row.lua), and at its foot a pencil box Take all. It opens where the
--  mouse is, its first line under it, or where it was placed in Edit Mode
--  (switch At the mouse); more lines than a good part of the screen scroll.
--
--  As the loot opens, the player's rules take what they want at once
--  (Slots.Wanted); those lines are not shown. The game's own Auto Loot takes
--  everything itself: the window then shows only if something is left a
--  moment later (bags full, a thing locked to a roll).
--
--  A click on a line takes the thing (LootSlot, as the game's window does: the
--  game asks itself for one that binds when picked up); a master looter's click
--  on a thing for the group opens the menu of who may have it (Master.lua).
--  Shift-click links it, Ctrl-click tries it on (the game's modified clicks);
--  Alt-click puts it on the player's loot list or takes it off. Closing the
--  window closes the loot (CloseLoot); Esc closes it (Core.Escape).
--
--      Window.Start()   listens to the loot's events; places it for Edit Mode
--      Window.Fill()    the lines anew, as the loot holds them now
--      Window.Place()   at the mouse or at its place, while it is open
--      Window.Close()   closes it and the loot
--      Window.Shown(), Window.frame
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Window = {}
ns.Window = Window

local panel, look, scroll, sheet, foot, take, placed
local rows = {}
local lines = {}      -- what the loot holds now (Slots.Read), less what the rules are taking
local taking = {}     -- [slot] = true: taken at once, waiting for the game to clear it
local open = false    -- the loot is open and the window is ours
local sample = false  -- shown in Edit Mode only, to be placed
local fromItem = false

-- What is looted: the corpse you look at, Fishing, else the game's word Loot.
local function Source()
    if Core.Ask(rawget(_G, "IsFishingLoot")) then return ns.TEXT.fishing end
    if not fromItem then
        for _, unit in ipairs({ "target", "softinteract", "mouseover" }) do
            if Core.Ask(UnitExists, unit) and Core.Ask(UnitIsDead, unit) then
                local name = Core.Ask(UnitName, unit)
                if name then return name end
            end
        end
    end
    return ns.TEXT.title
end

-------------------------------------------------------------------------------
--  The lines
-------------------------------------------------------------------------------
local function Tip(row)
    local line = row.line
    if not line or sample then return end
    row.shade:Show()
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if line.kind == "item" then
        GameTooltip:SetLootItem(line.slot)
    elseif line.kind == "currency" and GameTooltip.SetLootCurrency then
        GameTooltip:SetLootCurrency(line.slot)
    else
        GameTooltip:SetText(line.name)
    end
    if line.id and ns.options.kept[line.id] then GameTooltip:AddLine(ns.TEXT.onList, J.LIT[1], J.LIT[2], J.LIT[3], true) end
    GameTooltip:Show()
end

local function Untip(row)
    row.shade:Hide()
    GameTooltip_Hide()
end

-- Alt-click: the thing on the player's list, or off it.
local function Keep(line)
    if not line.id then return end
    local kept = ns.options.kept
    local name = line.link or line.name
    if kept[line.id] then
        kept[line.id] = nil
        ns.Print(ns.TEXT.unlisted:format(name))
    else
        kept[line.id] = true
        ns.Print(ns.TEXT.listed:format(name))
    end
end

-- One thing taken, as the game's window takes it; a master looter's thing goes to the menu instead.
local function Take(line, row)
    if line.locked then return end
    if ns.Master.Gives(line) then return ns.Master.Open(row, line) end
    LootSlot(line.slot)
end

local function Click(row)
    local line = row.line
    if not line or sample then return end
    if IsAltKeyDown() then return Keep(line) end
    if IsModifiedClick() then
        local link = line.link or Core.Plain(GetLootSlotLink(line.slot))
        if link then HandleModifiedItemClick(link) end
        return
    end
    Take(line, row)
end

local function TakeAll()
    if sample then return end
    for _, line in ipairs(lines) do
        if not line.locked and not ns.Master.Gives(line) then LootSlot(line.slot) end
    end
end

local function Row(index)
    local row = rows[index]
    if row then return row end
    row = ns.Row.New(sheet)
    row:SetScript("OnClick", ns.Guard(Click))
    row:SetScript("OnEnter", ns.Guard(Tip))
    row:SetScript("OnLeave", ns.Guard(Untip))
    rows[index] = row
    return row
end

local function Wheel(_, delta)
    local most = math.max(0, sheet:GetHeight() - scroll:GetHeight())
    local at = math.min(most, math.max(0, scroll:GetVerticalScroll() - delta * S.row))
    scroll:SetVerticalScroll(at)
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
local function TakeLit(on) take.box:SetStrong(on) end

local function TakeTip(button)
    TakeLit(true)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.TEXT.takeAll)
    GameTooltip:AddLine(ns.TEXT.takeAllTip, 1, 1, 1, true)
    GameTooltip:Show()
end

local function TakeUntip()
    TakeLit(false)
    GameTooltip_Hide()
end

-- Hidden by the game (its whole interface for a movie) or by us: the loot is closed with it.
local function Hidden()
    Core.Escape(panel, nil)
    ns.Safe("full", ns.Full.Hide)
    if open then
        open = false
        CloseLoot()
    end
end

local function Build()
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    Window.frame = panel
    look = J.Dress(panel, ns.TEXT.title)
    look.close:SetScript("OnClick", ns.Guard(function() Window.Close() end))
    panel:SetScript("OnHide", ns.Guard(Hidden))

    foot = CreateFrame("Frame", nil, look.content)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetPoint("BOTTOMRIGHT")
    foot:SetHeight(S.foot)
    take = CreateFrame("Button", nil, foot)
    take.text = take:CreateFontString(nil, "ARTWORK")
    J.Font(take.text, 13, true)
    take.text:SetPoint("CENTER")
    take.text:SetText(ns.TEXT.takeAll)
    take:SetSize(math.max(S.foot * 3, (tonumber(take.text:GetStringWidth()) or 0) + 4 * S.gap), S.foot - 4)
    take:SetPoint("RIGHT", foot, "RIGHT", 0, 0)
    take.box = J.Box(take, 0.5)
    TakeLit(false)
    take:SetScript("OnClick", ns.Guard(TakeAll))
    take:SetScript("OnEnter", ns.Guard(TakeTip))
    take:SetScript("OnLeave", ns.Guard(TakeUntip))
    foot.empty = foot:CreateFontString(nil, "ARTWORK")
    J.Font(foot.empty, 12, false, J.FAINT)
    foot.empty:SetPoint("LEFT")
    foot.empty:SetText(ns.TEXT.empty)

    scroll = CreateFrame("ScrollFrame", nil, look.content)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", 0, S.gap / 2)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(Wheel))
    sheet = CreateFrame("Frame", nil, scroll)
    sheet:SetSize(S.width, 1)
    scroll:SetScrollChild(sheet)

    placed = Core.Window.New(panel, { store = Core.Store(ns.name), key = "windowPlace", title = ns.TEXT.window,
                                       first = { point = "LEFT", x = 80, y = 120 } })
end

-- The first line's middle under the mouse, as near as the screen lets it (the window is clamped to it).
local function AtMouse()
    local scale = panel:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    local left, top = look.content:GetLeft(), look.content:GetTop()
    local dx = left and (left - (panel:GetLeft() or 0)) or 0
    local dy = top and ((panel:GetTop() or 0) - top) or 0
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - dx - S.icon / 2, y + dy + S.row / 2)
end

function Window.Place()
    if not panel or not panel:IsShown() then return end
    if ns.options.atMouse and not sample then AtMouse() else placed:Place() end
end

-- The lines as the loot holds them now: the rows laid out, the window as high as they are (to a share of the
-- screen; the rest scrolls), the foot's Take all while there is anything to take.
function Window.Fill()
    if not panel or not panel:IsShown() then return end
    local notes = ns.options.notes
    local shown = 0
    for _, line in ipairs(lines) do
        if not taking[line.slot] then
            shown = shown + 1
            local row = Row(shown)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -(shown - 1) * S.row)
            row:SetPoint("RIGHT", sheet, "RIGHT")
            ns.Row.Set(row, line, notes)
        end
    end
    for index = shown + 1, #rows do
        rows[index]:Hide()
        rows[index].line = nil
    end
    local height = math.max(shown, 1) * S.row
    sheet:SetSize(S.width, height)
    local _, chrome = J.Outer(S.width, 0)
    local screen = tonumber(UIParent:GetHeight()) or 0
    if screen <= 0 then screen = 768 end -- not laid out yet: the UI's own height at scale 1
    local room = screen * S.room - chrome - S.foot
    panel:SetSize(J.Outer(S.width, math.min(height, room) + S.foot + S.gap / 2))
    take:SetShown(shown > 0)
    foot.empty:SetShown(shown == 0)
    Wheel(nil, 0)
    ns.Safe("full", ns.Full.Update)
end

-- Reads the loot, takes at once what the rules want, and shows the rest.
local function Read()
    lines = ns.Slots.Read()
    wipe(taking)
    for _, line in ipairs(lines) do
        if ns.Slots.Wanted(line, ns.options) and not ns.Master.Gives(line) then
            taking[line.slot] = true
            LootSlot(line.slot)
        end
    end
end

local function Remaining()
    local count = 0
    for _, line in ipairs(lines) do
        if not taking[line.slot] then count = count + 1 end
    end
    return count
end

local function Show()
    if not open then return end
    if not panel then Build() end
    sample = false
    look.title:SetText(Source())
    panel:Show()
    panel:Raise()
    Window.Fill()
    Window.Place()
    Core.Escape(panel, function() ns.Guarded(Window.Close) end)
end

-- A moment after the loot opened without the window (the game's Auto Loot or the rules took it all): what is still
-- there (bags full, a thing locked to a roll) shows after all.
local function Check()
    if not open or (panel and panel:IsShown()) or #lines == 0 then return end
    wipe(taking)
    Show()
end
local late = Core.Later(function() ns.Guarded(Check) end, 0.4)

local function Opened(auto, item)
    if not ns.Game.Window() then return end
    if sample and panel then -- in Edit Mode: the sample goes, the loot comes
        sample = false
        panel:Hide()
    end
    open, fromItem = true, item and true or false
    Read()
    if auto or Remaining() == 0 then return late() end
    Show()
    if fromItem then Core.Sound("UI_CONTAINER_ITEM_OPEN")
    elseif Core.Ask(rawget(_G, "IsFishingLoot")) then Core.Sound("FISHING_REEL_IN") end
end

local function Find(slot)
    for index, line in ipairs(lines) do
        if line.slot == slot then return index, line end
    end
    return nil
end

local function Cleared(slot)
    if not open then return end
    local index = Find(slot)
    if index then table.remove(lines, index) end
    taking[slot] = nil
    if #lines == 0 then return Window.Close() end -- all taken: the loot closes, shown or not
    Window.Fill()
end

-- A thing the rules took could not be taken (the bags are full): its line shows again.
local function Refused(_, message)
    if not open or message ~= rawget(_G, "ERR_INV_FULL") then return end
    wipe(taking)
    Window.Fill()
end

local function Changed(slot)
    if not open then return end
    local index = Find(slot)
    if not index then return end
    local line = ns.Slots.Line(slot)
    if line then lines[index] = line else table.remove(lines, index) end
    Window.Fill()
end

local function Closed()
    open = false
    wipe(lines)
    wipe(taking)
    ns.Master.Close()
    if panel and panel:IsShown() and not sample then panel:Hide() end
end

function Window.Close()
    ns.Master.Close()
    if panel and panel:IsShown() then panel:Hide() end -- Hidden closes the loot
    if open then
        open = false
        CloseLoot()
    end
end

function Window.Shown()
    return panel ~= nil and panel:IsShown() and not sample
end

-- The lines on show (Full.lua reads them).
function Window.Lines()
    return lines
end

-- In Edit Mode the window shows, empty, to be placed where it opens while At the mouse is off (on, its place is
-- the mouse's: nothing to place).
local function Edit(on)
    if open then return end
    if on and ns.Game.Window() and not ns.options.atMouse then
        if not panel then Build() end
        sample = true
        wipe(lines)
        look.title:SetText(ns.TEXT.title)
        panel:Show()
        Window.Fill()
        placed:Place()
    elseif sample and panel then
        panel:Hide()
        sample = false
    end
end

function Window.Start()
    ns.On("LOOT_OPENED", ns.Guard(Opened))
    ns.On("LOOT_SLOT_CLEARED", ns.Guard(Cleared))
    ns.On("LOOT_SLOT_CHANGED", ns.Guard(Changed))
    ns.On("LOOT_CLOSED", ns.Guard(Closed))
    ns.On("UI_ERROR_MESSAGE", ns.Guard(Refused))
    Core.EditMode.Watch(ns.Guard(Edit))
end

function Window.GiveBack()
    sample = false
    if panel and panel:IsShown() then panel:Hide() end
    if panel then Core.Escape(panel, nil) end
    open = false
end
