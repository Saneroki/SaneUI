local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Scan bar
--  The full scan on the game's auction house window: a bar under its bottom right corner, beside the
--  window's tabs, that says the scan started, how far it is, that it finished, and when the next one comes.
--  It fills as the rows are read and then runs down to the next scan; pressed, it starts one now. At its right
--  end the game's own stopwatch buttons pause the scans and resume them (the pause kept for the account until
--  the player resumes, Scan.Pause), and the game's X cancels the scan underway, shown while one runs. Ours and
--  anchored to the game's window, nothing of the game's is written (Doc/guides/gui-development.md, *Changing
--  a Blizzard window*); made when the window is first there, shown while it is.
-------------------------------------------------------------------------------
local Scan = Core.Data.Scan

local WIDTH, HEIGHT = 440, 18
local RIGHT, BELOW = -8, -4 -- from the window's bottom right corner
local BUTTON = 22           -- the stopwatch's buttons, their art a little inside its square
local CLOSE = 18            -- the game's X, its art the whole square: as high as the bar
local PAUSE = "Interface\\TimeManager\\PauseButton"                 -- the game's stopwatch: pause
local GO = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"       -- and play
local LIGHT = "Interface\\Buttons\\UI-Common-MouseHilight"          -- its light under the mouse

local TEXT = {
    asking = "Full scan started, waiting for the server",
    reading = "Full scan: %s of %s auctions",
    kept = "Full scan finished at %s: %s auctions. Next in %s",
    refused = "The server gave no full scan. Next try in %s",
    lost = "The full scan was cut short. Next in %s",
    cancelled = "The full scan was cancelled. Next in %s",
    waiting = "Next full scan in %s",
    pausedAsking = "Full scan paused, waiting for the server",
    pausedReading = "Full scan paused: %s of %s auctions",
    paused = "Full scans paused",
    pausedKept = "Full scans paused. The last finished at %s: %s auctions",
    tip = "Full scan",
    start = "Click to scan the whole auction house now. The server allows one scan in 15 minutes.",
    resumeNow = "Full scans are paused on this account. Click to resume and scan now.",
    busy = "A full scan is running.",
    busyPaused = "This full scan is paused: resume it with the button on the right, or cancel it with the X.",
    pause = "Pause",
    pauseTip = "Pause the full scans: the one running waits where it is, and no new one starts. They stay paused on "
        .. "this account, after a logout too, until you resume. A scan paused halfway is lost when the auction house closes.",
    resume = "Resume",
    resumeTip = "Resume the full scans: a paused scan reads on from where it stopped, the next one comes at its time.",
    cancel = "Cancel",
    cancelTip = "Cancel this full scan: nothing of it is kept. The next one comes at its time.",
}

local strip, bar, label, light, hold, cancel

local function Number(amount)
    return Core.Ask(rawget(_G, "BreakUpLargeNumbers"), amount or 0) or tostring(amount or 0)
end

local function Left(seconds)
    seconds = math.max(math.ceil(seconds), 0)
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

local function Press()
    if Scan.Start() then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
end

local function Tip()
    local state = Scan.State()
    if state.phase ~= "waiting" then return state.paused and TEXT.busyPaused or TEXT.busy end
    return state.paused and TEXT.resumeNow or TEXT.start
end

-- The stopwatch's button: pause while the scans go, play while they are paused.
local function Hold()
    if Scan.Pause(not Scan.State().paused) then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON") end
end

local function Cancel()
    if Scan.Cancel() then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF") end
end

local function HoldTitle()
    return Scan.State().paused and TEXT.resume or TEXT.pause
end

local function HoldTip()
    return Scan.State().paused and TEXT.resumeTip or TEXT.pauseTip
end

