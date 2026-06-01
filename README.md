# offload

把占空间的目录安全迁移到外接盘，并带**断连保护**——外接盘拔掉也不会让系统崩溃。

为系统盘吃紧的 Mac 设计（典型场景：256G 系统盘 + 大容量外接盘）。

## 它解决什么问题

- 系统盘满了，但有些大目录（如 Xcode `iOS DeviceSupport`、go 模块缓存）平时不常访问。
- 想搬到外接盘省空间，又怕：① 搬移过程出错丢数据；② 外接盘断开后软链接悬空导致 app 崩溃或工具报错。

`offload` 用三层设计解决：

1. **迁移有备份**：`move` 先用 macOS 原生 `ditto` 拷贝 → 校验文件数与字节数 → 把原目录改名为 `.offload_old` 备份 → 才建软链接。确认无误后 `commit` 才删备份；出问题随时 `rollback`。
2. **在线哨兵**：靠外接盘上的 `.online` 文件判断盘是否真挂载（盘断开时整个挂载点消失，检测可靠）。
3. **断连不崩溃**：软链接在盘断开时只会“悬空”，访问报 `No such file`，不会让系统崩溃。开发缓存（`GOPATH`）则用 fish 条件环境变量，盘一断**自动回退本地**，`go` 命令照常工作。

## 安装

```bash
git clone <your-repo-url> ~/workspace/offload
cd ~/workspace/offload
./install.sh          # 软链接 offload、disk-maint 到 ~/.local/bin
./install.sh --fish   # 额外安装 go 缓存的 fish 条件变量片段
```

确认 `~/.local/bin` 在 `PATH` 中。外接盘路径默认 `/Volumes/Data-External/Offload`，可用环境变量 `OFFLOAD_EXT_ROOT` 覆盖。

首次使用前，在外接盘建好目录与哨兵：

```bash
mkdir -p /Volumes/你的盘/Offload/archive
echo "offload-sentinel-v1 do-not-delete" > /Volumes/你的盘/Offload/.online
```

## 用法

```bash
offload check              # 外接盘是否在线（退出码 0=在线 1=离线）
offload move <目录>        # 迁移目录到外接盘并建软链接（保留备份，不立即删）
offload commit <目录|all>  # 确认无误后删除 .offload_old 备份，真正释放空间
offload rollback <目录>    # 回滚：删软链接、恢复原目录
offload status             # 列出所有迁移项及健康状态
offload doctor             # 检查悬空/异常链接
```

配套的 `disk-maint` 清理可再生缓存（Homebrew / Xcode DerivedData / go-build / pip 等），默认只预览不删：

```bash
disk-maint          # 预览要清理什么 + 磁盘空间 + 迁移状态
disk-maint --yes    # 真正执行清理
```

## 适合 / 不适合迁移什么

- ✅ **适合**：大、且只在偶尔访问的可再生或归档数据（Xcode `iOS DeviceSupport`、模块缓存、旧项目、归档媒体）。
- ❌ **不适合**：持续读写的活跃 app 数据（浏览器 profile、聊天软件容器、笔记 app 数据）——断连中途易损坏甚至崩溃。这类请用 app 自带的清缓存功能处理。

## 注意

- 迁移不可再生数据务必走 `offload move`（有备份），不要手写 `rm` 绕过。
- 本工具在 macOS（APFS 外接盘）上开发测试。脚本为 POSIX sh，fish 片段仅用于 go 缓存条件变量。

## License

MIT
