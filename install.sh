#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
#  SillyTavern 酒馆 · Termux 一键安装脚本
#  项目地址：https://github.com/eko-fox/sillytavern-termux
#  用法（在 Termux 里粘贴这一行）：
#    国内：curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh | bash
#    海外：curl -fsSL https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh | bash
#  装好之后：输入 st 打开管理菜单
# ==========================================================

ST_DIR="$HOME/SillyTavern"
ST_BRANCH="release"
# 下载线路：按顺序尝试，失效的镜像可以随时换掉
REPO_LIST=(
  "https://github.com/SillyTavern/SillyTavern.git"
  "https://gh-proxy.com/https://github.com/SillyTavern/SillyTavern.git"
  "https://ghfast.top/https://github.com/SillyTavern/SillyTavern.git"
)
NPM_MIRROR="https://registry.npmmirror.com"
TERMUX_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main"
TOTAL=7
SCRIPT_VER="v1.2"
LOG="$HOME/酒馆安装日志.txt"

G='\033[32m'; Y='\033[33m'; R='\033[31m'; C='\033[36m'; P='\033[35m'; B='\033[1m'; N='\033[0m'
info(){ echo -e "${C}  ▸ $*${N}"; }
ok(){   echo -e "${G}  ✔ $* (๑•̀ㅂ•́)و✧${N}"; }
warn(){ echo -e "${Y}  ⚠ $* (・_・;)${N}"; }
fail(){
  echo
  echo -e "${R}  ✘ $* (╥﹏╥)${N}"
  echo -e "${Y}  别慌～可以截图保存上面的报错，方便排查问题 (っ´▽\`)っ${N}"
  if [[ -d "$HOME/storage/downloads" ]] && cp "$LOG" "$HOME/storage/downloads/" 2>/dev/null; then
    echo -e "${C}  完整的安装日志已经存到手机 Download 文件夹：酒馆安装日志.txt${N}"
  else
    echo -e "${C}  完整的安装日志在：~/酒馆安装日志.txt（输入 cat ~/酒馆安装日志.txt 查看）${N}"
  fi
  exit 1
}
step(){
  echo
  echo -e "${P}${B}  ━━━━━ 【$1/$TOTAL】$2 ━━━━━${N}"
}
TIPS=(
  "等待的时候可以去倒杯水 (｡･ω･｡)ﾉ♡"
  "屏幕在滚动就是没卡住哦～ ٩(ˊᗜˋ*)و"
  "正在努力搬砖中… ε=ε=ε=┏(゜ロ゜;)┛"
  "第一次装会慢一点，之后就快啦 (ฅ´ω\`ฅ)"
  "装好以后记得把 Termux 加进电池白名单～ (｀・ω・´)"
)
tip(){ echo -e "${P}  ♪ ${TIPS[$((RANDOM % ${#TIPS[@]}))]}${N}"; }
# 通过 curl | bash 运行时，输入要从 /dev/tty 读
ask(){ local a; echo -ne "${B}  ? $1 ${N}[Y/n] "; read -r a < /dev/tty; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
# 默认「否」的提问：要输入 y 才算同意
ask_no(){ local a; echo -ne "${B}  ? $1 ${N}[y/N] "; read -r a < /dev/tty; [[ "$a" =~ ^[Yy] ]]; }

# ---------- 生成 st 管理菜单、自动弹菜单、桌面快捷方式 ----------
write_menu(){
cat > "$PREFIX/bin/st" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ST_DIR="$HOME/SillyTavern"
SCRIPT_VER="__SCRIPT_VER__"
# 脚本更新地址：按顺序尝试
SCRIPT_URLS=(
  "https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh"
  "https://gh-proxy.com/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh"
  "https://ghfast.top/https://raw.githubusercontent.com/eko-fox/sillytavern-termux/main/install.sh"
)
UPD_TMP="${TMPDIR:-$HOME}/st_install_new.sh"
G='\033[32m'; Y='\033[33m'; R='\033[31m'; C='\033[36m'; P='\033[35m'; B='\033[1m'; N='\033[0m'

fetch_script(){
  local url
  for url in "${SCRIPT_URLS[@]}"; do
    curl -fsSL --max-time 15 -o "$UPD_TMP" "$url" 2>/dev/null \
      && grep -q '^SCRIPT_VER=' "$UPD_TMP" && return 0
  done
  rm -f "$UPD_TMP"; return 1
}
remote_ver(){ grep -m1 '^SCRIPT_VER=' "$UPD_TMP" | cut -d'"' -f2; }

# 每天最多悄悄检查一次新版本，不会卡住菜单
check_update_bg(){
  local stamp="$HOME/.st_update_check"
  [[ -n "$(find "$stamp" -mmin -1440 2>/dev/null)" ]] && return
  touch "$stamp"
  ( fetch_script && remote_ver > "$HOME/.st_latest"; rm -f "$UPD_TMP" ) >/dev/null 2>&1 &
}

self_update(){
  echo -e "${C}  正在检查菜单脚本的新版本… (｡･ω･｡)${N}"
  fetch_script || { echo -e "${R}  连不上更新地址，可能是网络问题，过会儿再试试 (・_・;)${N}"; return; }
  local rv; rv=$(remote_ver)
  echo "$rv" > "$HOME/.st_latest"
  if [[ "$rv" == "$SCRIPT_VER" ]]; then
    echo -e "${G}  已经是最新版 $SCRIPT_VER 啦 (๑•̀ㅂ•́)و✧${N}"
    rm -f "$UPD_TMP"; return
  fi
  echo -e "${C}  发现新版本：$SCRIPT_VER → $rv，正在更新菜单…${N}"
  if bash "$UPD_TMP" --update-menu; then
    rm -f "$UPD_TMP"
    echo -e "${G}  ✔ 菜单更新好啦！(≧∇≦)ﾉ${N}"
    echo -ne "${C}  按回车打开新菜单…${N}"; read -r
    exec "$PREFIX/bin/st"
  else
    rm -f "$UPD_TMP"
    echo -e "${R}  更新失败了，菜单还是原来的版本，不影响使用 (・_・;)${N}"
  fi
}

ver_of(){ [[ -f "$1" ]] && grep -m1 '"version"' "$1" | sed 's/.*: *"\([^"]*\)".*/\1/'; }
version_line(){
  local st hp
  st=$(ver_of "$ST_DIR/package.json")
  hp=$(ver_of "$ST_DIR/data/default-user/extensions/JS-Slash-Runner/manifest.json")
  echo -ne "  酒馆 ${st:-未安装}"
  [[ -n "$hp" ]] && echo -ne " · 助手 $hp"
  echo " · 脚本 $SCRIPT_VER"
}

start_st(){
  cd "$ST_DIR" || { echo -e "${R}  找不到酒馆文件夹，可能需要重新安装 (；′⌒\`)${N}"; return; }
  if curl -s -o /dev/null --max-time 2 "http://127.0.0.1:8000"; then
    echo -e "${G}  酒馆已经在运行啦，直接帮你打开浏览器～ (｡•ᴗ-)✧${N}"
    echo -e "${C}  （要关掉它的话，切到正在运行酒馆的那个 Termux 窗口按 音量下键 + C）${N}"
    termux-open-url "http://127.0.0.1:8000"
    return
  fi
  termux-wake-lock 2>/dev/null
  echo
  echo -e "${G}  ✧ 酒馆启动中，准备好以后浏览器会自动打开～ ヾ(≧▽≦*)o${N}"
  echo -e "${C}  （第一次启动比较慢，可能要等一两分钟）${N}"
  echo -e "${Y}  要关闭酒馆：按 音量下键 + C${N}"
  echo -e "${Y}  没自动打开的话，手动在浏览器输入：127.0.0.1:8000${N}"
  echo -e "${P}  ♪ 这个窗口要一直开着哦，它是酒馆的心脏 (｡•ᴗ-)✧${N}"
  echo
  # 等酒馆真正启动好了再打开浏览器，最多等 3 分钟
  (
    for _ in $(seq 1 180); do
      if curl -s -o /dev/null --max-time 2 "http://127.0.0.1:8000"; then
        termux-open-url "http://127.0.0.1:8000"; exit 0
      fi
      sleep 1
    done
  ) &
  node server.js
  termux-wake-unlock 2>/dev/null
  echo -e "${C}  酒馆已关闭，下次见～ (ﾉ´▽｀)ﾉ♪${N}"
}

update_st(){
  cd "$ST_DIR" || return
  echo -e "${Y}  建议更新前先备份一下哦～ (｀・ω・´)${N}"
  git pull --ff-only || { echo -e "${R}  更新失败：可能改过酒馆文件，或者网络不通 (・_・;)${N}"; return; }
  npm install --no-audit --no-fund --omit=dev && echo -e "${G}  ✔ 酒馆更新完成 (๑•̀ㅂ•́)و✧${N}"
  [[ -d "$ST_DIR/data/default-user/extensions/JS-Slash-Runner/.git" ]] && helper_st
}

backup_st(){
  if [[ ! -d "$HOME/storage/downloads" ]]; then
    echo -e "${Y}  第一次备份需要存储权限，弹窗请点「允许」 (｡･ω･｡)${N}"
    termux-setup-storage; sleep 4
  fi
  [[ -d "$HOME/storage/downloads" ]] || { echo -e "${R}  没拿到存储权限，备份取消 (╥﹏╥)${N}"; return; }
  local f="$HOME/storage/downloads/酒馆备份_$(date +%Y%m%d_%H%M).tar.gz"
  echo -e "${C}  打包中… ε=ε=┏( ・_・)┛${N}"
  tar -czf "$f" -C "$ST_DIR" data \
    && echo -e "${G}  ✔ 备份好啦：在手机「Download」文件夹里 (≧∇≦)ﾉ${N}" \
    || echo -e "${R}  备份失败 (╥﹏╥)${N}"
}

restore_st(){
  if [[ ! -d "$HOME/storage/downloads" ]]; then
    echo -e "${Y}  需要存储权限才能读取备份，弹窗请点「允许」 (｡･ω･｡)${N}"
    termux-setup-storage; sleep 4
  fi
  local files=()
  mapfile -t files < <(ls -t "$HOME/storage/downloads"/酒馆备份_*.tar.gz 2>/dev/null)
  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${Y}  在手机「Download」文件夹里没找到备份文件 (・_・;)${N}"
    echo -e "${C}  备份文件的名字要是「酒馆备份_日期.tar.gz」这种格式哦${N}"
    return
  fi
  echo
  echo -e "${C}  找到这些备份（最新的在最上面）：${N}"
  local i
  for i in "${!files[@]}"; do
    echo -e "  ${B}$((i+1)).${N} $(basename "${files[$i]}")"
  done
  echo -ne "${B}  输入要恢复的编号，直接回车取消：${N}"
  local n; read -r n
  [[ "$n" =~ ^[0-9]+$ && $n -ge 1 && $n -le ${#files[@]} ]] || { echo -e "${G}  已取消～${N}"; return; }
  local f="${files[$((n-1))]}"
  tar -tzf "$f" 2>/dev/null | head -n 1 | grep -q '^data' \
    || { echo -e "${R}  这个文件好像不是酒馆备份，或者已经损坏了 (╥﹏╥)${N}"; return; }
  echo -e "${Y}  恢复会替换掉现在的聊天、角色卡和设置${N}"
  echo -e "${Y}  （现在的数据会先改名保存成 data_旧_时间，不会直接删掉）${N}"
  echo -ne "${Y}  确定要恢复吗？输入 y 确认，直接回车取消：${N}"
  local a; read -r a
  [[ "$a" =~ ^[Yy]$ ]] || { echo -e "${G}  已取消～${N}"; return; }
  mkdir -p "$ST_DIR"
  local old=""
  if [[ -d "$ST_DIR/data" ]]; then
    old="$ST_DIR/data_旧_$(date +%Y%m%d_%H%M%S)"
    mv "$ST_DIR/data" "$old"
  fi
  echo -e "${C}  恢复中… ε=ε=┏( ・_・)┛${N}"
  if tar -xzf "$f" -C "$ST_DIR"; then
    echo -e "${G}  ✔ 恢复好啦！启动酒馆就能看到了 (≧∇≦)ﾉ${N}"
    [[ -n "$old" ]] && echo -e "${C}  旧数据放在：$(basename "$old")，确认没问题以后可以不用管它${N}"
  else
    rm -rf "$ST_DIR/data"
    [[ -n "$old" ]] && mv "$old" "$ST_DIR/data"
    echo -e "${R}  恢复失败，已经把原来的数据放回去了，什么都没丢 (・_・;)${N}"
  fi
}

backup_menu(){
  echo
  echo -e "${C}  ╭──── 备份与恢复 ────${N}"
  echo -e "${C}  │${N}  ${B}1.${N} 导出备份（存到手机 Download）"
  echo -e "${C}  │${N}  ${B}2.${N} 导入备份（从 Download 恢复）"
  echo -e "${C}  │${N}  ${B}0.${N} 返回"
  echo -e "${C}  ╰────────────────────${N}"
  echo -e "${Y}  提醒：备份里有 API 密钥，别把备份文件发给别人哦${N}"
  echo -ne "${B}  输入数字后回车：${N}"
  local c; read -r c
  case "$c" in
    1) backup_st ;;
    2) restore_st ;;
    *) echo -e "${C}  返回菜单～${N}" ;;
  esac
}

helper_st(){
  local ext="$ST_DIR/data/default-user/extensions"
  local dir="$ext/JS-Slash-Runner"
  if [[ ! -d "$dir/.git" && "$1" != "--yes" ]]; then
    echo -e "${C}  酒馆助手是第三方扩展（作者：KAKAA、青空莉想做舞台少女的狗）${N}"
    echo -ne "${B}  ? 要安装酒馆助手吗？${N}[y/N] "
    local a; read -r a
    [[ "$a" =~ ^[Yy] ]] || { echo -e "${G}  已取消～${N}"; return 0; }
  fi
  mkdir -p "$ext"
  if [[ -d "$dir/.git" ]]; then
    echo -e "${C}  更新酒馆助手中… (ง •_•)ง${N}"
    git -C "$dir" pull --ff-only \
      && { echo -e "${G}  ✔ 酒馆助手已是最新 (๑•̀ㅂ•́)و✧${N}"; return 0; } \
      || { echo -e "${R}  酒馆助手更新失败，可能是网络问题 (・_・;)${N}"; return 1; }
  fi
  local url
  for url in \
    "https://github.com/N0VI028/JS-Slash-Runner.git" \
    "https://gh-proxy.com/https://github.com/N0VI028/JS-Slash-Runner.git" \
    "https://ghfast.top/https://github.com/N0VI028/JS-Slash-Runner.git"; do
    echo -e "${C}  ▸ 尝试线路：$url${N}"
    if timeout 180 git clone --progress --depth 1 "$url" "$dir"; then
      echo -e "${G}  ✔ 酒馆助手安装好啦，重启酒馆后在扩展里就能看到 (≧∇≦)ﾉ${N}"
      return 0
    fi
    rm -rf "$dir"
  done
  echo -e "${R}  酒馆助手没装上，可能是网络问题，之后在菜单里选 4 再试试 (╥﹏╥)${N}"
  return 1
}

fix_st(){
  cd "$ST_DIR" || return
  echo -e "${C}  重新安装依赖中… (。-ω-)zzz${N}"
  rm -rf node_modules
  npm install --no-audit --no-fund --omit=dev && echo -e "${G}  ✔ 依赖修复完成 (๑•̀ㅂ•́)و✧${N}"
}

uninstall_st(){
  echo
  echo -e "${R}${B}  ⚠ 卸载会删除酒馆、酒馆助手、所有聊天记录和角色卡！${N}"
  echo -ne "${Y}  确定要卸载吗？输入 y 确认，直接回车取消：${N}"
  local a; read -r a
  [[ "$a" =~ ^[Yy]$ ]] || { echo -e "${G}  好哒，已取消卸载～ (｡•ᴗ-)✧${N}"; return; }
  echo -ne "${Y}  卸载前要先导出备份吗？[Y/n] ${N}"
  read -r a
  if [[ -z "$a" || "$a" =~ ^[Yy] ]]; then
    backup_st
    echo -ne "${Y}  备份完成了吗？没问题就输入 y 继续卸载：${N}"
    read -r a
    [[ "$a" =~ ^[Yy]$ ]] || { echo -e "${G}  已取消卸载～${N}"; return; }
  fi
  echo -e "${C}  卸载中… (。-ω-)${N}"
  rm -rf "$ST_DIR"
  rm -f "$HOME/.shortcuts/启动酒馆"
  [[ -f "$HOME/.bashrc" ]] && sed -i '/# >>> 酒馆菜单 >>>/,/# <<< 酒馆菜单 <<</d' "$HOME/.bashrc"
  rm -f "$PREFIX/bin/st" "$HOME/.st_latest" "$HOME/.st_update_check"
  echo -e "${G}  ✔ 酒馆已经卸载干净了，有缘再见～ (ﾉ´▽｀)ﾉ♪${N}"
  echo -e "${C}  想重新安装的话，再运行一次安装命令就好${N}"
  exit 0
}

# 给桌面小部件用：st start 直接启动
[[ "$1" == "start" ]] && { start_st; exit; }
[[ "$1" == "helper" ]] && { helper_st --yes; exit $?; }

check_update_bg
while true; do
  clear
  echo -e "${P}"
  echo "       /\\_/\\"
  echo "      ( ^.^ )   欢迎回来～"
  echo "       > ♡ <"
  echo -ne "${N}${C}"; version_line; echo -ne "${N}"
  latest=$(cat "$HOME/.st_latest" 2>/dev/null)
  [[ -n "$latest" && "$latest" != "$SCRIPT_VER" ]] && echo -e "${Y}  ✧ 菜单有新版本 $latest 啦，按 7 更新～${N}"
  echo -e "${C}  ╭──── ✧ 酒馆管理菜单 ────${N}"
  echo -e "${C}  │${N}"
  echo -e "${C}  │${N}  ${B}1.${N} 启动酒馆"
  echo -e "${C}  │${N}  ${B}2.${N} 更新酒馆"
  echo -e "${C}  │${N}  ${B}3.${N} 备份与恢复"
  echo -e "${C}  │${N}  ${B}4.${N} 安装/更新酒馆助手"
  echo -e "${C}  │${N}  ${B}5.${N} 修复依赖"
  echo -e "${C}  │${N}  ${B}6.${N} 卸载酒馆"
  echo -e "${C}  │${N}  ${B}7.${N} 更新菜单脚本"
  echo -e "${C}  │${N}  ${B}0.${N} 退出菜单"
  echo -e "${C}  │${N}"
  echo -e "${C}  ╰───────────────────────${N}"
  echo -ne "${B}  输入数字后回车：${N}"
  read -r c
  case "$c" in
    1) start_st ;;
    2) update_st ;;
    3) backup_menu ;;
    4) helper_st ;;
    5) fix_st ;;
    6) uninstall_st ;;
    7) self_update ;;
    0) echo -e "${P}  已退出菜单，想回来就输入 st (ﾉ´▽｀)ﾉ♪${N}"; exit 0 ;;
    *) echo -e "${Y}  没有这个选项哦～ (・∀・)?${N}" ;;
  esac
  echo -ne "${C}  按回车返回菜单…${N}"
  read -r
