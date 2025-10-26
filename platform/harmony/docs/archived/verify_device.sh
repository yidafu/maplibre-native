#!/bin/bash
# HarmonyOS 设备验证脚本
# 验证设备上APP的状态和日志输出

echo ""
echo "=========================================="
echo "📱 HarmonyOS 设备验证"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 步骤1: 检查设备连接
echo "🔌 [1/5] 检查设备连接..."
echo ""

if ! command -v hdc &> /dev/null; then
    echo -e "   ${RED}❌ hdc命令不存在${NC}"
    echo "   请确保DevEco Studio已安装"
    exit 1
fi

if ! hdc list targets 2>/dev/null | grep -q .; then
    echo -e "   ${RED}❌ 未检测到设备${NC}"
    echo "   请连接HarmonyOS设备"
    exit 1
else
    DEVICE_ID=$(hdc list targets | head -1)
    echo -e "   ${GREEN}✅ 设备已连接: $DEVICE_ID${NC}"
fi

echo ""

# 步骤2: 检查APP安装状态
echo "📦 [2/5] 检查APP安装状态..."
echo ""

if hdc shell bm dump -n org.maplibre.harmony 2>&1 | grep -q "not exist\|bundle not exist"; then
    echo -e "   ${YELLOW}⚠️  APP未安装${NC}"
    echo ""
    echo "   请先安装APP:"
    echo "   hdc install maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"
    echo ""
    exit 1
else
    echo -e "   ${GREEN}✅ APP已安装${NC}"
    echo ""
    echo "   APP信息:"
    hdc shell bm dump -n org.maplibre.harmony 2>&1 | grep -E "bundleName|versionName|installTime" | sed 's/^/   /'
fi

echo ""

# 步骤3: 捕获最新日志
echo "📊 [3/5] 捕获设备日志..."
echo ""

echo "   清除历史日志..."
hdc hilog -r > /dev/null 2>&1

echo -e "   ${BLUE}请在设备上启动 MapLibre APP...${NC}"
echo "   等待5秒..."
sleep 5

echo "   捕获日志（10秒）..."
timeout 10 hdc hilog > device_current.log 2>&1 || true

LOG_LINES=$(wc -l < device_current.log)
echo "   ✅ 捕获了 $LOG_LINES 行日志"
echo ""

# 步骤4: 分析日志
echo "🔍 [4/5] 分析捕获的日志..."
echo ""

# 检查关键标记
echo "   检查增强日志标记:"
echo ""

if grep -q "HTTP_CRITICAL" device_current.log; then
    echo -e "   ${GREEN}✅ 找到 HTTP_CRITICAL 标记${NC}"
    HTTP_CRITICAL_COUNT=$(grep -c "HTTP_CRITICAL" device_current.log)
    echo "   出现次数: $HTTP_CRITICAL_COUNT"
    echo ""
    echo "   最近的HTTP_CRITICAL日志:"
    grep "HTTP_CRITICAL" device_current.log | tail -5 | sed 's/^/   /'
else
    echo -e "   ${RED}❌ 未找到 HTTP_CRITICAL 标记${NC}"
    echo -e "   ${RED}   设备上的.so是旧版本！${NC}"
fi

echo ""

if grep -q "Step 3/5: Creating CURLEventLoop" device_current.log; then
    echo -e "   ${GREEN}✅ 找到 'Step 3/5' 标记${NC}"
else
    echo -e "   ${RED}❌ 未找到 'Step 3/5' 标记${NC}"
    echo -e "   ${RED}   设备上的.so是旧版本！${NC}"
fi

echo ""

if grep -q "Step 1/5: CURL global init SUCCESS" device_current.log; then
    echo -e "   ${GREEN}✅ 找到 'Step 1/5' 标记${NC}"
else
    echo -e "   ${RED}❌ 未找到 'Step 1/5' 标记${NC}"
fi

echo ""

# 检查HTTP流程
echo "   检查HTTP请求流程:"
echo ""

