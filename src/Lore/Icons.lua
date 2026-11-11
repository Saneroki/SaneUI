local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Icons
--  An NPC's services as big pictures without words, in a row over the talk
--  (Saneroki, 2026-11-11: big icons with no text on them, "over the
--  conversation window so you can quickly click them"): the hearthstone (an
--  inn made your home), a vendor's goods, a trainer, a flight master, the
--  bank, the auction house, a battlemaster, transmogrification; and at the
--  row's end leaving (Saneroki, 2026-11-11: "the goodbye should also be a top
--  icon"): Goodbye, or Decline on a quest offered, as the game's open hand. Each
--  on a plate of its own (Look.Plate), a little lighter under the mouse. A click
--  gives that answer (Talk.Answer); the mouse on one shows its words in the
--  tooltip, and why the game refuses it where it does (its picture greyed then).
--  The answers' column keeps the rest: quests, words to say, an option the
--  game marks as a quest's, and what has no large picture in the game (a
--  tabard, a guild charter, a trainer's unlearning, the spirit healer).
--  A kind is known by the game's own icon of it (option.icon) and drawn as the
--  game's own large picture of it: the cursor the game shows over such an NPC
--  (its 128 piece; the cursor's tip in that piece's top left corner cut away by
--  the game's diamond mask, laid so that its edge runs between the tip and the
--  picture), the bank and the auction house, which have no cursor, by their
--  map icons. Off (the setting Services as icons) they stand in the column.
--  The hand has no tip: nothing of it is cut.
--
--      Icons.Picture(option)   the large picture of a gossip option's kind, nil for none
--      Icons.GOODBYE           the picture of leaving (an answer marked goodbye)
--      Icons.Shown(answer)     whether that answer stands in the row (else in the column)
--      Icons.Draw(talk)        the row over the box: the talk's answers with a picture
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Icons = {}
ns.Icons = Icons

Icons.SIZE = 48   -- a picture's side
Icons.INSET = 5   -- between a picture and its plate's edge
Icons.SPACE = 8   -- between two plates
Icons.GAP = 10    -- between the row and the box under it, as between the other parts
Icons.LIT = 0.35  -- the picture laid over itself, added, under the mouse

local CURSOR = "Interface\\CURSOR\\"
-- A cursor's 128 piece, top left in its 512 x 256 sheet (the same in both games).
local PIECE = { 1 / 512, 129 / 512, 1 / 256, 129 / 256 }
-- The diamond, twice the piece's side, its middle on the piece's diagonal so far in (a share of the side): its edge
-- crosses the piece where x + y is 0.44 of the side, past the tip (up to 0.4), short of the hearthstone, the bag,
-- the book and the boot (0.47 on), through a few pixels of the shields' and the helmet's edges.
local DIAMOND = "Interface\\COMMON\\common-mask-diamond"
local MIDDLE = 92 / 128

-- The game's icons of an option's kind (Interface\GossipFrame), and the large picture of each.
local PICTURES = {
    [132052] = { file = CURSOR .. "UIInnkeeperCursor2x", tip = true },     -- BinderGossipIcon: the hearthstone
    [4955461] = { file = CURSOR .. "UIInnkeeperCursor2x", tip = true },    -- InnkeeperGossipIcon
    [132060] = { file = CURSOR .. "UIBuyCursor2x", tip = true },           -- VendorGossipIcon
    [132058] = { file = CURSOR .. "UITrainerCursor2x", tip = true },       -- TrainerGossipIcon
    [132057] = { file = CURSOR .. "UITaxiCursor2x", tip = true },          -- TaxiGossipIcon
    [132051] = { file = CURSOR .. "UICursorPVP2x", tip = true },           -- BattleMasterGossipIcon
    [1673939] = { file = CURSOR .. "UITransmogrifyCursor2x", tip = true }, -- transmogrifyGossipIcon
    [132050] = { atlas = "banker" },                           -- BankerGossipIcon: the map's
    [528409] = { atlas = "auctioneer" },                       -- the auction house's: the map's
}

-- Leaving: the game's open hand (its cursor's 128 piece, in the same place as the others', with no tip).
Icons.GOODBYE = { file = CURSOR .. "UIOpenhandCursor2x" }

local row
local buttons = {}

function Icons.Picture(option)
    if type(option) ~= "table" then return nil end
    return PICTURES[Core.Plain(option.icon)] or PICTURES[Core.Plain(option.overrideIconID)]
