local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Strays
--  The buttons other addons hang on and around the game's minimap, and the
--  addons the game's own addon compartment lists. While our window is the
--  minimap (Hybrid.Taken) the game's minimap lies inside our map, shown at its
--  steps only, and the rest of its cluster is out of sight: their buttons would
--  stand on our map now and then, or nowhere. So they are held in the satchel
--  instead (Satchel.lua), each in a cell of its own: its own button as its addon
--  made it, its clicks and its tooltip its own.
--
--  Another addon's: a frame on the minimap, its backdrop or its cluster with a
--  name of its own, whose global the game says an addon set (issecurevariable:
--  not secure, and by which addon; the game's own frames are secure, Sane UI's
--  are left), no larger than Strays.LARGEST, taking the mouse, not protected.
--  Looked for at the login, Strays.AGAIN seconds after it, after each addon that
--  loads, and as the satchel opens. Named by its addon's title in the addon list.
--
--  Held: its parent, place, scale, alpha and level kept, then out of sight until
--  the satchel lays it in its cell (Strays.Place), unseen there over the round
--  picture the satchel draws of it (Strays.Picture: without the ring and the
--  background round it), its clicks and tooltip its own; where its addon places it
--  again or shows it (a drag, an update of its own, a fade) it goes back (hooks
--  after its SetPoint and SetAlpha).
--  The clicks the cluster's hiding took from it are its own again (Hybrid.Release).
--  Given back exactly once the game's minimap is the game's again (the switch
--  Show the game's minimap) or the module stands down (GiveBack). One its addon
--  hides is left out of the satchel while it is hidden.
--
--  The game's addon compartment (AddonCompartmentFrame, in both games; out of
--  sight with the cluster): each addon it lists is a cell too, its icon and its
--  title, a click and the mouse over it calling that addon's own as the game's
--  menu calls them, behind pcall (a failure there is that addon's, never Sane
--  UI's). An addon with a button held shows once, by its button.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Strays = {}
ns.Strays = Strays

Strays.LARGEST = 64       -- a button no larger than this either way: a larger frame on the minimap is no button
Strays.AGAIN = { 0, 2, 10 } -- seconds after the login it looks again: the next frame first, for the buttons addons make
                             -- at the login itself (held before another addon that gathers minimap buttons takes them
                             -- off the minimap: it looks a second later), then for addons that make theirs late

local held = {}       -- [button] = what it was: parent, points, scale, strata, level, mouse; and its addon, title
local spots = {}      -- [button] = the frame it is laid on now (a cell), or the hidden home
local hooked = {}     -- [button] = true: its SetPoint and SetAlpha are hooked (a hook stays; it asks held)
local placing = false -- our own SetPoint on a held button: its hook leaves that be
local home            -- out of sight: where a held button waits for its cell

-- A text as the addon list shows it, without colours, pictures and links (Core.Fuzzy.Plain), trimmed.
local function Plain(text)
    if type(text) ~= "string" then return nil end
    text = Core.Fuzzy.Plain(text):match("^%s*(.-)%s*$")
    return text ~= "" and text or nil
end

-- An addon's title in the addon list (its folder's name where it has none).
local function Title(addon)
    local _, title = Core.Ask(C_AddOns.GetAddOnInfo, addon)
    return Plain(title) or addon
end

-- The frames other addons hang buttons on: the minimap, its backdrop, its cluster and the cluster's room for it.
local function Hangers()
    local cluster = rawget(_G, "MinimapCluster")
    return { rawget(_G, "Minimap"), rawget(_G, "MinimapBackdrop"), cluster, cluster and rawget(cluster, "MinimapContainer") }
end

-- The addon whose button a frame is: named, its global set by that addon (not Sane UI); nil for the game's own, and
-- for every frame where the client cannot tell (none held then).
local function Whose(frame)
    local name, ask = frame:GetName(), rawget(_G, "issecurevariable")
    if not name or not ask or rawget(_G, name) ~= frame then return nil end
    local secure, addon = ask(name)
    if secure or type(addon) ~= "string" or addon:find("^SaneUI") then return nil end
    return addon
end

-- Whether a frame is a button: small, taking clicks, not one of the protected kind (moved only out of a fight).
local function Button(frame)
    if frame:IsProtected() then return false end
    local width, height = frame:GetSize()
    if not width or width <= 0 or width > Strays.LARGEST or height <= 0 or height > Strays.LARGEST then return false end
    return frame:IsObjectType("Button") or frame:IsMouseEnabled() or frame:GetScript("OnMouseUp") ~= nil
end

-- A held button on its spot, at its size there (size: the units its larger side takes; nil: as it was).
local function Lay(button, size)
    local spot, was = spots[button], held[button]
    placing = true
    button:SetParent(spot)
    button:ClearAllPoints()
    button:SetPoint("CENTER", spot, "CENTER")
    local width, height = button:GetSize()
    button:SetScale(size and size / math.max(width or 1, height or 1, 1) or was.scale)
    button:SetFrameStrata(spot:GetFrameStrata())
    button:SetFrameLevel(spot:GetFrameLevel() + 2)
    button:SetAlpha(0) -- the satchel draws its picture under it
    placing = false
end

-- Its addon placed it again (a drag, its own update): back on its spot.
local function Placed(button)
    if placing or not held[button] then return end
    Lay(button, spots[button].size)
