# Kernel Build Script - v2.0

A comprehensive kernel build script with logging, verbose mode, custom job control, and dirty build support for AOSP/MIUI ROMs.

---

## New Features

### 1. **Automatic Build Logging**
- All build output automatically logged to timestamped files
- Build stops on first error with helpful message
- Easy debugging with complete build history
- Removed `--debug` flag (replaced by automatic logging)

### 2. **Verbose Mode (-V, --verbose)**
- Sets `V=1` for detailed make output
- See every command being executed
- Easier to track build progress

### 3. **Custom Job Control (-J, --jobs)**
- Set parallel jobs: `-J8`, `--jobs 12`
- Range: 1 to $(nproc)
- Auto-limits if value exceeds CPU cores
- Intelligent warnings when limited

### 4. **Dirty Build (-D, --dirty)**
- Skip `rm -rf out/` for faster iterative builds
- Perfect for testing small changes
- Saves 1-2 minutes per build

### 5. **Help System (-H, --help)**
- Comprehensive usage information
- Examples for common scenarios
- Always up-to-date documentation

---

## Prerequisites

### 1. Prepare Build Environment

You need `git`, `make`, `curl`, `bison`, `flex`, `zip`, etc.

- **Debian/Ubuntu:**
  ```bash
  sudo apt install build-essential git curl wget bison flex zip bc cpio libssl-dev ccache tar
  ```
  You also need `python` (not just `python3`):
  ```bash
  sudo apt install python-is-python3
  ```

- **RHEL/RPM-based OS:**
  ```bash
  sudo yum groupinstall 'Development Tools'
  sudo yum install wget bc openssl-devel ccache tar
  ```

  **Note:** `ccache` is enabled in `build.sh` (`$HOME/.cache/ccache_mikernel`). You may remove/modify it.

### 2. Download Toolchain

