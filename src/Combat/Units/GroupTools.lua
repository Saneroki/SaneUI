local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - GroupTools
--  The tools of a party or raid, in place of the game's raid manager at the
--  screen's edge (it stays out of sight, Group.lua): the cog on your own slot
--  among the group's frames (Saneroki, 2026-10-30) opens a small panel over it,
--  the rest of the slot answering as any other's: ready check, role check, countdown, everyone is assistant, the
--  raid markers on your target and on the ground, the game's menu of you (it
--  has converting to a raid or a party, difficulty and more), leaving.
--
--  The game does not let addon code do most of that (HasRestrictions: its marks,
--  ready check, countdown), so it is all done by the game's own secure means, on
--  the click itself: the markers are secure action buttons of the kinds raidtarget
--  and worldmarker, the menu togglemenu, and the rest kind click, which clicks
--  the game's own button in its raid manager: it stays loaded for that, and those
--  buttons know who may use them. Leaving is free to addons.
--
--  Secure buttons make the panel a protected frame, which addon code may not
--  show or hide in a fight: so the button on the cog and the panel's close
--  button are secure handlers that do it (SecureHandlerClickTemplate), and it
--  opens and closes in a fight too. Esc closes it out of a fight. The button
--  stands over the cog of the slot your unit has (Tools.Over), moved out of a
--  fight only.
--  What is enabled for you is looked at out of a fight, as you open it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Tools = {}
ns.GroupTools = Tools

Tools.WIDTH, Tools.PADDING = 306, 16
Tools.ROW, Tools.WORD = 26, 56 -- a row's height; how wide the word before a row of marks is
Tools.GAP = 6                  -- between two rows
Tools.MARK = 24                -- a mark's button, square
Tools.MARKS = 8
Tools.COG = 20                 -- the button on the cog, square: a little larger, to hit it easily
Tools.ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
Tools.CLEAR = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
-- The game's raid manager's own buttons ours click, by their keys in its display frame.
Tools.CLICKS = { { word = "groupReady", game = "readyCheckButton" }, { word = "groupRole", game = "rolePollButton" },
                 { word = "groupCountdown", game = "countdownButton" } }

local button, panel -- the button on your slot's cog, and the panel
local parts = {}    -- the panel's buttons that are not for everyone: { button, who }

-- A game's button of its raid manager, or nil.
local function GameButton(key)
    local manager = rawget(_G, "CompactRaidFrameManager")
    local display = type(manager) == "table" and rawget(manager, "displayFrame")
    local found = type(display) == "table" and rawget(display, key)
    return type(found) == "table" and found or nil
end

-- A word's button of the game's, secure with those attributes.
local function Word(word, width, attributes)
    local made = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate, SecureActionButtonTemplate")
    made:SetSize(width, Tools.ROW - 2)
    made:SetText(word)
    made:RegisterForClicks("AnyUp", "AnyDown")
    for name, value in pairs(attributes) do made:SetAttribute(name, value) end
    return made
end

-- One button of a row of marks: the raid marker's picture, or the clear sign; secure with those attributes.
local function Mark(cell, attributes)
    local made = CreateFrame("Button", nil, panel, "SecureActionButtonTemplate")
    made:SetSize(Tools.MARK, Tools.MARK)
    made:RegisterForClicks("AnyUp", "AnyDown")
    for name, value in pairs(attributes) do made:SetAttribute(name, value) end
    local picture = made:CreateTexture(nil, "ARTWORK")
    picture:SetPoint("TOPLEFT", made, "TOPLEFT", 2, -2)
    picture:SetPoint("BOTTOMRIGHT", made, "BOTTOMRIGHT", -2, 2)
    if cell then
        picture:SetTexture(Tools.ICONS)
        picture:SetSpriteSheetCell(cell, 4, 4)
    else
        picture:SetTexture(Tools.CLEAR)
    end
    made:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return made
end

-- A row of marks at that height: its word, the eight, the sign that clears them all.
local function Marks(top, word, attributes, clear)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", Tools.PADDING, top - 6)
    label:SetText(word)
    local left = Tools.PADDING + Tools.WORD
    for cell = 1, Tools.MARKS do
        Mark(cell, attributes(cell)):SetPoint("TOPLEFT", panel, "TOPLEFT", left + (cell - 1) * Tools.MARK, top)
    end
    Mark(nil, clear):SetPoint("TOPLEFT", panel, "TOPLEFT", left + Tools.MARKS * Tools.MARK, top)
end

