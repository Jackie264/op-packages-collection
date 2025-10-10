#!/usr/bin/env bash
set -euo pipefail

# 使用绝对路径，避免 cd 子模块后路径丢失
ROOT_DIR="$(pwd)"
PATCH_DIR="$ROOT_DIR/patches"
PATCH_FILE="$PATCH_DIR/0001-fix-luci-mk-include.patch"

mkdir -p "$PATCH_DIR"
> "$PATCH_FILE"

echo "🔍 Scanning for '../../luci.mk' includes..."
MODIFIED=0

# 遍历 packages 下的 Makefile
find packages -name Makefile -type f | while read -r mk; do
  # 只匹配真正的 include 行，避免注释
  if grep -qE '^[[:space:]]*include[[:space:]]+\.\./\.\./luci\.mk' "$mk"; then
    echo "⚡ Patching $mk"

    subdir=$(dirname "$mk")

    (
      cd "$subdir"

      # 用 awk 替换，只改真正的 include 行
      awk '{
        if ($0 ~ /^[[:space:]]*include[[:space:]]+\.\.\/\.\.\/luci\.mk/) {
          sub(/\.\.\/\.\.\/luci\.mk/, "$(TOPDIR)/feeds/luci/luci.mk")
        }
        print
      }' Makefile > Makefile.new && mv Makefile.new Makefile

      # 在子模块内部生成 diff，写到绝对路径
      git diff Makefile >> "$PATCH_FILE" || true

      # 恢复文件，保持子模块干净
      git checkout -- Makefile
    )

    MODIFIED=1
  fi
done

if [ $MODIFIED -eq 1 ]; then
  echo "📦 Patch generated at $PATCH_FILE"
else
  echo "✅ No Makefile needed patching."
  rm -f "$PATCH_FILE"
fi
