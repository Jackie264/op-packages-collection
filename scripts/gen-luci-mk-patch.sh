#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="patches"
PATCH_FILE="$PATCH_DIR/0001-fix-luci-mk-include.patch"

mkdir -p "$PATCH_DIR"

echo "🔍 Scanning for '../../luci.mk' includes..."
MODIFIED_FILES=()

# 扫描并替换
while IFS= read -r mk; do
  if grep -q "include ../../luci.mk" "$mk"; then
    echo "⚡ Patching $mk"
    sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' "$mk"
    MODIFIED_FILES+=("$mk")
  fi
done < <(find packages -name Makefile -type f)

# 如果有修改，生成补丁
if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
  echo "📦 Generating patch at $PATCH_FILE"
  git diff -- "${MODIFIED_FILES[@]}" > "$PATCH_FILE"

  # 恢复被修改的文件，避免污染源码
  git checkout -- "${MODIFIED_FILES[@]}"
else
  echo "✅ No Makefile needed patching, skipping patch generation."
fi
