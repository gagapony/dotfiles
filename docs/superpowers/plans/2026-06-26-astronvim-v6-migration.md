# AstroNvim v5 → v6 迁移（含 nvim-treesitter main 分支）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 AstroNvim 从 v5.3.15 升级到 v6，使 nvim-treesitter 切到 main 分支，同时保留用户所有自定义功能。

**Architecture:** AstroNvim v6 的核心变更是 (1) nvim-treesitter 配置从独立的 plugin spec 移入 AstroCore 的 `opts.treesitter` 字段；(2) AstroLSP 迁移到 `vim.lsp.config` 后端。本配置只需改 3 个文件 + 重置 lock 文件，因为用户配置大量依赖 AstroNvim 默认值，而 v6 保持了这些默认值的 API 形状。

**Tech Stack:** AstroNvim v6, AstroCore v3, AstroLSP v3, nvim-treesitter (main), Neovim 0.11+（推荐 0.12）

---

## 前置条件与风险

| 项 | 当前状态 | 是否阻塞 | 说明 |
|---|---|---|---|
| Neovim 版本 | v0.11.5 | 否（满足 v6 最低 v0.11） | `lw` workspace diagnostics 映射需要 v0.12，其余功能在 0.11 正常。用户用 Nix 管理，升级 nvim 是独立操作 |
| tree-sitter CLI | 系统 PATH 无，Mason 内有 | 否 | mason-tool-installer 的 ensure_installed 已含 `tree-sitter-cli`；nvim-treesitter main 编译 parser 主要需要 C 编译器 |
| git 安全网 | dotfiles 仓库可回滚 | — | 第一步会 commit 当前状态作为回滚点 |

## 已审计且无需修改的文件

以下文件经逐行核对，v6 兼容，**不在本计划改动范围**：
- `lua/plugins/keymaps.lua` — mappings 格式 v6 兼容；无 `:LspInfo` 等已移除命令引用
- `lua/plugins/astrolsp.lua` — `handlers` 全为注释无默认函数需迁移；`config.clangd` 是 server 级配置 v6 保留；无根级 `capabilities`/`flags` 需移入 `config["*"]`
- `lua/plugins/mason.lua` — 用 mason-tool-installer（非改名对象）
- `lua/plugins/neo-tree.lua` `fzf.lua` `gitsigns.lua` `neogen.lua` `grug-far.lua` `which-key.lua` `none-ls.lua` `astroui.lua` `heirline.lua` — 普通 plugin opts，跨版本兼容
- `lua/community.lua` — blink-cmp 改名由 astrocommunity pack 内部处理；用户层面不改
- `lua/plugins/transparent.lua` — Ufo highlight groups 预留串，v6 移除 nvim-ufo 后无效但无害（保留）
- `lua/plugins/user.lua` — `require("config.hide_patterns")` 已确认存在（`lua/config/hide_patterns.lua`）；`lsp_signature.nvim` 独立 setup 不依赖 astrolsp 内部 API
- `lua/polish.lua` — `if true then return end` 完全未激活
- `lua/plugins/marks.lua` `disable.lua` `smear-cursor.lua` — 空/全注释

## File Structure

本计划涉及修改的文件：

- **修改** `nvim/lua/lazy_setup.lua` — 版本 pin `^5` → `^6`（总开关，1 行）
- **重写** `nvim/lua/plugins/treesitter.lua` — 从 override `nvim-treesitter` 改为 override `astrocore` 的 `opts.treesitter` 字段
- **修改** `nvim/lua/plugins/autocmds.lua` — `handle_directory` autocmd 里的 `require("alpha").start()` 用 pcall 健壮化（alpha 不在 lock 文件中，当前是死代码；v6 用 snacks.dashboard）
- **删除** `nvim/lazy-lock.json` — 大版本迁移，让 v6 的 lazy_snapshot 重新解析所有插件版本

---

## Task 1: 建立回滚安全网

**Files:**
- 无文件改动，纯 git 操作

- [ ] **Step 1: 确认 git 状态**

