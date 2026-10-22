#!/usr/bin/env bash
# 一键发布三个 package 到 pub.dev。
#
# 用法（在仓库任意位置执行均可）：
#   bash publish_packages.sh              # 预检 + 发布（已发布的版本自动跳过）
#   bash publish_packages.sh --dry-run    # 只做发布预检，不上传
#
# 为什么强制 PUB_HOSTED_URL=https://pub.dev：
#   本机环境默认指向镜像站 https://pub.flutter-io.cn，而 OAuth 凭证属于
#   pub.dev；镜像站只做只读同步，直接往它上传会报 "Authentication failed"。
#   发布到 pub.dev 后镜像会自动同步，因此这里每次都显式覆盖。
set -euo pipefail

cd "$(dirname "$0")"
export PUB_HOSTED_URL="https://pub.dev"

PACKAGES=(
  hot_patch_annotations
  hot_patch_generator
  hot_patch
)

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

version_of() {
  awk '/^version:/{print $2; exit}' "$1/pubspec.yaml"
}

# 已发布版本列表（每行一个）；网络不可用时输出为空，交由发布阶段的
# "already exists" 兜底。
published_versions() {
  curl -fsS --max-time 15 "https://pub.dev/api/packages/$1" 2>/dev/null \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(v["version"] for v in d["versions"]))' \
      2>/dev/null \
    || true
}

echo "[publish] host=$PUB_HOSTED_URL"
echo

for pkg in "${PACKAGES[@]}"; do
  dir="packages/$pkg"
  version="$(version_of "$dir")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $pkg $version"
    dart pub publish --dry-run --ignore-warnings -C "$dir"
    echo
    continue
  fi

  if published_versions "$pkg" | grep -Fxq "$version"; then
    echo "[skip] $pkg $version 已发布"
    echo
    continue
  fi

  echo "[publish] $pkg $version"
  # 预检：真正的校验错误会在这一步暴露；警告（如工作区未提交）不影响发布。
  dart pub publish --dry-run --ignore-warnings -C "$dir"

  # --force：跳过 y/N 交互确认；不传 --ignore-warnings（正式发布不支持该参数）。
  set +e
  output="$(dart pub publish --force -C "$dir" 2>&1)"
  status=$?
  set -e
  printf '%s\n' "$output"

  if [[ "$status" -ne 0 ]]; then
    if printf '%s' "$output" | grep -q "already exists"; then
      # 刚发布的版本可能尚未被 API 索引，重复发布会命中该错误。
      echo "[skip] $pkg $version 已存在（索引可能尚未刷新）"
      echo
      continue
    fi
    if printf '%s' "$output" | grep -q "Authentication failed"; then
      echo "[error] $pkg 发布失败：未登录或凭证无效。请先执行：" >&2
      echo "        dart pub login" >&2
    else
      echo "[error] $pkg $version 发布失败（exit=$status）" >&2
    fi
    exit "$status"
  fi

  echo "[ok] $pkg $version"
  echo
done

echo "[done] 全部处理完成"
