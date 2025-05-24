# NetHunter CLI - توثيق شامل للأداة المتقدمة (الإصدار 3.1)

## 1. نظرة عامة

NetHunter CLI هي أداة متقدمة ومتكاملة لتثبيت وإدارة Kali NetHunter في بيئة Termux على أجهزة Android. تم تطوير هذه الأداة بمعايير هندسية وأمنية عالية، مع التركيز على المرونة والموثوقية والأمان.

**تحديث هام (الإصدار 3.1):** تم تحديث آلية تنزيل صور NetHunter للتوافق مع التغييرات الأخيرة في مستودعات Kali الرسمية. لم تعد الأداة تعتمد على ملف `index.json`، وبدلاً من ذلك تقوم ببناء روابط التنزيل مباشرة بناءً على نوع الصورة والمعمارية والإصدار المحدد (حالياً `kali-2025.1c`). تم تحسين التحقق من الروابط ورسائل الخطأ لتوفير تجربة أكثر سلاسة.

### 1.1 الميزات الرئيسية

- **بنية وحدات متكاملة**: تقسيم الكود إلى وحدات منفصلة ومستقلة.
- **تنزيل مباشر للصور**: بناء روابط التنزيل ديناميكياً من مستودعات Kali الرسمية (لا يعتمد على `index.json`).
- **اختيار مرن للصور**: دعم تحديد نوع الصورة (full, minimal, nano) والمعمارية (arm64, armhf, amd64, i386) عبر الأوامر.
- **تحقق محسن من الروابط**: فحص أفضل لصلاحية روابط التنزيل قبل البدء.
- **رسائل خطأ واضحة**: توفير معلومات أدق للمستخدم عند حدوث مشاكل في التنزيل أو غيرها.
- **واجهة سطر أوامر متكاملة**: دعم كامل للأعلام والخيارات المتقدمة.
- **نظام سجلات متقدم**: تسجيل مفصل لمعلومات النظام والأداء.
- **تشغيل آلي**: دعم التثبيت بدون تدخل يدوي.
- **نسخ احتياطي واستعادة**: وظائف مدمجة للنسخ الاحتياطي والاستعادة.
- **اختبارات متكاملة**: إطار اختبار كامل للوحدات والتكامل (إذا تم تضمينه).

## 2. دليل التثبيت على Termux

لتثبيت NetHunter CLI على Termux، اتبع الخطوات التالية:

1.  **تحديث حزم Termux:**
    ```bash
    pkg update && pkg upgrade -y
    ```

2.  **تثبيت Git و Wget و Proot (إذا لم تكن مثبتة):**
    ```bash
    pkg install git wget proot -y
    ```

3.  **استنساخ المستودع:**
    ```bash
    git clone https://github.com/ESCANORy/nethunter.git
    ```

4.  **الدخول إلى مجلد الأداة:**
    ```bash
    cd nethunter/dist
    ```

5.  **إعطاء صلاحيات التنفيذ للسكربت الرئيسي:**
    ```bash
    chmod +x nethunter-cli
    ```

6.  **تشغيل أمر التثبيت:**
    (اختر نوع الصورة والمعمارية المناسبة لجهازك)
    ```bash
    # مثال: تثبيت النسخة الكاملة لمعمارية arm64
    ./nethunter-cli install --type full --arch arm64
    
    # مثال: تثبيت النسخة المصغرة لمعمارية armhf
    ./nethunter-cli install --type minimal --arch armhf
    
    # إذا لم تحدد النوع أو المعمارية، ستحاول الأداة اكتشاف المعمارية وتثبيت النوع الافتراضي (full)
    ./nethunter-cli install 
    ```

7.  **بدء استخدام NetHunter:**
    بعد اكتمال التثبيت، يمكنك بدء NetHunter باستخدام الأوامر التالية:
    ```bash
    nethunter  # أو الاختصار nh
    ```

## 3. الاستخدام والأوامر

