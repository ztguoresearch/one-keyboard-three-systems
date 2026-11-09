# 推送、GitHub Pages 与社交预览

> 实际仓库：<https://github.com/ztguoresearch/one-keyboard-three-systems>  
> 实际主页（已启用）：<https://ztguoresearch.github.io/one-keyboard-three-systems/>

## 1. 当前仓库信息

| 项目 | 值 |
|---|---|
| 仓库名 | `one-keyboard-three-systems` |
| 默认分支 | `main` |
| 主页文件 | `index.html`（仓库根目录） |
| 主页横幅 | `assets/hero.png`（1200×630） |
| 社交预览 | 上传 `assets/hero.png` |

## 2. 本机推送

本机已经设置：

```bash
git remote add origin https://github.com/ztguoresearch/one-keyboard-three-systems.git
git config http.proxy http://127.0.0.1:7890
```

> 代理是本机 Clash 的端口。换机器/换网络时，把这一行删掉或改成你的代理。

推送：

```bash
git push -u origin main
```

如果弹出 GitHub 登录窗口，按提示授权即可。  
如果没有弹窗且提示认证失败，建议用 GitHub 的 Personal Access Token，或改用 SSH。

## 3. GitHub Pages（已启用）

1. 打开仓库：Settings → Pages；
2. Source 选 **Deploy from a branch**；
3. Branch 选 `main`，目录选 **`/ (root)`**；
4. 保存；
5. 等 1–3 分钟，访问：

```text
https://ztguoresearch.github.io/one-keyboard-three-systems/
```

`index.html` 会作为主页，直接引用 `assets/hero.png`。

> 如果 Pages 显示 404：确认分支是 `main`、目录是 `/ (root)`、`index.html` 在根目录；再等一分钟。

## 4. 设置社交预览图

GitHub 的社交预览（分享到微信/Twitter/ Slack 时的缩略图）目前需要在网页上设置：

1. 仓库首页 → Settings；
2. 找到 **Social preview**；
3. Upload an image；
4. 选择 `assets/hero.png`；
5. 保存。

这张图就是本文开头那张 1200×630 的架构图。

## 5. 日常更新

```bash
git add .
git commit -m "docs: update troubleshooting"
git push
```

建议提交信息：

```text
docs: add Samba permission note
fix: correct firewall remote address
feat: add macOS accessibility notes
```

## 6. 发布前检查

- [ ] README 顶部的仓库/主页链接正确；
- [ ] `index.html` 里的 GitHub 链接指向 `ztguoresearch/one-keyboard-three-systems`；
- [ ] `assets/architecture.svg` 页脚是实际仓库地址；
- [ ] `assets/hero.png` 是 1200×630，文字没有占位符；
- [ ] 截图里没有真实主机名/用户名/MAC；
- [ ] 没有密码、PAT、私钥、公网 IP；
- [ ] `git status` 干净；
- [ ] Pages 已启用，主页能打开。

## 7. 常见问题

| 现象 | 处理 |
|---|---|
| `Failed to connect to github.com port 443` | 配代理：`git config http.proxy http://127.0.0.1:7890` |
| `Authentication failed` | 用浏览器登录/PAT；检查凭据管理器 |
| Pages 404 | 分支/目录不对，或还没构建完 |
| 主页图片 404 | 确认 `assets/hero.png` 已推送，路径大小写一致 |
| 社交预览不更新 | GitHub 有缓存，等几分钟或重新上传 |
| 推送被拒（non-fast-forward） | `git pull --rebase origin main` 后再推，不要强推 |

## 8. 仓库地址汇总

```text
GitHub:  https://github.com/ztguoresearch/one-keyboard-three-systems
Pages:   https://ztguoresearch.github.io/one-keyboard-three-systems/
Raw hero: https://raw.githubusercontent.com/ztguoresearch/one-keyboard-three-systems/main/assets/hero.png
```
