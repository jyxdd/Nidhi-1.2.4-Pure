#!/bin/bash
set -e

# ============================================
# 路徑配置 (保持不變)
# ============================================
OUTPUT_DIR="$(pwd)/output"
LOG_DIR="$OUTPUT_DIR/logs"
ZIP_OUT_DIR="$OUTPUT_DIR/zip"
mkdir -p "$LOG_DIR" "$ZIP_OUT_DIR"

TOOLCHAIN_PATH=$HOME/zyc-clang/bin
export PATH="$TOOLCHAIN_PATH:$PATH"

TARGET_DEVICE=$1
JOBS=$(nproc)

# MAKE_ARGS 由 yml 傳入環境變量，此處不再重複定義以防衝突
# 但為了腳本獨立運行，保留基礎參數
[ -z "$MAKE_ARGS" ] && MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-"

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- Starting ThinLTO Build for $mode ---"
  
  rm -rf out/
  
  # 1. 生成配置
  make $MAKE_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # === 僅新增：ThinLTO 核心配置注入 ===
  ./scripts/config --file out/.config -e CONFIG_LTO_CLANG
  ./scripts/config --file out/.config -d CONFIG_LTO_NONE
  ./scripts/config --file out/.config -e CONFIG_THINLTO
  
  # 2. 原有配置保持不變
  ./scripts/config --file out/.config -d KSU -d KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure-LTO"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO

  # === 僅新增：同步 ThinLTO 配置依賴 ===
  make $MAKE_ARGS olddefconfig 2>&1 | tee -a "$log_file"

  # 3. 開始編譯 (ThinLTO 鏈接時間較長，請耐心等待)
  make $MAKE_ARGS -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 4. 打包 ZIP (保持原有邏輯)
  if [ -f out/arch/arm64/boot/Image ]; then
    echo "Kernel compiled successfully! Packing..."
    find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb
    rm -rf anykernel/kernels/ && mkdir -p anykernel/kernels/
    cp out/arch/arm64/boot/Image anykernel/kernels/
    cp out/arch/arm64/boot/dtb anykernel/kernels/

    cd anykernel
    ZIP_NAME="NidhiKernel_${TARGET_DEVICE}_${mode}_Pure_LTO.zip"
    zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip
    mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
    cd ..
  else
    echo "Error: Kernel Image not found for $mode!"
    exit 1
  fi
}

build_variant "AOSP"
build_variant "MIUI"

echo "Build Process Completed!"
