local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Synced: what is account wide, the tab Accountwide
--  of the page Profiles: a box Sane UI with a checkbox per module, its settings
--  the same on all characters (Core.Profiles.Shared); then a titled box per
--  group of Sync's parts (Sync.GROUPS: the game's own groups of options pages,
--  then what is on none), two columns of checkboxes. With "All settings
--  accountwide" unticked, nothing is account wide: the checkboxes are switched
--  off.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Panel = Config.Panel
local Profiles = Core.Profiles

local TEXT = {
    tab = "Accountwide",
    intro = "Ticked settings are the same on all your characters, and part of your profiles. Unticked ones each character keeps to itself. The game's are saved when you log out and set when a character logs in.",
    sane = "Sane UI",
    general = "General",
    moduleTip = "Ticked, the settings of %s are the same on all your characters. Unticked, each character keeps its own.",
}

-- The modules whose settings can be account wide or each character's own: those with switches,
-- and Core's general ones. Not Sync's, which is no module: they go with every character's settings.
local function Modules()
    local list = {}
    for _, name in ipairs(Core.optionOrder) do
        local module = SaneUI[name]
        if name == Core.name then
            list[#list + 1] = { name = name, title = TEXT.general }
        elseif module then
            list[#list + 1] = { name = name, title = module.title }
        end
    end
    return list
end

-- One box of checkboxes at y; returns the y under it.
local function Box(child, title, y, checks)
    local box = Panel.Box(child, title, y)
    local made = {}
    for _, check in ipairs(checks) do
        made[#made + 1] = Panel.Check(box, check.text, check.tip, check.get, check.set, Profiles.AccountWide)
    end
    return y - 18 - Panel.Columns(box, made) - 14
end

-- The tab Accountwide. Returns the height of what it holds.
local function Fill(child)
    Panel.Text(child, TEXT.intro, "GameFontHighlight", 8, -4)
    local checks = {}
    for _, module in ipairs(Modules()) do
        checks[#checks + 1] = { text = module.title, tip = TEXT.moduleTip:format(module.title),
            get = function() return Profiles.Shared(module.name) end,
            set = function(on) Profiles.SetShared(module.name, on) end }
    end
    local y = Box(child, TEXT.sane, -50, checks)
    local Sync = Core.Sync
    if not Sync.options then return -y end -- its settings failed to load: nothing to show
    for _, group in ipairs(Sync.GROUPS) do
        checks = {}
        for _, part in ipairs(Sync.parts) do
            if part.group == group.id then
                checks[#checks + 1] = { text = part.text, tip = part.tip,
                    get = function() return Sync.PartKept(part.id) end,
                    set = function(on) Sync.KeepPart(part.id, on) end }
            end
        end
        if #checks > 0 then y = Box(child, Sync.Word(group.id, group.fallback), y, checks) end
    end
    return -y
end

-- The tab Accountwide.
function Config.AccountTab()
    return { name = TEXT.tab, build = Fill }
end
