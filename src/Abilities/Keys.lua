local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Keys
--  Your spellbook, pet book and talents keys open our own windows instead of
--  the game's (Saneroki, 2026-10-20): whatever keys the game's key bindings
--  give its actions TOGGLESPELLBOOK, TOGGLEPETBOOK and TOGGLETALENTS run ours
--  (Bindings.xml, in the game's key bindings under SaneUI), by the game's own
--  override bindings, which leave your key bindings as they are: the full
--  screen with that window (the pet book: the spellbook at the pet's tab), and
--  pressed again while it shows, back to its size, as the game's keys toggle
--  its window. The game's micro menu buttons still open the game's own window.
--
--  Override bindings change out of a fight only: set at the login, anew when
--  your key bindings change (UPDATE_BINDINGS, only when the keys of those
--  actions did), and taken away when the switch is off or the module stands
--  down; in a fight, once it is over. Our keys themselves work in a fight too.
--  Only the keys of a window of ours this game has (Board.Present): in Retail,
--  where our spellbook and talents are not (Abilities.lua, ns.Serves), the game's
--  keys stay the game's.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Keys = {}
ns.Keys = Keys

-- The game's actions whose keys open ours, and what each opens.
Keys.ACTIONS = { TOGGLESPELLBOOK = "spellbook", TOGGLEPETBOOK = "pet", TOGGLETALENTS = "talents" }
Keys.ORDER = { "TOGGLESPELLBOOK", "TOGGLEPETBOOK", "TOGGLETALENTS" }
-- Our own keys (Bindings.xml), and the window of ours each opens.
Keys.COMMANDS = { spellbook = "SANEUI_ABILITIES_SPELLBOOK", pet = "SANEUI_ABILITIES_PETBOOK", talents = "SANEUI_ABILITIES_TALENTS" }
Keys.WINDOWS = { spellbook = "spellbook", pet = "spellbook", talents = "talents" }

-- Their words in the game's key bindings.
BINDING_NAME_SANEUI_ABILITIES_SPELLBOOK = "Open the spellbook on the full screen"
BINDING_NAME_SANEUI_ABILITIES_PETBOOK = "Open the pet's spells on the full screen"
BINDING_NAME_SANEUI_ABILITIES_TALENTS = "Open the talents on the full screen"
BINDING_NAME_SANEUI_ABILITIES_MACROS = "Open or close Sane Macros"

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

-- Whether the window of ours that one of the game's actions would open is there in this game.
local function Ours(action)
    local what = Keys.ACTIONS[action]
    return what ~= nil and ns.Board.Present(Keys.WINDOWS[what])
end

-- Our keys on the game's: out of a fight, or once it is over.
function Keys.Bind()
    if not owner then return end
    if InCombatLockdown() then return Core.AfterCombat("Abilities: keys", Keys.Bind) end
    ClearOverrideBindings(owner)
    bound = Signature()
    local options = ns.options or {}
    if ns.off or options.keys == false then return end
    for _, action in ipairs(Keys.ORDER) do
        if Ours(action) then
            for _, key in ipairs({ GetBindingKey(action) }) do
                if type(key) == "string" and key ~= "" then
                    SetOverrideBinding(owner, false, key, Keys.COMMANDS[Keys.ACTIONS[action]])
                end
            end
        end
    end
end

-- Whether our keys are on the game's now (that action's, TOGGLETALENTS; without one, any of them): the game's own
-- spellbook and talents then open from its micro menu buttons only (Core's Classic windows say so).
function Keys.Taken(action)
    local options = ns.options or {}
    if owner == nil or ns.off or options.keys == false then return false end
    if action then return Ours(action) end
    for _, each in ipairs(Keys.ORDER) do
        if Ours(each) then return true end
    end
    return false
end

local function Changed()
    if ns.off or Signature() == bound then return end
    Keys.Bind()
end

-- One of our keys was pressed (Bindings.xml): the full screen with that window, or back from it. The pet book's
-- does nothing while your pet has no spellbook, as the game's key (it opens its book only at the pet's tab); one
-- whose window this game has not (Retail) does nothing either.
function Keys.Press(what)
    if ns.off or not ns.Board.Present(Keys.WINDOWS[what]) then return end
    if what == "pet" then
        if not ns.SpellbookData.HasPet() then return end
        return ns.Screen.Toggle("spellbook", "pet")
    end
    ns.Screen.Toggle(what)
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
        Core.AfterCombat("Abilities: keys", Keys.Leave)
        return
    end
    ClearOverrideBindings(owner)
end
