local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Presets
--  What the profile Speedleveling sets over the defaults (Saneroki, 2026-10-30):
--  our recommended CVars, kept as single CVars of Sync's (Sync.Keep, the tick in
--  the tab CVars), so they are written into the game at the login and what the
--  player changes afterwards goes into the profile as anything else. A CVar one
--  of the two games lacks is passed over. And all of Speed Leveling's switches,
--  off by default, on in Speedleveling alone, with what other modules do by
--  themselves for it (Economy's Send by itself). And in Retail the Newcomer Chat,
--  which the game puts a character in by itself: left every time.
--  Accountwide is given none of this (Saneroki, 2026-11-15: "Accountwide profile
--  should be generated from the users current settings instead of my generic
--  defaults"): it is made from the settings of the character that turned the
--  profiles on (Profiles.lua). Character specific has none of it either: it
--  stays as the game has it. While the profiles are off nothing is given.
--
--  Given to a profile once for each Presets.VERSION, and then only what it does
--  not have yet (Profiles.lua: Standard), but all of it over a Speedleveling
--  made just then as a copy of Accountwide: raise the number when something is
--  added here, and every account gets what is new, while what a player changed
--  stays.
--
--      Core.Presets.VERSION
--      Core.Presets.profiles[name]   { [module] = { [switch] = value } }
-------------------------------------------------------------------------------
local Presets = { VERSION = 6, profiles = {} }
Core.Presets = Presets

-- Our recommended CVars, in Speedleveling. No water detail: its 3 crashed Forever's client in the Ruins of
-- Lordaeron, and SaneUI never sets it (Sync.Barred; Saneroki, 2026-11-06).
local RECOMMENDED = {
    -- How far and how much the world shows.
    farclip = "10000",               -- terrain and buildings out to the engine's ceiling
    horizonClip = "10000",           -- the sky's geometry out to that terrain
    horizonStart = "6000",           -- the horizon's fog far off, far mountains clear
    groundEffectDensity = "256",     -- the most grass and flowers
    groundEffectDist = "500",        -- out to 500 yards round you
    groundEffectFade = "500",        -- and fading out only at that edge
    weatherDensity = "3",            -- the most rain and snow
    shadowMode = "4",                -- the finest shadows
    shadowTextureSize = "2048",      -- without jagged edges
    SSAO = "4",                      -- the most ambient occlusion
    -- The frame rate, in front, behind and aimed at.
    maxFPS = "115", useMaxFPS = "1",
    maxFPSBk = "115", useMaxFPSBk = "1",
    targetFPS = "115", useTargetFPS = "1",
    -- Loading screens: the game does not wait for what is not needed at once.
    worldPreloadNonCritical = "0",
    worldPreloadHighResTextures = "0",
    -- A little more room.
    cameraDistanceMaxZoomFactor = "2.6", -- the camera out as far as the game lets it
    screenshotQuality = "10",
}

-- Speedleveling: nothing that stops or slows you.
local SPEEDLEVELING = {
    ffxDeath = "0",                  -- no grey blur when you die
    showTutorials = "0",             -- no tutorials on a new character
    instantQuestText = "1",          -- a quest's text at once, word for word not (Forever)
    Sound_EnableErrorSpeech = "0",   -- no "I can't do that" at every press of the key
    autoDismountFlying = "1",        -- a spell cast in the air takes you down
}

-- Speed Leveling's switches: every one of them, which is what makes the profile Speedleveling; but Professions along
-- the way, off there too (Saneroki, 2026-11-05: "don't do the profession steps").
local LEVELING = { follow = "on" }
for _, switch in ipairs({ "loot", "corpses", "talk", "walk", "objects", "useOn", "skull", "guide", "hearth", "items",
                          "take", "handin", "rewards", "gossip", "leave", "lootAll", "equipUpgrades", "rolls", "cinematics",
                          "party", "showGuide", "classQuests", "showArrow", "mapPin", "icons" }) do
    LEVELING[switch] = true
end

-- Economy's, for Speed Leveling: with Send to banker ticked, the mail to the banker goes at the mailbox without a click (Banker.lua; Saneroki,
-- 2026-11-09: "while speedleveling is turned on it aldo sends it totally automatically").
local ECONOMY = { bankerAuto = true }

-- Social's wish for a channel of the game, by the game's name of it: never in it (Join.lua). Forever has that one
-- switched off.
local SOCIAL = Core.ForGame({ retail = { presence = { ["Newcomer Chat"] = false } } })

local function With(extra)
    local named = {}
    for name, value in pairs(RECOMMENDED) do named[name] = value end
    for name, value in pairs(extra) do named[name] = value end
    return named
end

Presets.profiles.Speedleveling = { Sync = { named = With(SPEEDLEVELING) }, SpeedLeveling = LEVELING, Economy = ECONOMY,
                                  Social = SOCIAL }
