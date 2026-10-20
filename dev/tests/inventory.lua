-- Runs the Inventory module against the stand-in client (wowstub.lua): the bottom right corner opens and
-- closes the game's bags and character sheet, one push one change, the sheet left alone in a fight.
-- How it feels under the hand can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/inventory.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-- What the module needs of the client: the game's bags (open or not, as its functions say) and its sheet.
local bags, button = false, false
local opened, closed, tab = 0, 0, nil
IsAnyBagOpen = function() return bags end
OpenAllBags = function()
    if bags then return end -- the game's: open already, nothing more
    bags, opened = true, opened + 1
end
CloseAllBags = function() bags, closed = false, closed + 1 end
CharacterFrame = W.NewWidget("Frame", "CharacterFrame")
CharacterFrame:Hide()
ToggleCharacter = function(which) tab = which CharacterFrame:Show() end
HideUIPanel = function(frame) frame:Hide() end
IsMouseButtonDown = function() return button end
UIParent:SetSize(1920, 1080)

W.LoadCore(root)
local Core = SaneUI.Core
local Edge = Core.Edge
W.Fire("ADDON_LOADED", "SaneUI")
local first = #W.frames
local ns = W.LoadAddon(root, "Inventory", "SaneUI_Inventory")
W.Fire("ADDON_LOADED", "SaneUI_Inventory")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")

-- The corner: the module's one frame on UIParent that hears the mouse come.
local square
for index = first + 1, #W.frames do
    local frame = W.frames[index]
    if frame._parent == UIParent and frame._scripts.OnEnter then square = frame end
end
check(square and square:IsShown() and square._points[1][1] == "BOTTOMRIGHT", "a square lies in the bottom right corner")
local side = Core.Pixels(square, Edge.CORNER)
check(square:GetWidth() == side and square:GetHeight() == side, "as large as a docked window's corner")

-- The mouse comes into the corner; it leaves, and the look a few times a second sees it gone.
local function Push()
    W.cursorX, W.cursorY = 1920, 0
    square._scripts.OnEnter(square)
end
local function Leave()
    W.cursorX, W.cursorY = 900, 500
    W.Wait(Edge.LOOK * 2)
end

-- At login the mouse may lie in the corner already: no push.
Push()
check(not bags and not CharacterFrame:IsShown(), "a mouse that was in the corner already opens nothing")
W.Wait(Edge.QUIET)

-- A push opens both, as their keys do.
Push()
check(bags and CharacterFrame:IsShown() and tab == "PaperDollFrame", "a push opens the bags and the character sheet")
-- The mouse still in the corner: no second push, however it wiggles.
W.cursorX, W.cursorY = 1915, 6
W.Wait(Edge.LOOK * 3)
Push()
check(bags and CharacterFrame:IsShown(), "near the corner still: one push, one change")
Leave()
Push()
check(not bags and not CharacterFrame:IsShown(), "back in the corner: both close")

-- One of the two opened by its key: a push opens the other; the next closes both.
Leave()
OpenAllBags()
Push()
check(bags and CharacterFrame:IsShown() and opened == 2, "the bags open by their key: a push adds the sheet")
Leave()
Push()
check(not bags and not CharacterFrame:IsShown(), "and the next push closes both")

-- In a fight the game keeps its panels to its own keys: only the bags come and go.
Leave()
ToggleCharacter("PaperDollFrame")
W.combat = true
Push()
check(bags and CharacterFrame:IsShown(), "in a fight, the sheet open: a push opens the bags")
Leave()
Push()
check(not bags and CharacterFrame:IsShown(), "and closes them; the sheet is left as it is")
HideUIPanel(CharacterFrame)
Leave()
Push()
check(bags and not CharacterFrame:IsShown(), "in a fight, the sheet closed: the bags alone")
W.combat = false
Leave()
Push()
check(bags and CharacterFrame:IsShown(), "after the fight the sheet comes again")
Leave()
Push()
check(not bags and not CharacterFrame:IsShown(), "and goes with the bags")

-- No push during a drag, in Edit Mode, or while a window of Sane UI's fills the screen.
Leave()
button = true
Push()
check(not bags, "a mouse button held (a drag): no push")
button = false
Core.EditMode.active = true
Push()
check(not bags, "in Edit Mode: no push")
Core.EditMode.active = false
local all = Core.Window.All
Core.Window.All = function() return { { edge = { full = false } }, { edge = { full = true } } } end
Push()
check(not bags, "a window of Sane UI's fills the screen: no push")
Core.Window.All = all
Push()
check(bags and CharacterFrame:IsShown(), "none of those: the push opens them")
Leave()
Push()
check(not bags and not CharacterFrame:IsShown(), "and the next push closes them")
Leave()

-- The interface hidden and shown again (Alt-Z) under a mouse in the corner: no push.
square:Hide()
square:Show()
Push()
check(not bags, "shown again under the mouse: no push")
W.Wait(Edge.QUIET)

-- The UI's scale changed: the square is still so many of the screen's pixels.
square:SetSize(1, 1)
W.Fire("UI_SCALE_CHANGED")
check(square:GetWidth() == side, "a new UI scale sizes the square anew")

-- A failure stands the module down: the corner goes, what is open stays.
Push()
check(bags, "a push before standing down")
ns.StandDown("a test")
check(ns.off and not square:IsShown() and bags, "standing down: the square goes, the bags stay open")
Leave()
Push()
check(bags and CharacterFrame:IsShown(), "after it, a push does nothing")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Inventory: all %d checks passed.\n"):format(passed))
