#!/bin/bash
set -e

# ... (路徑配置部分保持不變) ...

build_variant() {
  local mode=$1
  local log_file="$LOG_DIR/build_${TARGET_DEVICE}_${mode}.log"
  echo "--- 🚀 Starting Build for $TARGET_DEVICE ($mode) ---"
  
  # 建議：不要每次都刪除整個 out 目錄，除非你確定 AOSP/MIUI 代碼衝突
  # rm -rf out/ 
  mkdir -p out

  # 1. 生成初始配置
  make $MAKE_ARGS ${TARGET_DEVICE}_defconfig 2>&1 | tee -a "$log_file"
  
  # 2. 強制關閉 KSU/SUSFS 並設置純淨版本號 (確保 100% Pure)
  ./scripts/config --file out/.config -d CONFIG_KSU
  ./scripts/config --file out/.config -d CONFIG_KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure-${mode}"
  ./scripts/config --file out/.config -d CONFIG_LOCALVERSION_AUTO
  
  # === 關鍵補充：同步配置結構 ===
  make $MAKE_ARGS O=out olddefconfig 2>&1 | tee -a "$log_file"

  # 3. 開始編譯
  make $MAKE_ARGS -j$JOBS 2>&1 | tee -a "$log_file"
  
  # 4. 打包 ZIP
  # 檢查編譯出的 Image 是否存在
  if [ -f out/arch/arm64/boot/Image ]; then
    echo "✅ Kernel compiled successfully! Packing..."
    
    # 優化 DTB 抓取路徑
    find out/arch/arm64/boot/dts/vendor/qcom -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb || \
    find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > out/arch/arm64/boot/dtb

    # 清理 AnyKernel 臨時工作區 (防止重複打包)
    rm -rf anykernel/kernels/ anykernel/*.zip
    mkdir -p anykernel/kernels/
    
    cp out/arch/arm64/boot/Image anykernel/kernels/
    cp out/arch/arm64/boot/dtb anykernel/kernels/
    # 如果有 dtbo 也一併帶上
    [ -f out/arch/arm64/boot/dtbo.img ] && cp out/arch/arm64/boot/dtbo.img anykernel/kernels/

    cd anykernel
    # 加入時間戳，方便區分版本
    BUILD_DATE=$(date +%Y%m%d_%H%M)
    ZIP_NAME="Nidhi-Pure-${TARGET_DEVICE}-${mode}-${BUILD_DATE}.zip"
    
    # 執行打包，排除不必要的 git 殘餘
    zip -r9 "$ZIP_NAME" ./* -x ".git/*" ".gitignore" "out/*" "README.md"
    mv "$ZIP_NAME" "$ZIP_OUT_DIR/"
    cd ..
    
    echo "🎁 Package saved: $ZIP_NAME"
  else
    echo "❌ Error: Kernel Image not found for $mode!"
    exit 1
  fi
}

# 執行編譯流程 (順序建議：先編譯產量大的，或者你最常用的)
build_variant "AOSP"
# 如果 MIUI 的 defconfig 不同，請確保倉庫裡有對應的檔案
# build_variant "MIUI" 

echo "🎉 All Build Processes Completed!"
