local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Book item
--  One grey icon in the spellbook: a spell or a rank you have not learned yet.
--
--  It is drawn with the same art as the game's own spellbook entries
--  (SpellBookItemTemplate), but it is a frame of this addon and shares no code
--  with them: the game's entries cast spells and write to the action bars'
--  tables, which a frame made by an addon must never do.
--
--  Drag it onto an action bar button to reserve that button. Shift-click links
--  the spell in chat. Right-click opens a small menu.
--
--  Two marks on the icon: the yellow "!" (top left) says "you get this from a
--  quest, not from the trainer", and the small clock (bottom right) says "a button
--  is reserved for this". The same clock sits on that button on the action bar
--  (Ghosts.lua).
-------------------------------------------------------------------------------
local I = {}
ns.BookItem = I
local S = ns.Sources
local Core = SaneUI.Core

local GOLD = { 1, 0.82, 0.3 }

-- The colour of the spellbook's text, also for Home.lua: the game's own, or its value where
-- the client does not hand it out.
function I.TextColor()
    if SPELLBOOK_FONT_COLOR then return SPELLBOOK_FONT_COLOR:GetRGB() end
    return 0.19, 0.12, 0.06
end

-- The two art sets of the game's entries: square for spells, round for passive ones.
local ART = {
    square = { mask = "spellbook-item-spellicon-mask", hover = "spellbook-item-iconframe-hover",
               border = "spellbook-item-iconframe-inactive", left = -10, top = 1, right = 2, bottom = -5,
               trainable = "spellbook-item-needtrainer-iconframe-backplate" },
    circle = { mask = "talents-node-circle-mask", hover = "spellbook-item-iconframe-passive-hover",
               border = "spellbook-item-iconframe-passive-inactive", left = 0, top = 0, right = 0, bottom = 0,
               trainable = "spellbook-item-needtrainer-passive-backplate" },
}

-------------------------------------------------------------------------------
--  What a spell's third line says, and its tooltip
-------------------------------------------------------------------------------
local function Format(pattern, value)
    local ok, text = pcall(string.format, pattern, value)
    return ok and text or nil
end

-- What has to be learned first: by its name where it is another spell than this one.
local function MissingText(entry)
    local name = entry.missing and ns.Data.Info(entry.missing)
    if name and name ~= entry.name then return ("Needs %s first"):format(name) end
    if entry.missing == entry.prior then return "Needs the rank before it" end
    return "Needs another spell first"
end

local function StatusText(entry)
    local state = entry.state
    if state == "trainable" then
        return SPELLBOOK_TRAINABLE or "Available at a trainer"
    elseif state == "level" then
        return Format(SPELLBOOK_AVAILABLE_AT or "Available at level %d", entry.level) or ("Level " .. entry.level)
    elseif state == "spellfirst" then
        return MissingText(entry)
    elseif state == "talentfirst" then
        return "Needs a talent first"
    elseif state == "quest" then
        return "From a quest"
    elseif state == "talent" then
        return "Talent"
    end
    return "Not learned yet"
end

-- Kept on the entry: it is drawn at every page, and only changes with the state (Sources.lua clears it).
function I.Status(entry)
    local text = entry.status
    if not text then
        text = StatusText(entry)
        entry.status = text
    end
    return text
end

-- Does this reservation wait for this entry? A reservation is for a spell by name, so it is
-- every rank's. But with all ranks listed side by side only the rank that was dragged onto
-- the button counts, or every one of them would carry the mark. family: this entry stands
-- for all its ranks (they are folded into it), so it is every rank's again.
local function Waits(reserved, entry, byRank)
    return reserved.kind == "spell" and reserved.name == entry.name
        and (not byRank or reserved.id == entry.id or not (reserved.id and S.UnlearnedByID(reserved.id)))
end