Download [ZyC-Clang v15](https://github.com/ZyCromerZ/Clang/releases/tag/15.0.7-20251111-release) toolchain:
```bash
mkdir zyc-clang
cd zyc-clang
wget https://github.com/ZyCromerZ/Clang/releases/download/15.0.7-20251111-release/Clang-15.0.7-20251111.tar.gz
tar -zxvf Clang-15.0.7-20251111.tar.gz
cd ..
```

---

## Usage

### Syntax
```bash
bash build.sh <device> [ksu] [aosp|miui] [OPTIONS]
```

### Arguments

| Argument | Required | Options | Default | Description |
|----------|----------|---------|---------|-------------|
| device | Yes | Device codename | - | Target device |
| ksu | No | `ksu` or empty | No KSU | Enable KernelSU+SUSFS |
| aosp\|miui | No | `aosp`, `miui`, empty | Both | ROM type |

### Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| --verbose | -V | Verbose build (V=1) | `-V` |
| --jobs <N> | -J<N> | Parallel jobs (1-nproc) | `-J8`, `--jobs 12` |
| --dirty | -D | Keep out/ directory | `-D` |
| --help | -H | Show help | `-H` |

---

## Examples

### Basic Builds
```bash
# Both ROMs, no KSU, default jobs
bash build.sh lmi

# Both ROMs with KSU
bash build.sh lmi ksu

# AOSP only
bash build.sh lmi ksu aosp

# MIUI only
bash build.sh lmi "" miui
```

### With Options
```bash
# Verbose mode
bash build.sh lmi -V
bash build.sh lmi --verbose

# Custom jobs
bash build.sh lmi -J8
bash build.sh lmi --jobs 12

# Dirty build (fast iterative)
bash build.sh lmi -D
bash build.sh lmi --dirty

# Combined options
bash build.sh lmi ksu -V -J8 -D
```

### Advanced Examples
```bash
# AOSP, KSU, verbose, 16 jobs
bash build.sh lmi ksu aosp -V -J16

# MIUI, dirty, 4 jobs (low-power mode)
bash build.sh lmi "" miui -D -J4

# Full release (both ROMs, clean, max speed)
bash build.sh lmi ksu -J$(nproc)

# Development mode (dirty, verbose, limited jobs)
bash build.sh lmi -D -V -J4
```

---

## Build Logging

### Automatic Logging
Every build automatically creates a log file:
```
build_20240127_143022.log
build_20240127_150315.log
build_20240127_163045.log
```

### What's Logged
- Build configuration
- All make output
- Kernel config changes
- DTS patching details
- Error messages
- Timestamps

### On Build Failure
```
======================================
  Build Failed!
======================================
Error occurred during: Compiling kernel
Please check the log file for details: build_20240127_143022.log
```

### Viewing Logs
```bash
# View latest log
tail -f build_*.log

# Search for errors
grep -i error build_20240127_143022.log

# View last 100 lines
tail -n 100 build_20240127_143022.log
```

---

## Feature Details

### 1. Automatic Logging

**How it works:**
- Creates timestamped log file up a directory in logs: `build_YYYYMMDD_HHMMSS.log`
- All stdout/stderr captured with `tee`
- Stops on first make error
- Clear error messages with log file reference

**Example output:**
```bash
$ bash build.sh lmi ksu
Build log will be saved to: build_20240127_143022.log
======================================
  Build Configuration
======================================
TARGET_DEVICE: lmi
KernelSU: Enabled (SUSFS)
...
[*] Compiling kernel (this may take a while)
  CC      drivers/usb/core/hub.o
  CC      drivers/usb/core/hcd.o
  ...
[+] Compiling kernel completed
```

**On error:**
```bash
======================================
  Build Failed!
======================================
Error occurred during: Compiling kernel
Please check the log file for details: build_20240127_143022.log
```

### 2. Verbose Mode (-V, --verbose)

**What it does:**
- Adds `V=1` to make command
- Shows full command lines
- Reveals exactly what's being compiled

**Normal output:**
```
  CC      drivers/usb/core/hub.o
  CC      drivers/usb/core/hcd.o
```

**Verbose output:**
```
clang -Wp,-MD,drivers/usb/core/.hub.o.d -nostdinc -isystem /home/user/zyc-clang/bin/../lib/clang/18.0.0/include -I./arch/arm64/include -I./arch/arm64/include/generated ...
```

**Usage:**
```bash
bash build.sh lmi -V
bash build.sh lmi --verbose
bash build.sh lmi ksu aosp -V
```

### 3. Custom Job Control (-J, --jobs)

**Syntax:**
```bash
-J8          # Short form
--jobs 12    # Long form
```

**Auto-limiting:**
```bash
# On 8-core system
$ bash build.sh lmi -J16
Warning: Job count 16 exceeds available cores (8)
Limiting to 8 jobs
```

**Examples:**
```bash
# Use 4 jobs (low power)
bash build.sh lmi -J4

# Use 8 jobs (balanced)
bash build.sh lmi -J8

# Use all cores
bash build.sh lmi -J$(nproc)

# Long form
bash build.sh lmi --jobs 12
```

**Why custom jobs?**
- **Low jobs (-J4)**: Less CPU/memory usage, system stays responsive
- **Medium jobs (-J8)**: Balanced performance
- **High jobs (-J16+)**: Maximum speed, uses all resources

### 4. Dirty Build (-D, --dirty)

**What it does:**
- Skips `rm -rf out/`
- Keeps compiled objects
- Rebuilds only changed files

**Time savings:**
```
Clean build:  15 minutes
Dirty build:  2-3 minutes (small changes)
```

**When to use:**
```bash
# Iterative development
bash build.sh lmi -D          # First change
bash build.sh lmi -D          # Second change
bash build.sh lmi -D          # Third change

# Clean build for release
bash build.sh lmi             # Full rebuild
```

**Warning:**
```
Dirty build enabled - keeping out/ directory
```

**Best practices:**
- Use `-D` during development
- Skip `-D` for release builds
- Clean build after major changes

### 5. Help System (-H, --help)

**Usage:**
```bash
bash build.sh -H
bash build.sh --help
```

**Shows:**
- Complete syntax
- All arguments and options
- Usage examples
- Important notes

---

## Build Modes Comparison

| Mode | Command | Use Case | Speed | Output |
|------|---------|----------|-------|--------|
| **Standard** | `bash build.sh lmi` | Release builds | Normal | Quiet |
| **Verbose** | `bash build.sh lmi -V` | Debugging | Normal | Detailed |
| **Fast** | `bash build.sh lmi -J16` | Quick builds | Fast | Quiet |
| **Dirty** | `bash build.sh lmi -D` | Development | Very Fast | Quiet |
| **Debug** | `bash build.sh lmi -V -J4 -D` | Troubleshooting | Slow | Detailed |
| **Production** | `bash build.sh lmi ksu -J$(nproc)` | Final release | Fast | Quiet |

---

## Workflows

### Development Workflow
```bash
# First build (clean)
bash build.sh lmi ksu aosp

# Make code changes...

# Quick rebuild (dirty)
bash build.sh lmi ksu aosp -D

# More changes...

# Quick rebuild again
bash build.sh lmi ksu aosp -D

# Final clean build for testing
bash build.sh lmi ksu aosp
```

### Debugging Workflow
```bash
# Build fails?
bash build.sh lmi -V -J4

# Check log
tail -f build_20240127_143022.log

# Fix error, rebuild
bash build.sh lmi -V -J4 -D

# Still failing? Check log again
grep -i error build_20240127_143022.log
```

### Release Workflow
```bash
# Clean, full build, all cores
bash build.sh lmi ksu -J$(nproc)

# Verify both ZIPs created
ls -lh out/NidhiKernel_*

# Test builds work
adb shell uname -r
# Expected: 5.10.0-Nidhi-1.2.3
```

### Multi-Device Workflow
```bash
#!/bin/bash
for device in lmi umi alioth; do
  echo "Building for $device..."
  bash build.sh $device ksu -J$(nproc)
done
```

---

## Output Structure

### Files Created
```
.
├── build_20240127_143022.log                    # Build log
├── out/
│   ├── lmi/                                     # Device-specific directory
│   │   ├── NidhiKernel_1.2.3_AOSP_lmi_KSUN-SUSFS_20240127_143022.zip
│   │   └── NidhiKernel_1.2.3_MIUI_lmi_KSUN-SUSFS_20240127_143530.zip
│   ├── umi/                                     # Another device
│   │   ├── NidhiKernel_1.2.3_AOSP_umi_KSUN-SUSFS_20240127_144012.zip
│   │   └── NidhiKernel_1.2.3_MIUI_umi_KSUN-SUSFS_20240127_144522.zip
│   └── arch/arm64/boot/
│       ├── Image
│       ├── dtb
│       └── dtbo.img
└── anykernel/
    └── kernels/
        ├── Image
        └── dtb
```

### Device-Organized Output

**New Feature:** ZIPs are now organized by device!

**Structure:**
```
out/
├── lmi/
│   ├── NidhiKernel_1.2.3_AOSP_lmi_*.zip
│   └── NidhiKernel_1.2.3_MIUI_lmi_*.zip
├── umi/
│   ├── NidhiKernel_1.2.3_AOSP_umi_*.zip
│   └── NidhiKernel_1.2.3_MIUI_umi_*.zip
└── alioth/
    ├── NidhiKernel_1.2.3_AOSP_alioth_*.zip
    └── NidhiKernel_1.2.3_MIUI_alioth_*.zip
```

**Benefits:**
- Easy to find builds for specific device
- Clean organization for multi-device builds
- No mixed ZIPs in one directory
- Better for release management

**Finding builds:**
```bash
# All builds for lmi
ls out/lmi/

# All AOSP builds
find out/ -name "*AOSP*.zip"

# All KSU builds
find out/ -name "*KSU*.zip"

# Latest build for device
ls -lt out/alioth/ | head -n 2
```

### Log File Content
```
Build started at Mon Jan 27 14:30:22 IST 2024
======================================

Build Configuration:
  TARGET_DEVICE: lmi
  KernelSU: Enabled (SUSFS)
  Verbose Mode: No
  Jobs: 16
  Dirty Build: No
  Build AOSP: Yes
  Build MIUI: Yes

=====================================
AOSP BUILD
=====================================
Cleaned out/ directory
======================================
Generating defconfig
======================================
[make output...]
```

---

## Tips & Tricks

### 1. Speed Optimization
```bash
# Fastest build (all cores, dirty)
bash build.sh lmi -D -J$(nproc)

# Balanced (leave cores for system)
bash build.sh lmi -J$(($(nproc) - 2))
```

### 2. Low Memory Systems
```bash
# Use fewer jobs to avoid OOM
bash build.sh lmi -J4
```

### 3. Verbose Debugging
```bash
# See everything
bash build.sh lmi -V -J1 2>&1 | tee manual.log
```

### 4. Clean After Dirty Builds
```bash
# After many dirty builds, do clean build
rm -rf out/
bash build.sh lmi
```

### 5. Check Logs for Warnings
```bash
# Find all warnings
grep -i warning build_*.log

# Find specific errors
grep -i "undefined reference" build_*.log
```

---

## Important Notes

### Build Log Files
- **Automatically created** for every build
- **Not cleaned** automatically - manage manually
- **Useful for debugging** - keep recent logs
- **Can be large** - compress or delete old logs

### Dirty Builds
- May cause issues after major changes
- Clean build recommended for releases
- Great for iterative development
- Saves significant time

### Job Count
- Higher jobs = More CPU/RAM usage
- Lower jobs = More stable on low-spec systems
- Optimal: $(nproc) or $(nproc) - 2

### Verbose Mode
- Helpful for debugging
- Makes logs much larger
- Slightly slower due to output
- Use when troubleshooting

---

## Comparison with Previous Version

| Feature | Old | New |
|---------|-----|-----|
| Debug Mode | `--debug` flag | Removed |
| Logging | None | Automatic |
| Verbose | Not available | `-V, --verbose` |
| Job Control | Fixed $(nproc) | `-J<N>, --jobs <N>` |
| Dirty Build | Not available | `-D, --dirty` |
| Help | Basic | Comprehensive `-H` |
| Error Handling | Exit on error | Stop + log file message |
| Build Tracking | None | Timestamped logs |

---

## Command Reference

### Quick Reference

| What you want | Command |
|---------------|---------|
| Normal build | `bash build.sh lmi` |
| With KSU | `bash build.sh lmi ksu` |
| Only AOSP | `bash build.sh lmi ksu aosp` |
| Only MIUI | `bash build.sh lmi ksu miui` |
| Verbose | `bash build.sh lmi -V` |
| 8 jobs | `bash build.sh lmi -J8` |
| Dirty build | `bash build.sh lmi -D` |
| All options | `bash build.sh lmi ksu aosp -V -J8 -D` |
| Help | `bash build.sh -H` |

### Option Combinations

```bash
# Development (fast, verbose, dirty)
bash build.sh lmi -V -D -J8

# Production (clean, max speed)
bash build.sh lmi ksu -J$(nproc)

# Debugging (verbose, slow, dirty)
bash build.sh lmi -V -J1 -D

# Low power (few jobs, dirty)
bash build.sh lmi -D -J4
```

---

## Troubleshooting

### Build Fails Immediately
**Check:** Log file for specific error
```bash
tail -n 50 build_20240127_143022.log
```

### Out of Memory
**Solution:** Reduce jobs
```bash
bash build.sh lmi -J4
```

### Dirty Build Issues
**Solution:** Clean build
```bash
rm -rf out/
bash build.sh lmi
```

### Can't Find Error in Log
**Solution:** Search log file
```bash
grep -i "error:" build_*.log
grep -i "failed" build_*.log
```

### Job Count Warning
**This is normal** if you exceed nproc
```
Warning: Job count 16 exceeds available cores (8)
Limiting to 8 jobs
```

---

## What's Next?

After successful build:
```bash
# Check outputs (now organized by device)
ls -lh out/lmi/
ls -lh out/umi/
ls -lh out/alioth/

# Or see all builds
find out/ -name "*.zip"

# Flash via recovery (TWRP)
# or

# Boot via fastboot
fastboot boot out/arch/arm64/boot/Image

# Verify on device
adb shell uname -r
# Expected: 5.10.0-Nidhi-1.2.3
```

---


