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
--  player's menu, and so on. But only where that opens none of the game's
--  panels: shown from our code, a panel runs the game's panel manager tainted
--  (Doc/guides/addon-standards.md, section 5). So a click on a kind the game
--  answers with its link tooltip, a menu or a whisper, with no key held or the
--  one that puts a link into the line; nothing for any other key (the dressing
--  room's) or kind.
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

-- The kinds whose click the game answers without one of its panels (its SetItemRef handlers: the link tooltip, a
-- floating pet tooltip, a player's menu or a whisper, a channel's line to write in or its menu).
local CLICKED = {
    player = true, playerCommunity = true, BNplayer = true, BNplayerCommunity = true, channel = true,
    item = true, spell = true, enchant = true, talent = true, quest = true, currency = true, achievement = true,
    instancelock = true, battlepet = true, battlePetAbil = true,
}

local function Click(link, text, button)
    local kind = link:match("^(%a+):")
    if not CLICKED[kind] then return end
    -- The dressing room and an item's own window are panels; on a channel the link key opens the game's list of
    -- channels. Any other key held: nothing.
    if IsModifiedClick("DRESSUP") or IsModifiedClick("EXPANDITEM") then return end
    local held = rawget(_G, "IsModifierKeyDown")
    local down = held and held() or false
    if down and (kind == "channel" or not IsModifiedClick("CHATLINK")) then return end
    -- A kind the game answers with its link tooltip: in a fight it refuses that window to our code ("Interface action
    -- failed"), and the tooltip on the mouse shows the link already.
    if not down and SHOWN[kind] and InCombatLockdown() then return end
    SetItemRef(link, text, button, DEFAULT_CHAT_FRAME)
end

-- The links in frame's texts answer the mouse.
function Links.Enable(frame)
    frame:SetHyperlinksEnabled(true)
    frame:SetScript("OnHyperlinkEnter", function(self, link) ns.Guarded(Enter, self, link) end)
    frame:SetScript("OnHyperlinkLeave", ns.Guard(function() GameTooltip:Hide() end))
    -- A click is a step of its own (Safe): a link the game's handling fails on is noted, the window stays.
    frame:SetScript("OnHyperlinkClick", function(_, link, text, button) ns.Safe("link", Click, link, text, button) end)
end
