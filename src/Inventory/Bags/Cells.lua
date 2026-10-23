local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Cells
--  The item buttons of the bag window: the game's own
--  (ContainerFrameItemButtonTemplate, Blizzard_UIPanels_Game's
--  ContainerFrame), so its click, drag, tooltip, the splitting of a stack,
--  selling at a vendor and putting into the bank are all the template's own
--  code, in a fight too.
--
--  A pool per window (Cells.New: the bags' is Cells.bags, and Cells' own
--  functions are its): each drawing takes as many buttons as it shows cells,
--  in order (Take), so one slot may show twice (pinned and in its category)
--  and a merged stack is one button. Each button stands in a holder of ours that
--  carries the bag's ID (SetID): the template asks its parent for the bag
--  (GetBagID), so nothing of ours is written into the button. The slot is
--  the button's own ID.
--
--  The look, Sane UI's own (Core.Journal): each cell a pencil slot on the
--  paper, the icon in it covering its inner line, cut a little round its
--  edge, without a border, its corners rounded by Core's icon mask
--  (Cells.ROUNDED; the highlight and the press too), the game's highlight,
--  a warm glow while pressed; over it, above the cooldown's swipe, the count
--  at the bottom right, the item level of gear at the top left in its
--  quality's colour, BoE at the bottom left on gear not yet bound, the
--  equipment set's name at the bottom, a quest mark on an item that starts a
--  quest, a coin on junk. An item the character cannot use is tinted red.
--  An empty slot is the pencil slot alone. What a search does not find is
--  faded.
--
--  Made out of a fight only: a button first needed in a fight waits for its
--  end (Cells.short tells the window).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Cells = {}
ns.Cells = Cells

Cells.TEMPLATE = "ContainerFrameItemButtonTemplate"
Cells.ZOOM = 0.08                       -- the icon's edge cut away, on each side
Cells.ROUNDED = Core.Journal.ART .. "icon-mask"  -- an icon's mask: its corners well rounded (Core's art)
Cells.CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
Cells.PRESSED = { 0.973, 0.839, 0.604 } -- the glow while pressed
Cells.EMPTY = { 0.12, 0.09, 0.07 }      -- an empty slot: the paper in its pencil slot, a breath of graphite
Cells.EMPTY_ALPHA = 0.04
Cells.EMPTY_SLOT = 0.5                  -- an empty slot's pencil lines (Saneroki, 2026-10-23: less distracting)
Cells.FADED = 0.2                       -- what a search does not find
Cells.UNUSABLE = { 1, 0.1, 0.1 }
Cells.MARK, Cells.COIN = 22, 16         -- the quest mark, the junk coin