done
EOF
sed -i "s/__SCRIPT_VER__/$SCRIPT_VER/" "$PREFIX/bin/st"
chmod +x "$PREFIX/bin/st"
ok "已创建 st 命令"

# 打开 Termux 时自动显示菜单（重复安装不会重复添加）
if ! grep -q "# >>> 酒馆菜单 >>>" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'
# >>> 酒馆菜单 >>>  （不想自动弹菜单的话，删掉这三行）
[[ $- == *i* && -z "$ST_MENU_SHOWN" ]] && { export ST_MENU_SHOWN=1; st; }
# <<< 酒馆菜单 <<<
EOF
fi
ok "已设置打开 Termux 自动显示菜单"
mkdir -p "$HOME/.shortcuts"
cat > "$HOME/.shortcuts/启动酒馆" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
/data/data/com.termux/files/usr/bin/st start
EOF
chmod +x "$HOME/.shortcuts/启动酒馆"
ok "已创建桌面快捷方式（需要装 Termux:Widget 插件才能用）"
}

# 只更新菜单（给 st 里的「更新菜单脚本」用），不重装任何东西
if [[ "$1" == "--update-menu" ]]; then
  [[ "$PREFIX" == *com.termux* ]] || { echo "请在 Termux 里运行"; exit 1; }
  write_menu
  exit 0
