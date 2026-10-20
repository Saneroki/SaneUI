local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Hybrid
--  The game's own minimap over our map, for what only it can show: its live dots
--  (nearby players, the creatures and the herbs and ore it tracks, quest areas)
--  and its tooltips over them. Our map is the ground: its own is switched off
--  (C_Minimap.SetDrawGroundTextures), as Blizzard's hybrid minimap does under its
--  map canvas (Blizzard_HybridMinimap). Only while the pin filter lets its dots
--  through (its kind Minimap dots). The small view (Window.lua):
--
--      shown        while the view follows the player and its zoom is one of the game's minimap's
--                   steps (camera.native); square, as large as the view's shorter side, in its middle,
--                   cut by the game's own white square (the game draws its dots inside its mask only,
--                   whatever its parent cuts, so nothing of it shows past the window); in a view that is
--                   not square, our map alone along its longer side's ends; above the map's layers and
--                   under its pins and marks, set again each time it is placed (a window raised and put
--                   back leaves the levels of its frames as they come)
--      the wheel    walks the game's steps first; out past the widest our map goes on alone, and
--                   in again it takes the widest step; in past the narrowest our map goes on alone
--                   too, up to its own nearest zoom (Camera.NEAR), and out again it takes the
--                   narrowest step (Wheel)
--      clicks       the left and right button go through to our map (drag, Ctrl-click, one map out);
--                   a plain left click on it pings, as the game's does (Ping); the mouse's moves stay
--                   the game's, for its tooltips
--      indoors      a cave, a building: its own ground stays off as outdoors (it would draw the
--                   indoor plan on black over our map, Saneroki 2026-10-20); our map and its dots show
--
--  The full map (Wide): around the player at the map's own scale, so its dots stand where they are
--  on our map: square, at its widest step whose square takes at most Hybrid.ROOM of the canvas'
--  shorter side (none at a zoom too close for its narrowest), kept on the player at each step of
--  the canvas' tracker (Follow) and shown while it lies wholly inside the canvas (Keep), as the pins.
--
--  Taken out of combat (Minimap is the game's frame, and some of what is set
--  here may not be set in a fight): its parent, place, size, level, mask, wheel
--  and clicks, its border art and zoom buttons out of sight, rotation ignored
--  while ours is north up, and the rest of the game's minimap cluster out of
--  sight and without clicks. Each is kept first and given back exactly (GiveBack;
--  the switch Show the game's minimap; Core's StandDown).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Hybrid = {}
ns.Hybrid = Hybrid

Hybrid.MASK = "Interface\\Buttons\\WHITE8X8" -- square: the corners of our map are the minimap's too
Hybrid.LEVEL = 10 -- over the canvas' layers, under its marks (Canvas.lua, Marks.lua)
Hybrid.ROOM = 0.5 -- the full map: its square takes at most so much of the canvas' shorter side
local WAIT = "navigation: minimap" -- what waits for the fight's end

local taken, saved, canvas, hooked
local surveying -- the steps are being measured: what the game says meanwhile is ours
local radii = { [true] = {}, [false] = {} } -- [indoors][zoom step] = the view's radius in yards
local cut -- the mask it is cut by now
local wide -- on the full map: { side, x, y (the player's place in the holder's units), holder }

-- The game's minimap, its cluster and border, if this client has them.
local function Parts()
    return rawget(_G, "Minimap"), rawget(_G, "MinimapCluster"), rawget(_G, "MinimapBackdrop")
end

-- The radius of a zoom step, read from the game while the minimap stands at that step.
local function Learn()
    local minimap = Parts()
    local radius = Core.Plain(Core.Ask(C_Minimap.GetViewRadius))
    if minimap and radius and radius > 0 then radii[IsIndoors() and true or false][minimap:GetZoom()] = radius end
end

-- Every step's radius: each step set once and read (the game answers at once), then the step as it was.
local function Survey()
    local minimap = Parts()
    local levels, was = minimap:GetZoomLevels(), minimap:GetZoom()
    surveying = true
    for step = 0, levels - 1 do
        minimap:SetZoom(step)
        Learn()
    end
    minimap:SetZoom(was)
    surveying = false
end

