local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Book casts
--  What makes a click on our spellbook cast, as a click on the game's does:
--  a secure button of the game's (SecureActionButtonTemplate) over the icon of
--  each spell the page shows that a click casts (a learned spell, a pet's
--  ability), casting it as the game's entry does (SpellBookItemMixin:
--  OnIconClick): a spell by its ID (the rank it is), the self-cast modifier
--  casting on yourself, a pet's ability by its name, a right click on one the
--  pet may autocast switching its autocast. The game's modified clicks that
--  cast nothing (the link in chat, the pickup) cast nothing here either: the
--  entry under it does them (Item.Modified), as it does the tooltip, the
--  highlight and the drag to an action bar.
--
--  Out of a fight only, by the game's rules (Saneroki, 2026-10-20): the buttons
--  are made, set, placed, shown and hidden only then, and go as a fight begins
--  (PLAYER_REGEN_DISABLED comes before the game locks them); in a fight the
--  book still shows and pages, a click says that it casts again after it, and
--  the buttons come back over the page shown when it ends.
--
--  They stand on UIParent, not in our window: a window holding one would be
--  locked by the game in a fight, and Combat's full screen must open, close and
--  change then as always. Each is placed over its icon in UIParent's units,
--  above the window's panels.
--
--      Casts.Cover(items, strata, level)   -- a button over each of these entries that a click casts
--      Casts.Clear()                       -- every button away (out of a fight; in one they are)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Item = ns.BookItem
local Casts = {}
ns.BookCasts = Casts

local buttons = {} -- the secure buttons, made out of a fight, used again
local under = {}   -- [button] = the entry under it now
local fighting = false

local OnEnter = ns.Guard(function(button) if under[button] then Item.Enter(under[button]) end end)
local OnLeave = ns.Guard(function(button) if under[button] then Item.Leave(under[button]) end end)
local OnDragStart = ns.Guard(function(button) if under[button] then Item.Drag(under[button]) end end)
local OnMouseDown = ns.Guard(function(button) if under[button] then Item.Press(under[button], true) end end)
local OnMouseUp = ns.Guard(function(button) if under[button] then Item.Press(under[button], false) end end)
-- After the game's own click (the cast, or nothing for a modified click): the link or the pickup.
local PostClick = ns.Guard(function(button) if under[button] then Item.Modified(under[button]) end end)

local function Make()
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetAttribute("useOnKeyDown", false) -- on the button's release, as the game's entry casts
    button:SetAttribute("checkselfcast", true)
    -- A shift click casts nothing: it links the spell or picks it up (PostClick).
    button:SetAttribute("shift-type1", "")
    button:SetAttribute("shift-type2", "")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnMouseDown", OnMouseDown)
    button:SetScript("OnMouseUp", OnMouseUp)
    button:SetScript("PostClick", PostClick)
    button:Hide()
    buttons[#buttons + 1] = button
    return button
end

-- What a button casts, for the entry under it.
local function Set(button, item)
    local info = item.info
    local pet = item.entry.bank == select(2, ns.BookData.Banks())
    if pet then
        local name = info.name or ""
        local allowed = ns.BookData.Ask("GetSpellBookItemAutoCast", item.entry.slot, item.entry.bank)
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext1", "/cast " .. name)
        button:SetAttribute("type2", "macro")
        button:SetAttribute("macrotext2", (allowed and "/petautocasttoggle " or "/cast ") .. name)
        button:SetAttribute("spell", nil)
    else
        button:SetAttribute("type1", "spell")
        button:SetAttribute("type2", "spell")
        button:SetAttribute("spell", info.spellID)
        button:SetAttribute("macrotext1", nil)
        button:SetAttribute("macrotext2", nil)
    end
end

-- Over its icon, in UIParent's units.
local function Place(button, item, strata, level)
    local icon = item.Button
    local left, top = Plain(icon:GetLeft()), Plain(icon:GetTop())
    if not (left and top) then return false end
    local ratio = (Plain(icon:GetEffectiveScale()) or 1) / (Plain(UIParent:GetEffectiveScale()) or 1)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, top * ratio)
    button:SetSize((Plain(icon:GetWidth()) or 0) * ratio, (Plain(icon:GetHeight()) or 0) * ratio)
    button:SetFrameStrata(strata)
    button:SetFrameLevel(level)
    return true
end

function Casts.Cover(items, strata, level)
    if fighting or InCombatLockdown() then return end
    local count = 0
    for _, item in ipairs(items) do
        if Item.Castable(item) and item:IsVisible() then
            count = count + 1
            local button = buttons[count] or Make()
            Set(button, item)
            if Place(button, item, strata, level) then
                under[button] = item
                button:Show()
            else
                under[button] = nil
                button:Hide()
            end
        end
    end
    for index = count + 1, #buttons do
        under[buttons[index]] = nil
        buttons[index]:Hide()
    end
end

function Casts.Clear()
    if InCombatLockdown() then return end
    for _, button in ipairs(buttons) do
        under[button] = nil
        button:Hide()
    end
end

-- A fight begins: the buttons go now, before the game locks them. It ends: the page shown is covered anew
-- (by the book, which knows what it shows).
function Casts.Fight()
    fighting = true
    Casts.Clear()
end

function Casts.Peace()
    fighting = false
end

function Casts.Fighting()
    return fighting or InCombatLockdown()
end
