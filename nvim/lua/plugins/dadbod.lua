return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_disable_info_notifications = 1
			vim.g.db_ui_winwidth = 30
			vim.g.db_ui_auto_execute_table_helpers = 1
			vim.g.db_ui_table_helpers = {
				postgresql = {
					Count = 'SELECT count(*) FROM "{table}"',
				},
				mysql = {
					Count = "SELECT count(*) FROM `{table}`",
				},
				sqlite = {
					Count = 'SELECT count(*) FROM "{table}"',
				},
			}
		end,
	},
}
