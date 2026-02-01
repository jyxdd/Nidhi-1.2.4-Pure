#!/bin/bash

# Kernel Build TUI Driver
# Author: kaixenber
# Version: 1.1

# Note: We don't use 'set -e' here because we want to handle
# build failures gracefully and continue with other devices

# Script information
SCRIPT_VERSION="1.1"
SCRIPT_AUTHOR="kaixenber"
BUILD_SCRIPT="./build.sh"
CONFIG_FILE=".buildall_config"

# Check for help argument
if [[ "$1" == "--help" || "$1" == "-H" ]]; then
    echo "Kernel Build TUI Driver v$SCRIPT_VERSION"
    echo "Author: $SCRIPT_AUTHOR"
    echo ""
    echo "Usage: $0 [Options]"
    echo ""
    echo "Options:"
    echo "  -H, --help    Show this help message and exit"
    echo ""
    echo "Description:"
    echo "  This script provides a TUI (Text User Interface) for building"
    echo "  Android kernels for various Xiaomi devices."
    echo ""
    echo "  It depends on 'dialog' and assumes execution from the kernel source root."
    exit 0
fi


# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "Error: 'dialog' is not installed."
    echo "Installing dialog..."
    sudo apt-get update && sudo apt-get install -y dialog
fi

# Language Definitions
set_language_en() {
    # Titles
    TXT_TITLE_MAIN="Kernel Build TUI - v$SCRIPT_VERSION"
    TXT_TITLE_ERROR="Error"
    TXT_TITLE_WARNING="Warning"
    TXT_TITLE_SETTINGS="Settings"
    TXT_TITLE_ABOUT="About Kernel Build TUI"
    TXT_TITLE_SELECT_DEV="Select Devices"
    TXT_TITLE_KSU="KernelSU"
    TXT_TITLE_ROM="ROM Type"
    TXT_TITLE_OPTS="Build Options"
    TXT_TITLE_JOBS="Job Count"
    TXT_TITLE_SUMMARY="Build Summary"
    
    # Main Menu
    TXT_MENU_LBL="Select an option:"
    TXT_OPT_START="Start Build Process"
    TXT_OPT_SETTINGS="Settings"
    TXT_OPT_ABOUT="About"
    TXT_OPT_EXIT="Exit"
    
    # Settings
    TXT_SET_LBL="Configure build script settings:"
    TXT_SET_SHOW_DEF="Show all defconfigs"
    TXT_SET_LANG="Change Language / ভাষা পরিবর্তন করুন"
    TXT_SET_BACK="Back to Main Menu"
    TXT_ON="ON"
    TXT_OFF="OFF"
    TXT_MSG_SHOW_ON="Show all defconfigs: ON\n\nShowing all available defconfigs."
    TXT_MSG_SHOW_OFF="Show all defconfigs: OFF\n\nOnly showing known device defconfigs."
    
    # Errors/Warnings
    TXT_ERR_SCRIPT_MISSING="Build script not found at: $BUILD_SCRIPT\n\nPlease ensure build.sh is in the same directory."
    TXT_ERR_NOT_EXEC="Build script is not executable and cannot be made executable.\n\nPlease run:\n  chmod +x $BUILD_SCRIPT"
    TXT_ERR_NO_DEFCONFIGS="No defconfigs found in arch/arm64/configs/\n\nPlease ensure you're in the kernel source directory."
    TXT_ERR_NO_DEV_SEL="No devices selected!"
    TXT_ERR_NOT_ROOT="Not in kernel source directory!\n\nPlease run this script from the root of your kernel source tree.\n\nCurrent directory: $(pwd)"
    
    # Steps
    TXT_MSG_SELECT_DEV="Select one or more devices to build:\n(Use SPACE to select, ENTER to confirm)"
    TXT_MSG_KSU="Enable KernelSU with SUSFS support?"
    TXT_OPT_KSU_YES="Yes - Enable KSU"
    TXT_OPT_KSU_NO="No - Disable KSU"
    TXT_OPT_CANCEL="Cancel"
    
    TXT_MSG_ROM="Select which ROM(s) to build:"
    TXT_OPT_ROM_BOTH="Both AOSP and MIUI"
    TXT_OPT_ROM_AOSP="AOSP only"
    TXT_OPT_ROM_MIUI="MIUI only"
    
    TXT_MSG_OPTS="Select build options:\n(Use SPACE to select, ENTER to confirm)"
    TXT_OPT_VERBOSE="Verbose mode (-V)"
    TXT_OPT_DIRTY="Dirty build (-D)"
    TXT_OPT_JOBS="Custom job count"
    
    TXT_MSG_JOBS="Enter number of parallel jobs (1-$MAX_JOBS):"
    TXT_MSG_JOBS_INV="Invalid job count. Using default."
    
    # Summary
    TXT_SUM_READY="Ready to build with the following configuration:"
    TXT_SUM_DEVS="Devices:"
    TXT_SUM_KSU="KernelSU:"
    TXT_SUM_KSU_EN="Enabled (SUSFS)"
    TXT_SUM_KSU_DIS="Disabled"
    TXT_SUM_ROM="ROM Type:"
    TXT_SUM_OPTS="Build Options:"
    TXT_SUM_STD="Standard build"
    TXT_SUM_TOTAL="Total builds:"
    TXT_SUM_PROCEED="Do you want to proceed?"
    TXT_SUM_DEV_COUNT="device(s)"
    
    # Execution
    TXT_EXEC_START="Starting Build Process"
    TXT_EXEC_TOTAL="Total devices:"
    TXT_EXEC_DEVS="Devices:"
    TXT_EXEC_BUILDING="Building"
    TXT_EXEC_CMD="Executing:"
    TXT_EXEC_SUCCESS="✓ Build completed successfully for"
    TXT_EXEC_FAIL="✗ Build failed for"
    TXT_EXEC_COMPLETE="Build Process Complete"
    TXT_EXEC_ALL_SUCC="SUCCESS: All devices built successfully!"
    TXT_EXEC_CHECK_OUT="Check the out/ directory for flashable ZIPs:"
    TXT_EXEC_LOGS="Build logs available:"
    TXT_EXEC_ERRORS="COMPLETED WITH ERRORS:"
    TXT_EXEC_FAIL_LIST="Failed builds"
    TXT_EXEC_SUCC_LIST="Successful builds"
    TXT_EXEC_CHECK_LOGS="Check build logs for error details"
    TXT_EXEC_PRESS_ENTER="Press ENTER to return to main menu..."
}

