# NetHunter CLI - توثيق شامل للأداة المتقدمة (الإصدار 3.2)

## 1. نظرة عامة

NetHunter CLI هي أداة متقدمة ومتكاملة لتثبيت وإدارة Kali NetHunter في بيئة Termux على أجهزة Android. تم تطوير هذه الأداة بمعايير هندسية وأمنية عالية، مع التركيز على المرونة والموثوقية والأمان.

**تحديث هام (الإصدار 3.2):** تم إجراء تحسينات كبيرة على التوافق مع Termux، وإصلاح أخطاء بناء الجملة، وتحسين معالجة الأخطاء بناءً على ملاحظات المستخدمين. تم استبدال `awk` بأدوات POSIX متوافقة، وتحسين التعامل مع أكواد الألوان، وتصحيح منطق تنزيل `wget`، وإضافة خيار لتعطيل الألوان.

### 1.1 الميزات الرئيسية

- **بنية وحدات متكاملة**: تقسيم الكود إلى وحدات منفصلة ومستقلة.
- **توافق محسن مع Termux**: استخدام أدوات POSIX متوافقة (مثل `cut`, `sed` بدلاً من `awk`) ومعالجة أفضل للألوان.
- **تنزيل مباشر للصور**: بناء روابط التنزيل ديناميكياً من مستودعات Kali الرسمية.
- **اختيار مرن للصور**: دعم تحديد نوع الصورة والمعمارية عبر الأوامر.
- **تحقق محسن من الروابط**: فحص أفضل لصلاحية روابط التنزيل قبل البدء.
- **رسائل خطأ واضحة**: توفير معلومات أدق للمستخدم عند حدوث مشاكل.
- **واجهة سطر أوامر متكاملة**: دعم كامل للأعلام والخيارات المتقدمة، بما في ذلك `--no-color`.
- **نظام سجلات متقدم**: تسجيل مفصل لمعلومات النظام والأداء (استخدم `-v` للمزيد من التفاصيل).
- **تشغيل آلي**: دعم التثبيت بدون تدخل يدوي.
- **نسخ احتياطي واستعادة**: وظائف مدمجة للنسخ الاحتياطي والاستعادة.

## 2. دليل التثبيت على Termux

لتثبيت NetHunter CLI على Termux، اتبع الخطوات التالية:

1.  **تحديث حزم Termux:**
    ```bash
    pkg update && pkg upgrade -y
    ```

2.  **تثبيت Git و Wget و Proot (إذا لم تكن مثبتة):**
    ```bash
    pkg install git wget proot coreutils gnupg -y
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
    
    # مثال: تثبيت مع تعطيل الألوان وزيادة التفاصيل في السجل
    ./nethunter-cli install --no-color -v
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
  -v, --verbose         Verbose mode (detailed debug output)
  -y, --yes             Automatic yes to prompts (non-interactive)
  --dev                 Development mode (skip integrity checks)
  --no-color            Disable colored output (Recommended for Termux issues)

Examples:
  # تثبيت النسخة الكاملة (مع اكتشاف المعمارية تلقائياً)
  nethunter-cli install
  
  # تثبيت النسخة المصغرة لمعمارية arm64
  nethunter-cli install --type minimal --arch arm64
  
  # تحديث التثبيت الحالي (سيقوم بإعادة التثبيت)
  nethunter-cli update --keep-archive
  
  # إلغاء التثبيت بدون طلب تأكيد
  nethunter-cli uninstall --force
  
  # تثبيت مع تعطيل الألوان وعرض سجلات التصحيح
  nethunter-cli install --no-color -v
```

## 4. استكشاف الأخطاء وإصلاحها (Termux)

-   **أخطاء متعلقة بالألوان / `command not found: $'\[...'`:**
    -   قد لا يدعم Terminal الخاص بك أو إعدادات Termux أكواد الألوان ANSI بشكل صحيح.
    -   **الحل:** استخدم الخيار `--no-color` عند تشغيل السكربت لتعطيل إخراج الألوان.
        ```bash
        ./nethunter-cli install --no-color
        ```
