import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/category.dart';
import 'package:wms/models/product.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  ProductViewState createState() => ProductViewState();
}

class ProductViewState extends State<ProductView> {
  // ───────────────────────────────────────────────────────────
  // Поля
  // ───────────────────────────────────────────────────────────
  final ProductPresenter _presenter = ProductPresenter();
  final ImagePicker _picker = ImagePicker();
  final List<Product> _products = [];
  final List<int> _selectedCategoryIds = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _token;

  // ───────────────────────────────────────────────────────────
  // Жизненный цикл
  // ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadProducts();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _presenter.fetchAllProduct();
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(products);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Служебные методы
  // ───────────────────────────────────────────────────────────
  Future<List<Category>> _loadCategoriesForProduct() async {
    final data = await _presenter.categoryApiService.getAllCategory();
    return data.map((json) => Category.fromJson(json)).toList();
  }

  /// Диалог выбора источника изображения ― всегда возвращает [XFile?]
  Future<XFile?> _showImageSourceSelectionDialog(
      BuildContext dialogContext) async {
    return showModalBottomSheet<XFile?>(
      context: dialogContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                Navigator.pop(context, pickedFile);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Сделать фото'),
              onTap: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (!mounted) return;
                Navigator.pop(context, pickedFile);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Поиск и фильтры
  // ───────────────────────────────────────────────────────────
  void _searchStub() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _searchQuery = '';
      });

