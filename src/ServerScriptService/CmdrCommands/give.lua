return {
	Name = "give",
	Description = "Gives an inventory item to one or more players.",
	Group = "HorrorOutbreakAdmin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players receiving the item.",
		},
		{
			Type = "string",
			Name = "item",
			Description = "Exact item name; use quotes for names with spaces.",
		},
	},
}
