local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Skills
--  The sheet's skills tab, as the game's sheet has it (Camelot's SkillsFrame),
--  ours: over the left pane your skill lines (C_SkillInfo) in the game's looks
--  (Rows.lua): a header (a click folds or unfolds it), a sub-header with its
--  fold button, a skill with the game's blue bar and its rank in numbers (the
--  green bonus beside it), the skills under a sub-header set in as the game
--  sets them. The class's own skills are left out, as the game leaves them out.
--  A click chooses a skill; at the right (Side.lua) its name, its rank bar, its
--  description and, for a weapon skill, what that skill means against a foe of
--  your level and against a raid boss, worked out as the game works it out.
--
--  The game's own skill rows are wired to the game's sheet (its event registry,
--  its side pane): ours are our own, on the same API and art. The choice is the
--  game's own (C_SkillInfo.SetSelectedSkill).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Skills = {}
ns.Skills = Skills

-- The game's numbers (SkillsFrame.lua): ranks per level, a raid boss's level and how much higher than yours a boss
-- counts, the skill line category the game leaves out (the class's), defense, how far skills under a sub-header are
-- set in, the descriptions' heights.
Skills.RANKS_PER_LEVEL = 5
Skills.BOSS_LEVEL = 63
Skills.HIDDEN = { [7] = true } -- class skills
Skills.DEFENSE = 95
Skills.INDENT_CHILD, Skills.INDENT = 46, 2
Skills.DESCRIPTION, Skills.WEAPON_DESCRIPTION = 120, 40
-- The weapon skill lines, ranged or not (SkillsFrame.lua's WEAPON_SKILL_LINES: the game's skill line IDs).
Skills.WEAPONS = {
    [43] = false, [44] = false, [45] = true, [46] = true, [54] = false, [55] = false, [136] = false, [160] = false,
    [172] = false, [173] = false, [176] = true, [226] = true, [228] = true, [229] = false, [162] = false, [3014] = false,
}

local list, side

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Info()
    return rawget(_G, "C_SkillInfo") or {}
end

local function Selected()
    return Core.Ask(Info().GetSelectedSkill) or 0
end

-- Whether the game lists a skill line (it leaves out the class's own skills).
local function Listed(skill)
    if skill.isHeader then return not Skills.HIDDEN[skill.skillID] end
    return not Skills.HIDDEN[skill.skillLineCategoryID]
end

local function Kind(skill)
    if not skill.isHeader then return "entry" end
    if skill.isChild then return "subheader" end
    return "header"
end

-- How far a row is set in, as the game sets it in (its view's indent).
local function Indent(skill)
    if skill.isHeader and not skill.isChild then return 0 end
    if not skill.isHeader and skill.isChild then return Skills.INDENT_CHILD end
    return Skills.INDENT
end

-------------------------------------------------------------------------------
--  A skill's rank, as the game's bar shows it
-------------------------------------------------------------------------------
-- The game's blue bar for a skill: its rank's share of the most it can have, the rank in numbers on it (the bonus
-- in green beside it).
local function Bar(bar, skill)
    local mixin = rawget(_G, "ColoredProgressBarMixin")
    if mixin and mixin.ColorType and bar.SetFillTextureByColorType then bar:SetFillTextureByColorType(mixin.ColorType.Blue) end
    if bar.Fill then bar.Fill:SetVertexColor(1, 1, 1) end
    local rank, most, bonus = skill.rank or 0, skill.maxRank or 0, skill.modifier or 0
    bar:SetFillPercent(most ~= 0 and math.max(0, math.min(1, rank / most)) or 0)
    if bonus == 0 then
        bar:SetText(rank .. " / " .. most)
    else
        bar:SetText(rank .. " |cnPURE_GREEN_COLOR:(+" .. bonus .. ")|r / " .. most)
    end
end

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local function Light(row)
    local skill = row.data
    if not skill or Kind(skill) == "header" then return end
    local chosen, over = Selected() == skill.skillIndex, row:IsMouseOver()
    ns.Rows.Light(row, (chosen and 0.20) or (over and 0.10) or 0)
end

local function Fold(row)
    local skill = row.data
    if not skill then return end
    if skill.isCollapsed then
        Core.Ask(Info().ExpandSkillHeader, skill.skillIndex)
    else
        Core.Ask(Info().CollapseSkillHeader, skill.skillIndex)
    end
end

-- A click on a skill chooses it; on a sub-header it folds it, as the game's does.
local function Choose(row)
    local skill = row.data
    if not skill then return end
    if Kind(skill) == "subheader" then return Fold(row) end
    Core.Ask(Info().SetSelectedSkill, skill.skillIndex or 0)
    ns.List.Redraw(list)
    Skills.Detail()
end

local OWNER = { click = Choose, fold = Fold, enter = Light, leave = Light }

local function Draw(row, skill)
    row.data = skill
    local kind = Kind(skill)
    ns.Rows.Draw(row, kind, skill.name, skill.isCollapsed, OWNER, Indent(skill))
    if kind == "header" then return end
    Bar(row.bar, skill)
    Light(row)
end

local function Extent(skill)
    return ns.Rows.Height(Kind(skill))
end

-------------------------------------------------------------------------------
--  The chosen skill, at the right
-------------------------------------------------------------------------------
local function Signed(value)
    if value == 0 then value = 0 end -- no "-0.00%"
    local text = ("%.2f%%"):format(value)
    if value > 0 then text = "+" .. text end
    return text
end

-- What a weapon skill means, as the game works it out: against a foe of your level, and against a raid boss (the
-- chance to hit and to strike critically, from the skill against the defense the foe's level gives; melee also the
-- glancing blows).
local function Weapon(skill, ranged)
    local level = Core.Plain(UnitLevel("player")) or 1
    local skillNow = (skill.rank or 0) + (skill.modifier or 0)
    local function Chance(offset)
        return ((level + offset) * Skills.RANKS_PER_LEVEL - skillNow) * -0.04
    end
    local same = Signed(Chance(0))
    ns.Side.Spacer(side, 6)
    ns.Side.Category(side, Core.Word("WEAPON_SKILL_DETAIL_SAME_LEVEL_HEADER", "Same Level"))
    local sameText = Core.Word(ranged and "WEAPON_SKILL_DETAIL_SAME_LEVEL_RANGED" or "WEAPON_SKILL_DETAIL_SAME_LEVEL",
        "Hit: %s  Crit: %s")
    ns.Side.Line(side, sameText:format(same, same), rawget(_G, "NORMAL_FONT_COLOR"))
    ns.Side.Spacer(side, 8)
    ns.Side.Category(side, Core.Word("WEAPON_SKILL_DETAIL_BOSS_HEADER", "Raid Boss"))
    local boss = Signed(Chance(Skills.BOSS_LEVEL - level))
    if ranged then
        ns.Side.Line(side, Core.Word("WEAPON_SKILL_DETAIL_BOSS_RANGED", "Hit: %s  Crit: %s"):format(boss, boss),
            rawget(_G, "NORMAL_FONT_COLOR"))
        return
    end
    local defense = Skills.BOSS_LEVEL * Skills.RANKS_PER_LEVEL
    local glancing = (Core.Ask(rawget(_G, "GetGlancingBlowChance"), skillNow, defense) or 0) * 100
    local penalty = (Core.Ask(rawget(_G, "GetGlancingBlowPenalty"), skillNow, defense) or 0) * 100
    ns.Side.Line(side, Core.Word("WEAPON_SKILL_DETAIL_BOSS", "Hit: %s  Crit: %s  Glancing: %s (%s)")
        :format(boss, boss, ("%.0f%%"):format(glancing), ("%.0f%%"):format(penalty)), rawget(_G, "NORMAL_FONT_COLOR"))
end

-- The pane at the right: the chosen skill, or a word to choose one (SkillDetailFrameMixin:Refresh).
function Skills.Detail()
    if not side then return end
    local index = Selected()
    local skill = index > 0 and Core.Ask(Info().GetSkillLineInfo, index)
    if type(skill) ~= "table" or skill.isHeader then
        ns.Side.Empty(side, Core.Word("SKILL_DETAIL_SELECT_PROMPT", "Select a skill to see more about it."))
        side.bar:Hide()
        return
    end
    if skill.skillID == Skills.DEFENSE then skill.modifier = Core.Plain(select(2, Game("UnitDefenseSkill", "player"))) or skill.modifier end
    ns.Side.Empty(side, nil)
    side.bar:Show()
    local ranged = Skills.WEAPONS[skill.skillID]
    ns.Side.Title(side, skill.name, nil, rawget(_G, "CHARACTER_FRAME_SIDE_PANEL_SKILL_COLOR"))
    Bar(side.bar, skill)
    ns.Side.Describe(side, skill.description, ranged == nil and Skills.DESCRIPTION or Skills.WEAPON_DESCRIPTION)
    ns.Side.Rows(side)
    if ranged ~= nil then Weapon(skill, ranged) end
end

-------------------------------------------------------------------------------
--  The tab
-------------------------------------------------------------------------------
-- The game's first choice when there is none (or a header is): the first skill it lists.
local function First(skills)
    local index = Selected()
    local chosen = index > 0 and Core.Ask(Info().GetSkillLineInfo, index)
    if type(chosen) == "table" and not chosen.isHeader then return end
    for _, skill in ipairs(skills) do
        if not skill.isHeader then
            Core.Ask(Info().SetSelectedSkill, skill.skillIndex)
            return
        end
    end
end

-- The list as the game has the skill lines now (the top level of each, without the class's), and the chosen one.
function Skills.Refresh()
    if not list then return end
    local skills = {}
    for index = 1, Core.Ask(Info().GetNumSkillLines) or 0 do
        local skill = Core.Ask(Info().GetSkillLineInfo, index)
        if type(skill) == "table" and (skill.parentSkillLineID or 0) == 0 and Listed(skill) then
            skill.skillIndex = index
            if skill.skillID == Skills.DEFENSE then
                skill.modifier = Core.Plain(select(2, Game("UnitDefenseSkill", "player"))) or skill.modifier
            end
            skills[#skills + 1] = skill
        end
    end
    First(skills)
    ns.List.Fill(list, skills)
    Skills.Detail()
end

local function Build(left, right)
    list = ns.List.New(left, { extent = Extent, draw = Draw })
    side = ns.Side.New(right)
    side.bar = CreateFrame("Frame", nil, side.content, "ColoredProgressBarTemplate")
    side.bar:SetSize(ns.Rows.SIDE_BAR, ns.Rows.BAR_HEIGHT)
    side.bar:SetPoint("TOP", side.divider, "BOTTOM", 0, -6)
    side.description:ClearAllPoints()
    side.description:SetPoint("TOP", side.bar, "BOTTOM", 0, -8)
    side.description:SetPoint("LEFT")
    side.description:SetPoint("RIGHT", -14, 0)
end

local later = Core.Later(function() ns.Safe("character", Skills.Refresh) end)

local function Show(on)
    if on then Core.On("SKILL_LINES_CHANGED", later) else Core.Off("SKILL_LINES_CHANGED", later) end
    if on then Skills.Refresh() end
end

ns.Sheet.Tab({
    key = "skills", icon = "Interface/ICONS/Ability_Racial_JackofAllTrades",
    tip = Core.Word("CHARACTER_FRAME_TAB_SKILLS", "Skills"), title = Core.Word("SKILLS", "Skills"),
    Build = Build, Show = Show,
})
