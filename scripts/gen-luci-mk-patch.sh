#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
PATCH_DIR="$ROOT_DIR/patches"
PATCH_FILE="$PATCH_DIR/0001-fix-luci-mk-include.patch"

mkdir -p "$PATCH_DIR"
> "$PATCH_FILE"

echo "🔍 Scanning for '../../luci.mk' includes..."

# 遍历 packages 下的 Makefile
find packages -name Makefile -type f | while read -r mk; do
  # 只匹配真正的 include 行，避免注释
  if grep -qE '^[[:space:]]*include[[:space:]]+\.\./\.\./luci\.mk' "$mk"; then
    echo "⚡ Patching $mk"

    # 用 awk 替换，只改真正的 include 行
    awk '{
      if ($0 ~ /^[[:space:]]*include[[:space:]]+\.\.\/\.\.\/luci\.mk/) {
        sub(/\.\.\/\.\.\/luci\.mk/, "$(TOPDIR)/feeds/luci/luci.mk")
      }
      print
    }' "$mk" > "$mk.new"

    # 生成 diff 并追加到补丁文件
    diff -u "$mk" "$mk.new" >> "$PATCH_FILE" || true

    # 删除临时文件，保持源码干净
    rm -f "$mk.new"
  fi
done

# 判断补丁文件是否有内容
if [ -s "$PATCH_FILE" ]; then
  echo "📦 Patch generated at $PATCH_FILE"
else
  echo "✅ No Makefile needed patching."
  rm -f "$PATCH_FILE"
fi
