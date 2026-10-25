local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Satchel
--  One button on the small map, in its lower corner at the screen's edge (the
--  window's grip has the corner away from it; the upper one where the window
--  stands in the screen's lower half): a leather satchel in the leather ring of
--  the found herbs (Found.Ring). Its click opens the satchel beside the window,
--  a page of the journal (Core.Journal) with, under their titles, large cells
--  that are easy to hit:
--
--      AddOns    the buttons other addons hang round the minimap and the addons
--                the game's addon compartment lists (Strays.lua), each over its
--                title, A to Z; their clicks and tooltips their own
--      Pins      every kind of pin the map can show here, in the pin filter's
--                order (ns.KINDS, ns.PIN_SECTIONS): a click switches it, as the
--                pin filter on the full map's bar does (their sizes stay there)
--      Tracking  what the game's own minimap tracks, as its tracking menu lists
--                it (the townsfolk, the finders, a hunter's beasts...): a click
--                switches it as that menu does; not Find Herbs and Find Minerals,
--                which Found herbs and Found ore switch (Nodes.lua)
--
--  A cell switched on shows its picture whole with a pencil tick, one switched
--  off faint and grey. Closed by its X, Esc, the button again, or the window
--  going to the full screen. Where the screen is lower than the page, the wheel
--  scrolls it. Only on the small view, while the window is the minimap.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Journal = Core.Journal
local Satchel = {}
ns.Satchel = Satchel

Satchel.SIZE = 28          -- the button's ring across, in units
Satchel.INSET = 4          -- the button from the window's corner
Satchel.BAG = 133628       -- its picture: a leather satchel (INV_Misc_Bag_07, in both games)
Satchel.GAP = 6            -- between the window and the satchel
Satchel.COLUMNS = 6
Satchel.CELL = { 72, 58 }  -- a cell's width and height: compact (Saneroki, 2026-10-25)
Satchel.ICON = 28          -- a cell's picture, on the paper as it is (no pencil slot round it)
Satchel.HEAD = 22          -- a section's title and its rule
Satchel.NOTE = 18          -- the line under an empty section's title
Satchel.AFTER = 6          -- room under a section
Satchel.ROOM = 0.8         -- the page takes at most so much of the screen's height; the wheel scrolls the rest
Satchel.FAINT = 0.4        -- a cell switched off: its picture so faint
Satchel.SPELL = { 0.0625, 0.9 } -- a tracking spell's icon cut inside its frame, as the game's menu cuts it
Satchel.TICK = "\226\136\154"   -- the pencil tick: Kalam's root sign
-- The game's tracking entries its menu lists besides those of a spell (Blizzard_Minimap, OPTIONAL_FILTERS; Forever
-- has them as MinimapConstants.OPTIONAL_FILTERS, Retail keeps them to itself): Enum.MinimapTrackingFilter's names.
Satchel.OPTIONAL = { "Banker", "Auctioneer", "Barber", "TrainerProfession", "AccountCompletedQuests", "TrivialQuests",
                     "Transmogrifier", "Mailbox" }
Satchel.TEXT = {
    title = Core.Word("MINIMAP_LABEL", "Minimap"),
    tip = "Addons, pins and tracking",
    addons = Core.Word("ADDONS", "AddOns"),
    pins = "Pins",
    tracking = Core.Word("TRACKING", "Tracking"),
    none = "The buttons other addons put round the minimap gather here.",
}

local button          -- the button on the small map
local panel, look, scroll, sheet
local cells, heads = {}, {} -- the cells and the sections' titles made so far, used again at each fill
local predicted = {}  -- [tracking index] = on: switched here, until the game's tracking says so too (a spell's cast)
local small = false   -- the window stands small and is the minimap: the button shows