```bash
Usage: nethunter-cli [command] [options]

Commands:
  install    Install NetHunter
  update     Update existing NetHunter installation (reinstall)
  uninstall  Remove NetHunter
  backup     Create backup of NetHunter
  restore    Restore NetHunter from backup
  verify     Verify NetHunter installation
  help       Show this help message

Options:
  -t, --type TYPE       Image type (full, minimal, nano) [Default: full]
  -a, --arch ARCH       Architecture (arm64, armhf, amd64, i386) [Default: auto-detected]
  -d, --dir DIR         Installation directory [Default: ~/nethunter]
  -k, --keep-archive    Keep downloaded archive after installation
  -f, --force           Force operation without confirmation
  -q, --quiet           Quiet mode (minimal output)
  -v, --verbose         Verbose mode (detailed output)
  -y, --yes             Automatic yes to prompts (non-interactive)
  --dev                 Development mode (skip integrity checks)
  --no-color            Disable colored output

Examples:
  # تثبيت النسخة الكاملة (مع اكتشاف المعمارية تلقائياً)
  nethunter-cli install
  
  # تثبيت النسخة المصغرة لمعمارية arm64
  nethunter-cli install --type minimal --arch arm64
  
  # تحديث التثبيت الحالي (سيقوم بإعادة التثبيت)
  nethunter-cli update --keep-archive
  
  # إلغاء التثبيت بدون طلب تأكيد
  nethunter-cli uninstall --force
```

## 4. استكشاف الأخطاء وإصلاحها

-   **فشل التنزيل / خطأ 404:**
    -   تأكد من صحة `type` (full, minimal, nano) و `arch` (arm64, armhf, etc.) التي اخترتها.
    -   تأكد من اتصالك بالإنترنت.
    -   قد يكون هناك تغيير في بنية مستودع Kali. تحقق من الروابط يدوياً في المتصفح بدءاً من `https://kali.download/nethunter-images/kali-2025.1c/rootfs/`.
    -   إذا استمرت المشكلة، قد تحتاج الأداة إلى تحديث لتعكس تغييرات أحدث في المستودع.
-   **فشل فك الضغط:**
    -   تأكد من وجود مساحة كافية على جهازك.
    -   قد يكون الملف المنزل تالفاً. حاول حذفه من مجلد الكاش (`~/.nethunter/cache`) وإعادة التنزيل.
-   **فشل تثبيت الحزم المطلوبة (proot, wget, etc.):**
    -   تأكد من عمل مستودعات `pkg` (apt) بشكل صحيح. جرب `pkg update`.
    -   قد تحتاج إلى تغيير مستودع Termux باستخدام `termux-change-repo`.

## 5. البنية الهندسية (للمطورين)

(هذا القسم يصف بنية الكود كما كانت في الإصدار السابق، قد تحتاج بعض التفاصيل للتحديث لتعكس إزالة الاعتماد على JSON)

### 5.1 هيكل الملفات

```
nethunter-cli/
├── dist/
│   ├── nethunter-cli       # نقطة الدخول الرئيسية
│   └── src/                # مجلد الوحدات البرمجية
│       ├── core.sh         # الوظائف والمتغيرات الأساسية
│       ├── utils.sh        # وظائف مساعدة (تنزيل، فحص، إلخ)
│       ├── install.sh      # وظائف التثبيت، التحديث، الإزالة
│       ├── gpg.sh          # وظائف التوقيع الرقمي (إذا كانت مفعلة)
│       ├── cli.sh          # واجهة سطر الأوامر وتحليل الخيارات
│       └── logging.sh      # نظام السجلات المتقدم
└── README.md               # هذا الملف
```

### 5.2 تدفق العمل

1.  **التهيئة (core.sh, logging.sh):** تحميل الوحدات، إعداد البيئة، تهيئة السجلات.
2.  **تحليل الأوامر (cli.sh):** معالجة أوامر المستخدم والأعلام (`install`, `--type`, etc.).
3.  **التحقق (utils.sh):** فحص البيئة (Termux)، المعمارية، المساحة، الحزم المطلوبة.
4.  **التنفيذ (install.sh, utils.sh):** تنفيذ العملية المطلوبة (تثبيت، تحديث، إلخ)، بما في ذلك:
    *   بناء رابط التنزيل (`nh_get_image_url` في `install.sh`).
    *   التحقق من الرابط (`nh_check_url` في `utils.sh`).
    *   تنزيل الملف (`nh_download_file` في `utils.sh`).
    *   فك الضغط (`nh_extract_archive` في `utils.sh`).
    *   إنشاء سكربت التشغيل والaliases.
5.  **التسجيل (core.sh):** تسجيل النتائج والأحداث في ملف السجل.
6.  **التنظيف (install.sh):** تنظيف الملفات المؤقتة أو الأرشيف المنزل (إذا لم يتم طلب الاحتفاظ به).