-- The side of the game's minimap in a view of that size: the shorter side, so all of it lies inside the view, cut by
-- the game's own square. (Bands of a texture of our own as its mask, to cover a view that is not square, left the
-- game's minimap empty: no dots and no arrow of its own, 2026-10-20.)
function Hybrid.Side(width, height)
    return math.min(width, height)
end

-- The zoom a step gives a view of that size (units per yard), or nil while its radius is not known.
function Hybrid.Zoom(step, size)
    local radius = radii[IsIndoors() and true or false][step]
    return radius and size / 2 / radius or nil
end

-- Clicks off on a frame and every frame under it, but Edit Mode's selection; what had them is kept.
local function Quiet(frame, kept)
    if frame == Parts() then return end -- the minimap itself, should it be under it still
    if frame:IsMouseEnabled() and frame ~= rawget(frame:GetParent() or {}, "Selection") then
        kept[frame] = true
        frame:EnableMouse(false)
    end
    for _, child in ipairs({ frame:GetChildren() }) do Quiet(child, kept) end
end

local function Take()
    local minimap, cluster, backdrop = Parts()
    if not minimap or not cluster or not canvas then return end
    saved = {
        parent = minimap:GetParent(), points = Core.Points(minimap), strata = minimap:GetFrameStrata(),
        level = minimap:GetFrameLevel(), wheel = minimap:IsMouseWheelEnabled(), shown = minimap:IsShown(),
        zoom = minimap:GetZoom(), clusterAlpha = cluster:GetAlpha(), clusterMouse = cluster:IsMouseEnabled(),
        backdropAlpha = backdrop and backdrop:GetAlpha(), mice = {}, buttons = {},
    }
    saved.width, saved.height = minimap:GetSize()
    taken = true -- from here on GiveBack undoes it, whatever fails next
    minimap:SetParent(canvas)
    minimap:ClearAllPoints()
    minimap:SetPoint("CENTER")
    minimap:SetFrameLevel(canvas:GetFrameLevel() + Hybrid.LEVEL)
    minimap:SetMaskTexture(Hybrid.MASK)
    cut = Hybrid.MASK
    minimap:EnableMouseWheel(false)
    if minimap.SetPassThroughButtons then minimap:SetPassThroughButtons("LeftButton", "RightButton") end
    for _, key in ipairs({ "ZoomIn", "ZoomOut" }) do
        local button = rawget(minimap, key)
        if button then
            saved.buttons[button] = { button:GetAlpha(), button:IsMouseEnabled() }
            button:SetAlpha(0)
            button:EnableMouse(false)
        end
    end
    if backdrop then backdrop:SetAlpha(0) end
    cluster:SetAlpha(0)
    Quiet(cluster, saved.mice)
    C_Minimap.SetIgnoreRotateMinimap(true)
    C_Minimap.SetDrawGroundTextures(false) -- outdoors and in: its dots only, our map under them
    Survey()
    minimap:Hide() -- shown by Place, when a view follows at one of its steps
end

local function Give()
    local minimap, cluster, backdrop = Parts()
    taken = false
    if minimap.SetPassThroughButtons then minimap:SetPassThroughButtons() end
    minimap:EnableMouseWheel(saved.wheel)
    minimap:SetParent(saved.parent)
    Core.Repoint(minimap, saved.points)
    minimap:SetSize(saved.width, saved.height)
    minimap:SetFrameStrata(saved.strata)
    minimap:SetFrameLevel(saved.level)
    minimap:SetZoom(saved.zoom)
    C_Minimap.SetDrawGroundTextures(true)
    C_Minimap.SetIgnoreRotateMinimap(false)
    cut = nil
    for button, was in pairs(saved.buttons) do
        button:SetAlpha(was[1])
        button:EnableMouse(was[2])
    end
    if backdrop and saved.backdropAlpha then backdrop:SetAlpha(saved.backdropAlpha) end
    for frame in pairs(saved.mice) do frame:EnableMouse(true) end
    cluster:SetAlpha(saved.clusterAlpha)
    cluster:EnableMouse(saved.clusterMouse)
    -- Its mask, frame art and sizes as the game sets them for the minimap's settings.
    if cluster.UpdateMinimapConfig then Core.Ask(cluster.UpdateMinimapConfig, cluster) end
    minimap:SetShown(saved.shown)
    saved = nil
