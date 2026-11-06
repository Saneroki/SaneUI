local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Group
--  One frame for your party and your raid, in place of the game's party and
--  raid frames: the same window whatever the group, only with more slots. It
--  fills from its bottom left corner: you and your party up, five to a column,
--  then a column to the right for each group of a raid, up to forty.
--
--  The window (Core.Window, placed in Edit Mode) is as large as the most you
--  allow. Nothing is drawn around it in play, only the units; in Edit Mode it has
--  the box every window has there. A click on that gives its settings, in Core's
--  dialog: its max width and height, a unit's max width, and how many made-up
--  units to preview. Five units always fill the max height, however few are
--  there (Saneroki, 2026-10-31): a slot is a fifth of it high. A slot is as wide
--  as the max unit width, narrower only where the columns the group fills would
--  not fit into the max width: then all share that evenly (Group.Size). Sizes
--  change out of a fight only; a fight keeps them, and members who join in one
--  show at that size.
--
--  The members are the game's secure group headers (SecureGroupHeaderTemplate),
--  one per raid group, side by side: each a column, its buttons going up from
--  the bottom, each anchored to the last so a group that is empty takes no
--  room. They arrange the buttons themselves, in a fight too. The buttons are the
--  game's secure unit buttons, made by the headers when you first join a group
--  (out of a fight); each carries our face (GroupFace.lua), which follows the unit
--  its header gives it, so clicks, the game's menu, the tooltip and @mouseover
--  are as on your other frames; a slot keeps its token while its member changes
--  (one left, the next slid in), so every face reads its unit anew whenever the
--  group changes, in a fight too. The game's state driver shows them while you
--  are in a group; alone you have your own frame. Your own slot among them is
--  one of them, with the group's word for a name and a cog that opens the
--  group's tools (GroupTools.lua).
--
--  In Edit Mode the live frames rest and the preview shows: plain frames of the
--  same look (GroupFace.lua) laid out by the same sizes, with random health,
--  mana, roles, raid markers, reminders' icons, barriers, lost health, dispels,
--  ready checks, aggro, the dead and the offline, a resurrection on its way, and
--  your own slot first.
--  They are rolled when their number changes, not as sizes change, so what you
--  look at holds still while you slide.
--
--  The game's party frame, raid container and the raid manager at the screen's
--  edge stand in a hidden frame of ours while ours shows (Core.Lend), with their
--  parents given back exactly. Off, or standing down, the game's are back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Face = ns.GroupFace
local Group = {}
ns.Group = Group

Group.GROUPS, Group.PER_GROUP = 8, 5
Group.GAP = 0           -- between two units: they stand edge to edge (Saneroki, 2026-10-30: "0px gaps")
Group.LEAST_WIDTH, Group.LEAST_HEIGHT = 40, 14
Group.GAME = { "PartyFrame", "CompactRaidFrameContainer", "CompactRaidFrameManager" } -- the game's frames ours stand in for
Group.SHOWN = "[group] show; hide"                         -- when the live frames show
-- What can be chosen in Edit Mode (each also an option of the module, Combat.lua).
Group.SETTINGS = {
    { key = "groupWidth", min = 100, max = 2000, step = 10 },
    { key = "groupHeight", min = 30, max = 800, step = 5 },
    { key = "groupUnitWidth", min = 40, max = 400, step = 5 },
    { key = "groupPreview", min = 0, max = Group.GROUPS * Group.PER_GROUP, input = true },
}

local holder, window, live, preview, box -- the window, the live frames' parent, the preview's parent, the game's hidden frame
local headers, samples, faces, lends = {}, {}, {}, nil -- the headers; the rolled previews; their faces; what is lent
local built = false -- the headers have their buttons
local holdCount = 0 -- ready checks ended: only the last one's result is taken away