if grep -q "OnlineFileSource::request()" device_current.log; then
    echo -e "   ${GREEN}✅ OnlineFileSource::request() 被调用${NC}"
else
    echo -e "   ${YELLOW}⚠️  未检测到 OnlineFileSource::request()${NC}"
fi

if grep -q "About to call httpFileSource.request()" device_current.log; then
    echo -e "   ${GREEN}✅ httpFileSource.request() 被调用${NC}"
else
    echo -e "   ${YELLOW}⚠️  未检测到 httpFileSource.request() 调用${NC}"
fi

if grep -q "CURLEventLoop Constructor" device_current.log; then
    echo -e "   ${GREEN}✅ CURLEventLoop 被创建${NC}"
else
    echo -e "   ${YELLOW}⚠️  未检测到 CURLEventLoop 创建${NC}"
fi

echo ""

# 步骤5: 生成诊断报告
echo "📋 [5/5] 生成诊断报告..."
echo ""

cat > device_verification_report.txt << EOF
========================================
HarmonyOS 设备验证报告
========================================

验证时间: $(date '+%Y-%m-%d %H:%M:%S')
设备ID: $DEVICE_ID
日志行数: $LOG_LINES

========================================
增强日志标记检查
========================================

HTTP_CRITICAL: $(grep -q "HTTP_CRITICAL" device_current.log && echo "✅ 存在" || echo "❌ 不存在")
Step 3/5: $(grep -q "Step 3/5" device_current.log && echo "✅ 存在" || echo "❌ 不存在")
Step 1/5: $(grep -q "Step 1/5" device_current.log && echo "✅ 存在" || echo "❌ 不存在")

========================================
HTTP请求流程检查
========================================

OnlineFileSource::request(): $(grep -q "OnlineFileSource::request()" device_current.log && echo "✅ 调用" || echo "❌ 未调用")
httpFileSource.request(): $(grep -q "About to call httpFileSource.request()" device_current.log && echo "✅ 调用" || echo "❌ 未调用")
CURLEventLoop创建: $(grep -q "CURLEventLoop Constructor" device_current.log && echo "✅ 创建" || echo "❌ 未创建")
HTTPRequest创建: $(grep -q "HTTPRequest.*CONSTRUCTOR" device_current.log && echo "✅ 创建" || echo "❌ 未创建")
handleResult调用: $(grep -q "handleResult" device_current.log && echo "✅ 调用" || echo "❌ 未调用")

========================================
完整日志
========================================

$(cat device_current.log)
EOF

echo "   ✅ 报告已生成: device_verification_report.txt"
echo ""

# 最终判断
echo "=========================================="
echo "🎯 验证结论"
echo "=========================================="
echo ""

if grep -q "HTTP_CRITICAL" device_current.log && grep -q "Step 3/5" device_current.log; then
    echo -e "${GREEN}✅ 设备上运行的是最新版本！${NC}"
    echo ""
    echo "   增强日志正常工作，可以开始调试HTTP流程"
    echo ""
elif grep -q "CURLEventLoop Constructor" device_current.log; then
    echo -e "${RED}❌ 设备上运行的是旧版本！${NC}"
    echo ""
    echo "   检测到CURLEventLoop但没有增强日志标记"
    echo "   说明设备使用了旧的.so文件"
    echo ""
    echo "🔧 解决方案:"
    echo ""
    echo "   1. 完全卸载APP:"
    echo "      hdc shell bm uninstall -n org.maplibre.harmony"
    echo ""
    echo "   2. 重启设备（重要！）:"
    echo "      hdc shell reboot"
    echo ""
    echo "   3. 等待设备重启后重新安装"
    echo ""
else
    echo -e "${YELLOW}⚠️  未检测到HTTP活动${NC}"
    echo ""
    echo "   可能原因:"
    echo "   - APP未完全启动"
    echo "   - Map未初始化"
    echo "   - 样式URL未设置"
    echo ""
fi

echo ""
echo "查看完整报告: cat device_verification_report.txt"
echo "查看原始日志: cat device_current.log"
echo ""

