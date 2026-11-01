-- Where everything stands: anchors, sizes, scales, as the game resolves them. The lab works in the cursor's
-- space (the screen 768 high, as GetCursorPosition answers); a region's own numbers are that divided by its
-- effective scale, as in the game.
return function(Lab)
    local S = Lab.S
    local Object = Lab.kinds.Object.methods
    local SR = Lab.kinds.ScriptRegion.methods
    local SCREEN = {}       -- anchored to the screen itself
    Lab.SCREEN = SCREEN

    local PX = { TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0, TOP = 0.5, CENTER = 0.5, BOTTOM = 0.5, TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1 }
    local PY = { TOPLEFT = 1, TOP = 1, TOPRIGHT = 1, LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5, BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0 }
    Lab.PX, Lab.PY = PX, PY

    -- Scale and alpha --------------------------------------------------------------------------------------------
    function Lab.EScale(o)
        local s = S[o]
        if s.screen then return s.scale end
        local p = s.parent
        local scale = s.scale * (s.animScale or 1)
        if p and not s.ignoreParentScale then return Lab.EScale(p) * scale end
        return scale
    end

    function Lab.EAlpha(o)
        local s = S[o]
        local a = s.alpha * (s.animAlpha or 1)
        local p = s.parent
        if p and not s.ignoreParentAlpha then return Lab.EAlpha(p) * a end
        return a
    end

    -- Rectangles ---------------------------------------------------------------------------------------------------
    -- Lab.Rect(o) -> left, bottom, width, height in the cursor's space, or nil while it has no place.
    local resolving = {}
    local function resolve(o)
        local s = S[o]
        if s.screen then return 0, 0, Lab.SW, Lab.SH end
        if s.place then return s.place(o) end
        local pts = s.points
        if #pts == 0 then return nil end
        local sc = Lab.EScale(o)
        local L, R, CX, T, B, CY
        for i = 1, #pts do
            local p = pts[i]
            local l, b, w, h
            if p.rel == SCREEN then
                l, b, w, h = 0, 0, Lab.SW, Lab.SH
            else
                l, b, w, h = Lab.Rect(p.rel)
            end
            if not l then return nil end
            local ax = l + w * PX[p.relPoint] + p.x * sc
            local ay = b + h * PY[p.relPoint] + p.y * sc
            local fx, fy = PX[p.point], PY[p.point]
            if fx == 0 then L = ax elseif fx == 1 then R = ax else CX = ax end
            if fy == 1 then T = ay elseif fy == 0 then B = ay else CY = ay end
        end
        -- a font string's size of 0 is none: its text gives it (SetWidth(0), <Size x="0"/>), as in the game
        local ownW, ownH = s.w, s.h
        if s.intrinsic and ownW == 0 then ownW = nil end
        if s.intrinsic and ownH == 0 then ownH = nil end
        local w
        if L and R then w = R - L
        elseif ownW then w = ownW * sc
        elseif L and CX then w = 2 * (CX - L)
        elseif R and CX then w = 2 * (R - CX)
        elseif s.intrinsic then w = (s.intrinsic(o, nil)) * sc
        else w = 0 end
        local h
        if T and B then h = T - B
        elseif ownH then h = ownH * sc
        elseif T and CY then h = 2 * (T - CY)
        elseif B and CY then h = 2 * (CY - B)
        elseif s.intrinsic then
            local _, ih = s.intrinsic(o, w / sc)
            h = ih * sc
        else h = 0 end
        local left = L or (R and R - w) or (CX - w / 2)
        local bottom = B or (T and T - h) or (CY - h / 2)
        if s.animX then
            left, bottom = left + s.animX, bottom + s.animY
        end
        return left, bottom, w, h
    end

    function Lab.Rect(o)
        local cache = Lab.rects
        if not cache then cache = {}; Lab.rects = cache end
        local r = cache[o]
        if r == nil then
            if resolving[o] then
                Lab.Warn("anchors that lead back to themselves: " .. Lab.Describe(o))
                return nil
            end
            resolving[o] = true
            local l, b, w, h = resolve(o)
            resolving[o] = nil
            r = l and { l, b, w, h } or false
            cache[o] = r
        end
        if r then return r[1], r[2], r[3], r[4] end
    end

    function Lab.Describe(o)
        local s = S[o]
        if not s then return tostring(o) end
        return (s.name or ("a " .. s.kind)) .. " (made at " .. s.at .. ")"
    end

    -- Does a depend on b through its anchors (or its parent's)?
    local function depends(a, b, seen)
        if a == b then return true end
        if a == SCREEN or not S[a] then return false end
        seen = seen or {}
        if seen[a] then return false end
        seen[a] = true
        for _, p in ipairs(S[a].points) do
            if depends(p.rel, b, seen) then return true end
        end
        return false
    end

    -- Object --------------------------------------------------------------------------------------------------------
    function Object:GetName() return S[self].name end
    function Object:GetObjectType() return S[self].kind end
    function Object:IsObjectType(kind) return Lab.Is(self, kind) or (kind == "Region" and Lab.Is(self, "ScriptRegion")) end
    function Object:IsForbidden() return false end
    function Object:SetForbidden() end
    function Object:IsProtected() return false, false end
    function Object:CanChangeProtectedState() return true end
    function Object:GetParent() return S[self].parent end
    function Object:GetDebugName()
        local s = S[self]
        if s.name then return s.name end
        local p = s.parent
        if p then
            for k, v in pairs(p) do
                if v == self then return Object.GetDebugName(p) .. "." .. tostring(k) end
            end
            return Object.GetDebugName(p) .. ".<unnamed " .. s.kind .. ">"
        end
        return "<unnamed " .. s.kind .. ">"
    end
    function Object:GetSourceLocation() return S[self].at end
    function Object:SetParentKey(key)
        local p = S[self].parent
        if p then p[key] = self end
    end
    function Object:GetParentKey()
        local p = S[self].parent
        if p then for k, v in pairs(p) do if v == self then return k end end end
    end

    -- Anchors ----------------------------------------------------------------------------------------------------
    local function point(name, method)
        if type(name) ~= "string" or not PX[name:upper()] then
            error(("%s(): invalid region point %s"):format(method, tostring(name)), 3)
        end
        return name:upper()
    end

    function SR:SetPoint(p, ...)
        p = point(p, "SetPoint")
        local s = S[self]
        local n = select("#", ...)
        local a, b, c, d = ...
        local rel, relPoint, x, y
        if n == 0 then
            rel, relPoint, x, y = nil, p, 0, 0
        elseif type(a) == "number" then
            rel, relPoint, x, y = nil, p, a, b or 0
        else
            rel = a
            if type(rel) == "string" then
                rel = Lab.G[rel]
                if not rel then error("SetPoint(): unknown region " .. a, 2) end
            end
            if type(b) == "number" then
                relPoint, x, y = p, b, c or 0
            else
                relPoint = b and point(b, "SetPoint") or p
                x, y = c or 0, d or 0
            end
        end
        if rel == nil then rel = s.parent or SCREEN end
        if rel ~= SCREEN and not S[rel] then error("SetPoint(): bad relativeTo: " .. tostring(rel), 2) end
        if rel == self then error("SetPoint(): Cannot anchor to itself", 2) end
        if rel ~= SCREEN and depends(rel, self) then
            error("SetPoint(): Cannot anchor to a region dependent on it", 2)
        end
        local entry = { point = p, rel = rel, relPoint = relPoint, x = tonumber(x) or 0, y = tonumber(y) or 0 }
        for i, q in ipairs(s.points) do
            if q.point == p then s.points[i] = entry; Lab.Touch(); return end
        end
        s.points[#s.points + 1] = entry
        Lab.Touch()
    end

    function SR:SetAllPoints(rel, doResize)
        local s = S[self]
        if type(rel) == "string" then rel = Lab.G[rel] end
        rel = rel or s.parent or SCREEN
        s.points = {}
        SR.SetPoint(self, "TOPLEFT", rel, "TOPLEFT", 0, 0)
        SR.SetPoint(self, "BOTTOMRIGHT", rel, "BOTTOMRIGHT", 0, 0)
    end

    -- As the game's: a part a pool gives out again stands nowhere, at no size, with nothing on it (Blizzard's menus).
    function SR:SetToDefaults()
        SR.ClearAllPoints(self)
        self:SetSize(0, 0)
        self:SetAlpha(1)
        if Lab.Is(self, "FontString") then self:SetText("") end
        if Lab.Is(self, "Texture") then self:SetTexture(nil) end
    end

    function SR:ClearAllPoints()
        S[self].points = {}
        Lab.Touch()
    end

    function SR:ClearPoint(p)
        p = point(p, "ClearPoint")
        local pts = S[self].points
        for i = #pts, 1, -1 do if pts[i].point == p then table.remove(pts, i) end end
        Lab.Touch()
    end

    function SR:GetNumPoints() return #S[self].points end

    local function relOut(rel) if rel == SCREEN then return nil end return rel end
    function SR:GetPoint(i)
        local q = S[self].points[i or 1]
        if q then return q.point, relOut(q.rel), q.relPoint, q.x, q.y end
    end
    function SR:GetPointByName(p)
        p = point(p, "GetPointByName")
        for _, q in ipairs(S[self].points) do
            if q.point == p then return q.point, relOut(q.rel), q.relPoint, q.x, q.y end
        end
    end
    function SR:AdjustPointsOffset(x, y)
        for _, q in ipairs(S[self].points) do q.x, q.y = q.x + x, q.y + y end
        Lab.Touch()
    end
    function SR:ClearPointsOffset()
        for _, q in ipairs(S[self].points) do q.x, q.y = 0, 0 end
        Lab.Touch()
    end
    function SR:IsAnchoringRestricted() return false end
    function SR:IsAnchoringSecret() return false end

    -- Sizes ------------------------------------------------------------------------------------------------------
    function SR:SetWidth(w)
        Lab.Check(w, "number", "SetWidth", 1)
        S[self].w = tonumber(w)
        Lab.Touch()
    end
    function SR:SetHeight(h)
        Lab.Check(h, "number", "SetHeight", 1)
        S[self].h = tonumber(h)
        Lab.Touch()
    end
    function SR:SetSize(w, h)
        Lab.Check(w, "number", "SetSize", 1)
        Lab.Check(h, "number", "SetSize", 2)
        local s = S[self]
        s.w, s.h = tonumber(w), tonumber(h)
        Lab.Touch()
    end

    -- The size the game answers: the resolved one where the region has a place (two anchors on a side win over
    -- a size set), else the one set (0 for none); ignoreRect asks for the one set.
    local function size(self, axis, ignoreRect)
        local s = S[self]
        if not ignoreRect then
            local l, b, w, h = Lab.Rect(self)
            if l then return (axis == "w" and w or h) / Lab.EScale(self) end
        end
        if s[axis] and not (s.intrinsic and s[axis] == 0) then return s[axis] end
        if s.intrinsic then
            local w, h = s.intrinsic(self, s.w ~= 0 and s.w or nil)
            return axis == "w" and w or h
        end
        return 0
    end
    function SR:GetWidth(ignoreRect) return size(self, "w", ignoreRect) end
    function SR:GetHeight(ignoreRect) return size(self, "h", ignoreRect) end
    function SR:GetSize(ignoreRect) return size(self, "w", ignoreRect), size(self, "h", ignoreRect) end

    local function edges(self)
        local l, b, w, h = Lab.Rect(self)
        if not l then return end
        local sc = Lab.EScale(self)
        return l / sc, b / sc, w / sc, h / sc
    end
    function SR:GetLeft() local l = edges(self); return l end
    function SR:GetBottom() local _, b = edges(self); return b end
    function SR:GetRight() local l, _, w = edges(self); return l and l + w end
    function SR:GetTop() local _, b, _, h = edges(self); return b and b + h end
    function SR:GetCenter()
        local l, b, w, h = edges(self)
        if l then return l + w / 2, b + h / 2 end
    end
    function SR:GetRect() return edges(self) end
    function SR:GetScaledRect() return Lab.Rect(self) end
    function SR:IsRectValid() return Lab.Rect(self) ~= nil end
    function SR:IsCollapsed() return false end
    function SR:IsMouseOver(top, bottom, left, right)
        local l, b, w, h = Lab.Rect(self)
        if not l then return false end
        local sc = Lab.EScale(self)
        local x, y = Lab.mouse.x, Lab.mouse.y
        -- the offsets move each edge (IsMouseOver(10, -10, -5, 5): ten above and below, five to each side)
        return x >= l + (left or 0) * sc and x <= l + w + (right or 0) * sc
            and y >= b + (bottom or 0) * sc and y <= b + h + (top or 0) * sc
    end
    function SR:IsMouseMotionFocus() return Lab.focus == self end
    function SR:IsMouseEnabled() return S[self].mouse and true or false end
    function SR:IsMouseClickEnabled() return S[self].mouse and true or false end
    function SR:IsMouseMotionEnabled() return (S[self].mouse or S[self].motion) and true or false end
    function SR:EnableMouse(on)
        S[self].mouse = on and true or false
        S[self].motion = on and true or false
        Lab.Touch()
    end
    function SR:SetMouseClickEnabled(on) S[self].mouse = on and true or false end
    function SR:SetMouseMotionEnabled(on) S[self].motion = on and true or false end
    function SR:EnableMouseMotion(on) S[self].motion = on and true or false end
    function SR:SetPassThroughButtons() end
    function SR:CanChangeProtectedState() return true end

    -- Shown and seen -----------------------------------------------------------------------------------------------
    function Lab.Visible(o)
        local s = S[o]
        while s do
            if not s.shown then return false end
            if not s.parent then return true end
            s = S[s.parent]
        end
        return false
    end

    function SR:IsShown() return S[self].shown and true or false end
    function SR:IsVisible() return Lab.Visible(self) end
    function SR:SetShown(on)
        if on then self:Show() else self:Hide() end
    end
    function SR:GetScale() return S[self].scale end
    function SR:SetScale(scale)
        Lab.Check(scale, "number", "SetScale", 1)
        if scale <= 0 then error("SetScale(): Scale must be > 0", 2) end
        S[self].scale = scale
        Lab.Touch()
    end
    function SR:GetEffectiveScale() return Lab.EScale(self) end
    function SR:SetIgnoreParentScale(on) S[self].ignoreParentScale = on and true or nil; Lab.Touch() end
    function SR:IsIgnoringParentScale() return S[self].ignoreParentScale and true or false end
    function SR:GetAlpha() return S[self].alpha end
    function SR:SetAlpha(a)
        Lab.Check(a, "number", "SetAlpha", 1)
        S[self].alpha = math.max(0, math.min(1, a))
        Lab.Touch()
    end
    function SR:GetEffectiveAlpha() return Lab.EAlpha(self) end
    function SR:SetIgnoreParentAlpha(on) S[self].ignoreParentAlpha = on and true or nil; Lab.Touch() end
    function SR:IsIgnoringParentAlpha() return S[self].ignoreParentAlpha and true or false end
end
