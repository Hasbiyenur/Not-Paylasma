import 'package:flutter/material.dart';

import 'core/services/app_dependencies.dart';
import 'core/services/hybrid_dependencies.dart';
import 'firebase_options.dart';
import 'core/services/app_scope.dart';
import 'core/utils/app_exception.dart';
import 'shared/widgets/app_status_view.dart';
import 'shared/widgets/app_loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotPaylasBootstrap());
}

class NotPaylasBootstrap extends StatefulWidget {
  const NotPaylasBootstrap({super.key, this.loadDependencies});
  final Future<AppDependencies> Function()? loadDependencies;
  @override
  State<NotPaylasBootstrap> createState() => _NotPaylasBootstrapState();
}

class _NotPaylasBootstrapState extends State<NotPaylasBootstrap> {
  late Future<AppDependencies> _future = _startLoad();
  AppDependencies? _dependencies;
  Future<AppDependencies> _startLoad() {
    final future = _load();
    // Senkron kurulum hatası sonraki karede FutureBuilder bağlanmadan dönebilir.
    // Hata aynı future üzerinde korunur ve FutureBuilder tarafından gösterilir.
    future.ignore();
    return future;
  }

  Future<AppDependencies> _load() async {
    final dependencies =
        await (widget.loadDependencies?.call() ??
            createHybridDependencies(DefaultFirebaseOptions.currentPlatform));
    if (!mounted) {
      await dependencies.close();
    } else {
      _dependencies = dependencies;
    }
    return dependencies;
  }

  @override
  void dispose() {
    _dependencies?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppDependencies>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return AppScope(dependencies: snapshot.data!);
      if (!snapshot.hasError) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AppLoadingScreen(),
        );
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppStatusView(
              status: snapshot.hasError ? AppStatus.error : AppStatus.loading,
              title: snapshot.hasError
                  ? 'Uygulama açılamadı'
                  : 'NotPaylaş hazırlanıyor',
              message: snapshot.hasError
                  ? errorMessage(snapshot.error!)
                  : 'Uygulama hazırlanıyor.',
              actionLabel: snapshot.hasError ? 'Tekrar dene' : null,
              onAction: snapshot.hasError
                  ? () => setState(() {
                      _future = _startLoad();
                    })
                  : null,
            ),
          ),
        ),
      );
    },
  );
}
