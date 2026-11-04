local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Combat - Macros - Reach
--  How a press reaches a macro, on this character. Nothing of this goes into the
--  game's own key settings or action slots, so taking it away leaves them as
--  they were.
--    a key        an override binding of ours, a click on the macro's hub
--    a bar button our button over it (Face.lua), and while the bar shows that
--                 button the button's own keys, by the game's state driver: on
--                 another page of Bar 1, in a vehicle or on a bar the game puts
--                 in place of yours the key is the game's again, in a fight too
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Reach = {}
Macros.Reach = Reach

-- The game's bars: the buttons' frames and the names of their keys.
Reach.BARS = {
    { prefix = "ActionButton", binding = "ACTIONBUTTON", paged = true },
    { prefix = "MultiBarBottomLeftButton", binding = "MULTIACTIONBAR1BUTTON" },
    { prefix = "MultiBarBottomRightButton", binding = "MULTIACTIONBAR2BUTTON" },
    { prefix = "MultiBarRightButton", binding = "MULTIACTIONBAR3BUTTON" },
    { prefix = "MultiBarLeftButton", binding = "MULTIACTIONBAR4BUTTON" },
    { prefix = "MultiBar5Button", binding = "MULTIACTIONBAR5BUTTON" },
    { prefix = "MultiBar6Button", binding = "MULTIACTIONBAR6BUTTON" },
    { prefix = "MultiBar7Button", binding = "MULTIACTIONBAR7BUTTON" },
}
Reach.BUTTONS = 12
Reach.PAGES = 6

local NOT_YOURS = "[overridebar][vehicleui][possessbar] game; "

-- Runs when the state changes: our button and the keys, or neither. Its text follows Press.SNIPPET's rules.
Reach.SLOT = [[
    local face = self:GetFrameRef("face")
    self:ClearBindings()
    if newstate == "ours" then
        face:Show()
        local name = self:GetAttribute("button")
        local first, second = self:GetAttribute("key1"), self:GetAttribute("key2")
        if first then self:SetBindingClick(true, first, name, "LeftButton") end
        if second then self:SetBindingClick(true, second, name, "LeftButton") end
    else
        face:Hide()
    end
]]

local owner              -- the frame our keys belong to
local headers = {}       -- [place] = the frame that follows the bar
local active = {}        -- [place] = true while it stands
local started = false

-- A bar of the list by its prefix.
local function Bar(prefix)
    for index, bar in ipairs(Reach.BARS) do
        if bar.prefix == prefix then return bar, index end
    end
    return nil
end

-- A place's parts: "ActionButton3:2" is Bar 1's third button on page 2.
function Reach.Parts(place)
    local prefix, button, page = place:match("^(.-Button)(%d+):?(%d*)$")
    if not prefix then return nil end
    return Bar(prefix), tonumber(button), tonumber(page)
end

function Reach.PlaceOf(bar, button, page)
    return bar.prefix .. button .. (bar.paged and ":" .. (page or 1) or "")
end

-- A place in words.
function Reach.Words(place)
    local bar, button = Reach.Parts(place)
    if not bar then return "" end
    local _, index = Bar(bar.prefix)
    return Macros.TEXT.bars[index], button
end

