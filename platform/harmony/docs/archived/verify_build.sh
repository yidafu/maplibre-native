#!/bin/bash
# HarmonyOS 编译产物验证脚本
# 验证源代码、.o文件、.so文件、HAP文件中是否包含增强日志

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "=========================================="
echo "🔍 HarmonyOS 编译产物验证"
echo "=========================================="
echo ""

# 验证计数器
PASS=0
FAIL=0
WARN=0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 步骤1: 验证源代码
echo "📝 [1/5] 验证源代码..."
echo ""

SOURCE_FILE="maplibre_harmony/src/main/cpp/http_file_source_harmony.cpp"

if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "   ${RED}❌ 源文件不存在: $SOURCE_FILE${NC}"
    ((FAIL++))
else
    echo "   ✅ 源文件存在"
    
    # 检查关键字符串
    if grep -q "HTTP_LOG_CRITICAL" "$SOURCE_FILE"; then
        echo "   ✅ 包含 HTTP_LOG_CRITICAL 宏定义"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 HTTP_LOG_CRITICAL 宏${NC}"
        ((FAIL++))
    fi
    
    if grep -q 'OH_LOG_Print(LOG_APP, LOG_ERROR, 0xA00000, "CURLEventLoop"' "$SOURCE_FILE"; then
        echo "   ✅ HTTP_LOG 使用 CURLEventLoop tag"
        ((PASS++))
    else
        echo -e "   ${YELLOW}⚠️  HTTP_LOG 未使用 CURLEventLoop tag${NC}"
        ((WARN++))
    fi
    
    if grep -q "Step 3/5: Creating CURLEventLoop" "$SOURCE_FILE"; then
        echo "   ✅ 包含 Step 3/5 日志标记"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 Step 3/5 日志标记${NC}"
        ((FAIL++))
    fi
    
    if grep -q "Step 1/3: Setting up CURL options" "$SOURCE_FILE"; then
        echo "   ✅ 包含 Step 1/3 日志标记"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 Step 1/3 日志标记${NC}"
        ((FAIL++))
    fi
fi

echo ""

# 步骤2: 查找并验证.o文件
echo "🔍 [2/5] 查找并验证.o文件..."
echo ""

O_FILE=$(find maplibre_harmony -name "http_file_source_harmony.cpp.o" 2>/dev/null | head -1)

if [ -z "$O_FILE" ]; then
    echo -e "   ${YELLOW}⚠️  .o文件未找到（可能未编译）${NC}"
    ((WARN++))
else
    O_SIZE=$(ls -lh "$O_FILE" | awk '{print $5}')
    O_TIME=$(ls -l "$O_FILE" | awk '{print $6, $7, $8}')
    echo "   ✅ .o文件: $O_SIZE (编译于 $O_TIME)"
    echo "   路径: $O_FILE"
    ((PASS++))
fi

echo ""

# 步骤3: 验证中间产物.so
echo "🔍 [3/5] 验证中间产物.so..."
echo ""

INTERMEDIATE_SO="maplibre_harmony/build/default/intermediates/libs/default/arm64-v8a/libmaplibre_native.so"

if [ ! -f "$INTERMEDIATE_SO" ]; then
    echo -e "   ${RED}❌ 中间.so文件不存在${NC}"
    echo "   路径: $INTERMEDIATE_SO"
    ((FAIL++))
else
    SO_SIZE=$(ls -lh "$INTERMEDIATE_SO" | awk '{print $5}')
    SO_TIME=$(ls -l "$INTERMEDIATE_SO" | awk '{print $6, $7, $8}')
    echo "   ✅ .so文件: $SO_SIZE (编译于 $SO_TIME)"
    echo "   路径: $INTERMEDIATE_SO"
    echo ""
    
    # 检查HTTPFileSource符号
    if nm -gC "$INTERMEDIATE_SO" 2>/dev/null | grep -q "mbgl::HTTPFileSource::request"; then
        echo "   ✅ 包含 HTTPFileSource::request 符号"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 HTTPFileSource::request 符号${NC}"
        ((FAIL++))
    fi
    
    # 检查增强日志字符串
    echo ""
    echo "   检查增强日志字符串:"
    
    if strings "$INTERMEDIATE_SO" | grep -q "HTTP_CRITICAL"; then
        echo "   ✅ 包含 'HTTP_CRITICAL' 字符串"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 'HTTP_CRITICAL' 字符串${NC}"
        ((FAIL++))
    fi
    
    if strings "$INTERMEDIATE_SO" | grep -q "Step 3/5: Creating CURLEventLoop"; then
        echo "   ✅ 包含 'Step 3/5: Creating CURLEventLoop' 字符串"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 'Step 3/5' 字符串 - .so未重新编译！${NC}"
        ((FAIL++))
    fi
    
    if strings "$INTERMEDIATE_SO" | grep -q "Step 1/3: Setting up CURL options"; then
        echo "   ✅ 包含 'Step 1/3: Setting up CURL options' 字符串"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 'Step 1/3' 字符串${NC}"
        ((FAIL++))
    fi
    
    if strings "$INTERMEDIATE_SO" | grep -q "HTTPFileSource::Impl CONSTRUCTOR START"; then
        echo "   ✅ 包含 'HTTPFileSource::Impl CONSTRUCTOR START' 字符串"
        ((PASS++))
    else
        echo -e "   ${RED}❌ 缺少 Impl CONSTRUCTOR 字符串${NC}"
        ((FAIL++))
    fi
