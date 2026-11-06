local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Menu
--  The module's lines in the spellbook's own options menu (the small arrow at
--  the top right of the spellbook).
--
--  Menu.ModifyMenu is the game's own door for this: an addon may append lines
--  to a menu without its code mixing with the game's lines above them. The
--  same lines go into another book's menu through Core (ns.BookMenu, Offer.lua:
--  Combat's spellbook), there without the two that are the game's book's alone.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local TEXT = ns.TEXT

local function Option(key)
    return ns.options[key] and true or false
end

-- The game's menu asks a line whether it is enabled and for its tooltip while the menu is open:
-- those functions are guarded, and made once, not at every opening of the menu.
local tooltips = {} -- [switch] = the tooltip of its line

-- One of the module's switches as a line of the menu, with the words of the options page.
-- A click sets it through Core (Core.Set): the module hears it as from the options page (its
-- changed redraws), and an open options page shows it too.
-- enabled: a function; while it says no, the line is greyed out and its tooltip says why (the
-- game's own lines in this menu do the same while a search is on).
local function Checkbox(root, key, enabled)
    local option = Core.Described(ns.name, key)
    local text, tip = option.text, option.tip
    local box = root:CreateCheckbox(text, ns.Guard(function() return Option(key) end), ns.Guard(function()
        Core.Set(ns.name, key, not Option(key))
    end))
    if not box then return box end
    if enabled and box.SetEnabled then box:SetEnabled(enabled) end
    if box.SetTooltip then
        local made = enabled and key or key .. "/always" -- a line that waits for nothing says no reason why
        tooltips[made] = tooltips[made] or ns.Guard(function(tooltip)
            GameTooltip_SetTitle(tooltip, text)
            if tip then GameTooltip_AddNormalLine(tooltip, tip) end
            if enabled and not enabled() then
                GameTooltip_AddErrorLine(tooltip, TEXT.pagesGame:format(ns.Book.Why() or ""))
            end
        end)
        box:SetTooltip(tooltips[made])
    end
    return box
end

local function Refresh()
    ns.Fire("REFRESH")
end

-- The four switches about the book do nothing while its pages are the game's.
local PagesOurs = ns.Guard(function()
    return ns.Book.Armed()
end)

-- The line the module adds for warriors and rogues (below), under the game's own words for it.
local ALL_RANKS = Core.Word("SHOW_ALL_SPELL_RANKS", TEXT.allRanks)
local AllRanksTip = ns.Guard(function(tooltip)
    GameTooltip_SetTitle(tooltip, ALL_RANKS)
    GameTooltip_AddNormalLine(tooltip, TEXT.allRanksTip)
end)

local function Layouts(root)
    local menu = root:CreateButton(TEXT.layoutsMenu)
    menu:CreateButton(TEXT.saveAs, ns.Guard(ns.Presets.AskSave))
    for _, name in ipairs(ns.Presets.List()) do
        local layout = menu:CreateButton(name)
        layout:CreateButton(TEXT.load, ns.Guard(function() ns.Presets.AskLoad(name) end))
        layout:CreateButton(TEXT.saveOver, ns.Guard(function()
            ns.Print((select(2, ns.Presets.Save(name))))
        end))
        layout:CreateButton(TEXT.delete, ns.Guard(function() ns.Presets.AskDelete(name) end))
    end
end

-- The book's own lines, and the divider under them. own: a book of Sane UI's (Combat's), whose pages are
-- always ours: no line waits for the game's pages, and compact pages and moving are the game's book's.
local function BookLines(root, own)
    local wait = not own and PagesOurs or nil
    Checkbox(root, "showHidden", wait)

    -- The game offers this line itself, except to warriors and rogues: their ranks replace
    -- each other, so the game has no old ranks to show. The ranks still to come are worth it.
    if ns.class == "WARRIOR" or ns.class == "ROGUE" then
        local box = root:CreateCheckbox(ALL_RANKS, ns.Guard(function() return GetCVarBool("ShowAllSpellRanks") end), ns.Guard(function()
            SetCVar("ShowAllSpellRanks", GetCVarBool("ShowAllSpellRanks") and "0" or "1")
            Refresh()
        end))
        if box and box.SetTooltip then box:SetTooltip(AllRanksTip) end
    end

    Checkbox(root, "home", wait)
    if not own then
        Checkbox(root, "compact", PagesOurs)
        Checkbox(root, "window", PagesOurs)
    end
    root:CreateDivider()
end

-- A druid's own switch (FormBar.lua), so no switch of the options page; also the checkbox beside Bar 6.
local FormBarOn = ns.Guard(function() return ns.FormBar.On() end)
local FormBarFlip = ns.Guard(function() ns.FormBar.Set(not ns.FormBar.On()) end)
local FormBarTip = ns.Guard(function(tooltip)
    GameTooltip_SetTitle(tooltip, TEXT.formBarMenu)
    GameTooltip_AddNormalLine(tooltip, TEXT.formBarTip)
end)

local function FormBarLine(root)
    if not ns.FormBar.For() then return end
    local box = root:CreateCheckbox(TEXT.formBarMenu, FormBarOn, FormBarFlip)
    if box and box.SetTooltip then box:SetTooltip(FormBarTip) end
end

-- First the book, then the bars, as on the options page. The book's lines are Forever's: in Retail
-- the spellbook's pages are the game's own (Abilities.lua, at the top), and the bars' lines follow the title.
local function Lines(root, own)
    if not ns.char then return end
    root:CreateDivider()
    root:CreateTitle(Core.TITLE)
    if Core.FOREVER then BookLines(root, own) end

    Checkbox(root, "ghosts")
    Checkbox(root, "announce")
    if Core.FOREVER then Checkbox(root, "ranks") end
    Checkbox(root, "holdPage")
    FormBarLine(root)
    Checkbox(root, "tightBars")

    Layouts(root)
end

local function Extend(_, root) Lines(root, false) end

-- The same lines in a book of Sane UI's own (Offer.lua).
function ns.BookMenu(root) Lines(root, true) end

if Menu and Menu.ModifyMenu then
    Menu.ModifyMenu("MENU_SPELL_BOOK_SETTINGS", ns.Guard(Extend))
end