end
local replaced = ns.Guard(Placed) -- made once: the hook after each held button's SetPoint

-- Its addon showed it again (a fade on the mouse's coming): unseen again over its picture.
local unseen = ns.Guard(function(button)
    if placing or not held[button] then return end
    placing = true
    button:SetAlpha(0)
    placing = false
end)

local function Take(button, addon)
    held[button] = {
        parent = button:GetParent(), points = Core.Points(button), scale = button:GetScale(),
        strata = button:GetFrameStrata(), level = button:GetFrameLevel(), alpha = button:GetAlpha(), addon = addon,
        title = Title(addon),
    }
    ns.Hybrid.Release(button)
    if not hooked[button] then
        hooksecurefunc(button, "SetPoint", replaced)
        hooksecurefunc(button, "SetAlpha", unseen)
        hooked[button] = true
    end
    spots[button] = home
    Lay(button)
end

-- Every button of another addon on the minimap and its cluster held, while our window is the minimap.
function Strays.Look()
    if not home or ns.off or not ns.Hybrid.Taken() then return end
    local hangers = Hangers()
    for index = 1, 4 do -- one may be missing: no ipairs
        local hanger = hangers[index]
        if type(hanger) == "table" then
            for _, frame in ipairs({ hanger:GetChildren() }) do
                if not held[frame] then
                    local addon = Whose(frame)
                    if addon and Button(frame) then Take(frame, addon) end
                end
            end
        end
    end
end

-- A held button on a cell of the satchel (size: the units its larger side takes there), or back out of sight (none).
function Strays.Place(button, cell, size)
    if not held[button] then return end
    spots[button] = cell or home
    if cell then cell.size = size end
    Lay(button, cell and size)
end

-- The picture an addon's button shows: the largest of its textures in the ARTWORK layer that shows something, else
-- its normal texture (some draw their picture so); nil where it has none. The ring and the background the common
-- minimap buttons lay round it are in other layers, and stay out of the satchel.
function Strays.Picture(button)
    local best, most
    for _, region in ipairs({ button:GetRegions() }) do
        if region:IsObjectType("Texture") and region:GetDrawLayer() == "ARTWORK" and (region:GetTexture() or region:GetAtlas()) then
            local width, height = region:GetSize()
            local area = (width or 0) * (height or 0)
            if not best or area > most then best, most = region, area end
        end
    end
    if best then return best end
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal and (normal:GetTexture() or normal:GetAtlas()) then return normal end
    return nil
end

-- A title as one addon's two ways of writing it compare: its letters and digits alone, in small letters.
local function Same(title)
    return (title:lower():gsub("[%s%p]", ""))
end

-- What the satchel holds, A to Z by title: { button, title } for each held button its addon shows, { entry, title,
-- icon } for each addon of the game's compartment that has no button held (by its title or its folder's name).
function Strays.List()
    local list, titles = {}, {}
    for button, was in pairs(held) do
        if button:IsShown() then
            list[#list + 1] = { button = button, title = was.title }
            titles[Same(was.title)], titles[Same(was.addon)] = true, true
        end
    end
    local compartment = rawget(_G, "AddonCompartmentFrame")
    local registered = compartment and compartment.registeredAddons
    for _, entry in ipairs(type(registered) == "table" and registered or {}) do
        local title = type(entry) == "table" and Plain(entry.text)
        if title and not titles[Same(title)] and not title:find("^Sane UI") then
            list[#list + 1] = { entry = entry, title = title, icon = entry.icon }
            titles[Same(title)] = true
        end
    end
    table.sort(list, function(a, b) return a.title:lower() < b.title:lower() end)
    return list
end

-- A compartment's addon clicked with mouse (its button's name): its own function, as the game's menu calls it.
function Strays.Click(entry, mouse)
    if type(entry.func) ~= "function" then return end
    local context = rawget(_G, "MenuInputContext")
    pcall(entry.func, nil, { context = context and context.MouseButton, buttonName = mouse }, nil)
end

-- The mouse over a compartment's addon (on) or gone from it: its own, if it has one. True where it has.
function Strays.Hover(entry, cell, on)
    local fn = on and entry.funcOnEnter or not on and entry.funcOnLeave
    if type(fn) ~= "function" then return false end
    pcall(fn, cell)
    return true
end

-- Every held button back where its addon had it, as it was.
function Strays.GiveBack()
    for button, was in pairs(held) do
        placing = true
        button:SetParent(was.parent)
        button:SetScale(was.scale)
        Core.Repoint(button, was.points)
        button:SetFrameStrata(was.strata)
        button:SetFrameLevel(was.level)
        button:SetAlpha(was.alpha)
        placing = false
    end
    wipe(held)
    wipe(spots)
    ns.Safe("satchel", ns.Satchel.Fill)
end

-- Held while our window is the minimap, given back when the game's minimap is the game's again.
function Strays.Update()
    if ns.Hybrid.Taken() and not ns.off then Strays.Look() else Strays.GiveBack() end
end

function Strays.Start()
    home = CreateFrame("Frame", nil, UIParent)
    home:Hide()
    ns.On("ADDON_LOADED", Core.Later(function() ns.Guarded(Strays.Look) end, 1))
    for _, after in ipairs(Strays.AGAIN) do C_Timer.After(after, ns.Guard(Strays.Look)) end
    Strays.Update()
end
