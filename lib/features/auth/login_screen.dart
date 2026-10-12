import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepoProvider).signIn(_email.text, _pass.text);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              const SizedBox(height: 40),
              const Text('تسجيل الدخول', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.mail_outline)),
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? null : 'بريد غير صالح',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                validator: (v) => (v ?? '').length >= 8 ? null : '8 أحرف على الأقل',
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: C.red))),
              const SizedBox(height: 24),
              GlowButton('دخول', loading: _loading, onPressed: _submit),
              TextButton(onPressed: () => context.go('/register'), child: const Text('ما عندك حساب؟ سجّل الآن')),
            ]),
          ),
        ),
      );
}
