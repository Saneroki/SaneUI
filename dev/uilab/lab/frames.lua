-- Frames: CreateFrame and what every frame does (children, regions, strata and levels, scripts, events, moving
-- and sizing), and the kinds with more: buttons, check buttons, scroll frames, sliders, status bars, cooldowns,
-- models (a box where the 3D model would be).
return function(Lab)
    local S = Lab.S
    local Frame = Lab.kinds.Frame.methods
    local Button = Lab.kinds.Button.methods
    local Check = Lab.kinds.CheckButton.methods
    local Scroll = Lab.kinds.ScrollFrame.methods
    local Slider = Lab.kinds.Slider.methods
    local Bar = Lab.kinds.StatusBar.methods
    local Cooldown = Lab.kinds.Cooldown.methods
    local Model = Lab.kinds.Model.methods

    Lab.STRATA = { WORLD = 1, BACKGROUND = 2, LOW = 3, MEDIUM = 4, HIGH = 5, DIALOG = 6, FULLSCREEN = 7,
        FULLSCREEN_DIALOG = 8, TOOLTIP = 9 }
    Lab.eventFrames = {}       -- [event] = frames registered for it, in the order they registered
    Lab.templates = {}         -- [name] = function(object): the templates the lab knows (lab/templates.lua)

    -- Templates are applied in the order given, each with what it inherits first; what they make waits for the
    -- object to be complete (Lab.Building, lab/xmlui.lua).
    function Lab.ApplyTemplate(o, names)
        Lab.Building(function()
            for name in tostring(names):gmatch("[^,%s]+") do
                local t = Lab.templates[name]
                if t then
                    t(o)
                else
                    Lab.Warn("template the lab does not know (yet): " .. name)
                end
            end
        end)
    end

    -- CreateFrame ---------------------------------------------------------------------------------------------------
    local INIT = {}
    Lab.INIT = INIT
    -- The frame alone, as the game makes it before any template: its kind's state, its parent's strata and level.
    function Lab.MakeFrame(kind, name, parent, id)
        local ps = parent and S[parent]
        local f = Lab.New(kind, { name = name, parent = parent, shown = true, children = {}, regions = {},
            strata = ps and ps.strata or "MEDIUM", level = ps and ps.level + 1 or 0, scripts = {}, events = {},
            id = id or 0 })
        Lab.frames[#Lab.frames + 1] = f
        if ps then ps.children[#ps.children + 1] = f end
        if Lab.Is(f, "Button") then INIT.Button(f) end
        if kind ~= "Button" and kind ~= "CheckButton" and INIT[kind] then INIT[kind](f) end
        return f
    end
    -- An intrinsic kind (EventFrame, DropdownButton) is its frame kind with its template applied first.
    function Lab.CreateFrame(kindName, name, parent, template, id)
        if type(kindName) ~= "string" then error("CreateFrame(): frame type must be a string", 3) end
        local kind, intrinsic = Lab.FrameKind(kindName)
        if not kind then error("CreateFrame(): Unknown frame type '" .. kindName .. "'", 3) end
        if type(parent) == "string" then parent = Lab.G[parent] end
        if parent ~= nil and not (S[parent] and Lab.Is(parent, "Frame")) then
            error("CreateFrame(): parent must be a frame", 3)
        end
        if name ~= nil and type(name) ~= "string" then error("CreateFrame(): name must be a string", 3) end
        if name and name:find("$parent", 1, true) then
            name = name:gsub("%$parent", parent and S[parent].name or "")
        end
        return Lab.Building(function()
            local f = Lab.MakeFrame(kind, name, parent, id)
            if intrinsic then Lab.ApplyTemplate(f, intrinsic) end
            if template then Lab.ApplyTemplate(f, template) end
            Lab.Loaded(f)
            return f
        end)
    end

    -- Children and regions ---------------------------------------------------------------------------------------------
    function Frame:GetChildren()
        local out = {}
        for _, c in ipairs(S[self].children) do out[#out + 1] = c end
        return unpack(out)
    end
    function Frame:GetNumChildren() return #S[self].children end
    function Frame:GetRegions()
        local out = {}
        for _, r in ipairs(S[self].regions) do if not S[r].inner then out[#out + 1] = r end end
        return unpack(out)
    end
    function Frame:GetNumRegions()
        local n = 0
        for _, r in ipairs(S[self].regions) do if not S[r].inner then n = n + 1 end end
        return n
    end
    function Frame:CreateTexture(name, layer, inherits, sub)
        local t = Lab.NewTexture("Texture", self, name, layer, inherits, sub)
        Lab.AddRegion(self, t)
        return t
    end
    function Frame:CreateMaskTexture(name, layer, inherits, sub)
        local t = Lab.NewTexture("MaskTexture", self, name, layer, inherits, sub)
        S[t].mask = true
        Lab.AddRegion(self, t)
        return t
    end
    function Frame:CreateLine(name, layer, inherits, sub)
        local t = Lab.NewTexture("Line", self, name, layer, inherits, sub)
        Lab.AddRegion(self, t)
        return t
    end
    function Frame:CreateFontString(name, layer, inherits)
        local fs = Lab.NewFontString(self, name, layer, inherits)
        Lab.AddRegion(self, fs)
        return fs
    end
    function Frame:CreateAnimationGroup(name, template) return Lab.NewAnimationGroup(self, name, template) end
    Frame.GetAnimationGroups = Lab.kinds.Region.methods.GetAnimationGroups
    Frame.StopAnimating = Lab.kinds.Region.methods.StopAnimating

    function Frame:SetParent(p)
        if type(p) == "string" then p = Lab.G[p] end
        if p ~= nil and not (S[p] and Lab.Is(p, "Frame")) then error("SetParent(): parent must be a frame", 2) end
        local s = S[self]
        if s.parent == p then return end
        local wasVisible = Lab.Visible(self)
        if s.parent then
            local list = S[s.parent].children
            for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
        end
        s.parent = p
        if p then
            local ps = S[p]
            ps.children[#ps.children + 1] = self
            if not s.fixedStrata then Lab.SetStrata(self, ps.strata) end
            if not s.fixedLevel then Frame.SetFrameLevel(self, ps.level + 1) end
        end
        Lab.Touch()
        Lab.ShownChanged(self, wasVisible)
    end

    -- Shown and hidden: OnShow and OnHide reach every frame that starts or stops being seen.
    local function walk(f, script)
        local s = S[f]
        if not s.shown then return end
        Lab.Run(f, script)
        for _, c in ipairs(s.children) do walk(c, script) end
    end
    function Lab.ShownChanged(f, wasVisible)
        local now = Lab.Visible(f)
        if now and not wasVisible then walk(f, "OnShow")
        elseif wasVisible and not now then
            local s = S[f]
            local shown = s.shown
            s.shown = true
            walk(f, "OnHide")
            s.shown = shown
            if Lab.editFocus and not Lab.Visible(Lab.editFocus) then Lab.ClearEditFocus() end
        end
    end
    function Frame:Show()
        local s = S[self]
        if s.shown then return end
        local was = Lab.Visible(self)
        s.shown = true
        Lab.Touch()
        Lab.ShownChanged(self, was)
    end
    function Frame:Hide()
        local s = S[self]
        if not s.shown then return end
        local was = Lab.Visible(self)
        s.shown = false
        Lab.Touch()
        Lab.ShownChanged(self, was)
    end
    function Frame:SetShown(on) if on then Frame.Show(self) else Frame.Hide(self) end end

    -- Strata and levels -------------------------------------------------------------------------------------------------
    function Lab.SetStrata(f, strata)
        local s = S[f]
        s.strata = strata
        for _, c in ipairs(s.children) do
            if not S[c].fixedStrata then Lab.SetStrata(c, strata) end
        end
    end
    function Frame:SetFrameStrata(strata)
        strata = tostring(strata):upper()
        if not Lab.STRATA[strata] then error("SetFrameStrata(): invalid strata " .. strata, 2) end
        Lab.SetStrata(self, strata)
        Lab.Touch()
    end
    function Frame:GetFrameStrata() return S[self].strata end
    function Frame:SetFixedFrameStrata(on) S[self].fixedStrata = on and true or nil end
    function Frame:HasFixedFrameStrata() return S[self].fixedStrata or false end
    function Frame:SetFrameLevel(level)
        Lab.Check(level, "number", "SetFrameLevel", 1)
        local s = S[self]
        level = math.max(0, math.min(10000, math.floor(level)))
        local delta = level - s.level
        s.level = level
        local function shift(f)
            for _, c in ipairs(S[f].children) do
                local cs = S[c]
                if not cs.fixedLevel then
                    cs.level = math.max(0, math.min(10000, cs.level + delta))
                    shift(c)
                end
            end
        end
        if delta ~= 0 then shift(self) end
        Lab.Touch()
    end
    function Frame:GetFrameLevel() return S[self].level end
    function Frame:SetFixedFrameLevel(on) S[self].fixedLevel = on and true or nil end
    function Frame:HasFixedFrameLevel() return S[self].fixedLevel or false end
    function Frame:SetUsingParentLevel(on)
        local p = S[self].parent
        if on and p then Frame.SetFrameLevel(self, S[p].level) end
    end
    function Frame:GetRaisedFrameLevel() return S[self].level end
    function Frame:Raise()
        local s = S[self]
        local top = s.level
        for _, f in ipairs(Lab.frames) do
            local fs = S[f]
            if fs.strata == s.strata and f ~= self and fs.level >= top and not Frame.IsChildOf(f, self) then top = fs.level + 1 end
        end
        if top ~= s.level then Frame.SetFrameLevel(self, top) end
        s.raised = Lab.counter
        Lab.counter = Lab.counter + 1
        Lab.Touch()
    end
    function Frame:Lower()
        Frame.SetFrameLevel(self, 0)
    end
    function Frame:IsChildOf(other)
        local p = S[self].parent
        while p do
            if p == other then return true end
            p = S[p].parent
        end
        return false
    end
    function Frame:SetToplevel(on) S[self].toplevel = on and true or nil end
    function Frame:IsToplevel() return S[self].toplevel or false end

    -- Scripts: Lab.ScriptMethods on every script region (lab/core.lua, lab/kinds.lua).

    -- Events ------------------------------------------------------------------------------------------------------------
    function Lab.KnownEvent(event)
        return Lab.docs.events[event] or Lab.extraEvents[event]
    end
    function Frame:RegisterEvent(event)
        if type(event) ~= "string" or not Lab.KnownEvent(event) then
            error(('RegisterEvent(): Attempt to register unknown event "%s"'):format(tostring(event)), 2)
        end
        local s = S[self]
        if s.events[event] then return true end
        s.events[event] = true
        local list = Lab.eventFrames[event] or {}
        Lab.eventFrames[event] = list
        list[#list + 1] = self
        return true
    end
    function Frame:RegisterUnitEvent(event, unit1, unit2)
        Frame.RegisterEvent(self, event)
        S[self].units = S[self].units or {}
        S[self].units[event] = { unit1, unit2 }
        return true
    end
    function Frame:UnregisterEvent(event)
        local s = S[self]
        if not s.events[event] then return end
        s.events[event] = nil
        if s.units then s.units[event] = nil end
        local list = Lab.eventFrames[event]
        for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
    end
    function Frame:UnregisterAllEvents()
        for event in pairs(S[self].events) do Frame.UnregisterEvent(self, event) end
    end
    function Frame:RegisterEventCallback(event, fn) return Lab.AddEventCallback(event, fn, self) end
    function Frame:RegisterUnitEventCallback(event, fn, u1, u2) return Lab.AddEventCallback(event, fn, self, { u1, u2 }) end
    function Frame:UnregisterEventCallback(event) Lab.RemoveEventCallback(event, self) end
    Frame.UnregisterUnitEventCallback = Frame.UnregisterEventCallback
    function Frame:IsEventRegistered(event) return S[self].events[event] or false end
    function Frame:RegisterAllEvents() S[self].allEvents = true end

    -- Fires an event at every frame registered for it, as the game does: in the order they registered.
    function Lab.Fire(event, ...)
        local list = Lab.eventFrames[event]
        if list then
            local copy = {}
            for i, f in ipairs(list) do copy[i] = f end
            local unit = ...
            for _, f in ipairs(copy) do
                local s = S[f]
                if s.events[event] then
                    local units = s.units and s.units[event]
                    if not units or units[1] == unit or units[2] == unit then
                        Lab.Run(f, "OnEvent", event, ...)
                    end
                end
            end
        end
        for _, f in ipairs(Lab.frames) do
            if S[f].allEvents then Lab.Run(f, "OnEvent", event, ...) end
        end
        local callbacks = Lab.eventCallbacks and Lab.eventCallbacks[event]
        if callbacks then
            local unit = ...
            local copy = {}
            for i, c in ipairs(callbacks) do copy[i] = c end
            for _, c in ipairs(copy) do
                if not c.units or c.units[1] == unit or c.units[2] == unit then Lab.Call(c.fn, c.owner, ...) end
            end
        end
        if Lab.OnFired then Lab.OnFired(event, ...) end
    end

    -- Mouse, keyboard, moving and sizing ----------------------------------------------------------------------------------
    function Frame:EnableMouseWheel(on) S[self].wheel = on and true or nil end
    function Frame:IsMouseWheelEnabled() return S[self].wheel or false end
    function Frame:EnableKeyboard(on) S[self].keyboard = on and true or nil end
    function Frame:IsKeyboardEnabled() return S[self].keyboard or false end
    function Frame:SetPropagateKeyboardInput(on) S[self].propagate = on and true or nil end
    function Frame:GetPropagateKeyboardInput() return S[self].propagate or false end
    function Frame:SetMovable(on) S[self].movable = on and true or nil end
    function Frame:IsMovable() return S[self].movable or false end
    function Frame:SetResizable(on) S[self].resizable = on and true or nil end
    function Frame:IsResizable() return S[self].resizable or false end
    function Frame:SetResizeBounds(minW, minH, maxW, maxH)
        S[self].bounds = { minW or 0, minH or 0, maxW, maxH }
    end
    function Frame:GetResizeBounds()
        local b = S[self].bounds or { 0, 0 }
        return b[1], b[2], b[3] or 0, b[4] or 0
    end
    function Frame:SetClampedToScreen(on) S[self].clamped = on and true or nil end
    function Frame:IsClampedToScreen() return S[self].clamped or false end
    function Frame:SetClampRectInsets(l, r, t, b) S[self].clampInsets = { l, r, t, b } end
    function Frame:GetClampRectInsets()
        local c = S[self].clampInsets or { 0, 0, 0, 0 }
        return c[1], c[2], c[3], c[4]
    end
    function Frame:SetUserPlaced(on) S[self].userPlaced = on and true or nil end
    function Frame:IsUserPlaced() return S[self].userPlaced or false end
    function Frame:SetDontSavePosition(on) S[self].dontSave = on end
    function Frame:GetDontSavePosition() return S[self].dontSave or false end
    function Frame:RegisterForDrag(...)
        local s = S[self]
        s.drag = {}
        for i = 1, select("#", ...) do
            local b = select(i, ...)
            if b then s.drag[(b:gsub("Up$", ""):gsub("Down$", ""))] = true end
        end
    end
    function Frame:SetHitRectInsets(l, r, t, b) S[self].hit = { l, r, t, b } end
    function Frame:GetHitRectInsets()
        local h = S[self].hit or { 0, 0, 0, 0 }
        return h[1], h[2], h[3], h[4]
    end
    function Frame:SetClipsChildren(on) S[self].clips = on and true or nil; Lab.Touch() end
    function Frame:DoesClipChildren() return S[self].clips or false end

    -- Moving: the frame keeps one anchor, its top left on the screen, as the game leaves a moved frame.
    function Frame:StartMoving()
        local s = S[self]
        if not s.movable then error("StartMoving(): Frame is not movable", 2) end
        local l, b, w, h = Lab.Rect(self)
        if not l then return end
        local sc = Lab.EScale(self)
        s.points = {}
        s.points[1] = { point = "TOPLEFT", rel = Lab.SCREEN, relPoint = "BOTTOMLEFT", x = l / sc, y = (b + h) / sc }
        Lab.moving = { frame = self, x = Lab.mouse.x, y = Lab.mouse.y, px = l / sc, py = (b + h) / sc }
        s.userPlaced = true
        Lab.Touch()
    end
    function Frame:StartSizing(point)
        local s = S[self]
        if not s.resizable then error("StartSizing(): Frame is not resizable", 2) end
        local l, b, w, h = Lab.Rect(self)
        if not l then return end
        local sc = Lab.EScale(self)
        point = (point or "BOTTOMRIGHT"):upper()
        -- the corner across from the one pulled stays where it is
        local px, py = 1 - Lab.PX[point], 1 - Lab.PY[point]
        local keep = (py == 1 and "TOP" or py == 0 and "BOTTOM" or "") .. (px == 1 and "RIGHT" or px == 0 and "LEFT" or "")
        if keep == "" then keep = "CENTER" end
        s.points = { { point = keep, rel = Lab.SCREEN, relPoint = "BOTTOMLEFT", x = (l + w * px) / sc, y = (b + h * py) / sc } }
        s.w, s.h = w / sc, h / sc
        Lab.sizing = { frame = self, point = point, x = Lab.mouse.x, y = Lab.mouse.y, w = s.w, h = s.h }
        Lab.Touch()
    end
    function Frame:StopMovingOrSizing()
        Lab.moving, Lab.sizing = nil, nil
    end

    -- Attributes, ids, highlight, draw layers -----------------------------------------------------------------------------
    function Frame:SetID(id) S[self].id = id end
    function Frame:GetID() return S[self].id or 0 end
    function Frame:SetAttribute(key, value)
        local s = S[self]
        s.attributes = s.attributes or {}
        s.attributes[key] = value
        Lab.Run(self, "OnAttributeChanged", key, value)
    end
    Frame.SetAttributeNoHandler = function(self, key, value)
        local s = S[self]
        s.attributes = s.attributes or {}
        s.attributes[key] = value
    end
    function Frame:GetAttribute(key) return S[self].attributes and S[self].attributes[key] end
    function Frame:ClearAttribute(key) if S[self].attributes then S[self].attributes[key] = nil end end
    function Frame:ClearAttributes() S[self].attributes = nil end
    function Frame:CanChangeAttribute() return true end
    function Frame:SetHyperlinksEnabled(on) S[self].links = on and true or nil end
    function Frame:GetHyperlinksEnabled() return S[self].links or false end
    function Frame:SetHyperlinkPropagateToParent(on) S[self].linkPropagate = on end
    function Frame:LockHighlight() S[self].highlightLocked = true; Lab.Touch() end
    function Frame:UnlockHighlight() S[self].highlightLocked = nil; Lab.Touch() end
    function Frame:SetHighlightLocked(on) S[self].highlightLocked = on and true or nil; Lab.Touch() end
    function Frame:IsHighlightLocked() return S[self].highlightLocked or false end
    function Frame:DisableDrawLayer(layer) S[self].offLayers = S[self].offLayers or {}; S[self].offLayers[layer] = true; Lab.Touch() end
    function Frame:EnableDrawLayer(layer) if S[self].offLayers then S[self].offLayers[layer] = nil end; Lab.Touch() end
    function Frame:SetDrawLayerEnabled(layer, on) if on then Frame.EnableDrawLayer(self, layer) else Frame.DisableDrawLayer(self, layer) end end
    function Frame:IsDrawLayerEnabled(layer) return not (S[self].offLayers and S[self].offLayers[layer]) end
    function Frame:SetFlattensRenderLayers() end
    function Frame:GetFlattensRenderLayers() return false end
    function Frame:SetIsFrameBuffer() end
    function Frame:IsFrameBuffer() return false end
    function Frame:SetIgnoringChildrenForBounds() end
    function Frame:SetAlphaFromBoolean(on, yes, no)
        Lab.kinds.ScriptRegion.methods.SetAlpha(self, on and (yes or 1) or (no or 0))
    end
    function Frame:DesaturateHierarchy(n)
        local function go(f)
            for _, r in ipairs(S[f].regions) do if S[r].kind == "Texture" then S[r].desat = (n and n > 0) and n or nil end end
            for _, c in ipairs(S[f].children) do go(c) end
        end
        go(self)
        Lab.Touch()
    end
    function Frame:GetBoundsRect() return Lab.kinds.ScriptRegion.methods.GetRect(self) end
    function Frame:SetWindow() end
    function Frame:SetOnUpdateMode() end

    -- Buttons ---------------------------------------------------------------------------------------------------------------
    function INIT.Button(f)
        local s = S[f]
        s.mouse, s.motion = true, true
        s.clicks = { LeftButtonUp = true }
        s.enabled = true
        s.pushedOffset = { 0, 0 }
    end

    local ROLES = { normal = "ARTWORK", pushed = "ARTWORK", highlight = "HIGHLIGHT", disabled = "ARTWORK",
        checked = "OVERLAY", disabledChecked = "OVERLAY" }
    local function roleTexture(self, role, asset, blend)
        local s = S[self]
        s.roles = s.roles or {}
        local t = s.roles[role]
        if asset == nil then
            if t then S[t].shown = false; s.roles[role] = nil end
            Lab.Touch()
            return
        end
        if type(asset) == "table" and S[asset] then
            t = asset
            if S[t].parent ~= self then Lab.kinds.Region.methods.SetParent(t, self) end
        else
            if not t then
                t = Lab.NewTexture("Texture", self, nil, ROLES[role])
                Lab.AddRegion(self, t)
                Lab.kinds.ScriptRegion.methods.SetAllPoints(t, self)
            end
            Lab.kinds.TextureBase.methods.SetTexture(t, asset)
        end
        local ts = S[t]
        ts.role, ts.layer, ts.shown = role, ROLES[role], true
        if role == "highlight" then ts.blend = blend or (ts.blend ~= "BLEND" and ts.blend) or "ADD" end
        if #ts.points == 0 then Lab.kinds.ScriptRegion.methods.SetAllPoints(t, self) end
        s.roles[role] = t
        Lab.Touch()
    end
    local function roleAtlas(self, role, atlas)
        roleTexture(self, role, "")
        Lab.kinds.TextureBase.methods.SetAtlas(S[self].roles[role], atlas)
    end
    for role, Name in pairs({ normal = "Normal", pushed = "Pushed", highlight = "Highlight", disabled = "Disabled" }) do
        Button["Set" .. Name .. "Texture"] = function(self, asset, blend) roleTexture(self, role, asset, blend) end
        Button["Get" .. Name .. "Texture"] = function(self) return S[self].roles and S[self].roles[role] end
        Button["Set" .. Name .. "Atlas"] = function(self, atlas) roleAtlas(self, role, atlas) end
        Button["Clear" .. Name .. "Texture"] = function(self) roleTexture(self, role, nil) end
    end
    Check.SetCheckedTexture = function(self, asset) roleTexture(self, "checked", asset) end
    Check.GetCheckedTexture = function(self) return S[self].roles and S[self].roles.checked end
    Check.SetDisabledCheckedTexture = function(self, asset) roleTexture(self, "disabledChecked", asset) end
    Check.GetDisabledCheckedTexture = function(self) return S[self].roles and S[self].roles.disabledChecked end

    local function buttonText(self)
        local s = S[self]
        if not s.fontString then
            local fs = Lab.NewFontString(self, nil, "OVERLAY")
            Lab.AddRegion(self, fs)
            Lab.kinds.ScriptRegion.methods.SetPoint(fs, "CENTER", self, "CENTER", 0, 0)
            S[fs].role = "text"
            s.fontString = fs
        end
        local fs = s.fontString
        local fo = s.normalFont
        if not s.enabled and s.disabledFont then fo = s.disabledFont
        elseif Lab.focus == self and s.highlightFont then fo = s.highlightFont end
        if fo and S[fs].fontObject ~= fo then S[fs].fontObject = fo; Lab.TextChanged(fs) end
        if not fo and not S[fs].fontObject and not (S[fs].fp and S[fs].fp.file) then
            S[fs].fontObject = Lab.G.GameFontNormal
        end
        return fs
    end
    Lab.ButtonText = buttonText
    function Button:SetText(text)
        local fs = buttonText(self)
        Lab.kinds.FontString.methods.SetText(fs, text)
    end
    function Button:SetFormattedText(fmt, ...) Button.SetText(self, string.format(fmt, ...)) end
    function Button:GetText()
        local fs = S[self].fontString
        return fs and Lab.kinds.FontString.methods.GetText(fs)
    end
    function Button:SetFontString(fs)
        local s = S[self]
        if S[fs].parent ~= self then Lab.kinds.Region.methods.SetParent(fs, self) end
        S[fs].role = "text"
        s.fontString = fs
        Lab.Touch()
    end
    function Button:GetFontString() return S[self].fontString end
    function Button:GetTextWidth()
        local fs = S[self].fontString
        return fs and Lab.kinds.FontString.methods.GetStringWidth(fs) or 0
    end
    function Button:GetTextHeight()
        local fs = S[self].fontString
        return fs and Lab.kinds.FontString.methods.GetStringHeight(fs) or 0
    end
    local function fontRole(field)
        return function(self, f)
            if type(f) == "string" then f = Lab.G[f] end
            S[self][field] = f
            if S[self].fontString or field == "normalFont" then buttonText(self) end
            Lab.Touch()
        end
    end
    Button.SetNormalFontObject = fontRole("normalFont")
    Button.SetHighlightFontObject = fontRole("highlightFont")
    Button.SetDisabledFontObject = fontRole("disabledFont")
    function Button:GetNormalFontObject() return S[self].normalFont end
    function Button:GetHighlightFontObject() return S[self].highlightFont end
    function Button:GetDisabledFontObject() return S[self].disabledFont end
    function Button:SetPushedTextOffset(x, y) S[self].pushedOffset = { x, y } end
    function Button:GetPushedTextOffset() local o = S[self].pushedOffset; return o[1], o[2] end
    function Button:Enable()
        local s = S[self]
        if s.enabled then return end
        s.enabled = true
        Lab.Touch()
        Lab.Run(self, "OnEnable")
    end
    function Button:Disable()
        local s = S[self]
        if not s.enabled then return end
        s.enabled = false
        s.pushed = nil
        Lab.Touch()
        Lab.Run(self, "OnDisable")
    end
    function Button:SetEnabled(on) if on then Button.Enable(self) else Button.Disable(self) end end
    function Button:IsEnabled() return S[self].enabled end
    function Button:RegisterForClicks(...)
        local s = S[self]
        s.clicks = {}
        for i = 1, select("#", ...) do
            local c = select(i, ...)
            if c == "AnyUp" or c == "AnyDown" then
                local way = c:sub(4)
                for _, b in ipairs({ "LeftButton", "RightButton", "MiddleButton", "Button4", "Button5" }) do
                    s.clicks[b .. way] = true
                end
            elseif c then
                s.clicks[c] = true
            end
        end
    end
    function Button:RegisterForMouse() end
    function Button:Click(button, down)
        button = button or "LeftButton"
        local s = S[self]
        if not s.enabled then return end
        if s.kind == "CheckButton" then s.checkedOn = not s.checkedOn; Lab.Touch() end
        Lab.Run(self, "PreClick", button, down or false)
        Lab.Run(self, "OnClick", button, down or false)
        Lab.Run(self, "PostClick", button, down or false)
    end
    function Button:GetButtonState() return S[self].pushed and "PUSHED" or "NORMAL" end
    function Button:SetButtonState(state, lock)
        S[self].pushed = state == "PUSHED" or nil
        S[self].pushLocked = lock and S[self].pushed or nil
        Lab.Touch()
    end
    function Button:SetMotionScriptsWhileDisabled(on) S[self].motionDisabled = on and true or nil end
    function Button:GetMotionScriptsWhileDisabled() return S[self].motionDisabled or false end
    Button.LockHighlight = Frame.LockHighlight
    Button.UnlockHighlight = Frame.UnlockHighlight

    function Check:SetChecked(on) S[self].checkedOn = on and true or false; Lab.Touch() end
    function Check:GetChecked() return S[self].checkedOn or false end

    -- Which of a button's role textures are seen now: the pushed one in place of the normal one while held, the
    -- disabled one in place of both while disabled, the highlight one under the mouse.
    function Lab.RoleShown(t)
        local ts = S[t]
        local role = ts.role
        local s = S[ts.parent]
        if not role or role == "text" or not s.roles or s.roles[role] ~= t then return true end
        local roles = s.roles
        local enabled = s.enabled ~= false
        local held = enabled and s.pushed
        if role == "normal" then
            if not enabled and roles.disabled then return false end
            return not (held and roles.pushed)
        elseif role == "pushed" then
            return held and true or false
        elseif role == "disabled" then
            return not enabled
        elseif role == "highlight" then
            return (Lab.focus == ts.parent and (enabled or s.motionDisabled)) or s.highlightLocked or false
        elseif role == "checked" then
            return s.checkedOn and (enabled or not roles.disabledChecked) or false
        elseif role == "disabledChecked" then
            return s.checkedOn and not enabled or false
        end
        return true
    end

    -- Scroll frames ---------------------------------------------------------------------------------------------------------
    function INIT.ScrollFrame(f)
        local s = S[f]
        s.clips = true
        s.vscroll, s.hscroll = 0, 0
    end
    function Scroll:SetScrollChild(child)
        local s = S[self]
        if s.child then S[s.child].place = nil end
        s.child = child
        if child then
            if S[child].parent ~= self then Frame.SetParent(child, self) end
            local sf = self
            S[child].place = function(c)
                local l, b, w, h = Lab.Rect(sf)
                if not l then return nil end
                local cs = S[c]
                local sc = Lab.EScale(c)
                local cw = (cs.w or 0) * sc
                local ch = (cs.h or 0) * sc
                if (cs.w or 0) == 0 and #cs.points > 0 then cw = w end
                local top = b + h + S[sf].vscroll * sc
                return l - S[sf].hscroll * sc, top - ch, cw, ch
            end
        end
        Lab.Touch()
    end
    function Scroll:GetScrollChild() return S[self].child end
    local function range(self, axis)
        local s = S[self]
        if not s.child then return 0 end
        local cs = S[s.child]
        local own = axis == "v" and Lab.kinds.ScriptRegion.methods.GetHeight(self) or Lab.kinds.ScriptRegion.methods.GetWidth(self)
        local size = axis == "v" and (cs.h or 0) or (cs.w or 0)
        return math.max(0, size - own)
    end
    function Scroll:GetVerticalScrollRange() return range(self, "v") end
    function Scroll:GetHorizontalScrollRange() return range(self, "h") end
    -- The game tells OnVerticalScroll (OnHorizontalScroll) only when the offset changes: Blizzard's scroll bar and
    -- its scroll frame set each other (ScrollUtil.InitScrollFrameWithScrollBar) and stop there.
    function Scroll:SetVerticalScroll(v)
        local was = S[self].vscroll
        S[self].vscroll = v
        Lab.Touch()
        if was == nil or math.abs((was or 0) - (v or 0)) > 1e-6 then Lab.Run(self, "OnVerticalScroll", v) end
    end
    function Scroll:GetVerticalScroll() return S[self].vscroll end
    function Scroll:SetHorizontalScroll(v)
        local was = S[self].hscroll
        S[self].hscroll = v
        Lab.Touch()
        if was == nil or math.abs((was or 0) - (v or 0)) > 1e-6 then Lab.Run(self, "OnHorizontalScroll", v) end
    end
    function Scroll:GetHorizontalScroll() return S[self].hscroll end
    function Scroll:UpdateScrollChildRect() Lab.Touch() end

    -- Sliders and status bars -------------------------------------------------------------------------------------------------
    local function initValue(f)
        local s = S[f]
        s.min, s.max, s.value = 0, 0, 0
        s.orientation = "HORIZONTAL"
    end
    function INIT.Slider(f)
        initValue(f)
        S[f].mouse, S[f].motion = true, true
        S[f].enabled = true
    end
    INIT.StatusBar = initValue

    local function setMinMax(self, lo, hi)
        Lab.Check(lo, "number", "SetMinMaxValues", 1)
        Lab.Check(hi, "number", "SetMinMaxValues", 2)
        local s = S[self]
        if s.min == lo and s.max == hi then return end
        s.min, s.max = lo, hi
        Lab.Run(self, "OnMinMaxChanged", lo, hi)
        if s.value < lo or s.value > hi then s.value = math.max(lo, math.min(hi, s.value)) end
        Lab.Touch()
    end
    local function setValue(self, v, user)
        Lab.Check(v, "number", "SetValue", 1)
        local s = S[self]
        v = math.max(s.min, math.min(s.max, v))
        if s.step and s.step > 0 and (not user or s.obeyStep) then
            v = s.min + math.floor((v - s.min) / s.step + 0.5) * s.step
            v = math.max(s.min, math.min(s.max, v))
        end
        if v == s.value then return end
        s.value = v
        Lab.Touch()
        Lab.Run(self, "OnValueChanged", v, user or false)
    end
    Lab.SetValue = setValue
    for _, M in ipairs({ Slider, Bar }) do
        M.SetMinMaxValues = setMinMax
        M.GetMinMaxValues = function(self) return S[self].min, S[self].max end
        M.SetValue = function(self, v) setValue(self, v, false) end
        M.GetValue = function(self) return S[self].value end
        M.SetOrientation = function(self, o) S[self].orientation = tostring(o):upper(); Lab.Touch() end
        M.GetOrientation = function(self) return S[self].orientation end
    end
    function Slider:SetValueStep(step) S[self].step = step end
    function Slider:GetValueStep() return S[self].step or 0 end
    function Slider:SetObeyStepOnDrag(on) S[self].obeyStep = on and true or nil end
    function Slider:GetObeyStepOnDrag() return S[self].obeyStep or false end
    function Slider:SetStepsPerPage(n) S[self].perPage = n end
    function Slider:GetStepsPerPage() return S[self].perPage or 1 end
    function Slider:Enable() S[self].enabled = true; Lab.Touch() end
    function Slider:Disable() S[self].enabled = false; Lab.Touch() end
    function Slider:IsEnabled() return S[self].enabled end
    function Slider:SetEnabled(on) S[self].enabled = on and true or false; Lab.Touch() end
    function Slider:IsDraggingThumb() return Lab.sliding == self end
    function Slider:SetThumbTexture(asset)
        local s = S[self]
        local t
        if type(asset) == "table" and S[asset] then
            t = asset
            if S[t].parent ~= self then Lab.kinds.Region.methods.SetParent(t, self) end
        else
            t = s.thumb
            if not t then
                t = Lab.NewTexture("Texture", self, nil, "OVERLAY")
                Lab.AddRegion(self, t)
            end
            Lab.kinds.TextureBase.methods.SetTexture(t, asset)
        end
        s.thumb = t
        local slider = self
        S[t].place = function(th)
            local l, b, w, h = Lab.Rect(slider)
            if not l then return nil end
            local ss = S[slider]
            local sc = Lab.EScale(th)
            local tw, thh = (S[th].w or 16) * sc, (S[th].h or 16) * sc
            local f = ss.max > ss.min and (ss.value - ss.min) / (ss.max - ss.min) or 0
            if ss.orientation == "VERTICAL" then
                return l + (w - tw) / 2, b + h - thh - f * (h - thh), tw, thh
            end
            return l + f * (w - tw), b + (h - thh) / 2, tw, thh
        end
        Lab.Touch()
    end
    function Slider:GetThumbTexture() return S[self].thumb end

    function Bar:SetStatusBarTexture(asset)
        local s = S[self]
        local t
        if type(asset) == "table" and S[asset] then
            t = asset
        else
            t = s.fill
            if not t then
                t = Lab.NewTexture("Texture", self, nil, "ARTWORK")
                Lab.AddRegion(self, t)
            end
            Lab.kinds.TextureBase.methods.SetTexture(t, asset)
        end
        s.fill = t
        local bar = self
        S[t].place = function(ft)
            local l, b, w, h = Lab.Rect(bar)
            if not l then return nil end
            local bs = S[bar]
            local f = bs.max > bs.min and (bs.value - bs.min) / (bs.max - bs.min) or 0
            f = math.max(0, math.min(1, f))
            S[ft].fillFraction = f
            if bs.orientation == "VERTICAL" then
                if bs.reverse then return l, b + h * (1 - f), w, h * f end
                return l, b, w, h * f
            end
            if bs.reverse then return l + w * (1 - f), b, w * f, h end
            return l, b, w * f, h
        end
        S[t].fillOf = self
        Lab.Touch()
        return true
    end
    function Bar:GetStatusBarTexture() return S[self].fill end
    function Bar:SetStatusBarColor(r, g, b, a)
        local fill = S[self].fill
        if fill then Lab.kinds.Region.methods.SetVertexColor(fill, r, g, b, a) end
        S[self].barColor = { r, g, b, a or 1 }
    end
    function Bar:GetStatusBarColor()
        local c = S[self].barColor or { 1, 1, 1, 1 }
        return c[1], c[2], c[3], c[4]
    end
    function Bar:SetReverseFill(on) S[self].reverse = on and true or nil; Lab.Touch() end
    function Bar:GetReverseFill() return S[self].reverse or false end
    function Bar:SetFillStyle(style) S[self].fillStyle = style; Lab.Touch() end
    function Bar:SetRotatesTexture(on) S[self].rotates = on end
    function Bar:SetStatusBarDesaturated(on) if S[self].fill then S[S[self].fill].desat = on and 1 or nil end end
    function Bar:IsInterpolating() return false end
    function Bar:SetToTargetValue() end

    -- Cooldowns and models --------------------------------------------------------------------------------------------------
    function Cooldown:SetCooldown(start, duration)
        local s = S[self]
        s.cdStart, s.cdDuration = start, duration
        Lab.Touch()
    end
    function Cooldown:GetCooldownTimes()
        local s = S[self]
        return (s.cdStart or 0) * 1000, (s.cdDuration or 0) * 1000
    end
    function Cooldown:GetCooldownDuration() return (S[self].cdDuration or 0) * 1000 end
    function Cooldown:Clear() S[self].cdStart = nil; Lab.Touch() end
    function Cooldown:SetSwipeColor(r, g, b, a) S[self].swipe = { r, g, b, a or 0.8 } end
    for _, name in ipairs({ "SetDrawEdge", "SetDrawSwipe", "SetDrawBling", "SetHideCountdownNumbers", "SetReverse",
        "SetSwipeTexture", "SetEdgeTexture", "SetBlingTexture", "SetUseCircularEdge", "SetCountdownFont" }) do
        Cooldown[name] = function(self, v) S[self][name] = v end
    end

    for _, name in ipairs({ "SetUnit", "ClearModel", "SetPortraitZoom", "SetFacing", "SetRotation", "RefreshUnit",
        "SetModel", "SetDisplayInfo", "SetCamDistanceScale", "SetPosition", "SetAnimation", "SetKeepModelOnHide",
        "SetModelScale", "Undress", "Dress", "TryOn", "SetSheathed", "SetLight", "SetCamera", "SetCreature",
        "SetBarberShopAlternateForm" }) do
        Model[name] = function(self, ...) S[self].model = { name, ... }; Lab.Touch() end
    end
    function Model:GetFacing() return 0 end
    function Model:GetModelScale() return 1 end
end