set_language_bn() {
    # Titles
    TXT_TITLE_MAIN="কার্নেল বিল্ড TUI - v$SCRIPT_VERSION"
    TXT_TITLE_ERROR="ত্রুটি"
    TXT_TITLE_WARNING="সতর্কতা"
    TXT_TITLE_SETTINGS="সেটিংস"
    TXT_TITLE_ABOUT="Kernel Build TUI সম্পর্কে"
    TXT_TITLE_SELECT_DEV="ডিভাইস নির্বাচন"
    TXT_TITLE_KSU="KernelSU"
    TXT_TITLE_ROM="রমের ধরন"
    TXT_TITLE_OPTS="বিল্ড অপশন"
    TXT_TITLE_JOBS="জব সংখ্যা"
    TXT_TITLE_SUMMARY="বিল্ড সারাংশ"
    
    # Main Menu
    TXT_MENU_LBL="একটি অপশন নির্বাচন করুন:"
    TXT_OPT_START="বিল্ড প্রক্রিয়া শুরু করুন"
    TXT_OPT_SETTINGS="সেটিংস"
    TXT_OPT_ABOUT="সম্পর্কে"
    TXT_OPT_EXIT="প্রস্থান"
    
    # Settings
    TXT_SET_LBL="বিল্ড স্ক্রিপ্ট সেটিংস কনফিগার করুন:"
    TXT_SET_SHOW_DEF="সব defconfigs দেখান"
    TXT_SET_LANG="Change Language / ভাষা পরিবর্তন করুন"
    TXT_SET_BACK="মূল মেনুতে ফিরে যান"
    TXT_ON="চালু"
    TXT_OFF="বন্ধ"
    TXT_MSG_SHOW_ON="সব defconfigs দেখান: চালু\n\nসব উপলব্ধ defconfigs দেখানো হচ্ছে।"
    TXT_MSG_SHOW_OFF="সব defconfigs দেখান: বন্ধ\n\nশুধুমাত্র পরিচিত ডিভাইসের defconfigs দেখানো হচ্ছে।"
    
    # Errors/Warnings
    TXT_ERR_SCRIPT_MISSING="বিল্ড স্ক্রিপ্ট পাওয়া যায়নি: $BUILD_SCRIPT\n\nঅনুগ্রহ করে নিশ্চিত করুন build.sh একই ডিরেক্টরিতে আছে।"
    TXT_ERR_NOT_EXEC="বিল্ড স্ক্রিপ্ট এক্সিকিউটেবল নয় এবং করা যাচ্ছে না।\n\nঅনুগ্রহ করে রান করুন:\n  chmod +x $BUILD_SCRIPT"
    TXT_ERR_NO_DEFCONFIGS="arch/arm64/configs/-এ কোনো defconfigs পাওয়া যায়নি\n\nঅনুগ্রহ করে নিশ্চিত করুন আপনি কার্নেল সোর্স ডিরেক্টরিতে আছেন।"
    TXT_ERR_NO_DEV_SEL="কোনো ডিভাইস নির্বাচন করা হয়নি!"
    TXT_ERR_NOT_ROOT="কার্নেল সোর্স ডিরেক্টরিতে নেই!\n\nঅনুগ্রহ করে আপনার কার্নেল সোর্স ট্রির রুট থেকে এই স্ক্রিপ্টটি চালান।\n\nবর্তমান ডিরেক্টরি: $(pwd)"
    
    # Steps
    TXT_MSG_SELECT_DEV="বিল্ড করার জন্য এক বা একাধিক ডিভাইস নির্বাচন করুন:\n(নির্বাচন করতে SPACE, নিশ্চিত করতে ENTER ব্যবহার করুন)"
    TXT_MSG_KSU="SUSFS সাপোর্ট সহ KernelSU সক্রিয় করবেন?"
    TXT_OPT_KSU_YES="হ্যাঁ - KSU সক্রিয় করুন"
    TXT_OPT_KSU_NO="না - KSU নিষ্ক্রিয় করুন"
    TXT_OPT_CANCEL="বাতিল"
    
    TXT_MSG_ROM="কোন রম(গুলো) বিল্ড করবেন নির্বাচন করুন:"
    TXT_OPT_ROM_BOTH="AOSP এবং MIUI উভয়ই"
    TXT_OPT_ROM_AOSP="শুধুমাত্র AOSP"
    TXT_OPT_ROM_MIUI="শুধুমাত্র MIUI"
    
    TXT_MSG_OPTS="বিল্ড অপশন নির্বাচন করুন:\n(নির্বাচন করতে SPACE, নিশ্চিত করতে ENTER ব্যবহার করুন)"
    TXT_OPT_VERBOSE="ভার্বোস মোড (-V)"
    TXT_OPT_DIRTY="ডার্টি বিল্ড (-D)"
    TXT_OPT_JOBS="কাস্টম জব সংখ্যা"
    
    TXT_MSG_JOBS="প্যারালাল জবের সংখ্যা লিখুন (১-$MAX_JOBS):"
    TXT_MSG_JOBS_INV="অবৈধ জব সংখ্যা। ডিফল্ট ব্যবহার করা হচ্ছে।"
    
    # Summary
    TXT_SUM_READY="নিম্নলিখিত কনফিগারেশনের সাথে বিল্ড করতে প্রস্তুত:"
    TXT_SUM_DEVS="ডিভাইসসমূহ:"
    TXT_SUM_KSU="KernelSU:"
    TXT_SUM_KSU_EN="সক্রিয় (SUSFS)"
    TXT_SUM_KSU_DIS="নিষ্ক্রিয়"
    TXT_SUM_ROM="রমের ধরন:"
    TXT_SUM_OPTS="বিল্ড অপশন:"
    TXT_SUM_STD="সাধারণ বিল্ড"
    TXT_SUM_TOTAL="মোট বিল্ড:"
    TXT_SUM_PROCEED="আপনি কি এগিয়ে যেতে চান?"
    TXT_SUM_DEV_COUNT="টি ডিভাইস"
    
    # Execution
    TXT_EXEC_START="বিল্ড প্রক্রিয়া শুরু হচ্ছে"
    TXT_EXEC_TOTAL="মোট ডিভাইস:"
    TXT_EXEC_DEVS="ডিভাইসসমূহ:"
    TXT_EXEC_BUILDING="বিল্ড হচ্ছে"
    TXT_EXEC_CMD="এক্সিকিউট হচ্ছে:"
    TXT_EXEC_SUCCESS="✓ বিল্ড সফলভাবে সম্পন্ন হয়েছে:"
    TXT_EXEC_FAIL="✗ বিল্ড ব্যর্থ হয়েছে:"
    TXT_EXEC_COMPLETE="বিল্ড প্রক্রিয়া সম্পন্ন"
    TXT_EXEC_ALL_SUCC="সফলতা: সব ডিভাইস সফলভাবে বিল্ড হয়েছে!"
    TXT_EXEC_CHECK_OUT="ফ্ল্যাশযোগ্য জিপগুলির জন্য out/ ডিরেক্টরি চেক করুন:"
    TXT_EXEC_LOGS="বিল্ড লগ উপলব্ধ:"
    TXT_EXEC_ERRORS="ত্রুটিসহ সম্পন্ন হয়েছে:"
    TXT_EXEC_FAIL_LIST="ব্যর্থ বিল্ড"
    TXT_EXEC_SUCC_LIST="সফল বিল্ড"
    TXT_EXEC_CHECK_LOGS="ত্রুটির বিস্তারিত জানার জন্য বিল্ড লগ চেক করুন"
    TXT_EXEC_PRESS_ENTER="মূল মেনুতে ফিরে যেতে ENTER টিপুন..."
}


