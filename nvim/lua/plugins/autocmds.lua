
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        -- 删除行尾空格
        trim_trailing_whitespace = {
          {
            event = "BufWritePre", -- 在保存文件之前触发
            desc = "Delete Blank Space When Save Files",
            callback = function()
              local cursor_pos = vim.api.nvim_win_get_cursor(0)
              vim.cmd([[%s/\s\+$//e]])
              vim.cmd([[%s/\r//ge]])
              -- vim.cmd([[set ff=unix]])
              vim.api.nvim_win_set_cursor(0, cursor_pos)
            end,
          },
        },
        -- nvim <folder>: cd + non-floating dashboard (no auto neo-tree)
        handle_directory = {
          {
            event = "VimEnter",
            desc = "cd into directory arg and show a non-floating dashboard",
            callback = function()
              local dir = vim.fn.expand("%:p")
              if vim.fn.isdirectory(dir) == 1 then
                -- set working directory
                vim.cmd.cd(dir)
                -- close the directory buffer
                vim.cmd("bd")
                -- open dashboard in the current window (non-floating, so neo-tree won't be covered)
                require("snacks").dashboard.open { win = vim.api.nvim_get_current_win() }
              end
            end,
          },
        },
      },
    },
  },
}
