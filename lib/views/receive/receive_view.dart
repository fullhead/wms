import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/presenters/receive/receive_presenter.dart';
import 'package:wms/presenters/product/product_presenter.dart';
import 'package:wms/presenters/cell/cell_presenter.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

// Функция для форматирования даты и времени в виде "YYYY-MM-DD HH:mm"
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return "${local.year.toString().padLeft(4, '0')}-"
      "${local.month.toString().padLeft(2, '0')}-"
      "${local.day.toString().padLeft(2, '0')} "
      "${local.hour.toString().padLeft(2, '0')}:"
      "${local.minute.toString().padLeft(2, '0')}";
}

// Функция для форматирования только даты "YYYY-MM-DD"
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return "${local.year.toString().padLeft(4, '0')}-"
      "${local.month.toString().padLeft(2, '0')}-"
      "${local.day.toString().padLeft(2, '0')}";
}

// Функция для форматирования только времени "HH:mm"
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return "${local.hour.toString().padLeft(2, '0')}:"
      "${local.minute.toString().padLeft(2, '0')}";
}

class ReceiveView extends StatefulWidget {
  const ReceiveView({super.key});

  @override
  ReceiveViewState createState() => ReceiveViewState();
}

class ReceiveViewState extends State<ReceiveView> {
  // -------------------------------------------------------
  // Поля класса
  // -------------------------------------------------------
  final ReceivePresenter _presenter = ReceivePresenter();
  final ProductPresenter _productPresenter = ProductPresenter();
  final CellPresenter _cellPresenter = CellPresenter();

