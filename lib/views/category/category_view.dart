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
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  late final CategoryPresenter _presenter;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _presenter = CategoryPresenter();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
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
        setState(() => _isLoading = false);
      }
    }
  }

  // -------------------------------------------------------
  // Методы для создания/редактирования категории
  // -------------------------------------------------------
  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(
      text: category?.categoryName ?? '',
    );

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
                category == null ? 'Добавить категорию' : 'Редактировать категорию',
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
                      if (category == null) {
                        responseMessage = await _presenter.createCategory(
                          categoryName: name,
                        );
                      } else {
                        responseMessage = await _presenter.updateCategory(
                          category,
                          name: name,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadCategories();
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
                  child: Text(category == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------
  // Методы для удаления категории
  // -------------------------------------------------------
  Future<void> _confirmDelete(Category category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Подтверждение'),
          content: Text(
            'Вы уверены, что хотите удалить категорию "${category.categoryName}"?',
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
        final responseMessage = await _presenter.deleteCategory(category);
        await _loadCategories();
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
  // Вспомогательные методы отрисовки
  // -------------------------------------------------------
  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          category.categoryName,
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
              onPressed: () => _showCategoryDialog(category: category),
            ),
            const SizedBox(width: 16),
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      // Плашка, если нет категорий
      return const Center(
        child: Text('Нет категорий. Добавьте новую категорию.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildBody() {
    // Если идёт загрузка
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Если есть ошибка
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    // Иначе рендерим список (возможен пустой или нет)
    return _buildCategoryList();
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: _loadCategories,
                child: _buildBody(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        tooltip: 'Добавить категорию',
        child: const Icon(Icons.add),
      ),
    );
  }
}
