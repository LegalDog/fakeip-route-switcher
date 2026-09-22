#!/system/bin/sh
# SukiSU / Magisk / KernelSU / APatch 后台常驻服务
# 针对家庭 Wi-Fi 自动注入 28.0.0.0/8 静态路由
# 断开家庭 Wi-Fi 时立即卸载，避免外出时流量死锁

MODDIR="/data/adb/modules/fakeip-route-switcher"
[ ! -d "$MODDIR" ] && MODDIR="/data/adb/modules_update/fakeip-route-switcher"
CONF_FILE="$MODDIR/config.env"
FALLBACK_CONF="/data/local/tmp/fakeip_config.env"
LOG_FILE="/data/local/tmp/fakeip_route.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# 默认内置初始参数
TARGET_SSID_RAW="云海天涯两杳茫"
NEXT_HOP_GATEWAY="192.168.31.39"
TARGET_ROUTE="28.0.0.0/8"
INTERFACE="wlan0"
CHECK_INTERVAL=3

load_config() {
    if [ -f "$CONF_FILE" ]; then
        . "$CONF_FILE"
    elif [ -f "$FALLBACK_CONF" ]; then
        . "$FALLBACK_CONF"
    fi
}

# 等待系统开机及网络子系统完全就绪
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done

log "FakeIP Route Switcher 守护进程启动成功"
ROUTE_MOUNTED=0

is_connected_to_target_wifi() {
    local info=""
    if command -v cmd >/dev/null 2>&1; then
        info=$(cmd wifi status 2>/dev/null | grep -E "Wifi is connected to")
        if echo "$info" | grep -q "\"$TARGET_SSID_RAW\""; then
            return 0
        fi
        if echo "$info" | grep -q "$TARGET_SSID_RAW"; then
            return 0
        fi
    fi

    local dump=""
    dump=$(dumpsys wifi 2>/dev/null | grep -E "mWifiInfo.*SSID" | head -n 2)
    if echo "$dump" | grep -q "\"$TARGET_SSID_RAW\""; then
        return 0
    fi
    if echo "$dump" | grep -q "$TARGET_SSID_RAW"; then
        return 0
    fi

    return 1
}

mount_route() {
    local gw_prefix="${NEXT_HOP_GATEWAY%.*}"
    if ip route show dev "$INTERFACE" 2>/dev/null | grep -q "$gw_prefix"; then
        ip route replace "$TARGET_ROUTE" via "$NEXT_HOP_GATEWAY" dev "$INTERFACE"
        ip route replace "$TARGET_ROUTE" via "$NEXT_HOP_GATEWAY" dev "$INTERFACE" table local 2>/dev/null
        ROUTE_MOUNTED=1
        log "已连上 [$TARGET_SSID_RAW]，成功挂载静态路由: $TARGET_ROUTE via $NEXT_HOP_GATEWAY"
    fi
}

unmount_route() {
    ip route del "$TARGET_ROUTE" dev "$INTERFACE" 2>/dev/null
    ip route del "$TARGET_ROUTE" table local dev "$INTERFACE" 2>/dev/null
    ROUTE_MOUNTED=0
    log "已断开 [$TARGET_SSID_RAW]，已卸载静态路由: $TARGET_ROUTE"
}

# 循环监听守护进程
while true; do
    load_config

    if is_connected_to_target_wifi; then
        if [ $ROUTE_MOUNTED -eq 0 ]; then
            mount_route
        fi
    else
        if [ $ROUTE_MOUNTED -eq 1 ]; then
            unmount_route
        fi
    fi
    sleep "$CHECK_INTERVAL"
done
