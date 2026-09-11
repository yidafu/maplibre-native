#!/bin/bash
# Harmony 平台编译脚本
# 用于编译 maplibre_harmony 模块

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查环境变量
check_environment() {
    print_header "检查环境"

    if [ ! -d "/Applications/DevEco-Studio.app" ]; then
        print_error "未找到 DevEco Studio，请确认已安装"
        exit 1
    fi
    print_success "DevEco Studio 已安装"

    export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
    export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node

    if [ ! -d "$DEVECO_SDK_HOME" ]; then
        print_error "SDK 路径不存在: $DEVECO_SDK_HOME"
        exit 1
    fi
    print_success "SDK 路径正确: $DEVECO_SDK_HOME"

    if [ ! -d "$NODE_HOME" ]; then
        print_error "Node 路径不存在: $NODE_HOME"
        exit 1
    fi
    print_success "Node 路径正确: $NODE_HOME"
}

MODULE_DIR="/Users/yidafu/github/maplibre-native/platform/harmony/maplibre_harmony"
PROFILE_FILE="$MODULE_DIR/build-profile.json5"

# 读取 build-profile.json5 当前配置的后端
get_current_backend() {
    if grep -q -- "-DMLN_WITH_VULKAN=ON" "$PROFILE_FILE"; then
        echo "vulkan"
    else
        echo "opengl"
    fi
}

# 将目标后端写入 build-profile.json5（编译期决定后端，GL/Vulkan 分离构建）
# 后端变化时清理 native 构建缓存，避免增量编译混入旧后端产物
switch_backend() {
    print_header "配置渲染后端: $BACKEND"

    local current
    current=$(get_current_backend)

    if [ "$current" = "$BACKEND" ]; then
        print_success "build-profile.json5 已是 $BACKEND 后端，无需修改"
        return
    fi

    if [ "$BACKEND" = "vulkan" ]; then
        local args="-DCMAKE_CXX_STANDARD=20 -DCMAKE_POLICY_DEFAULT_CMP0148=NEW -DMLN_WITH_VULKAN=ON -DMLN_WITH_OPENGL=OFF"
    else
        local args="-DCMAKE_CXX_STANDARD=20 -DCMAKE_POLICY_DEFAULT_CMP0148=NEW -DMLN_WITH_VULKAN=OFF -DMLN_WITH_OPENGL=ON"
    fi

    local tmp="$PROFILE_FILE.tmp"
    sed "s|\"arguments\": \"-DCMAKE_CXX_STANDARD[^\"]*\"|\"arguments\": \"$args\"|" "$PROFILE_FILE" > "$tmp"
    if ! grep -qF -- "$args" "$tmp"; then
        rm -f "$tmp"
        print_error "改写 build-profile.json5 失败，请手动修改 arguments 行"
        exit 1
    fi
    mv "$tmp" "$PROFILE_FILE"

    # 后端切换必须清理 native 缓存
    if [ -d "$MODULE_DIR/.cxx" ]; then
        print_info "后端已切换，清理 native 构建缓存 (.cxx)..."
        rm -rf "$MODULE_DIR/.cxx"
    fi

    print_success "已切换到 $BACKEND 后端"
}

# 清理构建
clean_build() {
    print_header "清理构建"
    
    cd /Users/yidafu/github/maplibre-native/platform/harmony
    
    if [ -d "maplibre_harmony/.cxx" ]; then
        print_info "删除 .cxx 目录..."
        rm -rf maplibre_harmony/.cxx
    fi
    
    if [ -d "maplibre_harmony/build" ]; then
        print_info "删除 build 目录..."
        rm -rf maplibre_harmony/build
    fi
    
    if [ -d ".hvigor" ]; then
        print_info "删除 .hvigor 目录..."
        rm -rf .hvigor
    fi
    
    print_success "清理完成"
}

# 编译模块
build_module() {
    print_header "编译 maplibre_harmony 模块"
    
    cd /Users/yidafu/github/maplibre-native/platform/harmony
    
    print_info "开始编译..."
    print_info "模式: $BUILD_MODE"
    print_info "产品: default"
    print_info "模块: maplibre_harmony@default"
    
    /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
        /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
        --mode module \
        -p product=default \
        -p module=maplibre_harmony@default \
        -p buildMode=$BUILD_MODE assembleHar \
        --analyze=normal \
        --parallel \
        --incremental \
        --daemon
    
    if [ $? -eq 0 ]; then
        print_success "编译成功"

        # 显示输出文件，并按后端分离产物
        # 注意：hvigor 每次构建会清空 outputs 目录，因此分离产物存放在
        # dist/ 下以保留两种后端的构建结果
        HAR_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony.har"
        if [ -f "$HAR_FILE" ]; then
            HAR_SIZE=$(du -h "$HAR_FILE" | cut -f1)
            print_success "HAR 文件: $HAR_FILE ($HAR_SIZE)"

            DIST_DIR="/Users/yidafu/github/maplibre-native/platform/harmony/dist"
            mkdir -p "$DIST_DIR"
            BACKEND_HAR="$DIST_DIR/maplibre_harmony_${BACKEND}.har"
            cp "$HAR_FILE" "$BACKEND_HAR"
            print_success "后端产物: $BACKEND_HAR ($(du -h "$BACKEND_HAR" | cut -f1))"
        fi
    else
        print_error "编译失败"
        exit 1
    fi
}

