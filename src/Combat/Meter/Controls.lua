local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Meter - Controls
--  What stands at the right end of the first line while the mouse is on the
--  meter, and nothing of it otherwise, from the left:
--      < 3 >    the arrows page through the fights, the number the page
--      note     the flyout Saved fights: this fight saved under a name of your own, each
--               saved fight to load or delete
--      cog      the flyout with the ticks, and Order by, a flyout of its own; under them when it shows
--  A right click on a name opens that character's own flyout: which bars they have, whatever the window's ticks say.
--  The flyouts are the game's menus (Blizzard_Menu).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Controls = {}
ns.MeterControls = Controls

Controls.SIZE = 16                -- a button, square
Controls.CROP = 0.16              -- the empty rim of the arrows' art, cut off so the arrow fills its button
Controls.PAGE = 20                -- the page's number
Controls.WIDTH = 4 * Controls.SIZE + Controls.PAGE + 2 -- all of it; the first line's name stays out of there
Controls.COG = "questlog-icon-setting"
Controls.NOTE = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up"
Controls.PREVIOUS = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-"
Controls.NEXT = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
Controls.TICKS = { "meterMine", "meterThreat", "meterDamage", "meterHealing", "meterInterrupts", "meterReset" } -- their order
Controls.WHEN = { "meterHideRest", "meterHideAlone", "meterHover" } -- the ticks under When it shows
Controls.LETTERS = 60             -- the most a saved fight's name can have

local frame, back, on, number, menu
local chosen -- the character whose flyout is open

-- The ticks' and the order's settings go through Core: told to the module (Combat.lua's changed), kept.
local IsOn = ns.Guard(function(key) return ns.options[key] and true or false end)
local Flip = ns.Guard(function(key) Core.Set(ns.name, key, not ns.options[key]) end)
local IsOrder = ns.Guard(function(key) return ns.options.meterOrder == key end)
local SetOrder = ns.Guard(function(key) Core.Set(ns.name, "meterOrder", key) end)

local Saved = ns.Guard(function(name) ns.MeterFights.Save(name) end)
local Ask = ns.Guard(function()
    Core.AskText(ns.TEXT.meterSaveAsk, nil, Core.Word("SAVE", "Save"), ns.MeterFights.Suggest(), Saved, Controls.LETTERS)
end)
local Load = ns.Guard(function(record)
    ns.MeterFights.Load(record)
    ns.Meter.Refresh()
end)
local Unload = ns.Guard(function()
    ns.MeterFights.Unload()
    ns.Meter.Refresh()
end)
local Delete = ns.Guard(function(record)
    ns.MeterFights.Delete(record)
    ns.Meter.Refresh()
end)

local function Ticks(_, root)
    for _, key in ipairs(Controls.TICKS) do
        root:CreateCheckbox(ns.TEXT.meterTicks[key], IsOn, Flip, key)
    end
    local order = root:CreateButton(ns.TEXT.meterOrder)
    for _, each in ipairs(ns.MeterRead.ORDERS) do
        order:CreateRadio(each.text, IsOrder, SetOrder, each.key):SetResponse(MenuResponse.Refresh)
    end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.meterWhen)
    for _, key in ipairs(Controls.WHEN) do
        root:CreateCheckbox(ns.TEXT.meterTicks[key], IsOn, Flip, key)
    end
end

-- One character's own bars: what the checkbox shows is what they have.
local Has = ns.Guard(function(kind) return ns.MeterShows.Is(chosen, kind) end)
local Toggle = ns.Guard(function(kind)
    ns.MeterShows.Flip(chosen, kind)
    ns.Meter.Refresh()
end)
local AsWindow = ns.Guard(function()
    ns.MeterShows.Clear(chosen)
    ns.Meter.Refresh()
end)

local Character = ns.Guard(function(_, root)
    root:CreateTitle(chosen.name)
    for _, each in ipairs(ns.MeterShows.KINDS) do
        root:CreateCheckbox(ns.TEXT.meterTicks[each.tick], Has, Toggle, each.kind)
    end
    if ns.MeterShows.Own(chosen) then root:CreateButton(ns.TEXT.meterAsWindow, AsWindow) end
end)

