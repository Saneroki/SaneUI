-- Auction scan: the full scan's bar under the game's auction house window, through all its phases
-- The game's window from its own files, Core from its TOC; the game's scan calls stand in for a house of
-- LabScan.rows auctions. LabScan.Answer() in the console is the server's answer; the bar's phases then follow.
Lab.Blizzard("Blizzard_FrameXMLUtil")
Lab.Blizzard("Blizzard_AuctionHouseUI")
Lab.TOC("src/Core/SaneUI.toc")
Lab.TOC("src/AuctionData/SaneUI_AuctionData.toc")

LabScan = { rows = 48012 }
C_WowTokenPublic = setmetatable({}, { __index = function() return function() end end })
WowToken_IsWowTokenAuctionDialogShown = function() return false end

C_AuctionHouse.ReplicateItems = function() end
C_AuctionHouse.IsThrottledMessageSystemReady = function() return true end
C_AuctionHouse.GetNumReplicateItems = function() return LabScan.rows end
C_AuctionHouse.GetReplicateItemLink = function() return nil end
C_AuctionHouse.GetReplicateItemInfo = function(index)
    return "A thing", 134400, 5, 1, true, 1, "", 100, 1, 500 + index % 97, 0, nil, nil, "Seller" .. index % 40, nil, 0, 1000 + index % 400, true
end
C_Item.GetItemInfoInstant = function(item) return item, "", "", "", 134400, 7, 0 end

function LabScan.Answer() Lab.Fire("REPLICATE_ITEM_LIST_UPDATE") end

Lab.OnLogin(function()
    AuctionHouseFrame:SetScript("OnShow", nil) -- its searches need more of the server than the lab has
    AuctionHouseFrame:Show()
    Lab.Fire("AUCTION_HOUSE_SHOW")
end)
