local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Look
--  The kit (Saneroki, 2026-11-15; Doc/guides/interface-style.md, The kit):
--  Sane UI's windows built from WoW: Forever's own parts, the login screen's
--  first, in the game's own Friz Quadrata. Every part is the game's atlas by
--  its name, so each game draws its own picture under it; where a game has no
--  picture by that name (Retail lacks Forever's heavy bronze), a stand-in of
--  its own draws instead (Look.STAND_IN), or nothing.
--
--  Sizes are the game's own in UI units, as its templates lay these parts out
--  (named at each part). An atlas with slice data (the bronze frame, the search
--  bar, the inside frame) is sliced by the game itself: its corners keep their
--  size however large the texture is drawn.
--
--      Look.Atlas(texture, name, useSize) -- an atlas, else its stand-in; false when neither is there
--      Look.Has(name)                     -- whether the game has an atlas by that name
--      Look.Font(name, size, flags)       -- a font object of Friz Quadrata (the game's GameFontNormal's), made once
--      Look.Frame(frame)                  -- a window's heavy bronze round frame: :Fit(l, b, w, h), :Rest(), :Hold(on)
--      Look.Plate(frame)                  -- the bronze plate alone, filling frame: once, cut to it (Look.Cover)
--      Look.Line(parent, alpha)           -- the thin golden line (the search bar's outline colour)
--      Look.Square(parent, size)          -- the grey square button (a normal one), :Icon(atlas | texture)
--      Look.Red(parent, words, width)     -- the red button (an important one: yes, no, sell)
--      Look.Search(box)                   -- a SearchBoxTemplate dressed as the character list's search
--      Look.Head(parent, words)           -- a section's head: the character window's (General, Weapons)
--      Look.Band(parent)                  -- a row's band, under every other line of a list
--      Look.Inset(frame)                  -- the thin frame round a part of a window
--      Look.Box(frame)                    -- the grey box: a section that is no window
--      Look.Headline(parent)              -- the loading screen's bar: a frame for a headline, words or buttons in it
--      Look.Slot(parent)                  -- an item's slot: the character window's gear slot
--      Look.Tab(parent, height)           -- a tab of the full screen's top bar: tab:SetSelected, tab:SetEnd
--      Look.Outline(frame)                -- the thin golden outline round frame (the search bar's): box:SetStrong(on)
--      Look.Rule(parent)                  -- the thin golden line, unplaced
--      Look.SetFont(fs, size, bold, colour) -- Friz Quadrata at a 1080p layout's size (Look.PX), white, the game's shadow
--      Look.Dress(frame, title)           -- a window of its own in the bronze: its head, title, X and content frame;
--      Look.Inner(w, h), Look.Outer(w, h) -- its content's size in a window that large, and the window round a content
-------------------------------------------------------------------------------
local Look = {}
Core.Look = Look

Look.FONT = "Fonts\\FRIZQT__.TTF"                  -- the game's own; every font object of its UI is this one
Look.NAV = { 0.8392, 0.7020, 0.5020 }               -- Forever's top bar words (CAMELOT_NAV_BAR_TEXT_COLOR_NORMAL)
Look.NAV_LIT = { 1.0, 0.8863, 0.7176 }              -- under the mouse and chosen (_HIGHLIGHT)
Look.NAV_OFF = { 0.5608, 0.5608, 0.5608 }           -- disabled (_DISABLED)
Look.LINE = { 0.62, 0.50, 0.30 }                    -- the thin golden outline of the search bar, as a colour of our own
Look.INK = { 1, 1, 1, 1 }                           -- words on the dark plates (HIGHLIGHT_FONT_COLOR)
Look.GOLD = { 1, 0.82, 0, 1 }                       -- heads and labels (NORMAL_FONT_COLOR)
Look.FAINT = { 0.6, 0.6, 0.6, 1 }                   -- what is only said in passing
Look.SHADE = { 1, 0.82, 0, 0.12 }                   -- a row under the mouse: a gold glow
Look.PX = 768 / 1080                                -- a 1080p layout's pixel in UI units (the windows' sizes are written in those)
-- The loot feed's hand-drawn font (Kalam Bold, Core's Fonts), kept by Saneroki's word (2026-11-02: "Leave it").
Look.HAND = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Bold.ttf"

-- The parts' sizes (UI units), as the game's templates have them.
Look.EDGE = 7          -- the bronze frame's picture reaches this far past the window: its shadow, see-through
Look.BAND = 10         -- the bronze band's breadth inside the window
Look.INSIDE = 14       -- from the window's edge to what it holds: inside the band, with a little room
Look.SQUARE = 42       -- the grey square button (CommonSquareIconButtonTemplate) and the red square ones
Look.RED = 42          -- the red button's height at its largest (the character list's); its words GameFontNormal
Look.HEAD = 32         -- a section's head (CharacterStatFrameCategoryTemplate: 197 x 40, its picture 201 x 32)
Look.BAND_HEIGHT = 18  -- a row's band (UI-Character-Info-Line-Bounce)
Look.TAB = 64          -- the top bar's buttons (Forever's CharacterSelectNavBarButtonBaseTemplate)
Look.TAB_OVER = 27     -- how far the outer tabs' pictures reach past them, at that height
Look.SLOT = 55         -- the gear slot's picture round a 37 unit item button

