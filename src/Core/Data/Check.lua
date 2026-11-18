local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Check
--  What the game told in play of an entry, compared with the set field by field (Doc/guides/data.md, *Checked in
--  play*): what agrees is confirmed, what differs or is missing is learned, so the data grows more right with every
--  player who plays. Core's watchers only (Quests.lua, Facts.lua, Loot.lua); a module reads the sets as ever.
--
--      Data.Check("Quests", 77, { name = "Wolves", rewardXP = 450, startNPCs = { npc = 69 } })
--
--  told holds the fields the game showed, in the set's own shape. How each is told is the schema's play list (the
--  set file's header): "name" a field the game shows whole, "startNPCs.npc" a list the game shows one member of at a
--  time (the giver talked to), known by that part, "services[]" a list of plain values shown one at a time,
--  "health{}" a map the game shows one key of at a time (the health at the level seen); a "?" after it, a field the
--  game shows only where the data is wrong (a requirement an offer proves wrong): it does not hold back the whole
--  entry. A field the list does not name is told whole. Check.NONE says the game shows the field empty (a quest offered to both
--  sides: side none).
--
--  - **Agrees:** the field (a member: "startNPCs=69") confirmed (Data.Confirm), shared like any confirmation; once
--    every field of the play list the entry holds was told (a list's every member), the whole entry.
--  - **Differs, or the set lacks the entry** (a quest only Forever has): learned (Data.Learn), the set's record with
--    what the game told put in (a member added to its list, never one taken away), and every part told kept with it
--    (Confirmations.Told), so the harvest stages only what the game said and leaves the set's other facts as they
--    are: unverified until the game tells them too.
-------------------------------------------------------------------------------
local Data, Confirmations = Core.Data, Core.Data.Confirmations

local Check = {}
Data.Checks = Check
Check.NONE = {} -- told: the game shows the field empty

local specs = {} -- [set name] = { [field] = { member = true, by = part or nil } } from the set's play list
local META = { since = true, day = true, patch = true }

-- How each field of a set is told, from its play list; made once a set is ready.
local function Spec(handle)
    local spec = specs[handle.name]
    if spec then return spec end
    if not handle:Ready() then return {} end
    spec = {}
    for _, said in ipairs(handle:PlayFields()) do
        local text, optional = said:match("^(.-)(%??)$")
        local field, by = text:match("^([%w_]+)%.([%w_]+)$")
        if field then
            spec[field] = { member = true, by = by }
        elseif text:match("^[%w_]+%[%]$") then
            spec[text:sub(1, -3)] = { member = true }
        elseif text:match("^[%w_]+{}$") then
            spec[text:sub(1, -3)] = { map = true }
        else
            spec[text] = {}
        end
        local how = spec[field or text:match("^[%w_]+")]
        if how then how.optional = optional == "?" end
    end
    specs[handle.name] = spec
    return spec
end
Check.Spec = Spec

-- The value a member is known by: its part (a giver's creature), or the value itself.
local function Id(how, value)
    if how.by then return type(value) == "table" and value[how.by] or nil end
    return value
end

local function Part(field, how, value)
    if not (how.member or how.map) then return field end
    return field .. "=" .. tostring(how.map and value or Id(how, value))
end
Check.Part = Part

-- Whether the game told every field of the play list that an entry holds (of a list, each member): told here, what
-- members told aside (own), so this client never confirms an entry whole on their word.
local function Covered(handle, key, record)
    local told = {}
    for _, part in ipairs(Data.ConfirmedParts(handle.name, key, true)) do told[part] = true end
    local any = false
    for field, how in pairs(Spec(handle)) do
        local value = record[field]
        if not how.optional and value ~= nil and not (type(value) == "table" and next(value) == nil) then
            any = true
            if how.member then
                for _, element in ipairs(value) do
                    if not told[Part(field, how, element)] then return false end
                end
            elseif how.map then
                for inner in pairs(value) do
                    if not told[Part(field, how, inner)] then return false end
                end
            elseif not told[field] then
                return false
            end
        end
    end
    return any
end
Check.Covered = Covered

-- A record of the set to change: the entry's fields, without what the reader adds (since, day, patch).
local function Own(record)
    local copy = {}
    for field, value in pairs(record or {}) do
        if not META[field] then copy[field] = Core.Copy(value) end
    end
    return copy
end

-- Compares what the game told with the set's entry; true when something was confirmed or learned.
function Data.Check(name, key, told)
    local handle = Data.Set(name)
    if key == nil or type(told) ~= "table" or not handle:Ready() then return false end
    local spec, current = Spec(handle), handle:Get(key)
    local record, agree, changed = Own(current), {}, {}
    for field, value in pairs(told) do
        if handle:HasField(field) then
            local how = spec[field] or {}
            if how.member then
                -- one member, or several in an array (a quest's tags)
                local members = value
                if (how.by and type(value) == "table" and value[how.by] ~= nil) or (not how.by and type(value) ~= "table") then
                    members = { value }
                end
                for _, member in ipairs(type(members) == "table" and members or {}) do
                    local id, found = Id(how, member), false
                    if id ~= nil then
                        for _, element in ipairs(record[field] or {}) do
                            if Id(how, element) == id then found = true end
                        end
                        local part = Part(field, how, member)
                        if found then
                            agree[#agree + 1] = part
                        else
                            local list = record[field] or {}
                            list[#list + 1] = Core.Copy(member)
                            record[field] = list
                            changed[#changed + 1] = part
                        end
                    end
                end
            elseif how.map then
                -- a map the game shows a key of at a time (a creature's health at the level seen)
                for inner, said in pairs(type(value) == "table" and value or {}) do
                    local part = Part(field, how, inner)
                    local own = record[field]
                    if type(own) == "table" and Core.Same(own[inner], said) then
                        agree[#agree + 1] = part
                    else
                        own = type(own) == "table" and own or {}
                        own[inner] = Core.Copy(said)
                        record[field] = own
                        changed[#changed + 1] = part
                    end
                end
            else
                if value == Check.NONE then value = nil end
                if Core.Same(record[field], value) then
                    agree[#agree + 1] = field
                else
                    record[field] = Core.Copy(value)
                    changed[#changed + 1] = field
                end
            end
        end
    end
    if #changed > 0 or (current == nil and #agree > 0) then
        if not Data.Learn(name, key, record) then return false end
        for _, part in ipairs(agree) do Confirmations.Told(name, key, part) end
        for _, part in ipairs(changed) do Confirmations.Told(name, key, part) end
        -- a field told a piece at a time (a creature's health at the level seen) is no discovery by itself
        for _, part in ipairs(changed) do
            local how = spec[part:match("^[%w_]+")]
            if not (how and how.optional) then
                Data.Discovered(name, key, current and "changed" or "new", changed)
                break
            end
        end
        if current == nil and #changed == 0 then Data.Discovered(name, key, "new", agree) end
        return true
    end
    if #agree == 0 then return false end
    if handle:Learned(key) then
        for _, part in ipairs(agree) do Confirmations.Told(name, key, part) end
        return true
    end
    if not handle:Unverified(key, nil, true) then return false end -- not confirmed whole by the game here (members' word aside)
    local kept = false
    for _, part in ipairs(agree) do kept = Data.Confirm(name, key, part) or kept end
    if Covered(handle, key, record) then kept = Data.Confirm(name, key) or kept end
    return kept
end
