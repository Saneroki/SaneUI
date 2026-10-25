local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Talents
--  Our own talents window, a window on Combat's full screen (Board.lua: the
--  part talents), that looks and works as the game's own talents window in
--  this client: the Talents tab of the game's PlayerSpellsFrame
--  (Blizzard_PlayerSpells, Camelot: ClassTalents/Blizzard_ClassTalentsFrame.xml
--  and .lua, over the shared ClassTalents/Blizzard_ClassTalentsFrame.lua), at
--  the game's size, 1212 by 681, scaled to fit its panel (never larger than it
--  is) and centred:
--    - your three talent trees, drawn by the game's shared talent frame
--      (Blizzard_SharedTalentUI's TalentFrameBaseTemplate: the nodes, the
--      arrows between them, their tooltips and clicks, the choice flyout, the
--      staged changes), its nodes in the game's art (Nodes.lua)
--    - the class's background and the game's clouds, light and border round
--      it (Art.lua); each tree's head with the points spent in it, and the
--      unspent points (Headers.lua)
--    - the primary and secondary specialization behind the game's tabs, the
--      active one marked, the other to look at and activate (Specs.lua)
--    - Apply Changes, Undo and the Reset menu at the foot (Foot.lua); the
--      commit's cast shown over the trees on a cast bar of ours, made from the
--      game's template and run by the game's own code (Commit.lua)
--    - the full window's search box finds talents, marked on their nodes as
--      the game's own search marks them
--
--  The game's shared talent frame is the game's, inherited as its class frame
--  inherits it; what the class frame adds is in Blizzard_PlayerSpells, which
--  belongs to the game's window and is never loaded by us: that layer is ours,
--  ported (Tree.lua, Changes.lua and the files above), with the game's sizes,
--  atlases, words and behaviour. Nothing of the game's window is touched, read
--  or written, and nothing of the game's casting bar: our frames are anonymous,
--  the game's tables are only read. Learning and refunding work where the game
--  lets them (out of a fight, on the active specialization), applying where
--  the game says it can (C_ClassTalents.CanChangeTalents).
--
--  Events only while it is shown. If the game has no shared talent frame, the
--  panel says so; before your first talent point it says from which level.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = {}
ns.Talents = Talents

-- The game's sizes (Camelot/Blizzard_PlayerSpellsFrame.xml, ClassTalentsFrameTemplate): the talents frame is 1212 by
-- 681; its background (Talents-Background-c60) is 701 high and stands out 20 over the frame's top, under the game's
-- title bar: the whole art is what is fitted into the panel.
Talents.WIDTH, Talents.HEIGHT = 1212, 681
Talents.HIGH = 701
Talents.WANTS = { 1218, 708 } -- the game's window round it (talentsWidth, talentsHeight): the first layout's share
Talents.LEAST = 0.4           -- the panel at least this share of the art, its head and edges round it
Talents.INSET = 24            -- what the panel says in place of the tree, from its sides

-- Every word it shows: the game's own where it has one.
Talents.TEXT = {
    unspent = Core.Word("UNSPENT_POINTS", "Unspent Points"),
    primary = Core.Word("DUAL_SPEC_PRIMARY", "Primary"),
    secondary = Core.Word("DUAL_SPEC_SECONDARY", "Secondary"),
    locked = Core.Word("TALENT_SPEC_LOCKED", "Locked"),
    active = Core.Word("TALENT_SPEC_ACTIVE", "Active"),
    activate = Core.Word("TALENT_SPEC_ACTIVATE", "Activate"),
    apply = Core.Word("TALENT_FRAME_APPLY_BUTTON_TEXT", "Apply Changes"),
    undo = Core.Word("TALENT_FRAME_DISCARD_CHANGES_BUTTON_TOOLTIP", "Undo pending changes"),
    resetTitle = Core.Word("TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE", "Reset Talents"),
    resetClass = Core.Word("TALENT_FRAME_RESET_BUTTON_DROPDOWN_LEFT", "Reset Class Talents"),
    resetSpec = Core.Word("TALENT_FRAME_RESET_BUTTON_DROPDOWN_RIGHT", "Reset Specialization Talents"),
    resetAll = Core.Word("TALENT_FRAME_RESET_BUTTON_DROPDOWN_ALL", "Reset All Talents"),
    tooFast = Core.Word("TALENT_FRAME_CONFIG_OPERATION_TOO_FAST", "You are changing talents too quickly."),
    refundInvalid = Core.Word("TALENT_FRAME_REFUND_INVALID_ERROR", "Changes would leave talents without what they need."),
    fight = Core.Word("ERR_NOT_IN_COMBAT", "You can't do that while in combat"),
    later = Core.Word("FEATURE_BECOMES_AVAILABLE_AT_LEVEL", "Available at level %d"),
    missing = "This game has no talent frame of its own to draw your talents with.",
}

