local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Rewards
--  Which reward to take where a quest offers a choice (Saneroki, 2026-10-30;
--  the switch Choose quest rewards): the biggest upgrade for your gear
--  (Core.Upgrade: the most item levels it brings), else the reward your guide's
--  step names, else the one worth the most: what a vendor pays for all of it,
--  or what the auction house brings after its cut where the thing can go there
--  (it does not bind when picked up, and you saw a price for it: the module
--  Tooltips keeps those).
--
--      Rewards.Best(named, choices)   the number of the reward to take; nil: nothing to go by, the choice is yours;
--                                     false: the game does not know them all yet, ask again in a moment
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Rewards = {}
ns.Rewards = Rewards

Rewards.CUT = 0.95    -- what a sale at the auction house leaves after the house's cut
local PICKED_UP = 1   -- the game's word for binding when picked up (Enum.ItemBind)

-- What you last saw the item go for at the auction house, if the module Tooltips kept a price.
local function Seen(id)
    local store = Core.Store("Tooltips")
    local prices = type(store) == "table" and store.prices
    local price = type(prices) == "table" and prices[id]
    return type(price) == "number" and price or 0
end

-- What one reward is worth, all of it; nil while the game does not know the item yet.
local function Worth(link, id, count)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" then return nil end
    local ok, name, _, _, _, _, _, _, _, _, _, vendor, _, _, bind = pcall(info, link)
    if not ok or not Plain(name) then return nil end
    local each = Plain(vendor) or 0
    if Plain(bind) ~= PICKED_UP then each = math.max(each, Seen(id) * Rewards.CUT) end
    return each * (count or 1)
end

function Rewards.Best(named, choices)
    local biggest, gain, richest, most = nil, 0, nil, 0
    for index = 1, choices do
        local link = Plain(Core.Ask(rawget(_G, "GetQuestItemLink"), "choice", index))
        if type(link) == "string" then
            local _, _, count = Core.Ask(rawget(_G, "GetQuestItemInfo"), "choice", index)
            local id = tonumber(link:match("item:(%d+)"))
            local worth = Worth(link, id, Plain(count))
            if worth == nil then return false end
            local _, levels = Core.Upgrade(link, id)
            if levels and levels > gain then biggest, gain = index, levels end
            if worth > most then richest, most = index, worth end
        end
    end
    if biggest then return biggest end
    if type(named) == "number" and named >= 1 and named <= choices then return named end
    return richest
end
