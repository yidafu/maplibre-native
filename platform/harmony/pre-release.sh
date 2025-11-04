#!/bin/bash

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