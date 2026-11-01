local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Buff list
--  The game's own lists of your buffs and debuffs at the top of the screen, with
--  your marks of them (Lists.lua) on it:
--      Important      a yellow glow around it
--      Unimportant    faded, BuffList.FADED of its strength
--      Hidden         out of sight, and last in the list, so nothing leaves a
--                     hole; shown while the mouse is on the list
--
--  A right click on one, out of a fight, opens a menu: Create reminder and the
--  marks. The game's button cancels a buff on a right click, in its own secure
--  code that addons cannot stop or do themselves (CancelAuraByInstanceID is
--  closed to them). So a frame of ours lies over each button and takes the
--  clicks alone, the mouse's coming stays the button's (its tooltip), and it
--  lets the click through, to the game, whenever a menu cannot serve: with Shift
--  held (so Shift + right click cancels), in a fight (a right click cancels as
--  ever), in Edit Mode, and on a weapon enchant, which is no aura.
--
--  In a fight the game hides what a button shows. What was marked before stays
--  so by the aura's instance where the game tells that; where it does not, a
--  change of the list in a fight shows everything plain until the fight ends,
--  as a mark on the wrong aura would be worse than none.
--
--  Nothing is written into the game's buttons: the glow is on our frame, the fade
--  on the button's regions (the button's own alpha is the game's, for its warning
--  flash), the order in anchors the game gave them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local BuffList = {}
ns.BuffList = BuffList

BuffList.FADED = 0.25  -- an unimportant aura's strength
BuffList.LINGER = 0.3  -- seconds the hidden stay after the mouse left, as the buttons have gaps between them
BuffList.GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
BuffList.COLOUR = { 1, 0.82, 0 }
BuffList.GROW = 1.75   -- the glow's size against the icon's: the picture has wide empty edges
BuffList.REGIONS = { "Icon", "Duration", "Count", "Symbol", "DebuffBorder", "TempEnchantBorder" }

