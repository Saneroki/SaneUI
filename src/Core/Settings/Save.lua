local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Save
--  The save window (Saneroki, 2026-11-09): after a change in a menu (the game's
--  options, Edit Mode, the addon list, Sane UI's options over a full screen;
--  Core/Unsaved.lua) it stands beside the menu, while the menu can still be
--  used, and stays until Yes or No, the menu closed too (no close button, Esc
--  leaves it). It lists what changed since the last save and, under Save to,
--  the profiles to save it to (a tick each, the one in use at first):
--      Yes   saved into every profile ticked
--      No    every change since the last save taken back
--  A step that waits for the answer (another profile, a /reload Sane UI offered)
--  is named in it. Made the first time there is a change; the game's own
--  ButtonFrameTemplate, as the window of Export and Import.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Unsaved = Core.Unsaved
local Panel = Config.Panel

local TEXT = {
    title = "Save the changes?",
    changed = "Changed since the last save:",
    more = "and %d more",
    saveTo = "Save to",
    saveToTip = "The profiles the changes are saved to: tick as many as you like. The profile in use is ticked at first; left unticked, it gets its settings back as they were at the last save.",
    none = "No profile",
    yes = "Yes",
    yesTip = "Keeps the changes: saved into every profile ticked under Save to.",
    no = "No",
    noTip = "Takes back every change since the last save.",
}
local WIDTH, LINES, LINE = 330, 8, 14 -- the window's width; the changes listed, and the height of each

local window

-- Beside the menu that is open (at its right), else at the screen's right.
local function Place(frame)
    frame:ClearAllPoints()
    for _, name in ipairs({ "SettingsPanel", "AddonList" }) do
        local menu = rawget(_G, name)
        if menu and menu.IsShown and menu:IsShown() then
            frame:SetPoint("TOPLEFT", menu, "TOPRIGHT", 8, 0)
            return
        end
    end
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -60, 0)
end

-- The profiles ticked, in words, for the dropdown.
local function Ticked()
    local names = {}
    for _, name in ipairs(Unsaved.Targets()) do
        if Unsaved.Ticked(name) then names[#names + 1] = name end
    end
    return #names > 0 and table.concat(names, ", ") or TEXT.none
end

local function Build()
    local frame = CreateFrame("Frame", "SaneUISaveChanges", UIParent, "ButtonFrameTemplate")
    if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
    local close = rawget(frame, "CloseButton") -- the template's own (parentKey)
    if type(close) == "table" and close.Hide then close:Hide() end -- it stays until Yes or No
    frame:SetFrameStrata("DIALOG") -- over the game's options, beside which it stands
    frame:SetToplevel(true)
    frame:SetWidth(WIDTH)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetTitle then frame:SetTitle(TEXT.title) end

    local head = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    head:SetPoint("TOPLEFT", 18, -34)
    head:SetText(TEXT.changed)
    local list = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    list:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
    list:SetWidth(WIDTH - 36)
    list:SetJustifyH("LEFT")
    list:SetJustifyV("TOP")
    list:SetSpacing(2)
    frame.List = list
    local after = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    after:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -8)
    after:SetWidth(WIDTH - 36)
    after:SetJustifyH("LEFT")
    frame.After = after

    local no = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    no:SetSize(110, 22)
    no:SetPoint("BOTTOMRIGHT", -8, 8)
    no:SetText(Core.Word("NO", TEXT.no))
    no:SetScript("OnClick", Core.Guard("options", function() Unsaved.Undo() end))
    Panel.Tooltip(no, no:GetText(), TEXT.noTip)
    frame.No = no
    local yes = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    yes:SetSize(110, 22)
    yes:SetPoint("RIGHT", no, "LEFT", -6, 0)
    yes:SetText(Core.Word("YES", TEXT.yes))
    yes:SetScript("OnClick", Core.Guard("options", function() Unsaved.Save() end))
    Panel.Tooltip(yes, yes:GetText(), TEXT.yesTip)
    frame.Yes = yes

    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", 18, 46)
    label:SetText(TEXT.saveTo)
    local menu = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    menu:SetWidth(WIDTH - 110)
    menu:SetPoint("LEFT", label, "RIGHT", 12, 0)
    -- Made once: the game builds the menu anew each time it opens, not its choices' functions.
    local isTicked = Core.Guard("options", function(name) return Unsaved.Ticked(name) end)
    local tick = Core.Guard("options", function(name) Unsaved.Tick(name, not Unsaved.Ticked(name)) end)
    menu:SetupMenu(Core.Guard("options", function(_, root)
        for _, name in ipairs(Unsaved.Targets()) do root:CreateCheckbox(name, isTicked, tick, name) end
    end))
    Panel.Tooltip(menu, TEXT.saveTo, TEXT.saveToTip)
    frame.Menu = menu
    window = frame
    return frame
end

-- Shows what waits to be saved, or goes when nothing does. Placed anew each time it comes.
local function Show()
    if not Unsaved.Pending() then
        if window then window:Hide() end
        return
    end
    local frame = window or Build()
    local changes, lines = Unsaved.Changes(), {}
    for index = 1, math.min(#changes, LINES) do lines[index] = changes[index] end
    if #changes > LINES then lines[#lines] = TEXT.more:format(#changes - LINES + 1) end
    frame.List:SetText(table.concat(lines, "\n"))
    local step = Unsaved.Next()
    frame.After:SetText(step or "")
    frame.After:SetShown(step ~= nil)
    frame:SetHeight(54 + #lines * LINE + (step and 26 or 0) + 82)
    frame.Menu:GenerateMenu()
    if frame.Menu.OverrideText then frame.Menu:OverrideText(Ticked()) end
    frame.Yes:SetEnabled(Unsaved.Any())
    if not frame:IsShown() then
        Place(frame)
        frame:Show()
    end
    frame:Raise()
end

-- The page Profiles shows it too (its Save and Load last settings).
Unsaved.Watch(function()
    Show()
    Config.RefreshSoon()
end)
