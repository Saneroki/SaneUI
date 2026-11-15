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
--      sharing     the card's Share (Saneroki, 2026-11-15: "Can we share markers with party and guild members?"):
--                  this marker, or all of yours in its zone, to your party or raid, or to your guild; who gets them
--                  is asked first (a small card: who shares what, Keep or No), and only kept on Keep, marked as
--                  from the one who shared them; one shared again by its maker (edited, moved) changes the copy
--                  kept, never a second one. The setting Markers others share (on) lets nobody ask while off.
--
--      Markers.List()            every marker: { id, map, x, y (0 to 1 on its map), title, text, icon, made (time) }
--      Markers.New(spot)         a new one at { map, x, y } (Canvas: Alt and a click), its card open to write in
--      Markers.Open(marker)      its card
--      Markers.Pins()            their pins (Pins.For), made anew when one changes
--      Markers.Moving()          the marker waiting for its new place (Move); Markers.Put(spot) puts it there
--      Markers.Remove(marker), Markers.Close()
--
--  Kept for the account in the module's saved settings (ns.store.markers), each game's in its own (their map IDs
--  differ, and so do their saved files): personal notes, never shipped, shared only when you share them yourself
--  (data.md, *Game facts, not people*). Drawing on the map comes later (board #481).
--
--  On the wire (Core.Wire, kind M, a block): "1", then a row a marker, cut by \030; a row: its origin (the maker's
--  character and the maker's own number, kept with every copy), its map, x, y (four places), icon, title and words,
--  cut by \031. A block holds what fits in Markers.BLOCK bytes, more go in further blocks (each asked about apart).
--  Taken: at most Markers.TAKE a block; a row whose map is no number, whose point is off its map, is left out; an
--  icon not known is the first; a title and words cut to their most; never from yourself (the wire drops those).
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
Markers.PER_ROW = 9          -- icons to pick in a row
Markers.BUTTON = 30          -- the card's grey square buttons
Markers.TITLE_MOST, Markers.TEXT_MOST = 60, 1000 -- letters a title and its words hold at most
Markers.KIND = "M"           -- the wire's kind of markers shared
Markers.BLOCK = 2800         -- bytes of rows in one block, unpacked (packed it stays well under the wire's 4 KB)
Markers.TAKE = 50            -- markers taken from one block at most
Markers.OFFER = 300          -- the offer card's width
-- The icons to pick from, the first the one a new marker has: the game's raid marks, its map icons and a few of its
-- spell icons for what happens where (Saneroki, 2026-11-15: "more custom map marker pin icon options? like Doors,
-- stairs, bosses, chests, jumps etc"), all in Forever's client. cut: a spell icon's frame cut off. A key is kept with
-- a marker and shared: never renamed; a key not known here (an older or newer copy) shows the first.
local ICON_CUT = 0.08
Markers.ICONS = {
    { key = "star", texture = 137001 }, { key = "circle", texture = 137002 }, { key = "diamond", texture = 137003 },
    { key = "triangle", texture = 137004 }, { key = "moon", texture = 137005 }, { key = "square", texture = 137006 },
    { key = "cross", texture = 137007 }, { key = "skull", texture = 137008 },
    -- the dungeon's way
    { key = "boss", atlas = "vignettekillboss" }, { key = "elite", atlas = "vignettekillelite" },
    { key = "danger", atlas = "dungeonskull" }, { key = "door", atlas = "poi-door" },
    { key = "up", atlas = "poi-door-arrow-up" }, { key = "down", atlas = "poi-door-arrow-down" },
    { key = "jump", texture = "Interface\\Icons\\Ability_HeroicLeap", cut = ICON_CUT },
    { key = "portal", texture = "Interface\\Icons\\Spell_Arcane_TeleportStormWind", cut = ICON_CUT },
    { key = "trap", atlas = "vehicle-trap-red" },
    { key = "chest", atlas = "vignetteloot" }, { key = "locked", atlas = "vignetteloot-locked" },
    { key = "key", texture = "Interface\\Icons\\INV_Misc_Key_03", cut = ICON_CUT },
    -- the group
    { key = "tank", atlas = "groupfinder-icon-role-large-tank" }, { key = "healer", atlas = "groupfinder-icon-role-large-heal" },
    { key = "damage", atlas = "groupfinder-icon-role-large-dps" }, { key = "summon", atlas = "Raid-Icon-SummonPending" },
    { key = "rally", texture = "Interface\\Icons\\INV_BannerPVP_02", cut = ICON_CUT },
    { key = "lookout", texture = "Interface\\Icons\\INV_Misc_Spyglass_03", cut = ICON_CUT },
    -- what to mind
    { key = "fire", texture = "Interface\\Icons\\Spell_Fire_Fire", cut = ICON_CUT },
    { key = "water", texture = "Interface\\Icons\\Ability_Druid_AquaticForm", cut = ICON_CUT },
    { key = "sneak", texture = "Interface\\Icons\\Ability_Stealth", cut = ICON_CUT },
    { key = "run", texture = "Interface\\Icons\\Ability_Rogue_Sprint", cut = ICON_CUT },
    { key = "bomb", texture = "Interface\\Icons\\INV_Misc_Bomb_04", cut = ICON_CUT },
    { key = "unknown", texture = "Interface\\Icons\\INV_Misc_QuestionMark", cut = ICON_CUT },
    -- the world
    { key = "quest", atlas = "questnormal" }, { key = "herb", atlas = "professions_tracking_herb" },
    { key = "ore", atlas = "professions_tracking_ore" }, { key = "inn", atlas = "innkeeper" },
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
    moveTip = "Click on the map where it should stand; a right click: it stays. With the palette's Move tool you can also drag it.",
    moving = "Click on the map where %s should stand; a right click: it stays.",
    pin = "The map pin here",
    pinTip = "The game's map pin on this marker: the golden line leads there.",
    delete = Core.Word("DELETE", "Delete"),
    deleteTip = "This marker away for good (asked first).",
    deleteAsk = "Delete the marker %s?",
    placed = "%s, put %s",
    noPlace = "No marker here: zoom in onto a zone.",
    inPlan = "in %s",
    offerPlan = "%s shares the sketch %s with you: %d markers, %d drawings.",
    share = "Share",
    shareTip = "This marker, or all of yours in its zone, to your party or raid, to your guild, or to someone: they are asked whether to keep them.",
    shareOne = "This marker with your %s",
    shareZone = "Your %d markers in %s with your %s",
    shareSomeone = "This marker with someone...",
    shareZoneSomeone = "Your %d markers in %s with someone...",
    shareWith = "Share with someone",
    party = "party", raid = "raid", guild = "guild",
    shared = "%d %s sent to your %s.", one = "marker", many = "markers",
    sharedTo = "%d %s sent to %s.",
    offered = "Markers shared",
    offerOne = "%s shares a marker with you: %s.",
    offerMany = "%s shares %d markers with you: %s.",
    keep = "Keep",
    no = Core.Word("NO", "No"),
    from = "from %s",
    hint = "Click: its card. Double click: the map pin here.",
    hintFloor = "Click: its card.",
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

-- An icon on a texture: the raid mark's or spell icon's file (a spell icon's frame cut off), else the map icon's atlas.
local function Paint(texture, key)
    local icon = Icon(key)
    if icon.texture then
        texture:SetTexture(icon.texture)
        local cut = icon.cut or 0
        texture:SetTexCoord(cut, 1 - cut, cut, 1 - cut)
    else
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetAtlas(icon.atlas)
    end
end
Markers.Paint = Paint

-- The map drawn anew with the markers as they are now.
local function Changed()
    stale = true
    if ns.Canvas and ns.Canvas.Refresh then ns.Canvas.Refresh() end
    if ns.Draw and ns.Draw.Changed then ns.Draw.Changed() end -- (a dungeon's floor shown)
end
Markers.Changed = Changed -- (a marker dragged: Draw.lua)

-- The markers as pins: in their plane (Coords), their icon, their title as the heading and their words in the tooltip,
-- their title beside them on the full map.
function Markers.Pins()
    if not stale then return pins end
    stale = false
    wipe(pins)
    for _, marker in ipairs(Markers.List()) do
        local home = type(marker.map) == "number" and ns.Plans.Visible(marker.plan) and Coords.PlaneOf(marker.map)
        local u, v
        if home then u, v = Coords.MapToPlane(marker.map, marker.x or 0, marker.y or 0, home) end
        if u then
            local icon = Icon(marker.icon)
            local lines = {}
            if marker.text and marker.text ~= "" then lines[1] = marker.text end
            if marker.from then lines[#lines + 1] = { Markers.TEXT.from:format(marker.from), 0.6, 0.6, 0.6 } end
            lines[#lines + 1] = { Markers.TEXT.hint, 0.5, 0.5, 0.5 }
            pins[#pins + 1] = { kind = "mark", key = "mark:" .. marker.id, marker = marker, name = marker.title,
                                label = marker.title, home = home, u = u, v = v, map = marker.map, x = marker.x,
                                y = marker.y, texture = icon.texture, atlas = icon.atlas, cut = icon.cut,
                                lines = lines }
        end
    end
    return pins
end

-- The name of the map a marker stands on: a zone's, or a dungeon's and its floor's (Dungeons.Named).
local function Where(map)
    local named = ns.Dungeons and ns.Dungeons.Named and ns.Dungeons.Named(map)
    if named then return named end
    return type(map) == "number" and ns.Find and ns.Find.MapName(map) or ""
end
Markers.Where = Where

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
    local placed = Markers.TEXT.placed:format(Where(marker.map), Day(marker.made))
    if marker.from then placed = placed .. ", " .. Markers.TEXT.from:format(marker.from) end
    if #ns.Plans.List() > 1 then placed = placed .. ", " .. Markers.TEXT.inPlan:format(ns.Plans.Of(marker).name or "") end
    reading.placed:SetText(placed)
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
        { "Interface\\FriendsFrame\\UI-Toast-BroadcastIcon", Markers.TEXT.share, Markers.TEXT.shareTip,
          function(button) Markers.Share(button) end },
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
    local marker = { id = store.markerNext, plan = ns.Plans.Active().id, map = spot.map, x = spot.x, y = spot.y,
                     title = "", text = "",
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

-------------------------------------------------------------------------------
--  Sharing
-------------------------------------------------------------------------------
local Wire = Core.Wire
local offers = {} -- the shares waiting for an answer, the oldest first: { sender, rows }
local offer       -- the card that asks
Markers.WAITING = 10 -- shares waiting for an answer at most (more are let go)

-- Your raid or else your party, as the wire names it, and its word; nil outside a group.
local function Group()
    local home = rawget(_G, "LE_PARTY_CATEGORY_HOME")
    if Core.Ask(rawget(_G, "IsInRaid"), home) then return "RAID", Markers.TEXT.raid end
    if Core.Ask(rawget(_G, "IsInGroup"), home) then return "PARTY", Markers.TEXT.party end
    return nil, Markers.TEXT.party
end

-- Words on the wire: none of its cutting signs, nor any other sign but the line's end; so many bytes at most.
local function Clean(text, most)
    text = tostring(text or ""):gsub("[%z\001-\009\011-\031]", "")
    if most and #text > most then text = text:sub(1, most) end
    return text
end

-- Where a marker came from, kept with every copy: its maker's character and the maker's own number.
local function Origin(marker)
    marker.origin = marker.origin or ((Core.charKey or "?") .. ":" .. tostring(marker.id))
    return marker.origin
end

function Markers.Row(marker)
    return table.concat({ Clean(Origin(marker), 80), tostring(marker.map), ("%.4f"):format(marker.x or 0),
        ("%.4f"):format(marker.y or 0), Clean(marker.icon, 16), Clean(marker.title, Markers.TITLE_MOST),
        Clean(marker.text, Markers.TEXT_MOST) }, "\031")
end

-- Markers sent to a channel of the wire (WHISPER: to the player named target), in as many blocks as they need; how
-- many went.
function Markers.Send(list, channel, target)
    if not channel then return 0 end
    local sent, rows, size = 0, {}, 0
    local function Flush()
        if #rows == 0 then return end
        if Wire.SendBlock(Markers.KIND, "1\030" .. table.concat(rows, "\030"), channel, target) then sent = sent + #rows end
        wipe(rows)
        size = 0
    end
    for _, marker in ipairs(list) do
        local row = Markers.Row(marker)
        if size > 0 and size + #row > Markers.BLOCK then Flush() end
        rows[#rows + 1] = row
        size = size + #row + 1
    end
    Flush()
    return sent
end

local function Told(count, word, someone)
    ns.Print((someone and Markers.TEXT.sharedTo or Markers.TEXT.shared):format(count,
        count == 1 and Markers.TEXT.one or Markers.TEXT.many, word))
end

-- Markers to someone: the player asked for (Core.AskPlayer: the game's search of the players it knows), then sent.
local function ToSomeone(list)
    Core.AskPlayer(Markers.TEXT.shareWith, ns.Guard(function(name) Told(Markers.Send(list, "WHISPER", name), name, true) end))
end
Markers.ToSomeone = ToSomeone

-- The card's Share: a menu of this marker, or all of yours on its map, to your raid or party, to your guild (one you
-- are not in greyed), or to someone (Saneroki, 2026-11-15: "share the drawing with someone specific instead of the
-- entire party or guild").
function Markers.Share(button)
    local marker = opened
    if not marker or not rawget(_G, "MenuUtil") then return end
    MenuUtil.CreateContextMenu(button, ns.Guard(function(_, root)
        root:CreateTitle(Markers.TEXT.share)
        local zone = ns.Find and ns.Find.MapName(marker.map) or "?"
        local here = {}
        for _, each in ipairs(Markers.List()) do
            if each.map == marker.map then here[#here + 1] = each end
        end
        local group, groupWord = Group()
        local guild = Core.Ask(rawget(_G, "IsInGuild")) and "GUILD" or nil
        for _, target in ipairs({ { group, groupWord }, { guild, Markers.TEXT.guild } }) do
            local channel, word = target[1], target[2]
            local one = root:CreateButton(Markers.TEXT.shareOne:format(word),
                ns.Guard(function() Told(Markers.Send({ marker }, channel), word) end))
            if not channel and one.SetEnabled then one:SetEnabled(false) end
            if #here > 1 then
                local all = root:CreateButton(Markers.TEXT.shareZone:format(#here, zone, word),
                    ns.Guard(function() Told(Markers.Send(here, channel), word) end))
                if not channel and all.SetEnabled then all:SetEnabled(false) end
            end
        end
        root:CreateButton(Markers.TEXT.shareSomeone, ns.Guard(function() ToSomeone({ marker }) end))
        if #here > 1 then
            root:CreateButton(Markers.TEXT.shareZoneSomeone:format(#here, zone), ns.Guard(function() ToSomeone(here) end))
        end
    end))
end

-- One marker's row read (see the file's head): nil where it does not hold (a map that is no zone's number nor a
-- dungeon's floor, a point off its map).
function Markers.ReadRow(row)
    local origin, map, x, y, icon, title, words = row:match("^(.-)\031(.-)\031(.-)\031(.-)\031(.-)\031(.-)\031(.*)$")
    map, x, y = ns.Plans.MapOf(map), tonumber(x), tonumber(y)
    if not (origin and origin ~= "" and map and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1) then return nil end
    return { origin = Clean(origin, 80), map = map, x = x, y = y, icon = Icon(icon).key,
             title = Clean(title, Markers.TITLE_MOST), text = Clean(words, Markers.TEXT_MOST) }
end

-- A block's markers, read: the rows that hold, at most Markers.TAKE.
function Markers.Read(text)
    local rows = {}
    local version, rest = tostring(text or ""):match("^(%d+)\030(.*)$")
    if version ~= "1" or not rest then return rows end
    for row in (rest .. "\030"):gmatch("(.-)\030") do
        if #rows >= Markers.TAKE then break end
        rows[#rows + 1] = Markers.ReadRow(row)
    end
    return rows
end

-- A share kept: each marker new, or the copy of the same origin changed (its maker shared it again).
function Markers.Keep(share)
    local list = Markers.List()
    local own = (Core.charKey or "?") .. ":"
    for _, row in ipairs(share.rows) do
        local kept
        for _, each in ipairs(list) do
            if each.origin == row.origin or (not each.origin and own .. tostring(each.id) == row.origin) then kept = each end
        end
        if not kept then
            ns.store.markerNext = (tonumber(ns.store.markerNext) or 0) + 1
            kept = { id = ns.store.markerNext, made = Core.Ask(GetServerTime), origin = row.origin }
            list[#list + 1] = kept
        end
        kept.map, kept.x, kept.y, kept.icon, kept.title, kept.text = row.map, row.x, row.y, row.icon, row.title, row.text
        if row.origin:sub(1, #own) ~= own then kept.from = share.sender end
    end
    Changed()
end

local Ask
local function Answer(keep)
    local share = table.remove(offers, 1)
    if share and keep then
        if share.plan then ns.Plans.Keep(share) else Markers.Keep(share) end
    end
    Ask()
end

-- The card that asks: who shares what (the first few titles, the zone), Keep or No; the next share once answered.
local function Offer()
    if offer then return offer end
    offer = CreateFrame("Frame", nil, UIParent)
    offer:SetWidth(Markers.OFFER)
    offer:SetFrameStrata("DIALOG")
    offer:SetToplevel(true)
    offer:SetClampedToScreen(true)
    offer:EnableMouse(true)
    offer:SetPoint("TOP", UIParent, "TOP", 0, -160)
    offer.look = Look.Dress(offer, Markers.TEXT.offered)
    offer.look.close:SetScript("OnClick", ns.Guard(function() Answer(false) end))
    offer.words = offer.look.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    offer.words:SetPoint("TOPLEFT")
    offer.words:SetWidth(Markers.OFFER - 2 * Look.INSIDE)
    offer.words:SetJustifyH("LEFT")
    offer.words:SetWordWrap(true)
    offer.keep = Look.Red(offer.look.content, Markers.TEXT.keep, 100)
    offer.keep:SetPoint("BOTTOMLEFT")
    offer.keep:SetScript("OnClick", ns.Guard(function() Answer(true) end))
    offer.no = Look.Red(offer.look.content, Markers.TEXT.no, 100)
    offer.no:SetPoint("LEFT", offer.keep, "RIGHT", 8, 0)
    offer.no:SetScript("OnClick", ns.Guard(function() Answer(false) end))
    offer:Hide()
    Markers.offer = offer -- (for the tests)
    return offer
end

function Ask()
    local share = offers[1]
    if not share then
        if offer then offer:Hide() end
        return
    end
    Offer()
    local names = {}
    for index = 1, math.min(3, #share.rows) do
        local title = share.rows[index].title
        names[index] = title ~= "" and title or Markers.TEXT.untitled
    end
    if #share.rows > 3 then names[#names + 1] = "..." end
    local words = #share.rows == 1 and Markers.TEXT.offerOne:format(share.sender, names[1])
        or Markers.TEXT.offerMany:format(share.sender, #share.rows, table.concat(names, ", "))
    if share.plan then
        words = Markers.TEXT.offerPlan:format(share.sender, share.plan.name, #share.rows, #share.drawings)
    end
    local first = share.rows[1] or share.drawings and share.drawings[1]
    local zone = first and Where(first.map)
    if zone and zone ~= "" then words = words .. " (" .. zone .. ")" end
    offer.words:SetText(words)
    local height = (offer.words:GetStringHeight() or 14) + 12 + 28
    offer:SetHeight(height + Look.DRESS_HEAD + 4 + Look.INSIDE + 4)
    offer:Show()
end

-- A block of markers heard (the wire, kind M): asked about, unless the setting says no or it holds none; a part of a
-- plan (version 2, Plans.Read) once all its parts came.
function Markers.Heard(sender, text)
    if ns.off or not (ns.options and ns.options.markerShares) then return end
    if #offers >= Markers.WAITING then return end
    if tostring(text or ""):sub(1, 2) == "2\030" then
        local share = ns.Plans.Read(sender, text)
        if not share or (#share.rows == 0 and #share.drawings == 0) then return end
        offers[#offers + 1] = share
    else
        local rows = Markers.Read(text)
        if #rows == 0 then return end
        offers[#offers + 1] = { sender = tostring(sender or "?"), rows = rows }
    end
    if #offers == 1 then Ask() end
end

if Wire and Wire.ListenBlock then Wire.ListenBlock(Markers.KIND, ns.Guard(Markers.Heard)) end
