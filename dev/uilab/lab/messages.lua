-- Message frames: the chat's scrolling message frame and the plain message frame (the errors in the middle of the
-- screen). In the game the first is Blizzard's (ScrollingMessageFrameMixin); the lab draws its own with the same
-- methods: newest line at the bottom, older ones above, fading after a while, scrolled by the wheel or by code.
return function(Lab)
    local S = Lab.S
    local SMF = Lab.kinds.ScrollingMessageFrame.methods
    local MF = Lab.kinds.MessageFrame.methods
    local FS = Lab.kinds.FontString.methods
    local SR = Lab.kinds.ScriptRegion.methods

    local function init(f, insertTop)
        local s = S[f]
        s.lines, s.maxLines, s.offset = {}, 120, 0
        s.fading, s.timeVisible, s.fadeDuration = true, 10, 3
        s.insert = insertTop and "TOP" or "BOTTOM"
        s.fp = { jh = "LEFT", jv = "TOP" }
        s.pool = {}
        s.messageFrame = true
    end
    Lab.INIT.ScrollingMessageFrame = function(f) init(f, false) end
    Lab.INIT.MessageFrame = function(f) init(f, true) end

    local M = {}
    for _, name in ipairs({ "SetFont", "GetFont", "SetFontObject", "GetFontObject", "SetTextColor", "GetTextColor",
        "SetShadowColor", "GetShadowColor", "SetShadowOffset", "GetShadowOffset", "SetJustifyH", "GetJustifyH",
        "SetJustifyV", "GetJustifyV", "SetSpacing", "GetSpacing", "SetIndentedWordWrap", "GetIndentedWordWrap" }) do
        local m = FS[name]
        M[name] = function(self, ...)
            local r = { m(self, ...) }
            for _, fs in ipairs(S[self].pool) do Lab.TextChanged(fs) end
            Lab.Touch()
            return unpack(r)
        end
    end

    function M:AddMessage(text, r, g, b, id, accessID, typeID)
        local s = S[self]
        if text == nil then text = "" end
        local line = { text = tostring(text), r = r, g = g, b = b, id = id, typeID = typeID, at = Lab.time }
        if s.insert == "TOP" then
            table.insert(s.lines, 1, line)
            if #s.lines > s.maxLines then s.lines[#s.lines] = nil end
        else
            s.lines[#s.lines + 1] = line
            if #s.lines > s.maxLines then table.remove(s.lines, 1) end
            if s.offset > 0 then s.offset = math.min(s.offset + 1, #s.lines - 1) end
        end
        Lab.Touch()
    end
    function M:BackFillMessage(text, r, g, b)
        local s = S[self]
        table.insert(s.lines, 1, { text = tostring(text), r = r, g = g, b = b, at = Lab.time })
        Lab.Touch()
    end
    function M:Clear() S[self].lines = {}; S[self].offset = 0; Lab.Touch() end
    function M:GetNumMessages() return #S[self].lines end
    function M:GetMessageInfo(i)
        local l = S[self].lines[i]
        if l then return l.text, l.r, l.g, l.b, l.id end
    end
    function M:RemoveMessagesByPredicate(pred)
        local lines = S[self].lines
        for i = #lines, 1, -1 do
            if pred(lines[i].text, lines[i].r, lines[i].g, lines[i].b, lines[i].id) then table.remove(lines, i) end
        end
        Lab.Touch()
    end
    function M:TransformMessages(pred, change)
        for _, l in ipairs(S[self].lines) do
            if pred(l.text, l.r, l.g, l.b, l.id) then
                l.text, l.r, l.g, l.b = change(l.text, l.r, l.g, l.b, l.id)
            end
        end
        Lab.Touch()
    end
    function M:SetMaxLines(n) S[self].maxLines = n; Lab.Touch() end
    function M:GetMaxLines() return S[self].maxLines end
    function M:SetFading(on) S[self].fading = on and true or false; Lab.Touch() end
    function M:GetFading() return S[self].fading end
    function M:SetTimeVisible(t) S[self].timeVisible = t end
    function M:GetTimeVisible() return S[self].timeVisible end
    function M:SetFadeDuration(t) S[self].fadeDuration = t end
    function M:GetFadeDuration() return S[self].fadeDuration end
    function M:SetFadePower() end
    function M:ResetAllFadeTimes()
        for _, l in ipairs(S[self].lines) do l.at = Lab.time end
        Lab.Touch()
    end
    function M:SetInsertMode(mode)
        local m = tostring(mode):upper()
        if mode == 1 then m = "TOP" elseif mode == 2 then m = "BOTTOM" end
        S[self].insert = m
    end
    function M:GetInsertMode() return S[self].insert end
    function M:SetScrollOffset(n)
        local s = S[self]
        s.offset = math.max(0, math.min(#s.lines - 1, n))
        Lab.Touch()
        if s.onScroll then Lab.Call(s.onScroll, self, s.offset) end
    end
    function M:GetScrollOffset() return S[self].offset end
    function M:ScrollUp() M.SetScrollOffset(self, S[self].offset + 1) end
    function M:ScrollDown() M.SetScrollOffset(self, S[self].offset - 1) end
    function M:PageUp() M.SetScrollOffset(self, S[self].offset + (S[self].shownLines or 1)) end
    function M:PageDown() M.SetScrollOffset(self, S[self].offset - (S[self].shownLines or 1)) end
    function M:ScrollToTop() M.SetScrollOffset(self, #S[self].lines - 1) end
    function M:ScrollToBottom() M.SetScrollOffset(self, 0) end
    function M:ScrollByAmount(n) M.SetScrollOffset(self, S[self].offset + n) end
    function M:AtTop() return S[self].offset >= #S[self].lines - 1 end
    function M:AtBottom() return S[self].offset == 0 end
    function M:GetMaxScrollRange() return math.max(0, #S[self].lines - 1) end
    function M:SetOnScrollChangedCallback(fn) S[self].onScroll = fn end
    function M:SetOnDisplayRefreshedCallback(fn) S[self].onRefresh = fn end
    function M:SetTextCopyable() end
    function M:IsTextCopyable() return false end
    function M:CalculateLineAlphaValueFromTimestamp() return 1 end
    for k, v in pairs(M) do SMF[k] = v; MF[k] = v end

    -- Lays the lines out before each drawing: as many as fit, newest at the bottom (at the top for a plain
    -- message frame), each a font string of the frame's font as wide as the frame.
    function Lab.LayoutMessages(f)
        local s = S[f]
        local l, b, w, h = Lab.Rect(f)
        for _, fs in ipairs(s.pool) do S[fs].shown = false end
        if not l then return end
        local sc = Lab.EScale(f)
        w, h = w / sc, h / sc
        local used, n = 0, 0
        local spacing = Lab.FontProps(f).spacing or 0
        local count = #s.lines
        local first = s.insert == "TOP" and 1 or count - s.offset
        local step = s.insert == "TOP" and 1 or -1
        local i = first
        while i >= 1 and i <= count do
            local line = s.lines[i]
            local alpha = 1
            if s.fading and Lab.time - line.at > s.timeVisible then
                alpha = 1 - (Lab.time - line.at - s.timeVisible) / math.max(0.01, s.fadeDuration)
            end
            if alpha <= 0 and s.offset == 0 then break end
            n = n + 1
            local fs = s.pool[n]
            if not fs then
                fs = Lab.NewFontString(f, nil, "ARTWORK")
                local fss = S[fs]
                fss.inner, fss.fontObject, fss.messageLine = true, f, true
                Lab.AddRegion(f, fs)
                s.pool[n] = fs
            end
            local fss = S[fs]
            fss.text = line.text
            -- a line without a colour of its own has the frame's
            fss.fp = line.r and { r = line.r, g = line.g, b = line.b } or nil
            fss.w = w
            fss.layout = nil
            local _, lh = Lab.TextIntrinsic(fs, w)
            if used + lh > h + 0.5 and n > 1 then
                fss.shown = false
                break
            end
            fss.shown = true
            fss.alpha = math.max(0, math.min(1, alpha))
            fss.points = {}
            if s.insert == "TOP" then
                fss.points[1] = { point = "TOPLEFT", rel = f, relPoint = "TOPLEFT", x = 0, y = -used }
            else
                fss.points[1] = { point = "BOTTOMLEFT", rel = f, relPoint = "BOTTOMLEFT", x = 0, y = used }
            end
            used = used + lh + spacing
            i = i + step
        end
        s.shownLines = n
        Lab.rects = nil
    end
end
