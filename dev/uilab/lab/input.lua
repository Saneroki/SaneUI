-- The mouse and the keys, as the page sends them: the frame under the mouse (its scripts OnEnter and OnLeave,
-- a button's highlight and its press), clicks, dragging, moving and sizing, the wheel, links in texts, typing.
return function(Lab)
    local S = Lab.S
    local G = Lab.G
    local Button = Lab.kinds.Button.methods

    Lab.focus = nil       -- the frame under the mouse that takes it
    Lab.pressed = nil     -- the frame a button went down on

    local function inside(f, x, y)
        local l, b, w, h = Lab.Rect(f)
        if not l then return false end
        local hit = S[f].hit
        if hit then
            local sc = Lab.EScale(f)
            l, w = l + hit[1] * sc, w - (hit[1] + hit[2]) * sc
            b, h = b + hit[4] * sc, h - (hit[3] + hit[4]) * sc
        end
        if x < l or x > l + w or y < b or y > b + h then return false end
        local clip = Lab.ClipOf and Lab.ClipOf(S[f].parent)
        if clip and (x < clip[1] or x > clip[1] + clip[3] or y < clip[2] or y > clip[2] + clip[4]) then return false end
        return true
    end
    Lab.Inside = inside

    -- The topmost frame under the point that passes the test, as the game finds it: by strata, level, order.
    function Lab.FrameAt(x, y, test)
        local order = Lab.FrameOrder()
        for i = #order, 1, -1 do
            local f = order[i]
            if test(f) and inside(f, x, y) then return f end
        end
    end

    local function takesMouse(f)
        local s = S[f]
        return s.mouse or s.motion
    end

    local function linkAt(f, x, y)
        for _, r in ipairs(S[f].regions) do
            local rs = S[r]
            local d = rs.drawn
            if rs.kind == "FontString" and rs.shown and d and d.layout then
                local lx, ly = (x - d.l) / d.sc, (d.top - y) / d.sc
                for _, line in ipairs(d.layout.lines) do
                    if ly >= line.y and ly <= line.y + d.layout.size then
                        for _, item in ipairs(line.items) do
                            if item.link and lx >= line.x + item.x and lx <= line.x + item.x + item.w then
                                return item.link, item.t, r
                            end
                        end
                    end
                end
            end
        end
    end

    local function setFocus(f)
        if f == Lab.focus then return end
        local old = Lab.focus
        Lab.focus = f
        if old and S[old] then
            Lab.Run(old, "OnLeave", true)
            if S[old].kind == "Button" or S[old].kind == "CheckButton" then Lab.ButtonText(old) end
        end
        if f then
            local s = S[f]
            if not (s.enabled == false and (s.kind == "Button" or s.kind == "CheckButton") and not s.motionDisabled) then
                Lab.Run(f, "OnEnter", true)
            end
            if s.kind == "Button" or s.kind == "CheckButton" then Lab.ButtonText(f) end
        end
        Lab.Touch()
    end

    local function move(x, y)
        Lab.mouse.x, Lab.mouse.y = x, y
        if Lab.moving then
            local m = Lab.moving
            local s = S[m.frame]
            local sc = Lab.EScale(m.frame)
            local nx, ny = m.px + (x - m.x) / sc, m.py + (y - m.y) / sc
            if s.clamped then
                local _, _, w, h = Lab.Rect(m.frame)
                nx = math.max(0, math.min(Lab.SW / sc - w / sc, nx))
                ny = math.max(h / sc, math.min(Lab.SH / sc, ny))
            end
            s.points[1].x, s.points[1].y = nx, ny
            Lab.Touch()
        elseif Lab.sizing then
            local z = Lab.sizing
            local s = S[z.frame]
            local sc = Lab.EScale(z.frame)
            local px, py = Lab.PX[z.point], Lab.PY[z.point]
            local dx, dy = (x - z.x) / sc, (y - z.y) / sc
            local w = z.w + (px == 1 and dx or px == 0 and -dx or 0)
            local h = z.h + (py == 0 and -dy or py == 1 and dy or 0)
            local b = s.bounds
            if b then
                w = math.max(b[1] or 0, w); h = math.max(b[2] or 0, h)
                if b[3] and b[3] > 0 then w = math.min(b[3], w) end
                if b[4] and b[4] > 0 then h = math.min(b[4], h) end
            end
            s.w, s.h = math.max(1, w), math.max(1, h)
            Lab.Touch()
        end
        if Lab.sliding then
            Lab.SlideTo(Lab.sliding, x, y)
        end
        if Lab.dragCandidate and not Lab.dragging then
            local d = Lab.dragCandidate
            if math.abs(x - d.x) + math.abs(y - d.y) > 4 * 768 / Lab.screen.ph then
                Lab.dragging = d.frame
                Lab.Run(d.frame, "OnDragStart", d.button)
            end
        end
        setFocus(Lab.FrameAt(x, y, takesMouse))
        local f = Lab.focus
        if f and S[f].links then
            local link, text = linkAt(f, x, y)
            if link ~= Lab.overLink then
                if Lab.overLink then Lab.Run(Lab.overLinkFrame, "OnHyperlinkLeave", Lab.overLink) end
                Lab.overLink, Lab.overLinkFrame = link, f
                if link then Lab.Run(f, "OnHyperlinkEnter", link, text) end
            end
        elseif Lab.overLink then
            Lab.Run(Lab.overLinkFrame, "OnHyperlinkLeave", Lab.overLink)
            Lab.overLink = nil
        end
        local tip = G.GameTooltip
        if tip and S[tip].shown and (S[tip].anchor or ""):find("^ANCHOR_CURSOR") then Lab.PlaceTooltip(tip) end
    end

    function Lab.SlideTo(f, x, y)
        local s = S[f]
        local l, b, w, h = Lab.Rect(f)
        if not l or s.enabled == false then return end
        local frac
        if s.orientation == "VERTICAL" then frac = 1 - (y - b) / math.max(1, h) else frac = (x - l) / math.max(1, w) end
        frac = math.max(0, math.min(1, frac))
        Lab.SetValue(f, s.min + frac * (s.max - s.min), true)
    end

    local function toplevelOf(f)
        while f do
            if S[f].toplevel then return f end
            f = S[f].parent
        end
    end

    local function down(button, x, y)
        Lab.mouse.buttons[button] = true
        move(x, y)
        Lab.Fire("GLOBAL_MOUSE_DOWN", button) -- what closes Blizzard's menus on a click elsewhere
        local f = Lab.FrameAt(x, y, function(fr) return S[fr].mouse end)
        Lab.pressed = f
        if not f then
            if Lab.editFocus then Lab.ClearEditFocus() end
            return
        end
        local s = S[f]
        if s.kind == "EditBox" then
            if s.enabled then f:SetFocus() end
        elseif Lab.editFocus then
            Lab.ClearEditFocus()
        end
        local top = toplevelOf(f)
        if top then Lab.kinds.Frame.methods.Raise(top) end
        local isButton = s.kind == "Button" or s.kind == "CheckButton"
        if isButton and s.enabled then s.pushed = true; Lab.Touch() end
        if s.kind == "Slider" and s.enabled then Lab.sliding = f; Lab.SlideTo(f, x, y) end
        if s.drag and s.drag[button] then Lab.dragCandidate = { frame = f, button = button, x = x, y = y } end
        if not isButton or s.enabled then Lab.Run(f, "OnMouseDown", button) end
        if isButton and s.enabled and s.clicks[button .. "Down"] then Button.Click(f, button, true) end
    end

    local function up(button, x, y)
        Lab.mouse.buttons[button] = nil
        move(x, y)
        local f = Lab.pressed
        Lab.pressed = nil
        Lab.sliding = nil
        if Lab.dragging then
            local d = Lab.dragging
            Lab.dragging = nil
            Lab.Run(d, "OnDragStop")
        end
        Lab.dragCandidate = nil
        if not f or not S[f] then return end
        local s = S[f]
        local isButton = s.kind == "Button" or s.kind == "CheckButton"
        local over = inside(f, x, y)
        if isButton then
            if not s.pushLocked then s.pushed = nil end
            Lab.Touch()
            if not s.enabled then return end
        end
        Lab.Run(f, "OnMouseUp", button, over)
        if s.links and over then
            local link, text = linkAt(f, x, y)
            if link then Lab.Run(f, "OnHyperlinkClick", link, text, button) end
        end
        if isButton and over and s.clicks[button .. "Up"] then Button.Click(f, button, false) end
    end

    local function wheel(delta, x, y)
        move(x, y)
        local f = Lab.FrameAt(x, y, function(fr) return S[fr].wheel end)
        if f then Lab.Run(f, "OnMouseWheel", delta) end
    end

    local function key(k, char, mods, isDown)
        if Lab.editFocus and isDown then
            Lab.EditKey(Lab.editFocus, k, char, mods)
            return
        end
        if Lab.editFocus then return end
        local script = isDown and "OnKeyDown" or "OnKeyUp"
        local order = Lab.FrameOrder()
        local taken = false
        for i = #order, 1, -1 do
            local f = order[i]
            local s = S[f]
            if s.keyboard and s.kind ~= "EditBox" and Lab.Has(f, script) then
                Lab.Run(f, script, k)
                if not s.propagate then taken = true break end
            end
        end
        if not taken and isDown and k == "ESCAPE" then G.CloseSpecialWindows() end
    end

    -- One event from the page: mouse in the stage's pixels, top left at 0, 0.
    function Lab.Input(e)
        local p = 768 / Lab.screen.ph
        local x, y = (e.x or 0) * p, Lab.SH - (e.y or 0) * p
        local m = e.mods
        if m then Lab.mouse.mods = { shift = m.shift, ctrl = m.ctrl, alt = m.alt, meta = m.meta } end
        if e.t == "move" then move(x, y)
        elseif e.t == "down" then down(e.b or "LeftButton", x, y)
        elseif e.t == "up" then up(e.b or "LeftButton", x, y)
        elseif e.t == "wheel" then wheel(e.d or 0, x, y)
        elseif e.t == "key" then key(e.key, e.char, Lab.mouse.mods, true)
        elseif e.t == "keyup" then key(e.key, nil, Lab.mouse.mods, false)
        elseif e.t == "leave" then setFocus(nil)
        end
    end
end
