-- What the game's own interface gives every addon before it loads, taken from Blizzard's code itself
-- (references/BlizzardInterfaceCode): the client's named colours and global strings (from its tables, where the
-- lab's server has them), Blizzard's shared Lua (Mixin, tables, colours, pools, callbacks, the backdrop) and its
-- font objects (GameFontNormal and the rest, read from its font XML).
return function(Lab)
    local S = Lab.S
    local G = Lab.G
    local xml = require("xml")
    local BLIZ = Lab.root .. "/references/BlizzardInterfaceCode/Interface/AddOns/"

    -- The client's tables -------------------------------------------------------------------------------------------------
    local client = Lab.Ask({ need = "client" })
    local colors, strings = {}, {}
    if client and client.ok then
        local data = dofile(client.file)
        colors, strings = data.colors, data.strings
        Lab.clientBuild = client.build
    else
        Lab.Note("note", "the client's tables were not found: the lab uses its own few colours and strings")
        colors = {
            NORMAL_FONT_COLOR = { 1, 0.82, 0, 1 }, HIGHLIGHT_FONT_COLOR = { 1, 1, 1, 1 }, WHITE_FONT_COLOR = { 1, 1, 1, 1 },
            RED_FONT_COLOR = { 1, 0.1, 0.1, 1 }, GREEN_FONT_COLOR = { 0.1, 1, 0.1, 1 }, GRAY_FONT_COLOR = { 0.5, 0.5, 0.5, 1 },
            YELLOW_FONT_COLOR = { 1, 1, 0, 1 }, DISABLED_FONT_COLOR = { 0.5, 0.5, 0.5, 1 }, BLACK_FONT_COLOR = { 0, 0, 0, 1 },
            LIGHTBLUE_FONT_COLOR = { 0.53, 0.67, 1, 1 }, ORANGE_FONT_COLOR = { 1, 0.5, 0.25, 1 },
        }
        strings = { CLOSE = "Close", OKAY = "Okay", CANCEL = "Cancel", ACCEPT = "Accept", YES = "Yes", NO = "No",
            NONE = "None", LEVEL = "Level", GUILD = "Guild", CHAT = "Chat", SEARCH = "Search" }
    end
    for name, text in pairs(strings) do G[name] = text end
    G.C_UIColor = { GetColors = function()
        local out = {}
        for name, c in pairs(colors) do out[#out + 1] = { baseTag = name, color = { r = c[1], g = c[2], b = c[3], a = c[4] } } end
        table.sort(out, function(a, b) return a.baseTag < b.baseTag end)
        return out
    end }
    -- The client's colour helpers (C_ColorUtil): a colour as the hex code |c takes, AARRGGBB.
    local function code(color)
        local function b(v) return math.max(0, math.min(255, math.floor((v or 1) * 255 + 0.5))) end
        return string.format("%02x%02x%02x%02x", b(color.a or 1), b(color.r), b(color.g), b(color.b))
    end
    G.C_ColorUtil = {
        WrapTextInColorCode = function(text, hex) return "|c" .. hex .. tostring(text) .. "|r" end,
        WrapTextInColor = function(text, color) return "|c" .. code(color) .. tostring(text) .. "|r" end,
        GenerateTextColorCode = code,
        ConvertRGBToHSV = function(r, g, b)
            local max, min = math.max(r, g, b), math.min(r, g, b)
            local d = max - min
            local h = 0
            if d > 0 then
                if max == r then h = ((g - b) / d) % 6 elseif max == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
                h = h * 60
            end
            return h, max > 0 and d / max or 0, max
        end,
        ConvertHSVToHSL = function(h, s, v)
            local l = v * (1 - s / 2)
            local sl = (l == 0 or l == 1) and 0 or (v - l) / math.min(l, 1 - l)
            return h, sl, l
        end,
    }

    -- What the client itself gives Blizzard's Lua before any of it runs (no Lua of Blizzard's defines these).
    G.Mixin = function(object, ...)
        for i = 1, select("#", ...) do
            local mixin = select(i, ...)
            for k, v in pairs(mixin) do object[k] = v end
        end
        return object
    end
    G.CreateFromMixins = function(...) return G.Mixin({}, ...) end
    G.AddSourceLocationExclude = function() end
    local classColors = {}
    for _, c in ipairs(client and client.ok and (dofile(client.file).classes or {}) or {}) do
        if c.r then classColors[c.file] = { c.r, c.g, c.b } end
    end
    local fallback = { WARRIOR = "C69B6D", PALADIN = "F48CBA", HUNTER = "AAD372", ROGUE = "FFF468", PRIEST = "FFFFFF",
        SHAMAN = "0070DD", MAGE = "3FC7EB", WARLOCK = "8788EE", DRUID = "FF7C0A" }
    for file, h in pairs(fallback) do
        classColors[file] = classColors[file] or { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 }
    end
    G.C_ClassColor = { GetClassColor = function(file)
        local c = classColors[file]
        if c and G.CreateColor then return G.CreateColor(c[1], c[2], c[3], 1) end
    end }
    -- Curves the client keeps (C_CurveUtil): the lab's own, by their points, straight between them.
    local Curve = {}
    Curve.__index = Curve
    function Curve:AddPoint(x, y) self.points[#self.points + 1] = { x, y }; table.sort(self.points, function(a, b) return a[1] < b[1] end) end
    function Curve:SetType(t) self.type = t end
    function Curve:ClearPoints() self.points = {} end
    function Curve:GetPointCount() return #self.points end
    function Curve:Evaluate(x)
        local p = self.points
        if #p == 0 then return 0 end
        if x <= p[1][1] then return p[1][2] end
        for i = 2, #p do
            if x <= p[i][1] then
                local a, b = p[i - 1], p[i]
                return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
            end
        end
        return p[#p][2]
    end
    G.C_CurveUtil = { CreateCurve = function() return setmetatable({ points = {} }, Curve) end,
        CreateColorCurve = function() return setmetatable({ points = {} }, Curve) end }

    -- Blizzard's Lua files ------------------------------------------------------------------------------------------------
    -- A file runs as the game runs an addon's file: its folder's name and a table of its own as ...
    local ns = {}
    function Lab.RunBlizzardFile(addon, file)
        local path = BLIZ .. addon .. "/" .. file:gsub("\\", "/")
        local chunk, err = loadfile(path)
        if not chunk then
            Lab.Note("lab", "Blizzard's " .. addon .. "/" .. file .. " did not load: " .. tostring(err))
            return false
        end
        setfenv(chunk, G)
        ns[addon] = ns[addon] or {}
        local ok, e = pcall(chunk, addon, ns[addon])
        if not ok then
            Lab.Note("lab", "Blizzard's " .. addon .. "/" .. file .. " stopped in the lab: " .. tostring(e):gsub(Lab.root .. "/", ""))
            return false
        end
        return true
    end

    -- Blizzard_SharedXMLBase: all its Lua, in its TOC's order.
    local toc = io.open(BLIZ .. "Blizzard_SharedXMLBase/Blizzard_SharedXMLBase.toc")
    if toc then
        for line in toc:lines() do
            local file = line:match("^%s*([^#%s][^%s]*%.lua)%s*$")
            if file then Lab.RunBlizzardFile("Blizzard_SharedXMLBase", file) end
        end
        toc:close()
    end
    -- Of Blizzard_SharedXML, the plain Lua the game's windows lean on that stands without its XML.
    for _, file in ipairs({ "SharedColorConstants.lua", "ColorUtil.lua", "ClassColors.lua", "Mainline/NineSliceLayouts.lua", "NineSlice.lua", "Backdrop.lua",
        "FormattingUtil.lua", "LinkUtil.lua", "StringUtil.lua", "EventUtil.lua", "SortUtil.lua", "CircularBuffer.lua",
        "DataProvider.lua", "EasingUtil.lua", "Interpolator.lua", "ButtonGroup.lua", "RegionUtil.lua",
        "PixelUtil.lua", "TextureUtil.lua", "MoneyFormatter.lua" }) do
        local f = io.open(BLIZ .. "Blizzard_SharedXML/" .. file)
        if f then
            f:close()
            Lab.RunBlizzardFile("Blizzard_SharedXML", file)
        end
    end

    -- Font objects from Blizzard's font XML ------------------------------------------------------------------------------------
    local FS = Lab.kinds.FontString.methods
    local function num(v) return v and tonumber(v) end
    local function color(el)
        if el.attrs.color then
            local c = G[el.attrs.color]
            if type(c) == "table" and c.r then return c.r, c.g, c.b, c.a or 1 end
            return nil
        end
        return num(el.attrs.r) or 0, num(el.attrs.g) or 0, num(el.attrs.b) or 0, num(el.attrs.a) or 1
    end
    local function applyFont(font, el)
        local a = el.attrs
        if a.inherits then
            local base = Lab.named[a.inherits]
            if base then Lab.kinds.Font.methods.CopyFontObject(font, base) end
        end
        local fp = S[font].fp
        if a.font then fp.file = a.font end
        if a.height then fp.size = tonumber(a.height) end
        local flags = {}
        if a.outline == "NORMAL" then flags[#flags + 1] = "OUTLINE" elseif a.outline == "THICK" then flags[#flags + 1] = "THICKOUTLINE" end
        if a.monochrome == "true" then flags[#flags + 1] = "MONOCHROME" end
        if a.outline or a.monochrome then fp.flags = table.concat(flags, ",") end
        if a.justifyH then fp.jh = a.justifyH:upper() end
        if a.justifyV then fp.jv = a.justifyV:upper() end
        if a.spacing then fp.spacing = tonumber(a.spacing) end
        for _, c in ipairs(el.children) do
            local tag = c.tag
            if tag == "Color" then
                local r, g, b, al = color(c)
                if r then fp.r, fp.g, fp.b, fp.a = r, g, b, al end
            elseif tag == "Shadow" then
                local off = xml.find(c, "Offset")
                if off then
                    local d = xml.find(off, "AbsDimension") or off
                    fp.sx, fp.sy = num(d.attrs.x) or 0, num(d.attrs.y) or 0
                end
                local col = xml.find(c, "Color")
                if col then fp.sr, fp.sg, fp.sb, fp.sa = color(col) end
            elseif tag == "FontHeight" then
                local v = xml.find(c, "AbsValue")
                if v then fp.size = num(v.attrs.val) end
            end
        end
    end

    function Lab.LoadFontXML(path)
        local doc, err = xml.read(path)
        if not doc then Lab.Note("lab", "font XML " .. path .. ": " .. tostring(err)) return end
        for _, el in ipairs(doc.children) do
            if el.tag == "Font" and el.attrs.name then
                local font = Lab.named[el.attrs.name] or Lab.NewFont(el.attrs.name)
                applyFont(font, el)
            elseif el.tag == "FontFamily" and el.attrs.name then
                local font = Lab.named[el.attrs.name] or Lab.NewFont(el.attrs.name)
                for _, m in ipairs(el.children) do
                    if m.tag == "Member" and m.attrs.alphabet == "roman" then
                        local f = xml.find(m, "Font")
                        if f then applyFont(font, f) end
                    end
                end
            end
        end
    end
    local fonts = BLIZ .. "Blizzard_Fonts_Shared/"
    for _, file in ipairs({ "Mainline/Fonts.xml", "Shared/Fonts.xml", "Shared/GameFonts.xml", "Mainline/GameFonts.xml",
        "Shared/FontStyles.xml", "Mainline/FontStyles.xml", "Mainline/GameFontStyles.xml", "Shared/GameFontStyles.xml" }) do
        local f = io.open(fonts .. file)
        if f then f:close(); Lab.LoadFontXML(fonts .. file) end
    end
    -- The few the lab needs should the XML be missing.
    for name, def in pairs({ GameFontNormal = { 12, 1, 0.82, 0 }, GameFontHighlight = { 12, 1, 1, 1 },
        GameTooltipHeaderText = { 14, 1, 1, 1 }, GameTooltipText = { 12, 1, 1, 1 }, ChatFontNormal = { 14, 1, 1, 1 } }) do
        if not Lab.named[name] then
            local f = Lab.NewFont(name)
            S[f].fp = { file = "Fonts\\FRIZQT__.TTF", size = def[1], r = def[2], g = def[3], b = def[4], a = 1, sx = 1, sy = -1, sr = 0, sg = 0, sb = 0, sa = 1 }
        end
    end
end
