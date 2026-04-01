#!/bin/bash
set -e

TARGET_DEVICE=$1
LOG_DIR="build_logs"
ZIP_OUT_DIR="out/$TARGET_DEVICE"
mkdir -p "$LOG_DIR" "$ZIP_OUT_DIR"

JOBS=$(nproc)

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- 🚀 Starting ThinLTO Build for $TARGET_DEVICE ($mode) ---"
  
  mkdir -p out

  # 1. 生成初始配置
  make $MAKE_ARGS O=out ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # === ThinLTO 核心注入 ===
  echo "🔧 Hard-locking ThinLTO Optimization..."
  ./scripts/config --file out/.config -e CONFIG_LTO_CLANG
  ./scripts/config --file out/.config -d CONFIG_LTO_NONE
  ./scripts/config --file out/.config -e CONFIG_THINLTO
  
  # 2. 強制關閉 KSU/SUSFS 並設置純淨版本號
  ./scripts/config --file out/.config -d CONFIG_KSU
  ./scripts/config --file out/.config -d CONFIG_KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure-LTO-${mode}"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO
  
  # === 關鍵：同步配置結構 ===
  make $MAKE_ARGS O=out olddefconfig 2>&1 | tee -a "$log_file"

  # 3. 開始編譯
  make $MAKE_ARGS O=out -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 4. 打包邏輯 (省略重複的 Image 檢查與 zip 指令，保持你原本的打包邏輯即可)
  if [ -f out/arch/arm64/boot/Image ]; then
    echo "✅ Kernel compiled! Packing..."
    # (此處接你原本 build.sh 裡的 AnyKernel3 打包代碼)
    # 確保使用的 ZIP 名稱包含 $mode 和 LTO 字樣
  fi
}

# 執行自動雙產
build_variant "AOSP"
build_variant "MIUI"

echo "🎉 All ThinLTO Builds Completed!"
