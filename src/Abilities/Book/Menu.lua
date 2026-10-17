local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Menu
--  The module's lines in the spellbook's own options menu (the small arrow at
--  the top right of the spellbook).
--
--  Menu.ModifyMenu is the game's own door for this: an addon may append lines
--  to a menu without its code mixing with the game's lines above them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local TEXT = ns.TEXT

local function Option(key)
    return ns.options[key] and true or false
end

-- One of the module's switches as a line of the menu, with the words of the options page.
-- A click sets it through Core (Core.Set): the module hears it as from the options page (its
-- changed redraws), and an open options page shows it too.
-- enabled: a function; while it says no, the line is greyed out and its tooltip says why (the
-- game's own lines in this menu do the same while a search is on).
local function Checkbox(root, key, enabled)
    local option = Core.Described(ns.name, key)
    local text, tip = option.text, option.tip
    local box = root:CreateCheckbox(text, function() return Option(key) end, function()
        Core.Set(ns.name, key, not Option(key))
    end)
    if not box then return box end
    if enabled and box.SetEnabled then box:SetEnabled(enabled) end
    if box.SetTooltip then
        box:SetTooltip(function(tooltip)
            GameTooltip_SetTitle(tooltip, text)
            if tip then GameTooltip_AddNormalLine(tooltip, tip) end
            if enabled and not enabled() then
                GameTooltip_AddErrorLine(tooltip, TEXT.pagesGame:format(ns.Book.Why() or ""))
            end
        end)
    end
    return box
end

local function Refresh()
    ns.Fire("REFRESH")
end

-- The four switches about the book do nothing while its pages are the game's.
local function PagesOurs()
    return ns.Book.Armed()
end

local function Layouts(root)
    local menu = root:CreateButton(TEXT.layoutsMenu)
    menu:CreateButton(TEXT.saveAs, ns.Presets.AskSave)
    for _, name in ipairs(ns.Presets.List()) do
        local layout = menu:CreateButton(name)
        layout:CreateButton(TEXT.load, function() ns.Presets.AskLoad(name) end)
        layout:CreateButton(TEXT.saveOver, function()
            ns.Print((select(2, ns.Presets.Save(name))))
        end)
        layout:CreateButton(TEXT.delete, function() ns.Presets.AskDelete(name) end)
    end
end

-- First the book, then the bars, as on the options page.
local function Extend(_, root)
    if not ns.char then return end
    root:CreateDivider()
    root:CreateTitle(Core.TITLE)

    Checkbox(root, "showHidden", PagesOurs)

    -- The game offers this line itself, except to warriors and rogues: their ranks replace
    -- each other, so the game has no old ranks to show. The ranks still to come are worth it.
    if ns.class == "WARRIOR" or ns.class == "ROGUE" then
        local text = Core.Word("SHOW_ALL_SPELL_RANKS", TEXT.allRanks)
        local box = root:CreateCheckbox(text, function() return GetCVarBool("ShowAllSpellRanks") end, function()
            SetCVar("ShowAllSpellRanks", GetCVarBool("ShowAllSpellRanks") and "0" or "1")
            Refresh()
        end)
        if box and box.SetTooltip then
            box:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, text)
                GameTooltip_AddNormalLine(tooltip, TEXT.allRanksTip)
            end)
        end
    end

    Checkbox(root, "home", PagesOurs)
    Checkbox(root, "compact", PagesOurs)
    Checkbox(root, "window", PagesOurs)

    root:CreateDivider()
    Checkbox(root, "ghosts")
    Checkbox(root, "announce")

    Layouts(root)
end

if Menu and Menu.ModifyMenu then
    Menu.ModifyMenu("MENU_SPELL_BOOK_SETTINGS", Extend)
end
