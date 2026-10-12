#!/usr/bin/env bash
# 一键启动 patch 静态服务：杀旧进程 → build_runner 重新生成产物 → 打包 zip → 启动 http 服务。
# 用法：bash start_patch_server.sh
set -euo pipefail

# 脚本在项目根目录
cd "$(dirname "$0")"

HOST="127.0.0.1"
PORT="8765"

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

echo "[start] build_runner 重新生成产物到 patch/ ..."
dart run build_runner build --delete-conflicting-outputs

if [ ! -d patch ]; then
  echo "[start] patch/ 不存在，build_runner 未产出？"
  exit 1
fi

echo "[start] 重新打包 patch/patch.zip ..."
# -x 排除 zip 自身，避免递归打包
( cd patch && rm -f patch.zip && zip -r -q patch.zip . -x patch.zip )
echo "[start] patch.zip 大小：$(du -h patch/patch.zip | cut -f1)"

echo "[start] 启动 http 服务 http://$HOST:$PORT/"
nohup dart run tool/patch_server.dart > /tmp/patch_server.log 2>&1 &
echo "[start] 后台 PID=$!，日志：/tmp/patch_server.log"
sleep 0.5
echo "[start] 验证：curl -s -o /dev/null -w '%{http_code}' http://$HOST:$PORT/patch/patch.zip"
curl -s -o /dev/null -w "  → HTTP %{http_code}\n" "http://$HOST:$PORT/patch/patch.zip" || true
