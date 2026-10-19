#!/usr/bin/env bash
# 一键启动 patch 静态服务：杀旧进程 → build_runner 重新生成产物 → 打包 zip → 启动 http 服务。
# 用法：bash start_patch_server.sh
#
# 仓库已改为 pub workspace：示例 App 在 example/，其 build_runner 产物落在
# example/patch/；本脚本仍在仓库根执行，服务端（tool/patch_server.dart）也按
# 仓库根解析 example/patch/。
set -euo pipefail

# 脚本在仓库根目录
cd "$(dirname "$0")"

HOST="127.0.0.1"
PORT="8765"
# 示例 App 目录与其 patch 产物目录（相对仓库根）
EX_DIR="example"
PATCH_DIR="$EX_DIR/patch"

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

echo "[start] build_runner 在 $EX_DIR/ 重新生成产物到 $PATCH_DIR/ ..."
( cd "$EX_DIR" && dart run build_runner build --delete-conflicting-outputs )

if [ ! -d "$PATCH_DIR" ]; then
  echo "[start] $PATCH_DIR/ 不存在，build_runner 未产出？"
  exit 1
fi

echo "[start] 重新打包 $PATCH_DIR/patch.zip ..."
# -x 排除 zip 自身，避免递归打包
( cd "$PATCH_DIR" && rm -f patch.zip && zip -r -q patch.zip . -x patch.zip )
echo "[start] patch.zip 大小：$(du -h "$PATCH_DIR/patch.zip" | cut -f1)"

echo "[start] 启动 http 服务 http://$HOST:$PORT/"
nohup dart run tool/patch_server.dart > /tmp/patch_server.log 2>&1 &
echo "[start] 后台 PID=$!，日志：/tmp/patch_server.log"

# `dart run` 首次编译需数秒，轮询等待就绪（最多约 10s），避免验证误报 HTTP 000。
echo "[start] 验证：curl -s -o /dev/null -w '%{http_code}' http://$HOST:$PORT/patch/patch.zip"
CODE=""
for _ in $(seq 1 20); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://$HOST:$PORT/patch/patch.zip" || true)
  [ "$CODE" = "200" ] && break
  sleep 0.5
done
echo "  → HTTP $CODE"
