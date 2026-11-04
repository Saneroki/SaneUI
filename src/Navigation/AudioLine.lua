local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Audio line
--  The satchel's line of Core's sound profiles (Core.Audio; Saneroki,
--  2026-11-04), first in its section Sane UI:
--
--      Sound:  [ Music off           v ]  [cogwheel]
--
--  The dropdown names the profile in use, "(changed)" after it while the game's
--  sound settings differ from it, and lists the profiles, the one in use first:
--  choosing one sets it at once. The cogwheel opens the game's menu under it
--  with the game's sound settings now: a checkbox and a slider for each of All
--  sound, Music, SFX, Dialogue and Ambience, set as they are clicked or moved
--  (the profile keeps them only when saved); then Save (the settings now into
--  the profile), Load (the profile set again), New (a profile of the settings
--  now, named in the game's dialog) and Delete (the profile in use, asked first;
--  not the last one). The satchel stays open while one of these menus or
--  dialogs is (Satchel's Held). On the paper: pencil boxes, words in graphite.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Journal = Core.Journal
local Audio = Core.Audio
local AudioLine = {}
ns.AudioLine = AudioLine

AudioLine.HEIGHT = 26     -- the line, its dropdown and its cogwheel
AudioLine.LABEL = 52      -- the word Sound before the dropdown
AudioLine.MENU = 220      -- the dropdown's width
AudioLine.GAP = 6         -- between the dropdown and the cogwheel
AudioLine.AFTER = 6       -- under the line
AudioLine.COG = "GM-icon-settings" -- the cogwheel: the game's settings gear (its raid manager's), in both games
AudioLine.COG_FILE = "Interface\\Icons\\INV_Misc_Gear_01" -- where a client lacks that atlas
AudioLine.COG_INSET = 4
-- A sound's row in the cogwheel's menu, as the pin filter's: its slider, the percent at its right, the checkbox and
-- the row's height.
AudioLine.SLIDER, AudioLine.PERCENT, AudioLine.CHECK, AudioLine.ROW = 120, 44, 40, 30
AudioLine.STEPS = 20      -- the slider's steps from 0 to 100 %: 5 % each, as the game's own
AudioLine.FAINT = "ff6e6154" -- faint graphite in a colour code: "(changed)"
AudioLine.TEXT = {
    sound = "Sound:",
    changed = "(changed)",
    profileTip = "The sound profile in use. A click lists them: choosing one sets it.",
    changedTip = "The game's sound settings differ from it now: Save or Load in the cogwheel's menu.",
    settings = "Sound settings",
    settingsTip = "The game's sounds now, and Save, Load, New and Delete for the profile in use.",
    save = "Save",
    saveTip = "The sound settings now into the profile %s.",
    load = "Load",
    loadTip = "The profile %s set again.",
    new = "New",
    newTip = "A new profile of the sound settings now.",
    delete = Core.Word("DELETE", "Delete"),
    deleteTip = "The profile %s deleted.",
    askNew = "A name for the new sound profile:",
    askDelete = "Delete the sound profile %s?",
}
local TEXT = AudioLine.TEXT

local line, word, profiles, cog
local asked -- the dialog New or Delete opened, and its data: while it shows, the satchel stays (AudioLine.Held)

-------------------------------------------------------------------------------
--  The menus
-------------------------------------------------------------------------------
local Current = ns.Guard(function(name) return name == Audio.Current() end)
local Choose = ns.Guard(function(name) Audio.Use(name) end)

-- The profiles, the one in use first, then the others in their order.
local function Profiles(_, root)
    local current = Audio.Current()
    root:CreateRadio(current, Current, Choose, current)
    for _, name in ipairs(Audio.Names()) do
        if name ~= current then root:CreateRadio(name, Current, Choose, name) end
    end
end

local function Tooltip(title, text)
    return ns.Guard(function(tooltip)
        GameTooltip_SetTitle(tooltip, title)
        GameTooltip_AddNormalLine(tooltip, text:format(Audio.Current()))
    end)
end

local function Percent(value) return ("%d%%"):format(math.floor(value + 0.5)) end

local OWNER = {} -- the sliders' callbacks are of this owner: a slider laid out anew replaces its last one

