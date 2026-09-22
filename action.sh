#!/system/bin/sh
# action.sh - 当用户在 SukiSU/KernelSU 模块卡片点击操作时触发
# 注意：SukiSU 原生 WebUI 通过 webroot/index.html 提供，此脚本仅为不支持 WebView 的备用兜底

# 调用系统默认浏览器打开本地 WebUI (若存在)
am start -a android.intent.action.VIEW -d "http://127.0.0.1:28080" >/dev/null 2>&1
