# FakeIP Route Switcher

> 为 Android 设备提供精准 FakeIP 路由分流的 Magisk / KernelSU / SukiSU / APatch 模块

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com/)

---

## 项目简介

**FakeIP Route Switcher** 是一个轻量级 Android Root 模块，用于在家庭 Wi-Fi 环境下自动注入 `28.0.0.0/8`（FakeIP 网段）静态路由，实现：

- **境内流量**：直连主路由（原生硬件加速，游戏零损耗）
- **境外流量**：自动走旁路由（MSF / Mihomo 透明代理）
- **离开家庭 Wi-Fi**：自动卸载路由，避免外出死锁

### 适用场景

| 场景 | 效果 |
|------|------|
| 家庭旁路由（fnOS + MSF） | 自动分流，无需手动切换网关 |
| 对战游戏（王者/吃鸡/原神） | 游戏 UDP 链路绝对对称，100% 正常进入对局 |
| 多设备共享网络 | 指定设备自动走旁路由，其他设备不受影响 |

---

## 功能特性

- ✅ **Wi-Fi 感知**：仅在连接指定家庭 Wi-Fi 时注入路由
- ✅ **自动卸载**：断开 Wi-Fi 时立即清除路由，避免外出死锁
- ✅ **SukiSU WebUI**：原生支持 KernelSU/SukiSU 模块内嵌 Web 控制台
- ✅ **热更新**：修改配置后 1 秒内自动生效，无需重启手机
- ✅ **中文 SSID 支持**：完美兼容中文 Wi-Fi 名称
- ✅ **零耗电**：后台守护进程休眠时 CPU 占用为 0%

---

## 安装方法

### 前置要求

- Android 设备已 Root（Magisk / KernelSU / SukiSU / APatch）
- 家庭网络已部署旁路由（如 fnOS + MSF，网关 `192.168.31.39`）
- 旁路由已启用 FakeIP 模式（默认网段 `28.0.0.0/8`）

### 刷入模块

1. 下载最新 Release 的 `fakeip-route-switcher.zip`
2. 打开 **SukiSU / KernelSU / Magisk / APatch** App
3. 点击 **模块** → **从本地安装** → 选择 zip 包
4. **重启手机**

### 默认配置

模块默认预置以下配置（安装后可通过 WebUI 修改）：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| 目标 Wi-Fi | `云海天涯两杳茫` | 家庭 Wi-Fi 名称 |
| 旁路由网关 | `192.168.31.39` | fnOS / MSF 主机 IP |
| FakeIP 网段 | `28.0.0.0/8` | Mihomo / Clash 默认 FakeIP 段 |

---

## 使用方法

### 方式一：SukiSU 原生 WebUI（推荐）

1. 重启手机后，打开 **SukiSU** App
2. 进入 **模块** 列表，找到 **「FakeIP Route Switcher」**
3. 点击 **WebUI** 按钮，即可在 App 内打开控制台

**WebUI 功能**：
- 实时显示当前 Wi-Fi 连接状态
- 一键填入当前连接的 Wi-Fi
- 自定义旁路由网关 IP
- 保存后 1 秒内热生效

### 方式二：命令行工具（Termux / adb shell）

```bash
# 查看当前状态
su -c fakeip-cfg status

# 修改配置（SSID + 网关）
su -c fakeip-cfg set "云海天涯两杳茫" "192.168.31.39"

# 立即应用配置（热生效）
su -c fakeip-cfg apply
```

---

## 工作原理

### 路由注入逻辑

```
手机连接家庭 Wi-Fi (云海天涯两杳茫)
    │
    ├─► 检测到 SSID 匹配
    │
    ▼
向 wlan0 注入静态路由：
    ip route add 28.0.0.0/8 via 192.168.31.39 dev wlan0
    │
    ├─► 访问国内网站 → 直连主路由 (192.168.31.1)
    ├─► 访问境外网站 → 自动走旁路由 (192.168.31.39)
    │
    ▼
断开 Wi-Fi → 自动删除路由（避免外出死锁）
```

