#!/bin/bash
# HarmonyOS 增强日志测试脚本
# 日期: 2025-10-21

echo "=========================================="
echo "HarmonyOS 增强日志版本测试"
echo "=========================================="
echo ""

# 步骤1: 卸载旧版本APP
echo "📱 步骤1: 卸载旧版本APP..."
hdc shell bm uninstall -n org.maplibre.harmony
echo "   ✅ 卸载完成"
echo ""

# 步骤2: 安装新版本
echo "📦 步骤2: 安装增强日志版本..."
HAP_PATH="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"
if [ -f "$HAP_PATH" ]; then
    hdc install "$HAP_PATH"
    echo "   ✅ 安装完成"
else
    echo "   ❌ HAP文件不存在: $HAP_PATH"
    exit 1
fi
echo ""

# 步骤3: 清除日志缓冲
echo "🧹 步骤3: 清除历史日志..."
hdc hilog -r
echo "   ✅ 日志已清除"
echo ""

# 步骤4: 提示用户启动APP
echo "=========================================="
echo "📱 请在设备上启动 MapLibre APP"
echo "=========================================="
echo ""
echo "等待5秒后开始捕获日志..."
sleep 5

# 步骤5: 捕获日志
echo ""
echo "=========================================="
echo "📊 开始捕获日志（Ctrl+C停止）"
echo "=========================================="
echo ""
echo "🔍 过滤关键日志（HTTP_CRITICAL和Step标记）："
echo ""

hdc hilog | grep -E "HTTP_CRITICAL|Step [1-5]/[35]:" --line-buffered

