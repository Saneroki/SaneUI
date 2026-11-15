local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Bin
--  The waste bin's question (Saneroki, 2026-11-15: "When you drag an item
--  over the delete icon it should be default ask if you want to delete the
--  item or not and inside the popup window it has another 3rd button with
--  "Delete the item and don't ask me again""): an item let go over Junk's bin
--  (or clicked onto it) is asked about in a small window of the kit's bronze
--  where the game's questions stand, its name in its quality's colour:
--  Delete, Cancel (the item back where it came from), and Delete the item and
--  don't ask me again (the setting Waste Bin Asks First switched off: from
--  then on the bin destroys at once). The item is destroyed by that click: the
--  game lets an addon destroy an item only at a press of the player's own
--  (DeleteCursorItem has restrictions; Asks.lua). Where the game refuses even
--  that, its own question comes, as for an item dropped into the world
--  (Menus.Destroy). The cursor emptied meanwhile (the item put down
--  elsewhere), the window goes.
--
--      Bin.Drop()   the item on the cursor let go over the bin: asked about, or destroyed at once
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bin = {}
ns.Bin = Bin

Bin.SIZE = { 440, 172 }
Bin.TOP = 135            -- from the screen's top, where the game's questions stand
Bin.BUTTON = { 150, 28 }
Bin.WIDE = 330           -- the third button, under the two
Bin.GAP = 8
Bin.CHECK = 0.3          -- seconds after the item was destroyed before the cursor shows whether the game let it

local frame, words

local function Item()
    local kind, id, link = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind ~= "item" or type(id) ~= "number" then return nil end
    return id, Core.Plain(link)
end

-- Its name in its quality's colour (the game's colours), as the game names it in its questions.
local function Named(id, link)
    local items = rawget(_G, "C_Item")
    local info = items and items.GetItemInfo or rawget(_G, "GetItemInfo")
    local ok, name, _, quality = pcall(info, link or id)
    if not ok then name, quality = nil, nil end
    name = Core.Plain(name) or (type(link) == "string" and link:match("%[(.-)%]")) or tostring(id)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = type(colors) == "table" and colors[Core.Plain(quality)]
    if type(color) == "table" and type(color.hex) == "string" then return color.hex .. name .. "|r" end
    return name
end

local function Close()
    if frame and frame:IsShown() then frame:Hide() end
end

-- A moment after the item was destroyed: gone, or the game refused and its own question comes.
local Check = Core.Later(function()
    ns.Guarded(function()
        if Core.Ask(rawget(_G, "CursorHasItem")) then ns.Menus.Destroy() end
    end)
end, Bin.CHECK, "Inventory: bin")

-- The item on the cursor destroyed, at the player's own press (a click here, or the drop itself).
local function Destroy()
    Close()
    if not Item() then return end
    local items = rawget(_G, "C_Item")
    local delete = rawget(_G, "DeleteCursorItem") or (items and items.DeleteCursorItem)
    if delete then pcall(delete) end
    Check()
end

local function Never()
    Core.Set(ns.name, "binAsk", false)
    Destroy()
end

-- No: the item back where it came from, as the game's own No does.
local function Cancel()
    Close()
    local clear = rawget(_G, "ClearCursor")
    if clear and Core.Ask(rawget(_G, "CursorHasItem")) then pcall(clear) end
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(Bin.SIZE[1], Bin.SIZE[2])
    frame:SetPoint("TOP", UIParent, "TOP", 0, -Bin.TOP)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:Hide()
    local look = Core.Look.Dress(frame, ns.TEXT.binTitle)
    look.close:SetScript("OnClick", ns.Guard(Cancel))
    local content = look.content
    words = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    words:SetPoint("TOPLEFT", 0, -8)
    words:SetPoint("TOPRIGHT", 0, -8)
    words:SetJustifyH("CENTER")
    words:SetWordWrap(true)
    local Look = Core.Look
    local never = Look.Red(content, ns.TEXT.binNever, Bin.WIDE, Bin.BUTTON[2])
    never:SetPoint("BOTTOM", 0, 0)
    never:SetScript("OnClick", ns.Guard(Never))
    local delete = Look.Red(content, Core.Word("DELETE", "Delete"), Bin.BUTTON[1], Bin.BUTTON[2])
    delete:SetPoint("BOTTOMRIGHT", never, "TOP", -Bin.GAP / 2, Bin.GAP)
    delete:SetScript("OnClick", ns.Guard(Destroy))
    local cancel = Look.Red(content, Core.Word("CANCEL", "Cancel"), Bin.BUTTON[1], Bin.BUTTON[2])
    cancel:SetPoint("BOTTOMLEFT", never, "TOP", Bin.GAP / 2, Bin.GAP)
    cancel:SetScript("OnClick", ns.Guard(Cancel))
    Bin.buttons = { delete = delete, cancel = cancel, never = never }
    -- The item put down elsewhere meanwhile: nothing left to ask about (heard only while it asks).
    frame:SetScript("OnEvent", ns.Guard(function()
        if not Core.Ask(rawget(_G, "CursorHasItem")) then Close() end
    end))
    frame:HookScript("OnShow", ns.Guard(function()
        frame:RegisterEvent("CURSOR_CHANGED")
        Core.Escape(frame, Cancel)
    end))
    frame:HookScript("OnHide", ns.Guard(function()
        frame:UnregisterEvent("CURSOR_CHANGED")
        Core.Escape(frame, nil)
    end))
end

function Bin.Drop()
    local id, link = Item()
    if not id then return false end
    if (ns.options or {}).binAsk == false then
        Destroy()
        return true
    end
    if not frame then Build() end
    words:SetText(ns.TEXT.binAsk:format(Named(id, link)))
    frame:Show()
    frame:Raise()
    Core.Sound("IG_MAINMENU_OPEN")
    return true
end

-- For the tests.
function Bin.Frame() return frame end
function Bin.Words() return words end
