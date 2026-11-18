local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Look out for
--  In your focus's place while you have no focus: Look out for. It rests out
--  of sight; the mouse on that place shows it. A click opens it into a field
--  that grows to the frame's width: a name, or by its + one of your group
--  (@tank, @healer, @party1-4, @raid1-40); Enter watches for it, its X stops
--  it. What is watched is looked for on the nameplates, among your group and
--  as your target, in a fight too. Once found, the place shows "Focus found:
--  Add it now", and a click on it (or its key) makes that one your focus.
--
--  The game lets no addon set a focus by itself (FocusUnit is restricted):
--  only a press on a secure button of the game's does. So the place is one
--  (SecureActionButtonTemplate) whose left click and key run a macro's text,
--  /focus [@focus,noexists] <the name or unit>, set out of a fight only: a
--  change made in one waits for its end. The game's /focus takes the name of
--  one of your group alone (FocusUnit), so a name's text goes on: where that
--  gave no focus, /targetexact the name, /focus your target, and your target
--  back as it was: the one you had (/cleartarget first, so a name not near
--  focuses nobody, then /targetlasttarget), or none (/cleartarget). Which of
--  the two a press runs, the button's own snippet picks as it is pressed, in
--  a fight too, by whether you have a target (LookOut.SNIPPET; Saneroki,
--  2026-11-09: "It doesn't add units that are not in the group"). The game
--  shows it while you have no focus and hides it while you have one, in a
--  fight too (a state driver). A right click runs nothing of the game's and
--  opens the field again.
--
--  In a fight the game hides a creature's name from addons: one found before
--  stays found while its nameplate stays, one that comes in a fight cannot be
--  told (a click still tries the name). Your group's names and roles stay
--  told; @tank and @healer are the first of your group with that role (not
--  you), looked up again as your group changes, armed out of a fight. What
--  is watched is kept per character (Core.Character: lookOut).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local LookOut = {}
ns.LookOut = LookOut

LookOut.NAME = "SaneUILookOut" -- the button's name: its key's binding clicks it (Bindings.xml)
LookOut.KEY = "Key"            -- the button a key's click comes as: it opens no field
LookOut.DRIVER = "[@focus,exists] hide; show"
LookOut.LINE = "/focus [@focus,noexists] %s" -- focuses only while you have none (the game's /focus takes a member's name)
-- After it, for a name not of your group: the target's way, your target kept (KEPT) or none again (BARE).
LookOut.KEPT = "\n/stopmacro [@focus,exists]\n/cleartarget\n/targetexact %s\n/focus [@target,exists] target\n/targetlasttarget"
LookOut.BARE = "\n/stopmacro [@focus,exists]\n/targetexact %s\n/focus [@target,exists] target\n/cleartarget"
-- As the button is pressed: the line for having a target or not, which the game's click then runs.
LookOut.SNIPPET = [[
    self:SetAttribute("macrotext", self:GetAttribute(UnitExists("target") and "sane-kept" or "sane-bare") or "")
]]
LookOut.WIDTH = 120  -- the button Look out for before it opens, in the frame's units
LookOut.OPEN = 0.15  -- seconds the field takes to grow to the frame's width
LookOut.SIDE = 18    -- its X and its +, square
LookOut.INSET = 6    -- the words' and the field's room from the ends
LookOut.ROLES = { tank = "TANK", healer = "HEALER" }

local PLATES, PARTY, RAID = {}, {}, {}
for index = 1, 40 do
    PLATES[index], RAID[index] = "nameplate" .. index, "raid" .. index
end
for index = 1, 4 do PARTY[index] = "party" .. index end

local spot, look, label, box, take, plus, grower, ear
local watched   -- what is watched: { text, name } or { text, role } or { text, unit }; nil for nothing
local found     -- the unit token it was found as, or nil
local wanted = "" -- the macro's text for what is watched now, with a target (a unit's: its one line)
local bare = ""   -- and without one
local armed = ""  -- the text on the button (out of a fight only)
local hover = false

