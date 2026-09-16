# JobOra — مساعدك الشخصي في البحث عن وظيفة

هذا هو **أساس المرحلة الأولى (Phase 1 MVP)** من تطبيق JobOra، مبني حسب المعمارية والمواصفات المطلوبة.

## ما تم تنفيذه في هذا التسليم

* بنية مشروع كاملة (`core/` + `features/`) حسب المعمارية المطلوبة.
* نظام تصميم مركزي: ألوان، خطوط، مسافات، أنماط الأزرار والحقول (`core/theme`).
* دعم كامل للغتين العربية والإنجليزية عبر ملفات JSON + دعم RTL تلقائي (`core/localization`, `assets/translations`).
* الوضع الفاتح والداكن.
* التنقل المركزي عبر `go_router` مع `redirect` منطقي (onboarding → auth → home) (`core/router`).
* الشاشات:

  * Splash، اختيار اللغة، اختيار العملة، Onboarding (3 صفحات)
  * تسجيل الدخول / إنشاء حساب (مع منع الإرسال المزدوج وتعطيل الزر بدون الموافقة على الشروط)
  * Home Dashboard (بطاقات ملخص، "يحتاج انتباهك"، القادم، إجراءات سريعة، حالة فراغ)
  * Applications (بحث + فلاتر + بطاقات حالة، حالة فراغ)
  * Add Application (حقول أساسية سريعة + "تفاصيل إضافية" قابلة للطي)
  * Application Details (Timeline بصري لمراحل التقديم)
  * Interviews، Statistics، Profile/Settings
* نماذج البيانات (`ApplicationModel`, `InterviewModel`) متوافقة مع بنية Firestore المقترحة في المواصفات.
* قواعد أمان Firestore و Storage جاهزة (`firestore.rules`, `storage.rules`) — كل مستخدم يصل فقط لبياناته.
* `pubspec.yaml` بكل الاعتماديات المطلوبة (Firebase, go_router, flutter_bloc, RevenueCat, PDF, إلخ).

## ملاحظة مهمة

الشاشات حاليًا تعمل ببيانات وهمية (mock data) موضحة بتعليق `NOTE` أعلى كل ملف، لأن الربط الفعلي مع Firebase يحتاج:

1. مشروع Firebase حقيقي (Firestore + Auth + Storage + Messaging).
2. تشغيل `flutterfire configure` لتوليد `firebase_options.dart`.
3. مفاتيح RevenueCat الحقيقية.
4. Backend/Cloud Function للـ AI (OpenRouter) حتى لا يتم تخزين مفاتيح AI داخل التطبيق مباشرة (كما ورد في قسم 27 من المواصفات).

## خطوات التشغيل

```bash
flutter pub get
flutterfire configure   # يربط المشروع بـ Firebase الخاص بك
flutter run
```

## خطة المراحل القادمة (كما في المواصفات الأصلية)

* **المرحلة 2:** CV Manager، Cover Letters، Follow-ups، تصدير PDF، مقارنة الوظائف.
* **المرحلة 3:** تحليل السيرة الذاتية بالـ AI، توليد خطابات التقديم، تدريب المقابلات، المساعد الذكي.
* **المرحلة 4:** RevenueCat والاشتراك المدفوع (Premium)، حدود استخدام AI.

## هيكل المجلدات

```text
lib/
├── core/
│   ├── router/        # GoRouter + منطق التوجيه
│   ├── theme/         # الألوان، الخطوط، المسافات
│   ├── localization/ # نظام الترجمة JSON
│   ├── services/      # AppSettingsController, AuthController
│   ├── models/        # ApplicationModel, InterviewModel
│   └── widgets/       # AppCard, StatusBadge, EmptyState, MainShell
├── features/
│   ├── splash/, onboarding/, auth/, home/
│   ├── applications/, interviews/, statistics/, profile/
│   └── cvs/, cover_letter/, ai/, notifications/  # جاهزة للمرحلة القادمة
└── main.dart
```

أخبرني أي جزء تريد أن أكمله بعد ذلك — مثلاً: ربط Firebase فعليًا، CV Manager، أو ميزات الـ AI (Cover Letter / CV Analysis / Interview Practice).
