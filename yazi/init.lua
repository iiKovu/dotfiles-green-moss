require("bookmarks"):setup({
	last_directory = { enable = true, persist = true, mode = "dir" },
	persist = "all",
	desc_format = "full",
	file_pick_mode = "parent",
	show_keys = true,
	notify = {
		enable = true,
		timeout = 3,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})
