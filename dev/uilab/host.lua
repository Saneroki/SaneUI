-- The interface lab's host: runs Sane UI's Lua under Lua 5.1 as the game runs it, with the lab's stand-in for the
-- game's API (dev/uilab/lab/), and talks with the lab's server (dev/tools/ui-lab) a JSON line at a time on its
-- standard input and output. The server starts it again for a reload.
--   lua5.1 dev/uilab/host.lua <Sane UI's folder>
local ROOT = assert(arg[1], "the project's folder")
package.path = ROOT .. "/dev/uilab/?.lua;" .. package.path
local json = require("json")
local out = io.stdout

local Lab = { root = ROOT }
Lab.files = {}             -- the files the lab read for this run: the server watches them

function Lab.Watch(path)
    for _, p in ipairs(Lab.files) do if p == path then return end end
    Lab.files[#Lab.files + 1] = path
end

-- A question to the server in the middle of the work (a font's widths, an item, the client's tables).
function Lab.Ask(t)
    out:write(json.encode(t), "\n")
    out:flush()
    local line = io.read("*l")
    if not line then os.exit(0) end
    return json.decode(line)
end

Lab.docs = require("docs")(ROOT)
local function part(name) require("lab." .. name)(Lab) end
part("core")
part("game")        -- Lab.G first: the kinds' methods and the parts below put things into it
part("kinds")
part("layout")
part("text")
part("regions")
part("frames")
part("edit")
part("messages")
part("tooltip")
part("anim")
part("templates")
part("xmlui")
part("input")
part("render")

local G = Lab.G
local S = Lab.S

-- Atlases and file IDs, as the server finds them in the game's lists.
local atlasCache, idCache = {}, {}
function Lab.Atlas(name)
    if type(name) ~= "string" then return nil end
    local a = atlasCache[name]
    if a == nil then
        local r = Lab.Ask({ need = "atlas", name = name })
        a = r and r.ok and { file = r.file, w = r.w, h = r.h, l = r.l, r = r.r, t = r.t, b = r.b, tileH = r.tileH, tileV = r.tileV } or false
        atlasCache[name] = a
    end
    return a or nil
end
function Lab.FileOfID(id)
    local p = idCache[id]
    if p == nil then
        local r = Lab.Ask({ need = "fileid", id = id })
        p = r and r.ok and r.path or false
        idCache[id] = p
    end
    return p or nil
end

-- The screen ------------------------------------------------------------------------------------------------------------------
Lab.screen = { pw = 3840, ph = 2160, scale = 0.65 }
local function screen(pw, ph, scale)
    Lab.screen.pw, Lab.screen.ph, Lab.screen.scale = pw, ph, scale
    Lab.SH = 768
    Lab.SW = 768 * pw / ph
    if G.UIParent then
        S[G.UIParent].scale = scale
        Lab.cvars.uiScale = tostring(scale)
    end
    Lab.Touch()
end

-- The frames the game has before any addon: the world and UIParent over it, the tooltip, a chat frame that is not
-- drawn (print's lines go to the page's log).
local function gameFrames()
    local world = Lab.New("Frame", { name = "WorldFrame", shown = true, children = {}, regions = {}, strata = "WORLD",
        level = 0, scripts = {}, events = {}, screen = true })
    Lab.frames[#Lab.frames + 1] = world
    local ui = Lab.New("Frame", { name = "UIParent", shown = true, children = {}, regions = {}, strata = "MEDIUM",
        level = 0, scripts = {}, events = {}, screen = true, scale = Lab.screen.scale })
    Lab.frames[#Lab.frames + 1] = ui
    G.WorldFrame, G.UIParent = world, ui
    local tip = Lab.CreateFrame("GameTooltip", "GameTooltip", ui)
    S[tip].strata = "TOOLTIP"
    G.ItemRefTooltip = Lab.CreateFrame("GameTooltip", "ItemRefTooltip", ui)
    local chat = Lab.CreateFrame("ScrollingMessageFrame", "ChatFrame1", ui)
    S[chat].shown = false
    Lab.labChat = chat
    G.DEFAULT_CHAT_FRAME, G.SELECTED_CHAT_FRAME = chat, chat
    G.GameTooltip_SetDefaultAnchor = function(tooltip, parent)
        tooltip:SetOwner(parent, "ANCHOR_NONE")
        tooltip:SetPoint("BOTTOMRIGHT", ui, "BOTTOMRIGHT", -13, 64)
    end
    G.GameTooltip_Hide = function() G.GameTooltip:Hide() end
    -- Of the game's own windows the lab has none (bags, the micro menu): what Blizzard's shared code calls of them
    -- does nothing.
    G.CloseAllBags = function() end
    G.UpdateMicroButtons = function() end
end

-- Saved variables: kept by the server between runs, as the game keeps them in WTF.
local saved = {}
local savedNames = {}      -- [name] = true for every saved variable an addon declared
local function serialize(v, depth, seen)
    depth = depth or 0
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t ~= "table" then return "nil" end
    seen = seen or {}
    if seen[v] or depth > 40 then return "nil" end
    seen[v] = true
    local parts = {}
    for k, x in pairs(v) do
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then key = k
        elseif type(k) == "string" or type(k) == "number" or type(k) == "boolean" then key = "[" .. serialize(k) .. "]" end
        local val = serialize(x, depth + 1, seen)
        if key and val ~= "nil" then parts[#parts + 1] = key .. "=" .. val end
    end
    seen[v] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end
Lab.Serialize = serialize

-- Addons ------------------------------------------------------------------------------------------------------------------------
local function runFile(path, addon, ns)
    local chunk, err = loadfile(path)
    Lab.Watch(path)
    if not chunk then
        Lab.Note("error", (tostring(err):gsub(ROOT .. "/", "")))
        return false
    end
    setfenv(chunk, G)
    Lab.Call(chunk, addon, ns)
    return true
end

local function addonLoaded(name)
    local a = Lab.addons[name]
    for v in pairs(a.saved or {}) do
        local src = saved[v]
        if src then
            local f = loadstring("return " .. src)
            local ok, value = pcall(f)
            if ok then G[v] = value end
        end
    end
    a.loaded = true
    Lab.Fire("ADDON_LOADED", name)
end

local function newAddon(name, fields)
    local a = Lab.addons[name]
    if a then return a end
    a = { name = name, fields = fields or {}, ns = {}, saved = {}, deps = {} }
    Lab.addons[name] = a
    Lab.addonOrder[#Lab.addonOrder + 1] = a
    return a
end

-- Sane UI's Core catches its errors and those of its modules (its guards) and keeps them in its error log
-- (/sane errors): the lab shows each one of this run as an error, with the place the log has for it.
local function coreErrors()
    local Core = rawget(G, "SaneUI") and G.SaneUI.Core
    if type(Core) ~= "table" or type(Core.NoteError) ~= "function" then return end
    local function show(label, text)
        text = tostring(text):gsub(ROOT .. "/", "")
        local first, rest = text:match("^([^\n]*)\n?(.*)$")
        Lab.Note("error", "Sane UI caught (" .. tostring(label) .. "): " .. first, { stack = rest ~= "" and rest or nil })
    end
    for _, e in ipairs(Core.log or {}) do show(e.label, e.text) end
    local note = Core.NoteError
    Core.NoteError = function(label, text, ...)
        show(label, text)
        return note(label, text, ...)
    end
end

-- An addon from its TOC, as the game reads it: its fields, its files in order (Lua, and XML with the Lua files
-- its <Script>s name), its saved variables.
local function loadTOC(path)
    local full = path:sub(1, 1) == "/" and path or (ROOT .. "/" .. path)
    local f = io.open(full)
    if not f then Lab.Note("error", "no TOC at " .. path) return end
    Lab.Watch(full)
    local folder = full:match("^(.*)/[^/]+$")
    local name = full:match("([^/]+)%.toc$")
    local fields, files = {}, {}
    for line in f:lines() do
        line = line:gsub("\r$", "")
        local k, v = line:match("^##%s*([%w%-_]+)%s*:%s*(.-)%s*$")
        if k then fields[k] = v
        elseif not line:match("^#") and line:match("%S") then files[#files + 1] = line:match("^%s*(.-)%s*$") end
    end
    f:close()
    local a = newAddon(name, fields)
    for _, key in ipairs({ "SavedVariables", "SavedVariablesPerCharacter" }) do
        for v in (fields[key] or ""):gmatch("[^,%s]+") do a.saved[v] = true; savedNames[v] = true end
    end
    for _, file in ipairs(files) do
        local p = folder .. "/" .. file:gsub("\\", "/")
        if file:lower():match("%.lua$") then
            runFile(p, name, a.ns)
        elseif file:lower():match("%.xml$") then
            Lab.LoadXML(p, { addon = name, ns = a.ns, run = function(lua) runFile(lua, name, a.ns) end })
        end
    end
    if name == "SaneUI" then coreErrors() end   -- before its saved log is read: this run's errors only
    addonLoaded(name)
    return a.ns
end

-- What a scene file has besides the game's environment.
local logins = {}
local SceneAPI = {}
function SceneAPI.World(name) Lab.World.Load(name) end
function SceneAPI.TOC(path) return loadTOC(path) end
function SceneAPI.Addon(name, ...)
    local a = newAddon(name, { Title = name })
    for i = 1, select("#", ...) do
        local file = select(i, ...)
        local path = file:sub(1, 1) == "/" and file or (ROOT .. "/" .. file)
        if path:lower():match("%.xml$") then
            Lab.LoadXML(path, { addon = name, ns = a.ns, run = function(lua) runFile(lua, name, a.ns) end })
        else
            runFile(path, name, a.ns)
        end
    end
    return a.ns
end
function SceneAPI.Saved(name, ...)
    local a = newAddon(name, { Title = name })
    for i = 1, select("#", ...) do local v = select(i, ...); a.saved[v] = true; savedNames[v] = true end
end
function SceneAPI.Loaded(name) addonLoaded(name) end
function SceneAPI.OnLogin(fn) logins[#logins + 1] = fn end
function SceneAPI.Say(kind, from, text, channel) Lab.World.Chat(kind, from, text, channel) end
function SceneAPI.Fire(event, ...) Lab.Fire(event, ...) end
function SceneAPI.After(seconds, fn) G.C_Timer.After(seconds, fn) end
function SceneAPI.Note(text) Lab.Note("note", tostring(text)) end
function SceneAPI.Slash(line) Lab.Slash(line) end
function SceneAPI.Combat(on) Lab.world.combat = on and true or nil; Lab.Fire(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED") end
SceneAPI.world = function() return Lab.world end

local sceneEnv = setmetatable({ Lab = SceneAPI }, { __index = G, __newindex = G })

-- Starting: the game's frames, Blizzard's shared code, the world, the scene with its addons, then the login.
local function start(msg)
    local sc = msg.screen or {}
    screen(sc.pw or 3840, sc.ph or 2160, sc.scale or 0.65)
    Lab.startClock = os.time()
    saved = msg.saved or {}
    part("blizzard")
    gameFrames()
    part("world")
    Lab.World.Load(msg.world or "default")
    Lab.LoadBlizzard("game")
    Lab.Documented()
    if msg.scene then
        local path = ROOT .. "/" .. msg.scene
        local chunk, err = loadfile(path)
        Lab.Watch(path)
        if not chunk then
            Lab.Note("error", (tostring(err):gsub(ROOT .. "/", "")))
        else
            setfenv(chunk, sceneEnv)
            Lab.Call(chunk)
        end
    end
    for _, a in ipairs(Lab.addonOrder) do
        if not a.loaded then addonLoaded(a.name) end
    end
    Lab.loggedIn = true
    Lab.Fire("PLAYER_LOGIN")
    Lab.Fire("PLAYER_ENTERING_WORLD", not msg.reload, msg.reload and true or false)
    Lab.Fire("EDIT_MODE_LAYOUTS_UPDATED", Lab.EditModeLayouts(), true)   -- the account's layouts, as the login sends them
    for _, fn in ipairs(logins) do Lab.Call(fn) end
    Lab.World.Start()
end

-- The frames under a point, top first, with what the lab knows of each (the page's inspector).
local function describe(o)
    local s = S[o]
    local l, b, w, h = Lab.Rect(o)
    local sc = Lab.EScale(o)
    local points = {}
    for _, p in ipairs(s.points or {}) do
        local rel = p.rel == Lab.SCREEN and "the screen" or (S[p.rel] and (S[p.rel].name or Lab.kinds.Object.methods.GetDebugName(p.rel))) or "?"
        points[#points + 1] = ("%s → %s %s (%g, %g)"):format(p.point, rel, p.relPoint, p.x, p.y)
    end
    local P = Lab.screen.ph / 768
    local d = { name = Lab.kinds.Object.methods.GetDebugName(o), kind = s.kind, at = s.at, points = points,
        px = l and { l * P, (Lab.SH - (b + h)) * P, w * P, h * P } or nil,
        size = l and { math.floor(w / sc * 10 + 0.5) / 10, math.floor(h / sc * 10 + 0.5) / 10 } or nil,
        scale = math.floor(sc * 1000 + 0.5) / 1000, shown = s.shown, visible = Lab.Visible(o) }
    if s.strata then d.strata, d.level, d.mouse = s.strata, s.level, s.mouse or s.motion or false end
    if s.layer then d.layer = s.layer .. " " .. (s.sub or 0) end
    if s.file then d.file = s.file end
    if s.color then d.color = s.color end
    if s.kind == "FontString" then d.text = s.text; d.font = { Lab.FontProps(o).file, Lab.FontProps(o).size } end
    return d
end

local function inspect(x, y)
    local p = 768 / Lab.screen.ph
    local ax, ay = x * p, Lab.SH - y * p
    local out = {}
    local order = Lab.FrameOrder()
    for i = #order, 1, -1 do
        local f = order[i]
        if Lab.Inside(f, ax, ay) and not S[f].screen then
            local d = describe(f)
            d.regions = {}
            for _, r in ipairs(S[f].regions) do
                local l, b, w, h = Lab.Rect(r)
                if S[r].shown and l and ax >= l and ax <= l + w and ay >= b and ay <= b + h then
                    d.regions[#d.regions + 1] = describe(r)
                end
            end
            out[#out + 1] = d
            if #out >= 12 then break end
        end
    end
    return out
end

-- /dump's view of a value.
local function dump(v, depth, seen)
    depth = depth or 0
    if type(v) == "string" then return string.format("%q", v) end
    if type(v) ~= "table" then return tostring(v) end
    if S[v] then return tostring(v) end
    seen = seen or {}
    if seen[v] then return "<seen>" end
    if depth > 2 then return "{...}" end
    seen[v] = true
    local parts, n = {}, 0
    for k, x in pairs(v) do
        n = n + 1
        if n > 40 then parts[#parts + 1] = "..." break end
        parts[#parts + 1] = string.rep("  ", depth + 1) .. "[" .. dump(k, 3) .. "] = " .. dump(x, depth + 1, seen)
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep("  ", depth) .. "}"
end

local function run(code)
    if code:match("^%s*/") then
        Lab.Slash(code:match("^%s*(.-)%s*$"))
        return
    end
    local chunk = loadstring("return " .. code, "console")
    if not chunk then
        local err
        chunk, err = loadstring(code, "console")
        if not chunk then Lab.Note("error", err) return end
    end
    setfenv(chunk, sceneEnv)
    local r = { Lab.Call(chunk) }
    if #r > 0 then
        local parts = {}
        for i = 1, table.maxn(r) do parts[i] = dump(r[i]) end
        Lab.Note("result", table.concat(parts, ", "))
    end
end

-- The answer to every message: what changed in the drawing, what the page should show in its log.
local function reply(extra)
    local changes, n = Lab.Render()
    local parts = {}
    for id, enc in pairs(changes) do parts[#parts + 1] = string.format("%q", id) .. ":" .. enc end
    local msgs = Lab.messages
    Lab.messages = {}
    local tail = {
        messages = msgs,
        reload = Lab.reload or nil,
        focus = Lab.focus and Lab.kinds.Object.methods.GetDebugName(Lab.focus) or nil,
        files = extra and extra.files or nil,
        inspect = extra and extra.inspect or nil,
        saved = extra and extra.saved or nil,
        people = extra and extra.people or nil,
        time = Lab.time,
    }
    if #msgs == 0 then tail.messages = nil end
    local t = json.encode(tail)
    out:write('{"changes":{', table.concat(parts, ","), "},", t:sub(2), "\n")
    out:flush()
end

-- The loop ------------------------------------------------------------------------------------------------------------------------
while true do
    local line = io.read("*l")
    if not line then break end
    local ok, msg = pcall(json.decode, line)
    if not ok then
        Lab.Note("error", "the lab's host could not read a message: " .. tostring(msg))
        reply()
    else
        local okRun, err = pcall(function()
            local op = msg.op
            if op == "start" then
                start(msg)
                local people = {}
                local w = Lab.world
                for _, list in ipairs({ w.guild and w.guild.members or {}, w.party or {}, w.others or {} }) do
                    for _, m in ipairs(list) do
                        local name = Lab.World.FullName(m)
                        local dup = false
                        for _, p in ipairs(people) do if p == name then dup = true end end
                        if not dup then people[#people + 1] = name end
                    end
                end
                reply({ files = Lab.files, people = people })
            elseif op == "frame" then
                for _, e in ipairs(msg.input or {}) do Lab.Input(e) end
                local dt = math.min(1, math.max(0, msg.dt or 0))
                Lab.time = Lab.time + dt
                Lab.TickTimers()
                Lab.World.Tick()
                Lab.TickAnimations(dt)
                local order = Lab.FrameOrder()
                for _, f in ipairs(order) do
                    if S[f].scripts.OnUpdate then Lab.Run(f, "OnUpdate", dt) end
                end
                reply()
            elseif op == "run" then
                run(msg.code or "")
                reply()
            elseif op == "server" then
                if msg.what == "chat" then
                    Lab.World.Chat(msg.kind or "SAY", msg.from, msg.text or "", msg.channel, msg.target)
                elseif msg.what == "event" then
                    if not Lab.KnownEvent(msg.name or "") then Lab.Note("warn", "the game has no event " .. tostring(msg.name))
                    else Lab.Fire(msg.name, unpack(msg.args or {})) end
                elseif msg.what == "replay" then
                    Lab.World.Start()
                elseif msg.what == "combat" then
                    SceneAPI.Combat(msg.on)
                end
                reply()
            elseif op == "inspect" then
                reply({ inspect = inspect(msg.x or 0, msg.y or 0) })
            elseif op == "screen" then
                screen(msg.pw, msg.ph, msg.scale)
                Lab.ResetDrawing()
                Lab.Fire("DISPLAY_SIZE_CHANGED")
                Lab.Fire("UI_SCALE_CHANGED")
                reply()
            elseif op == "logout" then
                Lab.Fire("PLAYER_LOGOUT")
                local keep = {}
                for v in pairs(savedNames) do
                    if G[v] ~= nil then keep[v] = serialize(G[v]) end
                end
                reply({ saved = keep })
            elseif op == "redraw" then
                Lab.ResetDrawing()
                reply()
            else
                reply()
            end
        end)
        if not okRun then
            Lab.Note("error", "the lab itself failed: " .. tostring(err):gsub(ROOT .. "/", ""))
            local okReply, e2 = pcall(reply)
            if not okReply then
                out:write(json.encode({ changes = json.object, messages = { { kind = "error", text = "the lab itself failed: " .. tostring(e2) } } }), "\n")
                out:flush()
            end
        end
    end
end
