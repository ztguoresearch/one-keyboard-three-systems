# 贡献指南

欢迎补充实测、纠错和新的排障案例。

## 最有价值的贡献

1. **macOS 实机验证**：权限、Retina、多显示器、图片剪贴板；
2. **Wayland 实测**：GNOME/KDE 版本、剪贴板图片是否可用；
3. **不同网卡/线材的链路速度**：100M/1G/2.5G/10G 的实际协商；
4. **新的错误信息与解法**：请附日志和复现步骤；
5. **Samba 权限/SELinux 的发行版差异**。

## 提 PR 前

- 不要提交真实密码、公网 IP、公司内网信息；
- 截图请打码主机名、用户名、MAC；
- 命令用代码块，注明 Shell/PowerShell；
- 说明你的 OS、Deskflow 版本、网络拓扑；
- 一次 PR 只做一件事。

## 文章风格

- 先给结论，再给证据；
- 不写“万能”“百分百”；
- 失败和限制要写出来；
- 引用他人内容请附链接。

## 提交信息

```text
docs: fix samba permission example
fix: correct firewall remote address
feat: add macOS accessibility notes
```
