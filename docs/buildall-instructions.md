# Kernel Build TUI Driver

A user-friendly ncurses-based interface for the kernel build script.

**Author:** kaixenber  
**Version:** 1.0

---

## Features

### Graphical Interface
- Ncurses TUI using `dialog`
- Easy navigation with arrow keys
- Clear visual feedback
- Progress tracking

### Multi-Device Support
- Select multiple devices simultaneously
- Sequential building with a single command
- Predefined device list with friendly names
- Option to show all available defconfigs

### Complete Build Control
- KernelSU enable/disable toggle
- ROM type selection (AOSP/MIUI/Both)
- LTO Mode selection (Thin/Full)
- Verbose mode toggle
- Dirty build support
- Custom job count configuration
- Build summary review before execution

### Known Device List
Pre-configured with popular Xiaomi devices:

| Code | Device Name |
|------|-------------|
| psyche | Xiaomi 12X |
| thyme | Xiaomi 10S |
| umi | Xiaomi 10 |
| munch | Redmi K40S / POCO F4 |
| lmi | Redmi K30 Pro / POCO F2 Pro |
| cmi | Xiaomi 10 Pro |
| cas | Xiaomi 10 Ultra |
| apollo | Xiaomi 10T / Redmi K30S Ultra |
| alioth | Xiaomi 11X / POCO F3 / Redmi K40 |
| elish | Xiaomi Pad 5 Pro |
| enuma | Xiaomi Pad 5 Pro 5G |
| dagu | Xiaomi Pad 5 Pro 12.4 |
| pipa | Xiaomi Pad 6 |

### Settings
- Toggle visual display of all defconfigs
- Change interface language (English/Bengali)
- About section with version information
- Script information display

---

## Requirements

### System Requirements
- Linux operating system (Ubuntu/Debian recommended)
- `dialog` package (automatically installs if missing)
- `build.sh` script located in the same directory

### Kernel Source
- Must be executed from the kernel root directory
- `arch/arm64/configs/` directory must exist
- Device defconfig files must be present

---

## Installation

### 1. Download Script
Place `build_tui.sh` in your kernel source root directory.

```bash
cd /path/to/kernel/source
# Copy build_tui.sh here
```

### 2. Make Executable
Ensure the script has execution permissions.

```bash
chmod +x build_tui.sh
```

### 3. Verify build.sh
Ensure `build.sh` is present in the same directory.

```bash
ls -l build.sh build_tui.sh
```

---

## Usage

### Starting the TUI
Execute the script from the terminal:

```bash
./build_tui.sh
```

### Navigation Rules
- **Arrow Keys**: Navigate up/down in menus
- **SPACE**: Select/deselect items in checklists
- **ENTER**: Confirm selection
- **ESC**: Cancel or return to previous menu
- **TAB**: Switch focus between buttons

---

## Build Process Overview

### Step 1: Select Devices
Select one or more devices from the list using the SPACE bar. Press ENTER to confirm.

### Step 2: KernelSU Selection
Choose whether to enable KernelSU with SUSFS support.

### Step 3: ROM Type Selection
Select the target ROM type:
- **Both AOSP and MIUI**: Generates two ZIP files per device.
- **AOSP only**: Generates one ZIP file per device.
- **MIUI only**: Generates one ZIP file per device.

### Step 4: LTO Selection
Select the Link Time Optimization mode:
- **Thin LTO (Default)**: Balanced performance and build time. Recommended.
- **Full LTO**: Maximum performance, but **RISKY**. May cause bootloops (e.g., stuck at Mi logo) on some devices. Use with caution.
- **No LTO**: Disables LTO.

### Step 5: Build Options
Configure additional build parameters:
- **Verbose mode (-V)**: Enables detailed output.
- **Dirty build (-D)**: Skips cleaning the output directory.
- **Custom job count**: Allows specifying the number of parallel jobs.

### Step 6: Build Summary
Review the selected configuration. Confirm to proceed with the build process.

### Step 7: Build Execution
The script will execute builds sequentially for each selected device. Full build output is displayed for monitoring.

### Step 8: Completion
Upon completion, a summary of successful and failed builds is displayed. Build logs are saved as `build_*.log`, and flashable ZIP files are located in the `out/` directory.

---

## Settings Menu