# Default settings
SHOW_ALL_DEFCONFIGS=false
CURRENT_LANGUAGE="en"

# Load config
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set language
if [ "$CURRENT_LANGUAGE" == "bn" ]; then
    set_language_bn
else
    set_language_en
fi

# Check if build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    dialog --title "$TXT_TITLE_ERROR" --msgbox "$TXT_ERR_SCRIPT_MISSING" 10 60
    clear
    exit 1
fi

# Make sure build script is executable
if [ ! -x "$BUILD_SCRIPT" ]; then
    chmod +x "$BUILD_SCRIPT" 2>/dev/null || {
        dialog --title "$TXT_TITLE_ERROR" --msgbox "$TXT_ERR_NOT_EXEC" 10 60
        clear
        exit 1
    }
fi

# Temporary file for dialog
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Known device configurations (device_code:device_name)
declare -A KNOWN_DEVICES=(
    ["psyche"]="Xiaomi 12X"
    ["thyme"]="Xiaomi 10S"
    ["umi"]="Xiaomi 10"
    ["munch"]="Redmi K40S / POCO F4"
    ["lmi"]="Redmi K30 Pro / POCO F2 Pro"
    ["cmi"]="Xiaomi 10 Pro"
    ["cas"]="Xiaomi 10 Ultra"
    ["apollo"]="Xiaomi 10T / Redmi K30S Ultra"
    ["alioth"]="Xiaomi 11X / POCO F3 / Redmi K40"
    ["elish"]="Xiaomi Pad 5 Pro"
    ["enuma"]="Xiaomi Pad 5 Pro 5G"
    ["dagu"]="Xiaomi Pad 5 Pro 12.4"
    ["pipa"]="Xiaomi Pad 6"
)

