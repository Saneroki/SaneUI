local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Bar 1
--  Action Bar 1 keeps the page you chose (Saneroki, 2026-10-31): a stance, a
--  form or stealth no longer puts another row of buttons on it. Its pages are
--  yours, turned with its arrows or your page keys, in a fight too.
--
--  In the game a button of Bar 1 asks its bar for its page, and on page 1 the
--  game writes a form's row to the bar. A button's own "actionpage" comes
--  first: each of the twelve holds the page you chose, so that writing changes
--  neither what it shows nor what its key casts. The buttons and their keys
--  stay the game's own.
--
--  Where the game puts something of its own in the bar's place (a vehicle, a
--  possessed creature, a temporary shape, Retail's skyriding) the buttons let
--  go and are the game's again. Your main keys are those of Bar 6, which has
--  nothing to do with that: for as long as it lasts they press the game's
--  buttons, as they would on Bar 1.
--
--  All of it runs in the game's secure state driver, so it works in a fight.
--  Bars 6 to 8 need nothing here: their slots are on none of Bar 1's pages and
--  no form changes them, but a druid's Bar 6 swaps with its form (FormBar.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bar1 = {}
ns.Bar1 = Bar1

-- The bar's page, or "game" while something of the game's stands in its place.
Bar1.STATES = "[vehicleui][overridebar][possessbar][shapeshift][bonusbar:5][petbattle] game; "
    .. "[bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; 1"

-- Run by the game's secure code on every change of that state. No state: the switch is off, and the
-- buttons and keys are left as the game has them.
Bar1.SNIPPET = [[
    local page = tonumber(newstate)
    for index = 1, 12 do
        self:GetFrameRef("button" .. index):SetAttribute("actionpage", page)
    end
    self:ClearBindings()
    if newstate == "game" then
        for index = 1, 12 do
            local first, second = GetBindingKey("MULTIACTIONBAR5BUTTON" .. index)
            if first then self:SetBinding(true, first, "ACTIONBUTTON" .. index) end
            if second then self:SetBinding(true, second, "ACTIONBUTTON" .. index) end
        end
    end
]]

local header       -- the driver's frame, made once and out of a fight
local held = false -- the buttons hold their page now

-- A frame of the game's secure code that knows a bar's twelve buttons and runs snippet on each change of its state
-- (state, "page" if none). Nil where the game has the buttons no more: the bar then stays the game's.
function Bar1.Header(prefix, snippet, state)
    local buttons = {}
    for index = 1, ns.NUM_BUTTONS do
        buttons[index] = rawget(_G, prefix .. index)
        if not buttons[index] then return nil end
    end
    local frame = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
    for index, button in ipairs(buttons) do frame:SetFrameRef("button" .. index, button) end
    frame:SetAttribute("_onstate-" .. (state or "page"), snippet)
    return frame
end

local function Apply()
    local want = not ns.off and ns.options.holdPage and true or false
    if want == held then return end
    if want then
        header = header or Bar1.Header("ActionButton", Bar1.SNIPPET)
        if not header then return end
        RegisterStateDriver(header, "page", Bar1.STATES)
    else
        UnregisterStateDriver(header, "page")
        header:SetAttribute("state-page", nil)
    end
    held = want
end

-- As the switch says, and the module not stood down; in a fight, once it is over.
function Bar1.Apply()
    Core.AfterCombat("Abilities: Bar 1", Apply)
end

-- Whether a slot is on a form's row while the bar keeps its page: that row never shows, unless it is a druid's Bar 9
-- or 10, which Bar 6 shows (FormBar.lua).
function Bar1.Unseen(slot)
    return held and slot > ns.PAGES[2] and slot <= ns.PAGES[#ns.PAGES] + ns.NUM_BUTTONS and not ns.FormBar.Number(slot)
end

-- For the test: whether the buttons hold their page now.
function Bar1.Held()
    return held
end
