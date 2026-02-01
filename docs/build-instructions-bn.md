# কার্নেল বিল্ড স্ক্রিপ্ট - v2.0

লগিং, ভার্বোস মোড, কাস্টম জব কন্ট্রোল, এবং AOSP/MIUI রমের জন্য ডার্টি বিল্ড সাপোর্ট সহ একটি পরিপূর্ণ কার্নেল বিল্ড স্ক্রিপ্ট।

---

## নতুন বৈশিষ্ট্যসমূহ

### ১. **অটোমেটিক বিল্ড লগিং**
- সমস্ত বিল্ড আউটপুট স্বয়ংক্রিয়ভাবে টাইমস্ট্যাম্পযুক্ত ফাইলে লগ করা হয়
- প্রথম ত্রুটিতেই সহায়ক বার্তা সহ বিল্ড বন্ধ হয়ে যায়
- সম্পূর্ণ বিল্ড ইতিহাস সহ সহজ ডিবাগিং
- `--debug` ফ্ল্যাগ সরানো হয়েছে (অটোমেটিক লগিং দ্বারা প্রতিস্থাপিত)

### ২. **ভার্বোস মোড (-V, --verbose)**
- বিস্তারিত মেক আউটপুটের জন্য `V=1` সেট করে
- প্রতিটি কমান্ড এক্সিকিউট হওয়ার সময় দেখা যায়
- বিল্ড অগ্রগতি ট্র্যাক করা সহজ

### ৩. **কাস্টম জব কন্ট্রোল (-J, --jobs)**
- প্যারালাল জব সেট করা: `-J8`, `--jobs 12`
- পরিসীমা: ১ থেকে $(nproc)
- মান CPU কোরের বেশি হলে স্বয়ংক্রিয়ভাবে সীমাবদ্ধ করে
- সীমাবদ্ধ হলে বুদ্ধিমান সতর্কতা দেয়

### ৪. **ডার্টি বিল্ড (-D, --dirty)**
- দ্রুত পুনরাবৃত্তিমূলক বিল্ডের জন্য `rm -rf out/` এড়িয়ে যায়
- ছোট পরিবর্তনের পরীক্ষার জন্য উপযুক্ত
- প্রতি বিল্ডে ১-২ মিনিট সময় বাঁচায়

### ৫. **হেল্প সিস্টেম (-H, --help)**
- বিস্তারিত ব্যবহারের তথ্য
- সাধারণ পরিস্থিতির জন্য উদাহরণ
- সর্বদা আপডেট থাকা ডকুমেন্টেশন

---

## পূর্বশর্ত

### ১. বিল্ড এনভায়রনমেন্ট প্রস্তুত করা

আপনার `git`, `make`, `curl`, `bison`, `flex`, `zip` ইত্যাদি প্রয়োজন।

- **Debian/Ubuntu:**
  ```bash
  sudo apt install build-essential git curl wget bison flex zip bc cpio libssl-dev ccache tar
  ```
  আপনার `python` ও প্রয়োজন (শুধু `python3` নয়):
  ```bash
  sudo apt install python-is-python3
  ```

- **RHEL/RPM-ভিত্তিক OS:**
  ```bash
  sudo yum groupinstall 'Development Tools'
  sudo yum install wget bc openssl-devel ccache tar
  ```

  **নোট:** `build.sh`-এ `ccache` সক্রিয় করা আছে (`$HOME/.cache/ccache_mikernel`)। আপনি এটি সরাতে/পরিবর্তন করতে পারেন।

### ২. টুলচেইন ডাউনলোড

