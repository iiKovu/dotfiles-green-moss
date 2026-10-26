local servers = {
	"lua_ls", -- Lua
	"air", -- R
	"bashls", -- Bash
	"basedpyright", -- Python (types)
	"ruff", -- Python (lint)
	"jdtls", -- Java
	"tombi", -- TOML
	"sqls", -- SQL
}

return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = servers,
			automatic_enable = false,
		},
		dependencies = { "neovim/nvim-lspconfig" },
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufReadPost", "BufNewFile" },
		config = function()
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
						workspace = {
							library = { vim.env.VIMRUNTIME },
							checkThirdParty = false,
						},
					},
				},
			})

			vim.lsp.config("basedpyright", {
				settings = {
					basedpyright = {
						disableOrganizeImports = true,
						analysis = { typeCheckingMode = "standard" },
					},
				},
			})

			vim.lsp.config("ruff", {
				on_attach = function(client)
					client.server_capabilities.hoverProvider = false
				end,
			})

			vim.lsp.config("air", {
				filetypes = { "r", "rmd", "quarto" },
			})

			vim.lsp.enable(servers)
		end,
	},
}
