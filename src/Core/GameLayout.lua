local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - GameLayout
--  SaneUI's layout of the game's Edit Mode (Saneroki, 2026-11-18: "set those
--  to permanent defaults as a 'SaneUI' edit mode layout"): where the game's own
--  frames stand with SaneUI, as he arranged them on his main character in WoW:
--  Forever: the action bars in four rows at the bottom middle (y 2, 47, 92,
--  137, each 12 buttons, no bar art), the minimap at the top right, the chat,
--  the micro menu at the right edge, the buffs beside the minimap, and so on;
--  the game's unit frames, party and raid frames where they stand when SaneUI
--  Combat's are off. SaneUI's own windows have first places of their own, the
--  same arrangement (each module's: Combat's frames over the bars, the party
--  and raid frame in the lower right corner, Social's chat at the bottom left,
--  the map at the top right, the quest log at the top left).
--
--  It is an account layout named SaneUI in the game's list, built as Edit Mode
--  copies a preset: the game's first preset (Modern) with each system of the
--  list over it, by the game's own enum words (Enum.EditModeSystem, its
--  SystemIndices and Settings), never a layout's text, which differs by game
--  and version: what this game lacks is left as the preset has it. Made once
--  for an account (kept: made), out of a fight, after the game has read its
--  layouts (EDIT_MODE_LAYOUTS_UPDATED); one of that name already there is left
--  as it is, one the player deleted is not made again. It is the layout in use
--  on a character that was on one of the game's presets and has not had it
--  yet (kept per character: set): a new player starts with it, a player with a
--  layout of their own keeps theirs and finds SaneUI in Edit Mode's list.
--  Writing the game's layouts acts on the player's own game: asked for by
--  Saneroki for every player (CLAUDE.md, For every player).
--
--      Core.GameLayout.NAME          its name in the game's list
--      Core.GameLayout.SYSTEMS       the systems over the preset: { system, index, point, to, toPoint, x, y, settings }
--      Core.GameLayout.Make()        made now (and in use where the character is on a preset); false where it cannot be
-------------------------------------------------------------------------------
local GameLayout = {}
Core.GameLayout = GameLayout

