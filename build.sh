#!/bin/bash

# Some logics of this script are copied from [scripts/build_kernel]. Thanks to UtsavBalar1231.

# Ensure the script exits on error
set -e

TOOLCHAIN_PATH=$HOME/zyc-clang/bin
GIT_COMMIT_ID=$(git rev-parse --short=8 HEAD)
BUILD_SCRIPT_VERSION='2.0'
NIDHIKERNEL_VERSION_STR='1.2.5'

# ============================================
# Print Build Script & NidhiKernel Version
# ============================================
echo -e "${GREEN}Build Script Version: $BUILD_SCRIPT_VERSION${NC}"
echo -e "${GREEN}NidhiKernel Version: $NIDHIKERNEL_VERSION_STR${NC}"

# ============================================
# Argument Parsing
# ============================================
TARGET_DEVICE=""
KSU_ENABLE=0
KSU_ZIP_STR="NoKernelSU"
TARGET_SYSTEM=""
VERBOSE_MODE=0
DIRTY_BUILD=0
JOBS=$(nproc)
LOG_FILE=""
LTO_TYPE=""

# Colors for output
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
NC=$'\e[0m' # No Color

show_help() {
  cat << EOF
${GREEN}Enhanced Kernel Build Script${NC}

${BLUE}Usage:${NC}
  bash build.sh <device> [ksu] [aosp|miui] [OPTIONS]

${BLUE}Arguments:${NC}
  device          Device codename (required)
  ksu             Enable KernelSU with SUSFS (optional)
  aosp|miui       Build for specific ROM type (optional, default: both)

${BLUE}Options:${NC}
  -V, --verbose   Verbose build output (V=1)
  -J<N>, --jobs <N>
                  Number of parallel jobs (1-$(nproc), default: $(nproc))
  -D, --dirty     Dirty build (don't clean out/ directory)
  -L, --lto [type]
                  Enable Link Time Optimization (thin|full|none, default: thin)
  -H, --help      Show this help message

${BLUE}Examples:${NC}
  ${GREEN}# Basic builds${NC}
  bash build.sh lmi                    # Both ROMs, no KSU
  bash build.sh lmi ksu                # Both ROMs with KSU
  bash build.sh lmi ksu aosp           # AOSP only with KSU
  bash build.sh lmi "" miui            # MIUI only without KSU

  ${GREEN}# With options${NC}
  bash build.sh lmi -V                 # Verbose mode
  bash build.sh lmi -J8                # Use 8 jobs
  bash build.sh lmi --jobs 12          # Use 12 jobs
  bash build.sh lmi -D                 # Dirty build (keep out/)
  bash build.sh lmi ksu -V -J8 -D      # Verbose, 8 jobs, dirty build

  ${GREEN}# Combined examples${NC}
  bash build.sh lmi ksu aosp -V -J16   # AOSP, KSU, verbose, 16 jobs
  bash build.sh lmi "" miui -D -J4     # MIUI, dirty, 4 jobs

${BLUE}Notes:${NC}
  - Build logs are saved to: ../logs/build_YYYYMMDD_HHMMSS.log
  - If build fails, check the log file for details
  - Use -D/--dirty for faster iterative builds
  - Job count automatically limited to $(nproc) if exceeded

EOF
}

# Parse all arguments
positional_args=()
skip_next=0

for ((i=1; i<=$#; i++)); do
  if [ $skip_next -eq 1 ]; then
    skip_next=0
    continue
  fi
  
  arg="${!i}"
  case $arg in
    -H|--help)
      show_help
      exit 0
      ;;
    -V|--verbose)
      VERBOSE_MODE=1
      ;;
    -D|--dirty)
      DIRTY_BUILD=1
      ;;
    -J*)
      job_value="${arg:2}"
      if [[ "$job_value" =~ ^[0-9]+$ ]] && [ "$job_value" -gt 0 ]; then
        JOBS=$job_value
      else
        echo -e "${RED}Error: Invalid job count in '$arg'${NC}"
        exit 1
      fi
      ;;
    --jobs)
      next_index=$((i + 1))
      job_value="${!next_index}"
      if [[ "$job_value" =~ ^[0-9]+$ ]] && [ "$job_value" -gt 0 ]; then
        JOBS=$job_value
        skip_next=1
      else
        echo -e "${RED}Error: Invalid job count for --jobs${NC}"
        exit 1
      fi
      ;;
    -L|--lto)
      next_index=$((i + 1))
      lto_val="${!next_index}"
      if [[ -n "$lto_val" && ! "$lto_val" =~ ^- && ("$lto_val" == "thin" || "$lto_val" == "full" || "$lto_val" == "none") ]]; then
        LTO_TYPE="$lto_val"
        skip_next=1
      else
        LTO_TYPE="thin"
      fi
      ;;
    *)
      positional_args+=("$arg")
      ;;
  esac
