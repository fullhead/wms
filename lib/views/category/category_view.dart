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
  // Диалоги создания/редактирования категории
  // -------------------------------------------------------
  Future<void> _showCategoryDialog({Category? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: category?.categoryName ?? '',
    );
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
                category == null ? 'Добавить категорию' : 'Редактировать категорию',
                style: theme.textTheme.titleMedium,
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Название',
                            // Глобальная тема InputDecorationTheme обеспечит видимый контур
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите название категории';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
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
  // Диалог удаления категории
  // -------------------------------------------------------
  Future<void> _confirmDelete(Category category) async {
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
            'Вы уверены, что хотите удалить категорию "${category.categoryName}"?',
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
  // Методы отрисовки
  // -------------------------------------------------------
  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          category.categoryName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
              onPressed: () => _showCategoryDialog(category: category),
            ),
            const SizedBox(width: 16),
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 24),
              onPressed: () => _confirmDelete(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Container(
          width: double.infinity,
          height: 16,
          color: theme.dividerColor,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              color: theme.dividerColor,
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              color: theme.dividerColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          child: ListView(
            children: const [
              SizedBox(height: 400),
              Center(child: Text('Нет категорий. Добавьте новую категорию.')),
            ],
          ),
        ),
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
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 12,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return _buildCategoryList();
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории', style: TextStyle(color: Colors.deepOrange)),
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
