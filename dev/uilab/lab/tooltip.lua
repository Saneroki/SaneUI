-- GameTooltip: the game's tooltip, as code fills it (owner and anchor, lines, double lines, items and units
-- from the lab's world), drawn plain: a dark box with a grey edge, its lines in the game's tooltip fonts.
return function(Lab)
    local S = Lab.S
    local Tip = Lab.kinds.GameTooltip.methods
    local SR = Lab.kinds.ScriptRegion.methods
    local FS = Lab.kinds.FontString.methods
    local Frame = Lab.kinds.Frame.methods

    local PAD, GAP, MAX = 10, 2, 300

    function Lab.INIT.GameTooltip(f)
        local s = S[f]
        s.lines = {}
        s.minWidth, s.pad = 0, { 0, 0, 0, 0 }
        s.strata = "TOOLTIP"
        s.shown = false
        local bg = Lab.NewTexture("Texture", f, nil, "BACKGROUND")
        Lab.AddRegion(f, bg)
        S[bg].inner = true
        Lab.kinds.TextureBase.methods.SetColorTexture(bg, 0.04, 0.04, 0.05, 0.92)
        SR.SetAllPoints(bg, f)
        for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 1 },
            { "TOPLEFT", "BOTTOMLEFT", 1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 } }) do
            local t = Lab.NewTexture("Texture", f, nil, "BORDER")
            Lab.AddRegion(f, t)
            S[t].inner = true
            Lab.kinds.TextureBase.methods.SetColorTexture(t, 0.55, 0.55, 0.55, 1)
            SR.SetPoint(t, side[1], f, side[1], 0, 0)
            SR.SetPoint(t, side[2], f, side[2], 0, 0)
            if side[3] == 1 then SR.SetWidth(t, 1.5) else SR.SetHeight(t, 1.5) end
        end
    end

    local function line(self, i)
        local s = S[self]
        local l = s.lines[i]
        if l then return l end
        local name = s.name
        local left = Lab.NewFontString(self, name and (name .. "TextLeft" .. i), "ARTWORK")
        local right = Lab.NewFontString(self, name and (name .. "TextRight" .. i), "ARTWORK")
        Lab.AddRegion(self, left)
        Lab.AddRegion(self, right)
        FS.SetFontObject(left, i == 1 and "GameTooltipHeaderText" or "GameTooltipText")
        FS.SetFontObject(right, "GameTooltipText")
        FS.SetJustifyH(left, "LEFT")
        FS.SetJustifyH(right, "RIGHT")
        l = { left = left, right = right }
        s.lines[i] = l
        return l
    end

    -- Lines laid out and the box sized to them, as the game does when it shows the tooltip.
    function Lab.LayoutTooltip(self)
        local s = S[self]
        local n = s.used or 0
        local widest = s.minWidth or 0
        for i = 1, n do
            local l = s.lines[i]
            if not l.wrap then
                local w = Lab.TextIntrinsic(l.left, nil)
                local rw = S[l.right].shown and Lab.TextIntrinsic(l.right, nil) or 0
                if rw > 0 then w = w + 20 + rw end
                if w > widest then widest = w end
            end
        end
        local wrapAt = math.max(widest, math.min(MAX, 250))
        local y = PAD
        for i = 1, #s.lines do
            local l = s.lines[i]
            local on = i <= n
            S[l.left].shown, S[l.right].shown = on, on and S[l.right].text ~= ""
            if on then
                local ls = S[l.left]
                ls.points = { { point = "TOPLEFT", rel = self, relPoint = "TOPLEFT", x = PAD, y = -y } }
                ls.wrap = l.wrap and true or false
                ls.w = l.wrap and wrapAt or nil
                ls.layout = nil
                local w, h = Lab.TextIntrinsic(l.left, ls.w)
                if l.wrap and w > widest then widest = w end
                if not l.wrap and w > widest then widest = w end
                local rs = S[l.right]
                rs.points = { { point = "TOPRIGHT", rel = self, relPoint = "TOPRIGHT", x = -PAD, y = -y } }
                y = y + math.max(h, 1) + GAP
            end
        end
        s.w = widest + PAD * 2
        s.h = y - GAP + PAD
        Lab.Touch()
    end

    local ANCHORS = {
        ANCHOR_RIGHT = { "BOTTOMLEFT", "TOPRIGHT" }, ANCHOR_LEFT = { "BOTTOMRIGHT", "TOPLEFT" },
        ANCHOR_TOP = { "BOTTOM", "TOP" }, ANCHOR_BOTTOM = { "TOP", "BOTTOM" },
        ANCHOR_TOPLEFT = { "BOTTOMLEFT", "TOPLEFT" }, ANCHOR_TOPRIGHT = { "BOTTOMRIGHT", "TOPRIGHT" },
        ANCHOR_BOTTOMLEFT = { "TOPRIGHT", "BOTTOMLEFT" }, ANCHOR_BOTTOMRIGHT = { "TOPLEFT", "BOTTOMRIGHT" },
    }
    function Tip:SetOwner(owner, anchor, x, y)
        local s = S[self]
        s.owner = owner
        s.anchor = anchor or "ANCHOR_LEFT"
        s.ax, s.ay = x or 0, y or 0
        Tip.ClearLines(self)
        if s.anchor ~= "ANCHOR_NONE" and s.anchor ~= "ANCHOR_PRESERVE" then s.points = {} end
        Lab.PlaceTooltip(self)
    end
    function Lab.PlaceTooltip(self)
        local s = S[self]
        local a = ANCHORS[s.anchor]
        if a and s.owner then
            s.points = { { point = a[1], rel = s.owner, relPoint = a[2], x = s.ax, y = s.ay } }
        elseif s.anchor == "ANCHOR_CURSOR" or s.anchor == "ANCHOR_CURSOR_RIGHT" or s.anchor == "ANCHOR_CURSOR_LEFT" then
            local sc = Lab.EScale(self)
            local dx = s.anchor == "ANCHOR_CURSOR_RIGHT" and 24 or 0
            s.points = { { point = "BOTTOMLEFT", rel = Lab.SCREEN, relPoint = "BOTTOMLEFT",
                x = Lab.mouse.x / sc + s.ax + dx, y = Lab.mouse.y / sc + s.ay + 8 } }
        end
        Lab.Touch()
    end
    function Tip:GetOwner() return S[self].owner end
    function Tip:IsOwned(f) return S[self].owner == f end
    function Tip:SetAnchorType(anchor, x, y) S[self].anchor = anchor; S[self].ax, S[self].ay = x or 0, y or 0; Lab.PlaceTooltip(self) end
    function Tip:GetAnchorType() return S[self].anchor end
    function Tip:ClearLines()
        local s = S[self]
        s.used = 0
        s.item, s.unit, s.spell = nil, nil, nil
        for _, l in ipairs(s.lines) do
            FS.SetText(l.left, "")
            FS.SetText(l.right, "")
        end
        Lab.LayoutTooltip(self)
        Lab.Run(self, "OnTooltipCleared")
    end
    function Tip:AddLine(text, r, g, b, wrap)
        local s = S[self]
        s.used = (s.used or 0) + 1
        local l = line(self, s.used)
        l.wrap = (wrap == true or wrap == 1) and true or nil
        FS.SetText(l.left, text or "")
        FS.SetText(l.right, "")
        local fo = s.used == 1 and Lab.G.GameTooltipHeaderText or Lab.G.GameTooltipText
        S[l.left].fontObject = fo
        if r then FS.SetTextColor(l.left, r, g, b) else S[l.left].fp = nil end
        Lab.LayoutTooltip(self)
    end
    function Tip:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)
        Tip.AddLine(self, left, lr, lg, lb)
        local l = S[self].lines[S[self].used]
        FS.SetText(l.right, right or "")
        if rr then FS.SetTextColor(l.right, rr, rg, rb) else S[l.right].fp = nil end
        Lab.LayoutTooltip(self)
    end
    function Tip:SetText(text, r, g, b, a, wrap)
        Tip.ClearLines(self)
        Tip.AddLine(self, text, r or 1, g or 0.82, b or 0, wrap)
    end
    function Tip:AppendText(text)
        local s = S[self]
        local l = s.lines[1]
        if l then FS.SetText(l.left, (S[l.left].text or "") .. text); Lab.LayoutTooltip(self) end
    end
    function Tip:NumLines() return S[self].used or 0 end
    function Tip:SetMinimumWidth(w) S[self].minWidth = w; Lab.LayoutTooltip(self) end
    function Tip:GetMinimumWidth() return S[self].minWidth end
    function Tip:SetPadding(r, b, l, t) S[self].pad = { r, b, l, t } end
    function Tip:GetPadding() local p = S[self].pad; return p[1], p[2], p[3], p[4] end
    function Tip:AddTexture(file)
        local s = S[self]
        local l = s.lines[s.used or 0]
        if l then FS.SetText(l.left, "|T" .. file .. ":0|t " .. (S[l.left].text or "")) end
    end
    function Tip:FadeOut() Frame.Hide(self) end
    function Tip:SetHyperlink(link)
        local kind, id = tostring(link):match("(%a+):(%-?%d+)")
        id = tonumber(id)
        if kind == "item" then return Tip.SetItemByID(self, id) end
        if kind == "spell" then return Tip.SetSpellByID(self, id) end
        Tip.SetText(self, tostring(link))
    end
    function Tip:SetItemByID(id)
        Tip.ClearLines(self)
        local lines = Lab.World.ItemTooltip(id)
        for i, l in ipairs(lines) do
            if l.right then Tip.AddDoubleLine(self, l.left, l.right, l.r, l.g, l.b, l.r, l.g, l.b)
            else Tip.AddLine(self, l.left, l.r, l.g, l.b, l.wrap) end
        end
        S[self].item = id
        Lab.Run(self, "OnTooltipSetItem")
        Frame.Show(self)
    end
    function Tip:SetInventoryItem(unit, slot)
        local id = Lab.World.EquippedID(unit, slot)
        if not id then return false end
        Tip.SetItemByID(self, id)
        return true
    end
    function Tip:SetBagItem(bag, slot)
        local id = Lab.World.BagItemID(bag, slot)
        if id then Tip.SetItemByID(self, id) end
    end
    function Tip:GetItem()
        local id = S[self].item
        if not id then return end
        local name, link = Lab.G.GetItemInfo(id)
        return name, link, id
    end
    function Tip:SetSpellByID(id)
        Tip.ClearLines(self)
        local spell = Lab.World.spells[id]
        Tip.AddLine(self, spell and spell.name or ("Spell " .. tostring(id)), 1, 1, 1)
        if spell and spell.text then Tip.AddLine(self, spell.text, 1, 0.82, 0, true) end
        S[self].spell = id
        Lab.Run(self, "OnTooltipSetSpell")
        Frame.Show(self)
    end
    function Tip:GetSpell()
        local id = S[self].spell
        if id then return Lab.G.GetSpellInfo(id), id end
    end
    function Tip:SetUnit(unit)
        Tip.ClearLines(self)
        local u = Lab.World.Unit(unit)
        if not u then return end
        local c = Lab.World.ClassColor(u.class)
        Tip.AddLine(self, Lab.World.FullName(u), c.r, c.g, c.b)
        if u.guild then Tip.AddLine(self, "<" .. u.guild .. ">", 0.25, 1, 0.25) end
        Tip.AddLine(self, ("Level %d %s %s"):format(u.level or 1, u.race or "", Lab.World.ClassName(u.class)), 1, 1, 1)
        S[self].unit = unit
        Lab.Run(self, "OnTooltipSetUnit")
        Frame.Show(self)
    end
    function Tip:GetUnit()
        local unit = S[self].unit
        if unit then return Lab.G.UnitName(unit), unit end
    end
    function Tip:IsTooltipType() return false end
    function Tip:SetCustomLineSpacing() end
    function Tip:SetAllowShowWithNoLines() end

    -- Shown with no owner it still lays out; hidden when its owner goes.
    local show = Frame.Show
    function Tip:Show()
        Lab.LayoutTooltip(self)
        show(self)
    end
end
