local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Window
--  The loot window (Saneroki, 2026-10-29): no paper, no frame, no title; a
--  line for each thing the loot holds (Row.lua: a round plate, dark and half
--  see-through, trimmed in its quality's colour; its picture, name, kind,
--  worth and an A), and at its foot two buttons on the same plates, Link and
--  Close. It opens where the
--  mouse is, its first line's picture under it, or where it was placed in Edit
--  Mode (switch At the mouse); more lines than a good part of the screen
--  scroll.
--
--  A thing taken, the lines close up and the next one stands where the taken
--  one stood, under the mouse: at the mouse the window moves down a line when
--  the last one was taken.
--
--  As soon as the game has the loot ready (LOOT_READY, before it opens), the
--  player's rules take what they want (Slots.Wanted), a few slots in one frame
--  and the rest in the frames after, so a big pile does not flood the server;
--  those lines are not shown. Nothing is taken at first: the switches Taken at
--  once and the player's word on an item (the A) decide. The game's own Auto
--  Loot is lent off meanwhile (Game.lua); held Shift (its key) still takes
--  everything, and the window then shows only what is left a moment later
--  (bags full, a thing locked to a roll).
--
--  A click on a line takes the thing (LootSlot, as the game's window does: the
--  game asks itself for one that binds when picked up); a master looter's click
--  on a thing for the group opens the menu of who may have it (Master.lua).
--  Shift-click links it, Ctrl-click tries it on (the game's modified clicks).
--  The A (or Alt-click) puts it on the player's list, to be taken at once
--  wherever it drops, and takes it; on the list, the A takes it off. Link puts
--  the links of the loot's things into the chat box: the player sends them
--  (an addon may not send chat itself). Close, or Esc, closes the window and
--  the loot (CloseLoot).
--
--  The items met in loot are kept by their IDs (options.seen, the newest
--  first) for the options' tab Your items (Items.lua).
--
--      Window.Start()   listens to the loot's events; places it for Edit Mode
--      Window.Fill()    the lines anew, as the loot holds them now
--      Window.Place()   at the mouse or at its place, while it is open
--      Window.Close()   closes it and the loot
--      Window.Shown(), Window.Lines(), Window.frame
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local S = ns.SIZE
local Window = {}
ns.Window = Window

local LIGHT = { 0.9, 0.9, 0.9 } -- the buttons' words; gold under the mouse
local CHAT_SHOWN, CHAT_BYTES = 250, 1270 -- what the game's chat box holds: 255 letters on show, 1280 bytes with links
local STEP = S.row + S.rowGap

local panel, scroll, sheet, linkButton, closeButton, placed, driver
local rows = {}
local lines = {}      -- what the loot holds now (Slots.Read), less what the rules are taking
local taking = {}     -- [slot] = true: taken at once, waiting for the game to clear it
local asked = {}      -- [slot] = true: LootSlot called for it while this loot is open
local queue = {}      -- the slots the rules take, waiting for their frame
local open = false    -- the loot is open (or ready) and the window is ours
local met = false     -- its items noted for the tab Your items
local sample = false  -- shown in Edit Mode only, to be placed
local fromItem = false
local full, view = 0, 0  -- the lines' height, and how much of it shows
local at              -- at the mouse: the window's top left { x, y } from the screen's bottom left
local snap            -- the thing the player took: { slot, index, scroll }; the next comes to its place
local hover           -- the line under the mouse

-------------------------------------------------------------------------------
--  Taking: the rules' things as fast as the game lets them go, a few a frame
-------------------------------------------------------------------------------
local function Loot(slot)
    if asked[slot] then return end
    asked[slot] = true
    LootSlot(slot)
end

-- A few of the waiting slots now; the driver takes the rest in the frames after.
local function Drain()
    for _ = 1, S.burst do
        local slot = table.remove(queue, 1)
        if not slot then break end
        Loot(slot)
    end
    if driver then driver:SetShown(#queue > 0) end
end

local function Queue(slot)
    if asked[slot] or taking[slot] == "queued" then return end
    taking[slot] = "queued"
    queue[#queue + 1] = slot
end

-------------------------------------------------------------------------------
--  The lines
-------------------------------------------------------------------------------
local function Tip(row)
    local line = row.line
    if not line or sample then return end
    hover = row
    row.plate:SetLit(true)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if line.kind == "item" then
        GameTooltip:SetLootItem(line.slot)
    elseif line.kind == "currency" and GameTooltip.SetLootCurrency then
        GameTooltip:SetLootCurrency(line.slot)
    else
        GameTooltip:SetText(line.name)
    end
    if line.upgrade then
        GameTooltip:AddLine(line.upgrade == "empty" and ns.TEXT.upgradeEmpty or ns.TEXT.upgradeBetter, 0.1, 1, 0.1, true)
    end
    local word = line.id and ns.options.kept[line.id]
    if word == true then GameTooltip:AddLine(ns.TEXT.onList, 1, 0.82, 0, true)
    elseif word == false then GameTooltip:AddLine(ns.TEXT.offList, 0.7, 0.7, 0.7, true) end
    GameTooltip:Show()
end

local function Untip(row)
    if hover == row then hover = nil end
    row.plate:SetLit(false)
    GameTooltip_Hide()
end

-- One thing taken, as the game's window takes it; a master looter's thing goes to the menu instead.
local function Take(line, row)
    if line.locked then return end
    snap = { slot = line.slot, index = row.index or 1, scroll = scroll:GetVerticalScroll() or 0 }
    if ns.Master.Gives(line) then return ns.Master.Open(row, line) end
    LootSlot(line.slot)
end

-- The A, or Alt-click: the thing on the player's list (and taken now), or off it.
local function Keep(row)
    local line = row.line
    if not line or not line.id or sample then return end
    local kept = ns.options.kept
    if kept[line.id] == true then
        kept[line.id] = nil
        ns.Row.Auto(row, false)
    else
        kept[line.id] = true
        ns.Row.Auto(row, true)
        Take(line, row)
    end
    ns.Safe("items", ns.Items.Refresh)
end

local function Click(row)
    local line = row.line
    if not line or sample then return end
    if IsAltKeyDown() then return Keep(row) end
    if IsModifiedClick() then
        local link = line.link or Core.Plain(GetLootSlotLink(line.slot))
        if link then HandleModifiedItemClick(link) end
        return
    end
    Take(line, row)
end

local function AutoTip(button)
    local on = button.on
    button.plate:SetLit(true)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(on and ns.TEXT.autoOn or ns.TEXT.autoOff)
    GameTooltip:AddLine(on and ns.TEXT.autoOnTip or ns.TEXT.autoOffTip, 1, 1, 1, true)
    GameTooltip:Show()
end

local function AutoUntip(button)
    button.plate:SetLit(false)
    GameTooltip_Hide()
end

local function Row(index)
    local row = rows[index]
    if row then return row end
    row = ns.Row.New(sheet)
    row:SetScript("OnClick", ns.Guard(Click))
    row:SetScript("OnEnter", ns.Guard(Tip))
    row:SetScript("OnLeave", ns.Guard(Untip))
    row.auto:SetScript("OnClick", ns.Guard(function(button) Keep(button:GetParent()) end))
    row.auto:SetScript("OnEnter", ns.Guard(AutoTip))
    row.auto:SetScript("OnLeave", ns.Guard(AutoUntip))
    rows[index] = row
    return row
end

local function Wheel(_, delta)
    local most = math.max(0, full - view)
    scroll:SetVerticalScroll(math.min(most, math.max(0, (scroll:GetVerticalScroll() or 0) - delta * STEP)))
end

-------------------------------------------------------------------------------
--  Link: the loot's links into the chat box
-------------------------------------------------------------------------------
-- The links of the loot's things (items, currencies), as many as the chat box holds.
local function Links()
    local list, shown, bytes = {}, 0, 0
    for _, line in ipairs(lines) do
        local link = line.link
        if not link and line.kind == "currency" then link = Core.Plain(GetLootSlotLink(line.slot)) end
        if type(link) == "string" then
            local letters = #(link:match("|h(%[.-%])|h") or link) + 1
            if shown + letters > CHAT_SHOWN or bytes + #link + 1 > CHAT_BYTES then break end
            shown, bytes = shown + letters, bytes + #link + 1
            list[#list + 1] = link
        end
    end
    return table.concat(list, " ")
end

-- Into the chat box being written in, else the chat box opened with them: Enter sends them where the player chose.
local function LinkAll()
    if sample then return end
    local text = Links()
    if text == "" then return end
    local chat = rawget(_G, "ChatFrameUtil")
    local active = chat and chat.GetActiveWindow and chat.GetActiveWindow()
    if active then
        active:Insert(text)
        active:SetFocus()
        return
    end
    local openChat = (chat and chat.OpenChat) or rawget(_G, "ChatFrame_OpenChat")
    if openChat then openChat(text) end
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
-- A button at the window's foot: its word on a round plate as the lines', its trim grey; darker, its word gold,
-- under the mouse.
local function Button(text, onClick, tip)
    local button = CreateFrame("Button", nil, panel)
    button:SetHeight(S.foot)
    button.plate = ns.Row.Plate(button, S.radius)
    button.text = button:CreateFontString(nil, "OVERLAY")
    ns.Row.Font(button.text, 13, true)
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    button.text:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
    button:SetScript("OnClick", ns.Guard(onClick))
    button:SetScript("OnEnter", ns.Guard(function()
        button.plate:SetLit(true)
        button.text:SetTextColor(ns.Row.Gold())
        if not tip then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", ns.Guard(function()
        button.plate:SetLit(false)
        button.text:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
        GameTooltip_Hide()
    end))
    return button
end

-- Link at the left half of the foot and Close at the right; Close alone across it when there is nothing to link.
-- Their plates laid out for the window's width.
local function Foot(linkable, width)
    linkButton:SetShown(linkable)
    linkButton:ClearAllPoints()
    closeButton:ClearAllPoints()
    closeButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    local half = (width - S.gap / 2) / 2
    if linkable then
        linkButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
        linkButton:SetPoint("RIGHT", panel, "BOTTOM", -S.gap / 4, 0)
        closeButton:SetPoint("LEFT", panel, "BOTTOM", S.gap / 4, 0)
        linkButton.plate:Fit(half, S.foot)
        closeButton.plate:Fit(half, S.foot)
    else
        closeButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
        closeButton.plate:Fit(width, S.foot)
    end
end

-- Hidden by the game (its whole interface for a movie) or by us: the loot is closed with it.
local function Hidden()
    Core.Escape(panel, nil)
    ns.Safe("full", ns.Full.Hide)
    snap = nil
    if hover then Untip(hover) end
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
    panel:Hide()
    Window.frame = panel
    panel:SetScript("OnHide", ns.Guard(Hidden))

    linkButton = Button(ns.TEXT.link, LinkAll, ns.TEXT.linkTip)
    closeButton = Button(ns.TEXT.close, function() Window.Close() end)
    Foot(true, S.least)

    scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, S.foot + S.gap)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(Wheel))
    sheet = CreateFrame("Frame", nil, scroll)
    sheet:SetSize(S.width, 1)
    scroll:SetScrollChild(sheet)

    placed = Core.Window.New(panel, { store = Core.Store(ns.name), key = "windowPlace", title = ns.TEXT.window,
                                       first = { point = "LEFT", x = 80, y = 120 } })
end

-- The window's top left at x, y (from the screen's bottom left), kept on the screen.
local function Put(x, y)
    local width, height = tonumber(panel:GetWidth()) or 0, tonumber(panel:GetHeight()) or 0
    local right, top = tonumber(UIParent:GetWidth()) or 0, tonumber(UIParent:GetHeight()) or 0
    if right > width then x = math.max(0, math.min(x, right - width)) end
    if top > height then y = math.max(height, math.min(y, top)) end
    at = { x = x, y = y }
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

-- The first line's picture under the mouse, as near as the screen lets it.
local function AtMouse()
    local scale = panel:GetEffectiveScale()
    local x, y = GetCursorPosition()
    Put(x / scale - S.pad - S.icon / 2, y / scale + S.row / 2)
end

function Window.Place()
    if not panel or not panel:IsShown() then return end
    if ns.options.atMouse and not sample then
        AtMouse()
    else
        at = nil
        placed:Place()
    end
end

-- The lines as the loot holds them now: the rows laid out, the window as wide as its widest line and as high as
-- its lines (to a share of the screen; the rest scrolls) and its foot.
function Window.Fill()
    if not panel or not panel:IsShown() then return end
    local notes, kept = ns.options.notes, ns.options.kept
    local shown, wide, linkable = 0, S.least, sample
    for _, line in ipairs(lines) do
        if not (line.slot and taking[line.slot]) then
            shown = shown + 1
            local row = Row(shown)
            row.index = shown
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -(shown - 1) * STEP)
            row:SetPoint("RIGHT", sheet, "RIGHT")
            ns.Row.Set(row, line, notes, line.id and kept[line.id] == true)
            wide = math.max(wide, ns.Row.Width(row))
            linkable = linkable or line.kind ~= "money"
        end
    end
    for index = shown + 1, #rows do
        rows[index]:Hide()
        rows[index].line = nil
    end
    local width = math.min(S.width, wide)
    local screen = tonumber(UIParent:GetHeight()) or 0
    if screen <= 0 then screen = 768 end -- not laid out yet: the UI's own height at scale 1
    full = math.max(shown * STEP - S.rowGap, 0)
    view = math.min(full, math.max(S.row, screen * S.room))
    sheet:SetSize(width, math.max(full, 1))
    panel:SetSize(width, view + S.gap + S.foot)
    for index = 1, shown do ns.Row.Fit(rows[index], width) end
    Foot(linkable, width)
    Wheel(nil, 0)
    -- what is under the mouse now is another thing: its tooltip
    if hover then
        if hover:IsShown() and hover.line then Tip(hover) else Untip(hover) end
    end
    ns.Safe("full", ns.Full.Update)
