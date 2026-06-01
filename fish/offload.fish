# offload —— go 等开发缓存的条件环境变量
#
# 放到 ~/.config/fish/conf.d/ 下会被 fish 自动加载（或在 config.fish 里 source 本文件）。
# 外接盘在线时把大缓存指向外接盘；盘断开时自动回退本地默认路径，go 命令照常工作、绝不报错。
#
# 可用环境变量 OFFLOAD_EXT_ROOT 覆盖外接盘路径（需与 offload 脚本一致）。

set -l _offload_root (test -n "$OFFLOAD_EXT_ROOT"; and echo $OFFLOAD_EXT_ROOT; or echo /Volumes/Data-External/Offload)
set -l _offload_sentinel $_offload_root/.online

# 二进制始终装本地，保证 PATH 稳定
set -gx GOBIN "$HOME/go/bin"

if test -f $_offload_sentinel
    set -gx GOPATH $_offload_root/dev-cache/go
    set -gx GOMODCACHE $_offload_root/dev-cache/go/pkg/mod
    test -d $GOPATH; or mkdir -p $GOPATH
else
    set -gx GOPATH "$HOME/go"
    set -gx GOMODCACHE "$HOME/go/pkg/mod"
end
