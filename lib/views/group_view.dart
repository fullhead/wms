import 'package:flutter/material.dart';
import 'package:wms/models/group.dart';
import 'package:wms/presenters/group_presenter.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

class GroupView extends StatefulWidget {
  const GroupView({super.key});

  @override
  GroupViewState createState() => GroupViewState();
}

class GroupViewState extends State<GroupView> {
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  late final GroupPresenter _presenter;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _presenter = GroupPresenter();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final groups = await _presenter.fetchAllGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -------------------------------------------------------
  // Диалоги создания/редактирования
  // -------------------------------------------------------
  Future<void> _showGroupDialog({Group? group}) async {
    // Получаем идентификатор группы авторизованного пользователя
    final currentUserGroup = await AuthStorage.getUserGroup();
    final currentUserGroupParsed = int.tryParse(currentUserGroup ?? '');
    // Если редактируемая группа совпадает с группой авторизованного пользователя, отключаем изменение статуса
    final disableStatusToggle = (group != null && group.groupID == currentUserGroupParsed);

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group?.groupName ?? '');
    // Начальное значение уровня доступа (по умолчанию "1", если group == null)
    String selectedAccessLevel = group?.groupAccessLevel ?? '1';
    bool status = group?.groupStatus ?? true;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            final theme = Theme.of(dialogContext);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                group == null ? 'Добавить группу' : 'Редактировать группу',
                style: theme.textTheme.titleMedium,
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Поле ввода названия
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название группы';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Для выбора уровня доступа (1, 2, 3)
                      DropdownButtonFormField<String>(
                        value: selectedAccessLevel,
                        decoration: const InputDecoration(
                          labelText: 'Уровень доступа',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '1',
                            child: Text('Уровень 1'),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text('Уровень 2'),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text('Уровень 3'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedAccessLevel = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Выберите уровень доступа';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Переключатель статуса
                      SwitchListTile(
                        title: const Text('Статус'),
                        value: status,
                        onChanged: disableStatusToggle
                            ? null
                            : (bool value) {
                          setStateDialog(() {
                            status = value;
                          });
                        },
                      ),
                      if (disableStatusToggle)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Нельзя изменить статус своей группы.",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameController.text.trim();
                    final level = selectedAccessLevel.trim();
                    try {
                      String responseMessage;
                      if (group == null) {
                        responseMessage = await _presenter.createGroup(
                          groupName: name,
                          groupAccessLevel: level,
                          groupStatus: status,
                        );
                      } else {
                        responseMessage = await _presenter.updateGroup(
                          group,
                          name: name,
                          accessLevel: level,
                          status: status,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadGroups();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(responseMessage),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  child: Text(group == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------
  // Диалог удаления группы
  // -------------------------------------------------------
  Future<void> _confirmDelete(Group group) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        final theme = Theme.of(alertContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Подтверждение', style: theme.textTheme.titleMedium),
          content: Text(
            'Вы уверены, что хотите удалить группу "${group.groupName}"?',
            style: theme.textTheme.bodyMedium,
          ),
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
        final responseMessage = await _presenter.deleteGroup(group);
        await _loadGroups();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // -------------------------------------------------------
  // Функция скелетона для группы
  // -------------------------------------------------------
  Widget _buildSkeletonCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 14,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 4),
            Container(
              width: 100,
              height: 14,
              color: theme.dividerColor,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Методы отрисовки группы
  // -------------------------------------------------------
  Widget _buildGroupCard(Group group) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Первая строка: название группы
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.groupName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Вторая строка: дата создания и уровень доступа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Дата создания: ${group.groupCreationDate.toLocal().toString().split('.')[0]}",
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Уровень: ${group.groupAccessLevel}",
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Третья строка: статус и кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildStatusChip(group)),
                Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                      onPressed: () => _showGroupDialog(group: group),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 24),
                      onPressed: () => _confirmDelete(group),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadGroups,
          child: ListView(
            children: const [
              SizedBox(height: 400),
              Center(child: Text('Нет групп. Добавьте новую группу.')),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return _buildGroupList();
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы', style: TextStyle(color: Colors.deepOrange)),
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: _loadGroups,
                child: _buildBody(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        tooltip: 'Добавить группу',
        child: const Icon(Icons.add),
      ),
    );
  }

  // -------------------------------------------------------
  // Пример функции для отображения статусного чипа группы
  // -------------------------------------------------------
  Widget _buildStatusChip(Group group) {
    final theme = Theme.of(context);
    final isActive = group.groupStatus;
    final text = isActive ? 'Активна' : 'Заблокирована';
    final bgColor = isActive
        ? theme.colorScheme.secondary.withValues(alpha: 0.1)
        : theme.colorScheme.error.withValues(alpha: 0.1);
    final textColor = isActive ? theme.colorScheme.secondary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
}
