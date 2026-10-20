local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Book item
--  One entry of our spellbook, as the game's own entry looks and behaves
--  (Blizzard_PlayerSpells, SpellBook/Blizzard_SpellBookItem.xml and .lua,
--  SpellBookItemMixin): its plate, the spell's icon in the game's frame (a
--  square one for a spell, a round one for a passive), its name, its rank or
--  "Passive", and for a spell still to learn the level it comes at or
--  "Trainable", greyed; the cooldown, the glow while the spell is on none of
--  your action bars, a pet spell's autocast, the game's lock while a spell is
--  locked by level linking, and the sheen that runs over a learned spell's
--  frame. Built in our code (the game's template holds its own spellbook's
--  click), in the game's art and words.
--
--  The click: casting is the game's, and takes a secure button of the game's
--  (Casts.lua), laid over the icon out of a fight. Under it, this entry's own
--  icon does what needs no cast: the tooltip (GameTooltip:SetSpellBookItem),
--  a drag to an action bar, a link in chat or the pickup with the game's
--  modified clicks. In a fight, where the secure buttons are away, a click
--  says that the book casts again after the fight; the drag still works.
--
--      local item = Item.Make(parent)
--      Item.Set(item, entry)            -- entry = { slot, bank, status }: drawn for it
--      Item.Cooldown(item)  Item.Status(item)  Item.AutoCast(item)  Item.Icon(item)
--      Item.Castable(item)              -- a learned spell or pet ability, which a click casts
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Data = ns.BookData
local Item = {}
ns.BookItem = Item

Item.WIDTH, Item.HEIGHT = 220, 60 -- SpellBookItemTemplate
Item.BUTTON, Item.ICON = 40, 36
Item.UNLEARNED = 0.6              -- unlearnedTextAlpha, unlearnedIconAlpha
Item.PLATE, Item.PLATE_HOVER = 0.25, 1 -- defaultBackplateAlpha, hoverBackplateAlpha
Item.HOVER, Item.PRESS = 0.35, 0.65    -- iconHighlightHoverAlpha, iconHighlightPressAlpha
Item.TEXT_LEFT, Item.TEXT_GAP = 50, 2
Item.FONT, Item.SMALL = "SystemFont_Large", "SystemFont_Med1"

-- The game's two sets of art for an entry (SpellBookItemMixin.ArtSet): its border with the border's anchors
-- to the 40-unit button, when learned and when not, the icon's mask, highlight, sheen mask and trainer plate.
Item.ART = {
    Square = {
        mask = "spellbook-item-spellicon-mask", highlight = "spellbook-item-iconframe-hover",
        active = "spellbook-item-iconframe", activeAt = { -11, 1, 1, -7 },
        inactive = "spellbook-item-iconframe-inactive", inactiveAt = { -10, 1, 2, -5 },
        sheen = "spellbook-item-iconframe-sheen-mask", trainer = "spellbook-item-needtrainer-iconframe-backplate",
    },
    Circle = {
        mask = "talents-node-circle-mask", highlight = "spellbook-item-iconframe-passive-hover",
        active = "talents-node-circle-gray", activeAt = { 0, 0, 0, 0 },
        inactive = "spellbook-item-iconframe-passive-inactive", inactiveAt = { 0, 0, 0, 0 },
        sheen = "talents-node-circle-sheenmask", trainer = "spellbook-item-needtrainer-passive-backplate",
        round = true,
    },
}

Item.TEXT = {
    passive = Core.Word("SPELL_PASSIVE", "Passive"),
    at = Core.Word("SPELLBOOK_AVAILABLE_AT", "Available at level %d"),
    trainable = Core.Word("SPELLBOOK_TRAINABLE", "Trainable"),
    fight = "In a fight, cast it from your action bars: the book casts again after the fight.",
}

local function Colour(name, r, g, b)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.GetRGB then return colour:GetRGB() end
    return r, g, b
end