GameLayout.NAME = "SaneUI"
GameLayout.SYSTEMS = {
    { system = "ActionBar", index = "MainBar", point = "BOTTOM", x = 0, y = 2, settings = { AlwaysShowButtons = 1, HideBarArt = 1, HideBarScrolling = 0, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0 } },
    { system = "ActionBar", index = "Bar2", settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0, VisibleSetting = 0 } },
    { system = "ActionBar", index = "Bar3", settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0, VisibleSetting = 0 } },
    { system = "ActionBar", index = "RightBar1", settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 1, VisibleSetting = 0 } },
    { system = "ActionBar", index = "RightBar2", settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 1, VisibleSetting = 0 } },
    { system = "ActionBar", index = "ExtraBar1", point = "BOTTOM", x = 0, y = 137, settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0, VisibleSetting = 0 } },
    { system = "ActionBar", index = "ExtraBar2", point = "BOTTOM", x = 0, y = 92, settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0, VisibleSetting = 0 } },
    { system = "ActionBar", index = "ExtraBar3", point = "BOTTOMRIGHT", to = "MainActionBar", toPoint = "TOPRIGHT", x = 0, y = 4, settings = { AlwaysShowButtons = 1, IconPadding = 2, IconSize = 5, NumIcons = 12, NumRows = 1, Orientation = 0, VisibleSetting = 0 } },
    { system = "ActionBar", index = "StanceBar", point = "BOTTOMRIGHT", to = "MultiBar6", toPoint = "BOTTOMLEFT", x = -4, y = 0, settings = { IconPadding = 2, IconSize = 5, NumRows = 1, Orientation = 0 } },
    { system = "ActionBar", index = "PetActionBar", point = "CENTER", x = -279, y = -254.5, settings = { AlwaysShowButtons = 0, IconPadding = 2, IconSize = 5, NumRows = 1, Orientation = 0 } },
    { system = "ActionBar", index = "PossessActionBar", point = "BOTTOM", toPoint = "BOTTOMLEFT", x = 716, y = 312, settings = { IconPadding = 2, IconSize = 5, NumRows = 1, Orientation = 0 } },
    { system = "CastBar", point = "CENTER", x = 0, y = -228, settings = { BarSize = 0, LockToPlayerFrame = 0, ShowCastTime = 0 } },
    { system = "Minimap", point = "TOP", x = 821.5, y = -2, settings = { HeaderUnderneath = 0, IconScale = 5, RotateMinimap = 0, Size = 5 } },
    { system = "UnitFrame", index = "Player", point = "CENTER", x = 0, y = -316.5, settings = { CastBarUnderneath = 0, FrameSize = 0 } },
    { system = "UnitFrame", index = "Target", settings = { BuffsOnTop = 0, FrameSize = 0 } },
    { system = "UnitFrame", index = "Focus", settings = { BuffsOnTop = 0, FrameSize = 0, UseLargerFrame = 0 } },
    { system = "UnitFrame", index = "Party", settings = { AuraOrganizationType = 0, BigDefensiveIconSize = 5, BuffIconSize = 5, DebuffIconSize = 5, DisplayBorder = 0, FrameHeight = 8, FrameSize = 0, FrameWidth = 26, Opacity = 100, ShowPartyFrameBackground = 0, SortPlayersBy = 1, UseHorizontalGroups = 0, UseRaidStylePartyFrames = 0 } },
    { system = "UnitFrame", index = "Raid", settings = { AuraOrganizationType = 0, BigDefensiveIconSize = 5, BuffIconSize = 5, DebuffIconSize = 5, DisplayBorder = 0, FrameHeight = 8, FrameSize = 0, FrameWidth = 26, Opacity = 100, RaidGroupDisplayType = 0, RowSize = 5, SortPlayersBy = 0, ViewRaidSize = 0 } },
    { system = "UnitFrame", index = "Boss", point = "TOPRIGHT", x = -2, y = -329, settings = { CastBarOnSide = 1, FrameSize = 0, UseLargerFrame = 0 } },
    { system = "UnitFrame", index = "Arena", point = "TOPRIGHT", x = -2, y = -280.5, settings = { AuraOrganizationType = 0, BigDefensiveIconSize = 5, BuffIconSize = 5, DebuffIconSize = 5, DisplayBorder = 0, FrameHeight = 8, FrameWidth = 26, Opacity = 100, ViewArenaSize = 1 } },
    { system = "UnitFrame", index = "Pet", settings = { FrameSize = 0 } },
    { system = "EncounterBar", point = "TOPLEFT", x = 1917, y = -644 },
    { system = "ExtraAbilities", point = "BOTTOM", toPoint = "BOTTOMLEFT", x = 716, y = 352 },
    { system = "AuraFrame", index = "BuffFrame", point = "TOPRIGHT", to = "MinimapCluster", toPoint = "TOPLEFT", x = 11, y = 0, settings = { IconDirection = 0, IconLimitBuffFrame = 11, IconPadding = 5, IconSize = 5, IconWrap = 0, Orientation = 0 } },
    { system = "AuraFrame", index = "DebuffFrame", point = "TOPRIGHT", to = "BuffFrame", toPoint = "BOTTOMRIGHT", x = -15, y = -4, settings = { IconDirection = 0, IconLimitDebuffFrame = 8, IconPadding = 5, IconSize = 5, IconWrap = 0, Orientation = 0, ShowDispelType = 1 } },
    { system = "AuraFrame", index = "ExternalDefensivesFrame", settings = { IconDirection = 1, IconLimitBuffFrame = 11, IconPadding = 5, IconSize = 5, IconWrap = 0, Opacity = 100, Orientation = 0, VisibleSetting = 0 } },
    { system = "TalkingHeadFrame", point = "CENTER", x = 0, y = -173 },
    { system = "ChatFrame", point = "CENTER", x = -697, y = -423, settings = { HeightHundreds = 1, HeightTensAndOnes = 70, WidthHundreds = 4, WidthTensAndOnes = 30 } },
    { system = "VehicleLeaveButton", point = "LEFT", x = 2, y = -79 },
    { system = "LootFrame" },
    { system = "HudTooltip", point = "RIGHT", x = -2, y = -278 },
    { system = "ObjectiveTracker", point = "TOPRIGHT", to = "MicroMenuContainer", toPoint = "BOTTOMRIGHT", x = 0, y = -4, settings = { Height = 0, Opacity = 0, TextSize = 0 } },
    { system = "MicroMenu", point = "RIGHT", x = -2, y = 272.5, settings = { Order = 0, Orientation = 0, Size = 4 } },
    { system = "Bags", settings = { Direction = 0, Orientation = 0, Size = 5 } },
    { system = "StatusTrackingBar", index = "StatusTrackingBar1", point = "TOP", x = -23, y = -2, settings = { Size = 10 } },
    { system = "StatusTrackingBar", index = "StatusTrackingBar2", settings = { Size = 10 } },
    { system = "DurabilityFrame", point = "TOPRIGHT", to = "MultiBar5", toPoint = "TOPLEFT", x = -4, y = 0, settings = { Size = 5 } },
    { system = "TimerBars", settings = { Size = 0 } },
    { system = "VehicleSeatIndicator", settings = { Size = 10 } },
    { system = "ArchaeologyBar", settings = { Size = 0 } },
    { system = "CooldownViewer", index = "Essential", settings = { HideWhenInactive = 1, IconDirection = 1, IconLimit = 12, IconPadding = 2, IconSize = 5, Opacity = 100, Orientation = 0, ShowTimer = 1, ShowTooltips = 1, VisibleSetting = 0 } },
    { system = "CooldownViewer", index = "Utility", settings = { HideWhenInactive = 1, IconDirection = 1, IconLimit = 7, IconPadding = 2, IconSize = 5, Opacity = 100, Orientation = 0, ShowTimer = 1, ShowTooltips = 1, VisibleSetting = 0 } },
    { system = "CooldownViewer", index = "BuffIcon", settings = { HideWhenInactive = 1, IconDirection = 1, IconLimit = 1, IconPadding = 5, IconSize = 5, Opacity = 100, Orientation = 0, ShowTimer = 1, ShowTooltips = 1, VisibleSetting = 0 } },
    { system = "CooldownViewer", index = "BuffBar", settings = { BarContent = 0, BarWidthScale = 100, HideWhenInactive = 1, IconDirection = 0, IconLimit = 1, IconPadding = 5, IconSize = 5, Opacity = 100, Orientation = 1, ShowTimer = 1, ShowTooltips = 1, VisibleSetting = 0 } },
    { system = "PersonalResourceDisplay", settings = { BarWidth = 5, HealthBarHeight = 5, HideAltPower = 0, HideClassInfo = 0, HideClassInfoOnPlayerFrame = 0, HideHealth = 0, HidePower = 0, Opacity = 100, Padding = 0, PowerBarHeight = 5, ShowBarText = 0, ShowClassColor = 0, Size = 3, VisibleSetting = 0 } },
    { system = "EncounterEvents", index = "Timeline", settings = { BackgroundTransparency = 0, BarWidth = 50, FlipHorizontally = 0, IconDirection = 1, IconSize = 5, Orientation = 1, OverallSize = 5, Padding = 2, ShowSpellName = 0, ShowTimer = 1, TooltipAnchor = 2, Transparency = 50, ViewType = 0, Visibility = 1 } },
    { system = "EncounterEvents", index = "CriticalWarnings", point = "BOTTOM", to = "MediumEncounterWarnings", toPoint = "TOP", x = -4, y = 4, settings = { IconSize = 5, OverallSize = 5, TooltipAnchor = 2, Transparency = 50, Visibility = 0 } },
    { system = "EncounterEvents", index = "MediumWarnings", point = "CENTER", x = 0, y = 366.5, settings = { IconSize = 5, OverallSize = 5, TooltipAnchor = 2, Transparency = 50, Visibility = 0 } },
    { system = "EncounterEvents", index = "NormalWarnings", point = "CENTER", x = 0, y = 324.5, settings = { IconSize = 5, OverallSize = 5, TooltipAnchor = 2, Transparency = 50, Visibility = 0 } },
    { system = "DamageMeter", point = "TOP", x = -438, y = -2, settings = { BackgroundTransparency = 50, BarHeight = 1, FrameHeight = 20, FrameWidth = 200, Numbers = 1, Padding = 2, ShowClassColor = 1, ShowSpecIcon = 1, Style = 0, TextSize = 5, Transparency = 50, Visibility = 0 } },
    { system = "RaidWarning", point = "CENTER", x = -20, y = 176.5 },
    { system = "TotemActionBar", point = "CENTER", x = -240.5, y = -248.5 },
    { system = "MainActionBarEndCap", index = "EndCapLeft", settings = { Hidden = 1 } },
    { system = "MainActionBarEndCap", index = "EndCapRight", point = "TOPRIGHT", to = "MultiBar7", toPoint = "TOPLEFT", x = 22, y = 5, settings = { Hidden = 1 } },
    { system = "GroupFinder", point = "BOTTOMLEFT", to = "MicroMenuContainer", toPoint = "TOPLEFT", x = 0, y = 4, settings = { Size = 10 } },
    { system = "LossOfControl", point = "CENTER", x = 0, y = -192.6, settings = { Size = 4 } },
    { system = "SwingTimer", index = "MainHand", point = "BOTTOMRIGHT", to = "SwingTimerOffHandFrame", toPoint = "TOPRIGHT", x = 0, y = 4, settings = { Height = 15, Opacity = 50, Scale = 5, ShowBarTitle = 1, ShowTime = 1, Visibility = 0, Width = 213 } },
    { system = "SwingTimer", index = "OffHand", point = "BOTTOMRIGHT", to = "SwingTimerRangedFrame", toPoint = "TOPRIGHT", x = 0, y = 4, settings = { Height = 15, Opacity = 50, Scale = 5, ShowBarTitle = 1, ShowTime = 1, Visibility = 0, Width = 213 } },
    { system = "SwingTimer", index = "Ranged", point = "RIGHT", x = -2, y = -332, settings = { Height = 15, Opacity = 50, Scale = 5, ShowBarTitle = 1, ShowTime = 1, Visibility = 0, Width = 213 } },
}

