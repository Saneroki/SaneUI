local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Keys
--  Your spellbook, pet book and talents keys open our own windows instead of
--  the game's (Saneroki, 2026-10-20): whatever keys the game's key bindings
--  give its actions TOGGLESPELLBOOK, TOGGLEPETBOOK and TOGGLETALENTS run ours
--  (Bindings.xml, in the game's key bindings under Sane UI), by the game's own
--  override bindings, which leave your key bindings as they are: the full
--  screen with that window (the pet book: the spellbook at the pet's tab), and
--  pressed again while it shows, back to its size, as the game's keys toggle
--  its window. The game's micro menu buttons still open the game's own window.
--
--  Override bindings change out of a fight only: set at the login, anew when
--  your key bindings change (UPDATE_BINDINGS, only when the keys of those
--  actions did), and taken away when the switch is off or the module stands
--  down; in a fight, once it is over. Our keys themselves work in a fight too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Keys = {}
ns.Keys = Keys

-- The game's actions whose keys open ours, and what each opens.
Keys.ACTIONS = { TOGGLESPELLBOOK = "spellbook", TOGGLEPETBOOK = "pet", TOGGLETALENTS = "talents" }
Keys.ORDER = { "TOGGLESPELLBOOK", "TOGGLEPETBOOK", "TOGGLETALENTS" }
-- Our own keys (Bindings.xml).
Keys.COMMANDS = { spellbook = "SANEUI_COMBAT_SPELLBOOK", pet = "SANEUI_COMBAT_PETBOOK", talents = "SANEUI_COMBAT_TALENTS" }

-- Their words in the game's key bindings.
BINDING_NAME_SANEUI_COMBAT_SPELLBOOK = "Open the spellbook on Combat's full screen"
BINDING_NAME_SANEUI_COMBAT_PETBOOK = "Open the pet's spells on Combat's full screen"
BINDING_NAME_SANEUI_COMBAT_TALENTS = "Open the talents on Combat's full screen"

local owner       -- the frame our override bindings belong to
local bound = nil -- the keys of those actions when they were last bound ("P|N|..."): rebound only when they change

-- The keys the game's key bindings give those actions, as one line.
local function Signature()
    local parts = {}
    for _, action in ipairs(Keys.ORDER) do
        local one, two = GetBindingKey(action)
        parts[#parts + 1] = action .. "=" .. tostring(one) .. "," .. tostring(two)
    end
    return table.concat(parts, "|")
end

-- Our keys on the game's: out of a fight, or once it is over.
function Keys.Bind()
    if not owner then return end
    if InCombatLockdown() then return Core.AfterCombat("Combat: keys", Keys.Bind) end
    ClearOverrideBindings(owner)
    bound = Signature()
    local options = ns.options or {}
    if ns.off or options.keys == false then return end
    for _, action in ipairs(Keys.ORDER) do
        for _, key in ipairs({ GetBindingKey(action) }) do
            if type(key) == "string" and key ~= "" then
                SetOverrideBinding(owner, false, key, Keys.COMMANDS[Keys.ACTIONS[action]])
            end
        end
    end
end

-- Whether our keys are on the game's now: the game's own spellbook and talents then open from its micro menu
-- buttons only (Core's Classic windows say so).
function Keys.Taken()
    local options = ns.options or {}
    return owner ~= nil and not ns.off and options.keys ~= false
end

local function Changed()
    if ns.off or Signature() == bound then return end
    Keys.Bind()
end

-- One of our keys was pressed (Bindings.xml): the full screen with that window, or back from it.
function Keys.Press(what)
    if ns.off then return end
    if what == "pet" then return ns.Window.Toggle("spellbook", "pet") end
    ns.Window.Toggle(what)
end

function Keys.Start()
    owner = CreateFrame("Frame")
    ns.On("UPDATE_BINDINGS", Changed)
    Keys.Bind()
end

-- The module stood down: the game's keys open the game's windows again.
function Keys.Leave()
    if not owner then return end
    if InCombatLockdown() then
        Core.AfterCombat("Combat: keys", Keys.Leave)
        return
    end
    ClearOverrideBindings(owner)
end
