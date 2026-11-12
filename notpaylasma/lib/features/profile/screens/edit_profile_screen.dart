import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_dependencies.dart';
import '../../../core/utils/validators.dart';
import '../../../models/selected_file.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/feedback.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(), _last = TextEditingController();
  SelectedFile? _photo;
  bool _picking = false;
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _first.text = user.firstName;
    _last.text = user.lastName;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final file = await context.read<AppDependencies>().device.pick(
        avatar: true,
      );
      if (mounted && file != null) setState(() => _photo = file);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().updateProfile(
        _first.text,
        _last.text,
        _photo,
      );
      if (mounted) {
        showMessage(context, 'Profil güncellendi.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy || _picking;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profili düzenle')),
        body: SafeArea(
          child: PageLayout(
            title: 'Seni tanıyalım.',
            subtitle: 'Fotoğraf: JPG, JPEG veya PNG, en fazla 5 MiB.',
            children: [
              if (_photo != null)
                SizedBox(
                  height: 120,
                  child: Image.memory(
                    _photo!.copyBytes(),
                    errorBuilder: (_, _, _) => const Text('Görsel okunamadı.'),
                  ),
                ),
              OutlinedButton(
                onPressed: busy ? null : _pick,
                child: const Text('Profil fotoğrafı seç'),
              ),
              const SizedBox(height: 16),
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _first,
                      decoration: const InputDecoration(labelText: 'Ad'),
                      validator: (v) => Validators.text(v, 'Ad', 1, 60),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _last,
                      decoration: const InputDecoration(labelText: 'Soyad'),
                      validator: (v) => Validators.text(v, 'Soyad', 1, 60),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : _save,
                      child: const Text('Profili kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
