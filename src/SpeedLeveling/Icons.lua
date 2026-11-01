local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Icons
--  What the guide's steps at hand want used and found, as icons only, in a row
--  past the guide's head (Saneroki, 2026-10-25): first the items to use (the
--  Hearthstone while a step hearths, the steps' items, the game's own quest
--  items of the quests in your log), then the NPCs and the creatures to
--  target. Each in Sane UI's round leather ring: an item its picture, its
--  cooldown and how many you carry; a target the game's picture of talking or
--  fighting, its portrait once you have seen it (its nameplate, your target).
--  A click uses the item, or targets the name and puts the skull on it while
--  Skull on what is found is on; the mouse on one says what it is.
--
--  Only what can be used is shown: an item in your bags that the steps name to
--  use, or one with a use of its own (the game's quest items have one); never
--  the gear or the loot a step only mentions.
--
--  Sane UI's own secure buttons (the game's SecureActionButtonTemplate): what
--  each does and whether it is there is set out of a fight only; in one the
--  row stays as it was and follows once it is over. It is placed by the screen
--  where the guide's head ends, not hung on the guide, whose height changes in a
--  fight.
--
--  Seen only with the mouse on the guide (Saneroki, 2026-11-01). Out of sight it
--  is out of the mouse's way too, so a click there reaches the world; but the
--  game lets nothing of a secure button change in a fight except how see-through
--  it is, so a fight begins with every icon open to the mouse: the row comes
--  when the mouse is on its place, wherever the guide has gone since.
--
--      Icons.Update(shown)          as the guide is now (shown or not); Steps.GiveBack hides it with the guide
--      Icons.Reveal(on)             in sight or out of it
--      Icons.Over()                 whether the mouse is on the row, where it counts
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Icons = {}
ns.Icons = Icons

Icons.HOLE = 26     -- a ring's hole, wide
Icons.MOST = 8      -- icons at most
Icons.BESIDE = 2    -- the row's distance from the guide's head
Icons.RING = "Interface\\AddOns\\SaneUI_SpeedLeveling\\Art\\mark-round"