end

-- Reads the loot and puts what the rules want in the queue (taken at once; not shown). Again (LOOT_READY, then
-- LOOT_OPENED) it asks nothing twice. While the game's Auto Loot takes everything (auto), it only reads.
local function Read(auto)
    lines = ns.Slots.Read()
    if auto then return end
    for slot in pairs(taking) do
        if not asked[slot] and taking[slot] ~= "queued" then taking[slot] = nil end
    end
    for _, line in ipairs(lines) do
        if asked[line.slot] then
            taking[line.slot] = true
        elseif ns.Slots.Wanted(line, ns.options) and not ns.Master.Gives(line) then
            Queue(line.slot)
        end
    end
    Drain()
end

-- The items of this loot noted for the tab Your items, the newest first, once a loot.
local function Meet()
    if met then return end
    met = true
    local seen, fresh, ids = ns.options.seen, {}, {}
    for _, line in ipairs(lines) do
        if line.kind == "item" and line.id and not fresh[line.id] then
            fresh[line.id] = true
            ids[#ids + 1] = line.id
        end
    end
    if #ids == 0 then return end
    for index = #seen, 1, -1 do
        if fresh[seen[index]] then table.remove(seen, index) end
    end
    for index = #ids, 1, -1 do table.insert(seen, 1, ids[index]) end -- this loot's first, in its order
    for index = #seen, S.seen + 1, -1 do seen[index] = nil end
    ns.Safe("items", ns.Items.Refresh)
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
    panel:Show()
    panel:Raise()
    Window.Fill()
    Window.Place()
    Core.Escape(panel, function() ns.Guarded(Window.Close) end)
end

-- A moment after the loot opened without the window (Shift's Auto Loot, or the rules took it all): what is still
-- there (bags full, a thing locked to a roll) shows after all.
local function Check()
    if not open or (panel and panel:IsShown()) or #lines == 0 then return end
    wipe(taking)
    Show()
end
local late = Core.Later(function() ns.Guarded(Check) end, 0.4)

-- In Edit Mode the sample goes, the loot comes (hidden before the loot is ours: hiding closes our loot).
local function Unsample()
    if sample and panel then
        sample = false
        panel:Hide()
    end
end

-- The loot is ready, a moment before it opens: the rules take at once (not while the game's Auto Loot takes all).
local function Ready(auto)
    if not ns.Game.Window() or auto then return end
    Unsample()
    open = true
    Read()
end

local function Opened(auto, item)
    if not ns.Game.Window() then return end
    Unsample()
    open, fromItem = true, item and true or false
    Read(auto)
    Meet()
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

-- The line that closed up into the taken one's place stands where it stood, under the mouse; the last one taken,
-- the line before it comes down to that place. Only at the mouse: a window placed in Edit Mode keeps its place.
local function Under(took)
    if not at or not ns.options.atMouse or sample then return end
    local shown = Remaining()
    if shown == 0 then return end
    local index = math.min(took.index, shown)
    Put(at.x, at.y - (took.index - index) * STEP + took.scroll - (scroll:GetVerticalScroll() or 0))
end

local function Cleared(slot)
    if not open then return end
    local index = Find(slot)
    if index then table.remove(lines, index) end
    taking[slot] = nil
    if #lines == 0 then return Window.Close() end -- all taken: the loot closes, shown or not
    local took = snap and snap.slot == slot and snap or nil
    if took then snap = nil end
    Window.Fill()
    if took and panel and panel:IsShown() then Under(took) end
end

-- A thing the rules took could not be taken (the bags are full): its line shows again.
local function Refused(_, message)
    if not open or message ~= rawget(_G, "ERR_INV_FULL") then return end
    wipe(taking)
    wipe(queue)
    if driver then driver:Hide() end
    Window.Fill()
end

-- A slot changed (a roll ended, the count grew): drawn anew, and taken if the rules want it now.
local function Changed(slot)
    if not open then return end
    local index = Find(slot)
    if not index then return end
    local line = ns.Slots.Line(slot)
    if line then lines[index] = line else table.remove(lines, index) end
    if line and not asked[slot] and ns.Slots.Wanted(line, ns.options) and not ns.Master.Gives(line) then
        Queue(slot)
        Drain()
    end
    Window.Fill()
end

local function Closed()
    open, met = false, false
    snap = nil
    wipe(lines)
    wipe(taking)
    wipe(asked)
    wipe(queue)
    if driver then driver:Hide() end
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

-- Two lines as they will look, to place the window by.
local function Sample()
    return {
        { kind = "item", name = ns.TEXT.window, icon = "Interface\\Icons\\INV_Misc_Bag_10", quality = 2, count = 1,
          worth = 1234, sub = ns.TEXT.takeGear },
        { kind = "item", name = ns.TEXT.questItem, icon = "Interface\\Icons\\INV_Misc_Note_01", quality = 1, count = 1,
          quest = true },
    }
end

-- In Edit Mode the window shows two lines as they will look, to be placed where it opens while At the mouse is off
-- (on, its place is the mouse's: nothing to place).
local function Edit(on)
    if open then return end
    if on and ns.Game.Window() and not ns.options.atMouse then
        if not panel then Build() end
        sample = true
        lines = Sample()
        wipe(taking)
        panel:Show()
        Window.Fill()
        Window.Place()
    elseif sample and panel then
        panel:Hide()
        sample = false
        lines = {}
    end
end

function Window.Start()
    driver = CreateFrame("Frame", nil, UIParent)
    driver:Hide()
    driver:SetScript("OnUpdate", ns.Guard(Drain))
    ns.On("LOOT_READY", ns.Guard(Ready))
    ns.On("LOOT_OPENED", ns.Guard(Opened))
    ns.On("LOOT_SLOT_CLEARED", ns.Guard(Cleared))
    ns.On("LOOT_SLOT_CHANGED", ns.Guard(Changed))
    ns.On("LOOT_CLOSED", ns.Guard(Closed))
    ns.On("UI_ERROR_MESSAGE", ns.Guard(Refused))
    Core.EditMode.Watch(ns.Guard(Edit))
end

function Window.GiveBack()
    sample = false
    wipe(queue)
    if driver then driver:Hide() end
    if panel and panel:IsShown() then panel:Hide() end
    if panel then Core.Escape(panel, nil) end
    open = false
end