local shields = {} -- [the game's aura button] = our frame over it
local marks = {}   -- [button] = its mark now
local shown = {}   -- [button] = the strength its regions have
local natural = {} -- [button] = its anchor as the game gave it
local placed = {}  -- [button] = the anchor it stands by
local known = {}   -- [an aura's instance] = its mark, from before the fight
local hovered, soon = {}, {} -- [the game's list]: the mouse on it; what looks again after it left
local lists = {}   -- the game's lists we cover

-- The aura a button of the game's shows, out of a fight: { id, name, icon, harmful, unit }.
local function Which(button)
    local info, kind = button.buttonInfo, Plain(button.auraType)
    if type(info) ~= "table" or (kind ~= "Buff" and kind ~= "Debuff") or Core.Restricted() then return nil end
    local harmful = kind == "Debuff"
    local auras = C_UnitAuras
    local data = Core.Ask(auras.GetAuraDataByAuraInstanceID, "player", Plain(info.auraInstanceID))
        or Core.Ask(auras.GetAuraDataByIndex, "player", Plain(info.index), harmful and "HARMFUL" or "HELPFUL")
    local id, name = type(data) == "table" and Plain(data.spellId), type(data) == "table" and Plain(data.name)
    if not (id and name) then return nil end
    return { id = id, name = name, icon = Plain(data.icon), harmful = harmful, unit = "player" }
end

-- The mark of the aura a button shows now.
local function Mark(button)
    if not button.hasValidInfo or button.isExample then return nil end
    local instance = type(button.buttonInfo) == "table" and Plain(button.buttonInfo.auraInstanceID) or nil
    if Core.Restricted() then return instance and known[instance] or nil end
    local spell = Which(button)
    local mark = spell and ns.AuraLists.Mark(spell.name) or nil
    if instance then known[instance] = mark end
    return mark
end

local function Dress(button, mark, reveal)
    marks[button] = mark
    local alpha = (mark == "black" and BuffList.FADED) or (mark == "hidden" and not reveal and 0) or 1
    if shown[button] ~= alpha then
        shown[button] = alpha
        for _, key in ipairs(BuffList.REGIONS) do
            local region = button[key]
            if region then region:SetAlpha(alpha) end
        end
    end
    shields[button].glow:SetShown(mark == "white")
end

-- The list's places: first what can be seen, in the game's order, then what is hidden.
local function Arrange(frame)
    local slots, order, last = {}, {}, {}
    for _, button in ipairs(frame.auraFrames) do
        if shields[button] and button.hasValidInfo then
            if not natural[button] then return end
            slots[#slots + 1] = natural[button]
            local line = marks[button] == "hidden" and last or order
            line[#line + 1] = button
        end
    end
    for _, button in ipairs(last) do order[#order + 1] = button end
    for index, button in ipairs(order) do
        if placed[button] ~= slots[index] then
            placed[button] = slots[index]
            button:ClearAllPoints()
            button:SetPoint(unpack(slots[index]))
        end
    end
end

local function Marked()
    return not ns.off and ns.options.buffList ~= false and not Core.EditMode.active
end

-- One of the game's lists as your marks say.
local function Style(frame)
    local on = Marked()
    for _, button in ipairs(frame.auraFrames) do
        if shields[button] then Dress(button, on and Mark(button) or nil, hovered[frame]) end
    end
    Arrange(frame)
end

function BuffList.Style()
    for _, frame in ipairs(lists) do Style(frame) end
end

-- Which frames of ours take the click now.
function BuffList.Sync()
    local open = Marked() and not Core.Restricted() and not IsShiftKeyDown()
    for button, shield in pairs(shields) do
        local kind = Plain(button.auraType)
        shield:SetMouseClickEnabled(open and (kind == "Buff" or kind == "Debuff") or false)
    end
end

-- Everything anew: the setting, Edit Mode, standing down.
function BuffList.Apply()
    BuffList.Sync()
    BuffList.Style()
end

local function Clicked(shield, mouse)
    if mouse ~= "RightButton" then return end
    local spell = Which(shield:GetParent())
    if not spell then return end
    MenuUtil.CreateContextMenu(shield, ns.Guard(function(_, root)
        root:CreateTitle(spell.name)
        ns.Reminders.Entry(root, spell)
        ns.AuraLists.Entries(root, spell)
        if not spell.harmful then root:CreateTitle(ns.TEXT.reminderCancel) end
    end))
end
local OnClicked = ns.Guard(Clicked)

-- The game laid its list out: those are its places now.
local function Took(frame)
    local all = not frame.doNotAnchorDisabledFrames
    for _, button in ipairs(frame.auraFrames) do
        if shields[button] and (all or button.hasValidInfo) then
            natural[button] = { button:GetPoint(1) }
            placed[button] = natural[button]
        end
    end
    Arrange(frame)
end

local function Over(frame, on)
    hovered[frame] = on or nil
    if on then Style(frame) else soon[frame]() end
end

local function Cover(frame)
    if type(frame) ~= "table" or type(frame.auraFrames) ~= "table" then return end
    lists[#lists + 1] = frame
    soon[frame] = Core.Later(function() if not hovered[frame] then Style(frame) end end, BuffList.LINGER, "buff list")
    for _, button in ipairs(frame.auraFrames) do
        if not button.isAuraAnchor then
            local shield = CreateFrame("Frame", nil, button)
            shield:SetAllPoints(button)
            shield:SetScript("OnMouseUp", OnClicked)
            shield:SetMouseMotionEnabled(false)
            shield:SetMouseClickEnabled(false)
            local icon = button.Icon
            local glow = shield:CreateTexture(nil, "OVERLAY")
            glow:SetTexture(BuffList.GLOW)
            glow:SetBlendMode("ADD")
            glow:SetVertexColor(BuffList.COLOUR[1], BuffList.COLOUR[2], BuffList.COLOUR[3])
            glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
            glow:SetSize(icon:GetWidth() * BuffList.GROW, icon:GetHeight() * BuffList.GROW)
            glow:Hide()
            shield.glow = glow
            shields[button] = shield
            button:HookScript("OnEnter", ns.Guard(function() Over(frame, true) end))
            button:HookScript("OnLeave", ns.Guard(function() Over(frame, false) end))
        end
    end
    Took(frame)
    hooksecurefunc(frame, "UpdateAuraButtons", ns.Guard(function()
        BuffList.Sync()
        Style(frame)
    end))
    if type(frame.AuraContainer) == "table" then
        hooksecurefunc(frame.AuraContainer, "UpdateGridLayout", ns.Guard(function() Took(frame) end))
    end
end

function BuffList.Start()
    Cover(rawget(_G, "BuffFrame"))
    Cover(rawget(_G, "DebuffFrame"))
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "MODIFIER_STATE_CHANGED",
                             "ADDON_RESTRICTION_STATE_CHANGED" }) do
        Core.On(event, BuffList.Sync)
    end
    Core.On("PLAYER_REGEN_ENABLED", function()
        wipe(known)
        BuffList.Style()
    end)
    Core.EditMode.Watch(ns.Guard(BuffList.Apply))
    BuffList.Apply()
end