fi

clear
# 把安装过程同时记录到日志文件，方便排查
exec 3>&1 4>&2
exec > >(tee "$LOG") 2>&1
echo -e "\033[2m  安装脚本 $SCRIPT_VER · $(date '+%Y-%m-%d %H:%M')\033[0m"
echo -e "${P}"
echo "       /\\_/\\"
echo "      ( o.o )    ✧ 酒馆一键安装 ✧"
echo "       > ^ <"
echo -e "${N}${C}  ╭───────────────────────${N}"
echo -e "${C}  │${N}  全程大概 5～15 分钟，放着就好～"
echo -e "${C}  ╰───────────────────────${N}"

# ---------- 0. 检查环境 ----------
[[ "$PREFIX" == *com.termux* ]] || fail "请在 Termux 里运行这个脚本（不是手机自带终端哦）"

# ---------- 1. 换源 ----------
step 1 "选择软件源"
USE_MIRROR=0
if ask "要换成国内软件源吗？（国内网络强烈建议选 Y）"; then
  USE_MIRROR=1
  echo "deb $TERMUX_MIRROR stable main" > "$PREFIX/etc/apt/sources.list"
  ok "已切换到清华源"
else
  info "好哒，保持原来的源～"
fi

# ---------- 2. 安装基础软件 ----------
step 2 "更新软件包"
tip
apt-get update || fail "软件源连不上，检查一下网络，或者重新运行时换源选 Y"
apt-get -y -o Dpkg::Options::=--force-confnew upgrade || fail "软件包更新失败"
# 更新时软件源配置可能被新版本覆盖，这里重新设置一次并刷新列表
[[ $USE_MIRROR == 1 ]] && echo "deb $TERMUX_MIRROR stable main" > "$PREFIX/etc/apt/sources.list"
apt-get update || fail "软件源连不上，检查一下网络，或者重新运行时换源选 Y"
ok "软件包更新好啦"

