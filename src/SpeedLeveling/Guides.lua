local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling - Guides
--  The window of the guides (/sane guides, or the last line of the guide's
--  menu): at the left the guides, those that come in this game's guide pack
--  and those kept, under their groups' headings; a click follows one (those
--  not for this character or this game greyed), the cross beside a kept one
--  forgets it (asked first). At the right, at the top, a line for the import string of
--  the guides you bought, or a large guide's text: what is pasted there is
--  gathered as it comes (the line itself holds a character only, so megabytes
--  do not hold the game up) and, once the paste is over, opened for your
--  account (Unlock.lua) or read as a guide; under it a box to paste a guide's
--  text into, and Read, which keeps each guide of it (an import string pasted
--  there is opened too). It says how many were kept and which lines could not
--  be read.
--  A panel of SaneUI's (Core.Window), made when first opened.
--
--      Guides.Open()     shown, or hidden again
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Guides = {}
ns.Guides = Guides

Guides.LIST = 230   -- the list's width
Guides.ROW = 20     -- a row of the list, high
Guides.INSET = 12
Guides.QUIET = 0.25 -- seconds without a character before a paste counts as over

local frame, window, list, child, box, status, line, lineHint
local rows, heads = {}, {} -- the list's guides; its groups' headings
local pasted, waited = {}, 0 -- the characters of the import line's paste so far; the time since the last
local listening = false      -- the line waits for its paste to be over
local Pasted, Opening        -- the line's and the window's OnUpdate while they wait, guarded once (below)

-- A group's heading in the list, at y.
local function Heading(index, words, y)
    local head = heads[index]
    if not head then
        head = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        head:SetJustifyH("LEFT")
        head:SetWordWrap(false)
        heads[index] = head
    end
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y - 4)
    head:SetPoint("RIGHT", child, "RIGHT", -2, 0)
    head:SetText(words)
    head:Show()
end

local function Fill()
    local kept = ns.Guide.Kept()
    local chosen = ns.Guide.Chosen()
    local y, groups, group = 0, 0, nil
    for index, guide in ipairs(kept) do
        if guide.group ~= group then
            group, groups = guide.group, groups + 1
            Heading(groups, group ~= "" and group or ns.TEXT.ungrouped, y)
            y = y + Guides.ROW
        end
        local row = rows[index]
        if not row then
            row = CreateFrame("Button", nil, child)
            row:SetHeight(Guides.ROW)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 4, 0)
            row.text:SetPoint("RIGHT", -22, 0)
            row.text:SetJustifyH("LEFT")
            row.text:SetWordWrap(false)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            row.forget = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            row.forget:SetSize(20, 20)
            row.forget:SetPoint("RIGHT", 0, 0)
            row.forget:SetScript("OnClick", ns.Guard(function(button)
                local key, name = button:GetParent().key, button:GetParent().name
                Core.Confirm(ns.TEXT.forget, name, function() ns.Guide.Remove(key) Fill() end)
            end))
            row:SetScript("OnClick", ns.Guard(function(self)
                if self.mine then
                    ns.Guide.Choose(self.key)
                    Fill()
                end
            end))
            rows[index] = row
        end
        row.key, row.name, row.mine = guide.key, guide.title or guide.name, guide.mine
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", child, "RIGHT")
        y = y + Guides.ROW
        local words = guide.subgroup ~= "" and (row.name .. "  |cff999999" .. guide.subgroup .. "|r") or row.name
        row.text:SetText((guide.key == chosen and "> " or "") .. words)
        row.text:SetFontObject(guide.mine and "GameFontHighlightSmall" or "GameFontDisableSmall")
        row.forget:SetShown(not guide.pack) -- a pack's guide comes with it: nothing to forget
        row:Show()
    end
    for index = #kept + 1, #rows do rows[index]:Hide() end
    for index = groups + 1, #heads do heads[index]:Hide() end
    child:SetHeight(math.max(1, y))
    if #kept == 0 and status:GetText() == "" then status:SetText(ns.TEXT.noneKept) end
end

