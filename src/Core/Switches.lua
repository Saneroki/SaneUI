local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Switches
--  Quick switches the modules offer for a view that gathers them (Saneroki,
--  2026-10-26: the Speed Leveling guide switched on, paused or off from the
--  minimap's satchel). A module offers a switch; a view (Navigation's satchel)
--  lists them and is told when one changed, so neither needs the other.
--
--      Core.Offer(key, switch)   switch = { title, icon, State = fn() -> state, Tip = fn() -> words,
--                                Click = fn(mouseButton, owner) }; state: "on", "paused" or "off"
--      Core.Switches()           the switches offered by modules that stand, in the order offered:
--                                { { key, title, icon, state, tip, Click } }, their state and tip as now
--      Core.SwitchChanged()      a module's switch changed: the views told on the next frame
--      Core.OnSwitches(fn)       fn() whenever a switch changed (a view that shows them)
-------------------------------------------------------------------------------
local offered, order = {}, {} -- [key] = switch; the keys in the order they were offered
local listeners = {}

function Core.Offer(key, switch)
    if not offered[key] then order[#order + 1] = key end
    offered[key] = switch
end

function Core.Switches()
    local list = {}
    for _, key in ipairs(order) do
        local switch = offered[key]
        local state = Core.Safe("switch " .. key, switch.State)
        if state ~= nil then
            list[#list + 1] = { key = key, title = switch.title, icon = switch.icon, state = state,
                                tip = switch.Tip and Core.Safe("switch " .. key, switch.Tip) or nil,
                                Click = switch.Click }
        end
    end
    return list
end

function Core.OnSwitches(fn) listeners[#listeners + 1] = fn end

local function Tell()
    for _, fn in ipairs(listeners) do Core.Safe("switches", fn) end
end
Core.SwitchChanged = Core.Later(Tell)