local function Kind(name)
    return Data.Enum("SpellBookItemType", name)
end

-------------------------------------------------------------------------------
--  Hover, press, click, drag: the game's entry's, without its cast
-------------------------------------------------------------------------------
function Item.Enter(item)
    local info = item.info
    if not info then return end
    local tooltip = GameTooltip
    tooltip:SetOwner(item.Button, "ANCHOR_RIGHT")
    if tooltip.SetSpellBookItem then tooltip:SetSpellBookItem(item.entry.slot, item.entry.bank) end
    if item.missing then
        local line = rawget(_G, "TALENT_BUTTON_TOOLTIP_NOT_ON_ACTION_BAR")
        if type(line) == "string" then tooltip:AddLine(line, Colour("LIGHTBLUE_FONT_COLOR", 0.53, 0.67, 1)) end
    end
    tooltip:Show()
    if not item.unlearned then
        item.Button.IconHighlight:Show()
        item.Backplate:SetAlpha(Item.PLATE_HOVER)
    end
end

function Item.Leave(item)
    item.Button.IconHighlight:Hide()
    item.Button.IconHighlight:SetAlpha(Item.HOVER)
    item.Backplate:SetAlpha(Item.PLATE)
    if GameTooltip:GetOwner() == item.Button then GameTooltip:Hide() end
end

function Item.Press(item, down)
    if item.info and not item.unlearned then item.Button.IconHighlight:SetAlpha(down and Item.PRESS or Item.HOVER) end
end

