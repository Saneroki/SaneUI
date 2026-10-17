local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Profiles
--  The page Profiles, a page of our own in the game's options (a canvas: Core
--  puts it up, Core.frames.Profiles): its title, a line on what profiles are,
--  and tabs:
--      Profiles        Accountwide: the switch, and what it means
--                      This character: the profile it uses, and what can be done
--                      with profiles (new, rename, delete, defaults, copy from
--                      another, export and import as text)
--                      Characters: first New Characters, the profile a character not
--                      seen yet starts with; then every character seen, each with
--                      its profile (and a button to forget it)
--      Game settings   which of the game's settings the profiles keep (Synced.lua)
--      CVars           the list of the game's CVars (CVars.lua)
--  With Accountwide off, everything about profiles is switched off: each
--  character keeps its own settings.
--
--  Core keeps the profiles and does the work (Core/Profiles.lua); this file only
--  shows them. Questions and names are asked in the game's own dialogs for
--  addons (Core.Confirm, Core.AskText).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Profiles = Core.Profiles

local TEXT = {
    title = "Profiles",
    intro = "Profiles keep the settings of Sane UI and of the game. With Accountwide on, every character uses a profile: Accountwide at first, the same for all of them.",
    tab = "Profiles",
    accountwide = "Accountwide",
    on = "Accountwide settings",
    onTip = "On: your characters share their settings through profiles: Sane UI's and the game's (its options, CVars, Edit Mode layout, chat windows: the tab Game settings). The game's are set from the profile when a character comes into the world and read back into it when the character leaves. Off: each character keeps its own Sane UI settings, a copy of its profile's to begin with, and the game's settings are left to the game.",
    onNote = "On, every character uses the profile Accountwide unless it is given another below. Off, each character keeps its own settings and nothing of the game's is touched.",
    askOn = "Switch Accountwide settings on? This character takes the settings of its profile, %s, the game's settings too.",
    turnedOn = "Accountwide settings are on: this character uses the profile %s.",
    turnedOff = "Accountwide settings are off: each character keeps its own settings, and the game's are left to the game.",
    yours = "This character",
    profile = "Profile",
    profileTip = "The profile this character uses: its settings, Sane UI's and the game's, are the profile's. A change made on any options page goes into it, for every character that uses it.",
    new = "New",
    newTip = "A new profile, a copy of the settings in use, which this character uses from then on.",
    askNew = "A new profile, a copy of the settings in use. Its name:",
    rename = "Rename",
    renameTip = "Gives the profile in use another name. Not Accountwide.",
    askRename = "Rename the profile %s to:",
    delete = "Delete",
    deleteTip = "Deletes the profile in use. Every character that used it uses Accountwide from then on, this one at once. Not Accountwide.",
    askDelete = "Delete the profile %s? Every character that used it uses Accountwide from then on, this one at once.",
    defaults = "Defaults",
    defaultsTip = "Every setting of Sane UI in the profile in use back to its default. The game's settings stay as they are.",
    askDefaults = "Set every setting of Sane UI in the profile %s back to its default? The game's settings stay as they are.",
    copyFrom = "Copy from",
    copyFromTip = "The settings in use take those of another profile: Sane UI's and the game's.",
    askCopy = "Copy the settings of the profile %s into the one in use? What it has now is replaced.",
    export = "Export",
    exportTip = "The profile in use as a line of text, to copy and keep or share.",
    import = "Import",
    importTip = "A profile from a line of text made by Export.",
    askImport = "The new profile's name:",
    exportTitle = "Export the profile %s",
    exportHelp = "Select all of it (Ctrl+A) and copy it (Ctrl+C).",
    importTitle = "Import a profile",
    importHelp = "Paste the text of an exported profile here (Ctrl+V), then Import.",
    characters = "Characters",
    character = "Character",
    you = "(this character)",
    newCharacters = "New Characters",
    newTip = "The profile a character Sane UI has not seen yet (a new one, or one that has not logged in since Sane UI was installed) starts with at its first login. Its own line here can change it afterwards.",
    useTip = "The profile this character uses. For the character you are playing it counts at once, for the others at their next login.",
    forget = "Forget",
    forgetTip = "Forgets the character: its line here and what Sane UI keeps for it. For a character deleted, or moved to another account.",
    askForget = "Forget the character %s? Sane UI forgets what it keeps for it.",
    created = "the profile %s is made, and this character uses it.",
    renamed = "the profile is called %s now.",
    deleted = "the profile %s is deleted.",
    reset = "every setting of Sane UI in the profile %s is back at its default.",
    copied = "the settings of %s are in use now.",
    imported = "the profile %s is imported.",
    used = "this character uses the profile %s.",
    forgotten = "%s is forgotten.",
    exportFailed = "the profile could not be written as text.",
    close = "Close",
}
local Panel = Config.Panel

