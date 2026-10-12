# سهمي (Sahmi) - المراحل 1 → 4 (وضع تجريبي)

## البناء (GitHub Actions / محلياً)
مجلد `android/` موجود بالمشروع (Flutter embedding v2، Gradle 8.14، AGP 8.11.1، Kotlin 2.2.20، Java 17)
ومعرّف التطبيق `com.sahmi.app`. لا حاجة لـ `flutter create`.

```
flutter pub get
flutter build apk --release      # الناتج: build/app/outputs/flutter-apk/app-release.apk
```
التوقيع بمفتاح debug (للتجربة). أيقونة التطبيق جاهزة داخل `android/app/src/main/res`.
لـ iOS شغّل مرة واحدة: `flutter create . --platforms=ios`.

## Supabase
نفّذ `supabase/schema.sql` كاملاً في SQL Editor (آمن لإعادة التنفيذ).
المفاتيح عبر `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` أو القيم الافتراضية في `lib/core/config.dart`.

## المحتوى
- م1: Splash، Onboarding، دخول، تسجيل 5 خطوات، RLS.
- م2: الرئيسية، السوق، تفاصيل السهم + محرك الإشارات، مراقبة محفوظة.
- م3: شحن تجريبي، سجل المعاملات، الدعوات والمستويات (XP) والمتصدرون، دعم تلغرام.
- م4: المحفظة، تداول تجريبي (RPC `execute_trade`)، حسابي (معلومات، إعدادات، أمان، مساعدة)،
  تلعيب: XP، Streak، 8 شارات، تحديات يومية/أسبوعية يتحقق منها الخادم.
- الدردشة: غرف عامة برسائل فورية (Realtime) مع حدود إرسال وحظر، من السوق أو حسابي. شريط شراء/بيع أسفل شاشة السهم.
- الأسعار والرصيد والمكافآت كلها افتراضية. سعر التداول يأتي من محاكاة العميل (تجريبي فقط).
