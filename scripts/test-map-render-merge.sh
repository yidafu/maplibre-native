#!/bin/bash
# Map+Render Thread 合并方案测试脚本
# 用于验证新架构是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC} %-50s ${BLUE}║${NC}\n" "$1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
}

print_test() {
    echo -e "${CYAN}🧪 测试: $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}  ℹ️  $1${NC}"
}

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# 测试结果记录
declare -a TEST_RESULTS

# 记录测试结果
record_test() {
    local test_name=$1
    local result=$2
    local message=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ $test_name: PASS")
        print_success "$message"
    elif [ "$result" = "FAIL" ]; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ $test_name: FAIL - $message")
        print_error "$message"
    elif [ "$result" = "WARN" ]; then
        WARNINGS=$((WARNINGS + 1))
        TEST_RESULTS+=("⚠️  $test_name: WARNING - $message")
        print_warning "$message"
    fi
}

# 检查设备连接
check_device() {
    print_header "检查设备连接"
    
    print_test "HDC 连接"
    if command -v hdc &> /dev/null; then
        record_test "HDC 命令" "PASS" "HDC 命令可用"
    else
        record_test "HDC 命令" "FAIL" "HDC 命令不可用"
        return 1
    fi
    
    print_test "设备列表"
    DEVICE_COUNT=$(hdc list targets | grep -v "Empty" | wc -l)
    if [ $DEVICE_COUNT -gt 0 ]; then
        record_test "设备连接" "PASS" "已连接 $DEVICE_COUNT 个设备"
    else
        record_test "设备连接" "FAIL" "未找到连接的设备"
        return 1
    fi
}

# 检查编译输出
check_build_output() {
    print_header "检查编译输出"
    
    cd /Users/yidafu/github/maplibre-native/platform/harmony
    
    print_test "HAR 文件"
    HAR_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony.har"
    if [ -f "$HAR_FILE" ]; then
        HAR_SIZE=$(du -h "$HAR_FILE" | cut -f1)
        record_test "HAR 文件存在" "PASS" "文件大小: $HAR_SIZE"
    else
        record_test "HAR 文件存在" "FAIL" "HAR 文件不存在"
        return 1
    fi
    
    print_test ".so 文件"
    SO_FILE=$(find maplibre_harmony/.cxx -name "libmaplibre_harmony.so" 2>/dev/null | head -1)
    if [ -n "$SO_FILE" ]; then
        SO_SIZE=$(du -h "$SO_FILE" | cut -f1)
        record_test ".so 文件存在" "PASS" "文件大小: $SO_SIZE"
    else
        record_test ".so 文件存在" "FAIL" ".so 文件不存在"
    fi
    
    print_test "关键符号检查"
    if [ -n "$SO_FILE" ]; then
        # 检查 HarmonyMapRenderThread 符号
        if nm "$SO_FILE" 2>/dev/null | grep -q "HarmonyMapRenderThread"; then
            record_test "HarmonyMapRenderThread 符号" "PASS" "类符号存在"
        else
            record_test "HarmonyMapRenderThread 符号" "WARN" "未找到类符号"
        fi
    fi
}

# 检查源代码
check_source_code() {
    print_header "检查源代码"
    
    cd /Users/yidafu/github/maplibre-native/platform/harmony/maplibre_harmony/src/main/cpp
    
    print_test "核心文件存在"
    
    if [ -f "rendering/harmony_map_render_thread.hpp" ]; then
        record_test "头文件" "PASS" "harmony_map_render_thread.hpp 存在"
    else
        record_test "头文件" "FAIL" "harmony_map_render_thread.hpp 不存在"
    fi
    
    if [ -f "rendering/harmony_map_render_thread.cpp" ]; then
        record_test "实现文件" "PASS" "harmony_map_render_thread.cpp 存在"
    else
        record_test "实现文件" "FAIL" "harmony_map_render_thread.cpp 不存在"
    fi
    
    print_test "旧文件已删除"
    
    if [ ! -f "rendering/harmony_render_thread.hpp" ]; then
        record_test "旧 RenderThread" "PASS" "旧文件已删除"
    else
        record_test "旧 RenderThread" "WARN" "旧文件仍存在"
    fi
    
    if [ ! -f "rendering/forwarding_renderer_observer.hpp" ]; then
        record_test "旧 ForwardingObserver" "PASS" "旧文件已删除"
    else
        record_test "旧 ForwardingObserver" "WARN" "旧文件仍存在"
    fi
}

