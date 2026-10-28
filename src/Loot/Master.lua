local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Master
--  While you are your group's master looter, a thing of the group's quality
--  or better is yours to give, not to take: a click on its line opens a menu
--  beside it (the game's menu, MenuUtil) with the thing's name, everybody the
--  game says may have it (GetMasterLootCandidate: in a raid under their
--  class, in a party one under another, each in their class's colour), and a
--  roll for it asked of the group (DoMasterLootRoll). A name chosen, the game's
--  yes or no (Core.Confirm), then the thing is given (GiveMasterLoot).
--
--      Master.Gives(line)       -- whether this thing is yours to give
--      Master.Open(row, line)   -- the menu beside a line of the loot window
--      Master.Close()           -- the menu closed (the loot closed)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Master = {}
ns.Master = Master

local MOST = 40 -- the most members a group can have (MAX_RAID_MEMBERS)
local menu

-- Whether you are the master looter of your group now.
local function Mastering()
    local party = rawget(_G, "C_PartyInfo")
    local method, partyID, raidID
    if party and party.GetLootMethod then
        method, partyID, raidID = Core.Ask(party.GetLootMethod)
    end
    local methods = rawget(_G, "Enum") and Enum.LootMethod
    if not (methods and method == methods.Masterlooter) then return false end
    if partyID == 0 then return true end
    if raidID then return Core.Ask(UnitIsUnit, "raid" .. raidID, "player") == true end
    return false
end

-- Everybody who may have the thing: { index, name, class (its name), token (its key) }.
local function Candidates(slot)
    local list = {}
    local candidate = rawget(_G, "GetMasterLootCandidate")
    if type(candidate) ~= "function" then return list end
    for index = 1, MOST do
        local name, class, token = Core.Ask(candidate, slot, index)
        if name then list[#list + 1] = { index = index, name = name, class = class or "", token = token } end
    end
    table.sort(list, function(a, b)
        if a.class ~= b.class then return a.class < b.class end
        return a.name < b.name
    end)
    return list
end

function Master.Gives(line)
    if not line or line.kind ~= "item" then return false end
    local threshold = Core.Ask(rawget(_G, "GetLootThreshold"))
    if not threshold or line.quality < threshold then return false end
    return Mastering() and #Candidates(line.slot) > 0
end

local function Give(line, candidate)
    local text = ("%s\n\n%s"):format(line.link or line.name, candidate.name)
    Core.Confirm(text, nil, function() GiveMasterLoot(line.slot, candidate.index) end)
end

-- A name in its class's colour, on a line of the menu.
local function Colour(button, token)
    local colors = rawget(_G, "RAID_CLASS_COLORS")
    local color = colors and token and colors[token]
    if color and button.fontString then button.fontString:SetTextColor(color.r, color.g, color.b) end
end

function Master.Open(row, line)
    local list = Candidates(line.slot)
    if #list == 0 then return end
    local raid = Core.Ask(IsInRaid) == true
    menu = MenuUtil.CreateContextMenu(row, ns.Guard(function(_, root)
        root:CreateTitle(line.name)
        local under, class = root, nil
        local give = root:CreateButton(ns.TEXT.give)
        for _, candidate in ipairs(list) do
            if raid and candidate.class ~= class then
                class = candidate.class
                under = give:CreateButton(class)
                local token = candidate.token
                under:AddInitializer(function(button) ns.Safe("master", Colour, button, token) end)
            elseif not raid then
                under = give
            end
            local entry = under:CreateButton(candidate.name, function() ns.Safe("master", Give, line, candidate) end)
            entry:AddInitializer(function(button) ns.Safe("master", Colour, button, candidate.token) end)
        end
        local roll = root:CreateButton(ns.TEXT.rollFor, function() ns.Safe("master", DoMasterLootRoll, line.slot) end)
        roll:SetTooltip(function(tooltip) ns.Safe("master", GameTooltip_AddNormalLine, tooltip, ns.TEXT.rollForTip) end)
    end))
end

-- The menu goes with the loot (the thing may be gone); one closed already is left alone.
function Master.Close()
    local open = menu
    menu = nil
    if open and open.Close and open.IsShown and open:IsShown() then ns.Safe("master", open.Close, open) end
end
