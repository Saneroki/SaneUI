local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Links
--  The links in a message ([Strong Iron Lockbox], a spell, a quest, a player):
--  the mouse over one shows its tooltip, a click does what a click on it does
--  in the game's chat.
--
--  A frame of ours with links enabled (SetHyperlinksEnabled) is told when the
--  mouse is over a link in one of its texts; nothing else of it takes the
--  mouse, so it does not stand in the way of a click into the world.
--  The click is the game's own handling of a chat link (SetItemRef): the
--  item's window, Shift to put the link into the line you write in, a
--  player's menu, and so on.
-------------------------------------------------------------------------------
local Links = {}
ns.Links = Links

-- The kinds of link the game's tooltip can show by itself. Others (a player, a channel) only answer a click.
local SHOWN = {
    item = true, spell = true, enchant = true, quest = true, achievement = true, currency = true,
    talent = true, instancelock = true, mount = true, transmogillusion = true, transmogappearance = true,
}

local function Enter(owner, link)
    local kind = link:match("^(%a+):")
    if not SHOWN[kind] then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT", 12, 0)
    -- A link the game cannot show after all (an old item, a kind this client lacks) shows nothing.
    if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

local function Click(link, text, button)
    SetItemRef(link, text, button, DEFAULT_CHAT_FRAME)
end

-- The links in frame's texts answer the mouse.
function Links.Enable(frame)
    frame:SetHyperlinksEnabled(true)
    frame:SetScript("OnHyperlinkEnter", function(self, link) ns.Guarded(Enter, self, link) end)
    frame:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnHyperlinkClick", function(_, link, text, button) ns.Guarded(Click, link, text, button) end)
end
