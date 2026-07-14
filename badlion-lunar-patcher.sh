#!/bin/bash
set -o pipefail

# ──────────────────────────────────────────────
# Badlion Lunar Patcher
# Удаляет лунаровскую хуйню из Бадлиона
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

# ── Цвета ────────────────────────────────────
R=$'\033[0;31m'; G=$'\033[0;32m'; Y=$'\033[1;33m'
C=$'\033[0;36m'; M=$'\033[0;35m'; B=$'\033[1m'; D=$'\033[2m'; N=$'\033[0m'

# ── Язык ─────────────────────────────────────
case "${LANG,,}" in ru*) L=ru ;; *) L=en ;; esac

# ── Тексты ───────────────────────────────────
t() { [ "$L" = ru ] && echo "$2" || echo "$1"; }

# ── UI ───────────────────────────────────────
info()  { echo -e "  ${C}→${N} ${B}$1${N}"; }
ok()    { echo -e "  ${G}✓${N} $1"; }
warn()  { echo -e "  ${Y}⚠${N} $1"; }
fail()  { echo -e "  ${R}✗${N} $1"; }

menu() {
  clear
  echo -e "${M}"
  echo "  ╔═══════════════════════════════════════════╗"
  echo "  ║       Badlion Lunar Client Patcher        ║"
  echo "  ║     $(t 'Removes Lunar migration nag' 'Удаляет лунаровскую хуйню')    ║"
  echo "  ╚═══════════════════════════════════════════╝"
  echo -e "${N}"
  echo "  $(t 'Choose option:' 'Выбери действие:')"
  echo
  echo "    ${B}1${N}) $(t 'Select AppImage  ▶' 'Выбрать AppImage  ▶')"
  echo "    ${B}2${N}) 🌐 $(t 'Language: English' 'Язык: Русский')"
  echo "    ${B}3${N}) ${R}${B}$(t 'Exit' 'Выход')${N}"
  echo
  echo -n "  ${C}›${N} "
}

# ── Проверка зависимостей ─────────────────────
check_deps() {
  local missing=0
  command -v mksquashfs &>/dev/null || { fail "squashfs-tools не найден"; missing=1; }
  command -v asar &>/dev/null || { fail "asar не найден (npm install -g asar)"; missing=1; }

  APPIMAGETOOL=""
  for p in appimagetool "$SCRIPT_DIR/appimagetool" /tmp/appimagetool; do
    if command -v "$p" &>/dev/null; then APPIMAGETOOL="$p"; break; fi
  done

  if [ -z "$APPIMAGETOOL" ]; then
    info "$(t 'Downloading appimagetool...' 'Скачиваю appimagetool...')"
    curl -sL -o /tmp/appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x /tmp/appimagetool && APPIMAGETOOL="/tmp/appimagetool" && ok "appimagetool"
  fi
  [ "$missing" -eq 1 ] && exit 1
}

