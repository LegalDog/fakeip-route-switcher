#!/system/bin/sh
# customize.sh - Magisk/KernelSU/SukiSU 模块安装脚本
# 安装时写入默认配置（非交互式，避免音量键检测在部分设备上失效）

MODDIR="/data/adb/modules/fakeip-route-switcher"
CONF_FILE="$MODDIR/config.env"
FALLBACK_CONF="/data/local/tmp/fakeip_config.env"

# 默认配置（可通过 WebUI 或 fakeip-cfg 修改）
DEFAULT_SSID="云海天涯两杳茫"
DEFAULT_GW="192.168.31.39"
DEFAULT_ROUTE="28.0.0.0/8"
DEFAULT_IFACE="wlan0"

mkdir -p "$MODDIR"

# 单行 printf 写入，确保与 ksu.exec 兼容
printf 'TARGET_SSID_RAW="%s"\nNEXT_HOP_GATEWAY="%s"\nTARGET_ROUTE="%s"\nINTERFACE="%s"\nCHECK_INTERVAL=3\n' \
    "$DEFAULT_SSID" "$DEFAULT_GW" "$DEFAULT_ROUTE" "$DEFAULT_IFACE" > "$CONF_FILE"
chmod 644 "$CONF_FILE"

printf 'TARGET_SSID_RAW="%s"\nNEXT_HOP_GATEWAY="%s"\nTARGET_ROUTE="%s"\nINTERFACE="%s"\nCHECK_INTERVAL=3\n' \
    "$DEFAULT_SSID" "$DEFAULT_GW" "$DEFAULT_ROUTE" "$DEFAULT_IFACE" > "$FALLBACK_CONF"
chmod 644 "$FALLBACK_CONF"

ui_print "- FakeIP Route Switcher 安装完成"
ui_print "- 默认 SSID: $DEFAULT_SSID"
ui_print "- 默认网关: $DEFAULT_GW"
ui_print "- 请通过 SukiSU WebUI 或 fakeip-cfg 命令修改配置"
