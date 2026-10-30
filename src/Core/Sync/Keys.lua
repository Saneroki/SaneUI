local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua
local Plain = Core.Plain

-------------------------------------------------------------------------------
--  Sane UI - Core - Sync - Keys
--  The key bindings (Saneroki, 2026-10-30: part of a profile like the rest):
--  every key of the game's list, Sane UI's keys and other addons' among them,
--  kept by command. Written out of a fight, as the rest of Sync, and saved in
--  the game's binding set in use. A command this client does not list now
--  (its addon is off) keeps its keys in the profile.
-------------------------------------------------------------------------------
local ID = "keyBindings"
local TEXT = {
    text = "Key bindings",
    tip = "Every key bound in Esc > Options > Keybindings, Sane UI's own keys too.",
}

local function Game(name, ...)
    return Core.Ask(rawget(_G, name), ...)
end

-- One line of the game's list into list: the keys of its command.
local function Line(list, ok, command, _, ...)
    command = ok and Plain(command)
    if type(command) ~= "string" then return end
    local keys = {}
    for at = 1, select("#", ...) do
        local key = Plain((select(at, ...)))
        if type(key) == "string" and key ~= "" then keys[#keys + 1] = key end
    end
    list[command] = keys
end

-- [command] = its keys, of every command the game lists now.
local function Bound()
    local list = {}
    local get = rawget(_G, "GetBinding")
    if type(get) ~= "function" then return list end
    for index = 1, Game("GetNumBindings") or 0 do Line(list, pcall(get, index)) end
    return list
end

Sync.Part(ID, "elsewhere", {
    text = TEXT.text,
    tip = TEXT.tip,
    Read = function()
        local now = Bound()
        if not next(now) then return Sync.Taken(ID) end
        local kept = {}
        for command, keys in pairs(Sync.Taken(ID) or {}) do
            if not now[command] then kept[command] = keys end
        end
        for command, keys in pairs(now) do
            if keys[1] then kept[command] = keys end
        end
        return kept
    end,
    Write = function(data)
        local now, changed = Bound(), false
        for command, keys in pairs(now) do
            if keys[1] and not Core.Same(keys, data[command]) then
                for _, key in ipairs(keys) do Game("SetBinding", key) end
                changed = true
            end
        end
        for command, keys in pairs(data) do
            if now[command] and type(keys) == "table" and not Core.Same(keys, now[command]) then
                for _, key in ipairs(keys) do Game("SetBinding", key, command) end
                changed = true
            end
        end
        if changed then Game("SaveBindings", Game("GetCurrentBindingSet")) end
        return false
    end,
    -- The game's own keys again (Character specific).
    Default = function()
        Game("LoadBindings", rawget(_G, "Enum") and Enum.BindingSet and Enum.BindingSet.Default or 0)
        Game("SaveBindings", Game("GetCurrentBindingSet"))
    end,
})