-- What a read kept, in words: how many, their names, the lines that could not be read (the first four).
local function Said(names, problems)
    if #names == 0 and #problems == 0 then return ns.TEXT.noneRead end
    local said = #names > 0 and ns.TEXT.read:format(#names, table.concat(names, ", ")) or ns.TEXT.noneRead
    if #problems > 0 then
        said = said .. "\n" .. ns.TEXT.unread:format(#problems) .. "\n"
            .. table.concat(problems, "\n", 1, math.min(#problems, 4))
    end
    return said
end

-- The guides of a text kept; an import string opened first, how far it is shown meanwhile. done() once it is over.
local function Take(text, done)
    if ns.Unlock.Looks(text) then
        status:SetText(ns.TEXT.opening:format(0))
        frame:SetScript("OnUpdate", Opening)
        local started = ns.Unlock.Open(text, function(texts, problem)
            frame:SetScript("OnUpdate", nil)
            if not texts then
                status:SetText(problem)
            else
                local names, problems = ns.Guide.AddAll(texts, true)
                status:SetText(Said(names, problems))
            end
            Fill()
            if done then done() end
        end)
        if not started then
            frame:SetScript("OnUpdate", nil)
            status:SetText(ns.TEXT.openingAlready)
        end
        return
    end
    local names, problems = ns.Guide.AddAll(ns.Format.Parts(text), false)
    status:SetText(Said(names, problems))
    Fill()
    if done then done() end
end

local function Read()
    local text = box:GetText()
    if not text:find("%S") then return end
    Take(text, function() box:SetText("") end)
end

-------------------------------------------------------------------------------
--  The import line: a paste gathered as it comes
-------------------------------------------------------------------------------
local function LineReset()
    wipe(pasted)
    waited, listening = 0, false
    line:SetScript("OnUpdate", nil)
end

Pasted = ns.Guard(function(_, elapsed)
    waited = waited + elapsed
    if waited < Guides.QUIET then return end
    local text = table.concat(pasted)
    LineReset()
    line:SetText("")
    line:ClearFocus()
    if not text:find("%S") then return end
    -- An import string, or a guide's text with its lines; a guide's text whose line breaks did not come through
    -- cannot be read: then the box below, which keeps them.
    if not ns.Unlock.Looks(text) and not text:find("\n") then
        status:SetText(ns.TEXT.notString)
        return
    end
    lineHint:SetText(ns.TEXT.pastedString:format(#text))
    Take(text, function() lineHint:SetText(ns.TEXT.stringHint) end)
end)

Opening = ns.Guard(function()
    local share = ns.Unlock.Shown()
    if share then status:SetText(ns.TEXT.opening:format(math.floor(share * 100))) end
end)

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(660, 460)
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = Core.Store(ns.name), key = "guidesPlace", title = ns.TEXT.guides, edge = false,
        dock = false, sizable = true, minWidth = 520, minHeight = 320,
        first = { point = "CENTER", x = 0, y = 40, width = 660, height = 460 },
        close = function() frame:Hide() end,
    })
    local inside, I = window.inside, Guides.INSET

    list = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    list:SetPoint("TOPLEFT", I, -I)
    list:SetPoint("BOTTOMLEFT", I, I)
    list:SetWidth(Guides.LIST)
    child = CreateFrame("Frame", nil, list)
    child:SetSize(Guides.LIST, 1)
    list:SetScrollChild(child)

    -- The import line, its words over it.
    local lineTitle = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lineTitle:SetPoint("TOPLEFT", list, "TOPRIGHT", I + 24, 0)
    lineTitle:SetText(ns.TEXT.stringTitle)
    line = CreateFrame("EditBox", nil, inside, "InputBoxTemplate")
    line:SetHeight(22)
    line:SetMultiLine(true) -- so a guide's text pasted here keeps its line breaks
    line:SetPoint("TOPLEFT", lineTitle, "BOTTOMLEFT", 6, -4)
    line:SetPoint("RIGHT", inside, "RIGHT", -(I + 6), 0)
    line:SetAutoFocus(false)
    line:SetScript("OnEditFocusGained", ns.Guard(function(self)
        LineReset()
        self:SetText("")
        self:SetMaxBytes(1)
    end))
    line:SetScript("OnEditFocusLost", ns.Guard(function(self) self:SetMaxBytes(0) end))
    line:SetScript("OnChar", ns.Guard(function(self, char)
        pasted[#pasted + 1] = char
        waited = 0
        if not listening then
            listening = true
            self:SetScript("OnUpdate", Pasted)
        end
    end))
    line:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    lineHint = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lineHint:SetPoint("TOPLEFT", line, "BOTTOMLEFT", -6, -4)
    lineHint:SetPoint("RIGHT", inside, "RIGHT", -I, 0)
    lineHint:SetJustifyH("LEFT")
    lineHint:SetText(ns.TEXT.stringHint)

    local hint = inside:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", lineHint, "BOTTOMLEFT", 0, -14)
    hint:SetText(ns.TEXT.pasteHint)

    local scroll = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", -(I + 24), I + 74)
    box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetMaxLetters(0)
    box:SetFontObject("ChatFontNormal")
    box:SetWidth(300)
    box:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    scroll:SetScrollChild(box)
    scroll:SetScript("OnSizeChanged", ns.Guard(function(self, width) box:SetWidth(width) end))
    local back = scroll:CreateTexture(nil, "BACKGROUND")
    back:SetPoint("TOPLEFT", -4, 4)
    back:SetPoint("BOTTOMRIGHT", 4, -4)
    back:SetColorTexture(0, 0, 0, 0.35)
    -- A click anywhere on the box's ground puts the cursor in it.
    scroll:SetScript("OnMouseDown", ns.Guard(function() box:SetFocus() end))

    local read = CreateFrame("Button", nil, inside, "UIPanelButtonTemplate")
    read:SetSize(100, 22)
    read:SetPoint("TOPRIGHT", scroll, "BOTTOMRIGHT", 24, -8)
    read:SetText(ns.TEXT.readButton)
    read:SetScript("OnClick", ns.Guard(Read))

    status = inside:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -10)
    status:SetPoint("RIGHT", read, "LEFT", -10, 0)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetText("")

    frame:HookScript("OnShow", ns.Guard(Fill))
    window:Place()
end

function Guides.Open()
    if ns.off then return end
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end

function Guides.GiveBack()
    if frame then frame:Hide() end
end
