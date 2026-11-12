# ==========================================================
#  SillyTavern 酒馆 · Windows 一键安装脚本
#  项目地址：https://github.com/eko-fox/sillytavern-termux
#  用法（在 PowerShell 里粘贴这一行，回车）：
#    国内：irm https://gh-proxy.com/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.ps1 | iex
#    海外：irm https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.ps1 | iex
#  装好之后：桌面上会有「启动酒馆」和「酒馆菜单」两个图标
# ==========================================================

& {

$SCRIPT_VER = 'v1.0'

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # Windows PowerShell 的进度条会让下载变得特别慢
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$BASE_NAME   = 'SillyTavern-OneClick'
$ST_BRANCH   = 'release'
$NPM_MIRROR  = 'https://registry.npmmirror.com'
$REPO_LIST = @(
  'https://github.com/SillyTavern/SillyTavern.git',
  'https://gh-proxy.com/https://github.com/SillyTavern/SillyTavern.git',
  'https://ghfast.top/https://github.com/SillyTavern/SillyTavern.git'
)
$TOTAL = 7

# ---------- 小工具 ----------
function Say($t, $c = 'Gray') { Write-Host "  $t" -ForegroundColor $c }
function Info($t) { Say "▸ $t" Cyan }
function Ok($t)   { Say "✔ $t (≧▽≦)" Green }
function Warn($t) { Say "⚠ $t (・_・;)" Yellow }
function Step($n, $t) { Write-Host ''; Write-Host "  ━━━━━ 【$n/$TOTAL】$t ━━━━━" -ForegroundColor Magenta }
function Fail($t) { throw "STFAIL:$t" }
function Ask-Yes($q) { $a = Read-Host "  ? $q [Y/n]"; return ($a -eq '' -or $a -match '^[Yy]') }
function Ask-No($q)  { $a = Read-Host "  ? $q [y/N]"; return ($a -match '^[Yy]') }

function Get-Json($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
    return ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json)
  } catch { return $null }
}

# 按顺序试多条下载线路，下载成功返回 $true
function Get-File($urls, $out, $minBytes) {
  foreach ($u in $urls) {
    Info "下载线路：$u"
    if (Test-Path $out) { Remove-Item $out -Force }
    $ok = $false
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
      & curl.exe -L --fail --retry 2 --connect-timeout 15 --speed-limit 1024 --speed-time 40 -o $out $u | Out-Host
      $ok = ($LASTEXITCODE -eq 0)
    } else {
      try { Invoke-WebRequest -Uri $u -OutFile $out -UseBasicParsing -TimeoutSec 900; $ok = $true } catch { $ok = $false }
    }
    if ($ok -and (Test-Path $out) -and ((Get-Item $out).Length -ge $minBytes)) { return $true }
    Warn '这条线路不通，换下一条'
  }
  return $false
}

function Expand-Zip($zip, $dest) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($zip, $dest)
}

function Get-NodeMajor {
  try { $v = (& node -v) 2>$null; if ($v -match '^v(\d+)\.') { return [int]$Matches[1] } } catch {}
  return 0
}

