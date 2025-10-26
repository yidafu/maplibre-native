#!/bin/bash

# MapLibre Harmony 安装脚本

set -e

echo "=========================================="
echo "MapLibre Harmony 安装脚本"
echo "=========================================="
echo ""

# 查找 HAP 文件
HAP_FILE=$(find maplibre_harmony/build -name "*.hap" -type f 2>/dev/null | head -1)

if [ -z "$HAP_FILE" ]; then
    echo "❌ 错误: 未找到 HAP 文件"
    echo "请先运行 ./build.sh 编译项目"
    exit 1
fi

echo "找到 HAP 文件: $HAP_FILE"
echo ""

# 检查设备连接
echo "检查设备连接..."
hdc list targets

if [ $? -ne 0 ]; then
    echo "❌ 错误: 未检测到设备"
    echo "请确保设备已连接并启用USB调试"
    exit 1
fi

echo ""
echo "🚀 开始安装..."

# 卸载旧版本（如果存在）
echo "卸载旧版本（如果存在）..."
hdc uninstall org.maplibre.harmony 2>/dev/null || true

# 安装新版本
echo "安装新版本..."
hdc install "$HAP_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 安装成功！"
    echo "=========================================="
    echo ""
    echo "下一步："
    echo "  1. 在设备上启动应用"
    echo "  2. 运行 ./logs.sh 查看实时日志"
    echo "  3. 参考 ../../RENDER_FIX_CHECKLIST.md 进行测试"
    echo ""
else
    echo ""
    echo "❌ 安装失败"
    exit 1
fi