-- That character's own flyout, from a right click on their name.
function Controls.Character(owner, person)
    chosen = person
    menu = MenuUtil.CreateContextMenu(owner, Character)
end

local function Fights(_, root)
    if ns.MeterFights.Loaded() then root:CreateButton(ns.TEXT.meterBack, Unload) end
    root:CreateButton(ns.TEXT.meterSave, Ask)
    local list = ns.MeterFights.List()
    if #list > 0 then root:CreateTitle(ns.TEXT.meterSavedFights) end
    for index = #list, 1, -1 do
        local record = list[index]
        local entry = root:CreateButton(record.name)
        entry:CreateButton(ns.TEXT.meterLoad, Load, record)
        entry:CreateButton(Core.Word("DELETE", "Delete"), Delete, record)
    end
end

local function Opens(generator)
    generator = ns.Guard(generator)
    return function(button) menu = MenuUtil.CreateContextMenu(button, generator) end
end

local function Icon(atlas, texture, tip, tipMore, click)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(Controls.SIZE, Controls.SIZE)
    if atlas then button:SetNormalAtlas(atlas) else button:SetNormalTexture(texture) end
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetScript("OnClick", ns.Guard(click))
    Core.Tip(button, tip, tipMore)
    return button
end

local function Arrow(art, tip, step)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(Controls.SIZE, Controls.SIZE)
    button:SetNormalTexture(art .. "Up")
    button:SetPushedTexture(art .. "Down")
    button:SetDisabledTexture(art .. "Disabled")
    for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetDisabledTexture() }) do
        texture:SetTexCoord(Controls.CROP, 1 - Controls.CROP, Controls.CROP, 1 - Controls.CROP)
    end
    button:SetScript("OnClick", ns.Guard(function()
        ns.MeterFights.Step(step)
        ns.Meter.Refresh()
    end))
    Core.Tip(button, tip)
    return button
end

-- The page's tooltip: the fight's name and how long it took.
local function About()
    local name, seconds = ns.MeterFights.About()
    if not seconds then return name or ns.TEXT.meterFight end
    return ns.TEXT.meterAbout:format(name or ns.TEXT.meterFight, seconds / 60, seconds % 60)
end

-- Made once with the meter's window; parent: what its first line stands in.
function Controls.Build(parent)
    frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(Controls.WIDTH, Controls.SIZE)
    frame:SetPoint("TOPRIGHT")
    frame:SetFrameLevel(parent:GetFrameLevel() + 20) -- over the rows
    local cog = Icon(Controls.COG, nil, ns.TEXT.meterTicksTip, nil, Opens(Ticks))
    cog:SetPoint("RIGHT")
    local note = Icon(nil, Controls.NOTE, ns.TEXT.meterSavedFights, ns.TEXT.meterSavedTip, Opens(Fights))
    note:SetPoint("RIGHT", cog, "LEFT", -1, 0)
    on = Arrow(Controls.NEXT, ns.TEXT.meterNext, 1)
    on:SetPoint("RIGHT", note, "LEFT", -1, 0)
    local page = CreateFrame("Frame", nil, frame)
    page:SetSize(Controls.PAGE, Controls.SIZE)
    page:SetPoint("RIGHT", on, "LEFT")
    number = page:CreateFontString(nil, "OVERLAY", ns.MeterRow.FONT)
    number:SetAllPoints()
    Core.Tip(page, About)
    back = Arrow(Controls.PREVIOUS, ns.TEXT.meterPrevious, -1)
    back:SetPoint("RIGHT", page, "LEFT")
    frame:Hide()
    return frame
end

-- The arrows and the page's number as the fights are now.
function Controls.Page()
    if not frame then return end
    local page, count = ns.MeterFights.Page()
    local saved = ns.MeterFights.Loaded()
    number:SetText(saved and "-" or page)
    back:SetEnabled(saved or page > 1)
    on:SetEnabled(saved or page < count)
end

-- Seen (on) or not.
function Controls.Show(shown)
    if frame then frame:SetShown(shown) end
end

-- Whether a flyout is open: the buttons stay while it is.
function Controls.Open()
    return menu ~= nil and menu:IsShown()
end