-- showRanks: "Show all spell ranks", as the caller read it; nil asks the game (a tooltip, a menu).
local function ByRank(entry, family, showRanks)
    if family or not entry.id then return false end
    if showRanks == nil then showRanks = GetCVarBool("ShowAllSpellRanks") end
    return showRanks and true or false
end

-- Every button that waits for this entry, in order: for its tooltip and its menu.
local function ReservedSlots(entry, family)
    local slots, byRank = {}, ByRank(entry, family)
    for slot, reserved in pairs(ns.char and ns.char.reserved or {}) do
        if Waits(reserved, entry, byRank) then slots[#slots + 1] = slot end
    end
    table.sort(slots)
    return slots
end
I.ReservedSlots = ReservedSlots

-- Whether any button waits for it: for the clock on every entry drawn, so no list is made.
local function IsReserved(entry, family, showRanks)
    if not ns.char then return false end
    local byRank = ByRank(entry, family, showRanks)
    for _, reserved in pairs(ns.char.reserved) do
        if Waits(reserved, entry, byRank) then return true end
    end
    return false
end

local function AddLine(text, color)
    GameTooltip:AddLine(text, color[1], color[2], color[3], true)
end

-- A hint for a click or a drag: green, as the game's own "<Click to ...>" lines.
local function Instruction(text)
    if rawget(_G, "GameTooltip_AddInstructionLine") then
        GameTooltip_AddInstructionLine(GameTooltip, text, true)
    else
        GameTooltip:AddLine(text, 0, 1, 0, true)
    end
end

local function ShowTooltip(item)
    local entry = item.entry
    if not entry then return end
    GameTooltip:SetOwner(item.Button, "ANCHOR_RIGHT")
    if not (entry.id and pcall(GameTooltip.SetSpellByID, GameTooltip, entry.id)) then
        GameTooltip:SetText(entry.name)
    end
    GameTooltip:AddLine(" ")
    AddLine(I.Status(entry) .. ".", GOLD)

    -- What the trainer charges, before any discount your reputation gives.
    local coins = entry.cost and entry.cost > 0 and Core.Coins(entry.cost)
    if coins then GameTooltip:AddLine("Cost: " .. coins, 1, 1, 1) end

    for _, slot in ipairs(ReservedSlots(entry, item.family)) do
        AddLine("Reserved on " .. ns.SlotLabel(slot) .. ".", GOLD)
    end
    if not entry.passive then Instruction("Drag onto an action bar button to reserve it.") end
    Instruction("Shift-click: link in chat. Right-click: more.")
    GameTooltip:Show()
end

local function HideTooltip(item)
    GameTooltip:Hide()
    item.Button.IconHighlight:Hide()
end

-------------------------------------------------------------------------------
--  Clicks
-------------------------------------------------------------------------------
-- The game makes the link; a spell it has no link for yet is not linked.
local function Link(entry)
    local link = entry.id and C_Spell.GetSpellLink and C_Spell.GetSpellLink(entry.id)
    if not link then return end
    if ChatFrameUtil and ChatFrameUtil.InsertLink and ChatFrameUtil.InsertLink(link) then return end
    -- No chat line open: open one with the link in it.
    local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
    if open then open(link) end
end

local function Menu(item)
    local entry = item.entry
    if not (entry and MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(item.Button, function(_, root)
        local slots = ReservedSlots(entry, item.family)
        if #slots > 0 then
            root:CreateTitle(entry.name)
            for _, slot in ipairs(slots) do
                root:CreateButton("Remove from " .. ns.SlotLabel(slot), function()
                    ns.Engine.Clear(slot)
                end)
            end
        end
        if #slots == 0 then root:CreateTitle(entry.name) end
        if entry.extra then
            root:CreateButton("Remove from the spellbook's list", function() S.RemoveExtra(entry) end)
        end
    end)
end

local function OnClick(button, mouseButton)
    local item = button:GetParent()
    if not item.entry then return end
    if mouseButton == "RightButton" then
        Menu(item)
    elseif IsModifiedClick and IsModifiedClick("CHATLINK") then
        Link(item.entry)
    end
end

-------------------------------------------------------------------------------
--  The frame
-------------------------------------------------------------------------------
local TEXT_LEFT = 50 -- where the text starts, from the entry's left edge

local function FontString(parent, font, lines)
    local text = parent:CreateFontString(nil, "ARTWORK", font)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    text:SetMaxLines(lines)
    text.lines = lines
    return text
end

function I.Create(parent)
    local item = CreateFrame("Frame", nil, parent)
    item:SetSize(220, 60)

    item.Backplate = item:CreateTexture(nil, "BACKGROUND")
    item.Backplate:SetAtlas("spellbook-item-backplate", true)
    item.Backplate:SetPoint("CENTER", 5, -5)

    local button = CreateFrame("Button", nil, item)
    item.Button = button
    button:SetSize(40, 40)
    button:SetPoint("LEFT")
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.TrainableShadow = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.TrainableShadow:SetAtlas("spellbook-item-needtrainer-shadow")
    button.TrainableShadow:SetSize(56, 56)
    button.TrainableShadow:SetPoint("CENTER")

    button.Border = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.TrainableBackplate = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    button.TrainableBackplate:SetAllPoints(button.Border)

    button.BorderShadow = button:CreateTexture(nil, "ARTWORK", nil, 1)
    button.BorderShadow:SetAtlas("spellbook-item-iconframe-shadow")
    button.BorderShadow:SetPoint("TOPLEFT", -12, 3)
    button.BorderShadow:SetPoint("BOTTOMRIGHT", 2, -8)

    button.Icon = button:CreateTexture(nil, "ARTWORK", nil, -1)
    button.Icon:SetSize(36, 36)
    button.Icon:SetPoint("CENTER")
    button.IconMask = button:CreateMaskTexture()
    button.IconMask:SetAllPoints(button.Icon)
    button.Icon:AddMaskTexture(button.IconMask)

    button.IconHighlight = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.IconHighlight:SetAllPoints()
    button.IconHighlight:SetBlendMode("ADD")
    button.IconHighlight:Hide()

    -- A quest reward: the trainer does not sell this one.
    button.Quest = button:CreateTexture(nil, "OVERLAY", nil, 5)
    button.Quest:SetAtlas(ns.QUEST_MARK, false)
    button.Quest:SetSize(22, 22)
    button.Quest:SetPoint("TOPLEFT", -9, 8)

    -- A clock in the corner: this spell has a button waiting for it.
    button.Reserved = button:CreateTexture(nil, "OVERLAY", nil, 5)
    button.Reserved:SetAtlas(ns.RESERVED_MARK, false)
    button.Reserved:SetSize(18, 18)
    button.Reserved:SetPoint("BOTTOMRIGHT", 5, -5)

    -- The three lines of text, kept centred on the icon's middle like the game's.
    local text = CreateFrame("Frame", nil, item)
    item.TextContainer = text
    text:SetPoint("LEFT", TEXT_LEFT, -1)
    text:SetSize(220 - TEXT_LEFT, 1)
    item.Name = FontString(text, "SystemFont_Large", 3)
    item.SubName = FontString(text, "SystemFont_Med1", 2)
    item.RequiredLevel = FontString(text, "SystemFont_Med1", 1)
    item.lines = { item.Name, item.SubName, item.RequiredLevel } -- in their order, for every draw

    button:SetScript("OnEnter", function(self)
        local owner = self:GetParent()
        if owner.highlight then self.IconHighlight:Show() end
        ShowTooltip(owner)
    end)
    button:SetScript("OnLeave", function(self) HideTooltip(self:GetParent()) end)
    button:SetScript("OnHide", function(self)
        if GameTooltip:GetOwner() == self then HideTooltip(self:GetParent()) end
    end)
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnDragStart", function(self)
        local entry = self:GetParent().entry
        if entry and not entry.passive then
            GameTooltip:Hide()
            ns.Drag.Start(entry)
        end
    end)
    button:SetScript("OnDragStop", function() ns.Drag.Stop() end)
    return item
end

-- Stack the lines that have text and give the block their height, so it stays centred.
-- Every line gets its width as a number: a line knows at once where to wrap, also on an
-- entry that has not been placed on a page yet.
local function LayoutText(item, width)
    local height, anchor = 0, nil
    item.TextContainer:SetWidth(width)
    for _, text in ipairs(item.lines) do
        text:ClearAllPoints()
        text:SetWidth(width)
        local content = text:GetText()
        if content and content ~= "" then
            if anchor then
                text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
                height = height + 2
            else
                text:SetPoint("TOPLEFT")
            end
            local own = math.min(text:GetStringHeight() or 0, (text:GetLineHeight() or 0) * text.lines)
            text:SetHeight(math.max(own, 1))
            text:Show()
            height = height + own
            anchor = text
        else
            text:Hide()
        end
    end
    item.TextContainer:SetHeight(math.max(height, 1))
end

-- style: how the game's own entries look right now (a skin may have changed them):
--   text, textFont  colour { r, g, b } of the lines     backplate  alpha of the plate
--   border, borderDesaturation                          highlight  false: no hover glow
-- note: the third line, where it should say something else than the spell's state (Home.lua).
-- family: the entry stands for all ranks of its spell (Book.lua folded them into it).
-- showRanks: "Show all spell ranks", read once by the caller for the whole page; nil asks the game.
function I.Set(item, entry, style, width, note, family, showRanks)
    style = style or {}
    item.entry, item.family = entry, family
    item.highlight = style.highlight ~= false
    item:SetWidth(width or 220)

    local art = entry.passive and ART.circle or ART.square
    local button = item.Button
    button.Icon:SetTexture(S.Icon(entry))
    button.Icon:SetDesaturated(true)
    if SPELLBOOK_UNLEARNED_TINT_COLOR then
        button.Icon:SetVertexColor(SPELLBOOK_UNLEARNED_TINT_COLOR:GetRGB())
    end
    button.Icon:SetAlpha(0.6)
    button.IconMask:SetAtlas(art.mask, false)
    button.IconHighlight:SetAtlas(art.hover, false)
    button.IconHighlight:SetAlpha(0.35)

    button.Border:SetAtlas(art.border, false)
    button.Border:ClearAllPoints()
    button.Border:SetPoint("TOPLEFT", button, "TOPLEFT", art.left, art.top)
    button.Border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", art.right, art.bottom)
    button.Border:SetAlpha(style.border or 1)
    if button.Border.SetDesaturation then button.Border:SetDesaturation(style.borderDesaturation or 0) end

    -- The warm plate the game puts behind a spell the trainer can teach you now.
    local trainable = entry.state == "trainable"
    button.TrainableBackplate:SetAtlas(art.trainable, false)
    button.TrainableBackplate:SetShown(trainable)
    button.TrainableShadow:SetShown(trainable)

    button.Quest:SetShown(entry.quest ~= nil)
    button.Reserved:SetShown(IsReserved(entry, family, showRanks))
    item.Backplate:SetAlpha(style.backplate or 0.25)

    local r, g, b
    if style.text then r, g, b = style.text[1], style.text[2], style.text[3] else r, g, b = I.TextColor() end
    for _, text in ipairs(item.lines) do
        text:SetTextColor(r, g, b)
        text:SetAlpha(0.6)
    end
    item.Name:SetText(entry.name)
    item.SubName:SetText(entry.sub or (entry.passive and (SPELL_PASSIVE or "Passive")) or "")
    item.RequiredLevel:SetText(note or I.Status(entry))
    LayoutText(item, math.max((width or 220) - TEXT_LEFT, 40))

    if GameTooltip:GetOwner() == button then ShowTooltip(item) end
end
