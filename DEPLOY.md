# 部署指南

本博客基于 **Hugo + 自定义主题 `buginst`**（红头文件 × 犯罪档案风格），采用
「Cloudflare Pages 主托管 + GitHub Pages 备用」的零成本方案。部署方式为
**本地构建后直传**，不走 Cloudflare「Connect to Git」自动构建。

> 环境依赖：`hugo`（Extended 版）、`node` + `npm`（仅用于本地装 `wrangler`）。
> 本机直连 `github.com` 不通，推送到 GitHub 必须走 `gh.524444.cn` 镜像。

## 1. 本地构建

```bash
cd myblog
npm install            # 安装 wrangler（仅需一次）
hugo --gc --minify     # 输出到 public/，可加 -D 预览草稿
```

本地预览：`hugo server`（默认 http://localhost:1313）。

## 2. 部署主站（Cloudflare Pages，直传）

```bash
cd myblog
hugo --gc --minify
./node_modules/.bin/wrangler pages deploy public --project-name=buginst --branch=main
```

- Pages 项目名：`buginst`
- 部署走 wrangler 的 OAuth 凭据（首次会打开浏览器授权），无需手工维护 API Token。
- 当前主域名：`https://buginst.pages.dev/`（`hugo.toml` 的 `baseURL` 已对应）。
  `buginst.com` / `www.buginst.com` 自定义域名映射已按需求关闭。

## 3. 推送到 GitHub（备用站，走镜像）

```bash
cd myblog
git add <文件>
git commit -m "docs: ..."
# 本机无法直连 github.com，经镜像推送：
git push "https://szlintel:<GITHUB_PAT>@gh.524444.cn/szlintel/Buginst.git" main
```

- 仓库：`https://github.com/szlintel/Buginst`（public）
- 镜像 `https://gh.524444.cn/` 仅代理 git 协议，不支持网页 / API 操作
- 推送后 `.github/workflows/hugo.yml` 自动构建并发布到
  `https://szlintel.github.io/Buginst/`

## 4. Docker 镜像代理（workers/docker-proxy）

```bash
cd workers/docker-proxy
../../myblog/node_modules/.bin/wrangler deploy
# 更新密钥（Docker Hub 只读 PAT）：
echo "新值" | ../../myblog/node_modules/.bin/wrangler secret put HUB_PAT
```

注意：`wrangler.toml` 的 `compatibility_date` 不能晚于 Cloudflare 服务端当天日期，
否则报 `Can't set compatibility date in the future (10021)`。

## 5. 验收

```bash
# 博客首页 / 某档案页
curl -s -o /dev/null -w "%{http_code}\n" https://buginst.pages.dev/
curl -s -o /dev/null -w "%{http_code}\n" https://buginst.pages.dev/posts/20251103-01/

# Docker 代理完整链路（令牌 → 清单）
T=$(curl -s "https://docker.524444.cn/token?service=registry.docker.io&scope=repository:library/hello-world:pull" | sed -E 's/.*"token":"([^"]+)".*/\1/')
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $T" \
  https://docker.524444.cn/v2/library/hello-world/manifests/latest
```

## 6. 注意事项

- 仓库为 **public**：`BugInst/`（原始案源素材）与 `node_modules/`、`package-lock.json`
  已在 `.gitignore` 中忽略，切勿 `git add -A` 误提交。
- 新增档案请照 `content/posts/` 现有 front matter 字段填写，并保留 `sources[]` 来源。
- 接手后建议轮换 GitHub / Cloudflare / Docker 三套令牌（见 HANDOFF-SECRETS.txt）。
