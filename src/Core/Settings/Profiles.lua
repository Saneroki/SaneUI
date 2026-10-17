local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Profiles
--  The page Profiles, a page of our own in the game's options (a canvas: Core
--  puts it up, Core.frames.Profiles): its title, a line on whose settings are in
--  use, and tabs, each a box of its own:
--      Profiles        Account wide: All settings accountwide
--                      Saved profiles: the profile, Load, Save, Duplicate, Rename, Delete
--                      (Empty and SaneUI Defaults are always there, and cannot be saved
--                      over, renamed or deleted)
--                      Characters: first New Characters, what a character not seen yet starts
--                      with; then every character seen; each with its profile, Load at login
--                      and Save at logout
--      Accountwide     which settings are account wide: Sane UI's modules, and
--                      Sync's parts in a titled box per group (Synced.lua)
--      CVars           the list of the game's CVars (CVars.lua)
--
--  Core keeps the profiles and does the work (Core/Profiles.lua); this file only
--  shows them. The names are asked for in the game's own dialogs, those it keeps
--  for addons (GENERIC_INPUT_BOX, GENERIC_CONFIRMATION).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Profiles = Core.Profiles

local TEXT = {
    title = "Profiles",
    intro = "Settings are saved account wide by default: every character uses the same ones.",
    tab = "Profiles",
    whose = "Account wide",
    all = "All settings accountwide",
    allTip = "Ticked, every character uses the same settings: those ticked in the tab Accountwide. Unticked, every character keeps all its settings to itself. A character with a profile and Load at login (below) uses its profile instead.",
    allNote = "Ticked will sync all settings accountwide by default. Profiles overwrites the setting on a per character basis.",
    characters = "Characters",
    character = "Character",
    you = "(this character)",
    saved = "Saved profiles",
    profile = "Profile",
    profileTip = "A profile keeps the settings of every module under a name, for all your characters. The buttons act on the profile chosen here. Two are always there, and can be loaded and duplicated, not changed, renamed or deleted: Empty, no profile, the settings as they are kept (the account's, or each character's own), loaded at every login and saved at every logout and /reload; and SaneUI Defaults, every setting of Sane UI's own as it is at first, without the game's settings that Sync keeps.",
    autoLoad = "Load at login",
    autoLoadTip = "Each time this character logs in (also after a /reload), it uses the settings of its profile: for itself only, the account's stay as they are. Empty always loads.",
    autoSave = "Save at logout",
    autoSaveTip = "Each time this character logs out (also at a /reload), its settings are saved into its profile. With Load at login too, it keeps its profile up to date, and so can other characters with the same profile. Empty always saves; SaneUI Defaults never, it stays as it is.",
    useProfile = "Profile of this character",
    useProfileTip = "The profile this character loads at login and saves into at logout, as ticked beside it. Empty: no profile, the settings as they are kept, loaded at every login and saved at every logout and /reload.",
    newCharacters = "New Characters",
    newTip = "A character Sane UI has not seen yet (a new one, or one that has not logged in since Sane UI was installed) starts with this line at its first login: its profile, Load at login and Save at logout. Its own line below can change them afterwards.",
    load = "Load",
    loadTip = "Every module takes the settings kept in the profile. They change the account's settings, or this character's own when it has them. Empty puts the kept settings back in use where a profile is in use. SaneUI Defaults sets every setting of Sane UI's modules switched on back to its default; the game's settings that Sync keeps stay as they are.",
    save = "Save",
    saveTip = "Keeps the settings of every module in a profile. You are asked for its name; the chosen profile's is filled in.",
    duplicate = "Duplicate",
    duplicateTip = "Makes a copy of the profile under another name.",
    rename = "Rename",
    renameTip = "Gives the profile another name. Not Empty or SaneUI Defaults.",
    delete = "Delete",
    deleteTip = "Deletes the profile. The settings in use stay as they are. Not Empty or SaneUI Defaults.",
    askSave = "Save the settings of every module as the profile (one of that name is replaced):",
    askDuplicate = "Copy the profile %s as:",
    askRename = "Rename the profile %s to:",
    askDelete = "Delete the profile %s?",
    loaded = "the settings of the profile %s are in use.",
    savedAs = "the settings of every module are saved as the profile %s.",
    noDialog = "the game's dialog for this is missing",
}
local Panel = Config.Panel