end

-- An answer's picture: a service's, or the hand for leaving.
local function Picture(answer)
    return answer.picture or (answer.goodbye and Icons.GOODBYE) or nil
end

function Icons.Shown(answer)
    return ns.options.icons ~= false and Picture(answer) ~= nil
end

-------------------------------------------------------------------------------
--  One picture
-------------------------------------------------------------------------------
local function Tip(button)
    local answer = button.answer
    if not answer then return end
    button.plate:SetLit(true)
    ns.Quiet.Tips(true)
    Core.ShowTip(button, answer.text ~= "" and answer.text or nil, nil, "ANCHOR_TOP")
    if answer.failure and answer.failure ~= "" and GameTooltip:IsOwned(button) then
        local red = rawget(_G, "RED_FONT_COLOR")
        if red and red.GetRGB then
            GameTooltip:AddLine(answer.failure, red:GetRGB())
        else
            GameTooltip:AddLine(answer.failure, 1, 0.13, 0.13)
        end
        GameTooltip:Show()
    end
end

local function Untip(button)
    button.plate:SetLit(false)
    Core.HideTip()
    ns.Quiet.Tips(false)
end

local function Make(index)
    local button = CreateFrame("Button", nil, row)
    button:SetSize(Icons.SIZE + Icons.INSET * 2, Icons.SIZE + Icons.INSET * 2)
    button.plate = ns.Look.Plate(button, ns.Look.BAR)
    button.picture = button:CreateTexture(nil, "ARTWORK")
    button.lit = button:CreateTexture(nil, "HIGHLIGHT")
    button.lit:SetBlendMode("ADD")
    button.lit:SetAlpha(Icons.LIT)
    button.mask = button:CreateMaskTexture()
    button.mask:SetTexture(DIAMOND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    button.mask:SetSize(Icons.SIZE * 2, Icons.SIZE * 2)
    for _, texture in ipairs({ button.picture, button.lit }) do
        texture:SetSize(Icons.SIZE, Icons.SIZE)
        texture:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    button.mask:SetPoint("TOPLEFT", button.picture, "TOPLEFT", (MIDDLE - 1) * Icons.SIZE, (1 - MIDDLE) * Icons.SIZE)
    button.masked = false -- whether the diamond is on its textures
    button:SetScript("OnClick", ns.Guard(function(self) ns.Talk.Answer(self.answer) end))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", ns.Guard(Untip))
    buttons[index] = button
    return button
end

-- The answer's picture on both layers; the diamond on a cursor's piece with a tip only. Greyed where the game
-- refuses it.
local function Paint(button, answer)
    local picture = Picture(answer)
    local masked = picture.tip == true
    for _, texture in ipairs({ button.picture, button.lit }) do
        if picture.file then
            texture:SetTexture(picture.file)
            texture:SetTexCoord(unpack(PIECE))
        else
            texture:SetAtlas(picture.atlas)
        end
        if masked ~= button.masked then
            if masked then texture:AddMaskTexture(button.mask) else texture:RemoveMaskTexture(button.mask) end
        end
    end
    button.masked = masked
    button.picture:SetDesaturated(answer.locked == true)
    button.picture:SetAlpha(answer.locked and 0.6 or 1)
end

-------------------------------------------------------------------------------
--  The row
-------------------------------------------------------------------------------
function Icons.Draw(talk)
    local shown = {}
    for _, answer in ipairs(talk.answers or {}) do
        if Icons.Shown(answer) then shown[#shown + 1] = answer end
    end
    if #shown == 0 then
        if row then row:Hide() end
        return
    end
    if not row then row = CreateFrame("Frame", nil, ns.Look.Root()) end
    local side = Icons.SIZE + Icons.INSET * 2
    row:ClearAllPoints()
    row:SetPoint("BOTTOM", ns.Box.Frame(), "TOP", 0, Icons.GAP)
    row:SetSize(#shown * side + (#shown - 1) * Icons.SPACE, side)
    for index, answer in ipairs(shown) do
        local button = buttons[index] or Make(index)
        button.answer = answer
        Paint(button, answer)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * (side + Icons.SPACE), 0)
        button.plate:SetLit(false)
        button:Show()
    end
    for index = #shown + 1, #buttons do
        buttons[index].answer = nil
        buttons[index]:Hide()
    end
    row:Show()
end
