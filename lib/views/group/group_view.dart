import 'package:flutter/material.dart';
import 'package:wms/models/group.dart';
import 'package:wms/presenters/group/group_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';

class GroupView extends StatefulWidget {
  const GroupView({super.key});

  @override
  GroupViewState createState() => GroupViewState();
}

class GroupViewState extends State<GroupView> {
  late final GroupPresenter _presenter;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showGroupDialog({Group? group}) async {
    final nameController = TextEditingController(text: group?.groupName ?? '');
    final levelController = TextEditingController(text: group?.groupAccessLevel ?? '1');
    bool status = group?.groupStatus ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(group == null ? 'Добавить группу' : 'Редактировать группу'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(
                        labelText: 'Уровень доступа',
                        border: OutlineInputBorder(),
                      ),
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
                    final name = nameController.text.trim();
                    final level = levelController.text.trim();
                    if (name.isEmpty || level.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Все поля обязательны')),
                      );
                      return;
                    }
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

  Future<void> _confirmDelete(Group group) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Подтверждение'),
          content: Text('Вы уверены, что хотите удалить группу "${group.groupName}"?'),
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
        String responseMessage = await _presenter.deleteGroup(group);
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

  Widget _buildStatusChip(Group group) {
    final isActive = group.groupStatus;
    final text = isActive ? 'Активна' : 'Заблокирована';
    final bgColor = isActive ? Colors.green[100] : Colors.red[100];
    final textColor = isActive ? Colors.green[800] : Colors.red[800];

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

  Widget _buildGroupCard(Group group) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Первая строка: название группы
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Вторая строка: статус слева и уровень доступа (прижат к правому краю) справа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(group),
                Text(
                  "Уровень: ${group.groupAccessLevel}  ",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Третья строка: дата создания слева и кнопки действий справа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Дата создание: ${group.groupCreationDate.toLocal().toString().split('.')[0]}",
                  style: const TextStyle(fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showGroupDialog(group: group),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                      onPressed: () => _confirmDelete(group),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const Center(
        child: Text('Нет групп. Добавьте новую группу.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
      ),
      drawer: const WmsDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _buildGroupList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        tooltip: 'Добавить группу',
        child: const Icon(Icons.add),
      ),
    );
  }
}
