# 🏜️ Desert Track — ملاحة برية مجانية بالكامل

تطبيق أندرويد لتسجيل وتتبع المسارات البرية والصحراوية باستخدام GPS وخرائط الأقمار الصناعية المجانية، يعمل بدون إنترنت.

---

## 📦 المتطلبات قبل البناء

| الأداة | الإصدار المطلوب |
|--------|----------------|
| Flutter SDK | >= 3.16 (stable) |
| Dart | >= 3.1 |
| Android Studio | Hedgehog 2023.1+ |
| Java JDK | 17 |
| Android SDK | API 21–34 |

---

## 🚀 خطوات بناء APK من الصفر

### 1. تثبيت Flutter

```bash
# Windows: نزّل Flutter SDK من https://flutter.dev
# Linux/Mac:
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PWD/flutter/bin:$PATH"
flutter doctor
```

### 2. استنساخ / نقل المشروع

```bash
# انسخ مجلد desert_track إلى جهازك
cd desert_track

# تحميل جميع الحزم
flutter pub get
```

### 3. بناء APK — Debug (للاختبار)

```bash
flutter build apk --debug
# الملف: build/app/outputs/flutter-apk/app-debug.apk
```

### 4. بناء APK — Release (للنشر)

```bash
flutter build apk --release --split-per-abi
# الملفات:
#   build/app/outputs/apk/release/app-arm64-v8a-release.apk  ← أحدث الهواتف
#   build/app/outputs/apk/release/app-armeabi-v7a-release.apk ← الهواتف القديمة
```

### 5. تثبيت مباشرة على الهاتف (USB Debug)

```bash
flutter run --release
# أو
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📂 هيكل المشروع

```
desert_track/
├── lib/
│   ├── main.dart                    # نقطة البداية + الثيم
│   ├── models/
│   │   ├── track_point.dart         # نموذج نقطة GPS
│   │   └── trip.dart                # نموذج الرحلة والـ Waypoints
│   ├── services/
│   │   ├── database_service.dart    # SQLite (حفظ الرحلات)
│   │   ├── location_service.dart    # GPS + خدمة الخلفية
│   │   ├── tile_cache_service.dart  # كاش خرائط الأقمار الصناعية
│   │   └── export_service.dart      # تصدير GPX و KML
│   ├── providers/
│   │   └── trip_provider.dart       # إدارة الحالة (Provider)
│   ├── screens/
│   │   ├── home_screen.dart         # الشاشة الرئيسية
│   │   ├── recording_screen.dart    # شاشة التسجيل المباشر
│   │   ├── map_view_screen.dart     # عرض الرحلة المحفوظة
│   │   └── trips_list_screen.dart   # قائمة الرحلات
│   └── utils/
│       └── geo_utils.dart           # حسابات المسافة والاتجاه
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  # الأذونات + الخدمات
│   │   │   ├── kotlin/.../
│   │   │   │   └── MainActivity.kt
│   │   │   └── res/values/styles.xml
│   │   ├── build.gradle
│   │   └── proguard-rules.pro
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
└── pubspec.yaml                     # الحزم والاعتماديات
```

---

## 🗺️ مصادر الخرائط (مجانية بالكامل)

| المصدر | النوع | API Key |
|--------|-------|---------|
| **ESRI World Imagery** | أقمار صناعية عالية الدقة | ❌ لا يوجد |
| OpenStreetMap | خرائط طرق | ❌ لا يوجد |

رابط ESRI:
```
https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}
```

---

## 📱 الميزات المطبّقة

| الميزة | الحالة |
|--------|--------|
| تسجيل GPS في الخلفية | ✅ |
| عرض على خريطة أقمار صناعية | ✅ |
| كاش الخرائط أوفلاين | ✅ |
| حفظ الرحلات (SQLite) | ✅ |
| تصدير GPX + KML | ✅ |
| مشاركة عبر واتساب/تيليجرام | ✅ |
| اتباع مسار محفوظ | ✅ |
| تنبيه الانحراف عن المسار | ✅ |
| Waypoints / نقاط مرجعية | ✅ |
| قياس المسافة والسرعة والوقت | ✅ |
| وضع ليلي (Dark Mode) | ✅ |
| أزرار كبيرة للاستخدام البري | ✅ |
| يعمل بدون إنترنت | ✅ |

---

## 🔧 حل المشاكل الشائعة

### `flutter pub get` يفشل
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### GPS لا يعمل في الخلفية
- اذهب إلى إعدادات الهاتف ← التطبيقات ← Desert Track ← الأذونات
- فعّل "الموقع" وضعه على "دائماً"
- بعض الهواتف (Xiaomi, Huawei) تحتاج تفعيل "تشغيل في الخلفية"

### خطأ `minSdkVersion`
في `android/app/build.gradle` تأكد من:
```gradle
minSdk 21
```

### مشكلة JDK
```bash
flutter config --jdk-dir /path/to/jdk17
```

---

## 📤 مشاركة الملف GPX

بعد التصدير:
- **Google Maps**: افتح gmaps ← القائمة ← رحلاتك ← استيراد GPX
- **OsmAnd**: ضع الملف في `OsmAnd/tracks/`
- **Google Earth**: افتح الملف مباشرة
- **واتساب/تيليجرام**: أرسل الملف كـ Document

---

## 📋 متطلبات أذونات أندرويد

| الإذن | السبب |
|-------|-------|
| ACCESS_FINE_LOCATION | تحديد الموقع بدقة |
| ACCESS_BACKGROUND_LOCATION | التتبع أثناء إغلاق الشاشة |
| FOREGROUND_SERVICE | الخدمة المستمرة |
| INTERNET | تنزيل البلاطات عند الاتصال |
| WAKE_LOCK | منع سكون المعالج أثناء التسجيل |

---

## 🆓 ترخيص

MIT License — مجاني للاستخدام الشخصي والتجاري
لا يوجد أي API مدفوع أو اشتراك.
