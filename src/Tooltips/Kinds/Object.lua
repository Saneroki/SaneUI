local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Tooltips - Kinds - Object
--  A thing in the world (a mailbox, a chest, a herb, a vein): its name and its
--  lines, as any other kind (Read.Generic). A herb or an ore Core's data knows
--  by its name also has the section Professions (Gathering.lua); the game's own
--  line that names the skill it needs ("Herbalism", "Requires Mining 175") is
--  left out there, as the section says it, in that line's colour where it is
--  one of the game's colours of difficulty.
-------------------------------------------------------------------------------
local Read = ns.Reader
local TYPE = Enum.TooltipDataType or {}

local function Object(ctx)
    local L = ctx.L
    local node = ns.Gathering.Find(L[1].left)
    local word = node and ns.Gathering.Word(node.skill)
    local said -- the game's line of the skill
    if word then
        for index = 2, ctx.count do
            local line = L[index]
            if line.left:find(word, 1, true) then
                line.used = true
                said = said or line
            end
        end
    end
    Read.Generic()
    if node then ns.Gathering.Node(node, said and said.lr, said and said.lg, said and said.lb) end
end

if TYPE.Object then ns.KINDS[TYPE.Object] = Object end