-- The panel's rows, top down; how high it all is.
local function Rows()
    local text = ns.TEXT
    local inner = Tools.WIDTH - 2 * Tools.PADDING
    local top = -(Tools.PADDING + 24)
    local wide = math.floor((inner - 2 * Tools.GAP) / 3)
    for index, click in ipairs(Tools.CLICKS) do
        local made = Word(text[click.word], wide, { type = "click", clickbutton = GameButton(click.game) })
        made:SetPoint("TOPLEFT", panel, "TOPLEFT", Tools.PADDING + (index - 1) * (wide + Tools.GAP), top)
        parts[#parts + 1] = { made, "leader" }
    end
    top = top - Tools.ROW - Tools.GAP
    local assist = Word(text.groupAssist, inner, { type = "click", clickbutton = GameButton("everyoneIsAssistButton") })
    assist:SetPoint("TOPLEFT", panel, "TOPLEFT", Tools.PADDING, top)
    parts[#parts + 1] = { assist, "raidLeader" }
    top = top - Tools.ROW - Tools.GAP
    Marks(top, text.groupTarget, function(cell)
        return { type = "raidtarget", unit = "target", action = "toggle", marker = cell }
    end, { type = "raidtarget", action = "clear-all" })
    top = top - Tools.MARK - Tools.GAP
    local order = rawget(_G, "WORLD_RAID_MARKER_ORDER")
    Marks(top, text.groupGround, function(cell) -- the game's list of them is by its own order, the last raid marker first
        return { type = "worldmarker", action = "toggle", marker = order and order[Tools.MARKS + 1 - cell] or cell }
    end, { type = "worldmarker", action = "clear" })
    top = top - Tools.MARK - Tools.GAP
    wide = math.floor((inner - Tools.GAP) / 2)
    local menu = Word(text.groupMenu, wide, { type = "togglemenu", unit = "player" })
    menu:SetPoint("TOPLEFT", panel, "TOPLEFT", Tools.PADDING, top)
    local leave = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    leave:SetSize(wide, Tools.ROW - 2)
    leave:SetPoint("TOPLEFT", panel, "TOPLEFT", Tools.PADDING + wide + Tools.GAP, top)
    leave:SetText(text.groupLeave)
    leave:SetScript("OnClick", ns.Guard(function() C_PartyInfo.LeaveParty() end))
    return Tools.PADDING - top + Tools.ROW
end

-- What you may use now, and the panel's title; what a fight locks is left as it is.
function Tools.Refresh()
    if not panel then return end
    local raid = Core.Ask(IsInRaid) == true
    local leader = Core.Ask(UnitIsGroupLeader, "player") == true
    local assist = Core.Ask(UnitIsGroupAssistant, "player") == true
    panel.title:SetText(raid and ns.TEXT.groupRaid or ns.TEXT.groupParty)
    if InCombatLockdown() then return end
    for _, part in ipairs(parts) do
        local who = part[2]
        part[1]:SetEnabled(who == "raidLeader" and raid and leader or who == "leader" and (leader or assist) or false)
    end
end

-- A secure click of that button runs that code (the game's restricted one), in a fight too.
local function Handler(host, code)
    host:RegisterForClicks("AnyUp")
    host:SetAttribute("_onclick", code)
end

local function Close()
    if not InCombatLockdown() then panel:Hide() end
end

local function Listen(on)
    Core.Escape(panel, on and Close or nil)
end

-- Made when you are first in a group (out of a fight): the button in the live frames, the panel over it.
function Tools.Build(parent)
    if button then return end
    panel = CreateFrame("Frame", nil, UIParent, "SecureFrameTemplate")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetWidth(Tools.WIDTH)
    panel:EnableMouse(true)
    panel:Hide()
    local ok, border = pcall(CreateFrame, "Frame", nil, panel, "DialogBorderTranslucentTemplate")
    if ok and border then border:SetAllPoints() end
    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    panel.title:SetPoint("TOP", 0, -15)
    panel:SetHeight(Rows())
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButtonNoScripts, SecureHandlerClickTemplate")
    close:SetPoint("TOPRIGHT")
    Handler(close, [[ self:GetParent():Hide() ]])
    button = CreateFrame("Button", nil, parent, "SecureHandlerClickTemplate")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    SecureHandlerSetFrameRef(button, "panel", panel)
    Handler(button, [[
        local panel = self:GetFrameRef("panel")
        if panel:IsShown() then panel:Hide() else panel:Show() end
    ]])
    button:SetScript("OnEnter", ns.Guard(function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.TEXT.groupTools)
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:Hide()
    panel:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
    panel:HookScript("OnShow", ns.Guard(function()
        Tools.Refresh()
        if not InCombatLockdown() then Listen(true) end
    end))
    panel:HookScript("OnHide", ns.Guard(function() Listen(false) end))
    ns.On("PLAYER_REGEN_DISABLED", function() Listen(false) end)
    ns.On("PLAYER_REGEN_ENABLED", function()
        if panel:IsShown() then Listen(true) end
    end)
end

-- The button on the cog of that frame (your slot), the cog's middle that far from its right edge; or out of sight
-- without one. Out of a fight.
function Tools.Over(slot, middle)
    if not button then return end
    button:ClearAllPoints()
    if slot then
        button:SetSize(Tools.COG, Tools.COG)
        button:SetPoint("CENTER", slot, "RIGHT", -middle, 0)
        button:SetFrameLevel((Core.Plain(slot:GetFrameLevel()) or 1) + 12)
    end
    button:SetShown(slot ~= nil)
end

-- The panel closed. Out of a fight.
function Tools.Hide()
    if panel then panel:Hide() end
end
