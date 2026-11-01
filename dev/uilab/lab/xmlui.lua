-- Frame XML: the game's <Ui> files read as the game reads them. Script and Include, fonts, and every frame,
-- region and animation in them: a virtual one becomes a template (CreateFrame's fourth argument, inherits=,
-- CreateTexture's), an intrinsic one a kind of its own (CreateFrame("EventFrame")), any other is made at once.
-- What a template holds is applied when it is used, as the game does: its inherits first, then its mixins, its
-- attributes and its parts (Size, Anchors, Layers, Frames, the button's textures and fonts, Scripts, KeyValues,
-- Animations). Anchors and masks are set when everything of the object being made is there (so relativeKey finds a
-- part made after the one anchored), then every OnLoad runs, children before their parents.
--   Lab.LoadXML(path, { addon =, ns =, run = function(luaPath), blizzard = true })
return function(Lab)
    local S = Lab.S
    local G = Lab.G
    local xml = require("xml")

    Lab.xmlTemplates = {}   -- [name] = { el =, file =, tag = }: the virtual elements read
    Lab.intrinsics = {}     -- [name in small letters] = { name =, kind = }: intrinsic frames, CreateFrame takes them

    -- Building: what waits for the object being made to be complete --------------------------------------------------
    local ctx
    function Lab.Building(fn, ...)
        if ctx then return fn(...) end
        local mine = { after = {}, loads = {} }
        ctx = mine
        local n = select("#", ...)
        local args = { ... }
        local r = { pcall(function() return fn(unpack(args, 1, n)) end) }
        ctx = nil
        for _, job in ipairs(mine.after) do Lab.Call(job) end
        for _, o in ipairs(mine.loads) do Lab.Run(o, "OnLoad") end
        if not r[1] then error(r[2], 0) end
        return unpack(r, 2, table.maxn(r))
    end
    local function later(job)
        if ctx then ctx.after[#ctx.after + 1] = job else Lab.Call(job) end
    end
    function Lab.Loaded(o)
        if ctx then ctx.loads[#ctx.loads + 1] = o else Lab.Run(o, "OnLoad") end
    end

    -- What the reader says: a problem in Sane UI's XML is a warning (an unknown script an error, as SetScript's),
    -- one in Blizzard's a line of the lab's own (Blizzard's XML is right for the game; the lab falls short).
    local told = {}
    local function tell(how, kind, text, at)
        local key = kind .. text .. (at or "")
        if told[key] then return end
        told[key] = true
        if how.blizzard then kind = "lab" end
        Lab.Note(kind, text, { where = at })
    end
    local function where(how, el) return Lab.Short(how.file) .. ":" .. (el.line or 0) end
    -- a part of the XML the game reads and the lab does not yet
    local function missing(how, el, what)
        tell(how, "missing", "the lab does not read " .. what .. " in XML yet", where(how, el))
    end

    -- A method as the game's XML calls it: the widget's own, never a mixin's of the same name.
    local function call(o, method, ...)
        local mt = getmetatable(o)
        local index = mt and mt.__index
        local m = type(index) == "table" and index[method]
        if type(m) ~= "function" then return nil end
        return m(o, ...)
    end

    -- A global by its name, with dots for fields (type="global" value="Settings.CategorySet.Game"), as the game reads it.
    local function global(name)
        local v = G
        for part in tostring(name):gmatch("[^%.]+") do
            if type(v) ~= "table" then return nil end
            v = v == G and rawget(G, part) or v[part]
        end
        if v == G then return nil end
        return v
    end

    local function bool(v) if v == "true" then return true elseif v == "false" then return false end end
    local function num(v) return v and tonumber(v) end
    local function upper(v) return v and v:upper() end
    -- A text attribute: a global string's name gives that string, as in the game; anything else is the text.
    local function words(v)
        if v == nil then return nil end
        local g = rawget(G, v)
        if type(g) == "string" then return g end
        return v
    end

    -- x and y of an element: attributes, or an AbsDimension (or RelDimension: the lab takes its numbers as UI units)
    local function dims(el)
        local x, y = num(el.attrs.x), num(el.attrs.y)
        local d = xml.find(el, "AbsDimension") or xml.find(el, "RelDimension")
        if d then x, y = x or num(d.attrs.x), y or num(d.attrs.y) end
        return x, y
    end
    local function insets(el)
        local a = el.attrs
        local d = xml.find(el, "AbsInset") or el
        return num(a.left or d.attrs.left) or 0, num(a.right or d.attrs.right) or 0,
            num(a.top or d.attrs.top) or 0, num(a.bottom or d.attrs.bottom) or 0
    end
    local function color(el)
        local a = el.attrs
        if a.color then
            local c = rawget(G, a.color)
            if type(c) == "table" and c.r then return c.r, c.g, c.b, c.a or 1 end
            return nil
        end
        return num(a.r) or 0, num(a.g) or 0, num(a.b) or 0, num(a.a) or 1
    end

    -- A name with $parent in it: the parent's name in its place, as the game makes it.
    local function named(name, parent)
        if name and name:lower():find("$parent", 1, true) then
            local pn = parent and S[parent] and S[parent].name or ""
            name = name:gsub("%$[Pp]arent", function() return pn end)
        end
        return name
    end

    -- relativeKey="$parent.Header.Title": from the object anchored, up by $parent, down by the keys.
    local function byKey(from, path)
        local o = from
        for part in path:gmatch("[^%.]+") do
            if part == "$parent" then o = S[o] and S[o].parent
            else o = type(o) == "table" and rawget(o, part) or nil end
            if o == nil then return nil end
        end
        return o
    end

    -- Parent keys and arrays: the object in the table of its parent (the frame whose part it is, the group of an
    -- animation), from the element or from a template it inherits, as the game sets them.
    local function keys(owner, o, a)
        if not owner then return end
        if a.parentKey then owner[a.parentKey] = o end
        if a.parentArray then
            local list = rawget(owner, a.parentArray)
            if type(list) ~= "table" then list = {}; owner[a.parentArray] = list end
            list[#list + 1] = o
        end
    end

    local apply   -- apply(o, el, how): an element's content on an object (below)

    -- Sizes and anchors ---------------------------------------------------------------------------------------------------
    local function size(o, el)
        local x, y = dims(el)
        if x and y then call(o, "SetSize", x, y)
        elseif x then call(o, "SetWidth", x)
        elseif y then call(o, "SetHeight", y) end
    end
    local function anchors(o, el, how)
        for _, an in ipairs(el.children) do
            if an.tag == "Anchor" then
                local a = an.attrs
                local x, y = num(a.x), num(a.y)
                local off = xml.find(an, "Offset")
                if off then
                    local ox, oy = dims(off)
                    x, y = x or ox, y or oy
                end
                later(function()
                    local rel
                    if a.relativeKey then
                        rel = byKey(o, a.relativeKey)
                        if not rel then
                            tell(how, "warn", "an anchor's relativeKey " .. a.relativeKey .. " is not there", where(how, an))
                            return
                        end
                    elseif a.relativeTo then
                        rel = rawget(G, named(a.relativeTo, S[o].parent))
                        if not rel then
                            tell(how, "warn", "an anchor's relativeTo " .. a.relativeTo .. " is not there", where(how, an))
                            return
                        end
                    end
                    local point = upper(a.point) or "TOPLEFT"
                    local relPoint = upper(a.relativePoint) or point
                    if rel then call(o, "SetPoint", point, rel, relPoint, x or 0, y or 0)
                    else call(o, "SetPoint", point, S[o].parent, relPoint, x or 0, y or 0) end
                end)
            end
        end
    end
    local function allPoints(o, a)
        if a.setAllPoints == "true" then later(function() call(o, "SetAllPoints", S[o].parent) end) end
    end

    -- Scripts ------------------------------------------------------------------------------------------------------------
    -- The names the game gives an inline script's arguments, after self.
    local ARGS = {
        OnClick = "button, down", PreClick = "button, down", PostClick = "button, down", OnDoubleClick = "button",
        OnEvent = "event, ...", OnUpdate = "elapsed", OnEnter = "motion", OnLeave = "motion",
        OnMouseDown = "button", OnMouseUp = "button, upInside", OnMouseWheel = "delta", OnSizeChanged = "width, height",
        OnKeyDown = "key", OnKeyUp = "key", OnChar = "text", OnTextChanged = "userInput", OnValueChanged = "value, userInput",
        OnMinMaxChanged = "min, max", OnVerticalScroll = "offset", OnHorizontalScroll = "offset",
        OnScrollRangeChanged = "xrange, yrange", OnHyperlinkClick = "link, text, button, region, left, bottom, width, height",
        OnHyperlinkEnter = "link, text, region, left, bottom, width, height", OnHyperlinkLeave = "",
        OnAttributeChanged = "name, value", OnDragStart = "button", OnReceiveDrag = "", OnFinished = "requested",
        OnStop = "requested", OnLoop = "loopState", OnCursorChanged = "x, y, w, h", OnShow = "", OnHide = "", OnLoad = "",
        OnEditFocusGained = "", OnEditFocusLost = "", OnEnterPressed = "", OnEscapePressed = "", OnTabPressed = "",
        OnArrowPressed = "key", OnTooltipSetDefaultAnchor = "", OnEnable = "", OnDisable = "", OnPlay = "",
    }
    local function both(first, second)
        return function(...)
            first(...)
            return second(...)
        end
    end
    -- intrinsic: the script is an intrinsic kind's own; it runs with what a template or code sets later, before it
    -- (intrinsicOrder="precall", the game's default) or after it ("postcall").
    local function script(o, el, how, intrinsic)
        local a = el.attrs
        local name = Lab.ScriptAllowed(o, el.tag)
        if not name then
            tell(how, "error", ("%s doesn't have a \"%s\" script"):format(S[o].kind, el.tag), where(how, el))
            return
        end
        local fn
        if a.method then
            local m = a.method
            fn = function(self, ...)
                local f = self[m]
                if type(f) ~= "function" then error(("%s: no method %s for the script %s"):format(tostring(self), m, name), 2) end
                return f(self, ...)
            end
        elseif a["function"] then
            fn = global(a["function"])
            if type(fn) ~= "function" then
                tell(how, "warn", "the script " .. name .. "'s function " .. a["function"] .. " is not there", where(how, el))
                return
            end
        elseif el.text:match("%S") then
            local code = string.rep("\n", (el.line or 1) - 1) .. "return function(self" ..
                ((ARGS[name] or "...") ~= "" and ", " .. (ARGS[name] or "...") or "") .. ") " .. el.text .. "\nend"
            local chunk, err = loadstring(code, "@" .. how.file)
            if not chunk then
                tell(how, "error", tostring(err):gsub(Lab.root .. "/", ""), where(how, el))
                return
            end
            setfenv(chunk, G)
            fn = chunk()
        else
            return
        end
        local s = S[o]
        s.scripts = s.scripts or {}
        s.scriptOrder = s.scriptOrder or {}
        local old, order = s.scripts[name], s.scriptOrder[name]
        if old and a.inherit == "prepend" then fn = both(fn, old)
        elseif old and a.inherit == "append" then fn = both(old, fn)
        elseif old and order == "precall" then fn = both(old, fn)
        elseif old and order == "postcall" then fn = both(fn, old) end
        if intrinsic then s.scriptOrder[name] = a.intrinsicOrder or "precall" end
        s.scripts[name] = fn
    end
    local function scripts(o, el, how, owner)
        for _, c in ipairs(el.children) do script(o, c, how, owner ~= nil and owner == how.intrinsic) end
    end

    local function keyValues(o, el, how)
        for _, kv in ipairs(el.children) do
            if kv.tag == "KeyValue" then
                local a = kv.attrs
                local function value(v, t)
                    t = t or "string"
                    if t == "number" then return tonumber(v)
                    elseif t == "boolean" then return v == "true"
                    elseif t == "global" then
                        local g = global(v)
                        if g == nil then tell(how, "warn", "the KeyValue's global " .. tostring(v) .. " is not there", where(how, kv)) end
                        return g
                    elseif t == "function" then return global(v)   -- a function by its name ("..." in Blizzard's: none)
                    elseif t == "nil" then return nil end
                    return v
                end
                local k = value(a.key, a.keyType)
                if k ~= nil then o[k] = value(a.value, a.type) end
            end
        end
    end
    local function attributes(o, el)
        for _, at in ipairs(el.children) do
            if at.tag == "Attribute" then
                local a = at.attrs
                local v = a.value
                if a.type == "number" then v = tonumber(v) elseif a.type == "boolean" then v = v == "true"
                elseif a.type == "global" then v = rawget(G, v) elseif a.type == "nil" then v = nil end
                local st = S[o]
                st.attributes = st.attributes or {}
                st.attributes[a.name] = v
            end
        end
    end

    -- Animations ------------------------------------------------------------------------------------------------------
    local ANIM = { Alpha = "Alpha", Translation = "Translation", Scale = "Scale", Rotation = "Rotation", Animation = "Animation" }
    local function animation(g, el, how)
        local kind = ANIM[el.tag]
        if not kind then
            if el.tag == "Scripts" then scripts(g, el, how)
            elseif el.tag == "KeyValues" then keyValues(g, el, how)
            else missing(how, el, "the animation <" .. el.tag .. ">") end
            return
        end
        local a = el.attrs
        local anim = call(g, "CreateAnimation", kind, a.name)
        apply(anim, el, how)
    end
    local function animationGroup(owner, el, how)
        local g = Lab.NewAnimationGroup(owner, named(el.attrs.name, owner))
        apply(g, el, how)
        Lab.Loaded(g)
    end

    -- Regions -----------------------------------------------------------------------------------------------------------
    local LAYERS = { BACKGROUND = true, BORDER = true, ARTWORK = true, OVERLAY = true, HIGHLIGHT = true }
    local function region(owner, el, how, layer, sub)
        local tag, a = el.tag, el.attrs
        local name = named(a.name, owner)
        local o
        if tag == "Texture" or tag == "MaskTexture" or tag == "Line" then
            o = Lab.NewTexture(tag, owner, name, layer, nil, sub)
            if tag == "MaskTexture" then S[o].mask = true end
        elseif tag == "FontString" then
            o = Lab.NewFontString(owner, name, layer, nil, sub)
        else
            missing(how, el, "the region <" .. tag .. ">")
            return nil
        end
        Lab.AddRegion(owner, o)
        apply(o, el, how)
        Lab.Loaded(o)
        return o
    end
    local function layers(o, el, how)
        for _, layer in ipairs(el.children) do
            if layer.tag == "Layer" then
                local level = upper(layer.attrs.level) or "ARTWORK"
                if not LAYERS[level] then level = "ARTWORK" end
                local sub = num(layer.attrs.textureSubLevel) or 0
                for _, c in ipairs(layer.children) do region(o, c, how, level, sub) end
            end
        end
    end

    -- A button's textures, a slider's thumb, a bar's fill: a texture of the frame's, given its role when it is placed.
    local ROLE = { NormalTexture = "SetNormalTexture", PushedTexture = "SetPushedTexture", DisabledTexture = "SetDisabledTexture",
        HighlightTexture = "SetHighlightTexture", CheckedTexture = "SetCheckedTexture",
        DisabledCheckedTexture = "SetDisabledCheckedTexture", ThumbTexture = "SetThumbTexture", BarTexture = "SetStatusBarTexture" }
    local ROLE_LAYER = { HighlightTexture = "HIGHLIGHT", CheckedTexture = "OVERLAY", DisabledCheckedTexture = "OVERLAY",
        ThumbTexture = "OVERLAY" }
    local function roleTexture(o, el, how)
        local t = Lab.NewTexture("Texture", o, named(el.attrs.name, o), ROLE_LAYER[el.tag] or "ARTWORK")
        Lab.AddRegion(o, t)
        if el.tag == "HighlightTexture" and not el.attrs.alphaMode then S[t].blend = "ADD" end
        apply(t, el, how)
        local method = ROLE[el.tag]
        later(function() call(o, method, t, el.tag == "HighlightTexture" and S[t].blend or nil) end)
    end
    local FONT_ROLE = { NormalFont = "SetNormalFontObject", HighlightFont = "SetHighlightFontObject",
        DisabledFont = "SetDisabledFontObject" }

    -- Frames --------------------------------------------------------------------------------------------------------------
    -- The kind an element's tag makes: one of the game's, or an intrinsic one (its kind and its template).
    function Lab.FrameKind(tag)
        local low = tostring(tag):lower()
        local kind = Lab.frameKinds[low]
        if kind then return kind end
        local i = Lab.intrinsics[low]
        if i then return i.kind, i.name end
    end

    local function frame(tag, el, parent, how)
        local kind, intrinsic = Lab.FrameKind(tag)
        if not kind then
            missing(how, el, "the frame <" .. tag .. ">")
            return nil
        end
        local a = el.attrs
        if a.parent then
            local p = rawget(G, named(a.parent, parent))
            if p and S[p] then parent = p
            else tell(how, "warn", "the frame's parent " .. a.parent .. " is not there", where(how, el)) end
        end
        return Lab.Building(function()
            local f = Lab.MakeFrame(kind, named(a.name, parent), parent, num(a.id))
            S[f].at = where(how, el)
            if intrinsic then Lab.ApplyTemplate(f, intrinsic) end
            apply(f, el, how)
            Lab.Loaded(f)
            return f
        end)
    end

    local function frames(o, el, how)
        for _, c in ipairs(el.children) do frame(c.tag, c, o, how) end
    end

    -- The attributes the lab reads, by kind (what an attribute does where the game has it).
    local onFrame = {
        toplevel = function(o, v) call(o, "SetToplevel", bool(v)) end,
        movable = function(o, v) call(o, "SetMovable", bool(v)) end,
        resizable = function(o, v) call(o, "SetResizable", bool(v)) end,
        enableMouse = function(o, v) call(o, "EnableMouse", bool(v)) end,
        enableMouseClicks = function(o, v) call(o, "SetMouseClickEnabled", bool(v)) end,
        enableMouseMotion = function(o, v) call(o, "SetMouseMotionEnabled", bool(v)) end,
        enableKeyboard = function(o, v) call(o, "EnableKeyboard", bool(v)) end,
        propagateKeyboardInput = function(o, v) call(o, "SetPropagateKeyboardInput", bool(v)) end,
        clampedToScreen = function(o, v) call(o, "SetClampedToScreen", bool(v)) end,
        frameStrata = function(o, v) call(o, "SetFrameStrata", v) end,
        frameLevel = function(o, v) call(o, "SetFrameLevel", tonumber(v)) end,
        fixedFrameStrata = function(o, v) call(o, "SetFixedFrameStrata", bool(v)) end,
        fixedFrameLevel = function(o, v) call(o, "SetFixedFrameLevel", bool(v)) end,
        useParentLevel = function(o, v) if bool(v) then call(o, "SetUsingParentLevel", true) end end,
        id = function(o, v) call(o, "SetID", tonumber(v)) end,
        scale = function(o, v) call(o, "SetScale", tonumber(v)) end,
        clipChildren = function(o, v) call(o, "SetClipsChildren", bool(v)) end,
        dontSavePosition = function(o, v) call(o, "SetDontSavePosition", bool(v)) end,
        hyperlinksEnabled = function(o, v) call(o, "SetHyperlinksEnabled", bool(v)) end,
        flattenRenderLayers = function() end,
        frameBuffer = function() end,
        enableMouseWheel = function(o, v) call(o, "EnableMouseWheel", bool(v)) end,
        registerForDrag = function(o, v) call(o, "RegisterForDrag", string.split(", ", v)) end,
        -- buttons
        -- after the template's ButtonText is the button's (later), as the game shows it
        text = function(o, v) if Lab.Is(o, "Button") or Lab.Is(o, "EditBox") then later(function() call(o, "SetText", words(v)) end) end end,
        registerForClicks = function(o, v)
            local list = {}
            for c in v:gmatch("[^,%s]+") do list[#list + 1] = c end
            call(o, "RegisterForClicks", unpack(list))
        end,
        motionScriptsWhileDisabled = function(o, v) call(o, "SetMotionScriptsWhileDisabled", bool(v)) end,
        checked = function(o, v) call(o, "SetChecked", bool(v)) end,
        -- edit boxes
        autoFocus = function(o, v) call(o, "SetAutoFocus", bool(v)) end,
        multiLine = function(o, v) call(o, "SetMultiLine", bool(v)) end,
        numeric = function(o, v) call(o, "SetNumeric", bool(v)) end,
        password = function(o, v) call(o, "SetPassword", bool(v)) end,
        letters = function(o, v) call(o, "SetMaxLetters", tonumber(v)) end,
        bytes = function(o, v) call(o, "SetMaxBytes", tonumber(v)) end,
        historyLines = function(o, v) call(o, "SetHistoryLines", tonumber(v)) end,
        ignoreArrows = function(o, v) call(o, "SetAltArrowKeyMode", bool(v)) end,
        countInvisibleLetters = function(o, v) call(o, "SetCountInvisibleLetters", bool(v)) end,
        blinkSpeed = function(o, v) call(o, "SetBlinkSpeed", tonumber(v)) end,
        -- sliders and status bars
        minValue = function(o, v) local _, hi = call(o, "GetMinMaxValues"); call(o, "SetMinMaxValues", tonumber(v), math.max(hi or 0, tonumber(v))) end,
        maxValue = function(o, v) local lo = call(o, "GetMinMaxValues"); call(o, "SetMinMaxValues", math.min(lo or 0, tonumber(v)), tonumber(v)) end,
        defaultValue = function(o, v) call(o, "SetValue", tonumber(v)) end,
        valueStep = function(o, v) call(o, "SetValueStep", tonumber(v)) end,
        stepsPerPage = function(o, v) call(o, "SetStepsPerPage", tonumber(v)) end,
        obeyStepOnDrag = function(o, v) call(o, "SetObeyStepOnDrag", bool(v)) end,
        orientation = function(o, v) call(o, "SetOrientation", v) end,
        reverseFill = function(o, v) call(o, "SetReverseFill", bool(v)) end,
        rotatesTexture = function(o, v) call(o, "SetRotatesTexture", bool(v)) end,
        -- cooldowns
        reverse = function(o, v) call(o, "SetReverse", bool(v)) end,
        drawEdge = function(o, v) call(o, "SetDrawEdge", bool(v)) end,
        drawSwipe = function(o, v) call(o, "SetDrawSwipe", bool(v)) end,
        drawBling = function(o, v) call(o, "SetDrawBling", bool(v)) end,
        hideCountdownNumbers = function(o, v) call(o, "SetHideCountdownNumbers", bool(v)) end,
        -- message frames
        maxLines = function(o, v) call(o, "SetMaxLines", tonumber(v)) end,
        fade = function(o, v) call(o, "SetFading", bool(v)) end,
        fadeDuration = function(o, v) call(o, "SetFadeDuration", tonumber(v)) end,
        displayDuration = function(o, v) call(o, "SetTimeVisible", tonumber(v)) end,
        insertMode = function(o, v) call(o, "SetInsertMode", v) end,
    }
    -- what every region takes as a frame does
    local onRegion = {
        scale = function(o, v) call(o, "SetScale", tonumber(v)) end,
        enableMouse = function(o, v) call(o, "EnableMouse", bool(v)) end,
        enableMouseMotion = function(o, v) call(o, "SetMouseMotionEnabled", bool(v)) end,
        enableMouseClicks = function(o, v) call(o, "SetMouseClickEnabled", bool(v)) end,
    }
    onFrame.propagateMouseInput = function(o, v)
        v = v:lower()
        call(o, "SetPropagateMouseMotion", v == "motion" or v == "both")
        call(o, "SetPropagateMouseClicks", v == "clicks" or v == "both")
    end
    local onTexture = {
        file = function(o, v) call(o, "SetTexture", v) end,
        atlas = function(o, v, a) call(o, "SetAtlas", v, a.useAtlasSize == "true") end,
        useAtlasSize = function() end,
        alphaMode = function(o, v) call(o, "SetBlendMode", v) end,
        horizTile = function(o, v) call(o, "SetHorizTile", bool(v)) end,
        vertTile = function(o, v) call(o, "SetVertTile", bool(v)) end,
        desaturated = function(o, v) call(o, "SetDesaturated", bool(v)) end,
        snapToPixelGrid = function(o, v) call(o, "SetSnapToPixelGrid", bool(v)) end,
        texelSnappingBias = function(o, v) call(o, "SetTexelSnappingBias", tonumber(v)) end,
        rotation = function(o, v) call(o, "SetRotation", math.rad(tonumber(v) or 0)) end,
        hWrapMode = function() end, vWrapMode = function() end, filterMode = function() end,
        thickness = function(o, v) call(o, "SetThickness", tonumber(v)) end,
    }
    local onText = {
        text = function(o, v) call(o, "SetText", words(v)) end,
        justifyH = function(o, v) call(o, "SetJustifyH", v) end,
        justifyV = function(o, v) call(o, "SetJustifyV", v) end,
        maxLines = function(o, v) call(o, "SetMaxLines", tonumber(v)) end,
        wordwrap = function(o, v) call(o, "SetWordWrap", bool(v)) end,
        nonspacewrap = function(o, v) call(o, "SetNonSpaceWrap", bool(v)) end,
        spacing = function(o, v) call(o, "SetSpacing", tonumber(v)) end,
        indented = function(o, v) call(o, "SetIndentedWordWrap", bool(v)) end,
        font = function() end, outline = function() end, monochrome = function() end, height = function() end,
        textScale = function(o, v) call(o, "SetTextScale", tonumber(v)) end,
    }
    for k, f in pairs(onRegion) do onTexture[k], onText[k] = f, f end
    local onAnim = {
        duration = function(o, v) call(o, "SetDuration", tonumber(v)) end,
        startDelay = function(o, v) call(o, "SetStartDelay", tonumber(v)) end,
        endDelay = function(o, v) call(o, "SetEndDelay", tonumber(v)) end,
        order = function(o, v) call(o, "SetOrder", tonumber(v)) end,
        smoothing = function(o, v) call(o, "SetSmoothing", v) end,
        childKey = function(o, v) call(o, "SetChildKey", v) end,
        targetKey = function(o, v) call(o, "SetTargetKey", v) end,
        target = function(o, v) call(o, "SetTargetName", v) end,
        fromAlpha = function(o, v) call(o, "SetFromAlpha", tonumber(v)) end,
        toAlpha = function(o, v) call(o, "SetToAlpha", tonumber(v)) end,
        offsetX = function(o, v) local _, y = call(o, "GetOffset"); call(o, "SetOffset", tonumber(v), y or 0) end,
        offsetY = function(o, v) local x = call(o, "GetOffset"); call(o, "SetOffset", x or 0, tonumber(v)) end,
        scaleX = function(o, v) local _, y = call(o, "GetScale"); call(o, "SetScale", tonumber(v), y or 1) end,
        scaleY = function(o, v) local x = call(o, "GetScale"); call(o, "SetScale", x or 1, tonumber(v)) end,
        fromScaleX = function(o, v) local _, y = call(o, "GetScaleFrom"); call(o, "SetScaleFrom", tonumber(v), y or 1) end,
        fromScaleY = function(o, v) local x = call(o, "GetScaleFrom"); call(o, "SetScaleFrom", x or 1, tonumber(v)) end,
        toScaleX = function(o, v) local _, y = call(o, "GetScaleTo"); call(o, "SetScaleTo", tonumber(v), y or 1) end,
        toScaleY = function(o, v) local x = call(o, "GetScaleTo"); call(o, "SetScaleTo", x or 1, tonumber(v)) end,
        degrees = function(o, v) call(o, "SetDegrees", tonumber(v)) end,
        radians = function(o, v) call(o, "SetRadians", tonumber(v)) end,
        looping = function(o, v) call(o, "SetLooping", v) end,
        setToFinalAlpha = function(o, v) call(o, "SetToFinalAlpha", bool(v)) end,
    }
    -- read where they belong, or meaning nothing to the lab's drawing
    local SKIP = { name = true, parentKey = true, parentArray = true, inherits = true, virtual = true, mixin = true,
        secureMixin = true, intrinsic = true, parent = true, hidden = true, setAllPoints = true, alpha = true,
        ignoreParentAlpha = true, ignoreParentScale = true, protected = true, forbidden = true, depth = true,
        scriptsUseGivenEnv = true }

    -- the range before a value in it
    local FIRST = { minValue = 1, maxValue = 1 }
    local function attrs(o, el, how)
        local a = el.attrs
        local table_
        if Lab.Is(o, "Frame") then table_ = onFrame
        elseif Lab.Is(o, "FontString") then table_ = onText
        elseif Lab.Is(o, "TextureBase") then table_ = onTexture
        elseif Lab.Is(o, "Animation") or Lab.Is(o, "AnimationGroup") then table_ = onAnim
        else table_ = {} end
        local s = S[o]
        if a.hidden then
            -- as the game reads it: no OnShow or OnHide while the object is made
            s.shown = a.hidden ~= "true"
            Lab.Touch()
        end
        if a.alpha then call(o, "SetAlpha", tonumber(a.alpha)) end
        if a.ignoreParentAlpha then s.ignoreParentAlpha = bool(a.ignoreParentAlpha) or nil end
        if a.ignoreParentScale then s.ignoreParentScale = bool(a.ignoreParentScale) or nil end
        local names = {}
        for k in pairs(a) do names[#names + 1] = k end
        table.sort(names, function(x, y)
            local px, py = FIRST[x] or 2, FIRST[y] or 2
            if px ~= py then return px < py end
            return x < y
        end)
        for _, k in ipairs(names) do
            local v = a[k]
            local f = table_[k]
            if f then
                f(o, v, a)
            elseif not SKIP[k] then
                missing(how, el, "the attribute " .. k .. " of <" .. el.tag .. ">")
            end
        end
    end

    -- The parts of an element, by tag.
    local function fontStringOf(o, el, how)
        -- an edit box's or message frame's <FontString>: its font and colours
        local a = el.attrs
        if a.inherits then
            local f = rawget(G, a.inherits)
            if f and S[f] then call(o, "SetFontObject", f) end
        end
        if a.font then
            local fh = xml.find(el, "FontHeight")
            local v = fh and xml.find(fh, "AbsValue")
            local _, sz, flags = call(o, "GetFont")
            call(o, "SetFont", a.font, num(v and v.attrs.val) or sz or 12, flags or "")
        end
        if a.justifyH then call(o, "SetJustifyH", a.justifyH) end
        if a.justifyV then call(o, "SetJustifyV", a.justifyV) end
        local c = xml.find(el, "Color")
        if c then
            local r, g, b, al = color(c)
            if r then call(o, "SetTextColor", r, g, b, al) end
        end
    end

    local PARTS = {}
    PARTS.Size = function(o, el) size(o, el) end
    PARTS.Anchors = anchors
    PARTS.Layers = layers
    PARTS.Frames = frames
    PARTS.Scripts = scripts
    PARTS.KeyValues = keyValues
    PARTS.Attributes = function(o, el) attributes(o, el) end
    PARTS.Animations = function(o, el, how)
        for _, c in ipairs(el.children) do
            if c.tag == "AnimationGroup" then animationGroup(o, c, how) else missing(how, c, "<" .. c.tag .. "> in Animations") end
        end
    end
    PARTS.HitRectInsets = function(o, el) call(o, "SetHitRectInsets", insets(el)) end
    PARTS.TextInsets = function(o, el) call(o, "SetTextInsets", insets(el)) end
    PARTS.PushedTextOffset = function(o, el) local x, y = dims(el); call(o, "SetPushedTextOffset", x or 0, y or 0) end
    PARTS.ResizeBounds = function(o, el)
        local lo, hi = xml.find(el, "minResize"), xml.find(el, "maxResize")
        local w1, h1 = lo and dims(lo)
        local w2, h2 = hi and dims(hi)
        call(o, "SetResizeBounds", w1 or 0, h1 or 0, w2, h2)
    end
    PARTS.ButtonText = function(o, el, how)
        local fs = Lab.NewFontString(o, named(el.attrs.name, o), "OVERLAY")
        Lab.AddRegion(o, fs)
        apply(fs, el, how)
        later(function()
            call(o, "SetFontString", fs)
            if #S[fs].points == 0 then call(fs, "SetPoint", "CENTER", o, "CENTER", 0, 0) end
        end)
    end
    PARTS.FontString = function(o, el, how) fontStringOf(o, el, how) end
    PARTS.HighlightColor = function(o, el) call(o, "SetHighlightColor", color(el)) end
    PARTS.BarColor = function(o, el) call(o, "SetStatusBarColor", color(el)) end
    PARTS.ScrollChild = function(o, el, how)
        for _, c in ipairs(el.children) do
            local child = frame(c.tag, c, o, how)
            if child then call(o, "SetScrollChild", child) end
        end
    end
    for tag in pairs(ROLE) do PARTS[tag] = roleTexture end
    for tag, method in pairs(FONT_ROLE) do
        PARTS[tag] = function(o, el, how)
            local f = el.attrs.style and rawget(G, el.attrs.style)
            if f and S[f] then call(o, method, f)
            elseif el.attrs.style then tell(how, "warn", "the font " .. el.attrs.style .. " is not there", where(how, el)) end
        end
    end
    for _, tag in ipairs({ "SwipeTexture", "EdgeTexture", "BlingTexture" }) do
        PARTS[tag] = function(o, el) if el.attrs.file then call(o, "Set" .. tag, el.attrs.file) end end
    end
    -- of textures and font strings
    PARTS.TexCoords = function(o, el)
        local a = el.attrs
        local rect = xml.find(el, "Rect")
        if rect then
            local r = rect.attrs
            call(o, "SetTexCoord", num(r.ULx) or 0, num(r.ULy) or 0, num(r.LLx) or 0, num(r.LLy) or 1,
                num(r.URx) or 1, num(r.URy) or 0, num(r.LRx) or 1, num(r.LRy) or 1)
        else
            call(o, "SetTexCoord", num(a.left) or 0, num(a.right) or 1, num(a.top) or 0, num(a.bottom) or 1)
        end
    end
    PARTS.Color = function(o, el)
        local r, g, b, al = color(el)
        if not r then return end
        if Lab.Is(o, "FontString") then call(o, "SetTextColor", r, g, b, al)
        elseif Lab.Is(o, "Line") or Lab.Is(o, "Texture") then call(o, "SetColorTexture", r, g, b, al) end
    end
    PARTS.Gradient = function(o, el)
        local lo, hi = xml.find(el, "MinColor"), xml.find(el, "MaxColor")
        if not (lo and hi and G.CreateColor) then return end
        call(o, "SetGradient", el.attrs.orientation or "HORIZONTAL", G.CreateColor(color(lo)), G.CreateColor(color(hi)))
    end
    PARTS.Shadow = function(o, el)
        local off = xml.find(el, "Offset")
        if off then local x, y = dims(off); call(o, "SetShadowOffset", x or 0, y or 0) end
        local c = xml.find(el, "Color")
        if c then call(o, "SetShadowColor", color(c)) end
    end
    PARTS.FontHeight = function() end   -- read with the font
    PARTS.MaskedTextures = function(o, el, how)
        for _, m in ipairs(el.children) do
            if m.tag == "MaskedTexture" and m.attrs.childKey then
                later(function()
                    local t = byKey(S[o].parent, m.attrs.childKey)
                    if t and S[t] then call(t, "AddMaskTexture", o)
                    else tell(how, "warn", "the masked texture " .. m.attrs.childKey .. " is not there", where(how, m)) end
                end)
            end
        end
    end
    for which, method in pairs({ StartAnchor = "SetStartPoint", EndAnchor = "SetEndPoint" }) do
        PARTS[which] = function(o, el, how)
            local a = el.attrs
            later(function()
                local rel = a.relativeKey and byKey(o, a.relativeKey) or (a.relativeTo and rawget(G, named(a.relativeTo, S[o].parent))) or S[o].parent
                call(o, method, upper(a.relativePoint) or "CENTER", rel, num(a.x) or 0, num(a.y) or 0)
            end)
        end
    end
    PARTS.Origin = function(o, el)
        local x, y = 0, 0
        local off = xml.find(el, "Offset")
        if off then x, y = dims(off) end
        call(o, "SetOrigin", upper(el.attrs.point) or "CENTER", x or 0, y or 0)
    end

    -- An element's content on an object: its inherits, its mixins, its attributes, its parts.
    function apply(o, el, how)
        local a = el.attrs
        if a.inherits then
            if Lab.Is(o, "FontString") then
                for name in a.inherits:gmatch("[^,%s]+") do
                    if Lab.templates[name] then Lab.ApplyTemplate(o, name)
                    else
                        local f = rawget(G, name)
                        if f and S[f] then call(o, "SetFontObject", f)
                        else tell(how, "warn", "the font " .. name .. " is not there", where(how, el)) end
                    end
                end
            else
                Lab.ApplyTemplate(o, a.inherits)
            end
        end
        keys(S[o].parent, o, a)
        for _, field in ipairs({ "mixin", "secureMixin" }) do
            for m in (a[field] or ""):gmatch("[^,%s]+") do
                local mixin = rawget(G, m)
                if type(mixin) == "table" then G.Mixin(o, mixin)
                else tell(how, "warn", "the mixin " .. m .. " is not there", where(how, el)) end
            end
        end
        attrs(o, el, how)
        local fontObject = a.font and rawget(G, a.font)
        if Lab.Is(o, "FontString") and fontObject and S[fontObject] then
            call(o, "SetFontObject", fontObject)   -- font="GameFontNormalHuge": a font object by its name
        elseif Lab.Is(o, "FontString") and a.font then
            local fh = xml.find(el, "FontHeight")
            local v = fh and xml.find(fh, "AbsValue")
            local _, sz, flags = call(o, "GetFont")
            local f = {}
            if a.outline == "NORMAL" then f[#f + 1] = "OUTLINE" elseif a.outline == "THICK" then f[#f + 1] = "THICKOUTLINE" end
            if a.monochrome == "true" then f[#f + 1] = "MONOCHROME" end
            call(o, "SetFont", a.font, num(v and v.attrs.val) or num(a.height) or sz or 12, #f > 0 and table.concat(f, ",") or flags or "")
        end
        allPoints(o, a)
        for _, c in ipairs(el.children) do
            local part = PARTS[c.tag]
            if Lab.Is(o, "AnimationGroup") and c.tag ~= "Scripts" and c.tag ~= "KeyValues" then
                animation(o, c, how)
            elseif part then
                part(o, c, how, el)
            else
                missing(how, c, "<" .. c.tag .. "> of <" .. el.tag .. ">")
            end
        end
    end

    -- What the client tells of a template (C_XMLUtil, as its documentation has it): its kind, its size and its
    -- KeyValues, its own or inherited.
    local function templateInfo(name, info, seen)
        local t = Lab.xmlTemplates[name]
        if not t or seen[name] then return end
        seen[name] = true
        local el = t.el
        for base in (el.attrs.inherits or ""):gmatch("[^,%s]+") do templateInfo(base, info, seen) end
        local sz = xml.find(el, "Size")
        if sz then
            local x, y = dims(sz)
            info.width, info.height = x or info.width, y or info.height
        end
        local kvs = xml.find(el, "KeyValues")
        for _, kv in ipairs(kvs and kvs.children or {}) do
            if kv.tag == "KeyValue" then
                local a = kv.attrs
                info.keyValues[#info.keyValues + 1] = { key = a.key, keyType = a.keyType or "string", type = a.type or "string", value = a.value }
            end
        end
    end
    G.C_XMLUtil = {
        GetTemplateInfo = function(name)
            local t = Lab.xmlTemplates[name]
            if not t then return nil end
            local info = { type = t.tag, width = 0, height = 0, keyValues = {}, inherits = t.el.attrs.inherits,
                sourceLocation = Lab.Short(t.file) .. ":" .. (t.el.line or 0) }
            templateInfo(name, info, {})
            return info
        end,
        GetTemplates = function()
            local out = {}
            for name, t in pairs(Lab.xmlTemplates) do out[#out + 1] = { name = name, type = t.tag } end
            return out
        end,
    }

    -- Files ---------------------------------------------------------------------------------------------------------------
    local REGIONS = { Texture = true, FontString = true, MaskTexture = true, Line = true, AnimationGroup = true }
    local function folderOf(path) return path:match("^(.*)/[^/]+$") or "." end
    local function relative(how, file)
        return folderOf(how.file) .. "/" .. file:gsub("\\", "/")
    end

    local function template(el, how)
        local name = el.attrs.name
        if not name then tell(how, "warn", "a virtual <" .. el.tag .. "> without a name", where(how, el)) return end
        local t = { el = el, file = how.file, tag = el.tag }
        Lab.xmlTemplates[name] = t
        local h = { file = how.file, blizzard = how.blizzard, intrinsic = el.attrs.intrinsic == "true" and el or nil }
        Lab.templates[name] = function(o) apply(o, el, h) end
        if el.attrs.intrinsic == "true" then
            local kind = Lab.FrameKind(el.tag)
            if Lab.frameKinds[name:lower()] then
                -- one of the lab's own kinds already (ScrollingMessageFrame): the lab's stays
                Lab.templates[name] = nil
                tell(how, "lab", "the intrinsic " .. name .. " is the lab's own kind: Blizzard's is left out", where(how, el))
            elseif kind then
                Lab.intrinsics[name:lower()] = { name = name, kind = kind }
            end
        end
    end

    local function top(el, how)
        local tag = el.tag
        if tag == "Script" then
            if el.attrs.file then
                how.run(relative(how, el.attrs.file))
            elseif el.text:match("%S") then
                local chunk, err = loadstring(string.rep("\n", (el.line or 1) - 1) .. el.text, "@" .. how.file)
                if not chunk then tell(how, "error", tostring(err), where(how, el)) return end
                setfenv(chunk, G)
                if how.blizzard then pcall(chunk) else Lab.Call(chunk) end
            end
        elseif tag == "Include" then
            if el.attrs.file then Lab.LoadXML(relative(how, el.attrs.file), how) end
        elseif tag == "Font" or tag == "FontFamily" then
            Lab.FontElement(el)
        elseif tag == "ScopedModifier" then
            for _, c in ipairs(el.children) do top(c, how) end
        elseif el.attrs.virtual == "true" or el.attrs.intrinsic == "true" then
            template(el, how)
        elseif REGIONS[tag] then
            tell(how, "warn", "a <" .. tag .. "> outside a frame, and not virtual: the game makes nothing of it", where(how, el))
        else
            local ok, err = pcall(frame, tag, el, nil, how)
            if not ok then tell(how, "error", tostring(err), where(how, el)) end
        end
    end

    -- Reads a <Ui> file; its Lua files run by how.run (an addon's file of the addon loading it).
    function Lab.LoadXML(path, how)
        local h = { addon = how.addon, ns = how.ns, run = how.run, blizzard = how.blizzard, file = path }
        if not how.blizzard then Lab.Watch(path) end
        local doc, err = xml.read(path)
        if not doc then
            tell(h, "error", "XML " .. Lab.Short(path) .. ": " .. tostring(err):gsub(Lab.root .. "/", ""))
            return false
        end
        if doc.tag ~= "Ui" then
            tell(h, "warn", "XML " .. Lab.Short(path) .. " is no <Ui> file")
            return false
        end
        for _, el in ipairs(doc.children) do top(el, h) end
        return true
    end
end
