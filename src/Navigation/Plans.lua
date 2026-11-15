local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Plans
--  Your markers and drawings grouped in plans (Saneroki, 2026-11-15: "drop pins and draw on the map and save those
--  drawings and map pins together so they can be shared or grouped together. This will be especially helpful in
--  instance maps"): a plan holds markers (Markers.lua) and drawings (Draw.lua), on any map, a dungeon's floor too;
--  it shows or hides as one, and goes to your party, raid or guild as one. No frames.
--
--      Plans.List()              every plan: { id, name, shown, origin, from }; the first made at the first need
--      Plans.Active()            the plan new markers and drawings go into (chosen in the palette, DrawBar.lua)
--      Plans.SetActive(plan), Plans.New(name), Plans.Rename(plan, name), Plans.Remove(plan), Plans.Show(plan, on)
--      Plans.Visible(id)         whether a plan's things are drawn (its own switch)
--      Plans.Drawings()          every drawing: { id, plan, map, kind, colour, width, points = { x, y, x, y, ... } }
--      Plans.Add(drawing), Plans.Erase(drawing), Plans.Undo(), Plans.Clear(map)
--      Plans.Share(plan, channel, target)  the whole plan to "RAID", "PARTY", "GUILD" or "WHISPER" (to target, a
--                                  player's name); how many blocks went
--      Plans.Read(sender, text)  a block heard: the share once all its parts are there (Markers asks about it)
--      Plans.Keep(share)         a plan kept: one of the same origin replaced whole, else a new one
--
--  A drawing: its kind (pen, line, arrow, circle), its colour's key (Plans.COLOURS), its width (1 thin, 2 thick),
--  and its points on its map (0 to 1 on a zone's map or a dungeon's floor; a stroke may reach past its map's edge),
--  four places each. A line and an arrow have two points, a circle its middle and a point on its edge.
--
--  On the wire (Core.Wire, kind M as the markers', version 2), a block a part: "2", then the plan's head cut by \031
--  (its origin, its name, the part, the parts, the share's own stamp), then its rows, each cut by \030: "m" and a marker's row as Markers
--  sends it, "d" and a drawing's (its origin, map, kind, colour, width, its points as three letters each in base 36:
--  (value + 1) * 10000), their fields cut by \031. The parts are put together by the sender and the plan's origin;
--  the plan is asked about once they are all there. At most Plans.TAKE drawings and Markers.TAKE markers a plan.
--
--  Kept for the account in the module's saved settings (ns.store.plans, drawings): personal, shared only when you
--  share them (data.md, *Map markers*).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plans = {}
ns.Plans = Plans

Plans.KINDS = { pen = true, line = true, arrow = true, circle = true, route = true, text = true }
Plans.ONE = { route = true, text = true } -- the kinds one point makes (a route's first stop, words)
-- The colours to draw in, in the palette's order (the game's own where it has them: its gold, its raid warning's red).
Plans.COLOURS = {
    { key = "gold", rgb = { 1, 0.82, 0 } }, { key = "red", rgb = { 1, 0.15, 0.1 } },
    { key = "blue", rgb = { 0.25, 0.6, 1 } }, { key = "green", rgb = { 0.3, 0.95, 0.3 } },
    { key = "white", rgb = { 1, 1, 1 } }, { key = "purple", rgb = { 0.75, 0.45, 1 } },
}
Plans.POINTS = 160    -- a stroke's points at most
Plans.TAKE = 200      -- drawings taken from a plan shared at most
Plans.PARTS = 20      -- parts of a plan shared at most
Plans.BLOCK = 2800    -- bytes of rows in a part, unpacked
Plans.TEXT = {
    first = "My markers",
    newName = "Sketch %d", -- (a plan is a sketch to players: Saneroki, 2026-11-15)
}

local colours = {}
for _, colour in ipairs(Plans.COLOURS) do colours[colour.key] = colour end

-- The colour of a key (gold for one not known).
function Plans.Colour(key)
    return (colours[key] or Plans.COLOURS[1]).rgb
end

local function Store()
    local store = ns.store
    if type(store.plans) ~= "table" then store.plans = {} end
    if type(store.drawings) ~= "table" then store.drawings = {} end
    return store
end

-- A new number for a plan, a drawing or a marker, from the store's counter of that name.
local function Number(counter)
    local store = Store()
    store[counter] = (tonumber(store[counter]) or 0) + 1
    return store[counter]
end

function Plans.List()
    local store = Store()
    if #store.plans == 0 then
        store.plans[1] = { id = Number("planNext"), name = Plans.TEXT.first, shown = true }
        store.activePlan = store.plans[1].id
    end
    return store.plans
end

function Plans.Get(id)
    for _, plan in ipairs(Plans.List()) do
        if plan.id == id then return plan end
    end
    return nil
end

-- The plan a marker or a drawing is in: its own, else the first (markers put before plans came).
function Plans.Of(thing)
    return thing and thing.plan and Plans.Get(thing.plan) or Plans.List()[1]
end

function Plans.Active()
    local store = Store()
    return Plans.Get(store.activePlan) or Plans.List()[1]
end

-- What a change to plans, markers or drawings asks: the markers' pins made anew, the map drawn again.
local function Changed()
    if ns.Markers and ns.Markers.Stale then ns.Markers.Stale() end
    if ns.Canvas and ns.Canvas.Refresh then ns.Canvas.Refresh() end
    if ns.Draw and ns.Draw.Changed then ns.Draw.Changed() end
end
Plans.Changed = Changed

function Plans.SetActive(plan)
    if not plan then return end
    Store().activePlan = plan.id
    if not plan.shown then Plans.Show(plan, true) end
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

function Plans.New(name)
    local plans = Plans.List()
    local id = Number("planNext")
    local plan = { id = id, name = (name and name ~= "") and name or Plans.TEXT.newName:format(#plans + 1), shown = true }
    plans[#plans + 1] = plan
    Plans.SetActive(plan)
    return plan
end

function Plans.Rename(plan, name)
    if plan and type(name) == "string" and name:match("%S") then plan.name = name:sub(1, 60) end
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

function Plans.Show(plan, on)
    if not plan then return end
    plan.shown = on and true or false
    Changed()
end

function Plans.Visible(id)
    local plan = id and Plans.Get(id) or Plans.List()[1]
    return plan == nil or plan.shown ~= false
end

-- A plan away, its markers and drawings with it; the first stays (one is always there).
function Plans.Remove(plan)
    local plans = Plans.List()
    if not plan then return end
    local first = plans[1] == plan
    local markers = ns.Markers.List()
    for index = #markers, 1, -1 do
        local marker = markers[index]
        if Plans.Of(marker) == plan then table.remove(markers, index) end
    end
    local drawings = Plans.Drawings()
    for index = #drawings, 1, -1 do
        if Plans.Of(drawings[index]) == plan then table.remove(drawings, index) end
    end
    if not first then
        for index = #plans, 1, -1 do
            if plans[index] == plan then table.remove(plans, index) end
        end
    end
    if Store().activePlan == plan.id and not first then Store().activePlan = plans[1].id end
    Changed()
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

-------------------------------------------------------------------------------
--  Drawings
-------------------------------------------------------------------------------
function Plans.Drawings()
    return Store().drawings
end

-- A drawing made (Draw.lua): kept in the active plan, its points to four places.
function Plans.Add(drawing)
    local points = {}
    for index, value in ipairs(drawing.points) do points[index] = math.floor(value * 10000 + 0.5) / 10000 end
    local kept = { id = Number("drawingNext"), plan = drawing.plan or Plans.Active().id, map = drawing.map,
                   kind = drawing.kind, colour = drawing.colour, width = drawing.width, points = points,
                   text = drawing.text }
    local drawings = Plans.Drawings()
    drawings[#drawings + 1] = kept
    Changed()
    return kept
end

function Plans.Erase(drawing)
    local drawings = Plans.Drawings()
    for index = #drawings, 1, -1 do
        if drawings[index] == drawing then table.remove(drawings, index) end
    end
    Changed()
end

-- The newest drawing of the active plan away; false where it has none.
function Plans.Undo()
    local plan, drawings = Plans.Active(), Plans.Drawings()
    for index = #drawings, 1, -1 do
        if Plans.Of(drawings[index]) == plan then
            table.remove(drawings, index)
            Changed()
            return true
        end
    end
    return false
end

-- Every drawing of the active plan on a map away; how many went.
function Plans.Clear(map)
    local plan, drawings, count = Plans.Active(), Plans.Drawings(), 0
    for index = #drawings, 1, -1 do
        local drawing = drawings[index]
        if drawing.map == map and Plans.Of(drawing) == plan then
            table.remove(drawings, index)
            count = count + 1
        end
    end
    if count > 0 then Changed() end
    return count
end

-- What a plan holds: its markers and its drawings.
function Plans.Holds(plan)
    local markers, drawings = {}, {}
    for _, marker in ipairs(ns.Markers.List()) do
        if Plans.Of(marker) == plan then markers[#markers + 1] = marker end
    end
    for _, drawing in ipairs(Plans.Drawings()) do
        if Plans.Of(drawing) == plan then drawings[#drawings + 1] = drawing end
    end
    return markers, drawings
end

-------------------------------------------------------------------------------
--  Sharing a plan
-------------------------------------------------------------------------------
local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

-- A coordinate as three letters in base 36 ((value + 1) * 10000, so from -1 to 3.66 on its map), and back.
local function Pack(value)
    local n = math.max(0, math.min(46655, math.floor((value + 1) * 10000 + 0.5)))
    local a, b, c = math.floor(n / 1296), math.floor(n / 36) % 36, n % 36
    return DIGITS:sub(a + 1, a + 1) .. DIGITS:sub(b + 1, b + 1) .. DIGITS:sub(c + 1, c + 1)
end

local function Unpack(text)
    if #text ~= 3 then return nil end
    local n = 0
    for index = 1, 3 do
        local digit = DIGITS:find(text:sub(index, index), 1, true)
        if not digit then return nil end
        n = n * 36 + digit - 1
    end
    return n / 10000 - 1
end
Plans.Pack, Plans.Unpack = Pack, Unpack

local function Clean(text, most)
    text = tostring(text or ""):gsub("[%z\001-\009\011-\031]", "")
    if most and #text > most then text = text:sub(1, most) end
    return text
end

-- A map on the wire: a zone's number, or a dungeon's floor of Core's data ("<instance>:<floor>").
local function MapOf(text)
    local number = tonumber(text)
    if number and number > 0 then return math.floor(number) end
    if type(text) == "string" and text:match("^%d+:%d+$") then return text end
    return nil
end
Plans.MapOf = MapOf

local function Origin(thing, letter)
    thing.origin = thing.origin or ((Core.charKey or "?") .. ":" .. letter .. tostring(thing.id))
    return thing.origin
end

local function DrawingRow(drawing)
    local packed = {}
    for index, value in ipairs(drawing.points) do packed[index] = Pack(value) end
    return table.concat({ "d", Clean(Origin(drawing, "d"), 80), tostring(drawing.map), drawing.kind or "line",
        drawing.colour or "gold", tostring(drawing.width == 2 and 2 or 1), table.concat(packed),
        Clean(drawing.text, 80) }, "\031")
end

local stamp = 0 -- shares sent since the login

-- The whole plan to a channel of the wire (WHISPER: to the player named target), in parts of Plans.BLOCK bytes; how
-- many parts went (0: none, no channel).
function Plans.Share(plan, channel, target)
    if not plan or not channel then return 0 end
    local markers, drawings = Plans.Holds(plan)
    local rows = {}
    for _, marker in ipairs(markers) do rows[#rows + 1] = "m\031" .. ns.Markers.Row(marker) end
    for _, drawing in ipairs(drawings) do rows[#rows + 1] = DrawingRow(drawing) end
    -- the rows into parts
    local parts, part, size = {}, {}, 0
    for _, row in ipairs(rows) do
        if size > 0 and size + #row > Plans.BLOCK then
            parts[#parts + 1] = part
            part, size = {}, 0
        end
        part[#part + 1] = row
        size = size + #row + 1
    end
    parts[#parts + 1] = part
    if #parts > Plans.PARTS then return 0 end
    local origin, sent = Clean(Origin(plan, "p"), 80), 0
    stamp = stamp + 1 -- (each share its own: parts of two shares of one plan are never put together)
    local share = tostring(Core.Ask(GetServerTime) or 0) .. "." .. stamp
    for index, each in ipairs(parts) do
        local head = table.concat({ "2", table.concat({ origin, Clean(plan.name, 60), index, #parts, share }, "\031") },
            "\030")
        local text = #each > 0 and head .. "\030" .. table.concat(each, "\030") or head
        if Core.Wire.SendBlock(ns.Markers.KIND, text, channel, target) then sent = sent + 1 end
    end
    return sent
end

-- A drawing's row read: its fields checked (a known kind, a map, two points at least, Plans.POINTS at most).
local function ReadDrawing(fields)
    local origin, map, kind, colour, width, points = fields[2], MapOf(fields[3]), fields[4], fields[5], fields[6], fields[7]
    if not (origin and origin ~= "" and map and Plans.KINDS[kind] and type(points) == "string") then return nil end
    if #points % 6 ~= 0 or #points < (Plans.ONE[kind] and 6 or 12) or #points > Plans.POINTS * 6 then return nil end
    local words = kind == "text" and Clean(fields[8], 80) or nil
    if kind == "text" and words == "" then return nil end
    local list = {}
    for index = 1, #points, 3 do
        local value = Unpack(points:sub(index, index + 2))
        if not value then return nil end
        list[#list + 1] = value
    end
    return { origin = Clean(origin, 80), map = map, kind = kind, colour = colours[colour] and colour or "gold",
             width = width == "2" and 2 or 1, points = list, text = words }
end

local gathering, gathered = {}, 0 -- [sender \t origin \t share] = the parts heard of a plan: { name, parts, got }
Plans.GATHERING = 20 -- plans being put together at once at most (more: the oldest let go, all of them)

-- A block of a plan heard: its part kept until all its parts are there, then the share: { sender, plan = { origin,
-- name }, rows (markers, as Markers.Read gives them), drawings }; nil meanwhile, or for a block off its shape.
function Plans.Read(sender, text)
    local head, rest = tostring(text or ""):match("^2\030([^\030]*)(.*)$")
    if not head then return nil end
    local origin, name, part, parts, stamped = head:match("^(.-)\031(.-)\031(%d+)\031(%d+)\031([%d%.]+)$")
    part, parts = tonumber(part), tonumber(parts)
    if not (origin and origin ~= "" and part and parts and parts >= 1 and parts <= Plans.PARTS and part >= 1
            and part <= parts) then
        return nil
    end
    local key = tostring(sender) .. "\t" .. origin .. "\t" .. stamped
    local held = gathering[key]
    if not held or held.parts ~= parts then
        if gathered >= Plans.GATHERING then
            wipe(gathering)
            gathered = 0
        end
        held = { name = Clean(name, 60), parts = parts, got = {}, count = 0 }
        gathering[key] = held
        gathered = gathered + 1
    end
    if not held.got[part] then
        held.got[part] = rest:sub(2) -- (its rows, without the cut after the head)
        held.count = held.count + 1
    end
    if held.count < parts then return nil end
    gathering[key] = nil
    gathered = math.max(0, gathered - 1)
    local share = { sender = tostring(sender or "?"), plan = { origin = Clean(origin, 80), name = held.name },
                    rows = {}, drawings = {} }
    for index = 1, parts do
        for row in ((held.got[index] or "") .. "\030"):gmatch("(.-)\030") do
            local kind = row:sub(1, 2)
            if kind == "m\031" and #share.rows < ns.Markers.TAKE then
                local marker = ns.Markers.ReadRow(row:sub(3))
                if marker then share.rows[#share.rows + 1] = marker end
            elseif kind == "d\031" and #share.drawings < Plans.TAKE then
                local fields = {}
                for field in (row .. "\031"):gmatch("(.-)\031") do fields[#fields + 1] = field end
                local drawing = ReadDrawing(fields)
                if drawing then share.drawings[#share.drawings + 1] = drawing end
            end
        end
    end
    return share
end

-- A plan shared kept: the plan of the same origin emptied and filled anew (its maker shared it again), else a new one,
-- shown, from its sender.
function Plans.Keep(share)
    local plans = Plans.List()
    local plan
    for _, each in ipairs(plans) do
        if each.origin == share.plan.origin then plan = each end
    end
    if plan then
        local markers, drawings = ns.Markers.List(), Plans.Drawings()
        for index = #markers, 1, -1 do
            if Plans.Of(markers[index]) == plan then table.remove(markers, index) end
        end
        for index = #drawings, 1, -1 do
            if Plans.Of(drawings[index]) == plan then table.remove(drawings, index) end
        end
    else
        plan = { id = Number("planNext"), origin = share.plan.origin, shown = true }
        plans[#plans + 1] = plan
    end
    plan.name, plan.from, plan.shown = share.plan.name ~= "" and share.plan.name or Plans.TEXT.first, share.sender, true
    local markers = ns.Markers.List()
    for _, row in ipairs(share.rows) do
        markers[#markers + 1] = { id = Number("markerNext"), plan = plan.id, origin = row.origin, from = share.sender,
                                  map = row.map, x = row.x, y = row.y, icon = row.icon, title = row.title,
                                  text = row.text, made = Core.Ask(GetServerTime) }
    end
    local drawings = Plans.Drawings()
    for _, drawing in ipairs(share.drawings) do
        drawings[#drawings + 1] = { id = Number("drawingNext"), plan = plan.id, origin = drawing.origin,
                                    map = drawing.map, kind = drawing.kind, colour = drawing.colour,
                                    width = drawing.width, points = drawing.points }
    end
    Changed()
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
    return plan
end
