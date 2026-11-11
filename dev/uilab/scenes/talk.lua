-- Lore: a talk with an innkeeper over the world, her services as big pictures over the talk, the answers beside it
-- Core and Lore from their TOCs, over a screenshot of the world. The gossip is the scene's own: the game's gossip calls
-- stand in for an innkeeper with a quest to hand in, a word to say, the hearthstone, her goods and the bank (refused
-- for now: its picture greyed, its tooltip says why); the answer given is printed in the log. No 3D in the lab: the
-- face is a dashed box. The module is LabTalk in the console: LabGossip(n) opens the talk again with the first n
-- options (LabGossip() all of them), LabGuard() a city guard's with fourteen places to ask the way to (its column lifted
-- onto the screen; SaneUI.Core.Set("Lore", "size", 150) makes it taller than the screen: the wheel and the arrows go
-- through it), LabTalk.Talk.Redraw() draws it anew.

-- The game's gossip and quest windows, closed, as Lore's Native.lua holds them (the lab loads neither).
CreateFrame("Frame", "GossipFrame", UIParent):Hide()
CreateFrame("Frame", "QuestFrame", UIParent):Hide()

-- The world under the talk, in sight while the interface fades out.
local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
world:SetIgnoreParentAlpha(true)
local ground = world:CreateTexture(nil, "BACKGROUND")
ground:SetAllPoints(world)
ground:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

local OPTIONS = {
    { name = "Make this inn your home.", icon = 132052 },                   -- the binder's: the hearthstone
    { name = "Let me browse your goods.", icon = 132060 },                  -- the vendor's
    { name = "What can I do in Goldshire?", icon = 132053 },                -- a word to say
    { name = "I would like to check my deposit box.", icon = 132050,        -- the banker's, refused for now
      status = 2, failureDescription = "The vault opens at dawn." },
    { name = "Train me.", icon = 132058 },                                  -- the trainer's
    { name = "I need a ride.", icon = 132057 },                             -- the flight master's
}
local shown = #OPTIONS
local PLACES = { "The bank", "The auction house", "The inn", "The gryphon master", "The guild master", "The mailbox",
                 "The stable master", "The weapon master", "The officers' lounge", "The battlemasters",
                 "A class trainer", "A profession trainer", "The barber", "The tram" }
local guard = false

local function Options()
    local list = {}
    if guard then
        for index, place in ipairs(PLACES) do
            list[index] = { name = place, icon = 132053, orderIndex = index, status = 0, flags = 0, rewards = {},
                            selectOptionWhenOnlyOption = false }
        end
        return list
    end
    for index = 1, shown do
        local option = OPTIONS[index]
        list[index] = { name = option.name, icon = option.icon, orderIndex = index, status = option.status or 0,
                        failureDescription = option.failureDescription, flags = 0, rewards = {},
                        selectOptionWhenOnlyOption = false }
    end
    return list
end

local ACTIVE = { { title = "Report to Goldshire", questID = 54, isComplete = true } }
C_GossipInfo = C_GossipInfo or {}
C_GossipInfo.GetText = function()
    if guard then return "How can I help you, citizen?" end
    return "Welcome to the Lion's Pride, traveller.\n\n<Farley wipes a mug.> Rooms are cheap, the ale is cold."
end
C_GossipInfo.GetOptions = Options
C_GossipInfo.GetAvailableQuests = function() return {} end
C_GossipInfo.GetActiveQuests = function() return guard and {} or ACTIVE end
C_GossipInfo.GetNumAvailableQuests = function() return 0 end
C_GossipInfo.GetNumActiveQuests = function() return guard and 0 or #ACTIVE end
C_GossipInfo.ForceGossip = function() return false end
C_GossipInfo.SelectOptionByIndex = function(index)
    print("Answered: " .. (guard and PLACES[index] or OPTIONS[index].name))
end
C_GossipInfo.SelectActiveQuest = function(id) print("Answered: the quest " .. id) end
C_GossipInfo.SelectAvailableQuest = function(id) print("Answered: the quest " .. id) end
C_GossipInfo.CloseGossip = function()
    GossipFrame:Hide()
    Lab.Fire("GOSSIP_CLOSED")
end
-- Space bound while the talk shows (Keys.lua): the lab has no key bindings.
SetOverrideBindingClick = SetOverrideBindingClick or function() end
ClearOverrideBindings = ClearOverrideBindings or function() end
local named = UnitName
UnitName = function(unit, ...)
    if unit == "npc" then return guard and "Stormwind City Guard" or "Innkeeper Farley" end
    return named(unit, ...)
end

Lab.TOC("src/Core/SaneUI.toc")
LabTalk = Lab.TOC("src/Lore/SaneUI_Lore.toc")

function LabGossip(count)
    guard = false
    shown = math.max(0, math.min(count or #OPTIONS, #OPTIONS))
    GossipFrame:Show()
    Lab.Fire("GOSSIP_SHOW")
end

function LabGuard()
    guard = true
    GossipFrame:Show()
    Lab.Fire("GOSSIP_SHOW")
end

Lab.OnLogin(function()
    C_Timer.After(0.2, function() LabGossip() end) -- the modules' logins run first
end)
