#!/usr/bin/env bash
# 构建 macOS release 包并发布到 docs/downloads/。
#
# 为什么打包前必须重签：
#   `flutter build macos` 产出的 app 是 ad-hoc 签名（flags=0x2(adhoc)），但构建
#   过程会改写 Frameworks 下的嵌套产物，导致 `spctl -a` 报
#   "nested code is modified or invalid"。本地直接运行不受影响（没有
#   com.apple.quarantine），一旦通过浏览器下载，zip 带上 quarantine →
#   解压后的 app 被 Gatekeeper 判为「已损坏，无法打开」。
#   对 app 做一次 ad-hoc 深度重签可让嵌套签名自洽（codesign --verify --deep
#   --strict 通过），下载后提示变为「无法验证开发者」，右键打开即可运行。
#
# 真正「下载即双击打开」需要 Developer ID Application 证书 + notarize + staple，
# 本机没有该证书时这一步做不到，详见 zip 内的「说明.txt」。
#
# 用法：
#   bash tool/package_macos.sh            # 重新构建 + 重签 + 打包
#   bash tool/package_macos.sh --skip-build   # 复用已有产物，只重签 + 打包
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"
APP_REL="example/build/macos/Build/Products/Release/flutter_hot.app"
OUT_ZIP="$REPO_ROOT/docs/downloads/flutter_hot_patch-macos.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ "${1:-}" != "--skip-build" ]; then
  echo "[mac] 构建 release ..."
  ( cd example && fvm flutter build macos --release --no-tree-shake-icons )
fi

APP="$REPO_ROOT/$APP_REL"
if [ ! -d "$APP" ]; then
  echo "[mac] 未找到 $APP_REL，先构建（去掉 --skip-build）"
  exit 1
fi

echo "[mac] ad-hoc 深度重签（修嵌套签名）..."
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "[mac] 签名校验通过；spctl 判定（未公证时必为 rejected，属预期）："
spctl -a -vv "$APP" 2>&1 | head -3 || true

echo "[mac] 组装发布目录 ..."
mkdir -p "$STAGE/flutter_hot"
cp -R "$APP" "$STAGE/flutter_hot/"

cat > "$STAGE/flutter_hot/打开.command" <<'SH'
#!/bin/bash
# 去掉网页下载附加的 quarantine 属性后启动（App 为 ad-hoc 签名，未做 Apple 公证）。
cd "$(dirname "$0")" || exit 1
xattr -dr com.apple.quarantine flutter_hot.app 2>/dev/null
open flutter_hot.app
SH
chmod +x "$STAGE/flutter_hot/打开.command"

cat > "$STAGE/flutter_hot/说明.txt" <<'TXT'
flutter_hot（macOS demo）
====================================

这个 App 是本地构建的 ad-hoc 签名包，没有 Apple Developer ID 签名与公证。
网页下载的压缩包会被 macOS 打上 com.apple.quarantine 标记，因此第一次双击
可能提示「无法验证开发者」或「已损坏，无法打开」——这不是文件损坏。

推荐方式（二选一）：
1) 双击同目录下的「打开.command」，它会去掉 quarantine 标记并启动 App。
2) 终端进入本目录后执行：
     xattr -dr com.apple.quarantine flutter_hot.app
     open flutter_hot.app

如果仍然提示无法打开，去「系统设置 → 隐私与安全性」里点「仍要打开」。
TXT

rm -f "$OUT_ZIP"
( cd "$STAGE" && ditto -c -k --sequesterRsrc --keepParent flutter_hot "$OUT_ZIP" )
echo "[mac] 已发布：${OUT_ZIP}（$(du -h "$OUT_ZIP" | cut -f1)）"