# 显示编译统计
show_statistics() {
    print_header "编译统计"
    
    cd /Users/yidafu/github/maplibre-native/platform/harmony
    
    if [ -f "maplibre_harmony/build/default/outputs/default/maplibre_harmony.har" ]; then
        HAR_FILE="maplibre_harmony/build/default/outputs/default/maplibre_harmony.har"
        HAR_SIZE=$(du -h "$HAR_FILE" | cut -f1)
        print_info "HAR 大小: $HAR_SIZE"
    fi
    
    if [ -d "maplibre_harmony/.cxx" ]; then
        SO_FILES=$(find maplibre_harmony/.cxx -name "*.so" 2>/dev/null | wc -l)
        print_info "生成的 .so 文件数: $SO_FILES"
        
        if [ $SO_FILES -gt 0 ]; then
            print_info "主要的 .so 文件:"
            find maplibre_harmony/.cxx -name "*.so" 2>/dev/null | while read so_file; do
                so_size=$(du -h "$so_file" | cut -f1)
                so_name=$(basename "$so_file")
                echo -e "  ${BLUE}→${NC} $so_name ($so_size)"
            done
        fi
    fi
}

# 快速编译（增量编译，不清理）
quick_build() {
    print_header "快速编译（增量）"
    check_environment
    switch_backend
    build_module
    show_statistics
}

# 完整编译（清理后编译）
full_build() {
    print_header "完整编译（清理 + 编译）"
    check_environment
    switch_backend
    clean_build
    build_module
    show_statistics
}

# 仅清理
only_clean() {
    check_environment
    clean_build
}

# 显示帮助
show_help() {
    echo "Harmony 平台编译脚本"
    echo ""
    echo "用法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  quick       快速编译（增量编译，默认）"
    echo "  full        完整编译（清理后编译）"
    echo "  clean       仅清理构建文件"
    echo "  help        显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --debug            使用 debug 模式编译（默认）"
    echo "  --release          使用 release 模式编译"
    echo "  --backend opengl   编译 OpenGL ES 后端（默认）"
    echo "  --backend vulkan   编译 Vulkan 后端（编译期决定，产物分离为 maplibre_harmony_vulkan.har）"
    echo ""
    echo "示例:"
    echo "  $0 quick                        # 快速增量编译（debug, opengl）"
    echo "  $0 full --backend vulkan        # 完整编译 Vulkan 后端"
    echo "  $0 quick --release --backend vulkan"
    echo "  $0 clean                        # 清理构建文件"
    echo ""
}

# 主函数
main() {
    # 默认参数
    COMMAND="quick"
    BUILD_MODE="debug"
    BACKEND="opengl"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            quick|full|clean|help)
                COMMAND=$1
                shift
                ;;
            --debug)
                BUILD_MODE="debug"
                shift
                ;;
            --release)
                BUILD_MODE="release"
                shift
                ;;
            --backend)
                shift
                if [[ "$1" != "opengl" && "$1" != "vulkan" ]]; then
                    print_error "--backend 仅支持 opengl 或 vulkan"
                    exit 1
                fi
                BACKEND=$1
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 执行命令
    case $COMMAND in
        quick)
            quick_build
            ;;
        full)
            full_build
            ;;
        clean)
            only_clean
            ;;
        help)
            show_help
            exit 0
            ;;
        *)
            print_error "未知命令: $COMMAND"
            show_help
            exit 1
            ;;
    esac
    
    # 计算耗时
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "完成"
    print_success "总耗时: ${DURATION} 秒"
    
    # 显示下一步提示
    echo ""
    print_info "下一步:"
    echo "  1. 检查编译输出是否有警告"
    echo "  2. 使用 DevEco Studio 运行测试应用"
    echo "  3. 查看日志: hdc hilog | grep -E 'MapRenderThread|HarmonyRenderer'"
    echo ""
}

# 运行主函数
main "$@"

