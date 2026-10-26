return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local noirbuddy_lualine = require("noirbuddy.plugins.lualine")
		local colors = require("noirbuddy.colors").all()

		if noirbuddy_lualine.theme and noirbuddy_lualine.theme.normal and noirbuddy_lualine.theme.normal.a then
			noirbuddy_lualine.theme.normal.a.bg = colors.primary
			noirbuddy_lualine.theme.normal.a.fg = colors.noir_9
		end

		local function attached_lsps()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return ""
			end

			local names = {}
			for _, client in ipairs(clients) do
				names[#names + 1] = client.name
			end

			return " " .. table.concat(names, ",")
		end

		require("lualine").setup({
			options = {
				theme = noirbuddy_lualine.theme,
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					"branch",
					{
						"diff",
						symbols = { added = " ", modified = " ", removed = " " },
					},
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = { error = " ", warn = " ", info = " ", hint = " " },
					},
				},
				lualine_c = {
					{
						"filename",
						path = 1,
						symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
					},
				},
				lualine_x = {
					attached_lsps,
					"encoding",
					"fileformat",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {
					{
						"filename",
						path = 1,
					},
				},
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
		})
	end,
}
