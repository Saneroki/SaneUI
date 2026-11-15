local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Style
--  What the module's windows draw with, in the kit's look (Core.Look,
--  Doc/guides/interface-style.md, The kit): the game's own Friz Quadrata in
--  its own colours on Forever's dark bronze (white words, gold heads, grey
--  for what is said in passing), the thin golden line, the game's slots,
--  boxes and dropdown arrow. The sizes stay those the windows were laid out
--  in: a 1080p layout's pixels (Style.PX), every word Style.WORDS larger.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Style = {}
ns.Style = Style

Style.PX = 768 / 1080         -- a 1080p layout's pixel in UI units: the windows' sizes are written in those
Style.WORDS = 1.2             -- every word this much larger than first drawn (Saneroki, 2026-10-23: to be read)
Style.SLOT_ICON = 0.06        -- an icon inside its slot: this share of the slot's side, each side

-- The game's own colours (its font colours), on the dark plates.
Style.INK = { 1, 1, 1, 1 }                   -- words (HIGHLIGHT_FONT_COLOR)
Style.SOFT = { 1, 0.82, 0, 1 }               -- a head, a count: the game's gold (NORMAL_FONT_COLOR)
Style.FAINT = { 0.6, 0.6, 0.6, 1 }           -- what is only said in passing: notes, numbers in brackets (grey)
Style.SHADE = { 1, 0.82, 0, 0.12 }           -- the mouse on a row, a head that takes what is brought: a gold glow
Style.CHOSEN = { 1, 0.82, 0, 0.22 }          -- a chosen row
Style.ZEBRA = { 1, 1, 1, 0.035 }             -- every other line of a list
Style.RULE_ALPHA = 0.6                       -- the thin golden line
Style.GOLD = { 1, 0.82, 0 }                  -- a button's words (the game's buttons')
Style.FAINT_HEX = "ff999999"                 -- faint words in a colour code

-- A height or width laid out for words at their first size, grown with them.
function Style.Fit(n)
    return math.floor(n * Style.WORDS + 0.5)
end

-- A font object of Friz Quadrata, white (size in 1080p pixels, grown by Style.WORDS), made once by its name. Bold
-- has no face of its own in the game's font: such words are the gold of the game's heads where they are heads.
function Style.Font(name, size, bold, flags)
    return Look.Font(name, size * Style.WORDS * Style.PX, flags, "GameFontHighlight")
end

-- For words in a game colour (a quality's, a class's): on the dark plate they read as they are.
function Style.Outlined(name, size, bold)
    return Style.Font(name, size, bold)
end

