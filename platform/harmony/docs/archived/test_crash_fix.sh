#!/bin/bash

echo "======================================"
echo "测试崩溃修复脚本"
echo "======================================"
echo ""
echo "等待 15 秒收集日志..."
echo "请在设备上快速拖动地图，尝试触发崩溃..."
echo ""

# 收集日志
hdc shell hilog > crash_test.log 2>&1 &
PID=$!

# 倒计时
for i in {15..1}; do
    echo -ne "\r剩余时间: $i 秒 "
    sleep 1
done
echo ""

# 停止日志收集
kill $PID 2>/dev/null
wait $PID 2>/dev/null

echo ""
echo "日志收集完成！"
echo ""

# 检查是否有崩溃
if grep -q "signal 11\|SIGSEGV\|Crash" crash_test.log; then
    echo "❌ 发现崩溃信号！"
    echo ""
    echo "崩溃详情："
    grep -A 5 "signal 11\|SIGSEGV\|Crash" crash_test.log | head -20
    echo ""
    echo "完整日志保存在: crash_test.log"
else
    echo "✅ 未发现崩溃信号！"
    echo ""
    echo "检查是否有错误日志..."
    if grep -i "error\|exception\|failed" crash_test.log | grep -i maplibre | head -10 | grep -q ""; then
        echo ""
        echo "发现一些错误（可能不严重）："
        grep -i "error\|exception\|failed" crash_test.log | grep -i maplibre | head -10
    else
        echo "没有发现明显错误！"
    fi
fi

echo ""
echo "======================================"

