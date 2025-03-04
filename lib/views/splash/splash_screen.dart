import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/services/auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await AuthStorage.getToken();
      final destinationRoute = (token != null && token.isNotEmpty)
          ? AppRoutes.dashboard
          : AppRoutes.authorization;
      // Ждём 4 секунды, чтобы анимация воспроизвелась полностью
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, destinationRoute);
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(child: Text("Ошибка: $_errorMessage")),
      );
    }
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Вычисляем размеры экрана
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          // Устанавливаем размер анимации как 50% от меньшей стороны экрана
          final animationSize =
              (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.5;
          return Center(
            child: Lottie.asset(
              'lib/assets/splash_animation.json',
              width: animationSize,
              height: animationSize,
              fit: BoxFit.contain,
              repeat: false,
            ),
          );
        },
      ),
    );
  }
}
