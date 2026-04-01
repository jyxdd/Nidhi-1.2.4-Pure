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

if [ -z "$TARGET_DEVICE" ]; then
  echo "Error: Device codename not specified!"
  exit 1
fi

# ============================================
# 強行定義編譯參數，確保 O=out 絕對生效
# ============================================
# 這裡定義一個內部的 ARGS，避免與外部變量混淆
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
  echo "--- Starting Build for $mode ---"
  
  # 1. 預建目錄
  rm -rf out/
  mkdir -p out

  # 2. 生成配置 (手動加上 O=out 確保萬無一失)
  make $BUILD_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # 3. 核心檢查與自動補救
  if [ ! -f "out/.config" ]; then
    echo "⚠️ Warning: out/.config not found in out/, checking root..."
    if [ -f ".config" ]; then
      echo "📍 Found .config in root, moving it to out/..."
      mv .config out/.config
    else
      echo "❌ Error: Configuration failed to generate!"
      exit 1
    fi
  fi

  # 4. 執行配置修改
  ./scripts/config --file out/.config -d KSU -d KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO

  # 5. 開始編譯
  make $BUILD_ARGS -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 6. 打包 ZIP
  if [ -f out/arch/arm64/boot/Image ]; then
    echo "Kernel compiled successfully! Packing..."
    find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb
    rm -rf anykernel/kernels/ && mkdir -p anykernel/kernels/
    cp out/arch/arm64/boot/Image anykernel/kernels/
    cp out/arch/arm64/boot/dtb anykernel/kernels/

    cd anykernel
    ZIP_NAME="NidhiKernel_${TARGET_DEVICE}_${mode}_Pure.zip"
    zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip
    mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
    cd ..

    # 清理空間
    rm -rf out/
  else
    echo "Error: Kernel Image not found for $mode!"
    exit 1
  fi
}

# 執行編譯流程
build_variant "AOSP"
build_variant "MIUI"

echo "Build Process Completed!"
