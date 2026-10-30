local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Cast
--  Your cast as part of your frame, in place of the game's cast bar: while you
--  cast, one more bar in the frame's stack, inside its one outline (Bar.Fit),
--  under your powers and your pet's row: the spell's icon square at its left
--  end, its name right of it, the seconds left at its right end, where the
--  frame's other bars have their numbers. Filling as a cast goes on, emptying
--  as a channel does, in the game's own cast bar art, as a nameplate's cast
--  bar. An empowered cast (Retail's) fills on to the hold at its last stage,
--  a thin line where each stage ends. Interrupted, the bar is full in the
--  art's red and says so, and by whom where the game names them; done or
--  interrupted, it stays Cast.HOLD seconds before it goes, so the outline
--  does not jump between two casts. A cast that fails goes at once.
--
--  What the game says of the cast (UnitCastingInfo, UnitChannelInfo) is read
--  when it starts and changes (your UNIT_SPELLCAST_* events, on the bar
--  itself). The game may hide any of it from addons (secret values); the bar
--  takes them as they are, as a nameplate's: its fill runs from the cast's
--  start to its end and is given the time now on its own OnUpdate, so the game
--  draws the progress whether we may read it or not. The seconds left need
--  the end itself: where it is hidden they come from the spell's cast time.
--
--  The game's own cast bars hear none of it while this one is on (Cast.GAME,
--  Units.lua: Core.Lend's SetDeaf): PlayerCastingBarFrame, and the overlay
--  that stands in for it over the vehicle bar and the game's talents window.
--  Hiding them would run their OnHide in our code, into the game's layout of
--  the bottom of the screen; so they never start.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Cast = {}
ns.UnitCast = Cast

-- The game's own cast bar art (its atlases): a cast, a channel, one that was interrupted.
Cast.ART = { cast = "ui-castingbar-filling-standard", channel = "ui-castingbar-filling-channel",
             broken = "ui-castingbar-interrupted" }
Cast.HOLD = 0.5      -- seconds a cast stays after it was done or interrupted
Cast.WAIT = 1        -- seconds past a reckoned end before a cast counts as done without the game's word
Cast.GAP = 3         -- between the icon, the name and the seconds
Cast.SAMPLE = 0.6    -- how full the sample is in Edit Mode
Cast.ICON = "Interface\\Icons\\INV_Misc_QuestionMark" -- the sample's
Cast.INTERRUPTED = Core.Word("INTERRUPTED", "Interrupted")
Cast.BY = Core.Word("SPELL_INTERRUPTED_BY", "Interrupted by %s")
-- Your cast's events; each reads the cast anew.
Cast.EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
                "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
                "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE",
                "UNIT_SPELLCAST_EMPOWER_STOP" }
