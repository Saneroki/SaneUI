local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Markers
--  Your own markers on the map (Saneroki, 2026-11-15: "a system where we can place our own custom map markers on
--  maps with our own text and description when you click on them"):
--
--      put one     Alt and a click on the map, small or full: a marker there, its card open to write in
--      on the map  its icon (the game's eight raid marks, or one of a few of its map icons), its title beside it on
--                  the full map; the mouse on it: its title and its words; a click: its card; a double click: the
--                  game's map pin there (the golden line leads there); the pin filter's Your markers shows or hides
--                  them all
--      its card    a small window in the kit's bronze (Core.Look.Dress) beside the mouse: its icon, its title, its
--                  words, the zone and the day it was put; Edit, Move (the next click on the map puts it there; a
--                  right click: it stays), the map pin, Delete (asked first). Esc closes it (Core.Escape). Editing: a line for its title, a box for its words, its
--                  icon to pick; Save (Enter in the title too) and Cancel (Esc). A new marker cancelled goes again.
--      the search  the map's search finds them by their titles and words (Find.lua)
--
--      Markers.List()            every marker: { id, map, x, y (0 to 1 on its map), title, text, icon, made (time) }
--      Markers.New(spot)         a new one at { map, x, y } (Canvas: Alt and a click), its card open to write in
--      Markers.Open(marker)      its card
--      Markers.Pins()            their pins (Pins.For), made anew when one changes
--      Markers.Moving()          the marker waiting for its new place (Move); Markers.Put(spot) puts it there
--      Markers.Remove(marker), Markers.Close()
--
--  Kept for the account in the module's saved settings (ns.store.markers), each game's in its own (their map IDs
--  differ, and so do their saved files): personal notes, never shared or shipped (data.md, *Game facts, not people*).
--  Sharing them with the party or the guild, and drawing on the map, come later (board #481).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Coords = ns.Coords
local Markers = {}
ns.Markers = Markers

Markers.WIDTH = 320          -- the card's width
Markers.WORDS = 96           -- the words' box, editing: its height
Markers.ICON = 32            -- the marker's icon on its card
Markers.PICK = 26            -- an icon to pick, editing
Markers.PER_ROW = 7          -- icons to pick in a row
Markers.BUTTON = 30          -- the card's grey square buttons
Markers.TITLE_MOST, Markers.TEXT_MOST = 60, 1000 -- letters a title and its words hold at most
-- The icons to pick from, the first the one a new marker has: the game's raid marks, and a few of its map icons.
Markers.ICONS = {
    { key = "star", texture = 137001 }, { key = "circle", texture = 137002 }, { key = "diamond", texture = 137003 },
    { key = "triangle", texture = 137004 }, { key = "moon", texture = 137005 }, { key = "square", texture = 137006 },
    { key = "cross", texture = 137007 }, { key = "skull", texture = 137008 },
    { key = "chest", atlas = "vignetteloot" }, { key = "quest", atlas = "questnormal" },
    { key = "herb", atlas = "professions_tracking_herb" }, { key = "ore", atlas = "professions_tracking_ore" },
    { key = "danger", atlas = "dungeonskull" }, { key = "inn", atlas = "innkeeper" },
}
Markers.TEXT = {
    new = "New marker",
    untitled = "Marker",
    title = "Title",
    words = "Description",
    icon = "Icon",
    save = Core.Word("SAVE", "Save"),
    cancel = Core.Word("CANCEL", "Cancel"),
    edit = "Edit",
    editTip = "Change its title, its description and its icon.",
    move = "Move",
    moveTip = "Click on the map where it should stand; a right click: it stays.",
    moving = "Click on the map where %s should stand; a right click: it stays.",
    pin = "The map pin here",
    pinTip = "The game's map pin on this marker: the golden line leads there.",
    delete = Core.Word("DELETE", "Delete"),
    deleteTip = "This marker away for good (asked first).",
    deleteAsk = "Delete the marker %s?",
    placed = "%s, put %s",
    noPlace = "No marker here: zoom in onto a zone.",
    hint = "Click: its card. Double click: the map pin here.",
}

local card, look, reading, editing -- the card, its dressing, its two faces
local opened                        -- the marker its card shows
local fresh                         -- the marker was just put: Cancel takes it away again
local moving                        -- the marker waiting for its new place (Move)
local picked                        -- the icon picked while editing
local pins = {}                     -- the markers' pins, made anew when one changes (stale)
local stale = true

-------------------------------------------------------------------------------
--  The markers
-------------------------------------------------------------------------------
-- Every marker, kept for the account (a list in the saved settings, made the first time).
function Markers.List()
    local store = ns.store
    if type(store.markers) ~= "table" then store.markers = {} end
    return store.markers
end

local function Icon(key)
    for _, icon in ipairs(Markers.ICONS) do
        if icon.key == key then return icon end
    end
    return Markers.ICONS[1]
end
Markers.Icon = Icon

-- An icon on a texture: the raid mark's file, else the map icon's atlas.
local function Paint(texture, key)
    local icon = Icon(key)
    if icon.texture then texture:SetTexture(icon.texture) else texture:SetAtlas(icon.atlas) end
end

-- The map drawn anew with the markers as they are now.
local function Changed()
    stale = true
    if ns.Canvas and ns.Canvas.Refresh then ns.Canvas.Refresh() end
end

-- The markers as pins: in their plane (Coords), their icon, their title as the heading and their words in the tooltip,
-- their title beside them on the full map.
function Markers.Pins()
    if not stale then return pins end
    stale = false
    wipe(pins)
    for _, marker in ipairs(Markers.List()) do
        local home = type(marker.map) == "number" and Coords.PlaneOf(marker.map)
        local u, v
        if home then u, v = Coords.MapToPlane(marker.map, marker.x or 0, marker.y or 0, home) end
        if u then
            local icon = Icon(marker.icon)
            local lines = {}
            if marker.text and marker.text ~= "" then lines[1] = marker.text end
            lines[#lines + 1] = { Markers.TEXT.hint, 0.5, 0.5, 0.5 }
            pins[#pins + 1] = { kind = "mark", key = "mark:" .. marker.id, marker = marker, name = marker.title,
                                label = marker.title, home = home, u = u, v = v, map = marker.map, x = marker.x,
                                y = marker.y, texture = icon.texture, atlas = icon.atlas, lines = lines }
        end
    end
    return pins
end

local function Day(made)
    return made and date("%Y-%m-%d", made) or ""
end

-------------------------------------------------------------------------------
--  Its card
-------------------------------------------------------------------------------
-- The card's face: reading (its words, the buttons) or editing (the boxes, the icons, Save and Cancel), and its height.
local function Face(edit)
    reading:SetShown(not edit)
    editing:SetShown(edit)
    local inner = edit and editing.height or reading.height
    card:SetHeight(inner + Look.DRESS_HEAD + 4 + Look.INSIDE + 4)
end

-- Reading: its icon, its words, where and when it was put; the card as high as its words need.
local function Read(marker)
    look.title:SetText(marker.title or Markers.TEXT.untitled)
    Paint(reading.icon, marker.icon)
    reading.words:SetText(marker.text or "")
    local zone = ns.Find and ns.Find.MapName(marker.map) or ""
    reading.placed:SetText(Markers.TEXT.placed:format(zone, Day(marker.made)))
    local words = (marker.text and marker.text ~= "") and (reading.words:GetStringHeight() or 0) or 0
    reading.height = math.max(Markers.ICON, words) + 8 + 16 + 8 + Markers.BUTTON
    Face(false)
end

-- The icons to pick, the one picked lit.
local function Light()
    for _, button in ipairs(editing.icons) do
        if button.key == picked then button:LockHighlight() else button:UnlockHighlight() end
        button.box:SetStrong(button.key == picked)
    end
end

local function Edit(marker)
    look.title:SetText(marker.title ~= "" and marker.title or Markers.TEXT.new)
    picked = marker.icon or Markers.ICONS[1].key
    editing.title:SetText(marker.title or "")
    editing.words:SetText(marker.text or "")
    Light()
    Face(true)
    editing.title:SetFocus()
    editing.title:HighlightText()
end

-- The card beside the mouse (on the screen, clamped to it).
local function Beside()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 24, y / scale + 24)
end

local function Save()
    local marker = opened
    if not marker then return end
    local title = (editing.title:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    marker.title = title ~= "" and title or Markers.TEXT.untitled
    marker.text = (editing.words:GetText() or ""):gsub("%s+$", "")
    marker.icon = picked or marker.icon
    fresh = nil
    editing.title:ClearFocus()
    editing.words:ClearFocus()
    Changed()
    Read(marker)
end

function Markers.Remove(marker)
    local list = Markers.List()
    for index = #list, 1, -1 do
        if list[index] == marker then table.remove(list, index) end
    end
    if opened == marker then Markers.Close() end
    if moving == marker then moving = nil end
    Changed()
end

local function Cancel()
    editing.title:ClearFocus()
    editing.words:ClearFocus()
    if fresh and opened == fresh then return Markers.Remove(fresh) end
    if opened then Read(opened) end
end

function Markers.Close()
    if card then card:Hide() end
end

local function Closed()
    if fresh then
        local marker = fresh
        fresh = nil
        Markers.Remove(marker)
    end
    opened = nil
end

local function Delete()
    local marker = opened
    if not marker then return end
    Core.Confirm(Markers.TEXT.deleteAsk, marker.title or "", ns.Guard(function() Markers.Remove(marker) end))
end

local function Pin()
    if opened then ns.PinView.Drop({ map = opened.map, x = opened.x, y = opened.y }) end
end

local function Move()
    if not opened then return end
    moving = opened
    UIErrorsFrame:AddMessage(Markers.TEXT.moving:format(opened.title or Markers.TEXT.untitled), 1, 0.82, 0)
    Markers.Close()
end

-- A grey square button of the card with its icon (atlas or file) and its tooltip.
local function Square(parent, icon, title, tip, click)
    local button = Look.Square(parent, Markers.BUTTON)
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("CENTER")
    texture:SetSize(Markers.BUTTON - 12, Markers.BUTTON - 12)
    if type(icon) == "number" or icon:find("\\", 1, true) then texture:SetTexture(icon) else texture:SetAtlas(icon) end
    button:SetScript("OnClick", ns.Guard(click))
    Core.Tip(button, title, tip, "ANCHOR_BOTTOM")
    return button
end

-- A box of the card to write in: the thin golden outline round it, the words in the game's font.
local function Box(parent, multi)
    local frame = CreateFrame("Frame", nil, parent)
    frame.outline = Look.Outline(frame)
    local box = CreateFrame("EditBox", nil, frame)
    box:SetFontObject("GameFontHighlight")
    box:SetAutoFocus(false)
    box:SetTextInsets(6, 6, 4, 4)
    if multi then
        -- in a scroll frame: the box as wide as the card's inside and as high as its words, the cursor kept in sight
        local scroll = CreateFrame("ScrollFrame", nil, frame)
        scroll:SetAllPoints()
        box:SetMultiLine(true)
        box:SetWidth(Markers.WIDTH - 2 * Look.INSIDE)
        scroll:SetScrollChild(box)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", ns.Guard(function(_, delta)
            local most = math.max(0, (box:GetHeight() or 0) - (scroll:GetHeight() or 0))
            scroll:SetVerticalScroll(math.max(0, math.min(most, scroll:GetVerticalScroll() - delta * 14)))
        end))
        box:SetScript("OnCursorChanged", ns.Guard(function(_, _, y, _, height)
            local top, room = -y, scroll:GetHeight() or 0
            local offset = scroll:GetVerticalScroll()
            if top < offset then
                scroll:SetVerticalScroll(top)
            elseif top + height > offset + room then
                scroll:SetVerticalScroll(top + height - room)
            end
        end))
        frame:EnableMouse(true)
        frame:SetScript("OnMouseDown", ns.Guard(function() box:SetFocus() end))
    else
        box:SetAllPoints()
    end
    box:SetScript("OnEditFocusGained", ns.Guard(function() frame.outline:SetStrong(true) end))
    box:SetScript("OnEditFocusLost", ns.Guard(function() frame.outline:SetStrong(false) end))
    frame.box = box
    return frame, box
end

local function Build()
    if card then return end
    card = CreateFrame("Frame", nil, UIParent)
    card:SetSize(Markers.WIDTH, 200)
    card:SetFrameStrata("DIALOG")
    card:SetToplevel(true)
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    card:SetMovable(true)
    look = Look.Dress(card, "")
    look.close:SetScript("OnClick", ns.Guard(Markers.Close))
    look.head:EnableMouse(true)
    look.head:RegisterForDrag("LeftButton")
    look.head:SetScript("OnDragStart", ns.Guard(function() card:StartMoving() end))
    look.head:SetScript("OnDragStop", ns.Guard(function() card:StopMovingOrSizing() end))
    -- Esc closes it, as Core closes all of Sane UI's that is open (Core.Escape)
    card:SetScript("OnShow", ns.Guard(function() Core.Escape(card, Markers.Close) end))
    card:SetScript("OnHide", ns.Guard(function()
        Core.Escape(card, nil)
        Closed()
    end))
    local content = look.content

    reading = CreateFrame("Frame", nil, content)
    reading:SetAllPoints()
    reading.icon = reading:CreateTexture(nil, "ARTWORK")
    reading.icon:SetSize(Markers.ICON, Markers.ICON)
    reading.icon:SetPoint("TOPLEFT", 0, -2)
    reading.words = reading:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    reading.words:SetPoint("TOPLEFT", reading.icon, "TOPRIGHT", 10, 0)
    reading.words:SetWidth(Markers.WIDTH - 2 * Look.INSIDE - Markers.ICON - 10)
    reading.words:SetJustifyH("LEFT")
    reading.words:SetJustifyV("TOP")
    reading.words:SetWordWrap(true)
    reading.placed = reading:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    reading.placed:SetPoint("BOTTOMLEFT", 0, Markers.BUTTON + 8)
    reading.placed:SetJustifyH("LEFT")
    local previous
    reading.buttons = {}
    for _, spec in ipairs({
        { "Interface\\Buttons\\UI-GuildButton-PublicNote-Up", Markers.TEXT.edit, Markers.TEXT.editTip,
          function() if opened then Edit(opened) end end },
        { "Interface\\CURSOR\\UI-Cursor-Move", Markers.TEXT.move, Markers.TEXT.moveTip, Move },
        { "Waypoint-MapPin-Untracked", Markers.TEXT.pin, Markers.TEXT.pinTip, Pin },
        { "Interface\\Buttons\\UI-GroupLoot-Pass-Up", Markers.TEXT.delete, Markers.TEXT.deleteTip, Delete },
    }) do
        local button = Square(reading, spec[1], spec[2], spec[3], spec[4])
        reading.buttons[#reading.buttons + 1] = button
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 6, 0) else button:SetPoint("BOTTOMLEFT") end
        previous = button
    end

    editing = CreateFrame("Frame", nil, content)
    editing:SetAllPoints()
    local y = 0
    local function Label(words)
        local label = editing:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 0, y)
        label:SetText(words)
        y = y - 16
        return label
    end
    Label(Markers.TEXT.title)
    local titleFrame, title = Box(editing, false)
    titleFrame:SetPoint("TOPLEFT", 0, y)
    titleFrame:SetPoint("RIGHT")
    titleFrame:SetHeight(24)
    title:SetMaxLetters(Markers.TITLE_MOST)
    y = y - 24 - 8
    Label(Markers.TEXT.words)
    local wordsFrame, words = Box(editing, true)
    wordsFrame:SetPoint("TOPLEFT", 0, y)
    wordsFrame:SetPoint("RIGHT")
    wordsFrame:SetHeight(Markers.WORDS)
    words:SetMaxLetters(Markers.TEXT_MOST)
    y = y - Markers.WORDS - 8
    Label(Markers.TEXT.icon)
    editing.icons = {}
    for index, icon in ipairs(Markers.ICONS) do
        local button = CreateFrame("Button", nil, editing)
        button:SetSize(Markers.PICK, Markers.PICK)
        local column, row = (index - 1) % Markers.PER_ROW, math.floor((index - 1) / Markers.PER_ROW)
        button:SetPoint("TOPLEFT", column * (Markers.PICK + 6), y - row * (Markers.PICK + 6))
        button.box = Look.Outline(button)
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("CENTER")
        texture:SetSize(Markers.PICK - 6, Markers.PICK - 6)
        Paint(texture, icon.key)
        local light = button:CreateTexture(nil, "HIGHLIGHT")
        light:SetAllPoints()
        light:SetColorTexture(Look.SHADE[1], Look.SHADE[2], Look.SHADE[3], Look.SHADE[4])
        button.key = icon.key
        button:SetScript("OnClick", ns.Guard(function()
            picked = icon.key
            Light()
        end))
        editing.icons[index] = button
    end
    local rows = math.ceil(#Markers.ICONS / Markers.PER_ROW)
    y = y - rows * (Markers.PICK + 6) - 6
    local save = Look.Red(editing, Markers.TEXT.save, 100)
    save:SetPoint("TOPLEFT", 0, y)
    save:SetScript("OnClick", ns.Guard(Save))
    local cancel = Look.Red(editing, Markers.TEXT.cancel, 100)
    cancel:SetPoint("LEFT", save, "RIGHT", 8, 0)
    cancel:SetScript("OnClick", ns.Guard(Cancel))
    editing.height = -y + 28
    editing.title, editing.words, editing.save, editing.cancel = title, words, save, cancel
    title:SetScript("OnEnterPressed", ns.Guard(Save))
    title:SetScript("OnTabPressed", ns.Guard(function() words:SetFocus() end))
    title:SetScript("OnEscapePressed", ns.Guard(Cancel))
    words:SetScript("OnEscapePressed", ns.Guard(Cancel))
    card:Hide()
    Markers.card = card -- (its parts, for the tests: card.look, card.reading, card.editing)
    card.look, card.reading, card.editing = look, reading, editing
end

-- A marker's card, reading it, beside the mouse.
function Markers.Open(marker)
    if not marker then return end
    Build()
    if fresh and fresh ~= marker then
        local old = fresh
        fresh = nil
        Markers.Remove(old)
    end
    opened = marker
    Beside()
    card:Show()
    Read(marker)
end

-- A new marker at a spot of a map ({ map, x, y }, Canvas.lua), its card open to write in; none where there is no map.
function Markers.New(spot)
    if type(spot) ~= "table" or not spot.map or not spot.x then
        UIErrorsFrame:AddMessage(Markers.TEXT.noPlace, 1, 0.1, 0.1)
        return nil
    end
    local store = ns.store
    store.markerNext = (tonumber(store.markerNext) or 0) + 1
    local marker = { id = store.markerNext, map = spot.map, x = spot.x, y = spot.y, title = "", text = "",
                     icon = Markers.ICONS[1].key, made = Core.Ask(GetServerTime) }
    local list = Markers.List()
    list[#list + 1] = marker
    Changed()
    Markers.Open(marker)
    fresh = marker
    Edit(marker)
    return marker
end

-- The marker waiting for its new place (Move), nil while none; the next click on the map puts it (Canvas.lua).
function Markers.Moving()
    return moving
end

function Markers.Put(spot)
    local marker = moving
    moving = nil
    if not marker then return end
    if type(spot) ~= "table" or not spot.map or not spot.x then
        UIErrorsFrame:AddMessage(Markers.TEXT.noPlace, 1, 0.1, 0.1)
        return
    end
    marker.map, marker.x, marker.y = spot.map, spot.x, spot.y
    Changed()
end

-- Esc while one waits for its place: it stays where it was.
function Markers.Stay()
    moving = nil
end

-- The settings changed (a profile loaded, another account's markers synced): the pins made anew.
function Markers.Stale()
    stale = true
end
