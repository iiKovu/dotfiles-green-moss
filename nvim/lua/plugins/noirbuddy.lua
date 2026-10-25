return {
	"jesseleite/nvim-noirbuddy",
	dependencies = { "tjdevries/colorbuddy.nvim" },
	lazy = false,
	priority = 1000,
	config = function()
		-- Colors from the active preset (~/.config/themes/current/nvim.lua)
		local ok, theme = pcall(dofile, vim.fn.expand("~/.config/themes/current/nvim.lua"))
		if not ok then
			theme = { primary = "#ff0088", soft = "#ff99cc", background = "" }
		end
		vim.g.theme_soft = theme.soft
		require("noirbuddy").setup({
			preset = "minimal",
			colors = {
				primary = theme.primary,
				background = theme.background ~= "" and theme.background or nil,
			},
		})
		local hl = vim.api.nvim_set_hl
		for _, g in ipairs({
			"@keyword",
			"@keyword.modifier",
			"@keyword.return",
			"@keyword.operator",
			"@keyword.function",
			"@attribute",
			"@lsp.type.keyword",
		}) do
			hl(0, g, { fg = theme.primary, bold = true })
		end
		for _, g in ipairs({
			"@string",
			"@number",
			"@boolean",
			"@constant",
			"@constant.builtin",
			"@lsp.type.string",
			"@lsp.type.number",
			"@lsp.type.boolean",
			"Number",
			"Constant",
		}) do
			hl(0, g, { fg = theme.soft })
		end
	end,
}
