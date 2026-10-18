-- A small piece of interface code with one of each kind of thing the tool reads.
TestMixin = {};

function TestMixin:OnLoad()
	self.value = 1;
end

function TestMixin:Refresh(force)
	return force;
end

function Test_Hooked(frame)
	frame:Show();
end

function Test_Params(a, b)
	return a + b;
end

function Test_Comment()
	return 1;
end

function OldFunction()
	return C_Test.NewFunction();
end

TEST_CONSTANT = 5;

local function Hidden() end

for index = 1, 3 do
	Hidden();
end

Menu.ModifyMenu("MENU_TEST_TAG", Hidden);

Settings = {};

function Settings.Open(category)
	return category;
end

Test_Table = {
	Inner = function(self, x) return x; end,
	Value = 3,
};

local text = [==[ function NotAFunction() end ]==];
--[[ function AlsoNot() end ]]
