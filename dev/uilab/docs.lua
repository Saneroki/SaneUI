-- What the game's API has, read from Blizzard's own documentation of it (references/BlizzardInterfaceCode,
-- Blizzard_APIDocumentationGenerated): every widget's methods, every function of every namespace and of the
-- global one, the enumerations (Enum), the constants (Constants) and the events. The lab knows from it what
-- the game has that the lab does not do yet, and says so when code uses it, instead of letting it be nil.
return function(root)
    local folder = root .. "/references/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/"
    local found = {}
    local auto
    auto = setmetatable({}, { __index = function(t, k) local v = setmetatable({}, getmetatable(t)); rawset(t, k, v); return v end })
    local env = setmetatable({
        APIDocumentation = { AddDocumentationTable = function(_, t) found[#found + 1] = t end },
    }, { __index = function() return auto end })

    local list = io.popen('ls "' .. folder .. '"')
    for file in list:lines() do
        if file:match("%.lua$") then
            local chunk = loadfile(folder .. file)
            if chunk then
                setfenv(chunk, env)
                pcall(chunk)
            end
        end
    end
    list:close()

    local docs = { widgets = {}, namespaces = {}, globals = {}, enums = {}, constants = {}, events = {} }
    for _, t in ipairs(found) do
        if t.Type == "ScriptObject" then
            local names = docs.widgets[t.Name] or {}
            for _, f in ipairs(t.Functions or {}) do names[f.Name] = true end
            docs.widgets[t.Name] = names
        else
            local into = docs.globals
            if t.Namespace then
                into = docs.namespaces[t.Namespace] or {}
                docs.namespaces[t.Namespace] = into
            end
            for _, f in ipairs(t.Functions or {}) do into[f.Name] = true end
        end
        for _, e in ipairs(t.Events or {}) do
            if e.LiteralName then docs.events[e.LiteralName] = true end
        end
        for _, tab in ipairs(t.Tables or {}) do
            if tab.Type == "Enumeration" then
                local e = {}
                for _, f in ipairs(tab.Fields or {}) do e[f.Name] = f.EnumValue end
                docs.enums[tab.Name] = e
            elseif tab.Type == "Constants" then
                local c = {}
                for _, v in ipairs(tab.Values or {}) do c[v.Name] = v.Value end
                docs.constants[tab.Name] = c
            end
        end
    end
    return docs
end