Run: `cd /home/gabriel/Dots/dotfiles && git status --short`
Expected: 显示 `M nvim/lazy-lock.json`（之前 sync 残留），其余工作区干净

- [ ] **Step 2: 提交当前状态作为 v5 回滚点**

Run:
```bash
cd /home/gabriel/Dots/dotfiles && git add -A && git commit -m "chore(nvim): snapshot before v6 migration"
```
Expected: commit 成功，记录此 commit hash 作为回滚锚点

- [ ] **Step 3: 记录回滚 hash**

Run: `cd /home/gabriel/Dots/dotfiles && git rev-parse --short HEAD`
Expected: 输出一个短 hash（例如 `a1b2c3d`），**记下来**，迁移出问题时用 `git reset --hard <hash>` 回滚

---

## Task 2: 切换 AstroNvim 版本到 v6

**Files:**
- Modify: `nvim/lua/lazy_setup.lua:4`

- [ ] **Step 1: 修改版本 pin**

在 `nvim/lua/lazy_setup.lua` 第 4 行，将：
```lua
    version = "^5", -- Remove version tracking to elect for nightly AstroNvim
```
改为：
```lua
    version = "^6", -- Remove version tracking to elect for nightly AstroNvim
```

- [ ] **Step 2: 确认改动**

Run: `cd /home/gabriel/Dots/dotfiles && git diff nvim/lua/lazy_setup.lua`
Expected: 仅 `^5` → `^6` 一处改动，无其他变化

---

## Task 3: 重写 treesitter 配置（迁移到 AstroCore）

这是核心改动。v6 下 `nvim-treesitter` main 分支删除了 `nvim-treesitter.configs` 模块，treesitter 的 ensure_installed / highlight / textobjects 全部改由 AstroCore 的 `opts.treesitter` 统一管理。AstroNvim v6 默认已开启 highlight、indent 和完整的 textobjects 映射（含 `af`/`if`/`ak`/`ik`/move/swap），因此用户只需声明 `ensure_installed`。

**Files:**
- Rewrite: `nvim/lua/plugins/treesitter.lua`

- [ ] **Step 1: 用新内容覆盖 treesitter.lua**

将 `nvim/lua/plugins/treesitter.lua` 全文替换为：
```lua
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
```

- [ ] **Step 2: 确认改动**

Run: `cd /home/gabriel/Dots/dotfiles && git diff nvim/lua/plugins/treesitter.lua`
Expected: 删除旧的 `main = "nvim-treesitter.configs"` + opts 块，替换为指向 astrocore 的新配置

---

## Task 4: 健壮化 dashboard autocmd

`autocmds.lua` 的 `handle_directory` 调用了 `require("alpha").start()`，但 alpha 不在当前 lazy-lock.json 中（死代码）。v6 改用 snacks.dashboard。用 pcall 检测使其对两种情况都安全，避免打开目录时报错。

**Files:**
- Modify: `nvim/lua/plugins/autocmds.lua:37-39`

- [ ] **Step 1: 替换 alpha 调用为健壮的 dashboard 打开逻辑**

在 `nvim/lua/plugins/autocmds.lua`，将这段：
```lua
                -- 打开 alpha 启动页
                require("alpha").start()
```
替换为：
```lua
                -- 打开 dashboard 启动页：v6 用 snacks.dashboard，兼容旧 alpha
                if package.loaded["snacks"] and require("snacks").dashboard then
                  require("snacks").dashboard.open()
                elseif pcall(require, "alpha") then
                  require("alpha").start()
                end
```

- [ ] **Step 2: 确认改动**

Run: `cd /home/gabriel/Dots/dotfiles && git diff nvim/lua/plugins/autocmds.lua`
Expected: 仅 dashboard 打开逻辑变化，trim_trailing_whitespace 等其余 autocmd 不变

---

## Task 5: 重置 lazy-lock.json

