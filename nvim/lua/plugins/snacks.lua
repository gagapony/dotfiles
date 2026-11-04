-- Snacks picker + notifier styling, ported from nvim_custom.
-- The nvim_custom source depended on its core.* framework; those deps are
-- inlined here as plain Neovim API so no core.* is imported:
--   core.hl.get(name, fb)            -> hl_get  (nvim_get_hl + to_hex + reverse + fallback)
--   core.event.on("theme:changed",f) -> ColorScheme autocmd registered in init

-- to_hex mirrors core.hl.to_hex: number -> "#rrggbb", nil -> "none", else as-is.
local function to_hex(v)
	if v == nil then
		return "none"
	end
	if type(v) == "number" then
		return string.format("#%06x", v)
	end
	return v
end

-- Read a highlight group as {fg=,bg=,sp=} of hex strings ("#rrggbb" or "none"),
-- resolving links and `reverse`, falling back to `fallback` when undefined.
-- Faithful port of core.hl.get.
local function hl_get(name, fallback)
	local hl = vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
	if vim.tbl_isempty(hl) then
		hl = (fallback and vim.deepcopy(fallback)) or {}
	end
	if hl.reverse then
		hl.fg, hl.bg = hl.bg, hl.fg
		hl.reverse = nil
	end
	hl.fg = to_hex(hl.fg or (fallback and fallback.fg))
	hl.bg = to_hex(hl.bg or (fallback and fallback.bg))
	hl.sp = to_hex(hl.sp)
	return hl
end

-- Convert a hl attr table's "#rrggbb" string values to 0xrrggbb ints for snacks
-- (which wants numeric colors). "none" -> nil.
local function picker_attr(name, fallback)
	local attr = hl_get(name, fallback)
	for _, key in ipairs({ "fg", "bg", "sp" }) do
		if type(attr[key]) == "string" and attr[key]:match("^#%x%x%x%x%x%x$") then
			attr[key] = tonumber(attr[key]:sub(2), 16)
		elseif attr[key] == "none" then
			attr[key] = nil
		end
	end
	return attr
end

local function picker_color(value)
	if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
		return tonumber(value:sub(2), 16)
	end
	return value ~= "none" and value or nil
end

local function picker_blend(fg, bg, alpha)
	if not fg then
		return bg
	end
	if not bg then
		return fg
	end
	local function ch(value, shift)
		return math.floor(value / shift) % 256
	end
	local r = ch(fg, 0x10000) * alpha + ch(bg, 0x10000) * (1 - alpha)
	local g = ch(fg, 0x100) * alpha + ch(bg, 0x100) * (1 - alpha)
	local b = ch(fg, 0x1) * alpha + ch(bg, 0x1) * (1 - alpha)
	return math.floor(r + 0.5) * 0x10000 + math.floor(g + 0.5) * 0x100 + math.floor(b + 0.5)
end

-- Borderless notifier render: drops the window border (compact/fancy draw the title
-- onto the border) and instead inlines icon + title into the first message line.
-- The icon+title prefix is highlighted with the level accent (via an extmark) so
-- the popup keeps a visual anchor even without a border.
local function notifier_render(buf, notif, ctx)
	ctx.opts.border = "none"
	local lines = vim.split(notif.msg, "\n")
	local title = vim.trim((notif.title or "") .. " " .. (notif.icon or ""))
	if title ~= "" then
		lines[1] = title .. "  " .. (lines[1] or "")
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	if title ~= "" then
		vim.api.nvim_buf_set_extmark(buf, ctx.ns, 0, 0, {
			end_col = #title,
			hl_group = ctx.hl.title,
		})
	end
end

-- Tint each notification level so the borderless popups still read as distinct
-- floating surfaces. Body uses base fg; window bg is editor bg blended with the
-- level accent (~18%).
local function setup_notifier_colors()
	local normal = picker_attr("Normal", { fg = 0xcdd6f4, bg = 0x1e1e2e })
	local base_bg = normal.bg or 0x1e1e2e
	local base_fg = normal.fg or 0xcdd6f4
	local crust = picker_color("#11111b")

	local levels = {
		Error = { "DiagnosticError", "#f38ba8" },
		Warn = { "DiagnosticWarn", "#f9e2af" },
		Info = { "DiagnosticInfo", "#89b4fa" },
		Debug = { "DiagnosticHint", "#94e2d5" },
		Trace = { "Special", "#cba6f7" },
	}

	for level, spec in pairs(levels) do
		local ac = picker_attr(spec[1], { fg = picker_color(spec[2]) }).fg or picker_color(spec[2])
		local bg = picker_blend(ac, base_bg, 0.18)
		vim.api.nvim_set_hl(0, "SnacksNotifier" .. level, { fg = base_fg, bg = bg })
		vim.api.nvim_set_hl(0, "SnacksNotifierTitle" .. level, { fg = ac, bg = bg, bold = true })
		vim.api.nvim_set_hl(0, "SnacksNotifierIcon" .. level, { fg = ac, bg = bg })
		vim.api.nvim_set_hl(0, "SnacksNotifierBorder" .. level, { fg = bg, bg = bg })
	end

	-- unlevelled: darken base toward crust for a subtle float
	vim.api.nvim_set_hl(0, "SnacksNotifier", { fg = base_fg, bg = picker_blend(base_bg, crust, 0.4) })
	local accent_fg = picker_attr("Special", { fg = picker_color("#cba6f7") }).fg
	vim.api.nvim_set_hl(0, "SnacksNotifierTitle", { fg = accent_fg, bold = true })