# 分析日志
analyze_logs() {
    print_header "分析应用日志"
    
    print_info "请确保应用正在运行..."
    print_info "将收集 10 秒的日志..."
    
    # 创建临时日志文件
    LOG_FILE="/tmp/harmony_map_test_$(date +%s).log"
    
    # 收集日志
    timeout 10s hdc hilog > "$LOG_FILE" 2>&1 || true
    
    print_test "初始化序列"
    
    if grep -q "Map+Render Thread Started" "$LOG_FILE"; then
        record_test "线程启动" "PASS" "线程成功启动"
    else
        record_test "线程启动" "FAIL" "未找到线程启动日志"
    fi
    
    if grep -q "RunLoop created" "$LOG_FILE"; then
        record_test "RunLoop 创建" "PASS" "RunLoop 成功创建"
    else
        record_test "RunLoop 创建" "FAIL" "未找到 RunLoop 创建日志"
    fi
    
    if grep -q "EGL Context initialized" "$LOG_FILE"; then
        record_test "EGL 初始化" "PASS" "EGL Context 成功初始化"
    else
        record_test "EGL 初始化" "FAIL" "未找到 EGL 初始化日志"
    fi
    
    if grep -q "Renderer created" "$LOG_FILE"; then
        record_test "Renderer 创建" "PASS" "Renderer 成功创建"
    else
        record_test "Renderer 创建" "FAIL" "未找到 Renderer 创建日志"
    fi
    
    if grep -q "Map created" "$LOG_FILE"; then
        record_test "Map 创建" "PASS" "Map 成功创建"
    else
        record_test "Map 创建" "FAIL" "未找到 Map 创建日志"
    fi
    
    print_test "运行状态"
    
    if grep -q "Starting RunLoop" "$LOG_FILE"; then
        record_test "RunLoop 运行" "PASS" "RunLoop 开始运行"
    else
        record_test "RunLoop 运行" "FAIL" "未找到 RunLoop 运行日志"
    fi
    
    print_test "Style 加载"
    
    if grep -q "Style.*load" "$LOG_FILE"; then
        record_test "Style 加载" "PASS" "检测到 Style 加载活动"
    else
        record_test "Style 加载" "WARN" "未检测到 Style 加载"
    fi
    
    print_test "错误检查"
    
    ERROR_COUNT=$(grep -iE "error|exception|crash|fail" "$LOG_FILE" | grep -v "Failed to.*test" | wc -l)
    if [ $ERROR_COUNT -eq 0 ]; then
        record_test "错误检查" "PASS" "未发现错误日志"
    else
        record_test "错误检查" "WARN" "发现 $ERROR_COUNT 条可能的错误日志"
        print_info "请查看日志文件: $LOG_FILE"
    fi
    
    print_info "日志文件保存在: $LOG_FILE"
}

# 性能检查
check_performance() {
    print_header "性能检查"
    
    print_test "内存使用"
    
    # 获取应用进程
    APP_PID=$(hdc shell pidof com.example.myapplication 2>/dev/null || echo "")
    
    if [ -n "$APP_PID" ]; then
        # 获取内存信息
        MEM_INFO=$(hdc shell cat /proc/$APP_PID/status 2>/dev/null | grep VmRSS || echo "")
        if [ -n "$MEM_INFO" ]; then
            MEM_KB=$(echo "$MEM_INFO" | awk '{print $2}')
            MEM_MB=$((MEM_KB / 1024))
            record_test "内存使用" "PASS" "当前使用: ${MEM_MB} MB"
        else
            record_test "内存使用" "WARN" "无法获取内存信息"
        fi
    else
        record_test "内存使用" "WARN" "应用未运行"
    fi
}

# 显示测试报告
show_report() {
    print_header "测试报告"
    
    echo ""
    echo "测试结果摘要:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  总测试数:   ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "  通过:       ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  失败:       ${RED}$FAILED_TESTS${NC}"
    echo -e "  警告:       ${YELLOW}$WARNINGS${NC}"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "  通过率:     ${BLUE}${PASS_RATE}%${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "${RED}失败的测试:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $result == *"FAIL"* ]]; then
                echo "  $result"
            fi
        done
        echo ""
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}警告:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $result == *"WARNING"* ]]; then
                echo "  $result"
            fi
        done
        echo ""
    fi
    
    # 总体评估
    if [ $FAILED_TESTS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✅ 所有测试通过！架构实施成功！    ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        return 0
    elif [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ⚠️  测试通过，但有警告项          ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
        return 0
    else
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ❌ 测试失败，需要修复              ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        return 1
    fi
}

# 快速测试（仅编译检查）
quick_test() {
    print_header "快速测试"
    check_build_output
    check_source_code
}

# 完整测试
full_test() {
    print_header "完整测试"
    check_device
    check_build_output
    check_source_code
    
    echo ""
    print_info "准备进行运行时测试..."
    print_info "请确保应用正在运行地图页面"
    read -p "按 Enter 继续..." 
    
    analyze_logs
    check_performance
}

# 显示帮助
show_help() {
    echo "Map+Render Thread 合并方案测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [命令]"
    echo ""
    echo "命令:"
    echo "  quick    快速测试（仅检查编译输出和源代码）"
    echo "  full     完整测试（包括运行时测试）"
    echo "  help     显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 quick    # 快速验证编译结果"
    echo "  $0 full     # 完整测试（需要应用运行）"
    echo ""
}

# 主函数
main() {
    local command=${1:-quick}
    
    case $command in
        quick)
            quick_test
            show_report
            ;;
        full)
            full_test
            show_report
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