-- The game's number for a word of the list; nil where this game has no such thing.
local function Number(enum, word)
    local list = rawget(Enum, enum)
    return type(list) == "table" and list[word] or nil
end

-- The system of a layout a line of the list speaks of; nil where this game has none.
local function System(layout, line)
    local system = Number("EditModeSystem", line.system)
    local index = line.index and Number("EditMode" .. line.system .. "SystemIndices", line.index)
    if system == nil or (line.index and index == nil) then return nil end
    for _, known in ipairs(layout.systems or {}) do
        if known.system == system and known.systemIndex == index then return known end
    end
    return nil
end

-- A line over the game's own system: its place (none: the preset's), and the settings this game has.
local function Over(system, line)
    if line.point then
        system.isInDefaultPosition = false
        system.anchorInfo = { point = line.point, relativeTo = line.to or "UIParent", relativePoint = line.toPoint or line.point,
                              offsetX = line.x or 0, offsetY = line.y or 0 }
    end
    for word, value in pairs(line.settings or {}) do
        local number = Number("EditMode" .. line.system .. "Setting", word)
        for _, setting in ipairs(system.settings or {}) do
            if number ~= nil and setting.setting == number then setting.value = value end
        end
    end
end

-- Its place in the game's list (presets first, then the account's layouts, then the character's), and whether the
-- character's layout in use is a preset: the list's index of SaneUI (nil: none), of the last account layout, the
-- presets' count.
local function Find(info)
    local kinds = Enum.EditModeLayoutType
    local found, last, presets = nil, 0, 0
    for index, known in ipairs(info.layouts or {}) do
        if known.layoutName == GameLayout.NAME then found = index end
        if known.layoutType == kinds.Preset then presets = index end
        if known.layoutType ~= kinds.Character then last = index end
    end
    return found, last, presets
