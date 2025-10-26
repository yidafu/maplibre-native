#!/bin/bash

echo "======================================"
echo "渲染触发调试测试脚本"
echo "======================================"
echo ""
echo "⚠️ 请按以下步骤操作："
echo ""
echo "1. 在设备上打开应用"
echo "2. 进入 'Gesture Test Page'"
echo "3. 快速拖动地图 5 秒"
echo "4. 停止操作，静止等待 10 秒"
echo "5. 按 Enter 键开始收集日志"
echo ""
read -p "准备好后按 Enter..."

echo ""
echo "正在收集日志..."

# 收集20秒的日志
hdc shell hilog > render_debug_full.log 2>&1 &
PID=$!

sleep 20

kill $PID 2>/dev/null
wait $PID 2>/dev/null

echo ""
echo "✅ 日志收集完成！"
echo ""

# 提取关键日志
echo "📊 分析渲染触发情况..."
echo ""

grep -E "🔄|🗺️|🎨|🎬" render_debug_full.log > render_debug.log

# 统计各类事件
echo "===================================="
echo "事件统计："
echo "===================================="
SOURCE_CHANGED=$(grep "🔄" render_debug.log | wc -l | tr -d ' ')
MAP_LOADED=$(grep "🗺️" render_debug.log | wc -l | tr -d ' ')
STYLE_LOADED=$(grep "🎨" render_debug.log | wc -l | tr -d ' ')
RENDER_REQUESTS=$(grep "🎬" render_debug.log | wc -l | tr -d ' ')

echo "🔄 onSourceChanged 调用次数: $SOURCE_CHANGED"
echo "🗺️ onDidFinishLoadingMap 调用次数: $MAP_LOADED"
echo "🎨 onDidFinishLoadingStyle 调用次数: $STYLE_LOADED"
echo "🎬 requestRender 总调用次数: $RENDER_REQUESTS"
echo ""

# 显示最后10秒的日志
echo "===================================="
echo "最后10秒的渲染事件（检查是否停止）："
echo "===================================="
tail -30 render_debug.log | tail -10

echo ""
echo "===================================="
echo ""
echo "完整调试日志已保存到："
echo "  - render_debug_full.log (完整日志)"
echo "  - render_debug.log (过滤后的关键日志)"
echo ""
echo "🔍 判断标准："
echo "  - 如果最后10秒还有 🔄 onSourceChanged → 瓦片加载导致持续渲染"
echo "  - 如果最后10秒没有任何日志 → 已正常停止渲染"
echo "  - 如果 🎬 requestRender 数量 > 100 → 存在过度渲染"
echo ""