  List<Receive> _receives = [];
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
    _loadReceives();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadReceives() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final receives = await _presenter.fetchAllReceives();
      if (!mounted) return;
      setState(() {
        _receives = receives;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // -------------------------------------------------------
  // Функция сканирования штрихкода
  // -------------------------------------------------------
  Future<String?> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------
  // Диалог выбора продукции
  // -------------------------------------------------------
  Future<Product?> _showProductSelectionDialog() async {
    List<Product> products = [];
    String searchQuery = '';
    bool isLoading = true;
    final selectedProduct = await showDialog<Product>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoading) {
              _productPresenter.fetchAllProduct().then((data) {
                setStateDialog(() {
                  products = data;
                  isLoading = false;
                });
              }).catchError((e) {
                setStateDialog(() {
                  isLoading = false;
                });
              });
            }
            List<Product> displayedProducts = products.where((p) {
              return p.productName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  p.productBarcode.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
            return AlertDialog(
              title: Row(
                children: [
                  const Text("Выбрать продукцию"),
                  const Spacer(),
                  IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.deepOrange, size: 24),
                    onPressed: () async {
                      final scanned = await _scanBarcode();
                      if (scanned != null) {
                        setStateDialog(() {
                          searchQuery = scanned;
                        });
                      }
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: displayedProducts.length,
                  itemBuilder: (ctx, index) {
                    final product = displayedProducts[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: AppConstants.apiBaseUrl + product.productImage,
                          httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(product.productName),
                      subtitle: Text(product.productBarcode),
                      onTap: () {
                        Navigator.pop(context, product);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Отмена"),
                ),
              ],
            );
          },
        );
      },
    );
    return selectedProduct;
  }

  // -------------------------------------------------------
  // Диалог выбора ячейки
  // -------------------------------------------------------
  Future<Cell?> _showCellSelectionDialog() async {
    List<Cell> cells = [];
    String searchQuery = '';
    bool isLoading = true;
    final selectedCell = await showDialog<Cell>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoading) {
              _cellPresenter.fetchAllCells().then((data) {
                setStateDialog(() {
                  cells = data;
                  isLoading = false;
                });
              }).catchError((e) {
                setStateDialog(() {
                  isLoading = false;
                });
              });
            }
            List<Cell> displayedCells = cells.where((c) {
              return c.cellName.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
            return AlertDialog(
              title: const Text("Выберите ячейку"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: displayedCells.length,
                  itemBuilder: (ctx, index) {
                    final cell = displayedCells[index];
                    return ListTile(
                      title: Text(cell.cellName),
                      onTap: () {
                        Navigator.pop(context, cell);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Отмена"),
                ),
              ],
            );
          },
        );
      },
    );
    return selectedCell;
  }

  // -------------------------------------------------------
  // Отображение деталей записи приёмки
  // -------------------------------------------------------
  void _showReceiveDetails(Receive receive) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
        final dialogHeight = size.height * 0.76;
        final imageSize = isDesktop ? 650.0 : 300.0;
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
                    receive.product.productName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: dialogHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: AppConstants.apiBaseUrl + receive.product.productImage,
                              httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Штрихкод:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                receive.product.productBarcode,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Ячейка:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                receive.cell.cellName,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Количество:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                receive.receiveQuantity.toString(),
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Дата:",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatDateTime(receive.receiveDate),
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showEditReceiveDialog(receive);
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
                              _confirmDeleteReceive(receive);
                            },
                            icon: Icon(Icons.delete, color: theme.colorScheme.error),
                            label: Text(
                              "Удалить",
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // Диалог редактирования записи приёмки
  // -------------------------------------------------------
  Future<void> _showEditReceiveDialog(Receive receive) async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();

    // Для редактирования используем локальное время
    Product selectedProduct = receive.product;
    Cell selectedCell = receive.cell;
    String quantityStr = receive.receiveQuantity.toString();
    DateTime selectedDate = receive.receiveDate.toLocal();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text("Редактировать запись приёмки", style: Theme.of(dialogContext).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Выбор продукции
                        Text("Продукция", style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final product = await _showProductSelectionDialog();
                            if (product != null) {
                              setStateDialog(() {
                                selectedProduct = product;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: AppConstants.apiBaseUrl + selectedProduct.productImage,
                                    httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(selectedProduct.productName)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Выбор ячейки
                        Text("Ячейка", style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final cell = await _showCellSelectionDialog();
                            if (cell != null) {
                              setStateDialog(() {
                                selectedCell = cell;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(selectedCell.cellName)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Поле ввода количества
                        TextFormField(
                          initialValue: quantityStr,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Количество"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите количество";
                            }
                            if (int.tryParse(value) == null || int.parse(value) <= 0) {
                              return "Количество должно быть положительным числом";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            quantityStr = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Редактирование даты
                        Row(
                          children: [
                            Expanded(child: Text("Дата: ${formatDate(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setStateDialog(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      selectedDate.hour,
                                      selectedDate.minute,
                                      selectedDate.second,
                                    );
                                  });
                                }
                              },
                              child: const Text("Выбрать дату"),
                            ),
                          ],
                        ),
                        // Редактирование времени
                        Row(
                          children: [
                            Expanded(child: Text("Время: ${formatTime(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                                );
                                if (pickedTime != null) {
                                  setStateDialog(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                      selectedDate.second,
                                    );
                                  });
                                }
                              },
                              child: const Text("Выбрать время"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Отмена"),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      try {
                        final updatedQuantity = int.parse(quantityStr);
                        receive.product = selectedProduct;
                        receive.cell = selectedCell;
                        receive.receiveQuantity = updatedQuantity;
                        // Используем выбранную локальную дату и время
                        receive.receiveDate = selectedDate;
                        final responseMessage = await _presenter.updateReceive(receive);
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        await _loadReceives();
                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(responseMessage),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
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
      },
    );
  }

  // -------------------------------------------------------
  // Диалог создания новой записи приёмки
  // -------------------------------------------------------
  Future<void> _showCreateReceiveDialog() async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();

    Product? selectedProduct;
    Cell? selectedCell;
    String quantityStr = '';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text("Создать запись приёмки", style: Theme.of(dialogContext).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Выбор продукции
                        Text("Продукция", style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final product = await _showProductSelectionDialog();
                            if (product != null) {
                              setStateDialog(() {
                                selectedProduct = product;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                if (selectedProduct != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                      imageUrl: AppConstants.apiBaseUrl + selectedProduct!.productImage,
                                      httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedProduct?.productName ?? "Выберите продукцию",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Выбор ячейки
                        Text("Ячейка", style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final cell = await _showCellSelectionDialog();
                            if (cell != null) {
                              setStateDialog(() {
                                selectedCell = cell;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCell?.cellName ?? "Выберите ячейку",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Поле ввода количества
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Количество"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите количество";
                            }
                            if (int.tryParse(value) == null || int.parse(value) <= 0) {
                              return "Количество должно быть положительным числом";
                            }
                            return null;
                          },
                          onSaved: (value) => quantityStr = value!,
                        ),
                        const SizedBox(height: 16),
                        // Выбор даты
                        Row(
                          children: [
                            Expanded(child: Text("Дата: ${formatDate(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setStateDialog(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      selectedDate.hour,
                                      selectedDate.minute,
                                      selectedDate.second,
                                    );
                                  });
                                }
                              },
                              child: const Text("Выбрать дату"),
                            ),
                          ],
                        ),
                        // Выбор времени
                        Row(
                          children: [
                            Expanded(child: Text("Время: ${formatTime(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                                );
                                if (pickedTime != null) {
                                  setStateDialog(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                      selectedDate.second,
                                    );
                                  });
                                }
                              },
                              child: const Text("Выбрать время"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Отмена"),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      if (selectedProduct == null || selectedCell == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text("Необходимо выбрать продукцию и ячейку")),
                        );
                        return;
                      }
                      formKey.currentState?.save();
                      try {
                        final newQuantity = int.parse(quantityStr);
                        final responseMessage = await _presenter.createReceive(
                          product: selectedProduct!,
                          cell: selectedCell!,
                          receiveQuantity: newQuantity,
                          receiveDate: selectedDate,
                        );
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        await _loadReceives();
                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(responseMessage),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
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
      },
    );
  }

  // -------------------------------------------------------
  // Подтверждение удаления записи приёмки
  // -------------------------------------------------------
  Future<void> _confirmDeleteReceive(Receive receive) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить запись приёмки для "${receive.product.productName}"?'),
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
        final responseMessage = await _presenter.deleteReceive(receive);
        await _loadReceives();
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
  // Построение карточки записи приёмки
  // -------------------------------------------------------
  Widget _buildReceiveCard(Receive receive) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: AppConstants.apiBaseUrl + receive.product.productImage,
            httpHeaders: _token != null ? {"Authorization": "Bearer $_token"} : {},
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          receive.product.productName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Штрихкод:",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    receive.product.productBarcode,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Ячейка:",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    receive.cell.cellName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Количество:",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    receive.receiveQuantity.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Дата:",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    formatDateTime(receive.receiveDate),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showReceiveDetails(receive),
      ),
    );
  }

  // -------------------------------------------------------
  // Построение Skeleton-карточки для записей приёмки
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
    final displayedReceives = _receives.where((r) {
      return _searchQuery.isEmpty ||
          r.product.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.product.productBarcode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (displayedReceives.isEmpty) {
      if (_searchQuery.isNotEmpty) {
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
      } else {
        return Center(
          child: RefreshIndicator(
            onRefresh: _loadReceives,
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
                        'Нет записей приёмки. Добавьте новую запись.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateReceiveDialog,
                        child: const Text('Добавить запись'),
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
      onRefresh: _loadReceives,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayedReceives.length,
        itemBuilder: (context, index) {
          final receive = displayedReceives[index];
          return _buildReceiveCard(receive);
        },
      ),
    );
  }

  // -------------------------------------------------------
  // Методы поиска и фильтрации в AppBar
  // -------------------------------------------------------
  void _startSearch() {
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

  // -------------------------------------------------------
  // Основной build метода
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Поиск по приёмке...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text("Приемка", style: TextStyle(color: Colors.deepOrange)),
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
            onPressed: _startSearch,
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
        onPressed: _showCreateReceiveDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
