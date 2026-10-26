-- Mason packages backing the formatters below (ruff comes with the LSP list)
local tools = { "stylua", "shfmt", "sqruff", "clang-format", "prettier" }

return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	init = function()
		-- Install missing formatters at startup, like mason-lspconfig does for servers
		local registry = require("mason-registry")
		registry.refresh(function()
			for _, name in ipairs(tools) do
				local pkg = registry.get_package(name)
				if not pkg:is_installed() then
					pkg:install()
				end
			end
		end)
	end,
	config = function()
		require("conform").setup({
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				return {
					timeout_ms = 1000,
					lsp_format = "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_organize_imports", "ruff_format" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				sql = { "sqruff" },
				mysql = { "sqruff" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				markdown = { "prettier" },
			},
		})
	end,
}
