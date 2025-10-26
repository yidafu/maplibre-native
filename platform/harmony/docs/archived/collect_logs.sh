#!/bin/bash

echo "收集日志中，请稍候..."
sleep 3

# 收集日志
hdc shell hilog > crash.log 2>&1 &
PID=$!

echo "日志收集已启动（PID: $PID）"
echo "等待 10 秒收集日志..."
sleep 10

# 停止日志收集
kill $PID 2>/dev/null

echo "日志收集完成！"
echo ""
echo "分析 DPI 相关日志..."
echo "========================================"

# 搜索关键日志
grep -i "\[DEBUG\]\|setPixelRatio\|Device DPI\|pixelRatio\|Component aboutToAppear\|onSurfaceCreated" crash.log | head -50

echo "========================================"
echo ""
echo "完整日志已保存到: crash.log"

