#!/bin/sh
# offload 安装脚本：把 bin/ 下的命令软链接到 ~/.local/bin，并可选安装 fish 片段。
#
#   ./install.sh            # 安装 offload、disk-maint 到 ~/.local/bin
#   ./install.sh --fish     # 额外把 fish/offload.fish 软链接到 ~/.config/fish/conf.d/
#
# 软链接方式：以后 git pull 更新本仓库即生效，无需重装。

set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
BIN_DST="$HOME/.local/bin"

mkdir -p "$BIN_DST"
for f in offload disk-maint; do
    ln -sf "$SRC/bin/$f" "$BIN_DST/$f"
    chmod +x "$SRC/bin/$f"
    echo "已链接 $BIN_DST/$f -> $SRC/bin/$f"
done

case "${1:-}" in
    --fish)
        CONF_D="$HOME/.config/fish/conf.d"
        mkdir -p "$CONF_D"
        ln -sf "$SRC/fish/offload.fish" "$CONF_D/offload.fish"
        echo "已链接 $CONF_D/offload.fish（重开 fish 生效）"
        ;;
esac

echo ""
echo "完成。确认 ~/.local/bin 在 PATH 中，然后运行: offload help"
echo "外接盘路径默认 /Volumes/Data-External/Offload，可用环境变量 OFFLOAD_EXT_ROOT 覆盖。"
