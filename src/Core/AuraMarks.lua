local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - AuraMarks
--  The menu of an aura or a spell, between the module that keeps your marks of
--  auras (Combat, Units/Lists.lua: Important, Unimportant, Hidden, Prioritize on
--  and Hide from unit frames, Edit tracked..., Add tracking) and those that show
--  auras and spells elsewhere (Abilities: the full screen's spellbook on a right
--  click, the aura history on a click), so neither needs the other (Saneroki,
--  2026-11-18: the full screen went to Abilities, the marks stayed in Combat).
--  Nobody serving (Combat switched off, or stood down): no menu, and the click
--  does nothing.
--
--      Core.AuraMarks.Serve(module, menu)  menu(owner, spell) opens it at owner; spell = { id, name, icon,
--                                          harmful, unit }, nil where the game hides which aura it is
--      Core.AuraMarks.Menu(owner, spell)   opens it: true where someone serves it
--      Core.AuraMarks.Served()             whether someone serves it now
--
--  And what an aura's icon is made of, the same on Combat's unit frames and in
--  Abilities' aura history (Paint): the picture cropped square, the swipe
--  darkening the time gone (it alone tells the time: no numbers), the stack
--  count over it.
-------------------------------------------------------------------------------
local AuraMarks = {}
Core.AuraMarks = AuraMarks

AuraMarks.CROP = { 0.08, 0.92, 0.08, 0.92 } -- an icon's picture without the edge it is drawn with

local owner, menu

function AuraMarks.Serve(module, served)
    owner, menu = module, served
end

function AuraMarks.Served()
    return menu ~= nil and not (owner and owner.off)
end

function AuraMarks.Menu(at, spell)
    if not AuraMarks.Served() then return false end
    Core.Safe("aura menu", menu, at, spell)
    return true
end

-- On a frame of the game's or ours: returns { picture, cooldown, top, count }.
function AuraMarks.Paint(frame)
    local crop = AuraMarks.CROP
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.5)
    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(frame)
    top:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetJustifyH("RIGHT")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    cooldown:SetHideCountdownNumbers(true) -- the darkening alone tells the time
    return { picture = icon, cooldown = cooldown, top = top, count = count }
end
