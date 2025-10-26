#!/bin/bash
set -e

echo "=================================================="
echo "🔍 文件日志诊断测试脚本"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_PACKAGE="org.maplibre.harmony"
HAP_PATH="maplibre_harmony/build/default/outputs/default/maplibre_harmony-default-signed.hap"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
# 步骤1：清理并安装
# ============================================================
log_step "步骤1: 清理旧应用..."
hdc shell aa force-stop $APP_PACKAGE 2>/dev/null || true
hdc shell bm uninstall -n $APP_PACKAGE 2>/dev/null || log_warn "应用可能未安装"

log_step "步骤2: 清理设备缓存..."
hdc shell "rm -rf /data/app/el1/bundle/public/$APP_PACKAGE" 2>/dev/null || true
hdc shell "rm -rf /data/local/tmp/$APP_PACKAGE" 2>/dev/null || true

log_step "步骤3: 准备文件日志..."
hdc shell "rm -f /data/local/tmp/http_debug.log" 2>/dev/null || true
hdc shell "touch /data/local/tmp/http_debug.log" 2>/dev/null || true
hdc shell "chmod 666 /data/local/tmp/http_debug.log" 2>/dev/null || true
log_step "✅ 文件日志已准备: /data/local/tmp/http_debug.log"

log_step "步骤4: 安装 HAP..."
if [ ! -f "$HAP_PATH" ]; then
    log_error "HAP 文件不存在: $HAP_PATH"
    log_error "请先在 DevEco Studio 中构建项目"
    exit 1
fi

hdc install -r "$HAP_PATH"
log_step "✅ HAP 安装成功"

log_step "步骤5: 清空 hilog..."
hdc hilog -r
log_step "✅ hilog 已清空"

# ============================================================
# 步骤2：等待用户启动应用
# ============================================================
echo ""
echo "=================================================="
echo "📱 请在设备上手动启动应用: $APP_PACKAGE"
echo "=================================================="
echo ""
echo "启动后，按任意键继续收集日志..."
read -n 1 -s

# ============================================================
# 步骤3：收集日志
# ============================================================
log_step "等待 3 秒让应用初始化..."
sleep 3

log_step "收集文件日志..."
hdc file recv /data/local/tmp/http_debug.log http_debug.log 2>&1 || log_warn "无法获取文件日志"

log_step "收集 hilog..."
timeout 2 hdc hilog > black-screen-g.log 2>&1 || true

# ============================================================
# 步骤4：分析日志
# ============================================================
echo ""
echo "=================================================="
echo "📊 日志分析"
echo "=================================================="

if [ -f http_debug.log ]; then
    FILE_SIZE=$(wc -c < http_debug.log)
    LINE_COUNT=$(wc -l < http_debug.log)
    
    if [ "$FILE_SIZE" -eq 0 ]; then
        log_error "文件日志为空！"
        echo "  可能原因："
        echo "  1. 代码未执行到 FILE_LOG"
        echo "  2. 文件系统权限问题"
        echo "  3. 应用在第一条日志前就崩溃"
    else
        log_step "✅ 文件日志大小: $FILE_SIZE 字节, $LINE_COUNT 行"
        
        echo ""
        echo "=== 文件日志内容 ==="
        cat http_debug.log
        
        echo ""
        echo "=== 最后一条日志 ==="
        tail -1 http_debug.log
        
        echo ""
        echo "=== 异常信息 ==="
        if grep -q "EXCEPTION" http_debug.log; then
            grep -A 2 "EXCEPTION" http_debug.log
            log_error "发现异常！"
        else
            log_step "✅ 无异常"
        fi
        
        echo ""
        echo "=== 关键节点检查 ==="
        
        check_log() {
            if grep -q "$1" http_debug.log; then
                echo -e "  ✅ $2"
            else
                echo -e "  ${RED}❌ $2${NC}"
            fi
        }
        
        check_log "HTTPFileSource::Impl CONSTRUCTOR ENTRY" "Impl 构造函数"
        check_log "HTTPFileSource CONSTRUCTOR ENTRY" "HTTPFileSource 构造函数"
        check_log "HTTPFileSource::request() ENTRY" "request() 函数"
        check_log "Before make_unique<HTTPRequest>" "准备创建 HTTPRequest"
        check_log "HTTPRequest CONSTRUCTOR ENTRY" "HTTPRequest 构造函数"
        check_log "Before handleError calls" "CURL 配置前"
        check_log "After all handleError calls" "CURL 配置后"
        check_log "Before adding handle to CURLEventLoop" "添加到事件循环前"
        check_log "addHandle SUCCESS" "添加到事件循环成功"
        check_log "Returning request" "request() 函数返回"
        
    fi
else
    log_error "文件日志不存在！"
fi

echo ""
echo "=== hilog 中的 FILE_LOG ==="
if grep -q "HTTP_FILE_LOG" black-screen-g.log 2>/dev/null; then
    grep "HTTP_FILE_LOG" black-screen-g.log | head -5
    log_step "✅ stderr 有输出"
else
    log_warn "stderr 无 FILE_LOG 输出"
fi

echo ""
echo "=== hilog 中的 HTTP_CRITICAL ==="
if grep -q "HTTP_CRITICAL" black-screen-g.log 2>/dev/null; then
    grep "HTTP_CRITICAL" black-screen-g.log | head -5
    log_step "✅ hilog 有 HTTP_CRITICAL"
else
    log_warn "hilog 无 HTTP_CRITICAL 输出"
fi

# ============================================================
# 生成诊断报告
# ============================================================
echo ""
echo "=================================================="
echo "📝 生成诊断报告"
echo "=================================================="

{
  echo "# 文件日志诊断报告"
  echo "生成时间: $(date)"
  echo ""
  echo "## 文件日志"
  if [ -f http_debug.log ]; then
    echo "\`\`\`"
    cat http_debug.log
    echo "\`\`\`"
  else
    echo "文件日志不存在"
  fi
  
  echo ""
  echo "## 异常信息"
  if [ -f http_debug.log ] && grep -q "EXCEPTION" http_debug.log; then
    echo "\`\`\`"
    grep -A 2 "EXCEPTION" http_debug.log
    echo "\`\`\`"
  else
    echo "无异常"
  fi
  
  echo ""
  echo "## stderr 输出"
  if grep -q "HTTP_FILE_LOG" black-screen-g.log 2>/dev/null; then
    echo "\`\`\`"
    grep "HTTP_FILE_LOG" black-screen-g.log | head -20
    echo "\`\`\`"
  else
    echo "无 FILE_LOG 输出"
  fi
} > diagnosis_report.md

log_step "✅ 诊断报告已生成: diagnosis_report.md"

echo ""
echo "=================================================="
echo "✅ 测试完成！"
echo "=================================================="
echo ""
echo "📁 生成的文件:"
echo "  - http_debug.log         (文件日志)"
echo "  - black-screen-g.log     (hilog 完整日志)"
echo "  - diagnosis_report.md    (诊断报告)"
echo ""
echo "请查看 diagnosis_report.md 了解详细分析结果"
echo "=================================================="

