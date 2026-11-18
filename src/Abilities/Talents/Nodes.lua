local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Talents - Nodes
--  The nodes of our talent trees, as the game's class talents draw them
--  (Blizzard_PlayerSpells: ClassTalents/Blizzard_ClassTalentUtil.lua, which
--  chooses each node's template and behaviour; Camelot's ClassTalentUtil.lua,
--  its sounds; ClassTalents/Blizzard_ClassTalentButtonTemplates.xml and .lua,
--  the class layer over the game's shared node buttons):
--    - each node is the game's shared button (Blizzard_SharedTalentUI: a
--      square, a circle, a choice of two, a capstone; TalentButtonArtTemplate
--      with its art sets) with the game's shared behaviour: a left click buys a
--      rank, a right click refunds one (with shift: and the nodes that hang on
--      it), a choice opens its flyout (Blizzard_TalentButtonSpend.lua,
--      Blizzard_TalentButtonSelect.lua, Blizzard_SharedTalentSelectionTemplates)
--    - the class layer ported: the green glow that pulses on a node you can
--      buy (SelectableGlow), the class talents' tooltip, the game's sounds for
--      buying and refunding by the node's kind
--    - the arrows between them, the game's (TalentEdgeArrowTemplate)
--  Left out of the class layer: the sheen that sweeps over the nodes now and
--  then, and what concerns the action bars (the mark of a talent missing from
--  them, lighting their buttons under the mouse): that code writes the game's
--  marks on its action bars, which only the game's own window may do.
--
--  Every script of a node, the game's and ours, stands behind the module's
--  guard: the game's mixins are copied for our nodes with their scripts guarded,
--  once, as the game's pools give them to the nodes they make.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Nodes = {}
ns.TalentsNodes = Nodes

-- The class talents' glow on a node you can buy (ClassTalentBaseButtonTemplate's SelectableGlow): its size, the
-- seconds it takes up and as many down again, how bright it gets (SelectableGlowMaxAlpha; a capstone's).
Nodes.GLOW_SIZE = 61
Nodes.GLOW_TIME = 1
Nodes.GLOW_MOST, Nodes.GLOW_CAPSTONE = 0.15, 0.7

local glows = {} -- [node] = { texture, pulse, most }: the glow of a node we made
local made       -- the game's mixins as our nodes take them, made once the game's talent frame is loaded

local function Game(name)
    return rawget(_G, name)
end

-- Whether a node's flags hold one flag of the game's (Enum.TraitNodeFlag: each a power of two).
local function Has(flags, flag)
    if type(flags) ~= "number" or type(flag) ~= "number" or flag <= 0 then return false end
    return math.floor(flags / flag) % 2 == 1
end

local function Kinds()
    local enum = Game("Enum") or {}
    return enum.TraitNodeEntryType or {}, enum.TraitNodeType or {}, enum.TraitNodeFlag or {}
end

-- The game's sound for buying a rank of a node of that kind: the class talents' (ClassTalentUtil), with this
-- client's change (a square plays the plain one, not the major one).
local function Sound(kind)
    local sounds = Game("SOUNDKIT") or {}
    local entry = Kinds()
    if kind == entry.SpendSquare or kind == entry.SpendCircle or kind == entry.SpendCapstoneCircle then
        return sounds.UI_CLASS_TALENT_NODE_SPEND
    elseif kind == entry.SpendCapstoneSquare then
        return sounds.UI_CLASS_TALENT_NODE_SPEND_MAJOR
    end
    return sounds.UI_CLASS_TALENT_NODE_SPEND
end

-------------------------------------------------------------------------------
--  The glow on a node you can buy
-------------------------------------------------------------------------------
local function MakeGlow(node, most)
    local texture = node:CreateTexture(nil, "OVERLAY")
    texture:SetBlendMode("ADD")
    texture:SetSize(Nodes.GLOW_SIZE, Nodes.GLOW_SIZE)
    texture:SetPoint("CENTER")
    if type(node.artSet) == "table" and node.artSet.glow then texture:SetAtlas(node.artSet.glow, false) end
    texture:Hide()
    local pulse = texture:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")
    pulse:SetToFinalAlpha(true)
    local up = pulse:CreateAnimation("Alpha")
    up:SetFromAlpha(0)
    up:SetToAlpha(most)
    up:SetDuration(Nodes.GLOW_TIME)
    up:SetOrder(1)
    up:SetSmoothing("OUT")
    local down = pulse:CreateAnimation("Alpha")
    down:SetFromAlpha(most)
    down:SetToAlpha(0)
    down:SetDuration(Nodes.GLOW_TIME)
    down:SetOrder(2)
    down:SetSmoothing("IN")
    glows[node] = { texture = texture, pulse = pulse }
end

-- The glow pulses while the node can be bought, unless the game's own glow is on it (ClassTalentButtonBaseMixin).
local function UpdateGlow(node)
    local glow = glows[node]
    if not glow then return end
    local util = Game("TalentButtonUtil")
    local selectable = util and util.BaseVisualState and util.BaseVisualState.Selectable
    local play = not (node.Glow and node.shouldGlow) and node.visualState ~= nil and node.visualState == selectable
    if play and node.capstone then play = Core.Ask(Game("GetCVarBool"), "seenPurchasableClassCapstone") ~= true end
    if play then
        glow.texture:Show()
        if not glow.pulse:IsPlaying() then glow.pulse:Play() end
    else
        glow.pulse:Stop()
        glow.texture:Hide()
    end
end

-- What every node of ours gets when the game's pool makes it: the glow, the class talents' tooltip, the sounds.
local function Dress(node, most, capstone)
    node.capstone = capstone
    MakeGlow(node, most)
    local style = Game("GAME_TOOLTIP_BACKDROP_STYLE_CLASS_TALENT")
    node.tooltipBackdropStyle = style
    if node.SearchIcon then node.SearchIcon.tooltipBackdropStyle = style end
    local sounds = Game("SOUNDKIT") or {}
    node.selectSound, node.deselectSound = sounds.UI_CLASS_TALENT_NODE_SPEND, sounds.UI_CLASS_TALENT_NODE_REFUND
end

-------------------------------------------------------------------------------
--  The game's mixins, for our nodes
-------------------------------------------------------------------------------
-- A copy of a mixin of the game's with ours over it; each script in it (and the one every node has from the game's
-- display template where the mixin has none) behind the module's guard. Ours are guarded already.
local function Guarded(mixin, ours)
    local copy, display = {}, Game("TalentDisplayMixin") or {}
    for key, value in pairs(mixin) do copy[key] = value end
    for _, name in ipairs(Talents.SCRIPTS) do
        local fn = copy[name] or display[name]
        if fn and not ours[name] then copy[name] = ns.Guard(fn) end
    end
    for key, value in pairs(ours) do copy[key] = value end
    return copy
