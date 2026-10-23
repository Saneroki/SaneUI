local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Paper
--  What the module's windows on the journal's page draw with (Core.Journal,
--  Doc/guides/interface-style.md): graphite in its strengths, the pencil's
--  light shading for a row under the mouse or chosen, Kalam's font objects,
--  a pencil rule, a game colour (a quality's, a class's) that reads on the
--  paper. The bags, the bank and the alts take their colours and fonts here.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Paper = {}
ns.Paper = Paper

Paper.INK = { J.INK[1], J.INK[2], J.INK[3], 1 }   -- words and lines
Paper.SOFT = { J.INK[1], J.INK[2], J.INK[3], 0.75 } -- a head of a smaller part, a count
Paper.FAINT = { J.INK[1], J.INK[2], J.INK[3], 0.5 } -- what is only said in passing: notes, numbers in brackets
Paper.SHADE = J.SHADE                              -- the mouse on a row, a head that takes what is brought
Paper.CHOSEN = J.CHOSEN                            -- a chosen row
Paper.ZEBRA = { J.INK[1], J.INK[2], J.INK[3], 0.035 } -- every other line of a list
Paper.RULE_ALPHA = 0.8

-- A font object of Kalam in graphite (size in 1080p pixels), made once by its name.
function Paper.Font(name, size, bold, flags)
    return J.FontObject(name, size, bold, flags)
end

-- An outlined Kalam for words in a game colour (a quality's, a class's): the colour unchanged, a thin dark line
-- round the letters, so a light one reads on the paper.
function Paper.Outlined(name, size, bold)
    return J.FontObject(name, size, bold, "OUTLINE", { 1, 1, 1, 1 })
end

-- A pencil line along a frame's edge ("TOP" or "BOTTOM"), as wide as the frame.
function Paper.Rule(frame, edge, layer)
    local line = J.Rule(frame, layer)
    line:SetPoint(edge .. "LEFT")
    line:SetPoint(edge .. "RIGHT")
    line:SetAlpha(Paper.RULE_ALPHA)
    return line
end

-- A colour of the game's set on a font string: plain words in graphite, a game colour outlined (fonts: the plain
-- and the outlined font object of the same size).
function Paper.Color(fs, r, g, b, plain, outlined)
    if r and not (r == 1 and g == 1 and b == 1) then
        if outlined then fs:SetFontObject(outlined) end
        fs:SetTextColor(r, g, b, 1)
    else
        if plain then fs:SetFontObject(plain) end
        fs:SetTextColor(Paper.INK[1], Paper.INK[2], Paper.INK[3], 1)
    end
end

-- A dropdown button on the paper: a pencil box, its word and arrow in graphite (the style's rule: on the paper,
-- pencil, never leather), the box drawn stronger under the mouse (the game's intrinsic DropdownButton, so
-- SetupMenu works as on the game's): menu:OverrideText(text) sets its word (menu.word).
function Paper.Dropdown(parent, width, height)
    local menu = CreateFrame("DropdownButton", nil, parent)
    height = height or 24
    menu:SetSize(width, height)
    local box = J.Box(menu, 0.5)
    local label = menu:CreateFontString(nil, "OVERLAY")
    J.Font(label, 14)
    label:SetPoint("LEFT", 7, 0)
    label:SetPoint("RIGHT", -14, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    local arrow = menu:CreateFontString(nil, "OVERLAY")
    J.Font(arrow, 12, true)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")
    menu.label, menu.box = label, box
    function menu.OverrideText(self, text)
        self.word = text
        label:SetText(text or "")
    end
    menu:HookScript("OnEnter", ns.Guard(function() box:SetStrong(true) end))
    menu:HookScript("OnLeave", ns.Guard(function() box:SetStrong(false) end))
    return menu
end

-- A button whose back is the leather patch and whose word is pressed in (text: its font string).
function Paper.Leather(button, text, height)
    J.Patch(button, height)
    J.Press(text, 13)
end

-- A game colour (a class's) as ink for a colour code in text ("ff" .. hex): darkened, so a light one reads.
function Paper.InkHex(r, g, b)
    r, g, b = J.Ink(r, g, b)
    return ("ff%02x%02x%02x"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end
Paper.FAINT_HEX = "ff6e6154" -- faint graphite in a colour code
