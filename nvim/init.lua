vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"
vim.g.disable_autoformat = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("vim-options")
require("lazy").setup("plugins")

local function map(mode, lhs, rhs, desc, opts)
	opts = vim.tbl_extend("force", { silent = true, desc = desc }, opts or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

--------------------
---- Mappings ----
--------------------
-- Clipboard
map({ "n", "v" }, "<leader>y", '"+y', "Yank to system clipboard")

-- Editing
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlights")
map("n", "<A-j>", "<cmd>m .+1<cr>==", "Move line down")
map("n", "<A-k>", "<cmd>m .-2<cr>==", "Move line up")
map("v", "<A-j>", ":m '>+1<cr>gv=gv", "Move selection down")
map("v", "<A-k>", ":m '<-2<cr>gv=gv", "Move selection up")

-- Find (Telescope)
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find files")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", "Search text")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "Find buffers")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Search help")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", "Find recent files")
map("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", "Search word under cursor")
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", "Search keymaps")
map("n", "<leader>fl", "<cmd>Telescope resume<cr>", "Resume last search")

-- Sessions
map("n", "<leader>ss", "<cmd>AutoSession search<cr>", "Search sessions")
map("n", "<leader>sd", "<cmd>AutoSession deletePicker<cr>", "Delete session")

-- LSP
local lsp_group = vim.api.nvim_create_augroup("user_lsp_mappings", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = lsp_group,
	callback = function(event)
		local buffer_opts = { buffer = event.buf }
		map("n", "gd", vim.lsp.buf.definition, "Go to definition", buffer_opts)
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration", buffer_opts)
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action", buffer_opts)
		map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol", buffer_opts)
		map("n", "<leader>cs", "<cmd>Telescope lsp_document_symbols<cr>", "Document symbols", buffer_opts)
		map("n", "<leader>cS", "<cmd>Telescope lsp_workspace_symbols<cr>", "Workspace symbols", buffer_opts)
	end,
})

-- Formatting
map("n", "<leader>cc", function()
	require("conform").format({ async = true, timeout_ms = 3000, lsp_format = "fallback" })
end, "Format buffer")
map("n", "<leader>tf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify("Format on save " .. (vim.g.disable_autoformat and "disabled" or "enabled"), vim.log.levels.INFO)
end, "Toggle format on save")

-- Diagnostics config
vim.diagnostic.config({
	severity_sort = true,
	float = { source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
	virtual_text = {
		prefix = "●",
		source = "if_many",
	},
})

-- Diagnostics mappings
map("n", "<leader>dd", vim.diagnostic.open_float, "Show line diagnostics")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics to location list")
map("n", "<leader>dn", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "<leader>dp", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Previous diagnostic")
map("n", "<leader>de", function()
	vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
end, "Errors to location list")
map("n", "<leader>dw", "<cmd>Telescope diagnostics<cr>", "Search workspace diagnostics")

-- Buffers
map("n", "<S-l>", "<cmd>bn<cr>", "Next buffer")
map("n", "<S-h>", "<cmd>bp<cr>", "Previous buffer")
map("n", "<leader>bd", "<cmd>bd<cr>", "Delete buffer")

-- Windows
map("n", "<C-h>", "<C-w>h", "Focus left window")
map("n", "<C-j>", "<C-w>j", "Focus lower window")
map("n", "<C-k>", "<C-w>k", "Focus upper window")
map("n", "<C-l>", "<C-w>l", "Focus right window")

-- Plugin toggles
map("n", "<C-n>", "<cmd>Neotree filesystem reveal left<cr>", "Reveal file tree")
map("n", "<leader>md", "<cmd>RenderMarkdown toggle<cr>", "Toggle rendered Markdown")
map("n", "<leader>tc", "<cmd>ColorizerToggle<cr>", "Toggle colorizer")
map("n", "<leader>tt", "<cmd>FloatermToggle<cr>", "Toggle floating terminal")
map("n", "<leader>ta", function()
	vim.b.completion_autoshow = vim.b.completion_autoshow == false
	vim.notify("Completion auto-popup " .. (vim.b.completion_autoshow and "enabled" or "disabled"), vim.log.levels.INFO)
end, "Toggle completion auto-popup (buffer)")

-- Databases
-- Toggle layout; dadbod-ui can't do SQLite, so re-run the query in `.mode line` (one column per line)
local function toggle_db_layout()
	local scheme = vim.fn.eval("db#url#parse(db_ui#resolve(b:db)).scheme")
	if scheme ~= "sqlite" and scheme ~= "sqlite3" then
		return vim.fn["db_ui#dbout#toggle_layout"]()
	end

	if vim.b.db_ui_expanded_layout then
		vim.b.db_ui_expanded_layout = false
		vim.cmd("normal R")
		return
	end

	local input = vim.fn.eval("b:db.input")
	local tmp = vim.fn.tempname()
	vim.fn.writefile(vim.list_extend({ ".mode line" }, vim.fn.readfile(input)), tmp)
	vim.cmd("let b:db.input = " .. vim.fn.string(tmp))
	vim.cmd("normal R")
	vim.cmd("let b:db.input = " .. vim.fn.string(input))
	vim.b.db_ui_expanded_layout = true
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "dbout",
	callback = function()
		map("n", "<leader>dl", toggle_db_layout, "Toggle database result layout", { buffer = true })
	end,
})

map("n", "<leader>db", "<cmd>DBUIToggle<cr>", "Toggle database UI")
