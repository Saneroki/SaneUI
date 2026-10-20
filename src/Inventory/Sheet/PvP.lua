local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - PvP
--  The sheet's PvP tab, as the game's sheet has it (Camelot's PVPRankFrame),
--  ours: the season's rank, kept by the game as the renown of its PvP rank
--  (C_MajorFactions, PvP.FACTION). Over the left pane: the season, your rank's
--  number and title, the game's rank ring (a Cooldown showing how far you are
--  toward the next rank, the rank's badge in its middle, your rank on its foot),
--  your points toward the next rank, and at the top the time left of the season,
--  counted down each second while the tab shows. At the right (Side.lua): the
--  rank's title and number, the season's description, your progress in it,
--  this week's higher cap, the next rank that brings a reward and what it gives,
--  and the vendor of the rewards.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local PvP = {}
ns.PvP = PvP

-- The game's numbers (PVPRankFrame.lua, .xml): the rank's renown faction, the season's description height, the
-- places and sizes of the main part, the ring and its parts.
PvP.FACTION = 2800
PvP.DESCRIPTION = 60
PvP.TIMER_X, PvP.TIMER_Y = -46, -18
PvP.MAIN_TOP = 60
PvP.RING, PvP.RING_Y = 154, -95
PvP.GLOW = { 275, 295 }
PvP.BAR = { 235, 209 }
PvP.BADGE = { 72, 84 }
PvP.REWARD = 36
PvP.PROGRESS_Y = -210

local main, timer, season, rank, progress, ring, side
local ticker
local formatter

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Majors()
    return rawget(_G, "C_MajorFactions") or {}
end

local function Horde()
    return UnitFactionGroup("player") == "Horde"
end

-- A rank's title, as the game words it: Unranked, or the faction's title for that rank in the character's gender.
local function Title(level)
    if not level or level <= 0 then return Core.Word("PVP_RANK_0_NAME", "Unranked") end
    local ranks = Enum and Enum.PvPRanks
    local first = ranks and ranks.Rank_1 or 5
    local key = "PVP_RANK_" .. tostring(first + level - 1) .. "_" .. (Horde() and "0" or "1")
    return Game("GetText", key, UnitSex("player")) or Core.Word(key, tostring(level))
end

-- The time left of the season, in the game's words (its seconds formatter: two units, days once more than one).
local function Countdown()
    local seasons = rawget(_G, "C_SeasonInfo")
    local left = seasons and seasons.GetTimeUntilCurrentPVPSeasonEnd and Core.Ask(seasons.GetTimeUntilCurrentPVPSeasonEnd) or 0
    if left <= 0 or not rawget(_G, "SecondsFormatterMixin") then return timer:Hide() end
    if not formatter then
        formatter = CreateFromMixins(SecondsFormatterMixin)
        formatter:Init(SecondsFormatterConstants.ZeroApproximationThreshold, SecondsFormatter.Abbreviation.None,
            SecondsFormatterConstants.DontRoundUpLastUnit, SecondsFormatterConstants.DontConvertToLower)
        formatter:SetDesiredUnitCount(2)
    end
    local intervals = SecondsFormatter.Interval
    formatter:SetMinInterval(left > (rawget(_G, "SECONDS_PER_DAY") or 86400) and intervals.Days or intervals.Seconds)
    timer:SetText(Core.Word("SEASON_ENDS_IN_TIME", "Season ends in %s"):format(formatter:Format(left)))
    timer:Show()
end

-- The ring: its share toward the next rank, the rank's badge (the faction's own while unranked), the rank number.
local function Ring(info)
    local level, points, threshold = info.renownLevel or 0, info.renownReputationEarned or 0, info.renownLevelThreshold or 0
    if level == 0 then
        ring.badge:SetAtlas(Horde() and "UI-Character-Info-Honor-Icon-Horde" or "UI-Character-Info-Honor-Icon-Alliance", true)
    else
        ring.badge:SetAtlas(("UI-Character-Info-Honor-Icon-%d"):format(level), true)
    end
    local share = threshold > 0 and points / threshold or 1
    Game("CooldownFrame_SetDisplayAsPercentage", ring, share)
    ring.level:SetText(level)
end

