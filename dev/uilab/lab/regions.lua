-- Regions: textures, mask textures, lines and what all regions share (layers, colour, shown or not).
return function(Lab)
    local S = Lab.S
    local Region = Lab.kinds.Region.methods
    local TB = Lab.kinds.TextureBase.methods
    local Tex = Lab.kinds.Texture.methods
    local Line = Lab.kinds.Line.methods

    Lab.LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }

    function Lab.AddRegion(frame, r)
        local fs = S[frame]
        fs.regions[#fs.regions + 1] = r
    end

    local function removeRegion(frame, r)
        local list = S[frame].regions
        for i = #list, 1, -1 do if list[i] == r then table.remove(list, i) end end
    end

    -- Shared by all regions -----------------------------------------------------------------------------------------
    function Region:Show() S[self].shown = true; Lab.Touch() end
    function Region:Hide() S[self].shown = false; Lab.Touch() end
    function Region:SetParent(p)
        if type(p) == "string" then p = Lab.G[p] end
        if not (p and S[p] and Lab.Is(p, "Frame")) then error("SetParent(): a region's parent must be a frame", 2) end
        local s = S[self]
        if s.parent then removeRegion(s.parent, self) end
        s.parent = p
        Lab.AddRegion(p, self)
        Lab.Touch()
    end
    function Region:SetDrawLayer(layer, sub)
        layer = tostring(layer):upper()
        if not Lab.LAYERS[layer] then error("SetDrawLayer(): invalid layer " .. layer, 2) end
        sub = sub or 0
        if sub < -8 or sub > 7 then error("SetDrawLayer(): sublevel must be between -8 and 7", 2) end
        local s = S[self]
        s.layer, s.sub = layer, sub
        Lab.Touch()
    end
    function Region:GetDrawLayer() return S[self].layer, S[self].sub end
    function Region:SetVertexColor(r, g, b, a)
        if type(r) == "table" then r, g, b, a = r.r, r.g, r.b, r.a end
        if S[self].kind == "FontString" then
            Lab.kinds.FontString.methods.SetTextColor(self, r, g, b, a)
            return
        end
        S[self].vc = { r or 1, g or 1, b or 1, a or 1 }
        Lab.Touch()
    end
    function Region:GetVertexColor()
        if S[self].kind == "FontString" then return Lab.kinds.FontString.methods.GetTextColor(self) end
        local vc = S[self].vc or { 1, 1, 1, 1 }
        return vc[1], vc[2], vc[3], vc[4]
    end
    function Region:IsObjectLoaded() return true end
    function Region:CreateAnimationGroup(name, template) return Lab.NewAnimationGroup(self, name, template) end
    function Region:GetAnimationGroups() return unpack(S[self].anims or {}) end
    function Region:StopAnimating()
        for _, g in ipairs(S[self].anims or {}) do g:Stop() end
    end
    function Region:IsDragging() return false end

    -- Textures ------------------------------------------------------------------------------------------------------
    local BLEND = { DISABLE = true, BLEND = true, ALPHAKEY = true, ADD = true, MOD = true }

    function Lab.NewTexture(kind, parent, name, layer, inherits, sub)
        local t = Lab.New(kind, { name = name, parent = parent, shown = true, layer = layer or "ARTWORK", sub = sub or 0,
            blend = "BLEND" })
        if inherits then Lab.ApplyTemplate(t, inherits) end
        return t
    end

    function TB:SetTexture(file, wrapH, wrapV, filter)
        local s = S[self]
        s.color, s.atlas, s.gradient = nil, nil, nil
        if file == nil or file == "" then
            s.file = nil
        elseif type(file) == "number" then
            s.file = Lab.FileOfID(file)
            if not s.file then Lab.Warn("texture file ID the lab does not know: " .. file) end
        elseif type(file) == "string" then
            s.file = file
        else
            error("SetTexture(): textureAsset must be a string or a number", 2)
        end
        s.wrapH, s.wrapV = wrapH, wrapV
        s.coords, s.coords8 = nil, nil
        Lab.Touch()
        return true
    end
    function TB:GetTexture() return S[self].file end
    function TB:GetTextureFilePath() return S[self].file end
    function TB:GetTextureFileID() return nil end
    function TB:SetColorTexture(r, g, b, a)
        local s = S[self]
        s.file, s.atlas = nil, nil
        s.color = { r or 1, g or 1, b or 1, a or 1 }
        Lab.Touch()
    end
    function TB:SetTexCoord(...)
        local n = select("#", ...)
        local s = S[self]
        if n == 4 then
            local l, r, t, b = ...
            s.coords, s.coords8 = { l, r, t, b }, nil
        elseif n == 8 then
            local ulx, uly, llx, lly, urx, ury, lrx, lry = ...
            if uly == ury and llx == ulx and lry == lly and urx == lrx then
                s.coords, s.coords8 = { ulx, urx, uly, lly }, nil
            else
                -- turned or slanted: the page maps the picture's corners onto the region's
                s.coords, s.coords8 = nil, { ulx, uly, llx, lly, urx, ury, lrx, lry }
            end
        else
            error("SetTexCoord(): 4 or 8 numbers", 2)
        end
        Lab.Touch()
    end
    function TB:GetTexCoord()
        if S[self].coords8 then return unpack(S[self].coords8) end
        local c = S[self].coords or { 0, 1, 0, 1 }
        return c[1], c[3], c[1], c[4], c[2], c[3], c[2], c[4]
    end
    function TB:SetDesaturated(on) S[self].desat = on and 1 or nil; Lab.Touch() end
    function TB:SetDesaturation(n) S[self].desat = (n and n > 0) and n or nil; Lab.Touch() end
    function TB:IsDesaturated() return S[self].desat ~= nil end
    function TB:GetDesaturation() return S[self].desat or 0 end
    function TB:SetBlendMode(mode)
        mode = tostring(mode):upper()
        if not BLEND[mode] then error("SetBlendMode(): invalid blend mode " .. mode, 2) end
        S[self].blend = mode
        Lab.Touch()
    end
    function TB:GetBlendMode() return S[self].blend end
    function TB:SetHorizTile(on) S[self].htile = on and true or nil; Lab.Touch() end
    function TB:GetHorizTile() return S[self].htile or false end
    function TB:SetVertTile(on) S[self].vtile = on and true or nil; Lab.Touch() end
    function TB:GetVertTile() return S[self].vtile or false end
    function TB:SetRotation(rad, origin)
        S[self].rotation = rad ~= 0 and rad or nil
        S[self].rotOrigin = origin
        Lab.Touch()
    end
    function TB:GetRotation() return S[self].rotation or 0 end
    function TB:SetGradient(orientation, from, to)
        if type(from) ~= "table" then
            error("SetGradient(): the game takes colours (CreateColor) here", 2)
        end
        S[self].gradient = { o = tostring(orientation):upper(), from = { from.r, from.g, from.b, from.a or 1 },
            to = { to.r, to.g, to.b, to.a or 1 } }
        Lab.Touch()
    end
    function TB:SetSnapToPixelGrid(on) S[self].snap = on end
    function TB:IsSnappingToPixelGrid() return S[self].snap ~= false end
    function TB:SetTexelSnappingBias() end
    function TB:GetTexelSnappingBias() return 0 end
    function TB:SetTextureSliceMargins(l, t, r, b)
        S[self].slice = { l, t, r, b }
        Lab.Touch()
    end
    function TB:GetTextureSliceMargins()
        local m = S[self].slice
        if m then return m[1], m[2], m[3], m[4] end
        return 0, 0, 0, 0
    end
    function TB:SetTextureSliceMode(mode) S[self].sliceMode = mode; Lab.Touch() end
    function TB:GetTextureSliceMode() return S[self].sliceMode or 0 end
    function TB:ClearTextureSlice() S[self].slice = nil; Lab.Touch() end
    function TB:SetAtlas(name, useAtlasSize, filter)
        local a = Lab.Atlas(name)
        local s = S[self]
        if not a then
            Lab.Warn("atlas the lab does not know: " .. tostring(name))
            s.file, s.atlas = nil, name
            Lab.Touch()
            return false
        end
        s.file, s.atlas, s.color = a.file, name, nil
        s.coords = { a.l, a.r, a.t, a.b }
        s.htile, s.vtile = a.tileH or nil, a.tileV or nil
        if useAtlasSize then s.w, s.h = a.w, a.h end
        Lab.Touch()
        return true
    end
    function TB:GetAtlas() return S[self].atlas end
    function TB:ResetTexCoord() S[self].coords = nil; Lab.Touch() end
    function TB:SetMask(file)
        Lab.Warn("Texture:SetMask is the old way; the lab draws masks made with CreateMaskTexture")
    end

    function Tex:AddMaskTexture(mask)
        local s = S[self]
        s.masks = s.masks or {}
        for _, m in ipairs(s.masks) do if m == mask then return end end
        s.masks[#s.masks + 1] = mask
        Lab.Touch()
    end
    function Tex:RemoveMaskTexture(mask)
        local masks = S[self].masks or {}
        for i = #masks, 1, -1 do if masks[i] == mask then table.remove(masks, i) end end
        Lab.Touch()
    end
    function Tex:GetNumMaskTextures() return #(S[self].masks or {}) end
    function Tex:GetMaskTexture(i) return (S[self].masks or {})[i] end
    Lab.kinds.FontString.methods.AddMaskTexture = Tex.AddMaskTexture
    Lab.kinds.FontString.methods.RemoveMaskTexture = Tex.RemoveMaskTexture

    -- Lines ----------------------------------------------------------------------------------------------------------
    local function ends(self, which, relPoint, rel, x, y)
        local s = S[self]
        if type(rel) == "string" then rel = Lab.G[rel] end
        s[which] = { relPoint = tostring(relPoint):upper(), rel = rel or s.parent, x = x or 0, y = y or 0 }
        Lab.Touch()
    end
    function Line:SetStartPoint(relPoint, rel, x, y) ends(self, "from", relPoint, rel, x, y) end
    function Line:SetEndPoint(relPoint, rel, x, y) ends(self, "to", relPoint, rel, x, y) end
    function Line:SetThickness(n) S[self].thickness = n; Lab.Touch() end
    function Line:GetThickness() return S[self].thickness or 1 end
    function Line:GetStartPoint()
        local e = S[self].from
        if e then return e.relPoint, e.rel, e.x, e.y end
    end
    function Line:GetEndPoint()
        local e = S[self].to
        if e then return e.relPoint, e.rel, e.x, e.y end
    end

    -- A line's two ends in the cursor's space.
    function Lab.LineEnds(o)
        local s = S[o]
        if not (s.from and s.to) then return end
        local sc = Lab.EScale(o)
        local out = {}
        for i, e in ipairs({ s.from, s.to }) do
            local l, b, w, h = Lab.Rect(e.rel)
            if not l then return end
            out[i * 2 - 1] = l + w * Lab.PX[e.relPoint] + e.x * sc
            out[i * 2] = b + h * Lab.PY[e.relPoint] + e.y * sc
        end
        return out[1], out[2], out[3], out[4]
    end
end
