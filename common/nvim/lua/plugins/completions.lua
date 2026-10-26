return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "rafamadriz/friendly-snippets" },
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(args)
					vim.b[args.buf].completion_autoshow = false
				end,
			})
		end,
		opts = {
			keymap = {
				preset = "none",
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
			completion = {
				list = { selection = { preselect = false, auto_insert = true } },
				menu = {
					auto_show = function()
						return vim.b.completion_autoshow ~= false
					end,
					draw = {
						columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				per_filetype = {
					sql = { "dadbod", inherit_defaults = true },
					mysql = { "dadbod", inherit_defaults = true },
					plsql = { "dadbod", inherit_defaults = true },
				},
				providers = {
					lsp = { name = "LSP" },
					path = { name = "Path" },
					snippets = { name = "Snip" },
					buffer = { name = "Buf" },
					dadbod = { name = "SQL", module = "vim_dadbod_completion.blink" },
				},
			},
			signature = { enabled = true },
		},
	},
}