v5 的 lazy-lock.json 钉死了大量与 v6 API 不兼容的旧 commit（包括 nvim-treesitter master 分支、astrocore v1.x、neoconf、vim-illuminate 等）。大版本迁移必须让 v6 的 lazy_snapshot 重新解析全部版本。

**Files:**
- Delete: `nvim/lazy-lock.json`

- [ ] **Step 1: 删除 lock 文件**

Run: `rm /home/gabriel/Dots/dotfiles/nvim/lazy-lock.json`
Expected: 文件删除成功（Task 1 已 commit 旧版本到 git，可随时恢复）

---

## Task 6: 执行同步（headless）

让 Lazy 基于 `version = "^6"` 重新克隆/更新所有插件。

- [ ] **Step 1: 运行 sync**

Run: `cd /home/gabriel/Dots/dotfiles && bash scripts/nvim_tool.sh sync`
Expected:
- Lazy 首次运行会下载较长时间（核心插件版本切换 + 重新克隆 nvim-treesitter/textobjects）
- 末尾输出 `✓ lazy-lock.json updated`
- **退出码 0**

- [ ] **Step 2: 如果 sync 报错（非零退出码）**

常见报错与处理（按概率排序）：
1. **`module 'nvim-treesitter.configs' not found`** — 说明有残留的旧 API override。Run: `grep -rn "nvim-treesitter.configs\|nvim-treesitter\".*main" nvim/lua/`，清除任何遗漏
2. **某 community pack 报旧 API** — 该 pack 尚未适配 v6。在 `community.lua` 注释掉对应 `{ import = ... }` 行后重试
3. **网络/克隆失败** — 重跑 `bash scripts/nvim_tool.sh sync`（Lazy 幂等）

每次修复后重跑 Step 1 直到退出码 0。

- [ ] **Step 3: 确认新 lock 文件已生成且指向 main 分支**

Run:
```bash
cd /home/gabriel/Dots/dotfiles && grep -E "nvim-treesitter|AstroNvim\"|astrocore" nvim/lazy-lock.json
```
Expected:
- `nvim-treesitter` 的 `branch` 为 `"main"`（不再是 master）
- `AstroNvim` commit 变为新的（v6 系列）
- `neoconf.nvim` / `vim-illuminate` 条目消失

- [ ] **Step 4: 验证 AstroCore/AstroLSP/AstroUI 升到了 v3/v4（关键！）**

> **执行中发现的坑**：`Lazy sync` 在删除 lock 后基于"已安装"状态重建 lock，**不会强制把已存在的核心插件跨大版本升级**。AstroNvim/nvim-treesitter 因分支/版本变化被重新 clone，但 astrocore/astrolsp/astroui 的旧 clone（v2/v3）会被保留，导致 `astrocore.treesitter` 模块缺失、treesitter 配置静默失效、AstroLSP 新 API 不可用。

Run:
```bash
for p in astrocore astrolsp astroui; do printf "%s: " "$p"; git -C ~/.local/share/nvim/lazy/$p describe --tags 2>/dev/null; done
```
Expected: `astrocore: v3.x` / `astrolsp: v4.x` / `astroui: v4.x`。若任一仍为旧版，强制重新 clone：
```bash
rm -rf ~/.local/share/nvim/lazy/{astrocore,astrolsp,astroui} && bash scripts/nvim_tool.sh sync
```

---

## Task 7: 健康检查与交互式验证

headless sync 成功不代表配置可用，必须做交互式验证。

- [ ] **Step 1: headless 启动测试（快速失败检测）**

Run:
```bash
cd /home/gabriel/Dots/dotfiles && nvim --headless +'lua print("startup OK")' +qa 2>&1 | tail -20
```
Expected: 输出 `startup OK`，无 `[Error]` / `E5108` 等 Lua 报错

- [ ] **Step 2: parser 安装确认**

Run:
```bash
cd /home/gabriel/Dots/dotfiles && nvim --headless +'lua print(vim.inspect(require("astrocore.treesitter").get_installed()))' +qa 2>&1 | tail -20
```
Expected: 列出 lua/vim/c/cpp/nix/python/markdown 等 parser

