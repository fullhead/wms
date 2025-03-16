import 'package:flutter/material.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/main.dart';

class AccessExpiredDialog extends StatelessWidget {
  const AccessExpiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final warningColor = theme.colorScheme.error;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            color: warningColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "Сессия истекла",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ваша сессия истекла. Для продолжения работы необходимо авторизоваться заново.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.authorization,
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: primaryColor, width: 2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
              ),
              child: const Text(
                "Авторизоваться",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Статический метод для отображения диалога без передачи контекста.
  static Future<void> showAccessExpired() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AccessExpiredDialog();
      },
    );
  }
}