step 3 "安装基础工具"
PKGS="git curl"
command -v node >/dev/null 2>&1 || PKGS="$PKGS nodejs-lts"
info "安装 $PKGS ..."
tip
apt-get install -y $PKGS || fail "基础软件安装失败"
ok "Node $(node -v) 已就绪"

# ---------- 3. 下载酒馆 ----------
step 4 "下载酒馆本体"
if [[ -d "$ST_DIR/.git" ]]; then
  warn "发现已经装过酒馆了，跳过下载（想更新请在菜单里选「更新」）"
else
  cloned=0
  for url in "${REPO_LIST[@]}"; do
    info "尝试线路：$url"
    if timeout 300 git clone --progress --depth 1 -b "$ST_BRANCH" "$url" "$ST_DIR"; then
      cloned=1; break
    fi
    rm -rf "$ST_DIR"
    warn "这条线路不通，换下一条"
  done
  [[ $cloned == 1 ]] || fail "所有线路都下载失败了，可能是网络问题，过会儿再试试"
  ok "酒馆下载完成"
fi

# ---------- 4. 安装依赖 ----------
step 5 "安装酒馆依赖"
info "用国内 npm 源，会刷一堆英文，别怕～"
tip
npm config set registry "$NPM_MIRROR"
cd "$ST_DIR" || fail "找不到酒馆文件夹"
npm install --no-audit --no-fund --omit=dev || fail "依赖安装失败，可以在菜单里选「修复依赖」再试"
ok "依赖安装完成"


