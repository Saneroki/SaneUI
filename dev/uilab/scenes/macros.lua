-- Sane Macros: Core and the module Macros from their TOCs, the window open on a sequence with four steps and a normal macro
-- beside it, the game's spells, items and macro conditions standing in. In the console LabMacros is the module's table.
Lab.TOC("src/Core/SaneUI.toc")
LabMacros = Lab.TOC("src/Macros/SaneUI_Macros.toc")

local PICTURES = { ["Shield Block"] = 132110, ["Victory Rush"] = 132342, ["Shield Slam"] = 134951, Slam = 132340, Rend = 132155 }
C_Spell = C_Spell or {}
C_Spell.DoesSpellExist = function(name) return PICTURES[name] ~= nil end
C_Spell.GetSpellInfo = function(name) return PICTURES[name] and { spellID = 1 } or nil end
C_Spell.GetSpellTexture = function(name) return PICTURES[name] end
C_SpellBook = C_SpellBook or {}
C_SpellBook.IsSpellKnown = function() return true end
SecureCmdOptionParse = function() return nil end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
ClearOverrideBindings, SetOverrideBindingClick = function() end, function() end
GetBindingKey = function() end

local function Step(what, when, unit, often)
    local step = LabMacros.Book.Step("spell", what)
    step.when, step.unit, step.often = when or {}, unit, often or 1
    return step
end

Lab.OnLogin(function()
    local Book = LabMacros.Book
    if not Book.All()[1] then
        local tank = Book.New("Tank")
        tank.steps = {
            Step("Shield Block"),
            Step("Victory Rush", { { word = "harm" } }),
            Step("Shield Slam", { { word = "harm" }, { word = "dead", no = true } }, nil, 2),
            Step("Slam", { { word = "combat" } }),
            Step("Sllam"),
        }
        local healing = Book.New("Mouse heal")
        healing.top = true
        healing.steps = { Step("Rend", { { word = "help" } }, "mouseover"), Step("Slam") }
        local text = Book.New("Long text")
        text.steps = { LabMacros.Book.Step("text", "#showtooltip\n/cast [mod:shift] Rend; Slam") }
    end
    LabMacros.Editor.Toggle()
end)
