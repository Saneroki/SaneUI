local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Native
--  The game's own chat: out of sight while our window is open (Hide), and
--  back exactly as it was when it is not (Show).
--
--  Nothing is hidden, closed or switched off: each of its frames gets a hidden
--  frame of ours as parent, and its own parent back later. So the game's chat
--  goes on collecting every line, and when our window goes (or fails) it is
--  complete. The game's edit boxes are not among them: they belong to the
--  screen, not to a chat frame, and Input.lua puts them into our window.
--
--  The game moves some of these frames to other parents itself (a tab into the
--  dock and out of it, all of them under a window that fills the screen). One
--  it has moved meanwhile is left where the game put it.
-------------------------------------------------------------------------------
local Native = {}
ns.Native = Native

-- What belongs to the game's chat besides its windows (CHAT_FRAMES), their tabs and the buttons of
-- minimised ones. Not every client has all.
local PARTS = { "GeneralDockManager", "QuickJoinToastButton", "TextToSpeechButtonFrame", "ChatAlertFrame",
                "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton" }

local hidden       -- the parent of what is out of sight
local parents = {} -- [frame] = its own parent

-- A new parent, the same layer: the game's own way for its chat frames.
local function Move(frame, parent)
    if FrameUtil and FrameUtil.SetParentMaintainRenderLayering then
        FrameUtil.SetParentMaintainRenderLayering(frame, parent)
    else
        frame:SetParent(parent)
    end
end

local function Away(frame)
    if not frame or frame:GetParent() == hidden then return end
    parents[frame] = frame:GetParent()
    Move(frame, hidden)
end

-- The game makes new frames of its chat while ours is open: they go out of sight too.
local function Again()
    if Native.away then ns.Guarded(Native.Hide) end
end

function Native.Hide()
    if not hidden then
        hidden = CreateFrame("Frame", nil, UIParent)
        hidden:Hide()
        -- A whisper in a window of its own (an option of the game) makes a new chat frame; a window
        -- minimised for the first time gets its button (a child of the screen, as its tab).
        if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", Again) end
        if FCF_MinimizeFrame then hooksecurefunc("FCF_MinimizeFrame", Again) end
    end
    Native.away = true
    for _, name in ipairs(CHAT_FRAMES) do
        local frame = _G[name]
        Away(frame)
        -- A docked window's tab is in the dock and goes with it; the game moves those about itself.
        if frame and not frame.isDocked then Away(_G[name .. "Tab"]) end
        Away(_G[name .. "Minimized"])
    end
    for _, name in ipairs(PARTS) do Away(_G[name]) end
end

-- Each frame by itself: one that fails keeps none of the others out of sight.
function Native.Show()
    Native.away = false
    for frame, parent in pairs(parents) do
        if frame:GetParent() == hidden then pcall(Move, frame, parent) end
    end
    wipe(parents)
end
