return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = "markdown",

	config = function(_, opts)
		-- Derive colours from noirbuddy
		local function set_markdown_colors()
			local c = require("noirbuddy.colors").all()
			local pink, soft_pink = c.primary, vim.g.theme_soft or "#ff99cc"
			local hl = vim.api.nvim_set_hl

			local function blend(fg, bg, alpha)
				local function ch(hex, i)
					return tonumber(hex:sub(i, i + 1), 16)
				end
				local out = "#"
				for i = 2, 6, 2 do
					out = out .. string.format("%02x", math.floor(ch(fg, i) * alpha + ch(bg, i) * (1 - alpha) + 0.5))
				end
				return out
			end

			local heading_fg = { pink, soft_pink, c.noir_0, c.noir_2, c.noir_4, c.noir_6 }
			local heading_bg = {
				blend(pink, c.background, 0.15),
				blend(soft_pink, c.background, 0.10),
				c.noir_9,
				c.noir_9,
				c.noir_9,
				c.noir_9,
			}
			for i = 1, 6 do
				hl(0, "Headline" .. i .. "Fg", { fg = heading_fg[i], bold = true })
				hl(0, "Headline" .. i .. "Bg", { bg = heading_bg[i] })
			end

			hl(0, "RenderMarkdownBullet", { fg = c.noir_5 })
			hl(0, "RenderMarkdownUnchecked", { fg = c.noir_4 })
			hl(0, "RenderMarkdownChecked", { fg = pink })
			hl(0, "RenderMarkdownTodo", { fg = soft_pink })
			hl(0, "RenderMarkdownQuote", { fg = c.noir_6 })
			for i, fg in ipairs({ pink, soft_pink, c.noir_4, pink, soft_pink, c.noir_4 }) do
				hl(0, "RenderMarkdownQuote" .. i, { fg = fg })
			end
			hl(0, "RenderMarkdownCode", { bg = c.noir_9 })
			hl(0, "RenderMarkdownCodeInfo", { fg = c.noir_4, bg = c.noir_9 })
			hl(0, "RenderMarkdownCodeBorder", { fg = c.noir_8, bg = c.noir_9 })
			hl(0, "RenderMarkdownCodeFallback", { fg = c.noir_3, bg = c.noir_9 })
			hl(0, "RenderMarkdownCodeInline", { fg = soft_pink, bg = c.noir_9 })
			hl(0, "RenderMarkdownDash", { fg = c.noir_7 })
			hl(0, "RenderMarkdownTableHead", { fg = pink, bold = true })
			hl(0, "RenderMarkdownTableRow", { fg = c.noir_6 })
			hl(0, "RenderMarkdownInfo", { fg = c.diagnostic_info })
			hl(0, "RenderMarkdownSuccess", { fg = c.diff_add })
			hl(0, "RenderMarkdownHint", { fg = c.diagnostic_hint })
			hl(0, "RenderMarkdownWarn", { fg = c.diagnostic_warning })
			hl(0, "RenderMarkdownError", { fg = c.diagnostic_error })
		end

		set_markdown_colors()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = set_markdown_colors,
		})
		require("render-markdown").setup(opts)
	end,

	opts = {
		bullet = {
			enabled = true,
			icons = { "•", "◦", "▪", "▫" },
			left_pad = 1,
			right_pad = 1,
		},
		checkbox = {
			enabled = true,
			unchecked = {
				icon = "󰄱 ",
				highlight = "RenderMarkdownUnchecked",
			},
			checked = {
				icon = "󰱒 ",
				highlight = "RenderMarkdownChecked",
			},
		},
		heading = {
			sign = false,
			icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
			position = "inline",
			width = "block",
			backgrounds = {
				"Headline1Bg",
				"Headline2Bg",
				"Headline3Bg",
				"Headline4Bg",
				"Headline5Bg",
				"Headline6Bg",
			},
			foregrounds = {
				"Headline1Fg",
				"Headline2Fg",
				"Headline3Fg",
				"Headline4Fg",
				"Headline5Fg",
				"Headline6Fg",
			},
		},
		code = {
			border = "thin",
			width = "block",
			left_pad = 1,
			right_pad = 1,
		},
		dash = {
			icon = "─",
			width = 0.8,
		},
		quote = {
			icon = "│",
			highlight = "RenderMarkdownQuote",
		},
		pipe_table = {
			preset = "round",
			style = "full",
		},
	},
}