# ---------- 5. 生成 st 管理菜单 ----------
step 6 "布置小窝"
write_menu

# ---------- 7. 安装酒馆助手（装不上也不影响酒馆本体） ----------
step 7 "酒馆助手（可选）"
echo -e "${C}  酒馆助手是第三方扩展（作者：KAKAA、青空莉想做舞台少女的狗）${N}"
if ask_no "要安装酒馆助手吗？"; then
  "$PREFIX/bin/st" helper || warn "酒馆助手先跳过，酒馆本体已经装好，之后在菜单里选 4 补装就行"
else
  info "好哒，跳过酒馆助手，以后想装可以在菜单里选 4～"
fi


# ---------- 完成 ----------
echo
echo -e "${P}       /\\_/\\      ✧*｡ 安装完成 ｡*✧"
echo -e "      ( ^ω^ )    ヽ(✿ﾟ▽ﾟ)ノ"
echo -e "       > ♡ <${N}"
echo -e "${G}  ══════════════════════════════════════${N}"
echo -e "   以后打开 Termux 会自动出现管理菜单，退出后输入 ${C}${B}st${N} 也能叫回来"
echo -e "   装了 Termux:Widget 的话，桌面添加小部件就能一键启动"
echo -e "   记得把 Termux 加进电池白名单，不然切后台会被杀～"
echo -e "${G}  ══════════════════════════════════════${N}"
echo
echo -e "${C}  安装日志保存在 ~/酒馆安装日志.txt${N}"
# 停止记录日志，之后的酒馆运行输出不写进日志
exec 1>&3 2>&4 3>&- 4>&-
sleep 0.3
if ask "现在就启动酒馆吗？"; then
  exec "$PREFIX/bin/st" start < /dev/tty
fi
echo -e "${P}  好哒～想玩的时候输入 st 就行 (｡•ᴗ-)✧${N}"
