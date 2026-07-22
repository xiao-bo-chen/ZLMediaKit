#!/bin/bash
# ZLMediaKit 一键编译脚本（Linux）
# 用法：把本脚本放在 ZLMediaKit 根目录，服务器上拉完代码后执行：
#   chmod +x build_zlm.sh && ./build_zlm.sh
# 编译产物 MediaServer 路径会在最后打印。

set -e

echo "==> [1/5] 检测系统包管理器并安装编译依赖"
PM=""
if command -v apt-get >/dev/null 2>&1;   then PM="apt";
elif command -v dnf >/dev/null 2>&1;      then PM="dnf";
elif command -v yum >/dev/null 2>&1;      then PM="yum";
fi

case "$PM" in
    apt)
        sudo apt-get update
        sudo apt-get install -y build-essential cmake git libssl-dev pkg-config
        ;;
    dnf|yum)
        sudo "$PM" install -y gcc gcc-c++ cmake make git openssl-devel
        ;;
    *)
        echo "未识别到 apt/dnf/yum，请手动安装：gcc g++ cmake make git openssl-devel"
        ;;
esac

echo "==> [2/5] 检查 cmake 版本（ZLMediaKit 需要 >= 3.1）"
CMAKE_VER=$(cmake --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo "当前 cmake 版本: $CMAKE_VER"
if command -v cmake >/dev/null 2>&1; then
    CMAKE_OK=$(awk "BEGIN{v=\"$CMAKE_VER\"; split(v,a,\".\"); print (a[1]>3 || (a[1]==3 && a[2]>=1))?1:0}")
    if [ "$CMAKE_OK" != "1" ]; then
        echo "cmake 版本过低，请升级 cmake 后重试（CentOS7 默认 2.8 太旧）。"
        exit 1
    fi
else
    echo "未找到 cmake，请先安装。"
    exit 1
fi

# 进入脚本所在目录（即 ZLMediaKit 根目录）
cd "$(dirname "$0")"
echo "==> 工作目录: $(pwd)"

echo "==> [3/5] 更新 git 子模块（3rdpart 等依赖）"
# 失败不中断：依赖若已内置可忽略
git submodule update --init --recursive || echo "（子模块更新失败或无需更新，继续）"

echo "==> [4/5] 开始编译"
mkdir -p build
cd build
# 如需精简（不需要 WebRTC 播放），可加：-DENABLE_WEBRTC=OFF 加速编译
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"

echo "==> [5/5] 定位编译产物"
MEDIA_SERVER=$(find "$(dirname "$0")/build" -type f -name MediaServer | head -1)
if [ -z "$MEDIA_SERVER" ]; then
    echo "未找到 MediaServer 二进制，编译可能失败，请检查上方日志。"
    exit 1
fi

echo "=================================================="
echo "编译成功！MediaServer 位于："
echo "  $MEDIA_SERVER"
echo ""
echo "部署说明："
echo "  1. 将 MediaServer 二进制替换到服务器现有 MediaServer 进程所在位置"
echo "     （即之前 pid 对应的那份，例如 /path/to/bin/MediaServer）。"
echo "  2. 二进制运行时需要在其工作目录下有 config.ini 和 www/ 目录，"
echo "     请从仓库 conf/ 复制 config.ini 并放入你的配置（含 [rtp_proxy] bind_source=0）。"
echo "  3. 重启 MediaServer 进程使其生效。"
echo "=================================================="
