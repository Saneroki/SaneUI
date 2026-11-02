local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Macros - Press
--  A macro's secure button, the hub: it holds the macro's turns and where the
--  macro stands, in numbered attributes, and a key clicks it. A bar button of
--  the macro (Face.lua) is a button of its own that reads the same hub.
--
--  On a press the game runs a snippet before the button's action, in a fight
--  too. It walks from where the macro stands (from the top with "top"), past
--  every turn whose condition fails, puts the first that holds on the button as
--  a macro's text, and moves on. Whether the game can cast it is the game's to
--  say on the action: a turn it refuses costs that press and nothing else.
--  Snippets cannot read rage, cooldowns or auras, so conditions are the only
--  way a turn is skipped. Their text may not hold the word for a Lua closure or
--  any brace, comments included.
--
--  Everything else here is out of a fight only: the game keeps addon code off a
--  secure button then. A macro's change waits for the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Press = {}
ns.Press = Press

Press.PREFIX = "SaneUIMacro"
Press.ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

Press.SNIPPET = [[
    local hub = self:GetFrameRef("hub") or self
    local count = hub:GetAttribute("count") or 0
    local at = hub:GetAttribute("top") and 1 or hub:GetAttribute("at") or 1
    local tries = 0
    local line
    while tries < count and not line do
        tries = tries + 1
        local when = hub:GetAttribute("c" .. at)
        if not when or SecureCmdOptionParse(when) then line = hub:GetAttribute("m" .. at) end
        at = at % count + 1
    end
    hub:SetAttribute("at", at)
    self:SetAttribute("type", "macro")
    self:SetAttribute("macrotext", line or "")
    self:CallMethod("Pressed")
]]

local hubs = {}  -- [macro id] = its button
local plainParse -- the game's parser, asked for what shows

-- A press: what shows moves on. Runs before the cast, for the look only.
local function Pressed()
    ns.Face.Paint()
end

-- A button that presses a macro: one edge only, or a press would be two turns.
function Press.Ready(button)
    local down = GetCVarBool("ActionButtonUseKeyDown") and true or false
    button:RegisterForClicks(down and "AnyDown" or "AnyUp")
    button:SetAttribute("useOnKeyDown", down)
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", "")
    button.Pressed = Pressed
    if not button.wrapped then
        button:WrapScript(button, "OnClick", Press.SNIPPET)
        button.wrapped = true
    end
end

-- The macro's hub, made when first needed. Out of a fight.
function Press.Hub(macro)
    local hub = hubs[macro.id]
    if not hub then
        hub = CreateFrame("Button", Press.PREFIX .. macro.id, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
        hubs[macro.id] = hub
        Press.Ready(hub)
    end
    return hub
end

function Press.Name(macro)
    return Press.PREFIX .. macro.id
end

-- The macro's turns onto its hub. Out of a fight.
function Press.Load(macro)
    local hub = Press.Hub(macro)
    local turns = ns.Write.Turns(macro)
    for index = 1, math.max(hub:GetAttribute("count") or 0, #turns) do
        local turn = turns[index]
        hub:SetAttribute("m" .. index, turn and turn.line or nil)
        hub:SetAttribute("c" .. index, turn and turn.when or nil)
    end
    hub:SetAttribute("count", #turns)
    hub:SetAttribute("top", macro.top and true or nil)
    hub:SetAttribute("at", 1)
    hub.turns = turns
end

-- A macro changed: a hub takes it now, or at the fight's end. A macro with no hub waits until it gets a key or a place.
function Press.Update(macro)
    if not hubs[macro.id] then return end
    Core.AfterCombat("Macros: " .. macro.id, function()
        Press.Load(macro)
        ns.Face.Paint()
    end)
end

-- A macro deleted: its hub does nothing more.
function Press.Drop(macro)
    local hub = hubs[macro.id]
    if not hub then return end
    Core.AfterCombat("Macros: " .. macro.id, function()
        hub:SetAttribute("count", 0)
        hub.turns = nil
    end)
end

-- A fight's end: the macros that start over do.
function Press.Fresh()
    for id, hub in pairs(hubs) do
        local macro = ns.Book.Find(id)
        if macro and macro.fresh then hub:SetAttribute("at", 1) end
    end
    ns.Face.Paint()
end

-- The key-down setting changed: every button takes it.
function Press.Edges()
    for _, hub in pairs(hubs) do Press.Ready(hub) end
end

-- The turn the next press would take, for what shows: the game's parser answers in a fight too.
function Press.Next(macro)
    local hub = hubs[macro.id]
    local turns = hub and hub.turns
    if not turns or not turns[1] then return nil end
    plainParse = plainParse or rawget(_G, "SecureCmdOptionParse")
    local count = #turns
    local at = macro.top and 1 or hub:GetAttribute("at") or 1
    for _ = 1, count do
        local turn = turns[at]
        if not turn.when or Core.Plain(plainParse(turn.when)) then return turn end
        at = at % count + 1
    end
    return nil
end

-- The spell a step's line would cast now, as far as the game's parser says.
function Press.SpellOf(step)
    if step.kind == "spell" then return step.what end
    if step.kind ~= "text" then return nil end
    for line in step.what:gmatch("[^\n]+") do
        local rest = line:match("^%s*/cast%s+(.+)$")
        if rest then
            plainParse = plainParse or rawget(_G, "SecureCmdOptionParse")
            return Core.Plain(Core.Ask(plainParse, rest))
        end
    end
    return nil
end

-- A step's picture.
function Press.Picture(step)
    if not step then return Press.ICON end
    if step.kind == "item" then
        local items = rawget(_G, "C_Item")
        local picture = items and step.id and Core.Ask(items.GetItemIconByID, step.id)
        return picture or (items and Core.Ask(items.GetItemIconByID, step.what)) or Press.ICON
    end
    local spell = Press.SpellOf(step)
    local spells = rawget(_G, "C_Spell")
    return spell and spells and Core.Ask(spells.GetSpellTexture, spell) or Press.ICON
end
