return {
	"rmagatti/auto-session",
	config = function()
		require("auto-session").setup({
			suppressed_dirs = { "~/", "/" },
			session_lens = {
				buftypes_to_ignore = {},
				load_on_setup = false,
				mappings = {
					delete_session = { { "i", "n" }, "<C-d>" },
					alternate_session = { "i", "<C-s>" },
					copy_session = { "i", "<C-y>" },
				},
				picker_opts = { border = true },
				previewer = "summary",
			},
		})
	end,
}