-- The spell on the cursor, to drop on an action bar (the game's own pickup).
function Item.Drag(item)
    if not item.info then return end
    Data.Ask("PickupSpellBookItem", item.entry.slot, item.entry.bank)
    item.grabbed = true
    Item.Status(item)
end

-- The game's modified clicks that need no cast: its link in chat (or its name into a macro being written), the
-- pickup. Returns true where one was it.
function Item.Modified(item)
    local info = item.info
    if not info then return false end
    if IsModifiedClick("CHATLINK") then
        local link = Data.Ask("GetSpellBookItemTradeSkillLink", item.entry.slot, item.entry.bank)
            or Data.Ask("GetSpellBookItemLink", item.entry.slot, item.entry.bank)
        local util = rawget(_G, "ChatFrameUtil")
        local insert = util and util.InsertLink or rawget(_G, "ChatEdit_InsertLink")
        if link and insert then insert(link) end
        return true
    elseif IsModifiedClick("PICKUPACTION") then
        Item.Drag(item)
        return true
    end
    return false
end

-- A click on the entry's own icon: what is under no secure button (a fight; a spell still to learn).
local function Clicked(button)
    local item = button:GetParent()
    if Item.Modified(item) then return end
    if Item.Castable(item) and InCombatLockdown() then
        local errors = rawget(_G, "UIErrorsFrame")
        if errors then errors:AddMessage(Item.TEXT.fight, 1, 0.1, 0.1) end
    end
end

local OnClick = ns.Guard(Clicked)
local OnEnter = ns.Guard(function(button) Item.Enter(button:GetParent()) end)
local OnLeave = ns.Guard(function(button) Item.Leave(button:GetParent()) end)
local OnDragStart = ns.Guard(function(button) Item.Drag(button:GetParent()) end)
local OnMouseDown = ns.Guard(function(button) Item.Press(button:GetParent(), true) end)
local OnMouseUp = ns.Guard(function(button) Item.Press(button:GetParent(), false) end)

-------------------------------------------------------------------------------
--  The frame, as the game's template draws it
-------------------------------------------------------------------------------
local function Text(parent, font, lines)
    local text = parent:CreateFontString(nil, "ARTWORK", font)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    if text.SetMaxLines then text:SetMaxLines(lines) end
    text:SetTextColor(Colour("SPELLBOOK_FONT_COLOR", 0.24, 0.15, 0.06))
    text.lines = lines
    return text
end

-- The animation that runs a texture's alpha up and down (the glow of a spell on no bar).
local function Pulse(texture)
    local group = texture:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local up = group:CreateAnimation("Alpha")
    up:SetFromAlpha(0.5) up:SetToAlpha(1) up:SetDuration(0.5) up:SetOrder(1) up:SetSmoothing("OUT")
    local down = group:CreateAnimation("Alpha")
    down:SetFromAlpha(1) down:SetToAlpha(0.5) down:SetDuration(0.5) down:SetOrder(2) down:SetSmoothing("IN")
    return group
end

function Item.Make(parent)
    local item = CreateFrame("Frame", nil, parent)
    item:SetSize(Item.WIDTH, Item.HEIGHT)
    local plate = item:CreateTexture(nil, "BACKGROUND")
    plate:SetAtlas("spellbook-item-backplate", true)
    plate:SetPoint("CENTER", 5, -5)
    plate:SetAlpha(Item.PLATE)
    item.Backplate = plate

    -- The words, centred beside the icon: name, rank, what it takes to learn.
    local box = CreateFrame("Frame", nil, item)
    box:SetPoint("LEFT", Item.TEXT_LEFT, -1)
    box:SetPoint("RIGHT", 0, -1)
    box:SetHeight(1)
    item.TextContainer = box
    item.Name = Text(box, Item.FONT, 3)
    item.Name:SetPoint("TOPLEFT")
    item.Name:SetPoint("TOPRIGHT")
    item.SubName = Text(box, Item.SMALL, 2)
    item.SubName:SetPoint("TOPLEFT", item.Name, "BOTTOMLEFT", 0, -Item.TEXT_GAP)
    item.SubName:SetPoint("TOPRIGHT", item.Name, "BOTTOMRIGHT", 0, -Item.TEXT_GAP)
    item.RequiredLevel = Text(box, Item.SMALL, 1)
    item.RequiredLevel:SetPoint("TOPLEFT", item.SubName, "BOTTOMLEFT", 0, -Item.TEXT_GAP)
    item.RequiredLevel:SetPoint("TOPRIGHT", item.SubName, "BOTTOMRIGHT", 0, -Item.TEXT_GAP)

    local button = CreateFrame("Button", nil, item)
    button:SetSize(Item.BUTTON, Item.BUTTON)
    button:SetPoint("LEFT")
    item.Button = button
    local shadow = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetAtlas("spellbook-item-needtrainer-shadow")
    shadow:SetSize(56, 56)
    shadow:SetPoint("CENTER")
    shadow:Hide()
    button.TrainableShadow = shadow
    local trainer = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    trainer:Hide()
    button.TrainableBackplate = trainer
    local icon = button:CreateTexture(nil, "ARTWORK", nil, -1)
    icon:SetSize(Item.ICON, Item.ICON)
    icon:SetPoint("CENTER")
    button.Icon = icon
    local frameShadow = button:CreateTexture(nil, "ARTWORK", nil, 1)
    frameShadow:SetAtlas("spellbook-item-iconframe-shadow")
    frameShadow:SetPoint("TOPLEFT", -12, 3)
    frameShadow:SetPoint("BOTTOMRIGHT", 2, -8)
    button.BorderShadow = frameShadow
    local border = button:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetAllPoints()
    button.Border = border
    trainer:SetAllPoints(border)
    local highlight = button:CreateTexture(nil, "OVERLAY", nil, 2)
    highlight:SetAllPoints()
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(Item.HOVER)
    highlight:Hide()
    button.IconHighlight = highlight

    -- The sheen that runs over a learned spell's frame now and then.
    local sheen = button:CreateTexture(nil, "OVERLAY", nil, 3)
    sheen:SetAtlas("talents-sheen-node", true)
    sheen:SetAlpha(0.5)
    sheen:SetBlendMode("ADD")
    sheen:SetPoint("RIGHT", button, "LEFT")
    local sheenMask = button:CreateMaskTexture()
    sheenMask:SetAllPoints(border)
    sheen:AddMaskTexture(sheenMask)
    local run = sheen:CreateAnimationGroup()
    run:SetLooping("REPEAT")
    local move = run:CreateAnimation("Translation")
    move:SetOffset(150, 0) move:SetStartDelay(5) move:SetEndDelay(10.5) move:SetDuration(6.5) move:SetOrder(1)
    sheen:Hide()
    button.BorderSheen, button.BorderSheenMask, button.Sheen = sheen, sheenMask, run

    local cover = button:CreateTexture(nil, "OVERLAY", nil, 4)
    cover:SetAllPoints()
    cover:SetColorTexture(0, 0, 0, 0.3)
    cover:Hide()
    button.LevelLinkIconCover = cover
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    cover:AddMaskTexture(mask)
    button.IconMask = mask
    local lock = button:CreateTexture(nil, "OVERLAY", nil, 5)
    lock:SetAtlas("QuestSharing-Padlock", true)
    lock:SetPoint("CENTER")
    lock:Hide()
    button.LevelLinkLock = lock
    local glow = button:CreateTexture(nil, "OVERLAY", nil, 5)
    glow:SetAtlas("spellbook-item-unassigned-glow")
    glow:SetBlendMode("ADD")
    glow:SetPoint("TOPLEFT", -4, 3)
    glow:SetPoint("BOTTOMRIGHT", 3, -3)
    glow:Hide()
    button.ActionBarHighlight, button.Glow = glow, Pulse(glow)

    -- A pet spell's autocast: its corners while it may autocast, the ants running round while it does.
    local auto = CreateFrame("Frame", nil, button)
    auto:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, -1.5)
    auto:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1.5, 1)
    local ants = auto:CreateTexture(nil, "OVERLAY", nil, 0)
    ants:SetAtlas("UI-HUD-ActionBar-PetAutoCast-Ants")
    ants:SetPoint("TOPLEFT", -10, 10)
    ants:SetPoint("BOTTOMRIGHT", 10, -10)
    local antsMask = auto:CreateMaskTexture()
    antsMask:SetAtlas("spellbook-item-petautocast-mask")
    antsMask:SetAllPoints()
    ants:AddMaskTexture(antsMask)
    local spin = ants:CreateAnimationGroup()
    spin:SetLooping("REPEAT")
    local turn = spin:CreateAnimation("Rotation")
    turn:SetDegrees(-360) turn:SetDuration(4) turn:SetOrder(1)
    local corners = auto:CreateTexture(nil, "OVERLAY", nil, 1)
    corners:SetAtlas("spellbook-item-petautocast-corners")
    corners:SetAllPoints()
    ants:Hide()
    auto:Hide()
    button.AutoCastOverlay, button.Ants, button.Spin = auto, ants, spin

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", 2, -2)
    cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetFrameLevel(button:GetFrameLevel())
    button.Cooldown = cooldown

    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnMouseDown", OnMouseDown)
    button:SetScript("OnMouseUp", OnMouseUp)
    return item
