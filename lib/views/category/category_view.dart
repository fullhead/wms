import 'package:flutter/material.dart';
import 'package:wms/models/category.dart';
import 'package:wms/presenters/category/category_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  CategoryViewState createState() => CategoryViewState();
}

class CategoryViewState extends State<CategoryView> {
  late final CategoryPresenter _presenter;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = CategoryPresenter();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _presenter.fetchAllCategory();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.categoryName ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text(category == null ? 'Добавить категорию' : 'Редактировать категорию'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
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
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Название обязательно')),
                      );
                      return;
                    }
                    try {
                      if (category == null) {
                        await _presenter.createCategory(categoryName: name);
                      } else {
                        await _presenter.updateCategory(category, name: name);
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _fetchCategories();
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  child: Text(category == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: Text('Вы уверены, что хотите удалить категорию "${category.categoryName}"?'),
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
        await _presenter.deleteCategory(category);
        await _fetchCategories();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildStyledDataTable() {
    return DataTableTheme(
      data: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        dataTextStyle: const TextStyle(fontSize: 14),
        dividerThickness: 1,
      ),
      child: DataTable(
        horizontalMargin: 10.0,
        columnSpacing: 16.0,
        columns: const [
          DataColumn(label: Text('Название')),
          DataColumn(
            label: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text('Действия'),
            ),
            headingRowAlignment: MainAxisAlignment.end,
          ),
        ],
        rows: List<DataRow>.generate(_categories.length, (index) {
          final category = _categories[index];
          final isEvenRow = index % 2 == 0;
          return DataRow(
            color: WidgetStateProperty.all(isEvenRow ? Colors.grey[50] : Colors.white),
            cells: [
              DataCell(Text(category.categoryName)),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.blue,
                        onPressed: () => _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => _confirmDelete(category),
                      ),
                    ],
                  ),
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
        title: const Text('Категории'),
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
        onPressed: () => _showCategoryDialog(),
        tooltip: 'Добавить категорию',
        child: const Icon(Icons.add),
      ),
    );
  }
}
