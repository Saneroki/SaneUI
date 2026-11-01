local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Form bar
--  One character's Action Bar 7 can follow its form (Saneroki, 2026-11-01): the
--  same keys cast a cat's spells in Cat Form and a bear's in Bear Form, while
--  another character's Bar 7 stays as it is. So the switch is the character's,
--  kept with its reservations, not one of the profile, which both may share.
--
--  A form's row of slots is Bar 1's in the game, and Bar 1 keeps its page here
--  (Bar1.lua), so those rows are free. Bar 7 takes them the way Bar 1 keeps its
--  page: a button asks for its own "actionpage" before its bar's, so each of the
--  twelve holds the form's page, and none out of a form. The buttons and their
--  keys stay the game's own, and the game's secure state driver does it all, so
--  it works in a fight.
--
--  A druid has two such rows (Saneroki, 2026-11-01): Cat Form's, which Prowl keeps,
--  and Bear Form's. As a human or in Moonkin Form the bar is itself.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local FormBar = {}
ns.FormBar = FormBar

local PREFIX = "MultiBar6Button"

-- The game's row for each form as a page, "own" for Bar 7's own slots.
FormBar.STATES = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; own"
-- A druid's: Prowl stays on Cat Form's row, should the game tell it as a row of its own, and Moonkin Form has none.
FormBar.DRUID = "[bonusbar:1][bonusbar:2] 7; [bonusbar:3] 9; own"

-- Run by the game's secure code on every change of that state. No page: the bar's own again.
FormBar.SNIPPET = [[
    local page = tonumber(newstate)
    for index = 1, 12 do
        self:GetFrameRef("button" .. index):SetAttribute("actionpage", page)
    end
]]

local header       -- the driver's frame, made once and out of a fight
local held = false -- the buttons follow the form now

-- Whether this character's switch is on.
function FormBar.On()
    return ns.char ~= nil and ns.char.formBar == true
end

local function Apply()
    local want = not ns.off and FormBar.On()
    if want == held then return end
    if want then
        header = header or ns.Bar1.Header(PREFIX, FormBar.SNIPPET)
        if not header then return end
        RegisterStateDriver(header, "page", ns.class == "DRUID" and FormBar.DRUID or FormBar.STATES)
    else
        UnregisterStateDriver(header, "page")
        header:SetAttribute("state-page", nil)
    end
    held = want
end

-- As the switch says, and the module not stood down; in a fight, once it is over.
function FormBar.Apply()
    Core.AfterCombat("Abilities: form bar", Apply)
end

function FormBar.Set(on)
    ns.char.formBar = on and true or nil
    FormBar.Apply()
end

-- Whether Bar 7 follows the form now: the rows of the forms are on show then.
function FormBar.Held()
    return held
end

-- The first slot of the form's row Bar 7 shows now, less one; nil on its own slots.
function FormBar.Row()
    local action = held and ns.ActionOf(rawget(_G, PREFIX .. "1"))
    if action and action <= ns.PAGES[#ns.PAGES] + ns.NUM_BUTTONS then
        return action - 1 - ((action - 1) % ns.NUM_BUTTONS)
    end
    return nil
end
