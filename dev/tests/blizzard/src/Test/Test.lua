-- A module that uses one of each kind of thing from the fixture export.
local _, ns = ...
local Test = {}
SaneUI_Test = Test

local frame = CreateFrame("Button", nil, UIParent, "TestButtonTemplate")
frame:RegisterEvent("TEST_EVENT")
frame:RegisterEvent("TEST_GONE")
hooksecurefunc("Test_Hooked", function() end)
hooksecurefunc(frame, "Refresh", function() end)
ns.thing = C_Test.GetThing(1)
ns.secret = C_Test.Secretive()
ns.gone = C_Test.Removed()
ns.info = C_Test.GetInfo()
ns.kind = Enum.TestKind.Second
ns.sum = Test_Params(1, 2)
ns.same = Test_Comment()
ns.old = OldFunction()
ns.number = TEST_CONSTANT
FamilyFunc()
VanillaOnly()
ExcludedFunc()
GameFunc()
Menu.ModifyMenu("MENU_TEST_TAG", function() end)
C_AddOns.LoadAddOn("Blizzard_Gone")
frame.Text:SetText("x")
frame.Box:Show()
frame.Mine = 1
ns.mine = frame.Mine
frame:SetThing(1)
frame:CreateTexture():SetAtlas("test-atlas-old")

-- A local with a Blizzard global's name is not Blizzard's.
local Settings = {}
Settings.Open = function() end
Settings.Open(1)

function Test.Refresh() end