# Function to get available defconfigs
get_defconfigs() {
    local show_all=$1
    local defconfigs=()
    
    if [ -d "arch/arm64/configs" ]; then
        # Get all defconfigs excluding *_stock-defconfig
        while IFS= read -r file; do
            local basename=$(basename "$file" _defconfig)
            
            # Skip stock defconfigs
            if [[ "$basename" == *"_stock" ]]; then
                continue
            fi
            
            # If show_all is false, only show known devices
            if [ "$show_all" = false ]; then
                if [[ -n "${KNOWN_DEVICES[$basename]}" ]]; then
                    defconfigs+=("$basename")
                fi
            else
                defconfigs+=("$basename")
            fi
        done < <(find arch/arm64/configs -name "*_defconfig" -type f | sort)
    fi
    
    printf '%s\n' "${defconfigs[@]}"
}

# Function to save config
save_config() {
    echo "SHOW_ALL_DEFCONFIGS=$SHOW_ALL_DEFCONFIGS" > "$CONFIG_FILE"
    echo "CURRENT_LANGUAGE=\"$CURRENT_LANGUAGE\"" >> "$CONFIG_FILE"
}

# Function to show about dialog
show_about() {
    dialog --title "$TXT_TITLE_ABOUT" --msgbox \
"╔════════════════════════════════════════╗
║   Kernel Build TUI Driver              ║
║                                        ║
║   Version: $SCRIPT_VERSION                        ║
║   Author:  $SCRIPT_AUTHOR                   ║
║                                        ║
║   Language: $CURRENT_LANGUAGE                           ║
╚════════════════════════════════════════╝

This is a graphical interface for the enhanced
kernel build script. It simplifies the process
of building kernels for multiple devices with
various configurations.

Features:
• Multi-device selection
• KernelSU support with SUSFS
• ROM type selection (AOSP/MIUI)
• Verbose and dirty build options
• Custom job control
• Build logging
• Multi-language support (English/Bengali)

The underlying build script supports:
- Automatic build logging
- Error detection and reporting
- KPM patching for SukiSU
- MIUI-specific DTS patches
- CONFIG_LOCALVERSION configuration

For more information, check the README.

Press OK to continue..." 30 60
}

