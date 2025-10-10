#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="patches"
PATCH_FILE="$PATCH_DIR/0001-fix-luci-mk-include.patch"

# 确保补丁目录存在
mkdir -p "$PATCH_DIR"

# 保存当前修改状态
git add packages

# 扫描并替换所有 Makefile 中的 include ../../luci.mk
echo "🔍 Scanning for '../../luci.mk' includes..."
find packages -name Makefile -type f | while read -r mk; do
  if grep -q "include ../../luci.mk" "$mk"; then
    echo "⚡ Patching $mk"
    sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' "$mk"
  fi
done

git -c status.submodulesummary=false diff

# 如果有修改，生成补丁
if ! git diff --quiet; then
  echo "📦 Generating patch at $PATCH_FILE"
  git diff > "$PATCH_FILE"

  # 只恢复顶层 Git 已跟踪的文件，避免 warning
  tracked_files=$(git diff --name-only | xargs -r git ls-files --error-unmatch 2>/dev/null || true)
  if [ -n "$tracked_files" ]; then
    git checkout -- $tracked_files
  fi
else
  echo "✅ No Makefile needed patching."
fi
