return {
	{
		"AstroNvim/astrocore",
		---@type AstroCoreOpts
		opts = {
			mappings = {
				-- first key is the mode
				n = {
					-- navigate buffer tabs
					["<Leader>ff"] = {
						function()
							require("snacks").picker.files {
								hidden = true,
								ignored = true,
							}
						end,
						desc = "Find files",
					},
					["<Leader>fc"] = {
						function()
							require("snacks").picker.grep_word {
								hidden = true,
								ignored = true,
							}
						end,
						desc = "Find word under cursor (including ignored)",
					},
					-- Enhanced grep searches with file extension filtering
					["<Leader>fw"] = {
						function()
							require("snacks").picker.grep {
								hidden = true,
								ignored = true,
							}
						end,
						desc = "Find words (filtered)",
					},
					["<Leader>fW"] = {
						function()
							require("snacks").picker.grep {
								hidden = true,
								ignored = true,
							}
						end,
						desc = "Find words in all files (filtered)",
					},
					["]b"] = {
						function()
							require("astrocore.buffer").nav(vim.v.count1)
						end,
						desc = "Next buffer",
					},
					["[b"] = {
						function()
							require("astrocore.buffer").nav(-vim.v.count1)
						end,
						desc = "Previous buffer",
					},

					-- mappings seen under group name "Buffer"
					["<Leader>bd"] = {
						function()
							require("astroui.status.heirline").buffer_picker(function(bufnr)
								require("astrocore.buffer").close(bufnr)
							end)
						end,
						desc = "Close buffer from tabline",
					},
					-- second key is the lefthand side of the map
					-- mappings seen under group name "Buffer"
					["<Leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
					["<Leader>bD"] = {
						function()
							require("astroui.status").heirline.buffer_picker(function(bufnr)
								require("astrocore.buffer").close(bufnr)
							end)
						end,
						desc = "Pick to close",
					},
					-- tables with just a `desc` key will be registered with which-key if it's installed
					-- this is useful for naming menus
					["<Leader>b"] = { desc = "Buffers" },
					-- 调整分割窗口大小
					["<a-h>"] = {
						function()
							require("smart-splits").resize_left()
						end,
						desc = "resize left",
					},
					["<a-j>"] = {
						function()
							require("smart-splits").resize_down()
						end,
						desc = "resize down",
					},
					["<a-k>"] = {
						function()
							require("smart-splits").resize_up()
						end,
						desc = "resize up",
					},
					["<a-l>"] = {
						function()
							require("smart-splits").resize_right()
						end,
						desc = "resize right",
					},

					-- 在分割窗口间移动光标
					["<c-h>"] = {
						function()
							require("smart-splits").move_cursor_left()
						end,
						desc = "move cursor left",
					},
					["<c-j>"] = {
						function()
							require("smart-splits").move_cursor_down()
						end,
						desc = "move cursor down",
					},
					["<c-k>"] = {
						function()
							require("smart-splits").move_cursor_up()
						end,
						desc = "move cursor up",
					},
					["<c-l>"] = {
						function()
							require("smart-splits").move_cursor_right()
						end,
						desc = "move cursor right",
					},
					["<c-\\>"] = {
						function()
							require("smart-splits").move_cursor_previous()
						end,
						desc = "move cursor previous",
					},
					-- quick save
					["<C-s>"] = { ":w!<cr>", desc = "Save File" }, -- change description but the same command
				},
				t = {
					-- setting a mapping to false will disable it
					-- ["<esc>"] = false,
				},
				i = {
					-- 添加 jk 映射为 Esc
					["jk"] = { "<Esc>", desc = "Escape insert mode" },
				},
			},
		},
	},
	{
		"AstroNvim/astrolsp",
		---@type AstroLSPOpts
		opts = {
			mappings = {
				n = {
					-- this mapping will only be set in buffers with an LSP attached
					K = {
						function()
							vim.lsp.buf.hover()
						end,
						desc = "Hover symbol details",
					},
					-- condition for only server with declaration capabilities
					gD = {
						function()
							vim.lsp.buf.declaration()
						end,
						desc = "Declaration of current symbol",
						cond = "textDocument/declaration",
					},
				},
			},
		},
	},
}