-- The pane at the right (PVPRankDetailFrameMixin:Refresh).
local function Detail(info)
    if not info then
        ns.Side.Empty(side, Core.Word("PVP_RANK_DETAIL_UNAVAILABLE", "Your rank cannot be shown right now."))
        return
    end
    ns.Side.Empty(side, nil)
    local level, points = info.renownLevel or 0, info.renownReputationEarned or 0
    local function Total(at) return Core.Ask(Majors().GetTotalReputationForRenownLevel, PvP.FACTION, at) or 0 end
    local weekMax, lastWeekMax, seasonMax = info.currentWeekProgressiveMaxLevel or 0, info.previousWeekProgressiveMaxLevel or 0, info.maxLevel or 0
    local weekTotal, seasonTotal = Total(weekMax), Total(seasonMax)
    local raised = weekTotal - Total(lastWeekMax)
    local mine = Total(level) + points
    local number = level > 0 and Core.Word("PVP_RANK_NUMBER", "Rank %d"):format(level) or nil
    ns.Side.Title(side, Title(level), number, rawget(_G, "CHARACTER_FRAME_SIDE_PANEL_PVP_COLOR"), rawget(_G, "WHITE_FONT_COLOR"))
    ns.Side.Describe(side, Core.Word("PVP_RANK_SEASON_RANKUP_DESCRIPTION", "%d points reach rank %d this season.")
        :format(seasonTotal, seasonMax), PvP.DESCRIPTION)
    ns.Side.Rows(side)
    local white, normal = rawget(_G, "HIGHLIGHT_FONT_COLOR"), rawget(_G, "NORMAL_FONT_COLOR")
    if mine > 0 and weekTotal == 0 then
        ns.Side.Line(side, Core.Word("PVP_RANK_SEASON_PROGRESS_NO_MAX", "Season progress: %d"):format(mine), white)
    elseif mine > 0 then
        ns.Side.Line(side, Core.Word("PVP_RANK_SEASON_PROGRESS", "Season progress: %d / %d"):format(mine, weekTotal), white)
    end
    if raised > 0 then
        ns.Side.Spacer(side, 4)
        ns.Side.Line(side, Core.Word("PVP_RANK_WEEKLY_CAP_INCREASE", "This week the cap rose by %d."):format(raised), normal)
    end
    -- The next rank that brings a reward, and what it gives.
    for next = level + 1, seasonMax do
        local rewards = Core.Ask(Majors().GetRenownRewardsForLevel, PvP.FACTION, next)
        if type(rewards) == "table" and #rewards > 0 then
            ns.Side.Spacer(side, 8)
            ns.Side.Category(side, Core.Word("PVP_RANK_NEXT_REWARD", "Rank %d"):format(next))
            local added = false
            for _, reward in ipairs(rewards) do
                if reward.description then
                    if added then ns.Side.Spacer(side, 4) end
                    ns.Side.Icon(side, reward.icon, reward.description, normal)
                    added = true
                end
            end
            ns.Side.Spacer(side, 6)
            ns.Side.Line(side, Core.Word(Horde() and "PVP_RANK_REWARDS_VENDOR_HORDE" or "PVP_RANK_REWARDS_VENDOR_ALLIANCE", ""), normal)
            break
        end
    end
end

-- Everything as the game has it now (PVPRankFrameMixin:Update).
function PvP.Refresh()
    if not main then return end
    local info = Core.Ask(Majors().GetMajorFactionProgressionInfo, PvP.FACTION)
    Countdown()
    if type(info) == "table" then
        local now = Core.Ask(rawget(_G, "GetCurrentArenaSeason")) or 0
        season:SetText(Core.Word("EXPANSION_SEASON_NAME", "%sSeason %d"):format("", now))
        season:SetShown(now > 0)
        local level = info.renownLevel or 0
        if level == 0 then
            rank:SetText(Core.Word("PVP_RANK_0_NAME", "Unranked"))
        else
            rank:SetText(Core.Word("PVP_RANK_NUMBER_AND_TITLE", "Rank %d: %s"):format(level, Title(level)))
        end
        Ring(info)
        progress:SetText(Core.Word("PVP_RANK_CURRENT_PROGRESS", "%d / %d"):format(info.renownReputationEarned or 0, info.renownLevelThreshold or 0))
        main:Show()
    else
        info = nil
        main:Hide()
    end
    Detail(info)
end

