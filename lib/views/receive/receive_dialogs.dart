import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/receive_presenter.dart';
import 'package:wms/core/utils.dart';

class ReceiveDialogs {
  /// Вспомогательная функция сканирования штрихкода.
  static Future<String?> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (e) {
      return null;
    }
  }

  /// Диалог выбора продукции.
  static Future<Product?> showProductSelectionDialog({
    required BuildContext context,
    required ProductPresenter productPresenter,
    String? token,
  }) async {
    final ScrollController productScrollController = ScrollController();

    List<Product> products = [];
    String searchQuery = '';
    bool isLoading = true;
    return showDialog<Product>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoading) {
              productPresenter.fetchAllProduct().then((data) {
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
              return p.productName
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  p.productBarcode
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
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
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.deepOrange, size: 24),
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
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: productScrollController,
                        child: ListView.builder(
                          controller: productScrollController,
                          itemCount: displayedProducts.length,
                          itemBuilder: (ctx, index) {
                            final product = displayedProducts[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: AppConstants.apiBaseUrl +
                                      product.productImage,
                                  httpHeaders: token != null
                                      ? {"Authorization": "Bearer $token"}
                                      : {},
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
  }

  /// Диалог выбора ячейки.
  static Future<Cell?> showCellSelectionDialog({
    required BuildContext context,
    required CellPresenter cellPresenter,
  }) async {
    final ScrollController cellScrollController = ScrollController();

    List<Cell> cells = [];
    String searchQuery = '';
    bool isLoading = true;

    return showDialog<Cell>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoading) {
              cellPresenter.fetchAllCells().then((data) {
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
              return c.cellName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text("Выберите ячейку"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: cellScrollController,
                        child: ListView.builder(
                          controller: cellScrollController,
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
  }

  /// Виджет для построения строки деталей записи.
  static Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Диалог отображения деталей записи приёмки с кнопками редактирования и удаления.
  static void showReceiveDetails({
    required BuildContext context,
    required Receive receive,
    required String? token,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
        final dialogHeight = size.height * 0.65;
        final imageSize = isDesktop ? 650.0 : 350.0;

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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                              imageUrl: AppConstants.apiBaseUrl +
                                  receive.product.productImage,
                              httpHeaders: token != null
                                  ? {"Authorization": "Bearer $token"}
                                  : {},
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.qr_code, "Штрихкод:",
                            receive.product.productBarcode),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.location_on, "Ячейка:",
                            receive.cell.cellName),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.confirmation_number,
                            "Количество:", receive.receiveQuantity.toString()),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.calendar_today, "Дата:",
                            formatDateTime(receive.receiveDate)),
                        const Divider(height: 20),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit,
                                color: theme.colorScheme.secondary),
                            label: Text(
                              "Редактировать",
                              style:
                                  TextStyle(color: theme.colorScheme.secondary),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: Icon(Icons.delete,
                                color: theme.colorScheme.error),
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

  /// Диалог редактирования записи приёмки.
  static Future<void> showEditReceiveDialog({
    required BuildContext context,
    required Receive receive,
    required ProductPresenter productPresenter,
    required CellPresenter cellPresenter,
    required String? token,
    required Future<void> Function() refreshReceives,
  }) async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = receive.receiveDate;
    Product selectedProduct = receive.product;
    Cell selectedCell = receive.cell;
    String quantityStr = receive.receiveQuantity.toString();

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text(
                "Редактировать запись приёмки",
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800
                        ? 0.5
                        : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Поле выбора продукции
                        FormField<Product>(
                          initialValue: selectedProduct,
                          validator: (value) {
                            if (value == null) {
                              return "Выберите продукцию";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Продукция",
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final product =
                                        await showProductSelectionDialog(
                                      context: dialogContext,
                                      productPresenter: productPresenter,
                                      token: token,
                                    );
                                    if (product != null) {
                                      setStateDialog(() {
                                        selectedProduct = product;
                                        state.didChange(product);
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
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: AppConstants.apiBaseUrl +
                                                selectedProduct.productImage,
                                            httpHeaders: token != null
                                                ? {
                                                    "Authorization":
                                                        "Bearer $token"
                                                  }
                                                : {},
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                selectedProduct.productName)),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      state.errorText!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Поле выбора ячейки
                        FormField<Cell>(
                          initialValue: selectedCell,
                          validator: (value) {
                            if (value == null) {
                              return "Выберите ячейку";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ячейка",
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final cell = await showCellSelectionDialog(
                                      context: dialogContext,
                                      cellPresenter: cellPresenter,
                                    );
                                    if (cell != null) {
                                      setStateDialog(() {
                                        selectedCell = cell;
                                        state.didChange(cell);
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
                                            child: Text(selectedCell.cellName)),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      state.errorText!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Поле для ввода количества
                        TextFormField(
                          initialValue: quantityStr,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: "Количество"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите количество";
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return "Количество должно быть положительным числом";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            quantityStr = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Выбор даты
                        Row(
                          children: [
                            Expanded(
                                child:
                                    Text("Дата: ${formatDate(selectedDate)}")),
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
                            Expanded(
                                child:
                                    Text("Время: ${formatTime(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: dialogContext,
                                  initialTime:
                                      TimeOfDay.fromDateTime(selectedDate),
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
                        receive.receiveDate = selectedDate;

                        final responseMessage =
                            await ReceivePresenter().updateReceive(receive);
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        await refreshReceives();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(responseMessage),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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

  /// Диалог создания новой записи приёмки.
  static Future<void> showCreateReceiveDialog({
    required BuildContext context,
    required ReceivePresenter presenter,
    required ProductPresenter productPresenter,
    required CellPresenter cellPresenter,
    required String? token,
    required Future<void> Function() refreshReceives,
  }) async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    Cell? selectedCell;
    String quantityStr = '';
    DateTime selectedDate = DateTime.now();

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text(
                "Создать запись приёмки",
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800
                        ? 0.5
                        : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Поле выбора продукции
                        FormField<Product>(
                          validator: (value) {
                            if (value == null) {
                              return "Выберите продукцию";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Продукция",
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final product =
                                        await showProductSelectionDialog(
                                      context: dialogContext,
                                      productPresenter: productPresenter,
                                      token: token,
                                    );
                                    if (product != null) {
                                      setStateDialog(() {
                                        selectedProduct = product;
                                        state.didChange(product);
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: CachedNetworkImage(
                                              imageUrl: AppConstants
                                                      .apiBaseUrl +
                                                  selectedProduct!.productImage,
                                              httpHeaders: token != null
                                                  ? {
                                                      "Authorization":
                                                          "Bearer $token"
                                                    }
                                                  : {},
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
                                            selectedProduct?.productName ??
                                                "Выберите продукцию",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      state.errorText!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Поле выбора ячейки
                        FormField<Cell>(
                          validator: (value) {
                            if (value == null) {
                              return "Выберите ячейку";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ячейка",
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final cell = await showCellSelectionDialog(
                                      context: dialogContext,
                                      cellPresenter: cellPresenter,
                                    );
                                    if (cell != null) {
                                      setStateDialog(() {
                                        selectedCell = cell;
                                        state.didChange(cell);
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
                                            selectedCell?.cellName ??
                                                "Выберите ячейку",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      state.errorText!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Поле ввода количества
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: "Количество"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите количество";
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
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
                            Expanded(
                                child:
                                    Text("Дата: ${formatDate(selectedDate)}")),
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
                            Expanded(
                                child:
                                    Text("Время: ${formatTime(selectedDate)}")),
                            TextButton(
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: dialogContext,
                                  initialTime:
                                      TimeOfDay.fromDateTime(selectedDate),
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
                        final newQuantity = int.parse(quantityStr);
                        final responseMessage = await presenter.createReceive(
                          product: selectedProduct!,
                          cell: selectedCell!,
                          receiveQuantity: newQuantity,
                          receiveDate: selectedDate,
                        );
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        await refreshReceives();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(responseMessage),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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

  /// Подтверждение удаления записи приёмки.
  static Future<void> confirmDeleteReceive({
    required BuildContext context,
    required Receive receive,
    required ReceivePresenter presenter,
    required Future<void> Function() refreshReceives,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(
            'Удалить запись приёмки для "${receive.product.productName}"?'),
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
        final responseMessage = await presenter.deleteReceive(receive);
        await refreshReceives();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
