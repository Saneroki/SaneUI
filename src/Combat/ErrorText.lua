local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - ErrorText
--  The game's red error text at the top of the screen ("Spell is not ready yet",
--  "Not enough rage") and its sound, off by the switch Hide the red error text. No
--  setting of the game does this. The frame that shows the text hears one event
--  for it, the same one the game's own /uierrorsoff stops, which also mutes every
--  sound effect: here the event alone, so the other sounds stay, and the yellow
--  lines (a quest's progress), which come by another event.
-------------------------------------------------------------------------------
local ErrorText = {}
ns.ErrorText = ErrorText

ErrorText.EVENT = "UI_ERROR_MESSAGE"

local hidden = false

local function Set(on)
    local frame = rawget(_G, "UIErrorsFrame")
    if on == hidden or not frame then return end
    hidden = on
    if on then frame:UnregisterEvent(ErrorText.EVENT) else frame:RegisterEvent(ErrorText.EVENT) end
end

-- The switch as it stands.
function ErrorText.Apply()
    Set(not ns.off and ns.options.hideErrors ~= false)
end

function ErrorText.GiveBack()
    Set(false)
end
