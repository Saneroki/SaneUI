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
--      local pool = Core.Pool(make)         -- pool:Take() a part, made by make() when none is free;
--                                           -- pool:Begin() a new round, pool:Done() hides the rest
--      Core.Confirm(text, arg, yes)         -- the game's yes/no dialog (GENERIC_CONFIRMATION)
--      Core.AskText(text, arg, accept, typed, done, letters)  -- a name typed (GENERIC_INPUT_BOX)
--      Core.Font(name, base, size, flags)   -- a font of ours: base's file (the game's), our size
--      Core.Sound(kit)                      -- one of the game's sounds (a SOUNDKIT name or number)
--      local lent = Core.Lend(frame)        -- a frame of the game's, changed for a while (below)
-------------------------------------------------------------------------------

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
function Core.Tip(region, title, text, anchor)
    if region.EnableMouse and not region:IsMouseEnabled() and region.SetMouseMotionEnabled then
        region:SetMouseMotionEnabled(true)
    end
    region:HookScript("OnEnter", function(self) Core.ShowTip(self, title, text, anchor) end)
    region:HookScript("OnLeave", Core.HideTip)
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

-- Asks yes or no. text may name arg (%s); yes() runs on yes, in Core.Safe. alert: the game's warning sign.
function Core.Confirm(text, arg, yes, alert)
    return Dialog("GENERIC_CONFIRMATION", { text = text, text_arg1 = arg, showAlert = alert and true or nil,
        callback = function() Core.Safe("dialog", yes) end })
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
--  A frame of the game's, lent to us for a while
-------------------------------------------------------------------------------
--  What a module changes on a frame of the game's (the chat's edit box seated in our window, a
--  tooltip made clear), each thing noted the first time it is changed, so Return puts back exactly
--  what was there. Nothing is written into the frame: the notes are ours.
--      lent:SetParent(parent)   lent:SetPoints(fn)  (fn(frame) sets its anchors)
--      lent:SetLayer(strata, level)   lent:SetAlpha(alpha)   lent:SetScale(scale)
--      lent:SetMouse(on)   lent:SetShown(on)
--      lent:Lent()     -- whether anything is changed now
--      lent:Return()   -- each thing back, each on its own (one that fails does not keep the
--                      -- others); the parent only if it is still the one we gave (the game may have
--                      -- taken it since). Raises the first failure once all are back.
--  A protected frame in a fight is not changed (each Set returns false) and is given back once the
--  fight is over.
local lends = {}

local function Note(self, what, ...)
    if self.notes[what] then return end
    self.notes[what] = { ... }
    self.order[#self.order + 1] = what
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

function lends:SetShown(on)
    if not Free(self) then return false end
    Note(self, "shown", self.frame:IsShown())
    self.frame:SetShown(on)
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
    shown = function(self, on) self.frame:SetShown(on) end,
}

-- Puts back in the reverse order of the changes: the parent first given is the last taken back.
function lends:Return()
    if Core.Locked(self.frame) then
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
    if first then error(first, 0) end
    return true
end

function Core.Lend(frame)
    return setmetatable({ frame = frame, notes = {}, order = {} }, { __index = lends })
end
