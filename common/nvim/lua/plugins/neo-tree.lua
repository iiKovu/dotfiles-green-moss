return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	cmd = "Neotree",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		close_if_last_window = true,
		enable_diagnostics = true,
		enable_git_status = true,
		window = {
			width = 36,
		},
		filesystem = {
			filtered_items = {
				hide_dotfiles = true,
				hide_gitignored = false,
				hide_ignored = false,
				hide_hidden = false,
				hide_by_name = {
					".git",
				},
			},
			follow_current_file = {
				enabled = true,
				leave_dirs_open = false,
			},
			group_empty_dirs = true,
			use_libuv_file_watcher = true,
		},
	},
}
