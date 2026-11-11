local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Kit
--  Small things every module needs and none should write again: the game's
--  own words, colours as hex, the screen's pixels, a tooltip on a region, a
--  pool of parts, the game's dialogs for a question or a name, a font at a
--  size, a sound, and a frame of the game's lent to us for a while.
--
--      Core.Word("CLOSE", "Close")          -- the game's string of that name, or ours
--      Core.RGB("26262B") -> r, g, b        -- nil for one that cannot be read; Core.Hex(r, g, b)
--      Core.Pixels(frame, 2)                -- two of the screen's pixels in the frame's units
--      Core.Tip(region, title, text, anchor) -- its tooltip (title and text may be functions)
--      Core.ShowTip(owner, title, text, anchor), Core.HideTip()
--      Core.Unconfirmed(tooltip)            -- the line under a fact the game has not confirmed (Core.UNCONFIRMED);
--                                           -- Core.UNCONFIRMED_MARK before each such thing's name in a tooltip
--      Core.TipLook(tooltip, look)          -- a creature that is no unit of the game's, drawn like one (below);
--      Core.TipSection(tooltip, words)      -- a line that heads a section of it; Core.LookOf(tooltip)
--      local pool = Core.Pool(make)         -- pool:Take() a part, made by make() when none is free;
--                                           -- pool:Begin() a new round, pool:Done() hides the rest
--      Core.Confirm(text, arg, yes)         -- the game's yes/no dialog (GENERIC_CONFIRMATION)
--      Core.AskText(text, arg, accept, typed, done, letters)  -- a name typed (GENERIC_INPUT_BOX)
--      Core.Font(name, base, size, flags)   -- a font of ours: base's file (the game's), our size
--      Core.Sound(kit)                      -- one of the game's sounds (a SOUNDKIT name or number)
--      Core.Caret(box, on)                  -- a blinking cursor of ours in an edit box (below)
--      local lent = Core.Lend(frame)        -- a frame of the game's, changed for a while (below)
-------------------------------------------------------------------------------

-- How far below the screen's top what tells something over the world stands: where the game's own toast stands. The
-- toast of a new level (Inventory, right of the middle) and the travel overlay (Navigation) keep this height.
Core.TOAST_TOP = 190