end

local function setup_picker_highlights()
	local normal = picker_attr("Normal", { fg = 0xcdd6f4, bg = 0x1e1e2e })
	local float = picker_attr("NormalFloat", normal)
	local status = picker_attr("StatusLine", float)
	local visual = picker_attr("Visual", status)
	local pmenu = picker_attr("Pmenu", float)

	local base_bg = float.bg or normal.bg
	local input_bg = picker_blend(status.bg or visual.bg, base_bg, 0.45)
	local list_bg = picker_blend(pmenu.bg, base_bg, 0.35)
	local preview_bg = picker_blend(visual.bg, base_bg, 0.22)
	local fg = float.fg or normal.fg

	vim.api.nvim_set_hl(0, "SnacksPickerInput", { fg = fg, bg = input_bg })
	vim.api.nvim_set_hl(0, "SnacksPickerList", { fg = fg, bg = list_bg })
	vim.api.nvim_set_hl(0, "SnacksPickerPreview", { fg = fg, bg = preview_bg })
end

local function apply_snacks_colors()
	setup_picker_highlights()
	setup_notifier_colors()
end

return {
	{
		"folke/snacks.nvim",
		-- Paint once now (safe: only nvim_set_hl). If the colorscheme isn't loaded
		-- yet, fallback colors are used; the ColorScheme autocmd below re-paints with
		-- the real palette once the theme loads (and on every later theme switch).
		init = function()
			local grp = vim.api.nvim_create_augroup("snacks_custom_colors", { clear = true })
			vim.api.nvim_create_autocmd("ColorScheme", { group = grp, callback = apply_snacks_colors })
			apply_snacks_colors()
		end,
		-- Merge into AstroNvim's snacks opts (do NOT override `config`).
		opts = function(_, opts)
			opts = opts or {}
			opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
				enabled = true,
				ui_select = true, -- replace vim.ui.select with the borderless picker
				layout = {
					preset = function()
						return vim.o.columns >= 120 and "gagapony" or "gagapony_vertical"
					end,
				},
				layouts = {
					gagapony = {
						layout = {
							box = "horizontal",
							backdrop = false,
							width = 0.82,
							min_width = 120,
							height = 0.82,
							border = "none",
							{
								box = "vertical",
								{
									win = "input",
									height = 1,
									border = "none",
									title = "{title} {live} {flags}",
									title_pos = "left",
								},
								{ win = "list", border = "none" },
							},
							{ win = "preview", title = "{preview}", border = "none", width = 0.48, title_pos = "left" },
						},
					},
					gagapony_vertical = {
						layout = {
							box = "vertical",
							backdrop = false,
							width = 0.72,
							min_width = 80,
							height = 0.82,
							min_height = 30,
							border = "none",
							{
								win = "input",
								height = 1,
								border = "none",
								title = "{title} {live} {flags}",
								title_pos = "left",
							},
							{ win = "list", border = "none" },
							{
								win = "preview",
								title = "{preview}",
								border = "none",
								height = 0.42,
								title_pos = "left",
							},
						},
					},
					gagapony_bottom = {
						layout = {
							box = "vertical",
							backdrop = false,
							row = -1,
							width = 0,
							height = 0.4,
							min_height = 12,
							border = "none",
							{
								win = "input",
								height = 1,
								border = "none",
								title = "{title} {live} {flags}",
								title_pos = "left",
							},
							{ win = "list", border = "none" },
							-- preview node must exist for the window to be enabled; the `lines` source
							-- uses preview = "main", so it overlays the editor window above the picker
							{ win = "preview", border = "none" },
						},
					},
					-- Borderless select layout, modelled on snacks' built-in `select` preset.
					gagapony_select = {
						hidden = { "preview" },
						layout = {
							backdrop = false,
							width = 0.5,
							min_width = 40,
							height = 0.4,
							min_height = 2,
							box = "vertical",
							border = "none",
							title = "{title}",
							title_pos = "center",
							{ win = "input", height = 1, border = "none" },
							{ win = "list", border = "none" },
						},
					},
				},
				win = {
					input = {
						border = "none",
						wo = {
							winhighlight = "Normal:SnacksPickerInput,NormalFloat:SnacksPickerInput",
						},
					},
					list = {
						border = "none",
						wo = {
							winhighlight = "Normal:SnacksPickerList,NormalFloat:SnacksPickerList,CursorLine:Visual",
						},
					},
					preview = {
						border = "none",
						wo = {
							winhighlight = "Normal:SnacksPickerPreview,NormalFloat:SnacksPickerPreview",
						},
					},
				},
				sources = {
					files = { exclude = require("config.hide_patterns") },
					grep = { exclude = require("config.hide_patterns") },
					grep_word = { exclude = require("config.hide_patterns"), live = true },
					lines = {
						layout = {
							preset = "gagapony_bottom",
						},
					},
					select = { layout = { preset = "gagapony_select" } },
				},
			})
			opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
				enabled = true,
				timeout = 3000,
				style = notifier_render,
			})
			opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
				notification = {
					zindex = 100,
					ft = "markdown",
					wo = { winblend = 5, wrap = false, conceallevel = 2, colorcolumn = "" },
					bo = { filetype = "snacks_notif" },
				},
			})
			return opts
		end,
	},
}
