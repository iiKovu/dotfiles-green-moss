return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = {
		user_default_options = {
			css = true,
			mode = "foreground",
			always_update = true,
		},
	},
}