fi

echo ""

# 步骤4: 验证HAP文件
echo "🔍 [4/5] 验证HAP文件..."
echo ""

HAP_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"

if [ ! -f "$HAP_FILE" ]; then
    echo -e "   ${RED}❌ HAP文件不存在${NC}"
    echo "   路径: $HAP_FILE"
    ((FAIL++))
else
    HAP_SIZE=$(ls -lh "$HAP_FILE" | awk '{print $5}')
    HAP_TIME=$(ls -l "$HAP_FILE" | awk '{print $6, $7, $8}')
    echo "   ✅ HAP文件: $HAP_SIZE (打包于 $HAP_TIME)"
    echo "   路径: $HAP_FILE"
    echo ""
    
    # 检查HAP中是否包含.so
    if unzip -l "$HAP_FILE" | grep -q "libs/arm64-v8a/libmaplibre_native.so"; then
        echo "   ✅ HAP包含 libmaplibre_native.so"
        HAP_SO_SIZE=$(unzip -l "$HAP_FILE" | grep "libs/arm64-v8a/libmaplibre_native.so" | awk '{print $1}')
        echo "   .so大小: $HAP_SO_SIZE bytes"
        ((PASS++))
    else
        echo -e "   ${RED}❌ HAP不包含 libmaplibre_native.so${NC}"
        ((FAIL++))
    fi
    
    echo ""
    echo "   从HAP中提取.so并检查增强日志:"
    
    # 提取并检查
    if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so | strings | grep -q "HTTP_CRITICAL"; then
        echo "   ✅ HAP中的.so包含 'HTTP_CRITICAL'"
        ((PASS++))
    else
        echo -e "   ${RED}❌ HAP中的.so缺少 'HTTP_CRITICAL'${NC}"
        echo -e "   ${RED}   严重: HAP打包时使用了旧的.so文件！${NC}"
        ((FAIL++))
    fi
    
    if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so | strings | grep -q "Step 3/5: Creating CURLEventLoop"; then
        echo "   ✅ HAP中的.so包含 'Step 3/5'"
        ((PASS++))
    else
        echo -e "   ${RED}❌ HAP中的.so缺少 'Step 3/5'${NC}"
        echo -e "   ${RED}   严重: HAP打包缓存问题！${NC}"
        ((FAIL++))
    fi
    
    if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so | strings | grep -q "Step 1/3: Setting up CURL options"; then
        echo "   ✅ HAP中的.so包含 'Step 1/3'"
        ((PASS++))
    else
        echo -e "   ${RED}❌ HAP中的.so缺少 'Step 1/3'${NC}"
        ((FAIL++))
    fi
fi

echo ""

# 步骤5: 时间戳一致性检查
echo "🔍 [5/5] 时间戳一致性检查..."
echo ""

if [ -f "$INTERMEDIATE_SO" ] && [ -f "$HAP_FILE" ]; then
    SO_TIMESTAMP=$(stat -f "%m" "$INTERMEDIATE_SO" 2>/dev/null || stat -c "%Y" "$INTERMEDIATE_SO" 2>/dev/null)
    HAP_TIMESTAMP=$(stat -f "%m" "$HAP_FILE" 2>/dev/null || stat -c "%Y" "$HAP_FILE" 2>/dev/null)
    
    echo "   中间.so时间戳: $SO_TIMESTAMP"
    echo "   HAP文件时间戳: $HAP_TIMESTAMP"
    
    if [ "$HAP_TIMESTAMP" -ge "$SO_TIMESTAMP" ]; then
        echo "   ✅ HAP打包时间晚于或等于.so编译时间（正常）"
        ((PASS++))
    else
        echo -e "   ${YELLOW}⚠️  HAP打包时间早于.so编译时间（异常）${NC}"
        ((WARN++))
    fi
fi

echo ""

# 总结报告
echo "=========================================="
echo "📊 验证总结"
echo "=========================================="
echo ""
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${YELLOW}警告: $WARN${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "=========================================="
    echo -e "${GREEN}✅ 所有验证通过！${NC}"
    echo "=========================================="
    echo ""
    echo "📱 可以部署到设备测试了！"
    echo ""
    echo "执行以下命令:"
    echo "  1. hdc shell bm uninstall -n org.maplibre.harmony"
    echo "  2. hdc shell reboot  # 重启设备清除缓存"
    echo "  3. hdc install $HAP_FILE"
    echo "  4. hdc hilog -r && hdc hilog | grep 'HTTP_CRITICAL'"
    echo ""
    exit 0
else
    echo "=========================================="
    echo -e "${RED}❌ 验证失败！${NC}"
    echo "=========================================="
    echo ""
    echo "⚠️  发现 $FAIL 个问题，需要修复后才能部署"
    echo ""
    
    if [ $FAIL -gt 0 ]; then
        echo "🔧 建议操作:"
        echo ""
        echo "如果中间.so包含增强日志，但HAP不包含:"
        echo "  → HAP打包缓存问题"
        echo "  → 运行: ./force_clean_rebuild.sh"
        echo ""
        echo "如果中间.so也不包含增强日志:"
        echo "  → .so未重新编译"
        echo "  → 删除 .cxx 目录后重新编译"
        echo ""
    fi
    exit 1
fi