# ── Патч JS ───────────────────────────────────
patch_js() {
  local js="$1"
  python3 - "$js" <<'PYEOF'
import sys, re
with open(sys.argv[1], 'r') as f:
    c = f.read()
if 'const p=()=>null' in c:
    print("already")
    sys.exit(0)
if 'void 0' in c and 'showModal("lunar-modal")' not in c:
    # Могли пропатчить брутфорсом в прошлый раз
    print("already")
    sys.exit(0)
if 'showModal("lunar-modal")' not in c:
    print("nope")
    sys.exit(1)

# Strategy 1: exact match
old = (
    'const p=()=>{const e=(0,a.useDispatch)();return(0,o.useEffect)((()=>{'
    'window.electronMode&&window.electronAppOrUpdater&&"app"===window.electronAppOrUpdater'
    '&&e(s.modalModule.showModal("lunar-modal"))'
    '}),[]),'
    'o.createElement(i.DarkModal,{name:"lunar-modal",maxWidth:i.v.breakpoints.md,noClose:!0},'
    'o.createElement(i.DarkModalTitle,null,l.A.t("Badlion Launcher Is Being Discontinued")),'
    'o.createElement(i.DarkModalContent,null,'
    'o.createElement(i.Block,{p:"lg"},'
    'o.createElement(i.Flex,{justifyContent:"center",flexColumn:!0},'
    'o.createElement(i.P,{textAlign:"center"},l.A.t("The Badlion Client launcher is now discontinued.")),'
    'o.createElement(i.P,{textAlign:"center"},l.A.t("To continue playing Badlion Client without interruption, please switch to the Lunar Client Launcher.")),'
    'o.createElement(i.P,{textAlign:"center"},l.A.t("A short video below shows exactly how to do this. It only takes a few clicks."))),'
    'o.createElement(i.Flex,{mt:"sm",justifyContent:"center"},'
    'o.createElement(i.Image,{src:c,alt:l.A.t("Badlion Launch through Lunar"),$overload:{width:"400px",height:"250px"}})),'
    'o.createElement(i.Flex,{mt:"sm",justifyContent:"center"},'
    'o.createElement(u.$n,{mt:"lg",theme:"yellow",px:"lg",py:"md",rounded:!0,fontWeight:"semibold",type:"submit",display:"block",to:"https://www.lunarclient.com/download"},l.A.t("Download"))))))};'
)
if old in c:
    c = c.replace(old, 'const p=()=>null;')
    with open(sys.argv[1], 'w') as f: f.write(c)
    print("exact"); sys.exit(0)

# Strategy 2: regex
pat = r'const p=\(\)=>\{const \w+=\(0,\w+\.useDispatch\)\(\);return\(0,\w+\.useEffect\)\(\(\(\)=>\{.*?showModal\("lunar-modal"\).*?\}\),\[\]\),.*?createElement\(i\.DarkModal,\{name:"lunar-modal".*?\}\)\};'
m = re.search(pat, c, re.DOTALL)
if m:
    c = c[:m.start()] + 'const p=()=>null;' + c[m.end():]
    with open(sys.argv[1], 'w') as f: f.write(c)
    print("regex"); sys.exit(0)

# Strategy 3: brute force
c = c.replace('&&e(s.modalModule.showModal("lunar-modal"))', '&&void 0')
c = c.replace(',o.createElement(i.DarkModal,{name:"lunar-modal",maxWidth:i.v.breakpoints.md,noClose:!0},o.createElement(i.DarkModalTitle,null,l.A.t("Badlion Launcher Is Being Discontinued")),o.createElement(i.DarkModalContent,null,o.createElement(i.Block,{p:"lg"},', ',null')
with open(sys.argv[1], 'w') as f: f.write(c)
print("brute")
PYEOF
  return $?
}

# ── Главная логика ────────────────────────────
patch_appimage() {
  local path="$1"
  local out; out="$(dirname "$path")/$(basename "$path" .AppImage)-patched.AppImage"
  local tmp; tmp="$(mktemp -d -t badlion-XXXXXX)"
  local sq="$tmp/squashfs-root"
  local asar_dir="$tmp/asar-extract"

  trap "rm -rf $tmp" EXIT

  info "$(t 'Extracting AppImage...' 'Распаковка AppImage...')"
  cd "$tmp"

  # Убедимся что файл исполняемый
  [ -x "$path" ] || chmod +x "$path" 2>/dev/null || true

  # Способ 1: --appimage-extract
  if "$path" --appimage-extract >/dev/null 2>&1; then
    [ -d squashfs-root ] && sq="$PWD/squashfs-root"
  else
    # Способ 2: unsquashfs с авто-поиском оффсета
    local offset
    offset=$(python3 -c "
import struct
with open('$path', 'rb') as f:
    f.seek(8)
    magic = f.read(2)
    if magic == b'AI':  # AppImage Type 2
        print(struct.unpack('<I', f.read(4))[0])
    else:  # AppImage Type 1 — ищем в конце файла
        f.seek(-24, 2)
        print(struct.unpack('<Q', f.read(8))[0])
" 2>/dev/null || echo "0")

    [ "$offset" -le 8 ] && offset=0
    unsquashfs -o "$offset" -d "$sq" "$path" >/dev/null 2>&1 || {
      # Способ 3: перебором оффсетов
      local found=0
      for off in 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072; do
        if unsquashfs -o "$off" -d "$sq" "$path" >/dev/null 2>&1; then
          found=1; break
        fi
      done
      [ "$found" -eq 0 ] && { fail "$(t 'Cannot extract AppImage. Try: chmod +x and FUSE' 'Не могу распаковать. Попробуй: chmod +x')"; exit 1; }
    }
  fi
  [ -f "$sq/AppRun" ] || { fail "$(t 'Not a valid AppImage' 'Не похоже на AppImage')"; exit 1; }
  ok "$(t 'Extracted' 'Распаковано')"

  [ -f "$sq/resources/app.asar" ] || { fail "$(t 'app.asar not found' 'app.asar не найден')"; exit 1; }
  info "$(t 'Extracting app.asar...' 'Распаковка app.asar...')"
  mkdir -p "$asar_dir"
  asar extract "$sq/resources/app.asar" "$asar_dir/" && ok "app.asar"

  local js
  for f in "$asar_dir"/app/static/js/main.*.js; do [ -f "$f" ] && js="$f" && break; done
  [ -z "$js" ] && { fail "$(t 'JS bundle not found' 'JS не найден')"; exit 1; }

  info "$(t 'Patching...' 'Патчинг...')"
  local r; r=$(patch_js "$js" 2>&1)
  case "$r" in
    already) warn "$(t 'Already patched!' 'Уже пропатчено!')" ;;
    exact|regex|brute) ok "$(t 'Patched!' 'Пропатчено!')" ;;
    nope) warn "$(t 'lunar-modal not found' 'lunar-modal не найден')"
          echo -n "  $(t 'Continue? [Y/n]: ' 'Продолжить? [Д/n]: ')"; read -r a
          [[ "$a" =~ ^[nN] ]] && exit 1 ;;
    *) fail "$(t 'Patch failed' 'Патч не сработал')"; exit 1 ;;
  esac

  # Чистка промо-ссылок
  python3 - "$js" <<'PYEOF'
