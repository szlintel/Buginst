# 部署指南

本博客基于 Hugo + PaperMod 主题，采用「Cloudflare Pages 主托管 + GitHub Pages 备用」的零成本方案。

## 本地写作流程

```powershell
# 1. 新建文章（在 myblog 目录下执行）
hugo new posts/我的文章标题.md

# 2. 编辑 content/posts/我的文章标题.md，写完将 draft 改为 false

# 3. 本地预览（浏览器打开 http://localhost:1313）
hugo server

# 4. 提交并推送到 GitHub 仓库，自动触发部署
```

## Cloudflare Pages 部署（主托管）

1. 将本目录推送到 GitHub 仓库。
2. 登录 Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**，选择该仓库。
3. 构建设置：
   - Framework preset: **Hugo**
   - Build command: `hugo`
   - Build output directory: `public`
4. 点击 **Save and Deploy**，稍候即可获得 `xxx.pages.dev` 域名。
5. （可选）在 Pages 项目 → **Custom domains** 中绑定自己的域名，按提示添加 DNS 记录。

## GitHub Pages 备用部署

1. 仓库 **Settings** → **Pages** → Source 选择 **GitHub Actions**。
2. 推送到 `main` 分支后，`.github/workflows/hugo.yml` 会自动构建并发布到 `https://<用户名>.github.io/<仓库名>/`。

## 注意事项

- 部署完成后，请将 `hugo.toml` 中的 `baseURL` 替换为实际域名（如 `https://xxx.pages.dev/`），然后重新推送。
- Cloudflare Pages 与 GitHub Pages 的域名不同，若以 GitHub Pages 为主，baseURL 应填 GitHub Pages 地址。
