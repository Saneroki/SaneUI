local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Reputation
--  The sheet's reputation tab, as the game's sheet has it (Camelot's
--  ReputationFrame), ours: over the left pane the factions you know
--  (C_Reputation), in the game's order and looks (Rows.lua): a header (a click
--  folds or unfolds it), a header with a standing of its own (its fold button
--  at its left), a faction with the game's coloured bar (the standing's word in
--  its colour; the progress in numbers under the mouse). A click chooses a faction,
--  lit in the game's way (brighter under the mouse, red while at war). At the
--  right the chosen faction (List.lua's side, Side.lua): its name and standing,
--  its description, its bar, and the game's three switches: at war, inactive,
--  shown on the screen.
--
--  The game's own reputation rows are wired to the game's sheet (its frame, its
--  selection event, its side pane): ours are our own, on the same API and art.
--  The choice is the game's own (C_Reputation.SetSelectedFaction), so the
--  game's sheet and ours agree on it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Reputation = {}
ns.Reputation = Reputation

-- The game's sizes (ReputationFrame.xml; the rows' are Rows.lua's): the switches at the side's foot.
-- How brightly a faction is lit (ReputationEntryMixin:RefreshBackgroundHighlightOpacity): chosen, under the mouse;
-- at war: chosen, under the mouse, else.
Reputation.LIT = { chosen = 0.20, over = 0.10 }
Reputation.WAR = { chosen = 0.85, over = 0.65, rest = 0.50 }

local list, side, checks
local factions = {} -- [faction index] = the game's data, as last listed

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Rep()
    return rawget(_G, "C_Reputation") or {}
end

local function Color(name)
    return rawget(_G, name)
end

local function Selected()
    return Core.Ask(Rep().GetSelectedFaction) or 0
end

local function Big(number)
    return Game("BreakUpLargeNumbers", number) or tostring(number)
end

-------------------------------------------------------------------------------
--  A faction's standing, as the game's bar shows it
-------------------------------------------------------------------------------
-- The bar's share, its colour, its standing's word and the progress in numbers (none at the top), by the faction's
-- kind: a friendship, a major faction (renown), or a standard one (ReputationFrame.lua's bar initializers).
local function Standing(data)
    local gossip = rawget(_G, "C_GossipInfo")
    local friend = gossip and gossip.GetFriendshipReputation and Core.Ask(gossip.GetFriendshipReputation, data.factionID)
    local colors = Color("FACTION_BAR_COLORS") or {}
    local low, high, now, word, color, capped
    if type(friend) == "table" and (friend.friendshipFactionID or 0) > 0 then
        capped = friend.nextThreshold == nil
        low, high, now = friend.reactionThreshold, friend.nextThreshold, friend.standing
        word, color = friend.reaction, colors[5] -- friendships are always green
    elseif Rep().IsMajorFaction and Core.Ask(Rep().IsMajorFaction, data.factionID) then
        local major = rawget(_G, "C_MajorFactions")
        local info = major and Core.Ask(major.GetMajorFactionData, data.factionID)
        capped = major and Core.Ask(major.HasMaximumRenown, data.factionID)
        low, high, now = 0, info and info.renownLevelThreshold or 0, info and info.renownReputationEarned or 0
        word = Core.Word("RENOWN_LEVEL_LABEL", "Renown %d"):format(info and info.renownLevel or 0)
        color = Color("BLUE_FONT_COLOR")
    else
        capped = data.reaction == (Color("MAX_REPUTATION_REACTION") or 8)
        low, high, now = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
        word = Game("GetText", "FACTION_STANDING_LABEL" .. tostring(data.reaction), UnitSex("player"))
            or Core.Word("FACTION_STANDING_LABEL" .. tostring(data.reaction), "")
        color = colors[data.reaction]
    end
    if capped then return 1, color, word, nil end
    low, high, now = low or 0, high or 0, now or 0
    local most, at = high - low, now - low
    local share = most ~= 0 and at / most or 0
    local white = Color("HIGHLIGHT_FONT_COLOR")
    local progress = Core.Word("REPUTATION_PROGRESS_FORMAT", "%s / %s"):format(Big(at), Big(most))
    if white and white.WrapTextInColorCode then progress = white:WrapTextInColorCode(progress) end
    return share, color, word, progress
end

-- A bar of the game's (ColoredProgressBarTemplate) drawn for a faction; under the mouse it shows the numbers.
local function Bar(bar, data)
    local share, color, word, progress = Standing(data)
    bar:SetFillPercent(math.max(0, math.min(1, share)))
    if color and bar.Fill then bar.Fill:SetVertexColor(color.r, color.g, color.b) end
    bar.word, bar.progress = word or "", progress
    bar:SetText(bar.word)
    return word
end

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local function Kind(data)
    if data.isHeader and not data.isHeaderWithRep then return "header" end
    if data.isHeaderWithRep then return "subheader" end
    return "entry"
end

local function Extent(data)
    return ns.Rows.Height(Kind(data))
end

-- How brightly a faction's row is lit now, and in which colour (red while at war).
local function Light(row)
    local data = row.data
    if not data or Kind(data) == "header" then return end
    local chosen, over, war = Selected() == data.factionIndex, row:IsMouseOver(), data.atWarWith
    local alpha
    if war then
        alpha = (chosen and Reputation.WAR.chosen) or (over and Reputation.WAR.over) or Reputation.WAR.rest
    else
        alpha = (chosen and Reputation.LIT.chosen) or (over and Reputation.LIT.over) or 0
    end
    ns.Rows.Light(row, alpha, war and Color("FACTION_AT_WAR_COLOR") or nil)
end

-- A header (or a header with a standing, by its button) folds or unfolds, by the game's own call.
local function Fold(row)
    local data = row.data
    if not data then return end
    if data.isCollapsed then
        Core.Ask(Rep().ExpandFactionHeader, data.factionIndex)
    else
        Core.Ask(Rep().CollapseFactionHeader, data.factionIndex)
    end
end

-- A faction (or a header with a standing) chosen, by the game's own call.
local function Choose(row)
    local data = row.data
    if not data then return end
    Core.Ask(Rep().SetSelectedFaction, data.factionIndex or 0)
    ns.List.Redraw(list)
    Reputation.Detail()
end

local function Entered(row)
    if row.data and Kind(row.data) ~= "header" and row.bar.progress then row.bar:SetText(row.bar.progress) end
    Light(row)
end

local function Left(row)
    if row.data and Kind(row.data) ~= "header" then row.bar:SetText(row.bar.word or "") end
    Light(row)
end

local OWNER = { click = Choose, fold = Fold, enter = Entered, leave = Left }

local function Draw(row, data)
    row.data = data
    local kind = Kind(data)
    ns.Rows.Draw(row, kind, data.name, data.isCollapsed, OWNER)
    if kind == "header" then return end
    Bar(row.bar, data)
    Light(row)
end

-------------------------------------------------------------------------------
--  The chosen faction, at the right
-------------------------------------------------------------------------------
local function War(box)
    Core.Ask(Rep().ToggleFactionAtWar, Selected())
    ns.Side.Sound(box)
    Reputation.Refresh()
end

local function Inactive(box)
    Core.Ask(Rep().SetFactionActive, Selected(), not box:GetChecked())
    ns.Side.Sound(box)
    Reputation.Refresh()
end

local function Watch(box)
    Core.Ask(Rep().SetWatchedFactionByIndex, box:GetChecked() and Selected() or 0)
    ns.Side.Sound(box)
end

-- The pane at the right: the chosen faction, or a word to choose one (ReputationDetailFrameMixin:Refresh).
function Reputation.Detail()
    if not side then return end
    local index = Selected()
    local data = index > 0 and Core.Ask(Rep().GetFactionDataByIndex, index)
    if type(data) ~= "table" or (data.factionID or 0) <= 0 then
        ns.Side.Empty(side, Core.Word("REPUTATION_DETAIL_SELECT_PROMPT", "Select a faction to see more about it."))
        side.bar:Hide()
        for _, box in ipairs(checks) do box:Hide() end
        return
    end
    ns.Side.Empty(side, nil)
    side.bar:Show()
    local word = Bar(side.bar, data)
    if side.bar.progress then side.bar:SetText(side.bar.progress) else side.bar:SetText("") end
    ns.Side.Title(side, data.name, word, Color("CHARACTER_FRAME_SIDE_PANEL_REPUTATION_COLOR"), Color("WHITE_FONT_COLOR"))
    ns.Side.Describe(side, data.description, Color("REPUTATION_DETAIL_DESCRIPTION_HEIGHT"))
    ns.Side.Rows(side)
    if Rep().IsAccountWideReputation and Core.Ask(Rep().IsAccountWideReputation, data.factionID) then
        ns.Side.Line(side, Core.Word("REPUTATION_TOOLTIP_ACCOUNT_WIDE_LABEL", ""), Color("GREEN_FONT_COLOR"))
    end
    local war, inactive, watch = checks[1], checks[2], checks[3]
    local canWar = data.canToggleAtWar and not data.isHeader
    war:SetEnabled(canWar and true or false)
    war:SetChecked(data.atWarWith and true or false)
    local warColor = canWar and Color("RED_FONT_COLOR") or Color("GRAY_FONT_COLOR")
    if warColor then war.label:SetTextColor(warColor.r, warColor.g, warColor.b) end
    inactive:SetEnabled(data.canSetInactive and true or false)
    inactive:SetChecked(not Core.Ask(Rep().IsFactionActive, index))
    local inactiveColor = data.canSetInactive and Color("NORMAL_FONT_COLOR") or Color("GRAY_FONT_COLOR")
    if inactiveColor then inactive.label:SetTextColor(inactiveColor.r, inactiveColor.g, inactiveColor.b) end
    watch:SetChecked(data.isWatched and true or false)
    for _, box in ipairs(checks) do box:Show() end
end

-------------------------------------------------------------------------------
--  The tab
-------------------------------------------------------------------------------
-- The game's first choice when there is none: the first faction that can be chosen.
local function First()
    if Selected() > 0 then return end
    for index, data in ipairs(factions) do
        if Kind(data) ~= "header" then
            Core.Ask(Rep().SetSelectedFaction, data.factionIndex or index)
            return
        end
    end
end

-- The list as the game has the factions now, and the chosen one at the right.
function Reputation.Refresh()
    if not list then return end
    local elements = {}
    factions = {}
    for index = 1, Core.Ask(Rep().GetNumFactions) or 0 do
        local data = Core.Ask(Rep().GetFactionDataByIndex, index)
        if type(data) == "table" then
            data.factionIndex = index
            elements[#elements + 1] = data
            factions[#factions + 1] = data
        end
    end
    First()
    ns.List.Fill(list, elements)
    Reputation.Detail()
end

local function Build(left, right)
    list = ns.List.New(left, { extent = Extent, draw = Draw })
    side = ns.Side.New(right, ns.Side.Foot(3))
    side.bar = CreateFrame("Frame", nil, side.content, "ColoredProgressBarTemplate")
    side.bar:SetSize(ns.Rows.SIDE_BAR, ns.Rows.BAR_HEIGHT)
    side.bar:SetPoint("TOP", side.divider, "BOTTOM", 0, -6)
    side.description:ClearAllPoints()
    side.description:SetPoint("TOP", side.bar, "BOTTOM", 0, -6)
    side.description:SetPoint("LEFT")
    side.description:SetPoint("RIGHT", -14, 0)
    local war = ns.Side.Check(side.foot, Core.Word("AT_WAR", "At War"), Core.Word("REPUTATION_AT_WAR_DESCRIPTION", ""),
        "Interface\\Buttons\\UI-CheckBox-SwordCheck", War)
    war:SetPoint("TOPLEFT", side.foot, "TOPLEFT", -4, 0)
    local inactive = ns.Side.Check(side.foot, Core.Word("MOVE_TO_INACTIVE", "Move to Inactive"),
        Core.Word("REPUTATION_MOVE_TO_INACTIVE", ""), nil, Inactive)
    inactive:SetPoint("TOPLEFT", war, "BOTTOMLEFT", 0, -ns.Side.CHECK_GAP)
    local watch = ns.Side.Check(side.foot, Core.Word("SHOW_FACTION_ON_MAINSCREEN", "Show as Experience Bar"),
        Core.Word("REPUTATION_SHOW_AS_XP", ""), nil, Watch)
    watch:SetPoint("TOPLEFT", inactive, "BOTTOMLEFT", 0, -ns.Side.CHECK_GAP)
    checks = { war, inactive, watch }
end

local later = Core.Later(function() ns.Safe("character", Reputation.Refresh) end)
local EVENTS = { "UPDATE_FACTION", "QUEST_LOG_UPDATE", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "MAJOR_FACTION_UNLOCKED" }

local function Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if on then Reputation.Refresh() end
end

ns.Sheet.Tab({
    key = "reputation", icon = "Interface/ICONS/INV_SideTab_Reputation2_c60",
    tip = Core.Word("CHARACTER_FRAME_TAB_REPUTATION", "Reputation"), title = Core.Word("REPUTATION", "Reputation"),
    Build = Build, Show = Show,
})
