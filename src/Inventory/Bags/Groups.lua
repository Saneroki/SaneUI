local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Groups
--  The groups the bag window shows its items in, as the player arranged them,
--  without a frame: the game's groups (Contents.GROUPS) and the player's own,
--  in the player's order, renamed, hidden or joined into another; which
--  group an item is in; the pinned items; what is junk.
--
--  Pinned and New stay at the top, in that order, and are not changed by
--  the player. Every other group can be renamed (an empty name gives a
--  group of the game's its own back), moved up or down past the groups shown,
--  and hidden (its items left out of the views with groups, until a search
--  finds them). A group of the game's can be joined into another (its items
--  shown there, its head gone) and taken out again; Junk is never joined
--  and never takes another in. The player's own groups are made, named and
--  deleted by the player; an item is put into one (or into a group of the
--  game's other than its own, or into Junk) and taken out again. A pinned
--  item shows in Pinned whatever group it is in. Junk is what is in the
--  group Junk and has a price, unless it is pinned: it is sold with the
--  junk. So an item is marked as junk by putting it into Junk, and a grey
--  item the game counts as junk is unmarked by putting it into the group of
--  its kind.
--
--  What the player chose is kept in the module's store (store.bags, the
--  window's: Groups.Use), by item ID, never trusted as it comes (Groups.Check):
--      pinned  { [item] = true }
--      put     { [item] = key }      an item put into a group not its own
--      groups  { [key] = { word, hidden, into, own } }
--                                    the player's own groups (own), and what
--                                    the player changed of the game's
--      ranks   { key, ... }          the groups in the player's order (nil:
--                                    the game's order, the player's own last)
-------------------------------------------------------------------------------
local Groups = {}
ns.Groups = Groups

Groups.PINNED, Groups.NEW, Groups.JUNK = "pinned", "new", "junk"
Groups.FIXED = { pinned = true, new = true } -- at the top, as they are
Groups.LETTERS = 32                          -- the most a group's name may have

local Contents = ns.Contents
local kept = {}
local list, rank = {}, {} -- the groups in the order shown; [key] = its place in it
Groups.list, Groups.rank = list, rank

-------------------------------------------------------------------------------
--  What is kept
-------------------------------------------------------------------------------
local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

-- Saved data comes from older versions and from hand edits: what is not of the right kind goes.
function Groups.Check(bags)
    local pinned, put, groups = Table(bags, "pinned"), Table(bags, "put"), Table(bags, "groups")
    for item, on in pairs(pinned) do
        if type(item) ~= "number" or on ~= true then pinned[item] = nil end
    end
    for item, key in pairs(put) do
        if type(item) ~= "number" or type(key) ~= "string" then put[item] = nil end
    end
    for key, group in pairs(groups) do
        local fine = type(key) == "string" and type(group) == "table" and not Groups.FIXED[key]
            and (group.own == true or Contents.GROUP[key] ~= nil)
        if fine then
            if type(group.word) ~= "string" or group.word == "" then group.word = group.own and ns.TEXT.bagsGroup or nil end
            if group.hidden ~= true then group.hidden = nil end
            if type(group.into) ~= "string" or group.own or key == Groups.JUNK then group.into = nil end
            if group.own ~= true then group.own = nil end
        else
            groups[key] = nil
        end
    end
    if type(bags.ranks) ~= "table" then
        bags.ranks = nil
    else
        for index = #bags.ranks, 1, -1 do
            if type(bags.ranks[index]) ~= "string" then table.remove(bags.ranks, index) end
        end
    end
    return bags
end

-- The player's choices from now on (store.bags), checked; the groups put in order.
function Groups.Use(bags)
    kept = Groups.Check(bags)
    Groups.Arrange()
end

-- A group there is: one of the game's, or one of the player's own.
local function Known(key)
    if Contents.GROUP[key] then return true end
    local group = kept.groups and kept.groups[key]
    return group ~= nil and group.own == true
