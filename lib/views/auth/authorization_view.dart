import 'package:flutter/material.dart';
import 'package:wms/presenters/auth/authorization_presenter.dart';
import 'package:wms/core/routes.dart';

class AuthorizationView extends StatefulWidget {
  const AuthorizationView({super.key});

  @override
  State<AuthorizationView> createState() => _AuthorizationViewState();
}

class _AuthorizationViewState extends State<AuthorizationView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _presenter = AuthorizationPresenter();

  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });

      try {
        await _presenter.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } catch (error) {
        setState(() => _errorMessage = error.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем LayoutBuilder для адаптивного расчета отступов и ограничений ширины
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS - система'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Если ширина экрана меньше 600, используем фиксированные отступы, иначе вычисляем динамически
          final horizontalPadding =
              constraints.maxWidth < 600 ? 24.0 : constraints.maxWidth * 0.2;
          final topPadding =
              constraints.maxWidth < 600 ? 120.0 : constraints.maxWidth * 0.1;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: topPadding,
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 16,
            ),
            child: Center(
              // Ограничиваем ширину содержимого для больших экранов
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Авторизоваться',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите логин';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Войти',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