local function Make(window)
    strip = CreateFrame("Button", nil, UIParent)
    strip:RegisterForClicks("LeftButtonUp")
    strip:SetScript("OnClick", Core.Guard("data: auction scan", Press))
    strip:SetSize(WIDTH, HEIGHT)
    strip:SetPoint("TOPRIGHT", window, "BOTTOMRIGHT", RIGHT, BELOW)
    strip:SetFrameStrata(window:GetFrameStrata())
    bar = Core.Bar.New(strip, { width = WIDTH, height = HEIGHT, segments = 1 })
    bar.frame:SetAllPoints(strip)
    local over = CreateFrame("Frame", nil, strip) -- above the bar's fill and its flare
    over:SetAllPoints(strip)
    over:SetFrameLevel(bar.frame:GetFrameLevel() + 5)
    -- The X at the right end, the pause beside it (Draw moves it to the end while the X is hidden).
    cancel = CreateFrame("Button", nil, strip, "UIPanelCloseButtonNoScripts")
    cancel:SetSize(CLOSE, CLOSE)
    cancel:SetPoint("RIGHT", strip, "RIGHT", -1, 0)
    cancel:SetFrameLevel(over:GetFrameLevel() + 1)
    cancel:SetScript("OnClick", Core.Guard("data: auction scan", Cancel))
    Core.Tip(cancel, TEXT.cancel, TEXT.cancelTip, "ANCHOR_TOP")
    hold = CreateFrame("Button", nil, strip)
    hold:SetSize(BUTTON, BUTTON)
    hold:SetFrameLevel(over:GetFrameLevel() + 1)
    hold:SetHighlightTexture(LIGHT, "ADD")
    hold:SetScript("OnClick", Core.Guard("data: auction scan", Hold))
    Core.Tip(hold, HoldTitle, HoldTip, "ANCHOR_TOP")
    label = over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", strip, "LEFT", 4, 0)
    label:SetPoint("RIGHT", hold, "LEFT", -2, 0)
    light = over:CreateTexture(nil, "ARTWORK")
    light:SetAllPoints(over)
    light:SetColorTexture(1, 1, 1, 0.1)
    light:Hide()
    strip:SetScript("OnEnter", Core.Guard("data: auction scan", function() light:Show() end))
    strip:SetScript("OnLeave", Core.Guard("data: auction scan", function() light:Hide() end))
    Core.Tip(strip, TEXT.tip, Tip, "ANCHOR_TOP")
end

-- The buttons as the state stands: pause or play; the X only while a scan runs, the pause in its place without it.
-- Changed only when it changes: Draw runs twice a second.
local function Buttons(state)
    local art, running = state.paused and GO or PAUSE, state.phase == "asking" or state.phase == "reading"
    if hold.art ~= art then
        hold.art = art
        hold:SetNormalTexture(art)
    end
    if hold.running == running then return end
    hold.running = running
    cancel:SetShown(running)
    hold:ClearAllPoints()
    if running then
        hold:SetPoint("RIGHT", cancel, "LEFT", 0, 0)
    else
        hold:SetPoint("RIGHT", strip, "RIGHT", 1, 0)
    end
end

local function Waiting(state)
    if state.paused then
        bar:SetValue(0, 1)
        if not state.kept then return TEXT.paused end
        return TEXT.pausedKept:format(Core.ClockAt(state.kept), Number(state.total))
    end
    local left = state.next - (Core.Ask(rawget(_G, "GetServerTime")) or 0)
    bar:SetValue(math.max(left, 0), state.span)
    if state.outcome == "kept" and state.kept then
        return TEXT.kept:format(Core.ClockAt(state.kept), Number(state.total), Left(left))
    end
    return (state.outcome ~= "kept" and TEXT[state.outcome] or TEXT.waiting):format(Left(left))
end

local function Draw(state)
    if state.phase == "closed" then
        if strip then strip:Hide() end
        return
    end
    local window = rawget(_G, "AuctionHouseFrame") -- the game loads it when the auction house first opens
    if not window then return end
    if not strip then Make(window) end
    strip:SetShown(window:IsShown())
    Buttons(state)
    if state.phase == "asking" then
        bar:SetValue(0, 1, 1) -- all of it still to come
        label:SetText(state.paused and TEXT.pausedAsking or TEXT.asking)
    elseif state.phase == "reading" then
        bar:SetValue(state.read, state.rows)
        label:SetText((state.paused and TEXT.pausedReading or TEXT.reading):format(Number(state.read), Number(state.rows)))
    else
        label:SetText(Waiting(state))
    end
end

Scan.OnChange(Draw)
