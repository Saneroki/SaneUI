local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Drag
--  Carrying a spell you do not have from the spellbook to a real action bar.
--
--  The game's own cursor refuses a spell you do not know, so the addon carries
--  it: an icon that follows the mouse. Let go over an action bar button and
--  that button is reserved for the spell. Nothing on the real bars is touched
--  while you drag; the button under the mouse only gets a gold frame around it.
-------------------------------------------------------------------------------
local D = {}
ns.Drag = D
local S, E = ns.Sources, ns.Engine
local Core = SaneUI.Core

local holder  -- the icon that follows the mouse
local hint    -- the gold frame around the button you are over
local held    -- the entry being carried
local from    -- the slot it was taken from, when it is a reservation carried to another button
local buttons = {} -- every action button, looked for again when a drag starts (Buttons.lua)

-- A button under the mouse, shown or hidden (a bar hides its empty buttons when "always show
-- buttons" is off, and shows them only while the game's own cursor carries something; ours is
-- not the game's), on a bar you can see. Shown buttons first: one may stand over a hidden one.
local function BarTarget()
    for pass = 1, 2 do
        for _, button in ipairs(buttons) do
            local shown = ns.Plain(button:IsVisible()) and true or false
            if shown == (pass == 1) and ns.Buttons.OnVisibleBar(button) and ns.Buttons.Under(button) then
                local slot = ns.ActionOf(button)
                if slot then return slot, button end
            end
        end
    end
    return nil
end

-- Any frame under the mouse that carries an action slot, or one of its parents: the game's
-- buttons, and a bar addon's own (they may keep the slot only in their attribute "action",
-- see ns.ActionOf).
local function OtherTarget()
    local foci = (GetMouseFoci and GetMouseFoci()) or (GetMouseFocus and { GetMouseFocus() }) or {}
    for _, frame in ipairs(foci) do
        for _ = 1, 3 do
            if type(frame) ~= "table" then break end
            local action = ns.ActionOf(frame)
            if action then return action, frame end
            frame = frame.GetParent and frame:GetParent()
        end
    end
    return nil
end

-- The action slot under the mouse, and its button. The frames under the mouse are asked first
-- (one call: the game's buttons carry their slot too); the scan of every button is for when
-- they say nothing.
local function Target()
    -- A frame may be one addons are not allowed to read, or (in a fight) one whose place
    -- the game keeps to itself: then there is no target, and no error either.
    local ok, slot, button = pcall(OtherTarget)
    if ok and slot then return slot, button end
    ok, slot, button = pcall(BarTarget)
    if ok then return slot, button end
    return nil
end

local function Build()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(34, 34)
    holder:SetFrameStrata("TOOLTIP")
    holder.icon = holder:CreateTexture(nil, "ARTWORK")
    holder.icon:SetAllPoints()
    holder.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    holder.icon:SetDesaturated(true)
    holder.icon:SetAlpha(0.85)
    holder:Hide()

    hint = CreateFrame("Frame", nil, UIParent)
    hint:SetFrameStrata("TOOLTIP")
    hint.glow = hint:CreateTexture(nil, "OVERLAY")
    hint.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    hint.glow:SetBlendMode("ADD")
    hint.glow:SetVertexColor(1, 0.82, 0.3)
    hint.glow:SetPoint("TOPLEFT", -14, 14)
    hint.glow:SetPoint("BOTTOMRIGHT", 14, -14)
    hint:Hide()

    -- The gold frame moves only when the button under the mouse is another one.
    local lastButton
    holder:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

        -- the gold frame by the button's place, which a hidden button has too (Buttons.Rect)
        local _, button = Target()
        if button == lastButton then return end
        lastButton = button
        local left, bottom, width, height
        if button then left, bottom, width, height = ns.Buttons.Rect(button) end
        if left then
            hint:ClearAllPoints()
            hint:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / scale, bottom / scale)
            hint:SetSize(width / scale, height / scale)
            hint:Show()
        else
            hint:Hide()
        end
    end)
    holder:SetScript("OnHide", function()
        lastButton = nil
        hint:Hide()
    end)
end

function D.Start(entry)
    if GetCursorInfo() then return end -- the real cursor is busy
    if not holder then Build() end
    buttons = ns.Buttons.All(true)
    held = entry
    holder.icon:SetTexture(S.Icon(entry))
    holder:Show()
end

-- Pick up the reservation of a slot to carry it to another button (Ghosts.lua).
function D.StartMove(slot)
    local entry = ns.char.reserved[slot]
    if not entry or held then return end
    D.Start(entry)
    if held then from = slot end
end

function D.Cancel()
    held, from = nil, nil
    if holder then holder:Hide() end
end

-- Let go: reserve the button under the mouse. Anywhere else nothing happens.
-- A real action on that button goes onto your cursor, as when you swap two real buttons.
function D.Stop()
    local entry, origin = held, from
    if not entry then return end
    D.Cancel()
    local slot = Target()
    if origin and not slot then
        -- A reservation carried off the bars and let go on no button is taken off, as a real
        -- action dragged off its button and let go is.
        E.Clear(origin)
        Core.Sound("IG_ABILITY_ICON_DROP")
        return
    end
    if not slot then return end
    if origin then
        if slot == origin then return end
        local ok, why = E.Move(origin, slot)
        if not ok and why then ns.Print(E.Reason(why)) end
        if ok then Core.Sound("IG_ABILITY_ICON_DROP") end
        return
    end
    local ok, why = E.Reserve(slot, entry, true)
    if not ok then
        ns.Print(E.Reason(why))
    elseif not S.Available(entry) and UIErrorsFrame and UIErrorsFrame.AddMessage then
        -- A spell you have becomes a real button at once and needs no words.
        UIErrorsFrame:AddMessage(ns.TEXT.reservedHere:format(S.Name(entry), ns.SlotLabel(slot)), 1, 0.82, 0.3)
    end
    if ok then Core.Sound("IG_ABILITY_ICON_DROP") end
end

function D.Held()
    return held
end
