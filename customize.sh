#!/sbin/sh
# customize.sh - 纯净一键安装脚本 (零按键烦恼，所有设置交付 WebUI)

SKIPUNZIP=0

ui_print "***************************************************"
ui_print "   FakeIP Route Switcher (Option 121 Polyfill)    "
ui_print "***************************************************"
ui_print ""
ui_print ">> 正在安装模块组件..."

# 预置初始配置（云海天涯两杳茫 + 192.168.31.39）
cat <<EOF > "$MODPATH/config.env"
TARGET_SSID_RAW="云海天涯两杳茫"
TARGET_SSID_HEX="e4ba91e6b5b7e5a4a9e6b6afe4b8a4e69db3e88cab"
NEXT_HOP_GATEWAY="192.168.31.39"
TARGET_ROUTE="28.0.0.0/8"
INTERFACE="wlan0"
CHECK_INTERVAL=3
EOF

chmod 644 "$MODPATH/config.env"
chmod 755 "$MODPATH/service.sh"
chmod 755 "$MODPATH/webserver.sh"
chmod 755 "$MODPATH/fakeip-cfg.sh"

ui_print " [√] 安装完成！"
ui_print ""
ui_print "==================================================="
ui_print " ★ 默认配置: Wi-Fi[云海天涯两杳茫] 网关[192.168.31.39]"
ui_print " ★ 手机重启后，使用任意浏览器打开本地 WebUI 即可修改:"
ui_print "     http://127.0.0.1:28080"
ui_print "   支持一键填入当前Wi-Fi、可视化查看旁路由挂载状态！"
ui_print "==================================================="
ui_print ""
