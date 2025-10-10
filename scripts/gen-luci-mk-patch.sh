#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="patches"
PATCH_FILE="$PATCH_DIR/0001-fix-luci-mk-include.patch"

mkdir -p "$PATCH_DIR"

echo "🔍 Scanning for '../../luci.mk' includes..."
> "$PATCH_FILE"   # 清空旧补丁

MODIFIED=0

# 扫描 packages 下的 Makefile
while IFS= read -r mk; do
  if grep -q "include ../../luci.mk" "$mk"; then
    echo "⚡ Patching $mk"

    # 备份原文件
    cp "$mk" "$mk.orig"

    # 替换
    sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' "$mk"

    # 生成 diff 并追加到补丁文件
    # diff -u "$mk.orig" "$mk" >> "$PATCH_FILE" || true
    diff -u "$mk.orig" "$mk" | sed "s|^\(--- \|+++ \)$mk|\1$mk|" >> "$PATCH_FILE" || true

    # 恢复原文件
    mv "$mk.orig" "$mk"

    MODIFIED=1
  fi
done < <(find packages -name Makefile -type f)

if [ $MODIFIED -eq 1 ]; then
  echo "📦 Patch generated at $PATCH_FILE"
else
  echo "✅ No Makefile needed patching, skipping patch generation."
  rm -f "$PATCH_FILE"
fi