-- What a text watches: a role of your group ({ role = "TANK" }), one of your group ({ unit = "party2" }), or a name
-- ({ name }); nil for nothing. Brackets and semicolons are no part of a name: they would change the macro's line.
function LookOut.Parse(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("[%[%];\r\n]", ""):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    local word = text:lower():match("^@(%w+)$")
    if word then
        if LookOut.ROLES[word] then return { text = "@" .. word, role = LookOut.ROLES[word] } end
        local kind, number = word:match("^(%a+)(%d+)$")
        number = tonumber(number)
        if number and ((kind == "party" and number <= 4) or (kind == "raid" and number <= 40)) and number >= 1 then
            return { text = "@" .. word, unit = word }
        end
    end
    local name = text:gsub("^@", "")
    if name == "" then return nil end
    return { text = name, name = name }
end

-- Your group's units in the game's order: a raid's, else your party's.
local function Group()
    return Core.Ask(IsInRaid) and RAID or PARTY
end

-- The first of your group with that role, not you; nil for none.
local function Resolve(role)
    for _, unit in ipairs(Group()) do
        if Core.Ask(UnitExists, unit) and not Core.Ask(UnitIsUnit, unit, "player")
            and Core.Ask(rawget(_G, "UnitGroupRolesAssigned"), unit) == role then
            return unit
        end
    end
    return nil
end

-- Whether a unit is the one watched by name: true, false, or nil while the game hides its name.
local function Matches(unit, name)
    if Core.Ask(UnitExists, unit) ~= true then return false end
    local ok, own = pcall(UnitName, unit)
    if not ok then return false end
    if Core.Secret(own) then return nil end
    if type(own) ~= "string" then return false end
    name = name:lower()
    if own:lower() == name then return true end
    local full = Core.FullName(unit)
    return full ~= nil and full:lower() == name
end

-- Where a name is now: a nameplate first (its token stays the same unit while it shows), then your group, then your
-- target; nil where none is, or none can be told.
local function Find(name)
    for _, unit in ipairs(PLATES) do
        if Matches(unit, name) then return unit end
    end
    for _, unit in ipairs(Group()) do
        if Matches(unit, name) then return unit end
    end
    if Matches("target", name) then return "target" end
    return nil
end

-- Whether the button holds the line for what is watched now (a change in a fight waits for its end).
local function Current()
    return armed == wanted
end

-- What the place says now.
local function Words()
    if not watched then return ns.TEXT.lookOut end
    if not Current() then return ns.TEXT.lookOutLater:format(watched.text) end
    if found then return ns.TEXT.lookOutFound end
    if watched.name and InCombatLockdown() then return ns.TEXT.lookOutTry:format(watched.text) end
    return ns.TEXT.lookOutWatching:format(watched.text)
end

-- The place as things are: its words, how wide it is (the button Look out for, else the frame's width), gold around
-- it while found; in sight while found, open or under the mouse.
local function Paint()
    if not spot then return end
    local hit = watched ~= nil and found ~= nil and Current()
    label:SetText(Words())
    local colour = rawget(_G, watched and "HIGHLIGHT_FONT_COLOR" or "NORMAL_FONT_COLOR")
    if type(colour) == "table" and colour.r then label:SetTextColor(colour.r, colour.g, colour.b) end
    label:SetShown(not look.opened)
    if not look.opened then look:SetWidth(watched and ns.Units.WIDTH or LookOut.WIDTH) end
    local edge = hit and ns.UnitBar.RANKS.elite.colour or ns.UnitBar.BORDER
    look.border:SetVertexColor(edge[1], edge[2], edge[3], edge[4] or 1)
    spot:SetAlpha((hit or look.opened or hover) and 1 or 0)
end
LookOut.Paint = Paint

-- The macro's texts for a target (a unit, a name): with a target of yours and without one. A unit of your group, or
-- a role's, is focused by its token alone; a name the game's /focus may not know (one not of your group) by your
-- target too.
function LookOut.Lines(target, named)
    if not target then return "", "" end
    local line = LookOut.LINE:format(target)
    if not named then return line, line end
    return line .. LookOut.KEPT:format(target), line .. LookOut.BARE:format(target)
end

-- Where what is watched is now, and the texts it wants; painted.
local function Look()
    local target
    if watched then target = watched.role and Resolve(watched.role) or watched.unit or watched.name end
    wanted, bare = LookOut.Lines(target, watched ~= nil and watched.name ~= nil)
    if not watched then
        found = nil
    elseif watched.name then
        -- One found stays found while the game hides its name (a fight); one it says is another is looked for anew.
        if not (found and Matches(found, watched.name) ~= false) then found = Find(watched.name) end
    else
        found = target and Core.Ask(UnitExists, target) == true and target or nil
    end
    Paint()
end
LookOut.Look = Look

-- The button's line for what is watched now, and the edge the game's key-down setting says. Out of a fight.
local function Arm()
    if not spot then return end
    Look()
    armed = wanted
    spot:SetAttribute("sane-kept", wanted)
    spot:SetAttribute("sane-bare", bare)
    spot:SetAttribute("macrotext", armed)
    spot:SetAttribute("useOnKeyDown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
    Paint()
end

local function Later()
    Core.AfterCombat("look out", Arm)
end

-- The events that tell where it is: only while something is watched (the focus and the fight always, for the looks).
local function Listen()
    ear:UnregisterAllEvents()
    for _, event in ipairs({ "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        ear:RegisterEvent(event)
    end
    if not watched then return end
    for _, event in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_TARGET_CHANGED",
                             "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "CVAR_UPDATE" }) do
        pcall(ear.RegisterEvent, ear, event)
    end
end

local function Heard(_, event, unit)
    if ns.off or not spot then return end
    if event == "NAME_PLATE_UNIT_ADDED" then
        if watched and watched.name and not found and Matches(unit, watched.name) then found = unit end
        return Paint()
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if found ~= unit then return end
        found = nil
    elseif event == "PLAYER_TARGET_CHANGED" then
        if found == "target" then found = nil end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
        if found and (found:find("^party") or found:find("^raid")) then found = nil end
        Later()
    elseif event == "CVAR_UPDATE" then
        if unit == "ActionButtonUseKeyDown" then Later() end
        return
    elseif event == "PLAYER_FOCUS_CHANGED" then
        if Core.Ask(UnitExists, "focus") then LookOut.Close() end
        return Paint()
    end
    Look() -- and after a fight: the names told again
end

-- The field grown to the frame's width, eased, then still.
local function Grow(self, elapsed)
    self.spent = self.spent + elapsed
    local share = math.min(self.spent / LookOut.OPEN, 1)
    local eased = 1 - (1 - share) * (1 - share)
    look:SetWidth(self.from + (self.to - self.from) * eased)
    if share >= 1 then self:Hide() end
end

-- The field open: what is watched in it, marked, to be typed over; it grows from the button's width.
function LookOut.Open()
    if not spot then return end
    if not look.opened then
        look.opened = true
        box:SetText(watched and watched.text or "")
        box:Show()
        take:Show()
        plus:Show()
        grower.from, grower.to, grower.spent = Plain(look:GetWidth()) or LookOut.WIDTH, ns.Units.WIDTH, 0
        grower:Show()
    end
    box:SetFocus()
    box:HighlightText()
    Paint()
end

-- The field closed, nothing changed.
function LookOut.Close()
    if not spot or not look.opened then return end
    look.opened = false
    grower:Hide()
    box:ClearFocus()
    box:Hide()
    take:Hide()
    plus:Hide()
    Paint()
end

-- Watch for a text from now on (nil: stop), kept for the character; the button takes it now or at the fight's end.
function LookOut.Watch(text)
    watched = LookOut.Parse(text)
    Core.Character(ns.name).lookOut = watched and watched.text or nil
    found = nil
    if spot then
        LookOut.Close()
        Listen()
        Look()
        Later()
    end
end

-- A click: the game ran the line already (the left button, a key). The right button, or the left while nothing is
-- found, opens the field; a key's click never does.
local function Clicked(_, button, down)
    if down or button == LookOut.KEY then return end
    if button == "RightButton" or not (found and Current()) then LookOut.Open() end
end

local function Instruction(text)
    local add = rawget(_G, "GameTooltip_AddInstructionLine")
    if add then return add(GameTooltip, text) end
    GameTooltip:AddLine(text, 0.1, 1, 0.1, true)
end

local function Entered(self)
    hover = true
    Paint()
    if not watched or look.opened then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.TEXT.lookOutWatching:format(watched.text), 1, 1, 1, 1, true)
    Instruction(found and ns.TEXT.lookOutClick or ns.TEXT.lookOutTryClick)
    Instruction(ns.TEXT.lookOutRight)
    GameTooltip:Show()
end

local function Left()
    hover = false
    GameTooltip:Hide()
    Paint()
end

-- The + : a role or a member of your group, watched at once.
local function Menu(owner)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(ns.TEXT.lookOutGroup)
        root:CreateButton(ns.TEXT.lookOutTank, ns.Guard(function() LookOut.Watch("@tank") end))
        root:CreateButton(ns.TEXT.lookOutHealer, ns.Guard(function() LookOut.Watch("@healer") end))
        local party = root:CreateButton(ns.TEXT.lookOutParty)
        for index = 1, #PARTY do
            party:CreateButton("@" .. PARTY[index], ns.Guard(function() LookOut.Watch("@" .. PARTY[index]) end))
        end
        local raid = root:CreateButton(ns.TEXT.lookOutRaid)
        local grid = rawget(_G, "MenuConstants")
        if raid.SetGridMode and grid then raid:SetGridMode(grid.VerticalGridDirection, 4) end
        for index = 1, #RAID do
            raid:CreateButton("@" .. RAID[index], ns.Guard(function() LookOut.Watch("@" .. RAID[index]) end))
        end
        -- Closed with nothing picked: back to typing.
        if root.AddMenuReleasedCallback then
            root:AddMenuReleasedCallback(ns.Guard(function() if look.opened then box:SetFocus() end end))
        end
    end))
end

local function Tip(button, text)
    button:SetScript("OnEnter", ns.Guard(function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end))
    button:SetScript("OnLeave", GameTooltip_Hide)
end

-- The place: the game's secure button over your focus's health bar, the look of a frame on it (its outline and
-- dark, the plates' font), the field with its + and X in it.
local function Make(anchor)
    local Bar, Text = ns.UnitBar, ns.UnitText
    ear = CreateFrame("Frame") -- first: what follows may fail, and standing down then stops its events
    ear:SetScript("OnEvent", ns.Guard(Heard))
    spot = CreateFrame("Button", LookOut.NAME, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    spot:SetFrameStrata("LOW")
    spot:SetPoint("TOPLEFT", anchor, "TOPLEFT")
    spot:SetPoint("TOPRIGHT", anchor, "TOPRIGHT")
    spot:SetHeight(ns.Units.HEIGHT)
    spot:RegisterForClicks("AnyUp", "AnyDown") -- a key's edge as the game's setting says; the mouse's always its release
    spot:SetAttribute("*type1", "macro")
    spot:SetAttribute("*type-" .. LookOut.KEY, "macro")
    spot:SetAttribute("macrotext", "")
    -- The text for having a target or not, as it is pressed; where the game's template gives no wrap, the text for one.
    if type(spot.WrapScript) == "function" then spot:WrapScript(spot, "OnClick", LookOut.SNIPPET) end
    spot:SetScript("PostClick", ns.Guard(Clicked))
    spot:SetScript("OnEnter", ns.Guard(Entered))
    spot:SetScript("OnLeave", ns.Guard(Left))
    spot:HookScript("OnHide", ns.Guard(function() hover = false end)) -- you got a focus: the mouse is no longer on it
    spot:SetAlpha(0)
    spot:Hide()
    local level = Plain(spot:GetFrameLevel()) or 1
    look = CreateFrame("Frame", nil, spot)
    look:SetPoint("TOPLEFT", spot, "TOPLEFT")
    look:SetSize(LookOut.WIDTH, ns.Units.HEIGHT)
    look:SetFrameLevel(level + 1)
    look.border = Bar.Plate(look, -4)
    look.fill = Bar.Plate(look, -3)
    look.fill:SetVertexColor(unpack(Bar.BACKGROUND))
    label = Text.Line(look, "CENTER")
    label:SetPoint("LEFT", look, "LEFT", LookOut.INSET, 0)
    label:SetPoint("RIGHT", look, "RIGHT", -LookOut.INSET, 0)
    grower = CreateFrame("Frame", nil, look)
    grower:Hide()
    grower:SetScript("OnUpdate", ns.Guard(Grow))
    take = CreateFrame("Button", nil, look, "UIPanelCloseButton")
    take:SetFrameLevel(level + 2) -- the template stands high
    take:SetSize(LookOut.SIDE, LookOut.SIDE)
    take:SetPoint("RIGHT", look, "RIGHT", -2, 0)
    take:SetScript("OnClick", ns.Guard(function() LookOut.Watch(nil) end))
    Tip(take, ns.TEXT.lookOutStop)
    plus = CreateFrame("Button", nil, look)
    plus:SetFrameLevel(level + 2)
    plus:SetSize(LookOut.SIDE, LookOut.SIDE)
    plus:SetPoint("RIGHT", take, "LEFT", 0, 0)
    local art = ns.AuraLists.PLUS_ART
    plus:SetNormalTexture(art.up)
    plus:SetPushedTexture(art.down)
    plus:SetHighlightTexture(art.lit, "ADD")
    plus:SetScript("OnClick", ns.Guard(Menu))
    Tip(plus, ns.TEXT.lookOutGroup)
    box = CreateFrame("EditBox", nil, look)
    box:SetFrameLevel(level + 2)
    box:SetAutoFocus(false)
    box:SetPoint("TOPLEFT", look, "TOPLEFT", LookOut.INSET, 0)
    box:SetPoint("BOTTOMRIGHT", look, "BOTTOMRIGHT", -(2 * LookOut.SIDE + 4), 0)
    local font = Text.Font()
    local object = rawget(_G, font.name or "GameFontHighlightSmall")
    if object then box:SetFontObject(object) end
    if font.file then box:SetFont(font.file, Text.SIZE, font.flags) end
    box:SetTextColor(1, 1, 1)
    box:SetScript("OnEnterPressed", ns.Guard(function(self) LookOut.Watch(self:GetText()) end))
    box:SetScript("OnEscapePressed", ns.Guard(LookOut.Close))
    -- Gone from the field to something else: closed, unless the mouse is on it (its + or X take the click first).
    box:SetScript("OnEditFocusLost", ns.Guard(function()
        if Plain(look:IsMouseOver()) ~= true then LookOut.Close() end
    end))
    Core.Caret(box)
    box:Hide()
    take:Hide()
    plus:Hide()
    spot.look = look -- its parts, for the tests
    look.label, look.box, look.take, look.plus, look.grower = label, box, take, plus, grower
end

-- The outline round as the frames' are, a screen pixel each, at the size the frame shows at.
local function Fit()
    local Bar, height = ns.UnitBar, ns.Units.HEIGHT
    local pixel = Core.Pixels(look, 1)
    local radius = height * Bar.CAP
    Bar.Around(look.border, look, 0, height, 0, 0, radius)
    Bar.Around(look.fill, look, -pixel, height, 0, 0, radius)
end

-- Out of sight and nothing on the button. Out of a fight.
local function Off()
    if not spot then return end
    UnregisterStateDriver(spot, "visibility")
    spot:Hide()
    armed = ""
    spot:SetAttribute("sane-kept", "")
    spot:SetAttribute("sane-bare", "")
    spot:SetAttribute("macrotext", "")
    ear:UnregisterAllEvents()
    LookOut.Close()
end

-- As the settings say: on while your focus's frame is ours and Look out for is on; out of sight in Edit Mode (the
-- focus's frame shows there). Out of a fight (Units' Apply).
function LookOut.Apply()
    local kind
    for _, each in ipairs(ns.Units.KINDS) do
        if each.unit == "focus" then kind = each end
    end
    local options = ns.options or {}
    if ns.off or not kind or not kind.button or options.units == false or options.unitFocus == false
        or options.unitLookOut == false then
        return Off()
    end
    if not spot then Make(kind.button) end
    spot:SetScale(Plain(kind.button:GetScale()) or 1)
    Fit()
    watched = LookOut.Parse(Core.Character(ns.name).lookOut)
    Listen()
    Arm()
    if Core.EditMode.active then
        UnregisterStateDriver(spot, "visibility")
        spot:Hide()
    else
        RegisterStateDriver(spot, "visibility", LookOut.DRIVER)
    end
end

-- Standing down: out of sight at once (its alpha may change in a fight), off after it.
function LookOut.GiveBack()
    if not spot then return end
    spot:SetAlpha(0)
    ear:UnregisterAllEvents()
    LookOut.Close()
    Core.AfterCombat("look out", Off)
end

-- For the tests: what is watched, where it was found, the text on the button and the one it wants (with a target;
-- then without one).
function LookOut.State()
    return watched, found, armed, wanted, spot, bare
end

_G["BINDING_NAME_CLICK " .. LookOut.NAME .. ":" .. LookOut.KEY] = ns.TEXT.lookOutKey