done

# Validate and limit job count
max_jobs=$(nproc)
if [ "$JOBS" -gt "$max_jobs" ]; then
  echo -e "${YELLOW}Warning: Job count $JOBS exceeds available cores ($max_jobs)${NC}"
  echo -e "${YELLOW}Limiting to $max_jobs jobs${NC}"
  JOBS=$max_jobs
fi

# Set positional arguments
set -- "${positional_args[@]}"

TARGET_DEVICE=$1
KSU_ARG=$2
TARGET_SYSTEM=$3

# ============================================
# Usage/Help
# ============================================
if [ -z "$1" ]; then
  echo -e "${RED}Error: No argument provided, please specify a target device.${NC}"
  echo ""
  show_help
  exit 1
fi

# ============================================
# Validation
# ============================================
if [ ! -d $TOOLCHAIN_PATH ]; then
  echo -e "${RED}TOOLCHAIN_PATH [$TOOLCHAIN_PATH] does not exist.${NC}"
  echo "Please ensure the toolchain is there, or change TOOLCHAIN_PATH in the script to your toolchain path."
  exit 1
fi

echo "TOOLCHAIN_PATH: [$TOOLCHAIN_PATH]"
export PATH="$TOOLCHAIN_PATH:$PATH"

if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
  echo -e "${RED}[aarch64-linux-gnu-ld] does not exist, please check your environment.${NC}"
  exit 1
fi

if ! command -v arm-linux-gnueabi-ld >/dev/null 2>&1; then
  echo -e "${RED}[arm-linux-gnueabi-ld] does not exist, please check your environment.${NC}"
  exit 1
fi

if ! command -v clang >/dev/null 2>&1; then
  echo -e "${RED}[clang] does not exist, please check your environment.${NC}"
  exit 1
fi

