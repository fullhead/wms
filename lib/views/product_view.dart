import 'dart:io';
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
  // -------------------------------------------------------
  // Поля класса
  // -------------------------------------------------------
  final ProductPresenter _presenter = ProductPresenter();
  final ImagePicker _picker = ImagePicker();
  final List<Product> _products = [];
  final List<int> _selectedCategoryIds = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _token;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadProducts();
  }

  Future<void> _loadToken() async {
    // Используем getAccessToken() вместо getToken()
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
        SnackBar(
          content: Text("Ошибка загрузки: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------
  // Приватные методы для диалогов и т. п.
  // -------------------------------------------------------
  Future<List<Category>> _loadCategoriesForProduct() async {
    final data = await _presenter.categoryApiService.getAllCategory();
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<File?> _showImageSourceSelectionDialog(BuildContext dialogContext) async {
    return showModalBottomSheet<File?>(
      context: dialogContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                Navigator.of(context).pop(pickedFile != null ? File(pickedFile.path) : null);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.primary),
              title: const Text('Сделать фото'),
              onTap: () async {
                final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (!mounted) return;
                Navigator.of(context).pop(pickedFile != null ? File(pickedFile.path) : null);
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
    } catch (e) {
      return null;
    }
  }

  // Методы поиска и фильтрации
  void _searchStub() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

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
                color: tempSelected.isNotEmpty ? Theme.of(dialogContext).colorScheme.primary : null,
              ),
              const SizedBox(width: 4),
              Text('По категориям${tempSelected.isNotEmpty ? ' (${tempSelected.length})' : ''}'),
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
                      color: isSelected ? Theme.of(ctx).colorScheme.primary : null,
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
              child: const Text('Отмена'),
            ),
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

  // -------------------------------------------------------
  // Методы отображения продукта (детали, редактирование, создание, удаление)
  // -------------------------------------------------------
  void _showProductDetails(Product product) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.5 : size.width * 0.9;
        final dialogHeight = isDesktop ? size.height * 0.6 : size.height * 0.46;
        final imageSize = isDesktop ? 750.0 : 300.0;
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    product.productName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
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
                    fileImage: null,
                    imageUrl: product.productImage,
                    token: _token,
                    width: imageSize,
                    height: imageSize,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showEditProductDialog(product);
                        },
                        icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                        label: Text(
                          "Редактировать",
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmDeleteProduct(product);
                        },
                        icon: Icon(Icons.delete, color: theme.colorScheme.error),
                        label: Text(
                          "Удалить",
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
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

  Future<void> _showEditProductDialog(Product product) async {
    final parentContext = context;
    final editFormKey = GlobalKey<FormState>();

    String editedName = product.productName;
    String editedBarcode = product.productBarcode;
    Category? editedCategory = product.productCategory;
    File? editedImage;
    List<Category> allCategories = [];

    try {
      allCategories = await _loadCategoriesForProduct();
      final foundIndex = allCategories.indexWhere(
            (cat) => cat.categoryID == product.productCategory.categoryID,
      );
      if (foundIndex >= 0) {
        editedCategory = allCategories[foundIndex];
      } else if (allCategories.isNotEmpty) {
        editedCategory = allCategories.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка загрузки категорий: $e"),
          duration: const Duration(seconds: 2),
        ),
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
          title: Text(
            "Редактировать продукт",
            style: theme.textTheme.titleMedium,
          ),
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
                            final result = await _showImageSourceSelectionDialog(inDialogContext);
                            if (result != null) {
                              editedImage = result;
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            fileImage: editedImage,
                            imageUrl: product.productImage,
                            token: _token,
                            width: double.infinity,
                            height: imageHeight,
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
                          child: const Text("Изменить изображение"),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: editedName,
                          decoration: const InputDecoration(labelText: "Название продукта"),
                          validator: (value) => (value == null || value.isEmpty) ? "Введите название" : null,
                          onSaved: (value) => editedName = value!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: editedBarcode,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner, color: Colors.deepOrange),
                              onPressed: () async {
                                final scannedCode = await _scanBarcode();
                                setStateDialog(() {
                                  editedBarcode = scannedCode ?? "";
                                });
                              },
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? "Введите штрихкод" : null,
                          onSaved: (value) => editedBarcode = value!,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(labelText: "Категория"),
                          value: editedCategory,
                          items: allCategories.map((cat) {
                            return DropdownMenuItem<Category>(
                              value: cat,
                              child: Text(cat.categoryName),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              editedCategory = newValue;
                            });
                          },
                          validator: (value) => value == null ? "Выберите категорию" : null,
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
                  editFormKey.currentState!.save();
                  try {
                    String imagePath = product.productImage;
                    if (editedImage != null) {
                      imagePath = await _presenter.productApiService.uploadProductImage(editedImage!.path);
                    }
                    product.productName = editedName;
                    product.productBarcode = editedBarcode;
                    product.productImage = imagePath;
                    if (editedCategory != null) {
                      product.productCategory = editedCategory!;
                    }
                    final responseMessage = await _presenter.updateProduct(product);
                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                    }
                    await _loadProducts();
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
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateProductDialog() async {
    final parentContext = context;
    final createFormKey = GlobalKey<FormState>();
    final barcodeController = TextEditingController();

    String newName = '';
    Category? newCategory;
    File? newImage;
    List<Category> allCategories = [];

    try {
      allCategories = await _loadCategoriesForProduct();
      if (allCategories.isNotEmpty) {
        newCategory = allCategories.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка при загрузке категорий: $e"),
          duration: const Duration(seconds: 2),
        ),
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
          title: Text(
            "Создать продукт",
            style: theme.textTheme.titleMedium,
          ),
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
                            final result = await _showImageSourceSelectionDialog(inDialogContext);
                            if (result != null) {
                              newImage = result;
                              setStateDialog(() {});
                            }
                          },
                          child: _buildDialogImage(
                            fileImage: newImage,
                            imageUrl: "",
                            width: isDesktop ? 300 : 250,
                            height: isDesktop ? 300 : 250,
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
                          child: const Text("Выбрать изображение"),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Название продукта"),
                          validator: (value) => (value == null || value.isEmpty) ? "Введите название" : null,
                          onSaved: (value) => newName = value!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner, color: Colors.deepOrange),
                              onPressed: () async {
                                final scannedCode = await _scanBarcode();
                                setStateDialog(() {
                                  barcodeController.text = scannedCode ?? "";
                                });
                              },
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? "Введите штрихкод" : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(labelText: "Категория"),
                          value: newCategory,
                          items: allCategories.map((cat) {
                            return DropdownMenuItem<Category>(
                              value: cat,
                              child: Text(cat.categoryName),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              newCategory = newValue;
                            });
                          },
                          validator: (value) => value == null ? "Выберите категорию" : null,
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
              onPressed: () {
                if (inDialogContext.mounted) {
                  Navigator.of(inDialogContext).pop();
                }
              },
              child: const Text("Отмена"),
            ),
            TextButton(
              onPressed: () async {
                if (createFormKey.currentState!.validate() && newCategory != null) {
                  createFormKey.currentState!.save();
                  try {
                    String imagePath = '';
                    if (newImage != null) {
                      imagePath = await _presenter.productApiService.uploadProductImage(newImage!.path);
                    }
                    final responseMessage = await _presenter.createProduct(
                      category: newCategory!,
                      productName: newName,
                      productBarcode: barcodeController.text,
                      productImage: imagePath,
                    );
                    if (inDialogContext.mounted) {
                      Navigator.of(inDialogContext).pop();
                    }
                    await _loadProducts();
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

  Future<void> _confirmDeleteProduct(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить продукт "${product.productName}"?'),
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
        final responseMessage = await _presenter.deleteProduct(product);
        await _loadProducts();
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

  // -------------------------------------------------------
  // Построение виджета для отображения изображения в диалоге
  // -------------------------------------------------------
  Widget _buildDialogImage({
    File? fileImage,
    String? imageUrl,
    String? token,
    bool showPlaceholder = false,
    double width = 250,
    double height = 250,
  }) {
    final theme = Theme.of(context);
    if (fileImage != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(fileImage),
            fit: BoxFit.cover,
          ),
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              AppConstants.apiBaseUrl + imageUrl,
              headers: token != null ? {"Authorization": "Bearer $token"} : null,
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
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: showPlaceholder ? const Icon(Icons.image, color: Colors.deepOrange, size: 50) : null,
    );
  }

  // -------------------------------------------------------
  // Построение Skeleton-карточки для продукции
  // -------------------------------------------------------
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        title: Container(
          width: double.infinity,
          height: 16,
          color: Colors.grey.shade300,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          height: 14,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Построение основного интерфейса
  // -------------------------------------------------------
  Widget _buildBody(BuildContext context) {
    final displayedProducts = _products.where((p) {
      final matchesCategory = _selectedCategoryIds.isEmpty
          ? true
          : _selectedCategoryIds.contains(p.productCategory.categoryID);
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (displayedProducts.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        // Если поиск нечего не дал, выводим сообщение
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
              child: Text(
                'Нечего не найдено!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      }
      if (_selectedCategoryIds.isNotEmpty) {
        // Если активны фильтры или задан поисковый запрос
        return Center(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            color: Theme.of(context).colorScheme.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: const [
                SizedBox(height: 400),
                Center(child: Text('По выбранным фильтрам не найдено продукции.')),
              ],
            ),
          ),
        );
      } else {
        // Если в базе вообще нет данных
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
                      Text(
                        'Нет продукции. Добавьте новую продукцию.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateProductDialog,
                        child: const Text('Добавить продукцию'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayedProducts.length,
        itemBuilder: (context, index) {
          final product = displayedProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  // -------------------------------------------------------
  // Построение карточки продукта
  // -------------------------------------------------------
  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: AppConstants.apiBaseUrl + product.productImage,
            httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          product.productName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner, color: Colors.deepOrange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.productBarcode,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.category, color: Colors.deepOrange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.productCategory.categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  // -------------------------------------------------------
  // Основной build метода
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Поиск по продукции...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text("Продукция", style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.deepOrange),
            onPressed: _stopSearch,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.deepOrange),
            onPressed: _searchStub,
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _selectedCategoryIds.isNotEmpty ? Icons.filter_alt : Icons.filter_list,
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
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_selectedCategoryIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildBody(context),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
