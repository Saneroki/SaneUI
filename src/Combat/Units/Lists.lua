local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Lists
--  Your marks of auras, kept in the module's settings by the spell's number with
--  its name, three lists:
--      Important      on the unit frames shown in front of the rest, whoever cast
--                     them, with a glow (Auras.lua); a glow in the game's list of
--                     your buffs and debuffs (BuffList.lua)
--      Unimportant    never on the unit frames, faded in that list
--      Hidden         out of sight in that list, until the mouse is on it
--  A spell is on one of them at most: put on one, it leaves the others.
--
--  Filled from a right click on an aura (Lists.Entries, in either's menu), and in
--  a window of its own (/sane auras, and the menu's Aura lists): a box to add a
--  spell by its number or its name (a name only where the game knows the
--  spell by it: one of yours), the lists side by side, each spell with its
--  icon, name and number and an X to take it off. Under them, what the game
--  lets the lists do.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Lists = {}
ns.AuraLists = Lists

Lists.WIDTH, Lists.HEIGHT = 740, 420
Lists.INSET = 12
Lists.LINE = 24 -- a spell's line
Lists.ICON = 18
Lists.TOP = 62  -- from the window's top to the lists' titles, under the box
Lists.KEYS = { white = "auraWhite", black = "auraBlack", hidden = "auraHidden" } -- the lists' settings
Lists.ORDER = { "white", "black", "hidden" }
Lists.WORDS = { white = "auraImportant", black = "auraUnimportant", hidden = "auraHidden" } -- their words in ns.TEXT

local frame, window, box, status
local columns = {} -- [which] = { scroll, child, lines }
local names        -- [a spell's name] = its list, made when asked after a change

-- A list: { [spell number] = its name }.
local function List(which)
    local key = Lists.KEYS[which]
    ns.options[key] = type(ns.options[key]) == "table" and ns.options[key] or {}
    return ns.options[key]
end

-- A spell's picture, by its number.
local function Icon(id)
    local spells = rawget(_G, "C_Spell")
    return spells and Core.Ask(spells.GetSpellTexture, id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- The window's lists as they are now.
local function Fill()
    if not frame then return end
    for which, column in pairs(columns) do
        local entries = {}
        for id, name in pairs(List(which)) do entries[#entries + 1] = { id = tonumber(id), name = tostring(name) } end
        table.sort(entries, function(a, b) return a.name:lower() < b.name:lower() end)
        for index, entry in ipairs(entries) do
            local line = column.lines[index] or column.Line(index)
            line.entry = entry
            line.icon:SetTexture(Icon(entry.id))
            line.name:SetText(entry.name)
            line.number:SetText(entry.id or "")
            line:Show()
        end
        for index = #entries + 1, #column.lines do column.lines[index]:Hide() end
        column.empty:SetShown(#entries == 0)
        column.child:SetHeight(math.max(#entries * Lists.LINE, 1))
    end
end

-- A list changed: every frame's auras anew, the game's list, the window.
local function Changed()
    names = nil
    ns.UnitAuras.Refresh()
    ns.BuffList.Style()
    Fill()
end

-- The list of a spell by its name, any rank of it: "white", "black", "hidden" or nil.
function Lists.Mark(name)
    if not names then
        names = {}
        for _, which in ipairs(Lists.ORDER) do
            for _, spell in pairs(List(which)) do names[spell] = which end
        end
    end
    return names[name]
end

-- A spell on a list: off the others.
function Lists.Put(which, spell)
    local id = tonumber(spell and spell.id)
    if not id then return end
    for _, other in ipairs(Lists.ORDER) do List(other)[id] = nil end
    List(which)[id] = spell.name or tostring(id)
    Changed()
    if status then status:SetText(ns.TEXT.listsPut:format(spell.name or id, ns.TEXT[Lists.WORDS[which]])) end
end

function Lists.Take(which, id)
    List(which)[id] = nil
    Changed()
end

-- A menu's lines for an aura: the three marks, one at most, a tick taken off again by a click; then the window.
function Lists.Entries(root, spell)
    for _, which in ipairs(Lists.ORDER) do
        root:CreateCheckbox(ns.TEXT[Lists.WORDS[which]], ns.Guard(function() return Lists.Mark(spell.name) == which end),
            ns.Guard(function()
                if Lists.Mark(spell.name) ~= which then return Lists.Put(which, spell) end
                for id, name in pairs(List(which)) do
                    if name == spell.name then List(which)[id] = nil end
                end
                Changed()
            end))
    end
    root:CreateDivider()
    root:CreateButton(ns.TEXT.auraLists, ns.Guard(function() Lists.Open() end))
end

-- The spell typed into the box: by its number, or by its name where the game knows it so.
local function Typed()
    local text = (box:GetText() or ""):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    local spells = rawget(_G, "C_Spell")
    local id = tonumber(text)
    if id then
        local name = spells and Core.Ask(spells.GetSpellName, id)
        if type(name) == "string" then return { id = id, name = name } end
        return nil
    end
    local info = spells and Core.Ask(spells.GetSpellInfo, text)
    if type(info) == "table" and type(Plain(info.spellID)) == "number" then return { id = info.spellID, name = info.name } end
    return nil
end

local function Add(which)
    local spell = Typed()
    if not spell then return status:SetText(ns.TEXT.listsUnknown) end
    box:SetText("")
    box:ClearFocus()
    Lists.Put(which, spell)
end

local function Tip(line)
    if not line.entry or not line.entry.id then return end
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    if not pcall(GameTooltip.SetSpellByID, GameTooltip, line.entry.id) then GameTooltip:SetText(line.entry.name) end
    GameTooltip:Show()
end

-- One list, its title over it, in a scroll area; its lines made as needed.
local function Column(which, left, right)
    local inside, I = window.inside, Lists.INSET
    local title = inside:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", inside, "TOPLEFT", left, -(I + Lists.TOP))
    title:SetText(ns.TEXT[Lists.WORDS[which]])
    local scroll = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOM", inside, "BOTTOM", 0, I + 40)
    scroll:SetPoint("RIGHT", inside, "LEFT", right - 24, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(right - left - 30, 1)
    scroll:SetScrollChild(child)
    local empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 4, -6)
    empty:SetText(ns.TEXT.listsEmpty)
    local column = { scroll = scroll, child = child, lines = {}, empty = empty }
    function column.Line(index)
        local line = CreateFrame("Frame", nil, child)
        line:SetHeight(Lists.LINE)
        line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Lists.LINE)
        line:SetPoint("RIGHT", child, "RIGHT", 0, 0)
        line:EnableMouse(true)
        line:SetScript("OnEnter", ns.Guard(Tip))
        line:SetScript("OnLeave", GameTooltip_Hide)
        line.icon = line:CreateTexture(nil, "ARTWORK")
        line.icon:SetSize(Lists.ICON, Lists.ICON)
        line.icon:SetPoint("LEFT", 2, 0)
        line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local take = CreateFrame("Button", nil, line, "UIPanelCloseButton")
        take:SetSize(Lists.LINE, Lists.LINE)
        take:SetPoint("RIGHT", line, "RIGHT", 0, 0)
        take:SetScript("OnClick", ns.Guard(function() if line.entry then Lists.Take(which, line.entry.id) end end))
        line.number = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        line.number:SetPoint("RIGHT", take, "LEFT", -2, 0)
        line.name = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        line.name:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
        line.name:SetPoint("RIGHT", line.number, "LEFT", -6, 0)
        line.name:SetJustifyH("LEFT")
        line.name:SetWordWrap(false)
        column.lines[index] = line
        return line
    end
    columns[which] = column
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Lists.WIDTH, Lists.HEIGHT)
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = ns.store, key = "auraListsPlace", title = ns.TEXT.listsTitle, edge = false,
        dock = false, sizable = false, first = { point = "CENTER", x = 0, y = 60 },
        close = function() frame:Hide() end,
    })
    local inside, I = window.inside, Lists.INSET
    local label = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", I, -I)
    label:SetText(ns.TEXT.listsInput)
    box = CreateFrame("EditBox", nil, inside, "InputBoxTemplate")
    box:SetSize(220, 22)
    box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 6, -4)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", ns.Guard(function() Add("white") end))
    box:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    local last = box
    local third = (Lists.WIDTH - 2 * I) / #Lists.ORDER
    for index, which in ipairs(Lists.ORDER) do
        local add = CreateFrame("Button", nil, inside, "UIPanelButtonTemplate")
        add:SetSize(120, 22)
        add:SetPoint("LEFT", last, "RIGHT", index == 1 and 10 or 6, 0)
        add:SetText(ns.TEXT[Lists.WORDS[which]])
        add:SetScript("OnClick", ns.Guard(function() Add(which) end))
        last = add
        Column(which, I + (index - 1) * third, I + index * third)
    end
    local rule = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    rule:SetPoint("BOTTOMLEFT", I, I)
    rule:SetPoint("RIGHT", inside, "RIGHT", -I, 0)
    rule:SetJustifyH("LEFT")
    rule:SetText(ns.TEXT.listsRule)
    status = inside:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", rule, "TOPLEFT", 0, 6)
    status:SetPoint("RIGHT", inside, "RIGHT", -I, 0)
    status:SetJustifyH("LEFT")
    frame:HookScript("OnShow", ns.Guard(Fill))
    window:Place()
end

function Lists.Open()
    if ns.off then return end
    if not frame then Build() end
    status:SetText("")
    frame:Show()
    Fill()
end

function Lists.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    Lists.Open()
end

-- Standing down: the window goes.
function Lists.Hide()
    if frame then frame:Hide() end
end
