local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Ghosts
--  Shows each reservation as a grey icon on the real, still empty button, with
--  the small clock in its corner that the spell also carries in the spellbook.
--  The ghost takes no clicks while its button is shown, so the button under it works as
--  always; a drag on that button, where the game would let you drag a real action (bars
--  unlocked, or the pick-up key held), carries the reservation to another button. Where the
--  bar hides the empty button, the ghost itself takes the mouse: its tooltip and that drag.
--  Its tooltip is the spell's own, shown after the button's (empty) one.
-------------------------------------------------------------------------------
local G = {}
ns.Ghosts = G
local S = ns.Sources

local ghosts = {} -- [real button] = our icon frame on top of it
local missing = true -- a button of the bars has no ghost yet (a bar addon may make its buttons late)

-- The button showed its own tooltip (none: it is empty). Ours follows, if a ghost is on show.
local function ShowTooltip(button)
    local ghost = ghosts[button]
    local entry = ghost and ghost:IsShown() and ghost.entry
    if not entry then return end
    if GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    local shown = entry.id and ((entry.kind == "spell" and pcall(GameTooltip.SetSpellByID, GameTooltip, entry.id))
        or (entry.kind == "item" and pcall(GameTooltip.SetItemByID, GameTooltip, entry.id)))
    if not shown then GameTooltip:SetText(S.Name(entry)) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.TEXT.reservedTip, 1, 0.82, 0.3, true)
    GameTooltip:Show()
end

-- Every action button runs this when the mouse comes: nothing to do unless its ghost is on show.
local function OnEnter(button)
    local ghost = ghosts[button]
    if ghost and ghost:IsShown() then ns.Safe("ghost tooltip", ShowTooltip, button) end
end

-- The game's rule for picking an action off a bar: the bars are not locked, or the key for it
-- (Shift, by default) is held.
local function MayPickUp()
    return not GetCVarBool("lockActionBars") or (IsModifiedClick and IsModifiedClick("PICKUPACTION")) and true or false
end

-- A drag on a reserved, empty button (or on the ghost of a hidden one) picks the reservation up.
local function OnDragStart(button)
    local ghost = ghosts[button]
    if not (ghost and ghost:IsShown() and ghost.entry and MayPickUp()) then return end
    local slot = ns.SlotOf(button, ghost.fallback)
    if ns.HasAction(slot) or GetCursorInfo() then return end
    GameTooltip:Hide()
    ns.Drag.StartMove(slot)
end

local function OnDragStop()
    if ns.Drag.Held() then ns.Drag.Stop() end
end

-- The ghost takes the mouse only while its button is hidden: over a shown button it must let
-- every click and every drop through. Asked again when the bar shows or hides the button.
local function Mouse(button)
    local ghost = ghosts[button]
    if ghost then ghost:EnableMouse(ghost:IsShown() and not ns.Plain(button:IsShown()) and true or false) end
end

-- A ghost hangs on the button's bar, in the button's place, not on the button itself: a bar
-- hides an empty button when "always show buttons" is off, and the reservation should show
-- all the same. A button a bar addon put away has a hidden bar, and so has its ghost.
local function Attach(button, fallback)
    if not button or ghosts[button] then return end
    local ghost = CreateFrame("Frame", nil, button:GetParent() or button)
    ghost:SetAllPoints(button)
    ghost:SetFrameLevel(button:GetFrameLevel() + 5)
    ghost.ignoreInLayout = true
    ghost.fallback = fallback
    ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
    ghost.icon:SetAllPoints(ghost)
    ghost.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ghost.icon:SetDesaturated(true)
    ghost.icon:SetAlpha(0.5)
    ghost.mark = ghost:CreateTexture(nil, "OVERLAY")
    ghost.mark:SetAtlas(ns.RESERVED_MARK, false)
    ghost.mark:SetSize(16, 16)
    ghost.mark:SetPoint("BOTTOMRIGHT", -1, 1)
    ghost:Hide()
    ghost:RegisterForDrag("LeftButton")
    ghost:SetScript("OnEnter", function() ns.Safe("ghost tooltip", ShowTooltip, button) end)
    ghost:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ghost:SetScript("OnDragStart", function() ns.Safe("ghost drag", OnDragStart, button) end)
    ghost:SetScript("OnDragStop", function() ns.Safe("ghost drag", OnDragStop) end)
    ghosts[button] = ghost
    -- Hooks run after the button's own handlers and leave them as they were.
    button:HookScript("OnEnter", OnEnter)
    button:HookScript("OnDragStart", function(self) ns.Safe("ghost drag", OnDragStart, self) end)
    button:HookScript("OnDragStop", function() ns.Safe("ghost drag", OnDragStop) end)
    button:HookScript("OnShow", Mouse)
    button:HookScript("OnHide", Mouse)
end

-- Give every real button its ghost. Asked again at each redraw until every button of the
-- bars has one, so a button that another addon creates late still gets one; never in combat,
-- where frames on the game's own bars must not be touched.
local function Build()
    if InCombatLockdown() then return end
    if missing then
        missing = false
        for _, bar in ipairs(ns.BARS) do
            for i = 1, ns.NUM_BUTTONS do
                local button = _G[bar.prefix .. i]
                if button then Attach(button, bar.offset + i) else missing = true end
            end
        end
    end
    -- A bar addon's own buttons: every action button there is (Buttons.lua).
    for _, button in ipairs(ns.Buttons.All()) do
        Attach(button, ns.ActionOf(button))
    end
end

function G.Refresh()
    if not ns.char then return end
    Build()
    local show = ns.options.ghosts
    for button, ghost in pairs(ghosts) do
        local slot = ns.SlotOf(button, ghost.fallback)
        local entry = show and ns.char.reserved[slot]
        -- the bar addon may have moved the button to another bar since
        local bar = button:GetParent()
        if bar and ghost:GetParent() ~= bar and not InCombatLockdown() then
            ghost:SetParent(bar)
            ghost:SetFrameLevel(button:GetFrameLevel() + 5)
        end
        ghost.action = slot -- a drag over the ghost of a hidden button finds that slot (ns.ActionOf)
        if entry and not ns.HasAction(slot) then
            ghost.entry = entry
            ghost.icon:SetTexture(S.Icon(entry))
            ghost:Show()
        else
            ghost.entry = nil
            ghost:Hide()
        end
        Mouse(button)
    end
end

ns.Listen("REFRESH", G.Refresh)

-- A bar addon builds its bars after the login: look for its buttons again once it has.
ns.On("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(5, function()
        if InCombatLockdown() then return end
        ns.Buttons.All(true)
        ns.Safe("ghosts", G.Refresh)
    end)
end)
