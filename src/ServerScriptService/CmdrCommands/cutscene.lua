return {
	Name = "cutscene",
	Description = "Plays a Chapter 1 cutscene for selected players. Invalid names list the available cutscenes.",
	Group = "HorrorOutbreakAdmin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players who will see the cutscene.",
		},
		{
			Type = "cutscene",
			Name = "cutscene",
			Description = "Exact cutscene event name.",
		},
	},
}