-- The talent frame's methods: our layer over the game's shared talent frame, each file adding its part (Tree.lua
-- puts them on the frame, each behind the module's guard).
Talents.Class = {}

-- The scripts the game's templates may give a frame of ours; Wrap puts each behind the module's guard.
Talents.SCRIPTS = { "OnClick", "OnEnter", "OnLeave", "OnDragStart", "OnReceiveDrag", "OnMouseDown", "OnMouseUp",
                    "OnShow", "OnHide", "OnEvent", "OnUpdate" }

local panel, holder, note -- the panel, the art fitted into it, what it says in place of the tree
local frame               -- the talent frame (Tree.lua), once built; false: the game has none
local search = ""         -- what the full window's search box holds
local fighting = false    -- a fight is on, from the moment the game says it begins

-- The scripts the game's template gave one of our frames, each behind the module's guard: the game's own code still
-- runs them, but an error there stands the module down and gives the game its window back, as at any door of ours.
function Talents.Wrap(widget, names)
    if not widget then return end
    for _, name in ipairs(names or Talents.SCRIPTS) do
        local fn = widget.GetScript and widget:GetScript(name)
        if fn then widget:SetScript(name, ns.Guard(fn)) end
    end
end

-- The game's yellow glow round a button of the window (its YellowGlow: newplayertutorial-yellowGlow-redbutton-*, 12
-- beyond the button's sides), hidden at first.
Talents.GLOW_BEYOND = 12
function Talents.YellowGlow(button)
    local glow = CreateFrame("Frame", nil, button)
    glow:SetHeight(1)
    glow:SetPoint("LEFT", -Talents.GLOW_BEYOND, 0)
    glow:SetPoint("RIGHT", Talents.GLOW_BEYOND, 0)
    local left = glow:CreateTexture(nil, "ARTWORK")
    left:SetAtlas("newplayertutorial-yellowGlow-redbutton-left", true)
    left:SetBlendMode("ADD")
    left:SetPoint("LEFT")
    local right = glow:CreateTexture(nil, "ARTWORK")
    right:SetAtlas("newplayertutorial-yellowGlow-redbutton-right", true)
    right:SetBlendMode("ADD")
    right:SetPoint("RIGHT")
    local middle = glow:CreateTexture(nil, "ARTWORK")
    middle:SetAtlas("newplayertutorial-yellowGlow-redbutton-middle")
    middle:SetBlendMode("ADD")
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    glow:Hide()
    return glow
end

-- A red button of the game's (UIPanelButtonNoTooltipTemplate with UIButtonTemplate, as the game's window has them):
-- its words, size, a click behind the module's guard (the game's button plays its sound first).
function Talents.Button(parent, text, width, height, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonNoTooltipTemplate, UIButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    if button.SetOnClickHandler then button:SetOnClickHandler(click) end
    Talents.Wrap(button)
    return button
end

-- Whether a fight is on: talents are not changed then.
function Talents.Fight()
    return fighting or InCombatLockdown()
end

-- The frame says a fight began or ended (PLAYER_REGEN_DISABLED comes before the game's lockdown).
function Talents.Fighting(on)
    fighting = on
end

-- The game's level at which talents come (Constants.LevelConstsExposed.MIN_TALENT_LEVEL).
local function TalentLevel()
    local constants = rawget(_G, "Constants")
    local levels = type(constants) == "table" and constants.LevelConstsExposed
    return type(levels) == "table" and levels.MIN_TALENT_LEVEL or 10
end

-- What the panel shows: the tree once you have earned a talent point, else from which level, as the game's talents
-- button says it (PlayerSpellsMicroButtonMixin:UpdateMicroButton).
local function Gate()
    if not frame then return end
    local specs = rawget(_G, "C_SpecializationInfo")
    local earned = true
    if specs and specs.HasPlayerEarnedATalentPoint then earned = Core.Ask(specs.HasPlayerEarnedATalentPoint) ~= false end
    if earned then
        note:Hide()
    else
        note:SetText(Talents.TEXT.later:format(TalentLevel()))
        note:Show()
    end
    frame:SetShown(earned)
end

local function Leveled()
    ns.Safe("talents", Gate)
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- Made with its panel: the game's shared talent frame loaded (it is the game's, and loads by itself with the game's
-- own talents; loading it here changes nothing of the game's window), our frame made from it.
function Talents.Build(made)
    panel = made
    note = panel.body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    note:SetPoint("LEFT", Talents.INSET, 0)
    note:SetPoint("RIGHT", -Talents.INSET, 0)
    note:SetWordWrap(true)
    note:Hide()
    holder = CreateFrame("Frame", nil, panel.body)
    holder:SetSize(Talents.WIDTH, Talents.HIGH)
    holder:SetPoint("CENTER")
    Talents.holder = holder

    local addons = rawget(_G, "C_AddOns")
    if addons and addons.LoadAddOn then pcall(addons.LoadAddOn, "Blizzard_SharedTalentUI") end
    frame = ns.TalentsTree.Make(holder) or false
    Talents.frame = frame or nil
    if not frame then
        note:SetText(Talents.TEXT.missing)
        note:Show()
        return
    end
    Gate()
    if search ~= "" then ns.TalentsTree.Search(frame, search) end
end

function Talents.Show(on)
    if on then
        Core.On("PLAYER_LEVEL_UP", Leveled)
        fighting = InCombatLockdown() or Core.Ask(rawget(_G, "UnitAffectingCombat"), "player") == true
        Gate()
    else
        Core.Off("PLAYER_LEVEL_UP", Leveled)
    end
end

-- The panel placed that large: the art as large as fits in its body, never larger than the game's.
function Talents.Size(width, height)
    if not holder then return end
    local edge = Core.Board.EDGE
    local bodyWidth, bodyHeight = width - 2 * edge, height - Core.Board.HEAD - 2 * edge
    holder:SetScale(math.max(0.1, math.min(1, bodyWidth / Talents.WIDTH, bodyHeight / Talents.HIGH)))
end

-- What the full window's search box holds: the talents it names marked on the tree.
function Talents.Search(text)
    search = text or ""
    if frame then ns.TalentsTree.Search(frame, search) end
end

-- Whether it is there: in the game whose talents it is made after (two specializations, each with its config:
-- Combat.lua, ns.Serves); in Retail the game's own talents stay, and its talents key opens them.
function Talents.Present()
    return ns.Serves("talents")
end

-- The module stands down: the commit's bar stopped, the frame's events gone.
function Talents.Leave()
    Talents.Show(false)
    if frame then ns.TalentsTree.Leave(frame) end
end

-- The panel at least this large: its share of the art, with the panel's head and edges round it.
local edge, head = Core.Board.EDGE, Core.Board.HEAD
ns.Board.Part("talents", ns.TEXT.talents,
    { math.floor(Talents.WIDTH * Talents.LEAST) + 2 * edge, math.floor(Talents.HIGH * Talents.LEAST) + head + 2 * edge },
    Talents, Talents.WANTS)
