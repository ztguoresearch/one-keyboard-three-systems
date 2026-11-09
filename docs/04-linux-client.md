# Linux 端：安装、固定 IP、连接和 Wayland

> 目标：让 Linux 作为 Client，固定 `10.10.10.2/24`，主动连接 `10.10.10.1:24800`。

## 1. 先看系统版本

```bash
lsb_release -a
# 或
grep VERSION_CODENAME /etc/os-release
uname -m
```

- `x86_64` → 选 `x86_64`
- `aarch64` → 选 `aarch64`

## 2. 安装 Deskflow

### 方式 A：Flatpak（最省事，推荐给 Ubuntu 22.04/24.04）

```bash
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.deskflow.deskflow
```

启动：

```bash
flatpak run org.deskflow.deskflow
```

### 方式 B：deb

从 [Releases](https://github.com/deskflow/deskflow/releases) 下载与你的 Ubuntu 版本匹配的 deb：

```text
deskflow-1.27.0-ubuntu-resolute-x86_64.deb   # 26.04
deskflow-1.27.0-ubuntu-stonking-x86_64.deb   # 26.10
```

安装：

```bash
cd ~/Downloads
sudo apt install ./deskflow-1.27.0-ubuntu-resolute-x86_64.deb
```

### 方式 C：rpm（Fedora/openSUSE）

```bash
sudo dnf install ./deskflow-1.27.0-fedora-46-x86_64.rpm
```

> 版本不同，文件名不同；以 Releases 页面为准。

## 3. 固定直连 IP

假设接口是 `eno1`，连接名是 `Wired connection 1`。

查看：

```bash
nmcli -t -f NAME,DEVICE con show
ip -br addr show eno1
```

修改：

```bash
CON="Wired connection 1"

sudo nmcli con mod "$CON" \
  ipv4.method manual \
  ipv4.addresses 10.10.10.2/24 \
  ipv4.gateway "" \
  ipv4.dns "" \
  ipv4.never-default yes

sudo nmcli con up "$CON"
```

如果还没有连接：

```bash
sudo nmcli con add type ethernet ifname eno1 con-name direct ip4 10.10.10.2/24
sudo nmcli con mod direct ipv4.never-default yes
sudo nmcli con up direct
```

验证：

```bash
ip -br addr show eno1
ip route | grep 10.10.10
ping -c 3 10.10.10.1
```

期望：

```text
10.10.10.0/24 dev eno1 proto kernel scope link src 10.10.10.2
```

> **不要设默认网关。** `ipv4.never-default yes` 可以防止直连抢走上网流量。Linux 上网继续走 Wi-Fi 或另一个网卡。

### netplan 版本

如果系统用 netplan 而不是 NetworkManager：

```yaml
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: false
      addresses: [10.10.10.2/24]
      optional: true
```

```bash
sudo netplan apply
```

## 4. 打开 Deskflow，做 Client

1. 选 **“使用另一台计算机的鼠标和键盘”**（Client）；
2. 服务器地址填 `10.10.10.1`；
3. 点 **Connect**。

如果服务器配置里已经有你的 Linux 主机名，连上后就能用；如果没有，服务端会提示添加屏幕，或者需要手动在 Server 配置里加。

Linux 主机名：

```bash
hostname
```

## 5. Wayland 还是 X11

查看：

```bash
echo $XDG_SESSION_TYPE
```

### X11

- Deskflow 支持较成熟；
- 图片剪贴板通常正常；
- 适合排障时优先使用。

### Wayland

- GNOME 45+/KDE 6.1+ 支持输入注入；
- 首次会弹远程桌面/输入捕获权限，点允许；
- 剪贴板图片可能受限，后台程序无法稳定写图片剪贴板。

如果图片粘贴失败：

1. 注销；
2. 登录界面点齿轮；
3. 选 **Ubuntu on Xorg**；
4. 重新登录，重连 Deskflow；
5. 再测图片。

## 6. 防火墙

Deskflow Client 是主动外连，一般不需要放行入站 24800。

如果你在 Linux 上跑 Samba，需要放行 445（只给 Windows 直连 IP）：

```bash
sudo ufw allow from 10.10.10.1 to any port 445 proto tcp
```

firewalld：

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.1" port port="445" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## 7. 开机自启

### Flatpak

可以创建用户级 systemd 服务，或把 Flatpak 应用加入桌面环境的“启动应用程序”。

### deb/rpm

创建 `~/.config/systemd/user/deskflow-client.service`：

```ini
[Unit]
Description=Deskflow Client
After=network-online.target

[Service]
ExecStart=/usr/bin/deskflow-core client 10.10.10.1
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now deskflow-client.service
```

> 不同安装方式的二进制路径不同，先用 `which deskflow-core` 确认。

## 8. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 连接超时 | IP/防火墙/服务端没监听 | `ping`、`nc -vz 10.10.10.1 24800` |
| Connection refused | 服务端没启动 | 检查服务端 24800 |
| TLS 错误 | 指纹未信任 | GUI 确认，或可信网络临时关闭校验 |
| 鼠标能过去但键盘不行 | 输入注入权限 | Wayland 授权；切 Xorg |
| 图片贴不出来 | 复制的是文件，或 Wayland | 复制图片像素；切 Xorg |
| 重启后 IP 变了 | DHCP/未持久化 | 用 nmcli 固定，检查 `ipv4.method manual` |

## 相关文档

- 网络与安全：[`05-network-security.md`](05-network-security.md)
- 剪贴板：[`06-clipboard.md`](06-clipboard.md)
- 故障对照：[`08-troubleshooting.md`](08-troubleshooting.md)
