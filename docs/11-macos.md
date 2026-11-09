# macOS 端：安装、权限和注意事项

> 说明：本文依据 Deskflow 官方发布物和社区经验整理，**本次没有 macOS 实机**。  
> 如果你在 macOS 上验证过，欢迎提 PR 补充。

## 1. 下载哪个包

从 [Releases](https://github.com/deskflow/deskflow/releases) 下载：

| 芯片 | 文件 |
|---|---|
| Apple Silicon（M1/M2/M3/M4） | `deskflow-1.27.0-macos-arm64.dmg` |
| Intel Mac | `deskflow-1.27.0-macos-x86_64.dmg` |

查看芯片：

```bash
uname -m
# arm64 → Apple Silicon
# x86_64 → Intel
```

## 2. 安装

1. 打开 dmg；
2. 把 Deskflow 拖到 Applications；
3. 首次打开如果被 Gatekeeper 拦截：
   - 右键 App → 打开；
   - 或系统设置 → 隐私与安全性 → “仍要打开”。

如果提示“已损坏”：

```bash
xattr -dr com.apple.quarantine /Applications/Deskflow.app
```

> 只在确认安装包来自官方 Releases 时这么做。

## 3. 辅助功能权限

macOS 不允许普通应用随意模拟键鼠。需要在：

```text
系统设置 → 隐私与安全性 → 辅助功能
```

把 Deskflow 加进去并勾选。

如果 Deskflow 作为 Client 接收输入，通常还需要：

```text
系统设置 → 隐私与安全性 → 输入监控
```

具体以 Deskflow 首次启动时的提示为准。

## 4. 角色

### macOS 做 Client

1. 打开 Deskflow；
2. 选“使用另一台计算机的鼠标和键盘”；
3. 服务器地址填 Windows 的 `10.10.10.1`；
4. Connect；
5. 在 Windows Server 的服务器配置里，把 macOS 屏幕加到正确的边。

### macOS 做 Server

1. 选“使用此计算机的键盘和鼠标”；
2. 配置屏幕布局；
3. Start；
4. 在 Windows/Linux Client 里填 macOS 的直连 IP。

> macOS 的防火墙可能会拦截入站 24800。系统设置 → 网络 → 防火墙 → 选项，允许 Deskflow。

## 5. 端口与网络

- 端口：TCP 24800；
- 建议和 Windows/Linux 在同一个直连网段；
- macOS 的 Wi-Fi 和有线网卡可能同时存在，确认 Client 填的是直连 IP；
- 如果 macOS 通过 USB-C 转 Ethernet，确认接口在“网络”里是哪个服务。

查看 IP：

```bash
ipconfig getifaddr en0
ipconfig getifaddr en1
```

## 6. 剪贴板

- 文字：支持；
- 图片像素：支持（受 macOS 剪贴板格式影响）；
- 文件：不支持。

如果图片失败：

- 确认复制的是图片像素，不是 Finder 里的文件；
- 更新到同版本 Deskflow；
- 检查 `clipboardSize`；
- 尝试在“预览/浏览器”里复制图片，而不是 Finder。

## 7. 常见问题

| 现象 | 处理 |
|---|---|
| 鼠标能过去，键盘不行 | 检查辅助功能/输入监控权限 |
| 完全无法注入 | 重新勾选权限，重启 Deskflow |
| 被 Gatekeeper 拦截 | 右键打开，或 `xattr` 去隔离 |
| 24800 不通 | macOS 防火墙、IP、服务端监听 |
| 休眠后不重连 | 唤醒后重启客户端，或等自动重连 |
| Retina/缩放导致鼠标偏 | 检查屏幕布局和缩放 |

## 8. 未验证项

以下内容本次没有 macOS 实机验证，标记为“待补充”：

- Apple Silicon 下的实际延迟；
- macOS 15/26 的权限弹窗差异；
- Retina + 多显示器混排的坐标表现；
- 图片剪贴板在 macOS ↔ Linux 的双向表现。

欢迎在 Issue/PR 里补充实测。

## 相关文档

- 架构：[`02-architecture.md`](02-architecture.md)
- 网络与安全：[`05-network-security.md`](05-network-security.md)
- 剪贴板：[`06-clipboard.md`](06-clipboard.md)