- [ ] **Step 3: 交互式验证清单**

Run: `cd /home/gabriel/Dots/dotfiles && bash scripts/nvim_tool.sh nvim`
在 nvim 中逐项验证：
- [ ] 打开一个 `.lua` 文件 → 语法高亮正常（treesitter highlight）
- [ ] 在函数体内按 `af` → 选中整个函数（textobjects）
- [ ] 在函数体内按 `if` → 选中函数内部
- [ ] 按 `ak` → 选中代码块（验证 AstroNvim 默认 textobjects 未丢失）
- [ ] `:LspInfo` 是否报错 → 应被替换；用 `:checkhealth vim.lsp` 代替
- [ ] 打开一个 LSP 项目（如 lua 文件）→ `gd` 跳转定义正常（fzf-lua 或原生）
- [ ] 按 `K` → hover 文档正常
- [ ] `:Neotree` 正常开关
- [ ] 状态栏（heirline）显示正常，含 treesitter 图标
- [ ] 从命令行 `nvim .`（打开目录）→ 不报错，dashboard 正常显示

- [ ] **Step 4: TSUpdate 确保所有 parser 最新**

Run: `cd /home/gabriel/Dots/dotfiles && nvim --headless +TSUpdate +qa`
Expected: 无报错退出

---

## Task 8: 提交迁移结果

**Files:**
- 全部改动

- [ ] **Step 1: 审查完整 diff**

Run: `cd /home/gabriel/Dots/dotfiles && git diff && git status`
Expected: 改动限于：
- `nvim/lua/lazy_setup.lua`（version）
- `nvim/lua/plugins/treesitter.lua`（重写）
- `nvim/lua/plugins/autocmds.lua`（dashboard）
- `nvim/lazy-lock.json`（重新生成）
- `docs/superpowers/plans/2026-06-26-astronvim-v6-migration.md`（本计划）

- [ ] **Step 2: 提交**

Run:
```bash
cd /home/gabriel/Dots/dotfiles && git add -A && git commit -m "$(cat <<'EOF'
feat(nvim): migrate AstroNvim v5 -> v6 (nvim-treesitter main branch)

- lazy_setup: version ^5 -> ^6
- treesitter: move config to astrocore.opts.treesitter (main branch API)
- autocmds: robust dashboard open (snacks preferred, alpha fallback)
- lazy-lock: regenerated for v6 snapshot

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## 回滚策略

如果验证阶段发现不可修复的问题，回滚到 Task 1 记录的 hash：

```bash
cd /home/gabriel/Dots/dotfiles
git reset --hard <Task1-Step3-记录的hash>
bash scripts/nvim_tool.sh sync   # 恢复 v5 插件状态
```

注意：Lazy 的 data 目录（`~/.local/share/nvim/lazy/`）在 v6 sync 后可能含有 main 分支的 nvim-treesitter clone。回滚后运行 sync 会让 Lazy 自动切回 master 分支；若出现 clone 状态混乱，删除该插件目录后重跑 sync：
```bash
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter-textobjects
```

---

## 自审笔记

- **Spec coverage**：迁移指南的核心 breaking changes 全覆盖 —— version pin、treesitter 重写、AstroLSP（已审计无需改）、改名插件（community 内部处理）、移除插件（随 snapshot 清理）、LSP 命令（无引用）、winborder（用户未自定义，用默认）、`lw` 新映射（自动获得）。
- **nvim 0.11.5 短板**：已在风险表标注，非阻塞。如需 0.12 完整体验，用户可单独升级 Nix 的 neovim 包。
- **alpha 死代码**：lock 文件无 alpha 条目，证实 `require("alpha")` 当前即为死代码，Task 4 的 pcall 写法使其在 v6 下安全且向前兼容。
- **treesitter 最小配置**：v6 AstroCore 默认开启 highlight/indent/完整 textobjects，故只声明 ensure_installed，避免重蹈 v5「覆盖默认 textobjects」的覆辙。
