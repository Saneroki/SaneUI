local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Quest
--  A quest's tooltip:
--
--      THE FURY RUNS DEEP
--      Level 27  ·  In progress                   the level in the colour of its difficulty
--      ------------------------------------
--      Motley Garmason wants Kam Deepfury's       what the tooltip says
--      head brought to him at Dun Modr.
--      ------------- OBJECTIVES -------------
--      [ ] Head of Deepfury                0/1    a box for each thing to do,
--      [x] Tough Wolf Meat                 8/8    ticked and green when it is done
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Read, TEXT = ns.Reader, ns.TEXT
local TYPE = Enum.TooltipDataType or {}
local LINE = Enum.TooltipDataLineType or {}

local OBJECTIVE = LINE.QuestObjective or -1
local GOLD, LIGHT, DONE = ns.COLOR.GOLD, ns.COLOR.LIGHT, ns.COLOR.DONE

-- Where the quest stands for you: nil if you neither have nor had it.
local function State(id)
    local log = C_QuestLog
    if not (log and id) then return nil end
    if log.IsOnQuest and Plain(log.IsOnQuest(id)) then
        return log.ReadyForTurnIn and Plain(log.ReadyForTurnIn(id)) and TEXT.READY or TEXT.IN_PROGRESS
    end
    if log.IsQuestFlaggedCompleted and Plain(log.IsQuestFlaggedCompleted(id)) then return TEXT.DONE end
    return nil
end

local function Quest(ctx)
    local L, id = ctx.L, ctx.id
    Read.Title(true)
    Read.AccentFromTitle()
    if not ctx.head.accent then Read.Accent(GOLD[1], GOLD[2], GOLD[3]) end

    -- Under the name: level and where it stands
    local log = C_QuestLog
    local level = id and log and log.GetQuestDifficultyLevel and Plain(log.GetQuestDifficultyLevel(id))
    local state = State(id)
    if type(level) == "number" and level > 0 then
        local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
        local row = Read.Text("sub", Read.Memo("level", TEXT.LEVEL, level), color and color.r or LIGHT[1], color and color.g or LIGHT[2], color and color.b or LIGHT[3])
        if state then row.label = Read.Memo("state", "\194\183  %s", state) end
    elseif state then
        Read.Text("sub", state, LIGHT[1], LIGHT[2], LIGHT[3])
    end

    -- The things to do come last, under a caption
    local objectives = false
    for index = 2, ctx.count do
        if L[index].type == OBJECTIVE then
            L[index].used, objectives = true, true
        end
    end
    ctx.rule = true
    Read.Rest()
    if not objectives then return end
    ctx.rule = false
    local caption = Read.Row()
    caption.kind, caption.left = "caption", TEXT.OBJECTIVES
    for index = 2, ctx.count do
        local line = L[index]
        if line.type == OBJECTIVE then
            -- "Head of Deepfury: 0/1", or the count first: the count goes to the right.
            local text = line.left
            local what, tally = text:match("^%s*%-?%s*(.-):?%s*(%d+/%d+)%s*$")
            if not what or what == "" then tally, what = text:match("^%s*%-?%s*(%d+/%d+)%s+(.+)$") end
            local done = line.data and Plain(line.data.completed) == true
            if not done and tally then
                local have, want = tally:match("^(%d+)/(%d+)$")
                done = tonumber(have) >= tonumber(want)
            end
            local color = done and DONE or LIGHT
            local row = Read.Text("row", what or text, color[1], color[2], color[3])
            row.right, row.icon = tally or "", done and "check" or "box"
        end
    end
end

if TYPE.Quest then ns.KINDS[TYPE.Quest] = Quest end