# Function to show settings menu
show_settings() {
    while true; do
        local choice=$(dialog --title "$TXT_TITLE_SETTINGS" --menu \
"$TXT_SET_LBL" 15 60 4 \
1 "$TXT_SET_SHOW_DEF: $([ "$SHOW_ALL_DEFCONFIGS" = true ] && echo "$TXT_ON" || echo "$TXT_OFF")" \
2 "$TXT_SET_LANG: $([ "$CURRENT_LANGUAGE" = "bn" ] && echo "Bengali" || echo "English")" \
3 "$TXT_OPT_ABOUT" \
4 "$TXT_SET_BACK" \
2>&1 >/dev/tty)
        
        case $choice in
            1)
                if [ "$SHOW_ALL_DEFCONFIGS" = true ]; then
                    SHOW_ALL_DEFCONFIGS=false
                    dialog --title "$TXT_TITLE_SETTINGS" --msgbox "$TXT_MSG_SHOW_OFF" 8 50
                else
                    SHOW_ALL_DEFCONFIGS=true
                    dialog --title "$TXT_TITLE_SETTINGS" --msgbox "$TXT_MSG_SHOW_ON" 8 50
                fi
                save_config
                ;;
            2)
                dialog --title "$TXT_SET_LANG" --menu \
"Select Language / ভাষা নির্বাচন করুন:" 10 50 2 \
"en" "English" \
"bn" "বাংলা (Bengali)" 2> $TEMP_FILE
                
                if [ $? -eq 0 ]; then
                    local lang_choice=$(cat $TEMP_FILE)
                    CURRENT_LANGUAGE="$lang_choice"
                    save_config
                    
                    # Reload language definitions
                    if [ "$CURRENT_LANGUAGE" == "bn" ]; then
                        set_language_bn
                    else
                        set_language_en
                    fi
                fi
                ;;
            3)
                show_about
                ;;
            4|"")
                break
                ;;
        esac
    done
}

# Function to select devices
select_devices() {
    local defconfigs=($(get_defconfigs $SHOW_ALL_DEFCONFIGS))
    
    if [ ${#defconfigs[@]} -eq 0 ]; then
        dialog --title "$TXT_TITLE_ERROR" --msgbox "$TXT_ERR_NO_DEFCONFIGS" 10 60
        return 1
    fi
    
    # Build menu items
    local menu_items=()
    for device in "${defconfigs[@]}"; do
        local device_name="${KNOWN_DEVICES[$device]}"
        if [ -z "$device_name" ]; then
            device_name="$device"
        fi
        menu_items+=("$device" "$device_name" "OFF")
    done
    
    dialog --title "$TXT_TITLE_SELECT_DEV" --checklist \
"$TXT_MSG_SELECT_DEV" \
20 70 ${#defconfigs[@]} \
"${menu_items[@]}" 2> $TEMP_FILE
    
    if [ $? -eq 0 ]; then
        # Read selected devices
        SELECTED_DEVICES=$(cat $TEMP_FILE | tr -d '"')
        if [ -z "$SELECTED_DEVICES" ]; then
            dialog --title "$TXT_TITLE_WARNING" --msgbox "$TXT_ERR_NO_DEV_SEL" 6 40
            return 1
        fi
        return 0
    else
        return 1
    fi
}

# Function to select KernelSU option
select_ksu() {
    dialog --title "$TXT_TITLE_KSU" --menu \
"$TXT_MSG_KSU" 12 60 3 \
1 "$TXT_OPT_KSU_YES" \
2 "$TXT_OPT_KSU_NO" \
3 "$TXT_OPT_CANCEL" 2> $TEMP_FILE
    
    local choice=$(cat $TEMP_FILE)
    case $choice in
        1)
            KSU_OPTION="ksu"
            return 0
            ;;
        2)
            KSU_OPTION=""
            return 0
            ;;
        3|"")
            return 1
            ;;
    esac
}

