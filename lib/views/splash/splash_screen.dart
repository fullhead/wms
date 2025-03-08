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
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  bool _hasError = false;
  String? _errorMessage;

  // -------------------------------------------------------
  // Жизненный цикл
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  // -------------------------------------------------------
  // Инициализация сплеша
  // -------------------------------------------------------
  Future<void> _initSplash() async {
    try {
      final token = await AuthStorage.getToken();
      final destinationRoute = (token != null && token.isNotEmpty)
          ? AppRoutes.dashboard
          : AppRoutes.authorization;

      // Ждем 4 секунды для воспроизведения анимации
      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, destinationRoute);
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  // -------------------------------------------------------
  // Построение экрана
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorView();
    }
    return _buildSplashAnimation();
  }

  Widget _buildErrorView() {
    return Scaffold(
      body: Center(
        child: Text("Ошибка: $_errorMessage"),
      ),
    );
  }

  Widget _buildSplashAnimation() {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Определяем размер анимации: 50% от меньшей стороны экрана
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
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