-- What tells something at that height for a while (Core.TellsAtTop(frame), each once): while one of them shows,
-- Core.TopTaken() is true and what only stands there (the guide's arrow) makes way; Core.OnTopTaken(fn): fn() whenever
-- one came or went.
local tellers, topWatchers = {}, {}
local function TopChanged()
    for _, fn in ipairs(topWatchers) do Core.Safe("toast place", fn) end
end
function Core.TellsAtTop(frame)
    tellers[#tellers + 1] = frame
    local changed = Core.Guard("toast place", TopChanged)
    frame:HookScript("OnShow", changed)
    frame:HookScript("OnHide", changed)
end
function Core.TopTaken()
    for _, frame in ipairs(tellers) do
        if frame:IsShown() then return true end
    end
    return false
end
function Core.OnTopTaken(fn)
    topWatchers[#topWatchers + 1] = fn
end

-- A word of the game's own (the name of one of its strings, in the player's language), or ours where
-- this client has none.
function Core.Word(name, fallback)
    local word = rawget(_G, name)
    return type(word) == "string" and word ~= "" and word or fallback
end

-- A colour written as six hex digits ("26262B"); nil for one that cannot be read. And back.
function Core.RGB(hex)
    local r, g, b = tostring(hex):match("^(%x%x)(%x%x)(%x%x)$")
    if not r then return nil end
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

function Core.Hex(r, g, b)
    local function Byte(value) return math.floor(math.min(math.max(tonumber(value) or 0, 0), 1) * 255 + 0.5) end
    return ("%02X%02X%02X"):format(Byte(r), Byte(g), Byte(b))
end

-- So many of the screen's own pixels in a frame's units, sharp at every UI scale: the game's PixelUtil
-- rounds to whole pixels; without it the screen is 768 units high at scale 1.
function Core.Pixels(frame, count)
    count = count or 1
    local scale = Core.Plain(frame:GetEffectiveScale())
    if not scale or scale <= 0 then return count end
    local util = rawget(_G, "PixelUtil")
    if util and util.GetNearestPixelSize then return util.GetNearestPixelSize(count, scale, count) end
    local _, pixels = Core.Ask(rawget(_G, "GetPhysicalScreenSize"))
    if not pixels or pixels <= 0 then return count end
    return count * 768 / pixels / scale
end

-------------------------------------------------------------------------------
--  Tooltips
-------------------------------------------------------------------------------
local function Value(value)
    if type(value) == "function" then return value() end
    return value
end

-- The game's tooltip at owner: the title, then the text in white, wrapped. title and text may be
-- functions, asked at each showing.
function Core.ShowTip(owner, title, text, anchor)
    local tip = rawget(_G, "GameTooltip")
    if not tip then return end
    title, text = Value(title), Value(text)
    if not title and not text then return end
    tip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    tip:SetText(title or text, 1, 0.82, 0)
    if title and text then tip:AddLine(text, 1, 1, 1, true) end
    tip:Show()
end

function Core.HideTip()
    local tip = rawget(_G, "GameTooltip")
    if tip then tip:Hide() end
end

-- A region with that tooltip while the mouse is on it. Its own OnEnter and OnLeave stay: these come after.
-- The line a tooltip ends with where what it shows is not yet confirmed by the game (imported, the older game's):
-- the words between two red marks (the game's red), in the game's grey. Sane UI's tooltips (the module Tooltips)
-- know it by its words and draw it as a quiet grey note at the panel's bottom, the marks red.
Core.UNCONFIRMED_WORDS = "Unconfirmed Data"
do
    local red = rawget(_G, "RED_FONT_COLOR")
    local hex = type(red) == "table" and type(red.r) == "number" and Core.Hex(red.r, red.g, red.b) or "FF2020"
    Core.UNCONFIRMED = ("|cff%s!|r  %s  |cff%s!|r"):format(hex, Core.UNCONFIRMED_WORDS, hex)
    -- Before the name of each thing a tooltip lists that is not yet confirmed (a boss's item, a quest), so the red ! of
    -- the line Unconfirmed Data says which (Saneroki, 2026-10-23)
    Core.UNCONFIRMED_MARK = ("|cff%s!|r "):format(hex)
end

function Core.Unconfirmed(tooltip)
    tooltip:AddLine(Core.UNCONFIRMED, 0.5, 0.5, 0.5)
end

-- A tooltip about a creature that is no unit of the game's (a boss on a dungeon's map): its look, which Sane UI's
-- tooltips (the module Tooltips) draw like a unit's: { display (its 3D model: the game's creature display), or
-- creature (its model by the NPC's ID: a rare on the map), dragon ("boss", "elite", "silver": round its portrait),
-- badge (its level: "??" for a boss) }. Its lines are written into
-- the tooltip as ever: the name, then under it its title and what it is, then its sections, each headed by a line of
-- Core.TipSection; the game's own tooltip shows them as they are. Kept until the tooltip is cleared (its next
-- SetOwner); set it right after SetOwner.
local looks = setmetatable({}, { __mode = "k" })  -- [tooltip] = its look
local watched = setmetatable({}, { __mode = "k" }) -- [tooltip] = true: its clearing lets go of its look

function Core.TipLook(tooltip, look)
    if not watched[tooltip] then
        watched[tooltip] = true
        tooltip:HookScript("OnTooltipCleared", Core.Guard("tooltip", function(self) looks[self] = nil end))
    end
    looks[tooltip] = look
end

function Core.LookOf(tooltip)
    return looks[tooltip]
end

-- A line in the game's gold that heads a section of a tooltip with a look (its words in the section's divider).
function Core.TipSection(tooltip, words)
    tooltip:AddLine(words, 1, 0.82, 0)
    local look, at = looks[tooltip], Core.Plain(tooltip:NumLines())
    if look and type(at) == "number" then
        look.sections = look.sections or {}
        look.sections[at] = true
    end
end

function Core.Tip(region, title, text, anchor)
    if region.EnableMouse and not region:IsMouseEnabled() and region.SetMouseMotionEnabled then
        region:SetMouseMotionEnabled(true)
    end
    region:HookScript("OnEnter", Core.Guard("tooltip", function(self) Core.ShowTip(self, title, text, anchor) end))
    region:HookScript("OnLeave", Core.Guard("tooltip", Core.HideTip))
end

-------------------------------------------------------------------------------
--  A pool of parts: made when first needed, used again
-------------------------------------------------------------------------------
local pools = {}

-- A new round: what is taken from now on counts for it.
function pools:Begin()
    self.taken = 0
end

-- The next part of this round; made by make(pool, index) when the pool has no more.
function pools:Take()
    local index = self.taken + 1
    self.taken = index
    local part = self[index]
    if not part then
        part = self.make(self, index)
        self[index] = part
    end
    return part
end

-- The round is over: the parts not taken in it are hidden, those taken stay as they are.
function pools:Done()
    for index = self.taken + 1, #self do
        if self[index].Hide then self[index]:Hide() end
    end
end

-- Every part hidden and the round begun anew.
function pools:Reset()
    self:Begin()
    self:Done()
end

function Core.Pool(make)
    return setmetatable({ make = make, taken = 0 }, { __index = pools })
end

-------------------------------------------------------------------------------
--  The game's dialogs for addons, never a dialog of ours in its list
-------------------------------------------------------------------------------
-- One of the game's dialogs with our data; nil (noted) where the client has it no more.
local function Dialog(which, data)
    local dialogs = rawget(_G, "StaticPopupDialogs")
    if not (type(dialogs) == "table" and dialogs[which] and rawget(_G, "StaticPopup_Show")) then
        Core.Report("dialog", "the game's dialog " .. which .. " is missing")
        return nil
    end
    return StaticPopup_Show(which, nil, nil, data)
end

-- Asks yes or no. text may name arg (%s); yes() runs on yes, in Core.Safe. alert: the game's warning sign;
-- accept: the word on the yes button (the game's Yes without).
function Core.Confirm(text, arg, yes, alert, accept)
    return Dialog("GENERIC_CONFIRMATION", { text = text, text_arg1 = arg, showAlert = alert and true or nil,
        acceptText = accept, callback = function() Core.Safe("dialog", yes) end })
end

-- Asks for a name or a line. text may name arg (%s); accept: the button's word; typed: filled in and
-- marked; done(text) once accepted, in Core.Safe; letters: the most that can be typed.
function Core.AskText(text, arg, accept, typed, done, letters)
    local dialog = Dialog("GENERIC_INPUT_BOX", { text = text, text_arg1 = arg, acceptText = accept, maxLetters = letters,
        callback = function(value) Core.Safe("dialog", done, value) end })
    local box = dialog and dialog.GetEditBox and dialog:GetEditBox()
    if box and typed then
        box:SetText(typed)
        box:HighlightText()
    end
    return dialog
end

-------------------------------------------------------------------------------
--  Fonts and sounds
-------------------------------------------------------------------------------
local fonts = {}

-- A font object of ours called name, with the file and flags of the game's font base (its language's
-- letters) at our size. Made once; asked again it takes the new size. nil where base is missing.
function Core.Font(name, base, size, flags)
    local source = type(base) == "string" and rawget(_G, base) or base
    if not (source and source.GetFont) then return nil end
    local font = fonts[name]
    if not font then
        font = CreateFont(name)
        font:CopyFontObject(source)
        fonts[name] = font
    end
    local file, own, kept = source:GetFont()
    font:SetFont(file, size or own, flags or kept)
    return font
end

-- One of the game's sounds, by its SOUNDKIT name or number; nothing where the client lacks it.
function Core.Sound(kit)
    local kits = rawget(_G, "SOUNDKIT")
    local id = type(kit) == "string" and kits and kits[kit] or kit
    if type(id) == "number" and rawget(_G, "PlaySound") then pcall(PlaySound, id) end
end

-------------------------------------------------------------------------------
--  A cursor of ours in an edit box
-------------------------------------------------------------------------------
-- The game's own blinking cursor does not show in every edit box, and nothing tells when it does not.
-- Core.Caret(box) puts a bar where the game says its cursor stands (OnCursorChanged, counted from inside the
-- box's insets), as high as a line, in the text's colour, while the box has the keyboard. It blinks at the
-- game's speed and stays lit while keys move it. A frame of its own on the box, nothing written into the box, so
-- the game's edit boxes can have one. Asked again, it stands anew (the insets changed); Core.Caret(box, false):
-- no bar, until it is asked for again. For a box whose text starts at the left.
local CARET_WIDTH, CARET_SPEED = 2, 0.5 -- the bar's width; seconds lit and dark where the game names no speed
local carets = {}                       -- [edit box] = its bar

-- The bar where the cursor stands, or gone: not wanted, no keyboard, or a place the game keeps hidden.
local function Stand(bar)
    local box = bar.box
    local left, right, top, bottom = box:GetTextInsets()
    left, right, top, bottom = Core.Plain(left), Core.Plain(right), Core.Plain(top), Core.Plain(bottom)
    local empty = Core.Plain(box:GetText()) == "" -- opened empty, the game may tell nothing
    local x, y = empty and 0 or bar.x, empty and 0 or bar.y
    if not (bar.on and box:HasFocus() and left and right and top and bottom and x and y) then
        bar:Hide()
        return
    end
    local room = (Core.Plain(box:GetWidth()) or 0) - left - right
    if room > 0 then x = math.min(x, room) end
    bar:ClearAllPoints()
    if box:IsMultiLine() then
        bar:SetPoint("TOPLEFT", box, "TOPLEFT", left + x, y - top)
    else -- one line stands in the middle of the box
        bar:SetPoint("LEFT", box, "LEFT", left + x, (bottom - top) / 2)
    end
    local _, size = box:GetFont()
    bar:SetSize(CARET_WIDTH, bar.height or Core.Plain(size) or 14)
    bar.fill:SetColorTexture(box:GetTextColor())
    bar:Show()
end

local function Light(bar)
    bar.since = 0
    bar.fill:Show()
end

local Blink = Core.Guard("cursor", function(bar, elapsed)
    bar.since = bar.since + elapsed
    if bar.since < bar.speed then return end
    bar.since = 0
    bar.fill:SetShown(not bar.fill:IsShown())
end)

-- The game tells this for its layout too, with the cursor where it was: only a move lights the bar.
local Moved = Core.Guard("cursor", function(box, x, y, _, height)
    local bar = carets[box]
    x, y = Core.Plain(x), Core.Plain(y)
    if x ~= bar.x or y ~= bar.y then Light(bar) end
    bar.x, bar.y = x, y
    height = Core.Plain(height)
    if height and height > 0 then bar.height = height end
    Stand(bar)
end)

local Focus = Core.Guard("cursor", function(box)
    local bar = carets[box]
    Light(bar)
    Stand(bar)
end)

function Core.Caret(box, on)
    local bar = carets[box]
    if not bar then
        bar = CreateFrame("Frame", nil, box)
        bar.box, bar.x, bar.y = box, 0, 0
        bar.fill = bar:CreateTexture(nil, "OVERLAY")
        bar.fill:SetAllPoints()
        local speed = Core.Plain(box:GetBlinkSpeed())
        bar.speed = speed and speed > 0 and speed or CARET_SPEED
        bar:SetScript("OnUpdate", Blink)
        Light(bar)
        carets[box] = bar
        box:HookScript("OnCursorChanged", Moved)
        box:HookScript("OnEditFocusGained", Focus)
        box:HookScript("OnEditFocusLost", Focus)
    end
    bar.on = on ~= false
    Stand(bar)
end

-------------------------------------------------------------------------------
--  A frame of the game's, lent to us for a while
-------------------------------------------------------------------------------
--  What a module changes on a frame of the game's (the chat's edit box seated in our window, a
--  tooltip made clear), each thing noted the first time it is changed, so Return puts back exactly
--  what was there. Nothing is written into the frame: the notes are ours.
--      lent:SetParent(parent)   lent:SetPoints(fn)  (fn(frame) sets its anchors)
--      lent:SetLayer(strata, level)   lent:SetAlpha(alpha)   lent:SetScale(scale)
--      lent:SetMouse(on)   lent:SetShown(on)
--      lent:SetDeaf(events)  -- it no longer hears those events (a bar the game shows and lays out itself)
--      lent:Lent()     -- whether anything is changed now
--      lent:Return()   -- each thing back, each on its own (one that fails does not keep the
--                      -- others); the parent only if it is still the one we gave (the game may have
--                      -- taken it since). Raises the first failure once all are back.
--      Core.Lent(frame) -- whether a frame of the game's is lent now, to any module (so another
--                      -- leaves it alone meanwhile: Abilities does not place a spellbook Combat holds)
--  A protected frame in a fight is not changed (each Set but SetAlpha returns false) and is given back
--  once the fight is over; its alpha (the game allows that in a fight) at once.
local lends = {}
local lending = setmetatable({}, { __mode = "k" }) -- [frame] = the lend that has changed it now

