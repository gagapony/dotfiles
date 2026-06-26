
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
        handle_directory = {
          {
            event = "VimEnter",
            desc = "Handle directory open and set working directory",
            callback = function()
              local dir = vim.fn.expand("%:p")
              if vim.fn.isdirectory(dir) == 1 then
                -- 设置工作目录
                vim.cmd.cd(dir)
                -- 关闭默认打开的 buffer
                vim.cmd("bd")
                -- 确保 neo-tree 是关闭的
                if package.loaded["neo-tree"] then
                  vim.cmd("Neotree close")
                end
                -- 打开 dashboard 启动页：v6 用 snacks.dashboard，兼容旧 alpha
                if package.loaded["snacks"] and require("snacks").dashboard then
                  require("snacks").dashboard.open()
                elseif pcall(require, "alpha") then
                  require("alpha").start()
                end
              end
            end,
          },
        },
      },
    },
  },
}

