local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - People
--  What the player writes about other players: an alias, a name of their own
--  choosing that Sane UI shows in place of a character's name (five alts of one
--  friend can all be "Saneroki"), and a note. Kept for the account, by the
--  player's key (Core.PlayerKeyOf: the whole name on Forever, Name-Realm
--  elsewhere), in SaneUIDB.modules.SaneUI.people; personal data, never shared
--  (Doc/guides/data.md, *Game facts and personal data*).
--
--  Written from the game's own menu of a player (a name in a chat, the friends
--  list, the guild, the target, the group), which every one of those opens:
--  Menu.ModifyMenu appends two lines to it, Set Alias and Set Note, each asking
--  in the game's input dialog. Empty text takes the alias or note away.
--
--      Core.People.Key(text)          the key of a player named by text; nil if it is no whole name
--      Core.People.Alias(key)         the alias, or nil
--      Core.People.Note(key)          the note, or nil
--      Core.People.Shown(text)        what to show for a player named by text: the alias, else nil
--      Core.People.Set(key, what, v)  what = "alias" or "note"; v nil or "" takes it away
--      Core.People.Watch(fn)          fn() after any change (a view draws its names anew)
-------------------------------------------------------------------------------
local People = {}
Core.People = People

local TEXT = {
    alias = "Set Alias",
    note = Core.Word("SET_NOTE", "Set Note"),
    askAlias = "The name Sane UI shows for %s (empty: their own name):",
    askNote = "A note about %s (empty: none):",
}
People.TEXT = TEXT
People.LETTERS = { alias = 24, note = 80 }

-- The game's menus of a player character: those its player popup tags MENU_UNIT_<which>.
People.MENUS = { "PLAYER", "FRIEND", "FRIEND_OFFLINE", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "RAID", "TARGET",
                 "FOCUS", "CHAT_ROSTER", "GUILD", "GUILD_OFFLINE", "COMMUNITIES_GUILD_MEMBER",
                 "COMMUNITIES_WOW_MEMBER", "RECENT_ALLY", "RECENT_ALLY_OFFLINE", "PVP_SCOREBOARD",
                 "WORLD_STATE_SCORE" }

local listeners = {}

-- [key] = { alias = "...", note = "..." }: found the first time it is asked, once the saved settings are read.
local function List()
    local store = Core.Store(Core.name)
    if type(store.people) ~= "table" then store.people = {} end
    return store.people
end

local function Clean(value)
    if type(value) ~= "string" then return nil end
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
end

function People.Key(text)
    return Core.PlayerKeyOf(text)
end

local function Field(key, what)
    if type(key) ~= "string" then return nil end
    local person = List()[key]
    return type(person) == "table" and Clean(person[what]) or nil
end

function People.Alias(key) return Field(key, "alias") end
function People.Note(key) return Field(key, "note") end

function People.Shown(text)
    return People.Alias(People.Key(text))
end

function People.Set(key, what, value)
    if type(key) ~= "string" or (what ~= "alias" and what ~= "note") then return end
    local list = List()
    local person = type(list[key]) == "table" and list[key] or {}
    person[what] = Clean(value)
    list[key] = next(person) and person or nil
    for _, fn in ipairs(listeners) do Core.Safe("people", fn) end
end

function People.Watch(fn)
    listeners[#listeners + 1] = fn
end

-- The player a menu is about: by its unit where it has one, else by the name (and realm) it was given.
local function Whom(data)
    if type(data) ~= "table" then return nil end
    local key = data.unit and Core.PlayerKey(data.unit)
    if key then return key, Core.FullName(data.unit) or key end
    local name = Core.Plain(data.name)
    if type(name) ~= "string" or name == "" then return nil end
    local server = Core.Plain(data.server)
    local text = type(server) == "string" and server ~= "" and not Core.Surnames() and name .. "-" .. server or name
    key = People.Key(text)
    return key, key and name or nil
end

local function Ask(key, shown, what)
    Core.AskText(what == "alias" and TEXT.askAlias or TEXT.askNote, shown, nil, Field(key, what) or "",
        function(value) People.Set(key, what, value) end, People.LETTERS[what])
end

-- The two lines under the game's own, after a divider; the alias and the note there now in their tooltips.
local function Extend(_, root, data)
    local key, shown = Whom(data)
    if not key then return end
    root:CreateDivider()
    for _, what in ipairs({ "alias", "note" }) do
        local button = root:CreateButton(TEXT[what], function() Core.Safe("people", Ask, key, shown, what) end)
        local now = Field(key, what)
        if now and button.SetTooltip then
            button:SetTooltip(function(tooltip) GameTooltip_SetTitle(tooltip, now) end)
        end
    end
end

if Menu and Menu.ModifyMenu then
    for _, which in ipairs(People.MENUS) do Menu.ModifyMenu("MENU_UNIT_" .. which, Core.Guard("aliases", Extend)) end
end
