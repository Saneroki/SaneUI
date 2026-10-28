local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Quiet
--  The game's interface out of sight while you talk (Saneroki, 2026-10-28):
--  the whole of it (UIParent) fades out as the talk comes and back in when it
--  ends, at once when a fight begins. Nothing of the game's is hidden: its
--  frames stay where they are and shown, only clear (an alpha, which the game
--  allows in a fight too, lent: Core.Lend), so no OnHide of the game's runs from
--  our code and nothing it holds is closed.
--  Kept in sight over it, each frame ignoring its parent's alpha for that time
--  (what it did before noted and put back):
--    - the talk itself (Look.lua, always);
--    - the game's questions (StaticPopup1-4: a quest that costs money, a quest a
--      friend shares, a gossip's question) and its error lines (UIErrorsFrame:
--      your bags are full, choose a reward);
--    - the tooltips (GameTooltip and its two comparisons), only while one shows
--      for a part of the talk (Quiet.Tips): the clear frames under the mouse
--      show none. Sane UI's tooltip panels follow their tooltip.
--  The clear frames still take the mouse; the talk lies over them where it
--  stands.
--
--      Quiet.On()        the interface fades out (when the setting says so; never in a fight)
--      Quiet.Off(now)    it fades back in (now: at once)
--      Quiet.Tips(on)    the tooltips in sight over it, while a part of the talk shows one
--      Quiet.GiveBack()  the interface as it was, now
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Quiet = {}
ns.Quiet = Quiet

Quiet.FADE = 0.4 -- seconds the interface takes to fade out or back in

local KEPT = { "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4", "UIErrorsFrame" }
local TIPS = { "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2" }

local driver          -- a frame of ours that moves the alpha, its OnUpdate set only while it moves
local lend            -- UIParent, lent while its alpha is ours
local base = 1        -- UIParent's alpha before ours, which it fades back to
local from, to, began -- the fade under way
local noted = {}      -- [frame] = whether it ignored its parent's alpha before ours (nil: not ours now)

local function Keep(list, on)
    for _, name in ipairs(list) do
        local frame = rawget(_G, name)
        if type(frame) == "table" and type(frame.SetIgnoreParentAlpha) == "function" then
            if on then
                if noted[frame] == nil then
                    noted[frame] = Core.Plain(frame:IsIgnoringParentAlpha()) == true
                end
                frame:SetIgnoreParentAlpha(true)
            elseif noted[frame] ~= nil then
                frame:SetIgnoreParentAlpha(noted[frame])
                noted[frame] = nil
            end
        end
    end
end

-- Back in sight: UIParent's own alpha again, the kept frames as they were.
local function Done()
    if driver then driver:SetScript("OnUpdate", nil) end
    from, to = nil, nil
    local given = lend
    lend = nil
    Keep(TIPS, false)
    Keep(KEPT, false)
    if given then given:Return() end
end

local function Step()
    local share = math.min(1, (GetTime() - began) / Quiet.FADE)
    lend:SetAlpha(from + (to - from) * share)
    if share < 1 then return end
    if to == base then return Done() end
    driver:SetScript("OnUpdate", nil)
end
local Stepping -- Step, guarded: made once

local function Fade(target)
    if not driver then
        driver = CreateFrame("Frame")
        Stepping = ns.Guard(Step)
    end
    from, to, began = Core.Plain(UIParent:GetAlpha()) or base, target, GetTime()
    driver:SetScript("OnUpdate", Stepping)
end

function Quiet.On()
    if not ns.options.quiet or InCombatLockdown() then return end
    if not lend then
        base = Core.Plain(UIParent:GetAlpha()) or 1
        lend = Core.Lend(UIParent)
    end
    Keep(KEPT, true)
    Fade(0)
end

function Quiet.Off(now)
    if not lend then return end
    if now then return Done() end
    Fade(base)
end

-- While a part of the talk shows a tooltip (its OnEnter, before the tooltip is filled; its OnLeave).
function Quiet.Tips(on)
    if on and not lend then return end
    Keep(TIPS, on)
end

function Quiet.GiveBack()
    Done()
end
