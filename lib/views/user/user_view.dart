import 'package:flutter/material.dart';
import 'package:wms/models/user.dart';
import 'package:wms/models/group.dart';
import 'package:wms/presenters/user/user_presenter.dart';
import 'package:wms/presenters/group/group_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  UserViewState createState() => UserViewState();
}

class UserViewState extends State<UserView> {
  late final UserPresenter _userPresenter;
  late final GroupPresenter _groupPresenter;

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userPresenter = UserPresenter();
    _groupPresenter = GroupPresenter();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _userPresenter.fetchAllUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Group>> _fetchGroupsForDialog() async {
    return await _groupPresenter.fetchAllGroups();
  }

  Future<void> _showUserDialog({User? user}) async {
    final fullNameController =
    TextEditingController(text: user?.userFullname ?? '');
    final usernameController =
    TextEditingController(text: user?.userName ?? '');
    final passwordController = TextEditingController();
    bool status = user?.userStatus ?? true;

    List<Group> allGroups = [];
    Group? selectedGroup = user?.userGroup;

    try {
      allGroups = await _fetchGroupsForDialog();
      if (user != null) {
        final foundIndex = allGroups
            .indexWhere((g) => g.groupID == user.userGroup.groupID);
        if (foundIndex >= 0) {
          selectedGroup = allGroups[foundIndex];
        }
      } else if (allGroups.isNotEmpty) {
        selectedGroup = allGroups.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке групп: $e')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text(user == null
                  ? 'Добавить пользователя'
                  : 'Редактировать пользователя'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameController,
                      decoration:
                      const InputDecoration(labelText: 'Полное имя'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Логин'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: user == null
                            ? 'Пароль (обязателен при создании)'
                            : 'Новый пароль (если нужно изменить)',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Group>(
                      decoration: const InputDecoration(labelText: 'Группа'),
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
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Статус'),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final fullName = fullNameController.text.trim();
                    final username = usernameController.text.trim();
                    final password = passwordController.text.trim();

                    if (fullName.isEmpty || username.isEmpty) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Полное имя и логин обязательны')),
                      );
                      return;
                    }
                    if (selectedGroup == null) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Выберите группу')),
                      );
                      return;
                    }

                    try {
                      if (user == null) {
                        if (password.isEmpty) {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Пароль обязателен при создании пользователя'),
                            ),
                          );
                          return;
                        }
                        debugPrint(
                            'Creating user: fullName=$fullName, username=$username, password=$password, groupID=${selectedGroup!.groupID}, status=$status');
                        await _userPresenter.createUser(
                          fullName: fullName,
                          username: username,
                          password: password,
                          group: selectedGroup!,
                          status: status,
                        );
                      } else {
                        debugPrint(
                            'Updating user: userID=${user.userID}, newFullName=$fullName, newUsername=$username, newPassword=${password.isEmpty ? 'NOT CHANGED' : password}, newGroupID=${selectedGroup!.groupID}, newStatus=$status');
                        await _userPresenter.updateUser(
                          user,
                          fullName: fullName,
                          username: username,
                          password: password.isEmpty ? null : password,
                          group: selectedGroup,
                          status: status,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _fetchUsers();
                    } catch (err) {
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(err.toString())),
                      );
                    }
                  },
                  child: Text(user == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(User user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        return AlertDialog(
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
        );
      },
    );
    if (confirmed == true) {
      try {
        await _userPresenter.deleteUser(user);
        if (!mounted) return;
        await _fetchUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildStatusChip(User user) {
    final isActive = user.userStatus;
    final text = isActive ? 'Активен' : 'Заблокирован';
    final bgColor = isActive ? Colors.green[100] : Colors.red[100];
    final textColor = isActive ? Colors.green[800] : Colors.red[800];

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStyledDataTable() {
    return DataTableTheme(
      data: DataTableThemeData(
        headingRowColor:
        WidgetStateProperty.all(Colors.blueGrey[50]),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => null),
        dataTextStyle: const TextStyle(fontSize: 14),
        dividerThickness: 1,
      ),
      child: DataTable(
        horizontalMargin: 10.0,
        columnSpacing: 16.0,
        columns: const [
          DataColumn(label: Text('Полное имя')),
          DataColumn(label: Text('Логин')),
          DataColumn(label: Text('Группа')),
          DataColumn(label: Text('Статус')),
          DataColumn(label: Text('Дата создания')),
          DataColumn(label: Text('Действия')),
        ],
        rows: List<DataRow>.generate(_users.length, (index) {
          final user = _users[index];
          final isEvenRow = index % 2 == 0;
          return DataRow(
            color: WidgetStateProperty.all(
                isEvenRow ? Colors.grey[50] : Colors.white),
            cells: [
              DataCell(Text(user.userFullname)),
              DataCell(Text(user.userName)),
              DataCell(Text(user.userGroup.groupName)),
              DataCell(_buildStatusChip(user)),
              DataCell(Text(user.userCreationDate
                  .toLocal()
                  .toString()
                  .split('.')[0])),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      onPressed: () => _showUserDialog(user: user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(user),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      drawer: const WmsDrawer(),
      body: Padding(
        padding: EdgeInsets.zero,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: constraints.maxWidth),
                  child: _buildStyledDataTable(),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        tooltip: 'Добавить пользователя',
        child: const Icon(Icons.add),
      ),
    );
  }
}
