import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/presenters/personalization/personalization_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'package:wms/services/auth_storage.dart';

class PersonalizationView extends StatefulWidget {
  const PersonalizationView({super.key});

  @override
  PersonalizationViewState createState() => PersonalizationViewState();
}

class PersonalizationViewState extends State<PersonalizationView> {
  final _presenter = PersonalizationPresenter();
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  User? _currentUser;
  bool _isLoading = false;
  File? _newAvatarImage;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadCurrentUser();
    // Слушатели для полей логина и пароля, чтобы активировать/деактивировать кнопку сохранения
    _loginController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _presenter.getCurrentUser();
      setState(() {
        _currentUser = user;
        _loginController.text = user.userName;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка загрузки профиля: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<void> _selectAvatarImage() async {
    final selected = await showModalBottomSheet<File?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () async {
                  final image = await _pickImage(ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () async {
                  final image = await _pickImage(ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _newAvatarImage = selected;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null) return;

    final bool isAvatarChanged = _newAvatarImage != null;
    final bool isLoginChanged =
        _loginController.text.trim() != _currentUser!.userName;
    final bool isPasswordChanged = _passwordController.text.trim().isNotEmpty;

    // Если не было никаких изменений, выводим уведомление
    if (!isAvatarChanged && !isLoginChanged && !isPasswordChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Нечего обновлять")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isAvatarChanged) {
        await _presenter.updateAvatar(_currentUser!, _newAvatarImage!.path);
      }
      if (isLoginChanged) {
        await _presenter.updateLogin(_currentUser!, _loginController.text.trim());
      }
      if (isPasswordChanged) {
        await _presenter.updatePassword(_currentUser!, _passwordController.text.trim());
      }

      // По завершении всех обновлений показываем одно сообщение
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Изменения успешно сохранены")),
        );
        await _loadCurrentUser();
        _passwordController.clear();
        setState(() {
          _newAvatarImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка обновления профиля: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _isUpdateEnabled {
    if (_currentUser == null) return false;
    return _newAvatarImage != null ||
        _loginController.text.trim() != _currentUser!.userName ||
        _passwordController.text.trim().isNotEmpty;
  }

  Widget _buildAvatar(double radius) {
    final avatarUrl = _currentUser?.userAvatar;
    final defaultAvatarUrl =
        '${AppConstants.apiBaseUrl}/assets/user/no_image_user.png';

    return GestureDetector(
      onTap: _selectAvatarImage,
      child: CircleAvatar(
        radius: radius,
        backgroundImage: _newAvatarImage != null
            ? FileImage(_newAvatarImage!)
            : (avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(
          '${AppConstants.apiBaseUrl}$avatarUrl',
          headers: _token != null
              ? {"Authorization": "Bearer $_token"}
              : null,
        )
            : CachedNetworkImageProvider(
          defaultAvatarUrl,
          headers: _token != null
              ? {"Authorization": "Bearer $_token"}
              : null,
        )),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Настраиваем размеры для разных экранов
        final bool isWide = constraints.maxWidth > 800;
        final double avatarRadius = isWide ? 160 : 60;
        final double fieldMaxWidth = isWide ? 600 : double.infinity;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль пользователя'),
          ),
          drawer: const WmsDrawer(),
          body: RefreshIndicator(
            onRefresh: _loadCurrentUser,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentUser == null
                ? const Center(child: Text('Профиль не найден'))
                : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: fieldMaxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildAvatar(avatarRadius),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _loginController,
                          decoration: const InputDecoration(
                            labelText: 'Логин',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Введите логин';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Новый пароль',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            // Пароль не обязателен
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                          _isUpdateEnabled ? _saveChanges : null,
                          child: const Text('Сохранить изменения'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
