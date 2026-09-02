import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class AuthRequired {
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (AuthService.instance.isLoggedIn) return true;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Login required'),
          content: const Text(
            'You can browse products and nearby stores as a guest. Please log in to use the cart or shopping lists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continue as Guest'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Login'),
            ),
          ],
        );
      },
    );

    if (shouldLogin != true || !context.mounted) return false;

    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (routeContext) => const LoginScreen()),
    );
    return loggedIn == true && AuthService.instance.isLoggedIn;
  }
}
