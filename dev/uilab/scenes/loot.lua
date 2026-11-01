-- Loot: the loot window over the world with a thing of every quality, a quest's item (gold), coins; click to take
-- Core and the module Loot from their TOCs; the loot is the scene's own: the game's loot functions stand in for a
-- corpse holding these slots, LootSlot takes one (LOOT_SLOT_CLEARED), the last taken closes the loot. Linen Cloth is put
-- on your list after the loot opens, to show the A lit. The module's table is LabLoot in the console:
-- LabLoot.Window.Close() closes it, LabLoot.Open() opens the loot again with every slot back. Beside it your group's
-- rolls, a line each: the last runs down and starts again, the others stand at a share of their time to show the time
-- line's colours; LabLoot.Roll() brings them back.

-- The lab hides what lies beyond a mask's rectangle, where the game's CLAMPTOWHITE shows it: here masks without a
-- picture, so the bars are seen (square at their ends; round in the game).
local create = CreateFrame
CreateFrame = function(kind, ...)
    local frame = create(kind, ...)
    local mask = frame.CreateMaskTexture
    frame.CreateMaskTexture = function(self, ...)
        local made = mask(self, ...)
        made.SetTexture = function() end
        return made
    end
    return frame
end

-- The game's own loot window and roll frames, as Loot's Game.lua finds them (the lab loads neither).
CreateFrame("Frame", "LootFrame", UIParent):RegisterEvent("LOOT_OPENED")
CreateFrame("Frame", "GroupLootContainer", UIParent)

-- The corpse: an item of each quality from the data master (Core's set Items), a quest's item, coins.
local SLOTS = {
    { item = 7073, count = 2 },              -- Broken Fang, poor
    { item = 2589, count = 4 },              -- Linen Cloth, common (trade goods)
    { item = 6411 },                         -- Chief Brigadier Armor, uncommon (binds when equipped)
    { item = 12784 },                        -- Arcanite Reaper, rare
    { item = 873 },                          -- Staff of Jordan, epic
    { item = 13262 },                        -- Ashbringer, legendary (binds when picked up)
    { item = 182, quest = true },            -- Garrick's Head, a quest's item
    { money = "17 Silver\n43 Copper" },      -- coins, as the game writes them on lines
}
local gone = {}

GetNumLootItems = function() return #SLOTS end
GetLootSlotType = function(slot)
    local s = SLOTS[slot]
    if not s or gone[slot] then return Enum.LootSlotType.None end
    return s.money and Enum.LootSlotType.Money or Enum.LootSlotType.Item
end
GetLootSlotLink = function(slot)
    local s = SLOTS[slot]
    if not s or gone[slot] or not s.item then return nil end
    local _, link = C_Item.GetItemInfo(s.item)
    return link
end
GetLootSlotInfo = function(slot)
    local s = SLOTS[slot]
    if not s or gone[slot] then return nil end
    if s.money then return 133784, s.money, 0, nil, 0, false, false, nil, false, true end
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(s.item)
    return icon, name, s.count or 1, nil, quality, false, s.quest or false, nil, false, false
end
LootSlot = function(slot)
    if not SLOTS[slot] or gone[slot] then return end
    gone[slot] = true
    Lab.Fire("LOOT_SLOT_CLEARED", slot)
end
CloseLoot = function() Lab.Fire("LOOT_CLOSED") end
IsFishingLoot = function() return false end

-- The rolls, a thing of the corpse each: share is the time left (nil: running down), need = false a Need refused;
-- the words the game would say of who chose what, on the chat's line.
local ROLL_TIME = 60
local ROLLS = {
    { item = 12784, share = 0.1 },
    { item = 873, share = 0.35, disenchant = true, need = false },
    { item = 6411, share = 0.7, chose = "Greed" },
    { item = 13262 },
}
local open = {}

GetLootRollItemInfo = function(id)
    local roll = open[id] and ROLLS[id]
    if not roll then return nil end
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(roll.item)
    return icon, name, 1, quality, false, roll.need ~= false, true, roll.disenchant or false,
        roll.need == false and 2 or 0, 0, 0, 0, false
end
GetLootRollItemLink = function(id)
    local roll = open[id] and ROLLS[id]
    return roll and select(2, C_Item.GetItemInfo(roll.item)) or nil
end
GetLootRollTimeLeft = function(id)
    local roll = open[id] and ROLLS[id]
    if not roll then return 0 end
    return roll.share and roll.share * ROLL_TIME * 1000 or (ROLL_TIME - GetTime() % ROLL_TIME) * 1000
end
GetActiveLootRollIDs = function()
    local ids = {}
    for id in pairs(open) do ids[#ids + 1] = id end
    return ids
end
RollOnLoot = function(id)
    open[id] = nil
    Lab.Fire("CANCEL_LOOT_ROLL", id)
end
C_Loot = C_Loot or {}
C_Loot.GetLootRollDuration = function() return ROLL_TIME * 1000 end

-- Money in the game's coins, as the game writes it (the lab lacks it): each kind its number and picture, none of 0.
C_CurrencyInfo = C_CurrencyInfo or {}
C_CurrencyInfo.GetCoinTextureString = function(copper)
    local parts = {}
    for _, coin in ipairs({ { 10000, "Gold" }, { 100, "Silver" }, { 1, "Copper" } }) do
        local count = math.floor(copper / coin[1])
        copper = copper % coin[1]
        if count > 0 then
            parts[#parts + 1] = ("%d|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"):format(count, coin[2])
        end
    end
    return table.concat(parts, " ")
end

-- The world behind: a screenshot of the game's (a local picture, assets/generated/ui-lab/backdrops/, not in the
-- repository; without it a magenta box: choose the backdrop dark).
local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
world:SetFrameLevel(0)
local picture = world:CreateTexture(nil, "BACKGROUND")
picture:SetAllPoints(world)
picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Loot/SaneUI_Loot.toc")
LabLoot = ns

-- The loot opened as the game opens it, every slot back; the window in the middle of the screen.
function ns.Open()
    Lab.Fire("LOOT_CLOSED")
    wipe(gone)
    ns.options.atMouse = false -- placed here, not at the lab's mouse
    -- every line on show: what is taken at once at first would not stand in the window
    ns.options.takeCoins, ns.options.takeQuest, ns.options.takeJunk = false, false, false
    ns.options.kept[2589] = nil
    Lab.Fire("LOOT_READY", false)
    Lab.Fire("LOOT_OPENED", false, false)
    ns.options.kept[2589] = true -- on your list now: its A lit
    ns.Window.Fill()
    local frame = ns.Window.frame
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("RIGHT", UIParent, "CENTER", -200, 40)
    end
end

-- The rolls open as the game opens them; who chose what, on the game's lines.
function ns.Roll()
    Lab.Fire("CANCEL_ALL_LOOT_ROLLS")
    for id, roll in ipairs(ROLLS) do
        open[id] = true
        Lab.Fire("START_LOOT_ROLL", id, ROLL_TIME * 1000)
        if roll.chose then
            Lab.Fire("CHAT_MSG_LOOT", LOOT_ROLL_GREED:format(id, "Mirabel", GetLootRollItemLink(id)))
        end
    end
end

Lab.OnLogin(function()
    if ns and ns.Open then
        ns.Open()
        ns.Roll()
    end
end)