local look = {}     -- [button] = what is ours on it (kept apart from the game's button)
local recordOf = {} -- [button] = the record it draws now
local fonts
local Pool = {}     -- a pool's functions
Pool.__index = Pool

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- A part of the template's (a texture, a font string, a frame), if this client's template has it.
local function Part(button, key)
    local part = button[key]
    return type(part) == "table" and part or nil
end
Cells.Part = Part

-- A method of the template's, if this client's template has it.
local function Call(button, name, ...)
    local fn = button[name]
    if type(fn) == "function" then return fn(button, ...) end
end

local function Fonts()
    if fonts then return fonts end
    fonts = {
        count = Core.Font("SaneUIBagsCount", "NumberFontNormal", 13, "OUTLINE"),
        level = Core.Font("SaneUIBagsLevel", "NumberFontNormal", 13, "OUTLINE"),
        bind = Core.Font("SaneUIBagsBind", "NumberFontNormal", 12, "OUTLINE"),
        set = Core.Font("SaneUIBagsSet", "NumberFontNormal", 10, "OUTLINE"),
    }
    return fonts
end
Cells.Fonts = Fonts

-- The mouse on a button, or off it; a click after the game's: the pool's window may answer (its Hover, Clicked).
local function Hovered(pool, button, on)
    local owner = pool.owner or ns.Bags
    if owner and owner.Hover then owner.Hover(button, on) end
end

local function Clicked(pool, button, mouse)
    local owner = pool.owner or ns.Bags
    if owner and owner.Clicked then owner.Clicked(button, mouse) end
end

-- A pool of buttons standing in parent (a scroll area's child), its window owner (its Hover and Clicked; nil:
-- the bags).
function Cells.New(parent, owner)
    return setmetatable({ parent = parent, owner = owner, buttons = {}, taken = 0, at = {},
        short = false }, Pool)
end

-- The bags' pool, whose functions are Cells' own.
function Cells.Build(child)
    Cells.bags = Cells.New(child)
    Cells.bags.default = true
end

-------------------------------------------------------------------------------
--  The look
-------------------------------------------------------------------------------
-- A thin border inside a frame's edge: four lines, thick pixels of the screen's own.
local function Border(frame, layer)
    local lines = {}
    for index = 1, 4 do
        lines[index] = frame:CreateTexture(nil, layer or "OVERLAY", nil, 2)
        lines[index]:SetColorTexture(1, 1, 1, 1)
    end
    lines[1]:SetPoint("TOPLEFT"); lines[1]:SetPoint("TOPRIGHT")
    lines[2]:SetPoint("BOTTOMLEFT"); lines[2]:SetPoint("BOTTOMRIGHT")
    lines[3]:SetPoint("TOPLEFT"); lines[3]:SetPoint("BOTTOMLEFT")
    lines[4]:SetPoint("TOPRIGHT"); lines[4]:SetPoint("BOTTOMRIGHT")
    return lines
end
Cells.Border = Border

-- A mask of a texture's own (the rounded icon's, Cells.ROUNDED, or another file) laid over it; the textures given
-- after it share it. Returns the mask, nil where the client has none.
function Cells.Mask(owner, file, texture, ...)
    if not (owner.CreateMaskTexture and texture and texture.AddMaskTexture) then return nil end
    local mask = owner:CreateMaskTexture()
    mask:SetTexture(file or Cells.ROUNDED, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    for index = 1, select("#", ...) do
        local other = select(index, ...)
        if other and other.AddMaskTexture then other:AddMaskTexture(mask) end
    end
    return mask
end

function Cells.Edge(lines, r, g, b, a, thick)
    for index = 1, 4 do lines[index]:SetVertexColor(r, g, b, a or 1) end
    if thick then
        lines[1]:SetHeight(thick); lines[2]:SetHeight(thick)
        lines[3]:SetWidth(thick); lines[4]:SetWidth(thick)
    end
end

-- The template's own parts set to the flat look, ours added beside them (look[button]).
local function Skin(button, holder)
    for _, key in ipairs({ "NewItemTexture", "BattlepayItemTexture", "flash" }) do
        local part = Part(button, key)
        if part and part.Hide then part:Hide(); part:SetAlpha(0) end
    end
    local glow = Part(button, "newitemglowAnim")
    if glow and glow.Stop then glow:Stop() end
    -- the pencil slot at the button's edge; the icon and what lies on it inside, over the slot's inner line
    local inset = ns.Layout.SIZE * Core.Journal.SLOT_ICON
    local face = CreateFrame("Frame", nil, button)
    face:SetPoint("TOPLEFT", inset, -inset)
    face:SetPoint("BOTTOMRIGHT", -inset, inset)
    local icon = Part(button, "icon")
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(face)
        icon:SetTexCoord(Cells.ZOOM, 1 - Cells.ZOOM, Cells.ZOOM, 1 - Cells.ZOOM)
        local mask = Part(button, "IconMask")
        if mask and icon.RemoveMaskTexture then
            icon:RemoveMaskTexture(mask)
            mask:Hide()
        end
    end
    local light = button:GetHighlightTexture()
    if light then light:ClearAllPoints(); light:SetAllPoints(face) end
    local pressed = button:GetPushedTexture()
    if pressed then
        pressed:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        pressed:SetTexCoord(0, 1, 0, 1)
        pressed:ClearAllPoints()
        pressed:SetAllPoints(face)
        pressed:SetVertexColor(Cells.PRESSED[1], Cells.PRESSED[2], Cells.PRESSED[3], 1)
    end
    local normal = button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local border = Part(button, "IconBorder")
    if border then border:SetAlpha(0) end

    local mine = { holder = holder, face = face }
    mine.slot = Core.Journal.Slot(button, 1, "BACKGROUND")
    mine.empty = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    mine.empty:SetAllPoints(face)
    mine.empty:SetColorTexture(Cells.EMPTY[1], Cells.EMPTY[2], Cells.EMPTY[3], 1)
    -- the corners rounded: the icon, the empty slot's breath of graphite, the highlight, the press
    mine.mask = Cells.Mask(button, Cells.ROUNDED, icon, mine.empty, light, pressed)
    -- Above the cooldown's swipe: the words and marks.
    local over = CreateFrame("Frame", nil, button)
    over:SetAllPoints()
    local cooldown = Part(button, "Cooldown")
    over:SetFrameLevel((cooldown and cooldown:GetFrameLevel() or button:GetFrameLevel()) + 2)
    mine.over = over
    local font = Fonts()
    local count = Part(button, "Count")
    if count then
        count:SetParent(over)
        if font.count then count:SetFontObject(font.count) end
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -1, 1)
    end
    local function Words(point, x, y, object)
        local words = over:CreateFontString(nil, "OVERLAY", nil, 7)
        if object then words:SetFontObject(object) end
        words:SetPoint(point, face, point, x, y)
        return words
    end
    mine.level = Words("TOPLEFT", 1, -1, font.level)
    mine.bind = Words("BOTTOMLEFT", 1, 2, font.bind)
    mine.set = Words("BOTTOM", 0, 2, font.set)
    mine.set:SetWordWrap(false)
    mine.quest = over:CreateTexture(nil, "OVERLAY", nil, 6)
    mine.quest:SetAtlas("QuestNormal")
    mine.quest:SetSize(Cells.MARK, Cells.MARK)
    mine.quest:SetPoint("BOTTOMLEFT", -2, 1)
    mine.coin = over:CreateTexture(nil, "OVERLAY", nil, 6)
    mine.coin:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    mine.coin:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    mine.coin:SetSize(Cells.COIN, Cells.COIN)
    mine.coin:SetPoint("BOTTOMLEFT", -3, -3)
    Cells.Mask(over, Cells.CIRCLE, mine.coin)
    look[button] = mine
    return mine
