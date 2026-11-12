import 'app_exception.dart';

abstract final class Validators {
  static String? text(String? value, String label, int min, int max) {
    final length = (value ?? '').trim().length;
    return length < min || length > max
        ? '$label $min–$max karakter olmalı.'
        : null;
  }

  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
      ? null
      : 'Geçerli bir e-posta girin.';
  static String? password(String? value) =>
      (value ?? '').length < 8 ? 'Şifre en az 8 karakter olmalı.' : null;
  static void require(String? error) {
    if (error != null) throw AppException(error);
  }

  static String normalize(String value) =>
      value.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  static List<String> tags(String value) {
    final tags = value
        .split(',')
        .map(normalize)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (tags.length > 5 || tags.any((e) => e.length < 2 || e.length > 30)) {
      throw const AppException(
        'En fazla 5 etiket; her biri 2–30 karakter olmalı.',
      );
    }
    return tags;
  }
}
