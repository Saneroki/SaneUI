local Test =
{
	Name = "Test",
	Type = "System",
	Namespace = "C_Test",
	Environment = "All",

	Functions =
	{
		{
			Name = "GetThing",
			Type = "Function",
			Documentation = { "Words for people, never compared." },

			Arguments =
			{
				{ Name = "thingID", Type = "number", Nilable = false },
			},

			Returns =
			{
				{ Name = "thing", Type = "string", Nilable = false },
			},
		},
		{
			Name = "Secretive",
			Type = "Function",

			Returns =
			{
				{ Name = "value", Type = "number", Nilable = false },
			},
		},
		{
			Name = "Removed",
			Type = "Function",
		},
		{
			Name = "GetInfo",
			Type = "Function",

			Returns =
			{
				{ Name = "info", Type = "TestInfo", Nilable = false },
			},
		},
	},

	Events =
	{
		{
			Name = "TestEvent",
			Type = "Event",
			LiteralName = "TEST_EVENT",
			Payload =
			{
				{ Name = "unit", Type = "string", Nilable = false },
			},
		},
		{
			Name = "TestGone",
			Type = "Event",
			LiteralName = "TEST_GONE",
		},
	},

	Tables =
	{
		{
			Name = "TestKind",
			Type = "Enumeration",
			NumValues = 2,
			MinValue = 1,
			MaxValue = 2,
			Fields =
			{
				{ Name = "First", Type = "TestKind", EnumValue = 1 },
				{ Name = "Second", Type = "TestKind", EnumValue = 2 },
			},
		},
		{
			Name = "TestInfo",
			Type = "Structure",
			Fields =
			{
				{ Name = "name", Type = "string", Nilable = false },
				{ Name = "size", Type = "number", Nilable = false },
			},
		},
	},
};

APIDocumentation:AddDocumentationTable(Test);
