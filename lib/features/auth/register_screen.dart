import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/password_strength.dart';
import '../../core/theme.dart';
import 'auth_repository.dart';

/// تسجيل من 5 خطوات / 5-step registration
class RegisterScreen extends ConsumerStatefulWidget {
  final String? inviteCode;
  const RegisterScreen({super.key, this.inviteCode});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _d = RegisterData();
  final _keys = List.generate(5, (_) => GlobalKey<FormState>());
  final _pass = TextEditingController();
  late final TextEditingController _invite;
  int _step = 0;
  bool _loading = false;
  String? _error, _userMsg;
  int? _inviteCount;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _invite = TextEditingController(text: widget.inviteCode ?? '');
    if (_invite.text.isNotEmpty) _checkInvite(_invite.text);
  }

  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }

  void _checkUsername(String v) {
    _debounce?.cancel();
    if (v.length < 3) { setState(() => _userMsg = null); return; }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final ok = await ref.read(authRepoProvider).usernameAvailable(v);
        if (mounted) setState(() => _userMsg = ok ? 'متاح ✓' : 'مستخدم مسبقاً');
      } catch (_) {}
    });
  }

  Future<void> _checkInvite(String v) async {
    if (v.trim().length < 4) { setState(() => _inviteCount = null); return; }
    try {
      final n = await ref.read(authRepoProvider).inviteCount(v.trim());
      if (mounted) setState(() => _inviteCount = n);
    } catch (_) {}
  }

  bool get _under18 => _d.birthDate != null && DateTime.now().difference(_d.birthDate!).inDays < 365 * 18;

  Future<void> _next() async {
    if (!_keys[_step].currentState!.validate()) return;
    _keys[_step].currentState!.save();
    if (_step == 0) {
      if (_userMsg != null && _userMsg != 'متاح ✓') return;
      if (_d.birthDate == null || _under18) {
        setState(() => _error = 'يجب إدخال تاريخ ميلاد (18 سنة أو أكثر)');
        return;
      }
    }
    setState(() => _error = null);
    if (_step < 4) { setState(() => _step++); return; }
    setState(() => _loading = true);
    try {
      _d.inviteCode = _invite.text;
      _d.password = _pass.text;
      await ref.read(authRepoProvider).signUp(_d);
      if (mounted && Supabase.instance.client.auth.currentSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تحقق من بريدك لتفعيل الحساب')));
        context.go('/login');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر إنشاء الحساب');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null;

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return Column(children: [
          TextFormField(decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: _req, onSaved: (v) => _d.fullName = v!.trim()),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(labelText: 'اسم المستخدم', helperText: _userMsg),
            onChanged: _checkUsername,
            validator: (v) => RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v ?? '') ? null : '3-20 حرف إنجليزي/أرقام/_',
            onSaved: (v) => _d.username = v!.trim(),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: C.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(_d.birthDate == null ? 'تاريخ الميلاد' : _d.birthDate!.toString().substring(0, 10)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final p = await showDatePicker(
                  context: context, initialDate: DateTime(2000), firstDate: DateTime(1940), lastDate: DateTime.now());
              if (p != null) setState(() => _d.birthDate = p);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'الجنس (اختياري)'),
            items: const [DropdownMenuItem(value: 'm', child: Text('ذكر')), DropdownMenuItem(value: 'f', child: Text('أنثى'))],
            onChanged: (v) => _d.gender = v,
          ),
        ]);
      case 1:
        return Column(children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? null : 'بريد غير صالح',
            onSaved: (v) => _d.email = v!.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '+964',
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            validator: (v) => RegExp(r'^\+9647[3-9]\d{8}$').hasMatch((v ?? '').replaceAll(' ', '')) ? null : 'مثال: +9647701234567',
            onSaved: (v) => _d.phone = v!.replaceAll(' ', ''),
          ),
        ]);
      case 2:
        return Column(children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'المحافظة'),
            items: [for (final g in iraqGovernorates) DropdownMenuItem(value: g, child: Text(g))],
            validator: (v) => v == null ? 'مطلوب' : null,
            onChanged: (v) => _d.city = v,
            onSaved: (v) => _d.city = v,
          ),
          const SizedBox(height: 12),
          TextFormField(decoration: const InputDecoration(labelText: 'المنطقة / الحي'), onSaved: (v) => _d.district = v),
          const SizedBox(height: 12),
          TextFormField(decoration: const InputDecoration(labelText: 'العنوان (اختياري)'), onSaved: (v) => _d.address = v),
        ]);
      case 3:
        return StatefulBuilder(builder: (_, set) {
          final s = passwordStrength(_pass.text);
          final colors = [C.red, Colors.orange, C.green, C.gold];
          return Column(children: [
            TextFormField(
              controller: _pass,
              obscureText: true,
              onChanged: (_) => set(() {}),
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              validator: (v) => (v ?? '').length >= 8 ? null : '8 أحرف على الأقل',
            ),
            const SizedBox(height: 8),
            Row(children: [
              for (var i = 0; i < 4; i++)
                Expanded(child: Container(
                  height: 6, margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: _pass.text.isNotEmpty && i <= s.index ? colors[s.index] : Colors.white12,
                      borderRadius: BorderRadius.circular(4)),
                )),
              const SizedBox(width: 8),
              Text(_pass.text.isEmpty ? '' : pwLabels[s]!),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              validator: (v) => v == _pass.text ? null : 'غير متطابقة',
            ),
          ]);
        });
      default:
        return Column(children: [
          TextFormField(
            controller: _invite,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'رمز الدعوة (اختياري)'),
            onChanged: _checkInvite,
          ),
          if (_inviteCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('$_inviteCount شخص سجلوا من رمز صديقك', style: const TextStyle(color: C.gold)),
            ),
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('هذه نسخة تجريبية: الرصيد والمكافآت افتراضية ولا تمثل أموالاً حقيقية.',
                  style: TextStyle(color: Colors.white60)),
            ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['معلومات أساسية', 'التواصل', 'الموقع', 'الأمان', 'رمز الدعوة'];
    return Scaffold(
      appBar: AppBar(
        title: Text('${titles[_step]} (${_step + 1}/5)'),
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--))
            : IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            LinearProgressIndicator(value: (_step + 1) / 5, color: C.gold, backgroundColor: Colors.white12),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: Form(key: _keys[_step], child: _stepBody()))),
            if (_error != null) Text(_error!, style: const TextStyle(color: C.red)),
            const SizedBox(height: 12),
            GlowButton(_step == 4 ? 'إنشاء الحساب' : 'التالي', loading: _loading, onPressed: _next),
          ]),
        ),
      ),
    );
  }
}