local function Note(self, what, ...)
    if self.notes[what] then return end
    self.notes[what] = { ... }
    self.order[#self.order + 1] = what
    lending[self.frame] = self
end

function Core.Lent(frame)
    return lending[frame] ~= nil
end

local function Free(self)
    if Core.Locked(self.frame) then return false end
    return true
end

function lends:SetParent(parent)
    if not Free(self) then return false end
    Note(self, "parent", self.frame:GetParent())
    self.frame:SetParent(parent)
    self.parent = parent
    return true
end

function lends:SetPoints(fn)
    if not Free(self) then return false end
    Note(self, "points", Core.Points(self.frame))
    fn(self.frame)
    return true
end

function lends:SetLayer(strata, level)
    if not Free(self) then return false end
    Note(self, "layer", self.frame:GetFrameStrata(), self.frame:GetFrameLevel())
    if strata then self.frame:SetFrameStrata(strata) end
    if level then self.frame:SetFrameLevel(level) end
    return true
end

function lends:SetAlpha(alpha)
    Note(self, "alpha", self.frame:GetAlpha())
    self.frame:SetAlpha(alpha)
    return true
end

function lends:SetScale(scale)
    if not Free(self) then return false end
    Note(self, "scale", self.frame:GetScale())
    self.frame:SetScale(scale)
    return true
end

function lends:SetMouse(on)
    if not Free(self) then return false end
    Note(self, "mouse", self.frame:IsMouseEnabled())
    self.frame:EnableMouse(on)
    return true
end

-- The mouse moving over it alone (the game's health bars take no click, but hold the mouse off the world).
function lends:SetMotion(on)
    if not Free(self) then return false end
    Note(self, "motion", self.frame:IsMouseMotionEnabled())
    self.frame:SetMouseMotionEnabled(on)
    return true
end

function lends:SetShown(on)
    if not Free(self) then return false end
    Note(self, "shown", self.frame:IsShown())
    self.frame:SetShown(on)
    return true
end

-- Deaf to those events (those it hears now, noted with their units): the game's own code never runs and nothing of
-- it is written, so a frame the game shows and lays out itself stays out of sight, in a fight too.
function lends:SetDeaf(events)
    if not Free(self) then return false end
    local heard = {}
    for _, event in ipairs(events) do
        local on, unit, other = self.frame:IsEventRegistered(event)
        if on then
            heard[#heard + 1] = { event, unit, other }
            self.frame:UnregisterEvent(event)
        end
    end
    Note(self, "heard", heard)
    return true
end

function lends:Lent()
    return #self.order > 0
end

local PUT = {
    parent = function(self, parent)
        if self.frame:GetParent() == self.parent then self.frame:SetParent(parent) end
    end,
    points = function(self, points) Core.Repoint(self.frame, points) end,
    layer = function(self, strata, level)
        self.frame:SetFrameStrata(strata)
        self.frame:SetFrameLevel(level)
    end,
    alpha = function(self, alpha) self.frame:SetAlpha(alpha) end,
    scale = function(self, scale) self.frame:SetScale(scale) end,
    mouse = function(self, on) self.frame:EnableMouse(on) end,
    motion = function(self, on) self.frame:SetMouseMotionEnabled(on) end,
    shown = function(self, on) self.frame:SetShown(on) end,
    heard = function(self, heard)
        for _, note in ipairs(heard) do
            if note[2] then
                self.frame:RegisterUnitEvent(note[1], note[2], note[3])
            else
                self.frame:RegisterEvent(note[1])
            end
        end
    end,
}

-- Puts back in the reverse order of the changes: the parent first given is the last taken back.
function lends:Return()
    if Core.Locked(self.frame) then
        -- The alpha may change in a fight: a frame given back is seen at once; the rest after the fight.
        local alpha = self.notes.alpha
        if alpha then
            self.frame:SetAlpha(alpha[1])
            self.notes.alpha = nil
            for index, what in ipairs(self.order) do
                if what == "alpha" then table.remove(self.order, index) break end
            end
        end
        Core.AfterCombat(self, self.Return, self)
        return false
    end
    local first
    for index = #self.order, 1, -1 do
        local what = self.order[index]
        local note = self.notes[what]
        local ok, problem = pcall(PUT[what], self, unpack(note, 1, 2))
        if not ok and not first then first = problem end
    end
    wipe(self.notes)
    wipe(self.order)
    self.parent = nil
    if lending[self.frame] == self then lending[self.frame] = nil end
    if first then error(first, 0) end
    return true
end

function Core.Lend(frame)
    return setmetatable({ frame = frame, notes = {}, order = {} }, { __index = lends })
end
