/// إعدادات التطبيق / App configuration
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://rpkcvepfxlwfbwlwxikh.supabase.co');
  // Anon key عام بطبيعته؛ الحماية الحقيقية عبر RLS (انظر supabase/schema.sql)
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwa2N2ZXBmeGx3ZmJ3bHd4aWtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExMzYxMTEsImV4cCI6MjEwNjcxMjExMX0.lTVBp2IDGMiPFVp1Mk1RzGjZTpvPn7iYAN528wdiFUQ');
  static const telegramHandle = 'CG_CG9';
  static const telegramUrl = 'https://t.me/CG_CG9';
  static const telegramDeepLink = 'tg://resolve?domain=CG_CG9';
  /// وضع تجريبي: رصيد ومكافآت وهمية فقط / Demo mode: virtual funds only
  static const demoMode = true;
}

const iraqGovernorates = [
  'بغداد','البصرة','نينوى','أربيل','السليمانية','دهوك','كركوك','الأنبار','ديالى',
  'صلاح الدين','بابل','كربلاء','النجف','واسط','ذي قار','ميسان','المثنى','القادسية',
];
