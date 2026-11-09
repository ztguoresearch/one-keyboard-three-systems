# Linux 共享文件夹 + Windows 映射 Z: 盘

> 目标：Linux 做 Samba 服务端，Windows 把共享挂成 `Z:`，像本地盘一样拖文件。

## 1. 网络前提

| 机器 | IP |
|---|---|
| Windows | `10.10.10.1` |
| Linux | `10.10.10.2` |

先确认互通：

```powershell
Test-NetConnection 10.10.10.2 -Port 445
```

在 Samba 没配好之前，这个结果通常是 `False`。

## 2. Linux 安装 Samba

### Ubuntu / Debian / 麒麟 / UOS

```bash
sudo apt update
sudo apt install -y samba
```

### Fedora / RHEL / CentOS

```bash
sudo dnf install -y samba
```

## 3. 建共享目录

```bash
sudo mkdir -p /srv/share
sudo chown -R "$USER":"$USER" /srv/share
```

> 不要直接共享整个 `/home`。权限和家目录访问控制容易出问题，`/srv/share` 更干净。

## 4. 配置 smb.conf

先备份：

```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
```

确认没有同名 `[share]`：

```bash
grep -n '^\[share\]' /etc/samba/smb.conf
```

如果没有，追加：

```bash
sudo tee -a /etc/samba/smb.conf >/dev/null <<'EOF'

[share]
    path = /srv/share
    browseable = yes
    read only = no
    valid users = youruser
    create mask = 0664
    directory mask = 0775
EOF
```

把 `youruser` 换成你的 Linux 用户名：

```bash
whoami
```

## 5. 设置 Samba 密码

Samba 密码和 Linux 登录密码是分开的：

```bash
sudo smbpasswd -a youruser
```

输入两次密码。

## 6. 启动服务

### Ubuntu / Debian

```bash
sudo systemctl enable --now smbd
sudo systemctl restart smbd
```

可选：需要“网上邻居”按主机名发现时：

```bash
sudo systemctl enable --now nmbd
```

### Fedora / RHEL

```bash
sudo systemctl enable --now smb
sudo systemctl restart smb
```

检查配置：

```bash
testparm -s
```

检查本机共享：

```bash
smbclient -L //127.0.0.1 -U youruser
```

## 7. 防火墙

### ufw（Ubuntu）

只允许 Windows 直连地址：

```bash
sudo ufw allow from 10.10.10.1 to any port 445 proto tcp
```

如果 ufw 没启用，规则不会生效，但也不影响。

### firewalld（Fedora/RHEL）

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.1" port port="445" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## 8. SELinux（Fedora/RHEL）

如果写入被拒绝：

```bash
sudo setsebool -P samba_export_all_rw on
sudo chcon -Rt samba_share_t /srv/share
```

更持久的写法（可选）：

```bash
sudo semanage fcontext -a -t samba_share_t "/srv/share(/.*)?"
sudo restorecon -Rv /srv/share
```

## 9. AppArmor（Ubuntu）

Ubuntu 的 Samba AppArmor profile 通常会在 `smbd` 重启时自动读取导出目录。

如果日志里出现 `apparmor="DENIED"`：

```bash
sudo aa-complain /usr/sbin/smbd
sudo systemctl restart smbd
```

确认可用后，再考虑收紧策略。

## 10. Windows 映射网络驱动器

### 方式 A：资源管理器

1. `Win+R` → `\\10.10.10.2\share`
2. 用户名：`10.10.10.2\youruser`
3. 密码：Samba 密码
4. 右键“此电脑” → **映射网络驱动器**
5. 驱动器：`Z:`
6. 文件夹：`\\10.10.10.2\share`
7. 勾选“登录时重新连接”

### 方式 B：命令行

```powershell
net use Z: \\10.10.10.2\share /user:10.10.10.2\youruser *
```

删除旧映射：

```powershell
net use Z: /delete
```

## 11. 验证

Windows：

```powershell
Test-NetConnection 10.10.10.2 -Port 445
dir Z:\
```

Linux：

```bash
ls -ld /srv/share
sudo systemctl status smbd --no-pager
```

## 12. 权限与常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 445 不通 | Samba 没启动/防火墙 | `systemctl status smbd`、放行 445 |
| 拒绝访问 | 用户名/密码/Samba 用户 | `sudo smbpasswd -a youruser` |
| 能读不能写 | `read only = no` 没生效/目录权限 | 检查配置和 `ls -ld` |
| Windows 提示不安全来宾 | 用了 guest | 用账号密码，别开 `guest ok` |
| 改了配置不生效 | 没重启 | `sudo systemctl restart smbd` |
| Windows 缓存旧密码 | 凭据管理器 | `net use * /delete`，删旧凭据 |
| SELinux 拒绝 | 类型不对 | `setsebool`、`chcon` |
| 中文文件名乱码 | 编码 | Samba 默认 UTF-8，检查客户端 |

## 13. 性能

Samba 的速度取决于链路：

| 链路 | 大文件大致速度 |
|---|---|
| 100 Mbps | ~11 MB/s |
| 1 Gbps | ~100 MB/s |
| 2.5 Gbps | ~250 MB/s |
| 10 Gbps | ~500 MB/s+ |

本次 Windows 端是 Realtek USB GbE，实际协商到 100 Mbps，所以 SMB 只有约 11 MB/s。想提速，先解决链路协商，而不是调 Samba 参数。

### 不适合放 Samba 的东西

- Git 仓库（海量小文件、锁文件）
- `node_modules`
- 数据库文件
- 大型 Access/Excel 直接编辑

这些建议放本地，或先打包再传。

## 14. 安全

- 不要把 445 映射到公网；
- 只允许直连 IP 访问；
- 密码要强；
- 不需要时关闭 Samba；
- 共享目录定期备份。

## 相关文档

- 网络与安全：[`05-network-security.md`](05-network-security.md)
- 故障对照：[`08-troubleshooting.md`](08-troubleshooting.md)
