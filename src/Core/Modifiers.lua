local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Modifiers
--  Shift, Ctrl and Alt for those who wait for them. The game sends
--  MODIFIER_STATE_CHANGED when one of these keys goes down or up in its window.
--  With two game windows (one on each screen), Shift held in one and the mouse
--  moved into the other, the window manager gives the keyboard to the window
--  under the mouse, and that window may learn the key is held from the system
--  without any key press: IsShiftKeyDown() says true, and the game sends no
--  event. A tooltip that waits for Shift would wait for ever. So while something
--  waits (a tooltip is shown, a pin is hovered), the keys are looked at a few
--  times a second, and a change nobody was told of is raised as the event
--  (Core.Raise) for all who listen. Nothing waits, nothing runs.
--  If the window is not told of the key at all (IsShiftKeyDown stays false), no
--  addon can know: /sane keys shows what the window sees, to tell the two apart.
--
--      Core.Modifiers.Want(owner, true)   -- keep looking while owner waits
--      Core.Modifiers.Want(owner, false)  -- owner waits no more
-------------------------------------------------------------------------------
local Modifiers = { LOOK = 0.1 } -- seconds between two looks
Core.Modifiers = Modifiers

-- Per key: the game's call that says it is down, and the two sides' calls and event names.
local KEYS = {
    { ask = "IsShiftKeyDown", sides = { { "IsLeftShiftKeyDown", "LSHIFT" }, { "IsRightShiftKeyDown", "RSHIFT" } }, word = "Shift" },
    { ask = "IsControlKeyDown", sides = { { "IsLeftControlKeyDown", "LCTRL" }, { "IsRightControlKeyDown", "RCTRL" } }, word = "Ctrl" },
    { ask = "IsAltKeyDown", sides = { { "IsLeftAltKeyDown", "LALT" }, { "IsRightAltKeyDown", "RALT" } }, word = "Alt" },
}

local heard, found = 0, 0 -- changes the game told us of, and changes we found it had not
local wanted, count = {}, 0
local watch -- the frame whose OnUpdate looks; shown while somebody wants it

-- Whether the game says the key is down now.
local function Down(entry)
    local ask = rawget(_G, entry.ask)
    return ask ~= nil and Core.Ask(ask) == true
end

-- Which side of the key is down, as the event names it ("LSHIFT"); the left one when the game cannot say.
local function Side(entry)
    for _, side in ipairs(entry.sides) do
        local ask = rawget(_G, side[1])
        if ask and Core.Ask(ask) == true then return side[2] end
    end
    return entry.sides[1][2]
end

-- What each key was when the game or a look last said so, and which side of it went down last.
local was, side = {}, {}
local raising = false -- our own event is on its way round: not the game's news

-- The game's own news: a change it told of (or ours, which only keeps the books straight).
Core.On("MODIFIER_STATE_CHANGED", function(key, down)
    if not raising then heard = heard + 1 end
    for _, entry in ipairs(KEYS) do
        for _, one in ipairs(entry.sides) do
            if one[2] == key then
                was[entry] = down == 1
                side[entry] = key
            end
        end
    end
end)

-- One look: a key whose state is not what the game last said is raised as its event.
local function Look()
    for _, entry in ipairs(KEYS) do
        local down = Down(entry)
        local before = was[entry]
        was[entry] = down
        if before ~= nil and before ~= down then
            found = found + 1
            local key = down and Side(entry) or side[entry] or entry.sides[1][2]
            raising = true
            Core.Raise("MODIFIER_STATE_CHANGED", key, down and 1 or 0)
            raising = false
        end
    end
end

local function Watching()
    watch = CreateFrame("Frame")
    watch:Hide()
    Modifiers.watch = watch -- for the tests
    local passed = 0
    watch:SetScript("OnShow", Core.Guard("modifiers", function()
        passed = 0
        Look()
    end))
    watch:SetScript("OnUpdate", Core.Guard("modifiers", function(_, elapsed)
        passed = passed + elapsed
        if passed < Modifiers.LOOK then return end
        passed = 0
        Look()
    end))
end

function Modifiers.Want(owner, on)
    if on then
        if wanted[owner] then return end
        wanted[owner] = true
        count = count + 1
        if count == 1 then
            if not watch then Watching() end
            watch:Show()
        end
    elseif wanted[owner] then
        wanted[owner] = nil
        count = count - 1
        if count == 0 and watch then watch:Hide() end
    end
end

-- Counts, for the tests and for /sane keys.
function Modifiers.Counts()
    return heard, found
end

-------------------------------------------------------------------------------
--  /sane keys: what this game window sees of Shift, Ctrl and Alt
-------------------------------------------------------------------------------
local TEXT = {
    about = "shows what this game window sees of Shift, Ctrl and Alt (for two game windows: hold Shift in one, move the mouse into the other)",
    line = "Shift %s   Ctrl %s   Alt %s      told by the game: %d      found without it: %d",
    on = "|cff55ff55down|r",
    off = "up",
    help = "Hold Shift in one game window and move the mouse into the other, with this on in both. If Shift reads down there, the window learned of it; 'found without it' counts such changes, and Sane UI passes them on. If it stays up, this window was never told: that is the game or the computer, not Sane UI.",
}

local readout

local function Show()
    local state = {}
    for index, entry in ipairs(KEYS) do state[index] = Down(entry) and TEXT.on or TEXT.off end
    readout.text:SetText(TEXT.line:format(state[1], state[2], state[3], heard, found))
end

local function Readout()
    readout = CreateFrame("Frame", nil, UIParent)
    readout:SetSize(520, 26)
    readout:SetPoint("TOP", UIParent, "TOP", 0, -90)
    readout:SetFrameStrata("TOOLTIP")
    local back = readout:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.75)
    readout.text = readout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    readout.text:SetPoint("CENTER")
    readout:SetScript("OnUpdate", Core.Guard("keys", Show))
    readout:Hide()
end

Core.Command("keys", TEXT.about, function()
    if not readout then Readout() end
    local on = not readout:IsShown()
    readout:SetShown(on)
    Modifiers.Want(readout, on)
    if on then Core.Print(TEXT.help) end
end)
