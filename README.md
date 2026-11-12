# 酒馆一键安装（手机 / 电脑）

一行命令装好 [SillyTavern（酒馆）](https://github.com/SillyTavern/SillyTavern)，装好后有中文管理菜单，启动、更新、备份都只要按数字。

- 📱 [安卓手机版（Termux）](#安卓手机版)
- 💻 [Windows 电脑版](#windows-电脑版)

> 这是一个由社区制作的非官方安装脚本，并非 SillyTavern 或酒馆助手官方出品。使用中遇到的问题请在本仓库反馈。

## 安卓手机版

### 准备

- 一台安卓手机（iOS 不能在本地运行酒馆）
- 安装 **Termux**：请从 [F-Droid](https://f-droid.org/packages/com.termux/) 或 [Termux 的 GitHub 发布页](https://github.com/termux/termux-app/releases) 下载
  - ⚠ 不要用 Google Play 上的版本，太旧了，会安装失败
- 剩余空间建议 1GB 以上

### 安装

打开 Termux，复制下面**一行**命令粘贴进去，回车：

**国内网络：**
```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh | bash
```

**能正常访问 GitHub 的：**
```bash
curl -fsSL https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh | bash
```

全程大概 5～15 分钟，中间会问两个问题：
1. 要不要换成国内软件源：国内网络选 `Y`
2. 要不要安装酒馆助手：想装就输 `y`，不装直接回车

### 使用

装好以后，**每次打开 Termux 会自动出现管理菜单**：

| 数字 | 功能 |
|---|---|
| 1 | 启动酒馆（会自动打开浏览器） |
| 2 | 更新酒馆（装了酒馆助手会一起更新） |
| 3 | 备份与恢复 |
| 4 | 安装 / 更新酒馆助手 |
| 5 | 修复依赖（启动报错时试试） |
| 6 | 卸载酒馆 |
| 7 | 更新菜单脚本 |
| 0 | 退出菜单 |

退出菜单后输入 `st` 可以重新打开。菜单脚本有新版本时，菜单顶上会出现提示，按 7 就能更新，不会动到酒馆和你的数据。

- 浏览器没自动打开的话，手动访问 `127.0.0.1:8000`
- 关闭酒馆：在 Termux 里按 **音量下键 + C**
- **酒馆运行时 Termux 要一直开着**，清掉后台酒馆就会断开

### 桌面一键启动（可选）

从 F-Droid 安装 **Termux:Widget**，在桌面添加它的小部件，里面会有「启动酒馆」，点一下就能启动。

## Windows 电脑版

### 准备

- Windows 10 / 11（64 位）
- 不需要提前装 Node.js 和 Git，脚本会自动下载一份免安装版放在酒馆文件夹里，不会动你电脑上原有的软件
- 剩余空间建议 2GB 以上，安装时可以选择装在哪个盘（C 盘快满的话选 D 盘就好）

### 安装

1. 按键盘上的 **Win 键**，输入 `powershell`，打开 **Windows PowerShell**（不用管理员权限）
2. 复制下面**一行**命令粘贴进去，回车：

**国内网络：**
```powershell
irm https://gh-proxy.com/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.ps1 | iex
```

**能正常访问 GitHub 的：**
```powershell
irm https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.ps1 | iex
```

中间会问三个问题：
1. 装在哪个盘：输入盘符，直接回车用推荐的盘
2. 要不要安装酒馆助手：想装就输 `y`，不装直接回车
3. 现在要不要启动酒馆

### 使用

装好以后桌面上会有两个图标：

- **启动酒馆**：双击就启动，准备好以后会自动打开浏览器
- **酒馆菜单**：更新、备份与恢复、酒馆助手、修复依赖、卸载、更新菜单脚本，功能和手机版一样

注意事项：
- 酒馆运行时那个黑色窗口要一直开着，**关掉窗口酒馆就停了**
- 浏览器没自动打开的话，手动访问 `127.0.0.1:8000`
- 所有文件都在你选的那个盘的 `SillyTavern-OneClick` 文件夹里

## 备份说明

备份会打包酒馆的全部数据：角色卡、聊天记录、世界书、预设、设置和扩展，保存在「下载」文件夹里：

- 手机版：文件名类似 `酒馆备份_20261011_1530.tar.gz`
- 电脑版：文件名类似 `酒馆备份_20261112_193000.zip`

⚠ **备份里包含你填写的 API 密钥，请不要把备份文件发给别人。**

## 常见问题

### 手机版

**切到后台一会儿酒馆就断了？**
在手机设置里把 Termux 加入电池优化白名单 / 允许后台运行。不同品牌的手机设置位置不一样，可以搜索「手机型号 + 后台保活」。

**安装失败了怎么办？**
安装日志保存在 `~/酒馆安装日志.txt`，如果有存储权限也会复制一份到 `Download` 文件夹。提问时附上报错截图和日志会更容易排查。

**提示 `command not found: st`？**
说明安装没有完成，重新运行一次安装命令即可，已经下载的内容会自动跳过。

**分享文件给 Termux 时提示需要「Display over other apps」权限？**
在手机设置 → 应用 → Termux 里打开「显示在其他应用上层 / 悬浮窗」权限。

### 电脑版

**粘贴命令后提示「无法连接」或者下载很慢？**
国内网络用上面「国内网络」那一行；如果开着 VPN，试试关掉再运行，或者反过来。

**双击图标一闪就没了？**
打开「酒馆菜单」看看菜单顶上的版本号，选 5「修复依赖」试试；还不行就重新运行一次安装命令，已经下好的东西会自动跳过。

## 致谢

- [SillyTavern](https://github.com/SillyTavern/SillyTavern)
- [酒馆助手 JS-Slash-Runner](https://github.com/N0VI028/JS-Slash-Runner)（作者：KAKAA、青空莉想做舞台少女的狗）

脚本只是从以上项目的官方仓库下载安装，各项目遵循各自的许可证。

## 免责声明

本脚本按现状提供，不保证在所有设备上都能正常运行。下载线路中的加速镜像由第三方提供，脚本会优先尝试官方地址。使用前请自行了解相关风险。
