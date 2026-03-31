#!/bin/bash
# NidhiKernel Build Script - Cloud Optimized Version
set -e

# ============================================
# 路徑配置 (針對 GitHub Actions 優化)
# ============================================
# 統一將產出放在源碼目錄下的 output 文件夾
OUTPUT_DIR="$(pwd)/output"
LOG_DIR="$OUTPUT_DIR/logs"
ZIP_OUT_DIR="$OUTPUT_DIR/zip"

mkdir -p "$LOG_DIR"
mkdir -p "$ZIP_OUT_DIR"

TOOLCHAIN_PATH=$HOME/zyc-clang/bin
GIT_COMMIT_ID=$(git rev-parse --short=8 HEAD || echo "Unknown")
BUILD_SCRIPT_VERSION='2.1-CI'
NIDHIKERNEL_VERSION_STR='1.2.4'

# 顏色定義
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
NC=$'\e[0m'

echo -e "${GREEN}Build Script Version: $BUILD_SCRIPT_VERSION${NC}"
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
  echo -e "${RED}錯誤: 未指定目標設備 (例如: munch)${NC}"
  exit 1
fi

LOG_FILE="$LOG_DIR/build_${TARGET_DEVICE}_$(date +'%Y%m%d_%H%M%S').log"
export PATH="$TOOLCHAIN_PATH:$PATH"

# KSU 狀態判定
if [ "$KSU_ARG" == "ksu" ]; then
  KSU_ENABLE=1
  KSU_ZIP_STR=KSUN-SUSFS
else
  KSU_ENABLE=0
  KSU_ZIP_STR=NoKernelSU
fi

# 編譯參數
MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"
[ $VERBOSE_MODE -eq 1 ] && MAKE_ARGS="$MAKE_ARGS V=1"

run_make() {
  local desc="$1"
  echo -e "${BLUE}[*] $desc${NC}"
  if ! make "${@:2}" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${RED}編譯失敗: $desc${NC}"
    exit 1
  fi
}

build_kernel() {
  local mode=$1 # AOSP or MIUI
  echo -e "${GREEN}開始編譯 $mode 版本...${NC}"
  
  [ $DIRTY_BUILD -eq 0 ] && rm -rf out/
  run_make "$mode: Generating defconfig" $MAKE_ARGS ${TARGET_DEVICE}_defconfig

  # 內核配置 (KSU/SUSFS)
  if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config -e KSU -e KSU_SUSFS -e KSU_SUSFS_SUS_PATH -e KSU_SUSFS_SUS_MOUNT -e KSU_SUSFS_SUS_KSTAT -e KSU_SUSFS_SPOOF_UNAME -e KSU_SUSFS_ENABLE_LOG -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG -e KSU_SUSFS_OPEN_REDIRECT -e KSU_SUSFS_SUS_MAP -e THREAD_INFO_IN_TASK
  else
    scripts/config --file out/.config -d KSU
  fi

  # 通用配置
  scripts/config --file out/.config -e OVERLAY_FS -e CONFIG_TMPFS_XATTR -e CONFIG_KALLSYMS -e CONFIG_KALLSYMS_ALL -d CONFIG_LOCALVERSION_AUTO --set-str CONFIG_LOCALVERSION "-Nidhi-${NIDHIKERNEL_VERSION_STR}"

  run_make "$mode: Building Kernel" $MAKE_ARGS -j$JOBS
  
  # 生成 DTB 並打包
  find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb
  rm -rf anykernel/kernels/ && mkdir -p anykernel/kernels/
  cp out/arch/arm64/boot/Image anykernel/kernels/
  cp out/arch/arm64/boot/dtb anykernel/kernels/

  cd anykernel
  ZIP_NAME="NidhiKernel_${NIDHIKERNEL_VERSION_STR}_${mode}_${TARGET_DEVICE}_${KSU_ZIP_STR}.zip"
  zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip >> "$LOG_FILE" 2>&1
  mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
  cd ..
  echo -e "${GREEN}[✓] $mode 編譯完成: $ZIP_NAME${NC}"
}

# 執行編譯
if [ -z "$TARGET_SYSTEM" ] || [ "$TARGET_SYSTEM" == "aosp" ]; then build_kernel "AOSP"; fi
if [ -z "$TARGET_SYSTEM" ] || [ "$TARGET_SYSTEM" == "miui" ]; then build_kernel "MIUI"; fi
