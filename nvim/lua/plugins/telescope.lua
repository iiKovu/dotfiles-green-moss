return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		init = function()
			-- Load Telescope on first vim.ui.select (e.g. code actions); ui-select then replaces this stub
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "telescope.nvim" } })
				return vim.ui.select(...)
			end
		end,
		config = function()
			require("telescope").setup({
				defaults = {
					path_display = { "smart" },
					file_ignore_patterns = {
						"%.git/",
						"node_modules/",
						"dist/",
						"build/",
						"target/",
						"%.cache/",
					},
					layout_config = {
						prompt_position = "top",
					},
					vimgrep_arguments = {
						"rg",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden",
						"--glob",
						"!.git/*",
					},
				},
				pickers = {
					find_files = {
						theme = "dropdown",
						hidden = true,
						find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
					},
					live_grep = {
						theme = "dropdown",
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("fzf")
		end,
	},
}
