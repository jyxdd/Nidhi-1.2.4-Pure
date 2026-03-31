#!/bin/bash
set -e

# ============================================
# 路徑配置
# ============================================
OUTPUT_DIR="$(pwd)/output"
LOG_DIR="$OUTPUT_DIR/logs"
ZIP_OUT_DIR="$OUTPUT_DIR/zip"
mkdir -p "$LOG_DIR" "$ZIP_OUT_DIR"

TOOLCHAIN_PATH=$HOME/zyc-clang/bin
NIDHIKERNEL_VERSION_STR='1.2.4'

# 顏色
BLUE=$'\e[0;34m'
GREEN=$'\e[0;32m'
NC=$'\e[0m'

TARGET_DEVICE=$1
JOBS=$(nproc)

if [ -z "$TARGET_DEVICE" ]; then
  echo "錯誤: 請指定設備代號"
  exit 1
fi

LOG_FILE="$LOG_DIR/build_${TARGET_DEVICE}.log"
export PATH="$TOOLCHAIN_PATH:$PATH"

# 編譯參數 (純淨版)
MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"

run_make() {
  echo -e "${BLUE}[*] $1${NC}"
  make "${@:2}" 2>&1 | tee -a "$LOG_FILE"
}

build_variant() {
  local mode=$1
  echo -e "${GREEN}開始編譯 $mode 變體...${NC}"
  
  rm -rf out/
  run_make "Generating defconfig" $MAKE_ARGS ${TARGET_DEVICE}_defconfig

  # 徹底停用 KSU 相關配置
  scripts/config --file out/.config -d KSU -d KSU_SUSFS
  
  # 基礎內核配置
  scripts/config --file out/.config \
    -e OVERLAY_FS -e CONFIG_TMPFS_XATTR \
    -d CONFIG_LOCALVERSION_AUTO \
    --set-str CONFIG_LOCALVERSION "-Nidhi-${NIDHIKERNEL_VERSION_STR}-Pure"

  run_make "Compiling" $MAKE_ARGS -j$JOBS

  # 打包
  find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb
  rm -rf anykernel/kernels/ && mkdir -p anykernel/kernels/
  cp out/arch/arm64/boot/Image anykernel/kernels/
  cp out/arch/arm64/boot/dtb anykernel/kernels/

  cd anykernel
  ZIP_NAME="NidhiKernel_${TARGET_DEVICE}_${mode}_Pure.zip"
  zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip
  mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
  cd ..
}

# 執行編譯 (預設跑 AOSP 和 MIUI)
build_variant "AOSP"
build_variant "MIUI"

echo -e "${GREEN}編譯完成！產物在 output/zip/${NC}"
