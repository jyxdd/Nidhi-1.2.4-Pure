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

# MAKE_ARGS 優先使用 yml 傳入的環境變量
[ -z "$MAKE_ARGS" ] && MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-"

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- Starting ThinLTO Build for $mode ---"
  
  # === 關鍵修正：手動創建 out 目錄，防止 scripts/config 找不到路徑 ===
  rm -rf out/
  mkdir -p out

  # 1. 生成配置
  make $MAKE_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # 確保 .config 真的在那裡
  if [ ! -f "out/.config" ]; then
    echo "❌ Error: out/.config not found! Checking build log..."
    exit 1
  fi

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

  # 3. 開始編譯
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

    # 打包完建議清理 out，給下一個 variant 留空間
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
