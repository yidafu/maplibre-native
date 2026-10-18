#!/bin/bash

# 清理 NapiArgs 优化过程中生成的备份文件

echo "🗑️  清理备份文件..."

BACKUP_DIR="/Users/yidafu/github/maplibre-native/platform/harmony/maplibre-harmony/src/main/cpp"

cd "$BACKUP_DIR"

# 统计备份文件
BACKUP_COUNT=$(find . -name "*.backup" -type f | wc -l | tr -d ' ')
echo "找到 $BACKUP_COUNT 个备份文件"

if [ "$BACKUP_COUNT" -eq 0 ]; then
    echo "✅ 没有备份文件需要清理"
    exit 0
fi

# 列出所有备份文件
echo ""
echo "备份文件列表："
find . -name "*.backup" -type f | while read -r file; do
    echo "  - $file"
done

echo ""
read -p "确认删除这些备份文件？(y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    find . -name "*.backup" -type f -delete
    echo "✅ 已删除 $BACKUP_COUNT 个备份文件"
else
    echo "❌ 已取消删除操作"
    exit 1
fi

echo ""
echo "✨ 清理完成！"