# ---------- 生成管理菜单和桌面图标 ----------
function Write-Menu($BASE) {
  $menuPath = Join-Path $BASE 'menu.ps1'
  $menu = @'
# 酒馆管理菜单（由一键安装脚本生成，项目地址：https://github.com/eko-fox/sillytavern-termux）
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$BASE       = '__BASE__'
$SCRIPT_VER = '__SCRIPT_VER__'
$ST_DIR     = Join-Path $BASE 'SillyTavern'
$NODE_DIR   = Join-Path $BASE 'tools\node'
$GIT_DIR    = Join-Path $BASE 'tools\git'
$MENU       = Join-Path $BASE 'menu.ps1'
$LATEST     = Join-Path $BASE '.latest_version'
$STAMP      = Join-Path $BASE '.update_check'
$HELPER_DIR = Join-Path $ST_DIR 'data\default-user\extensions\JS-Slash-Runner'
$NPM_MIRROR = 'https://registry.npmmirror.com'
$RAW = 'https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.ps1'
$SCRIPT_URLS = @($RAW, "https://gh-proxy.com/$RAW", "https://ghfast.top/$RAW")
$HELPER_URLS = @(
  'https://github.com/N0VI028/JS-Slash-Runner.git',
  'https://gh-proxy.com/https://github.com/N0VI028/JS-Slash-Runner.git',
  'https://ghfast.top/https://github.com/N0VI028/JS-Slash-Runner.git'
)
$HELPER_CREDIT = '酒馆助手是第三方扩展（作者：KAKAA、青空莉想做舞台少女的狗）'

if (Test-Path (Join-Path $NODE_DIR 'node.exe')) { $env:Path = "$NODE_DIR;$env:Path" }
if (Test-Path (Join-Path $GIT_DIR 'cmd\git.exe')) { $env:Path = "$GIT_DIR\cmd;$env:Path" }
try { $Host.UI.RawUI.WindowTitle = '酒馆管理菜单' } catch {}

function Say($t, $c = 'Gray') { Write-Host "  $t" -ForegroundColor $c }
function Ok($t)   { Say "✔ $t (≧▽≦)" Green }
function Warn($t) { Say "⚠ $t (・_・;)" Yellow }
function Bad($t)  { Say "✘ $t (╥﹏╥)" Red }
function Ask-Yes($q) { $a = Read-Host "  ? $q [Y/n]"; return ($a -eq '' -or $a -match '^[Yy]') }
function Ask-No($q)  { $a = Read-Host "  ? $q [y/N]"; return ($a -match '^[Yy]') }
$GITNET = @('-c', 'http.lowSpeedLimit=1000', '-c', 'http.lowSpeedTime=40')

function Get-Ver($file) {
  if (Test-Path $file) { try { return (Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch {} }
  return $null
}

function Test-StRunning {
  try {
    $c = New-Object Net.Sockets.TcpClient
    $r = $c.BeginConnect('127.0.0.1', 8000, $null, $null)
    if (-not $r.AsyncWaitHandle.WaitOne(500)) { $c.Close(); return $false }
    $c.EndConnect($r); $c.Close(); return $true
  } catch { return $false }
}

function Get-Downloads {
  try { $p = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path; if ($p) { return $p } } catch {}
  return (Join-Path $env:USERPROFILE 'Downloads')
}

function Start-St {
  if (-not (Test-Path (Join-Path $ST_DIR 'server.js'))) { Bad '找不到酒馆，可能需要重新安装'; return $false }
  if (Test-StRunning) {
    Ok '酒馆已经在运行啦，直接帮你打开浏览器'
    Start-Process 'http://127.0.0.1:8000'
    return $false
  }
  Write-Host ''
  Say '✧ 酒馆启动中，准备好以后浏览器会自动打开～' Green
  Say '（第一次启动比较慢，可能要等一两分钟）' Cyan
  Say '没自动打开的话，手动在浏览器输入：127.0.0.1:8000' Yellow
  Say '♪ 这个窗口要一直开着哦，关掉它酒馆就停了' Magenta
  Write-Host ''
  Push-Location $ST_DIR
  try { & node server.js | Out-Host } finally { Pop-Location }
  Say '酒馆已关闭，下次见～ (ﾉ´▽｀)ﾉ♪' Cyan
  return $true
}

function Install-Deps {
  Push-Location $ST_DIR
  try { & npm.cmd install --no-audit --no-fund --omit=dev "--registry=$NPM_MIRROR" | Out-Host; return ($LASTEXITCODE -eq 0) }
  finally { Pop-Location }
}

function Update-St {
  if (Test-StRunning) { Bad '酒馆正在运行，先关掉酒馆窗口再更新'; return }
  Warn '建议更新前先备份一下哦'
  & git -C $ST_DIR @GITNET pull --ff-only
  if ($LASTEXITCODE -ne 0) { Bad '更新失败：可能改过酒馆文件，或者网络不通'; return }
  if (Install-Deps) { Ok '酒馆更新完成' } else { Bad '依赖更新失败，可以试试菜单里的「修复依赖」' }
  if (Test-Path (Join-Path $HELPER_DIR '.git')) { Install-Helper $true }
}

function Backup-St {
  $data = Join-Path $ST_DIR 'data'
  if (-not (Test-Path $data)) { Warn '还没有数据可以备份（先启动一次酒馆）'; return }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $f = Join-Path (Get-Downloads) ('酒馆备份_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
  Say '打包中… ε=ε=┏( ・_・)┛' Cyan
  try {
    [IO.Compression.ZipFile]::CreateFromDirectory($data, $f, [IO.Compression.CompressionLevel]::Optimal, $true)
    Ok "备份好啦：$f"
  } catch { Bad "备份失败：$($_.Exception.Message)" }
}

function Restore-St {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $files = @(Get-ChildItem -Path (Get-Downloads) -Filter '酒馆备份_*.zip' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  if ($files.Count -eq 0) { Warn '在「下载」文件夹里没找到备份文件（名字像 酒馆备份_日期.zip）'; return }
  Write-Host ''
  Say '找到这些备份（最新的在最上面）：' Cyan
  for ($i = 0; $i -lt $files.Count; $i++) { Say ('{0}. {1}' -f ($i + 1), $files[$i].Name) }
  $n = Read-Host '  输入要恢复的编号，直接回车取消'
  $idx = 0
  if (-not [int]::TryParse($n, [ref]$idx) -or $idx -lt 1 -or $idx -gt $files.Count) { Say '已取消～' Green; return }
  $zip = $files[$idx - 1].FullName
  $valid = $false
  try {
    $z = [IO.Compression.ZipFile]::OpenRead($zip)
    $valid = ($z.Entries.Count -gt 0) -and (@($z.Entries | Where-Object { $_.FullName -notmatch '^data[\\/]' }).Count -eq 0)
    $z.Dispose()
  } catch { $valid = $false }
  if (-not $valid) { Bad '这个文件好像不是酒馆备份，或者已经损坏了'; return }
  if (Test-StRunning) { Bad '酒馆正在运行，先关掉酒馆窗口再恢复'; return }
  Warn '恢复会替换掉现在的聊天、角色卡和设置'
  Say '（现在的数据会先改名保存成 data_旧_时间，不会直接删掉）' Yellow
  if (-not (Ask-No '确定要恢复吗？')) { Say '已取消～' Green; return }
  $data = Join-Path $ST_DIR 'data'
  $old = $null
  if (Test-Path $data) {
    $old = Join-Path $ST_DIR ('data_旧_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Move-Item -LiteralPath $data -Destination $old
  }
  Say '恢复中… ε=ε=┏( ・_・)┛' Cyan
  try {
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $ST_DIR)
    Ok '恢复好啦！启动酒馆就能看到了'
    if ($old) { Say "旧数据放在：$(Split-Path $old -Leaf)，确认没问题以后可以不用管它" Cyan }
  } catch {
    if (Test-Path $data) { Remove-Item -LiteralPath $data -Recurse -Force -ErrorAction SilentlyContinue }
    if ($old) { Move-Item -LiteralPath $old -Destination $data }
    Bad '恢复失败，已经把原来的数据放回去了，什么都没丢'
  }
}

function Backup-Menu {
  Write-Host ''
  Say '╭──── 备份与恢复 ────' Cyan
  Say '│  1. 导出备份（存到「下载」文件夹）'
  Say '│  2. 导入备份（从「下载」文件夹恢复）'
  Say '│  0. 返回'
  Say '╰────────────────────' Cyan
  Say '提醒：备份里有 API 密钥，别把备份文件发给别人哦' Yellow
  $c = Read-Host '  输入数字后回车'
  switch ($c) { '1' { Backup-St } '2' { Restore-St } default { Say '返回菜单～' Cyan } }
}

function Install-Helper($auto) {
  $ext = Split-Path $HELPER_DIR -Parent
  if (Test-Path (Join-Path $HELPER_DIR '.git')) {
    Say '更新酒馆助手中… (ง •_•)ง' Cyan
    & git -C $HELPER_DIR @GITNET pull --ff-only
    if ($LASTEXITCODE -eq 0) { Ok '酒馆助手已是最新' } else { Bad '酒馆助手更新失败，可能是网络问题' }
    return
  }
  if (-not $auto) {
    Say $HELPER_CREDIT Cyan
    if (-not (Ask-No '要安装酒馆助手吗？')) { Say '已取消～' Green; return }
  }
  New-Item -ItemType Directory -Force -Path $ext | Out-Null
  foreach ($round in 1..2) {
    foreach ($u in $HELPER_URLS) {
      Say "▸ 尝试线路：$u" Cyan
      Say '  （40 秒没动静会自动换下一条线路）' Cyan
      & git @GITNET clone --depth 1 $u $HELPER_DIR
      if ($LASTEXITCODE -eq 0) { Ok '酒馆助手安装好啦，重启酒馆后在扩展里就能看到'; return }
      if (Test-Path $HELPER_DIR) { Remove-Item -LiteralPath $HELPER_DIR -Recurse -Force -ErrorAction SilentlyContinue }
    }
  }
  Bad '酒馆助手没装上，可能是网络问题，之后在菜单里选 4 再试试'
}

function Fix-Deps {
  if (Test-StRunning) { Bad '酒馆正在运行，先关掉酒馆窗口再修复'; return }
  Say '重新安装依赖中… (。-ω-)zzz' Cyan
  $nm = Join-Path $ST_DIR 'node_modules'
  if (Test-Path $nm) { cmd /c "rd /s /q `"$nm`"" }
  if (Install-Deps) { Ok '依赖修复完成' } else { Bad '依赖安装失败，检查一下网络再试' }
}

function Uninstall-St {
  Write-Host ''
  Say '⚠ 卸载会删除酒馆、酒馆助手、所有聊天记录和角色卡，还有脚本自带的 Node 和 Git！' Red
  $a = Read-Host '  确定要卸载吗？输入 y 确认，直接回车取消'
  if ($a -notmatch '^[Yy]$') { Say '好哒，已取消卸载～' Green; return }
  if (Test-StRunning) { Bad '酒馆正在运行，先关掉酒馆窗口再卸载'; return }
  if ((Split-Path $BASE -Leaf) -ne 'SillyTavern-OneClick') { Bad "安装目录看起来不对（$BASE），为了安全不自动删除，请手动处理"; return }
  if (Ask-Yes '卸载前要先导出备份吗？') { Backup-St }
  Say '卸载中… (。-ω-)' Cyan
  $desk = [Environment]::GetFolderPath('Desktop')
  Remove-Item -LiteralPath (Join-Path $desk '启动酒馆.lnk'), (Join-Path $desk '酒馆菜单.lnk') -Force -ErrorAction SilentlyContinue
  Set-Location $env:USERPROFILE
  cmd /c "rd /s /q `"$BASE`""
  if (Test-Path $BASE) { Warn "有些文件没删干净，可以手动删除这个文件夹：$BASE" }
  else { Ok '酒馆已经卸载干净了，有缘再见～' }
  Say '想重新安装的话，再运行一次安装命令就好' Cyan
  Read-Host '  按回车关闭' | Out-Null
  exit
}

function Get-RemoteScript {
  foreach ($u in $SCRIPT_URLS) {
    try {
      $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
      $t = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
      if ($t -match "\`$SCRIPT_VER = '(v[^']+)'") { return $t }
    } catch {}
  }
  return $null
}

function Update-Menu {
  Say '正在检查菜单脚本的新版本… (｡･ω･｡)' Cyan
  $code = Get-RemoteScript
  if (-not $code) { Bad '连不上更新地址，可能是网络问题，过会儿再试试'; return }
  $null = $code -match "\`$SCRIPT_VER = '(v[^']+)'"
  $rv = $Matches[1]
  Set-Content -Path $LATEST -Value $rv -Encoding UTF8
  if ($rv -eq $SCRIPT_VER) { Ok "已经是最新版 $SCRIPT_VER 啦"; return }
  Say "发现新版本：$SCRIPT_VER → $rv，正在更新菜单…" Cyan
  $env:ST_UPDATE_MENU_ONLY = '1'
  $env:ST_BASE = $BASE
  try { Invoke-Expression $code } finally { Remove-Item Env:ST_UPDATE_MENU_ONLY -ErrorAction SilentlyContinue }
  Ok '菜单更新好啦！'
  Read-Host '  按回车打开新菜单' | Out-Null
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MENU
  exit
}

# 每天最多在后台悄悄检查一次新版本，不会卡住菜单
function Check-UpdateBg {
  if ((Test-Path $STAMP) -and (((Get-Date) - (Get-Item $STAMP).LastWriteTime).TotalHours -lt 24)) { return }
  Set-Content -Path $STAMP -Value '' -Encoding UTF8
  $null = Start-Job -ArgumentList $SCRIPT_URLS, $LATEST -ScriptBlock {
    param($urls, $out)
    foreach ($u in $urls) {
      try {
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
        $t = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
        if ($t -match "\`$SCRIPT_VER = '(v[^']+)'") { Set-Content -Path $out -Value $Matches[1] -Encoding UTF8; break }
      } catch {}
    }
  }
}

# 桌面「启动酒馆」图标：直接启动
if ($args -contains 'start') {
  if (-not (Start-St)) { Read-Host '  按回车关闭' | Out-Null }
  exit
}

Check-UpdateBg
while ($true) {
  Clear-Host
  Write-Host ''
  Write-Host '       /\_/\' -ForegroundColor Magenta
  Write-Host '      ( ^.^ )   欢迎回来～' -ForegroundColor Magenta
  Write-Host '       > ♡ <' -ForegroundColor Magenta
  $stv = Get-Ver (Join-Path $ST_DIR 'package.json')
  $hpv = Get-Ver (Join-Path $HELPER_DIR 'manifest.json')
  $line = '酒馆 ' + $(if ($stv) { $stv } else { '未安装' })
  if ($hpv) { $line += " · 助手 $hpv" }
  $line += " · 脚本 $SCRIPT_VER"
  Say $line DarkCyan
  if (Test-Path $LATEST) {
    $lv = (Get-Content $LATEST -Raw -Encoding UTF8).Trim()
    if ($lv -and $lv -ne $SCRIPT_VER) { Say "✧ 菜单有新版本 $lv 啦，按 7 更新～" Yellow }
  }
  Say '╭──── ✧ 酒馆管理菜单 ────' Cyan
  Say '│' Cyan
  Say '│  1. 启动酒馆'
  Say '│  2. 更新酒馆'
  Say '│  3. 备份与恢复'
  Say '│  4. 安装/更新酒馆助手'
  Say '│  5. 修复依赖'
  Say '│  6. 卸载酒馆'
  Say '│  7. 更新菜单脚本'
  Say '│  0. 退出菜单'
  Say '│' Cyan
  Say '╰───────────────────────' Cyan
  $c = Read-Host '  输入数字后回车'
  switch ($c) {
    '1' { $null = Start-St }
    '2' { Update-St }
    '3' { Backup-Menu }
    '4' { Install-Helper $false }
    '5' { Fix-Deps }
    '6' { Uninstall-St }
    '7' { Update-Menu }
    '0' { exit }
    default { Say '没有这个选项哦～ (・∀・)?' Yellow }
  }
  Read-Host '  按回车返回菜单' | Out-Null
}
'@
  $menu = $menu.Replace('__BASE__', $BASE).Replace('__SCRIPT_VER__', $SCRIPT_VER)
  [IO.File]::WriteAllText($menuPath, $menu, (New-Object Text.UTF8Encoding $true))
  Ok '已生成管理菜单'

  # 桌面图标
  $desk = [Environment]::GetFolderPath('Desktop')
  $icon = Join-Path $BASE 'SillyTavern\public\favicon.ico'
  $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $ws = New-Object -ComObject WScript.Shell
  foreach ($s in @(@('启动酒馆', 'start'), @('酒馆菜单', ''))) {
    $lnk = $ws.CreateShortcut((Join-Path $desk ($s[0] + '.lnk')))
    $lnk.TargetPath = $ps
    $lnk.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" {1}' -f $menuPath, $s[1]).Trim()
    $lnk.WorkingDirectory = $BASE
    if (Test-Path $icon) { $lnk.IconLocation = $icon }
    $lnk.Save()
  }
  Ok '已在桌面放好「启动酒馆」和「酒馆菜单」两个图标'
}

# ---------- 菜单自动更新时只走这里 ----------
if ($env:ST_UPDATE_MENU_ONLY -eq '1' -and $env:ST_BASE) {
  Write-Menu $env:ST_BASE
  return
}

try {
  Clear-Host
  Write-Host "  安装脚本 $SCRIPT_VER · $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
  Write-Host ''
  Write-Host '       /\_/\' -ForegroundColor Magenta
  Write-Host '      ( o.o )    ✧ 酒馆一键安装 · 电脑版 ✧' -ForegroundColor Magenta
  Write-Host '       > ^ <' -ForegroundColor Magenta
  Say '╭───────────────────────' Cyan
  Say '│  全程大概 5～15 分钟，放着就好～' Cyan
  Say '╰───────────────────────' Cyan

  if (-not [Environment]::Is64BitOperatingSystem) { Fail '这个脚本只支持 64 位的 Windows' }

  # ---------- 1. 选择安装位置 ----------
  Step 1 '选择安装位置'
  $drives = @([IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady })
  if ($drives.Count -eq 0) { Fail '没找到可以安装的硬盘' }
  $existing = $drives | Where-Object { Test-Path (Join-Path $_.RootDirectory.FullName "$BASE_NAME\SillyTavern\package.json") } | Select-Object -First 1
  if ($existing) {
    $def = $existing.Name.Substring(0, 1)
    Info "发现 $($def): 盘已经装过酒馆了，默认继续用这个位置"
  } else {
    $d = $drives | Where-Object { $_.Name -like 'D*' -and $_.AvailableFreeSpace -gt 3GB } | Select-Object -First 1
    if (-not $d) { $d = $drives | Sort-Object AvailableFreeSpace -Descending | Select-Object -First 1 }
    $def = $d.Name.Substring(0, 1)
  }
  Say '你的电脑上有这些盘：' Cyan
  foreach ($dr in $drives) { Say ('  {0}  剩余 {1:N1} GB' -f $dr.Name.Substring(0, 2), ($dr.AvailableFreeSpace / 1GB)) }
  $pick = (Read-Host "  ? 要装在哪个盘？输入盘符（比如 D），直接回车用 $def 盘").Trim().TrimEnd(':').ToUpper()
  if ($pick -eq '') { $pick = $def }
  $drive = $drives | Where-Object { $_.Name.Substring(0, 1) -eq $pick } | Select-Object -First 1
  if (-not $drive) { Fail "没有找到 $pick 盘，重新运行一次，输入上面列出的盘符" }
  if ($drive.AvailableFreeSpace -lt 2GB) { Warn "$pick 盘剩余空间不到 2GB，可能装不下" }
  $BASE = Join-Path $drive.RootDirectory.FullName $BASE_NAME
  $ST_DIR = Join-Path $BASE 'SillyTavern'
  $TOOLS = Join-Path $BASE 'tools'
  New-Item -ItemType Directory -Force -Path $TOOLS | Out-Null
  Ok "安装到：$BASE"

  # ---------- 2. 准备 Node.js ----------
  Step 2 '准备 Node.js'
  $NODE_DIR = Join-Path $TOOLS 'node'
  if (Test-Path (Join-Path $NODE_DIR 'node.exe')) { $env:Path = "$NODE_DIR;$env:Path" }
  if ((Get-NodeMajor) -ge 20) {
    Ok "Node $(& node -v) 已就绪"
  } else {
    Info '正在找最新的 Node.js 长期支持版…'
    $idx = Get-Json 'https://registry.npmmirror.com/-/binary/node/index.json'
    if (-not $idx) { $idx = Get-Json 'https://nodejs.org/dist/index.json' }
    $ver = $null
    if ($idx) {
      $e = $idx | Where-Object { $_.lts -and ($_.files -contains 'win-x64-zip') } | Select-Object -First 1
      if ($e) { $ver = $e.version }
    }
    if (-not $ver) { $ver = 'v22.12.0' }
    $name = "node-$ver-win-x64"
    $zip = Join-Path $TOOLS "$name.zip"
    $urls = @(
      "https://registry.npmmirror.com/-/binary/node/$ver/$name.zip",
      "https://cdn.npmmirror.com/binaries/node/$ver/$name.zip",
      "https://nodejs.org/dist/$ver/$name.zip"
    )
    if (-not (Get-File $urls $zip 10MB)) { Fail 'Node.js 下载失败了，检查一下网络再重新运行一次' }
    Info '解压中…'
    $tmp = Join-Path $TOOLS 'node_tmp'
    if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    if (Test-Path $NODE_DIR) { Remove-Item -LiteralPath $NODE_DIR -Recurse -Force }
    Expand-Zip $zip $tmp
    Move-Item -LiteralPath (Join-Path $tmp $name) -Destination $NODE_DIR
    Remove-Item -LiteralPath $tmp, $zip -Recurse -Force -ErrorAction SilentlyContinue
    $env:Path = "$NODE_DIR;$env:Path"
    if ((Get-NodeMajor) -lt 20) { Fail 'Node.js 装好了但是运行不了，截图发给作者看看' }
    Ok "Node $(& node -v) 已就绪"
  }

  # ---------- 3. 准备 Git ----------
  Step 3 '准备 Git'
  $GIT_DIR = Join-Path $TOOLS 'git'
  if (Test-Path (Join-Path $GIT_DIR 'cmd\git.exe')) { $env:Path = "$GIT_DIR\cmd;$env:Path" }
  if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok "$((& git --version) -join ' ') 已就绪"
  } else {
    Info '正在找最新的 Git…'
    $gitUrls = @()
    $mirror = 'https://registry.npmmirror.com/-/binary/git-for-windows/'
    $list = Get-Json $mirror
    if ($list) {
      $cands = @($list | Where-Object { $_.name -match '^v\d+\.\d+\.\d+\.windows\.\d+/$' } | Sort-Object -Descending -Property {
        $m = [regex]::Match($_.name, '^v(\d+)\.(\d+)\.(\d+)\.windows\.(\d+)')
        '{0:D4}{1:D4}{2:D4}{3:D4}' -f [int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value, [int]$m.Groups[4].Value
      })
      foreach ($c in ($cands | Select-Object -First 3)) {
        $files = Get-Json ($mirror + $c.name)
        $a = $files | Where-Object { $_.name -match '^MinGit-[\d.]+-64-bit\.zip$' } | Select-Object -First 1
        if ($a) { $gitUrls += ($mirror + $c.name + $a.name); break }
      }
    }
    $rel = Get-Json 'https://api.github.com/repos/git-for-windows/git/releases/latest'
    if ($rel) {
      $a = $rel.assets | Where-Object { $_.name -match '^MinGit-[\d.]+-64-bit\.zip$' } | Select-Object -First 1
      if ($a) { $gitUrls += "https://gh-proxy.com/$($a.browser_download_url)"; $gitUrls += $a.browser_download_url }
    }
    # 实在找不到最新版，就用一个确定存在的版本
    $gitUrls += 'https://registry.npmmirror.com/-/binary/git-for-windows/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip'
    $gitUrls += 'https://gh-proxy.com/https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip'
    $zip = Join-Path $TOOLS 'mingit.zip'
    if (-not (Get-File $gitUrls $zip 10MB)) { Fail 'Git 下载失败了，检查一下网络再重新运行一次' }
    Info '解压中…'
    if (Test-Path $GIT_DIR) { Remove-Item -LiteralPath $GIT_DIR -Recurse -Force }
    Expand-Zip $zip $GIT_DIR
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    $env:Path = "$GIT_DIR\cmd;$env:Path"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'Git 装好了但是运行不了，截图发给作者看看' }
    Ok "$((& git --version) -join ' ') 已就绪"
  }
  $GITNET = @('-c', 'http.lowSpeedLimit=1000', '-c', 'http.lowSpeedTime=40')

  # ---------- 4. 下载酒馆 ----------
  Step 4 '下载酒馆本体'
  $oldSt = $null
  if (Test-Path (Join-Path $ST_DIR 'package.json')) {
    Warn '发现已经装过酒馆了，跳过下载（想更新请在菜单里选「更新」）'
  } else {
    if (Test-Path $ST_DIR) {
      # 文件夹在但不完整（比如之前下载到一半断了）：先挪到一边，保住里面可能有的聊天数据
      $oldSt = "${ST_DIR}_旧_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
      Move-Item -LiteralPath $ST_DIR -Destination $oldSt
      Warn "发现一个不完整的酒馆文件夹，已经挪到 $(Split-Path $oldSt -Leaf)，重新下载"
    }
    $cloned = $false
    foreach ($round in 1..3) {
      if ($round -gt 1) { Warn "第 $round 轮重试，网络不稳的话多试几次常常就好了"; Start-Sleep -Seconds 3 }
      foreach ($u in $REPO_LIST) {
        Info "尝试线路：$u"
        Info '  （40 秒没动静会自动换下一条线路）'
        & git @GITNET clone --progress --depth 1 -b $ST_BRANCH $u $ST_DIR
        if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $ST_DIR 'package.json'))) { $cloned = $true; break }
        if (Test-Path $ST_DIR) { cmd /c "rd /s /q `"$ST_DIR`"" }   # 只删这次没下完的，旧文件夹已经挪走了
        Warn '这条线路不通，换下一条'
      }
      if ($cloned) { break }
    }
    if (-not $cloned) { Fail '试了好几轮都没下载下来，网络可能不太稳。换个网络（或者开关 VPN）再运行一次试试' }
    Ok '酒馆下载完成'
    if ($oldSt -and (Test-Path (Join-Path $oldSt 'data'))) {
      Move-Item -LiteralPath (Join-Path $oldSt 'data') -Destination (Join-Path $ST_DIR 'data')
      Ok '已经把旧文件夹里的聊天和角色卡搬回来了'
    }
  }

  # ---------- 5. 安装依赖 ----------
  Step 5 '安装酒馆依赖'
  Info '用国内 npm 源，会刷一堆英文，别怕～'
  Push-Location $ST_DIR
  try { & npm.cmd install --no-audit --no-fund --omit=dev "--registry=$NPM_MIRROR"; $npmOk = ($LASTEXITCODE -eq 0) } finally { Pop-Location }
  if (-not $npmOk) { Fail '依赖安装失败，可以在「酒馆菜单」里选「修复依赖」再试' }
  Ok '依赖安装完成'

  # ---------- 6. 生成菜单和桌面图标 ----------
  Step 6 '布置小窝'
  Write-Menu $BASE

  # ---------- 7. 酒馆助手（可选） ----------
  Step 7 '酒馆助手（可选）'
  Say '酒馆助手是第三方扩展（作者：KAKAA、青空莉想做舞台少女的狗）' Cyan
  if (Ask-No '要安装酒馆助手吗？') {
    $hd = Join-Path $ST_DIR 'data\default-user\extensions\JS-Slash-Runner'
    if (Test-Path (Join-Path $hd '.git')) {
      Ok '酒馆助手已经装过了'
    } else {
      New-Item -ItemType Directory -Force -Path (Split-Path $hd -Parent) | Out-Null
      $hok = $false
      foreach ($round in 1..2) {
        foreach ($u in @('https://github.com/N0VI028/JS-Slash-Runner.git',
                         'https://gh-proxy.com/https://github.com/N0VI028/JS-Slash-Runner.git',
                         'https://ghfast.top/https://github.com/N0VI028/JS-Slash-Runner.git')) {
          Info "尝试线路：$u"
          & git @GITNET clone --depth 1 $u $hd
          if ($LASTEXITCODE -eq 0) { $hok = $true; break }
          if (Test-Path $hd) { cmd /c "rd /s /q `"$hd`"" }
        }
        if ($hok) { break }
      }
      if ($hok) { Ok '酒馆助手安装好啦' } else { Warn '酒馆助手先跳过，之后在「酒馆菜单」里选 4 补装就行' }
    }
  } else {
    Info '好哒，跳过酒馆助手，以后想装可以在菜单里选 4～'
  }

  # ---------- 完成 ----------
  Write-Host ''
  Write-Host '       /\_/\      ✧*｡ 安装完成 ｡*✧' -ForegroundColor Magenta
  Write-Host '      ( ^ω^ )' -ForegroundColor Magenta
  Write-Host '       > ♡ <' -ForegroundColor Magenta
  Say '══════════════════════════════════════' Green
  Say '以后双击桌面上的「启动酒馆」就能用'
  Say '更新、备份、装酒馆助手，双击「酒馆菜单」'
  Say '══════════════════════════════════════' Green
  if (Ask-Yes '现在就启动酒馆吗？') {
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') `
      -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}" start' -f (Join-Path $BASE 'menu.ps1')) `
      -WorkingDirectory $BASE
    Ok '已经在新窗口里启动酒馆，这个窗口可以关掉啦'
  } else {
    Say '好哒～想玩的时候双击桌面上的「启动酒馆」就行 (｡•ᴗ-)✧' Magenta
  }
} catch {
  $msg = "$($_.Exception.Message)"
  if ($msg.StartsWith('STFAIL:')) { $msg = $msg.Substring(7) }
  Write-Host ''
  Say "✘ $msg (╥﹏╥)" Red
  Say '别慌～可以截图保存上面的报错，方便排查问题 (っ´▽`)っ' Yellow
}

}
