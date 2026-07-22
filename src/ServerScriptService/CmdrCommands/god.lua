return {
	Name = "god",
	Description = "Prevents selected players from taking humanoid damage.",
	Group = "HorrorOutbreakAdmin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players to update.",
		},
		{
			Type = "boolean",
			Name = "enabled",
			Description = "Whether god mode is enabled.",
		},
	},
}