end

-- The class layer over a node's mixin (ClassTalentButtonSpendMixin and its kin): base is the game's mixin.
local function Layer(base, most, choosing, capstone)
    local art = Game("TalentButtonArtMixin") or {}
    local ours = {}
    ours.OnLoad = ns.Guard(function(node)
        if base.OnLoad then base.OnLoad(node) end
        Dress(node, most, capstone)
        if choosing == "split" then node.selectSound = (Game("SOUNDKIT") or {}).UI_CLASS_TALENT_NODE_SPEND_MAJOR end
    end)
    if choosing ~= "split" and base.UpdateEntryInfo then
        ours.UpdateEntryInfo = ns.Guard(function(node, skipUpdate)
            base.UpdateEntryInfo(node, skipUpdate)
            node.selectSound = Sound(node.entryInfo and node.entryInfo.type)
        end)
    end
    ours.UpdateStateBorder = ns.Guard(function(node, visualState)
        if art.UpdateStateBorder then art.UpdateStateBorder(node, visualState) end
        UpdateGlow(node)
    end)
    ours.UpdateGlow = ns.Guard(function(node)
        if art.UpdateGlow then art.UpdateGlow(node) end
        UpdateGlow(node)
        -- No glow of the game's while the node's choices are open.
        if choosing and node.Glow and node.shouldGlow and node:GetTalentFrame():AreSelectionsOpen(node) then
            node.Glow:SetShown(false)
        end
    end)
    if choosing then
        ours.ShowSelections = ns.Guard(function(node)
            base.ShowSelections(node)
            node:UpdateGlow()
        end)
        ours.ClearSelections = ns.Guard(function(node)
            base.ClearSelections(node)
            node:UpdateGlow()
        end)
    end
    return Guarded(base, ours)
end

