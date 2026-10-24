return {
	"3rd/image.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	rocks = {
		hererocks = true,
	},
	ft = "markdown",
	config = function()
		require("image").setup({
			backend = "kitty",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = false,
					only_render_image_at_cursor = true,
					filetypes = { "markdown" },
				},
			},
			max_height_window_percentage = 50,
			kitty_method = "normal",
		})
	end,
}