end

-- Taken or given back as the switch says (Show the game's minimap), and given back once the module stood
-- down. Out of combat; asked in a fight, it waits for its end.
function Hybrid.Update()
    local wanted = not ns.off and not ns.options.nativeMinimap and canvas ~= nil
    if wanted == (taken and true or false) then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Hybrid.Update) end
    if not wanted then return Give() end
    Take()
    -- The small view starts at the step the player had the game's minimap at.
    if taken then ns.Window.Native(saved.zoom) end
end

function Hybrid.GiveBack()
    if not taken then return end
    if InCombatLockdown() then return Core.AfterCombat(WAIT, Hybrid.GiveBack) end
    Give()
end

-- The game sets the minimap's mask again when its rotation is switched (MinimapCluster:UpdateMinimapConfig;
-- in this game a function of its own, on the setting rotateMinimap): ours again after it, and its border
-- kept out of sight.
local function Reset()
    if not taken then return end
    local minimap, _, backdrop = Parts()
    minimap:SetMaskTexture(cut or Hybrid.MASK)
    if backdrop then backdrop:SetAlpha(0) end
end

local resetting = ns.Guard(Reset) -- made once

-- A zoom step was set (by us, or the game going indoors): its radius learnt, the view's zoom with it. The
-- first time indoors, or outdoors, every step is measured.
local function Zoomed()
    if not taken or surveying then return end
    if not next(radii[IsIndoors() and true or false]) then Survey() else Learn() end
    ns.Canvas.Refresh()
end

-- After every loading screen the game tells the minimap's radius anew (at login it may not yet): measured
-- again, and the small view at the player's step if it had none.
local function Entered()
    if not taken then return end
    wipe(radii[true])
    wipe(radii[false])
    Survey()
    ns.Window.Native(Parts():GetZoom())
    ns.Canvas.Refresh()
end

function Hybrid.Start(canvasFrame)
    canvas = canvasFrame
    local _, cluster = Parts()
    if not hooked and cluster and cluster.UpdateMinimapConfig then
        hooksecurefunc(cluster, "UpdateMinimapConfig", ns.Guard(Reset))
        hooked = true
    end
    -- After the game's own answer to the setting, on the next frame.
    ns.On("CVAR_UPDATE", function(name) if name == "rotateMinimap" then C_Timer.After(0, resetting) end end)
    ns.On("MINIMAP_UPDATE_ZOOM", Zoomed)
    ns.On("ZONE_CHANGED_INDOORS", Zoomed)
    ns.On("PLAYER_ENTERING_WORLD", Entered)
    Hybrid.Update()
end

-- Whether the game's minimap is ours now.
function Hybrid.Taken()
    return taken and true or false
end

-- Before a view is laid out: a camera at one of the game's steps has that step's zoom for the view's size
-- (it changes with the size, and indoors); a step not known any more is left.
function Hybrid.Fit(camera, width, height)
    if not camera.native then return end
    local zoom = taken and Hybrid.Zoom(camera.native, Hybrid.Side(width, height))
    if zoom then camera.k = zoom else camera.native = nil end
end

-- Its size, layer and step for a view (mask: the one it is cut by).
local function Set(minimap, size, step, mask)
    if mask ~= cut then
        minimap:SetMaskTexture(mask)
        cut = mask
    end
    minimap:SetSize(size, size)
    minimap:SetFrameStrata(canvas:GetFrameStrata())
    minimap:SetFrameLevel(canvas:GetFrameLevel() + Hybrid.LEVEL)
    if minimap:GetZoom() ~= step then minimap:SetZoom(step) end
end

