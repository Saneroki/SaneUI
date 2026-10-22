-- Journal chat: a chat window of the journal look, from the 4K pieces, fed by the fake server's chat
-- The window is the draft dev/uilab/drafts/Journal.lua; this scene only fills it: tabs, the lines, the line to type in.
local ns = Lab.Addon("SaneUI_Draft", "dev/uilab/drafts/Journal.lua")
local Journal = ns.Journal

local KINDS = { SAY = "Say", YELL = "Yell", GUILD = "Guild", OFFICER = "Officer", PARTY = "Party", RAID = "Raid",
    WHISPER = "Whisper", WHISPER_INFORM = "To", CHANNEL = nil, EMOTE = "", SYSTEM = "" }
local TABS = {
    { "General", { "SAY", "YELL", "EMOTE", "CHANNEL", "SYSTEM", "GUILD", "OFFICER", "PARTY", "WHISPER", "WHISPER_INFORM" } },
    { "Guild", { "GUILD", "OFFICER" } },
    { "Whispers", { "WHISPER", "WHISPER_INFORM" } },
}

-- A colour of the game's chat or classes, darkened to read as ink on the paper.
local function ink(r, g, b)
    local k = 0.55
    return ("|cff%02x%02x%02x"):format(math.floor(r * 255 * k + 30 * (1 - k)), math.floor(g * 255 * k + 23 * (1 - k)), math.floor(b * 255 * k + 17 * (1 - k)))
end

Lab.OnLogin(function()
    local w = Journal.Window(UIParent, "LabJournalChat", 400, 520, "Chat")
    w:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 40, 40)
    w:EnableMouse(true)
    w:SetMovable(true)
    w:SetResizable(true)
    w:SetResizeBounds(360, 300, 900, 900)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", w.StartMoving)
    w:SetScript("OnDragStop", w.StopMovingOrSizing)
    tinsert(UISpecialFrames, "LabJournalChat")

    -- a grip in the bottom right corner sizes it
    local grip = CreateFrame("Button", nil, w)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -18, 4)
    grip:SetScript("OnMouseDown", function() w:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() w:StopMovingOrSizing() end)

    local c = w.content
    local log = CreateFrame("ScrollingMessageFrame", nil, c)
    log:SetPoint("TOPLEFT", 4, -34)
    log:SetPoint("BOTTOMRIGHT", -4, 34)
    log:SetFont(Journal.FONT, 16 * 768 / 1080, "")
    log:SetTextColor(unpack(Journal.INK))
    log:SetShadowOffset(0, 0)
    log:SetJustifyH("LEFT")
    log:SetSpacing(2)
    log:SetFading(false)
    log:SetMaxLines(200)
    log:SetHyperlinksEnabled(true)
    log:EnableMouseWheel(true)
    log:SetScript("OnMouseWheel", function(self, delta) if delta > 0 then self:ScrollUp() else self:ScrollDown() end end)
    log:SetScript("OnHyperlinkEnter", function(self, link)
        if link:match("^item:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
        end
    end)
    log:SetScript("OnHyperlinkLeave", GameTooltip_Hide)

    local shown = {}
    local tabs = {}
    local x = 0
    for i, t in ipairs(TABS) do
        local tab = Journal.Tab(c, t[1], function()
            for j, other in ipairs(tabs) do other:SetChosen(j == i) end
            shown = {}
            for _, kind in ipairs(t[2]) do shown[kind] = true end
        end)
        tab:SetPoint("TOPLEFT", c, "TOPLEFT", x, 0)
        x = x + tab:GetWidth() - 2
        tabs[i] = tab
    end
    tabs[1]:Click()

    local rule = Journal.Rule(c)
    rule:SetPoint("BOTTOMLEFT", 0, 6)
    rule:SetPoint("BOTTOMRIGHT", 0, 6)

    local edit = CreateFrame("EditBox", nil, c)
    edit:SetPoint("BOTTOMLEFT", 2, 8)
    edit:SetPoint("BOTTOMRIGHT", -2, 8)
    edit:SetHeight(24)
    edit:SetAutoFocus(false)
    edit:SetFont(Journal.FONT, 16 * 768 / 1080, "")
    edit:SetTextColor(unpack(Journal.INK))
    edit:SetHighlightColor(0.55, 0.45, 0.3, 0.35)
    edit:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if text ~= "" then SendChatMessage(text, "GUILD") end
        self:SetText("")
        self:ClearFocus()
    end)
    edit:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    local hint = edit:CreateFontString(nil, "ARTWORK")
    Journal.Font(hint, 15, false, Journal.INK, 0.45)
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText("Write to the guild ...")
    edit:SetScript("OnTextChanged", function(self) hint:SetShown(self:GetText() == "") end)

    -- the lines: a time, the channel, the name in its class's colour, the words
    local events = CreateFrame("Frame")
    for kind in pairs(KINDS) do events:RegisterEvent("CHAT_MSG_" .. kind) end
    events:RegisterEvent("CHAT_MSG_CHANNEL")
    events:SetScript("OnEvent", function(_, event, text, sender, _, channelName, _, _, _, channelIndex, _, _, _, guid)
        local kind = event:sub(10)
        if not shown[kind] then return end
        local info = ChatTypeInfo[kind] or ChatTypeInfo.SAY
        local color = ink(info.r, info.g, info.b)
        local tag = KINDS[kind]
        if kind == "CHANNEL" then tag = tostring(channelIndex) end
        local name = sender
        if guid and guid ~= "" then
            local _, class = GetPlayerInfoByGUID(guid)
            local cc = class and RAID_CLASS_COLORS[class]
            if cc then name = ink(cc.r, cc.g, cc.b) .. sender .. "|r" end
        end
        local time = date("%H:%M")
        local line
        if kind == "SYSTEM" then
            line = color .. text .. "|r"
        elseif kind == "EMOTE" then
            line = ("%s%s %s|r"):format(color, sender, text)
        else
            line = ("|cff6b5a48%s|r %s[%s]|r |Hplayer:%s|h%s|h: %s"):format(time, color, tag, sender, name, text)
        end
        log:AddMessage(line)
    end)
end)