end

-------------------------------------------------------------------------------
--  Drawn for its spell (SpellBookItemMixin:UpdateVisuals)
-------------------------------------------------------------------------------
-- The words' box as high as what it holds, so they stand centred beside the icon (the game's TrimTextSpace).
local function Fit(item)
    local total, shown = 0, 0
    for _, text in ipairs({ item.Name, item.SubName, item.RequiredLevel }) do
        local words = text:GetText()
        if words and words ~= "" then
            local line = (text.GetLineHeight and Plain(text:GetLineHeight())) or 14
            local height = math.min(Plain(text:GetStringHeight()) or line, line * text.lines)
            text:SetHeight(height)
            text:Show()
            total, shown = total + height, shown + 1
        else
            text:SetHeight(1)
            text:Hide()
        end
    end
    item.TextContainer:SetHeight(math.max(total + Item.TEXT_GAP * math.max(shown - 1, 0), 1))
end

local function SubName(item, words)
    if (words == nil or words == "") and item.info and item.info.isPassive then words = Item.TEXT.passive end
    item.SubName:SetText(words or "")
    Fit(item)
end

local function Border(item, art)
    local border, at = item.Button.Border, item.unlearned and art.inactiveAt or art.activeAt
    border:SetAtlas(item.unlearned and art.inactive or art.active)
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", item.Button, "TOPLEFT", at[1], at[2])
    border:SetPoint("BOTTOMRIGHT", item.Button, "BOTTOMRIGHT", at[3], at[4])
