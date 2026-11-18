#!/usr/bin/env bash
# 一键启动 patch 静态服务：build_runner 重新生成产物（含 patch.zip 归档）→ 杀旧进程 → 启动 http 服务。
# 用法：bash start_patch_server.sh
#
# 仓库已改为 pub workspace：示例 App 在 example/，其 build_runner 产物落在
# example/patch/；本脚本仍在仓库根执行，服务端（tool/patch_server.dart）也按
# 仓库根解析 example/patch/。
#
# patch.zip 由生成器的 ui_patch_archive builder 产出，与本脚本无关：直接跑
# build_runner 就会得到新鲜归档。
set -euo pipefail

# 脚本在仓库根目录
cd "$(dirname "$0")"

PORT="8765"
# 示例 App 目录与其 patch 产物目录（相对仓库根）
EX_DIR="example"
PATCH_DIR="$EX_DIR/patch"

echo "[start] build_runner 在 $EX_DIR/ 重新生成产物到 $PATCH_DIR/ ..."
( cd "$EX_DIR" && dart run build_runner build --delete-conflicting-outputs )

if [ ! -d "$PATCH_DIR" ]; then
  echo "[start] $PATCH_DIR/ 不存在，build_runner 未产出？"
  exit 1
fi
if [ ! -f "$PATCH_DIR/patch.zip" ]; then
  echo "[start] $PATCH_DIR/patch.zip 不存在，归档 builder 未产出？"
  exit 1
fi

# 是否需要压缩 / 混淆本次产物：
#   flutter.js、runtime.js、packages/** 只压缩不混淆；其余只混淆方法体。
# 压缩后的 patch.zip 与 sourcemap 回填到 example/patch/，临时目录处理完即删除。
# 非交互场景（无 tty）默认不处理。
MINIFY_ANSWER=""
if [ -t 0 ]; then
  read -r -p "[start] 是否压缩/混淆本次产物？[y/N] " MINIFY_ANSWER || true
fi
case "$MINIFY_ANSWER" in
  y | Y | yes | YES)
    bash tool/minify_patch.sh "$PATCH_DIR"
    ;;
  *)
    echo "[start] 跳过压缩混淆"
    # 清掉上一次压缩留下的 sourcemap / 临时目录，避免和本次未压缩产物混在一起。
    find "$PATCH_DIR" -type f -name '*.js.map' -delete
    rm -rf "$EX_DIR/patch_minified"
    ;;
esac

echo "[start] patch.zip 大小：$(du -h "$PATCH_DIR/patch.zip" | cut -f1)"

# 同步一份归档到 docs/blog/patch.zip：docs/ 是 GitHub Pages 的发布目录，
# push 之后 release 包就能从
#   https://jdongkhan.github.io/flutter_hot_patch/blog/patch.zip
# 加载补丁（见 example/lib/base/patch_config.dart 的 release 分支），
# 别人装包后不需要再自己起本地服务。
DOC_ZIP="docs/blog/patch.zip"
mkdir -p "$(dirname "$DOC_ZIP")"
cp "$PATCH_DIR/patch.zip" "$DOC_ZIP"
echo "[start] 已同步到 ${DOC_ZIP}（$(du -h "$DOC_ZIP" | cut -f1)）；push 后线上可用"

# 杀进程放在产物就绪之后：旧服务只在这段极短的窗口内不可用，避免构建期间
# （数秒到数十秒）服务就已挂掉。
echo "[start] 杀掉旧 patch_server 进程..."
# pkill 匹配 dart run 父进程，但 dartvm 子进程命令行不含 patch_server.dart——
# 用 lsof 直接按端口找 PID 杀，更可靠。
OLD_PID=$(lsof -ti :$PORT 2>/dev/null || true)
if [ -n "$OLD_PID" ]; then
  kill -9 $OLD_PID 2>/dev/null && echo "[start] 已杀掉旧进程 PID=$OLD_PID" || echo "[start] 杀进程失败"
else
  echo "[start] 无旧进程"
fi
# 等端口释放
sleep 0.5

# 前台运行：patch_server 的启动日志与每个 mock 请求都直接打到当前终端，
# Ctrl+C 停止。需要后台常驻时自行改用 `nohup dart run tool/patch_server.dart &`。
echo "[start] 启动 patch_server（前台，Ctrl+C 停止）"
dart run tool/patch_server.dart
