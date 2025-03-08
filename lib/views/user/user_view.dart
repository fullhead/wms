import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/group.dart';
import 'package:wms/models/user.dart';
import 'package:wms/presenters/group/group_presenter.dart';
import 'package:wms/presenters/user/user_presenter.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  UserViewState createState() => UserViewState();
}

class UserViewState extends State<UserView> {
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  late final UserPresenter _userPresenter;
  late final GroupPresenter _groupPresenter;
  final ImagePicker _picker = ImagePicker();

  List<User> _users = [];
  bool _isLoading = false;
  String? _token;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _userPresenter = UserPresenter();
    _groupPresenter = GroupPresenter();
    _loadToken();
    _loadUsers();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userPresenter.fetchAllUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка загрузки: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------
  // Приватные методы для запросов и диалогов
  // -------------------------------------------------------
  Future<List<Group>> _loadGroupsForUser() async {
    return _groupPresenter.fetchAllGroups();
  }

  Future<File?> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<File?> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<File?> _showImageSourceSelectionDialog(BuildContext dialogContext) async {
    return showModalBottomSheet<File?>(
      context: dialogContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.of(context).pop(await _pickImageFromGallery());
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Сделать фото'),
              onTap: () async {
                Navigator.of(context).pop(await _pickImageFromCamera());
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Методы для отображения деталей, создания, редактирования, удаления
  // -------------------------------------------------------
  void _showUserDetails(User user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
        final dialogHeight = size.height * 0.76;
        final imageSize = isDesktop ? 650.0 : 300.0;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    user.userFullname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: dialogHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: _buildDialogImage(
                            fileImage: null,
                            imageUrl: user.userAvatar,
                            token: _token,
                            width: imageSize,
                            height: imageSize,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.login, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Логин:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userName,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.info, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Статус:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            _buildStatusChip(user),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Группа:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userGroup.groupName,
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Дата создания:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userCreationDate.toLocal().toString().split('.')[0],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Последний вход:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userLastLoginDate.toLocal().toString().split('.')[0],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showEditUserDialog(user);
                            },
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            label: const Text(
                              "Редактировать",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _confirmDeleteUser(user);
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              "Удалить",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditUserDialog(User user) async {
    final parentContext = context;
    final editFormKey = GlobalKey<FormState>();

    final fullNameController = TextEditingController(text: user.userFullname);
    final usernameController = TextEditingController(text: user.userName);
    final passwordController = TextEditingController();

    // Текущее значение аватара в БД.
    String imagePath = user.userAvatar;

    // Если выберем новое изображение – оно временно хранится тут.
    File? editedImage;

    // Если нажмём "Удалить аватар" – ставим флаг, что в итоге аватар будет удалён.
    bool isAvatarDeleted = false;

    bool status = user.userStatus;
    Group? selectedGroup = user.userGroup;
    List<Group> allGroups = [];

    try {
      allGroups = await _loadGroupsForUser();
      final foundIndex = allGroups.indexWhere((g) => g.groupID == user.userGroup.groupID);
      if (foundIndex >= 0) {
        selectedGroup = allGroups[foundIndex];
      } else if (allGroups.isNotEmpty) {
        selectedGroup = allGroups.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки групп: $e")),
      );
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (inDialogContext) {
        final size = MediaQuery.of(inDialogContext).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.6 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.78;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Редактировать пользователя"),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: StatefulBuilder(
              builder: (inDialogContext, setStateDialog) {
                return SingleChildScrollView(
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Аватар
                        GestureDetector(
                          onTap: () async {
                            final result = await _showImageSourceSelectionDialog(inDialogContext);
                            if (result != null) {
                              editedImage = result;
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            fileImage: editedImage,
                            imageUrl: imagePath,
                            token: _token,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Кнопки изменения и удаления
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result = await _showImageSourceSelectionDialog(inDialogContext);
                                if (result != null) {
                                  editedImage = result;
                                  setStateDialog(() {});
                                }
                              },
                              child: const Text("Изменить аватар"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                isAvatarDeleted = true;
                                editedImage = null;
                                imagePath = '/assets/user/no_image_user.png';
                                setStateDialog(() {});
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Удалить аватар"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Полное имя
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),

                        // Логин
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),

                        // Новый пароль (необязательно)
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: "Новый пароль (если нужно изменить)",
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),

                        // Группа
                        DropdownButtonFormField<Group>(
                          decoration: const InputDecoration(labelText: "Группа"),
                          value: selectedGroup,
                          items: allGroups
                              .map(
                                (g) => DropdownMenuItem<Group>(
                              value: g,
                              child: Text(g.groupName),
                            ),
                          )
                              .toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              selectedGroup = newValue;
                            });
                          },
                          validator: (value) => value == null ? "Выберите группу" : null,
                        ),
                        const SizedBox(height: 10),

                        // Статус
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Статус"),
                          value: status,
                          onChanged: (bool value) {
                            setStateDialog(() {
                              status = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(inDialogContext).pop(),
              child: const Text("Отмена"),
            ),
            TextButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  try {
                    // Подготовим аватар к сохранению
                    String newAvatar;
                    if (isAvatarDeleted) {
                      // Удаляем на сервере и ставим дефолт
                      await _userPresenter.deleteUserAvatar(user.userID);
                      newAvatar = '/assets/user/no_image_user.png';
                    } else if (editedImage != null) {
                      // Если выбрали новое изображение
                      newAvatar = await _userPresenter.setUserAvatar(user.userID, editedImage!.path);
                    } else {
                      // Если ничего не меняли
                      newAvatar = imagePath;
                    }

                    // Обновляем пользователя
                    final responseMessage = await _userPresenter.updateUser(
                      user,
                      fullName: fullNameController.text.trim(),
                      username: usernameController.text.trim(),
                      avatar: newAvatar,
                      status: status,
                      password: passwordController.text.trim().isEmpty
                          ? null
                          : passwordController.text.trim(),
                      group: selectedGroup,
                    );

                    // Закрываем диалог и обновляем список
                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                    }
                    await _loadUsers();

                    // Показываем уведомление об успешном обновлении
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(responseMessage),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                      ScaffoldMessenger.of(inDialogContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateUserDialog() async {
    final parentContext = context;
    final createFormKey = GlobalKey<FormState>();

    final fullNameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    File? newImage;
    String? avatarPath;
    bool status = true;
    Group? selectedGroup;
    List<Group> allGroups = [];

    try {
      allGroups = await _loadGroupsForUser();
      if (allGroups.isNotEmpty) {
        selectedGroup = allGroups.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки групп: $e")),
      );
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (inDialogContext) {
        final size = MediaQuery.of(inDialogContext).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.6 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.78;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Создать пользователя"),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: StatefulBuilder(
              builder: (inDialogContext, setStateDialog) {
                return SingleChildScrollView(
                  child: Form(
                    key: createFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Выбор/отображение аватара
                        GestureDetector(
                          onTap: () async {
                            final result = await _showImageSourceSelectionDialog(inDialogContext);
                            if (result != null) {
                              newImage = result;
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            fileImage: newImage,
                            showPlaceholder: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result = await _showImageSourceSelectionDialog(inDialogContext);
                                if (result != null) {
                                  newImage = result;
                                  setStateDialog(() {});
                                }
                              },
                              child: const Text("Выбрать аватар"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Очистка выбранного аватара
                                newImage = null;
                                avatarPath = '/assets/user/no_image_user.png';
                                setStateDialog(() {});
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Очистить аватар"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Полное имя
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),

                        // Логин
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),

                        // Пароль
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: "Пароль"),
                          obscureText: true,
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите пароль" : null,
                        ),
                        const SizedBox(height: 10),

                        // Группа
                        DropdownButtonFormField<Group>(
                          decoration: const InputDecoration(labelText: "Группа"),
                          value: selectedGroup,
                          items: allGroups
                              .map(
                                (g) => DropdownMenuItem<Group>(
                              value: g,
                              child: Text(g.groupName),
                            ),
                          )
                              .toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              selectedGroup = newValue;
                            });
                          },
                          validator: (value) => value == null ? "Выберите группу" : null,
                        ),
                        const SizedBox(height: 10),

                        // Статус
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Статус"),
                          value: status,
                          onChanged: (value) {
                            setStateDialog(() {
                              status = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(inDialogContext).pop(),
              child: const Text("Отмена"),
            ),
            TextButton(
              onPressed: () async {
                if (createFormKey.currentState!.validate() && selectedGroup != null) {
                  try {
                    // При создании, если avatarPath не задан, сервер сам поставит дефолт.
                    final responseMessage = await _userPresenter.createUser(
                      fullName: fullNameController.text.trim(),
                      username: usernameController.text.trim(),
                      password: passwordController.text.trim(),
                      group: selectedGroup!,
                      avatar: avatarPath ?? '',
                      status: status,
                    );

                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                    }
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(responseMessage),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                      ScaffoldMessenger.of(inDialogContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Создать"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(User user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить пользователя "${user.userFullname}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertContext, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(alertContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final responseMessage = await _userPresenter.deleteUser(user);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseMessage),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // -------------------------------------------------------
  // Виджеты для статуса и изображения
  // -------------------------------------------------------
  Widget _buildStatusChip(User user) {
    final isActive = user.userStatus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Активен' : 'Заблокирован',
        style: TextStyle(
          color: isActive ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDialogImage({
    File? fileImage,
    String? imageUrl,
    String? token,
    bool showPlaceholder = false,
    double width = 250,
    double height = 250,
  }) {
    // Если выбрано локальное изображение
    if (fileImage != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(fileImage),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    // Если есть ссылка на изображение
    else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              AppConstants.apiBaseUrl + imageUrl,
              headers: token != null ? {"Authorization": "Bearer $token"} : null,
            ),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    // Пустой контейнер с иконкой
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: showPlaceholder ? const Icon(Icons.person, size: 50) : null,
    );
  }

  // -------------------------------------------------------
  // Построение списка/пустого состояния
  // -------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      // Плашка, если нет пользователей
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          child: ListView(
            // ListView нужен, чтобы работал RefreshIndicator
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text('Нет пользователей. Добавьте нового пользователя.'),
              ),
            ],
          ),
        ),
      );
    }

    // Иначе отображаем список
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(
            AppConstants.apiBaseUrl + user.userAvatar,
            headers: _token != null ? {"Authorization": "Bearer $_token"} : null,
          ),
          backgroundColor: Colors.grey[300],
        ),
        title: Text(
          user.userFullname,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    user.userName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  user.userLastLoginDate.toLocal().toString().split('.')[0],
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(user),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      user.userGroup.groupName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildBody(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        tooltip: 'Добавить пользователя',
        child: const Icon(Icons.add),
      ),
    );
  }
}