end

function Item.Set(item, entry)
    if item.cancel then
        item.cancel()
        item.cancel = nil
    end
    item.entry, item.grabbed = entry, false
    local info = Data.Ask("GetSpellBookItemInfo", entry.slot, entry.bank)
    item.info = type(info) == "table" and info or nil
    if not item.info then
        item.Name:SetText("")
        item.SubName:SetText("")
        item.RequiredLevel:SetText("")
        item.Button.Icon:SetTexture(nil)
        return
    end
    info = item.info
    local button = item.Button
    item.Name:SetText(info.name or "")
    button.Icon:SetTexture(info.iconID)
    local art = info.isPassive and Item.ART.Circle or Item.ART.Square
    item.art = art
    button.IconMask:SetAtlas(art.mask)
    button.IconHighlight:SetAtlas(art.highlight)
    button.BorderSheenMask:SetAtlas(art.sheen)

    item.unlearned = info.isOffSpec or info.itemType == Kind("FutureSpell")
    button.Icon:SetDesaturated(item.unlearned and true or false)
    local trainable = false
    local alpha = item.unlearned and Item.UNLEARNED or 1
    item.Name:SetAlpha(alpha)
    item.SubName:SetAlpha(alpha)
    item.RequiredLevel:SetAlpha(alpha)
    if item.unlearned then
        button.Icon:SetVertexColor(Colour("SPELLBOOK_UNLEARNED_TINT_COLOR", 0.8, 0.8, 0.8))
        button.Icon:SetAlpha(Item.UNLEARNED)
        local level = Data.Ask("GetSpellBookItemLevelLearned", entry.slot, entry.bank)
        local now = Plain(UnitLevel("player")) or 0
        local words = ""
        if type(level) == "number" and level > now then
            words = Item.TEXT.at:format(level)
        elseif not info.isOffSpec then
            trainable = true
            words = Item.TEXT.trainable
            button.TrainableBackplate:SetAtlas(art.trainer)
        end
        item.RequiredLevel:SetText(words)
    else
        button.Icon:SetVertexColor(1, 1, 1)
        button.Icon:SetAlpha(1)
        item.RequiredLevel:SetText("")
    end
    button.TrainableShadow:SetShown(trainable)
    button.TrainableBackplate:SetShown(trainable)
    Border(item, art)

    local locked = info.spellID and Core.Ask(rawget(_G, "C_LevelLink") and C_LevelLink.IsSpellLocked, info.spellID) or false
    button.LevelLinkLock:SetShown(locked and true or false)
    button.LevelLinkIconCover:SetShown(locked and true or false)

    -- Its rank: the game's words for it, or the spell's once the game has loaded it (Spell:ContinueOnSpellLoad).
    if info.subName and info.subName ~= "" then
        SubName(item, info.subName)
    else
        SubName(item, "")
        local Spell = rawget(_G, "Spell")
        if info.spellID and Spell and Spell.CreateFromSpellID then
            local spell = Spell:CreateFromSpellID(info.spellID)
            item.cancel = spell:ContinueWithCancelOnSpellLoad(ns.Guard(function()
                item.cancel = nil
                SubName(item, spell:GetSpellSubtext())
            end))
        end
    end

    -- The sheen runs over a learned spell's frame only.
    button.BorderSheen:SetShown(not item.unlearned)
    if item.unlearned then button.Sheen:Stop() elseif not button.Sheen:IsPlaying() then button.Sheen:Play() end
    Item.Cooldown(item)
    Item.Status(item)
    Item.AutoCast(item)
