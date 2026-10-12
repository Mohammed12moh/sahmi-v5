import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      context.go(loggedIn ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [C.gold, C.green]),
                boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .4), blurRadius: 40)],
              ),
              child: const Icon(Icons.show_chart_rounded, size: 60, color: C.navy),
            )
                .animate()
                .scale(duration: 700.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 900.ms, color: Colors.white54),
            const SizedBox(height: 20),
            const Text('سهمي', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: C.gold))
                .animate().fadeIn(delay: 400.ms).slideY(begin: .3),
          ]),
        ),
      );
}
