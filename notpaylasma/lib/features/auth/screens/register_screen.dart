import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/app_loading_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(), _last = TextEditingController();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.run(
        () => auth.repository.register(
          _first.text,
          _last.text,
          _email.text,
          _password.text,
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().busy) {
      return const AppLoadingScreen(message: 'Hesabın oluşturuluyor…');
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap oluştur')),
      body: SafeArea(
        child: PageLayout(
          title: 'Öğrenme topluluğuna katıl.',
          subtitle: context.read<AppDependencies>().isFirebase
              ? 'E-posta adresin ve şifrenle hesabını oluştur.'
              : context.read<AppDependencies>().isLocalJson
              ? 'Hesabın yerel JSON kaydında korunur. Çıkış yapınca bilgiler silinmez.'
              : context.read<AppDependencies>().isPersistent
              ? 'Demo hesabın bu cihazda saklanır. Gerçek şifreni kullanma.'
              : 'Demo hesabı bu çalıştırma boyunca kullanılabilir.',
          children: [
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final field in [
                    (_first, 'Ad', 1, 60),
                    (_last, 'Soyad', 1, 60),
                  ]) ...[
                    TextFormField(
                      controller: field.$1,
                      decoration: InputDecoration(labelText: field.$2),
                      validator: (v) =>
                          Validators.text(v, field.$2, field.$3, field.$4),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirm,
                    decoration: const InputDecoration(
                      labelText: 'Şifre tekrar',
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v != _password.text ? 'Şifreler eşleşmiyor.' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: context.watch<AuthProvider>().busy
                        ? null
                        : _submit,
                    child: const Text('Kaydol'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
