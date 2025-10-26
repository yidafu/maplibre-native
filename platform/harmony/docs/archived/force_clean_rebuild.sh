#!/bin/bash
# HarmonyOS 强制清理并重新编译脚本
# 解决HAP打包缓存问题

set -e  # 遇到错误立即退出

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "=========================================="
echo "🧹 HarmonyOS 强制清理并重新编译"
echo "=========================================="
echo ""
echo "📍 当前目录: $SCRIPT_DIR"
echo ""

# 步骤1: 清理所有本地构建缓存
echo "🧹 [1/6] 清理所有本地构建缓存..."
echo ""

# 项目级缓存
echo "   清理项目缓存:"
[ -d ".cxx" ] && echo "   - 删除 .cxx" && rm -rf .cxx
[ -d ".hvigor" ] && echo "   - 删除 .hvigor" && rm -rf .hvigor
[ -d "build-harmony" ] && echo "   - 删除 build-harmony" && rm -rf build-harmony

# 模块级缓存
echo ""
echo "   清理模块缓存:"
[ -d "maplibre_harmony/.cxx" ] && echo "   - 删除 maplibre_harmony/.cxx" && rm -rf maplibre_harmony/.cxx
[ -d "maplibre_harmony/.hvigor" ] && echo "   - 删除 maplibre_harmony/.hvigor" && rm -rf maplibre_harmony/.hvigor
[ -d "maplibre_harmony/build" ] && echo "   - 删除 maplibre_harmony/build" && rm -rf maplibre_harmony/build

# oh_modules缓存
[ -d "maplibre_harmony/oh_modules" ] && echo "   - 删除 maplibre_harmony/oh_modules" && rm -rf maplibre_harmony/oh_modules

echo ""
echo "   ✅ 本地缓存已清理"
echo ""

# 步骤2: 清理用户级hvigor缓存
echo "🧹 [2/6] 清理用户级hvigor缓存..."
echo ""

if [ -d "$HOME/.hvigor/cache" ]; then
    echo "   - 删除 ~/.hvigor/cache"
    rm -rf "$HOME/.hvigor/cache"
    echo "   ✅ 用户级hvigor缓存已清理"
else
    echo "   ℹ️  用户级hvigor缓存不存在"
fi
echo ""

# 步骤3: 清理DevEco Studio缓存
echo "🧹 [3/6] 清理DevEco Studio缓存..."
echo ""

DEVECO_CACHE_PATTERN="$HOME/Library/Caches/com.huawei.deveco*"
if ls $DEVECO_CACHE_PATTERN 1> /dev/null 2>&1; then
    echo "   发现DevEco Studio缓存:"
    ls -d $DEVECO_CACHE_PATTERN | while read dir; do
        echo "   - 删除 $(basename $dir)"
        rm -rf "$dir"
    done
    echo "   ✅ DevEco Studio缓存已清理"
else
    echo "   ℹ️  DevEco Studio缓存不存在"
fi
echo ""

# 步骤4: 验证源代码包含增强日志
echo "🔍 [4/6] 验证源代码包含增强日志..."
echo ""

if grep -q "Step 3/5: Creating CURLEventLoop" maplibre_harmony/src/main/cpp/http_file_source_harmony.cpp; then
    echo "   ✅ 源代码包含增强日志标记"
else
    echo "   ❌ 错误: 源代码不包含增强日志！"
    echo "   请确认已修改 http_file_source_harmony.cpp"
    exit 1
fi

if grep -q "HTTP_LOG_CRITICAL" maplibre_harmony/src/main/cpp/http_file_source_harmony.cpp; then
    echo "   ✅ 源代码包含HTTP_LOG_CRITICAL宏"
else
    echo "   ❌ 错误: 源代码不包含HTTP_LOG_CRITICAL宏！"
    exit 1
fi
echo ""

# 步骤5: 重新编译
echo "🔨 [5/6] 重新编译（强制完全重新构建）..."
echo ""

# 设置环境变量
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node

echo "   环境变量:"
echo "   - DEVECO_SDK_HOME=$DEVECO_SDK_HOME"
echo "   - NODE_HOME=$NODE_HOME"
echo ""

# 先执行clean
echo "   执行clean..."
$NODE_HOME/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  clean --no-daemon

echo ""
echo "   执行assembleHap..."

# 执行编译
$NODE_HOME/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=maplibre_harmony@default \
  -p product=default -p requiredDeviceType=phone \
  assembleHap --no-daemon 2>&1 | tee compile_force.log

# 检查编译结果
if grep -q "BUILD SUCCESSFUL" compile_force.log; then
    echo ""
    echo "   ✅ 编译成功"
    COMPILE_TIME=$(grep "BUILD SUCCESSFUL" compile_force.log | sed 's/.*in //')
    echo "   编译耗时: $COMPILE_TIME"
