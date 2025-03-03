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
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
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
              title: Text(group == null ? 'Добавить группу' : 'Редактировать группу'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(labelText: 'Уровень доступа'),
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
                      if (group == null) {
                        await _presenter.createGroup(
                          groupName: name,
                          groupAccessLevel: level,
                          groupStatus: status,
                        );
                      } else {
                        await _presenter.updateGroup(
                          group,
                          name: name,
                          accessLevel: level,
                          status: status,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _fetchGroups();
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
        await _presenter.deleteGroup(group);
        await _fetchGroups();
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

  Widget _buildStyledDataTable() {
    return DataTableTheme(
      data: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => null,
        ),
        dataTextStyle: const TextStyle(fontSize: 14),
        dividerThickness: 1,
      ),
      child: DataTable(
        horizontalMargin: 10.0,
        columnSpacing: 16.0,
        columns: const [
          DataColumn(label: Text('Название')),
          DataColumn(label: Text('Уровень')),
          DataColumn(label: Text('Статус')),
          DataColumn(label: Text('Дата создания')),
          DataColumn(label: Text('Действия')),
        ],
        rows: List<DataRow>.generate(_groups.length, (index) {
          final group = _groups[index];
          final isEvenRow = index % 2 == 0;
          return DataRow(
            color: WidgetStateProperty.all(isEvenRow ? Colors.grey[50] : Colors.white),
            cells: [
              DataCell(Text(group.groupName)),
              DataCell(Center(child: Text(group.groupAccessLevel))),
              DataCell(_buildStatusChip(group)),
              DataCell(Text(
                group.groupCreationDate.toLocal().toString().split('.')[0],
              )),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      onPressed: () => _showGroupDialog(group: group),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(group),
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
        title: const Text('Группы'),
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
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: _buildStyledDataTable(),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        tooltip: 'Добавить группу',
        child: const Icon(Icons.add),
      ),
    );
  }
}
