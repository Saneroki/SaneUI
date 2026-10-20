local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Page
--  What a window of the game's character sheet stands on, on the module's full
--  screen (Board.lua): its panel's body cut as the game's sheet cuts its
--  window. A left part takes the room there is (a list, the PvP rank); a window
--  that tells of what is chosen has the game's right pane at its right, as the
--  game draws it (UI-Character-Info-Stat-BG, its stone at the top, the game's
--  divider at its left edge), as wide as the game's and as high as the panel,
--  for the side pane (Side.lua). The panel is moved and sized on Core's board;
--  what is in it follows its size.
--
--      ns.Page.Part(key, title, least, page)
--          page = { side = true,                          -- with the right pane
--                   Build = function(left, right, panel) end,
--                   Show = function(on) end,               -- shown or hidden
--                   Size = function(width, height) end }   -- its body's size, once a change stands
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Page = {}
ns.Page = Page

Page.SIDE = 233 -- the game's right pane's width

-- The game's right pane: its background stretched to the pane's height, its stone at the top, its divider.
local function Right(body)
    local right = CreateFrame("Frame", nil, body)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(Page.SIDE)
    local back = right:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas("UI-Character-Info-Stat-BG")
    back:SetAllPoints()
    right.stone = right:CreateTexture(nil, "ARTWORK")
    right.stone:SetAtlas("UI-Character-Info-Stat-StoneBG3", true)
    right.stone:SetPoint("TOPLEFT")
    local divider = right:CreateTexture(nil, "OVERLAY")
    divider:SetAtlas("common-framedivider", true)
    divider:SetPoint("TOPLEFT", -6, -1)
    divider:SetPoint("BOTTOMLEFT", -6, 0)
    return right
end

-- A panel's body cut into its parts: the left part, and the right pane if the page has one.
function Page.New(panel, side)
    local body = panel.body
    local left = CreateFrame("Frame", nil, body)
    if not side then
        left:SetAllPoints()
        return left
    end
    local right = Right(body)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    return left, right
end

-- A panel's body's size from the panel's (Core's board tells the panel's): less its head and its edges.
function Page.Body(width, height)
    local edge = Core.Board.EDGE
    return width - 2 * edge, height - Core.Board.HEAD - 2 * edge
end

-- A window of the sheet's registered with the module's board.
function Page.Part(key, title, least, page)
    local part = {}
    function part.Build(panel)
        local left, right = Page.New(panel, page.side)
        page.Build(left, right, panel)
    end
    part.Show = page.Show
    if page.Size then
        function part.Size(width, height) page.Size(Page.Body(width, height)) end
    end
    ns.Board.Part(key, title, least, part)
end

-- The board's least for a body that small: its head and its edges round it.
function Page.Least(width, height)
    local edge = Core.Board.EDGE
    return { width + 2 * edge, height + Core.Board.HEAD + 2 * edge }
end
