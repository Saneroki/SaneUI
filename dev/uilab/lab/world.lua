-- The fake server: what the game would hear from the server, from a world file (dev/uilab/worlds/): the player,
-- their group and guild, chat, items, money, stats, zone. Units, the guild roster, chat messages and items are
-- answered by the game's own functions, as the game answers them; chat and other events come at the times the
-- world says, or when the page sends them. Items and spells are the game's own, read from SaneUI's data master.
return function(Lab)
    local S = Lab.S
    local G = Lab.G
    local World = {}
    Lab.World = World
    Lab.world = {}

    -- The game's classes, races and item classes: from the client's tables where the lab has them.
    local client = Lab.Ask({ need = "client" })
    local cdata = client and client.ok and dofile(client.file) or {}
    local CLASSES = cdata.classes or {
        { id = 1, file = "WARRIOR", name = "Warrior" }, { id = 2, file = "PALADIN", name = "Paladin" },
        { id = 3, file = "HUNTER", name = "Hunter" }, { id = 4, file = "ROGUE", name = "Rogue" },
        { id = 5, file = "PRIEST", name = "Priest" }, { id = 7, file = "SHAMAN", name = "Shaman" },
        { id = 8, file = "MAGE", name = "Mage" }, { id = 9, file = "WARLOCK", name = "Warlock" },
        { id = 11, file = "DRUID", name = "Druid" } }
    local RACES = cdata.races or {
        { id = 1, file = "Human", name = "Human" }, { id = 2, file = "Orc", name = "Orc" }, { id = 3, file = "Dwarf", name = "Dwarf" },
        { id = 4, file = "NightElf", name = "Night Elf" }, { id = 5, file = "Scourge", name = "Undead" },
        { id = 6, file = "Tauren", name = "Tauren" }, { id = 7, file = "Gnome", name = "Gnome" }, { id = 8, file = "Troll", name = "Troll" } }
    local classByFile, classById, raceByFile = {}, {}, {}
    for _, c in ipairs(CLASSES) do classByFile[c.file] = c; classById[c.id] = c end
    for _, r in ipairs(RACES) do raceByFile[r.file] = r end
    local itemClasses = cdata.itemClasses or { [0] = "Consumable", [1] = "Container", [2] = "Weapon", [4] = "Armor",
        [7] = "Trade Goods", [9] = "Recipe", [12] = "Quest", [15] = "Miscellaneous" }
    local itemSubClasses = cdata.itemSubClasses or {}

    G.LOCALIZED_CLASS_NAMES_MALE, G.LOCALIZED_CLASS_NAMES_FEMALE = {}, {}
    for _, c in ipairs(CLASSES) do
        G.LOCALIZED_CLASS_NAMES_MALE[c.file] = c.name
        G.LOCALIZED_CLASS_NAMES_FEMALE[c.file] = c.female or c.name
    end
    G.CLASS_SORT_ORDER = {}
    for _, c in ipairs(CLASSES) do G.CLASS_SORT_ORDER[#G.CLASS_SORT_ORDER + 1] = c.file end
    G.GetNumClasses = function() local n = 0; for id in pairs(classById) do if id > n then n = id end end return n end
    G.GetClassInfo = function(id)
        local c = classById[id]
        if c then return c.name, c.file, c.id end
    end
    G.C_CreatureInfo = {
        GetClassInfo = function(id) local c = classById[id]; if c then return { className = c.name, classFile = c.file, classID = c.id } end end,
        GetRaceInfo = function(id) for _, r in ipairs(RACES) do if r.id == id then return { raceName = r.name, clientFileString = r.file, raceID = r.id } end end end,
    }
    if not rawget(G, "RAID_CLASS_COLORS") then
        local hex = { WARRIOR = "C69B6D", PALADIN = "F48CBA", HUNTER = "AAD372", ROGUE = "FFF468", PRIEST = "FFFFFF",
            SHAMAN = "0070DD", MAGE = "3FC7EB", WARLOCK = "8788EE", DRUID = "FF7C0A" }
        G.RAID_CLASS_COLORS = {}
        for file, h in pairs(hex) do
            local r, g, b = tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255
            G.RAID_CLASS_COLORS[file] = G.CreateColor and G.CreateColor(r, g, b, 1) or { r = r, g = g, b = b, colorStr = "ff" .. h:lower() }
            G.RAID_CLASS_COLORS[file].colorStr = "ff" .. h:lower()
        end
    end
    function World.ClassColor(file) return G.RAID_CLASS_COLORS[file] or { r = 1, g = 1, b = 1, colorStr = "ffffffff" } end
    function World.ClassName(file) local c = classByFile[file]; return c and c.name or tostring(file) end
    G.GetClassColor = function(file)
        local c = World.ClassColor(file)
        return c.r, c.g, c.b, c.colorStr
    end
    G.C_ClassColor = { GetClassColor = function(file) return G.RAID_CLASS_COLORS[file] end }

    -- Loading a world -------------------------------------------------------------------------------------------------
    function World.Load(name)
        -- A name only: a world is a file of dev/uilab/worlds/, never a path the page or a scene points elsewhere.
        if type(name) ~= "string" or not name:match("^[%w_%-]+$") then
            Lab.Note("error", "world: not a name: " .. tostring(name))
            return
        end
        local path = Lab.root .. "/dev/uilab/worlds/" .. name .. ".lua"
        local chunk, err = loadfile(path)
        if not chunk then Lab.Note("error", "world " .. name .. ": " .. tostring(err)) return end
        -- Under the lab's G, as a scene runs: the host's stdout is its protocol with the page, so a print in a world
        -- file must go to the log (G's print), never to the real one, which would break that protocol.
        setfenv(chunk, G)
        local ok, w = pcall(chunk)
        if not ok then Lab.Note("error", "world " .. name .. ": " .. tostring(w)) return end
        Lab.world = w or {}
        Lab.worldName = name
        Lab.Watch(path)
        World.Prepare()
    end

    function World.Prepare()
        local w = Lab.world
        w.player = w.player or { name = "Player", class = "WARRIOR", race = "Human", level = 1 }
        w.realm = w.realm or "Forever"
        local p = w.player
        p.guid = p.guid or "Player-1-00000001"
        p.isPlayer = true
        if w.guild then
            p.guild = w.guild.name
            for i, m in ipairs(w.guild.members or {}) do
                m.guid = m.guid or ("Player-1-%08X"):format(1000 + i)
                m.isPlayer = true
                m.guild = w.guild.name
            end
        end
        for i, m in ipairs(w.party or {}) do
            m.guid = m.guid or ("Player-1-%08X"):format(2000 + i)
            m.isPlayer = true
        end
        Lab.lineID = 0
    end

    function World.FullName(u)
        if not u then return nil end
        if u.surname and u.surname ~= "" then
            return u.name .. G.Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR .. u.surname
        end
        return u.name
    end

    -- Units ------------------------------------------------------------------------------------------------------------
    function World.Unit(unit)
        if type(unit) ~= "string" then return nil end
        local w = Lab.world
        unit = unit:lower()
        if unit == "player" then return w.player end
        if unit == "target" then return w.target end
        if unit == "focus" then return w.focus end
        if unit == "mouseover" then return w.mouseover end
        if unit == "pet" then return w.pet end
        local n = unit:match("^party(%d)$")
        if n then return (w.party or {})[tonumber(n)] end
        n = unit:match("^raid(%d+)$")
        if n then
            local i = tonumber(n)
            if i == 1 then return w.player end
            return (w.party or {})[i - 1] or (w.raid or {})[i - 1 - #(w.party or {})]
        end
        for _, list in ipairs({ w.party or {}, w.raid or {} }) do
            for _, m in ipairs(list) do
                if m.name:lower() == unit or (World.FullName(m) or ""):lower() == unit then return m end
            end
        end
    end
    local U = World.Unit
    local function race(u) return raceByFile[u.race or "Human"] or { name = u.race, file = u.race, id = 0 } end
    local function class(u) return classByFile[u.class or "WARRIOR"] or { name = u.class, file = u.class, id = 0 } end

    G.UnitExists = function(unit) return U(unit) ~= nil end
    G.UnitName = function(unit) local u = U(unit); if u then return u.name, u.surname end return nil end
    G.UnitNameUnmodified = G.UnitName
    G.UnitNameUnmodified = G.UnitName
    G.UnitFullName = function(unit) local u = U(unit); if u then return u.name, u.realm or Lab.world.realm end end
    G.GetUnitName = function(unit, showServer) local u = U(unit); return u and World.FullName(u) end
    G.UnitClass = function(unit) local u = U(unit); if u then local c = class(u); return c.name, c.file, c.id end end
    G.UnitClassBase = function(unit) local u = U(unit); if u then local c = class(u); return c.file, c.id end end
    G.UnitRace = function(unit) local u = U(unit); if u then local r = race(u); return r.name, r.file, r.id end end
    G.UnitLevel = function(unit) local u = U(unit); return u and (u.level or 1) or 0 end
    G.UnitEffectiveLevel = G.UnitLevel
    G.UnitSex = function(unit) local u = U(unit); return u and (u.sex or 2) or 1 end
    G.UnitGUID = function(unit) local u = U(unit); return u and u.guid end
    G.UnitIsPlayer = function(unit) local u = U(unit); return u and u.isPlayer or false end
    G.UnitIsUnit = function(a, b) local x, y = U(a), U(b); return x ~= nil and x == y end
    G.UnitIsConnected = function(unit) local u = U(unit); return u and u.online ~= false or false end
    G.UnitIsDead = function(unit) local u = U(unit); return u and u.dead or false end
    G.UnitIsGhost = function() return false end
    G.UnitIsDeadOrGhost = G.UnitIsDead
    G.UnitHealth = function(unit) local u = U(unit); return u and (u.health or 100) or 0 end
    G.UnitHealthMax = function(unit) local u = U(unit); return u and (u.healthMax or 100) or 0 end
    G.UnitPower = function(unit) local u = U(unit); return u and (u.power or 100) or 0 end
    G.UnitPowerMax = function(unit) local u = U(unit); return u and (u.powerMax or 100) or 0 end
    G.UnitPowerType = function(unit)
        local u = U(unit)
        local t = u and u.powerType or 0
        local tokens = { [0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY" }
        return t, tokens[t] or "MANA"
    end
    G.UnitFactionGroup = function(unit) local u = U(unit); if u then local f = u.faction or Lab.world.player.faction or "Alliance"; return f, f end end
    G.UnitAffectingCombat = function(unit) return Lab.world.combat and unit == "player" or false end
    G.UnitInParty = function(unit) local u = U(unit); if not u then return false end; if u == Lab.world.player then return #(Lab.world.party or {}) > 0 end; for _, m in ipairs(Lab.world.party or {}) do if m == u then return true end end return false end
    G.UnitInRaid = function(unit) return Lab.world.raid and U(unit) and 1 or nil end
    G.UnitIsGroupLeader = function(unit) local u = U(unit); return u and u.leader or false end
    G.UnitIsFriend = function() return true end
    G.UnitIsEnemy = function() return false end
    G.UnitCanAttack = function() return false end
    G.UnitCanCooperate = function() return true end
    G.UnitReaction = function() return 5 end
    G.UnitClassification = function() return "normal" end
    G.UnitIsAFK = function(unit) local u = U(unit); return u and u.status == 1 or false end
    G.UnitIsDND = function(unit) local u = U(unit); return u and u.status == 2 or false end
    G.UnitIsPVP = function() return false end
    G.UnitGroupRolesAssigned = function() return "NONE" end
    G.UnitXP = function() return Lab.world.player.xp or 0 end
    G.UnitXPMax = function() return Lab.world.player.xpMax or 0 end
    G.GetXPExhaustion = function() return Lab.world.player.rested end
    G.IsInGroup = function() return #(Lab.world.party or {}) > 0 end
    G.IsInRaid = function() return Lab.world.raid ~= nil end
    G.GetNumGroupMembers = function()
        local n = #(Lab.world.party or {}) + #(Lab.world.raid or {})
        return n > 0 and n + 1 or 0
    end
    G.GetNumSubgroupMembers = function() return #(Lab.world.party or {}) end
    G.GetRealmName = function() return Lab.world.realm end
    G.GetNormalizedRealmName = function() return (Lab.world.realm:gsub("[%s%-]", "")) end
    G.Ambiguate = function(name) return (tostring(name):gsub("%-.*$", "")) end
    G.GetPlayerInfoByGUID = function(guid)
        local function find(u)
            if u and u.guid == guid then
                local c, r = class(u), race(u)
                return c.name, c.file, r.name, r.file, u.sex or 2, World.FullName(u), u.realm or ""
            end
        end
        local w = Lab.world
        local a = { find(w.player) }
        if a[1] then return unpack(a) end
        for _, list in ipairs({ w.party or {}, w.raid or {}, w.guild and w.guild.members or {} }) do
            for _, m in ipairs(list) do
                a = { find(m) }
                if a[1] then return unpack(a) end
            end
        end
    end

    -- Zone, money, stats -------------------------------------------------------------------------------------------------
    G.GetZoneText = function() return Lab.world.player.zone or "" end
    G.GetRealZoneText = G.GetZoneText
    G.GetSubZoneText = function() return Lab.world.player.subzone or "" end
    G.GetMinimapZoneText = function() return Lab.world.player.subzone or Lab.world.player.zone or "" end
    G.GetMoney = function() return Lab.world.player.money or 0 end
    G.C_Map = setmetatable({
        GetBestMapForUnit = function(unit) local u = U(unit); return u and u.mapID end,
        GetMapInfo = function(id) return { mapID = id, name = Lab.world.player.zone or "", mapType = 3, parentMapID = 0 } end,
    }, {})
    local STATS = { "strength", "agility", "stamina", "intellect", "spirit" }
    G.UnitStat = function(unit, i)
        local st = (U(unit) or {}).stats or {}
        local v = st[STATS[i] or ""] or 0
        return v, v, 0, 0
    end
    G.UnitArmor = function(unit)
        local v = ((U(unit) or {}).stats or {}).armor or 0
        return v, v, v, 0, 0
    end
    G.UnitResistance = function(unit, school)
        local r = (((U(unit) or {}).stats or {}).resistances or {})[school] or 0
        return r, r, 0, 0
    end
    G.UnitAttackPower = function(unit) local v = ((U(unit) or {}).stats or {}).attackPower or 0; return v, 0, 0 end
    G.UnitRangedAttackPower = G.UnitAttackPower
    G.UnitAttackSpeed = function(unit) return ((U(unit) or {}).stats or {}).speed or 2, nil end
    G.UnitDamage = function(unit)
        local d = ((U(unit) or {}).stats or {}).damage or { 1, 2 }
        return d[1], d[2], 0, 0, 0, 0, 1
    end
    G.UnitRangedDamage = function() return 0, 0, 0, 0, 0, 1 end
    for name, field in pairs({ GetCritChance = "crit", GetRangedCritChance = "crit", GetDodgeChance = "dodge",
        GetParryChance = "parry", GetBlockChance = "block", GetSpellCritChance = "spellCrit", GetSpellBonusDamage = "spellPower",
        GetSpellBonusHealing = "healing", GetHitModifier = "hit", GetSpellHitModifier = "spellHit" }) do
        G[name] = function() return ((Lab.world.player or {}).stats or {})[field] or 0 end
    end
    -- The client's numbers for the five attributes (UnitStat's index), and how the character moves now: on foot.
    for i, name in ipairs({ "STRENGTH", "AGILITY", "STAMINA", "INTELLECT", "SPIRIT" }) do
        if rawget(G, "LE_UNIT_STAT_" .. name) == nil then G["LE_UNIT_STAT_" .. name] = i end
    end
    G.IsSwimming = function() return false end
    G.IsFlying = function() return false end
    G.IsFalling = function() return false end
    -- What the game's character sheet asks besides (its stats files): plain numbers of a character with no ratings,
    -- what an attribute gives none of its own, its defense its level's skill, no enemy beyond its level.
    local function zero() return 0 end
    for _, name in ipairs({ "GetAttackPowerForStat", "GetRangedAttackPowerForStat", "GetCritChanceFromStat",
        "GetSpellCritChanceFromStat", "GetDodgeChanceFromAttribute", "GetHealthRegenFromSpirit", "GetManaRegenFromSpirit",
        "GetArmorPenetration", "GetCombatRating", "GetCombatRatingBonus", "GetExpertisePercent", "GetMeleeHaste",
        "GetOffhandHitModifier", "GetRangedHitModifier", "GetShieldBlock", "UnitSpellHaste",
        "GetSpellPenetration", "GetEnemyChanceToMiss", "GetEnemyCritChance", "GetEnemyCrushingBlowChance",
        "GetEnemyDodgeChance", "GetEnemyParryChance", "GetEnemySkillDifference", "ExpectedSpellResistance",
        "GetShapeshiftForm" }) do
        G[name] = zero
    end
    G.GetHealthRegen = function() return 0, 0 end
    G.GetExpertise = function() return 0, 0, 0 end
    G.GetRangedHaste = function() return 0, 0 end
    G.GetOverrideAPBySpellPower = zero
    G.GetOverrideSpellPowerByAP = zero
    G.IsDualWielding = function() return false end
    G.IsRangedWeapon = function() return false end
    G.UnitHPPerStamina = function() return 10 end
    G.GetPVPGearStatRules = function() return false end
    G.ClassicExpansionAtLeast = function(expansion) return (tonumber(expansion) or 0) <= 0 end
    local function defense(unit) local level = (U(unit) or {}).level or 1; return level * 5, 0 end
    G.UnitDefenseSkill = defense
    -- The character sheet's own questions: armor's share of a hit taken off by an attacker's level (the old games'
    -- formula), no target to weigh it against, no shield.
    local paperDoll = rawget(G, "C_PaperDollInfo") or {}
    G.C_PaperDollInfo = paperDoll
    paperDoll.GetArmorEffectiveness = function(armor, level)
        armor = tonumber(armor) or 0
        return armor / (armor + 400 + 85 * (tonumber(level) or 1))
    end
    paperDoll.GetArmorEffectivenessAgainstTarget = function() return nil end
    paperDoll.OffhandHasShield = function() return false end
    G.GetEffectiveDefenseSkill = function() return defense("player") end
    -- Running, flying and swimming as the game's base speed (7 yards a second) a walking character has.
    G.GetUnitSpeed = function() return 0, 7, 7, 4.722 end
    -- A number with the game's thousands separator (the client's own, here the English comma).
    G.BreakUpLargeNumbers = function(n)
        local text = tostring(math.floor((tonumber(n) or 0) + 0.5))
        local sign, digits = text:match("^(-?)(%d+)$")
        if not digits then return text end
        return sign .. digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
    G.GetManaRegen = function() local r = ((Lab.world.player or {}).stats or {}).regen or 0; return r, r end

    -- Items and spells: the game's own, from the data master (by the lab's server) ---------------------------------------------
    local items, spells = {}, {}
    function World.Item(id)
        id = tonumber(id)
        if not id then return nil end
        local it = items[id]
        if it == nil then
            local answer = Lab.Ask({ need = "item", id = id })
            it = answer and answer.ok and answer.item or false
            if it then it.id = id end
            items[id] = it
        end
        return it or nil
    end
    World.spells = setmetatable({}, { __index = function(t, id)
        id = tonumber(id)
        if not id then return nil end
        local sp = spells[id]
        if sp == nil then
            local answer = Lab.Ask({ need = "spell", id = id })
            sp = answer and answer.ok and answer.spell or false
            spells[id] = sp
        end
        return sp or nil
    end })

    local QUALITY = { [0] = "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000", "ffe6cc80", "ff00ccff", "ff00ccff" }
    G.ITEM_QUALITY_COLORS = rawget(G, "ITEM_QUALITY_COLORS") or {}
    for q, hex in pairs(QUALITY) do
        local r, g, b = tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255
        if not G.ITEM_QUALITY_COLORS[q] then
            G.ITEM_QUALITY_COLORS[q] = { r = r, g = g, b = b, hex = "|c" .. hex, color = G.CreateColor and G.CreateColor(r, g, b, 1) }
        end
    end
    G.GetItemQualityColor = function(q)
        local hex = QUALITY[q] or QUALITY[1]
        return tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255, hex
    end

    local function itemID(item)
        if type(item) == "number" then return item end
        if type(item) == "string" then
            local id = item:match("item:(%d+)") or item:match("^%d+$")
            if id then return tonumber(id) end
            for k, it in pairs(items) do if it and it.name == item then return k end end
        end
    end
    function World.Link(id)
        local it = World.Item(id)
        if not it then return nil end
        return ("|c%s|Hitem:%d::::::::%d:::::::::|h[%s]|h|r"):format(QUALITY[it.quality or 1], id, Lab.world.player.level or 60, it.name)
    end
    local function subClassName(it)
        return itemSubClasses[(it.class or 0) .. "." .. (it.subclass or 0)] or ""
    end
    G.GetItemInfo = function(item)
        local id = itemID(item)
        local it = id and World.Item(id)
        if not it then return nil end
        return it.name, World.Link(id), it.quality or 1, it.itemLevel or 1, it.minLevel or 0, itemClasses[it.class or 0] or "",
            subClassName(it), it.stack or 1, it.slot or "", it.icon, it.sell or 0, it.class or 0, it.subclass or 0, it.bind or 0, 0, it.set, false
    end
    G.GetItemInfoInstant = function(item)
        local id = itemID(item)
        local it = id and World.Item(id)
        if not it then return nil end
        return id, itemClasses[it.class or 0] or "", subClassName(it), it.slot or "", it.icon, it.class or 0, it.subclass or 0
    end
    G.GetItemIcon = function(item) local id = itemID(item); local it = id and World.Item(id); return it and it.icon end
    G.C_Item = {
        GetItemInfo = G.GetItemInfo, GetItemInfoInstant = G.GetItemInfoInstant, GetItemIconByID = G.GetItemIcon,
        GetItemNameByID = function(item) local id = itemID(item); local it = id and World.Item(id); return it and it.name end,
        GetItemQualityByID = function(item) local id = itemID(item); local it = id and World.Item(id); return it and it.quality end,
        GetItemQualityColor = G.GetItemQualityColor,
        DoesItemExistByID = function(item) return World.Item(itemID(item)) ~= nil end,
        IsItemDataCachedByID = function() return true end,
        RequestLoadItemDataByID = function(item)
            local id = itemID(item)
            G.C_Timer.After(0, function() Lab.Fire("ITEM_DATA_LOAD_RESULT", id, World.Item(id) ~= nil) end)
        end,
        GetItemLink = function(loc) return nil end,
    }
    function World.ItemTooltip(id)
        local it = World.Item(id)
        if not it then return { { left = "Retrieving item information", r = 1, g = 0.1, b = 0.1 } } end
        local r, g, b = G.GetItemQualityColor(it.quality or 1)
        local lines = { { left = it.name, r = r, g = g, b = b } }
        local function add(left, right, cr, cg, cb) lines[#lines + 1] = { left = left, right = right, r = cr or 1, g = cg or 1, b = cb or 1 } end
        if it.itemLevel and it.itemLevel > 1 then add("Item Level " .. it.itemLevel, nil, 1, 0.82, 0) end
        local binds = { [1] = "Binds when picked up", [2] = "Binds when equipped", [3] = "Binds when used", [4] = "Quest Item" }
        if binds[it.bind] then add(binds[it.bind]) end
        if it.unique then add("Unique") end
        local slot = it.slot and rawget(G, it.slot)
        if slot and slot ~= "" then add(slot, subClassName(it)) end
        if it.damageMin then add(("%d - %d Damage"):format(it.damageMin, it.damageMax or it.damageMin), it.speed and ("Speed %.2f"):format(it.speed)) end
        if it.armor then add(it.armor .. " Armor") end
        for stat, v in pairs(it.stats or {}) do
            local label = rawget(G, stat) or stat
            add(("+%d %s"):format(v, label))
        end
        for _, e in ipairs(it.effects or {}) do
            if e.text then lines[#lines + 1] = { left = (e.trigger == "use" and "Use: " or e.trigger == "hit" and "Chance on hit: " or "Equip: ") .. e.text, r = 0, g = 1, b = 0, wrap = true } end
        end
        if it.minLevel and it.minLevel > 1 then
            local low = (Lab.world.player.level or 60) < it.minLevel
            add("Requires Level " .. it.minLevel, nil, 1, low and 0.13 or 1, low and 0.13 or 1)
        end
        if it.description then lines[#lines + 1] = { left = '"' .. it.description .. '"', r = 1, g = 0.82, b = 0, wrap = true } end
        return lines
    end

    G.GetSpellInfo = function(id)
        local sp = World.spells[id]
        if not sp then return nil end
        return sp.name, sp.rank, sp.icon, sp.castTime or 0, 0, sp.maxRange or 0, tonumber(id)
    end
    G.GetSpellTexture = function(id) local sp = World.spells[id]; return sp and sp.icon end
    G.C_Spell = {
        GetSpellInfo = function(id)
            local sp = World.spells[id]
            if sp then return { name = sp.name, iconID = sp.icon, originalIconID = sp.icon, castTime = sp.castTime or 0, minRange = 0, maxRange = sp.maxRange or 0, spellID = tonumber(id) } end
        end,
        GetSpellName = function(id) local sp = World.spells[id]; return sp and sp.name end,
        GetSpellTexture = function(id) local sp = World.spells[id]; return sp and sp.icon, sp and sp.icon end,
        GetSpellDescription = function(id) local sp = World.spells[id]; return sp and sp.text or "" end,
        DoesSpellExist = function(id) return World.spells[id] ~= nil end,
        GetSpellLink = function(id) local sp = World.spells[id]; return sp and ("|cff71d5ff|Hspell:%d:0|h[%s]|h|r"):format(id, sp.name) end,
    }

    -- Equipment and bags ------------------------------------------------------------------------------------------------------
    local SLOTS = { AmmoSlot = 0, HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6,
        LegsSlot = 7, FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13,
        Trinket1Slot = 14, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18, TabardSlot = 19 }
    local EMPTY = { HeadSlot = "Head", NeckSlot = "Neck", ShoulderSlot = "Shoulder", ShirtSlot = "Shirt", ChestSlot = "Chest",
        WaistSlot = "Waist", LegsSlot = "Legs", FeetSlot = "Feet", WristSlot = "Wrists", HandsSlot = "Hands",
        Finger0Slot = "Finger", Finger1Slot = "Finger", Trinket0Slot = "Trinket", Trinket1Slot = "Trinket", BackSlot = "Chest",
        MainHandSlot = "MainHand", SecondaryHandSlot = "SecondaryHand", RangedSlot = "Ranged", TabardSlot = "Tabard", AmmoSlot = "Ammo" }
    G.GetInventorySlotInfo = function(name)
        local id = SLOTS[name]
        if not id then error("GetInventorySlotInfo(): invalid slot " .. tostring(name), 2) end
        return id, "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. EMPTY[name], false
    end
    function World.EquippedID(unit, slot)
        local u = U(unit)
        local e = u and u.equipped
        return e and e[slot]
    end
    G.GetInventoryItemID = function(unit, slot) return World.EquippedID(unit, slot) end
    G.GetInventoryItemLink = function(unit, slot) local id = World.EquippedID(unit, slot); return id and World.Link(id) end
    G.GetInventoryItemTexture = function(unit, slot) local id = World.EquippedID(unit, slot); local it = id and World.Item(id); return it and it.icon end
    G.GetInventoryItemQuality = function(unit, slot) local id = World.EquippedID(unit, slot); local it = id and World.Item(id); return it and it.quality end
    G.GetInventoryItemCount = function(unit, slot) return World.EquippedID(unit, slot) and 1 or 0 end
    G.GetInventoryItemDurability = function(slot) if World.EquippedID("player", slot) then return 80, 100 end end
    G.GetInventoryItemBroken = function() return false end
    G.GetInventoryItemCooldown = function() return 0, 0, 1 end

    local function bag(b) return ((Lab.world.player or {}).bags or {})[b] end
    function World.BagItemID(b, slot)
        local bg = bag(b)
        local e = bg and bg.items and bg.items[slot]
        return e and (type(e) == "table" and e[1] or e)
    end
    G.C_Container = {
        -- the bags' slots among the character's (Blizzard's CONTAINER_BAG_OFFSET: 30 before the first bag)
        ContainerIDToInventoryID = function(b)
            if type(b) ~= "number" or b < 1 then error("ContainerIDToInventoryID(): a bag's ID expected", 2) end
            return 30 + b
        end,
        GetContainerNumSlots = function(b) local bg = bag(b); return bg and bg.size or 0 end,
        GetContainerItemID = function(b, s) return World.BagItemID(b, s) end,
        GetContainerItemLink = function(b, s) local id = World.BagItemID(b, s); return id and World.Link(id) end,
        GetContainerItemInfo = function(b, s)
            local bg = bag(b)
            local e = bg and bg.items and bg.items[s]
            if not e then return nil end
            local id = type(e) == "table" and e[1] or e
            local it = World.Item(id) or {}
            return { iconFileID = it.icon, stackCount = type(e) == "table" and e[2] or 1, isLocked = false, quality = it.quality,
                isReadable = false, hasLoot = false, hyperlink = World.Link(id), isFiltered = false, hasNoValue = (it.sell or 0) == 0,
                itemID = id, isBound = (it.bind or 0) == 1 }
        end,
        GetContainerNumFreeSlots = function(b)
            local bg = bag(b)
            if not bg then return 0, 0 end
            local used = 0
            for _ in pairs(bg.items or {}) do used = used + 1 end
            return (bg.size or 0) - used, 0
        end,
        GetBagName = function(b) local bg = bag(b); return bg and bg.name end,
    }

    -- The guild ----------------------------------------------------------------------------------------------------------------
    local function guild() return Lab.world.guild end
    G.IsInGuild = function() return guild() ~= nil end
    G.GetGuildInfo = function(unit)
        local g, u = guild(), U(unit)
        if not (g and u and u.guild) then return nil end
        local rank = u.rank or (u == Lab.world.player and g.playerRank) or 0
        return g.name, (g.ranks or {})[rank + 1] or "", rank, nil
    end
    G.GetNumGuildMembers = function()
        local g = guild()
        if not g then return 0, 0, 0 end
        local online = 0
        for _, m in ipairs(g.members or {}) do if m.online then online = online + 1 end end
        return #(g.members or {}), online, online
    end
    G.GetGuildRosterInfo = function(i)
        local g = guild()
        local m = g and (g.members or {})[i]
        if not m then return nil end
        local c = class(m)
        return World.FullName(m), (g.ranks or {})[(m.rank or 0) + 1] or "", m.rank or 0, m.level or 1, c.name, m.zone or "",
            m.note or "", m.officerNote or "", m.online or false, m.status or 0, c.file, m.achievements or 0, 0, false, false, 4, m.guid
    end
    G.GetGuildRosterLastOnline = function(i)
        local m = guild() and guild().members[i]
        if not m or m.online then return nil end
        local days = m.lastOnline or 1
        return 0, 0, days, 0
    end
    G.GetGuildRosterMOTD = function() return guild() and guild().motd or "" end
    G.GetGuildInfoText = function() return guild() and guild().info or "" end
    G.CanEditMOTD = function() return guild() and (guild().playerRank or 0) <= 1 or false end
    G.CanEditPublicNote = function() return true end
    G.CanEditOfficerNote = function() return guild() and (guild().playerRank or 0) <= 1 or false end
    G.CanViewOfficerNote = G.CanEditOfficerNote
    G.IsGuildLeader = function() return guild() and (guild().playerRank or 0) == 0 or false end
    G.GuildControlGetNumRanks = function() return #((guild() or {}).ranks or {}) end
    G.GuildControlGetRankName = function(i) return ((guild() or {}).ranks or {})[i] or "" end
    G.GetGuildRosterShowOffline = function() return Lab.world.showOffline ~= false end
    G.SetGuildRosterShowOffline = function(on) Lab.world.showOffline = on and true or false end
    G.GuildRoster = function() G.C_Timer.After(0.2, function() Lab.Fire("GUILD_ROSTER_UPDATE", false) end) end
    G.SortGuildRoster = function() end
    G.GuildRosterSetPublicNote = function(i, note)
        local m = guild() and guild().members[i]
        if m then m.note = note; G.GuildRoster() end
    end
    G.GuildRosterSetOfficerNote = function(i, note)
        local m = guild() and guild().members[i]
        if m then m.officerNote = note; G.GuildRoster() end
    end
    G.C_GuildInfo = setmetatable({
        GuildRoster = G.GuildRoster,
        GetGuildRankOrder = function(guid) return 1 end,
        CanEditOfficerNote = G.CanEditOfficerNote,
        CanViewOfficerNote = G.CanViewOfficerNote,
        IsGuildOfficer = G.CanEditOfficerNote,
        MemberExistsByName = function(name)
            for _, m in ipairs((guild() or {}).members or {}) do if World.FullName(m) == name or m.name == name then return true end end
            return false
        end,
    }, {})

    -- Chat ------------------------------------------------------------------------------------------------------------------
    G.ChatTypeInfo = rawget(G, "ChatTypeInfo") or {}
    for kind, c in pairs({ SAY = { 1, 1, 1 }, YELL = { 1, 0.25, 0.25 }, EMOTE = { 1, 0.5, 0.25 }, TEXT_EMOTE = { 1, 0.5, 0.25 },
        GUILD = { 0.25, 1, 0.25 }, OFFICER = { 0.25, 0.75, 0.25 }, PARTY = { 0.67, 0.67, 1 }, PARTY_LEADER = { 0.46, 0.78, 1 },
        RAID = { 1, 0.5, 0 }, RAID_LEADER = { 1, 0.28, 0.04 }, RAID_WARNING = { 1, 0.28, 0 }, WHISPER = { 1, 0.5, 1 },
        WHISPER_INFORM = { 1, 0.5, 1 }, SYSTEM = { 1, 1, 0 }, CHANNEL = { 1, 0.75, 0.75 }, INSTANCE_CHAT = { 1, 0.5, 0 },
        LOOT = { 0, 0.67, 0 }, MONEY = { 1, 1, 0 }, SKILL = { 0.33, 0.33, 1 }, COMBAT_XP_GAIN = { 0.44, 0.44, 1 },
        ACHIEVEMENT = { 1, 1, 0 }, GUILD_ACHIEVEMENT = { 0.25, 1, 0.25 }, MONSTER_SAY = { 1, 1, 0.62 } }) do
        if not G.ChatTypeInfo[kind] then
            G.ChatTypeInfo[kind] = { r = c[1], g = c[2], b = c[3], id = 0, sticky = 0, flashTab = false, colorNameByClass = true }
        end
    end
    local filters = {}
    G.ChatFrame_AddMessageEventFilter = rawget(G, "ChatFrame_AddMessageEventFilter") or function(event, fn)
        filters[event] = filters[event] or {}
        table.insert(filters[event], fn)
    end
    G.ChatFrame_RemoveMessageEventFilter = rawget(G, "ChatFrame_RemoveMessageEventFilter") or function(event, fn)
        for i, f in ipairs(filters[event] or {}) do if f == fn then table.remove(filters[event], i) break end end
    end
    G.ChatFrame_GetMessageEventFilters = rawget(G, "ChatFrame_GetMessageEventFilters") or function(event) return filters[event] end
    G.GetDefaultLanguage = function() return "Common", 7 end
    G.GetNumLanguages = function() return 1 end
    G.GetLanguageByIndex = function() return "Common", 7 end
    local function channels() return Lab.world.channels or {} end
    G.GetChannelName = function(which)
        for _, c in ipairs(channels()) do
            if c.id == which or c.name == which or (type(which) == "string" and c.name:lower():find(which:lower(), 1, true) == 1) then
                return c.id, c.name, 0, false
            end
        end
        return 0, nil, 0, false
    end
    G.GetChannelList = function()
        local out = {}
        for _, c in ipairs(channels()) do out[#out + 1] = c.id; out[#out + 1] = c.name; out[#out + 1] = false end
        return unpack(out)
    end
    G.JoinChannelByName = function(name)
        local list = channels()
        local id = #list + 1
        list[id] = { id = id, name = name }
        Lab.world.channels = list
        return id, name
    end
    G.JoinPermanentChannel = G.JoinChannelByName
    G.LeaveChannelByName = function() end

    -- Text in the world file may hold {item:ID}, {spell:ID} and {player:Name}: the game's links for them.
    function World.Expand(text)
        text = tostring(text or "")
        text = text:gsub("{item:(%d+)}", function(id) return World.Link(tonumber(id)) or ("[item " .. id .. "]") end)
        text = text:gsub("{spell:(%d+)}", function(id) return G.C_Spell.GetSpellLink(tonumber(id)) or ("[spell " .. id .. "]") end)
        text = text:gsub("{player:([^}]+)}", function(name) return ("|Hplayer:%s|h[%s]|h"):format(name, name) end)
        return text
    end

    local function memberByName(name)
        local w = Lab.world
        if not name then return nil end
        for _, list in ipairs({ { w.player }, w.party or {}, w.raid or {}, w.guild and w.guild.members or {}, w.others or {} }) do
            for _, m in ipairs(list) do
                if World.FullName(m) == name or m.name == name then return m end
            end
        end
    end

    -- A chat message as the server sends it: the event CHAT_MSG_<KIND> with its arguments in the game's order.
    function World.Chat(kind, from, text, channel, target)
        kind = tostring(kind):upper()
        local who = memberByName(from)
        local sender = who and World.FullName(who) or from or ""
        Lab.lineID = (Lab.lineID or 0) + 1
        local channelName, channelIndex, channelBase = "", 0, ""
        if kind == "CHANNEL" then
            local id, name = G.GetChannelName(channel or 1)
            channelIndex, channelBase = id, name or ""
            channelName = id .. ". " .. (name or "")
        end
        local event = "CHAT_MSG_" .. kind
        if not Lab.KnownEvent(event) then
            Lab.Note("warn", "the game has no event " .. event)
            return
        end
        Lab.Fire(event, World.Expand(text), sender, "Common", channelName, target or "", "", 0, channelIndex, channelBase, 7,
            Lab.lineID, who and who.guid or "", 0, false, false, false, false)
    end

    -- What the player sends: the server answers with the same message back, as the game's server does.
    G.SendChatMessage = function(text, kind, language, target)
        kind = (kind or "SAY"):upper()
        local me = World.FullName(Lab.world.player)
        if kind == "WHISPER" then
            Lab.lineID = (Lab.lineID or 0) + 1
            Lab.Fire("CHAT_MSG_WHISPER_INFORM", text, target or "", "Common", "", me, "", 0, 0, "", 7, Lab.lineID, Lab.world.player.guid, 0, false, false, false, false)
            return
        end
        if kind == "CHANNEL" then World.Chat("CHANNEL", me, text, tonumber(target) or 1) return end
        World.Chat(kind, me, text)
    end
    G.C_ChatInfo = setmetatable({
        SendChatMessage = G.SendChatMessage,
        RegisterAddonMessagePrefix = function(prefix) Lab.prefixes = Lab.prefixes or {}; Lab.prefixes[prefix] = true; return true end,
        IsAddonMessagePrefixRegistered = function(prefix) return Lab.prefixes and Lab.prefixes[prefix] or false end,
        SendAddonMessage = function(prefix, message, kind, target)
            Lab.Note("addon", ("%s → %s: %s"):format(prefix, kind or "?", tostring(message):sub(1, 200)))
            if kind == "GUILD" or kind == "PARTY" or kind == "RAID" or kind == "OFFICER" or kind == "INSTANCE_CHAT" then
                G.C_Timer.After(0.05, function()
                    if Lab.prefixes and Lab.prefixes[prefix] then
                        Lab.Fire("CHAT_MSG_ADDON", prefix, message, kind, World.FullName(Lab.world.player), "", 0, 0, "", 0)
                    end
                end)
            end
            return 0
        end,
        GetChannelRosterInfo = function() return nil end,
        GetChatTypeName = function(id) return nil end,
        IsChatLineCensored = function() return false end,
    }, {})
    G.C_ChatInfo.SendAddonMessageLogged = G.C_ChatInfo.SendAddonMessage
    G.RegisterAddonMessagePrefix = G.C_ChatInfo.RegisterAddonMessagePrefix
    G.SendAddonMessage = G.C_ChatInfo.SendAddonMessage

    -- The world's script: chat and events at their times after the login, again every `loop` seconds if it says so.
    function World.Start()
        Lab.script = {}
        for _, e in ipairs(Lab.world.script or {}) do Lab.script[#Lab.script + 1] = { at = e.at or 0, e = e } end
        Lab.scriptStart = Lab.time
    end
    function World.Tick()
        local list = Lab.script
        if not list or #list == 0 then return end
        local t = Lab.time - Lab.scriptStart
        local keep = {}
        for _, item in ipairs(list) do
            if item.at <= t then World.Send(item.e) else keep[#keep + 1] = item end
        end
        Lab.script = keep
        if #keep == 0 and Lab.world.loop then
            Lab.scriptStart = Lab.time + Lab.world.loop
            for _, e in ipairs(Lab.world.script or {}) do Lab.script[#Lab.script + 1] = { at = e.at or 0, e = e } end
        end
    end
    function World.Send(e)
        if e.chat or e.kind then
            World.Chat(e.chat or e.kind, e.from, e.text, e.channel, e.target)
        elseif e.event then
            Lab.Fire(e.event, unpack(e.args or {}))
        elseif e.run then
            Lab.Call(e.run, G, World)
        end
    end
end