-- The controls show what changed, a frame later: the setting whose change started it has finished first.
local Refresh = Core.Later(function() Config.Refresh() end)

-- Says how a step went in chat: done (with a name) or why not.
local function Tell(ok, why, done, name)
    if not ok then
        Core.Print(tostring(why))
        return false
    end
    if done then Core.Print(done:format(tostring(name))) end
    Refresh()
    return true
end

local function Run(fn, ...)
    Core.Safe("Settings: profiles", fn, ...)
end

-- The profile in use; nil while Accountwide is off.
local function InUse()
    return Profiles.InUse()
end

-- Whether what acts on the profile in use can be used: Accountwide on, and (fixed) not Accountwide itself.
local function Usable() return Profiles.On() end
local function Changeable() return Profiles.On() and not Profiles.Fixed(InUse()) end

-------------------------------------------------------------------------------
--  Export and import: a window with a box of text
-------------------------------------------------------------------------------
local window

local function Window()
    if window then return window end
    local frame = CreateFrame("Frame", "SaneUIProfileText", UIParent, "ButtonFrameTemplate")
    if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
    frame:SetFrameStrata("DIALOG") -- over the game's options, which it is opened from
    frame:SetToplevel(true)
    frame:SetSize(520, 300)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    tinsert(UISpecialFrames, "SaneUIProfileText") -- Esc closes it

    local help = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", 20, -34)
    help:SetPoint("TOPRIGHT", -20, -34)
    help:SetJustifyH("LEFT")
    frame.Help = help

    local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -62)
    scroll:SetPoint("BOTTOMRIGHT", -30, 44)
    scroll.hideCharCount = true
    if scroll.CharCount then scroll.CharCount:Hide() end
    local box = scroll.EditBox
    box:SetWidth(520 - 24 - 30 - 18) -- the template sizes its box when it loads, before it has a size here
    box:SetMaxLetters(0)
    frame.Box = box

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(120, 22)
    close:SetPoint("BOTTOMRIGHT", -8, 8)
    close:SetText(Core.Word("CLOSE", TEXT.close))
    close:SetScript("OnClick", function() frame:Hide() end)
    local act = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    act:SetSize(120, 22)
    act:SetPoint("RIGHT", close, "LEFT", -6, 0)
    act:SetText(TEXT.import)
    act:SetScript("OnClick", function() if frame.act then Run(frame.act, box:GetText()) end end)
    frame.Act = act
    window = frame
    return frame
end

local function Export()
    local name = InUse()
    local text = Profiles.Export(name)
    if not text then return Core.Print(TEXT.exportFailed) end
    local frame = Window()
    frame:SetTitle(TEXT.exportTitle:format(name))
    frame.Help:SetText(TEXT.exportHelp)
    frame.Act:Hide()
    frame.act = nil
    frame:Show()
    frame.Box:SetText(text)
    frame.Box:SetFocus()
    frame.Box:HighlightText()
end

local function Import()
    local frame = Window()
    frame:SetTitle(TEXT.importTitle)
    frame.Help:SetText(TEXT.importHelp)
    frame.Act:Show()
    frame.act = function(text)
        local value = Core.Serial.Read(text)
        local suggested = type(value) == "table" and type(value.name) == "string" and value.name or nil
        Core.AskText(TEXT.askImport, nil, TEXT.import, suggested, function(name)
            local ok, result = Profiles.Import(text, name)
            if Tell(ok, result, TEXT.imported, result) then frame:Hide() end
        end, Profiles.MAX_NAME)
    end
    frame:Show()
    frame.Box:SetText("")
    frame.Box:SetFocus()
end

