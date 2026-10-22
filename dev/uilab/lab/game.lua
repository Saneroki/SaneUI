-- The game's global environment as the code sees it: Lua as the game gives it (no io, os, require; its extra
-- string, table and math functions; bit), time and timers, the screen, the mouse and keys, fonts, colours and
-- strings, addons and settings. What a player and the world are (units, the guild, chat, items) is the fake
-- server's (lab/world.lua).
return function(Lab)
    local S = Lab.S
    local G = {}
    Lab.G = G
    G._G = G

    -- Lua as the game has it -----------------------------------------------------------------------------------------
    for _, name in ipairs({ "assert", "error", "ipairs", "pairs", "next", "pcall", "select", "tonumber", "tostring",
        "type", "unpack", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable", "collectgarbage", "gcinfo",
        "newproxy" }) do
        G[name] = _G[name]
    end
    G.string, G.table, G.math, G.coroutine = string, table, math, coroutine
    G.xpcall = function(fn, handler, ...)
        local n, args = select("#", ...), { ... }
        return xpcall(function() return fn(unpack(args, 1, n)) end, handler)
    end
    G.loadstring = function(code, name)
        local f, err = loadstring(code, name)
        if f then setfenv(f, G) end
        return f, err
    end
    G.setfenv = function(f, env)
        if f == 0 then error("setfenv(0) is not allowed here", 2) end
        return setfenv(type(f) == "number" and f + 1 or f, env)
    end
    G.getfenv = function(f)
        if f == 0 or f == nil then return G end
        local env = getfenv(type(f) == "number" and f + 1 or f)
        if env == _G then return G end
        return env
    end
    G.date, G.time, G.difftime = os.date, os.time, os.difftime

    -- The game's extra string functions, on string itself so ("x"):trim() works as in the game.
    function string.trim(s, chars)
        if chars then
            local set = "[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]"
            return (s:gsub("^" .. set .. "+", ""):gsub(set .. "+$", ""))
        end
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    function string.split(sep, s, limit)
        local out, start = {}, 1
        local plain = #sep == 1
        while true do
            if limit and #out == limit - 1 then out[#out + 1] = s:sub(start); break end
            local a, b
            if plain then a = s:find(sep, start, true); b = a
            else a, b = s:find("[" .. sep:gsub("[%]%^%-%%]", "%%%0") .. "]", start) end
            if not a then out[#out + 1] = s:sub(start); break end
            out[#out + 1] = s:sub(start, a - 1)
            start = b + 1
        end
        return unpack(out)
    end
    function string.join(sep, ...) return table.concat({ ... }, sep) end
    function string.rtgsub(s, ...) return s:gsub(...) end
    G.strsplit, G.strjoin, G.strtrim = string.split, string.join, string.trim
    G.strconcat = function(...) return table.concat({ ... }) end
    G.strlen, G.strsub, G.strfind, G.strmatch, G.gsub, G.strrep = string.len, string.sub, string.find, string.match, string.gsub, string.rep
    G.strlower, G.strupper, G.strbyte, G.strchar, G.strrev, G.format, G.gmatch = string.lower, string.upper, string.byte, string.char, string.reverse, string.format, string.gmatch
    G.strgfind = string.gmatch
    G.strlenutf8 = function(s) return #(s:gsub("[\128-\191]", "")) end
    G.strcmputf8i = function(a, b) a, b = a:lower(), b:lower(); return a < b and -1 or a > b and 1 or 0 end
    G.strsplittable = function(sep, s, limit) return { string.split(sep, s, limit) } end
    G.tostringall = function(...)
        local out = {}
        for i = 1, select("#", ...) do out[i] = tostring((select(i, ...))) end
        return unpack(out, 1, select("#", ...))
    end
    function table.wipe(t) for k in pairs(t) do t[k] = nil end return t end
    G.wipe, G.tinsert, G.tremove, G.sort, G.getn, G.foreach = table.wipe, table.insert, table.remove, table.sort, table.getn, table.foreach
    G.tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
    G.abs, G.floor, G.ceil, G.max, G.min, G.sqrt, G.exp, G.log, G.log10, G.frexp, G.ldexp, G.mod =
        math.abs, math.floor, math.ceil, math.max, math.min, math.sqrt, math.exp, math.log, math.log10, math.frexp, math.ldexp, math.fmod
    G.deg, G.rad, G.random, G.fastrandom, G.PI = math.deg, math.rad, math.random, math.random, math.pi
    G.sin = function(d) return math.sin(math.rad(d)) end
    G.cos = function(d) return math.cos(math.rad(d)) end
    G.tan = function(d) return math.tan(math.rad(d)) end
    G.asin = function(x) return math.deg(math.asin(x)) end
    G.acos = function(x) return math.deg(math.acos(x)) end
    G.atan = function(x) return math.deg(math.atan(x)) end
    G.atan2 = function(y, x) return math.deg(math.atan2(y, x)) end

    -- bit, as the game's (32 bits)
    local function bits(op)
        return function(a, b)
            a, b = a % 4294967296, b % 4294967296
            local r, p = 0, 1
            for _ = 1, 32 do
                local x, y = a % 2, b % 2
                if op(x, y) then r = r + p end
                a, b, p = (a - x) / 2, (b - y) / 2, p * 2
            end
            return r
        end
    end
    local band, bor, bxor = bits(function(x, y) return x == 1 and y == 1 end), bits(function(x, y) return x == 1 or y == 1 end), bits(function(x, y) return x ~= y end)
    local function many(f) return function(a, ...) for i = 1, select("#", ...) do a = f(a, (select(i, ...))) end return a end end
    G.bit = { band = many(band), bor = many(bor), bxor = many(bxor),
        bnot = function(a) return 4294967295 - a % 4294967296 end,
        lshift = function(a, n) return (a * 2 ^ n) % 4294967296 end,
        rshift = function(a, n) return math.floor((a % 4294967296) / 2 ^ n) end,
        arshift = function(a, n) a = a % 4294967296; if a >= 2147483648 then a = a - 4294967296 end return math.floor(a / 2 ^ n) % 4294967296 end,
        mod = math.fmod }

    -- Errors and safety ------------------------------------------------------------------------------------------------
    G.geterrorhandler = function() return Lab.handler or function(msg) Lab.Note("error", tostring(msg)) end end
    G.seterrorhandler = function(fn) Lab.handler = fn end
    G.debugstack = function(start, n1, n2) return debug.traceback("", (start or 1) + 1):gsub("^\n?stack traceback:\n", "") end
    G.debuglocals = function() return "" end
    G.debugprofilestop = function() return Lab.time * 1000 end
    G.debugprofilestart = function() end
    G.GetTimePreciseSec = function() return Lab.time end
    G.issecure = function() return false end
    G.issecurevariable = function() return true, nil end
    G.issecretvalue = function() return false end
    G.issecrettable = function() return false end
    G.canaccessvalue = function() return true end
    G.canaccesstable = function() return true end
    G.forceinsecure = function() end
    G.securecall = function(fn, ...)
        if type(fn) == "string" then fn = G[fn] end
        return Lab.Call(fn, ...)
    end
    G.securecallfunction = G.securecall
    G.secureexecuterange = function(t, fn, ...)
        for k, v in pairs(t) do Lab.Call(fn, k, v, ...) end
    end
    G.hooksecurefunc = function(t, name, fn)
        if type(t) ~= "table" then t, name, fn = G, t, name end
        local old = t[name]
        if type(old) ~= "function" then error("hooksecurefunc(): " .. tostring(name) .. " is not a function", 2) end
        t[name] = function(...)
            local r = { old(...) }
            Lab.Call(fn, ...)
            return unpack(r, 1, table.maxn(r))
        end
    end
    G.InCombatLockdown = function() return Lab.world.combat or false end
    G.GetCurrentEnvironment = function() return G end
    G.SwapToGlobalEnvironment = function() end

    -- Time and timers ----------------------------------------------------------------------------------------------------
    Lab.time = 0
    Lab.timers = {}
    G.GetTime = function() return 1000 + Lab.time end
    G.GetServerTime = function() return Lab.startClock + math.floor(Lab.time) end
    G.GetFramerate = function() return 60 end
    G.C_DateAndTime = setmetatable({
        GetServerTimeLocal = function() return Lab.startClock + math.floor(Lab.time) end,
        GetCurrentCalendarTime = function()
            local t = os.date("*t", Lab.startClock + math.floor(Lab.time))
            return { year = t.year, month = t.month, monthDay = t.day, weekday = t.wday, hour = t.hour, minute = t.min }
        end,
    }, {})
    local function timer(seconds, fn, times)
        if type(fn) ~= "function" and not (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call) then
            error("C_Timer: callback must be a function", 3)
        end
        local t = { at = Lab.time + math.max(0, seconds or 0), every = seconds, fn = fn, times = times }
        local handle = {}
        function handle:Cancel() t.cancelled = true end
        function handle:IsCancelled() return t.cancelled or false end
        function handle:Invoke(...) return fn(handle, ...) end
        t.handle = handle
        Lab.timers[#Lab.timers + 1] = t
        return handle, t
    end
    G.C_Timer = {
        After = function(seconds, fn) local _, t = timer(seconds, fn); t.plain = true end,
        NewTimer = function(seconds, fn) return (timer(seconds, fn, 1)) end,
        NewTicker = function(seconds, fn, n) return (timer(seconds, fn, n or math.huge)) end,
    }
    function Lab.TickTimers()
        local due = {}
        for _, t in ipairs(Lab.timers) do
            if not t.cancelled and t.at <= Lab.time then due[#due + 1] = t end
        end
        for _, t in ipairs(due) do
            if not t.cancelled then
                if t.plain then
                    t.cancelled = true
                    Lab.Call(t.fn)
                else
                    t.times = t.times - 1
                    if t.times <= 0 then t.cancelled = true else t.at = t.at + math.max(0.001, t.every) end
                    Lab.Call(t.fn, t.handle)
                end
            end
        end
        local keep = {}
        for _, t in ipairs(Lab.timers) do if not t.cancelled then keep[#keep + 1] = t end end
        Lab.timers = keep
    end

    -- Frames and fonts -----------------------------------------------------------------------------------------------------
    G.CreateFrame = function(kind, name, parent, template, id) return Lab.CreateFrame(kind, name, parent, template, id) end
    G.CreateFont = function(name)
        if type(name) ~= "string" then error("CreateFont(): name must be a string", 2) end
        if Lab.named[name] then return Lab.named[name] end
        return Lab.NewFont(name)
    end
    G.GetFonts = function()
        local out = {}
        for name, o in pairs(Lab.named) do if S[o].kind == "Font" then out[#out + 1] = name end end
        return out
    end
    G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    G.UNIT_NAME_FONT = "Fonts\\FRIZQT__.TTF"
    G.DAMAGE_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    G.NAMEPLATE_FONT = "Fonts\\FRIZQT__.TTF"

    -- The screen, the mouse, the keys -------------------------------------------------------------------------------------
    Lab.mouse = { x = 0, y = 0, buttons = {}, mods = {} }
    G.GetCursorPosition = function() return Lab.mouse.x, Lab.mouse.y end
    G.GetScaledCursorPosition = function()
        local sc = S[G.UIParent].scale
        return Lab.mouse.x / sc, Lab.mouse.y / sc
    end
    G.GetMouseFoci = function() return { Lab.focus } end
    G.GetMouseFocus = nil
    G.GetScreenWidth = function() return Lab.SW / S[G.UIParent].scale end
    G.GetScreenHeight = function() return Lab.SH / S[G.UIParent].scale end
    G.GetPhysicalScreenSize = function() return Lab.screen.pw, Lab.screen.ph end
    G.GetScreenDPIScale = function() return 1 end
    G.IsShiftKeyDown = function() return Lab.mouse.mods.shift or false end
    G.IsControlKeyDown = function() return Lab.mouse.mods.ctrl or false end
    G.IsAltKeyDown = function() return Lab.mouse.mods.alt or false end
    G.IsMetaKeyDown = function() return Lab.mouse.mods.meta or false end
    G.IsModifierKeyDown = function() local m = Lab.mouse.mods; return (m.shift or m.ctrl or m.alt) and true or false end
    G.IsLeftShiftKeyDown, G.IsRightShiftKeyDown = G.IsShiftKeyDown, G.IsShiftKeyDown
    G.IsLeftControlKeyDown, G.IsRightControlKeyDown = G.IsControlKeyDown, G.IsControlKeyDown
    G.IsLeftAltKeyDown, G.IsRightAltKeyDown = G.IsAltKeyDown, G.IsAltKeyDown
    G.IsMouseButtonDown = function(b) return Lab.mouse.buttons[b or "LeftButton"] or false end
    G.GetCurrentKeyBoardFocus = function() return Lab.editFocus end
    G.SetCursor = function() end
    G.ResetCursor = function() end
    G.GetCursorInfo = function() return nil end
    G.ClearCursor = function() end
    G.CursorHasItem = function() return false end

    -- Sounds, chat output, reload -------------------------------------------------------------------------------------------
    G.PlaySound = function(kit, channel) Lab.Note("sound", "PlaySound " .. tostring(kit)); return true, 1 end
    G.PlaySoundFile = function(file, channel) Lab.Note("sound", "PlaySoundFile " .. tostring(file)); return true, 1 end
    G.StopSound = function() end
    G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
        local text = table.concat(parts, " ")
        Lab.Note("print", text)
        local chat = rawget(G, "DEFAULT_CHAT_FRAME")
        if chat and chat ~= Lab.labChat and type(chat.AddMessage) == "function" then Lab.Call(chat.AddMessage, chat, text) end
    end
    G.ReloadUI = function() Lab.reload = true end
    G.C_UI = { Reload = G.ReloadUI }
    G.Screenshot = function() Lab.Note("note", "Screenshot()") end

    -- Special windows (Esc closes them) and the slash commands typed into the page's console.
    G.UISpecialFrames = {}
    G.CloseSpecialWindows = function()
        local closed = false
        for _, name in ipairs(G.UISpecialFrames) do
            local f = G[name]
            if f and S[f] and S[f].shown and Lab.Visible(f) then f:Hide(); closed = true end
        end
        return closed
    end
    G.SlashCmdList = {}
    G.hash_SlashCmdList = {}
    function Lab.Slash(line)
        local cmd, rest = line:match("^(/%S+)%s*(.-)$")
        if not cmd then return false end
        cmd = cmd:lower()
        if cmd == "/reload" or cmd == "/rl" then G.ReloadUI() return true end
        for key, fn in pairs(G.SlashCmdList) do
            local i = 1
            while true do
                local alias = rawget(G, "SLASH_" .. key .. i)
                if not alias then break end
                if alias:lower() == cmd then Lab.Call(fn, rest, nil) return true end
                i = i + 1
            end
        end
        Lab.Note("warn", "no slash command " .. cmd)
        return true
    end

    -- The game's version and addons ---------------------------------------------------------------------------------------
    G.WOW_PROJECT_ID, G.WOW_PROJECT_MAINLINE, G.WOW_PROJECT_CLASSIC, G.WOW_PROJECT_CAMELOT = 18, 1, 2, 18
    G.LE_EXPANSION_LEVEL_CURRENT, G.GetExpansionLevel = 0, function() return 0 end
    G.GetBuildInfo = function() return "1.60.1", "70245", "Oct 1 2026", 16001, "", "", 16001 end
    G.GetLocale = function() return "enUS" end
    G.IsLoggedIn = function() return Lab.loggedIn or false end
    G.IsTestBuild, G.IsPublicBuild, G.IsBetaBuild = function() return false end, function() return true end, function() return false end
    G.Is64BitClient = function() return true end
    G.IsMacClient, G.IsWindowsClient, G.IsLinuxClient = function() return false end, function() return true end, function() return false end
    G.GetCVar = function(name) return Lab.cvars[name] end
    G.SetCVar = function(name, value) Lab.cvars[name] = value ~= nil and tostring(value) or nil; Lab.Fire("CVAR_UPDATE", name, value) return true end
    G.GetCVarBool = function(name) local v = Lab.cvars[name]; return v == "1" or v == "true" end
    G.GetCVarDefault = function(name) return Lab.cvarDefaults[name] end
    Lab.cvars = { scriptErrors = "1", uiScale = "1", useUiScale = "0", colorChatNamesByClass = "1", chatStyle = "im",
        whisperMode = "inline" }
    Lab.cvarDefaults = {}
    for k, v in pairs(Lab.cvars) do Lab.cvarDefaults[k] = v end
    G.C_CVar = { GetCVar = G.GetCVar, SetCVar = G.SetCVar, GetCVarBool = G.GetCVarBool, GetCVarDefault = G.GetCVarDefault,
        RegisterCVar = function(name, value) if Lab.cvars[name] == nil then Lab.cvars[name] = tostring(value) end end }

    Lab.addons = {}   -- [name] = { title, notes, fields = {}, loaded }
    local function addon(name)
        if type(name) == "number" then
            local i = 0
            for _, a in ipairs(Lab.addonOrder) do i = i + 1; if i == name then return a end end
            return nil
        end
        return Lab.addons[name]
    end
    Lab.addonOrder = {}
    G.C_AddOns = {
        GetAddOnMetadata = function(name, field)
            local a = addon(name)
            return a and a.fields[field] or nil
        end,
        IsAddOnLoaded = function(name) local a = addon(name); return a and a.loaded or false, a and a.loaded or false end,
        IsAddOnLoadOnDemand = function() return false end,
        DoesAddOnExist = function(name) return addon(name) ~= nil end,
        GetNumAddOns = function() return #Lab.addonOrder end,
        GetAddOnInfo = function(name)
            local a = addon(name)
            if not a then return nil end
            return a.name, a.fields.Title or a.name, a.fields.Notes, true, a.loaded and "" or "DISABLED", "INSECURE", false
        end,
        GetAddOnEnableState = function(name) return addon(name) and 2 or 0 end,
        LoadAddOn = function(name) local a = addon(name); return a and a.loaded or false, a and nil or "MISSING" end,
        EnableAddOn = function() end,
        DisableAddOn = function() end,
        GetAddOnDependencies = function(name) local a = addon(name); return unpack(a and a.deps or {}) end,
        IsAddOnDefaultEnabled = function() return true end,
    }
    G.GetAddOnMetadata = G.C_AddOns.GetAddOnMetadata
    G.IsAddOnLoaded = G.C_AddOns.IsAddOnLoaded

    -- Colours, strings, enums and constants ------------------------------------------------------------------------------------
    -- Enum and Constants from Blizzard's documentation; the client's named colours and global strings where the
    -- lab's server found the client's tables (lab.Client), else the few the lab keeps itself.
    G.Enum = {}
    for name, e in pairs(Lab.docs.enums) do G.Enum[name] = e end
    G.Constants = {}
    for name, c in pairs(Lab.docs.constants) do G.Constants[name] = c end
    G.Constants.CharacterNameSeparatorConsts = G.Constants.CharacterNameSeparatorConsts or { CHARACTERNAME_SURNAME_SEPARATOR = " " }

    Lab.extraEvents = {}
    for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD", "VARIABLES_LOADED",
        "SPELLS_CHANGED", "UPDATE_BINDINGS", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "CVAR_UPDATE" }) do
        Lab.extraEvents[e] = true
    end
end
