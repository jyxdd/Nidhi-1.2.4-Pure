build_variant() {
  local mode=$1
  # 每次編譯前清空 out，否則 ThinLTO 會撐爆硬碟
  rm -rf out/
  mkdir -p out

  echo "--- 🚀 Starting ThinLTO Build for $TARGET_DEVICE ($mode) ---"

  # 1. 生成配置
  make $MAKE_ARGS O=out ${TARGET_DEVICE}_defconfig
  
  # 2. 注入 ThinLTO 與 Pure 設置
  ./scripts/config --file out/.config -e CONFIG_LTO_CLANG -d CONFIG_LTO_NONE -e CONFIG_THINLTO
  ./scripts/config --file out/.config -d CONFIG_KSU -d CONFIG_KSU_SUSFS
  ./scripts/config --file out/.config --set-str CONFIG_LOCALVERSION "-Nidhi-Pure-LTO-${mode}"
  
  make $MAKE_ARGS O=out olddefconfig

  # 3. 編譯
  make $MAKE_ARGS O=out -j$(nproc)
  
  # 4. 關鍵：打包前清理，騰出空間給 ZIP
  if [ -f out/arch/arm64/boot/Image ]; then
    echo "✅ Kernel compiled! Freeing space..."
    # 刪除佔用好幾 GB 的中間件，只保留 Image 和 dtb
    find out -name "*.o" -type f -delete
    find out -name "*.bc" -type f -delete

    # 進入 AnyKernel3 打包
    cd anykernel
    rm -rf kernels/*.zip *.zip # 清理舊包
    mkdir -p kernels/
    cp ../out/arch/arm64/boot/Image kernels/
    # 這裡確保你的 dtb 抓取邏輯正確
    
    # 使用固定、好找的名字
    local ZIP_NAME="Nidhi-Pure-LTO-${mode}-${TARGET_DEVICE}.zip"
    zip -r9 "$ZIP_NAME" ./* -x .git .gitignore
    
    # 確保移動到 yml 能抓到的位置 (源碼根目錄/out/device)
    mkdir -p "../out/${TARGET_DEVICE}"
    mv "$ZIP_NAME" "../out/${TARGET_DEVICE}/"
    
    echo "✅ ZIP created: out/${TARGET_DEVICE}/$ZIP_NAME"
    cd ..
  else
    echo "❌ Build failed, Image not found!"
    exit 1
  fi
}
