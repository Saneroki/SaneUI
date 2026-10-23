local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Range
--  Whether your target is out of reach of everything you could attack it
--  with: then its plate's border is red instead of white (Bar.Border).
--
--  Your attacks: the spells of your spellbook (not passive) the game calls
--  harmful and gives a range (C_Spell.IsSpellHarmful, SpellHasRange): melee
--  strikes, a warrior's Charge and his Shoot (which reaches only with a bow,
--  as the game itself checks), a mage's bolts. The game says for each whether
--  it reaches your target now (C_Spell.IsSpellInRange: true, false, or nil
--  where it cannot tell, a Shoot without a bow, say); your target is in reach
--  while any of them does. The list is made anew when your spells change.
--
--  The game tells when one of them goes in or out of reach of your target
--  (SPELL_RANGE_CHECK_UPDATE, asked for each by EnableSpellRangeCheck), so
--  nothing is looked at between. Where none of your spells can tell (a
--  character without any yet), the target is out of reach beyond
--  Range.FALLBACK yards, by the distance read from the game's scaling
--  (Scale.Yards), looked at every Range.EVERY seconds while that is so.
--  Only a target you can attack; a friend's border stays white.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Range = {}
ns.Range = Range

Range.FALLBACK = 40 -- yards, where none of your spells can tell
Range.EVERY = 0.25  -- seconds between looks at the distance, while it decides

local spells = {}   -- your attacks: their spell IDs
local watched = {}  -- [spell ID] = true: the game tells us when it goes in or out of reach
local ticker

-- Your attacks, as your spellbook has them now.
local function Collect()
    local book, spell = rawget(_G, "C_SpellBook"), rawget(_G, "C_Spell")
    local banks = rawget(_G, "Enum") and Enum.SpellBookSpellBank
    local kinds = rawget(_G, "Enum") and Enum.SpellBookItemType
    local found = {}
    if not (book and spell and banks and kinds) then return found end
    local bank = banks.Player
    for line = 1, Core.Ask(book.GetNumSpellBookSkillLines) or 0 do
        local info = Core.Ask(book.GetSpellBookSkillLineInfo, line)
        if type(info) == "table" and not info.shouldHide and (Plain(info.offSpecID) or 0) == 0 then
            local first = (Plain(info.itemIndexOffset) or 0) + 1
            for index = first, first + (Plain(info.numSpellBookItems) or 0) - 1 do
                local item = Core.Ask(book.GetSpellBookItemInfo, index, bank)
                local id = type(item) == "table" and Plain(item.spellID)
                if id and Plain(item.itemType) == kinds.Spell and not Plain(item.isPassive)
                    and Core.Ask(spell.IsSpellHarmful, id) and Core.Ask(spell.SpellHasRange, id) then
                    found[#found + 1] = id
                end
            end
        end
    end
    return found
end

-- Whether your target is out of reach: true, false, or nil when none of your spells can tell.
local function Asked()
    local spell = rawget(_G, "C_Spell")
    local told = false
    for _, id in ipairs(spells) do
        local reach = Core.Ask(spell.IsSpellInRange, id, "target")
        if reach == true then return false end
        if reach == false then told = true end
    end
    if told then return true end
    return nil
end

-- Whether your target is out of reach now, by your spells, else by its distance.
function Range.Out()
    if Plain(UnitExists("target")) ~= true or Core.Ask(UnitCanAttack, "player", "target") ~= true then return false end
    local out = Asked()
    Range.guessing = out == nil
    if out ~= nil then return out end
    local yards = ns.Scale.Yards("target")
    return yards ~= nil and yards > Range.FALLBACK
end

-- Looked at anew: the border of your target's plate red or white, and the distance looked at while it decides.
function Range.Update()
    local out = not ns.off and (ns.options or {}).range ~= false and Range.Out()
    if out ~= Range.out then
        Range.out = out
        ns.Plate.Borders()
    end
    if ticker then ticker:SetShown(Range.guessing == true and not ns.off) end
end
local again = Core.Later(Range.Update)

-- Your attacks made anew, the game asked to tell about each (and no more about those gone).
local function Rebuild()
    local spell = rawget(_G, "C_Spell")
    local enable = spell and spell.EnableSpellRangeCheck
    spells = Collect()
    local now = {}
    for _, id in ipairs(spells) do now[id] = true end
    if enable then
        for id in pairs(watched) do
            if not now[id] then pcall(enable, id, false) end
        end
        for id in pairs(now) do
            if not watched[id] then pcall(enable, id, true) end
        end
    end
    watched = now
    again()
end
local rebuild = Core.Later(Rebuild)

local since = 0
local function Tick(_, elapsed)
    since = since + elapsed
    if since < Range.EVERY then return end
    since = 0
    Range.Update()
end

function Range.Start()
    ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", ns.Guard(Tick))
    Range.ticker = ticker
    ns.On("SPELLS_CHANGED", rebuild)
    ns.On("SPELL_RANGE_CHECK_UPDATE", again)
    ns.On("PLAYER_TARGET_CHANGED", again)
    ns.On("UNIT_FACTION", again)
    Rebuild()
end
