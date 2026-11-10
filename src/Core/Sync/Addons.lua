local ADDON = ...
local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Sync - Addons
--  Which addons are switched on (Saneroki, 2026-10-30: all characters of a
--  profile the same, addons too). The game keeps that for each character; a
--  part of Sync keeps it in the profile. Only addons this client has are
--  written, and Sane UI itself is never switched off: the game shows a change
--  after a /reload, which is offered. An addon switched on the character
--  screen since this character's last logout is the player's word: it goes
--  into the profile at the login instead of being switched back (Sync.Outside;
--  Saneroki, 2026-11-10: "I can't turn off addons").
-------------------------------------------------------------------------------
local TEXT = {
    text = "Addons",
    tip = "Which addons are switched on in the game's addon list.",
    reload = "your addons",
}
local NONE = 0 -- the game's word for switched off (Enum.AddOnEnableState)

local function Me()
    return Core.Ask(UnitGUID, "player")
end

local function Enabled(addons, name)
    return (Core.Ask(addons.GetAddOnEnableState, name, Me()) or NONE) ~= NONE
end

Sync.Part("addons", "elsewhere", {
    text = TEXT.text,
    tip = TEXT.tip,
    reload = TEXT.reload,
    Read = function()
        local addons = rawget(_G, "C_AddOns")
        if not addons then return nil end
        local list = {}
        for index = 1, Core.Ask(addons.GetNumAddOns) or 0 do
            local name = Core.Ask(addons.GetAddOnInfo, index)
            if type(name) == "string" then list[name] = Enabled(addons, name) end
        end
        return list
    end,
    Write = function(data)
        local addons = rawget(_G, "C_AddOns")
        if not addons then return false end
        local changed = false
        for name, on in pairs(data) do
            if type(name) == "string" and name ~= ADDON and Core.Ask(addons.GetAddOnInfo, name)
                and Enabled(addons, name) ~= on then
                Core.Ask(on and addons.EnableAddOn or addons.DisableAddOn, name, Me())
                changed = true
            end
        end
        if changed then Core.Ask(addons.SaveAddOns) end
        return changed
    end,
    -- Switched since the last logout (on the character screen): the profile takes it. One this character did not
    -- have then (installed since) is left to the profile's.
    Outside = function(data, before, now)
        for name, on in pairs(now) do
            if type(before[name]) == "boolean" and before[name] ~= on then data[name] = on end
        end
    end,
})