-- What draws where the game has no picture by Forever's name (Retail, the testing platform: Forever's own
-- heavy bronze and the character window's slots are Forever's alone). An atlas's name, a file to repeat (tile),
-- or false: nothing.
Look.STAND_IN = {
    ["heavybronze-frame-basic"] = "ui-frame-chamfered",
    ["heavybronze-frame-background"] = { file = "Interface\\FrameGeneral\\UI-Background-Rock" },
    ["heavybronze-vert-cornerbracket-tr"] = false,
    ["heavybronze-vert-cornerbracket-br"] = false,
    ["ui-character-info-gearslot"] = "UI-HUD-ActionBar-IconFrame",
    ["bank-frame-item-slotframe"] = "bags-item-slot64",         -- Forever's bank's free slot
    ["bank-frame-bag-slotframe"] = "UI-HUD-ActionBar-IconFrame", -- and its slot that holds something
    ["ui-character-info-stat-bg"] = { file = "Interface\\FrameGeneral\\UI-Background-Rock", tile = true },
}

local known = {}
function Look.Has(name)
    if type(name) ~= "string" then return false end
    local has = known[name]
    if has == nil then
        local textures = rawget(_G, "C_Texture")
        if textures and textures.GetAtlasInfo then
            has = textures.GetAtlasInfo(name) ~= nil
        else
            has = true -- no way to ask (outside the game): the atlas is set, as the game would
        end
        known[name] = has
    end
    return has
end

function Look.Atlas(texture, name, useSize)
    if Look.Has(name) then
        texture:SetAtlas(name, useSize)
        return true
    end
    local stand = Look.STAND_IN[name:lower()]
    if type(stand) == "string" and Look.Has(stand) then
        texture:SetAtlas(stand, useSize)
        return true
    end
    if type(stand) == "table" then
        texture:SetTexture(stand.file, stand.tile and "REPEAT" or nil, stand.tile and "REPEAT" or nil)
        texture:SetHorizTile(stand.tile or false)
        texture:SetVertTile(stand.tile or false)
        return true
    end
    texture:SetTexture(nil)
    return false
end

-- A font object of Friz Quadrata in the game's normal gold (or white: base "GameFontHighlight"), that size (UI
-- units) and outline, made once by its name: the game's font object copied, else made of the font file itself.
function Look.Font(name, size, flags, base)
    local font = Core.Font(name, base or "GameFontNormal", size, flags)
    if font then return font end
    font = rawget(_G, name) or CreateFont(name)
    font:SetFont(Look.FONT, size or 12, flags or "")
    if base == "GameFontHighlight" then font:SetTextColor(1, 1, 1) else font:SetTextColor(1, 0.82, 0) end
    font:SetShadowColor(0, 0, 0, 1)
    font:SetShadowOffset(1, -1)
    return font
end