### 为什么能根治游戏 UDP 不对称问题？

传统旁路由方案（网关写死为旁路由）会导致：
```
手机 → 旁路由 → 主路由 → 游戏服务器
       ↑___________________________↓
       （回程路径不一致，UDP 打洞失败）
```

本模块通过 **Option 121 等效路由注入**，让游戏流量直接走主路由：
```
手机 ──(国内流量)──► 主路由 ──► 游戏服务器
       ◄────────────────────────────┘
       （100% 对称链路，NAT 打洞成功）
```

---

## 项目结构

```
fakeip-route-switcher/
├── module.prop           # 模块元信息（声明 webroot）
├── customize.sh          # 安装脚本（写入默认配置）
├── service.sh            # 后台守护服务（Wi-Fi 监听 + 路由注入）
├── post-fs-data.sh       # 注册 CLI 命令（fakeip-cfg）
├── action.sh             # 模块卡片点击动作（备用入口）
├── fakeip-cfg.sh         # 配置后端脚本（供 WebUI / CLI 调用）
├── webroot/
│   └── index.html        # SukiSU 原生 WebUI 页面
├── .gitignore
├── LICENSE               # MIT License
└── README.md             # 本文档
```

---

## 技术细节

### Wi-Fi 状态检测

通过以下三种方式交叉验证当前连接的 SSID：
1. `cmd wifi status`（Android 11+ 推荐）
2. `dumpsys wifi`（兼容旧版本）
3. `wpa_cli`（部分设备支持）

### 路由注入命令

```bash
# 注入主路由表
ip route replace 28.0.0.0/8 via 192.168.31.39 dev wlan0

# 注入 local 路由表（Android 14/15 策略路由优先查 local）
ip route replace 28.0.0.0/8 via 192.168.31.39 dev wlan0 table local
```

### 配置文件格式

`/data/adb/modules/fakeip-route-switcher/config.env`：

```bash
TARGET_SSID_RAW="云海天涯两杳茫"
NEXT_HOP_GATEWAY="192.168.31.39"
TARGET_ROUTE="28.0.0.0/8"
INTERFACE="wlan0"
CHECK_INTERVAL=3
```

---

## 常见问题

### Q1: 为什么连接 Wi-Fi 后路由没有生效？

检查以下几点：
1. Wi-Fi 名称是否与配置完全一致（区分大小写、中英文符号）
2. 旁路由 IP 是否在当前局域网内可达（`ping 192.168.31.39`）
3. 查看日志：`cat /data/local/tmp/fakeip_route.log`

### Q2: 离开家后手机无法上网？

模块会在断开家庭 Wi-Fi 时**立即卸载路由**。如果出现异常：
1. 手动删除路由：`su -c "ip route del 28.0.0.0/8 dev wlan0"`
2. 检查日志确认卸载流程是否执行

### Q3: 支持哪些 Root 方案？

- ✅ **Magisk**（官方 / Alpha / Delta）
- ✅ **KernelSU**
- ✅ **SukiSU**
- ✅ **APatch**

### Q4: 如何卸载模块？

在 Root 管理器中禁用模块并重启，或直接删除模块目录：
```bash
su -c "rm -rf /data/adb/modules/fakeip-route-switcher"
```

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境

- macOS / Linux
- Bash / Shell
- Android SDK Platform Tools（可选，用于 adb 调试）

### 提交流程

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m "feat: add your feature"`
4. 推送分支：`git push origin feature/your-feature`
5. 创建 Pull Request

---

## 致谢

- [KernelSU](https://kernelsu.org/) - 提供模块 WebUI 规范
- [SukiSU](https://github.com/ShirkNeko/SukiSU-Ultra) - 国产 Root 管理器
- [MSF](https://github.com/scoltzero/msf/) - 旁路由管理系统（MosDNS + Mihomo）

---

## License

[MIT License](LICENSE) © 2026 LegalDog