import sys
with open(sys.argv[1], 'r') as f:
    c = f.read()
for o, n in [('lunarclient.com/download','badlion.net/download'),('lunarclient.com/terms','badlion.net/terms'),('lunarclient.com/privacy','badlion.net/privacy')]:
    c = c.replace(o, n)
with open(sys.argv[1], 'w') as f: f.write(c)
PYEOF

  # Блокировка серверных запросов — меняем URL апдейтера на заглушку
  if [ -f "$sq/resources/app-update.yml" ]; then
    local update_url
    update_url=$(grep "^url:" "$sq/resources/app-update.yml" | head -1 | awk '{print $2}')
    if [ -n "$update_url" ] && [ "$update_url" != "https://example.com/" ]; then
      sed -i "s|url:.*|url: https://example.com/|" "$sq/resources/app-update.yml"
      ok "$(t 'Update URL blocked' 'URL апдейтера заблокирован'): $update_url → https://example.com/"
    else
      ok "$(t 'Update URL already blocked' 'URL уже заблокирован')"
    fi
  fi

  info "$(t 'Repacking...' 'Упаковка...')"
  asar pack "$asar_dir/" "$sq/resources/app.asar"
  rm -f "$out"

  # Пробуем appimagetool, если нет — mksquashfs + runtime вручную
  if "$APPIMAGETOOL" --comp xz "$sq/" "$out" 2>/dev/null; then
    chmod +x "$out"
  else
    # Ручная сборка: mksquashfs + загрузка runtime
    warn "$(t 'appimagetool failed, trying manual method...' 'appimagetool упал, пробую вручную...')"
    mksquashfs "$sq/" "$tmp/badlion.squashfs" -comp xz -noappend 2>&1 || { fail "$(t 'mksquashfs failed' 'mksquashfs не сработал')"; exit 1; }
    # Скачиваем runtime если нет
    if [ ! -f "$tmp/runtime" ]; then
      curl -sL -o "$tmp/runtime" "https://github.com/AppImage/AppImageKit/releases/download/continuous/runtime-x86_64" 2>&1 || {
        fail "$(t 'Cannot download runtime' 'Не могу скачать runtime')"; exit 1;
      }
    fi
    cat "$tmp/runtime" "$tmp/badlion.squashfs" > "$out"
    chmod +x "$out"
  fi

  echo
  echo -e "  ${G}${B}✅ $(t 'Done!' 'Готово!')${N}"
  echo "  ${B}$out${N}"
  echo
}

# ── Меню ──────────────────────────────────────
while true; do
  menu
  read -r c
  case "$c" in
    1)
      echo
      echo -n "  $(t 'Path to AppImage:' 'Путь к AppImage:') "
      read -r p
      p="${p/#\~/$HOME}"; p="${p%\"}"; p="${p#\"}"; p="${p%\'}"; p="${p#\'}"
      [ ! -f "$p" ] && { warn "$(t 'File not found' 'Файл не найден')"; sleep 1; continue; }
      patch_appimage "$p"
      echo -n "  $(t 'Press Enter' 'Нажми Enter') "; read -r _
      ;;
    2) [ "$L" = ru ] && L=en || L=ru ;;
    3) echo; echo "  bye 👋"; echo; exit 0 ;;
  esac
done
