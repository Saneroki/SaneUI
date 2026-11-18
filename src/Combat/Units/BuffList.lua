local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Units - Buff list
--  The game's own lists of your buffs and debuffs at the top of the screen, with
--  your marks of them (Lists.lua) on it:
--      Important      the game's golden animated outline around it
--      Unimportant    faded, BuffList.FADED of its strength
--      Hidden         out of sight, and last in the list, so nothing leaves a
--                     hole; shown while the mouse is on the list
--
--  A left click on one opens a menu: Create reminder and the marks. It does
--  nothing of the game's: its left click only tells a callback nobody listens
--  to, so the button's click is merely hooked. A right click cancels a buff, as
--  in the game.
--
--  In a fight the game hides what a button shows. What was on before stays known
--  by the aura's instance where the game tells that, with its mark and its menu;
--  what it hides and came in the fight, the menu says so. Where it does not tell
--  the instance, a change of the list in a fight shows everything plain until
--  the fight ends, as a mark on the wrong aura would be worse than none.
--
--  Nothing is written into the game's buttons: the outline is a frame of ours in
--  it, the fade on the button's regions (the button's own alpha is the game's, for
--  its warning flash), the order in anchors the game gave them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local BuffList = {}
ns.BuffList = BuffList

BuffList.FADED = 0.25  -- an unimportant aura's strength
BuffList.LINGER = 0.3  -- seconds the hidden stay after the mouse left, as the buttons have gaps between them
BuffList.ALERT = "ActionButtonSpellAlertTemplate" -- the game's outline of a spell that wants attention
BuffList.GROW = 1.4    -- its size against the icon's, as the game gives it
BuffList.ICON = 30     -- the game's aura icon, where it hides the size of one: a fight it showed in does that, past its end
BuffList.REGIONS = { "Icon", "Duration", "Count", "Symbol", "DebuffBorder", "TempEnchantBorder" }

local covered = {} -- [the game's aura button] = true
local alerts = {}  -- [button] = its outline, made when first needed
local marks = {}   -- [button] = its mark now
local shown = {}   -- [button] = the strength its regions have
local natural = {} -- [button] = its anchor as the game gave it
local placed = {}  -- [button] = the anchor it stands by
local known = {}   -- [an aura's instance] = the spell it is, from before the fight
local hovered, soon = {}, {} -- [the game's list]: the mouse on it; what looks again after it left
local lists = {}   -- the game's lists we cover

-- Whether a button holds an aura (a weapon enchant is none).
local function HoldsAura(button)
    local kind = Plain(button.auraType)
    return type(button.buttonInfo) == "table" and (kind == "Buff" or kind == "Debuff")
end

-- The aura a button of the game's shows: { id, name, icon, harmful, unit }, read where the game tells it (never-secret
-- spells in a fight too), else as known from before the fight; nil where it cannot be told.
local function Which(button)
    if not HoldsAura(button) then return nil end
    local info, harmful = button.buttonInfo, Plain(button.auraType) == "Debuff"
    local auras = C_UnitAuras
    local instance = Plain(info.auraInstanceID)
    local data = Core.Ask(auras.GetAuraDataByAuraInstanceID, "player", instance)
        or Core.Ask(auras.GetAuraDataByIndex, "player", Plain(info.index), harmful and "HARMFUL" or "HELPFUL")
    local id, name = type(data) == "table" and Plain(data.spellId), type(data) == "table" and Plain(data.name)
    if not (id and name) then return instance and known[instance] or nil end
    local spell = { id = id, name = name, icon = Plain(data.icon), harmful = harmful, unit = "player" }
    if instance then known[instance] = spell end
    return spell
end

-- The mark of the aura a button shows now.
local function Mark(button)
    if not button.hasValidInfo or button.isExample then return nil end
    local spell = Which(button)
    return spell and ns.AuraLists.Mark(spell.name) or nil
end

-- The game's own golden animated outline, as it has around a spell that wants attention: its template, sized as its
-- spell alerts are, around that region. Its manager is not asked: that would write our frames into the game's table.
-- The animation goes while the outline shows, and on when it shows again. nil where this client has no such template.
function BuffList.Alert(parent, around)
    local ok, alert = pcall(CreateFrame, "Frame", nil, parent, BuffList.ALERT)
    if not (ok and alert and alert.ProcLoop and alert.ProcStartFlipbook) then return nil end
    alert:SetSize((Plain(around:GetWidth()) or BuffList.ICON) * BuffList.GROW,
        (Plain(around:GetHeight()) or BuffList.ICON) * BuffList.GROW)
    alert:SetPoint("CENTER", around, "CENTER", 0, 0)
    alert.ProcStartFlipbook:SetAlpha(0) -- its burst is for a proc's start: this one just stands
    alert:HookScript("OnShow", ns.Guard(function(self)
        if not Plain(self.ProcLoop:IsPlaying()) then self.ProcLoop:Play() end
    end))
    return alert
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
    if mark == "white" and not alerts[button] then alerts[button] = BuffList.Alert(button, button.Icon) end
    if alerts[button] then alerts[button]:SetShown(mark == "white") end
end

-- The list's places: first what can be seen, in the game's order, then what is hidden.
local function Arrange(frame)
    local slots, order, last = {}, {}, {}
    for _, button in ipairs(frame.auraFrames) do
        if covered[button] and button.hasValidInfo then
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
        if covered[button] then Dress(button, on and Mark(button) or nil, hovered[frame]) end
    end
    Arrange(frame)
end

-- Everything anew: a mark, the setting, Edit Mode, standing down.
function BuffList.Style()
    for _, frame in ipairs(lists) do Style(frame) end
end

-- A click on a button, after the game's: a left click opens the aura's menu.
local function Clicked(button, mouse)
    if mouse == "LeftButton" and Marked() and HoldsAura(button) then ns.AuraLists.Menu(button, Which(button)) end
end
local OnClicked = ns.Guard(Clicked)

-- The game laid its list out: those are its places now.
local function Took(frame)
    local all = not frame.doNotAnchorDisabledFrames
    for _, button in ipairs(frame.auraFrames) do
        if covered[button] and (all or button.hasValidInfo) then
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
            covered[button] = true
            button:HookScript("OnClick", OnClicked)
            button:HookScript("OnEnter", ns.Guard(function() Over(frame, true) end))
            button:HookScript("OnLeave", ns.Guard(function() Over(frame, false) end))
        end
    end
    Took(frame)
    hooksecurefunc(frame, "UpdateAuraButtons", ns.Guard(function() Style(frame) end))
    if type(frame.AuraContainer) == "table" then
        hooksecurefunc(frame.AuraContainer, "UpdateGridLayout", ns.Guard(function() Took(frame) end))
    end
end

function BuffList.Start()
    Cover(rawget(_G, "BuffFrame"))
    Cover(rawget(_G, "DebuffFrame"))
    Core.On("PLAYER_REGEN_ENABLED", function()
        wipe(known)
        BuffList.Style()
    end)
    Core.EditMode.Watch(ns.Guard(BuffList.Style))
    BuffList.Style()
end
