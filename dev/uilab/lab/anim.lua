-- Animations: groups of alpha, translation, scale and rotation steps on a frame or region, played in order,
-- with their scripts (OnPlay, OnFinished, OnLoop, OnUpdate) as the game runs them.
return function(Lab)
    local S = Lab.S
    local Group = Lab.kinds.AnimationGroup.methods
    local Anim = Lab.kinds.Animation.methods
    local AlphaM = Lab.kinds.Alpha.methods
    local Move = Lab.kinds.Translation.methods
    local ScaleM = Lab.kinds.Scale.methods
    local Turn = Lab.kinds.Rotation.methods

    Lab.playing = {}   -- [group] = true while it plays

    Lab.ScriptMethods(Group)
    Lab.ScriptMethods(Anim)

    function Lab.NewAnimationGroup(target, name, template)
        local g = Lab.New("AnimationGroup", { name = name, parent = target, target = target, anims = {}, looping = "NONE",
            shown = true, scripts = {} })
        local ts = S[target]
        ts.anims = ts.anims or {}
        ts.anims[#ts.anims + 1] = g
        if template then Lab.ApplyTemplate(g, template) end
        return g
    end

    local KINDS = { alpha = "Alpha", translation = "Translation", scale = "Scale", rotation = "Rotation",
        animation = "Animation" }
    function Group:CreateAnimation(kind, name, template)
        local k = KINDS[tostring(kind or "Animation"):lower()]
        if not k then
            Lab.Warn("animation kind the lab does not play: " .. tostring(kind))
            k = "Animation"
        end
        local a = Lab.New(k, { name = name, parent = self, group = self, duration = 0, delay = 0, endDelay = 0, order = 1,
            smoothing = "NONE", shown = true, scripts = {} })
        local list = S[self].anims
        list[#list + 1] = a
        if template then Lab.ApplyTemplate(a, template) end
        return a
    end
    function Group:GetAnimations() return unpack(S[self].anims) end
    function Group:SetLooping(l) S[self].looping = tostring(l):upper() end
    function Group:GetLooping() return S[self].looping end
    function Group:GetLoopState() return S[self].loopState or "NONE" end
    function Group:SetToFinalAlpha(on) S[self].keepFinal = on and true or nil end
    function Group:IsSetToFinalAlpha() return S[self].keepFinal or false end
    function Group:IsPlaying() return Lab.playing[self] and not S[self].paused or false end
    function Group:IsPaused() return S[self].paused or false end
    function Group:IsDone() return S[self].done or false end
    function Group:IsReverse() return S[self].reverse or false end
    function Group:GetProgress()
        local d = Group.GetDuration(self)
        return d > 0 and math.min(1, (S[self].elapsed or 0) / d) or 0
    end
    function Group:GetDuration()
        local total = 0
        for _, part in ipairs(Lab.Orders(self)) do total = total + part.length end
        return total
    end
    function Group:SetPlaying(on) if on then Group.Play(self) else Group.Stop(self) end end
    function Group:Play(reverse, offset)
        local s = S[self]
        s.elapsed, s.reverse, s.paused, s.done = offset or 0, reverse and true or nil, nil, nil
        s.loopState = "NONE"
        Lab.playing[self] = true
        Lab.Run(self, "OnPlay")
        for _, a in ipairs(s.anims) do Lab.Run(a, "OnPlay") end
        Lab.ApplyGroup(self)
    end
    function Group:Restart(reverse, offset) Group.Play(self, reverse, offset) end
    function Group:Pause() S[self].paused = true; Lab.Run(self, "OnPause") end
    local function clear(self)
        local ts = S[S[self].target]
        ts.animAlpha, ts.animX, ts.animY, ts.animScale, ts.animTurn = nil, nil, nil, nil, nil
        Lab.Touch()
    end
    function Group:Stop()
        if not Lab.playing[self] then return end
        Lab.playing[self] = nil
        clear(self)
        Lab.Run(self, "OnStop", false)
    end
    function Group:Finish()
        if not Lab.playing[self] then return end
        S[self].elapsed = Group.GetDuration(self)
        Lab.TickGroup(self, 0)
    end
    function Group:SetDuration() end
    function Group:SetAnimationSpeedMultiplier(n) S[self].speed = n end
    function Group:GetAnimationSpeedMultiplier() return S[self].speed or 1 end
    function Group:RemoveAnimations() S[self].anims = {} end

    function Anim:SetDuration(d) S[self].duration = d or 0 end
    function Anim:GetDuration() return S[self].duration end
    function Anim:SetStartDelay(d) S[self].delay = d or 0 end
    function Anim:GetStartDelay() return S[self].delay end
    function Anim:SetEndDelay(d) S[self].endDelay = d or 0 end
    function Anim:GetEndDelay() return S[self].endDelay end
    function Anim:SetOrder(n) S[self].order = n end
    function Anim:GetOrder() return S[self].order end
    function Anim:SetSmoothing(sm) S[self].smoothing = tostring(sm):upper() end
    function Anim:GetSmoothing() return S[self].smoothing end
    function Anim:SetSmoothProgress() end
    function Anim:SetTarget(t) S[self].target = t end
    function Anim:SetChildKey(key) S[self].childKey = key end
    function Anim:SetTargetKey(key) S[self].childKey = key end
    function Anim:SetTargetName(name) S[self].target = Lab.G[name] end
    function Anim:SetTargetParent() S[self].target = S[S[self].group].target end
    function Anim:GetTarget() return Lab.AnimTarget(self) end
    function Anim:GetRegionParent() return S[S[self].group].target end
    function Anim:GetProgress() return S[self].progress or 0 end
    function Anim:GetSmoothProgress() return S[self].progress or 0 end
    function Anim:GetElapsed() return S[self].elapsedOwn or 0 end
    function Anim:IsPlaying() return Lab.playing[S[self].group] and true or false end
    function Anim:IsDone() return false end
    function Anim:Play() Group.Play(S[self].group) end
    function Anim:Stop() Group.Stop(S[self].group) end
    function Anim:Pause() Group.Pause(S[self].group) end

    function AlphaM:SetFromAlpha(a) S[self].from = a end
    function AlphaM:GetFromAlpha() return S[self].from or 0 end
    function AlphaM:SetToAlpha(a) S[self].to = a end
    function AlphaM:GetToAlpha() return S[self].to or 0 end
    function Move:SetOffset(x, y) S[self].dx, S[self].dy = x or 0, y or 0 end
    function Move:GetOffset() return S[self].dx or 0, S[self].dy or 0 end
    function ScaleM:SetScale(x, y) S[self].sfrom, S[self].sto = { 1, 1 }, { x, y or x } end
    function ScaleM:GetScale() local t = S[self].sto or { 1, 1 }; return t[1], t[2] end
    function ScaleM:SetScaleFrom(x, y) S[self].sfrom = { x, y or x } end
    function ScaleM:SetScaleTo(x, y) S[self].sto = { x, y or x } end
    function ScaleM:GetScaleFrom() local t = S[self].sfrom or { 1, 1 }; return t[1], t[2] end
    function ScaleM:GetScaleTo() local t = S[self].sto or { 1, 1 }; return t[1], t[2] end
    function ScaleM:SetOrigin(point, x, y) S[self].origin = { point, x, y } end
    function Turn:SetDegrees(d) S[self].turn = math.rad(d or 0) end
    function Turn:GetDegrees() return math.deg(S[self].turn or 0) end
    function Turn:SetRadians(r) S[self].turn = r or 0 end
    function Turn:GetRadians() return S[self].turn or 0 end
    Turn.SetOrigin = ScaleM.SetOrigin

    function Lab.AnimTarget(a)
        local s = S[a]
        if s.target then return s.target end
        local t = S[s.group].target
        if s.childKey then t = t[s.childKey] or t end
        return t
    end

    -- The orders a group plays one after another, each as long as its longest animation.
    function Lab.Orders(g)
        local byOrder, keys = {}, {}
        for _, a in ipairs(S[g].anims) do
            local o = S[a].order or 1
            if not byOrder[o] then byOrder[o] = { anims = {}, length = 0 }; keys[#keys + 1] = o end
            local part = byOrder[o]
            part.anims[#part.anims + 1] = a
            local s = S[a]
            part.length = math.max(part.length, s.delay + s.duration + s.endDelay)
        end
        table.sort(keys)
        local out = {}
        for _, k in ipairs(keys) do out[#out + 1] = byOrder[k] end
        return out
    end

    local function smooth(p, how)
        if how == "IN" then return p * p end
        if how == "OUT" then return 1 - (1 - p) * (1 - p) end
        if how == "IN_OUT" then return p * p * (3 - 2 * p) end
        return p
    end

    -- Puts the group's effect on its targets at its time now.
    function Lab.ApplyGroup(g)
        local s = S[g]
        local t = s.elapsed or 0
        local effects = {}
        local start = 0
        for _, part in ipairs(Lab.Orders(g)) do
            for _, a in ipairs(part.anims) do
                local as = S[a]
                local local_ = t - start - as.delay
                local p
                if local_ <= 0 then p = (start + as.delay > t) and 0 or 0
                elseif as.duration <= 0 then p = 1
                else p = math.min(1, local_ / as.duration) end
                if t < start then p = 0 end
                if s.reverse then p = 1 - p end
                as.progress = p
                as.elapsedOwn = math.max(0, local_)
                local e = smooth(p, as.smoothing)
                local target = Lab.AnimTarget(a)
                local fx = effects[target] or {}
                effects[target] = fx
                if as.kind == "Alpha" then
                    if t >= start + as.delay or fx.alpha == nil then
                        fx.alpha = (as.from or 0) + ((as.to or 0) - (as.from or 0)) * e
                    end
                elseif as.kind == "Translation" then
                    fx.x = (fx.x or 0) + (as.dx or 0) * e
                    fx.y = (fx.y or 0) + (as.dy or 0) * e
                elseif as.kind == "Scale" then
                    local from, to = as.sfrom or { 1, 1 }, as.sto or { 1, 1 }
                    fx.scale = (fx.scale or 1) * (from[1] + (to[1] - from[1]) * e)
                elseif as.kind == "Rotation" then
                    fx.turn = (fx.turn or 0) + (as.turn or 0) * e
                end
            end
            start = start + part.length
        end
        for target, fx in pairs(effects) do
            local ts = S[target]
            if ts then
                ts.animAlpha = fx.alpha
                local sc = (fx.x or fx.y) and Lab.EScale(target) or 1
                ts.animX = fx.x and fx.x * sc or nil
                ts.animY = fx.y and fx.y * sc or nil
                ts.animScale = fx.scale
                ts.animTurn = fx.turn
            end
        end
        Lab.Touch()
    end

    function Lab.TickGroup(g, dt)
        local s = S[g]
        if s.paused then return end
        s.elapsed = (s.elapsed or 0) + dt * (s.speed or 1)
        local total = Group.GetDuration(g)
        Lab.Run(g, "OnUpdate", dt)
        if s.elapsed >= total then
            if s.looping == "REPEAT" or s.looping == "BOUNCE" then
                s.elapsed = s.elapsed - total
                if s.looping == "BOUNCE" then s.reverse = not s.reverse or nil end
                s.loopState = s.reverse and "REVERSE" or "FORWARD"
                Lab.Run(g, "OnLoop", s.loopState)
                Lab.ApplyGroup(g)
                return
            end
            s.elapsed = total
            Lab.ApplyGroup(g)
            Lab.playing[g] = nil
            s.done = true
            local keep = s.keepFinal
            if not keep then clear(g) end
            for _, a in ipairs(s.anims) do Lab.Run(a, "OnFinished", false) end
            Lab.Run(g, "OnFinished", false)
            return
        end
        Lab.ApplyGroup(g)
    end

    function Lab.TickAnimations(dt)
        local list = {}
        for g in pairs(Lab.playing) do list[#list + 1] = g end
        table.sort(list, function(a, b) return S[a].order < S[b].order end)
        for _, g in ipairs(list) do
            local target = S[g].target
            if Lab.playing[g] and (not target or Lab.Visible(target)) then Lab.TickGroup(g, dt) end
        end
    end
end
