-- Texts: fonts and font objects, the game's escape sequences (|c colours, |T pictures, |H links, |n), and how a
-- text is broken into lines, cut with "..." and placed, measured with the font file's own advance widths (the
-- lab's server reads them; the page draws each line where the lab put it, so both agree).
return function(Lab)
    local S = Lab.S
    local Region = Lab.kinds.Region.methods
    local FS = Lab.kinds.FontString.methods
    local Font = Lab.kinds.Font.methods

    -- Font files ---------------------------------------------------------------------------------------------------
    local metrics = {}
    function Lab.Metrics(file)
        if not file then return nil end
        local key = file:gsub("/", "\\"):lower()
        local m = metrics[key]
        if m == nil then
            local answer = Lab.Ask({ need = "font", file = file })
            if answer and answer.ok then
                m = { adv = {}, url = answer.url }
                for k, v in pairs(answer.adv) do m.adv[tonumber(k)] = v end
                m.fallback = m.adv[63] or 0.5
            else
                m = false
                Lab.Warn("font file not found: " .. file)
            end
            metrics[key] = m
        end
        return m or nil
    end

    -- Font properties: a font string's own, else its font object's, else that one's (SetFontObject links them).
    local FIELDS = { "file", "size", "flags", "r", "g", "b", "a", "sx", "sy", "sr", "sg", "sb", "sa", "jh", "jv", "spacing" }
    function Lab.FontProps(o)
        local out = {}
        local s = S[o]
        local depth = 0
        while s and depth < 10 do
            local fp = s.fp
            if fp then
                for _, f in ipairs(FIELDS) do
                    if out[f] == nil then out[f] = fp[f] end
                end
            end
            s = s.fontObject and S[s.fontObject]
            depth = depth + 1
        end
        out.r, out.g, out.b, out.a = out.r or 1, out.g or 1, out.b or 1, out.a or 1
        out.jh, out.jv = out.jh or "CENTER", out.jv or "MIDDLE"
        out.spacing = out.spacing or 0
        out.flags = out.flags or ""
        return out
    end

    local function fp(o)
        local s = S[o]
        s.fp = s.fp or {}
        return s.fp
    end

    local function changed(o)
        local s = S[o]
        s.layout = nil
        if s.kind == "Font" then
            for other, st in pairs(S) do if st.fontObject == o then st.layout = nil end end
        end
        Lab.Touch()
    end
    Lab.TextChanged = changed

    local function fontObject(f)
        if type(f) == "string" then f = Lab.G[f] end
        return f
    end

    -- Methods of fonts and font strings alike ----------------------------------------------------------------------
    local Shared = {}
    function Shared:SetFont(file, size, flags)
        Lab.Check(file, "string", "SetFont", 1)
        Lab.Check(size, "number", "SetFont", 2)
        local p = fp(self)
        p.file, p.size, p.flags = file, tonumber(size), flags or ""
        changed(self)
        return Lab.Metrics(file) ~= nil
    end
    function Shared:GetFont()
        local p = Lab.FontProps(self)
        return p.file, p.size, p.flags
    end
    function Shared:SetFontObject(f)
        local s = S[self]
        f = fontObject(f)
        if f ~= nil and not (S[f] and (S[f].kind == "Font" or S[f].kind == "FontString")) then
            error("SetFontObject(): not a font object", 2)
        end
        s.fontObject = f
        if s.fp then s.fp.file, s.fp.size, s.fp.flags = nil, nil, nil end
        changed(self)
    end
    function Shared:GetFontObject() return S[self].fontObject end
    function Shared:SetTextColor(r, g, b, a)
        local p = fp(self)
        if type(r) == "table" then r, g, b, a = r.r, r.g, r.b, r.a end
        p.r, p.g, p.b, p.a = r, g, b, a or 1
        changed(self)
    end
    function Shared:GetTextColor()
        local p = Lab.FontProps(self)
        return p.r, p.g, p.b, p.a
    end
    function Shared:SetShadowColor(r, g, b, a)
        local p = fp(self)
        p.sr, p.sg, p.sb, p.sa = r, g, b, a or 1
        changed(self)
    end
    function Shared:GetShadowColor()
        local p = Lab.FontProps(self)
        return p.sr or 0, p.sg or 0, p.sb or 0, p.sa or 0
    end
    function Shared:SetShadowOffset(x, y)
        local p = fp(self)
        p.sx, p.sy = x, y
        changed(self)
    end
    function Shared:GetShadowOffset()
        local p = Lab.FontProps(self)
        return p.sx or 0, p.sy or 0
    end
    local JH = { LEFT = true, CENTER = true, RIGHT = true }
    local JV = { TOP = true, MIDDLE = true, BOTTOM = true }
    function Shared:SetJustifyH(j)
        j = tostring(j):upper()
        if not JH[j] then error("SetJustifyH(): invalid justification " .. j, 2) end
        fp(self).jh = j
        changed(self)
    end
    function Shared:GetJustifyH() return Lab.FontProps(self).jh end
    function Shared:SetJustifyV(j)
        j = tostring(j):upper()
        if not JV[j] then error("SetJustifyV(): invalid justification " .. j, 2) end
        fp(self).jv = j
        changed(self)
    end
    function Shared:GetJustifyV() return Lab.FontProps(self).jv end
    function Shared:SetSpacing(n) fp(self).spacing = n; changed(self) end
    function Shared:GetSpacing() return Lab.FontProps(self).spacing end
    function Shared:SetIndentedWordWrap(on) S[self].indented = on and true or nil; changed(self) end
    function Shared:GetIndentedWordWrap() return S[self].indented or false end
    for k, v in pairs(Shared) do FS[k] = v; Font[k] = v end

    function Font:CopyFontObject(src)
        src = fontObject(src)
        local p = Lab.FontProps(src)
        local mine = fp(self)
        for _, f in ipairs(FIELDS) do mine[f] = p[f] end
        changed(self)
    end
    function Font:GetAlpha() return Lab.FontProps(self).a end
    function Font:SetAlpha(a) fp(self).a = a; changed(self) end

    -- Escape sequences ----------------------------------------------------------------------------------------------
    -- Lab.Parse(text, r, g, b) -> tokens: { t = text, c = {r, g, b}, link = } | { tex = file, w =, h =, coords = }
    -- | { br = true }
    local function hex(s) return tonumber(s, 16) / 255 end
    function Lab.Parse(text, r, g, b)
        local tokens = {}
        local colors = { { r, g, b } }
        local link
        local i, n = 1, #text
        local buf = {}
        local function flush()
            if #buf > 0 then
                tokens[#tokens + 1] = { t = table.concat(buf), c = colors[#colors], link = link }
                buf = {}
            end
        end
        while i <= n do
            local c = text:sub(i, i)
            if c == "\n" then
                flush(); tokens[#tokens + 1] = { br = true }; i = i + 1
            elseif c == "|" and i < n then
                local e = text:sub(i + 1, i + 1)
                if e == "|" then
                    buf[#buf + 1] = "|"; i = i + 2
                elseif e == "n" then
                    flush(); tokens[#tokens + 1] = { br = true }; i = i + 2
                elseif e == "c" and text:sub(i + 2, i + 2) == "n" then
                    local name, stop = text:match("^cn([%w_]+):()", i + 1)
                    if name then
                        flush()
                        local color = Lab.G[name]
                        if type(color) == "table" and color.r then
                            colors[#colors + 1] = { color.r, color.g, color.b }
                        else
                            colors[#colors + 1] = colors[#colors]
                        end
                        i = stop
                    else
                        buf[#buf + 1] = "|"; i = i + 1
                    end
                elseif e == "c" and text:sub(i + 2, i + 9):match("^%x%x%x%x%x%x%x%x$") then
                    flush()
                    local h = text:sub(i + 4, i + 9)
                    colors[#colors + 1] = { hex(h:sub(1, 2)), hex(h:sub(3, 4)), hex(h:sub(5, 6)) }
                    i = i + 10
                elseif e == "r" then
                    flush()
                    if #colors > 1 then colors[#colors] = nil end
                    i = i + 2
                elseif e == "T" or e == "A" then
                    local close = text:find("|" .. e:lower(), i + 2, true)
                    if close then
                        flush()
                        local spec = text:sub(i + 2, close - 1)
                        local parts = {}
                        for part in (spec .. ":"):gmatch("([^:]*):") do parts[#parts + 1] = part end
                        local tok = { tex = parts[1], atlas = e == "A" or nil, h = tonumber(parts[2]) or 0, w = tonumber(parts[3]),
                            ox = tonumber(parts[4]) or 0, oy = tonumber(parts[5]) or 0 }
                        if e == "T" and #parts >= 11 then
                            local tw, th = tonumber(parts[6]), tonumber(parts[7])
                            local l, r2, t, b2 = tonumber(parts[8]), tonumber(parts[9]), tonumber(parts[10]), tonumber(parts[11])
                            if tw and th and l then tok.coords = { l / tw, r2 / tw, t / th, b2 / th } end
                        end
                        tokens[#tokens + 1] = tok
                        i = close + 2
                    else
                        buf[#buf + 1] = "|"; i = i + 1
                    end
                elseif e == "H" then
                    local stop = text:find("|h", i + 2, true)
                    if stop then
                        flush()
                        link = text:sub(i + 2, stop - 1)
                        i = stop + 2
                    else
                        buf[#buf + 1] = "|"; i = i + 1
                    end
                elseif e == "h" then
                    flush(); link = nil; i = i + 2
                elseif e == "K" then
                    local stop = text:find("|k", i + 2, true)
                    buf[#buf + 1] = "???"
                    i = stop and stop + 2 or n + 1
                elseif e == "4" then
                    local a, b2, stop = text:match("^4([^:]*):([^;]*);()", i + 1)
                    if a then
                        local before = table.concat(buf):match("(%d+)%s*$")
                        buf[#buf + 1] = (tonumber(before) == 1) and a or b2
                        i = stop
                    else
                        buf[#buf + 1] = "|"; i = i + 1
                    end
                else
                    buf[#buf + 1] = "|"; i = i + 1
                end
            else
                local stop = text:find("[|\n]", i) or n + 1
                buf[#buf + 1] = text:sub(i, stop - 1)
                i = stop
            end
        end
        flush()
        return tokens
    end

    -- Measuring -----------------------------------------------------------------------------------------------------
    local CHAR = "[%z\1-\127\194-\244][\128-\191]*"
    local function codepoint(ch)
        local b1 = ch:byte(1)
        if b1 < 0x80 then return b1 end
        if b1 < 0xE0 then return (b1 - 0xC0) * 64 + (ch:byte(2) - 0x80) end
        if b1 < 0xF0 then return (b1 - 0xE0) * 4096 + (ch:byte(2) - 0x80) * 64 + (ch:byte(3) - 0x80) end
        return (b1 - 0xF0) * 262144 + (ch:byte(2) - 0x80) * 4096 + (ch:byte(3) - 0x80) * 64 + (ch:byte(4) - 0x80)
    end

    local function measure(m, size, text)
        if not m then return #text * size * 0.5 end
        local w = 0
        local adv, fb = m.adv, m.fallback
        for ch in text:gmatch(CHAR) do
            w = w + (adv[codepoint(ch)] or fb)
        end
        return w * size
    end
    Lab.Measure = measure

    -- Lines --------------------------------------------------------------------------------------------------------
    -- Lab.Lines(o, maxWidth) lays out a font string's text: lines of items, each with its x, its width and what it
    -- shows; no maxWidth: lines only where the text breaks them.
    local function newLine() return { items = {}, w = 0 } end

    local function addText(line, text, tok, w)
        local last = line.items[#line.items]
        if last and last.t and last.c == tok.c and last.link == tok.link then
            last.t = last.t .. text
            last.w = last.w + w
        else
            line.items[#line.items + 1] = { t = text, c = tok.c, link = tok.link, x = line.w, w = w }
        end
        line.w = line.w + w
    end

    local function trimEnd(line, m, size)
        local last = line.items[#line.items]
        while last and last.t do
            local trimmed = last.t:gsub("%s+$", "")
            if trimmed == last.t then break end
            local cut = measure(m, size, last.t:sub(#trimmed + 1))
            last.t, last.w = trimmed, last.w - cut
            line.w = line.w - cut
            if trimmed ~= "" then break end
            line.items[#line.items] = nil
            last = line.items[#line.items]
        end
    end

    function Lab.Lines(o, maxWidth)
        local s = S[o]
        local p = Lab.FontProps(o)
        local size = p.size or 12
        local m = Lab.Metrics(p.file)
        local tokens = Lab.Parse(s.text or "", p.r, p.g, p.b)
        local wrap = s.wrap ~= false and maxWidth and maxWidth > 0
        local lines = { newLine() }
        local line = lines[1]
        local function breakLine()
            trimEnd(line, m, size)
            line = newLine()
            lines[#lines + 1] = line
            if s.indented then line.w = size end
        end
        for _, tok in ipairs(tokens) do
            if tok.br then
                breakLine()
            elseif tok.tex then
                local h = (tok.h and tok.h > 0) and tok.h or size
                local w = tok.w and tok.w > 0 and tok.w or h
                if wrap and line.w + w > maxWidth + 0.01 and #line.items > 0 then breakLine() end
                line.items[#line.items + 1] = { tex = tok.tex, atlas = tok.atlas, coords = tok.coords, x = line.w, w = w, h = h,
                    ox = tok.ox, oy = tok.oy }
                line.w = line.w + w
            else
                for space, word in tok.t:gmatch("(%s*)(%S*)") do
                    if space ~= "" then
                        local w = measure(m, size, space)
                        if not (wrap and #line.items == 0 and #lines > 1) then addText(line, space, tok, w) end
                    end
                    if word ~= "" then
                        local w = measure(m, size, word)
                        if wrap and line.w + w > maxWidth + 0.01 and line.w > 0 then breakLine() end
                        if wrap and w > maxWidth and s.nonSpaceWrap then
                            for ch in word:gmatch(CHAR) do
                                local cw = measure(m, size, ch)
                                if line.w + cw > maxWidth + 0.01 and line.w > 0 then breakLine() end
                                addText(line, ch, tok, cw)
                            end
                        else
                            addText(line, word, tok, w)
                        end
                    end
                end
            end
        end
        trimEnd(line, m, size)
        return lines, size, p, m
    end

    -- Cuts the line to width w with "..." at its end.
    local function ellipsis(line, w, m, size)
        local dots = measure(m, size, "...")
        while #line.items > 0 and line.w + dots > w + 0.01 do
            local last = line.items[#line.items]
            if last.t and #last.t > 1 then
                local chars = {}
                for ch in last.t:gmatch(CHAR) do chars[#chars + 1] = ch end
                local cut = measure(m, size, chars[#chars])
                chars[#chars] = nil
                last.t = table.concat(chars)
                last.w = last.w - cut
                line.w = line.w - cut
            else
                line.w = line.w - last.w
                line.items[#line.items] = nil
            end
        end
        trimEnd(line, m, size)
        local last = line.items[#line.items]
        if last and last.t then
            last.t = last.t .. "..."
            last.w = last.w + dots
        else
            line.items[#line.items + 1] = { t = "...", c = last and last.c or nil, x = line.w, w = dots }
        end
        line.w = line.w + dots
    end

    -- The text laid out in a box w x h (own units; h nil: as high as it needs): lines with x and y from the box's
    -- top left, and whether it was cut.
    function Lab.TextLayout(o, w, h)
        local s = S[o]
        local lines, size, p, m = Lab.Lines(o, w)
        local spacing = p.spacing or 0
        local limit = (s.maxLines and s.maxLines > 0) and s.maxLines or nil
        if h and h > 0 then
            local fit = math.max(1, math.floor((h + spacing) / (size + spacing) + 0.01))
            limit = limit and math.min(limit, fit) or fit
        end
        local truncated = false
        if limit and #lines > limit then
            for i = #lines, limit + 1, -1 do lines[i] = nil end
            ellipsis(lines[limit], w or lines[limit].w, m, size)
            truncated = true
        end
        if w and w > 0 and (s.wrap == false or not w) then
            for _, line in ipairs(lines) do
                if line.w > w + 0.5 then ellipsis(line, w, m, size); truncated = true end
            end
        end
        local total = #lines * size + math.max(0, #lines - 1) * spacing
        local top = 0
        if h then
            if p.jv == "MIDDLE" then top = (h - total) / 2 elseif p.jv == "BOTTOM" then top = h - total end
        end
        for i, line in ipairs(lines) do
            line.y = top + (i - 1) * (size + spacing)
            local bw = w or line.w
            if p.jh == "CENTER" then line.x = (bw - line.w) / 2
            elseif p.jh == "RIGHT" then line.x = bw - line.w
            else line.x = 0 end
        end
        return { lines = lines, size = size, props = p, metrics = m, truncated = truncated, height = total }
    end

    -- A font string's own size where nothing else gives it one: as wide as its text, as high as its lines.
    local function intrinsic(o, width)
        local s = S[o]
        if (s.text or "") == "" then return 0, 0 end
        local lines, size, p = Lab.Lines(o, width)
        local w = 0
        for _, line in ipairs(lines) do if line.w > w then w = line.w end end
        if s.maxLines and s.maxLines > 0 and #lines > s.maxLines then
            for i = #lines, s.maxLines + 1, -1 do lines[i] = nil end
        end
        local h = #lines * size + math.max(0, #lines - 1) * (p.spacing or 0)
        return math.ceil(w), h
    end
    Lab.TextIntrinsic = intrinsic

    -- Font strings ----------------------------------------------------------------------------------------------------
    function Lab.NewFontString(parent, name, layer, inherits, sub)
        local fs = Lab.New("FontString", { name = name, parent = parent, shown = true, layer = layer or "ARTWORK",
            sub = sub or 0, text = "", intrinsic = intrinsic })
        -- inherits: a font string template (from XML), else a font object, as the game takes either
        if inherits and Lab.templates[inherits] then Lab.ApplyTemplate(fs, inherits)
        elseif inherits then FS.SetFontObject(fs, inherits) end
        return fs
    end

    function FS:SetText(text)
        if text ~= nil and type(text) ~= "string" and type(text) ~= "number" then
            error("SetText(): text must be a string or a number", 2)
        end
        local s = S[self]
        text = text and tostring(text) or ""
        if s.text ~= text then
            s.text = text
            changed(self)
        end
    end
    function FS:GetText()
        local t = S[self].text
        if t == "" then return nil end
        return t
    end
    function FS:SetFormattedText(fmt, ...) FS.SetText(self, string.format(fmt, ...)) end
    function FS:SetWordWrap(on) S[self].wrap = on and true or false; changed(self) end
    function FS:CanWordWrap() return S[self].wrap ~= false end
    function FS:SetNonSpaceWrap(on) S[self].nonSpaceWrap = on and true or nil; changed(self) end
    function FS:CanNonSpaceWrap() return S[self].nonSpaceWrap or false end
    function FS:SetMaxLines(n) S[self].maxLines = n; changed(self) end
    function FS:GetMaxLines() return S[self].maxLines or 0 end
    function FS:SetTextScale(n) S[self].textScale = n; changed(self) end
    function FS:GetTextScale() return S[self].textScale or 1 end
    function FS:SetTextHeight(h)
        local p = fp(self)
        p.size = h
        changed(self)
    end

    local function box(self)
        local l, b, w, h = Lab.Rect(self)
        local sc = Lab.EScale(self)
        if l then return w / sc, h / sc end
        local s = S[self]
        return s.w, s.h
    end
    function FS:GetStringWidth()
        local w = box(self)
        local lines = Lab.Lines(self, w)
        local max = 0
        for _, line in ipairs(lines) do if line.w > max then max = line.w end end
        return max
    end
    function FS:GetUnboundedStringWidth()
        local w = intrinsic(self, nil)
        return w
    end
    function FS:GetWrappedWidth() return FS.GetStringWidth(self) end
    function FS:GetStringHeight()
        local w, h = box(self)
        local layout = Lab.TextLayout(self, w, nil)
        return layout.height
    end
    function FS:GetNumLines()
        local w = box(self)
        return #(Lab.Lines(self, w))
    end
    function FS:IsTruncated()
        local w, h = box(self)
        return Lab.TextLayout(self, w, h).truncated
    end
    function FS:GetLineHeight() return Lab.FontProps(self).size or 12 end
    function FS:SetAlphaGradient() end
    function FS:SetFixedColor() end
    function FS:CalculateScreenAreaFromCharacterSpan() end
    function FS:FindCharacterIndexAtCoordinate() end

    -- Font objects --------------------------------------------------------------------------------------------------
    function Lab.NewFont(name)
        return Lab.New("Font", { name = name, shown = true, fp = {} })
    end
end