-- The ring, the game's (RankProgressBarDisplay): a paused Cooldown whose swipe shows the share, its glow and
-- the faction's background, the honour bar, the badge, and the rank's ring at its foot.
local function BuildRing(parent)
    ring = CreateFrame("Cooldown", nil, parent)
    ring:SetSize(PvP.RING, PvP.RING)
    ring:SetPoint("TOP", 0, PvP.RING_Y)
    ring:SetReverse(true)
    ring:SetHideCountdownNumbers(true)
    if ring.SetRotation then ring:SetRotation(math.pi) end
    ring:SetSwipeTexture("Interface\\PVPFrame\\pvpqueue-sidebar-honorbar-fill")
    ring:Pause()
    local glow = ring:CreateTexture(nil, "BACKGROUND")
    glow:SetAtlas("UI-Character-Info-Honor-Bar-BG-Glow")
    glow:SetSize(PvP.GLOW[1], PvP.GLOW[2])
    glow:SetPoint("CENTER")
    local back = ring:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas(Horde() and "UI-Character-Info-Honor-Bar-BG-Horde" or "UI-Character-Info-Honor-Bar-BG-Alliance", true)
    back:SetPoint("CENTER")
    local bar = ring:CreateTexture(nil, "BORDER")
    bar:SetAtlas("UI-Character-Info-Honor-Bar")
    bar:SetSize(PvP.BAR[1], PvP.BAR[2])
    bar:SetPoint("CENTER", 0, -1)
    ring.badge = ring:CreateTexture(nil, "ARTWORK")
    ring.badge:SetSize(PvP.BADGE[1], PvP.BADGE[2])
    ring.badge:SetPoint("CENTER")
    local foot = CreateFrame("Frame", nil, ring)
    foot:SetSize(PvP.REWARD, PvP.REWARD)
    foot:SetPoint("BOTTOM", 0, -1)
    local cover = foot:CreateTexture(nil, "BACKGROUND", nil, -1)
    cover:SetColorTexture(0.1, 0.1, 0.1, 1)
    cover:SetAllPoints()
    local circle = foot:CreateMaskTexture()
    circle:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    circle:SetAllPoints()
    cover:AddMaskTexture(circle)
    local border = foot:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("UI-Character-Info-Honor-RewardRing")
    border:SetAllPoints()
    ring.level = foot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ring.level:SetPoint("CENTER")
    ring.level:SetJustifyH("CENTER")
end

local function Build(left, right)
    timer = left:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    timer:SetJustifyH("RIGHT")
    timer:SetPoint("TOPRIGHT", left, "TOPRIGHT", PvP.TIMER_X, PvP.TIMER_Y)
    main = CreateFrame("Frame", nil, left)
    main:SetPoint("TOPLEFT", left, "TOPLEFT", 0, -PvP.MAIN_TOP)
    main:SetPoint("TOPRIGHT", left, "TOPRIGHT", 0, -PvP.MAIN_TOP)
    main:SetHeight(1)
    season = main:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    season:SetPoint("TOP", 0, -20)
    rank = main:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    rank:SetPoint("TOP", season, "BOTTOM", 0, -10)
    local line = main:CreateTexture(nil, "ARTWORK")
    line:SetAtlas("UI-Character-Info-Honor-LevelBG", true)
    line:SetPoint("BOTTOM", rank, "BOTTOM", 0, -10)
    progress = main:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    progress:SetPoint("TOP", rank, "BOTTOM", 0, PvP.PROGRESS_Y)
    BuildRing(main)
    side = ns.Side.New(right)
end

local function Tick()
    Countdown()
end

local later = Core.Later(function() ns.Safe("character", PvP.Refresh) end)
local EVENTS = { "UPDATE_FACTION", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" }

-- Shown: the game listened to, the season counted down each second; hidden: neither.
local function Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    if on then
        ticker = C_Timer.NewTicker(1, function() ns.Safe("character", Tick) end)
        PvP.Refresh()
    end
end

-- The tab's icon: the faction's honour.
ns.Sheet.Tab({
    key = "pvp", tip = Core.Word("CHARACTER_FRAME_TAB_PVP", "PvP"), title = Core.Word("PVP", "PvP"),
    icon = function()
        return Horde() and "Interface/ICONS/INV_SideTab_Honor_Horde_c60" or "Interface/ICONS/INV_SideTab_Honor_Alliance_c60"
    end,
    Build = Build, Show = Show,
})
