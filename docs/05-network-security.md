# 网络与安全：直连、固定 IP、只放行对端

## 1. 为什么建议直连

三种常见组网：

| 方式 | 优点 | 缺点 |
|---|---|---|
| 两台机器直连 | 延迟低、不依赖路由器、可控 | 占用一个网口，需要静态 IP |
| 同一个路由器/交换机 | 配置简单，能上网 | 受 Wi-Fi/路由器影响，IP 可能变 |
| 跨网段/VPN | 远程可用 | 延迟、防火墙、NAT 问题多 |

键鼠事件很小，Wi-Fi 也能用；但如果你要同时跑 Samba 传文件，直连更稳。

## 2. IP 规划

建议单独一个 `/24`，不要和家里/学校现有网段冲突：

```text
10.10.10.0/24
├── 10.10.10.1   Windows（Server）
├── 10.10.10.2   Linux（Client）
└── 10.10.10.3   macOS（可选 Client）
```

不要用 `192.168.1.x` 或 `192.168.0.x`，很容易和路由器网段撞车。

## 3. 静态 IP

### Windows

```text
IP:      10.10.10.1
Mask:    255.255.255.0
Gateway: 留空
```

检查：

```powershell
Get-NetIPAddress -InterfaceAlias "以太网 3" -AddressFamily IPv4 |
  Format-Table IPAddress, PrefixLength, PrefixOrigin
```

### Linux

```bash
sudo nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 10.10.10.2/24 \
  ipv4.gateway "" \
  ipv4.never-default yes
sudo nmcli con up "Wired connection 1"
```

检查：

```bash
ip -br addr show eno1
ip route | grep 10.10.10
```

### 为什么不设网关

直连只负责两台机器之间的流量。设了默认网关，Linux 可能把上网流量也发到这条线上，导致“Deskflow 能用，浏览器打不开”。

`ipv4.never-default yes` 或“网关留空”可以避免。

## 4. 只让 Deskflow 绑定直连 IP

在 `Deskflow.conf` 的 `[core]` 段：

```ini
[core]
interface=10.10.10.1
```

效果：

```text
修改前: 0.0.0.0:24800     （Wi-Fi 也能访问）
修改后: 10.10.10.1:24800  （只有直连能访问）
```

检查：

```powershell
Get-NetTCPConnection -LocalPort 24800 -State Listen |
  Format-Table LocalAddress, LocalPort
```

## 5. 防火墙只放行对端

即使已经绑定 IP，还是建议加一层防火墙。

```powershell
$rule = "Deskflow 24800 (10.10.10.2 only)"
Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule

New-NetFirewallRule `
  -DisplayName $rule `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 24800 `
  -RemoteAddress 10.10.10.2 `
  -Action Allow `
  -Profile Any
```

关闭旧的宽泛规则：

```powershell
Get-NetFirewallRule -DisplayName "Deskflow Server","Deskflow Client" -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule
```

## 6. 验证

在 Windows 上：

```powershell
Test-NetConnection 10.10.10.1 -Port 24800
Test-NetConnection 192.168.1.50 -Port 24800
```

期望：

```text
10.10.10.1:24800      True
192.168.1.50:24800   False
```

在 Linux 上：

```bash
nc -vz 10.10.10.1 24800
```

如果 `nc` 没装：

```bash
timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.10.10.1/24800' && echo open
```

## 7. TLS 指纹：安全与便利的取舍

Deskflow 1.27 默认启用 TLS，并默认要求确认对端指纹（`checkPeerFingerprints=true`）。

- `true`：更安全，但第一次连接需要在 GUI 里确认指纹；
- `false`：跳过人工确认，保留加密；适合可信直连/家庭局域网，不适合公共网络。

临时排障：

```ini
[security]
checkPeerFingerprints=false
```

长期建议：

1. 在 GUI 里完成一次指纹确认；
2. 把 `checkPeerFingerprints` 改回 `true`；
3. 如果换证书/重装，重新确认。

## 8. 公共 Wi-Fi 的风险

即使绑定了直连 IP，也要注意：

- 不要在公共 Wi-Fi 上把 `interface` 改回 `0.0.0.0`；
- 不要把 24800 端口映射到公网；
- 不要在公共网络上使用 `checkPeerFingerprints=false`；
- 不用时退出 Deskflow，或关闭 Wi-Fi。

## 9. 链路速度：万兆线不等于万兆

本次实测中：

```text
Windows 直连网卡: Realtek USB GbE
协商速度: 100 Mbps
```

原因可能是：

- 网线只有两对线/质量差；
- USB 网卡插在 USB 2.0 口；
- 网卡/对端协商问题。

100 Mbps 对键鼠足够，但 Samba 只有约 11 MB/s。想提速：

1. 换 Cat6a/Cat7 成品线；
2. 插 USB 3.0 口；
3. 检查 `Speed & Duplex` 是否为 Auto Negotiation；
4. 必要时手动设 1.0 Gbps Full Duplex，若链路断开再改回 Auto。

## 相关文档

- Windows 配置：[`03-windows-server.md`](03-windows-server.md)
- Linux 配置：[`04-linux-client.md`](04-linux-client.md)
- Samba：[`07-samba.md`](07-samba.md)
