local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Select
--  Words picked out of the messages on the full screen, to copy with Ctrl+C:
--  press the mouse on the text of a bubble, drag over as many messages as you
--  like (yours and everybody else's; the wheel scrolls on meanwhile), let go.
--  What is picked is lit in the grey the game lights picked text with in its
--  own lists, and stays lit until the next press, Esc, another key, or the
--  full screen's going. A press with no drag picks nothing; a link answers a
--  click as always (its frame takes the mouse over it, Links.lua).
--
--  The game's copy to the clipboard (CopyToClipboard) is for its own code
--  only; its edit boxes copy what is highlighted in them on Ctrl+C. So the
--  words picked wait in an edit box of ours, out of sight, highlighted and
--  with the keyboard (Hold), until Ctrl+C has copied them: a frame later the
--  keyboard is the game's again, and the words stay lit. A line being written
--  in keeps its words meanwhile: the game closes its line on losing the
--  keyboard only while it is empty.
--
--  Which letter is under the mouse, and where a span of letters stands, the
--  game's text tells (FindCharacterIndexAtCoordinate, CalculateScreenArea-
--  FromCharacterSpan), counting the letters of the text with its codes (a
--  colour, a link's hidden part). A row lights its message's span whenever it
--  is drawn (Bubble.Init asks Select.Span), so a scroll that hands the rows to
--  other messages keeps the picking where it is. A message's place is the one
--  it had in its list when the press came; one that comes later is never picked.
--
--  What is copied: the words as they read (no colours, a link's words without
--  its code, no icons). From one message, just the words picked; from more,
--  each message's on a line of its own, after the name of whoever said it.
--
--  A list of messages takes part by Select.Attach (its box and its messages,
--  in their order); it takes the mouse only while Select.Allow says so: the
--  chat's only while the window fills the screen, so a click on it at its size
--  still goes into the game.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bubble = ns.Bubble
local Select = {}
ns.Select = Select

local lists = {} -- [box] = its messages on show, in their order (the module's own table, the same always)
local pick       -- what is picked: { box, order (the messages then), at ([message] = place), from, to ({ message, caret }) }
local held       -- the mouse holds: pick.to follows it
local copy       -- the edit box the words wait in
local freeing    -- the keyboard is being given back by us, not taken by a click elsewhere
local driver     -- runs while the mouse holds

-------------------------------------------------------------------------------
--  The letter under the mouse
-------------------------------------------------------------------------------
-- The caret nearest the mouse (before its letter, 1: before the first) in the text of a row in view: the one the
-- mouse is in, else the nearest by height (beside a bubble, the line of text there). One function for every row,
-- no closure per look: the mouse is looked at every frame while it holds.
local x, y, found, caret, distance
local function Nearest(row, entry)
    local text = Bubble.Text(row)
    if not text or entry.pill then return nil end
    local index, inside = text:FindCharacterIndexAtCoordinate(x, y)
    local top, bottom = text:GetTop(), text:GetBottom()
    if not (index and top and bottom) then return nil end
    local off = inside and -1 or (y > top and y - top) or (y < bottom and bottom - y) or 0
    if not distance or off < distance then found, caret, distance = entry, index, off end
    return inside -- found: the rest need not be asked
end

local function Under(box)
    local scale = box:GetEffectiveScale()
    local mouseX, mouseY = GetCursorPosition()
    x, y, found, caret, distance = mouseX / scale, mouseY / scale, nil, nil, nil
    box:ForEachFrame(Nearest)
    return found, caret
end

-------------------------------------------------------------------------------
--  What is picked
-------------------------------------------------------------------------------
-- Its two ends, the earlier first, and their places.
local function Ends()
    local one, other = pick.from, pick.to
    local first, last = pick.at[one[1]], pick.at[other[1]]
    if first < last or (first == last and one[2] <= other[2]) then return one, other, first, last end
    return other, one, last, first
end

-- The part of a message that is picked: from the caret before its first letter picked to the caret after its last
-- (all of it: 1, #text + 1); nil: none of it.
function Select.Span(entry)
    local place = pick and not entry.pill and pick.at[entry]
    if not place then return nil end
    local first, last, from, to = Ends()
    if place < from or place > to then return nil end
    local left = place == from and first[2] or 1
    local right = place == to and last[2] or #entry.text + 1
    if left >= right then return nil end
    return left, right
end

-- The codes whose whole reads as nothing, by what closes them: an icon, an atlas, a Battle.net name.
local CLOSE = { T = "|t", A = "|a", K = "|k" }

local function Continues(text, index)
    local byte = text:byte(index)
    return byte ~= nil and byte >= 0x80 and byte < 0xC0
end

-- The words of a text's span (its letters from caret from up to caret to, codes counted) as they read: no colours,
-- a link's words without its hidden part, no icons. A caret inside a letter of more than one byte takes it whole.
local function Words(text, from, to)
    while from > 1 and Continues(text, from) do from = from - 1 end
    while Continues(text, to) do to = to + 1 end
    local out, index, size = {}, 1, #text
    while index <= size do
        local bar = text:find("|", index, true) or size + 1
        local left, right = math.max(index, from), math.min(bar - 1, to - 1)
        if left <= right then out[#out + 1] = text:sub(left, right) end
        if bar > size then break end
        local code = text:sub(bar + 1, bar + 1)
        local within = bar >= from and bar < to
        if code == "|" then -- a bar itself
            if within then out[#out + 1] = "|" end
            index = bar + 2
        elseif code == "n" then -- a new line
            if within then out[#out + 1] = "\n" end
            index = bar + 2
        elseif code == "c" and text:sub(bar + 2, bar + 2) == "n" then -- a colour by its name: |cn, the name, a colon
            local close = text:find(":", bar + 3, true)
            index = close and close + 1 or size + 1
        elseif code == "c" then -- a colour: |c and eight digits
            index = bar + 10
        elseif code == "H" then -- a link: its hidden part, up to the |h before its words
            local close = text:find("|h", bar + 2, true)
            index = close and close + 2 or size + 1
        elseif CLOSE[code] then
            local close = text:find(CLOSE[code], bar + 2, true)
            index = close and close + 2 or size + 1
        else -- |r, the |h after a link's words: nothing to read
            index = bar + 2
        end
    end
    return table.concat(out)
end
Select.Words = Words

-- Whose a message is, for a line copied with others: the speaker's name as shown above it, yours, none (a note).
local function Whose(entry)
    if entry.side == "right" then return Core.FullName("player") end
    if entry.side ~= "left" then return nil end
    local speaker = Bubble.Speaker(entry)
    local name = Words(speaker, 1, #speaker + 1)
    return name ~= "" and name or nil
end

-- The words picked, as they are copied.
local function Gather()
    local _, _, from, to = Ends()
    local lines, many = {}, from ~= to
    for place = from, to do
        local entry = pick.order[place]
        local left, right = Select.Span(entry)
        if left then
            local words, who = Words(entry.text, left, right), many and Whose(entry)
            lines[#lines + 1] = who and (who .. ": " .. words) or words
        end
    end
    return table.concat(lines, "\n")
end

-- Every row in view of the list picked in shows its part of what is picked.
local function Remark(row, entry)
    Bubble.Mark(row, Select.Span(entry))
end

local function Redraw(box)
    box:ForEachFrame(Remark)
end

-------------------------------------------------------------------------------
--  The edit box the words wait in
-------------------------------------------------------------------------------
-- The keyboard back to the game: the words stay lit.
local function Free()
    if not (copy and copy:IsShown()) then return end
    freeing = true
    copy:ClearFocus()
    copy:Hide()
    freeing = false
end

-- Nothing is picked any more: no word lit, the keyboard the game's.
local function Drop()
    local box = pick and pick.box
    pick, held = nil, false
    if driver then driver:Hide() end
    if box then Redraw(box) end
    Free()
end

-- Ctrl+C copies what the edit box has highlighted, as the game's edit boxes do, after its key's scripts: the
-- keyboard goes back a frame later. Any other key (a modifier alone aside) lets the words go.
local MODIFIERS = { LCTRL = true, RCTRL = true, LSHIFT = true, RSHIFT = true, LALT = true, RALT = true, LMETA = true, RMETA = true }
local Copied = Core.Later(function() ns.Safe("selection", Free) end)

local function Key(_, key)
    if MODIFIERS[key] then return end
    if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then return Copied() end
    Drop()
end

-- The keyboard taken by something else (a click into a line): the words are let go.
local function Lost()
    if not freeing then Drop() end
end

local function Hold(words)
    if not copy then
        copy = CreateFrame("EditBox", nil, UIParent)
        copy:SetSize(1, 1)
        copy:SetPoint("BOTTOMLEFT")
        copy:SetAlpha(0)
        copy:EnableMouse(false)
        copy:SetAutoFocus(false)
        copy:SetMultiLine(true)
        copy:SetMaxLetters(0) -- no end: as much as is picked
        copy:SetFontObject(ChatFontNormal)
        copy:SetScript("OnKeyDown", function(self, key) ns.Safe("selection", Key, self, key) end)
        copy:SetScript("OnEscapePressed", function() ns.Safe("selection", Drop) end)
        copy:SetScript("OnEditFocusLost", function() ns.Safe("selection", Lost) end)
    end
    copy:Show()
    copy:SetText(words)
    copy:HighlightText()
    copy:SetFocus()
end

-------------------------------------------------------------------------------
--  The mouse
-------------------------------------------------------------------------------
-- While it holds, the end it holds follows it.
local function Follow()
    local entry, at = Under(pick.box)
    if not (entry and pick.at[entry]) or (entry == pick.to[1] and at == pick.to[2]) then return end
    pick.to = { entry, at }
    Redraw(pick.box)
end

-- Pressed in a list: what was picked goes, and the picking starts at the letter there.
local function Take(box, button)
    if button ~= "LeftButton" then return end
    Drop()
    local entry, at = Under(box)
    if not entry then return end
    local order, places = {}, {}
    for place, each in ipairs(lists[box]) do order[place], places[each] = each, place end
    if not places[entry] then return end
    pick = { box = box, order = order, at = places, from = { entry, at }, to = { entry, at } }
    held = true
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", function() ns.Safe("selection", Follow) end)
    end
    driver:Show()
end

-- Let go: the words picked wait for Ctrl+C; none (a press without a drag), nothing is picked. A right click on a
-- message: the game's menu of whoever wrote it, with Social's lines (PlayerMenu.lua; Saneroki, 2026-11-18: "Enable
-- right click on peoples chat messages").
local function Let(box, button)
    if button == "RightButton" then
        local entry = Under(box)
        if entry and ns.PlayerMenu then ns.PlayerMenu.Message(box, entry) end
        return
    end
    if button ~= "LeftButton" or not held then return end
    held = false
    driver:Hide()
    Follow()
    local words = Gather()
    if words == "" then return Drop() end
    Hold(words)
end

-- A list of messages picks words: its box (the game's scrolling list, its rows drawn by Bubble.Init) and its
-- messages on show, in their order. It does not take the mouse until Select.Allow.
function Select.Attach(box, list)
    lists[box] = list
    box:HookScript("OnMouseDown", function(self, button) ns.Safe("selection", Take, self, button) end)
    box:HookScript("OnMouseUp", function(self, button) ns.Safe("selection", Let, self, button) end)
    Select.Allow(box, false)
end

-- The list takes the mouse (on), or lets a click through to the game; then what was picked in it goes.
function Select.Allow(box, on)
    if not box then return end -- (a window whose building failed half way)
    box:EnableMouse(on and true or false)
    if not on and pick and pick.box == box then Drop() end
end

-- What is picked goes (another conversation chosen, the full screen gone).
function Select.Clear()
    if pick or (copy and copy:IsShown()) then Drop() end
end
