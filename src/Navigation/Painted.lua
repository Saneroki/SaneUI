local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Painted
--  The view Atlas: the whole world painted as one map, over the terrain as
--  Scrying draws it. The art is a module of its own, SaneUI_Atlas (its code in
--  src/Atlas/, its art of about 3 GB made into assets/optimized/Atlas/ and put in
--  by dev/build), loaded on demand:
--
--      found      at login, without loading it: it is in the addon list, switched on for this character
--                 and loadable (Find); only then the view is offered (its button, its choice)
--      loaded     the first time the view is drawn (Ready: C_AddOns.LoadAddOn, guarded); its index
--                 read, it answers as SaneUI.Atlas (Core's modules). If it cannot be loaded, or stands
--                 down later, the view is no longer offered: its button and choice go and the map shows
--                 Scrying (Navigation.lua, Offer); the problem is kept and told once
--
--  Its blocks (512 x 512 pixels) come in levels: level 0 at 2048 pixels a terrain
--  tile, each level up half the detail. The level drawn is the coarsest whose art
--  still has as many pixels a yard as the screen shows at that zoom (Level), so
--  about the same number of blocks are drawn at every zoom; under it the next
--  coarser level's blocks, a quarter as many, so a block still loading leaves no
--  hole. Where the index has no block (open sea, not painted yet) the terrain
--  shows. Every continent's blocks wherever they are in view, laid by link into
--  the view's plane as the terrain's overview is (Terrain.Overview), each at the
--  level its own scale on the screen asks for, from the canvas' pool: a block that
--  stays in view is not loaded again.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Painted = {}
ns.Painted = Painted

Painted.ADDON = "SaneUI_Atlas"
Painted.CAP = 400 -- the most blocks of a continent's level laid out at once; past it a coarser one (a long way of the window)
-- What the game says of an addon that is loaded on demand and not yet loaded (Blizzard_AddOnList: its reasons).
local DEMAND = { DEMAND_LOADED = true, DEP_DEMAND_LOADED = true }

local Coords = ns.Coords
local state -- nil: not looked for; "found": there, not loaded; "ready": loaded and read; false: not there, or failed
local atlas -- the module's table once loaded (SaneUI.Atlas)
local pool

-- The view goes from the buttons and the settings on the next frame (not inside the layout that found it).
local offer = Core.Later(function() ns.Guarded(ns.Offer) end)

-- Looks for the module in the game's addon list, without loading it (at login).
function Painted.Find()
    state = false
    local api = rawget(_G, "C_AddOns")
    if not api then return false end
    if Core.Ask(api.IsAddOnLoaded, Painted.ADDON) then
        state = "found"
        return true
    end
    -- Five answers: Core.Ask hands on three. A name not in the list fails or says MISSING.
    local ok, name, _, _, loadable, reason = pcall(api.GetAddOnInfo, Painted.ADDON)
    if not ok or Core.Plain(name) ~= Painted.ADDON then return false end
    local enabled = Core.Ask(api.GetAddOnEnableState, Painted.ADDON, Core.Plain(UnitGUID("player")))
    if enabled == 0 or not (Core.Plain(loadable) or DEMAND[Core.Plain(reason)]) then return false end
    state = "found"
    return true
end

-- Whether the view is offered: the module was found and has not failed.
function Painted.Offered()
    return state == "found" or state == "ready"
end

-- It cannot be drawn (why: what to keep and tell; nil when a guard told it already): no longer offered.
local function Fail(why)
    state, atlas = false, nil
    if why then ns.Report("atlas", ns.TEXT.atlasFailed:format(why)) end
    offer()
end

-- The module loaded and its index read: true, or why not.
local function Load()
    local api = C_AddOns
    if not Core.Ask(api.IsAddOnLoaded, Painted.ADDON) then
        local ok, loaded, reason = pcall(api.LoadAddOn, Painted.ADDON)
        if not ok then return tostring(loaded) end
        if not Core.Plain(loaded) then return tostring(Core.Plain(reason) or "?") end
    end
    local module = SaneUI.Atlas
    if type(module) ~= "table" or module.off or type(module.Ready) ~= "function" then return ns.TEXT.atlasBroken end
    if not module.Ready() then return ns.TEXT.atlasEmpty end
    atlas = module
    return true
end

-- Whether the view can be drawn now: loaded the first time it is asked (the view is drawn); false once the
-- module failed to load or stood down (its own error, caught by Core's guards).
function Painted.Ready()
    if state == "ready" then
        if not atlas.off then return true end
        Fail(nil)
        return false
    end
    if state ~= "found" then return false end
    local done = ns.Safe("atlas", Load)
    if done == true then
        state = "ready"
        return true
    end
    Fail(done)
    return false
end

-- The level for a zoom (perYard: the screen's pixels a yard), of levels with blocks of pixels a side, span(level)
-- yards: the coarsest whose art still has as many pixels a yard, never finer than 0 nor past the last.
function Painted.Level(perYard, levels, pixels, span)
    local level = 0
    while level + 1 < levels and pixels / span(level + 1) >= perYard do level = level + 1 end
    return level
end

-- The screen's pixels in one of the canvas' units (768 units are the screen's height at scale 1).
local function Pixels()
    local frame = ns.Canvas.frame
    local scale = frame and Core.Plain(frame:GetEffectiveScale())
    local _, high = Core.Ask(rawget(_G, "GetPhysicalScreenSize"))
    if not scale or scale <= 0 or type(high) ~= "number" or high <= 0 then return 1 end
    return scale * high / 768
end

-- The blocks of a level a continent's grid has in view (link: that continent's plane in the view's): its
-- first and last row and column, or nil.
local function Range(view, link, level)
    local last = atlas.Cells(level) - 1
    -- The view's corners in that continent's own plane, as the world's yards: x = v (north), y = -u (west).
    local left, top = (view.left - link.du) / link.su, (view.top - link.dv) / link.sv
    local right, bottom = (view.right - link.du) / link.su, (view.bottom - link.dv) / link.sv
    local r0, c0 = atlas.Cell(level, top, -left)
    local r1, c1 = atlas.Cell(level, bottom, -right)
    r0, c0, r1, c1 = math.max(0, r0), math.max(0, c0), math.min(last, r1), math.min(last, c1)
    if r0 > r1 or c0 > c1 then return nil end
    return r0, r1, c0, c1
end

-- A continent's blocks of a level in view (link: its plane in the view's), at sublevel.
local function Lay(view, continent, link, level, sublevel)
    local r0, r1, c0, c1 = Range(view, link, level)
    if not r0 then return end
    local span = atlas.Span(level)
    for row = r0, r1 do
        for column = c0, c1 do
            local key = atlas.Key(continent, level, row, column)
            if atlas.Has(key) then
                local x, y = atlas.Corner(level, row, column)
                ns.Canvas.Put(pool:Get(key, atlas.File(continent, level, row, column), sublevel),
                    link.du - link.su * y, link.dv + link.sv * x, span * link.su, span * link.sv)
            end
        end
    end
end

-- One continent's painted map in view: the level its zoom asks for (on the screen a continent's yard is so
-- many of the view's), coarser while more than CAP blocks would be in view, and the next coarser under it.
local function Continent(view, continent, link, perYard)
    local levels = atlas.Levels()
    local level = Painted.Level(perYard * math.sqrt(link.su * link.sv), levels, atlas.PIXELS, atlas.Span)
    local r0, r1, c0, c1 = Range(view, link, level)
    while r0 and (r1 - r0 + 1) * (c1 - c0 + 1) > Painted.CAP do
        if level + 1 >= levels then return end
        level = level + 1
        r0, r1, c0, c1 = Range(view, link, level)
    end
    if not r0 then return end
    if level + 1 < levels then Lay(view, continent, link, level + 1, 0) end
    Lay(view, continent, link, level, 1)
end

function Painted.Build(holder)
    local layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    pool = ns.Canvas.Pool(layer, "BACKGROUND")
    return layer
end

-- The painted map in view (view: Canvas.view), if shown and loaded (Ready): every plane's blocks there (the
-- continents, and Zephras Isle once the art has it).
function Painted.Place(view, shown)
    pool:Begin()
    if shown and atlas then
        local perYard = view.k * Pixels()
        for _, map in ipairs(Coords.Planes()) do
            local box, link = Coords.Box(map), Coords.Link(map, view.map)
            if box and link then Continent(view, box.continent, link, perYard) end
        end
    end
    pool:End()
end

-- Every texture let go.
function Painted.Clear()
    pool:Begin()
    pool:End()
end