### Show All Defconfigs
**OFF (Default):**
Displays only the curated list of known devices.

**ON:**
Displays all available defconfigs found in `arch/arm64/configs/`, excluding stock defconfigs. This is useful for building for devices not in the predefined list.

### Change Language
Allows switching the interface language between English (Default) and Bengali (বাংলা).
- **English**: Standard interface.
- **Bengali**: Full Bengali translation of all menus and messages.

The preference is saved to `.buildall_config` and persists across sessions.

### About Section
Displays version and author information.

---

## Examples

### Example 1: Single Device, Standard Build
1. Launch TUI: `./build_tui.sh`
2. Select "Start Build Process"
3. Select device: `[X] lmi`
4. KernelSU: `No`
5. ROM Type: `Both AOSP and MIUI`
6. Build Options: (none selected)
7. Confirm and build

**Result:** Generates AOSP and MIUI ZIPs for lmi without KernelSU.

### Example 2: Multiple Devices with KernelSU
1. Launch TUI
2. Select devices: `umi`, `lmi`, `alioth`
3. KernelSU: `Yes`
4. ROM Type: `Both`
5. Build Options: `Verbose mode`, `Custom job count: 8`
6. Confirm and build

**Result:** Generates ZIPs for all three devices with KernelSU, verbose output, using 8 parallel jobs.

---

## Features in Detail

### Multi-Device Selection
Allows sequential building of multiple devices with identical configurations. If one device build fails, the script continues to the next device.

### Predefined Device List
Provides a curated list of supported and tested devices with user-friendly names to prevent identification errors.

### Dynamic Defconfig Discovery
Scans `arch/arm64/configs/` to dynamically list available device configurations, excluding stock defconfigs.

### Build Summary
Displays a comprehensive summary of all selected options before execution to ensure correctness.

---

## Tips & Best Practices

### Quick Single Build
Run `./build_tui.sh`, select a single device, accept default options, and confirm.

### Batch Building
Select all target devices, configure KernelSU and ROM type, and optionally enable dirty build for faster iteration.

### Development Workflow
For iterative development, enable "Show all defconfigs" if using a non-standard device, and use the "Dirty build" option to speed up compilation.

---

## Troubleshooting

### Dialog Not Installed
**Error:** `dialog: command not found`

**Solution:**
The script attempts to auto-install `dialog`. If it fails, install it manually:
```bash
sudo apt-get update && sudo apt-get install dialog
```

### Build Script Not Found
**Error:** `Build script not found at: ./build.sh`

**Solution:**
Ensure `build.sh` is located in the same directory as `build_tui.sh`.

### No Defconfigs Found
**Error:** `No defconfigs found`

**Solution:**
Ensure the script is executed from the root of the kernel source directory.

### Device Not Listed
**Issue:** Target device is not visible in the list.

**Solution:**
Enable "Show all defconfigs" in the Settings menu, or manually add the device to the `KNOWN_DEVICES` array in the script.

---

## Advanced Usage

### Modifying Device List
To add a new device to the verified list, edit the `KNOWN_DEVICES` array in `build_tui.sh`:

```bash
declare -A KNOWN_DEVICES=(
    ...
    ["surya"]="POCO X3 / Redmi Note 9 Pro"
    ...
)
```

### Automation
While `build_tui.sh` is designed for interactive use, the underlying `build.sh` can be used for automation and CI/CD pipelines.

---

## File Structure

```
kernel-source/
├── build.sh              # Main build script
├── build_tui.sh          # TUI driver script
├── arch/arm64/configs/   # Device defconfigs
├── anykernel/            # AnyKernel3 directory
├── out/                  # Build output directory
└── build_*.log           # Build logs
```

---

## FAQ

**Q: Can I build for devices not in the list?**
A: Yes, enable "Show all defconfigs" in the Settings menu.

**Q: Can I select no devices?**
A: No, at least one device must be selected.

**Q: What happens if a build fails?**
A: The script will proceed to build the remaining selected devices and report failures at the end.

**Q: Can I cancel the build process?**
A: Yes, press `Ctrl+C` to abort. Any completed builds will remain in the `out/` directory.

---

## Credits

- **Script Author:** kaixenber
- **Build Script:** Enhanced kernel build system
- **UI Framework:** dialog (ncurses)

---

## License

This script is provided as-is for kernel development purposes.
