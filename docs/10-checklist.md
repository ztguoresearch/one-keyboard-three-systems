# 复现清单：从零到一套键鼠

> 建议按顺序勾选。每一步都先验证，再进入下一步。

## 阶段 0：准备

- [ ] 两台机器都能正常启动、联网
- [ ] Windows 有一个空闲 USB/网口
- [ ] Linux 有一个空闲网口（示例 `eno1`）
- [ ] 一根确认好的网线（Cat6a/Cat7 更稳）
- [ ] 知道 Linux 用户名（`whoami`）
- [ ] 知道 Linux 主机名（`hostname`）

## 阶段 1：物理链路

- [ ] Windows 网卡状态 `Up`
- [ ] Linux `ip -br link` 显示 `UP`
- [ ] 链路速度至少 100 Mbps（1 Gbps 更好）

Windows：

```powershell
Get-NetAdapter | Format-Table Name, Status, LinkSpeed
```

Linux：

```bash
ip -br link
sudo ethtool eno1 | grep -E "Speed|Link detected"
```

## 阶段 2：静态 IP

- [ ] Windows 设为 `10.10.10.1/24`，网关留空
- [ ] Linux 设为 `10.10.10.2/24`，不设默认网关
- [ ] Windows 能 ping 通 `10.10.10.2`
- [ ] Linux 能 ping 通 `10.10.10.1`

Windows：

```powershell
Get-NetIPAddress -InterfaceAlias "以太网 3" -AddressFamily IPv4
ping 10.10.10.2
```

Linux：

```bash
ip -br addr show eno1
ping -c 3 10.10.10.1
```

## 阶段 3：安装 Deskflow

- [ ] Windows 安装在纯英文路径（`C:\Tools\Deskflow` 或 `E:\Tools\Deskflow`）
- [ ] Linux 安装 Flatpak/deb/rpm
- [ ] 两端版本一致（示例 1.27.0）
- [ ] Windows 服务 `Deskflow` 的路径指向当前目录

```powershell
Get-CimInstance Win32_Service -Filter "Name='Deskflow'" | Select-Object State, PathName
```

## 阶段 4：服务端配置

- [ ] Windows 选 Server
- [ ] 屏幕布局：Linux 在左/右，和物理位置一致
- [ ] `Deskflow.conf` 有 Linux 的 `screens\N\name` 和 `[computer_...]` 段
- [ ] `deskflow-server.conf` 只有 `section: links` 和 `section: options`
- [ ] `[core] interface=10.10.10.1`
- [ ] 启动后 24800 只监听 `10.10.10.1`

```powershell
Get-NetTCPConnection -LocalPort 24800 -State Listen
```

期望：

```text
10.10.10.1:24800
```

## 阶段 5：防火墙

- [ ] 只允许 `10.10.10.2` 访问 24800
- [ ] 旧的 `Deskflow Server/Client` 宽泛规则已禁用
- [ ] 直连网络是 Private
- [ ] `10.10.10.1:24800` 通
- [ ] `192.168.1.50:24800` 不通

```powershell
Test-NetConnection 10.10.10.1 -Port 24800
Test-NetConnection 192.168.1.50 -Port 24800
```

## 阶段 6：客户端连接

- [ ] Linux 选 Client
- [ ] 地址填 `10.10.10.1`
- [ ] 服务端日志出现 `accepted client connection`
- [ ] 鼠标能穿屏
- [ ] 键盘能跟随

```bash
nc -vz 10.10.10.1 24800
```

## 阶段 7：剪贴板

- [ ] 复制一段文字，另一边能粘贴
- [ ] 复制一张图片的**像素**（不是文件），另一边能粘贴
- [ ] 大截图测试（`clipboardSize` 足够）
- [ ] 如果失败，确认 Linux 会话是 X11 还是 Wayland

```bash
echo $XDG_SESSION_TYPE
```

## 阶段 8：文件共享

- [ ] Linux 安装 Samba
- [ ] 创建 `/srv/share`
- [ ] 配置 `[share]`
- [ ] `smbpasswd -a` 设置密码
- [ ] `smbd` 运行
- [ ] 防火墙放行 `10.10.10.1` 访问 445
- [ ] Windows `Test-NetConnection 10.10.10.2 -Port 445` 为 True
- [ ] Windows 映射 `Z:`
- [ ] 双向读写测试

## 阶段 9：稳定性

- [ ] 只保留一套 Deskflow 实例
- [ ] 旧中文路径目录已改名/删除
- [ ] 旧快捷方式已清理
- [ ] 重启 Windows 后 24800 能起来（或运行启动脚本）
- [ ] 重启 Linux 后 IP 仍是 `10.10.10.2`
- [ ] 休眠/唤醒后客户端能重连
- [ ] 备份了 `Deskflow.conf`、`deskflow-server.conf`、`smb.conf`

## 阶段 10：安全复盘

- [ ] 24800 没有暴露在 Wi-Fi/公网
- [ ] 445 没有暴露在公网
- [ ] 没有使用 `checkPeerFingerprints=false` 连公共网络
- [ ] Samba 密码足够强
- [ ] 不需要时关闭 Deskflow/Samba

## 如果只能记住三件事

1. **纯英文路径**；
2. **同网段静态 IP，不设默认网关**；
3. **一台机器只留一套实例**。

## 相关文档

- 故障对照：[`08-troubleshooting.md`](08-troubleshooting.md)
- 网络与安全：[`05-network-security.md`](05-network-security.md)
- Samba：[`07-samba.md`](07-samba.md)
