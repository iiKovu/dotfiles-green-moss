return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup()

		require("nvim-treesitter").install({
			"lua",
			"python",
			"r",
			"bash",
			"java",
			"sql",
			"toml",
			"markdown",
			"markdown_inline",
			"html",
			"css",
			"javascript",
			"typescript",
			"tsx",
			"json",
			"yaml",
		})

		-- Start treesitter for any filetype with an installed parser
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				if not pcall(vim.treesitter.start, args.buf) then
					return
				end
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				if lang and vim.treesitter.query.get(lang, "indents") then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
