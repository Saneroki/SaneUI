local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Loot - Items
--  The options' tab Your items (Saneroki, 2026-10-29: a list in the settings
--  to see at a glance which items are taken at once and which are not). The
--  things met in loot of late (options.seen, kept by the loot window) and those
--  the player gave a word on (options.kept), in two parts:
--      Taken at once      ticked; why at the right: your word, Everything, or
--                         the kind whose switch takes it (Trade goods, ...)
--      Left for a click   not ticked; your word: never, where you said so
--  A tick changes it for that item alone: the player's word, over the
--  switches; a word that says what the switches say anyway is dropped. Forget
--  the rest takes the things without a word off the list (until met again).
--  Drawn in the game's own parts, as the rest of the options page; an item the
--  game has not told yet is asked for (GET_ITEM_INFO_RECEIVED shows it).
--
--      Items.Build(child)   fills the tab's scroll area; returns its height
--      Items.Refresh()      the list anew, as the words and switches are now
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Items = {}
ns.Items = Items

local LINE = 26   -- a line of the list
local ICON = 20
local HEAD = 24   -- a part's heading
local TOP = 54    -- the words over the list and the button

local child, intro
local heads = {}
local pool = {}   -- the lines, made once and used again
local asked = {}  -- [id] = true: the game was asked for the item

-- The item's line (Slots.Item), or a bare one while the game has not told it yet (asked for once).
local function Line(id)
    local line = ns.Slots.Item(id)
    if line then return line end
    if not asked[id] then
        asked[id] = true
        local item = rawget(_G, "C_Item")
        if item and item.RequestLoadItemDataByID then Core.Ask(item.RequestLoadItemDataByID, id) end
    end
    return { kind = "item", id = id, name = ns.TEXT.itemsWaiting, quality = 1, waiting = true }
end

-- Why a line is taken at once, or left: the words at the right of its line.
local function Why(line, rule)
    if rule == "list" then return ns.TEXT.whyList end
    if ns.options.kept[line.id] == false then return ns.TEXT.whyNever end
    if rule == "takeAll" then return ns.TEXT.whyAll end
    return rule and ns.TEXT[rule] or ""
end

-- Every item to list: those met of late in their order, then those with a word not met of late.
local function Entries()
    local options, list, listed = ns.options, {}, {}
    local function Add(id)
        id = tonumber(id)
        if not id or listed[id] then return end
        listed[id] = true
        local line = Line(id)
        local rule = ns.Slots.Rule(line, options)
        list[#list + 1] = { id = id, line = line, taken = rule ~= nil, why = Why(line, rule) }
    end
    for _, id in ipairs(options.seen) do Add(id) end
    local words = {}
    for id in pairs(options.kept) do words[#words + 1] = id end
    table.sort(words, function(a, b) return tostring(a) < tostring(b) end)
    for _, id in ipairs(words) do Add(id) end
    return list
end

-- A tick: the player's word on the item, unless it says what the switches say anyway.
local function Toggle(check)
    local entry = check:GetParent().entry
    if not entry then return end
    local options = ns.options
    local want = not entry.taken
    local bySwitches = ns.Slots.Rule(entry.line, options, false) ~= nil
    if want == bySwitches then options.kept[entry.id] = nil else options.kept[entry.id] = want end
    Items.Refresh()
    ns.Safe("window", ns.Window.Fill)
end

local function Tip(line)
    local entry = line.entry
    if not entry then return end
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID and not entry.line.waiting then
        GameTooltip:SetItemByID(entry.id)
    else
        GameTooltip:SetText(entry.line.name)
    end
    GameTooltip:Show()
end

local function NewLine()
    local line = CreateFrame("Frame", nil, child)
    line:SetHeight(LINE)
    line:EnableMouse(true)
    line:SetScript("OnEnter", ns.Guard(Tip))
    line:SetScript("OnLeave", ns.Guard(function() GameTooltip_Hide() end))
    line.check = CreateFrame("CheckButton", nil, line, "UICheckButtonTemplate")
    line.check:SetSize(LINE, LINE)
    line.check:SetPoint("LEFT", 0, 0)
    line.check:SetScript("OnClick", ns.Guard(Toggle))
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(ICON, ICON)
    line.icon:SetPoint("LEFT", line.check, "RIGHT", 4, 0)
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.why = line:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    line.why:SetPoint("RIGHT", line, "RIGHT", -8, 0)
    line.why:SetJustifyH("RIGHT")
    line.name = line:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    line.name:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.name:SetPoint("RIGHT", line.why, "LEFT", -8, 0)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    return line
end

local function Head(index, text)
    local head = heads[index]
    if not head then
        head = child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        head:SetJustifyH("LEFT")
        heads[index] = head
    end
    head:SetText(text)
    return head
end

-- The list anew: the taken ones under their heading, then the rest under theirs. The tab's height follows.
function Items.Refresh()
    if not child then return end
    local entries = Entries()
    local parts = { { text = ns.TEXT.itemsTaken, list = {} }, { text = ns.TEXT.itemsLeft, list = {} } }
    for _, entry in ipairs(entries) do
        local into = entry.taken and parts[1].list or parts[2].list
        into[#into + 1] = entry
    end
    local y, used = -TOP, 0
    for index, part in ipairs(parts) do
        local head = Head(index, part.text)
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", child, "TOPLEFT", 8, y - 4)
        y = y - HEAD
        for _, entry in ipairs(part.list) do
            used = used + 1
            local line = pool[used] or NewLine()
            pool[used] = line
            line.entry = entry
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", child, "TOPLEFT", 8, y)
            line:SetPoint("RIGHT", child, "RIGHT", -8, 0)
            line.check:SetChecked(entry.taken)
            line.icon:SetTexture(entry.line.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            line.name:SetText(entry.line.name)
            line.name:SetTextColor(ns.Row.Color(entry.line.quality))
            line.why:SetText(entry.why)
            line:Show()
            y = y - LINE
        end
        y = y - 8
    end
    for index = used + 1, #pool do
        pool[index]:Hide()
        pool[index].entry = nil
    end
    intro:SetText(#entries == 0 and (ns.TEXT.itemsIntro .. "\n" .. ns.TEXT.itemsNone) or ns.TEXT.itemsIntro)
    local height = -y + 8
    child:SetHeight(height)
    return height
end

-- Forget the rest: the things without the player's word off the list.
local function Forget()
    wipe(ns.options.seen)
    Items.Refresh()
end

function Items.Build(frame)
    child = frame
    intro = child:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 8, -8)
    intro:SetPoint("RIGHT", -128, 0)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    local forget = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    forget:SetSize(112, 22)
    forget:SetPoint("TOPRIGHT", -8, -8)
    forget:SetText(ns.TEXT.itemsForget)
    forget:SetScript("OnClick", ns.Guard(Forget))
    forget:SetScript("OnEnter", ns.Guard(function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.TEXT.itemsForget)
        GameTooltip:AddLine(ns.TEXT.itemsForgetTip, 1, 1, 1, true)
        GameTooltip:Show()
    end))
    forget:SetScript("OnLeave", ns.Guard(function() GameTooltip_Hide() end))
    Items.forget = forget
    -- shown anew each time the tab shows, and when the game tells an item it was asked for
    child:HookScript("OnShow", ns.Guard(Items.Refresh))
    local later = Core.Later(function() ns.Guarded(Items.Refresh) end, 0.2)
    ns.On("GET_ITEM_INFO_RECEIVED", ns.Guard(function() if child:IsVisible() then later() end end))
    return Items.Refresh()
end
