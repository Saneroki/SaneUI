local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Seat
--  A window that is not ours (the game's spellbook, the window of an addon Sane
--  UI knows: Neighbours.lua) seated in a room of the screen while one of our
--  windows stands full there: in the room's middle, as large as fits and never
--  larger than it is itself. Only its place, scale and layer are lent
--  (Core.Lend) and given back exactly. Its parent stays its own, so our code
--  never shows or hides it: its OnShow and OnHide run from its own code only,
--  and it works as always.
--
--  Followed while seated: the game (or its addon) places or scales it anew (the
--  game's panels make room for each other, a window scaled to fit the screen):
--  hooks after its SetPoint and SetScale put it back, and after its
--  SetFrameStrata and SetFrameLevel its layer: the game's action bars set their
--  own strata at every drag onto them (ActionBarMixin:UpdateFrameStrata: MEDIUM,
--  TOOLTIP while a spell is dragged), which put them behind the full screen,
--  dark and out of the mouse's reach until it opened again. A new size (another tab,
--  made small) fits it anew and is told (sized). Closed, it is given back and
--  that is told (gone). Nothing of it is replaced: hooks after its functions
--  and scripts (hooksecurefunc, HookScript), each made once per window.
--
--  A protected window in a fight is not seated (Lend says no: Hold returns
--  false), and one seated is given back once the fight is over.
--
--  Its parts the game pinned above it, in a strata of their own (the trainer
--  window's list and scroll bar stand on HIGH, the window on MEDIUM), keep a
--  level of that strata that its own levels never move: seated on the full
--  screen's strata they stayed behind it, and the trainer's list was empty
--  until the window was opened again (Saneroki, 2026-11-11). So they are lent
--  too, raised above the rest of the window in the room's strata, and given
--  back after it (its strata given back drags theirs along).
--
--      local seat = Core.Seat.New(frame, {
--          label = "spellbook",            -- its name in the error log
--          sized = function() end,         -- its size changed while seated (fitted anew already)
--          gone = function() end,          -- it closed while seated (given back already)
--      })
--      seat:Hold(left, top, width, height, strata, level)
--                                          -- seated in that room: UIParent's units, left and top from its
--                                          -- bottom left corner; in that strata, at least at that level.
--                                          -- false: not now (closed, or protected in a fight)
--      seat:Free()                         -- given back
--      seat.held                           -- seated now
--      seat:Size()                         -- its own size in UIParent's units, as it is when not seated
-------------------------------------------------------------------------------
local Seat = {}
Core.Seat = Seat

local seats = setmetatable({}, { __mode = "k" }) -- [frame] = its seat
local methods = {}
local placing = false -- our own SetPoint or SetScale on a window is running: its hooks pass

local function Plain(value)
    return Core.Plain(value) or 0
end

-- Its scale and place in the room: as large as fits, at most its own scale (base), in the room's middle.
local function Fit(self)
    local frame, room = self.frame, self.room
    local width, height = Plain(frame:GetWidth()), Plain(frame:GetHeight())
    if width <= 0 or height <= 0 then return end
    local parent = frame:GetParent()
    local outer = (parent and parent:GetEffectiveScale() or 1) / UIParent:GetEffectiveScale() -- its parent's, in UIParent's
    local scale = math.min(room[3] / (width * outer), room[4] / (height * outer), self.base)
    local own = scale * outer -- one of its units, in UIParent's
    local left = room[1] + (room[3] - width * own) / 2
    local top = room[2] - (room[4] - height * own) / 2
    placing = true
    local ok, problem = pcall(function()
        self.lent:SetScale(scale)
        self.lent:SetPoints(function()
            frame:ClearAllPoints()
            -- An anchor's offsets are in the window's own units.
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / own, top / own)
        end)
    end)
    placing = false
    if not ok then error(problem, 0) end
end

-- The hooks, after the window's own: each finds the seat it has now.
local function Moved(frame)
    local self = seats[frame]
    if placing or not self or not self.held or Core.Locked(frame) then return end
    Core.Safe(self.label, Fit, self)
end

