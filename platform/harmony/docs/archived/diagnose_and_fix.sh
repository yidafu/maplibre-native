#!/bin/bash
# HarmonyOS 完整诊断和修复脚本
# 自动诊断问题并提供修复建议

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo ""
echo "=========================================="
echo "🔍 HarmonyOS 黑屏问题诊断工具"
echo "=========================================="
echo ""
echo "此工具将诊断编译产物和设备状态"
echo "并提供针对性的修复建议"
echo ""

# 阶段1: 验证编译产物
echo -e "${CYAN}=========================================="
echo "阶段1: 验证编译产物"
echo -e "==========================================${NC}"
echo ""

./verify_build.sh

BUILD_VERIFY=$?

if [ $BUILD_VERIFY -eq 0 ]; then
    echo -e "${GREEN}✅ 编译产物验证通过${NC}"
    BUILD_OK=true
else
    echo -e "${RED}❌ 编译产物验证失败${NC}"
    BUILD_OK=false
fi

echo ""
echo "按Enter继续..."
read

# 阶段2: 验证设备状态
echo ""
echo -e "${CYAN}=========================================="
echo "阶段2: 验证设备状态"
echo -e "==========================================${NC}"
echo ""

if [ "$BUILD_OK" = false ]; then
    echo -e "${YELLOW}⚠️  跳过设备验证（编译产物未通过）${NC}"
    echo ""
    echo "请先修复编译问题，运行:"
    echo "  ./force_clean_rebuild.sh"
    echo ""
    exit 1
fi

./verify_device.sh

DEVICE_VERIFY=$?

echo ""

# 阶段3: 综合诊断
echo ""
echo -e "${CYAN}=========================================="
echo "阶段3: 综合诊断和建议"
echo -e "==========================================${NC}"
echo ""

if [ $BUILD_VERIFY -eq 0 ] && [ $DEVICE_VERIFY -eq 0 ]; then
    # 完美情况
    echo -e "${GREEN}🎉 完美！所有验证通过！${NC}"
    echo ""
    echo "✅ 编译产物包含增强日志"
    echo "✅ 设备上运行的是最新版本"
    echo "✅ 可以开始调试HTTP流程"
    echo ""
    
elif [ $BUILD_VERIFY -eq 0 ] && [ $DEVICE_VERIFY -ne 0 ]; then
    # 编译OK，但设备版本旧
    echo -e "${YELLOW}⚠️  诊断结果: 设备版本不匹配${NC}"
    echo ""
    echo "✅ 编译产物正确（包含增强日志）"
    echo "❌ 设备上运行的是旧版本"
    echo ""
    echo -e "${BLUE}🔧 修复步骤:${NC}"
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
    echo "4️⃣ 等待设备重启（约1-2分钟）"
    echo ""
    echo "5️⃣ 重新安装HAP:"
    echo "   hdc install maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"
    echo ""
    echo "6️⃣ 重新运行此诊断脚本:"
    echo "   ./diagnose_and_fix.sh"
    echo ""
    
elif [ $BUILD_VERIFY -ne 0 ]; then
    # 编译产物有问题
    echo -e "${RED}❌ 诊断结果: 编译产物问题${NC}"
    echo ""
    echo "❌ 编译产物不包含增强日志"
    echo ""
    
    # 检查具体原因
    INTERMEDIATE_SO="maplibre_harmony/build/default/intermediates/libs/default/arm64-v8a/libmaplibre_native.so"
    HAP_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"
    
    HAS_INTERMEDIATE=false
    HAS_HAP=false
    INTERMEDIATE_HAS_LOG=false
    HAP_HAS_LOG=false
    
    if [ -f "$INTERMEDIATE_SO" ]; then
        HAS_INTERMEDIATE=true
        if strings "$INTERMEDIATE_SO" | grep -q "Step 3/5"; then
            INTERMEDIATE_HAS_LOG=true
        fi
    fi
    
    if [ -f "$HAP_FILE" ]; then
        HAS_HAP=true
        if unzip -p "$HAP_FILE" libs/arm64-v8a/libmaplibre_native.so 2>/dev/null | strings | grep -q "Step 3/5"; then
            HAP_HAS_LOG=true
        fi
    fi
    
    echo "   诊断详情:"
    echo "   - 中间.so存在: $([ "$HAS_INTERMEDIATE" = true ] && echo "是" || echo "否")"
    echo "   - 中间.so有增强日志: $([ "$INTERMEDIATE_HAS_LOG" = true ] && echo "是" || echo "否")"
    echo "   - HAP文件存在: $([ "$HAS_HAP" = true ] && echo "是" || echo "否")"
    echo "   - HAP中.so有增强日志: $([ "$HAP_HAS_LOG" = true ] && echo "是" || echo "否")"
    echo ""
    
    echo -e "${BLUE}🔧 修复建议:${NC}"
    echo ""
    
    if [ "$INTERMEDIATE_HAS_LOG" = true ] && [ "$HAP_HAS_LOG" = false ]; then
        echo "   ${RED}问题: HAP打包缓存${NC}"
        echo ""
        echo "   中间.so正确，但HAP中的.so是旧版本"
        echo "   说明HAP打包时使用了缓存"
        echo ""
        echo "   运行强制清理重编译脚本:"
        echo "   ./force_clean_rebuild.sh"
        echo ""
    elif [ "$INTERMEDIATE_HAS_LOG" = false ]; then
        echo "   ${RED}问题: .so未重新编译${NC}"
        echo ""
        echo "   源代码有增强日志，但.so中没有"
        echo "   说明.so文件使用了缓存"
        echo ""
        echo "   解决方案:"
        echo "   1. 删除所有.cxx目录"
        echo "   2. 运行: ./force_clean_rebuild.sh"
        echo ""
    else
        echo "   未识别的问题，请检查编译输出"
        echo ""
    fi
fi

echo ""
echo "=========================================="
echo "📁 生成的文件"
echo "=========================================="
echo ""
echo "   - device_current.log (设备日志)"
echo "   - device_verification_report.txt (验证报告)"
echo ""

if [ -f "compile_force.log" ]; then
    echo "   - compile_force.log (编译日志)"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""

