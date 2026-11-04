# Dotfiles：Linux / Apple Silicon macOS

Flake 同时导出 `packages.x86_64-linux` 和 `packages.aarch64-darwin`：

| 包 | 内容与布局 |
|---|---|
| `zsh-config` | 固定 revision/hash 的 Powerlevel10k → `config/custom/themes/powerlevel10k/`；本地 `zsh/.p10k.zsh` → `config/custom/themes/.p10k.zsh` |
| `nvim-config` | 本地 `nvim/` → `config/nvim/`（不含其中 README） |
| `tmux-config` | 固定 revision/hash 的 gpakosz/.tmux → `config/.tmux.conf`；本地 `tmux/.tmux.conf.local` → `config/.tmux.conf.local` |

三个包仍使用原来的配置复制构建，包名、布局及上游固定源不变。
Zsh 包只有主题及其配置，并不是完整 `.zshrc`。编辑本地文件会进入上述映射；
上游 Powerlevel10k 和 `.tmux.conf` 不来自本地同名副本，不应通过无效本地副本修改它们。

## 平台差异与运行依赖

- Tmux 的 vi copy-mode `y`：macOS 使用原生 `pbcopy`；Linux 保留 `xclip -selection clipboard -i`。
  已审查锁定的上游 `.tmux.conf`，其普通 clipboard 绑定已有 pbcopy 探测，无需修改固定源。
  此处只修复本地覆盖绑定；Linux 仍需安装 xclip，不擅自改为 Wayland 行为。
- Neovim 保留既有 `tmux` / `osc52` 默认选择，没有 Linux 专用硬编码。
  可用 `:ClipboardProvider system` 交给 Neovim 系统检测（Mac 应检测 pbcopy/pbpaste）；
  `:ClipboardProvider tmux` / `osc52` 取决于终端、Tmux 和 SSH 链路能力，需实机验证。
- Neovim 首次启动会下载 Lazy/AstroNvim 插件；现有 Git 下载代理 `gh-proxy.com` 未改动。
  Mason 会下载 lua-language-server、clangd、stylua、pyright、tree-sitter-cli、clang-format，
  需要网络、Python/Node 及相应编译工具。`lazy-lock.json` 不锁定 Mason 下载，主 Nix lock
  也不固定所有运行时下载。未运行 Neovim 配置启动，避免自动下载和改写用户数据。
- Tmux 插件（Catppuccin、yank、cpu、resurrect、continuum 等）仍由既有插件管理逻辑处理，
  不由本 Flake 构建或锁定。未运行完整 Tmux 配置，Mac 插件运行兼容性待实机确认。
- Powerlevel10k 字体/终端能力以及 Mac 系统剪贴板权限仍需实机验证。

## 验证（不激活、不安装到用户环境）

```sh
# path: 包含尚未被 Git 跟踪的新增文件；不要把敏感文件或运行产物放进工作区。
nix flake show --all-systems "path:$PWD"
for system in x86_64-linux aarch64-darwin; do
  for package in zsh-config nvim-config tmux-config; do
    nix eval --raw "path:$PWD#packages.$system.$package.drvPath"
  done
done
# Linux 上只构建 Linux 包；目标 Mac 上将平台换为 aarch64-darwin。
for package in zsh-config nvim-config tmux-config; do
  nix build --no-link "path:$PWD#packages.x86_64-linux.$package"
done
```

本地验证使用了 `tests/check.py`（按用户要求不提交，克隆后不包含此文件）。
该脚本需要 Python 3、Nix 和 Tmux：检查六个输出及真实 derivation 平台，
然后在临时 socket 的 Tmux server 中模拟 Linux/Darwin 的 uname，仅加载复制绑定片段，
验证最终键绑定；结束即清理 server，不读取个人 Tmux 配置、不下载插件、不操作剪贴板。
这不是 Mac 实际执行 pbcopy 的测试。

本次 Linux x86_64 验证：六包求值、Linux 三包构建、上述回归测试均 exit 0。
改前 Linux 三包也构建成功；改后 Zsh/Neovim 产物内容完全一致，Tmux 仅上述绑定变化。
三个 Linux drvPath 均变化，因为原有 derivation 引用了整个 `self` 源，文档/测试/flake
变更也会改变输入路径，不代表这三个配置的运行语义均发生改变。未修改 flake.lock。
没有 Darwin builder，本次未实际构建 Darwin 包、运行 Mac 应用或激活任何系统。
本次详细命令日志在执行机器 `/tmp/dotfiles-darwin/`，不提交进仓库。

## 与 nixosdots 的交接

本次适配只修改 dotfiles，不修改 nixosdots。可先临时验证本地输入：

```sh
cd /absolute/path/to/nixosdots
nix eval --raw "path:$PWD#darwinConfigurations.macmini.system.drvPath" \
  --override-input dotfiles path:/absolute/path/to/dotfiles --no-write-lock-file
```

**当前 nixosdots 的 Darwin profile 仍使用原生 HM 配置，没有消费这些包。**
因此 override 求值成功不代表接入完成；下一步需单独审查 HM 文件映射与现有文件冲突，
不能直接导入原有 Linux Zsh/Tmux 模块或其删除配置目录的激活钩子。
推送后才能按新的远端提交更新主仓库 lock；本地提交本身不会更新远端或主仓库引用。
