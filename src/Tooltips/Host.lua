local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Host
--  The game's own tooltip, with a panel in front of it. The game keeps doing
--  everything with it (it places it, fills it, hides it, fades it) and other
--  addons keep reading it; this file only keeps it out of sight while its
--  panel is drawn, places the panel, and hands the tooltip back untouched.
--
--  Out of sight means alpha 0, nothing more: the tooltip keeps its size and
--  place (the game lines up its comparisons by the tooltips' sizes; a size of
--  ours would come back as comparisons that jump), and only a tooltip the
--  mouse can be on also has its mouse area made the panel's (Reach). Since the
--  game sets the tooltip's own alpha when it shows or fades it, but never the
--  alpha of its pieces (its border and ground, its lines, its small pictures,
--  the bar under a unit's, its coins, the tab over a comparison), each of those
--  pieces is set to 0 too (Blank).
--
--  Every alpha taken is noted on the panel and set back by Free, the
--  tooltip's own first: should a piece fail to come back (the game has
--  dropped it), the tooltip itself is still seen.
--
--  The panels place themselves. A panel takes the corner its tooltip hangs
--  by; a tooltip the game set beside another tooltip with a panel has its
--  panel set beside that panel (Beside); the comparisons of the game's two
--  main tooltips stand at places of the module's own (Compare). Every panel
--  keeps itself on the screen.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Host = {}
ns.Host = Host

-- The corner a tooltip hangs by: the panel takes the same one, so it stands where the tooltip
-- would, whichever of the two is larger.
local CORNER = {
    ANCHOR_RIGHT = "BOTTOMLEFT", ANCHOR_TOPLEFT = "BOTTOMLEFT", ANCHOR_CURSOR_RIGHT = "BOTTOMLEFT",
    ANCHOR_LEFT = "BOTTOMRIGHT", ANCHOR_TOPRIGHT = "BOTTOMRIGHT", ANCHOR_CURSOR_LEFT = "BOTTOMRIGHT",
    ANCHOR_BOTTOMRIGHT = "TOPLEFT", ANCHOR_BOTTOMLEFT = "TOPRIGHT",
    ANCHOR_TOP = "BOTTOM", ANCHOR_CURSOR = "BOTTOM", ANCHOR_BOTTOM = "TOP",
}
local JOIN = { TOP = { LEFT = "TOPLEFT", RIGHT = "TOPRIGHT" }, BOTTOM = { LEFT = "BOTTOMLEFT", RIGHT = "BOTTOMRIGHT" } }

