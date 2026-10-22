-- Edit boxes: the text typed into them (the page sends the keys), the caret, the focus, and their scripts.
return function(Lab)
    local S = Lab.S
    local Edit = Lab.kinds.EditBox.methods
    local FS = Lab.kinds.FontString.methods
    local SR = Lab.kinds.ScriptRegion.methods

    Lab.editFocus = nil

    local function inner(f) return S[f].textRegion end

    local function place(f)
        local s = S[f]
        local fs = s.textRegion
        local i = s.insets
        S[fs].points = {}
        SR.SetPoint(fs, "TOPLEFT", f, "TOPLEFT", i[1], -i[3])
        SR.SetPoint(fs, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -i[2], i[4])
    end

    function Lab.INIT.EditBox(f)
        local s = S[f]
        s.mouse, s.motion, s.keyboard = true, true, true
        s.enabled, s.autoFocus = true, true
        s.value, s.cursor, s.maxLetters = "", 0, 0
        s.insets = { 0, 0, 0, 0 }
        local fs = Lab.NewFontString(f, nil, "OVERLAY")
        local fss = S[fs]
        fss.inner, fss.wrap, fss.editOf = true, false, f
        fss.fontObject = f        -- the edit box's own font settings (it is a font instance too)
        s.fp = { jh = "LEFT", jv = "MIDDLE" }
        Lab.AddRegion(f, fs)
        s.textRegion = fs
        place(f)
    end

    -- An edit box is a font instance: its font methods set what its text is drawn with.
    for _, name in ipairs({ "SetFont", "GetFont", "SetFontObject", "GetFontObject", "SetTextColor", "GetTextColor",
        "SetShadowColor", "GetShadowColor", "SetShadowOffset", "GetShadowOffset", "SetJustifyH", "GetJustifyH",
        "SetJustifyV", "GetJustifyV", "SetSpacing", "GetSpacing", "SetIndentedWordWrap" }) do
        local m = FS[name]
        Edit[name] = function(self, ...)
            local r = { m(self, ...) }
            Lab.TextChanged(inner(self))
            return unpack(r)
        end
    end

    local function show(self)
        local s = S[self]
        local text = s.value
        if s.password then text = string.rep("*", #text:gsub("[\128-\191]", "")) end
        S[inner(self)].text = text
        Lab.TextChanged(inner(self))
    end

    local function set(self, text, user)
        local s = S[self]
        if s.maxLetters > 0 then
            local n, out = 0, {}
            for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                n = n + 1
                if n > s.maxLetters then break end
                out[#out + 1] = ch
            end
            text = table.concat(out)
        end
        local changed = text ~= s.value
        s.value = text
        if s.cursor > #text then s.cursor = #text end
        show(self)
        if changed or not user then
            Lab.Run(self, "OnTextChanged", user or false)
        end
        if not user then Lab.Run(self, "OnTextSet") end
    end
    Lab.EditSet = set

    function Edit:SetText(text)
        if text == nil then text = "" end
        text = tostring(text)
        S[self].cursor = #text
        S[self].select = nil
        set(self, text, false)
    end
    function Edit:GetText() return S[self].value end
    function Edit:GetDisplayText() return S[inner(self)].text end
    function Edit:SetNumber(n) Edit.SetText(self, tostring(n)) end
    function Edit:GetNumber() return tonumber(S[self].value) or 0 end
    function Edit:Insert(text)
        local s = S[self]
        text = tostring(text)
        local v = s.value
        if s.select then
            v = v:sub(1, s.select[1]) .. v:sub(s.select[2] + 1)
            s.cursor = s.select[1]
            s.select = nil
        end
        s.value = v:sub(1, s.cursor) .. text .. v:sub(s.cursor + 1)
        s.cursor = s.cursor + #text
        set(self, s.value, true)
    end
    function Edit:SetMaxLetters(n) S[self].maxLetters = n or 0 end
    function Edit:GetMaxLetters() return S[self].maxLetters end
    function Edit:SetMaxBytes(n) S[self].maxBytes = n end
    function Edit:GetMaxBytes() return S[self].maxBytes or 0 end
    function Edit:GetNumLetters() return #(S[self].value:gsub("[\128-\191]", "")) end
    function Edit:SetNumeric(on) S[self].numeric = on and true or nil end
    function Edit:IsNumeric() return S[self].numeric or false end
    function Edit:SetPassword(on) S[self].password = on and true or nil; show(self) end
    function Edit:IsPassword() return S[self].password or false end
    function Edit:SetMultiLine(on)
        local s = S[self]
        s.multi = on and true or nil
        S[inner(self)].wrap = on and true or false
        s.fp.jv = on and "TOP" or "MIDDLE"
        Lab.TextChanged(inner(self))
    end
    function Edit:IsMultiLine() return S[self].multi or false end
    function Edit:SetAutoFocus(on) S[self].autoFocus = on and true or false end
    function Edit:IsAutoFocus() return S[self].autoFocus end
    function Edit:SetTextInsets(l, r, t, b)
        S[self].insets = { l or 0, r or 0, t or 0, b or 0 }
        place(self)
    end
    function Edit:GetTextInsets()
        local i = S[self].insets
        return i[1], i[2], i[3], i[4]
    end
    function Edit:SetCursorPosition(n)
        local s = S[self]
        s.cursor = math.max(0, math.min(#s.value, n or 0))
        Lab.Touch()
        Lab.Run(self, "OnCursorChanged", 0, 0, 0, 0)
    end
    function Edit:GetCursorPosition() return S[self].cursor end
    function Edit:HighlightText(from, to)
        local s = S[self]
        from = from or 0
        to = (to == nil or to < 0) and #s.value or to
        if to > from then s.select = { from, to } else s.select = nil end
        Lab.Touch()
    end
    function Edit:ClearHighlightText() S[self].select = nil; Lab.Touch() end
    function Edit:GetHighlightText()
        local s = S[self]
        if s.select then return s.value:sub(s.select[1] + 1, s.select[2]) end
        return ""
    end
    function Edit:HasText() return S[self].value ~= "" end
    function Edit:SetFocus()
        if Lab.editFocus == self then return end
        if Lab.editFocus then Lab.ClearEditFocus() end
        Lab.editFocus = self
        Lab.Touch()
        Lab.Run(self, "OnEditFocusGained")
    end
    function Edit:ClearFocus()
        if Lab.editFocus == self then Lab.ClearEditFocus() end
    end
    function Edit:HasFocus() return Lab.editFocus == self end
    function Lab.ClearEditFocus()
        local f = Lab.editFocus
        if not f then return end
        Lab.editFocus = nil
        S[f].select = nil
        Lab.Touch()
        Lab.Run(f, "OnEditFocusLost")
    end
    function Edit:Enable() S[self].enabled = true; Lab.Touch() end
    function Edit:Disable() S[self].enabled = false; Edit.ClearFocus(self); Lab.Touch() end
    function Edit:IsEnabled() return S[self].enabled end
    function Edit:SetEnabled(on) if on then Edit.Enable(self) else Edit.Disable(self) end end
    function Edit:SetBlinkSpeed(n) S[self].blink = n end
    function Edit:GetBlinkSpeed() return S[self].blink or 0.5 end
    function Edit:SetHistoryLines(n) S[self].historyMax = n end
    function Edit:GetHistoryLines() return S[self].historyMax or 0 end
    function Edit:AddHistoryLine(text)
        local s = S[self]
        s.history = s.history or {}
        s.history[#s.history + 1] = text
    end
    function Edit:ClearHistory() S[self].history = nil end
    function Edit:SetAltArrowKeyMode(on) S[self].altArrow = on end
    function Edit:GetAltArrowKeyMode() return S[self].altArrow or false end
    function Edit:SetCountInvisibleLetters(on) S[self].countInvisible = on end
    function Edit:SetHighlightColor(r, g, b, a) S[self].highlightColor = { r, g, b, a or 1 } end
    function Edit:SetVisibleTextByteLimit(n) S[self].byteLimit = n end
    function Edit:IsInIMECompositionMode() return false end
    function Edit:GetInputLanguage() return "ROMAN" end

    -- The keys the page sends while an edit box has the focus.
    local function prevChar(v, i)
        i = i - 1
        while i > 0 and v:byte(i) >= 128 and v:byte(i) < 192 do i = i - 1 end
        return math.max(0, i - 1)
    end
    local function nextChar(v, i)
        i = i + 2
        while i <= #v and v:byte(i) >= 128 and v:byte(i) < 192 do i = i + 1 end
        return math.min(#v, i - 1)
    end

    function Lab.EditKey(f, key, char, mods)
        local s = S[f]
        if not s.enabled then return end
        local v = s.value
        if char and char ~= "" then
            if s.numeric and not char:match("^%d$") then return end
            Lab.Run(f, "OnChar", char)
            if Lab.editFocus ~= f then return end
            Edit.Insert(f, char)
            return
        end
        if key == "ENTER" then
            if s.multi and not Lab.Has(f, "OnEnterPressed") then Edit.Insert(f, "\n") return end
            Lab.Run(f, "OnEnterPressed")
        elseif key == "ESCAPE" then
            if Lab.Has(f, "OnEscapePressed") then Lab.Run(f, "OnEscapePressed") else Edit.ClearFocus(f) end
        elseif key == "TAB" then
            Lab.Run(f, "OnTabPressed")
        elseif key == "SPACE" then
            Lab.Run(f, "OnSpacePressed")
        elseif key == "BACKSPACE" then
            if s.select then Edit.Insert(f, "") return end
            if s.cursor > 0 then
                local cut = prevChar(v, s.cursor)
                s.value = v:sub(1, cut) .. v:sub(s.cursor + 1)
                s.cursor = cut
                set(f, s.value, true)
            end
        elseif key == "DELETE" then
            if s.select then Edit.Insert(f, "") return end
            if s.cursor < #v then
                s.value = v:sub(1, s.cursor) .. v:sub(nextChar(v, s.cursor) + 1)
                set(f, s.value, true)
            end
        elseif key == "LEFT" then
            s.select = nil; s.cursor = prevChar(v, s.cursor); Lab.Touch()
        elseif key == "RIGHT" then
            s.select = nil; s.cursor = nextChar(v, s.cursor); Lab.Touch()
        elseif key == "HOME" then
            s.select = nil; s.cursor = 0; Lab.Touch()
        elseif key == "END" then
            s.select = nil; s.cursor = #v; Lab.Touch()
        elseif key == "UP" or key == "DOWN" then
            Lab.Run(f, "OnArrowPressed", key)
            local h = s.history
            if h and #h > 0 and not s.multi then
                s.historyAt = math.max(1, math.min(#h + 1, (s.historyAt or #h + 1) + (key == "UP" and -1 or 1)))
                Edit.SetText(f, h[s.historyAt] or "")
            end
        elseif key == "A" and mods and mods.ctrl then
            Edit.HighlightText(f)
        end
    end
end