end

local function Add(key)
    list[#list + 1] = key
    rank[key] = #list
end

-- The groups in the order shown: Pinned and New, then the player's order, then the groups not in it yet (the
-- game's in their order, the player's own by when they were made).
function Groups.Arrange()
    for index = #list, 1, -1 do list[index] = nil end
    for key in pairs(rank) do rank[key] = nil end
    Add(Groups.PINNED)
    Add(Groups.NEW)
    for _, key in ipairs(kept.ranks or {}) do
        if Known(key) and not rank[key] then Add(key) end
    end
    for _, group in ipairs(Contents.GROUPS) do
        if not rank[group.key] then Add(group.key) end
    end
    local own = {}
    for key, group in pairs(kept.groups or {}) do
        if group.own and not rank[key] then own[#own + 1] = key end
    end
    table.sort(own, function(a, b) return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0) end)
    for _, key in ipairs(own) do Add(key) end
end

-------------------------------------------------------------------------------
--  A group
-------------------------------------------------------------------------------
local function Entry(key) return kept.groups and kept.groups[key] end

-- The name a group is shown by: the player's, else the game's.
function Groups.Word(key)
    local group = Entry(key)
    if group and group.word then return group.word end
    local game = Contents.GROUP[key]
    return game and game.word or ""
end

-- Whether a group is one of the player's own.
function Groups.Own(key)
    local group = Entry(key)
    return group ~= nil and group.own == true
end

function Groups.Hidden(key)
    local group = Entry(key)
    return group ~= nil and group.hidden == true
end

-- The group a group of the game's is joined into (nil: none).
function Groups.Into(key)
    local group = Entry(key)
    local into = group and group.into
    if not into or into == key or Groups.FIXED[into] or into == Groups.JUNK or not Known(into) then return nil end
    return into
end

-- The group whose head shows a group's items: itself, or the one it is joined into (and so on, never round).
function Groups.Shown(key)
    for _ = 1, #list do
        local into = Groups.Into(key)
        if not into or into == key then return key end
        key = into
    end
    return key
end

-- Whether items can be put into a group: not Pinned or New (those have their own ways), not Junk (an item is
-- marked as junk), not one joined into another.
function Groups.Takes(key)
    return Known(key) and not Groups.FIXED[key] and key ~= Groups.JUNK and not Groups.Into(key)
end

-- Whether a group can be joined into another: a group of the game's but Junk, shown by itself.
function Groups.Joins(key)
    return Contents.GROUP[key] ~= nil and not Groups.FIXED[key] and key ~= Groups.JUNK and not Groups.Into(key)
end

-- Whether a group can take another in: neither itself, nor Pinned, New or Junk, nor joined into another.
function Groups.TakesIn(key, other)
    return key ~= other and Known(key) and not Groups.FIXED[key] and key ~= Groups.JUNK and not Groups.Into(key)
end

local function Edit(key)
    local groups = kept.groups
    local group = groups[key]
    if not group then
        group = {}
        groups[key] = group
    end
    return group
end

-- A group's entry gone once nothing of the game's group is changed any more.
local function Tidy(key)
    local group = kept.groups[key]
    if group and not group.own and not group.word and not group.hidden and not group.into then kept.groups[key] = nil end
end

local function Trim(text)
    return type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
end

-- A group named anew; for one of the game's an empty name (or the game's own) gives the game's back.
function Groups.Rename(key, text)
    if not Known(key) or Groups.FIXED[key] then return false end
    text = Trim(text)
    if Groups.Own(key) then
        if text == "" then return false end
        kept.groups[key].word = text
        return true
    end
    local game = Contents.GROUP[key].word
    Edit(key).word = text ~= "" and text ~= game and text or nil
    Tidy(key)
    return true
end

-- A group hidden or shown again.
function Groups.Hide(key, on)
    if not Known(key) or Groups.FIXED[key] then return false end
    Edit(key).hidden = on and true or nil
    Tidy(key)
    return true