-- A sound's row with its volume's slider at its right (the game's slider, lent to the row by the menu while it is
-- open, as the pin filter has it). Returns the row's size.
local function Slider(button, key)
    local mixin = MinimalSliderWithSteppersMixin
    local slider = button:AttachTemplate("MinimalSliderWithSteppersTemplate")
    slider:SetWidth(AudioLine.SLIDER)
    slider:ClearAllPoints()
    slider:SetPoint("RIGHT", -AudioLine.PERCENT, 0)
    -- The menu's sliders are its pool's: one that showed another sound still has our callback for it, which its
    -- Init would tell this sound's volume. Let go first.
    slider:UnregisterCallback(mixin.Event.OnValueChanged, OWNER)
    local _, volume = Audio.Get(key)
    slider:Init((volume or 0) * 100, 0, 100, AudioLine.STEPS, { [mixin.Label.Right] = Percent })
    slider:RegisterCallback(mixin.Event.OnValueChanged,
        ns.Guard(function(_, value) Audio.Set(key, nil, value / 100) end), OWNER)
    local text = button.fontString
    return (text and text:GetUnboundedStringWidth() or 100) + AudioLine.CHECK + AudioLine.SLIDER + AudioLine.PERCENT,
        AudioLine.ROW
end

-- A row without a slider (a client without the game's slider) as tall as those with one.
local function Tall(button)
    local text = button.fontString
    return (text and text:GetUnboundedStringWidth() or 100) + AudioLine.CHECK, AudioLine.ROW
end

local On = ns.Guard(function(key) return Audio.Get(key) == true end)
local Switch = ns.Guard(function(key) Audio.Set(key, not Audio.Get(key)) end)

-- The dialog asked: kept while it shows (the game's dialogs are used again for others: its data tells ours).
local function Asked(dialog)
    asked = dialog and { dialog = dialog, data = dialog.data } or nil
end

local function Made(name)
    local ok, why = Audio.New(name)
    if not ok then Core.Print(tostring(why)) end
end

local function Gone()
    local ok, why = Audio.Delete()
    if not ok then Core.Print(tostring(why)) end
end

local Save = ns.Guard(function()
    Audio.Save()
    return MenuResponse.Refresh
end)
local Load = ns.Guard(function()
    Audio.Load()
    return MenuResponse.Refresh -- the rows read the profile's settings again
end)
local New = ns.Guard(function()
    Asked(Core.AskText(TEXT.askNew, nil, Core.Word("SAVE", TEXT.save), nil, Made, Audio.LETTERS))
end)
local Delete = ns.Guard(function()
    Asked(Core.Confirm(TEXT.askDelete, Audio.Current(), Gone, nil, TEXT.delete))
end)

-- The game's sound settings now, each sound's checkbox and slider; the profile's buttons under them.
local function Settings(_, root)
    root:CreateTitle(Audio.Current())
    local sliders = rawget(_G, "MinimalSliderWithSteppersMixin") ~= nil
    for _, kind in ipairs(Audio.Kinds()) do
        local key = kind.key
        local box = root:CreateCheckbox(kind.text, On, Switch, key)
        if sliders then
            box:AddInitializer(ns.Guard(function(button) return Slider(button, key) end))
        else
            box:AddInitializer(ns.Guard(Tall))
        end
    end
    root:CreateDivider()
    local buttons = {
        { TEXT.save, Save, TEXT.saveTip }, { TEXT.load, Load, TEXT.loadTip },
        { TEXT.new, New, TEXT.newTip }, { TEXT.delete, Delete, TEXT.deleteTip },
    }
    for _, button in ipairs(buttons) do
        local item = root:CreateButton(button[1], button[2]) -- guarded: Save, Load, New, Delete are ns.Guard's
        if item.SetTooltip then item:SetTooltip(Tooltip(button[1], button[3])) end -- guarded: Tooltip's ns.Guard
        if button[2] == Delete and #Audio.Names() < 2 then item:SetEnabled(false) end
    end
end

-------------------------------------------------------------------------------
--  The line
-------------------------------------------------------------------------------
local function Tip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if owner == cog then
        GameTooltip:SetText(TEXT.settings)
        GameTooltip:AddLine(TEXT.settingsTip, 1, 1, 1, true)
    else
        GameTooltip:SetText(Audio.Current())
        GameTooltip:AddLine(TEXT.profileTip, 1, 1, 1, true)
        if Audio.Changed() then GameTooltip:AddLine(TEXT.changedTip, 1, 1, 1, true) end
    end
    GameTooltip:Show()
end

local function Entered(button)
    button.box:SetStrong(true)
    Tip(button)
end

local function Left(button)
    button.box:SetStrong(false)
    GameTooltip:Hide()
end

-- A dropdown of the game's own kind (SetupMenu opens its menu under it) in a pencil box.
local function Dropdown(width, generator)
    local menu = CreateFrame("DropdownButton", nil, line)
    menu:SetSize(width, AudioLine.HEIGHT)
    menu.box = Journal.Box(menu, 0.5)
    menu:SetupMenu(ns.Guard(generator))
    menu:HookScript("OnEnter", ns.Guard(Entered))
    menu:HookScript("OnLeave", ns.Guard(Left))
    return menu
end

-- The cogwheel's picture: the game's silver gear as it draws it (tinted graphite it is a dark blot), else the gear's
-- icon.
local function Gear(texture)
    local atlases = rawget(_G, "C_Texture")
    if atlases and atlases.GetAtlasInfo and Core.Ask(atlases.GetAtlasInfo, AudioLine.COG) then
        texture:SetAtlas(AudioLine.COG)
    else
        texture:SetTexture(AudioLine.COG_FILE)
    end
end

local function Build(sheet)
    line = CreateFrame("Frame", nil, sheet)
    line:SetHeight(AudioLine.HEIGHT)
    word = line:CreateFontString(nil, "OVERLAY")
    Journal.Font(word, 15, true, Journal.INK)
    word:SetPoint("LEFT", line, "LEFT", 2, 0)
    word:SetText(TEXT.sound)
    profiles = Dropdown(AudioLine.MENU, Profiles)
    profiles:SetPoint("LEFT", line, "LEFT", AudioLine.LABEL, 0)
    profiles.label = profiles:CreateFontString(nil, "OVERLAY")
    Journal.Font(profiles.label, 14, false, Journal.INK)
    profiles.label:SetPoint("LEFT", 7, 0)
    profiles.label:SetPoint("RIGHT", -16, 0)
    profiles.label:SetJustifyH("LEFT")
    profiles.label:SetWordWrap(false)
    local arrow = profiles:CreateFontString(nil, "OVERLAY")
    Journal.Font(arrow, 12, true, Journal.INK)
    arrow:SetPoint("RIGHT", -7, 0)
    arrow:SetText("v")
    cog = Dropdown(AudioLine.HEIGHT, Settings)
    cog:SetPoint("LEFT", profiles, "RIGHT", AudioLine.GAP, 0)
    cog.icon = cog:CreateTexture(nil, "ARTWORK")
    cog.icon:SetPoint("TOPLEFT", AudioLine.COG_INSET, -AudioLine.COG_INSET)
    cog.icon:SetPoint("BOTTOMRIGHT", -AudioLine.COG_INSET, AudioLine.COG_INSET)
    Gear(cog.icon)
    AudioLine.line, AudioLine.profiles, AudioLine.cog = line, profiles, cog
end

-- The dropdown's words: the profile in use, "(changed)" after it while the game's settings differ from it.
function AudioLine.Refresh()
    if not (line and line:IsShown()) then return end
    local name = Audio.Current()
    if Audio.Changed() then name = ("%s |c%s%s|r"):format(name, AudioLine.FAINT, TEXT.changed) end
    profiles.label:SetText(name)
end

-- Whether the line has anything to show here: the game's sound settings.
function AudioLine.Offered()
    return #Audio.Kinds() > 0
end

-- The line on the satchel's sheet at y, as wide as the sheet. Returns where the sheet goes on.
function AudioLine.Place(sheet, y)
    if not line then Build(sheet) end
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, -y)
    line:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", 0, -y)
    line:Show()
    AudioLine.Refresh()
    return y + AudioLine.HEIGHT + AudioLine.AFTER
end

function AudioLine.Hide()
    if line then line:Hide() end
end

-- Whether a dialog the line opened still shows (New's name, Delete's question).
function AudioLine.Held()
    local dialog = asked and asked.dialog
    if not (dialog and dialog.IsShown and Core.Plain(dialog:IsShown()) and dialog.data == asked.data) then
        asked = nil
        return false
    end
    return true
end

Audio.Watch(function() AudioLine.Refresh() end)
