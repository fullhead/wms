import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/core/session/auth_storage.dart';

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
    _initSplash();
  }

  Future<void> _initSplash() async {
    try {
      final token = await AuthStorage.getAccessToken();
      String destinationRoute = AppRoutes.authorization;
      if (token != null && token.isNotEmpty) {
        final accessLevel = await AuthStorage.getUserGroupLevel();
        if (accessLevel == '1') {
          destinationRoute = AppRoutes.users;
        } else if (accessLevel == '2') {
          destinationRoute = AppRoutes.receives;
        } else if (accessLevel == '3') {
          destinationRoute = AppRoutes.dashboard;
        }
      }
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
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final animationSize =
              (screenWidth < screenHeight ? screenWidth : screenHeight) * 1;
          return Center(
            child: Lottie.asset(
              'lib/assets/logo_splash_animation.json',
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
