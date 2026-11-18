local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Tooltips - Inspect
--  The item level and the talents of the player a tooltip shows: Core's
--  (Core.Inspect, src/Core/Inspect.lua), which paces the inspections for
--  every view that asks. Start(arrived): arrived(guid) when a player's
--  answer came.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Inspect = {}
ns.Inspect = Inspect

function Inspect.Level(unit, guid) return Core.Inspect.Level(unit, guid) end
function Inspect.Talents(unit, guid) return Core.Inspect.Talents(unit, guid) end
function Inspect.Start(arrived) Core.Inspect.Watch(ns.Guard(arrived)) end
