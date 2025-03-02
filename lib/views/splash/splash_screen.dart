import 'package:flutter/material.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/services/auth_storage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<String> _checkToken() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      return AppRoutes.dashboard;
    } else {
      return AppRoutes.authorization;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _checkToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Ошибка: ${snapshot.error}")),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, snapshot.data!);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
