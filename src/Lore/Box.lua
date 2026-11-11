local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Box
--  The NPC's face, name and words, low in the middle of the screen (Saneroki,
--  2026-10-28), see-through over the world: at the left the NPC's own 3D face
--  (the game's model of the unit you talk to, with no background; a thing with
--  no face, a board or a book, shows the game's quest book), talking while a
--  paragraph is new; beside it the name in the game's gold, the paragraph under
--  it in white, and at the bottom right which paragraph of how many. A soft
--  shade lies behind the whole. Clicks are the talk's (Talk.Click). The quest
--  under the words (Quest.lua) lifts the box: the two stand on one column whose
--  foot stays put.
--
--      Box.Frame()        the box (the answers stand beside it)
--      Box.Draw(talk)     the talk's name and paragraph at hand
--      Box.Words(talk)    only the paragraph (the next one came)
--      Box.Place(quest)   on the column, over the quest's frame when one is shown
--      Box.Top()          how high the box's top stands over the screen's bottom, in the talk's units
--      Box.Shift(x)       the column moved so far from the screen's middle (left: negative), for the answers' room
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Box = {}
ns.Box = Box

Box.WIDTH = 620  -- the box's width (the quest under it as wide)
Box.FACE = 128   -- the face, square
Box.PAD = 14     -- inside the shade
Box.FOOT = 168   -- the column's foot over the screen's bottom
Box.ZOOM = 0.95  -- the face's camera, as close as the game's portraits go (1)
Box.TALKING = 60 -- the game's animation of a unit talking (its EmoteTalk)
Box.BOOK = "Interface\\QuestFrame\\UI-QuestLog-BookIcon" -- the game's own picture for a talk with no face

Box.GAP = 10     -- between the box and the quest under it

local frame, face, book, name, words, count, shade
local placed    -- the quest's frame the box stands on, nil for none
local shift = 0 -- the column's distance from the screen's middle (Answers.Place)

local function Build()
    local root = ns.Look.Root()
    frame = CreateFrame("Button", nil, root)
    frame:SetWidth(Box.WIDTH)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnClick", ns.Guard(function(_, button) ns.Talk.Click(button) end))
    shade = ns.Look.Shade(frame)

    face = CreateFrame("PlayerModel", nil, frame)
    face:SetSize(Box.FACE, Box.FACE)
    face:SetPoint("TOPLEFT", frame, "TOPLEFT", Box.PAD, -Box.PAD)
    book = frame:CreateTexture(nil, "ARTWORK")
    book:SetSize(Box.FACE * 0.6, Box.FACE * 0.6)
    book:SetPoint("CENTER", face, "CENTER")
    book:SetTexture(Box.BOOK)
    book:Hide()

    local left = Box.PAD * 2 + Box.FACE
    local width = Box.WIDTH - left - Box.PAD
    name = ns.Look.Text(frame, "name")
    name:SetPoint("TOPLEFT", frame, "TOPLEFT", left, -Box.PAD)
    name:SetWidth(width)
    name:SetWordWrap(false)
    local gold = rawget(_G, "NORMAL_FONT_COLOR")
    if gold and gold.GetRGB then name:SetTextColor(gold:GetRGB()) else name:SetTextColor(1, 0.82, 0) end
    words = ns.Look.Text(frame, "words")
    words:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -8)
    words:SetWidth(width)
    words:SetSpacing(3)
    count = ns.Look.Text(frame, "count")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -Box.PAD, Box.PAD * 0.6)
    count:SetJustifyH("RIGHT")
    count:SetTextColor(unpack(ns.Look.GREY))
end

function Box.Frame()
    if not frame then Build() end
    return frame
end

-- An action in <...> is what the NPC does, not says: in the game's colour for it.
local function Emotes(text)
    local info = rawget(_G, "ChatTypeInfo")
    local emote = info and info.MONSTER_EMOTE
    if type(emote) ~= "table" or not emote.r then return text end
    local colour = ("|cff%02x%02x%02x"):format(emote.r * 255, emote.g * 255, emote.b * 255)
    return (text:gsub("(<[^>]+>)", colour .. "%1|r"))
end

-- The face of the unit talked to: its model, else the quest book.
local function Face(talk)
    local unit = talk.unit
    if unit and UnitExists(unit) then
        book:Hide()
        face:Show()
        face:ClearModel()
        face:SetUnit(unit)
        face:SetPortraitZoom(Box.ZOOM)
    else
        face:Hide()
        book:Show()
    end
end

function Box.Words(talk)
    Box.Frame()
    local paragraph = talk.paragraphs[talk.at] or ""
    words:SetText(Emotes(paragraph))
    local total = #talk.paragraphs
    count:SetText(total > 1 and ("%d/%d"):format(talk.at, total) or "")
    -- The face talks while the paragraph is new, unless it is all an action.
    if face:IsShown() then
        local said = paragraph:gsub("<[^>]+>", "")
        if said:find("%S") then
            Box.said = (Box.said or 0) + 1
            local this = Box.said
            face:SetAnimation(Box.TALKING)
            -- Back to rest once it is said (about as long as it takes to say it), unless another came.
            C_Timer.After(math.max(1.5, #said / 28), ns.Guard(function()
                if this == Box.said and face:IsShown() then face:SetAnimation(0) end
            end))
        end
    end
    local height = (Core.Plain(name:GetStringHeight()) or 0) + 8 + (Core.Plain(words:GetStringHeight()) or 0) + 20
    frame:SetHeight(math.max(Box.FACE, height) + Box.PAD * 2)
end

-- On the column: its foot over the screen's bottom, the box on the quest when one is shown under it.
function Box.Place(quest)
    Box.Frame()
    placed = quest
    frame:ClearAllPoints()
    if quest then
        quest:ClearAllPoints()
        quest:SetPoint("BOTTOM", UIParent, "BOTTOM", shift, Box.FOOT)
        frame:SetPoint("BOTTOM", quest, "TOP", 0, Box.GAP)
    else
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", shift, Box.FOOT)
    end
end

function Box.Shift(x)
    if x == shift then return end
    shift = x
    Box.Place(placed)
end

function Box.Top()
    Box.Frame()
    local top = Box.FOOT + (Core.Plain(frame:GetHeight()) or 0)
    if placed then top = top + (Core.Plain(placed:GetHeight()) or 0) + Box.GAP end
    return top
end

function Box.Draw(talk)
    Box.Frame()
    name:SetText(talk.name or "")
    Face(talk)
    shade:SetStrength(1)
    Box.Words(talk)
    frame:Show()
end