-------------------------------------------------------------------------------
--  The tab Profiles
-------------------------------------------------------------------------------
-- What the buttons do with the profile in use; needs: when the button can be used.
local ACTIONS = {
    { button = TEXT.new, tip = TEXT.newTip, needs = Usable, run = function()
        Core.AskText(TEXT.askNew, nil, TEXT.new, nil, function(name)
            local ok, made = Profiles.Create(name)
            if not Tell(ok, made) then return end
            Tell(Profiles.Use(made))
            Core.Print(TEXT.created:format(made))
        end, Profiles.MAX_NAME)
    end },
    { button = TEXT.rename, tip = TEXT.renameTip, needs = Changeable, run = function()
        local name = InUse()
        Core.AskText(TEXT.askRename, name, TEXT.rename, name, function(as)
            local ok, why = Profiles.Rename(name, as)
            Tell(ok, why, TEXT.renamed, InUse())
        end, Profiles.MAX_NAME)
    end },
    { button = TEXT.delete, tip = TEXT.deleteTip, needs = Changeable, run = function()
        local name = InUse()
        Core.Confirm(TEXT.askDelete, name, function()
            local ok, why = Profiles.Delete(name)
            Tell(ok, why, TEXT.deleted, name)
        end, true)
    end },
    { button = TEXT.defaults, tip = TEXT.defaultsTip, needs = Usable, run = function()
        local name = InUse()
        Core.Confirm(TEXT.askDefaults, name, function()
            local ok, why = Profiles.Reset()
            Tell(ok, why, TEXT.reset, name)
        end, true)
    end },
}
local MORE = {
    { button = TEXT.export, tip = TEXT.exportTip, needs = Usable, run = Export },
    { button = TEXT.import, tip = TEXT.importTip, needs = Usable, run = Import },
}

-- A row of buttons from x, y in box.
local function Buttons(box, list, x, y)
    local previous
    for _, action in ipairs(list) do
        local button = Panel.Button(box, action.button, action.tip, function()
            if not action.needs or action.needs() then Run(action.run) end
        end, action.needs, 96)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 6, 0) else button:SetPoint("TOPLEFT", x, y) end
        previous = button
    end
    return previous
end

-- One of the game's dropdowns of profiles: chosen(name) whether one is ticked, choose(name), enabled().
-- skip(name): left out of the list.
local function Menu(parent, width, tip, title, chosen, choose, enabled, skip)
    local menu = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    menu:SetWidth(width)
    menu:SetupMenu(function(_, root)
        for _, name in ipairs(Profiles.List()) do
            if not (skip and skip(name)) then
                root:CreateRadio(name, chosen, function(value) Run(choose, value) end, name)
            end
        end
    end)
    Panel.Tooltip(menu, title, tip)
    Panel.Watch({ label = title, widget = menu, Refresh = function()
        menu:GenerateMenu()
        if menu.SetEnabled then menu:SetEnabled(enabled() and true or false) end
    end })
    return menu
end

