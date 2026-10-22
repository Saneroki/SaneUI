-- The lab's core: its widgets as objects the game's code holds, their kinds and methods, the scripts run as the
-- game runs them (an error is caught, shown, and stops nothing else), and what the lab tells the page.
return function(Lab)
    local S = setmetatable({}, { __mode = "k" })  -- [object] = its state: kept apart from the fields code sets on it
    Lab.S = S
    Lab.frames = {}                                -- every frame, in the order made
    Lab.named = {}                                 -- [global name] = object
    Lab.counter = 0
    Lab.changed = true                             -- something to draw anew
    Lab.messages = {}                              -- what goes to the page with the next answer: prints, errors, notes

    function Lab.Touch()
        Lab.changed = true
        Lab.rects = nil
    end

    -- Where the game's code that called the lab stands: file and line, the lab's own files skipped.
    local labPath = Lab.root .. "/dev/uilab/"
    function Lab.Caller(level)
        level = level or 3
        while true do
            local info = debug.getinfo(level, "Sl")
            if not info then return "?" end
            local src = info.source or ""
            if src:sub(1, 1) == "@" and src:sub(2, #labPath + 1) ~= labPath then
                return Lab.Short(src:sub(2)) .. ":" .. (info.currentline or 0)
            elseif src:sub(1, 1) ~= "@" and src ~= "=[C]" then
                return (info.short_src or "?") .. ":" .. (info.currentline or 0)
            end
            level = level + 1
        end
    end

    function Lab.Short(path)
        if path:sub(1, #Lab.root + 1) == Lab.root .. "/" then return path:sub(#Lab.root + 2) end
        return path
    end

    function Lab.Note(kind, text, extra)
        local m = { kind = kind, text = text, at = Lab.time }
        if extra then for k, v in pairs(extra) do m[k] = v end end
        Lab.messages[#Lab.messages + 1] = m
    end

    local warned = {}
    function Lab.Warn(text)
        if warned[text] then return end
        warned[text] = true
        Lab.Note("warn", text, { where = Lab.Caller(4) })
    end

    -- Errors: kept with their stack (the lab's own lines left out) and told to the page; the game's code may
    -- have set an error handler of its own (seterrorhandler), which is called too, as the game calls it.
    local function stack(msg)
        local tb = debug.traceback("", 3)
        local lines = {}
        for line in tb:gmatch("[^\n]+") do
            if not line:find(labPath, 1, true) and not line:find("^stack traceback") and not line:find("%[C%]: in function 'xpcall'") then
                lines[#lines + 1] = (line:gsub("^%s+", ""):gsub(Lab.root .. "/", ""))
            end
        end
        return { msg = tostring(msg), stack = table.concat(lines, "\n") }
    end

    Lab.handler = nil   -- the game code's own (seterrorhandler)
    function Lab.Report(e)
        local msg = e.msg:gsub(Lab.root .. "/", "")
        if Lab.blizzardLoading then
            -- a script of Blizzard's own frames, made while its interface loads: it needs what the lab has not
            Lab.Note("lab", "Blizzard's interface in the lab: " .. msg, { stack = e.stack })
            return
        end
        Lab.Note("error", msg, { stack = e.stack })
        if Lab.handler then
            local ok = pcall(Lab.handler, e.msg)
            if not ok then Lab.Note("error", "the error handler of the game's code failed too") end
        end
    end

    -- Calls fn(...) as the game calls a script: an error in it is reported and returns nothing.
    local caught
    local function onError(msg) caught = stack(msg); return msg end
    local unpack = unpack
    function Lab.Call(fn, ...)
        local n = select("#", ...)
        local args = { ... }
        local result = { xpcall(function() return fn(unpack(args, 1, n)) end, onError) }
        if not result[1] then
            Lab.Report(caught)
            return
        end
        return unpack(result, 2, table.maxn(result))
    end

    -- Scripts ----------------------------------------------------------------------------------------------------
    -- A widget's script and the functions hooked to it (HookScript) run in turn; each one's error is its own.
    function Lab.Run(o, script, ...)
        local s = S[o]
        if not s or not s.scripts then return end
        local fn = s.scripts[script]
        if fn then Lab.Call(fn, o, ...) end
        local hooks = s.hooks and s.hooks[script]
        if hooks then
            for _, h in ipairs(hooks) do Lab.Call(h, o, ...) end
        end
    end

    function Lab.Has(o, script)
        local s = S[o]
        return s and s.scripts and (s.scripts[script] or (s.hooks and s.hooks[script])) and true or false
    end

    -- Kinds and their methods -------------------------------------------------------------------------------------
    -- Lab.kinds[name] = { parent = , methods = {}, docs = {doc tables}, scripts = {names} }. A method the game
    -- documents for the kind but the lab does not do yet is still there (code that asks whether it is there gets
    -- yes, as in the game), and says so when called.
    Lab.kinds = {}
    function Lab.Kind(name, parent, docs, scripts)
        local k = { name = name, parent = parent and Lab.kinds[parent], methods = {}, docs = docs or {}, scripts = {} }
        for _, sc in ipairs(scripts or {}) do k.scripts[sc:lower()] = sc end   -- the game takes any case
        Lab.kinds[name] = k
        return k.methods
    end

    local function documented(k, method)
        while k do
            for _, d in ipairs(k.docs) do
                local names = Lab.docs.widgets[d]
                if names and names[method] then return k.name end
            end
            k = k.parent
        end
    end

    local function lookup(k, method)
        while k do
            local m = k.methods[method]
            if m ~= nil then return m end
            k = k.parent
        end
    end

    -- What the game has but the lab does not do: told once, with the place of the code that wanted it.
    local missing = {}
    function Lab.Missing(text, level)
        if missing[text] then return end
        missing[text] = true
        -- while Blizzard's own interface loads, it is the lab's own business (its log's "the lab")
        Lab.Note(Lab.blizzardLoading and "lab" or "missing", text, { where = Lab.Caller(level or 4) })
    end
    Lab.meta = {}
    function Lab.Meta(kindName)
        if Lab.meta[kindName] then return Lab.meta[kindName] end
        local k = Lab.kinds[kindName]
        local cache = {}
        local mt = {
            __index = function(t, key)
                local m = cache[key]
                if m ~= nil then return m end
                m = lookup(k, key)
                if m == nil and type(key) == "string" then
                    local doc = documented(k, key)
                    if doc then
                        m = function()
                            local text = "the lab does not do " .. kindName .. ":" .. key .. "() yet (the game has it)"
                            Lab.Missing(text)
                        end
                    end
                end
                if m ~= nil then cache[key] = m end
                return m
            end,
            __tostring = function(t) return kindName .. ": " .. tostring(S[t] and S[t].name or "unnamed") end,
        }
        Lab.meta[kindName] = mt
        return mt
    end

    function Lab.Is(o, kindName)
        local s = S[o]
        if not s then return false end
        local k = Lab.kinds[s.kind]
        while k do
            if k.name == kindName then return true end
            k = k.parent
        end
        return false
    end

    -- The script's name as the kind has it (the game takes "OnGamepadStick" for "OnGamePadStick"), or false.
    function Lab.ScriptAllowed(o, script)
        if type(script) ~= "string" then return false end
        local k = Lab.kinds[S[o].kind]
        local low = script:lower()
        while k do
            if k.scripts[low] then return k.scripts[low] end
            k = k.parent
        end
        return false
    end

    -- SetScript and the rest, the same for frames, regions and animations: a script the kind does not have is an
    -- error, as in the game; HookScript on no script sets it.
    function Lab.ScriptMethods(M)
        local function canonical(self, name, method)
            local c = Lab.ScriptAllowed(self, name)
            if not c then
                error(("%s(): %s doesn't have a \"%s\" script"):format(method, S[self].kind, tostring(name)), 3)
            end
            return c
        end
        local function scripts(self)
            local s = S[self]
            s.scripts = s.scripts or {}
            return s
        end
        function M:SetScript(name, fn)
            name = canonical(self, name, "SetScript")
            if fn ~= nil and type(fn) ~= "function" then error("SetScript(): handler must be a function or nil", 2) end
            local s = scripts(self)
            s.scripts[name] = fn
            if s.hooks then s.hooks[name] = nil end
            Lab.Touch()
        end
        function M:GetScript(name)
            name = canonical(self, name, "GetScript")
            return scripts(self).scripts[name]
        end
        function M:HasScript(name) return Lab.ScriptAllowed(self, name) and true or false end
        function M:HookScript(name, fn)
            name = canonical(self, name, "HookScript")
            local s = scripts(self)
            if not s.scripts[name] then
                s.scripts[name] = fn
                return
            end
            s.hooks = s.hooks or {}
            s.hooks[name] = s.hooks[name] or {}
            table.insert(s.hooks[name], fn)
        end
    end

    -- A new object of a kind: its table (with the userdata the game's own objects carry at [0]) and its state.
    function Lab.New(kindName, state)
        Lab.counter = Lab.counter + 1
        local o = setmetatable({ [0] = newproxy(false) }, Lab.Meta(kindName))
        state.kind = kindName
        state.order = Lab.counter
        state.at = Lab.Caller(4)
        state.alpha = state.alpha or 1
        state.scale = state.scale or 1
        state.points = state.points or {}
        S[o] = state
        if state.name then
            Lab.named[state.name] = o
            Lab.G[state.name] = o
        end
        Lab.Touch()
        return o
    end

    -- Arguments checked as the game checks them: a wrong type is an error naming the method.
    function Lab.Check(value, kind, method, position, nilable)
        if value == nil and nilable then return end
        local t = type(value)
        if kind == "number" and t == "string" and tonumber(value) then return end
        if t ~= kind then
            error(("bad argument #%d to '%s' (%s expected, got %s)"):format(position, method, kind, t), 3)
        end
    end
end