  Future<void> _showFilterDialog() async {
    final categories = await _loadCategoriesForProduct();
    final tempSelected = Set<int>.from(_selectedCategoryIds);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                tempSelected.isNotEmpty ? Icons.filter_alt : Icons.filter_list,
                color: tempSelected.isNotEmpty
                    ? Theme.of(dialogContext).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 4),
              Text(
                  'По категориям${tempSelected.isNotEmpty ? ' (${tempSelected.length})' : ''}'),
            ],
          ),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                final isSelected = tempSelected.contains(cat.categoryID);
                return CheckboxListTile(
                  title: Text(
                    cat.categoryName,
                    style: TextStyle(
                      color:
                          isSelected ? Theme.of(ctx).colorScheme.primary : null,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (checked) {
                    if (checked == true) {
                      tempSelected.add(cat.categoryID);
                    } else {
                      tempSelected.remove(cat.categoryID);
                    }
                    (dialogContext as Element).markNeedsBuild();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryIds
                    ..clear()
                    ..addAll(tempSelected);
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // Виджеты-помощники
  // ───────────────────────────────────────────────────────────
  Widget _buildDialogImage({
    Uint8List? localBytes,
    String? imageUrl,
    String? token,
    bool showPlaceholder = false,
    double width = 250,
    double height = 250,
  }) {
    final theme = Theme.of(context);

    // локально выбранная картинка
    if (localBytes != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: MemoryImage(localBytes), fit: BoxFit.cover),
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // картинка с сервера
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              AppConstants.apiBaseUrl + imageUrl,
              headers:
                  token != null ? {"Authorization": "Bearer $token"} : null,
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
          color: theme.dividerColor, borderRadius: BorderRadius.circular(4)),
      child: showPlaceholder
          ? const Icon(Icons.image, color: Colors.deepOrange, size: 50)
          : null,
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8)),
        ),
        title: Container(
            width: double.infinity, height: 16, color: Colors.grey.shade300),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          height: 14,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Диалоги: детали / редактирование / создание / удаление
  // ───────────────────────────────────────────────────────────
  void _showProductDetails(Product product) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final dialogWidth = isDesktop ? size.width * 0.5 : size.width * 0.9;
    final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.46;
    final imageSize = isDesktop ? 600.0 : 280.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(product.productName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDialogImage(
                    imageUrl: product.productImage,
                    token: _token,
                    width: imageSize,
                    height: imageSize,
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditProductDialog(product);
                        },
                        icon: Icon(Icons.edit,
                            color: theme.colorScheme.secondary),
                        label: Text("Редактировать",
                            style:
                                TextStyle(color: theme.colorScheme.secondary)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteProduct(product);
                        },
                        icon:
                            Icon(Icons.delete, color: theme.colorScheme.error),
                        label: Text("Удалить",
                            style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────── редактирование ─────────────────────
  Future<void> _showEditProductDialog(Product product) async {
    final parentContext = context;
    final editFormKey = GlobalKey<FormState>();

    String editedName = product.productName;
    String editedBarcode = product.productBarcode;
    Category? editedCategory = product.productCategory;
    XFile? editedImage;
    Uint8List? editedBytes;
    List<Category> allCategories = [];

    try {
      allCategories = await _loadCategoriesForProduct();
      final found = allCategories.indexWhere(
          (cat) => cat.categoryID == product.productCategory.categoryID);
      editedCategory = found >= 0
          ? allCategories[found]
          : allCategories.isNotEmpty
              ? allCategories.first
              : null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки категорий: $e")),
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
        final dialogWidth = isDesktop ? size.width * 0.5 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.7;
        final imageHeight = isDesktop ? 430.0 : 300.0;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          title:
              Text("Редактировать продукт", style: theme.textTheme.titleMedium),
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
                            final result =
                                await _showImageSourceSelectionDialog(
                                    inDialogContext);
                            if (result != null) {
                              editedImage = result;
                              editedBytes = await result.readAsBytes();
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            localBytes: editedBytes,
                            imageUrl: product.productImage,
                            token: _token,
                            width: double.infinity,
                            height: imageHeight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final result =
                                await _showImageSourceSelectionDialog(
                                    inDialogContext);
                            if (result != null) {
                              editedImage = result;
                              editedBytes = await result.readAsBytes();
                              setStateDialog(() {});
                            }
                          },
                          child: const Text("Изменить изображение"),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: editedName,
                          decoration: const InputDecoration(
                              labelText: "Название продукта"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Введите название"
                              : null,
                          onSaved: (v) => editedName = v!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: editedBarcode,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner,
                                  color: Colors.deepOrange),
                              onPressed: () async {
                                final scanned = await _scanBarcode();
                                setStateDialog(
                                    () => editedBarcode = scanned ?? "");
                              },
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Введите штрихкод"
                              : null,
                          onSaved: (v) => editedBarcode = v!,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration:
                              const InputDecoration(labelText: "Категория"),
                          value: editedCategory,
                          items: allCategories
                              .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat.categoryName)))
                              .toList(),
                          onChanged: (v) =>
                              setStateDialog(() => editedCategory = v),
                          validator: (v) =>
                              v == null ? "Выберите категорию" : null,
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
                onPressed: () => Navigator.pop(inDialogContext),
                child: const Text("Отмена")),
            TextButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  editFormKey.currentState!.save();
                  try {
                    String imagePath = product.productImage;
                    if (editedImage != null) {
                      imagePath = kIsWeb
                          ? await _presenter.productApiService
                              .uploadProductImage(
                              bytes: editedBytes!,
                              filename: editedImage!.name,
                            )
                          : await _presenter.productApiService
                              .uploadProductImage(
                              imagePath: editedImage!.path,
                            );
                    }
                    product
                      ..productName = editedName
                      ..productBarcode = editedBarcode
                      ..productImage = imagePath
                      ..productCategory = editedCategory!;
                    final msg = await _presenter.updateProduct(product);
                    if (inDialogContext.mounted) Navigator.pop(inDialogContext);
                    await _loadProducts();
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    }
                  } catch (e) {
                    if (inDialogContext.mounted) {
                      Navigator.pop(inDialogContext);
                      ScaffoldMessenger.of(inDialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString())),
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

  // ───────────────────── создание ─────────────────────
  Future<void> _showCreateProductDialog() async {
    final parentContext = context;
    final createFormKey = GlobalKey<FormState>();
    final barcodeController = TextEditingController();

    String newName = '';
    Category? newCategory;
    XFile? newImage;
    Uint8List? newBytes;
    List<Category> allCategories = [];

    try {
      allCategories = await _loadCategoriesForProduct();
      newCategory = allCategories.isNotEmpty ? allCategories.first : null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки категорий: $e")),
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
        final dialogWidth = isDesktop ? size.width * 0.5 : size.width * 0.95;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.7;

        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          title: Text("Создать продукт", style: theme.textTheme.titleMedium),
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
                            final result =
                                await _showImageSourceSelectionDialog(
                                    inDialogContext);
                            if (result != null) {
                              newImage = result;
                              newBytes = await result.readAsBytes();
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            localBytes: newBytes,
                            imageUrl: "",
                            showPlaceholder: true,
                            width: isDesktop ? 300 : 250,
                            height: isDesktop ? 300 : 250,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final result =
                                await _showImageSourceSelectionDialog(
                                    inDialogContext);
                            if (result != null) {
                              newImage = result;
                              newBytes = await result.readAsBytes();
                              setStateDialog(() {});
                            }
                          },
                          child: const Text("Выбрать изображение"),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: "Название продукта"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Введите название"
                              : null,
                          onSaved: (v) => newName = v!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner,
                                  color: Colors.deepOrange),
                              onPressed: () async {
                                final scanned = await _scanBarcode();
                                setStateDialog(() =>
                                    barcodeController.text = scanned ?? "");
                              },
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Введите штрихкод"
                              : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration:
                              const InputDecoration(labelText: "Категория"),
                          value: newCategory,
                          items: allCategories
                              .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat.categoryName)))
                              .toList(),
                          onChanged: (v) =>
                              setStateDialog(() => newCategory = v),
                          validator: (v) =>
                              v == null ? "Выберите категорию" : null,
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
                onPressed: () => Navigator.pop(inDialogContext),
                child: const Text("Отмена")),
            TextButton(
              onPressed: () async {
                if (createFormKey.currentState!.validate() &&
                    newCategory != null) {
                  createFormKey.currentState!.save();
                  try {
                    String imagePath = '';
                    if (newImage != null) {
                      imagePath = kIsWeb
                          ? await _presenter.productApiService
                              .uploadProductImage(
                              bytes: newBytes!,
                              filename: newImage!.name,
                            )
                          : await _presenter.productApiService
                              .uploadProductImage(
                              imagePath: newImage!.path,
                            );
                    }
                    final msg = await _presenter.createProduct(
                      category: newCategory!,
                      productName: newName,
                      productBarcode: barcodeController.text,
                      productImage: imagePath,
                    );
                    if (inDialogContext.mounted) Navigator.pop(inDialogContext);
                    await _loadProducts();
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    }
                  } catch (e) {
                    if (inDialogContext.mounted) {
                      Navigator.pop(inDialogContext);
                      ScaffoldMessenger.of(inDialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString())),
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

  // ───────────────────── удаление ─────────────────────
  Future<void> _confirmDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (alert) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить продукт "${product.productName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(alert, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(alert, true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final msg = await _presenter.deleteProduct(product);
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────
  // Основное тело списка
  // ───────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    final displayed = _products.where((p) {
      final matchCat = _selectedCategoryIds.isEmpty ||
          _selectedCategoryIds.contains(p.productCategory.categoryID);
      final matchSearch = _searchQuery.isEmpty ||
          p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (_, __) => _buildSkeletonCard(),
      );
    }

    if (displayed.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
                child: Text('Ничего не найдено!',
                    style: Theme.of(context).textTheme.bodyMedium)),
          ],
        );
      }
      if (_selectedCategoryIds.isNotEmpty) {
        return Center(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            color: Theme.of(context).colorScheme.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: const [
                SizedBox(height: 400),
                Center(
                    child: Text('По выбранным фильтрам не найдено продукции.')),
              ],
            ),
          ),
        );
      }
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 400),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Нет продукции. Добавьте новую продукцию.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _showCreateProductDialog,
                        child: const Text('Добавить')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayed.length,
        itemBuilder: (_, i) => _buildProductCard(displayed[i]),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: AppConstants.apiBaseUrl + product.productImage,
            httpHeaders:
                _token != null ? {"Authorization": "Bearer $_token"} : {},
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(product.productName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.document_scanner,
                  color: Colors.deepOrange, size: 16),
              const SizedBox(width: 4),
              Text(product.productBarcode,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
            ]),
            Row(children: [
              const Icon(Icons.category, color: Colors.deepOrange, size: 16),
              const SizedBox(width: 4),
              Text(product.productCategory.categoryName,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
            ]),
          ]),
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: "Поиск по продукции...",
                    border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text("Продукция",
                style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.deepOrange),
                    onPressed: _stopSearch),
              ]
            : [
                IconButton(
                    icon: const Icon(Icons.search, color: Colors.deepOrange),
                    onPressed: _searchStub),
                Stack(children: [
                  IconButton(
                    icon: Icon(
                      _selectedCategoryIds.isNotEmpty
                          ? Icons.filter_alt
                          : Icons.filter_list,
                      color: Colors.deepOrange,
                    ),
                    onPressed: _showFilterDialog,
                  ),
                  if (_selectedCategoryIds.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('${_selectedCategoryIds.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ]),
              ],
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (_, c) => Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildBody(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _showCreateProductDialog, child: const Icon(Icons.add)),
    );
  }
}