# Function to select ROM type
select_rom_type() {
    dialog --title "$TXT_TITLE_ROM" --menu \
"$TXT_MSG_ROM" 12 60 4 \
1 "$TXT_OPT_ROM_BOTH" \
2 "$TXT_OPT_ROM_AOSP" \
3 "$TXT_OPT_ROM_MIUI" \
4 "$TXT_OPT_CANCEL" 2> $TEMP_FILE
    
    local choice=$(cat $TEMP_FILE)
    case $choice in
        1)
            ROM_TYPE=""
            return 0
            ;;
        2)
            ROM_TYPE="aosp"
            return 0
            ;;
        3)
            ROM_TYPE="miui"
            return 0
            ;;
        4|"")
            return 1
            ;;
    esac
}

# Function to select build options
select_build_options() {
    MAX_JOBS=$(nproc)
    dialog --title "$TXT_TITLE_OPTS" --checklist \
"$TXT_MSG_OPTS" \
12 60 3 \
1 "$TXT_OPT_VERBOSE" OFF \
2 "$TXT_OPT_DIRTY" OFF \
3 "$TXT_OPT_JOBS" OFF \
2> $TEMP_FILE
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local selected=$(cat $TEMP_FILE)
    
    VERBOSE_FLAG=""
    DIRTY_FLAG=""
    JOBS_FLAG=""
    
    if [[ "$selected" == *"1"* ]]; then
        VERBOSE_FLAG="-V"
    fi
    
    if [[ "$selected" == *"2"* ]]; then
        DIRTY_FLAG="-D"
    fi
    
    if [[ "$selected" == *"3"* ]]; then
        # Ask for job count
        dialog --title "$TXT_TITLE_JOBS" --inputbox \
"$TXT_MSG_JOBS" 8 50 "$MAX_JOBS" 2> $TEMP_FILE
        
        if [ $? -eq 0 ]; then
            local jobs=$(cat $TEMP_FILE)
            if [[ "$jobs" =~ ^[0-9]+$ ]] && [ "$jobs" -gt 0 ]; then
                JOBS_FLAG="-J$jobs"
            else
                dialog --title "$TXT_TITLE_WARNING" --msgbox "$TXT_MSG_JOBS_INV" 6 40
            fi
        fi
    fi
    
    return 0
}

# Function to show build summary
show_build_summary() {
    local devices_list=$(echo "$SELECTED_DEVICES" | tr ' ' '\n' | sed 's/^/  • /')
    local ksu_status="$TXT_SUM_KSU_DIS"
    [ "$KSU_OPTION" = "ksu" ] && ksu_status="$TXT_SUM_KSU_EN"
    
    local rom_type_text="$TXT_OPT_ROM_BOTH"
    [ "$ROM_TYPE" = "aosp" ] && rom_type_text="$TXT_OPT_ROM_AOSP"
    [ "$ROM_TYPE" = "miui" ] && rom_type_text="$TXT_OPT_ROM_MIUI"
    
    local options_text="$TXT_SUM_STD"
    local options_list=""
    [ -n "$VERBOSE_FLAG" ] && options_list="${options_list}${TXT_OPT_VERBOSE}\n"
    [ -n "$DIRTY_FLAG" ] && options_list="${options_list}${TXT_OPT_DIRTY}\n"
    [ -n "$JOBS_FLAG" ] && options_list="${options_list}${TXT_OPT_JOBS}: ${JOBS_FLAG:2}\n"
    [ -n "$options_list" ] && options_text="$options_list"
    
    dialog --title "$TXT_TITLE_SUMMARY" --yesno \
"$TXT_SUM_READY

$TXT_SUM_DEVS
$devices_list

$TXT_SUM_KSU $ksu_status
$TXT_SUM_ROM $rom_type_text

$TXT_SUM_OPTS
$options_text

$TXT_SUM_TOTAL $(echo "$SELECTED_DEVICES" | wc -w) $TXT_SUM_DEV_COUNT × $([ "$ROM_TYPE" = "" ] && echo "2 ROMs" || echo "1 ROM")

$TXT_SUM_PROCEED" 25 70
    
    return $?
}

