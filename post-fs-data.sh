#!/system/bin/sh
# post-fs-data.sh: 链接全局 CLI 命令
# 将 fakeip-cfg.sh 软链接到 /system/bin 或通过 alias 提供支持

MODDIR="${0%/*}"

if [ -f "$MODDIR/fakeip-cfg.sh" ]; then
    chmod 755 "$MODDIR/fakeip-cfg.sh"
    # 创建可直接调用的软链接或执行包装
    mkdir -p "$MODDIR/system/bin"
    cp -f "$MODDIR/fakeip-cfg.sh" "$MODDIR/system/bin/fakeip-cfg"
    chmod 755 "$MODDIR/system/bin/fakeip-cfg"
fi
