return {
	Name = "checkpoint",
	Description = "Teleports players to a Chapter 1 checkpoint. Invalid names list the available checkpoints.",
	Group = "HorrorOutbreakAdmin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players to teleport.",
		},
		{
			Type = "checkpoint",
			Name = "checkpoint",
			Description = "Exact checkpoint name; use quotes for names with spaces.",
		},
	},
}
