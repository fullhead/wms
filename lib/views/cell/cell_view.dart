import 'package:flutter/material.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/presenters/cell/cell_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';

class CellView extends StatefulWidget {
  const CellView({super.key});

  @override
  CellViewState createState() => CellViewState();
}

class CellViewState extends State<CellView> {
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  late final CellPresenter _presenter;
  List<Cell> _cells = [];
  bool _isLoading = false;
  String? _errorMessage;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _presenter = CellPresenter();
    _loadCells();
  }

  Future<void> _loadCells() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cells = await _presenter.fetchAllCells();
      if (!mounted) return;
      setState(() => _cells = cells);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -------------------------------------------------------
  // Диалоги создания/редактирования
  // -------------------------------------------------------
  Future<void> _showCellDialog({Cell? cell}) async {
    final nameController = TextEditingController(text: cell?.cellName ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                cell == null ? 'Добавить ячейку' : 'Редактировать ячейку',
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Название обязательно')),
                      );
                      return;
                    }
                    try {
                      String responseMessage;
                      if (cell == null) {
                        responseMessage = await _presenter.createCell(cellName: name);
                      } else {
                        responseMessage = await _presenter.updateCell(cell, name: name);
                      }

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      await _loadCells();
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
                  child: Text(cell == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------
  // Диалог удаления
  // -------------------------------------------------------
  Future<void> _confirmDelete(Cell cell) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Подтверждение'),
          content: Text('Вы уверены, что хотите удалить ячейку "${cell.cellName}"?'),
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
        final responseMessage = await _presenter.deleteCell(cell);
        await _loadCells();
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
  // Вспомогательные методы отображения
  // -------------------------------------------------------
  Widget _buildCellCard(Cell cell) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          cell.cellName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showCellDialog(cell: cell),
            ),
            const SizedBox(width: 16),
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(cell),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellList() {
    if (_cells.isEmpty) {
      return const Center(
        child: Text('Нет ячеек. Добавьте новую ячейку.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _cells.length,
      itemBuilder: (context, index) {
        final cell = _cells[index];
        return _buildCellCard(cell);
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return _buildCellList();
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ячейки'),
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: _loadCells,
                child: _buildBody(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCellDialog(),
        tooltip: 'Добавить ячейку',
        child: const Icon(Icons.add),
      ),
    );
  }
}