if [ ! -f "arch/arm64/configs/${TARGET_DEVICE}_defconfig" ]; then
  echo -e "${RED}No target device [${TARGET_DEVICE}] found.${NC}"
  echo "Available defconfigs, please choose one target from below:"
  ls arch/arm64/configs/*_defconfig
  exit 1
fi

# ============================================
# Setup Logging
# ============================================
mkdir -p ../logs
LOG_FILE="$(pwd)/../logs/build_$(date +'%Y%m%d_%H%M%S').log"
echo -e "${BLUE}Build log will be saved to: ${LOG_FILE}${NC}"
echo "Build started at $(date)" > "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# ============================================
# Configuration
# ============================================
# Enable ccache for speed up compiling
export KBUILD_BUILD_USER="Smarajit"
export KBUILD_BUILD_HOST="Local"
export CCACHE_DIR="$HOME/.cache/ccache_mikernel"
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

# Base MAKE_ARGS
MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"

# Add V=1 if verbose mode
if [ $VERBOSE_MODE -eq 1 ]; then
  MAKE_ARGS="$MAKE_ARGS V=1"
fi

# Apply LTO-specific toolchain flags if LTO is enabled
if [ -n "$LTO_TYPE" ]; then
  # LTO requires LLD linker and LLVM tools
  # We use explicit tool definitions instead of LLVM=1 to potentially avoid bootloop issues with IAS
  MAKE_ARGS="$MAKE_ARGS LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip"
fi

# Check clang is existing.
echo "[clang --version]:"
clang --version

# Parse KSU argument
if [ "$KSU_ARG" == "ksu" ]; then
  KSU_ENABLE=1
  KSU_ZIP_STR=KSUN-SUSFS
else
  KSU_ENABLE=0
  KSU_ZIP_STR=NoKernelSU
fi

# Determine which ROMs to build
BUILD_AOSP=0
BUILD_MIUI=0

if [ -z "$TARGET_SYSTEM" ]; then
  # No third argument - build both
  BUILD_AOSP=1
  BUILD_MIUI=1
elif [ "$TARGET_SYSTEM" == "aosp" ]; then
  BUILD_AOSP=1
elif [ "$TARGET_SYSTEM" == "miui" ]; then
  BUILD_MIUI=1
else
  echo -e "${RED}Error: Invalid ROM type '$TARGET_SYSTEM'. Use 'aosp' or 'miui'.${NC}"
  exit 1
fi

# ============================================
# Display Configuration
# ============================================
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Build Configuration${NC}"
echo -e "${GREEN}======================================${NC}"
echo "TARGET_DEVICE: $TARGET_DEVICE"
echo "KernelSU: $([ $KSU_ENABLE -eq 1 ] && echo "Enabled (SUSFS)" || echo "Disabled")"
echo "Verbose Mode: $([ $VERBOSE_MODE -eq 1 ] && echo "Yes (V=1)" || echo "No")"
echo "Jobs: -j$JOBS"
echo "Dirty Build: $([ $DIRTY_BUILD -eq 1 ] && echo "Yes (keep out/)" || echo "No (clean build)")"
echo "Build AOSP: $([ $BUILD_AOSP -eq 1 ] && echo "Yes" || echo "No")"
echo "Build MIUI: $([ $BUILD_MIUI -eq 1 ] && echo "Yes" || echo "No")"
echo "LTO Mode: ${LTO_TYPE:-Default}"
echo "Log File: $LOG_FILE"
echo -e "${GREEN}======================================${NC}"
echo ""

# Log configuration
{
  echo "Build Configuration:"
  echo "  TARGET_DEVICE: $TARGET_DEVICE"
  echo "  KernelSU: $([ $KSU_ENABLE -eq 1 ] && echo "Enabled (SUSFS)" || echo "Disabled")"
  echo "  Verbose Mode: $([ $VERBOSE_MODE -eq 1 ] && echo "Yes" || echo "No")"
  echo "  Jobs: $JOBS"
  echo "  Dirty Build: $([ $DIRTY_BUILD -eq 1 ] && echo "Yes" || echo "No")"
  echo "  Build AOSP: $([ $BUILD_AOSP -eq 1 ] && echo "Yes" || echo "No")"
  echo "  Build MIUI: $([ $BUILD_MIUI -eq 1 ] && echo "Yes" || echo "No")"
  echo "  LTO Mode: ${LTO_TYPE:-Default}"
  echo ""
} >> "$LOG_FILE"

if [ $KSU_ENABLE -eq 1 ]; then
  echo "KSU is enabled with SUSFS support"
  #curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash -s builtin
else
  echo "KSU is disabled"
fi

# ============================================
# Helper function for running make with logging
# ============================================
run_make() {
  local description="$1"
  echo -e "${BLUE}[*] $description${NC}"
  echo "======================================" >> "$LOG_FILE"
  echo "$description" >> "$LOG_FILE"
  echo "======================================" >> "$LOG_FILE"
  
  # Run make and capture output
  if ! make "${@:2}" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}  Build Failed!${NC}"
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}Error occurred during: $description${NC}"
    echo -e "${YELLOW}Please check the log file for details: ${LOG_FILE}${NC}"
    echo ""
    echo "Build failed at: $(date)" >> "$LOG_FILE"
    exit 1
  fi
  
  echo -e "${GREEN}[✓] $description completed${NC}"
  echo "" >> "$LOG_FILE"
}

# ============================================
# Function: Build for AOSP
# ============================================
Build_AOSP() {
  echo ""
  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}  Building for AOSP${NC}"
  echo -e "${GREEN}======================================${NC}"
  
  echo "" >> "$LOG_FILE"
  echo "=====================================" >> "$LOG_FILE"
  echo "AOSP BUILD" >> "$LOG_FILE"
  echo "=====================================" >> "$LOG_FILE"

  if [ $DIRTY_BUILD -eq 0 ]; then
    echo "Cleaning out/ directory..."
    rm -rf out/
    echo "Cleaned out/ directory" >> "$LOG_FILE"
  else
    echo -e "${YELLOW}Dirty build enabled - keeping out/ directory${NC}"
    echo "Dirty build - kept out/ directory" >> "$LOG_FILE"
  fi

  run_make "Generating defconfig" $MAKE_ARGS ${TARGET_DEVICE}_defconfig

  if [ $KSU_ENABLE -eq 1 ]; then
      scripts/config --file out/.config \
      -e KSU \
      -e KSU_SUSFS \
      -e KSU_SUSFS_SUS_PATH \
      -e KSU_SUSFS_SUS_MOUNT \
      -e KSU_SUSFS_SUS_KSTAT \
      -e KSU_SUSFS_SPOOF_UNAME \
      -e KSU_SUSFS_ENABLE_LOG \
      -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
      -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
      -e KSU_SUSFS_OPEN_REDIRECT \
      -e KSU_SUSFS_SUS_MAP \
      -e THREAD_INFO_IN_TASK 
      echo "KSU configs enabled" >> "$LOG_FILE"
  else
      scripts/config --file out/.config -d KSU
      echo "KSU disabled" >> "$LOG_FILE"
  fi

  scripts/config --file out/.config \
    -e OVERLAY_FS \
    -e CONFIG_TMPFS_XATTR \
    -e CONFIG_KALLSYMS \
    -e CONFIG_KALLSYMS_ALL \
    -d CONFIG_LOCALVERSION_AUTO \
    -d CFI_CLANG \
    --set-str CONFIG_LOCALVERSION "-Nidhi-${NIDHIKERNEL_VERSION_STR}"
  
  echo "AOSP-specific configs applied" >> "$LOG_FILE"

  # Apply LTO configuration if specified
  if [ -n "$LTO_TYPE" ]; then
    echo "Applying LTO configuration: $LTO_TYPE" >> "$LOG_FILE"
    if [ "$LTO_TYPE" == "thin" ]; then
        scripts/config --file out/.config \
            -e LTO_CLANG \
            -e LTO_CLANG_THIN \
            -e THINLTO \
            -d LTO_CLANG_FULL \
            -d LTO_NONE
    elif [ "$LTO_TYPE" == "full" ]; then
        scripts/config --file out/.config \
            -e LTO_CLANG \
            -d LTO_CLANG_THIN \
            -d THINLTO \
            -e LTO_CLANG_FULL \
            -d LTO_NONE
    elif [ "$LTO_TYPE" == "none" ]; then
        scripts/config --file out/.config \
            -d LTO_CLANG \
            -d LTO_CLANG_THIN \
            -d LTO_CLANG_FULL \
            -e LTO_NONE
    fi
  fi

  run_make "Compiling kernel (this may take a while)" $MAKE_ARGS -j$JOBS

  if [ -f "out/arch/arm64/boot/Image" ]; then
      echo -e "${GREEN}[✓] Kernel Image generated successfully${NC}"
      echo "Kernel Image generated successfully" >> "$LOG_FILE"
  else
      echo -e "${RED}[✗] Kernel Image not found after build${NC}"
      echo -e "${YELLOW}Check log file: ${LOG_FILE}${NC}"
      echo "ERROR: Kernel Image not found" >> "$LOG_FILE"
      exit 1
  fi

  echo "Generating DTB..."
  find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
  echo "DTB generated" >> "$LOG_FILE"

  rm -rf anykernel/kernels/
  mkdir -p anykernel/kernels/

  cp out/arch/arm64/boot/Image anykernel/kernels/
  cp out/arch/arm64/boot/dtb anykernel/kernels/

  cd anykernel

  ZIP_FILENAME=NidhiKernel_${NIDHIKERNEL_VERSION_STR}_AOSP_${TARGET_DEVICE}_${KSU_ZIP_STR}_$(date +'%Y%m%d_%H%M%S').zip

  echo "Creating flashable ZIP..."
  zip -r9 $ZIP_FILENAME ./* -x .git .gitignore out/ ./*.zip >> "$LOG_FILE" 2>&1

  # Create device-specific output directory
  DEVICE_OUT_DIR="../../out/${TARGET_DEVICE}"
  mkdir -p "$DEVICE_OUT_DIR"
  
  mv $ZIP_FILENAME "$DEVICE_OUT_DIR/"

  cd ..

  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}AOSP Build Complete!${NC}"
  echo -e "${GREEN}======================================${NC}"
  echo "Output: out/${TARGET_DEVICE}/$ZIP_FILENAME"
  echo ""
  
  echo "AOSP build completed successfully" >> "$LOG_FILE"
  echo "Output ZIP: ${TARGET_DEVICE}/$ZIP_FILENAME" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# ============================================
# Function: Build for MIUI
# ============================================
Build_MIUI() {
  echo ""
  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}  Building for MIUI${NC}"
  echo -e "${GREEN}======================================${NC}"
  
  echo "" >> "$LOG_FILE"
  echo "=====================================" >> "$LOG_FILE"
  echo "MIUI BUILD" >> "$LOG_FILE"
  echo "=====================================" >> "$LOG_FILE"

  if [ $DIRTY_BUILD -eq 0 ]; then
    echo "Cleaning out/ directory..."
    rm -rf out/
    echo "Cleaned out/ directory" >> "$LOG_FILE"
  else
    echo -e "${YELLOW}Dirty build enabled - keeping out/ directory${NC}"
    echo "Dirty build - kept out/ directory" >> "$LOG_FILE"
  fi

  dts_source=arch/arm64/boot/dts/vendor/qcom

  # Backup dts
  echo "Backing up device tree files..."
  cp -a ${dts_source} .dts.bak
  echo "DTS backed up" >> "$LOG_FILE"

  echo "Applying MIUI-specific DTS patches..."
  # Correct panel dimensions on MIUI builds
  sed -i 's/<154>/<1537>/g' ${dts_source}/dsi-panel-j1s*
  sed -i 's/<154>/<1537>/g' ${dts_source}/dsi-panel-j2*
  sed -i 's/<155>/<1544>/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
  sed -i 's/<155>/<1545>/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
  sed -i 's/<155>/<1546>/g' ${dts_source}/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
  sed -i 's/<155>/<1546>/g' ${dts_source}/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
  sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
  sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
  sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
  sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
  sed -i 's/<71>/<710>/g' ${dts_source}/dsi-panel-j1s*
  sed -i 's/<71>/<710>/g' ${dts_source}/dsi-panel-j2*

  # Enable back mi smartfps while disabling qsync min refresh-rate
  sed -i 's/\/\/ mi,mdss-dsi-pan-enable-smart-fps/mi,mdss-dsi-pan-enable-smart-fps/g' ${dts_source}/dsi-panel*
  sed -i 's/\/\/ mi,mdss-dsi-smart-fps-max_framerate/mi,mdss-dsi-smart-fps-max_framerate/g' ${dts_source}/dsi-panel*
  sed -i 's/\/\/ qcom,mdss-dsi-pan-enable-smart-fps/qcom,mdss-dsi-pan-enable-smart-fps/g' ${dts_source}/dsi-panel*
  sed -i 's/qcom,mdss-dsi-qsync-min-refresh-rate/\/\/qcom,mdss-dsi-qsync-min-refresh-rate/g' ${dts_source}/dsi-panel*

  # Enable back refresh rates supported on MIUI
  sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-36-02-0c-dsc-video.dtsi
  sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-37-02-0a-dsc-video.dtsi
  sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-37-02-0b-dsc-video.dtsi
  sed -i 's/144 120 90 60/144 120 90 60 50 48 30/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi

  # Enable back brightness control from dtsi
  sed -i 's/\/\/39 00 00 00 00 00 03 51 03 FF/39 00 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 03 51 0D FF/39 00 00 00 00 00 03 51 0D FF/g' ${dts_source}/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' ${dts_source}/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' ${dts_source}/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 01 00 03 51 03 FF/39 01 00 00 01 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
  sed -i 's/\/\/39 01 00 00 11 00 03 51 03 FF/39 01 00 00 11 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
  
  echo "MIUI DTS patches applied" >> "$LOG_FILE"

  run_make "Generating defconfig" $MAKE_ARGS ${TARGET_DEVICE}_defconfig

  if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config \
      -e KSU \
      -e KSU_SUSFS \
      -e KSU_SUSFS_SUS_PATH \
      -e KSU_SUSFS_SUS_MOUNT \
      -e KSU_SUSFS_SUS_KSTAT \
      -e KSU_SUSFS_SPOOF_UNAME \
      -e KSU_SUSFS_ENABLE_LOG \
      -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
      -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
      -e KSU_SUSFS_OPEN_REDIRECT \
      -e KSU_SUSFS_SUS_MAP \
      -e THREAD_INFO_IN_TASK
    echo "KSU configs enabled" >> "$LOG_FILE"
  else
    scripts/config --file out/.config -d KSU
    echo "KSU disabled" >> "$LOG_FILE"
  fi

  scripts/config --file out/.config \
    --set-str STATIC_USERMODEHELPER_PATH /system/bin/micd \
    -e PERF_CRITICAL_RT_TASK \
    -e SF_BINDER \
    -e OVERLAY_FS \
    -e CONFIG_TMPFS_XATTR \
    -d DEBUG_FS \
    -e MIGT \
    -e MIGT_ENERGY_MODEL \
    -e MIHW \
    -e PACKAGE_RUNTIME_INFO \
    -e BINDER_OPT \
    -e KPERFEVENTS \
    -e MILLET \
    -e PERF_HUMANTASK \
    -d LTO_CLANG \
    -e SF_BINDER \
    -e XIAOMI_MIUI \
    -d MI_MEMORY_SYSFS \
    -e TASK_DELAY_ACCT \
    -e MIUI_ZRAM_MEMORY_TRACKING \
    -d CONFIG_MODULE_SIG_SHA512 \
    -d CONFIG_MODULE_SIG_HASH \
    -e MI_FRAGMENTION \
    -e PERF_HELPER \
    -e BOOTUP_RECLAIM \
    -e MI_RECLAIM \
    -e RTMM \
    -e CONFIG_KALLSYMS \
    -e CONFIG_KALLSYMS_ALL \
    -d CONFIG_LOCALVERSION_AUTO \
    -d CFI_CLANG \
    --set-str CONFIG_LOCALVERSION "-Nidhi-${NIDHIKERNEL_VERSION_STR}"
  
  echo "MIUI-specific configs applied" >> "$LOG_FILE"

  # Apply LTO configuration if specified
  if [ -n "$LTO_TYPE" ]; then
    echo "Applying LTO configuration: $LTO_TYPE" >> "$LOG_FILE"
    if [ "$LTO_TYPE" == "thin" ]; then
        scripts/config --file out/.config \
            -e LTO_CLANG \
            -e LTO_CLANG_THIN \
            -e THINLTO \
            -d LTO_CLANG_FULL \
            -d LTO_NONE
    elif [ "$LTO_TYPE" == "full" ]; then
        scripts/config --file out/.config \
            -e LTO_CLANG \
            -d LTO_CLANG_THIN \
            -d THINLTO \
            -e LTO_CLANG_FULL \
            -d LTO_NONE
    elif [ "$LTO_TYPE" == "none" ]; then
        scripts/config --file out/.config \
            -d LTO_CLANG \
            -d LTO_CLANG_THIN \
            -d LTO_CLANG_FULL \
            -e LTO_NONE
    fi
  fi

  run_make "Compiling kernel (this may take a while)" $MAKE_ARGS -j$JOBS

  if [ -f "out/arch/arm64/boot/Image" ]; then
    echo -e "${GREEN}[✓] Kernel Image generated successfully${NC}"
    echo "Kernel Image generated successfully" >> "$LOG_FILE"
  else
    echo -e "${RED}[✗] Kernel Image not found after build${NC}"
    echo -e "${YELLOW}Check log file: ${LOG_FILE}${NC}"
    echo "ERROR: Kernel Image not found" >> "$LOG_FILE"
    exit 1
  fi

  echo "Generating DTB..."
  find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
  echo "DTB generated" >> "$LOG_FILE"

  # Restore modified dts
  echo "Restoring device tree files..."
  rm -rf ${dts_source}
  mv .dts.bak ${dts_source}
  echo "DTS restored" >> "$LOG_FILE"

  rm -rf anykernel/kernels/
  mkdir -p anykernel/kernels/

  cp out/arch/arm64/boot/Image anykernel/kernels/
  cp out/arch/arm64/boot/dtb anykernel/kernels/

  cd anykernel

  ZIP_FILENAME=NidhiKernel_${NIDHIKERNEL_VERSION_STR}_MIUI_${TARGET_DEVICE}_${KSU_ZIP_STR}_$(date +'%Y%m%d_%H%M%S').zip

  echo "Creating flashable ZIP..."
  zip -r9 $ZIP_FILENAME ./* -x .git .gitignore out/ ./*.zip >> "$LOG_FILE" 2>&1

  # Create device-specific output directory
  DEVICE_OUT_DIR="../../out/${TARGET_DEVICE}"
  mkdir -p "$DEVICE_OUT_DIR"
  
  mv $ZIP_FILENAME "$DEVICE_OUT_DIR/"

  cd ..

  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}MIUI Build Complete!${NC}"
  echo -e "${GREEN}======================================${NC}"
  echo "Output: out/${TARGET_DEVICE}/$ZIP_FILENAME"
  echo ""
  
  echo "MIUI build completed successfully" >> "$LOG_FILE"
  echo "Output ZIP: ${TARGET_DEVICE}/$ZIP_FILENAME" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# ============================================
# Main Build Execution
# ============================================
if [ $BUILD_AOSP -eq 1 ]; then
  Build_AOSP
fi

if [ $BUILD_MIUI -eq 1 ]; then
  Build_MIUI
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  All Builds Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo "Check the out/ directory for flashable ZIPs"
echo "Each device has its own subdirectory: out/<device>/"
echo -e "${BLUE}Build log saved to: ../logs/${LOG_FILE}${NC}"
echo ""

echo "All builds completed successfully at $(date)" >> "$LOG_FILE"