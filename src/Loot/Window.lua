local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Window
--  The loot window, as little as it can be (Saneroki, 2026-10-29): no paper,
--  no frame, no title, a line for each thing the loot holds (Row.lua) straight
--  on the world, and over the lines at the right two words: Link and the X
--  that closes it. It opens where the mouse is, its first line under it, or
--  where it was placed in Edit Mode (switch At the mouse); more lines than a
--  good part of the screen scroll.
--
--  A thing taken, the lines close up and the next one stands where the taken
--  one stood, under the mouse: at the mouse the window moves down a line when
--  the last one was taken.
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
--  Alt-click puts it on the player's loot list or takes it off. Link puts the
--  links of the loot's things into the chat box: the player sends them (an
--  addon may not send chat itself). Closing the window closes the loot
--  (CloseLoot); Esc closes it (Core.Escape).
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

local LIGHT = { 0.85, 0.85, 0.85 } -- the two words over the lines; gold under the mouse
local CHAT_SHOWN, CHAT_BYTES = 250, 1270 -- what the game's chat box holds: 255 letters on show, 1280 bytes with links

local panel, scroll, sheet, linkButton, closeButton, placed
local rows = {}
local lines = {}      -- what the loot holds now (Slots.Read), less what the rules are taking
local taking = {}     -- [slot] = true: taken at once, waiting for the game to clear it
local open = false    -- the loot is open and the window is ours
local sample = false  -- shown in Edit Mode only, to be placed
local fromItem = false
local full, view = 0, 0  -- the lines' height, and how much of it shows
local at              -- at the mouse: the window's top left { x, y } from the screen's bottom left
local snap            -- the thing the player took: { slot, index, scroll }; the next comes to its place
local hover           -- the line under the mouse

-------------------------------------------------------------------------------
--  The lines
-------------------------------------------------------------------------------
local function Tip(row)
    local line = row.line
    if not line or sample then return end
    hover = row
    row.shade:Show()
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if line.kind == "item" then
        GameTooltip:SetLootItem(line.slot)
    elseif line.kind == "currency" and GameTooltip.SetLootCurrency then
        GameTooltip:SetLootCurrency(line.slot)
    else
        GameTooltip:SetText(line.name)
    end
    if line.id and ns.options.kept[line.id] then GameTooltip:AddLine(ns.TEXT.onList, 1, 0.82, 0, true) end
    GameTooltip:Show()
end

local function Untip(row)
    if hover == row then hover = nil end
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
    snap = { slot = line.slot, index = row.index or 1, scroll = scroll:GetVerticalScroll() or 0 }
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
    local most = math.max(0, full - view)
    scroll:SetVerticalScroll(math.min(most, math.max(0, (scroll:GetVerticalScroll() or 0) - delta * S.row)))
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
-- A word over the lines that is a button: light, gold under the mouse.
local function Word(text, onClick, tip)
    local button = CreateFrame("Button", nil, panel)
    button.text = button:CreateFontString(nil, "OVERLAY")
    ns.Row.Font(button.text, 13, true)
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    button.text:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
    button:SetSize(math.max(S.top, (tonumber(button.text:GetStringWidth()) or 0) + S.gap), S.top)
    button:SetScript("OnClick", ns.Guard(onClick))
    button:SetScript("OnEnter", ns.Guard(function()
        button.text:SetTextColor(ns.Row.Gold())
        if not tip then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", ns.Guard(function()
        button.text:SetTextColor(LIGHT[1], LIGHT[2], LIGHT[3])
        GameTooltip_Hide()
    end))
    return button
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

    closeButton = Word("x", function() Window.Close() end)
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    linkButton = Word(ns.TEXT.link, LinkAll, ns.TEXT.linkTip)
    linkButton:SetPoint("RIGHT", closeButton, "LEFT", -S.gap / 2, 0)

    scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -S.top)
    scroll:SetPoint("BOTTOMRIGHT")
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
    Put(x / scale - S.icon / 2, y / scale + S.top + S.row / 2)
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

-- The lines as the loot holds them now: the rows laid out, the window as wide as its widest words and as high as
-- its lines (to a share of the screen; the rest scrolls).
function Window.Fill()
    if not panel or not panel:IsShown() then return end
    local notes = ns.options.notes
    local shown, wide, linkable = 0, S.least, sample
    for _, line in ipairs(lines) do
        if not (line.slot and taking[line.slot]) then
            shown = shown + 1
            local row = Row(shown)
            row.index = shown
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -(shown - 1) * S.row)
            row:SetPoint("RIGHT", sheet, "RIGHT")
            ns.Row.Set(row, line, notes)
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
    full = shown * S.row
    view = math.min(full, math.max(S.row, screen * S.room - S.top))
    sheet:SetSize(width, math.max(full, 1))
    panel:SetSize(width, S.top + view)
    linkButton:SetShown(linkable)
    Wheel(nil, 0)
    -- what is under the mouse now is another thing: its tooltip
    if hover then
        if hover:IsShown() and hover.line then Tip(hover) else Untip(hover) end
    end
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

-- The line that closed up into the taken one's place stands where it stood, under the mouse; the last one taken,
-- the line before it comes down to that place. Only at the mouse: a window placed in Edit Mode keeps its place.
local function Under(took)
    if not at or not ns.options.atMouse or sample then return end
    local shown = Remaining()
    if shown == 0 then return end
    local index = math.min(took.index, shown)
    Put(at.x, at.y - (took.index - index) * S.row + took.scroll - (scroll:GetVerticalScroll() or 0))
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
    snap = nil
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

-- Two lines as they will look, to place the window by.
local function Sample()
    return {
        { kind = "item", name = ns.TEXT.window, icon = "Interface\\Icons\\INV_Misc_Bag_10", quality = 2, count = 1 },
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
