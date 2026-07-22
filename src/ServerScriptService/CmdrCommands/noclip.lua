return {
	Name = "noclip",
	Description = "Turns character collision on or off for selected players.",
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
			Description = "Whether noclip is enabled.",
		},
	},
}