-- The controls show what changed: the values in use, whose they are, the profiles. A frame later,
-- so that the setting whose change started it has finished its own work first.
local Refresh = Core.Later(function() Config.Refresh() end)

-- Says how a step went: done (with the chosen profile's name) or why not, in chat.
local function Tell(ok, why, done)
    if not ok then
        Core.Print(why)
        return
    end
    if done then Core.Print(done:format(Profiles.Chosen())) end
    Refresh()
end

local function Run(fn, ...)
    Core.Safe("Settings: profiles", fn, ...)
end

-- One of the game's dialogs for addons, shown with data; nil (and noted) if it is gone.
local function Dialog(which, data)
    if not (StaticPopupDialogs and StaticPopupDialogs[which]) then
        Core.Report("Settings: profiles", TEXT.noDialog .. " (" .. which .. ")")
        return nil
    end
    return StaticPopup_Show(which, nil, nil, data)
end

-- Asks for a name. text may name the profile (%s); typed is filled in; done(name) once accepted.
local function AskName(text, profile, typed, accept, done)
    local dialog = Dialog("GENERIC_INPUT_BOX", { text = text, text_arg1 = profile, acceptText = accept,
        maxLetters = Profiles.MAX_NAME, callback = function(name) Run(done, name) end })
    local box = dialog and dialog.GetEditBox and dialog:GetEditBox()
    if box and typed then
        box:SetText(typed)
        box:HighlightText()
    end
end

local function Delete(profile)
    Tell(Profiles.Delete(profile))
end

-- The chosen profile can be renamed and deleted: not Empty or SaneUI Defaults.
local function Changeable()
    return not Profiles.Fixed(Profiles.Chosen())
end

-- What the buttons do, each with the chosen profile (there always is one: at least SaneUI
-- Defaults); needs: when the button can be used.
local ACTIONS = {
    { button = TEXT.load, tip = TEXT.loadTip, run = function(profile)
        local ok, why = Profiles.Load(profile)
        Tell(ok, why, TEXT.loaded)
    end },
    { button = TEXT.save, tip = TEXT.saveTip, run = function(profile)
        -- The chosen profile's name to save over it; none for Empty and SaneUI Defaults, which cannot be.
        local typed = not Profiles.Fixed(profile) and profile or nil
        AskName(TEXT.askSave, nil, typed, TEXT.save, function(name)
            local ok, why = Profiles.Save(name)
            Tell(ok, why, TEXT.savedAs)
        end)
    end },
    { button = TEXT.duplicate, tip = TEXT.duplicateTip, run = function(profile)
        AskName(TEXT.askDuplicate, profile, nil, TEXT.duplicate, function(name) Tell(Profiles.Duplicate(profile, name)) end)
    end },
    { button = TEXT.rename, tip = TEXT.renameTip, needs = Changeable, run = function(profile)
        AskName(TEXT.askRename, profile, profile, TEXT.rename, function(name) Tell(Profiles.Rename(profile, name)) end)
    end },
    { button = TEXT.delete, tip = TEXT.deleteTip, needs = Changeable, run = function(profile)
        Dialog("GENERIC_CONFIRMATION", { text = TEXT.askDelete, text_arg1 = profile, showAlert = true,
            callback = function() Run(Delete, profile) end })
    end },
}

-- The tab Profiles. Returns the height of what it holds.
local function ProfilesTab(child)
    -- Whether the settings are the account's
    local whose = Panel.Box(child, TEXT.whose, -4)
    local all = Panel.Check(whose, TEXT.all, TEXT.allTip, Profiles.AccountWide, function(on)
        Profiles.SetAccountWide(on)
        Refresh()
    end)
    all:SetPoint("TOPLEFT", 12, -10)
    Panel.Text(whose, TEXT.allNote, "GameFontDisableSmall", 18, -40)
    whose:SetHeight(64)

    -- The saved profiles: the one chosen, what can be done with it
    local saved = Panel.Box(child, TEXT.saved, -104)
    local label = saved:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, -20)
    label:SetText(TEXT.profile)
    local menu = CreateFrame("DropdownButton", nil, saved, "WowStyle1DropdownTemplate")
    menu:SetWidth(260)
    menu:SetPoint("LEFT", label, "RIGHT", 16, 0)
    menu:SetupMenu(function(_, root)
        local function IsChosen(name) return Profiles.Chosen() == name end
        local function Choose(name)
            Profiles.Choose(name)
            Panel.Refresh()
        end
        for _, name in ipairs(Profiles.List()) do root:CreateRadio(name, IsChosen, Choose, name) end
    end)
    Panel.Tooltip(menu, TEXT.profile, TEXT.profileTip)
    Panel.Watch({ label = TEXT.profile, widget = menu, Refresh = function() menu:GenerateMenu() end })

    local previous
    for _, action in ipairs(ACTIONS) do
        local button = Panel.Button(saved, action.button, action.tip, function()
            if not action.needs or action.needs() then Run(action.run, Profiles.Chosen()) end
        end, action.needs)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 6, 0) else button:SetPoint("TOPLEFT", 14, -50) end
        previous = button
    end
    saved:SetHeight(84)

    -- First the line for characters not seen yet, then every character seen on the account, each on
    -- a line: its profile, loaded at login and saved at logout if ticked.
    local list = Profiles.Characters()
    table.insert(list, 1, { key = Profiles.NEW, new = true })
    local box = Panel.Box(child, TEXT.characters, -206)
    for _, head in ipairs({ { TEXT.character, 16 }, { TEXT.autoLoad, 168 }, { TEXT.autoSave, 268 }, { TEXT.profile, 384 } }) do
        local text = box:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", head[2], -12)
        text:SetText(head[1])
    end
    Config.characters = {}
    for index, character in ipairs(list) do
        local key, y = character.key, -32 - (index - 1) * 30
        local function Line() return Profiles.Character(key) or {} end
        -- Empty always loads and saves (shown ticked, switched off); SaneUI Defaults is never saved into.
        local function Loads() return Line().profile ~= Profiles.EMPTY end
        local function Saves() return not Profiles.Fixed(Line().profile) end
        local name = box:CreateFontString(nil, "ARTWORK", character.new and "GameFontNormal" or "GameFontHighlight")
        name:SetPoint("TOPLEFT", 16, y - 6)
        name:SetWidth(145)
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
        local loadTip, saveTip, menuTip = TEXT.autoLoadTip, TEXT.autoSaveTip, TEXT.useProfileTip
        if character.new then loadTip, saveTip, menuTip = TEXT.newTip, TEXT.newTip, TEXT.newTip end
        row.load = Panel.Check(box, TEXT.autoLoad, loadTip, function() return Line().autoLoad end, function(on)
            Profiles.SetCharacter(key, "autoLoad", on)
            Refresh()
        end, Loads, true)
        row.load:SetPoint("TOPLEFT", 196, y)
        row.save = Panel.Check(box, TEXT.autoSave, saveTip, function() return Line().autoSave end, function(on)
            Profiles.SetCharacter(key, "autoSave", on)
        end, Saves, true)
        row.save:SetPoint("TOPLEFT", 296, y)
        local choice = CreateFrame("DropdownButton", nil, box, "WowStyle1DropdownTemplate")
        choice:SetWidth(180)
        choice:SetPoint("TOPLEFT", 384, y)
        choice:SetupMenu(function(_, root)
            local function IsChosen(value) return Line().profile == value end
            local function Choose(value)
                Profiles.SetCharacter(key, "profile", value)
                Refresh()
            end
            for _, profile in ipairs(Profiles.List()) do root:CreateRadio(profile, IsChosen, Choose, profile) end
        end)
        Panel.Tooltip(choice, character.new and TEXT.newCharacters or TEXT.useProfile, menuTip)
        Panel.Watch({ label = TEXT.useProfile, widget = choice, Refresh = function() choice:GenerateMenu() end })
        row.menu, Config.characters[key] = choice, row
    end
    box:SetHeight(40 + #list * 30)
    return 206 + 18 + box:GetHeight() + 8
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