-- A tooltip without such an anchor is held by points, and may be by several. One held by its
-- middle alone (the chat link's: Tooltips.lua puts it in the middle of the screen) has its panel
-- held by the middle too.
local function Corner(tooltip)
    local known = CORNER[Plain(tooltip:GetAnchorType()) or ""]
    if known then return known end
    local vertical, horizontal, middle = nil, nil, false
    for index = 1, Plain(tooltip:GetNumPoints()) or 0 do
        local point = Plain((tooltip:GetPoint(index)))
        if type(point) == "string" then
            if point:find("BOTTOM", 1, true) then vertical = "BOTTOM" elseif point:find("TOP", 1, true) then vertical = "TOP" end
            if point:find("RIGHT", 1, true) then horizontal = "RIGHT" elseif point:find("LEFT", 1, true) then horizontal = "LEFT" end
            if point == "CENTER" then middle = true end
        end
    end
    if middle and not (vertical or horizontal) then return "CENTER" end
    return JOIN[vertical or "TOP"][horizontal or "LEFT"]
end

-- Which side of the frame it hangs on a point puts a tooltip: one side of it against the other side
-- of that frame. "left", "right", or nil for a point that sets no side (TOP on TOP).
local function SideOf(point, relativePoint)
    if type(point) ~= "string" or type(relativePoint) ~= "string" then return nil end
    if point:find("RIGHT", 1, true) and relativePoint:find("LEFT", 1, true) then return "left" end
    if point:find("LEFT", 1, true) and relativePoint:find("RIGHT", 1, true) then return "right" end
    return nil
end

-- How a panel stands beside another: its own point, on the other's point, tops in a line.
local NEXT_TO = { left = { "TOPRIGHT", "TOPLEFT" }, right = { "TOPLEFT", "TOPRIGHT" } }

-- A tooltip the game set beside another tooltip that has a panel (as it sets any comparison: tops
-- in a line, one's side against the other's, TooltipComparisonManager): its panel goes beside that
-- panel, on the same side, tops in a line. False when it stands beside no such panel, or its panel
-- cannot stand there: the game sets two comparisons by each other, now one way round, now the other,
-- and a panel cannot hang on one that hangs on it.
local function Beside(tooltip, panel)
    local panels, other, side = ns.Panel.All(), nil, nil
    for index = 1, Plain(tooltip:GetNumPoints()) or 0 do
        local point, relative, relativePoint = tooltip:GetPoint(index)
        local candidate = relative ~= nil and Plain(relative) ~= nil and panels[relative] or nil
        local which = candidate and candidate ~= panel and candidate:IsShown() and SideOf(Plain(point), Plain(relativePoint))
        if which then other, side = candidate, which end
    end
    if not other then return false end
    local pair = NEXT_TO[side]
    panel:ClearAllPoints()
    panel.corner = nil -- placed by a point (or by nothing): the corner is set anew next time
    if pcall(panel.SetPoint, panel, pair[1], other, pair[2], 0, 0) then return true end
    panel:ClearAllPoints()
    return false
end

-- What you wear, beside what you look at (comparisons). The game sets ShoppingTooltip1 and 2 (and
-- the chat link's ItemRefShoppingTooltip1 and 2) beside the tooltip they belong to, and does it
-- again several times a second: it hides each, fills it, places it, now the first on the second,
-- then the other way round, and the lines of what would change come a moment after the rest. A
-- panel that followed all of that would take every step for a new place, and flicker.
-- So these panels stand at places of the module's own, points on UIParent, worked out from what
-- holds still:
--   - the main panel's place (the panel of the tooltip they belong to), taken when it shows a new
--     thing (another owner or item), and afterwards only once it has rested in a new place for
--     REST seconds (Host.Track, every frame of the main panel): a wobble is never followed, a move is;
--   - a side, chosen once for that thing: right where all of them fit, else left, else the side with
--     more room (the game's own side where nothing can be measured);
--   - for each comparison a slot as wide as the widest its panel has been for that thing, so the
--     second's place does not change while the first is hidden, refilled or narrower for a moment.
-- The slots are a gap apart (Gap), the first that gap from the main panel, their tops in a line
-- with it. A panel is set again only when its place changes (Pin).
local REST = 0.12 -- seconds the main panel must stand in a new place before its comparisons follow it
local MOVED = 1   -- a change of place smaller than this is none
local MAINS = { "GameTooltip", "ItemRefTooltip" } -- the tooltips that have comparisons (shoppingTooltips)
local layouts = {} -- [main tooltip] = { owner, item, side, left, right, top, widths = {}, wantLeft, wantRight, wantTop, since }

-- Between two panels that stand side by side: so much that their soft edges just meet.
local function Gap()
    return 2 * (ns.Panel.EDGE or 0)
end

-- The tooltip a comparison belongs to, and which of its comparisons it is (1, 2); nil for any other.
local function MainOf(tooltip)
    for _, name in ipairs(MAINS) do
        local main = rawget(_G, name)
        local shops = type(main) == "table" and rawget(main, "shoppingTooltips")
        if type(shops) == "table" then
            for index, shop in ipairs(shops) do
                if shop == tooltip then return main, index end
            end
        end
    end
    return nil
end

-- A panel's left, right and top on the screen, or nil while it has no place.
local function Rect(panel)
    local left, right, top = Plain(panel:GetLeft()), Plain(panel:GetRight()), Plain(panel:GetTop())
    if type(left) == "number" and type(right) == "number" and type(top) == "number" then return left, right, top end
    return nil
end

-- The side the game put a comparison on, by its points.
local function GameSide(tooltip)
    for index = 1, Plain(tooltip:GetNumPoints()) or 0 do
        local point, _, relative = tooltip:GetPoint(index)
        local side = SideOf(Plain(point), Plain(relative))
        if side then return side end
    end
    return "right"
end

-- How wide a comparison is: its panel's width from its last draw, else its tooltip's.
local function WidthOf(shop, shopPanel)
    local width = shopPanel and Plain(shopPanel:GetWidth())
    if not (type(width) == "number" and width > 0) then width = Plain(shop:GetWidth()) end
    return type(width) == "number" and width or 0
end

local function Side(main, left, right, tooltip)
    local screen = Plain(UIParent:GetWidth())
    if not (type(screen) == "number" and screen > 0) then return GameSide(tooltip) end
    local need, panels, gap = 0, ns.Panel.All(), Gap()
    for _, shop in ipairs(main.shoppingTooltips) do
        if shop:IsShown() then need = need + gap + WidthOf(shop, panels[shop]) end
    end
    if right + need <= screen then return "right" end
    if left - need >= 0 then return "left" end
    return screen - right >= left and "right" or "left"
end

-- Puts a panel at an absolute place, by a point of its own, unless it stands there already.
local function Pin(panel, point, x, y)
    if panel.pinPoint == point and math.abs(panel.pinX - x) < 0.5 and math.abs(panel.pinY - y) < 0.5
        and (Plain(panel:GetNumPoints()) or 0) > 0 then
        return
    end
    panel:ClearAllPoints()
    panel.corner = nil
    panel:SetPoint(point, UIParent, "BOTTOMLEFT", x, y)
    panel.pinPoint, panel.pinX, panel.pinY = point, x, y
end

-- Places every comparison panel of main that is shown (or about to be) by its layout.
local function Lay(main, layout)
    local panels, gap = ns.Panel.All(), Gap()
    local right = layout.side ~= "left"
    local x = right and layout.right + gap or layout.left - gap
    for index, shop in ipairs(main.shoppingTooltips) do
        local shopPanel = panels[shop]
        local width = math.max(layout.widths[index] or 0, WidthOf(shop, shopPanel))
        layout.widths[index] = width
        if shopPanel and (shopPanel:IsShown() or shopPanel.pending) then
            Pin(shopPanel, right and "TOPLEFT" or "TOPRIGHT", x, layout.top)
        end
        x = right and x + width + gap or x - width - gap
    end
end

-- What the main tooltip shows, as the layout knows it: its owner and its item.
local function Thing(main, mainPanel)
    return Plain(main:GetOwner()), mainPanel.data and Plain(mainPanel.data.id) or nil
end

-- The layout of main's comparisons: kept while main shows the same thing, made anew for a new one.
-- Nil while the main panel has no place.
local function LayoutOf(main, mainPanel, tooltip)
    local layout = layouts[main]
    if not layout then
        layout = { widths = {} }
        layouts[main] = layout
    end
    local owner, item = Thing(main, mainPanel)
    if layout.side and layout.owner == owner and layout.item == item then return layout end
    local left, right, top = Rect(mainPanel)
    if not left then return nil end
    wipe(layout.widths)
    layout.owner, layout.item, layout.since = owner, item, nil
    layout.left, layout.right, layout.top = left, right, top
    layout.side = Side(main, left, right, tooltip)
    return layout
end

-- Places a comparison's panel (see above). False for a tooltip that is none, or while the panel of
-- the tooltip it belongs to is not there to stand beside.
local function Compare(tooltip, panel)
    local main = MainOf(tooltip)
    if not main then return false end
    local mainPanel = ns.Panel.All()[main]
    if not (mainPanel and (mainPanel:IsShown() or mainPanel.pending)) then return false end
    local layout = LayoutOf(main, mainPanel, tooltip)
    if not layout then return false end
    Lay(main, layout)
    return (Plain(panel:GetNumPoints()) or 0) > 0
end

-- Every frame of a main panel with comparisons (Tooltips.lua): has it moved, and rested in its new
-- place for REST seconds? Then its comparisons follow it, once.
local function Near(a, b) return math.abs(a - b) <= MOVED end
function Host.Track(tooltip, panel)
    if type(rawget(tooltip, "shoppingTooltips")) ~= "table" then return end
    local layout = layouts[tooltip]
    if not (layout and layout.side) then return end
    local owner, item = Thing(tooltip, panel)
    if owner ~= layout.owner or item ~= layout.item then return end -- a new thing: its comparisons make it anew
    local left, right, top = Rect(panel)
    if not left then return end
    if Near(left, layout.left) and Near(right, layout.right) and Near(top, layout.top) then
        layout.since = nil
        return
    end
    local now = GetTime()
    if not (layout.since and Near(left, layout.wantLeft) and Near(right, layout.wantRight) and Near(top, layout.wantTop)) then
        layout.since, layout.wantLeft, layout.wantRight, layout.wantTop = now, left, right, top
        return
    end
    if now - layout.since < REST then return end
    layout.left, layout.right, layout.top, layout.since = left, right, top, nil
    Lay(tooltip, layout)
end

local function Align(tooltip, panel)
    if Compare(tooltip, panel) or Beside(tooltip, panel) then return end
    local corner = Corner(tooltip)
    if panel.corner == corner then return end
    panel.corner = corner
    panel:ClearAllPoints()
    panel:SetPoint(corner, tooltip, corner)
end

-------------------------------------------------------------------------------
--  Out of sight, and back
-------------------------------------------------------------------------------
-- The tooltip's pieces that can be seen, by their keys.
local PIECES = { "NineSlice", "TopOverlay", "BottomOverlay", "CompareHeader" }

-- One piece out of sight; how visible it was is noted the first time.
local function Mute(panel, piece)
    if type(piece) ~= "table" or not piece.SetAlpha then return end
    local taken = panel.parts
    if taken[piece] == nil then taken[piece] = Plain(piece:GetAlpha()) or 1 end
    piece:SetAlpha(0)
end

-- The game's frames of a tooltip that are found by their names: GameTooltipTexture1 to 30 and
-- GameTooltipStatusBar (made with it), its coins' frames GameTooltipMoneyFrame1, ... (made when it
-- first shows coins). Looked up once, and the coins' frames as the game makes more of them; no
-- name is put together on every fill.
local function Named(tooltip, panel)
    local named = panel.named
    if not named then
        named = { money = 0, name = tooltip:GetName() }
        panel.named = named
        local name = named.name
        if name then
            for index = 1, 30 do
                local picture = rawget(_G, name .. "Texture" .. index)
                if not picture then break end
                named[#named + 1] = picture
            end
            named[#named + 1] = rawget(_G, name .. "StatusBar")
        end
    end
    local money = tonumber(tooltip.numMoneyFrames) or 0
    if named.name and money > named.money then
        for index = named.money + 1, money do
            named[#named + 1] = rawget(_G, named.name .. "MoneyFrame" .. index)
        end
        named.money = money
    end
    return named
end

local function MutePieces(tooltip, panel)
    if not panel.parts then panel.parts = {} end
    for _, key in ipairs(PIECES) do Mute(panel, tooltip[key]) end
    for index = 1, Plain(tooltip:NumLines()) or 0 do
        Mute(panel, tooltip:GetLeftLine(index))
        Mute(panel, tooltip:GetRightLine(index))
    end
    local named = Named(tooltip, panel)
    for index = 1, #named do Mute(panel, named[index]) end
end

-- The tooltip out of sight, and how visible it was noted: the tooltip alone (Dim, for one nobody
-- sees), or each of its pieces as well, which stay so while the game fades it (Blank).
function Host.Dim(tooltip, panel)
    if panel.alpha == nil then panel.alpha = Plain(tooltip:GetAlpha()) or 1 end
    tooltip:SetAlpha(0)
end

function Host.Blank(tooltip, panel)
    Host.Dim(tooltip, panel)
    MutePieces(tooltip, panel)
end

-- A tooltip the mouse can be on (the chat link's: it is dragged, and a click closes it, see
-- Tooltips.lua) takes the mouse where its panel is seen, not where it stands itself: its area for
-- the mouse is made the panel's (SetHitRectInsets; its size and place stay as they are), and its
-- X, out of sight under the panel, takes no click of its own. Both are noted and set back by Free.
local function Reach(tooltip, panel)
    if not Plain(tooltip:IsMouseEnabled()) then return end
    local left, right, top, bottom = Plain(tooltip:GetLeft()), Plain(tooltip:GetRight()), Plain(tooltip:GetTop()), Plain(tooltip:GetBottom())
    local scale = (Plain(panel:GetEffectiveScale()) or 1) / (Plain(tooltip:GetEffectiveScale()) or 1)
    local panelLeft, panelRight, panelTop, panelBottom = Plain(panel:GetLeft()), Plain(panel:GetRight()), Plain(panel:GetTop()), Plain(panel:GetBottom())
    if not (left and right and top and bottom and panelLeft and panelRight and panelTop and panelBottom) then return end
    if not panel.reach then
        local a, b, c, d = tooltip:GetHitRectInsets()
        panel.reach = { Plain(a) or 0, Plain(b) or 0, Plain(c) or 0, Plain(d) or 0 }
    end
    tooltip:SetHitRectInsets(panelLeft * scale - left, right - panelRight * scale, top - panelTop * scale, panelBottom * scale - bottom)
    local close = tooltip.CloseButton
    if close and close.EnableMouse and panel.closeMouse == nil then
        panel.closeMouse = Plain(close:IsMouseEnabled()) ~= false
        close:EnableMouse(false)
    end
end

-- The panel is drawn: its tooltip out of sight, the panel in its place. Again whenever the game
-- shows the tooltip.
function Host.Seat(tooltip, panel)
    Host.Blank(tooltip, panel)
    Align(tooltip, panel)
    Reach(tooltip, panel)
end

-- The game hid the tooltip and fills it again at once: it refreshes a comparison so, several times
-- a second (TooltipComparisonManager: SetOwner hides it, ClearAllPoints, the lines, SetShown, and
-- only then its points). Until the panel is drawn anew at the end of the frame, the old picture
-- holds the place it had when the tooltip was hidden, on nothing else: the tooltip has no place
-- yet (its corner would put the panel where the game's tooltip stands, not beside the other panel:
-- two places in turn), and a panel it hung on may soon hang on it.
function Host.Hold(tooltip, panel)
    Host.Blank(tooltip, panel)
    local x, y = panel.stoodX, panel.stoodY
    if not (x and y) then return Align(tooltip, panel) end
    panel:ClearAllPoints()
    panel.corner, panel.pinPoint = nil, nil
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

-- The game fades a tooltip out, and shows it at full strength when it fills it again.
function Host.Keep(tooltip)
    if Plain(tooltip:GetAlpha()) ~= 0 then tooltip:SetAlpha(0) end
end

-- The panel goes, and the tooltip is the game's again, as it was. The panel lets go of what it
-- hung on, so it hangs on no other panel that may soon hang on it; where it stood is noted (Hold).
function Host.Free(tooltip, panel)
    local shown = panel:IsShown()
    panel.stoodX = shown and Plain(panel:GetLeft()) or nil
    panel.stoodY = shown and Plain(panel:GetTop()) or nil
    panel:Hide()
    panel:ClearAllPoints()
    panel.corner, panel.pinPoint = nil, nil
    local reach = panel.reach
    if reach then
        tooltip:SetHitRectInsets(reach[1], reach[2], reach[3], reach[4])
        panel.reach = nil
    end
    if panel.closeMouse ~= nil then
        tooltip.CloseButton:EnableMouse(panel.closeMouse)
        panel.closeMouse = nil
    end
    if panel.alpha ~= nil then
        tooltip:SetAlpha(panel.alpha)
        panel.alpha = nil
    end
    local taken = panel.parts
    if not taken then return end
    for piece, alpha in pairs(taken) do pcall(piece.SetAlpha, piece, alpha) end -- each by itself
    wipe(taken)
end
