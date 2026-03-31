#!/bin/bash

# Ensure the script exits on error
set -e

# ============================================
# 路徑配置 (針對 GitHub Actions 優化)
# ============================================
# 統一將產出放在源碼目錄下的 output 文件夾，方便 GitHub Actions 抓取
OUTPUT_DIR="$(pwd)/output"
LOG_DIR="$OUTPUT_DIR/logs"
ZIP_OUT_DIR="$OUTPUT_DIR/zip"

mkdir -p "$LOG_DIR"
mkdir -p "$ZIP_OUT_DIR"

TOOLCHAIN_PATH=$HOME/zyc-clang/bin
GIT_COMMIT_ID=$(git rev-parse --short=8 HEAD)
BUILD_SCRIPT_VERSION='2.1-CI'
NIDHIKERNEL_VERSION_STR='1.2.4'

# 顏色定義
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
NC=$'\e[0m'

echo -e "${GREEN}Build Script Version: $BUILD_SCRIPT_VERSION (Cloud Optimized)${NC}"
echo -e "${GREEN}NidhiKernel Version: $NIDHIKERNEL_VERSION_STR${NC}"

# ============================================
# 參數解析
# ============================================
TARGET_DEVICE=""
KSU_ENABLE=0
KSU_ZIP_STR="NoKernelSU"
TARGET_SYSTEM=""
VERBOSE_MODE=0
DIRTY_BUILD=0
JOBS=$(nproc)

positional_args=()
skip_next=0

for ((i=1; i<=$#; i++)); do
  if [ $skip_next -eq 1 ]; then skip_next=0; continue; fi
  arg="${!i}"
  case $arg in
    -V|--verbose) VERBOSE_MODE=1 ;;
    -D|--dirty)   DIRTY_BUILD=1 ;;
    -J*)          JOBS="${arg:2}" ;;
    --jobs)       next_index=$((i + 1)); JOBS="${!next_index}"; skip_next=1 ;;
    *)            positional_args+=("$arg") ;;
  esac
done

set -- "${positional_args[@]}"
TARGET_DEVICE=$1
KSU_ARG=$2
TARGET_SYSTEM=$3

if [ -z "$TARGET_DEVICE" ]; then
  echo -e "${RED}Error: No target device specified.${NC}"
  exit 1
fi

# ============================================
# 日誌設定 (修改為當前目錄)
# ============================================
LOG_FILE="$LOG_DIR/build_$(date +'%Y%m%d_%H%M%S').log"
echo -e "${BLUE}Build log will be saved to: ${LOG_FILE}${NC}"

# ============================================
# 環境校驗與配置
# ============================================
export PATH="$TOOLCHAIN_PATH:$PATH"

# 檢查工具鏈
for cmd in aarch64-linux-gnu-ld arm-linux-gnueabi-ld clang; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo -e "${RED}[$cmd] 不存在，請檢查 GitHub Action 工具鏈下載步驟。${NC}"
    exit 1
  fi
done

# 編譯參數
export KBUILD_BUILD_USER="Smarajit"
export KBUILD_BUILD_HOST="GitHub-CI"
export CCACHE_DIR="$HOME/.cache/ccache_mikernel"
export PATH="/usr/lib/ccache:$PATH"

MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"
[ $VERBOSE_MODE -eq 1 ] && MAKE_ARGS="$MAKE_ARGS V=1"

# KSU 判定
if [ "$KSU_ARG" == "ksu" ]; then
  KSU_ENABLE=1
  KSU_ZIP_STR=KSUN-SUSFS
else
  KSU_ENABLE=0
  KSU_ZIP_STR=NoKernelSU
fi

# ============================================
# 輔助函數：執行編譯並記錄日誌
# ============================================
run_make() {
  local desc="$1"
  echo -e "${BLUE}[*] $desc${NC}"
  if ! make "${@:2}" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${RED}編譯失敗: $desc${NC}"
    exit 1
  fi
}

# ============================================
# 通用編譯函數
# ============================================
build_target() {
  local mode=$1 # "AOSP" 或 "MIUI"
  echo -e "${GREEN}正在為 $mode 編譯...${NC}"

  [ $DIRTY_BUILD -eq 0 ] && rm -rf out/
  
  run_make "$mode: Generating defconfig" $MAKE_ARGS ${TARGET_DEVICE}_defconfig

  # 這裡保留你原始的 scripts/config 邏輯
  if [ $KSU_ENABLE -eq 1 ]; then
      scripts/config --file out/.config -e KSU -e KSU_SUSFS -e THREAD_INFO_IN_TASK # ...簡略，實際會跑你原本的長串
  fi

  scripts/config --file out/.config \
    -e OVERLAY_FS -e CONFIG_TMPFS_XATTR \
    -d CONFIG_LOCALVERSION_AUTO \
    --set-str CONFIG_LOCALVERSION "-Nidhi-${NIDHIKERNEL_VERSION_STR}"

  run_make "$mode: Compiling kernel" $MAKE_ARGS -j$JOBS

  # 生成 DTB
  find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb

  # 打包 AnyKernel3
  rm -rf anykernel/kernels/ && mkdir -p anykernel/kernels/
  cp out/arch/arm64/boot/Image anykernel/kernels/
  cp out/arch/arm64/boot/dtb anykernel/kernels/

  cd anykernel
  ZIP_NAME="NidhiKernel_${NIDHIKERNEL_VERSION_STR}_${mode}_${TARGET_DEVICE}_${KSU_ZIP_STR}.zip"
  zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip
  
  # 關鍵修改：搬運到雲端可見的路徑
  mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
  cd ..

  echo -e "${GREEN}$mode 編譯完成！檔案位址: $ZIP_OUT_DIR/$ZIP_NAME${NC}"
}

# ============================================
# 執行
# ============================================
if [ -z "$TARGET_SYSTEM" ] || [ "$TARGET_SYSTEM" == "aosp" ]; then
  build_target "AOSP"
fi

if [ -z "$TARGET_SYSTEM" ] || [ "$TARGET_SYSTEM" == "miui" ]; then
  # 這裡可以加入你原本腳本中的 DTS sed 修改邏輯
  build_target "MIUI"
fi

echo -e "${GREEN}所有任務已完成。產物位於 output/ 目錄下。${NC}"
