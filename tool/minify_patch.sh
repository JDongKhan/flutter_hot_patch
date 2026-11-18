#!/usr/bin/env bash
# patch 产物压缩 / 混淆脚本（默认输出到独立目录，处理后重建 patch.zip）。
#
# 规则（按产物路径区分）：
#   - flutter.js、runtime.js、packages/**（三方 package 产物）：只压缩，不混淆；
#   - 其余 .js：压缩 + 只混淆方法体，即只重命名形参与局部变量；
#     类名、全局变量、方法名（属性名）一律保持原样。
#
# 依赖 terser（优先用已安装的，找不到时用 npx 缓存）：
#   npm install -g terser
#
# 用法：bash tool/minify_patch.sh [源patch目录] [输出目录] [并发数]
#   默认：源 example/patch，输出 example/patch_minified，并发 8。
#   两个目录相同时就地处理；不同时先完整拷贝到输出目录再处理，
#   保证 build_runner 产出的原始 patch/ 不被改写。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="${1:-$REPO_ROOT/example/patch}"
OUT_DIR="${2:-$REPO_ROOT/example/patch_minified}"
JOBS="${3:-8}"

if [ ! -d "$SRC_DIR" ]; then
  echo "[minify] 目录不存在：$SRC_DIR"
  exit 1
fi
SRC_DIR="$(cd "$SRC_DIR" && pwd)"
# 输出目录统一成绝对路径再比较，避免把同一个目录误判成两个而删掉源产物。
mkdir -p "$(dirname "$OUT_DIR")"
OUT_DIR="$(cd "$(dirname "$OUT_DIR")" && pwd)/$(basename "$OUT_DIR")"

if [ "$SRC_DIR" = "$OUT_DIR" ]; then
  PATCH_DIR="$SRC_DIR"
else
  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR"
  rsync -a --exclude 'patch.zip' --exclude '.DS_Store' "$SRC_DIR"/ "$OUT_DIR"/
  PATCH_DIR="$(cd "$OUT_DIR" && pwd)"
fi

# 解析 terser 入口：全局安装 → 全局 npm 包 → npx 缓存，避免每个文件都起一次 npx。
TERSER_BIN=""
TERSER_NODE="0"
if command -v terser >/dev/null 2>&1; then
  TERSER_BIN="$(command -v terser)"
else
  NPM_GLOBAL_ROOT="$(npm root -g 2>/dev/null || true)"
  if [ -n "$NPM_GLOBAL_ROOT" ] && [ -f "$NPM_GLOBAL_ROOT/terser/bin/terser" ]; then
    TERSER_BIN="$NPM_GLOBAL_ROOT/terser/bin/terser"
    TERSER_NODE="1"
  else
    TERSER_BIN="$(ls -t "$HOME"/.npm/_npx/*/node_modules/terser/bin/terser 2>/dev/null | head -1 || true)"
    [ -n "$TERSER_BIN" ] && TERSER_NODE="1"
  fi
fi
if [ -z "$TERSER_BIN" ]; then
  echo "[minify] 找不到 terser，请先安装：npm install -g terser"
  exit 1
fi
export TERSER_BIN TERSER_NODE

