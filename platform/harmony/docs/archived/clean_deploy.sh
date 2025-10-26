#!/bin/bash
# HarmonyOS 完全清理并重新部署脚本
# 确保设备使用最新的.so文件

set -e  # 遇到错误立即退出

echo ""
echo "=========================================="
echo "🧹 HarmonyOS 完全清理并重新部署"
echo "=========================================="
echo ""

# 步骤1: 卸载APP
echo "📱 [1/7] 卸载设备上的APP..."
echo "   执行: hdc shell bm uninstall -n org.maplibre.harmony"
hdc shell bm uninstall -n org.maplibre.harmony 2>&1 || echo "   (APP可能已经不存在)"
echo "   等待2秒让系统完成清理..."
sleep 2
echo "   ✅ 完成"
echo ""

# 步骤2: 验证APP已删除
echo "🔍 [2/7] 验证APP已完全删除..."
if hdc shell bm dump -n org.maplibre.harmony 2>&1 | grep -q "not exist\|bundle not exist"; then
    echo "   ✅ APP已完全删除"
else
    echo "   ⚠️ APP可能仍然存在"
    echo "   设备上的APP信息:"
    hdc shell bm dump -n org.maplibre.harmony 2>&1 | head -5
fi
echo ""

# 步骤3: 清理本地构建缓存
echo "🧹 [3/7] 清理本地构建缓存..."
cd /Users/yidafu/github/maplibre-native/platform/harmony

# 列出要删除的目录
echo "   准备删除以下目录:"
[ -d ".cxx" ] && echo "   - .cxx"
[ -d "maplibre_harmony/.cxx" ] && echo "   - maplibre_harmony/.cxx"
[ -d "maplibre_harmony/build" ] && echo "   - maplibre_harmony/build"

# 执行删除
rm -rf .cxx
rm -rf maplibre_harmony/.cxx  
rm -rf maplibre_harmony/build
echo "   ✅ 缓存已清理"
echo ""

# 步骤4: 重新编译
echo "🔨 [4/7] 重新编译（这可能需要10-15秒）..."
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node

/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=maplibre_harmony@default \
  -p product=default -p requiredDeviceType=phone \
  assembleHap --no-daemon 2>&1 | grep -E "BUILD|Finished.*assembleHap"

if [ $? -eq 0 ]; then
    echo "   ✅ 编译成功"
else
    echo "   ❌ 编译失败"
    exit 1
fi
echo ""

# 步骤5: 验证.so内容
echo "🔍 [5/7] 验证新.so包含增强日志..."
SO_PATH="maplibre_harmony/build/default/intermediates/libs/default/arm64-v8a/libmaplibre_native.so"

if [ -f "$SO_PATH" ]; then
    SO_SIZE=$(ls -lh "$SO_PATH" | awk '{print $5}')
    SO_TIME=$(ls -l "$SO_PATH" | awk '{print $6, $7, $8}')
    echo "   .so文件: $SO_SIZE (编译于 $SO_TIME)"
    
    # 检查关键字符串
    if strings "$SO_PATH" | grep -q "Step 3/5: Creating CURLEventLoop"; then
        echo "   ✅ 包含增强日志: 'Step 3/5: Creating CURLEventLoop'"
    else
        echo "   ❌ 警告：未找到增强日志字符串"
        exit 1
    fi
    
    if strings "$SO_PATH" | grep -q "HTTP_CRITICAL"; then
        echo "   ✅ 包含关键日志: 'HTTP_CRITICAL'"
    else
        echo "   ⚠️ 未找到HTTP_CRITICAL tag"
    fi
else
    echo "   ❌ .so文件不存在: $SO_PATH"
    exit 1
fi
echo ""

# 步骤6: 安装新HAP
echo "📦 [6/7] 安装新版本到设备..."
HAP_PATH="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"

if [ -f "$HAP_PATH" ]; then
    HAP_SIZE=$(ls -lh "$HAP_PATH" | awk '{print $5}')
    HAP_TIME=$(ls -l "$HAP_PATH" | awk '{print $6, $7, $8}')
    echo "   HAP文件: $HAP_SIZE (打包于 $HAP_TIME)"
    
    echo "   执行: hdc install $HAP_PATH"
    hdc install "$HAP_PATH"
    
    echo "   ✅ 安装完成"
else
    echo "   ❌ HAP文件不存在: $HAP_PATH"
    exit 1
fi
echo ""

# 步骤7: 验证安装并准备测试
echo "✅ [7/7] 验证安装..."
if hdc shell bm dump -n org.maplibre.harmony 2>&1 | grep -q "org.maplibre.harmony"; then
    echo "   ✅ APP已成功安装到设备"
    
    # 获取APP信息
    echo ""
    echo "   APP信息:"
    hdc shell bm dump -n org.maplibre.harmony 2>&1 | grep -E "bundleName|versionName|versionCode|installTime" | head -4
else
    echo "   ❌ APP安装验证失败"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 部署完成！"
echo "=========================================="
echo ""
echo "📋 下一步操作:"
echo ""
echo "1️⃣ 清除历史日志:"
echo "   hdc hilog -r"
echo ""
echo "2️⃣ 启动设备上的MapLibre APP"
echo ""
echo "3️⃣ 查看增强日志:"
echo "   hdc hilog | grep -E 'HTTP_CRITICAL|Step 3/5|Step 1/5'"
echo ""
echo "🔍 预期看到以下日志:"
echo "   HTTP_CRITICAL: HTTPFileSource::Impl CONSTRUCTOR START"
echo "   CURLEventLoop: Step 1/5: CURL global init SUCCESS"
echo "   CURLEventLoop: Step 3/5: Creating CURLEventLoop..."
echo "   HTTP_CRITICAL: HTTPFileSource::Impl CONSTRUCTOR COMPLETE"
echo ""
echo "❌ 如果仍然看不到增强日志，说明需要进一步排查"
echo ""