-- How large a unit is for that many columns within the limits: five fill the height whoever is there; as wide as a
-- unit may be, or the width shared evenly where that many would not fit.
function Group.Size(columns, width, height, unit)
    columns = math.max(columns, 1)
    local wide = math.floor((width - (columns - 1) * Group.GAP) / columns)
    local high = math.floor((height - (Group.PER_GROUP - 1) * Group.GAP) / Group.PER_GROUP)
    return math.max(math.min(wide, unit), Group.LEAST_WIDTH), math.max(high, Group.LEAST_HEIGHT)
end

-- The limits as the settings say.
local function Limits()
    local options = ns.options
    return tonumber(options.groupWidth), tonumber(options.groupHeight), tonumber(options.groupUnitWidth)
end

-- How many columns your group fills now: a raid one for each group in use, a party one.
function Group.Filled()
    if not Core.Ask(IsInRaid) then return 1 end
    local used, columns = {}, 0
    for index = 1, Core.Ask(GetNumGroupMembers) or 0 do
        local _, _, group = Core.Ask(GetRaidRosterInfo, index)
        if group and not used[group] then
            used[group] = true
            columns = columns + 1
        end
    end
    return columns
end

-- A button of a header: its unit followed by our face.
local function UnitChanged(button, name, value)
    if name == "unit" then Face.Unit(button.face, value) end
end
local OnAttributeChanged = ns.Guard(UnitChanged)

local function Dress(button)
    ns.Units.Clicks(button)
    button.face = Face.Make(button)
    button.face:SetAllPoints(button)
    ns.Units.Marks(button.face)
    button:HookScript("OnAttributeChanged", OnAttributeChanged)
    Face.Unit(button.face, button:GetAttribute("unit"))
end

-- The headers and their buttons: the header makes those itself, and all at once when told to start below its first
-- (shown: a header does nothing out of sight). Out of a fight.
local function Headers()
    if built then return end
    built = true
    live:Show()
    for index = 1, Group.GROUPS do
        local header = CreateFrame("Frame", nil, live, "SecureGroupHeaderTemplate")
        header:SetAttribute("template", "SecureUnitButtonTemplate")
        header:SetAttribute("showRaid", true)
        header:SetAttribute("showParty", true)
        header:SetAttribute("showPlayer", true)
        header:SetAttribute("groupFilter", tostring(index))
        header:SetAttribute("point", "BOTTOM")
        header:SetAttribute("yOffset", Group.GAP)
        header:SetAttribute("minWidth", 0.1) -- an empty group takes no room
        header:SetAttribute("minHeight", 0.1)
        if index == 1 then
            header:SetPoint("BOTTOMLEFT", live, "BOTTOMLEFT")
        else
            header:SetPoint("BOTTOMLEFT", headers[index - 1], "BOTTOMRIGHT", Group.GAP, 0)
        end
        header:Show()
        header:SetAttribute("startingIndex", 1 - Group.PER_GROUP)
        header:SetAttribute("startingIndex", 1)
        headers[index] = header
        for child = 1, Group.PER_GROUP do
            if header[child] then Dress(header[child]) end
        end
    end
end

-- The tools' button on your own slot's cog. Out of a fight.
local function Mine()
    local slot
    for _, header in ipairs(headers) do
        for child = 1, Group.PER_GROUP do
            local button = header[child]
            if button and button.face and button.face.mine then slot = button end
        end
    end
    ns.GroupTools.Over(slot, Face.INSET + Face.ICON / 2)
end

-- Every live face, each with its fn.
local function EachFace(fn, ...)
    for _, header in ipairs(headers) do
        for child = 1, Group.PER_GROUP do
            local button = header[child]
            if button and button.face then fn(button.face, ...) end
        end
    end
end
Group.Each = EachFace

-- Every live unit at the size the group calls for. Out of a fight.
local function Layout()
    local width, height, unit = Limits()
    local wide, high = Group.Size(Group.Filled(), width, height, unit)
    for _, header in ipairs(headers) do
        for child = 1, Group.PER_GROUP do
            if header[child] then header[child]:SetSize(wide, high) end
        end
        header:SetAttribute("yOffset", Group.GAP) -- arranged anew for the new size
    end
end

