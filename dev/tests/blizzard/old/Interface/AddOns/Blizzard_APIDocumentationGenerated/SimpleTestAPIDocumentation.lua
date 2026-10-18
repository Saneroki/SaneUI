local SimpleTestAPI =
{
	Name = "SimpleTestAPI",
	Type = "ScriptObject",
	Environment = "All",

	Functions =
	{
		{
			Name = "SetThing",
			Type = "Function",

			Arguments =
			{
				{ Name = "thing", Type = "number", Nilable = false },
			},
		},
	},
};

APIDocumentation:AddDocumentationTable(SimpleTestAPI);
