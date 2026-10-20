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
--  hooks after its SetPoint and SetScale put it back. A new size (another tab,
--  made small) fits it anew and is told (sized). Closed, it is given back and
--  that is told (gone). Nothing of it is replaced: hooks after its functions
--  and scripts (hooksecurefunc, HookScript), each made once per window.
--
--  A protected window in a fight is not seated (Lend says no: Hold returns
--  false), and one seated is given back once the fight is over.
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
    frame:HookScript("OnSizeChanged", Core.Guard("seat", Sized))
    frame:HookScript("OnHide", Core.Guard("seat", Hidden))
end

function methods:Hold(left, top, width, height, strata, level)
    local frame = self.frame
    if Core.Locked(frame) or not frame:IsShown() then return false end
    Follow(frame)
    if not self.held then self.base = Plain(frame:GetScale()) end
    if self.base <= 0 then self.base = 1 end
    self.held = true
    local room = self.room
    room[1], room[2], room[3], room[4] = left, top, math.max(width, 1), math.max(height, 1)
    -- Its own level where that is above already (the game's spellbook stands at 5000, its parts above that).
    self.lent:SetLayer(strata, Plain(frame:GetFrameLevel()) <= level and level or nil)
    Fit(self)
    return true
end

function methods:Free()
    if not self.held then return end
    self.held = false
    placing = true
    local ok, problem = pcall(self.lent.Return, self.lent)
    placing = false
    if not ok then Core.Report(self.label, problem) end
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
                                lent = Core.Lend(frame), room = {}, held = false, base = 1 }, { __index = methods })
    seats[frame] = self
    return self
end