-- A font object at a size in 1080p pixels, not grown (Core.Journal.FontObject's place).
function Style.FontObject(name, size, bold, flags)
    return Look.Font(name, size * Style.PX, flags, "GameFontHighlight")
end

-- Friz Quadrata on a font string at a size in 1080p pixels, in a colour (white), with the game's shadow.
function Style.SetFont(fs, size, bold, color, alpha)
    fs:SetFont(Look.FONT, size * Style.PX, "")
    color = color or Style.INK
    fs:SetTextColor(color[1], color[2], color[3], alpha or color[4] or 1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
end

-- The thin golden line along a frame's edge ("TOP" or "BOTTOM"), as wide as the frame.
function Style.Rule(frame, edge, layer)
    local line = Look.Line(frame, Style.RULE_ALPHA, layer)
    line:SetPoint(edge .. "LEFT")
    line:SetPoint(edge .. "RIGHT")
    return line
end

-- The thin golden line, unplaced (anchor its ends).
function Style.Line(frame, layer)
    return Look.Line(frame, Style.RULE_ALPHA, layer)
end

-- A colour of the game's on a font string: plain words white, a game colour as it is (fonts: the plain and the
-- coloured font object of the same size).
function Style.Color(fs, r, g, b, plain, outlined)
    if r and not (r == 1 and g == 1 and b == 1) then
        if outlined then fs:SetFontObject(outlined) end
        fs:SetTextColor(r, g, b, 1)
    else
        if plain then fs:SetFontObject(plain) end
        fs:SetTextColor(Style.INK[1], Style.INK[2], Style.INK[3], 1)
    end
end

-- A game colour as a colour code for text ("ff" .. hex), as it is: it reads on the dark plate.
function Style.InkHex(r, g, b)
    return ("ff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- A colour of the game's that reads on the plate (Core.Journal.Ink's place): itself.
function Style.Ink(r, g, b)
    return r, g, b
end

-- The thin golden outline round frame (the search bar's, the character list's), a little dark inside: a box for a
-- part, a button or a check. box:SetStrong(on) brightens it (the mouse on it). weight: unused, as the pencil's was.
local function Strong(box, on)
    for _, line in ipairs(box.lines) do line:SetAlpha(on and 1 or 0.6) end
end

function Style.Box(frame, weight, layer)
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
    box.parts[5] = box.fill -- every part, to show or hide the box whole
    Strong(box, false)
    return box
end

-- An item's slot behind a button: the game's empty bag slot (bags-item-slot-blank) at frame's edge (out: units
-- beyond it), the icon inset by Style.SLOT_ICON of its side.
function Style.Slot(frame, out, layer)
    local slot = frame:CreateTexture(nil, layer or "BACKGROUND")
    if not Look.Atlas(slot, "bags-item-slot-blank") then slot:SetTexture("Interface\\Buttons\\UI-EmptySlot") end
    out = out or 1
    slot:SetPoint("TOPLEFT", -out, out)
    slot:SetPoint("BOTTOMRIGHT", out, -out)
    return slot
end

-- The game's small pictures Inventory's rows and cells use (Core.Journal.Texture's place for its pieces): the
-- chevron of a group that opens, the red X of the bin, the minimal checkbox.
Style.PIECES = {
    arrow = "uitools-icon-chevron-down", -- pointing down, as the journal's was: the sidebar turns it
    trash = "128-redbutton-delete", -- the waste bin: the game's red delete button (the character list's)
    ["pencil-slot"] = "checkbox-minimal",
    check = "checkmark-minimal",
}
function Style.Texture(parent, piece, layer)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    Look.Atlas(texture, Style.PIECES[piece] or piece)
    return texture
end

-- A dropdown button in the kit's look: the thin golden outline round black (the search bar's), its word white,
-- the game's small gold chevron at its right; brighter under the mouse (the game's intrinsic DropdownButton, so
-- SetupMenu works as on the game's): menu:OverrideText(text) sets its word (menu.word).
function Style.Dropdown(parent, width, height)
    local menu = CreateFrame("DropdownButton", nil, parent)
    height = height or 24
    menu:SetSize(width, height)
    local box = Style.Box(menu)
    local label = menu:CreateFontString(nil, "OVERLAY")
    Style.SetFont(label, 13 * Style.WORDS)
    label:SetPoint("LEFT", 7, 0)
    label:SetPoint("RIGHT", -16, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    local arrow = menu:CreateTexture(nil, "OVERLAY")
    Look.Atlas(arrow, "minimal-scrollbar-small-arrow-bottom")
    arrow:SetSize(10, 8)
    arrow:SetPoint("RIGHT", -5, 0)
    menu.label, menu.box, menu.arrow = label, box, arrow
    function menu.OverrideText(self, text)
        self.word = text
        label:SetText(text or "")
    end
    menu:HookScript("OnEnter", ns.Guard(function() box:SetStrong(true) end))
    menu:HookScript("OnLeave", ns.Guard(function() box:SetStrong(false) end))
    return menu
end

-- A button of the red button's art (128-RedButton in three slices, Core.Look.Red's), its word the game's gold:
-- for what matters (deposit, sell). text: its font string.
function Style.Red(button, text, height)
    local parts = {}
    for index, name in ipairs({ "128-redbutton-left", "_128-redbutton-center", "128-redbutton-right" }) do
        local part = button:CreateTexture(nil, "BACKGROUND")
        Look.Atlas(part, name)
        parts[index] = part
    end
    -- the ends at the button's height: the left 114, the right 292 of the picture's 128 high
    parts[1]:SetPoint("TOPLEFT"); parts[1]:SetPoint("BOTTOMLEFT"); parts[1]:SetWidth(height * 114 / 128)
    parts[3]:SetPoint("TOPRIGHT"); parts[3]:SetPoint("BOTTOMRIGHT"); parts[3]:SetWidth(height * 292 / 128)
    parts[2]:SetPoint("TOPLEFT", parts[1], "TOPRIGHT"); parts[2]:SetPoint("BOTTOMRIGHT", parts[3], "BOTTOMLEFT")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    if text then
        text:SetFontObject("GameFontNormal")
        text:SetTextColor(Style.GOLD[1], Style.GOLD[2], Style.GOLD[3])
    end
    button.parts = parts
    return parts
end
