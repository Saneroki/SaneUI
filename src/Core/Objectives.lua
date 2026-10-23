-------------------------------------------------------------------------------
--  Sane UI - Core - Objectives
--  What is still to do about a creature for a quest in your log, as the game
--  itself says it in the creature's tooltip data, for every view that shows it
--  (a nameplate, a mark beside one): Core.UnitQuest(unit).
--
--  First the game's word that the creature belongs to a quest at all
--  (C_QuestLog.UnitIsRelatedToActiveQuest), then its tooltip data
--  (C_TooltipInfo.GetUnit): its lines of the kind QuestObjective, each with its
--  text and whether it is done. The first objective still open counts: "kill"
--  where its text names the creature, "loot" otherwise, and its count ("3/8").
--  Nothing is guessed: a creature the game says nothing about has nothing to do.
--  In a fight the game may hide what the tooltip says (a secret value): then the
--  answer is false, and a view keeps what it showed.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain

-- "kill" or "loot" and the count ("3/8", or ""); nil when there is nothing to do; false when the game hides it now.
function Core.UnitQuest(unit)
    local log = rawget(_G, "C_QuestLog")
    if not (log and log.UnitIsRelatedToActiveQuest) then return nil end
    local known, related = pcall(log.UnitIsRelatedToActiveQuest, unit)
    if not known then return nil end
    if Core.Secret(related) then return false end
    if not related then return nil end
    local info = rawget(_G, "C_TooltipInfo")
    local ok, data = pcall(info and info.GetUnit or error, unit)
    local lines = ok and type(data) == "table" and data.lines or nil
    if Core.Secret(lines) then return false end
    if type(lines) ~= "table" then return nil end
    local name = Plain(UnitName(unit))
    local kinds = rawget(_G, "Enum") and Enum.TooltipDataLineType
    local objective = kinds and kinds.QuestObjective
    for _, line in ipairs(lines) do
        if objective and Plain(line.type) == objective then
            local text, right = Plain(line.leftText), Plain(line.rightText)
            if type(text) == "string" then
                local count = text:match("(%d+%s*/%s*%d+)") or (type(right) == "string" and right:match("(%d+%s*/%s*%d+)")) or ""
                local have, need = count:match("^(%d+)%s*/%s*(%d+)$")
                local full = have and tonumber(need) > 0 and tonumber(have) >= tonumber(need)
                if Plain(line.completed) ~= true and not full then
                    local kind = (type(name) == "string" and name ~= "" and text:find(name, 1, true)) and "kill" or "loot"
                    return kind, (count:gsub("%s", ""))
                end
            end
        end
    end
    return nil
end
