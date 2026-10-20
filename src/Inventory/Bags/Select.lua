local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Select
--  Choosing items in the bag window by clicking them, instead of using them:
--      put      a category's "+" clicked with nothing on the cursor: the
--               next item clicked goes into that category (Pinned: it is
--               pinned); then the mode ends
--      junk     the junk marker (the coin on the bar): each item clicked is
--               marked as junk, or unmarked; the mode stays until the coin is
--               clicked again
--  While a mode is on, the rest of the window (the bar, the strip, the
--  sidebar, the foot) is dimmed and a catcher over the items takes the mouse:
--  the item under it is lit (a thick border in Sane UI's colour, a pale
--  veil), a click acts on it and never reaches the game's button. A right
--  click, a click on the dimmed parts, Esc or a fight ends the mode.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Select = {}
ns.Select = Select

Select.DIM = 0.6       -- the rest of the window while choosing
Select.VEIL = 0.4      -- over the item under the mouse
Select.EDGE = 2        -- its border, screen pixels

local Categories = ns.Categories
local catcher, mark, dims = nil, nil, {}
local mode, target     -- "put" (target: a category's key) or "junk"; nil: none
local over             -- the button under the mouse
local lastX, lastY

-- The item button under the mouse now (one of the buttons drawn), nil: none.
local function Under()
    for _, button in ipairs(ns.Cells.Each()) do
        local record = ns.Cells.Record(button)
        if record and record.item and button:IsVisible() and button:IsMouseOver() then return button end
    end
end

local function Light(button)
    over = button
    if button then
        mark:ClearAllPoints()
        mark:SetAllPoints(button)
        mark:Show()
    else
        mark:Hide()
    end
end

local function Watch()
    local x, y = GetCursorPosition()
    if x == lastX and y == lastY then return end
    lastX, lastY = x, y
    Light(Under())
end

-- A click on an item while choosing: put it into the category, or mark or unmark it as junk.
local function Act(button)
    local record = button and ns.Cells.Record(button)
    if not (record and record.item) then return end
    if mode == "junk" then
        Categories.MarkJunk(record.item, not Categories.Junk(record.item, record.quality), record.quality)
        Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
        ns.Bags.Refresh()
        return
    end
    local key = target
    Select.Stop()
    if key == Categories.PINNED then
        Categories.Pin(record.item, true)
    elseif key == Categories.JUNK then
        Categories.MarkJunk(record.item, true)
    else
        Categories.Assign(record.item, key)
    end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    ns.Bags.Refresh()
end

local function Clicked(_, mouse)
    if mouse == "RightButton" then return Select.Stop() end
    Light(Under())
    Act(over)
end

local function Key(self, key)
    if key == "ESCAPE" then
        if not InCombatLockdown() then self:SetPropagateKeyboardInput(false) end
        Select.Stop()
    elseif not InCombatLockdown() then
        self:SetPropagateKeyboardInput(true)
    end
end

local function Wheel(_, delta)
    local scroll = ns.Bags.scroll
    if not scroll then return end
    local most = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or 0
    scroll:SetVerticalScroll(math.max(0, math.min(most, scroll:GetVerticalScroll() - delta * 40)))
    lastX = nil
end

local function Fought()
    Select.Stop()
end

-- A dim over one part of the window; a click on it ends the mode.
local function Dim(part)
    local dim = CreateFrame("Frame", nil, part)
    dim:SetAllPoints()
    dim:SetFrameLevel(part:GetFrameLevel() + 40)
    local shade = dim:CreateTexture(nil, "OVERLAY")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, Select.DIM)
    dim:EnableMouse(true)
    dim:SetScript("OnMouseUp", function() ns.Safe("bags", Select.Stop) end)
    dim:Hide()
    return dim
end

-- The catcher over the scroll area, the dims over the window's other parts.
function Select.Build(scroll, parts)
    catcher = CreateFrame("Frame", nil, scroll:GetParent())
    catcher:SetAllPoints(scroll)
    catcher:SetFrameLevel(scroll:GetFrameLevel() + 50)
    catcher:EnableMouse(true)
    catcher:EnableMouseWheel(true)
    catcher:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", Clicked, self, mouse) end)
    catcher:SetScript("OnMouseWheel", function(self, delta) ns.Safe("bags", Wheel, self, delta) end)
    catcher:SetScript("OnKeyDown", function(self, key) ns.Safe("bags", Key, self, key) end)
    catcher:SetScript("OnUpdate", function() ns.Safe("bags", Watch) end)
    catcher:Hide()
    mark = CreateFrame("Frame", nil, catcher)
    mark:SetFrameLevel(catcher:GetFrameLevel() + 1)
    local veil = mark:CreateTexture(nil, "ARTWORK")
    veil:SetAllPoints()
    veil:SetColorTexture(1, 1, 1, Select.VEIL)
    mark.border = ns.Cells.Border(mark)
    mark:Hide()
    for index, part in ipairs(parts) do dims[index] = Dim(part) end
end

-- A mode begun: "put" into a category (key), or "junk"; out of a fight only.
function Select.Start(kind, key)
    if InCombatLockdown() or not catcher then return false end
    mode, target, lastX = kind, key, nil
    local gold = Core.GOLD
    ns.Cells.Edge(mark.border, gold[1], gold[2], gold[3], 1, Core.Pixels(mark, Select.EDGE))
    catcher:Show()
    if catcher.EnableKeyboard then catcher:EnableKeyboard(true) end
    for _, dim in ipairs(dims) do
        if dim:GetParent():IsShown() then dim:Show() end
    end
    Core.On("PLAYER_REGEN_DISABLED", Fought)
    if ns.Bags.Marked then ns.Bags.Marked(kind == "junk") end
    return true
end

function Select.Stop()
    if not mode then return end
    mode, target, over = nil, nil, nil
    catcher:Hide()
    if catcher.EnableKeyboard and not InCombatLockdown() then catcher:EnableKeyboard(false) end
    mark:Hide()
    for _, dim in ipairs(dims) do dim:Hide() end
    Core.Off("PLAYER_REGEN_DISABLED", Fought)
    if ns.Bags.Marked then ns.Bags.Marked(false) end
end

-- The mode on now ("put", "junk", nil) and the category it puts into.
function Select.Mode()
    return mode, target
end

-- For the tests: a click while choosing, on this button.
function Select.Click(button)
    Act(button)
end