-- What the game's cast bars hear (CastingBarMixin:SetUnit): those, and what they hear besides.
Cast.GAME = { "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD" }
for _, event in ipairs(Cast.EVENTS) do Cast.GAME[#Cast.GAME + 1] = event end

-- A status bar's fill in a piece of the game's cast bar art (given to the bar, which crops it as it fills, as the
-- game's own cast bar does), or in plain dark.
local function Fills(bar, atlas)
    if atlas then
        bar:SetStatusBarTexture(atlas)
        bar:SetStatusBarColor(1, 1, 1)
    else
        local dark = ns.UnitBar.BACKGROUND
        bar:SetStatusBarTexture(ns.UnitBar.WHITE)
        bar:SetStatusBarColor(dark[1], dark[2], dark[3])
    end
end

-- A texture behind a fill in a piece of the game's cast bar art, or in plain dark.
local function Art(texture, atlas)
    if atlas then
        texture:SetAtlas(atlas)
        texture:SetVertexColor(1, 1, 1, 1)
    else
        local dark = ns.UnitBar.BACKGROUND
        texture:SetTexture(ns.UnitBar.WHITE)
        texture:SetVertexColor(dark[1], dark[2], dark[3], dark[4])
    end
end

-- The bar's art for the cast on it: a cast fills in the game's golden art; a channel empties (the channel's art
-- behind, the dark filling from its end).
local function Paint(bar)
    local cast = bar.cast
    bar.fill:SetReverseFill(cast.channel)
    bar.fill:SetMinMaxValues(cast.starts, cast.ends)
    if cast.channel then
        Fills(bar.fill, nil)
        Art(bar.fill.background, Cast.ART.channel)
    else
        Fills(bar.fill, Cast.ART.cast)
        Art(bar.fill.background, nil)
    end
end

-- The thin lines where the stages of an empowered cast end, each its share of the bar along it (none for another
-- cast). After the bar is laid out: they need its width.
local function Stages(bar)
    local cast = bar.cast
    local count = cast and cast.stages or 0
    local span = count > 0 and (Plain(cast.ends) or 0) - (Plain(cast.starts) or 0) or 0
    local width = Plain(bar.fill:GetWidth()) or 0
    local sum = 0
    for index = 1, span > 0 and count or 0 do
        local line = bar.lines[index]
        if not line then
            line = bar.top:CreateTexture(nil, "ARTWORK")
            line:SetTexture(ns.UnitBar.WHITE)
            line:SetVertexColor(0, 0, 0, 1)
            bar.lines[index] = line
        end
        sum = sum + (Core.Ask(rawget(_G, "GetUnitEmpowerStageDuration"), "player", index - 1) or 0)
        line:ClearAllPoints()
        line:SetPoint("TOP", bar.fill, "TOPLEFT", width * sum / span, 0)
        line:SetPoint("BOTTOM", bar.fill, "BOTTOMLEFT", width * sum / span, 0)
        line:SetWidth(Core.Pixels(bar, 1))
        line:Show()
    end
    for index = span > 0 and count + 1 or 1, #bar.lines do bar.lines[index]:Hide() end
end

-- The bar gone from the stack.
local function Gone(bar)
    bar.cast, bar.on = nil, false
    Stages(bar)
    ns.UnitBar.Fit(bar.face)
end

-- A cast done: the bar as it ends (a cast full, a channel empty), no seconds, staying Cast.HOLD seconds.
local function Done(bar)
    local cast = bar.cast
    cast.held = GetTime() + Cast.HOLD
    bar.fill:SetValue(cast.ends)
    bar.timer:SetText("")
end

-- The seconds left of the cast on the bar, its fill; done when its end (known or reckoned) has passed.
local function Tick(bar)
    local cast = bar.cast
    if not cast then return end
    local now = GetTime()
    if cast.held then
        if now >= cast.held then Gone(bar) end
        return
    end
    bar.fill:SetValue(now * 1000)
    local ends = cast.plainEnd or cast.reckoned
    if not ends then return bar.timer:SetText("") end
    local left = ends - now
    if left <= 0 then
        -- Its end known: done; only reckoned (from the spell's cast time): wait a little for the game's word.
        if cast.plainEnd or left < -Cast.WAIT then return Done(bar) end
        return bar.timer:SetText("")
    end
    bar.timer:SetFormattedText(left < 10 and "%.1f" or "%.0f", left)
end
local OnUpdate = ns.Guard(Tick)

-- Whether the game shows your cast at all here (a rule of some of its modes takes it away).
local function Allowed()
    local rules = rawget(_G, "GameRulesUtil")
    return not (rules and Core.Ask(rules.ShouldShowPlayerCastBar) == false)
end

-- Your cast as the game says it now: { name, icon, starts, ends (milliseconds, hidden or not), channel, id (a cast's,
-- where it may be read), stages (an empowered cast's), plainEnd or reckoned (seconds) }; nil where you cast nothing.
local function Read()
    if not Allowed() then return nil end
    local channel, empowered, stages = false, false, nil
    local ok, name, _, icon, starts, ends, _, id, _, spell = pcall(UnitCastingInfo, "player")
    if not ok or type(name) == "nil" then -- looked at with type() only: a hidden name is never compared
        channel = true
        ok, name, _, icon, starts, ends, _, _, spell, empowered, stages = pcall(UnitChannelInfo, "player")
        if not ok or type(name) == "nil" then return nil end
    end
    if type(starts) == "nil" or type(ends) == "nil" then return nil end
    local cast = { name = name, icon = icon, starts = starts, ends = ends, channel = channel, id = Plain(id) }
    if empowered == true and type(stages) == "number" and stages > 0 then
        -- It fills as a cast does, on to the hold at its last stage (as the game's bar).
        cast.channel, cast.stages = false, stages
        local hold, plain = Core.Ask(rawget(_G, "GetUnitEmpowerHoldAtMaxTime"), "player"), Plain(ends)
        if type(hold) == "number" and type(plain) == "number" then cast.ends = plain + hold end
    end
    local plainEnd = Plain(cast.ends)
    if type(plainEnd) == "number" then
        cast.plainEnd = plainEnd / 1000
    elseif not channel then
        -- Its end hidden: the spell's cast time from now (or from its start where that may be read).
        local known = Plain(spell)
        local data = known and Core.Ask(C_Spell.GetSpellInfo, known)
        local length = type(data) == "table" and Plain(data.castTime)
        local began = Plain(starts)
        if type(length) == "number" and length > 0 then
            cast.reckoned = (type(began) == "number" and began / 1000 or GetTime()) + length / 1000
        end
    end
    return cast
end

-- Who interrupted a cast, by the GUID the game gives: a name, or nil.
local function Interrupter(guid)
    if type(guid) ~= "string" or guid == "" then return nil end
    local name = ns.UnitBar.Raw(rawget(_G, "UnitNameFromGUID"), guid)
    if Plain(name) == "" then return nil end
    return name
end

-- The cast on the bar was interrupted: a moment in red, saying so, then gone.
local function Broken(bar, who)
    bar.cast.held, bar.cast.stages = GetTime() + Cast.HOLD, nil
    bar.fill:SetReverseFill(false)
    Fills(bar.fill, Cast.ART.broken)
    Art(bar.fill.background, nil)
    bar.fill:SetMinMaxValues(0, 1)
    bar.fill:SetValue(1)
    bar.timer:SetText("")
    Stages(bar)
    local name = Interrupter(Plain(who))
    if type(name) == "nil" or not pcall(bar.text.SetFormattedText, bar.text, Cast.BY, name) then
        bar.text:SetText(Cast.INTERRUPTED)
    end
end

-- Your cast on the bar as the game says it now (event: what told us). Over: done it stays a moment; failed it goes at
-- once; interrupted it stays red.
local function Update(bar, event)
    if not bar.wanted or bar.sample then return end
    local cast = Read()
    if not cast then
        local old = bar.cast
        if not old or old.held then return end
        if event == "UNIT_SPELLCAST_FAILED" then return Gone(bar) end
        return Done(bar)
    end
    bar.cast = cast
    Paint(bar)
    bar.icon:SetTexture(cast.icon)
    bar.text:SetText(cast.name)
    if not bar.on then
        bar.on = true
        ns.UnitBar.Fit(bar.face)
    end
    Tick(bar)
    Stages(bar)
end

-- The game's word of a cast: an interrupted cast's, or a channel's or an empowered cast's that ended by someone's hand
-- (the event's cast, then, by event, who interrupted it or whether it was completed and who); else read anew. A
-- cast of its own number only: the game also tells of what you tried while casting.
local function Heard(bar, event, _, id, _, fourth, fifth)
    if ns.off then return end
    local cast = bar.cast
    if cast and not cast.held then
        if event == "UNIT_SPELLCAST_INTERRUPTED" and (not cast.id or Plain(id) == cast.id) then
            return Broken(bar, fourth)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" and type(fourth) ~= "nil" then
            return Broken(bar, fourth)
        elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" and Plain(fourth) == false then
            return Broken(bar, fifth)
        end
    end
    Update(bar, event)
end
local OnEvent = ns.Guard(Heard)

-- Your cast's bar in your frame's stack (hidden until it casts): as high as height, the icon as wide, the fill right
-- of it; the frame's masks for the stack's ends (Bar.Fit) over both, the left one over the icon.
function Cast.Make(face, height)
    local level = face.health:GetFrameLevel()
    local bar = CreateFrame("Frame", nil, face)
    bar:SetFrameLevel(level)
    bar:Hide()
    local fill = ns.UnitBar.Strip(bar, level)
    fill:SetValue(0)
    local top = ns.UnitText.Over(bar)
    local icon = top:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("TOPLEFT", bar, "TOPLEFT")
    icon:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    icon:SetWidth(height)
    icon:AddMaskTexture(fill.ends[1])
    fill:SetPoint("TOPLEFT", icon, "TOPRIGHT")
    fill:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    local Text = ns.UnitText
    local text, timer = Text.Line(top, "LEFT"), Text.Line(top, "RIGHT")
    timer:SetPoint("RIGHT", bar, "RIGHT", 1 - Text.INSET, 0)
    text:SetPoint("LEFT", icon, "RIGHT", Cast.GAP, 0)
    text:SetPoint("RIGHT", timer, "LEFT", -Cast.GAP, 0)
    bar.face, bar.tall, bar.ends, bar.fill = face, height, fill.ends, fill
    bar.top, bar.icon, bar.text, bar.timer, bar.lines = top, icon, text, timer, {}
    for _, event in ipairs(Cast.EVENTS) do pcall(bar.RegisterUnitEvent, bar, event, "player") end
    bar:RegisterEvent("PLAYER_ENTERING_WORLD") -- a cast seen again after a loading screen
    bar:SetScript("OnEvent", OnEvent)
    bar:SetScript("OnUpdate", OnUpdate)
    face.cast = bar
    face.under[#face.under + 1] = bar
end

-- The sample in Edit Mode: where a cast shows, and how far the frame's outline goes then.
local function Sample(bar)
    bar.sample, bar.on = true, true
    bar.fill:SetReverseFill(false)
    Fills(bar.fill, Cast.ART.cast)
    Art(bar.fill.background, nil)
    bar.fill:SetMinMaxValues(0, 1)
    bar.fill:SetValue(Cast.SAMPLE)
    bar.icon:SetTexture(Cast.ICON)
    bar.text:SetText(ns.TEXT.samples.cast)
    bar.timer:SetText("")
end

-- The bar on, as your cast is now (in Edit Mode a sample), or off.
function Cast.Set(face, on)
    local bar = face.cast
    bar.wanted, bar.sample, bar.cast, bar.on = on, nil, nil, false
    Stages(bar)
    if on and Core.EditMode.active then
        Sample(bar)
    else
        Update(bar)
    end
    ns.UnitBar.Fit(face)
end
