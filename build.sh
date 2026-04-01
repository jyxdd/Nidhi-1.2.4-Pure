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
export PATH="$TOOLCHAIN_PATH:$PATH"

TARGET_DEVICE=$1
JOBS=$(nproc)

# 強行定義編譯參數 (ThinLTO 建議在腳本內鎖死)
BUILD_ARGS="ARCH=arm64 \
SUBARCH=arm64 \
O=out \
CC=clang \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CLANG_TRIPLE=aarch64-linux-gnu- \
KBUILD_BUILD_USER=jyxdd \
KBUILD_BUILD_HOST=Nidhi-CI"

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- Starting ThinLTO Build for $mode ---"
  
  # 1. 預建目錄
  rm -rf out/
  mkdir -p out

  # 2. 生成初始配置
  make $BUILD_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # 3. 路徑自動補救 (確保 .config 在 out/ 裡)
  if [ ! -f "out/.config" ]; then
    [ -f ".config" ] && mv .config out/.config || { echo "❌ Error: Config failed"; exit 1; }
  fi

  # === 核心改動：注入 ThinLTO 配置 (有了這幾行才是 LTO 版) ===
  ./scripts/config --file out/.config -e CONFIG_LTO_CLANG
  ./scripts/config --file out/.config -d CONFIG_LTO_NONE
  ./scripts/config --file out/.config -e CONFIG_THINLTO
  
  # 4. 基本配置修改
  ./scripts/config --file out/.config -d KSU -d KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure-LTO"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO

  # === 核心改動：同步配置依賴 (必須跑這行，LTO 才會生效) ===
  make $BUILD_ARGS olddefconfig 2>&1 | tee -a "$log_file"

  # 5. 開始編譯 (ThinLTO 鏈接時間會顯著增加)
  make $BUILD_ARGS -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 6. 打包 ZIP
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

    # 清理空間給下一個 variant
    rm -rf out/
  else
    echo "Error: Kernel Image not found for $mode!"
    exit 1
  fi
}

build_variant "AOSP"
build_variant "MIUI"

echo "Build Process Completed!"
