local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Guides
--  The window of the guides kept as text (/sane guides, or Paste a guide in
--  the guide's menu): at the left the guides kept, a click runs one (those not
--  for this character greyed), the cross beside one forgets it (asked first);
--  at the right a box to paste a guide's text into, and Read, which keeps each
--  guide of it and says how many and which lines could not be read.
--  A panel of Sane UI's (Core.Window), made when first opened.
--
--      Guides.Open()     shown, or hidden again
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Guides = {}
ns.Guides = Guides

Guides.LIST = 210   -- the list's width
Guides.ROW = 20     -- a row of the list, high
Guides.INSET = 12

local frame, window, list, child, box, status
local rows = {}

local function Fill()
    local kept = ns.Guide.Kept()
    local chosen = ns.Guide.Chosen()
    for index, guide in ipairs(kept) do
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
                local name = button:GetParent().name
                Core.Confirm(ns.TEXT.forget, name, function() ns.Guide.Remove(name) Fill() end)
            end))
            row:SetScript("OnClick", ns.Guard(function(self)
                if self.mine then
                    ns.Guide.Choose(self.name)
                    Fill()
                end
            end))
            rows[index] = row
        end
        row.name, row.mine = guide.name, guide.mine
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(index - 1) * Guides.ROW)
        row:SetPoint("RIGHT", child, "RIGHT")
        local words = guide.group ~= "" and (guide.name .. "  |cff999999" .. guide.group .. "|r") or guide.name
        row.text:SetText((guide.name == chosen and "> " or "") .. words)
        row.text:SetFontObject(guide.mine and "GameFontHighlightSmall" or "GameFontDisableSmall")
        row:Show()
    end
    for index = #kept + 1, #rows do rows[index]:Hide() end
    child:SetHeight(math.max(1, #kept * Guides.ROW))
    if #kept == 0 then status:SetText(ns.TEXT.noneKept) end
end

local function Read()
    local text = box:GetText()
    if not text:find("%S") then return end
    local names, problems = ns.Guide.Add(text)
    if #names == 0 then
        status:SetText(ns.TEXT.noneRead)
    else
        local said = ns.TEXT.read:format(#names, table.concat(names, ", "))
        if #problems > 0 then
            said = said .. "\n" .. ns.TEXT.unread:format(#problems) .. "\n" .. table.concat(problems, "\n", 1,
                                                                                         math.min(#problems, 4))
        end
        status:SetText(said)
        box:SetText("")
    end
    Fill()
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(620, 440)
    frame:Hide()
    window = Core.Window.New(frame, {
        kind = "panel", store = Core.Store(ns.name), key = "guidesPlace", title = ns.TEXT.guides, edge = false,
        dock = false, sizable = true, minWidth = 480, minHeight = 300,
        first = { point = "CENTER", x = 0, y = 40, width = 620, height = 440 },
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

    local scroll = CreateFrame("ScrollFrame", nil, inside, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", list, "TOPRIGHT", I + 24, 0)
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

    local hint = inside:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 0, 4)
    hint:SetText(ns.TEXT.pasteHint)

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