end

-- The next button of this drawing; made now if need be, nil in a fight for one not made yet (pool.short).
function Pool:Take()
    self.taken = self.taken + 1
    local button = self.buttons[self.taken]
    if button then return button end
    if InCombatLockdown() then
        self.taken = self.taken - 1
        self.short = true
        if self.default then Cells.short = true end
        return nil
    end
    local holder = CreateFrame("Frame", nil, self.parent)
    holder:SetSize(ns.Layout.SIZE, ns.Layout.SIZE)
    button = CreateFrame("ItemButton", nil, holder, Cells.TEMPLATE)
    button:SetAllPoints(holder)
    Skin(button, holder)
    local pool = self
    button:HookScript("OnEnter", function(this) ns.Safe("bags", Hovered, pool, this, true) end)
    button:HookScript("OnLeave", function(this) ns.Safe("bags", Hovered, pool, this, false) end)
    button:HookScript("OnClick", function(this, mouse) ns.Safe("bags", Clicked, pool, this, mouse) end)
    button:HookScript("OnMouseUp", ns.Guard(function(this, mouse)
        if mouse == "MiddleButton" then Clicked(pool, this, mouse) end
    end))
    self.buttons[self.taken] = button
    return button
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
local function Faded(button, mine, faded)
    local alpha = faded and Cells.FADED or 1
    button:SetAlpha(alpha)
    mine.over:SetAlpha(alpha)
end

local function Plain(mine)
    mine.level:SetText("")
    mine.bind:SetText("")
    mine.set:SetText("")
    mine.quest:Hide()
    mine.coin:Hide()
end

-- An empty slot: the dark square, the mouse taken (an item may be put there).
local function Empty(button, mine)
    Game("SetItemButtonTexture", button, nil)
    Game("SetItemButtonCount", button, 0)
    Game("SetItemButtonDesaturated", button, false)
    Call(button, "SetHasItem", nil)
    local icon = Part(button, "icon")
    if icon then icon:Hide() end
    mine.empty:Show()
    mine.empty:SetAlpha(Cells.EMPTY_ALPHA)
    mine.slot:SetAlpha(Cells.EMPTY_SLOT)
    Plain(mine)
    local cooldown = Part(button, "Cooldown")
    if cooldown and cooldown.Clear then cooldown:Clear() end
    Call(button, "UpdateQuestItem", false, nil, false)
    Faded(button, mine, false)
end

-- A button as the record says; how: { faded (a search did not find it), count (a merged stack's), coin (the
-- junk coin shown), grey (junk greyed), bind (BoE shown), set (the set's name shown), level (the item level
-- shown) }.
function Pool:Draw(button, record, how)
    local mine = look[button]
    local holder = mine.holder
    holder:SetID(record.bag)
    button:SetID(record.slot)
    recordOf[button] = record
    local key = record.bag .. ":" .. record.slot
    if not self.at[key] then self.at[key] = button end
    Game("ClearItemButtonOverlay", button)
    if not record.item then return Empty(button, mine) end
    mine.empty:Hide()
    mine.slot:SetAlpha(1)
    local icon = Part(button, "icon")
    if icon then icon:Show() end
    Call(button, "SetHasItem", record.icon)
    Game("SetItemButtonTexture", button, record.icon)
    Game("SetItemButtonQuality", button, record.quality, record.link, false, record.bound)
    local border = Part(button, "IconBorder")
    if border then border:Hide() end
    Game("SetItemButtonCount", button, how and how.count or record.count or 0)
    Game("SetItemButtonDesaturated", button, record.locked or (how and how.grey and record.junk) or false)
    Call(button, "UpdateExtended")
    -- The template's own quest overlay stays off: ours is the border and the mark.
    Call(button, "UpdateQuestItem", false, nil, false)
    Call(button, "UpdateItemContextMatching")
    Call(button, "UpdateCooldown", record.icon)
    Call(button, "SetReadable", record.readable)
    if icon then
        local red = record.unusable and Cells.UNUSABLE
        icon:SetVertexColor(red and red[1] or 1, red and red[2] or 1, red and red[3] or 1)
    end
    local color = rawget(_G, "ITEM_QUALITY_COLORS") and record.quality and ITEM_QUALITY_COLORS[record.quality]
    if record.level and not (how and how.level == false) then
        mine.level:SetText(record.level)
        if color then mine.level:SetTextColor(color.r, color.g, color.b) else mine.level:SetTextColor(1, 1, 1) end
    else
        mine.level:SetText("")
    end
    local starter = record.questID and not record.questActive
    mine.quest:SetShown(starter or false)
    if how and how.bind and record.boe and not record.bound and not starter then
        mine.bind:SetText(ns.TEXT.bagsBoE)
        if color then mine.bind:SetTextColor(color.r, color.g, color.b) else mine.bind:SetTextColor(1, 1, 1) end
    else
        mine.bind:SetText("")
    end
    mine.set:SetText(how and how.set and record.set or "")
    mine.coin:SetShown((how and how.coin and record.junk) or false)
    local tip = rawget(_G, "GameTooltip")
    if tip and tip.IsOwned and tip:IsOwned(button) then Call(button, "UpdateTooltip") end
    Faded(button, mine, how and how.faded)