-- The full map (its camera, the canvas' size): the widest step whose square at the map's zoom fits in
-- Hybrid.ROOM of the canvas' shorter side; placed on the player by Follow.
local function Wide(minimap, camera, width, height, known)
    local room, indoors = math.min(width, height) * Hybrid.ROOM, IsIndoors() and true or false
    local step, side
    for each = 0, minimap:GetZoomLevels() - 1 do
        local radius = radii[indoors][each]
        if radius and 2 * radius * camera.k <= room then
            step, side = each, 2 * radius * camera.k
            break
        end
    end
    if not step or not known then
        wide = nil
        return minimap:Hide()
    end
    Set(minimap, side, step, Hybrid.MASK)
    wide = { side = side }
    minimap:Hide() -- until Follow knows where the player is
end

-- The game's minimap for a view (camera, the view's size): shown in its middle at the camera's step while
-- it follows the player (known is false while the player's place is not), square in its middle, out of
-- sight otherwise. The camera's zoom is the step's. On the full map: Wide.
function Hybrid.Place(camera, width, height, known)
    if not taken then return end
    local minimap = Parts()
    wide = nil
    if not ns.Pins.Shows("minimap") then return minimap:Hide() end
    if camera == ns.Window.full then return Wide(minimap, camera, width, height, known) end
    local size = Hybrid.Side(width, height)
    local step = camera.native
    local zoom = size > 0 and step and camera.follow and known and Hybrid.Zoom(step, size)
    if not zoom then
        minimap:Hide()
        return
    end
    minimap:ClearAllPoints()
    minimap:SetPoint("CENTER", canvas, "CENTER")
    Set(minimap, size, step, Hybrid.MASK)
    minimap:Show()
end

-- The full map: kept on the player (x, y: the player's place in holder's units, nil while not known on the
-- map's plane), shown while it lies wholly inside the canvas. Each step of the canvas' tracker.
function Hybrid.Follow(holder, x, y)
    if not wide then return end
    local minimap = Parts()
    wide.x, wide.y = x, y
    if not x then return minimap:Hide() end
    minimap:ClearAllPoints()
    minimap:SetPoint("CENTER", holder, "CENTER", x, y)
    minimap:SetShown(ns.Canvas.Inside(x, y, wide.side / 2))
end

-- The full map moved (Canvas.edge): shown while it still lies wholly inside the canvas.
function Hybrid.Keep()
    if wide and wide.x then Parts():SetShown(ns.Canvas.Inside(wide.x, wide.y, wide.side / 2)) end
end

-- Out of sight (the window on its way to the full screen and back).
function Hybrid.Hide()
    wide = nil
    if taken then Parts():Hide() end
end

-- Whether it shows now: the canvas hides the player's arrow then, the game's own is there.
function Hybrid.Shown()
    return taken and Parts():IsShown() or false
end

-- The wheel over a view that follows the player (size: Hybrid.Side of it): the game's steps first. True
-- when it took the notch (the camera's step and zoom are set), false when our map zooms on its own.
function Hybrid.Wheel(camera, notches, size)
    if not taken or not camera.follow then return false end
    local minimap = Parts()
    local step, last = camera.native, minimap:GetZoomLevels() - 1
    local nearest = Hybrid.Zoom(last, size)
    if step then
        step = step + (notches > 0 and 1 or -1)
        if step < 0 then
            -- Out past the widest step: our map alone, a notch farther.
            camera.native = nil
            camera.k = (Hybrid.Zoom(0, size) or camera.k) / ns.Camera.STEP
            return true
        end
        if step > last then
            -- In past the narrowest step: our map alone, a notch nearer, up to its own nearest zoom.
            if not nearest or nearest >= ns.Camera.Near() then return true end
            camera.native = nil
            camera.k = math.min(ns.Camera.Near(), nearest * ns.Camera.STEP)
            return true
        end
    elseif nearest and camera.k > nearest then
        -- Nearer than the narrowest step: our map zooms on alone; out again, it takes the narrowest step.
        if notches > 0 or camera.k * ns.Camera.STEP ^ notches > nearest * (1 + 1e-6) then return false end
        step = last
    elseif notches > 0 then
        local widest = Hybrid.Zoom(0, size)
        if not widest or camera.k * ns.Camera.STEP ^ notches < widest and camera.k < ns.Camera.Near() then return false end
        step = 0
    else
        return false
    end
    local zoom = Hybrid.Zoom(step, size)
    if not zoom then return false end
    camera.native, camera.k = step, zoom
    return true
end

-- A plain left click at x, y units from the view's middle: the game's ping, where its minimap shows.
function Hybrid.Ping(x, y)
    if wide or not Hybrid.Shown() then return false end
    local minimap = Parts()
    local half = minimap:GetWidth() / 2
    if math.abs(x) > half or math.abs(y) > half then return false end
    minimap:PingLocation(x, y)
    return true
end
