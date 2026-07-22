#!/bin/bash
# ZLMediaKit 一键编译脚本（Linux）
# 用法：放在 ZLMediaKit 根目录，服务器上执行：
#   chmod +x build_zlm.sh && ./build_zlm.sh

set -e
cd "$(dirname "$0")"

git submodule update --init --recursive || true

mkdir -p build
cd build

CMAKE_BIN=$(command -v cmake3 || command -v cmake)
"$CMAKE_BIN" .. -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"

MEDIA_SERVER=$(find "$(dirname "$0")/build" -type f -name MediaServer | head -1)
echo "MediaServer: $MEDIA_SERVER"