-- One made-up unit: most are well, a few are not.
local NAMES = ns.TEXT.groupSamples
local function Pick(list)
    return list[math.random(#list)]
end
local function Chance(share)
    return math.random() < share
end
local function Roll(icons)
    local sample = { name = Pick(NAMES.first) .. " " .. Pick(NAMES.last), health = 0.35 + math.random() * 0.65,
                     most = math.random(2, 30) * 1000, icons = {} }
    if Chance(0.35) then -- a tank or a healer
        sample.mana = 0.1 + math.random() * 0.9
        sample.role = Pick({ "TANK", "HEALER" })
    end
    if Chance(0.2) then sample.mark = math.random(1, 8) end
    if Chance(0.2) then sample.barrier = math.min(0.1 + math.random() * 0.3, 1 - sample.health) end
    if Chance(0.15) then sample.lost = 0.1 + math.random() * 0.3 end
    if Chance(0.15) then sample.dispel = Pick({ "Magic", "Curse", "Disease", "Poison" }) end
    if Chance(0.2) then sample.ready = Pick({ "ready", "notready", "waiting" }) end
    if Chance(0.1) then sample.aggro = true end
    for _, icon in ipairs(icons) do
        if Chance(0.25) then sample.icons[#sample.icons + 1] = icon end
    end
    local dead, offline = Chance(0.06), Chance(0.05)
    if dead or offline then
        sample.word = dead and ns.UnitText.DEAD or ns.UnitText.OFFLINE
        sample.colour = dead and Face.DEAD or Face.OFFLINE
        sample.mana, sample.barrier, sample.lost, sample.dispel, sample.aggro = nil, nil, nil, nil, nil
        sample.icons = {}
        sample.rez = dead and Chance(0.5)
    end
    return sample
end

-- That many samples, rolled anew only when their number changes.
local function Rolled(count)
    if #samples ~= count then
        local icons = ns.GroupReminders.Icons()
        wipe(samples)
        for index = 1, count do samples[index] = Roll(icons) end
        if samples[1] then samples[1].you = true end
    end
    return samples
end

-- The preview as the settings say; each unit in its place, as the headers would put it.
local function Preview()
    local count = math.min(tonumber(ns.options.groupPreview) or 0, Group.GROUPS * Group.PER_GROUP)
    local width, height, unit = Limits()
    local wide, high = Group.Size(math.ceil(count / Group.PER_GROUP), width, height, unit)
    for index, sample in ipairs(Rolled(count)) do
        sample.raid = count > Group.PER_GROUP
        local face = faces[index]
        if not face then
            face = Face.Make(preview, true)
            faces[index] = face
        end
        local place = index - 1
        face:ClearAllPoints()
        face:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", math.floor(place / Group.PER_GROUP) * (wide + Group.GAP),
                      (place % Group.PER_GROUP) * (high + Group.GAP))
        face:SetSize(wide, high)
        Face.Fit(face) -- the sample's words read how narrow it is
        Face.Sample(face, sample)
        face:Show()
    end
    for index = count + 1, #faces do faces[index]:Hide() end
    preview:Show()
end

-- The window: as large as the limits; its settings in Edit Mode's dialog.
local function Build()
    if holder then return end
    box = CreateFrame("Frame", nil, UIParent)
    box:Hide()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetFrameStrata("LOW")
    local width, height = Limits()
    holder:SetSize(width, height)
    live = CreateFrame("Frame", nil, holder, "SecureFrameTemplate")
    live:SetAllPoints(holder)
    live:Hide()
    preview = CreateFrame("Frame", nil, holder)
    preview:SetAllPoints(holder)
    preview:Hide()
    local settings = {}
    for index, setting in ipairs(Group.SETTINGS) do
        settings[index] = { key = setting.key, min = setting.min, max = setting.max, step = setting.step,
                            input = setting.input, text = ns.TEXT[setting.key] }
    end
    window = Core.Window.New(holder, {
        store = ns.store, key = "groupPlace", title = ns.TEXT.group, first = Group.FIRST, settings = settings,
        get = function(key) return ns.options[key] end,
        set = function(key, value) Core.Set(ns.name, key, value) end })
    window:Place()
end
Group.FIRST = { point = "BOTTOMLEFT", x = 16, y = 340 }

-- The game's frames out of sight, or back.
local function Away()
    if lends then return end
    lends = {}
    for _, name in ipairs(Group.GAME) do
        local game = rawget(_G, name)
        if type(game) == "table" then
            local lend = Core.Lend(game)
            lend:SetParent(box)
            lends[#lends + 1] = lend
        end
    end
end

local function Back()
    local lent = lends
    lends = nil
    for index = #(lent or {}), 1, -1 do ns.Safe("group frames", lent[index].Return, lent[index]) end
end

-- The live frames rest: hidden, the game's state driver off.
local function Rest()
    if not live then return end
    UnregisterStateDriver(live, "visibility")
    live:Hide()
    ns.GroupTools.Hide()
end

-- As the settings and your group say. Out of a fight.
local function Apply()
    if ns.off or ns.options.group == false then
        Rest()
        if preview then preview:Hide() end
        return Back()
    end
    Build()
    Away()
    local width, height = Limits()
    window:GrowFromBottom(width, height)
    EachFace(ns.Units.Marks)
    if Core.EditMode.active then
        Rest()
        return Preview()
    end
    preview:Hide()
    if not Core.Ask(IsInGroup) then return Rest() end
    Headers()
    ns.GroupTools.Build(live)
    Layout()
    EachFace(Face.Fill)
    Mine()
    ns.GroupTools.Refresh()
    RegisterStateDriver(live, "visibility", Group.SHOWN)
end

-- What fails here stands the module down: half made, nothing would show, the game's frames being away.
function Group.Apply()
    Core.AfterCombat("group frames", ns.Guarded, Apply)
end

-- Every face read anew: a changed group, a marker, the end of a fight.
local Again = Core.Later(function()
    if not ns.off then EachFace(Face.Fill) end
end)

-- A ready check began or someone answered: each face as the game says. It ended: the result stays a while.
local function ReadyCheck()
    if ns.off then return end
    holdCount = holdCount + 1
    Face.holding = false
    EachFace(Face.Ready)
end

local function ReadyEnded()
    if ns.off then return end
    EachFace(Face.Ready)
    EachFace(Face.ReadyEnded)
    Face.holding = true
    holdCount = holdCount + 1
    local held = holdCount
    C_Timer.After(Face.READY_HOLD, ns.Guard(function()
        if held ~= holdCount then return end
        Face.holding = false
        EachFace(Face.ReadyGone)
    end))
end

function Group.Start()
    -- The group changed: every face reads its slot anew at once (a header gives a slot the same token whoever fills it,
    -- and no event of the unit's tells of its new member; a fight holds the rest back), then the sizes and the driver.
    local Applied = Core.Later(Group.Apply)
    ns.On("GROUP_ROSTER_UPDATE", function()
        if InCombatLockdown() then Again() end -- out of a fight Apply fills every face itself
        Applied()
    end)
    ns.On("PLAYER_ROLES_ASSIGNED", Again)
    ns.On("RAID_TARGET_UPDATE", Again)
    ns.On("PLAYER_REGEN_ENABLED", Again)
    ns.On("READY_CHECK", ReadyCheck)
    ns.On("READY_CHECK_CONFIRM", ReadyCheck)
    ns.On("READY_CHECK_FINISHED", ReadyEnded)
    ns.On("PARTY_LEADER_CHANGED", Core.Later(function() ns.Guarded(ns.GroupTools.Refresh) end))
    ns.On("UI_SCALE_CHANGED", Core.Later(Group.Apply))
    Core.EditMode.Watch(ns.Guard(Group.Apply))
    Group.Apply()
end

-- Standing down: ours out of sight at once, hidden after the fight; the game's frames back.
function Group.GiveBack()
    if holder then holder:SetAlpha(0) end
    Core.AfterCombat("group frames", function()
        Rest()
        if preview then preview:Hide() end
    end)
    ns.Safe("group frames", Back)
    EachFace(function(face) face.marks:Set(nil) end)
end
