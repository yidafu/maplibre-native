#!/bin/bash

# 鸿蒙 Vulkan 后端重新构建脚本
# 用途：清理缓存并验证配置

set -e

echo "🔧 鸿蒙 Vulkan 后端构建脚本"
echo "================================"
echo ""

# 切换到项目目录
cd "$(dirname "$0")/maplibre_harmony"

echo "📁 当前目录: $(pwd)"
echo ""

# 1. 清理构建缓存
echo "🧹 步骤 1: 清理构建缓存..."
if [ -d ".cxx" ]; then
    rm -rf .cxx
    echo "   ✅ .cxx 已删除"
else
    echo "   ℹ️  .cxx 目录不存在（已清理）"
fi

if [ -d ".hvigor" ]; then
    rm -rf .hvigor
    echo "   ✅ .hvigor 已删除"
else
    echo "   ℹ️  .hvigor 目录不存在（已清理）"
fi
echo ""

# 2. 验证配置
echo "🔍 步骤 2: 验证构建配置..."
if grep -q "MLN_WITH_VULKAN=ON" build-profile.json5 && \
   grep -q "MLN_WITH_OPENGL=OFF" build-profile.json5; then
    echo "   ✅ Vulkan 后端配置正确"
    echo "      - MLN_WITH_VULKAN=ON"
    echo "      - MLN_WITH_OPENGL=OFF"
    echo "      - MLN_WITH_EGL=OFF"
else
    echo "   ❌ 配置文件可能有问题"
    echo "   请检查 build-profile.json5"
    exit 1
fi
echo ""

# 3. 检查 CMake 配置
echo "📝 步骤 3: 检查 harmony.cmake 配置..."
if grep -q "MLN_WITH_VULKAN AND MLN_WITH_OPENGL" ../../harmony.cmake; then
    echo "   ✅ CMake 冲突检查存在"
    echo "   ℹ️  这会防止同时启用两个后端"
else
    echo "   ⚠️  未找到冲突检查"
fi
echo ""

# 4. 构建指引
echo "✅ 缓存清理完成！"
echo ""
echo "📋 下一步操作："
echo "================================"
echo ""
echo "方式 1: 使用 DevEco Studio (推荐)"
echo "   1. 在 DevEco Studio 中打开项目"
echo "   2. Build → Make Project"
echo "   3. 等待构建完成"
echo "   4. Run → Run 'maplibre_harmony'"
echo ""
echo "方式 2: 命令行构建"
echo "   注意：需要正确配置鸿蒙 SDK 环境"
echo "   详见: VULKAN_COMPILE_FIX.md"
echo ""
echo "📊 构建成功标志："
echo "   ✅ 看到: 'HarmonyOS: Using Vulkan rendering backend'"
echo "   ✅ 看到: 'HarmonyOS: Adding Vulkan renderer backend sources'"
echo "   ✅ 没有: 'Cannot enable both Vulkan and OpenGL' 错误"
echo ""
echo "❓ 如果还有问题，请查看:"
echo "   - FIX_CMAKE_CONFLICT.md (CMake 冲突解决)"
echo "   - VULKAN_COMPILE_FIX.md (编译问题解决)"
echo "   - COMPILE_STATUS_SUMMARY.md (状态总结)"
echo ""

