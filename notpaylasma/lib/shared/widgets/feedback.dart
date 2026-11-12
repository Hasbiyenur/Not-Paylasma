import 'package:flutter/material.dart';

import '../../core/utils/app_exception.dart';

void showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, Object error) =>
    showMessage(context, errorMessage(error));
