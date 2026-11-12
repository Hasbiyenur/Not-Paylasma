import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'app_shell.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return _SessionNavigator(
      key: ValueKey(user?.uid ?? 'signed-out'),
      signedIn: user != null,
    );
  }
}

class _SessionNavigator extends StatefulWidget {
  const _SessionNavigator({required this.signedIn, super.key});
  final bool signedIn;
  @override
  State<_SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<_SessionNavigator> {
  final _key = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
    onPopWithResult: (_) => _key.currentState!.maybePop(),
    child: Navigator(
      key: _key,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) =>
            widget.signedIn ? const AppShell() : const LoginScreen(),
      ),
    ),
  );
}