-- The tab Profiles. Returns the height of what it holds.
local function ProfilesTab(child)
    -- Accountwide: the switch
    local whose = Panel.Box(child, TEXT.accountwide, -4)
    local on = Panel.Check(whose, TEXT.on, TEXT.onTip, Profiles.On, function(value)
        if value then
            -- Its profile's settings come into use, the game's too: asked first. Till then it shows off.
            Core.Confirm(TEXT.askOn, Profiles.Character(Core.charKey) and Profiles.Character(Core.charKey).profile
                or Profiles.ACCOUNTWIDE, function()
                Profiles.SetOn(true)
                Tell(true, nil, TEXT.turnedOn, InUse())
            end)
            Refresh()
        else
            Profiles.SetOn(false)
            Tell(true, nil, TEXT.turnedOff)
        end
    end)
    on:SetPoint("TOPLEFT", 12, -10)
    Panel.Text(whose, TEXT.onNote, "GameFontDisableSmall", 18, -40)
    whose:SetHeight(64)

    -- This character's profile, and what can be done with profiles
    local yours = Panel.Box(child, TEXT.yours, -100)
    local label = yours:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, -20)
    label:SetText(TEXT.profile)
    local menu = Menu(yours, 260, TEXT.profileTip, TEXT.profile, function(name) return InUse() == name end,
        function(name)
            local ok, why = Profiles.Use(name)
            Tell(ok, why, TEXT.used, name)
        end, Usable)
    menu:SetPoint("LEFT", label, "RIGHT", 16, 0)
    Buttons(yours, ACTIONS, 14, -50)
    local copy = Menu(yours, 196, TEXT.copyFromTip, TEXT.copyFrom, function() return false end, function(name)
        Core.Confirm(TEXT.askCopy, name, function()
            local ok, why = Profiles.CopyFrom(name)
            Tell(ok, why, TEXT.copied, name)
        end, true)
    end, Usable, function(name) return name == InUse() end)
    if copy.OverrideText then copy:OverrideText(TEXT.copyFrom) end
    copy:SetPoint("TOPLEFT", 14, -80)
    Buttons(yours, MORE, 222, -80)
    yours:SetHeight(112)

    -- First the line for characters not seen yet, then every character seen on the account.
    local list = Profiles.Characters()
    table.insert(list, 1, Profiles.Character(Profiles.NEW))
    local box = Panel.Box(child, TEXT.characters, -232)
    for _, head in ipairs({ { TEXT.character, 16 }, { TEXT.profile, 220 } }) do
        local text = box:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", head[2], -12)
        text:SetText(head[1])
    end
    Config.characters = {}
    for index, character in ipairs(list) do
        local key, y = character.key, -32 - (index - 1) * 30
        local function Line() return Profiles.Character(key) or {} end
        local name = box:CreateFontString(nil, "ARTWORK", character.new and "GameFontNormal" or "GameFontHighlight")
        name:SetPoint("TOPLEFT", 16, y - 6)
        name:SetWidth(196)
        name:SetJustifyH("LEFT")
        if character.new then
            name:SetText(TEXT.newCharacters)
        else
            -- The name in its class's colour; this character's marked in grey words too.
            local colors, gray = rawget(_G, "RAID_CLASS_COLORS"), rawget(_G, "GRAY_FONT_COLOR")
            local color = colors and colors[character.class]
            local text = color and color.WrapTextInColorCode and color:WrapTextInColorCode(character.name) or character.name
            local you = gray and gray:WrapTextInColorCode(TEXT.you) or TEXT.you
            name:SetText(character.current and text .. " " .. you or text)
        end
        local row = { name = name }
        row.menu = Menu(box, 180, character.new and TEXT.newTip or TEXT.useTip,
            character.new and TEXT.newCharacters or character.name, function(value) return Line().profile == value end,
            function(value) Tell(Profiles.SetCharacter(key, value)) end, Usable)
        row.menu:SetPoint("TOPLEFT", 220, y)
        if not character.new and not character.current then
            row.forget = Panel.Button(box, TEXT.forget, TEXT.forgetTip, function()
                Core.Confirm(TEXT.askForget, character.name, function()
                    local ok, why = Profiles.Forget(key)
                    if Tell(ok, why, TEXT.forgotten, character.name) then
                        row.name:SetAlpha(0.4)
                        row.forget:Disable()
                        row.gone = true
                    end
                end, true)
            end, function() return not row.gone end, 80)
            row.forget:SetPoint("TOPLEFT", 412, y - 2)
        end
        Config.characters[key] = row
    end
    box:SetHeight(40 + #list * 30)
    return 232 + 18 + box:GetHeight() + 8
end

-- Builds the page into the frame Core put up for it. The game calls OnRefresh when it shows it.
function Config.BuildProfiles(page)
    Panel.Header(page, TEXT.title)
    Panel.Text(page, TEXT.intro, "GameFontHighlight", 7, -62)
    local tabs = { { name = TEXT.tab, build = ProfilesTab } }
    tabs[#tabs + 1] = Config.AccountTab()
    tabs[#tabs + 1] = Config.CVarsTab()

    -- The tabs' frame: a box under the tabs, each tab's part filling it
    local frame = CreateFrame("Frame", nil, page, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", 7, -118)
    frame:SetPoint("BOTTOMRIGHT", -7, 8)
    Panel.Frame(frame)
    local names, parts = {}, {}
    for index, tab in ipairs(tabs) do
        local part = CreateFrame("Frame", nil, frame)
        part:SetAllPoints()
        part:Hide()
        if tab.scroll == false then
            Core.Safe("Settings: tab " .. tab.name, tab.build, part)
        else
            local child = Panel.Scroll(part)
            child:SetHeight(Core.Safe("Settings: tab " .. tab.name, tab.build, child) or 1)
        end
        names[index], parts[index] = tab.name, part
    end
    page.tabs = Panel.Tabs(page, names, function(index)
        for which, part in ipairs(parts) do part:SetShown(which == index) end
    end, 14, -84)
    page.parts = parts
    page.OnRefresh = function() Panel.Refresh() end
    Panel.Refresh()
end
