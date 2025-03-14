import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/group.dart';
import 'package:wms/models/user.dart';
import 'package:wms/presenters/group_presenter.dart';
import 'package:wms/presenters/user_presenter.dart';
import 'package:wms/core/session/auth_storage.dart';
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
    _token = await AuthStorage.getAccessToken();
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
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.of(context).pop(await _pickImageFromGallery());
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.primary),
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
    final theme = Theme.of(context);
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                          child: CircleAvatar(
                            radius: imageSize / 2,
                            backgroundImage: CachedNetworkImageProvider(
                              AppConstants.apiBaseUrl + user.userAvatar,
                              headers: _token != null ? {"Authorization": "Bearer $_token"} : {},
                            ),
                            backgroundColor: theme.dividerColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.login, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Логин:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userName,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.info, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Статус:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            _buildStatusChip(user),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.group, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Группа:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userGroup.groupName,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Дата создания:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userCreationDate.toLocal().toString().split('.')[0],
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Последний вход:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.userLastLoginDate.toLocal().toString().split('.')[0],
                                style: theme.textTheme.bodyMedium,
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
                            icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                            label: Text(
                              "Редактировать",
                              style: TextStyle(color: theme.colorScheme.secondary),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _confirmDeleteUser(user);
                            },
                            icon: Icon(Icons.delete, color: theme.colorScheme.error),
                            label: Text(
                              "Удалить",
                              style: TextStyle(color: theme.colorScheme.error),
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
    final currentUserId = await AuthStorage.getUserID();
    final currentUserIdParsed = int.tryParse(currentUserId ?? '');
    final isCurrentUser = (user.userID == currentUserIdParsed);

    final parentContext = context;
    final editFormKey = GlobalKey<FormState>();

    final fullNameController = TextEditingController(text: user.userFullname);
    final usernameController = TextEditingController(text: user.userName);
    final passwordController = TextEditingController();

    String imagePath = user.userAvatar;
    File? editedImage;
    bool isAvatarDeleted = false;
    bool status = user.userStatus;
    if (isCurrentUser) status = true;

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
        final theme = Theme.of(inDialogContext);
        final size = MediaQuery.of(inDialogContext).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.6 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.78;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          title: Text(
            "Редактировать пользователя",
            style: theme.textTheme.titleMedium,
          ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: const Text("Удалить аватар"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: "Новый пароль (если нужно изменить)",
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Статус"),
                          value: status,
                          onChanged: isCurrentUser
                              ? null
                              : (value) {
                            setStateDialog(() {
                              status = value;
                            });
                          },
                        ),
                        if (isCurrentUser)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Нельзя заблокировать свою учетную запись.",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
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
                    String newAvatar;
                    if (isAvatarDeleted) {
                      await _userPresenter.deleteUserAvatar(user.userID);
                      newAvatar = '/assets/user/no_image_user.png';
                    } else if (editedImage != null) {
                      newAvatar = await _userPresenter.setUserAvatar(user.userID, editedImage!.path);
                    } else {
                      newAvatar = imagePath;
                    }
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
        final theme = Theme.of(inDialogContext);
        final size = MediaQuery.of(inDialogContext).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.6 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.78;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          title: Text(
            "Создать пользователя",
            style: theme.textTheme.titleMedium,
          ),
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
                                newImage = null;
                                setStateDialog(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: const Text("Очистить аватар"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: "Пароль"),
                          obscureText: true,
                          validator: (value) =>
                          (value == null || value.isEmpty) ? "Введите пароль" : null,
                        ),
                        const SizedBox(height: 10),
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
                    final responseMessage = await _userPresenter.createUser(
                      fullName: fullNameController.text.trim(),
                      username: usernameController.text.trim(),
                      password: passwordController.text.trim(),
                      group: selectedGroup!,
                      avatarFilePath: newImage?.path,
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

  // -------------------------------------------------------
  // Запрещаем удаление текущей учетной записи
  // -------------------------------------------------------
  Future<void> _confirmDeleteUser(User user) async {
    final currentUserId = await AuthStorage.getUserID();
    final currentUserIdParsed = int.tryParse(currentUserId ?? '');
    if (user.userID == currentUserIdParsed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Невозможно удалить учетную запись, с которой вы авторизованы."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (!mounted) return;
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.secondary;
    final errorColor = theme.colorScheme.error;
    final isActive = user.userStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withValues(alpha: 0.1)
            : errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Активен' : 'Заблокирован',
        style: TextStyle(
          color: isActive ? primaryColor : errorColor,
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
    final theme = Theme.of(context);
    if (fileImage != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(fileImage),
            fit: BoxFit.cover,
          ),
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
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
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: showPlaceholder ? const Icon(Icons.person, color: Colors.deepOrange, size: 50) : null,
    );
  }

  // -------------------------------------------------------
  // Построение основного интерфейса
  // -------------------------------------------------------
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        title: Container(
          width: double.infinity,
          height: 16,
          color: Colors.grey.shade300,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          height: 14,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_isLoading) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _loadUsers,
          child: ListView(
            children: const [
              SizedBox(height: 400),
              Center(child: Text('Нет пользователей. Добавьте нового пользователя.')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(
            AppConstants.apiBaseUrl + user.userAvatar,
            headers: _token != null ? {"Authorization": "Bearer $_token"} : {},
          ),
          backgroundColor: theme.dividerColor,
        ),
        title: Text(
          user.userFullname,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  user.userLastLoginDate.toLocal().toString().split('.')[0],
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
                    const Icon(Icons.group, color: Colors.deepOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      user.userGroup.groupName,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
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
        title: const Text('Пользователи', style: TextStyle(color: Colors.deepOrange)),
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
