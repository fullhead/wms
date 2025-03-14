import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/issue.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/issue_presenter.dart';
import 'package:wms/presenters/warehouse_presenter.dart';
import 'package:wms/core/utils.dart';

class IssueDialogs {
  /// Вспомогательная функция сканирования штрихкода.
  static Future<String?> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (e) {
      return null;
    }
  }

  /// Диалог выбора продукции из записей склада.
  /// Возвращает Map с ключами: 'product', 'cell' и 'availableQuantity'.
  static Future<Map<String, dynamic>?> showWarehouseProductSelectionDialog({
    required BuildContext context,
    required WarehousePresenter warehousePresenter,
    String? token,
  }) async {
    List<Map<String, dynamic>> selection = [];
    try {
      final warehouses = await warehousePresenter.fetchAllWarehouse();
      final availableWarehouses = warehouses.where((w) => w.warehouseQuantity > 0).toList();
      selection = availableWarehouses.map((w) {
        return {
          'product': w.warehouseProductID,
          'cell': w.warehouseCellID,
          'availableQuantity': w.warehouseQuantity,
        };
      }).toList();
    } catch (e) {
      // Ошибка получения данных склада
    }

    String searchQuery = '';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<Map<String, dynamic>> filtered = selection.where((item) {
              final Product product = item['product'];
              return product.productName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  product.productBarcode.toLowerCase().contains(searchQuery.toLowerCase());
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
                child: filtered.isEmpty
                    ? const Center(child: Text("Нет доступных товаров на складе"))
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      final Product product = item['product'];
                      final int availableQuantity = item['availableQuantity'];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: AppConstants.apiBaseUrl + product.productImage,
                            httpHeaders: token != null ? {"Authorization": "Bearer $token"} : {},
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(product.productName),
                        subtitle: Text("Доступно: $availableQuantity шт."),
                        onTap: () {
                          Navigator.pop(context, item);
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
              return c.cellName.toLowerCase().contains(searchQuery.toLowerCase());
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
                  child: ListView.builder(
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
  static Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 16),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  /// Диалог отображения деталей записи выдачи с кнопками редактирования и удаления.
  static void showIssueDetails({
    required BuildContext context,
    required Issue issue,
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
        final dialogHeight = size.height * 0.75;
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
                    issue.product.productName,
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
                              imageUrl: AppConstants.apiBaseUrl + issue.product.productImage,
                              httpHeaders: token != null ? {"Authorization": "Bearer $token"} : {},
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.qr_code, "Штрихкод:", issue.product.productBarcode),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.location_on, "Ячейка:", issue.cell.cellName),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.confirmation_number, "Количество:", issue.issueQuantity.toString()),
                        const Divider(height: 20),
                        _buildDetailRow(theme, Icons.calendar_today, "Дата:", formatDateTime(issue.issueDate)),
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
                            icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                            label: Text(
                              "Редактировать",
                              style: TextStyle(color: theme.colorScheme.secondary),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onDelete,
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

  /// Диалог редактирования записи выдачи.
  static Future<void> showEditIssueDialog({
    required BuildContext context,
    required Issue issue,
    required ProductPresenter productPresenter,
    required CellPresenter cellPresenter,
    required WarehousePresenter warehousePresenter,
    required String? token,
    required Future<void> Function() refreshIssues,
  }) async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = issue.issueDate;
    Product selectedProduct = issue.product;
    Cell selectedCell = issue.cell;
    int availableStock = 0;
    try {
      final warehouseRecord = await warehousePresenter.fetchWarehouseById(selectedCell.cellID);
      availableStock = warehouseRecord.warehouseQuantity;
    } catch (e) {
      availableStock = issue.issueQuantity;
    }
    double quantitySliderValue = issue.issueQuantity.toDouble();
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text("Редактировать запись выдачи", style: Theme.of(dialogContext).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Выбор продукции из записей склада
                        FormField<Map<String, dynamic>>(
                          initialValue: {
                            'product': selectedProduct,
                            'cell': selectedCell,
                            'availableQuantity': availableStock
                          },
                          validator: (value) {
                            if (value == null || value['product'] == null) {
                              return "Выберите продукцию";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Продукция", style: Theme.of(dialogContext).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final result = await showWarehouseProductSelectionDialog(
                                      context: dialogContext,
                                      warehousePresenter: warehousePresenter,
                                      token: token,
                                    );
                                    if (result != null) {
                                      setStateDialog(() {
                                        selectedProduct = result['product'];
                                        selectedCell = result['cell'];
                                        availableStock = result['availableQuantity'];
                                        quantitySliderValue = 1;
                                        state.didChange(result);
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
                                            httpHeaders: token != null ? {"Authorization": "Bearer $token"} : {},
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            selectedProduct.productName,
                                            style: const TextStyle(fontSize: 16),
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
                        // Автоматическая подстановка ячейки (информационное поле)
                        Text("Ячейка: ${selectedCell.cellName}", style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        // Выбор количества через ползунок
                        if (availableStock > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Количество (Доступно: $availableStock шт.)", style: Theme.of(dialogContext).textTheme.titleMedium),
                              Slider(
                                value: quantitySliderValue.clamp(1, availableStock).toDouble(),
                                min: 1,
                                max: availableStock.toDouble(),
                                divisions: availableStock > 1 ? availableStock - 1 : null,
                                label: quantitySliderValue.toInt().toString(),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    quantitySliderValue = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text("Выбранное количество: ${quantitySliderValue.toInt()}"),
                            ],
                          )
                        else
                          const Text("Нет доступного количества для выбранной продукции"),
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
                      try {
                        final newQuantity = quantitySliderValue.toInt();
                        issue.product = selectedProduct;
                        issue.cell = selectedCell;
                        issue.issueQuantity = newQuantity;
                        issue.issueDate = selectedDate;
                        final responseMessage = await IssuePresenter().updateIssue(issue);
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        await refreshIssues();
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

  /// Диалог создания новой записи выдачи.
  static Future<void> showCreateIssueDialog({
    required BuildContext context,
    required IssuePresenter presenter,
    required ProductPresenter productPresenter,
    required CellPresenter cellPresenter,
    required WarehousePresenter warehousePresenter,
    required String? token,
    required Future<void> Function() refreshIssues,
  }) async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    Cell? selectedCell;
    int availableStock = 0;
    double quantitySliderValue = 1;
    DateTime selectedDate = DateTime.now();

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text("Создать запись выдачи", style: Theme.of(dialogContext).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width *
                    (MediaQuery.of(dialogContext).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Выбор продукции из записей склада
                        FormField<Map<String, dynamic>>(
                          validator: (value) {
                            if (value == null || value['product'] == null) {
                              return "Выберите продукцию";
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Продукция", style: Theme.of(dialogContext).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final result = await showWarehouseProductSelectionDialog(
                                      context: dialogContext,
                                      warehousePresenter: warehousePresenter,
                                      token: token,
                                    );
                                    if (result != null) {
                                      setStateDialog(() {
                                        selectedProduct = result['product'];
                                        selectedCell = result['cell'];
                                        availableStock = result['availableQuantity'];
                                        quantitySliderValue = 1;
                                        state.didChange(result);
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
                                              httpHeaders: token != null ? {"Authorization": "Bearer $token"} : {},
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
                        // Автоматическая подстановка ячейки (информационное поле)
                        Text("Ячейка: ${selectedCell != null ? selectedCell!.cellName : 'Не выбрана'}",
                            style: Theme.of(dialogContext).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        // Выбор количества через ползунок
                        if (availableStock > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Количество (Доступно: $availableStock шт.)", style: Theme.of(dialogContext).textTheme.titleMedium),
                              Slider(
                                value: quantitySliderValue.clamp(1, availableStock).toDouble(),
                                min: 1,
                                max: availableStock.toDouble(),
                                divisions: availableStock > 1 ? availableStock - 1 : null,
                                label: quantitySliderValue.toInt().toString(),
                                onChanged: (value) {
                                  setStateDialog(() {
                                    quantitySliderValue = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text("Выбранное количество: ${quantitySliderValue.toInt()}"),
                            ],
                          )
                        else
                          const Text("Нет доступного количества для выбранной продукции"),
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
                      try {
                        final newQuantity = quantitySliderValue.toInt();
                        await presenter.createIssue(
                          product: selectedProduct!,
                          cell: selectedCell!,
                          issueQuantity: newQuantity,
                          issueDate: selectedDate,
                        );
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        await refreshIssues();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Запись выдачи создана"),
                            duration: Duration(seconds: 2),
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

  /// Подтверждение удаления записи выдачи.
  static Future<void> confirmDeleteIssue({
    required BuildContext context,
    required Issue issue,
    required IssuePresenter presenter,
    required Future<void> Function() refreshIssues,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить запись выдачи для "${issue.product.productName}"?'),
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
        final responseMessage = await presenter.deleteIssue(issue);
        await refreshIssues();
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
