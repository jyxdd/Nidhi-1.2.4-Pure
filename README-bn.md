# Xiaomi SM8250 Android™ ডিভাইসের জন্য NidhiKernel

## সূচিপত্র
- [ভূমিকা](#ভূমিকা)
- [বৈশিষ্ট্য](#বৈশিষ্ট্য)
- [নোট](#নোট)
- [কমিউনিটি](#কমিউনিটি)
- [সমর্থিত ডিভাইস](#সমর্থিত-ডিভাইস)
- [বিল্ড নির্দেশাবলী](#বিল্ড-নির্দেশাবলী)
  - [TUI বিল্ড](#tui-বিল্ড)
  - [ম্যানুয়াল বিল্ড](#ম্যানুয়াল-বিল্ড)

---

## ভূমিকা

এই রিপোজিটরি [SO-TS/android_kernel_xiaomi_sm8250](https://github.com/SO-TS/android_kernel_xiaomi_sm8250)-এর `android16-aptusitu` ব্রাঞ্চের উপর ভিত্তি করে তৈরি।

HyperOS/MIUI সাপোর্টের জন্য প্রয়োজনীয় কোড এবং কিছু ডিভাইস-নির্দিষ্ট ড্রাইভার [Strawing-এর রিপো](https://github.com/liyafe1997/kernel_xiaomi_sm8250_mod) থেকে কমিট ইতিহাস তুলনা করে বেছে নেওয়া হয়েছে, যা মূলত [UtsavBalar1231-এর রিপো](https://github.com/UtsavBalar1231/kernel_xiaomi_sm8250) এবং [Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) থেকে এসেছে।

এই কার্নেলটি একাধিক উৎসের অবদানকে একত্রিত করে তৈরি করা হয়েছে যাতে এটি যতটা সম্ভব ব্যবহারযোগ্য এবং স্বয়ংসম্পূর্ণ হয়।

---

## বৈশিষ্ট্য

এই কার্নেলটি [sidex15-এর KernelSU-Next ফর্ক](https://github.com/sidex15/KernelSU-Next) ([KernelSU-Next](https://github.com/rifsxd/KernelSU-Next), যা KernelSU-এর একটি ফর্ক) এবং [SuSFS](https://gitlab.com/simonpunk/susfs4ksu) সমর্থন করে। অনুগ্রহ করে [KernelSU-Next ম্যানেজার](https://github.com/rifsxd/KernelSU-Next/releases) নিজে ইনস্টল করুন।

NoKernelSU সংস্করণটি Magisk এবং APatch (এবং তাদের ফর্ক) সমর্থন করে।

নিচে কিছু মূল বৈশিষ্ট্য দেওয়া হলো:
1. USB সিরিয়াল ড্রাইভার সমর্থন (CH340 / FTDI / PL2303 / OTI6858 / TI / SPCP8X5 / QT2 / UPD78F0730 / CP210X)
2. CAN বাস এবং USB CAN অ্যাডাপ্টার (যেমন CANable) সমর্থন
3. উন্নত ফ্ল্যাশ TRIM আচরণের জন্য রিয়েলটাইম ডিসকার্ড সহ F2FS সমর্থন
4. EROFS সমর্থন
5. zRAM-এ একাধিক কম্প্রেশন অ্যালগরিদম সমর্থন, যার মধ্যে রয়েছে LZ4, LZ4HC, lz4k_oplus, LZ4KD, এবং ZSTD
6. Linux 5.10 থেকে ব্যাকপোর্ট করা BPF (Android 16 সামঞ্জস্যপূর্ণ)
7. টাচস্ক্রিন, ক্যামেরা, অডিও, GPU/DRM/MSM, এবং CNSS2 ড্রাইভার Xiaomi-নির্দিষ্ট ইমপ্লিমেন্টেশন ব্যবহার করে (UtsavBalar1231-এর রিপোজিটরি এবং MiCode থেকে প্রাপ্ত। Display/DRM ড্রাইভারের AOSP সংস্করণটি LineageOS সংস্করণ); এছাড়াও, টাচস্ক্রিন ড্রাইভারে `double_tap` নোড যোগ করা হয়েছে
8. [ব্যাটারি শতাংশ 1%-এ আটকে থাকার সমস্যা](https://github.com/liyafe1997/Xiaomi-fix-battery-one-percent) ঠিক করে এবং উচ্চ-ক্ষমতার প্রতিস্থাপন ব্যাটারি শনাক্তকরণ সমর্থন করে
9. [BBG (Baseband-guard)](https://github.com/vc-teahouse/Baseband-guard) ইন্টিগ্রেট করা হয়েছে

---

## নোট

**দ্রষ্টব্য**: কার্নেল জিপ প্যাকেজে `dtbo.img` থাকে না এবং এটি আপনার dtbo পার্টিশন ফ্ল্যাশ করবে না।
স্টক `dtbo` অথবা কোনও থার্ড-পার্টি রম-এর বান্ডিল করা ফাইল ব্যবহার করার পরামর্শ দেওয়া হয় (যদি মূল লেখক নিশ্চিত করেন যে এটি ভালো কাজ করে)।
এই সোর্স থেকে তৈরি `dtbo.img`-এ কিছু সমস্যা রয়েছে—উদাহরণস্বরূপ, লক স্ক্রিনে, স্ক্রিন বন্ধ করার চেষ্টা করার সময় ডিসপ্লে হঠাৎ সর্বোচ্চ উজ্জ্বলতায় জ্বলে উঠতে পারে।
যদি আপনি অন্য কোনো থার্ড-পার্টি কার্নেল ফ্ল্যাশ করে থাকেন বা অদ্ভুত সমস্যার সম্মুখীন হন, তবে অনুগ্রহ করে পরীক্ষা করুন আপনার `dtbo` প্রতিস্থাপিত হয়েছে কিনা।

**সতর্কতা**: আপনি যদি HyperOS/MIUI ব্যবহার করেন, তবে অনুগ্রহ করে **MIUI সংস্করণ** ফ্ল্যাশ করুন।
AOSP সংস্করণে আলাদা ডিসপ্লে ড্রাইভার রয়েছে, যার কারণে HyperOS/MIUI-তে স্ক্রিন সঠিকভাবে প্রদর্শিত নাও হতে পারে।
ফ্ল্যাশ করার পরে যদি আপনি কালো স্ক্রিন (black screen) পান, তবে পরীক্ষা করুন আপনি HyperOS/MIUI-তে আছেন কিন্তু AOSP সংস্করণ ফ্ল্যাশ করেছেন কিনা।
এই নির্দিষ্ট সমস্যা সম্পর্কে কোনো ফিডব্যাক গ্রহণ করা হবে না।

---

## সমর্থিত ডিভাইস
| ডিভাইস কোডনেম | ডিভাইসের নাম |
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

## বিল্ড নির্দেশাবলী

### TUI বিল্ড
অনুগ্রহ করে বিস্তারিত [TUI-এর জন্য বিল্ড নির্দেশাবলী](docs/buildall-instructions-bn.md) দেখুন।

---

### ম্যানুয়াল বিল্ড
অনুগ্রহ করে বিস্তারিত [বিল্ড নির্দেশাবলী](docs/build-instructions-bn.md) দেখুন।