end

-- Its icon anew (an attack's icon changes with the shapeshift form).
function Item.Icon(item)
    if not item.info then return end
    local texture = Data.Ask("GetSpellBookItemTexture", item.entry.slot, item.entry.bank)
    if texture then item.Button.Icon:SetTexture(texture) end
end

-- The cooldown, by the game's duration object (it may be a hidden value in a fight: the swirl takes it as
-- it is), else by its numbers where they are plain.
function Item.Cooldown(item)
    local cooldown = item.Button.Cooldown
    if not item.info then return cooldown:Clear() end
    local book = rawget(_G, "C_SpellBook")
    local getDuration = book and book.GetSpellBookItemCooldownDuration
    if getDuration and cooldown.SetCooldownFromDurationObject then
        local ok, duration = pcall(getDuration, item.entry.slot, item.entry.bank)
        if ok and duration then
            cooldown:SetCooldownFromDurationObject(duration, true)
            return
        end
    end
    local info = Data.Ask("GetSpellBookItemCooldown", item.entry.slot, item.entry.bank)
    if type(info) == "table" and info.isEnabled and type(info.startTime) == "number" and type(info.duration) == "number" then
        cooldown:SetCooldown(info.startTime, info.duration, info.modRate)
    else
        cooldown:Clear()
    end
end

-- Whether the game's book marks the spell missing from your action bars (SpellSearchUtil's rules: a learned,
-- active spell or pet ability, not your auto attack, on no bar of yours), and the glow with it.
function Item.Status(item)
    local info, util = item.info, rawget(_G, "ActionButtonUtil")
    local missing = false
    if info and util and util.ActionBarActionStatus and not item.grabbed and item.entry.status and not item.unlearned
        and not info.isPassive then
        local ok, status
        if info.itemType == Kind("Spell") then
            local spells = rawget(_G, "C_Spell")
            local auto = spells and ((spells.IsAutoAttackSpell and Core.Ask(spells.IsAutoAttackSpell, info.spellID))
                or (spells.IsRangedAutoAttackSpell and Core.Ask(spells.IsRangedAutoAttackSpell, info.spellID)))
            if not auto and util.GetActionBarStatusForSpell then
                ok, status = pcall(util.GetActionBarStatusForSpell, info.actionID, true, false)
            end
        elseif info.itemType == Kind("PetAction") and util.GetActionBarStatusForPetAction then
            ok, status = pcall(util.GetActionBarStatusForPetAction, info.actionID)
        end
        missing = ok and Plain(status) == util.ActionBarActionStatus.MissingFromAllBars or false
    end
    item.missing = missing
    local button = item.Button
    button.ActionBarHighlight:SetShown(missing)
    if missing then
        if not button.Glow:IsPlaying() then button.Glow:Play() end
    else
        button.Glow:Stop()
    end
end

-- A pet spell's autocast (C_SpellBook.GetSpellBookItemAutoCast): may it, does it.
function Item.AutoCast(item)
    local button = item.Button
    local allowed, enabled = false, false
    if item.info and not item.info.isOffSpec then
        allowed, enabled = Data.Ask("GetSpellBookItemAutoCast", item.entry.slot, item.entry.bank)
    end
    button.AutoCastOverlay:SetShown(allowed and true or false)
    button.Ants:SetShown(enabled and true or false)
    if enabled then
        if not button.Spin:IsPlaying() then button.Spin:Play() end
    else
        button.Spin:Stop()
    end
end

-- Whether a click casts it (SpellBookItemMixin:OnIconClick): a learned spell, or a pet's ability.
function Item.Castable(item)
    local info = item.info
    if not info then return false end
    return (info.itemType == Kind("Spell") and not info.isOffSpec and not item.unlearned) or info.itemType == Kind("PetAction")
end
