-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - About
--  The page "Sane UI" under its banner: where to find Sane UI (Discord, the
--  website, GitHub) and feedback (a bug, an idea, a note).
--
--  An addon can open no web page, copy nothing to the clipboard and send
--  nothing out of the game. So a link is shown in the game's own dialog with
--  its address selected, to copy with Ctrl+C; and feedback is written here and
--  made into a report (with Sane UI's version, the game's and, for a bug, the
--  latest errors), selected to copy and paste on GitHub or Discord.
--
--  The rows are the game's own (section headers, button rows), handed to the
--  page by Settings.lua's Config.Fill; the feedback window is made the first
--  time it is opened (ButtonFrameTemplate, InputScrollFrameTemplate).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Config = Core.Config
local About = {}
Config.About = About

-- Where Sane UI can be found. An address left empty has its row, with the button off.
About.LINKS = {
    { key = "discord", name = "Discord", url = "", tip = "Talk with other players and the maker of Sane UI." },
    { key = "website", name = "Website", url = "", tip = "News, guides and downloads." },
    { key = "github", name = "GitHub", url = "", tip = "The code, and the place for bug reports and ideas (Issues)." },
}

-- The kinds of feedback, in the order of their buttons.
About.KINDS = {
    { key = "bug", name = "Report a bug", title = "Bug report", errors = true,
      tip = "Something broke or did not work as it should.",
      ask = "What happened, and what did you do just before? Sane UI adds its version, the game's version and its latest errors to the report." },
    { key = "idea", name = "Suggest a feature", title = "Feature suggestion",
      tip = "Something Sane UI could do, or do better.",
      ask = "What would you like Sane UI to do, and when would it help you?" },
    { key = "note", name = "General feedback", title = "Feedback",
      tip = "Anything else you would like to say.",
      ask = "What would you like to say?" },
}

local TEXT = {
    community = "Community",
    feedback = "Feedback",
    open = "Copy link",
    soon = "Coming soon",
    soonTip = "Not there yet.",
    write = "Write...",
    copy = "%s: press Ctrl+C to copy the address, then paste it into your browser.",
    make = "Make report",
    edit = "Back to writing",
    empty = "Write something first.",
    ready = "Your report is selected: press Ctrl+C to copy it, then paste it %s.",
    where = "into a new issue on GitHub or in Discord",
    errors = "Latest errors",
    noErrors = "none",
}
About.TEXT = TEXT

local ERRORS_MAX = 5 -- the newest errors a bug report carries

local function Url(link)
    return type(link.url) == "string" and link.url ~= "" and link.url or nil
end

-- A link in the game's dialog for addons, its address selected to copy.
function About.ShowLink(link)
    local url = Url(link)
    if not (url and StaticPopupDialogs and StaticPopupDialogs.GENERIC_INPUT_BOX) then return end
    local dialog = StaticPopup_Show("GENERIC_INPUT_BOX", nil, nil, { text = TEXT.copy:format(link.name),
        acceptText = CLOSE or "Close", maxLetters = 255, callback = function() end })
    local box = dialog and dialog.GetEditBox and dialog:GetEditBox()
    if box then
        box:SetText(url)
        box:HighlightText()
        if box.SetFocus then box:SetFocus() end
    end
    return dialog
end

-------------------------------------------------------------------------------
--  The report
-------------------------------------------------------------------------------
local function Modules()
    local titles = {}
    for index, module in ipairs(Core.modules or {}) do titles[index] = module.title end
    return #titles > 0 and table.concat(titles, ", ") or "none"
end

