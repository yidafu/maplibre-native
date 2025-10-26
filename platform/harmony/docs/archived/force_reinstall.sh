#!/bin/bash
set -e

echo "=================================================="
echo "🔥 强制完全清理+重新安装流程"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_PACKAGE="org.maplibre.harmony"
HAP_PATH="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_step() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# ============================================================
# 步骤1：停止应用
# ============================================================
log_step "步骤1: 停止应用..."
hdc shell aa force-stop $APP_PACKAGE 2>/dev/null || log_warn "应用可能未运行"

# ============================================================
# 步骤2：完全卸载
# ============================================================
log_step "步骤2: 完全卸载应用（包括数据）..."
hdc shell bm uninstall -n $APP_PACKAGE 2>/dev/null && log_step "✅ 卸载成功" || log_warn "应用可能未安装"

# ============================================================
# 步骤3：清理设备缓存
# ============================================================
log_step "步骤3: 清理设备上的所有缓存..."
hdc shell "rm -rf /data/app/el1/bundle/public/$APP_PACKAGE" 2>/dev/null || true
hdc shell "rm -rf /data/local/tmp/$APP_PACKAGE" 2>/dev/null || true
hdc shell "rm -rf /data/local/tmp/*.hap" 2>/dev/null || true
log_step "✅ 设备缓存已清理"

# ============================================================
# 步骤4：清理本地构建缓存
# ============================================================
log_step "步骤4: 清理本地构建缓存..."
log_warn "跳过clean步骤（hvigor命令不可用）"

# ============================================================
# 步骤5：检查已构建的HAP
# ============================================================
log_step "步骤5: 检查已构建的HAP..."
if [ ! -f "$HAP_PATH" ]; then
    log_error "HAP文件不存在: $HAP_PATH"
    log_error "请先手动构建: cd /Users/yidafu/github/maplibre-native && 构建命令"
    exit 1
fi
log_step "✅ HAP文件存在"

# ============================================================
# 步骤6：验证.so文件包含新日志
# ============================================================
log_step "步骤6: 验证.so文件内容..."
SO_PATH="maplibre_harmony/build/default/intermediates/libs/default/arm64-v8a/libmaplibre_native.so"

if [ ! -f "$SO_PATH" ]; then
    log_error ".so文件不存在: $SO_PATH"
    exit 1
fi

echo "检查关键字符串..."
if strings "$SO_PATH" | grep -q "HTTP_CRITICAL"; then
    echo "  ✅ HTTP_CRITICAL - 存在"
else
    log_error "HTTP_CRITICAL 不存在！"
    exit 1
fi

if strings "$SO_PATH" | grep -q "Step 3/5"; then
    echo "  ✅ Step 3/5 - 存在"
else
    log_error "Step 3/5 不存在！"
    exit 1
fi

if strings "$SO_PATH" | grep -q "BEFORE httpFileSource"; then
    echo "  ✅ BEFORE httpFileSource - 存在"
else
    log_error "BEFORE httpFileSource 不存在！"
    exit 1
fi

if strings "$SO_PATH" | grep -q "AFTER httpFileSource"; then
    echo "  ✅ AFTER httpFileSource - 存在"
else
    log_error "AFTER httpFileSource 不存在！"
    exit 1
fi

log_step "✅ .so文件验证通过"

# ============================================================
# 步骤7：强制安装新HAP
# ============================================================
log_step "步骤7: 安装新HAP..."
if [ ! -f "$HAP_PATH" ]; then
    log_error "HAP文件不存在: $HAP_PATH"
    exit 1
fi

hdc install -r "$HAP_PATH"
log_step "✅ HAP安装成功"

# ============================================================
# 步骤8：清空日志
# ============================================================
log_step "步骤8: 清空hilog..."
hdc hilog -r
log_step "✅ 日志已清空"

# ============================================================
# 步骤9：验证设备上的.so文件
# ============================================================
log_step "步骤9: 验证设备上的.so文件..."
sleep 2  # 等待文件系统同步

DEVICE_SO_PATH="/data/app/el1/bundle/public/$APP_PACKAGE/libs/arm64/libmaplibre_native.so"
echo "检查设备文件: $DEVICE_SO_PATH"
if hdc shell "test -f $DEVICE_SO_PATH && echo exists" | grep -q "exists"; then
    log_step "✅ 设备上的.so文件存在"
    
    # 获取文件大小和修改时间
    hdc shell "ls -lh $DEVICE_SO_PATH"
else
    log_warn "设备上的.so文件不存在（可能是安装后未展开）"
fi

# ============================================================
# 完成
# ============================================================
echo ""
echo "=================================================="
echo "✅ 完全清理+重新安装完成！"
echo "=================================================="
echo ""
echo "📋 下一步操作："
echo "1. 手动在设备上启动应用: $APP_PACKAGE"
echo "2. 运行以下命令捕获日志："
echo ""
echo "   hdc hilog | grep -E \"HTTP_CRITICAL|Step 3/5|BEFORE|AFTER\""
echo ""
echo "   或使用完整日志："
echo "   hdc hilog > maplibre_harmony/black-screen-f.log"
echo ""
echo "=================================================="
echo "🔍 预期日志（应该看到）："
echo "=================================================="
echo "  ✓ HTTP_CRITICAL: HTTPFileSource::Impl CONSTRUCTOR START"
echo "  ✓ Step 1/5: Initializing CURL global..."
echo "  ✓ Step 3/5: Creating CURLEventLoop..."
echo "  ✓ HTTP_CRITICAL: HTTPFileSource HARMONY CONSTRUCTOR CALLED"
echo "  ✓ 🔵 BEFORE httpFileSource.request() call"
echo "  ✓ HTTP_CRITICAL: HTTPFileSource::request() HARMONY VERSION CALLED"
echo "  ✓ 🔵 AFTER httpFileSource.request() call"
echo ""
echo "如果仍然看不到这些日志，请查看:"
echo "  platform/harmony/DEVICE_CACHE_DIAGNOSIS.md"
echo "=================================================="

