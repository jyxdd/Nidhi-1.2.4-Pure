Build.sh我加的對嗎？
#!/bin/bash
set -e

# ============================================
# 路徑配置 (雲端優化)
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

# 編譯參數
MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- Starting Build for $mode ---"
  
  # 清理舊緩存
  rm -rf out/
  
  # 1. 生成配置
  make $MAKE_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # 2. 強制關閉 KSU/SUSFS 配置 (以防萬一)
  ./scripts/config --file out/.config -d KSU -d KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO

  # 3. 開始編譯
  make $MAKE_ARGS -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 4. 打包 ZIP
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
  else
    echo "Error: Kernel Image not found for $mode!"
    exit 1
  fi
}

# 執行編譯流程
build_variant "AOSP"
build_variant "MIUI"

echo "Build Process Completed!"