-- The text to paste: what the player wrote, under what helps to read it. No name of a character:
-- only its class and level.
function About.Report(kind, written)
    local version, build = "?", "?"
    if GetBuildInfo then version, build = GetBuildInfo() end
    local lines = {
        ("Sane UI %s: %s"):format(kind.title, Core.VERSION),
        ("Game %s (%s), %s"):format(tostring(version), tostring(build), GetLocale and GetLocale() or "?"),
        ("Modules: %s"):format(Modules()),
        ("Character: %s, level %s"):format(Core.class or "?", UnitLevel and tostring(UnitLevel("player")) or "?"),
        "",
        strtrim(written or ""),
    }
    if kind.errors then
        lines[#lines + 1] = ""
        local log, listed = Core.log or {}, 0
        lines[#lines + 1] = TEXT.errors .. ":"
        for index = #log, math.max(1, #log - ERRORS_MAX + 1), -1 do
            local entry = log[index]
            if type(entry) == "table" then
                local text = tostring(entry.text or ""):gsub("\n", " | ")
                lines[#lines + 1] = ("- %s (%s, %sx): %s"):format(tostring(entry.label), tostring(entry.when),
                    tostring(entry.count or 1), text)
                listed = listed + 1
            end
        end
        if listed == 0 then lines[#lines] = TEXT.errors .. ": " .. TEXT.noErrors end
    end
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------------------
--  The feedback window: write, then make the report and copy it
-------------------------------------------------------------------------------
local window
local drafts = {} -- [kind key] = what was written, kept while the session lasts

local function Build()
    local frame = CreateFrame("Frame", "SaneUIFeedbackFrame", UIParent, "ButtonFrameTemplate")
    if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
    -- Over the game's options (strata HIGH), which it is opened from.
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetSize(520, 400)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    tinsert(UISpecialFrames, "SaneUIFeedbackFrame") -- Esc closes it

    local ask = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    ask:SetPoint("TOPLEFT", 20, -34)
    ask:SetPoint("TOPRIGHT", -20, -34)
    ask:SetJustifyH("LEFT")
    frame.Ask = ask

    local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -78)
    scroll:SetPoint("BOTTOMRIGHT", -30, 44)
    scroll.hideCharCount = true
    if scroll.CharCount then scroll.CharCount:Hide() end
    -- The template sizes its box when it loads, before it has a size here.
    local box = scroll.EditBox
    box:SetWidth(520 - 24 - 30 - 18)
    if box.Instructions then box.Instructions:SetWidth(520 - 24 - 30) end
    box:SetMaxLetters(0)
    frame.Scroll, frame.Box = scroll, box

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(120, 22)
    close:SetPoint("BOTTOMRIGHT", -8, 8)
    close:SetText(CLOSE or "Close")
    close:SetScript("OnClick", function() frame:Hide() end)

    local make = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    make:SetSize(140, 22)
    make:SetPoint("RIGHT", close, "LEFT", -6, 0)
    frame.Make = make
    make:SetScript("OnClick", function() Core.Safe("Settings: feedback", About.Toggle) end)

    frame:SetScript("OnHide", function()
        if frame.kind and not frame.made then drafts[frame.kind.key] = box:GetText() end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end)
    return frame
end

-- Writing: the box holds what was written and the button makes the report.
local function Write(text)
    window.made = false
    window.Ask:SetText(window.kind.ask)
    window.Box:SetText(text or "")
    if InputScrollFrame_SetInstructions then InputScrollFrame_SetInstructions(window.Scroll, window.kind.tip) end
    window.Make:SetText(TEXT.make)
    window.Box:SetFocus()
end

-- Between writing and the made report.
function About.Toggle()
    if window.made then
        Write(drafts[window.kind.key])
        return
    end
    local written = window.Box:GetText()
    if strtrim(written or "") == "" then
        window.Ask:SetText(TEXT.empty)
        return
    end
    drafts[window.kind.key] = written
    window.made = true
    window.Ask:SetText(TEXT.ready:format(TEXT.where))
    window.Box:SetText(About.Report(window.kind, written))
    window.Make:SetText(TEXT.edit)
    window.Box:SetFocus()
    window.Box:HighlightText()
end

-- Opens the window for a kind of feedback, with what was written for it before.
function About.Open(kind)
    window = window or Build()
    window.kind = kind
    if window.SetTitle then window:SetTitle(kind.name) end
    window:Show()
    window:Raise()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    Write(drafts[kind.key])
    return window
end

-------------------------------------------------------------------------------
--  The rows on the page Sane UI
-------------------------------------------------------------------------------
function About.Fill(page)
    if not CreateSettingsButtonInitializer then return end
    Settings.RegisterInitializer(page, CreateSettingsListSectionHeaderInitializer(TEXT.community))
    for _, link in ipairs(About.LINKS) do
        local url = Url(link)
        local row = CreateSettingsButtonInitializer(link.name, url and TEXT.open or TEXT.soon,
            function() Core.Safe("Settings: link", About.ShowLink, link) end,
            url and (link.tip .. "\n" .. url) or TEXT.soonTip, false)
        if not url and row.AddModifyPredicate then row:AddModifyPredicate(function() return false end) end
        Settings.RegisterInitializer(page, row)
    end
    Settings.RegisterInitializer(page, CreateSettingsListSectionHeaderInitializer(TEXT.feedback))
    for _, kind in ipairs(About.KINDS) do
        Settings.RegisterInitializer(page, CreateSettingsButtonInitializer(kind.name, TEXT.write,
            function() Core.Safe("Settings: feedback", About.Open, kind) end, kind.tip, true))
    end
end

-- /sane feedback [bug|idea|note]: the feedback window without the options (bug when none is named).
Core.Command("feedback", "report a bug, suggest a feature or send feedback (/sane feedback idea, note)", function(rest)
    local wanted = strtrim(rest or ""):lower()
    for _, kind in ipairs(About.KINDS) do
        if kind.key == wanted then return About.Open(kind) end
    end
    About.Open(About.KINDS[1])
end, "bug")
