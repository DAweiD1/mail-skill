#!/bin/bash
# 把本仓库安装 / 更新到 ~/.agents/skills/mail-to-calendar。
# 用法：bash scripts/install.sh [目标目录]
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$HOME/.agents/skills/mail-to-calendar}"
CONFIG_DIR="$HOME/.config/mail-to-calendar"

if [ -z "$TARGET" ]; then
  echo "目标目录为空" >&2
  exit 1
fi

mkdir -p "$TARGET/bin"
cp "$DIR/bin/mail" "$TARGET/bin/mail"
cp "$DIR/SKILL.md" "$DIR/config.example.txt" "$TARGET/"
chmod +x "$TARGET/bin/mail"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/account.txt" ]; then
  cp "$DIR/config.example.txt" "$CONFIG_DIR/account.txt"
  chmod 600 "$CONFIG_DIR/account.txt"
  echo "已生成配置模板：$CONFIG_DIR/account.txt"
  echo "请填入 user 和 password（授权码），然后：$TARGET/bin/mail check"
else
  echo "配置已存在，未覆盖：$CONFIG_DIR/account.txt"
fi

echo "installed: $TARGET"
