import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/presenters/user/user_presenter.dart';
import 'package:wms/presenters/group/group_presenter.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  UserViewState createState() => UserViewState();
}

class UserViewState extends State<UserView> {
  late final UserPresenter _userPresenter;
  late final GroupPresenter _groupPresenter;
  final ImagePicker _picker = ImagePicker();

  List<User> _users = [];
  bool _isLoading = false;
  String? _token;

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
      if (mounted) setState(() => _users = users);
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


  void _showUserDetails(User user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.all(10),
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
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _buildDialogImage(
                  fileImage: null,
                  imageUrl: user.userAvatar,
                  token: _token,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.login, size: 16),
                  const SizedBox(width: 4),
                  const Text("Логин:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(user.userName, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.info, size: 16),
                  const SizedBox(width: 4),
                  const Text("Статус:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  _buildStatusChip(user),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.group, size: 16),
                  const SizedBox(width: 4),
                  const Text("Группа:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(user.userGroup.groupName, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  const Text("Дата создания:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    user.userCreationDate.toLocal().toString().split('.')[0],
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  const Text("Последний вход:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    user.userLastLoginDate.toLocal().toString().split('.')[0],
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showEditUserDialog(user);
                    },
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    label: const Text("Редактировать", style: TextStyle(color: Colors.blue)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteUser(user);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Удалить", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(User user) async {
    final parentContext = context;
    final editFormKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.userFullname);
    final usernameController = TextEditingController(text: user.userName);
    final passwordController = TextEditingController();
    String imagePath = user.userAvatar;
    File? editedImage;
    bool status = user.userStatus;
    Group? selectedGroup = user.userGroup;
    List<Group> allGroups = [];

    try {
      allGroups = await _loadGroupsForUser();
      final foundIndex =
      allGroups.indexWhere((g) => g.groupID == user.userGroup.groupID);
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
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Редактировать пользователя"),
          content: SizedBox(
            width: size.width * 0.95,
            height: size.height * 0.7,
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
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) => value == null || value.isEmpty ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) => value == null || value.isEmpty ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: "Новый пароль (если нужно изменить)"),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Group>(
                          decoration: const InputDecoration(labelText: "Группа"),
                          value: selectedGroup,
                          items: allGroups
                              .map((g) => DropdownMenuItem<Group>(
                            value: g,
                            child: Text(g.groupName),
                          ))
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
                    String newAvatar = imagePath;
                    if (editedImage != null) {
                      newAvatar = await _userPresenter.userApiService.uploadUserAvatar(editedImage!.path);
                    }
                    final responseMessage = await _userPresenter.updateUser(
                      user,
                      fullName: fullNameController.text.trim(),
                      username: usernameController.text.trim(),
                      avatar: newAvatar,
                      status: status,
                      password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
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
                  }catch (e) {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка загрузки групп: $e")));
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (inDialogContext) {
        final size = MediaQuery.of(inDialogContext).size;
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Создать пользователя"),
          content: SizedBox(
            width: size.width * 0.95,
            height: size.height * 0.7,
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
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(labelText: "Полное имя"),
                          validator: (value) => value == null || value.isEmpty ? "Введите полное имя" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(labelText: "Логин"),
                          validator: (value) => value == null || value.isEmpty ? "Введите логин" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: "Пароль"),
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty ? "Введите пароль" : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Group>(
                          decoration: const InputDecoration(labelText: "Группа"),
                          value: selectedGroup,
                          items: allGroups
                              .map((g) => DropdownMenuItem<Group>(
                            value: g,
                            child: Text(g.groupName),
                          ))
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
                    if (newImage != null) {
                      avatarPath = await _userPresenter.userApiService.uploadUserAvatar(newImage!.path);
                    }
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
  }) {
    if (fileImage != null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(fileImage),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 250,
        height: 250,
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
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: showPlaceholder ? const Icon(Icons.person, size: 50) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      drawer: const WmsDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
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
                        Text(user.userName, style: const TextStyle(fontSize: 14)),
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
                          children: [
                            const Icon(Icons.group, size: 16),
                            const SizedBox(width: 4),
                            Text(user.userGroup.groupName, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                onTap: () => _showUserDetails(user),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        tooltip: 'Добавить пользователя',
        child: const Icon(Icons.add),
      ),
    );
  }
}