-- The round ring's measures, as the art has them (dev/tools/mark-art): its hole's and its leather's radius, shares of
-- the picture's side.
local HOLE, OUTER = 0.2293 * 252 / 256, 0.2942 * 252 / 256
local WHOLE = Icons.HOLE / (HOLE * 2)   -- the ring's picture's side
local STEP = 2 * OUTER * WHOLE + 2      -- from one icon's middle to the next
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- The game's cursors' pictures for a target not seen yet (the largest of the sheet, past its tip's corner).
local CURSOR = { 16 / 512, 128 / 512, 16 / 256, 128 / 256 }
local FRIEND, FOE = "Interface\\CURSOR\\UISpeakCursor2x", "Interface\\CURSOR\\UIAttackCursor2x"

local row
local buttons = {}
local shownList = {}  -- what the buttons do now: { { item = ID } or { name, foe } }
local placed          -- the row's place and what it holds, as last set: "left|edge|up|..."
local revealed = false -- the mouse is on the guide

local function Font(name, size)
    local font = CreateFont(name)
    if not font:SetFont(ns.Steps.FONT, size, "OUTLINE") then
        local base = rawget(_G, "NumberFontNormal")
        local file = base and base:GetFont()
        if file then font:SetFont(file, size, "OUTLINE") end
    end
    return font
end

-------------------------------------------------------------------------------
--  One icon
-------------------------------------------------------------------------------
local function Tip(button)
    local entry = button.entry
    if not entry then return end
    if entry.item then
        GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
        GameTooltip:SetItemByID(entry.item)
        GameTooltip:Show()
    else
        Core.ShowTip(button, entry.name, entry.foe and ns.TEXT.targetFoe or ns.TEXT.targetFriend, "ANCHOR_BOTTOM")
    end
end

local function Make(index)
    local button = CreateFrame("Button", "SaneUISpeedLevelingIcon" .. index, row, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetSize(STEP - 2, STEP - 2)
    button.backing = button:CreateTexture(nil, "BACKGROUND")
    button.backing:SetColorTexture(0, 0, 0, 0.6)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    for _, round in ipairs({ button.backing, button.icon }) do
        round:SetSize(Icons.HOLE * 1.1, Icons.HOLE * 1.1)
        round:SetPoint("CENTER")
        local mask = button:CreateMaskTexture()
        mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(round)
        round:AddMaskTexture(mask)
    end
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    if button.cooldown.SetSwipeTexture then button.cooldown:SetSwipeTexture(ROUND) end
    if button.cooldown.SetUseCircularEdge then button.cooldown:SetUseCircularEdge(true) end
    button.ring = button:CreateTexture(nil, "OVERLAY")
    button.ring:SetTexture(Icons.RING)
    button.ring:SetSize(WHOLE, WHOLE)
    button.ring:SetPoint("CENTER")
    button.count = button:CreateFontString(nil, "OVERLAY", nil, 7)
    button.count:SetFontObject(Font("SaneUISpeedLevelingIconCount", 11))
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", ns.Guard(function() Core.HideTip() end))
    buttons[index] = button
    return button
end

-- What an icon shows: an item's picture, count and cooldown; a target's portrait once seen, else the game's picture.
local function Draw(button)
    local entry = button.entry
    if not entry then return end
    if entry.item then
        local items = rawget(_G, "C_Item")
        local file = Core.Ask(items and items.GetItemIconByID or rawget(_G, "GetItemIcon"), entry.item)
        button.icon:SetTexture(file or 134400)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local count = Core.Ask(items and items.GetItemCount or rawget(_G, "GetItemCount"), entry.item) or 0
        button.count:SetText(count > 1 and count or "")
        local bags = rawget(_G, "C_Container")
        local start, duration = Core.Ask(bags and bags.GetItemCooldown, entry.item)
        if type(start) == "number" and type(duration) == "number" and duration > 0 then
            button.cooldown:SetCooldown(start, duration)
        else
            button.cooldown:Clear()
        end
    else
        button.count:SetText("")
        button.cooldown:Clear()
        if button.portrait ~= entry.name then
            button.icon:SetTexture(entry.foe and FOE or FRIEND)
            button.icon:SetTexCoord(unpack(CURSOR))
            button.portrait = nil
        end
    end
end

-- A target seen (its nameplate, your target): its portrait on its icon.
local function Seen(unit)
    local name = Core.Plain(Core.Ask(UnitName, unit))
    if type(name) ~= "string" then return end
    for _, button in ipairs(buttons) do
        local entry = button.entry
        local portrait = rawget(_G, "SetPortraitTexture")
        if entry and entry.name == name and button.portrait ~= name and portrait then
            portrait(button.icon, unit)
            button.icon:SetTexCoord(0, 1, 0, 1)
            button.portrait = name
        end
    end
end

-------------------------------------------------------------------------------
--  The row
-------------------------------------------------------------------------------
-- A name a macro can take: none that would break its line.
local function Plain(name)
    return type(name) == "string" and name ~= "" and not name:find("[;%[%]\n]")
end

-- What the row holds now: the items in your bags first, then the NPCs, then the creatures. An item the steps name
-- (named) is shown when you carry it; another only when it has a use of its own.
local function Wanted()
    local list, have = {}, {}
    local items = rawget(_G, "C_Item")
    local function Item(item, named)
        if #list < Icons.MOST and not have["i" .. item]
            and (Core.Ask(items and items.GetItemCount or rawget(_G, "GetItemCount"), item) or 0) > 0
            and (named or Core.Ask(items and items.GetItemSpell or rawget(_G, "GetItemSpell"), item) ~= nil) then
            have["i" .. item] = true
            list[#list + 1] = { item = item }
        end
    end
    local function Name(name, foe)
        if #list < Icons.MOST and Plain(name) and not have["n" .. name] then
            have["n" .. name] = true
            list[#list + 1] = { name = name, foe = foe }
        end
    end
    local uses = ns.Guide.Uses()
    for _, item in ipairs(uses or {}) do Item(item, true) end
    for _, item in ipairs(ns.Items.QuestItems()) do Item(item, false) end
    local foes, friends = ns.Guide.Targets()
    for _, name in ipairs(friends or {}) do Name(name, false) end
    for _, name in ipairs(foes or {}) do Name(name, true) end
    return list
end

local function Signature(list, left, edge, up)
    local parts = { math.floor(left + 0.5), math.floor(edge + 0.5), up and "up" or "down", ns.options.skull and "skull" or "" }
    for _, entry in ipairs(list) do parts[#parts + 1] = entry.item or ((entry.foe and "foe:" or "friend:") .. entry.name) end
    return table.concat(parts, "|")
end

local function Later()
    Core.AfterCombat("speedleveling: icons", function() ns.Guarded(ns.Steps.Update) end)
end

-- In sight or out of it, and out of a fight in the mouse's way or not.
local function Reach()
    if not row then return end
    row:SetAlpha(revealed and 1 or 0)
    if InCombatLockdown() then return end
    for _, button in ipairs(buttons) do button:EnableMouse(revealed) end
end

-- A fight begins (the moment before the lock): the icons open to the mouse for all of it.
local function Fighting()
    if InCombatLockdown() then return end
    for _, button in ipairs(buttons) do button:EnableMouse(true) end
end

function Icons.Reveal(on)
    revealed = on
    Reach()
end

function Icons.Over()
    return row ~= nil and row:IsShown() and (revealed or InCombatLockdown()) and row:IsMouseOver()
end

local function Build()
    row = CreateFrame("Frame", "SaneUISpeedLevelingIcons", UIParent)
    row:SetSize(STEP, STEP)
    row:SetFrameStrata("LOW")
    ns.On("PLAYER_REGEN_DISABLED", Fighting)
    ns.On("PLAYER_REGEN_ENABLED", Reach)
    ns.On("NAME_PLATE_UNIT_ADDED", Seen)
    ns.On("PLAYER_TARGET_CHANGED", function() Seen("target") end)
    local function Redraw()
        for _, button in ipairs(buttons) do if button:IsShown() then Draw(button) end end
    end
    ns.On("BAG_UPDATE_COOLDOWN", Redraw)
    -- Items come and go in the bags, quest items with quests: the row anew, as the guide is shown now.
    local again = Core.Later(function() Icons.Update(ns.Steps.Frame() ~= nil) end, 0.3)
    ns.On("BAG_UPDATE_DELAYED", again)
    ns.On("QUEST_LOG_UPDATE", again)
end

function Icons.Update(shown)
    local on = shown and not ns.off and ns.options.icons
    local left, edge, up
    if on then left, edge, up = ns.Steps.Edge() end
    if not left then
        if row and row:IsShown() then
            if InCombatLockdown() then return Later() end
            row:Hide()
            placed = nil
        end
        return
    end
    if not row then Build() end
    local list = Wanted()
    local signature = Signature(list, left, edge, up)
    if InCombatLockdown() then
        -- The game holds secure buttons in a fight: only their pictures change; the rest once it is over.
        for _, button in ipairs(buttons) do if button:IsShown() then Draw(button) end end
        if signature ~= placed then Later() end
        return
    end
    if signature ~= placed then
        placed = signature
        for index, entry in ipairs(list) do
            local button = buttons[index] or Make(index)
            button.entry = entry
            if entry.item then
                button:SetAttribute("type", "item")
                button:SetAttribute("item", "item:" .. entry.item)
                button:SetAttribute("macrotext", nil)
            else
                button:SetAttribute("type", "macro")
                button:SetAttribute("item", nil)
                button:SetAttribute("macrotext", "/cleartarget\n/targetexact " .. entry.name
                    .. (ns.options.skull and "\n/tm [exists] !8" or ""))
            end
            button:ClearAllPoints()
            button:SetPoint("CENTER", row, "BOTTOMLEFT", (index - 0.5) * STEP, STEP / 2)
            button:Show()
        end
        for index = #list + 1, #buttons do
            buttons[index].entry = nil
            buttons[index]:Hide()
        end
        row:SetSize(math.max(1, #list) * STEP, STEP)
        row:ClearAllPoints()
        row:SetPoint(up and "BOTTOMLEFT" or "TOPLEFT", UIParent, "BOTTOMLEFT", left, edge + (up and Icons.BESIDE or -Icons.BESIDE))
        row:SetShown(#list > 0)
        Reach()
    end
    for _, button in ipairs(buttons) do if button:IsShown() then Draw(button) end end
end
