#!/bin/sh
# offload 测试套件 —— 纯 POSIX sh，零依赖。
# 用临时目录模拟外接盘（OFFLOAD_EXT_ROOT）和状态目录（OFFLOAD_STATE_DIR），
# 完全隔离，不触碰真实外接盘或迁移清单。
#
# 运行: sh test/run.sh

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OFFLOAD="$ROOT/bin/offload"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

EXT="$TMP/ext/Offload"
export OFFLOAD_EXT_ROOT="$EXT"
export OFFLOAD_STATE_DIR="$TMP/state"
HOME_BAK="$HOME"
export HOME="$TMP/home"          # 让被迁移目录落在隔离的「家」里
mkdir -p "$HOME"

pass=0; fail=0
ok(){ pass=$((pass+1)); printf 'ok   - %s\n' "$1"; }
no(){ fail=$((fail+1)); printf 'FAIL - %s\n' "$1"; }

online(){ mkdir -p "$EXT/archive"; echo "offload-sentinel-v1 do-not-delete" > "$EXT/.online"; }
offline(){ rm -rf "$EXT"; }

# --- 1. 离线时 check 应返回非 0 ---
offline
if "$OFFLOAD" check >/dev/null 2>&1; then no "离线 check 应返回非0"; else ok "离线 check 返回非0"; fi

# --- 2. 在线时 check 应返回 0 ---
online
if "$OFFLOAD" check >/dev/null 2>&1; then ok "在线 check 返回0"; else no "在线 check 应返回0"; fi

# --- 3. move：建软链接 + 保留备份 + 内容正确 ---
D="$HOME/data1"; mkdir -p "$D/sub"; echo hello > "$D/a.txt"; echo world > "$D/sub/b.txt"
"$OFFLOAD" move "$D" >/dev/null 2>&1
[ -L "$D" ] && ok "move 后原位置是软链接" || no "move 后原位置应为软链接"
[ -d "$D.offload_old" ] && ok "move 后保留 .offload_old 备份" || no "move 后应保留备份"
[ -d "$EXT/archive/data1" ] && ok "外接盘有副本" || no "外接盘应有副本"
[ "$(cat "$D/a.txt" 2>/dev/null)" = "hello" ] && ok "经软链接读取内容正确" || no "经软链接内容应正确"

# --- 4. status 输出包含该路径 ---
if "$OFFLOAD" status 2>/dev/null | grep -q "data1"; then ok "status 列出迁移项"; else no "status 应列出迁移项"; fi

# --- 5. commit：删备份，软链接仍在 ---
"$OFFLOAD" commit "$D" >/dev/null 2>&1
[ ! -e "$D.offload_old" ] && ok "commit 后备份已删" || no "commit 后备份应删除"
[ -L "$D" ] && ok "commit 后软链接仍在" || no "commit 后软链接应仍在"

# --- 6. rollback：从外接盘移回（无备份场景）---
"$OFFLOAD" rollback "$D" >/dev/null 2>&1
[ -d "$D" ] && [ ! -L "$D" ] && ok "rollback 后恢复为真实目录" || no "rollback 后应为真实目录"
[ "$(cat "$D/a.txt" 2>/dev/null)" = "hello" ] && ok "rollback 后内容正确" || no "rollback 后内容应正确"
if "$OFFLOAD" status 2>/dev/null | grep -q "data1"; then no "rollback 后清单应已清空"; else ok "rollback 后清单已清空"; fi

# --- 7. 含空格与正则元字符的路径 ---
S="$HOME/my dir (x).v1"; mkdir -p "$S"; echo hi > "$S/f.txt"
"$OFFLOAD" move "$S" >/dev/null 2>&1
[ -L "$S" ] && [ "$(cat "$S/f.txt" 2>/dev/null)" = "hi" ] && ok "特殊字符路径 move 正常" || no "特殊字符路径 move 应正常"
"$OFFLOAD" rollback "$S" >/dev/null 2>&1
[ -d "$S" ] && [ ! -L "$S" ] && ok "特殊字符路径 rollback 正常" || no "特殊字符路径 rollback 应正常"

# --- 8. 离线时 move 应被拒绝 ---
offline
D2="$HOME/data2"; mkdir -p "$D2"; echo x > "$D2/c.txt"
if "$OFFLOAD" move "$D2" >/dev/null 2>&1; then no "离线 move 应被拒绝"; else ok "离线 move 被拒绝"; fi
[ -d "$D2" ] && [ ! -L "$D2" ] && ok "离线 move 后原目录原封不动" || no "离线 move 不应破坏原目录"

export HOME="$HOME_BAK"
printf '\n通过 %d，失败 %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