end

local function OnPreset(info)
    local active = info.layouts and info.layouts[info.activeLayout]
    return active ~= nil and active.layoutType == Enum.EditModeLayoutType.Preset
end

-- Made now where it is not there (once for an account), and in use on a character still on a preset that has not
-- had it yet. Out of a fight only.
function GameLayout.Make()
    local manager = rawget(_G, "EditModeManagerFrame")
    local info = type(manager) == "table" and rawget(manager, "layoutInfo")
    local presets = rawget(_G, "EditModePresetLayoutManager")
    if type(info) ~= "table" or not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) or not presets
        or not (Enum.EditModeLayoutType and Enum.EditModeSystem) then
        return false
    end
    if InCombatLockdown() then
        Core.AfterCombat("game layout", GameLayout.Make)
        return false
    end
    local store, char = Core.Store(Core.name), Core.Character(Core.name)
    local use = OnPreset(info) and not char.gameLayoutSet
    local found, last, count = Find(info)
    if found then
        if use then
            char.gameLayoutSet = true
            C_EditMode.SetActiveLayout(found)
        end
        store.gameLayoutMade = true
        return true
    end
    if store.gameLayoutMade then return true end -- made once; the player took it away: not again
    local all = C_EditMode.GetLayouts()
    local copy = presets:GetCopyOfPresetLayouts()
    local layout = type(copy) == "table" and copy[1]
    if type(all) ~= "table" or type(all.layouts) ~= "table" or type(layout) ~= "table" then return false end
    layout.layoutName, layout.layoutType = GameLayout.NAME, Enum.EditModeLayoutType.Account
    for _, line in ipairs(GameLayout.SYSTEMS) do
        local system = System(layout, line)
        if system then Over(system, line) end
    end
    table.insert(all.layouts, last + 1 - count, layout)
    C_EditMode.SaveLayouts(all)
    store.gameLayoutMade = true
    if use then char.gameLayoutSet = true end
    if C_EditMode.OnLayoutAdded then C_EditMode.OnLayoutAdded(last + 1, use and true or false, false) end
    return true
end

-- Once the game has read its layouts (at the login, and after each change of them): the first time, made.
local looked = false
Core.On("EDIT_MODE_LAYOUTS_UPDATED", function()
    if looked then return end
    looked = true
    Core.Later(function() Core.Safe("game layout", GameLayout.Make) end, 1)()
end)
