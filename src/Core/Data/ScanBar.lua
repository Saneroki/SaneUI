local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Scan bar
--  The full scan on the game's auction house window: a bar under its bottom right corner, beside the
--  window's tabs, that says the scan started, how far it is, that it finished, and when the next one comes.
--  It fills as the rows are read and then runs down to the next scan; pressed, it starts one now. Ours and
--  anchored to the game's window, nothing of the game's is written (Doc/guides/gui-development.md, *Changing
--  a Blizzard window*); made when the window is first there, shown while it is.
-------------------------------------------------------------------------------
local Scan = Core.Data.Scan

local WIDTH, HEIGHT = 440, 18
local RIGHT, BELOW = -8, -4 -- from the window's bottom right corner

local TEXT = {
    asking = "Full scan started, waiting for the server",
    reading = "Full scan: %s of %s auctions",
    kept = "Full scan finished at %s: %s auctions. Next in %s",
    refused = "The server gave no full scan. Next try in %s",
    lost = "The full scan was cut short. Next in %s",
    waiting = "Next full scan in %s",
    tip = "Full scan",
    start = "Click to scan the whole auction house now. The server allows one scan in 15 minutes.",
    busy = "A full scan is running.",
}

local strip, bar, label, light

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
    return Scan.State().phase == "waiting" and TEXT.start or TEXT.busy
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
    label = over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    light = over:CreateTexture(nil, "ARTWORK")
    light:SetAllPoints(over)
    light:SetColorTexture(1, 1, 1, 0.1)
    light:Hide()
    strip:SetScript("OnEnter", Core.Guard("data: auction scan", function() light:Show() end))
    strip:SetScript("OnLeave", Core.Guard("data: auction scan", function() light:Hide() end))
    Core.Tip(strip, TEXT.tip, Tip, "ANCHOR_TOP")
end

local function Waiting(state)
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
    if state.phase == "asking" then
        bar:SetValue(0, 1, 1) -- all of it still to come
        label:SetText(TEXT.asking)
    elseif state.phase == "reading" then
        bar:SetValue(state.read, state.rows)
        label:SetText(TEXT.reading:format(Number(state.read), Number(state.rows)))
    else
        label:SetText(Waiting(state))
    end
end

Scan.OnChange(Draw)