# Function to execute builds
execute_builds() {
    # Save terminal state
    local saved_state=$(stty -g 2>/dev/null)
    
    clear
    
    local total_devices=$(echo "$SELECTED_DEVICES" | wc -w)
    local current=0
    local failed_builds=()
    
    echo "========================================"
    echo "  $TXT_EXEC_START"
    echo "========================================"
    echo ""
    echo "$TXT_EXEC_TOTAL $total_devices"
    echo "$TXT_EXEC_DEVS $SELECTED_DEVICES"
    echo ""
    
    for device in $SELECTED_DEVICES; do
        ((current++))
        
        echo "========================================"
        echo "$TXT_EXEC_BUILDING $current/$total_devices: $device"
        echo "========================================"
        
        # Build command
        local cmd="bash $BUILD_SCRIPT $device"
        [ -n "$KSU_OPTION" ] && cmd="$cmd $KSU_OPTION"
        [ -n "$ROM_TYPE" ] && cmd="$cmd $ROM_TYPE"
        [ -n "$VERBOSE_FLAG" ] && cmd="$cmd $VERBOSE_FLAG"
        [ -n "$DIRTY_FLAG" ] && cmd="$cmd $DIRTY_FLAG"
        [ -n "$JOBS_FLAG" ] && cmd="$cmd $JOBS_FLAG"
        
        echo "$TXT_EXEC_CMD $cmd"
        echo ""
        
        # Execute build - run in foreground with proper terminal handling
        set +e  # Don't exit on error
        eval "$cmd"
        local build_status=$?
        set -e
        
        if [ $build_status -eq 0 ]; then
            echo ""
            echo "$TXT_EXEC_SUCCESS $device"
        else
            echo ""
            echo "$TXT_EXEC_FAIL $device (exit code: $build_status)"
            failed_builds+=("$device")
        fi
        
        echo ""
    done
    
    echo "========================================"
    echo "  $TXT_EXEC_COMPLETE"
    echo "========================================"
    echo ""
    
    # Show completion message
    if [ ${#failed_builds[@]} -eq 0 ]; then
        echo "$TXT_EXEC_ALL_SUCC"
        echo ""
        echo "$TXT_EXEC_CHECK_OUT"
        for device in $SELECTED_DEVICES; do
            echo "  - out/$device/"
        done
        echo ""
        echo "$TXT_EXEC_LOGS build_*.log"
    else
        echo "$TXT_EXEC_ERRORS"
        echo ""
        echo "$TXT_EXEC_FAIL_LIST (${#failed_builds[@]}):"
        for device in "${failed_builds[@]}"; do
            echo "  ✗ $device"
        done
        echo ""
        echo "$TXT_EXEC_SUCC_LIST ($((total_devices - ${#failed_builds[@]}))):"
        for device in $SELECTED_DEVICES; do
            if [[ ! " ${failed_builds[@]} " =~ " ${device} " ]]; then
                echo "  ✓ $device"
            fi
        done
        echo ""
        echo "$TXT_EXEC_CHECK_LOGS"
    fi
    
    echo ""
    echo "$TXT_EXEC_PRESS_ENTER"
    read -r
    
    # Restore terminal state
    if [ -n "$saved_state" ]; then
        stty "$saved_state" 2>/dev/null || true
    fi
    
    clear
}

# Main menu
main_menu() {
    while true; do
        local choice=$(dialog --title "$TXT_TITLE_MAIN" --menu \
"$TXT_MENU_LBL" 15 60 5 \
1 "$TXT_OPT_START" \
2 "$TXT_OPT_SETTINGS" \
3 "$TXT_OPT_ABOUT" \
4 "$TXT_OPT_EXIT" \
2>&1 >/dev/tty)
        
        case $choice in
            1)
                # Build process flow
                if select_devices; then
                    if select_ksu; then
                        if select_rom_type; then
                            if select_build_options; then
                                if show_build_summary; then
                                    # Execute builds - this will show builds in terminal
                                    execute_builds
                                    # After builds complete and user presses enter, return to menu
                                fi
                            fi
                        fi
                    fi
                fi
                ;;
            2)
                show_settings
                ;;
            3)
                show_about
                ;;
            4|"")
                clear
                exit 0
                ;;
        esac
    done
}

# Check if we're in kernel source directory
if [ ! -d "arch/arm64/configs" ]; then
    dialog --title "$TXT_TITLE_ERROR" --msgbox \
"$TXT_ERR_NOT_ROOT" 10 60
    clear
    exit 1
fi

# Start main menu
main_menu