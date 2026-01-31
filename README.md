# Warning
**বাংলা:**  
কার্নেল সোর্স কোড এখনও উন্নয়নাধীন এবং কিছু অপ্রত্যাশিত সমস্যা সৃষ্টি করতে পারে। দয়া করে সতর্কতার সাথে ব্যবহার করুন।  
**English:**  
The kernel source code is still under development and may cause some unpredictable problems. Please use it with caution.  

# NidhiKernel for Xiaomi SM8250 android devices  

## সূচিপত্র / Table of Contents
- [ভূমিকা / Introduction](#简介--introduction)  
- [বৈশিষ্ট্য / Features](#特性--features)  
- [নোট / Notes](#注意事项--notes)  
- [কমিউনিটি / Community](#社区--community)  
- [সমর্থিত ডিভাইস / Supported Devices](#支持的设备--supported-devices)   
- [বিল্ড নির্দেশাবলী / Build Instructions](#构建方法--build-instructions)  
  - [দ্রুত বিল্ড / Quick Build](#快速构建--quick-build)  
  - [ম্যানুয়াল বিল্ড / Manual Build](#手动构建--manual-build)   

---

## ভূমিকা / Introduction
**বাংলা:**  
এই রিপোজিটরি [LineageOS/android_kernel_xiaomi_sm8250](https://github.com/LineageOS/android_kernel_xiaomi_sm8250) এর `lineage-23` ব্রাঞ্চের উপর ভিত্তি করে তৈরি। HyperOS/MIUI এর জন্য প্রয়োজনীয় কোড এবং কিছু ডিভাইস-নির্দিষ্ট ড্রাইভার [Strawing এর রিপোজিটরি](https://github.com/liyafe1997/kernel_xiaomi_sm8250_mod) এর কমিট হিস্ট্রি তুলনা করে বাছাই করা হয়েছে, যা [UtsavBalar1231 এর রিপোজিটরি](https://github.com/UtsavBalar1231/kernel_xiaomi_sm8250) এবং [Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) থেকে এসেছে।  

এই সোর্স কোড দৈত্যদের কাঁধে দাঁড়িয়ে আছে, একাধিক উৎস থেকে অবদান সংযুক্ত করে কার্নেলকে যতটা সম্ভব ভালো করে তোলার চেষ্টা করা হয়েছে।  

**English:**  
This repository is based on the `lineage-23` branch of [LineageOS/android_kernel_xiaomi_sm8250](https://github.com/LineageOS/android_kernel_xiaomi_sm8250).

Code required for HyperOS/MIUI support, as well as some device-specific drivers, was selectively cherry-pickedby comparing commit histories from [Strawing's repo](https://github.com/liyafe1997/kernel_xiaomi_sm8250_mod), which in turn sources changes from [UtsavBalar1231's repo](https://github.com/UtsavBalar1231/kernel_xiaomi_sm8250) and [Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource).  

This kernel stands on the shoulders of giants, combining contributions from multiple upstreams to make it as practical and well-rounded as possible.  

---

## বৈশিষ্ট্য / Features
**বাংলা:**  
এই কার্নেল [sidex15's KernelSU-Next fork]() ([KernelSU-Next]() এর উপর ভিত্তি করে, KernelSU এর একটি ফর্ক) এবং [SuSFS](https://gitlab.com/simonpunk/susfs4ksu) সমর্থন করে। দয়া করে [KernelSU-Next ম্যানেজার]() নিজে ইনস্টল করুন। NoKernelSU সংস্করণ Magisk এবং APatch (এবং তাদের ফর্ক) সমর্থন করে।

এই কার্নেল এর NoKernelSU ভার্সন Magisk বা Apatch (এবং তার ফর্ক) ব্যাবহার করতে পারবেন।

নিচে কিছু মূল বৈশিষ্ট্য দেওয়া হল:   
1. USB সিরিয়াল ড্রাইভার সমর্থন (CH340/FTDI/PL2303/OTI6858/TI/SPCP8X5/QT2/UPD78F0730/CP210X)  
2. CANBus এবং USB CAN অ্যাডাপ্টার (যেমন CANable) সমর্থন  
3. F2FS-এ realtime discard সক্রিয় করা হয়েছে উন্নত ফ্ল্যাশ TRIM আচরণের জন্য  
4. EROFS সমর্থন  
5. zRAM একাধিক কম্প্রেশন অ্যালগরিদম সমর্থন করে, যার মধ্যে রয়েছে LZ4, LZ4HC, lz4k_oplus, LZ4KD এবং ZSTD  
6. Linux 5.10 থেকে ব্যাকপোর্ট করা BPF (Android 16 সামঞ্জস্যপূর্ণ)  
7. টাচস্ক্রিন, ক্যামেরা, অডিও, GPU/DRM/MSM এবং CNSS2 ড্রাইভার Xiaomi-নির্দিষ্ট ইমপ্লিমেন্টেশন ব্যবহার করে (UtsavBalar1231 এর রিপোজিটরি এবং MiCode থেকে প্রাপ্ত। Display/DRM ড্রাইভারের AOSP সংস্করণ হল LineageOS সংস্করণ); এছাড়াও, টাচস্ক্রিন ড্রাইভারে `double_tap` নোড যোগ করা হয়েছে  
8. [ব্যাটারি শতাংশ 1% এ আটকে থাকার সমস্যা](https://github.com/liyafe1997/Xiaomi-fix-battery-one-percent) ঠিক করা হয়েছে এবং উচ্চ ক্ষমতার প্রতিস্থাপন ব্যাটারি সনাক্তকরণ সমর্থন করে
9. [BBG (Baseband-guard)](https://github.com/vc-teahouse/Baseband-guard) সংহত করা হয়েছে  

**English:**  
This kernel supports [sidex15's KernelSU-Next fork]() ([KernelSU-Next](), a fork of KernelSU ) & [SuSFS](https://gitlab.com/simonpunk/susfs4ksu). Please install the [KernelSU-Next ম্যানেজার]() by yourself.

The NoKernelSU version supports Magisk and APatch (and their forks).  

Below are some of the key features:  
1. Support for USB serial drivers (CH340 / FTDI / PL2303 / OTI6858 / TI / SPCP8X5 / QT2 / UPD78F0730 / CP210X)  
2. Support for CAN bus and USB CAN adapters (e.g. CANable)  
3. F2FS with realtime discard enabled for improved flash TRIM behavior  
4. Support for EROFS  
5. zRAM with support for multiple compression algorithms, including LZ4, LZ4HC, lz4k_oplus, LZ4KD, and ZSTD  
6. Backported BPF from Linux 5.10 (Android 16 compatible)  
7. Touchscreen, camera, audio, GPU/DRM/MSM, and CNSS2 drivers use Xiaomi-specific implementations (sourced from UtsavBalar1231's repository and MiCode. The AOSP version of the Display/DRM driver is LineageOS version.); also, `double_tap` node has been added to the touchscreen driver  
8. Fixes [the issue where the battery percentage gets stuck at 1%](https://github.com/liyafe1997/Xiaomi-fix-battery-one-percent), and supports recognizing higher-capacity replacement batteries
9. Integrate [BBG(Baseband-guard)](https://github.com/vc-teahouse/Baseband-guard)  

---

## নোট / Notes
**বাংলা:**  
**দ্রষ্টব্য**: কার্নেল zip প্যাকেজে `dtbo.img` নেই এবং এটি আপনার dtbo পার্টিশন ফ্ল্যাশ করবে না।  
স্টক `dtbo` ব্যবহার করার পরামর্শ দেওয়া হয়, অথবা তৃতীয় পক্ষের ROM এর বান্ডেল করা ফাইল থেকে একটি ব্যবহার করুন (যদি মূল লেখক নিশ্চিত করেন যে এটি ভালো কাজ করে)।  
এই সোর্স থেকে তৈরি `dtbo.img`-এ কিছু সমস্যা আছে—উদাহরণস্বরূপ, লক স্ক্রিনে, স্ক্রিন বন্ধ করার চেষ্টা করার সময় ডিসপ্লে হঠাৎ সর্বোচ্চ উজ্জ্বলতায় ফ্ল্যাশ হতে পারে।  
যদি আপনি অন্য তৃতীয় পক্ষের কার্নেল ফ্ল্যাশ করে থাকেন বা অদ্ভুত সমস্যার সম্মুখীন হন, তাহলে দয়া করে পরীক্ষা করুন আপনার `dtbo` প্রতিস্থাপিত হয়েছে কিনা।  

**সতর্কতা**: যদি আপনি HyperOS/MIUI ব্যবহার করেন, তাহলে দয়া করে **MIUI সংস্করণ** ফ্ল্যাশ করুন।  
AOSP সংস্করণে ভিন্ন ডিসপ্লে ড্রাইভার রয়েছে, যা HyperOS/MIUI-তে স্ক্রিন সঠিকভাবে প্রদর্শিত হতে দেবে না।  
ফ্ল্যাশ করার পরে যদি আপনি একটি কালো স্ক্রিন পান, তাহলে পরীক্ষা করুন আপনি HyperOS/MIUI-তে আছেন কিন্তু AOSP সংস্করণ ফ্ল্যাশ করেছেন কিনা।  
এই নির্দিষ্ট সমস্যা সম্পর্কে প্রতিক্রিয়া ডিফল্টভাবে গ্রহণ করা হবে না।  

**English:**  
**Note**: The kernel zip package does **not** contain `dtbo.img` and will not flash your dtbo partition.  
It is recommended to use the stock `dtbo`, or one from the bundled files of a third-party ROM (if the original author confirms it works well).  
The `dtbo.img` built from this source has some issues—for example, on the lock screen, the display may suddenly flash to max brightness when trying to turn off the screen.  
If you have flashed other third-party kernels or encounter strange issues, please check whether your `dtbo` has been replaced.  

**Warning**: If you are using HyperOS/MIUI, please flash the **MIUI version**.  
The AOSP version has different display drivers, which will cause the screen not to display properly on HyperOS/MIUI.  
If you get a black screen after flashing, check if you are on HyperOS/MIUI but flashed the AOSP version.  
Feedback about this specific issue will not be accepted by default.  

---

## সমর্থিত ডিভাইস / Supported Devices
| ডিভাইস কোডনেম / Codename  | ডিভাইসের নাম / Device Name            |
|---------------------|-----------------------------------|
| psyche              | Xiaomi 12X                        |
| thyme               | Xiaomi 10S                        |
| umi                 | Xiaomi 10                         |
| munch               | Redmi K40S / POCO F4              |
| lmi                 | Redmi K30 Pro / POCO F2 Pro       |
| cmi                 | Xiaomi 10 Pro                     |
| cas                 | Xiaomi 10 Ultra                   |
| apollo              | Xiaomi 10T / Redmi K30S Ultra     |
| alioth              | Xiaomi 11X / POCO F3 / Redmi K40  |
| elish               | Xiaomi Pad 5 Pro                  |
| enuma               | Xiaomi Pad 5 Pro 5G               |
| dagu                | Xiaomi Pad 5 Pro 12.4             |
| pipa                | Xiaomi Pad 6                      |

---

## বিল্ড নির্দেশাবলী / Build Instructions

### দ্রুত বিল্ড / Quick Build
**বাংলা:**  
1. এই রিপোজিটরি ফর্ক করুন (একটি স্টার দিতে ভুলবেন না~)  
2. **Actions** এ যান  
3. যদি আপনি সব সমর্থিত ডিভাইসের জন্য কার্নেল কম্পাইল করতে চান, তাহলে `Build All Devices Kernel (Matrix Parallel + Release)` খুঁজুন এবং `Run workflow` ক্লিক করুন  
4. যদি আপনি একটি নির্দিষ্ট ডিভাইসের জন্য কার্নেল কম্পাইল করতে চান, তাহলে `Build Kernel` খুঁজুন, `Run workflow` ক্লিক করুন এবং প্রয়োজনীয় অপশনগুলি নির্বাচন করুন  

**English:**  
1. Fork this repo (don't forget to leave a Star~)  
2. Go to **Actions**  
3. If you want to compile the kernel for all supported devices, find `Build All Devices Kernel (Matrix Parallel + Release)` and click `Run workflow`  
4. If you want to compile the kernel for a single device, find `Build Kernel`, click `Run workflow`, and select the necessary options  

---

### ম্যানুয়াল বিল্ড / Manual Build
**বাংলা:**  
1. বিল্ড এনভায়রনমেন্ট প্রস্তুত করুন।  
   আপনার প্রয়োজন `git`, `make`, `curl`, `bison`, `flex`, `zip` ইত্যাদি।  
   - Debian/Ubuntu-তে:  
   ```
   sudo apt install build-essential git curl wget bison flex zip bc cpio libssl-dev ccache tar
   ```
   আপনার `python`-ও প্রয়োজন (শুধু `python3` যথেষ্ট নয়):  
   ```
   sudo apt install python-is-python3
   ```

   - RHEL/RPM-ভিত্তিক OS-এ:  
   ```
   sudo yum groupinstall 'Development Tools'
   sudo yum install wget bc openssl-devel ccache tar
   ```

   দ্রষ্টব্য: `build.sh`-এ `ccache` সক্রিয় আছে (`$HOME/.cache/ccache_mikernel`)। আপনি এটি মুছে ফেলতে/পরিবর্তন করতে পারেন।  

2. [ZyC-Clang v15](https://github.com/ZyCromerZ/Clang/releases/tag/15.0.7-20251111-release) টুলচেইন ডাউনলোড করুন:  
   ```
   mkdir zyc-clang
   cd zyc-clang
   wget https://github.com/ZyCromerZ/Clang/releases/download/15.0.7-20251111-release/Clang-15.0.7-20251111.tar.gz
   tar -zxvf Clang-15.0.7-20251111.tar.gz
   cd ..
   ```

3. বিল্ড করুন:  
   - KernelSU ছাড়া:  
     ```
     bash build.sh TARGET_DEVICE
     ```
   - KernelSU সহ:  
     ```
     bash build.sh TARGET_DEVICE ksu
     ```

   উদাহরণ:  
   - lmi (Redmi K30 Pro/POCO F2 Pro) KernelSU ছাড়া:  
     ```
     bash build.sh lmi
     ```
   - umi (Xiaomi 10) KernelSU সহ:  
     ```
     bash build.sh umi ksu
     ```

   এছাড়াও, `buildall.sh` একবারে সব ডিভাইসের জন্য বিল্ড করতে পারে।  

**English:**  
1. Prepare the build environment.  
   You need `git`, `make`, `curl`, `bison`, `flex`, `zip`, etc.  
   - On Debian/Ubuntu:  
   ```
   sudo apt install build-essential git curl wget bison flex zip bc cpio libssl-dev ccache tar
   ```
   You also need `python` (not just `python3`):  
   ```
   sudo apt install python-is-python3
   ```

   - On RHEL/RPM-based OS:  
   ```
   sudo yum groupinstall 'Development Tools'
   sudo yum install wget bc openssl-devel ccache tar
   ```

   Note: `ccache` is enabled in `build.sh` (`$HOME/.cache/ccache_mikernel`). You may remove/modify it.  

2. Download [ZyC-Clang v15](https://github.com/ZyCromerZ/Clang/releases/tag/15.0.7-20251111-release) toolchain:  
   ```
   mkdir zyc-clang
   cd zyc-clang
   wget https://github.com/ZyCromerZ/Clang/releases/download/15.0.7-20251111-release/Clang-15.0.7-20251111.tar.gz
   tar -zxvf Clang-15.0.7-20251111.tar.gz
   cd ..
   ```

3. Build:  
   - Without KernelSU:  
     ```
     bash build.sh TARGET_DEVICE
     ```
   - With KernelSU:  
     ```
     bash build.sh TARGET_DEVICE ksu
     ```

   Example:  
   - lmi (Redmi K30 Pro/POCO F2 Pro) without KernelSU:  
     ```
     bash build.sh lmi
     ```
   - umi (Xiaomi 10) with KernelSU:  
     ```
     bash build.sh umi ksu
     ```

   Additionally, `buildall.sh` can build for all supported devices at once.