-- The page Bar 1 shows, as the game's conditions say: the same word in both games.
function Reach.Page()
    local parse = rawget(_G, "SecureCmdOptionParse")
    local words = {}
    for page = 2, Reach.PAGES do words[#words + 1] = "[bar:" .. page .. "] " .. page end
    words[#words + 1] = "1"
    return tonumber(Core.Plain(Core.Ask(parse, table.concat(words, "; ")))) or 1
end

local function ClearSlot(place)
    local header = headers[place]
    if not header then return end
    UnregisterStateDriver(header, "slot")
    ClearOverrideBindings(header)
    header.face:Hide()
    active[place] = nil
end

local function Short(key)
    local text = rawget(_G, "GetBindingText")
    return key and (text and Core.Ask(text, key, 1) or key) or ""
end
Reach.Short = Short -- a key as a bar button writes it

local function SetSlot(place, macro)
    local bar, button, page = Reach.Parts(place)
    local slot = bar and rawget(_G, bar.prefix .. button)
    if not slot then return end
    local first, second = GetBindingKey(bar.binding .. button)
    local name = "SaneUIMacroFace_" .. place:gsub(":", "_")
    local face = Macros.Face.Get(place, slot, name)
    Macros.Press.Load(macro)
    Macros.Face.Show(face, macro, Short(first))
    local header = headers[place]
    if not header then
        header = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
        header.face = face
        header:SetFrameRef("face", face)
        header:SetAttribute("button", name)
        header:SetAttribute("_onstate-slot", Reach.SLOT)
        headers[place] = header
    end
    header:SetAttribute("key1", first)
    header:SetAttribute("key2", second)
    active[place] = (first or "") .. "," .. (second or "")
    RegisterStateDriver(header, "slot", NOT_YOURS .. (bar.paged and "[bar:" .. (page or 1) .. "] ours; game" or "ours"))
end

-- Every bar button of this character stands as saved. Out of a fight.
local function Slots()
    for place in pairs(headers) do ClearSlot(place) end
    for place, id in pairs(Macros.own.places) do
        local macro = Macros.Book.Find(id)
        if macro then SetSlot(place, macro) else Macros.own.places[place] = nil end
    end
end

-- Every key of this character stands as saved. Out of a fight.
local function Keys()
    owner = owner or CreateFrame("Frame")
    ClearOverrideBindings(owner)
    for key, id in pairs(Macros.own.keys) do
        local macro = Macros.Book.Find(id)
        if macro then
            Macros.Press.Load(macro)
            SetOverrideBindingClick(owner, true, key, Macros.Press.Name(macro), "LeftButton")
        else
            Macros.own.keys[key] = nil
        end
    end
end

function Reach.Update()
    Core.AfterCombat("Macros: keys", Keys)
    Core.AfterCombat("Macros: bars", Slots)
end

-- The game's key settings changed: a button whose keys are others now takes them.
local function Bindings()
    for place in pairs(active) do
        local bar, button = Reach.Parts(place)
        local first, second = GetBindingKey(bar.binding .. button)
        if active[place] ~= (first or "") .. "," .. (second or "") then
            return Core.AfterCombat("Macros: bars", Slots)
        end
    end
end

local function Edges(name)
    if name ~= "ActionButtonUseKeyDown" then return end
    Core.AfterCombat("Macros: edges", function()
        Macros.Press.Edges()
        Macros.Face.Edges()
    end)
end

function Reach.Start()
    if started then return end
    started = true
    Reach.Update()
    ns.On("PLAYER_REGEN_ENABLED", Macros.Press.Fresh)
    ns.On("UPDATE_BINDINGS", Bindings)
    ns.On("CVAR_UPDATE", Edges)
end

-- A macro's key. Returns the macro that held that key before, if another did.
function Reach.SetKey(macro, key)
    local had = Macros.Book.Find(Macros.own.keys[key] or 0)
    local old = Macros.Book.KeyOf(macro)
    if old then Macros.own.keys[old] = nil end
    Macros.own.keys[key] = macro.id
    Reach.Update()
    return had ~= macro and had or nil
end

function Reach.TakeKey(macro)
    local old = Macros.Book.KeyOf(macro)
    if old then Macros.own.keys[old] = nil end
    Reach.Update()
end

-- A macro's bar button. One button a macro.
function Reach.SetPlace(macro, place)
    local old = Macros.Book.PlaceOf(macro)
    if old then Macros.own.places[old] = nil end
    Macros.own.places[place] = macro.id
    Reach.Update()
end

function Reach.TakePlace(macro)
    local old = Macros.Book.PlaceOf(macro)
    if old then Macros.own.places[old] = nil end
    Reach.Update()
end

-- Standing down: no key and no bar button of ours.
function Reach.GiveBack()
    Core.AfterCombat("Macros: give back", function()
        if owner then ClearOverrideBindings(owner) end
        for place in pairs(headers) do ClearSlot(place) end
    end)
end
