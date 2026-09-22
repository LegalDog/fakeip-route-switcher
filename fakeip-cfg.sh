#!/system/bin/sh
# fakeip-cfg.sh - FakeIP Route Switcher 配置后端 (供 WebUI / action.sh / CLI 调用)
# 用法:
#   fakeip-cfg set <ssid> <gateway> [route]
#   fakeip-cfg status
#   fakeip-cfg apply

MODDIR="/data/adb/modules/fakeip-route-switcher"
[ ! -d "$MODDIR" ] && MODDIR="/data/adb/modules_update/fakeip-route-switcher"
CONF_FILE="$MODDIR/config.env"
FALLBACK_CONF="/data/local/tmp/fakeip_config.env"

# 默认参数
TARGET_SSID_RAW="云海天涯两杳茫"
NEXT_HOP_GATEWAY="192.168.31.39"
TARGET_ROUTE="28.0.0.0/8"
INTERFACE="wlan0"

if [ -f "$CONF_FILE" ]; then
    . "$CONF_FILE"
elif [ -f "$FALLBACK_CONF" ]; then
    . "$FALLBACK_CONF"
fi

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

ACTION="$1"
shift 2>/dev/null

case "$ACTION" in
    set)
        NEW_SSID="$1"
        NEW_GW="$2"
        NEW_ROUTE="${3:-28.0.0.0/8}"

        if [ -z "$NEW_SSID" ] || [ -z "$NEW_GW" ]; then
            echo "{\"success\":false,\"error\":\"用法: fakeip-cfg set <ssid> <gateway> [route]\"}"
            exit 1
        fi

        mkdir -p "$MODDIR"
        # 单行 printf 写配置，兼容 SukiSU ksu.exec
        printf 'TARGET_SSID_RAW="%s"\nNEXT_HOP_GATEWAY="%s"\nTARGET_ROUTE="%s"\nINTERFACE="%s"\nCHECK_INTERVAL=3\n' \
            "$NEW_SSID" "$NEW_GW" "$NEW_ROUTE" "$INTERFACE" > "$CONF_FILE"
        chmod 644 "$CONF_FILE"

        printf 'TARGET_SSID_RAW="%s"\nNEXT_HOP_GATEWAY="%s"\nTARGET_ROUTE="%s"\nINTERFACE="%s"\nCHECK_INTERVAL=3\n' \
            "$NEW_SSID" "$NEW_GW" "$NEW_ROUTE" "$INTERFACE" > "$FALLBACK_CONF"
        chmod 644 "$FALLBACK_CONF"

        echo "{\"success\":true,\"message\":\"配置已更新\"}"
        ;;

    status)
        CUR_SSID=""
        if command -v cmd >/dev/null 2>&1; then
            CUR_SSID=$(cmd wifi status 2>/dev/null | grep -E "Wifi is connected to" | awk -F'"' '{print $2}')
        fi
        [ -z "$CUR_SSID" ] && CUR_SSID=$(dumpsys wifi 2>/dev/null | grep -E "mWifiInfo.*SSID" | head -n 1 | awk -F'"' '{print $2}')

        IS_MOUNTED="false"
        if ip route show dev "$INTERFACE" 2>/dev/null | grep -q "$TARGET_ROUTE"; then
            IS_MOUNTED="true"
        fi

        echo "{\"current_ssid\":\"$CUR_SSID\",\"is_mounted\":$IS_MOUNTED,\"target_ssid\":\"$TARGET_SSID_RAW\",\"next_hop\":\"$NEXT_HOP_GATEWAY\",\"target_route\":\"$TARGET_ROUTE\"}"
        ;;

    apply)
        if is_connected_to_target_wifi; then
            ip route replace "$TARGET_ROUTE" via "$NEXT_HOP_GATEWAY" dev "$INTERFACE"
            ip route replace "$TARGET_ROUTE" via "$NEXT_HOP_GATEWAY" dev "$INTERFACE" table local 2>/dev/null
            echo "{\"success\":true,\"message\":\"路由已热生效\"}"
        else
            echo "{\"success\":true,\"message\":\"配置已保存（当前未连接目标Wi-Fi，待连接后自动生效）\"}"
        fi
        ;;

    *)
        echo "{\"success\":false,\"error\":\"用法: fakeip-cfg {set <ssid> <gateway> [route]|status|apply}\"}"
        exit 1
        ;;
esac