# 单个文件处理：$1 = 相对 PATCH_DIR 的路径，$2 = mangle / keep。
minify_one() {
  local rel="$1"
  local mode="$2"
  local src="$PATCH_DIR/$rel"
  local tmp="$src.minify.tmp"
  local err
  err="$(mktemp -t terser)"

  local terser_cmd
  if [ "$TERSER_NODE" = "1" ]; then
    terser_cmd=(node "$TERSER_BIN")
  else
    terser_cmd=("$TERSER_BIN")
  fi

  # keep_fargs：保留形参个数（回调可能依赖 arity）；keep_fnames：保留函数名。
  # if_return：禁止把「if (...) return; 后续语句」折叠进 if 块——class 是块级
  # 作用域，被折叠进块后块外引用会变成 Can't find variable（runtime.js 的
  # `class JsBuildContext` 就会这样丢作用域）。
  local args=(-c keep_fargs=true,keep_fnames=true,if_return=false)
  if [ "$mode" = "mangle" ]; then
    # 只混淆方法体：顶层（全局变量 / 模块绑定）、类名、函数名、属性名都不动。
    args+=(-m toplevel=false,module=false,keep_classnames=true,keep_fnames=true)
  fi
  # 含 ESM 语法的文件按 module 解析，否则普通脚本解析。
  if grep -qE '^[[:space:]]*(import|export)([[:space:]{*]|$)' "$src"; then
    args+=(--module)
  fi

  if ! "${terser_cmd[@]}" "$src" "${args[@]}" --comments false -o "$tmp" 2>"$err"; then
    echo "[minify] 失败：$rel"
    head -5 "$err" | sed 's/^/    /'
    rm -f "$tmp" "$err"
    return 1
  fi
  mv "$tmp" "$src"
  rm -f "$err"
}
export -f minify_one
export PATCH_DIR

# 按路径拆分：三方产物只压缩，其余压缩 + 混淆方法体。
MANGLE_LIST=()
KEEP_LIST=()
while IFS= read -r -d '' f; do
  rel="${f#"$PATCH_DIR"/}"
  case "$rel" in
    flutter.js | runtime.js | packages/*) KEEP_LIST+=("$rel") ;;
    *) MANGLE_LIST+=("$rel") ;;
  esac
done < <(find "$PATCH_DIR" -type f -name '*.js' -print0)

run_pass() {
  local mode="$1"
  shift
  [ "$#" -eq 0 ] && return 0
  printf '%s\0' "$@" |
    xargs -0 -P "$JOBS" -n 1 bash -c 'minify_one "$2" "$1"' _ "$mode"
}

JS_SIZE_BEFORE=$(find "$PATCH_DIR" -type f -name '*.js' -print0 | xargs -0 stat -f%z | awk '{s+=$1} END {print s+0}')

echo "[minify] 压缩 + 混淆方法体：${#MANGLE_LIST[@]} 个"
run_pass mangle ${MANGLE_LIST[@]+"${MANGLE_LIST[@]}"}
echo "[minify] 只压缩：${#KEEP_LIST[@]} 个（flutter.js / runtime.js / packages/**）"
run_pass keep ${KEEP_LIST[@]+"${KEEP_LIST[@]}"}

JS_SIZE_AFTER=$(find "$PATCH_DIR" -type f -name '*.js' -print0 | xargs -0 stat -f%z | awk '{s+=$1} END {print s+0}')

# 产物内容变了，同步刷新清单里的资源哈希（清单由生成器产出，哈希只描述内容）。
if [ -f "$PATCH_DIR/manifest.json" ]; then
  node - "$PATCH_DIR" <<'NODE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const root = process.argv[2];
const manifestPath = path.join(root, 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const resources = manifest.resources || {};
const walk = (dir) => {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith('.js')) {
      const rel = path.relative(root, full).split(path.sep).join('/');
      if (rel in resources) {
        resources[rel] = crypto.createHash('sha256').update(fs.readFileSync(full)).digest('hex');
      }
    }
  }
};
walk(root);
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
NODE
fi

# 重建归档：条目以 patch/ 为根，与生成器 patch_archive_builder 的口径一致。
echo "[minify] 重建 patch.zip ..."
rm -f "$PATCH_DIR/patch.zip"
(cd "$PATCH_DIR" && zip -qrD patch.zip . -x 'patch.zip' '*.DS_Store')

awk -v before="$JS_SIZE_BEFORE" -v after="$JS_SIZE_AFTER" 'BEGIN {
  printf "[minify] JS 合计：%.1f MB → %.1f MB（保留 %.0f%%）\n", before/1048576, after/1048576, after*100/before;
}'
echo "[minify] patch.zip：$(du -h "$PATCH_DIR/patch.zip" | cut -f1)"
