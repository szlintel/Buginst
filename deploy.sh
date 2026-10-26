#!/usr/bin/env bash
#
# deploy.sh — Buginst 主站一键重部署脚本
# 用途: 在本机重新构建 Hugo 站点并上传到 Cloudflare Pages,
#       完成后自动自检线上是否已刷新(去印章 / 动态日期 / pages.dev / 魏家案新内容)。
#
# 使用:
#   1) 首次需登录一次:  npx wrangler login   (会打开浏览器授权)
#   2) 之后每次重部署:  ./deploy.sh
#
# 注意: 本脚本只做 构建 + 上传 + 自检, 不碰 git。推送源码请单独 git push。
set -euo pipefail

# 进入脚本所在目录 (myblog/), 保证相对路径正确
cd "$(dirname "$0")"

# 非交互部署: 从 .env 读取 CF 令牌 (若存在), 避免无界面机器走 OAuth
if [ -f .env ]; then
  set -a; . ./.env; set +a
fi
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] || [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  echo "提示: 未检测到 CLOUDFLARE_API_TOKEN / CLOUDFLARE_ACCOUNT_ID。" >&2
  echo "      请在 myblog/.env 中写入这两行后重试 (或 export 到环境变量):" >&2
  echo "      CLOUDFLARE_API_TOKEN=cfut_xxx" >&2
  echo "      CLOUDFLARE_ACCOUNT_ID=你的account_id" >&2
  echo "      无界面服务器无法用 wrangler login(OAuth 需浏览器+localhost)。" >&2
  exit 1
fi

SITE="https://buginst.pages.dev"

echo "==> [1/3] 构建 Hugo 站点 (hugo --gc --minify)"
if command -v hugo >/dev/null 2>&1; then
  HUGO=hugo
elif [ -x ./node_modules/.bin/hugo ]; then
  HUGO=./node_modules/.bin/hugo
else
  echo "错误: 未找到 hugo, 请先安装 Hugo Extended 版本。" >&2
  exit 1
fi
$HUGO --gc --minify

echo "==> [2/3] 部署到 Cloudflare Pages (buginst / main)"
if [ -x ./node_modules/.bin/wrangler ]; then
  WRANGLER=./node_modules/.bin/wrangler
elif command -v wrangler >/dev/null 2>&1; then
  WRANGLER=wrangler
else
  echo "错误: 未找到 wrangler, 请先 'npm i wrangler' 或 'npm i -g wrangler' 并登录。" >&2
  exit 1
fi
$WRANGLER pages deploy public --project-name=buginst --branch=main

echo "==> [3/3] 自检线上站点 (等待 CDN 刷新, 最多重试)"
present() {            # 返回 0 = 找到 pattern
  local url="$1" pat="$2" tries=6 i
  for ((i=1;i<=tries;i++)); do
    if curl -s --max-time 20 "$url" | grep -q "$pat"; then return 0; fi
    sleep 4
  done
  return 1
}

ok=1
if present "$SITE/sitemap.xml" "buginst.com"; then
  echo "✗ sitemap 仍指向旧域名 buginst.com"; ok=0
else
  echo "✓ sitemap 已指向 pages.dev"
fi
if present "$SITE/" "专用章"; then
  echo "✗ 首页仍含旧印章 '专用章'"; ok=0
else
  echo "✓ 首页无旧印章"
fi
if present "$SITE/posts/20261013-01/" "魏怀仁"; then
  echo "✓ 魏家案新内容已上线"
else
  echo "✗ 魏家案内容未更新 (20261013-01)"; ok=0
fi

if [ "$ok" -eq 1 ]; then
  echo ""
  echo "部署成功 🎉  主站: $SITE"
else
  echo ""
  echo "部署已提交但自检未全部通过, 请稍候 CDN 刷新或重新运行 ./deploy.sh"
fi
