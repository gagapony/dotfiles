#!/bin/bash
# dotfiles 工具脚本入口
# 用 dotfiles/nvim 作为配置目录运行 nvim 相关操作，
# 绕过 Nix store 只读限制。
#
# 用法：scripts.sh <command>
#   sync    安装/更新/清理插件，更新 lazy-lock.json
#   update  更新插件到最新版本，更新 lazy-lock.json
#   nvim    用 dotfiles 配置启动交互式 nvim（快速验证）
#   help    显示帮助

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
export XDG_CONFIG_HOME="$DOTFILES"

cmd="${1:-help}"

usage() {
  cat <<EOF
用法: $(basename "$0") <command>

命令:
  sync    Lazy sync  — 安装/更新/清理插件，更新 lazy-lock.json
  update  Lazy update — 更新插件到最新版本，更新 lazy-lock.json
  nvim    用 dotfiles/nvim 配置启动交互式 nvim（快速验证）
  help    显示此帮助

示例:
  $(basename "$0") sync        # 新增/删除插件后更新 lockfile
  $(basename "$0") nvim        # 快速验证配置改动
EOF
}

case "$cmd" in
  sync)
    echo ">> Lazy sync（$DOTFILES/nvim）..."
    nvim --headless +'Lazy! sync' +qa
    echo "✓ lazy-lock.json 已更新"
    echo "检查改动: git -C \"$DOTFILES\" diff nvim/lazy-lock.json"
    ;;
  update)
    echo ">> Lazy update（$DOTFILES/nvim）..."
    nvim --headless +'Lazy! update' +qa
    echo "✓ lazy-lock.json 已更新"
    echo "检查改动: git -C \"$DOTFILES\" diff nvim/lazy-lock.json"
    ;;
  nvim)
    echo ">> 启动 nvim（配置目录: $DOTFILES/nvim）..."
    exec nvim "${@:2}"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "未知命令: $cmd"
    echo
    usage
    exit 1
    ;;
esac
