-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
	"AstroNvim/astrocore",
	---@type AstroCoreOpts
	opts = {
		-- Configure core features of AstroNvim
		features = {
			large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
			autopairs = true, -- enable autopairs at start
			cmp = true, -- enable completion at start
			diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      		diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
			highlighturl = true, -- highlight URLs at start
			notifications = true, -- enable notifications at start
		},
		-- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
		diagnostics = {
			virtual_text = true,
			underline = true,
		},
		-- passed to `vim.filetype.add`
    	filetypes = {
      		-- see `:h vim.filetype.add` for usage
      		extension = {
        		foo = "fooscript",
      		},
      		filename = {
        		[".foorc"] = "fooscript",
      		},
      		pattern = {
        		[".*/etc/foo/.*"] = "fooscript",
      		},
    	},

		-- vim options can be configured here
		options = {
			opt = { -- vim.opt.<key>
				expandtab = true;
				shiftwidth = 4,
				tabstop = 4,
				softtabstop = 4,
				relativenumber = true, -- sets vim.opt.relativenumber
				number = true, -- sets vim.opt.number
				spell = false, -- sets vim.opt.spell
				signcolumn = "yes", -- sets vim.opt.signcolumn to yes
				wrap = false, -- sets vim.opt.wrap
				colorcolumn = "120";
				winborder = "none", -- flat style: no drawn lines around diagnostic floats, hover, signature, terminal, ...
				clipboard = "unnamedplus";
				fillchars = { vert = " " }, -- hide the vertical window separator; separate windows by bg color instead
			},
			g = { -- vim.g.<key>
				-- configure global vim variables (vim.g)
			},
		},
	},
}
