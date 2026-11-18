#!/usr/bin/env bash
# 构建 release 包并发布到 docs/downloads/：
#   - Android: flutter_hot_patch-android.apk（arm64 单 ABI）
#   - macOS:   flutter_hot_patch-macos.zip（ad-hoc 重签，未公证）
#
# macOS 为什么必须重签：
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
#   bash tool/package_apps.sh                    # Android + macOS 都打包
#   bash tool/package_apps.sh android            # 只打包 Android
#   bash tool/package_apps.sh macos              # 只打包 macOS
#   bash tool/package_apps.sh --skip-build       # 复用已有产物，只重签 / 拷贝
#   bash tool/package_apps.sh android --skip-build
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"
OUT_DIR="$REPO_ROOT/docs/downloads"

ANDROID_APK_REL="example/build/app/outputs/flutter-apk/app-release.apk"
ANDROID_OUT="$OUT_DIR/flutter_hot_patch-android.apk"

MAC_APP_REL="example/build/macos/Build/Products/Release/flutter_hot.app"
MAC_OUT="$OUT_DIR/flutter_hot_patch-macos.zip"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

TARGET="all"
SKIP_BUILD="no"
for arg in "$@"; do
  case "$arg" in
    android | macos | all) TARGET="$arg" ;;
    --skip-build) SKIP_BUILD="yes" ;;
    *)
      echo "[package] 未知参数：$arg"
      exit 1
      ;;
  esac
done

mkdir -p "$OUT_DIR"

package_android() {
  if [ "$SKIP_BUILD" = "no" ]; then
    echo "[android] 构建 release APK ..."
    # --target-platform android-arm64：只编 arm64 的 Flutter 产物；
    # ONLY_ARM64=true：连插件 AAR 里的 x86_64 / armeabi-v7a so 一起剔除
    # （--target-platform / ndk.abiFilters 过滤不掉，见 android/app/build.gradle.kts）。
    # --no-tree-shake-icons：icon_from_json.dart 的动态 IconData 不能 tree-shake。
    ( cd example && ONLY_ARM64=true fvm flutter build apk --release --no-tree-shake-icons --target-platform android-arm64 )
  fi
  local apk="$REPO_ROOT/$ANDROID_APK_REL"
  if [ ! -f "$apk" ]; then
    echo "[android] 未找到 $ANDROID_APK_REL，先去掉 --skip-build 构建"
    return 1
  fi
  cp "$apk" "$ANDROID_OUT"
  echo "[android] 已发布：${ANDROID_OUT}（$(du -h "$ANDROID_OUT" | cut -f1)）"
}

package_macos() {
  if [ "$SKIP_BUILD" = "no" ]; then
    echo "[mac] 构建 release ..."
    ( cd example && fvm flutter build macos --release --no-tree-shake-icons )
  fi

  local app="$REPO_ROOT/$MAC_APP_REL"
  if [ ! -d "$app" ]; then
    echo "[mac] 未找到 $MAC_APP_REL，先去掉 --skip-build 构建"
    return 1
  fi

  echo "[mac] ad-hoc 深度重签（修嵌套签名）..."
  codesign --force --deep --sign - "$app"
  codesign --verify --deep --strict "$app"
  echo "[mac] 签名校验通过；spctl 判定（未公证时必为 rejected，属预期）："
  spctl -a -vv "$app" 2>&1 | head -3 || true

  echo "[mac] 组装发布目录 ..."
  mkdir -p "$STAGE/flutter_hot"
  cp -R "$app" "$STAGE/flutter_hot/"

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

  rm -f "$MAC_OUT"
  ( cd "$STAGE" && ditto -c -k --sequesterRsrc --keepParent flutter_hot "$MAC_OUT" )
  echo "[mac] 已发布：${MAC_OUT}（$(du -h "$MAC_OUT" | cut -f1)）"
}

case "$TARGET" in
  android) package_android ;;
  macos) package_macos ;;
  all)
    package_android
    package_macos
    ;;
esac