end

-- A button at its place in the parent (its top left, x right and y down), size wide and high; reach: the width
-- of a list's line its click reaches over (nil: only the button).
function Pool:Place(button, x, y, size, reach)
    local holder = look[button].holder
    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x, -y)
    holder:SetSize(size, size)
    look[button].set:SetWidth(size - 4)
    button:SetHitRectInsets(0, reach and -(reach - size) or 0, 0, 0)
    holder:Show()
    button:Show()
end

-- One slot's lock changed (an item picked up or put down): grey or not, as the game shows it.
function Pool:Lock(record)
    for index = 1, self.taken do
        local button = self.buttons[index]
        if recordOf[button] == record then Game("SetItemButtonDesaturated", button, record.locked) end
    end
end

-- The cooldowns of the buttons shown, anew.
function Pool:Cooldowns()
    for index = 1, self.taken do
        local record = recordOf[self.buttons[index]]
        Call(self.buttons[index], "UpdateCooldown", record and record.item and record.icon or nil)
    end
end

-- The buttons of one bag lit (the game's mark for a bag's items, as its combined bag does while the mouse is on
-- a bag of the bag bar); nil: none.
function Pool:Light(bag)
    for index = 1, self.taken do
        local button = self.buttons[index]
        local mark = Part(button, "BagIndicator")
        local record = recordOf[button]
        if mark and mark.SetShown then mark:SetShown(bag ~= nil and record ~= nil and record.bag == bag) end
    end
end

-------------------------------------------------------------------------------
--  A drawing
-------------------------------------------------------------------------------
-- A new drawing: what is not taken in it goes out of sight at Done.
function Pool:Begin()
    self.taken = 0
    for key in pairs(self.at) do self.at[key] = nil end
    self.short = false
    if self.default then Cells.short = false end
end

function Pool:Done()
    for index = self.taken + 1, #self.buttons do
        local button = self.buttons[index]
        recordOf[button] = nil
        look[button].holder:Hide()
        local mark = Part(button, "BagIndicator")
        if mark and mark.Hide then mark:Hide() end
    end
end

-- The buttons of this drawing, in their order.
function Pool:Each()
    local list = {}
    for index = 1, self.taken do list[index] = self.buttons[index] end
    return list
end

-- The record a button of any pool draws now.
function Cells.Record(button)
    return recordOf[button]
end

-- The first button that draws a slot now, and whether one does.
function Pool:Button(bag, slot)
    return self.at[bag .. ":" .. slot]
end

function Pool:Shown(bag, slot)
    local button = self.at[bag .. ":" .. slot]
    return button ~= nil and button:IsShown()
end

-- A button's icon round (the list's setting), or its corners rounded again.
function Cells.Round(button, on)
    local mine = look[button]
    if not (mine and mine.mask) or (mine.round or false) == on then return end
    mine.mask:SetTexture(on and Cells.CIRCLE or Cells.ROUNDED, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mine.round = on
end

-- Every button out of sight (the module stood down, or the panel hidden).
function Pool:HideAll()
    self:Begin()
    self:Done()
end

-- Cells' own functions are the bags' pool's.
for _, name in ipairs({ "Take", "Draw", "Place", "Lock", "Cooldowns", "Light", "Begin", "Done", "Each", "Button",
                        "Shown", "HideAll" }) do
    Cells[name] = function(...)
        local pool = Cells.bags
        if pool then return pool[name](pool, ...) end
    end
end
