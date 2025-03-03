import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/category.dart';
import 'package:wms/models/product.dart';
import 'package:wms/presenters/product/product_presenter.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  ProductViewState createState() => ProductViewState();
}

class ProductViewState extends State<ProductView> {
  final ProductPresenter _presenter = ProductPresenter();
  final List<Product> _products = [];
  bool _isLoading = false;
  String? _token;
  bool _isSearching = false;
  String _searchQuery = '';
  final ImagePicker _picker = ImagePicker();
  final List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadProducts();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _presenter.fetchAllProduct();
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
      setState(() => _isLoading = false);
    }
  }

  Future<List<Category>> _fetchCategoriesForDialog() async {
    final data = await _presenter.categoryApiService.getAllCategory();
    return data.map((json) => Category.fromJson(json)).toList();
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

  /// Диалог выбора источника изображения (галерея или камера)
  Future<File?> _showImageSourceSelectionDialog(BuildContext dialogContext) async {
    return showModalBottomSheet<File?>(
      context: dialogContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.of(context).pop(await _picker
                    .pickImage(source: ImageSource.gallery)
                    .then((pickedFile) => pickedFile != null ? File(pickedFile.path) : null));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Сделать фото'),
              onTap: () async {
                Navigator.of(context).pop(await _picker
                    .pickImage(source: ImageSource.camera)
                    .then((pickedFile) => pickedFile != null ? File(pickedFile.path) : null));
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

  void _searchStub() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  Future<void> _showFilterDialog() async {
    final categories = await _fetchCategoriesForDialog();
    final tempSelected = Set<int>.from(_selectedCategoryIds);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Фильтр по категориям'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                final isSelected = tempSelected.contains(cat.categoryID);
                return CheckboxListTile(
                  title: Text(cat.categoryName),
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            width: size.width * 0.95,
            height: size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: AppConstants.apiBaseUrl + product.productImage,
                    httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                    height: 400,
                    width: 400,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
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
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text("Редактировать", style: TextStyle(color: Colors.blue)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          _confirmDeleteProduct(product);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Удалить", style: TextStyle(color: Colors.red)),
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
      allCategories = await _fetchCategoriesForDialog();
      final foundIndex = allCategories.indexWhere((cat) => cat.categoryID == product.productCategory.categoryID);
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
        final size = MediaQuery.of(inDialogContext).size;
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Редактировать продукт"),
          content: StatefulBuilder(
            builder: (inDialogContext, setStateDialog) {
              return SizedBox(
                width: size.width * 0.95,
                height: size.height * 0.7,
                child: SingleChildScrollView(
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
                          child: Container(
                            height: 430,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: editedImage != null
                                ? Image.file(
                              editedImage!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            )
                                : CachedNetworkImage(
                              imageUrl: AppConstants.apiBaseUrl + product.productImage,
                              httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                              fit: BoxFit.contain,
                              width: double.infinity,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
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
                          initialValue: product.productName,
                          decoration: const InputDecoration(labelText: "Название продукта"),
                          validator: (value) => value == null || value.isEmpty ? "Введите название" : null,
                          onSaved: (value) => editedName = value!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: product.productBarcode,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner),
                              onPressed: () async {
                                final scannedCode = await _scanBarcode();
                                setStateDialog(() {
                                  editedBarcode = scannedCode ?? "";
                                });
                              },
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? "Введите штрихкод" : null,
                          onSaved: (value) => editedBarcode = value!,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(labelText: "Категория"),
                          value: editedCategory,
                          items: allCategories
                              .map((cat) => DropdownMenuItem<Category>(
                            value: cat,
                            child: Text(cat.categoryName),
                          ))
                              .toList(),
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
                ),
              );
            },
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
    String newName = '';
    Category? newCategory;
    File? newImage;
    final TextEditingController barcodeController = TextEditingController();

    List<Category> allCategories = [];
    try {
      allCategories = await _fetchCategoriesForDialog();
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
        final size = MediaQuery.of(inDialogContext).size;
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          contentPadding: const EdgeInsets.all(10),
          title: const Text("Создать продукт"),
          content: StatefulBuilder(
            builder: (inDialogContext, setStateDialog) {
              return SizedBox(
                width: size.width * 0.95,
                height: size.height * 0.7,
                child: SingleChildScrollView(
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
                          child: Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: newImage != null
                                ? Image.file(
                              newImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                                : const Center(child: Text("Изображение не выбрано")),
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
                          validator: (value) => value == null || value.isEmpty ? "Введите название" : null,
                          onSaved: (value) => newName = value!,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: "Штрихкод",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.document_scanner),
                              onPressed: () async {
                                final scannedCode = await _scanBarcode();
                                setStateDialog(() {
                                  barcodeController.text = scannedCode ?? "";
                                });
                              },
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? "Введите штрихкод" : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(labelText: "Категория"),
                          value: newCategory,
                          items: allCategories
                              .map((cat) => DropdownMenuItem<Category>(
                            value: cat,
                            child: Text(cat.categoryName),
                          ))
                              .toList(),
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
                ),
              );
            },
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

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _products.where((p) {
      final matchesCategory = _selectedCategoryIds.isEmpty
          ? true
          : _selectedCategoryIds.contains(p.productCategory.categoryID);
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
            : const Text("Продукция"),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _stopSearch,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchStub,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      drawer: const WmsDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView.builder(
          itemCount: displayedProducts.length,
          itemBuilder: (context, index) {
            final product = displayedProducts[index];
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.document_scanner, size: 16),
                          const SizedBox(width: 1),
                          Text(product.productBarcode, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 1),
                          Text(product.productCategory.categoryName, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () => _showProductDetails(product),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
