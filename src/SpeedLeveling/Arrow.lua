local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Arrow
--  The way to the guide's place (Saneroki, 2026-10-25): Sane UI's leather ring
--  that runs out into a point, turned the way to the place (up: ahead), in its
--  hole the game's own picture of what to do there (its cursors': a speech
--  bubble to talk, a sword to kill, a bag to loot, an open hand to use, the
--  quest's ! and ?, a coin bag to buy, a book to train, the Hearthstone, a
--  winged boot to fly, a map to just get there; Guide.Doing), and under it, in
--  Expressway, what to do there (the step's first words) and how far: the
--  yards, and the time to get there at the pace you have been closing in. Within
--  the place's reach the ring and the yards go, the words stay.
--
--  A part of its own, placed in Edit Mode apart from the guide (Core.Window), at
--  first over the middle of the screen; shown while the guide is and it has a
--  place to go to (the switch Show the arrow).
--
--      Arrow.Update(shown)   shown or not with the guide, drawn anew
--      Arrow.GiveBack()
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Arrow = {}
ns.Arrow = Arrow

Arrow.WIDTH = 240        -- the part's width: its words wrap within it
Arrow.HOLE = 30          -- the ring's hole, wide
Arrow.LOOK = 0.05        -- seconds between turns
Arrow.ASK = 0.5          -- seconds between asks of where it points
Arrow.PACE = 0.5         -- seconds between measures of the pace
Arrow.SMOOTH = 0.35      -- each measure's share of the pace
Arrow.LEAP = 50          -- yards a second: more is a new place, not your pace
Arrow.SLOW = 0.8         -- yards a second: closing in slower than this, no time is told
Arrow.RING = "Interface\\AddOns\\SaneUI_SpeedLeveling\\Art\\mark-pointed"

-- The ring's measures, as the art has them (dev/tools/mark-art, 1040 texels on 252 of 256): its hole's and its
-- leather's radius, and the point's tip from the middle, each a share of the picture's side.
local HOLE, OUTER, TIP = 0.2293 * 252 / 256, 0.2942 * 252 / 256, 510 / 1040 * 252 / 256
-- The pictures of what to do: the game's cursors, the largest of each sheet, past the corner its tip is drawn in.
local CURSOR = "Interface\\CURSOR\\"
local WIDE = { 16 / 512, 128 / 512, 16 / 256, 128 / 256 } -- a sheet 512 x 256
local PICTURES = {
    take = { CURSOR .. "UIQuestCursor2x", { 144 / 512, 256 / 512, 16 / 512, 128 / 512 } },
    handin = { CURSOR .. "UIQuestCursor2x", { 16 / 512, 128 / 512, 16 / 512, 128 / 512 } },
    talk = { CURSOR .. "UISpeakCursor2x", WIDE },
    buy = { CURSOR .. "UIBuyCursor2x", WIDE },
    train = { CURSOR .. "UITrainerCursor2x", WIDE },
    inn = { CURSOR .. "UIInnkeeperCursor2x", WIDE },
    hearth = { CURSOR .. "UIInnkeeperCursor2x", WIDE },
    fly = { CURSOR .. "UITaxiCursor2x", WIDE },
    kill = { CURSOR .. "UIAttackCursor2x", WIDE },
    loot = { CURSOR .. "UILootAllCursor2x", WIDE },
    use = { CURSOR .. "UIOpenhandCursor2x", WIDE },
    go = { CURSOR .. "UIDirectionsCursor2x", WIDE },
}
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local SOFT = { 0.8, 0.8, 0.8 }

local frame, window, holder, ring, picture, backing, words, far
local target, step  -- where it points, the step there
local pace          -- { yards, at, speed }: how fast you have been closing in

local function Font(name, size)
    local font = CreateFont(name)
    if not font:SetFont(ns.Steps.FONT, size, "OUTLINE") then
        local base = rawget(_G, "GameFontHighlight")
        local file = base and base:GetFont()
        if file then font:SetFont(file, size, "OUTLINE") end
    end
    return font
end

-- The time to get there, at the pace you have been closing in; nil while you are not.
local function Time(yards)
    local now = Core.Plain(Core.Ask(rawget(_G, "GetTime"))) or 0
    if not pace then
        pace = { yards = yards, at = now, speed = 0 }
        return nil
    end
    local passed = now - pace.at
    if passed >= Arrow.PACE then
        local speed = (pace.yards - yards) / passed
        if math.abs(speed) > Arrow.LEAP then
            pace = { yards = yards, at = now, speed = 0 }
            return nil
        end
        pace.speed = pace.speed + (speed - pace.speed) * Arrow.SMOOTH
        pace.yards, pace.at = yards, now
    end
    if pace.speed < Arrow.SLOW then return nil end
    local seconds = math.floor(yards / pace.speed + 0.5)
    if seconds < 60 then return ns.TEXT.seconds:format(seconds) end
    return ns.TEXT.minutes:format(math.floor(seconds / 60), seconds % 60)
end

-- The step's words for under the ring: what to do first (its first words, else its first thing not yet done), the
-- pictures in them dropped.
local function Words(at)
    local chosen
    for index, line in ipairs(at and at.lines or {}) do
        if index == 1 and not line.count then chosen = line.text break end
        if not line.done and not chosen then chosen = line.text end
    end
    if not chosen then return "" end
    return (chosen:gsub("|T.-|t%s*", ""):gsub("^%s+", ""))
end

-- The ring turned the way to the place, the words and the yards under it; within the place's reach only the words.
local function Turn()
    if not target then return end
    local yards, way = ns.Run.Way(target)
    local facing = Core.Plain(Core.Ask(rawget(_G, "GetPlayerFacing")))
    local near = target.near and target.near > 0 and target.near or ns.Format.FAR
    local turn = 0
    if yards and way and facing and yards > near then
        turn = way - facing
        ring:SetRotation(turn)
        ring:Show()
        picture:Show()
        backing:Show()
        local time = Time(yards)
        local text = Core.Distance(yards)
        far:SetText(time and (text .. "  \194\183  " .. time) or text)
    else
        ring:Hide()
        picture:Hide()
        backing:Hide()
        far:SetText("")
        pace = nil
    end
    -- The words under the ring, under its point while that points down.
    local whole = ring:GetWidth()
    local low = math.max(OUTER, -math.cos(turn) * TIP) * whole
    words:ClearAllPoints()
    words:SetPoint("TOP", holder, "CENTER", 0, -low - 2)
end

-- What to do there, in the ring's hole.
local function Picture()
    local doing = PICTURES[ns.Guide.Doing(step)] or PICTURES.go
    picture:SetTexture(doing[1])
    picture:SetTexCoord(unpack(doing[2]))
end

local function Build()
    frame = CreateFrame("Frame", "SaneUISpeedLevelingArrow", UIParent)
    local whole = Arrow.HOLE / (HOLE * 2)
    frame:SetSize(Arrow.WIDTH, whole + 44)
    frame:SetFrameStrata("LOW")
    holder = CreateFrame("Frame", nil, frame)
    holder:SetSize(whole, whole)
    holder:SetPoint("TOP", frame, "TOP")
    backing = holder:CreateTexture(nil, "BACKGROUND")
    backing:SetColorTexture(0, 0, 0, 0.6)
    backing:SetSize(Arrow.HOLE * 1.1, Arrow.HOLE * 1.1)
    backing:SetPoint("CENTER")
    picture = holder:CreateTexture(nil, "ARTWORK")
    picture:SetSize(Arrow.HOLE * 1.08, Arrow.HOLE * 1.08)
    picture:SetPoint("CENTER")
    for _, round in ipairs({ backing, picture }) do
        local mask = holder:CreateMaskTexture()
        mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(round)
        round:AddMaskTexture(mask)
    end
    ring = holder:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(Arrow.RING)
    ring:SetSize(whole, whole)
    ring:SetPoint("CENTER")
    words = frame:CreateFontString(nil, "OVERLAY")
    words:SetFontObject(Font("SaneUISpeedLevelingArrowWords", 12.5))
    words:SetWidth(Arrow.WIDTH)
    words:SetJustifyH("CENTER")
    words:SetMaxLines(2)
    far = frame:CreateFontString(nil, "OVERLAY")
    far:SetFontObject(Font("SaneUISpeedLevelingArrowFar", 11))
    far:SetTextColor(unpack(SOFT))
    far:SetPoint("TOP", words, "BOTTOM", 0, -2)
    -- Turned while shown, a step at a time; where it points asked less often.
    local turned, asked = 0, 0
    frame:SetScript("OnUpdate", ns.Guard(function(_, elapsed)
        turned, asked = turned + elapsed, asked + elapsed
        if asked >= Arrow.ASK then
            asked = 0
            local place, at = ns.Guide.Target()
            if not ns.Run.SamePlace(place, target) then pace = nil end
            target, step = place, at
            if not target then return Arrow.Update(true) end
            Picture()
            words:SetText(Words(step))
        end
        if turned >= Arrow.LOOK then
            turned = 0
            Turn()
        end
    end))
    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", ns.Guard(function(self, button)
        if button == "RightButton" then ns.Steps.LockMenu(self, window) end
    end))
    window = Core.Window.New(frame, { store = Core.Store(ns.name), key = "arrowPlace", title = ns.TEXT.arrowView,
                                      first = { point = "TOP", x = 0, y = -110 },
                                      unlockedMenu = function(owner) ns.Steps.LockMenu(owner, window) end })
    window:Place()
end

function Arrow.Update(shown)
    target, step = nil, nil
    if shown and not ns.off and ns.options.showArrow then target, step = ns.Guide.Target() end
    if not target then
        if frame then frame:Hide() end
        pace = nil
        return
    end
    if not frame then Build() end
    Picture()
    words:SetText(Words(step))
    frame:Show()
    Turn()
end

function Arrow.GiveBack()
    Arrow.Update(false)
end
