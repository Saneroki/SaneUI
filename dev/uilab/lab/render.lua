-- Drawing: every region that is seen, in the game's order (strata, level, then draw layer and sublevel), turned
-- into what the page draws, in the screen's pixels with the top left at 0, 0. Only what changed since the last
-- drawing goes to the page.
return function(Lab)
    local S = Lab.S
    local json = require("json")

    local last = {}         -- [id] = the JSON the page has for it
    function Lab.ResetDrawing() last = {} end

    -- Frames in the order the game draws them, those seen only.
    local orderCache
    function Lab.FrameOrder()
        if orderCache and not Lab.rectsDirtyOrder and Lab.rects then return orderCache end
        local list = {}
        for _, f in ipairs(Lab.frames) do
            if Lab.Visible(f) then list[#list + 1] = f end
        end
        local STRATA = Lab.STRATA
        table.sort(list, function(a, b)
            local x, y = S[a], S[b]
            local sa, sb = STRATA[x.strata] or 4, STRATA[y.strata] or 4
            if sa ~= sb then return sa < sb end
            if x.level ~= y.level then return x.level < y.level end
            return x.order < y.order
        end)
        orderCache = list
        return list
    end

    -- The clip rectangle a frame's children are drawn in (cursor space), or nil for none.
    local clips = {}
    function Lab.ClipOf(f)
        if not f then return nil end
        local c = clips[f]
        if c ~= nil then return c or nil end
        local parent = Lab.ClipOf(S[f].parent)
        local mine
        if S[f].clips then
            local l, b, w, h = Lab.Rect(f)
            if l then mine = { l, b, w, h } end
        end
        if mine and parent then
            local x1, y1 = math.max(mine[1], parent[1]), math.max(mine[2], parent[2])
            local x2 = math.min(mine[1] + mine[3], parent[1] + parent[3])
            local y2 = math.min(mine[2] + mine[4], parent[2] + parent[4])
            mine = { x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1) }
        end
        c = mine or parent or false
        clips[f] = c
        return c or nil
    end

    local function hex(r, g, b)
        local function c(v) return math.max(0, math.min(255, math.floor((v or 1) * 255 + 0.5))) end
        return string.format("%02x%02x%02x", c(r), c(g), c(b))
    end

    local P, SH
    local function px(l, b, w, h)
        return l * P, (SH - (b + h)) * P, w * P, h * P
    end
    local function r2(v) return math.floor(v * 100 + 0.5) / 100 end
    local function r2s(v) return math.floor(v * 10000 + 0.5) / 10000 end
    local function now() return Lab.G.GetTime() end

    local LAYERS = Lab.LAYERS
    local function regionOrder(a, b)
        local x, y = S[a], S[b]
        local la, lb = LAYERS[x.layer] or 3, LAYERS[y.layer] or 3
        if la ~= lb then return la < lb end
        if (x.sub or 0) ~= (y.sub or 0) then return (x.sub or 0) < (y.sub or 0) end
        return x.order < y.order
    end

    local function highlightShown(f)
        local s = S[f]
        if s.highlightLocked then return true end
        return Lab.focus == f and (s.mouse or s.motion) and s.enabled ~= false
    end

    local function maskData(r, l, b, w, h)
        local out
        for _, m in ipairs(S[r].masks or {}) do
            local ms = S[m]
            local ml, mb, mw, mh = Lab.Rect(m)
            if ml and ms.file then
                out = out or {}
                out[#out + 1] = { f = ms.file, x = r2((ml - l) * P), y = r2(((b + h) - (mb + mh)) * P), w = r2(mw * P), h = r2(mh * P),
                    cw = ms.wrapH == "CLAMPTOWHITE" and ms.wrapV == "CLAMPTOWHITE" and 1 or nil }
            end
        end
        return out
    end

    local function textItem(r, s, l, b, w, h, sc)
        local layout = Lab.TextLayout(r, w / sc, h / sc)
        s.drawn = { l = l, top = b + h, sc = sc, layout = layout }
        local p = layout.props
        local k = P * sc
        local lines = {}
        local defaultColor = hex(p.r, p.g, p.b)
        for _, line in ipairs(layout.lines) do
            local items = {}
            for _, it in ipairs(line.items) do
                if it.t then
                    if it.t ~= "" then
                        local c = it.c and hex(it.c[1], it.c[2], it.c[3]) or defaultColor
                        items[#items + 1] = { t = it.t, x = r2(it.x * k), c = c ~= defaultColor and c or nil, u = it.link and 1 or nil }
                    end
                else
                    items[#items + 1] = { tex = it.tex, atlas = it.atlas, x = r2(it.x * k), w = r2(it.w * k), h = r2(it.h * k),
                        tc = it.coords }
                end
            end
            lines[#lines + 1] = { x = r2(line.x * k), y = r2(line.y * k), i = items }
        end
        local item = { k = "f", font = layout.metrics and layout.metrics.url or nil, size = r2(layout.size * k), c = defaultColor,
            ca = p.a ~= 1 and r2(p.a) or nil, lines = lines, flags = p.flags ~= "" and p.flags or nil }
        if p.sx and (p.sx ~= 0 or p.sy ~= 0) and (p.sa or 0) > 0 then
            item.sh = { r2(p.sx * k), r2(-p.sy * k), hex(p.sr, p.sg, p.sb), r2(p.sa or 1) }
        end
        return item
    end

    local function textureItem(r, s, l, b, w, h, sc)
        local item
        if s.color and not s.file then
            item = { k = "c", c = hex(s.color[1], s.color[2], s.color[3]), ca = r2(s.color[4] or 1) }
        elseif s.file then
            item = { k = "t", f = s.file }
            local c = s.coords
            if s.fillOf and S[s.fillOf] then
                local bs = S[s.fillOf]
                local f = s.fillFraction or 1
                c = c or { 0, 1, 0, 1 }
                if bs.orientation == "VERTICAL" then
                    c = bs.reverse and { c[1], c[2], c[3], c[3] + (c[4] - c[3]) * f } or { c[1], c[2], c[4] - (c[4] - c[3]) * f, c[4] }
                else
                    c = bs.reverse and { c[2] - (c[2] - c[1]) * f, c[2], c[3], c[4] } or { c[1], c[1] + (c[2] - c[1]) * f, c[3], c[4] }
                end
            end
            if c and not (c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 1) then
                item.tc = { r2s(c[1]), r2s(c[2]), r2s(c[3]), r2s(c[4]) }
            end
            if s.coords8 then
                local t = {}
                for i, v in ipairs(s.coords8) do t[i] = r2s(v) end
                item.tc8 = t
            end
            if s.wrapH == "REPEAT" or s.wrapH == true then item.rx = 1 end
            if s.wrapV == "REPEAT" or s.wrapV == true then item.ry = 1 end
            if s.htile then item.ht = 1 end
            if s.vtile then item.vt = 1 end
            if s.slice then
                item.sl = s.slice
                item.slm = s.sliceMode
                if s.atlas and s.atlasW then item.aw, item.ah = r2(s.atlasW), r2(s.atlasH) end
            end
            item.u = r2(P * sc)
        else
            return nil
        end
        if s.vc and not (s.vc[1] == 1 and s.vc[2] == 1 and s.vc[3] == 1) then item.vc = hex(s.vc[1], s.vc[2], s.vc[3]) end
        if s.vc and s.vc[4] and s.vc[4] ~= 1 then item.va = r2(s.vc[4]) end
        if s.desat then item.ds = r2(s.desat) end
        if s.blend and s.blend ~= "BLEND" then item.bl = s.blend end
        if s.rotation then item.rot = r2(s.rotation) end
        if s.gradient then
            local g = s.gradient
            item.gr = { g.o, hex(g.from[1], g.from[2], g.from[3]), r2(g.from[4]), hex(g.to[1], g.to[2], g.to[3]), r2(g.to[4]) }
        end
        item.m = maskData(r, l, b, w, h)
        return item
    end

    local function caretItems(f, add)
        local s = S[f]
        local fs = s.textRegion
        local fss = S[fs]
        local l, b, w, h = Lab.Rect(fs)
        if not l then return end
        local sc = Lab.EScale(fs)
        local layout = Lab.TextLayout(fs, w / sc, h / sc)
        local size = layout.size
        local shown = fss.text or ""
        local prefix = shown:sub(1, s.cursor)
        if s.password then prefix = string.rep("*", #prefix:gsub("[\128-\191]", "")) end
        local line = layout.lines[1] or { x = 0, y = 0 }
        local cx = line.x + Lab.Measure(layout.metrics, size, prefix)
        local top = (b + h) - line.y * sc
        if s.multi then
            -- the caret after the text before it, laid out alone at the box's width
            local text = fss.text
            fss.text = prefix
            local lines = Lab.Lines(fs, w / sc)
            fss.text = text
            local last = lines[#lines]
            cx = last and last.w or 0
            top = (b + h) - (#lines - 1) * (size + (layout.props.spacing or 0)) * sc
        end
        if s.select then
            local x1 = line.x + Lab.Measure(layout.metrics, size, shown:sub(1, s.select[1]))
            local x2 = line.x + Lab.Measure(layout.metrics, size, shown:sub(1, s.select[2]))
            local hl = s.highlightColor or { 0.3, 0.5, 1, 0.5 }
            add(f, "s", { k = "c", c = hex(hl[1], hl[2], hl[3]), ca = hl[4] }, l + x1 * sc, top - size * sc, (x2 - x1) * sc, size * sc)
        end
        if (Lab.time % 1) < 0.55 then
            add(f, "c", { k = "c", c = "ffffff", ca = 1 }, l + cx * sc, top - size * sc, 1.5 * sc, size * sc)
        end
    end

    -- The drawing: what changed since the last one, by id; false for what is gone.
    function Lab.Render()
        P, SH = Lab.screen.ph / 768, Lab.SH
        clips = {}
        orderCache = nil
        -- What lays itself out before it is drawn: message frames, tooltips.
        for _, f in ipairs(Lab.frames) do
            local s = S[f]
            if s.messageFrame and Lab.Visible(f) then Lab.LayoutMessages(f) end
            if s.kind == "GameTooltip" and s.shown and s.owner and S[s.owner] and not Lab.Visible(s.owner) then
                Lab.kinds.Frame.methods.Hide(f)
            end
        end
        local drawn = {}
        local z = 0
        local function add(o, suffix, item, l, b, w, h, clip)
            z = z + 1
            local x, y, pw, ph = px(l, b, w, h)
            if item.k ~= "f" and item.k ~= "l" then
                -- on the screen's pixels, as the game snaps textures (SetSnapToPixelGrid): neighbours meet exactly
                local x2, y2 = math.floor(x + pw + 0.5), math.floor(y + ph + 0.5)
                x, y = math.floor(x + 0.5), math.floor(y + 0.5)
                pw, ph = x2 - x, y2 - y
                if pw <= 0 or ph <= 0 then return end
            end
            item.z, item.x, item.y, item.w, item.h = z, r2(x), r2(y), r2(pw), r2(ph)
            if clip then
                local cx, cy, cw, ch = px(clip[1], clip[2], clip[3], clip[4])
                item.cl = { r2(cx), r2(cy), r2(cw), r2(ch) }
            end
            local id = tostring(S[o].order) .. (suffix or "")
            drawn[id] = json.encode(item)
        end
        for _, f in ipairs(Lab.FrameOrder()) do
            local fs = S[f]
            local falpha = Lab.EAlpha(f)
            local clip = Lab.ClipOf(f)
            local regions = {}
            for _, r in ipairs(fs.regions) do regions[#regions + 1] = r end
            table.sort(regions, regionOrder)
            local hl = highlightShown(f)
            for _, r in ipairs(regions) do
                local s = S[r]
                local seen = s.shown and not s.mask and not (fs.offLayers and fs.offLayers[s.layer])
                if seen and s.layer == "HIGHLIGHT" and not s.role then seen = hl end
                if seen and s.role then seen = Lab.RoleShown(r) end
                if seen then
                    local l, b, w, h = Lab.Rect(r)
                    if s.kind == "Line" then
                        local x1, y1, x2, y2 = Lab.LineEnds(r)
                        if x1 then
                            local item = textureItem(r, s, x1, y1, 0, 0, 1) or { k = "c", c = "ffffff", ca = 1 }
                            item.k = "l"
                            local p1x, p1y = px(x1, y1, 0, 0)
                            local p2x, p2y = px(x2, y2, 0, 0)
                            item.line = { r2(p1x), r2(p1y), r2(p2x), r2(p2y), r2((s.thickness or 1) * Lab.EScale(r) * P) }
                            item.a = r2(falpha * s.alpha * (s.animAlpha or 1))
                            add(r, nil, item, 0, SH, 0, 0, clip)
                        end
                    elseif l and w > 0 and h > 0 then
                        local sc = Lab.EScale(r)
                        local item
                        if s.kind == "FontString" then
                            if (s.text or "") ~= "" then
                                local dx, dy = 0, 0
                                if s.role == "text" and S[s.parent].pushed and S[s.parent].enabled ~= false then
                                    local off = S[s.parent].pushedOffset or { 0, 0 }
                                    dx, dy = off[1] * sc, off[2] * sc
                                end
                                item = textItem(r, s, l + dx, b + dy, w, h, sc)
                                l, b = l + dx, b + dy
                            end
                        else
                            item = textureItem(r, s, l, b, w, h, sc)
                        end
                        if item then
                            local a = falpha * s.alpha * (s.animAlpha or 1)
                            if not s.ignoreParentAlpha then a = a else a = s.alpha end
                            if a < 1 then item.a = r2(a) end
                            local rclip = clip
                            if s.editOf then
                                local el, eb, ew, eh = Lab.Rect(s.editOf)
                                if el then
                                    rclip = rclip and {
                                        math.max(el, rclip[1]), math.max(eb, rclip[2]),
                                        math.min(el + ew, rclip[1] + rclip[3]) - math.max(el, rclip[1]),
                                        math.min(eb + eh, rclip[2] + rclip[4]) - math.max(eb, rclip[2]) } or { el, eb, ew, eh }
                                end
                            end
                            add(r, nil, item, l, b, w, h, rclip)
                        end
                    end
                end
            end
            -- What a frame draws besides its regions.
            local l, b, w, h = Lab.Rect(f)
            if l and w > 0 and h > 0 then
                if fs.kind == "Cooldown" and fs.cdStart and fs.cdDuration and fs.cdDuration > 0 then
                    local left = 1 - (now() - fs.cdStart) / fs.cdDuration
                    if left > 0 then
                        local sw = fs.swipe or { 0, 0, 0, 0.8 }
                        add(f, "cd", { k = "cd", left = r2(left), c = hex(sw[1], sw[2], sw[3]), ca = r2(sw[4]), a = r2(falpha) }, l, b, w, h, clip)
                    end
                elseif (fs.kind == "Model" or fs.kind == "PlayerModel" or fs.kind == "DressUpModel") and fs.model then
                    add(f, "m", { k = "m", what = tostring(fs.model[2] or fs.model[1]), a = r2(falpha) }, l, b, w, h, clip)
                elseif fs.kind == "EditBox" and Lab.editFocus == f then
                    caretItems(f, function(o, suffix, item, x, y, cw, ch) item.a = r2(falpha); add(o, suffix, item, x, y, cw, ch, clip) end)
                end
            end
            -- Sizes changed: OnSizeChanged, as the game tells it after laying out.
            if l and (fs.scripts.OnSizeChanged or (fs.hooks and fs.hooks.OnSizeChanged)) then
                local sc = Lab.EScale(f)
                local sw, sh = (w or 0) / sc, (h or 0) / sc
                local was = fs.lastSize
                if not was or math.abs(was[1] - sw) > 0.01 or math.abs(was[2] - sh) > 0.01 then
                    fs.lastSize = { sw, sh }
                    if was then Lab.Run(f, "OnSizeChanged", sw, sh) end
                end
            end
            if fs.kind == "ScrollFrame" and fs.scripts.OnScrollRangeChanged then
                local xr, yr = f:GetHorizontalScrollRange(), f:GetVerticalScrollRange()
                local was = fs.lastRange
                if not was or was[1] ~= xr or was[2] ~= yr then
                    fs.lastRange = { xr, yr }
                    Lab.Run(f, "OnScrollRangeChanged", xr, yr)
                end
            end
        end
        local changes, n = {}, 0
        for id, enc in pairs(drawn) do
            if last[id] ~= enc then changes[id] = enc; n = n + 1 end
        end
        for id in pairs(last) do
            if not drawn[id] then changes[id] = "null"; n = n + 1 end
        end
        last = drawn
        Lab.changed = false
        return changes, n
    end
end