-   **أخطاء متعلقة بـ `awk` / `{print $N}: command not found`:**
    -   تم استبدال معظم استخدامات `awk` بأدوات POSIX مثل `cut` و `sed` في الإصدار 3.2 لتحسين التوافق.
    -   إذا استمرت المشكلة، تأكد من أن أدوات `coreutils` مثبتة (`pkg install coreutils`).
    -   للتصحيح المتقدم، استخدم الخيار `-v` لعرض سجلات مفصلة وتحديد الأمر المسبب للمشكلة.
-   **فشل استيراد مفتاح GPG / خطأ في `gpg.sh`:**
    -   تأكد من تثبيت `gnupg` (`pkg install gnupg`).
    -   تحقق من اتصالك بالإنترنت إذا كان السكربت يحاول تنزيل المفتاح.
    -   تأكد من صلاحية الملفات في مجلد `~/.nethunter/gpg`.
    -   تم إصلاح خطأ بناء الجملة في `gpg.sh` (الإصدار 3.2).
-   **فشل تنزيل `wget` مع `exit code 2`:**
    -   هذا الخطأ يشير عادةً إلى مشكلة في تحليل الخيارات أو الرابط.
    -   تم إصلاح طريقة استدعاء `wget` في الإصدار 3.2 لتجنب استخدام `eval` وتمرير الخيارات بشكل آمن.
    -   إذا استمرت المشكلة، تحقق من الرابط يدوياً وتأكد من عدم وجود حروف خاصة أو مسافات غير متوقعة.
    -   استخدم الخيار `-v` لعرض أمر `wget` الدقيق الذي يتم تنفيذه ومخرجاته.
-   **فشل التنزيل / خطأ 404:**
    -   تأكد من صحة `type` و `arch`.
    -   تأكد من اتصالك بالإنترنت.
    -   تحقق من الروابط يدوياً في المتصفح بدءاً من `https://kali.download/nethunter-images/kali-2025.1c/rootfs/`.
-   **فشل فك الضغط:**
    -   تأكد من وجود مساحة كافية.
    -   قد يكون الملف المنزل تالفاً. احذفه من `~/.nethunter/cache` وأعد المحاولة.
-   **فشل تثبيت الحزم المطلوبة:**
    -   جرب `pkg update && pkg upgrade`.
    -   جرب `termux-change-repo`.

**نصيحة عامة:** للحصول على تفاصيل إضافية حول أي خطأ، قم بتشغيل الأمر مع الخيار `-v` (verbose) وافحص ملفات السجل في `~/.nethunter/logs/`.

## 5. البنية الهندسية (للمطورين)

(هذا القسم يصف بنية الكود العامة)

### 5.1 هيكل الملفات

```
nethunter-cli/
├── dist/
│   ├── nethunter-cli       # نقطة الدخول الرئيسية
│   └── src/                # مجلد الوحدات البرمجية
│       ├── core.sh         # الوظائف الأساسية، الألوان، السجلات
│       ├── utils.sh        # وظائف مساعدة (تنزيل، فحص، إلخ)
│       ├── install.sh      # وظائف التثبيت، التحديث، الإزالة
│       ├── gpg.sh          # وظائف التوقيع الرقمي (إذا كانت مفعلة)
│       ├── cli.sh          # واجهة سطر الأوامر وتحليل الخيارات
│       └── logging.sh      # نظام السجلات المتقدم (مدمج في core.sh حالياً)
└── README.md               # هذا الملف
```

### 5.2 تدفق العمل

1.  **التهيئة (core.sh):** تحميل الوحدات، إعداد البيئة، تهيئة الألوان والسجلات.
2.  **تحليل الأوامر (cli.sh):** معالجة أوامر المستخدم والأعلام (`install`, `--type`, `--no-color`, etc.).
3.  **التحقق (utils.sh):** فحص البيئة، المعمارية، المساحة، الحزم المطلوبة.
4.  **التنفيذ (install.sh, utils.sh):** تنفيذ العملية المطلوبة.
5.  **التسجيل (core.sh):** تسجيل النتائج والأحداث في ملف السجل.
6.  **التنظيف (core.sh):** تنظيف الملفات المؤقتة عند الخروج.

