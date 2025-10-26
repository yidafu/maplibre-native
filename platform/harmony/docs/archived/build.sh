#!/bin/bash

# MapLibre Harmony 编译脚本
# 修复地图重复渲染问题后的编译脚本

set -e  # 遇到错误立即退出

echo "=========================================="
echo "MapLibre Harmony 编译脚本"
echo "=========================================="
echo ""

# 设置环境变量
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node

echo "✓ 环境变量已设置"
echo "  DEVECO_SDK_HOME: $DEVECO_SDK_HOME"
echo "  NODE_HOME: $NODE_HOME"
echo ""

# 切换到 harmony 平台目录
cd "$(dirname "$0")"
echo "✓ 当前目录: $(pwd)"
echo ""

# 清理之前的构建（可选）
if [ "$1" == "clean" ]; then
    echo "🧹 清理之前的构建..."
    rm -rf maplibre_harmony/build
    rm -rf maplibre_harmony/.hvigor
    echo "✓ 清理完成"
    echo ""
fi

# 执行编译
echo "🔨 开始编译 MapLibre Harmony..."
echo ""

$NODE_HOME/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=maplibre_harmony@default \
  -p product=default -p requiredDeviceType=phone \
  assembleHap --no-daemon

# 检查编译结果
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 编译成功！"
    echo "=========================================="
    echo ""
    echo "修复内容："
    echo "  ✓ 移除了 onDidFinishLoadingMap() 中的重复渲染请求"
    echo "  ✓ 移除了 onDidFinishLoadingStyle() 中的重复渲染请求"
    echo "  ✓ 移除了 onSourceChanged() 中的重复渲染请求"
    echo "  ✓ 添加了 requestRender() 防抖保护"
    echo ""
    echo "HAP 文件位置："
    echo "  maplibre_harmony/build/default/outputs/default/"
    echo ""
    echo "下一步："
    echo "  1. 安装到设备: ./install.sh"
    echo "  2. 查看日志: ./logs.sh"
    echo "  3. 测试清单: cat ../../RENDER_FIX_CHECKLIST.md"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 编译失败"
    echo "=========================================="
    echo ""
    echo "请检查编译错误信息"
    exit 1
fi