else
    echo ""
    echo "   ❌ 编译失败"
    echo "   请查看 compile_force.log 了解详情"
    exit 1
fi
echo ""

# 步骤6: 验证编译产物
echo "🔍 [6/6] 验证编译产物包含增强日志..."
echo ""

# 检查中间.so
INTERMEDIATE_SO="maplibre_harmony/build/default/intermediates/libs/default/arm64-v8a/libmaplibre_native.so"
if [ -f "$INTERMEDIATE_SO" ]; then
    SO_SIZE=$(ls -lh "$INTERMEDIATE_SO" | awk '{print $5}')
    SO_TIME=$(ls -l "$INTERMEDIATE_SO" | awk '{print $6, $7, $8}')
    echo "   中间产物.so: $SO_SIZE (编译于 $SO_TIME)"
    
    if strings "$INTERMEDIATE_SO" | grep -q "Step 3/5: Creating CURLEventLoop"; then
        echo "   ✅ 中间.so包含: 'Step 3/5: Creating CURLEventLoop'"
    else
        echo "   ❌ 警告: 中间.so不包含增强日志！"
        echo "   可能需要触发强制重新编译"
        exit 1
    fi
    
    if strings "$INTERMEDIATE_SO" | grep -q "HTTP_CRITICAL"; then
        echo "   ✅ 中间.so包含: 'HTTP_CRITICAL'"
    else
        echo "   ❌ 警告: 中间.so不包含HTTP_CRITICAL！"
        exit 1
    fi
else
    echo "   ❌ 中间.so文件不存在: $INTERMEDIATE_SO"
    exit 1
fi

echo ""

# 检查HAP中的.so
HAP_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"
if [ -f "$HAP_FILE" ]; then
    HAP_SIZE=$(ls -lh "$HAP_FILE" | awk '{print $5}')
    HAP_TIME=$(ls -l "$HAP_FILE" | awk '{print $6, $7, $8}')
    echo "   HAP文件: $HAP_SIZE (打包于 $HAP_TIME)"
    
    # 从HAP中提取.so并检查
    if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so | strings | grep -q "Step 3/5: Creating CURLEventLoop"; then
        echo "   ✅ HAP中的.so包含: 'Step 3/5: Creating CURLEventLoop'"
    else
        echo "   ❌ 严重错误: HAP中的.so不包含增强日志！"
        echo "   说明HAP打包时使用了旧的.so文件"
        echo ""
        echo "   调试信息:"
        echo "   - 中间.so有增强日志: 是"
        echo "   - HAP中.so有增强日志: 否"
        echo "   - 结论: HAP打包缓存问题"
        echo ""
        echo "   建议: 手动从中间目录复制.so到HAP"
        exit 1
    fi
    
    if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so | strings | grep -q "HTTP_CRITICAL"; then
        echo "   ✅ HAP中的.so包含: 'HTTP_CRITICAL'"
    else
        echo "   ❌ HAP中的.so不包含HTTP_CRITICAL"
        exit 1
    fi
else
    echo "   ❌ HAP文件不存在: $HAP_FILE"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ 强制重新编译完成！"
echo "=========================================="
echo ""
echo "📊 编译产物验证:"
echo "   ✅ 中间.so包含增强日志"
echo "   ✅ HAP中的.so包含增强日志"
echo "   ✅ 所有验证通过"
echo ""
echo "📱 下一步操作:"
echo ""
echo "1️⃣ 完全卸载设备上的APP:"
echo "   hdc shell bm uninstall -n org.maplibre.harmony"
echo ""
echo "2️⃣ 验证APP已删除:"
echo "   hdc shell bm dump -n org.maplibre.harmony"
echo "   (应该显示: bundle not exist)"
echo ""
echo "3️⃣ 重启设备（清除系统缓存）:"
echo "   hdc shell reboot"
echo ""
echo "4️⃣ 等待设备重启后安装新HAP:"
echo "   hdc install $HAP_FILE"
echo ""
echo "5️⃣ 清除日志并测试:"
echo "   hdc hilog -r"
echo "   # 启动APP"
echo "   hdc hilog | grep -E 'HTTP_CRITICAL|Step 3/5'"
echo ""
echo "🔍 预期看到:"
echo "   HTTP_CRITICAL: HTTPFileSource::Impl CONSTRUCTOR START"
echo "   CURLEventLoop: Step 1/5: CURL global init SUCCESS"
echo "   CURLEventLoop: Step 3/5: Creating CURLEventLoop..."
echo "   HTTP_CRITICAL: HTTPFileSource::Impl CONSTRUCTOR COMPLETE"
echo ""

