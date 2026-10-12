import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/haptics.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  await Haptics.load();
  runApp(const ProviderScope(child: SahmiApp()));
}

class SahmiApp extends ConsumerWidget {
  const SahmiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'سهمي',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('ar', 'IQ'),
        supportedLocales: const [Locale('ar', 'IQ'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
}