local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Keys
--  Your guild key opens our guild window instead of the game's (the switch The
--  Guild Key Opens It): whatever keys the game's key bindings give its action
--  TOGGLEGUILDTAB run ours (Bindings.xml, in the game's key bindings under
--  Sane UI), by the game's own override bindings, which leave your key
--  bindings as they are. Pressed again while it shows, it closes, as the
--  game's key toggles its window. The game's micro menu button still opens the
--  game's own guild window.
--
--  Only while you are in a guild: outside one the game's key opens the game's
--  own window, where a guild is found.
--
--  Override bindings change out of a fight only: set at the login, anew when
--  your key bindings change (UPDATE_BINDINGS, only when the guild key did) or
--  you join or leave a guild (PLAYER_GUILD_UPDATE), and taken away when the
--  switch is off or the module stands down; in a fight, once it is over. Our
--  key itself works in a fight too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Keys = {}
ns.Keys = Keys

Keys.ACTION = "TOGGLEGUILDTAB"
Keys.COMMAND = "SANEUI_GUILD_TOGGLE"

-- Its words in the game's key bindings.
BINDING_NAME_SANEUI_GUILD_TOGGLE = "Open or close the guild window"

local owner
local bound = nil -- the guild key's keys when they were last bound
local guilded = nil -- whether the player was in a guild then

local function Signature()
    local one, two = GetBindingKey(Keys.ACTION)
    return tostring(one) .. "," .. tostring(two)
end

local function InGuild()
    return Core.Ask(rawget(_G, "IsInGuild")) == true
end

-- Our key on the game's guild key, while in a guild: out of a fight, or once it is over.
function Keys.Bind()
    if not owner then return end
    if InCombatLockdown() then return Core.AfterCombat("Guild: keys", Keys.Bind) end
    ClearOverrideBindings(owner)
    bound, guilded = Signature(), InGuild()
    if ns.off or ns.options.keys == false or not guilded then return end
    for _, key in ipairs({ GetBindingKey(Keys.ACTION) }) do
        if type(key) == "string" and key ~= "" then SetOverrideBinding(owner, false, key, Keys.COMMAND) end
    end
end

local function Changed()
    if ns.off or (Signature() == bound and InGuild() == guilded) then return end
    Keys.Bind()
end

-- Our key was pressed (Bindings.xml).
function Keys.Press()
    if ns.off then return end
    ns.Window.Toggle()
end

function Keys.Start()
    owner = CreateFrame("Frame")
    ns.On("UPDATE_BINDINGS", Changed)
    ns.On("PLAYER_GUILD_UPDATE", Changed)
    Keys.Bind()
end

-- The module stood down: the guild key opens the game's window again.
function Keys.Leave()
    if not owner then return end
    if InCombatLockdown() then
        Core.AfterCombat("Guild: keys", Keys.Leave)
        return
    end
    ClearOverrideBindings(owner)
end
