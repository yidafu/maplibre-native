#!/bin/bash

# MapLibre Harmony 日志查看脚本

echo "=========================================="
echo "MapLibre Harmony 实时日志"
echo "=========================================="
echo ""
echo "监控关键日志输出..."
echo "按 Ctrl+C 停止"
echo ""
echo "关注的关键点："
echo "  ✓ onDidBecomeIdle - 应该在加载完成后出现"
echo "  ✓ needsRepaint=0 - 应该在静止时出现"
echo "  ✗ needsRepaint=1 持续 - 表示问题未解决"
echo ""
echo "------------------------------------------"
echo ""

# 清除之前的日志
hdc shell hilog -r

# 实时显示相关日志
hdc shell hilog -x | grep -E "(NativeMapView|HarmonyRenderer|onWillStartRenderingFrame|onDidFinishRenderingFrame|onDidBecomeIdle|needsRepaint|requestRender)" --line-buffered --color=always