-- A choice in a node's flyout (ClassTalentSelectionChoiceMixin): the class talents' tooltip, the search's mark.
local function Choice(base)
    local art = Game("TalentButtonArtMixin") or {}
    local display = Game("TalentDisplayMixin") or {}
    local ours = {}
    local Shown = ns.Guard(function(choice) choice:UpdateSpendText() end)
    ours.OnLoad = ns.Guard(function(choice)
        if art.OnLoad then art.OnLoad(choice) end
        local style = Game("GAME_TOOLTIP_BACKDROP_STYLE_CLASS_TALENT")
        choice.tooltipBackdropStyle = style
        if choice.SearchIcon then choice.SearchIcon.tooltipBackdropStyle = style end
    end)
    -- As the game's (TalentSelectionChoiceMixin:Init), its OnShow ours, made once.
    ours.Init = ns.Guard(function(choice, talentFrame)
        if display.Init then display.Init(choice, talentFrame) end
        choice:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        choice:RegisterForDrag("LeftButton")
        choice:SetScript("OnShow", Shown)
    end)
    ours.SetSelectionInfo = ns.Guard(function(choice, entryInfo, canSelectChoice, isCurrentSelection, selectionIndex)
        base.SetSelectionInfo(choice, entryInfo, canSelectChoice, isCurrentSelection, selectionIndex)
        local nodeInfo = choice.GetNodeInfo and choice:GetNodeInfo()
        local talentFrame = choice:GetTalentFrame()
        local match = nodeInfo and talentFrame.GetSearchMatchTypeForEntry
            and talentFrame:GetSearchMatchTypeForEntry(nodeInfo.ID, choice:GetEntryID()) or nil
        choice:SetSearchMatchType(match)
    end)
    return Guarded(base, ours)
end

-- The game's mixins as our nodes take them, made once (the game's talent frame is loaded by then).
local function Made()
    if made then return made end
    made = {
        spend = Layer(Game("TalentButtonSpendMixin") or {}, Nodes.GLOW_MOST),
        select = Layer(Game("TalentButtonSelectMixin") or {}, Nodes.GLOW_MOST, "select"),
        split = Layer(Game("TalentButtonSplitSelectMixin") or {}, Nodes.GLOW_MOST, "split"),
        choice = Choice(Game("TalentSelectionChoiceArtMixin") or {}),
    }
    local capstone = Game("TalentButtonCapstoneWithTrackMixin")
    local pip = Game("TalentButtonCapstonePipMixin")
    if capstone then
        made.capstone = Layer(capstone, Nodes.GLOW_CAPSTONE, nil, true)
        if pip then
            made.pip = Layer(pip, Nodes.GLOW_MOST)
            made.capstone.GetCapstonePipMixin = ns.Guard(function() return made.pip end)
        end
    end
    return made
end

-------------------------------------------------------------------------------
--  What the game's talent frame asks (its keys getTemplateType, getSpecializedMixin, getSpecializedChoiceMixin,
--  getEdgeTemplateType), as ClassTalentUtil answers, with the game's shared templates in place of the class
--  frame's own (which are the class frame's, in the game's window)
-------------------------------------------------------------------------------
function Nodes.Template(nodeInfo, kind, large)
    local entry, node, flag = Kinds()
    if nodeInfo and nodeInfo.type == node.Selection and Has(nodeInfo.flags, flag.ShowMultipleIcons) then
        return "TalentButtonChoiceTemplate"
    end
    if nodeInfo and nodeInfo.type == node.Tiered and Has(nodeInfo.flags, flag.ShowTierTrack) then
        if kind == entry.SpendCapstoneCircle then return "TalentButtonCapstoneWithTrackCircleTemplate" end
        if kind == entry.SpendCapstoneSquare then return "TalentButtonCapstoneWithTrackSquareTemplate" end
    end
    local capstone = kind ~= nil and (kind == entry.SpendCapstoneCircle or kind == entry.SpendCapstoneSquare)
    if not nodeInfo and capstone then return "TalentButtonCapstonePipCircleTemplate" end
    if large then
        if kind == entry.SpendSquare then return "TalentButtonLargeSquareTemplate" end
        return "TalentButtonLargeCircleTemplate"
    end
    if kind ~= nil then
        if kind == entry.SpendSquare then return "TalentButtonSquareTemplate" end
        if kind == entry.SpendCapstoneCircle then return "TalentButtonCapstoneCircleTemplate" end
        if kind == entry.SpendCapstoneSquare then return "TalentButtonCapstoneSquareTemplate" end
    end
    return "TalentButtonCircleTemplate"
end

function Nodes.Mixin(nodeInfo, kind)
    local entry, node, flag = Kinds()
    local mixins = Made()
    if nodeInfo and nodeInfo.type == node.Selection then
        return Has(nodeInfo.flags, flag.ShowMultipleIcons) and mixins.split or mixins.select
    end
    if nodeInfo and nodeInfo.type == node.Tiered and Has(nodeInfo.flags, flag.ShowTierTrack) and mixins.capstone
        and kind ~= nil and (kind == entry.SpendCapstoneCircle or kind == entry.SpendCapstoneSquare) then
        return mixins.capstone
    end
    return mixins.spend
end

function Nodes.Choice()
    return Made().choice
end

-- The arrows between nodes: the game's (ClassTalentEdgeArrowTemplate is it, with what only hero talents need).
function Nodes.Edge(style)
    local enum = Game("Enum") or {}
    local styles = enum.TraitEdgeVisualStyle or {}
    if style ~= nil and style == styles.Straight then return "TalentEdgeArrowTemplate" end
    return nil
end