-------------------------------------------------------------------------------
--  What it holds
-------------------------------------------------------------------------------
-- The kinds of pin the map can show here, in the pin filter's order.
local function Pins()
    local order, list = {}, {}
    for index, section in ipairs(ns.PIN_SECTIONS) do order[section[1]] = index end
    for index, kind in ipairs(ns.KINDS) do
        if ns.KindOffered(kind) then
            list[#list + 1] = { pin = kind, title = kind[2], on = ns.Pins.Shows(kind[1]),
                                rank = (order[kind.section] or #ns.PIN_SECTIONS + 1) * 1000 + index }
        end
    end
    table.sort(list, function(a, b) return a.rank < b.rank end)
    return list
end

-- The game's tracking entries its own menu shows: a spell's, and its optional ones.
local function Optional()
    local constants = rawget(_G, "MinimapConstants")
    if constants and type(constants.OPTIONAL_FILTERS) == "table" then return constants.OPTIONAL_FILTERS end
    local filters, set = Enum and Enum.MinimapTrackingFilter, {}
    for _, name in ipairs(Satchel.OPTIONAL) do
        if filters and filters[name] then set[filters[name]] = true end
    end
    return set
end

local function Listed(index, optional)
    if not C_Minimap.GetTrackingFilter then return true end
    local filter = Core.Ask(C_Minimap.GetTrackingFilter, index)
    return type(filter) == "table" and (optional[filter.filterID] or filter.spellID) and true or false
end

-- What the game's minimap tracks, as its menu lists it, but the finders Found herbs and Found ore switch.
local function Tracking()
    local list, optional = {}, Optional()
    local finders = ns.Nodes.FINDERS
    for index = 1, Core.Plain(Core.Ask(C_Minimap.GetNumTrackingTypes)) or 0 do
        local info = Core.Ask(C_Minimap.GetTrackingInfo, index)
        if type(info) == "table" and info.spellID ~= finders.herb and info.spellID ~= finders.ore and Listed(index, optional) then
            local on = Core.Plain(info.active) and true or false
            if predicted[index] ~= nil then
                if predicted[index] == on then predicted[index] = nil else on = predicted[index] end
            end
            list[#list + 1] = { track = index, title = Core.Plain(info.name) or "", texture = info.texture,
                                spell = info.type == "spell", on = on }
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  The cells
-------------------------------------------------------------------------------
local function Tip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(text or "")
    GameTooltip:Show()
end

local function Entered(cell)
    cell.shade:Show()
    local item = cell.item
    if item and item.entry and not ns.Strays.Hover(item.entry, cell, true) then Tip(cell, item.title) end
end

local function Left(cell)
    cell.shade:Hide()
    local item = cell.item
    if not (item and item.entry and ns.Strays.Hover(item.entry, cell, false)) then GameTooltip:Hide() end
end

-- A tracking entry switched as the game's menu switches it; shown so at once (a spell's takes its cast).
local function Track(index, on)
    predicted[index] = on
    local util = rawget(_G, "MinimapUtil")
    if util and util.SetTrackingFilterByFilterIndex then
        util.SetTrackingFilterByFilterIndex(index, on)
    else
        C_Minimap.SetTracking(index, on)
    end
end

local function Clicked(cell, mouse)
    local item = cell.item
    if not item then return end
    if item.entry then return ns.Strays.Click(item.entry, mouse) end
    if item.pin then
        ns.SwitchPin(item.pin[1]) -- the setting's change fills the satchel anew (Navigation.lua)
    elseif item.track then
        Track(item.track, not item.on)
        Satchel.Fill()
    end
end

local function Cell(index)
    local cell = cells[index]
    if cell then return cell end
    cell = CreateFrame("Button", nil, sheet)
    cell:SetSize(Satchel.CELL[1], Satchel.CELL[2])
    cell:RegisterForClicks("AnyUp")
    cell.shade = cell:CreateTexture(nil, "BACKGROUND")
    cell.shade:SetAllPoints()
    cell.shade:SetColorTexture(Journal.SHADE[1], Journal.SHADE[2], Journal.SHADE[3], Journal.SHADE[4])
    cell.shade:Hide()
    cell.spot = CreateFrame("Frame", nil, cell)
    cell.spot:SetSize(Satchel.ICON, Satchel.ICON)
    cell.spot:SetPoint("TOP", 0, -3)
    cell.picture = cell.spot:CreateTexture(nil, "ARTWORK")
    cell.picture:SetAllPoints()
    cell.tick = cell:CreateFontString(nil, "OVERLAY")
    Journal.Font(cell.tick, 16, true, Journal.INK)
    cell.tick:SetPoint("BOTTOMLEFT", cell.spot, "TOPRIGHT", -3, -9)
    cell.tick:SetText(Satchel.TICK)
    cell.name = cell:CreateFontString(nil, "OVERLAY")
    Journal.Font(cell.name, 12, false, Journal.INK)
    cell.name:SetPoint("TOP", cell.spot, "BOTTOM", 0, -2)
    cell.name:SetWidth(Satchel.CELL[1] - 4)
    cell.name:SetMaxLines(2)
    cell.name:SetJustifyH("CENTER")
    cell:SetScript("OnEnter", ns.Guard(Entered))
    cell:SetScript("OnLeave", ns.Guard(Left))
    cell:SetScript("OnClick", ns.Guard(Clicked))
    cells[index] = cell
    return cell
end

-- A picture: an atlas where the game has one by that name, else a file.
local function Picture(texture, art)
    local atlases = rawget(_G, "C_Texture")
    if type(art) == "string" and atlases and atlases.GetAtlasInfo(art) then
        texture:SetAtlas(art)
    else
        texture:SetTexture(art)
    end
end

-- A cell let go: a held button on it back out of sight (Strays.Place), the cell hidden.
local function Empty(cell)
    local item = cell.item
    if item and item.button then ns.Strays.Place(item.button) end
    cell.item = nil
    cell:Hide()
end

-- A cell holding item (a held button, a compartment's addon, a kind of pin, a tracking entry).
local function Dress(cell, item)
    cell.item = item
    cell.name:SetText(item.title)
    local icon = cell.picture
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetDesaturated(false)
    if item.button then
        -- Its own button in the picture's place, as its addon made it.
        icon:Hide()
        cell.tick:Hide()
        ns.Strays.Place(item.button, cell.spot, Satchel.ICON)
        return cell:Show()
    end
    icon:Show()
    local pin = item.pin
    if pin then
        Picture(icon, pin.texture or pin.icon)
        if pin.tint then icon:SetVertexColor(pin.tint[1] / 255, pin.tint[2] / 255, pin.tint[3] / 255) end
        if pin.grey then icon:SetDesaturated(true) end
    elseif item.track then
        Picture(icon, item.texture)
        if item.spell then icon:SetTexCoord(Satchel.SPELL[1], Satchel.SPELL[2], Satchel.SPELL[1], Satchel.SPELL[2]) end
    else
        Picture(icon, item.icon or 134400) -- a compartment's addon without a picture: the game's question mark
    end
    local switch = item.on ~= nil -- a pin, a tracking entry: on or off
    local off = switch and not item.on
    if off then icon:SetDesaturated(true) end
    icon:SetAlpha(off and Satchel.FAINT or 1)
    cell.tick:SetShown(switch and item.on or false)
    cell.name:SetAlpha(off and Journal.FAINT[4] or 1)
    cell:Show()
end

-- A section's title over its rule at y on the sheet; the line under it if it holds nothing.
local function Head(index, title, y, note)
    local head = heads[index]
    if not head then
        head = { text = sheet:CreateFontString(nil, "OVERLAY"), rule = Journal.Rule(sheet),
                 note = sheet:CreateFontString(nil, "OVERLAY") }
        Journal.Font(head.text, 15, true, Journal.INK)
        Journal.Font(head.note, 12, false, Journal.FAINT)
        head.note:SetJustifyH("LEFT")
        heads[index] = head
    end
    head.text:SetText(title)
    head.text:ClearAllPoints()
    head.text:SetPoint("TOPLEFT", sheet, "TOPLEFT", 2, -y)
    head.text:Show()
    head.rule:ClearAllPoints()
    head.rule:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -(y + Satchel.HEAD - 6))
    head.rule:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", 0, -(y + Satchel.HEAD - 6))
    head.rule:Show()
    head.note:SetShown(note ~= nil)
    if note then
        head.note:ClearAllPoints()
        head.note:SetPoint("TOPLEFT", sheet, "TOPLEFT", 2, -(y + Satchel.HEAD))
        head.note:SetPoint("RIGHT", sheet, "RIGHT", 0, 0)
        head.note:SetText(note)
    end
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- Beside the window, toward the screen's middle: under it where it stands in the screen's upper half, else over it;
-- its edge at the window's on the side of the screen's edge it is nearer.
local function Anchor()
    local window = ns.Window.frame
    local x, y = window:GetCenter()
    local midX, midY = UIParent:GetCenter()
    local side = (x or 0) > (midX or 0) and "RIGHT" or "LEFT"
    panel:ClearAllPoints()
    if (y or 0) > (midY or 0) then
        panel:SetPoint("TOP" .. side, window, "BOTTOM" .. side, 0, -Satchel.GAP)
    else
        panel:SetPoint("BOTTOM" .. side, window, "TOP" .. side, 0, Satchel.GAP)
    end
end

local function Wheel(_, delta)
    local most = scroll:GetVerticalScrollRange() or 0
    scroll:SetVerticalScroll(math.min(math.max(scroll:GetVerticalScroll() - delta * Satchel.CELL[2], 0), most))
end

local function Build()
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    Satchel.frame = panel
    look = Journal.Dress(panel, Satchel.TEXT.title)
    look.close:SetScript("OnClick", ns.Guard(function() Satchel.Close() end))
    scroll = CreateFrame("ScrollFrame", nil, look.content)
    scroll:SetAllPoints()
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", ns.Guard(Wheel))
    sheet = CreateFrame("Frame", nil, scroll)
    sheet:SetSize(Satchel.COLUMNS * Satchel.CELL[1], 1)
    scroll:SetScrollChild(sheet)
    ns.On("MINIMAP_UPDATE_TRACKING", function() Satchel.Fill() end)
end

-- What it holds, laid out anew (opened, a switch changed, a button given back); nothing while it is closed.
function Satchel.Fill()
    if not panel or not panel:IsShown() then return end
    local sections = {
        { Satchel.TEXT.addons, ns.Strays.List(), Satchel.TEXT.none },
        { Satchel.TEXT.pins, Pins() },
        { Satchel.TEXT.tracking, Tracking() },
    }
    for _, cell in ipairs(cells) do Empty(cell) end
    for _, head in ipairs(heads) do
        head.text:Hide()
        head.rule:Hide()
        head.note:Hide()
    end
    local y, used, titled = 0, 0, 0
    for _, section in ipairs(sections) do
        local items = section[2]
        if #items > 0 or section[3] then
            titled = titled + 1
            Head(titled, section[1], y, #items == 0 and section[3] or nil)
            y = y + Satchel.HEAD
            if #items == 0 then y = y + Satchel.NOTE end
            for index, item in ipairs(items) do
                used = used + 1
                local cell = Cell(used)
                local column, row = (index - 1) % Satchel.COLUMNS, math.floor((index - 1) / Satchel.COLUMNS)
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", sheet, "TOPLEFT", column * Satchel.CELL[1], -(y + row * Satchel.CELL[2]))
                Dress(cell, item)
            end
            y = y + math.ceil(#items / Satchel.COLUMNS) * Satchel.CELL[2] + Satchel.AFTER
        end
    end
    y = math.max(y - Satchel.AFTER, 1) -- no room under the last section: the page's own margin is there
    local width = Satchel.COLUMNS * Satchel.CELL[1]
    sheet:SetSize(width, y)
    local _, chrome = Journal.Outer(width, 0)
    local room = (tonumber(UIParent:GetHeight()) or 768) * Satchel.ROOM - chrome
    panel:SetSize(Journal.Outer(width, math.max(math.min(y, room), 1)))
    Wheel(nil, 0) -- the scroll within the new height
end

function Satchel.Open()
    if not small then return end
    if not panel then Build() end
    ns.Strays.Look()
    Anchor()
    panel:Show()
    panel:Raise()
    Satchel.Fill()
    Core.Escape(panel, function() ns.Guarded(Satchel.Close) end)
end

function Satchel.Close()
    if not panel or not panel:IsShown() then return end
    panel:Hide()
    Core.Escape(panel, nil)
    for _, cell in ipairs(cells) do Empty(cell) end -- the held buttons wait out of sight again
end

function Satchel.Toggle()
    if panel and panel:IsShown() then Satchel.Close() else Satchel.Open() end
end

function Satchel.Shown()
    return panel ~= nil and panel:IsShown()
end

-------------------------------------------------------------------------------
--  The button
-------------------------------------------------------------------------------
local function ButtonTip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(Satchel.TEXT.title)
    GameTooltip:AddLine(Satchel.TEXT.tip, 1, 1, 1)
    GameTooltip:Show()
end

function Satchel.Build(canvas)
    button = CreateFrame("Button", nil, canvas)
    button:SetSize(Satchel.SIZE, Satchel.SIZE)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(Satchel.BAG)
    icon:SetPoint("CENTER")
    ns.Found.Round(icon, button:CreateMaskTexture())
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(ns.Found.RING)
    ns.Found.Ring(ring, icon, Satchel.SIZE * ns.Found.HOLE / ns.Found.OUTER)
    button:SetScript("OnClick", ns.Guard(Satchel.Toggle))
    button:SetScript("OnEnter", ns.Guard(ButtonTip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:Hide()
    Satchel.button = button
end

-- Over what stands on the map (Canvas.lua lays the levels).
function Satchel.Stack(level)
    if button then button:SetFrameLevel(level) end
end

-- The window stands small and is the minimap (on), or not (full, on its way, resting, gone): the button in the
-- corner at the screen's edge, or gone with the satchel.
function Satchel.Place(on)
    small = on and true or false
    if not button then return end
    if not small then
        Satchel.Close()
        return button:Hide()
    end
    local window = ns.Window.frame
    local x, y = window:GetCenter()
    local midX, midY = UIParent:GetCenter()
    local corner = ((y or 0) > (midY or 0) and "BOTTOM" or "TOP") .. ((x or 0) > (midX or 0) and "RIGHT" or "LEFT")
    local dx = corner:find("RIGHT") and -Satchel.INSET or Satchel.INSET
    local dy = corner:find("TOP") and -Satchel.INSET or Satchel.INSET
    button:ClearAllPoints()
    button:SetPoint(corner, button:GetParent(), corner, dx, dy)
    button:Show()
    if panel and panel:IsShown() then Anchor() end
end

-- The module stood down: the button and the satchel go.
function Satchel.Hide()
    Satchel.Place(false)
end
