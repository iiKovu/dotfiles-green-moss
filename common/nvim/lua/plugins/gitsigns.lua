return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		on_attach = function(bufnr)
			local gs = require("gitsigns")
			local map = vim.keymap.set
			local function opts(desc)
				return { buffer = bufnr, silent = true, desc = desc }
			end

			map("n", "<leader>gn", function()
				gs.nav_hunk("next")
			end, opts("Next git hunk"))
			map("n", "<leader>gN", function()
				gs.nav_hunk("prev")
			end, opts("Previous git hunk"))
			map("n", "<leader>gp", gs.preview_hunk, opts("Preview git hunk"))
			map("n", "<leader>gs", gs.stage_hunk, opts("Stage git hunk"))
			map("n", "<leader>gr", gs.reset_hunk, opts("Reset git hunk"))
			map("n", "<leader>gb", gs.blame_line, opts("Git blame line"))
			map("n", "<leader>gB", gs.toggle_current_line_blame, opts("Toggle inline git blame"))
		end,
	},
}
