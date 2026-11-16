#!/usr/bin/env bash
# 打包「可直接下载的源码包」：只含源码 + 用到的 assets，剔除 .git、隐藏目录、
# build 产物、文档目录（docs/、dart2js-syntax-reference/）与发布用的二进制。
#
#   bash tool/package_source.sh
#
# 产物：docs/downloads/flutter_hot_patch-source.zip（同名覆盖）。
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="docs/downloads/flutter_hot_patch-source.zip"
NAME="flutter_hot_patch"
mkdir -p docs/downloads
rm -f "$OUT"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

rsync -a \
  --exclude '.git' \
  --exclude '.*/' \
  --exclude '.dart_tool' \
  --exclude '.idea' \
  --exclude '.fvm' \
  --exclude '.fvmrc' \
  --exclude '.trae' \
  --exclude '.trae-html-share-packages' \
  --exclude '.screenshots' \
  --exclude '.DS_Store' \
  --exclude '.*' \
  --exclude 'build' \
  --exclude '*.iml' \
  --exclude 'Pods' \
  --exclude '.symlinks' \
  --exclude '.gradle' \
  --exclude 'example/patch' \
  --exclude 'docs' \
  --exclude 'dart2js-syntax-reference' \
  --exclude 'docs/downloads' \
  ./ "$STAGE/$NAME/"

(cd "$STAGE" && zip -qry "$OLDPWD/$OUT" "$NAME")

echo "打包完成：$OUT ($(du -h "$OUT" | cut -f1))"