[ZyC-Clang v15](https://github.com/ZyCromerZ/Clang/releases/tag/15.0.7-20251111-release) টুলচেইন ডাউনলোড করুন:
```bash
mkdir zyc-clang
cd zyc-clang
wget https://github.com/ZyCromerZ/Clang/releases/download/15.0.7-20251111-release/Clang-15.0.7-20251111.tar.gz
tar -zxvf Clang-15.0.7-20251111.tar.gz
cd ..
```

---

## ব্যবহার

### সিনট্যাক্স
```bash
bash build.sh <device> [ksu] [aosp|miui] [OPTIONS]
```

### আর্গুমেন্ট

| আর্গুমেন্ট | আবশ্যক | অপশন | ডিফল্ট | বিবরণ |
|----------|----------|---------|---------|-------------|
| device | হ্যাঁ | ডিভাইসের কোডনেম | - | টার্গেট ডিভাইস |
| ksu | না | `ksu` বা খালি | No KSU | KernelSU+SUSFS সক্রিয় করে |
| aosp\|miui | না | `aosp`, `miui`, খালি | Both | রমের ধরন |

### অপশন

| অপশন | সংক্ষিপ্ত | বিবরণ | উদাহরণ |
|--------|-------|-------------|---------|
| --verbose | -V | ভার্বোস বিল্ড (V=1) | `-V` |
| --jobs <N> | -J<N> | প্যারালাল জব (১-nproc) | `-J8`, `--jobs 12` |
| --dirty | -D | out/ ডিরেক্টরি রাখা | `-D` |
| --help | -H | সাহায্য দেখানো | `-H` |

---

## উদাহরণ

### সাধারণ বিল্ড
```bash
# উভয় রম, KSU নেই, ডিফল্ট জব
bash build.sh lmi

# উভয় রম সাথে KSU
bash build.sh lmi ksu

# শুধুমাত্র AOSP
bash build.sh lmi ksu aosp

# শুধুমাত্র MIUI
bash build.sh lmi "" miui
```

### অপশন সহ
```bash
# ভার্বোস মোড
bash build.sh lmi -V
bash build.sh lmi --verbose

# কাস্টম জব
bash build.sh lmi -J8
bash build.sh lmi --jobs 12

# ডার্টি বিল্ড (দ্রুত পুনরাবৃত্তিমূলক)
bash build.sh lmi -D
bash build.sh lmi --dirty

# সব অপশন একসাথে
bash build.sh lmi ksu -V -J8 -D
```

### অ্যাডভান্সড উদাহরণ
```bash
# AOSP, KSU, ভার্বোস, ১৬ জব
bash build.sh lmi ksu aosp -V -J16

# MIUI, ডার্টি, ৪ জব (লো-পাওয়ার মোড)
bash build.sh lmi "" miui -D -J4

# ফুল রিলিজ (উভয় রম, ক্লিন, সর্বোচ্চ গতি)
bash build.sh lmi ksu -J$(nproc)

# ডেভেলপমেন্ট মোড (ডার্টি, ভার্বোস, সীমিত জব)
bash build.sh lmi -D -V -J4
```

---

## বিল্ড লগিং

### অটোমেটিক লগিং
প্রতিটি বিল্ড স্বয়ংক্রিয়ভাবে একটি লগ ফাইল তৈরি করে:
```
build_20240127_143022.log
build_20240127_150315.log
build_20240127_163045.log
```

### যা লগ করা হয়
- বিল্ড কনফিগারেশন
- সমস্ত মেক আউটপুট
- কার্নেল কনফিগারেশন পরিবর্তন
- DTS প্যাচিং বিস্তারিত
- ত্রুটির বার্তা
- টাইমস্ট্যাম্প

### বিল্ড ব্যর্থ হলে
```
======================================
  Build Failed!
======================================
Error occurred during: Compiling kernel
Please check the log file for details: build_20240127_143022.log
```

### লগ দেখা
```bash
# সর্বশেষ লগ দেখা
tail -f build_*.log

# ত্রুটি খোঁজা
grep -i error build_20240127_143022.log

# শেষ ১০০ লাইন দেখা
tail -n 100 build_20240127_143022.log
```

---

## ফিচারের বিস্তারিত

### ১. অটোমেটিক লগিং

**কিভাবে কাজ করে:**
- `logs` ডিরেক্টরির এক ধাপ উপরে টাইমস্ট্যাম্পযুক্ত লগ ফাইল তৈরি করে: `build_YYYYMMDD_HHMMSS.log`
- `tee` দিয়ে সমস্ত stdout/stderr ক্যাপচার করা হয়
- প্রথম মেক ত্রুটিতেই থামানো হয়
- লগ ফাইল রেফারেন্স সহ পরিষ্কার ত্রুটির বার্তা

**উদাহরণ আউটপুট:**
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

**ত্রুটি হলে:**
```bash
======================================
  Build Failed!
======================================
Error occurred during: Compiling kernel
Please check the log file for details: build_20240127_143022.log
```

### ২. ভার্বোস মোড (-V, --verbose)

**এটি কি করে:**
- মেক কমান্ডে `V=1` যোগ করে
- পুরো কমান্ড লাইন দেখায়
- ঠিক কি কম্পাইল হচ্ছে তা প্রকাশ করে

**সাধারণ আউটপুট:**
```
  CC      drivers/usb/core/hub.o
  CC      drivers/usb/core/hcd.o
```

**ভার্বোস আউটপুট:**
```
clang -Wp,-MD,drivers/usb/core/.hub.o.d -nostdinc -isystem /home/user/zyc-clang/bin/../lib/clang/18.0.0/include -I./arch/arm64/include -I./arch/arm64/include/generated ...
```

**ব্যবহার:**
```bash
bash build.sh lmi -V
bash build.sh lmi --verbose
bash build.sh lmi ksu aosp -V
```

### ৩. কাস্টম জব কন্ট্রোল (-J, --jobs)

**সিনট্যাক্স:**
```bash
-J8          # সংক্ষিপ্ত রূপ
--jobs 12    # দীর্ঘ রূপ
```

**অটো-লিমিটিং:**
```bash
# ৮-কোর সিস্টেমে
$ bash build.sh lmi -J16
Warning: Job count 16 exceeds available cores (8)
Limiting to 8 jobs
```

**উদাহরণ:**
```bash
# ৪ জব ব্যবহার (লো পাওয়ার)
bash build.sh lmi -J4

# ৮ জব ব্যবহার (ভারসাম্যপূর্ণ)
bash build.sh lmi -J8

# সব কোর ব্যবহার
bash build.sh lmi -J$(nproc)

# দীর্ঘ রূপ
bash build.sh lmi --jobs 12
```

**কেন কাস্টম জব?**
- **লো জব (-J4)**: কম CPU/মেমরি ব্যবহার, সিস্টেম রেসপন্সিভ থাকে
- **মিডিয়াম জব (-J8)**: ভারসাম্যপূর্ণ পারফরম্যান্স
- **হাই জব (-J16+)**: সর্বোচ্চ গতি, সমস্ত রিসোর্স ব্যবহার করে

### ৪. ডার্টি বিল্ড (-D, --dirty)

**এটি কি করে:**
- `rm -rf out/` এড়িয়ে যায়
- কম্পাইল করা অবজেক্ট রাখে
- শুধুমাত্র পরিবর্তিত ফাইলগুলি পুনরায় বিল্ড করে

**সময় সাশ্রয়:**
```
ক্লিন বিল্ড: ১৫ মিনিট
ডার্টি বিল্ড: ২-৩ মিনিট (ছোট পরিবর্তন)
```

**কখন ব্যবহার করবেন:**
```bash
# পুনরাবৃত্তিমূলক ডেভেলপমেন্ট
bash build.sh lmi -D          # প্রথম পরিবর্তন
bash build.sh lmi -D          # দ্বিতীয় পরিবর্তন
bash build.sh lmi -D          # তৃতীয় পরিবর্তন

# রিলিজের জন্য ক্লিন বিল্ড
bash build.sh lmi             # সম্পূর্ণ রিবিল্ড
```

**সতর্কতা:**
```
Dirty build enabled - keeping out/ directory
```

**সেরা অভ্যাস:**
- ডেভেলপমেন্টের সময় `-D` ব্যবহার করুন
- রিলিজ বিল্ডের জন্য `-D` এড়িয়ে চলুন
- বড় পরিবর্তনের পর ক্লিন বিল্ড করুন

### ৫. হেল্প সিস্টেম (-H, --help)

**ব্যবহার:**
```bash
bash build.sh -H
bash build.sh --help
```

**যা দেখায়:**
- সম্পূর্ণ সিনট্যাক্স
- সমস্ত আর্গুমেন্ট এবং অপশন
- ব্যবহারের উদাহরণ
- গুরুত্বপূর্ণ নোট

---

## বিল্ড মোড তুলনা

| মোড | কমান্ড | ব্যবহারের ক্ষেত্র | গতি | আউটপুট |
|------|---------|----------|-------|--------|
| **Standard** | `bash build.sh lmi` | রিলিজ বিল্ড | সাধারণ | শান্ত |
| **Verbose** | `bash build.sh lmi -V` | ডিবাগিং | সাধারণ | বিস্তারিত |
| **Fast** | `bash build.sh lmi -J16` | দ্রুত বিল্ড | দ্রুত | শান্ত |
| **Dirty** | `bash build.sh lmi -D` | ডেভেলপমেন্ট | খুব দ্রুত | শান্ত |
| **Debug** | `bash build.sh lmi -V -J4 -D` | ট্রাবলশুটিং | ধীর | বিস্তারিত |
| **Production** | `bash build.sh lmi ksu -J$(nproc)` | ফাইনাল রিলিজ | দ্রুত | শান্ত |

---

## ওয়ার্কফ্লো

### ডেভেলপমেন্ট ওয়ার্কফ্লো
```bash
# প্রথম বিল্ড (ক্লিন)
bash build.sh lmi ksu aosp

# কোড পরিবর্তন...

# দ্রুত রিবিল্ড (ডার্টি)
bash build.sh lmi ksu aosp -D

# আরও পরিবর্তন...

# আবার দ্রুত রিবিল্ড
bash build.sh lmi ksu aosp -D

# টেস্টিংয়ের জন্য ফাইনাল ক্লিন বিল্ড
bash build.sh lmi ksu aosp
```

### ডিবাগিং ওয়ার্কফ্লো
```bash
# বিল্ড ব্যর্থ?
bash build.sh lmi -V -J4

# লগ চেক
tail -f build_20240127_143022.log

# ত্রুটি ঠিক করুন, রিবিল্ড
bash build.sh lmi -V -J4 -D

# এখনও ব্যর্থ? আবার লগ চেক করুন
grep -i error build_20240127_143022.log
```

### রিলিজ ওয়ার্কফ্লো
```bash
# ক্লিন, ফুল বিল্ড, সব কোর
bash build.sh lmi ksu -J$(nproc)

# উভয় জিপ তৈরি হয়েছে যাচাই করুন
ls -lh out/NidhiKernel_*

# বিল্ড কাজ করছে টেস্ট করুন
adb shell uname -r
# প্রত্যাশিত: 5.10.0-Nidhi-1.2.3
```

### মাল্টি-ডিভাইস ওয়ার্কফ্লো
```bash
#!/bin/bash
for device in lmi umi alioth; do
  echo "Building for $device..."
  bash build.sh $device ksu -J$(nproc)
done
```

---

## আউটপুট স্ট্রাকচার

### তৈরি হওয়া ফাইল
```
.
├── build_20240127_143022.log                    # বিল্ড লগ
├── out/
│   ├── lmi/                                     # ডিভাইস-নির্দিষ্ট ডিরেক্টরি
│   │   ├── NidhiKernel_1.2.3_AOSP_lmi_KSUN-SUSFS_20240127_143022.zip
│   │   └── NidhiKernel_1.2.3_MIUI_lmi_KSUN-SUSFS_20240127_143530.zip
│   ├── umi/                                     # অন্য ডিভাইস
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

### ডিভাইস-সংগঠিত আউটপুট

**নতুন বৈশিষ্ট্য:** জিপগুলি এখন ডিভাইস দ্বারা সংগঠিত!

**স্ট্রাকচার:**
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

**সুবিধা:**
- নির্দিষ্ট ডিভাইসের জন্য বিল্ড খুঁজে পাওয়া সহজ
- মাল্টি-ডিভাইস বিল্ডের জন্য পরিষ্কার সংগঠন
- এক ডিরেক্টরিতে মিশ্রিত জিপ নেই
- রিলিজ ম্যানেজমেন্টের জন্য আরও ভালো

**বিল্ড খোঁজা:**
```bash
# lmi-এর সমস্ত বিল্ড
ls out/lmi/

# সমস্ত AOSP বিল্ড
find out/ -name "*AOSP*.zip"

# সমস্ত KSU বিল্ড
find out/ -name "*KSU*.zip"

# ডিভাইসের জন্য সর্বশেষ বিল্ড
ls -lt out/alioth/ | head -n 2
```

### লগ ফাইল কন্টেন্ট
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

## টিপস ও ট্রিকস

### ১. স্পিড অপ্টিমাইজেশন
```bash
# দ্রুততম বিল্ড (সব কোর, ডার্টি)
bash build.sh lmi -D -J$(nproc)

# ভারসাম্যপূর্ণ (সিস্টেমের জন্য কোর বাকি রাখা)
bash build.sh lmi -J$(($(nproc) - 2))
```

### ২. লো মেমরি সিস্টেম
```bash
# OOM এড়াতে কম জব ব্যবহার করুন
bash build.sh lmi -J4
```

### ৩. ভার্বোস ডিবাগিং
```bash
# সবকিছু দেখুন
bash build.sh lmi -V -J1 2>&1 | tee manual.log
```

### ৪. ক্লিন আফটার ডার্টি বিল্ড
```bash
# অনেক ডার্টি বিল্ডের পর, ক্লিন বিল্ড করুন
rm -rf out/
bash build.sh lmi
```

### ৫. লগে সতর্কতা চেক করা
```bash
# সমস্ত সতর্কতা খুঁজুন
grep -i warning build_*.log

# নির্দিষ্ট ত্রুটি খুঁজুন
grep -i "undefined reference" build_*.log
```

---

## গুরুত্বপূর্ণ নোট

### বিল্ড লগ ফাইল
- প্রতি বিল্ডের জন্য **স্বয়ংক্রিয়ভাবে তৈরি** হয়
- স্বয়ংক্রিয়ভাবে **মুছে ফেলা হয় না** - ম্যানুয়ালি ম্যানেজ করুন
- **ডিবাগিংয়ের জন্য দরকারী** - সাম্প্রতিক লগ রাখুন
- **বড় হতে পারে** - পুরোনো লগ কম্প্রেস বা ডিলিট করুন

### ডার্টি বিল্ড
- বড় পরিবর্তনের পর সমস্যা সৃষ্টি করতে পারে
- রিলিজের জন্য ক্লিন বিল্ড সুপারিশ করা হয়
- পুনরাবৃত্তিমূলক ডেভেলপমেন্টের জন্য দুর্দান্ত
- উল্লেখযোগ্য সময় বাঁচায়

### জব কাউন্ট
- বেশি জব = বেশি CPU/RAM ব্যবহার
- কম জব = লো-স্পেক সিস্টেমে বেশি স্থিতিশীল
- অপটিমাল: $(nproc) বা $(nproc) - 2

### ভার্বোস মোড
- ডিবাগিংয়ের জন্য সহায়ক
- লগ অনেক বড় করে তোলে
- আউটপুট দেখানোর কারণে কিছুটা ধীর
- সমস্যা সমাধানের সময় ব্যবহার করুন

---

## পূর্ববর্তী সংস্করনের সাথে তুলনা

| বৈশিষ্ট্য | পুরাতন | নতুন |
|---------|-----|-----|
| ডিবাগ মোড | `--debug` ফ্ল্যাগ | সরানো হয়েছে |
| লগিং | নেই | অটোমেটিক |
| ভার্বোস | নেই | `-V, --verbose` |
| জব কন্ট্রোল | ফিক্সড $(nproc) | `-J<N>, --jobs <N>` |
| ডার্টি বিল্ড | নেই | `-D, --dirty` |
| হেল্প | সাধারণ | বিস্তারিত `-H` |
| এরর হ্যান্ডলিং | ত্রুটিতে এক্সিট | স্টপ + লগ ফাইল বার্তা |
| বিল্ড ট্র্যাকিং | নেই | টাইমস্ট্যাম্পযুক্ত লগ |

---

## কমান্ড রেফারেন্স

### কুইক রেফারেন্স

| কি চান | কমান্ড |
|---------------|---------|
| নরমাল বিল্ড | `bash build.sh lmi` |
| সাথে KSU | `bash build.sh lmi ksu` |
| শুধু AOSP | `bash build.sh lmi ksu aosp` |
| শুধু MIUI | `bash build.sh lmi ksu miui` |
| ভার্বোস | `bash build.sh lmi -V` |
| ৮ জব | `bash build.sh lmi -J8` |
| ডার্টি বিল্ড | `bash build.sh lmi -D` |
| সব অপশন | `bash build.sh lmi ksu aosp -V -J8 -D` |
| হেল্প | `bash build.sh -H` |

### অপশন কম্বিনেশন

```bash
# ডেভেলপমেন্ট (দ্রুত, ভার্বোস, ডার্টি)
bash build.sh lmi -V -D -J8

# প্রোডাকশন (ক্লিন, সর্বোচ্চ গতি)
bash build.sh lmi ksu -J$(nproc)

# ডিবাগিং (ভার্বোস, ধীর, ডার্টি)
bash build.sh lmi -V -J1 -D

# লো পাওয়ার (কম জব, ডার্টি)
bash build.sh lmi -D -J4
```

---

## ট্রাবলশুটিং

### বিল্ড শুরুতেই ব্যর্থ
**চেক করুন:** নির্দিষ্ট ত্রুটির জন্য লগ ফাইল
```bash
tail -n 50 build_20240127_143022.log
```

### আউট অফ মেমরি
**সমাধান:** জব কমান
```bash
bash build.sh lmi -J4
```

### ডার্টি বিল্ড সমস্যা
**সমাধান:** ক্লিন বিল্ড
```bash
rm -rf out/
bash build.sh lmi
```

### লগে ত্রুটি খুঁজে পাচ্ছেন না
**সমাধান:** লগ ফাইল সার্চ করুন
```bash
grep -i "error:" build_*.log
grep -i "failed" build_*.log
```

### জব কাউন্ট সতর্কতা
**এটি স্বাভাবিক** যদি আপনি nproc অতিক্রম করেন
```
Warning: Job count 16 exceeds available cores (8)
Limiting to 8 jobs
```

---

## এরপর কি?

সফল বিল্ডের পর:
```bash
# আউটপুট চেক করুন (এখন ডিভাইস অনুযায়ী সংগঠিত)
ls -lh out/lmi/
ls -lh out/umi/
ls -lh out/alioth/

# অথবা সব বিল্ড দেখুন
find out/ -name "*.zip"

# রিকভারি (TWRP) দিয়ে ফ্ল্যাশ করুন
# অথবা

# ফাস্টবুট দিয়ে বুট করুন
fastboot boot out/arch/arm64/boot/Image

# ডিভাইসে যাচাই করুন
adb shell uname -r
# প্রত্যাশিত: 5.10.0-Nidhi-1.2.3
```
