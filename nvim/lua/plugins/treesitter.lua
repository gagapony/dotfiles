-- v6: treesitter 配置已迁移到 AstroCore 的 opts.treesitter
-- highlight / indent / textobjects 默认由 AstroNvim v6 开启（含完整映射）
-- 这里只声明需要预装 parser 的语言列表
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      ensure_installed = {
        "lua",
        "vim",
        "c",
        "cpp",
        "nix",
        "python",
        "markdown",
        -- add more arguments for adding more treesitter parsers
      },
    },
  },
}