-- The bronze plate's picture laid over a rect that large: once, as large as the rect's longer side and cut to the
-- rect, its middle in the middle. So its grain is as fine as the character list draws it (Blizzard stretches it down
-- to the list's size) and never repeats (Saneroki, 2026-11-15: tiled at its own size it looked low in resolution).
local function Cover(plate, width, height)
    if not (width and height) or width <= 0 or height <= 0 then return end
    local side = math.max(width, height)
    local u, v = width / side, height / side
    plate:SetTexCoord((1 - u) / 2, (1 + u) / 2, (1 - v) / 2, (1 + v) / 2)
end
Look.Cover = Cover

-- A plate that follows its owner's size: the picture laid anew whenever the owner is sized (inset: the plate's room
-- in from the owner's sides).
local function Follow(plate, owner, inset)
    local function Laid()
        local w, h = owner:GetSize()
        Cover(plate, (w or 0) - 2 * inset, (h or 0) - 2 * inset)
    end
    owner:HookScript("OnSizeChanged", Core.Guard("look", Laid))
    Laid()
end

-- The bronze plate, the character list's textured background, over all of frame.
function Look.Plate(frame, layer)
    local plate = frame:CreateTexture(nil, layer or "BACKGROUND", nil, -7)
    Look.Atlas(plate, "heavybronze-frame-background")
    plate:SetHorizTile(false)
    plate:SetVertTile(false)
    plate:SetAllPoints()
    Follow(plate, frame, 0)
    return plate
end

-- The thin golden line, along a part's edge or between two parts (the caller places it).
function Look.Line(parent, alpha, layer)
    local line = parent:CreateTexture(nil, layer or "ARTWORK")
    line:SetColorTexture(Look.LINE[1], Look.LINE[2], Look.LINE[3], alpha or 0.6)
    line:SetHeight(1)
    return line
end

-------------------------------------------------------------------------------
--  The window's frame: the character list's heavy bronze
-------------------------------------------------------------------------------
-- The frame placed on a rect given (left, bottom, width, height, in UIParent's units, as the full screen's motion
-- gives them: Edge.lua), or on its window again.
local function Fit(look, left, bottom, width, height)
    look:ClearAllPoints()
    if left then
        look:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
        look:SetSize(math.max(width, 1), math.max(height, 1))
    else
        look:SetAllPoints(look.window)
    end
end

local function Rest(look)
    if not look.held then Fit(look) end
end

-- Another part fits it on every step of its motion (on), or no more.
local function Hold(look, on)
    look.held = on and true or nil
end

-- A bracket lit (on): its corner under the mouse or held sizes the window (Core.Board's corners). The bracket again
-- over it, added light; made the first time.
local CORNERS = { TOPRIGHT = "heavybronze-vert-cornerbracket-TR", BOTTOMRIGHT = "heavybronze-vert-cornerbracket-BR" }
local function Light(look, corner, on)
    look.lit = look.lit or {}
    local lit = look.lit[corner]
    if not lit then
        if not on or not CORNERS[corner] then return end
        lit = look:CreateTexture(nil, "ARTWORK", nil, 1)
        Look.Atlas(lit, CORNERS[corner], true)
        lit:SetAllPoints(corner == "TOPRIGHT" and look.top or look.bottom)
        lit:SetBlendMode("ADD")
        lit:SetAlpha(0.5)
        look.lit[corner] = lit
    end
    lit:SetShown(on and true or false)
end

-- The character list's frame round a window (CharacterSelectListBGTemplate, Camelot): the bronze plate, the band
-- round it, the two brackets on its right corners. A frame one level under the window, as Core.Skin's, so all the
-- window holds stands over it; it answers as a skin does (Edge.lua fits it while the window fills the screen).
function Look.Frame(frame)
    local look = CreateFrame("Frame", nil, frame)
    look.window = frame
    look:SetAllPoints()
    look:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
    look.plate = look:CreateTexture(nil, "BACKGROUND", nil, -7)
    Look.Atlas(look.plate, "heavybronze-frame-background")
    look.plate:SetHorizTile(false)
    look.plate:SetVertTile(false)
    look.plate:SetPoint("TOPLEFT", 4, -4)
    look.plate:SetPoint("BOTTOMRIGHT", -4, 4)
    Follow(look.plate, look, 4)
    look.border = look:CreateTexture(nil, "BORDER")
    Look.Atlas(look.border, "heavybronze-frame-basic")
    look.border:SetPoint("TOPLEFT", -Look.EDGE, Look.EDGE)
    look.border:SetPoint("BOTTOMRIGHT", Look.EDGE, -Look.EDGE)
    look.top = look:CreateTexture(nil, "ARTWORK")
    Look.Atlas(look.top, CORNERS.TOPRIGHT, true)
    look.top:SetPoint("TOPRIGHT", look.border, "TOPRIGHT")
    look.bottom = look:CreateTexture(nil, "ARTWORK")
    Look.Atlas(look.bottom, CORNERS.BOTTOMRIGHT, true)
    look.bottom:SetPoint("BOTTOMRIGHT", look.border, "BOTTOMRIGHT")
    look.Fit, look.Rest, look.Hold, look.Light = Fit, Rest, Hold, Light
    return look
end

-------------------------------------------------------------------------------
--  Buttons
-------------------------------------------------------------------------------
-- Its icon in the middle: an atlas (the game's yellow ones: common-icon-zoomin, -rotateleft, -undo) or a texture.
local function Icon(button, art, size)
    local icon = button.icon
    if not icon then
        icon = button:CreateTexture(nil, "ARTWORK", nil, 5)
        icon:SetPoint("CENTER")
        button.icon = icon
    end
    if type(art) == "string" and Look.Has(art) then icon:SetAtlas(art) else icon:SetTexture(art) end
    local s = size or math.floor(button:GetWidth() * 24 / 42 + 0.5)
    icon:SetSize(s, s)
    return icon
end

-- The grey square button with a golden rim (the character select's rotate buttons, the character window's zoom:
-- CommonSquareIconButtonTemplate): pressed it sinks, under the mouse it lights.
function Look.Square(parent, size, template)
    local button = CreateFrame("Button", nil, parent, template)
    size = size or Look.SQUARE
    button:SetSize(size, size)
    local normal = button:CreateTexture(nil, "BACKGROUND")
    Look.Atlas(normal, "common-button-square-gray-up")
    normal:SetAllPoints()
    button:SetNormalTexture(normal)
    local pushed = button:CreateTexture(nil, "BACKGROUND")
    Look.Atlas(pushed, "common-button-square-gray-down")
    pushed:SetAllPoints()
    button:SetPushedTexture(pushed)
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button.Icon = Icon
    return button
end

-- The red button with the gold rim and its words (SharedButtonTemplate's 128-RedButton in three slices: the
-- character list's Create Character), for what matters: yes and no, sell, delete. Its disabled state is the
-- grey button. As wide as its words need unless a width is given.
function Look.Red(parent, words, width, height)
    local button = CreateFrame("Button", nil, parent, "SharedButtonSmallTemplate")
    button:SetHeight(height or 28)
    button:SetText(words or "")
    if width then
        button:SetWidth(width)
    elseif button.FitToText then
        button:FitToText()
    end
    return button
end

-------------------------------------------------------------------------------
--  The search box
-------------------------------------------------------------------------------
-- The game's search box (SearchBoxTemplate) in the character list's look: its frame the thin golden outline round
-- black (glues-characterSelect-searchbar, its ends kept), its glass the subtle golden brown one, as Forever's own
-- character list dresses it (CharSelectSearchMixin).
function Look.Search(box)
    for _, key in ipairs({ "Left", "Right", "Middle" }) do
        local piece = rawget(box, key)
        if piece and piece.SetAlpha then piece:SetAlpha(0) end
    end
    local back = box.lookBack or box:CreateTexture(nil, "BACKGROUND")
    if Look.Atlas(back, "glues-characterSelect-searchbar") then
        back:ClearAllPoints()
        back:SetPoint("TOPLEFT", -5, 2)
        back:SetPoint("BOTTOMRIGHT", 0, -2)
    else -- the game's own frame of the box, where it lacks the character list's
        for _, key in ipairs({ "Left", "Right", "Middle" }) do
            local piece = rawget(box, key)
            if piece and piece.SetAlpha then piece:SetAlpha(1) end
        end
    end
    box.lookBack = back
    local glass = rawget(box, "searchIcon")
    if glass and Look.Has("glues-characterSelect-icon-search") then
        glass:SetAtlas("glues-characterSelect-icon-search", true)
    end
    return box
end

-------------------------------------------------------------------------------
--  Parts of a window
-------------------------------------------------------------------------------
-- A section's head, the character window's (General, Primary Attributes): a bronze plate with curled ends, its
-- words white in the middle (GameFontHighlight). Placed by the caller, as wide as it needs.
function Look.Head(parent, words, height)
    local head = CreateFrame("Frame", nil, parent)
    head:SetHeight(height or Look.HEAD)
    head.back = head:CreateTexture(nil, "BACKGROUND")
    Look.Atlas(head.back, "UI-Character-Info-Title")
    head.back:SetAllPoints()
    head.text = head:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    head.text:SetPoint("CENTER", 0, 1)
    head.text:SetText(words or "")
    return head
end

-- A row's band (UI-Character-Info-Line-Bounce), under every other line of a list; placed by the caller.
function Look.Band(parent, layer)
    local band = parent:CreateTexture(nil, layer or "BACKGROUND", nil, 1)
    Look.Atlas(band, "UI-Character-Info-Line-Bounce")
    return band
end

-- The thin frame round a part of a window (common-insideframe), over all of frame.
function Look.Inset(frame, layer)
    local inset = frame:CreateTexture(nil, layer or "BORDER")
    Look.Atlas(inset, "common-insideframe")
    inset:SetAllPoints()
    return inset
end

-- The grey box (the shop's details box: generic-frame-chamfered-12d-2o): a thin grey rim with cut corners round
-- black that lets a little of what lies behind through; a section that is no window. Over all of frame.
function Look.Box(frame, layer)
    local box = frame:CreateTexture(nil, layer or "BACKGROUND")
    Look.Atlas(box, "generic-frame-chamfered-12d-2o")
    box:SetAllPoints()
    return box
end

-- The loading screen's bar as a frame for a headline (Interface\Glues\LoadingBar): its pointed ends kept, the
-- middle stretched; words or buttons go in it (the caller's). Its height the caller's, 32 at first.
local LOADING = "Interface\\Glues\\LoadingBar\\Loading-BarBorder-"
local END = 40 / 1024   -- the ends' share of the picture's width (their 40 of its 1024 at its 32 high)
function Look.Headline(parent, height)
    local frame = CreateFrame("Frame", nil, parent)
    height = height or 32
    frame:SetHeight(height)
    local function Three(file, layer)
        local parts = {}
        for index, coords in ipairs({ { 0, END }, { END, 1 - END }, { 1 - END, 1 } }) do
            local part = frame:CreateTexture(nil, layer)
            part:SetTexture(LOADING .. file)
            part:SetTexCoord(coords[1], coords[2], 0, 1)
            parts[index] = part
        end
        parts[1]:SetPoint("TOPLEFT")
        parts[1]:SetPoint("BOTTOMLEFT")
        parts[1]:SetWidth(height * 40 / 32)
        parts[3]:SetPoint("TOPRIGHT")
        parts[3]:SetPoint("BOTTOMRIGHT")
        parts[3]:SetWidth(height * 40 / 32)
        parts[2]:SetPoint("TOPLEFT", parts[1], "TOPRIGHT")
        parts[2]:SetPoint("BOTTOMRIGHT", parts[3], "BOTTOMLEFT")
        return parts
    end
    frame.back = Three("Background-v2", "BACKGROUND")
    frame.frame = Three("Frame-v2", "BORDER")
    return frame
end

-- An item's slot, the character window's gear slot (UI-Character-Info-GearSlot): its frame with bronze studs at the
-- corners round an item button; drawn on parent over all of it (parent as large as the button and a little more).
function Look.Slot(parent, layer)
    local slot = parent:CreateTexture(nil, layer or "BACKGROUND")
    Look.Atlas(slot, "ui-character-info-gearslot")
    slot:SetAllPoints()
    return slot
end

-------------------------------------------------------------------------------
--  The top bar's tabs: the character screen's (SHOP, MENU, RULESET)
-------------------------------------------------------------------------------
-- Which picture a tab draws: the first's and the last's reach past them with the bar's ends, the others are its
-- middle; a divider after each but the last; the chosen one lit from below.
local function SetEnd(tab, first, last)
    local height = tab:GetHeight()
    if not height or height <= 0 then height = Look.TAB end
    local k = height / Look.TAB
    tab.divider:SetSize(7 * k, 48 * k)
    tab.Text:SetFontObject(Look.Font("SaneUILookTab" .. math.floor(height + 0.5), math.max(13, math.floor(15 * k + 0.5)), "OUTLINE"))
    local over = Look.TAB_OVER * k
    local back, lit = tab.back, tab.lit
    back:ClearAllPoints()
    lit:ClearAllPoints()
    if first and last then
        Look.Atlas(back, "glues-characterselect-tophud-middle-bg")
        back:SetAllPoints()
        Look.Atlas(lit, "glues-characterselect-tophud-selected-middle")
    elseif first then
        Look.Atlas(back, "glues-characterselect-tophud-left-bg")
        back:SetPoint("TOPLEFT", -over, 0)
        back:SetPoint("BOTTOMRIGHT")
        Look.Atlas(lit, "glues-characterselect-tophud-selected-left")
    elseif last then
        Look.Atlas(back, "glues-characterselect-tophud-right-bg")
        back:SetPoint("TOPLEFT")
        back:SetPoint("BOTTOMRIGHT", over, 0)
        Look.Atlas(lit, "glues-characterselect-tophud-selected-right")
    else
        Look.Atlas(back, "glues-characterselect-tophud-middle-bg")
        back:SetAllPoints()
        Look.Atlas(lit, "glues-characterselect-tophud-selected-middle")
    end
    lit:SetPoint("BOTTOMLEFT", first and 4 * k or 0, 7 * k)
    lit:SetPoint("BOTTOMRIGHT", last and -3 * k or -7 * k, 7 * k)
    lit:SetHeight(44 * k)
    tab.divider:SetShown(not last)
    tab.first, tab.last = first, last
end

local function Words(tab)
    local color = not tab:IsEnabled() and Look.NAV_OFF or (tab.selected or tab:IsMouseOver()) and Look.NAV_LIT or Look.NAV
    tab.Text:SetTextColor(color[1], color[2], color[3])
    tab.lit:SetShown(tab.selected or tab:IsMouseOver())
    tab.lit:SetAlpha(tab.selected and 1 or 0.5)
end

local function SetSelected(tab, on)
    tab.selected = on and true or false
    Words(tab)
end

-- A tab of the full screen's top bar, as Forever's character screen draws its own (CharacterSelectNavBar,
-- Camelot): its words Friz Quadrata in Forever's top bar colours (tab.Text, as the game's tabs have it).
function Look.Tab(parent, height)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetHeight(height and height > 0 and height or Look.TAB)
    tab.back = tab:CreateTexture(nil, "BACKGROUND")
    tab.lit = tab:CreateTexture(nil, "BACKGROUND", nil, 2)
    tab.divider = tab:CreateTexture(nil, "ARTWORK")
    Look.Atlas(tab.divider, "glues-characterselect-tophud-bg-divider")
    tab.divider:SetPoint("CENTER", tab, "RIGHT")
    tab.Text = tab:CreateFontString(nil, "OVERLAY")
    tab.Text:SetShadowOffset(1, -1)
    tab.Text:SetPoint("CENTER", 0, 1)
    tab.SetSelected, tab.SetEnd = SetSelected, SetEnd
    tab:SetScript("OnEnter", Core.Guard("look", Words))
    tab:SetScript("OnLeave", Core.Guard("look", Words))
    SetEnd(tab, false, false)
    SetSelected(tab, false)
    return tab
end

-------------------------------------------------------------------------------
--  Words, outlines and a window of its own
-------------------------------------------------------------------------------
-- Friz Quadrata on a font string at a size in a 1080p layout's pixels, in a colour (white), with the game's shadow.
-- bold: the game's font has no bold face; heads are told apart by their colour.
function Look.SetFont(fs, size, bold, colour, alpha)
    fs:SetFont(Look.FONT, size * Look.PX, "")
    colour = colour or Look.INK
    fs:SetTextColor(colour[1], colour[2], colour[3], alpha or colour[4] or 1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
end

-- The thin golden line, unplaced (anchor its ends), one unit high.
function Look.Rule(parent, layer)
    return Look.Line(parent, 0.6, layer)
end

-- The thin golden outline round frame, a little dark inside (the character list's search bar): a box for a part, a
-- button or a dropdown. box:SetStrong(on) brightens it (the mouse on it); box.parts all of it, to show or hide.
local function Strong(box, on)
    for _, line in ipairs(box.lines) do line:SetAlpha(on and 1 or 0.6) end
end

function Look.Outline(frame, layer)
    if type(layer) ~= "string" then layer = nil end -- (the journal's box took a weight there: a number is no layer)
    local box = { lines = {}, parts = {}, SetStrong = Strong }
    box.fill = frame:CreateTexture(nil, layer == "ARTWORK" and "BORDER" or "BACKGROUND")
    box.fill:SetColorTexture(0, 0, 0, 0.35)
    box.fill:SetAllPoints()
    for index, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = frame:CreateTexture(nil, layer or "BORDER")
        line:SetColorTexture(Look.LINE[1], Look.LINE[2], Look.LINE[3], 1)
        if index <= 2 then
            line:SetPoint(side .. "LEFT")
            line:SetPoint(side .. "RIGHT")
            line:SetHeight(1)
        else
            line:SetPoint("TOP" .. side)
            line:SetPoint("BOTTOM" .. side)
            line:SetWidth(1)
        end
        box.lines[index] = line
        box.parts[index] = line
    end
    box.parts[5] = box.fill
    Strong(box, false)
    return box
end

-- A window of its own (not on a board: Navigation's satchel) in the bronze frame: inside its band a head to drag it
-- by with its title at the left in the game's gold, the game's X at its right, the thin golden line under it, and
-- its content frame under that, Look.INSIDE from the frame's sides and bottom.
Look.DRESS_HEAD = 40   -- from the window's top to the line under its head: the band and a row of 30
function Look.Inner(width, height)
    return width - 2 * Look.INSIDE, height - Look.DRESS_HEAD - 4 - Look.INSIDE
end

function Look.Outer(width, height)
    return width + 2 * Look.INSIDE, height + Look.DRESS_HEAD + 4 + Look.INSIDE
end

function Look.Dress(frame, title)
    local look = { frame = Look.Frame(frame) }
    local row = Look.DRESS_HEAD - Look.BAND
    look.close = CreateFrame("Button", nil, frame, "UIPanelCloseButtonNoScripts")
    look.close:SetPoint("TOPRIGHT", -Look.BAND + 2, -Look.BAND - (row - 24) / 2)
    look.head = CreateFrame("Frame", nil, frame)
    look.head:SetPoint("TOPLEFT", Look.BAND, -Look.BAND)
    look.head:SetPoint("RIGHT", look.close, "LEFT")
    look.head:SetHeight(row)
    look.title = look.head:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    look.title:SetPoint("LEFT", Look.INSIDE - Look.BAND + 2, 0)
    look.title:SetPoint("RIGHT", -4, 0)
    look.title:SetJustifyH("LEFT")
    look.title:SetWordWrap(false)
    look.title:SetText(title or "")
    local line = Look.Line(frame, 0.5)
    line:SetPoint("TOPLEFT", Look.INSIDE, -Look.DRESS_HEAD)
    line:SetPoint("TOPRIGHT", -Look.INSIDE, -Look.DRESS_HEAD)
    look.content = CreateFrame("Frame", nil, frame)
    look.content:SetPoint("TOPLEFT", Look.INSIDE, -(Look.DRESS_HEAD + 4))
    look.content:SetPoint("BOTTOMRIGHT", -Look.INSIDE, Look.INSIDE)
    look.close:SetFrameLevel(look.content:GetFrameLevel() + 20)
    return look
end

