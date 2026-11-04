-- Combat's full screen with Sane Macros and the action bars as windows: Core and Combat from their TOCs, the game's
-- action bars standing in (the lab has none), four wide ones stacked and touching and a tall one. Drag a macro from
-- the list onto a bar.
-- In the console LabMacros is the module's table, LabBars.Full() brings the full screen again.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end -- not in the lab
    return create(kind, name, parent, template, ...)
end
SecureHandlerSetFrameRef = function() end
RegisterUnitWatch, UnregisterUnitWatch = function(frame) frame:Show() end, function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
ClearOverrideBindings, SetOverrideBinding, SetOverrideBindingClick = function() end, function() end, function() end
SecureCmdOptionParse = function() return nil end
GetBindingKey = function() end

-- The game's bars: frames that know their size, each with its twelve buttons.
local function Bar(name, prefix, across, rows, x, y)
    local bar = CreateFrame("Frame", name, UIParent)
    bar:SetSize(across * 40, rows * 40)
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", x, y)
    bar.actionButtons = {}
    for index = 1, 12 do
        local button = CreateFrame("Button", prefix .. index, bar)
        button:SetSize(36, 36)
        local column, row = (index - 1) % across, math.floor((index - 1) / across)
        button:SetPoint("TOPLEFT", bar, "TOPLEFT", column * 40 + 2, -row * 40 - 2)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetColorTexture(0.3, 0.26, 0.18, 1)
        bar.actionButtons[index] = button
    end
    bar:Show()
    return bar
end
Bar("MainActionBar", "ActionButton", 12, 1, 0, 8)
Bar("MultiBar7", "MultiBar7Button", 12, 1, 0, 48)
Bar("MultiBar6", "MultiBar6Button", 12, 1, 0, 88)
Bar("MultiBar5", "MultiBar5Button", 12, 1, 0, 128)
Bar("MultiBarRight", "MultiBarRightButton", 1, 12, 600, 100)

-- Two of the game's macros, marked W under yours.
GetNumMacros = function() return 2, 0 end
GetMacroInfo = function(index)
    if index == 1 then return "Mount", 132261, "/use Horse" end
    if index == 2 then return "Hearth", 134414, "/use Hearthstone" end
end

Lab.TOC("src/Core/SaneUI.toc")
local combat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
combat.UnitAuras.missing = true -- the lab has no aura containers
LabMacros = combat.Macros

local PICTURES = { ["Shield Block"] = 132110, ["Victory Rush"] = 132342, ["Shield Slam"] = 134951, Slam = 132340 }
C_Spell = C_Spell or {}
C_Spell.GetSpellTexture = function(name) return PICTURES[name] end
C_Spell.DoesSpellExist = function(name) return PICTURES[name] ~= nil end

LabBars = { Full = function() combat.Window.Fill() end }
Lab.OnLogin(function()
    local Book = LabMacros.Book
    if not Book.All()[1] then
        local tank = Book.New("Tank")
        for _, name in ipairs({ "Shield Block", "Victory Rush", "Shield Slam", "Slam" }) do
            tank.steps[#tank.steps + 1] = Book.Step("spell", name)
        end
        Book.New("Mouse heal")
        for _, name in ipairs({ "Hi", "Thanks", "Sit", "Follow", "HP Potion" }) do Book.FromGame(name, "/" .. name:lower()) end
    end
    combat.Window.Fill()
end)
