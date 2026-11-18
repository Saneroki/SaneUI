local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Settings
--  The module's switches handed to Core once every part has added its own:
--  Combat.lua's (ns.OPTIONS), then the nameplates' (Nameplates/Nameplates.lua).
--  A switch that changes goes to ns.Changed (Combat.lua), which tells the part
--  it is about; another profile's settings coming in to ns.Replaced.
-------------------------------------------------------------------------------
local Core = SaneUI.Core

Core.Options(ns.name, ns.OPTIONS, {
    changed = function(key, value) ns.Changed(key, value) end,
    replaced = function() ns.Replaced() end,
})
