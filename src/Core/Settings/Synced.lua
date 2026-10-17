local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - Synced: the tab Game settings of the page
--  Profiles. Which of the game's own settings the profiles keep (Sync's parts),
--  a titled box per group of them (Sync.GROUPS: the game's own groups of
--  options pages, then what is on none), two columns of checkboxes. Each
--  profile keeps its own ticks. With Accountwide off the profiles keep nothing
--  of the game's: the checkboxes are switched off.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Panel = Config.Panel
local Profiles = Core.Profiles

local TEXT = {
    tab = "Game settings",
    intro = "The game's own settings the profile in use keeps, so every character that uses it has them: set when a character comes into the world, read back when it leaves. Unticked ones the game keeps for each character, as it does without Sane UI. With Accountwide settings off (tab Profiles) none are kept.",
}

-- One box of checkboxes at y; returns the y under it.
local function Box(child, title, y, checks)
    local box = Panel.Box(child, title, y)
    local made = {}
    for _, check in ipairs(checks) do
        made[#made + 1] = Panel.Check(box, check.text, check.tip, check.get, check.set, Profiles.On)
    end
    return y - 18 - Panel.Columns(box, made) - 14
end

-- The tab Game settings. Returns the height of what it holds.
local function Fill(child)
    Panel.Text(child, TEXT.intro, "GameFontHighlight", 8, -4)
    local Sync = Core.Sync
    if not Sync.options then return 60 end -- its settings failed to load: nothing to show
    local y = -64
    for _, group in ipairs(Sync.GROUPS) do
        local checks = {}
        for _, part in ipairs(Sync.parts) do
            if part.group == group.id then
                checks[#checks + 1] = { text = part.text, tip = part.tip,
                    get = function() return Sync.PartKept(part.id) end,
                    set = function(on) Sync.KeepPart(part.id, on) end }
            end
        end
        if #checks > 0 then y = Box(child, Core.Word(group.id, group.fallback), y, checks) end
    end
    return -y
end

-- The tab Game settings.
function Config.AccountTab()
    return { name = TEXT.tab, build = Fill }
end