end

-- A group of the game's joined into another (into nil: shown by itself again).
function Groups.Join(key, into)
    if into ~= nil and not (Groups.Joins(key) and Groups.TakesIn(into, key)) then return false end
    if into == nil and not Entry(key) then return false end
    Edit(key).into = into
    Tidy(key)
    Groups.Arrange()
    return true
end

-- The groups that may be moved, in their order (all but Pinned and New).
local function Movable()
    local order = {}
    for _, key in ipairs(list) do
        if not Groups.FIXED[key] then order[#order + 1] = key end
    end
    return order
end

-- A group moved up (step -1) or down (1), past the next group shown (shown: [key] = true; nil: every group);
-- dry: only whether it can.
function Groups.Move(key, step, shown, dry)
    local order = Movable()
    local at
    for index, other in ipairs(order) do
        if other == key then at = index end
    end
    if not at then return false end
    local to = at + step
    while order[to] and shown and not shown[order[to]] do to = to + step end
    if not order[to] then return false end
    if dry then return true end
    table.remove(order, at)
    table.insert(order, to, key)
    kept.ranks = order
    Groups.Arrange()
    return true
end

-- A group of the player's own made, at the top under New; returns its key (nil: no name).
function Groups.New(text)
    text = Trim(text)
    if text == "" then return nil end
    local number = 0
    for key in pairs(kept.groups) do
        number = math.max(number, tonumber(type(key) == "string" and key:match("^own(%d+)$")) or 0)
    end
    local key = "own" .. (number + 1)
    kept.groups[key] = { own = true, word = text }
    local order = Movable()
    table.insert(order, 1, key)
    kept.ranks = order
    Groups.Arrange()
    return key
end

-- A group of the player's own deleted: its items back in their own groups, the groups joined into it by
-- themselves again.
function Groups.Delete(key)
    if not Groups.Own(key) then return false end
    kept.groups[key] = nil
    for item, into in pairs(kept.put) do
        if into == key then kept.put[item] = nil end
    end
    for other, group in pairs(kept.groups) do
        if group.into == key then
            group.into = nil
            Tidy(other)
        end
    end
    if kept.ranks then
        for index = #kept.ranks, 1, -1 do
            if kept.ranks[index] == key then table.remove(kept.ranks, index) end
        end
    end
    Groups.Arrange()
    return true
end

-------------------------------------------------------------------------------
--  An item
-------------------------------------------------------------------------------
function Groups.Pinned(item)
    return item ~= nil and kept.pinned ~= nil and kept.pinned[item] == true
end

function Groups.Pin(item, on)
    if type(item) ~= "number" then return false end
    kept.pinned[item] = on and true or nil
    return true
end

-- The group an item is in: the one the player put it into, else its own (natural: the game's, Contents).
function Groups.Home(item, natural)
    local key = item and kept.put and kept.put[item]
    if key and Known(key) and not Groups.FIXED[key] then return key end
    return natural
end

-- The group the player put an item into (nil: none, it is in its own).
function Groups.Put(item)
    return item and kept.put and kept.put[item] or nil
end

-- An item put into a group (nil, or its own group: taken out again); it is pinned no more. Into Pinned:
-- pinned.
function Groups.PutInto(item, key, natural)
    if type(item) ~= "number" then return false end
    if key == Groups.PINNED then return Groups.Pin(item, true) end
    if key ~= nil and (not Known(key) or Groups.FIXED[key]) then return false end
    kept.put[item] = key ~= natural and key or nil
    kept.pinned[item] = nil
    return true
end

-- An item marked as junk, or unmarked: put into Junk, or into the group of its kind (classed: the group it
-- would be in if it were not grey).
function Groups.MarkJunk(item, on, natural, classed)
    return Groups.PutInto(item, on and Groups.JUNK or classed, natural)
end

Groups.Use({})
