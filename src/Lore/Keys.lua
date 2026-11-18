local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Keys
--  Space goes on while the talk shows (the setting Space goes on): an override
--  binding of ours (SetOverrideBindingClick, on a button of ours) that lives
--  exactly as long as the talk, and is given back the moment it ends. Every
--  other key does what it always does; Esc ends the talk (Core.Escape, Talk.lua).
--  Override bindings cannot change in a fight, and a fight ends the talk before
--  one begins (the game tells it first), so they are never set or left there.
--
--      Keys.On()        Space goes on, from now until Keys.Off()
--      Keys.Off()       Space jumps again
--      Keys.Update()    as the setting says now
--      Keys.GiveBack()  no binding of ours
-------------------------------------------------------------------------------
local Keys = {}
ns.Keys = Keys

Keys.BUTTON = "SaneUILoreContinue" -- the button the key clicks (an override binding needs its name)
Keys.KEY = "SPACE"

local button
local wanted = false -- the talk shows
local bound = false

local function Set()
    local want = wanted and ns.options.space and not ns.off
    if want == bound then return end
    if InCombatLockdown() then return end
    if not button then
        button = CreateFrame("Button", Keys.BUTTON, ns.Look.Root())
        button:SetScript("OnClick", ns.Guard(function() ns.Talk.Continue() end))
    end
    if want then
        SetOverrideBindingClick(button, true, Keys.KEY, Keys.BUTTON, "LeftButton")
    else
        ClearOverrideBindings(button)
    end
    bound = want
end

function Keys.On()
    wanted = true
    Set()
end

function Keys.Off()
    wanted = false
    Set()
end

function Keys.Update()
    Set()
end

function Keys.GiveBack()
    wanted = false
    if button and bound and not InCombatLockdown() then ClearOverrideBindings(button) end
    bound = false
end
