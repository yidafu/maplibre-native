#!/bin/bash

# 用法: ./pre-release.sh [new_version]
# 发布新版本时，需先修改版本号再构建
#   - 指定 new_version: 更新 package.json 版本后再构建
#   - 不指定: 使用 package.json 中已有的版本号构建（适用于 npm version + npm publish 流程）

PACKAGE_JSON="maplibre_harmony/package.json"

# 获取当前版本
CURRENT_VERSION=$(grep '"version"' "$PACKAGE_JSON" | sed 's/.*"version": "\(.*\)",/\1/')

if [ -n "$1" ]; then
  # 指定了新版本，更新 package.json
  NEW_VERSION="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" "$PACKAGE_JSON"
  else
    sed -i "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" "$PACKAGE_JSON"
  fi
  BUILD_VERSION="$NEW_VERSION"
  echo "Version updated: $CURRENT_VERSION -> $BUILD_VERSION"
else
  BUILD_VERSION="$CURRENT_VERSION"
  echo "Building version: $BUILD_VERSION"
fi

# 检测操作系统，如果是 macOS 则设置默认路径
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -z "$DEVECO_SDK_HOME" ]; then
    export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
    echo "macOS detected: DEVECO_SDK_HOME set to $DEVECO_SDK_HOME"
  fi

  if [ -z "$NODE_HOME" ]; then
    export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node
    echo "macOS detected: NODE_HOME set to $NODE_HOME"
  fi
fi

#/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js

$NODE_HOME/bin/node $DEVECO_SDK_HOME/../tools/hvigor/bin/hvigorw.js \
  --mode module \
  -p product=default \
  -p module=maplibre_harmony@default \
  -p buildMode=release assembleHar \
  --analyze=normal \
  --parallel \
  --incremental --no-daemon

# 复制 har 到根目录
cp -r maplibre_harmony/build/default/outputs/default/mapping ./maplibre_harmony