-- The game's stratas, low to high.
local STRATA = { WORLD = 0, BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6,
                 FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

-- Its parts pinned above it (a strata of their own, higher than its own), found before it is seated, while that
-- still shows; each one's layer noted first, since the window's new strata may change it.
local function Pinned(frame)
    local own, pinned = STRATA[frame:GetFrameStrata()], {}
    if not own then return pinned end
    for _, child in ipairs({ frame:GetChildren() }) do
        local strata = STRATA[child:GetFrameStrata()]
        if strata and strata > own then
            local lend = Core.Lend(child)
            if lend:SetLayer() then pinned[#pinned + 1] = lend end
        end
    end
    return pinned
end

-- The highest level in a frame and its parts, those of skip left out.
local function Top(frame, skip)
    local top = Plain(frame:GetFrameLevel())
    for _, child in ipairs({ frame:GetChildren() }) do
        if not skip[child] then top = math.max(top, Top(child, skip)) end
    end
    return top
end

-- Its pinned parts above the rest of it in the room's strata, as they stood above it in the game's own; one in a
-- strata above the room's stands above the full screen already and is left there.
local function Lift(self, strata)
    local pinned, skip = self.pinned, {}
    if #pinned == 0 then return end
    for _, lend in ipairs(pinned) do skip[lend.frame] = true end
    local level = Top(self.frame, skip) + 1
    for _, lend in ipairs(pinned) do
        if (STRATA[lend.frame:GetFrameStrata()] or 0) <= (STRATA[strata] or 0) then lend:SetLayer(strata, level) end
    end
end

-- Its layer in the room: that strata, at least that level (where its own is above already, its own); its pinned
-- parts above it.
local function Layer(self)
    local frame, strata, level = self.frame, self.layer[1], self.layer[2]
    placing = true
    local ok, problem = pcall(function()
        self.lent:SetLayer(strata, Plain(frame:GetFrameLevel()) < level and level or nil)
        Lift(self, strata)
    end)
    placing = false
    if not ok then error(problem, 0) end
end

-- Its own code set its strata or level anew: the room's again, now or once the fight is over (a protected frame).
local function Relayer(self)
    if not self.held or Core.Locked(self.frame) then return end
    Layer(self)
end

local function Layered(frame)
    local self = seats[frame]
    if placing or not self or not self.held or not self.layer then return end
    if frame:GetFrameStrata() == self.layer[1] and Plain(frame:GetFrameLevel()) >= self.layer[2] then return end
    if Core.Locked(frame) then
        return Core.AfterCombat(self.label .. ": layer of " .. tostring(frame:GetName() or frame), Relayer, self)
    end
    Core.Safe(self.label, Layer, self)
end

local function Sized(frame)
    local self = seats[frame]
    if placing or not self or not self.held or Core.Locked(frame) then return end
    Core.Safe(self.label, Fit, self)
    if self.options.sized then Core.Safe(self.label, self.options.sized) end
end

local function Hidden(frame)
    local self = seats[frame]
    if not self or not self.held then return end
    self:Free()
    if self.options.gone then Core.Safe(self.label, self.options.gone) end
end

local hooked = setmetatable({}, { __mode = "k" })
local function Follow(frame)
    if hooked[frame] then return end
    hooked[frame] = true
    hooksecurefunc(frame, "SetPoint", Core.Guard("seat", Moved))
    hooksecurefunc(frame, "SetScale", Core.Guard("seat", Moved))
    hooksecurefunc(frame, "SetFrameStrata", Core.Guard("seat", Layered))
    hooksecurefunc(frame, "SetFrameLevel", Core.Guard("seat", Layered))
    frame:HookScript("OnSizeChanged", Core.Guard("seat", Sized))
    frame:HookScript("OnHide", Core.Guard("seat", Hidden))
end

function methods:Hold(left, top, width, height, strata, level)
    local frame = self.frame
    if Core.Locked(frame) or not frame:IsShown() then return false end
    Follow(frame)
    if not self.held then
        self.base = Plain(frame:GetScale())
        self.pinned = Pinned(frame)
    end
    if self.base <= 0 then self.base = 1 end
    self.held = true
    local room = self.room
    room[1], room[2], room[3], room[4] = left, top, math.max(width, 1), math.max(height, 1)
    -- Its own level where that is above already (the game's spellbook stands at 5000, its parts above that).
    self.layer = { strata or frame:GetFrameStrata(), level or 0 }
    Layer(self)
    Fit(self)
    return true
end

function methods:Free()
    if not self.held then return end
    self.held = false
    placing = true
    local ok, back = pcall(self.lent.Return, self.lent)
    local problem = not ok and back or nil
    -- Its pinned parts after it, its strata given back dragging theirs along: after the fight too where its own
    -- waits for that (Core.AfterCombat keeps the order).
    for _, lend in ipairs(self.pinned) do
        if ok and back == false then
            Core.AfterCombat(lend, lend.Return, lend)
        else
            local fine, why = pcall(lend.Return, lend)
            if not fine and not problem then problem = why end
        end
    end
    self.pinned = {}
    placing = false
    if problem then Core.Report(self.label, problem) end
end

function methods:Size()
    local frame = self.frame
    local parent = frame:GetParent()
    local outer = (parent and parent:GetEffectiveScale() or 1) / UIParent:GetEffectiveScale()
    local scale = self.held and self.base or Plain(frame:GetScale())
    return Plain(frame:GetWidth()) * scale * outer, Plain(frame:GetHeight()) * scale * outer
end

function Seat.New(frame, options)
    options = options or {}
    local self = setmetatable({ frame = frame, options = options, label = options.label or "seat",
                                lent = Core.Lend(frame), room = {}, held = false, base = 1, pinned = {} },
                         { __index = methods })
    seats[frame] = self
    return self
end

-------------------------------------------------------------------------------
--  A window not ours as a part of a module's board (Saneroki, 2026-11-09: the
--  game's vendor, trainer and profession windows on a full screen). Its panel
--  holds the window, seated in the panel's body while the window is open; the
--  part is there (Present) only while it is. The game opens and closes it, at
--  an NPC or by its own keys: our code only follows (hooks after its OnShow
--  and OnHide), and tells the module.
--
--      local part = Core.Seat.Part({
--          frame = "MerchantFrame",          -- the window's global name (there once its addon is loaded)
--          addon = "Blizzard_TrainerUI",     -- the game's addon it comes with, loaded by the game on demand (or none)
--          label = "Inventory: vendor",      -- its name in the error log
--          level = 30,                       -- how far above its panel's body it stands (over Core's panels)
--          width = 336,                      -- how wide it is, until it is there to ask (part.Width)
--          opened = function(frame) end,     -- it came into sight, by whatever way (after its own OnShow)
--          closed = function(frame) end,     -- it went (after its own OnHide)
--      })
--      part.Build(panel), part.Show(on), part.Size(), part.Present(), part.Leave()  -- a part of a module's board
--      part.Frame()                          -- the window, once there
--      part.Width()                          -- how wide it is itself, in UIParent's units
--      part.Follow()                         -- its opening and closing followed: now, or once its addon has loaded
-------------------------------------------------------------------------------
Seat.LEVEL = 30 -- how far above its panel's body a seated part stands, unless it says

function Seat.Part(options)
    local part, label = {}, options.label or "seat"
    local body, seat, shown, followed

    function part.Frame()
        local frame = rawget(_G, options.frame)
        if type(frame) == "table" and type(frame.IsShown) == "function" then return frame end
    end

    -- Seated in its panel's body while both are shown: the body's room in UIParent's units.
    local function Lay()
        local frame = part.Frame()
        if not (shown and body and frame and frame:IsShown()) then return end
        local left, top = body:GetLeft(), body:GetTop()
        if not (left and top) then return end
        local ratio = body:GetEffectiveScale() / UIParent:GetEffectiveScale()
        seat = seat or Seat.New(frame, { label = label })
        seat:Hold(left * ratio, top * ratio, body:GetWidth() * ratio, body:GetHeight() * ratio, body:GetFrameStrata(),
                  body:GetFrameLevel() + (options.level or Seat.LEVEL))
    end
    local Relay = Core.Later(function() Core.Safe(label, Lay) end, nil, label) -- once the panel stands where it goes

    function part.Build(panel) body = panel.body end

    function part.Show(on)
        shown = on
        if on then return Relay() end
        if seat then seat:Free() end
    end

    function part.Size() Relay() end

    function part.Present()
        local frame = part.Frame()
        return frame ~= nil and Core.Plain(frame:IsShown()) == true
    end

    -- How wide it is itself, in UIParent's units, as when it is not seated (a layout's share); options.width while it
    -- is not there yet.
    function part.Width()
        local frame = part.Frame()
        if seat then return (seat:Size()) end
        local width = frame and Core.Plain(frame:GetWidth())
        if type(width) ~= "number" or width <= 0 then return options.width or 300 end
        local parent = frame:GetParent()
        local outer = (parent and parent:GetEffectiveScale() or 1) / UIParent:GetEffectiveScale()
        return width * (Core.Plain(frame:GetScale()) or 1) * outer
    end

    function part.Leave()
        shown = false
        if seat then seat:Free() end
    end

    local function Hook(frame)
        if followed or type(frame) ~= "table" then return end
        followed = true
        frame:HookScript("OnShow", Core.Guard(label, function(self) if options.opened then options.opened(self) end end))
        frame:HookScript("OnHide", Core.Guard(label, function(self) if options.closed then options.closed(self) end end))
    end

    function part.Follow()
        if part.Frame() then return Hook(part.Frame()) end
        local util = rawget(_G, "EventUtil")
        if options.addon and util and util.ContinueOnAddOnLoaded then
            util.ContinueOnAddOnLoaded(options.addon, Core.Guard(label, function() Hook(part.Frame()) end))
        end
    end

    return part
end
