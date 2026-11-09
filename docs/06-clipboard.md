# 剪贴板：文字、图片、文件，到底支持哪几种

## 一句话

Deskflow 支持**文字**和**图片像素**，不支持**文件/文件夹**。

这三者在操作系统剪贴板里是不同格式：

| 你复制的对象 | 剪贴板格式 | Deskflow |
|---|---|---|
| 一段文字 | `text/plain`、`text/html` | ✅ |
| 浏览器里右键“复制图片” | `image/png` / bitmap | ✅ |
| 截图工具复制 | bitmap | ✅ |
| 资源管理器里 `Ctrl+C` 一个文件 | `CF_HDROP`（文件列表） | ❌ |
| 拖拽文件 | 文件列表 | ❌ |

## 为什么图片有时“看起来支持，实际贴不出来”

先看日志。Deskflow 抓到图片时会打印：

```text
bitmap: 1151x213 24
computer "WIN-SERVER" updated clipboard 0
```

说明图片已经进入剪贴板通道。

失败通常有三类原因：

### 1. 你复制的是图片文件

在资源管理器里选中 `photo.png` 按 `Ctrl+C`，剪贴板里是“文件路径列表”，不是图片像素。

Deskflow 不会传文件，所以到对面粘贴不出来。

**正确做法：**

- 双击打开图片，在看图软件里 `Ctrl+C`；
- 或在浏览器里右键“复制图片”；
- 或用截图工具复制；
- 或者干脆走 Samba 传文件。

### 2. 图片太大，超过 `clipboardSize`

默认：

```ini
[server]
clipboardSize=3
```

单位 MB。4K 截图的原始像素约 33 MB，默认值直接截断。

改成：

```ini
[server]
clipboardSize=64
```

然后重启 core。

> 不是越大越好。太大的剪贴板会占内存、增加传输时间。一般 32–64 MB 够用。

### 3. Linux 是 Wayland

Wayland 下，后台程序写剪贴板受限制：

- GNOME/KDE 的剪贴板权限模型不同；
- Deskflow 客户端没有前台焦点时，可能无法写入图片；
- 文字有时正常，图片失败。

检查：

```bash
echo $XDG_SESSION_TYPE
```

如果是 `wayland`：

1. 注销；
2. 登录界面点齿轮；
3. 选 **Ubuntu on Xorg**；
4. 重新登录，重连 Deskflow；
5. 再测图片。

Xorg 下图片剪贴板通常正常。

## 测试步骤

### Windows → Linux

1. 在 Windows 浏览器打开一张图；
2. 右键“复制图片”；
3. 鼠标移到 Linux；
4. 打开图片编辑器、聊天窗口或支持图片粘贴的应用；
5. `Ctrl+V`。

### Linux → Windows

1. 在 Linux 用截图工具复制图片；
2. 鼠标移回 Windows；
3. 在画图/聊天窗口 `Ctrl+V`。

## 在 Linux 上验证剪贴板内容

### X11

```bash
sudo apt install -y xclip

# 看当前剪贴板支持哪些类型
xclip -selection clipboard -t TARGETS -o

# 把图片取出来
xclip -selection clipboard -t image/png -o > /tmp/clip.png
file /tmp/clip.png
```

如果 `TARGETS` 里有 `image/png`，且 `/tmp/clip.png` 是 PNG，说明图片已经到达 Linux 剪贴板。

### Wayland

```bash
sudo apt install -y wl-clipboard

wl-paste --list-types
wl-paste --type image/png > /tmp/clip.png
file /tmp/clip.png
```

## 常见现象与处理

| 现象 | 可能原因 | 处理 |
|---|---|---|
| 文字能贴，图片不能 | 复制的是文件 | 复制图片像素，不要复制文件 |
| 小图能贴，大图不能 | 超过 `clipboardSize` | 调到 32–64 MB |
| Windows 日志没有 `bitmap` | Windows 没把图片放进剪贴板 | 换应用复制，或先粘贴到画图确认 |
| Linux `TARGETS` 没有 `image/png` | 客户端没写入图片 | 切 Xorg 再试 |
| 两边都卡一下 | 大图传输 | 降低图片尺寸/剪贴板大小 |
| `OpenClipboard` 报错 | 多个 Deskflow 实例抢剪贴板 | 只留一个实例 |

## 官方边界

Deskflow 的 issue 里明确讨论过：

- [Clipboard only works for text and images](https://github.com/deskflow/deskflow/issues/8399)

结论就是：**文本和图片可以，文件不行。**

这不是 bug，是产品边界。文件请用 Samba/SFTP/LocalSend。

## 相关文档

- Samba：[`07-samba.md`](07-samba.md)
- 故障对照：[`08-troubleshooting.md`](08-troubleshooting.md)
- 网络与安全：[`05-network-security.md`](05-network-security.md)
