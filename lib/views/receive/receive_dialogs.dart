import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/cell.dart';
import 'package:wms/models/product.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/receive_presenter.dart';

/// Сборник всех диалогов, связанных с приёмкой.
class ReceiveDialogs {
  /* ──────────────────────────────────────────────────────────
   *  Вспомогательные методы
   * ────────────────────────────────────────────────────────── */

  /// Сканирование штрих-кода.
  static Future<String?> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent;
    } catch (_) {
      return null;
    }
  }

  /* ──────────────────────────────────────────────────────────
   *  Диалог выбора продукции
   * ────────────────────────────────────────────────────────── */

  static Future<Product?> showProductSelectionDialog({
    required BuildContext context,
    required ProductPresenter productPresenter,
    String? token,
  }) async {
    final scrollCtrl = ScrollController();

    List<Product> products = [];
    String query = '';
    bool loading = true;

    return showDialog<Product>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            if (loading) {
              productPresenter.fetchAllProduct().then((list) {
                setState(() {
                  products = list;
                  loading = false;
                });
              }).catchError((e) {
                setState(() => loading = false);
                return <Product>[];
              });
            }

            final filtered = products.where((p) {
              return query.isEmpty ||
                  p.productName.toLowerCase().contains(query.toLowerCase()) ||
                  p.productBarcode.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: Row(
                children: [
                  const Text('Выбрать продукцию'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.deepOrange, size: 24),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      final code = await _scanBarcode();
                      if (code != null) setState(() => query = code);
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: scrollCtrl,
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      AppConstants.apiBaseUrl + p.productImage,
                                  httpHeaders: token != null
                                      ? {"Authorization": "Bearer $token"}
                                      : {},
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(p.productName),
                              subtitle: Text(p.productBarcode),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Диалог выбора ячейки
   * ────────────────────────────────────────────────────────── */

  static Future<Cell?> showCellSelectionDialog({
    required BuildContext context,
    required CellPresenter cellPresenter,
  }) async {
    final scrollCtrl = ScrollController();

    List<Cell> cells = [];
    String query = '';
    bool loading = true;

    return showDialog<Cell>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            if (loading) {
              cellPresenter.fetchAllCells().then((list) {
                setState(() {
                  cells = list;
                  loading = false;
                });
              }).catchError((e) {
                setState(() => loading = false);
                return <Cell>[];
              });
            }

            final filtered = cells
                .where((c) =>
                    c.cellName.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Выберите ячейку'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: scrollCtrl,
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final cell = filtered[i];
                            return ListTile(
                              title: Text(cell.cellName),
                              onTap: () => Navigator.pop(context, cell),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Детали приёмки
   * ────────────────────────────────────────────────────────── */

  static Widget _detailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  /// Диалог информации о приёмке.
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
        final imageSize = isDesktop ? 600.0 : 250.0;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(receive.product.productName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: dialogHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                    _detailRow(theme, Icons.qr_code, 'Штрихкод:',
                        receive.product.productBarcode),
                    const Divider(height: 20),
                    _detailRow(theme, Icons.category, 'Категория:',
                        receive.product.productCategory.categoryName),
                    const Divider(height: 20),
                    _detailRow(theme, Icons.location_on, 'Ячейка:',
                        receive.cell.cellName),
                    const Divider(height: 20),
                    _detailRow(theme, Icons.confirmation_number, 'Количество:',
                        receive.receiveQuantity.toString()),
                    const Divider(height: 20),
                    _detailRow(theme, Icons.calendar_today, 'Дата:',
                        formatDateTime(receive.receiveDate)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: Icon(Icons.edit,
                              color: theme.colorScheme.secondary),
                          label: Text('Редактировать',
                              style: TextStyle(
                                  color: theme.colorScheme.secondary)),
                        ),
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete,
                              color: theme.colorScheme.error),
                          label: Text('Удалить',
                              style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      ],
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

  /* ──────────────────────────────────────────────────────────
   *  Диалог редактирования
   * ────────────────────────────────────────────────────────── */

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

    // Локальные переменные для редактирования
    DateTime selectedDate = receive.receiveDate;
    Product selectedProduct = receive.product;
    Cell selectedCell = receive.cell;
    String qtyStr = receive.receiveQuantity.toString();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text('Редактировать запись приёмки',
                  style: Theme.of(ctx).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(ctx).size.width *
                    (MediaQuery.of(ctx).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /* 1. Продукция */
                        FormField<Product>(
                          initialValue: selectedProduct,
                          validator: (v) =>
                              v == null ? 'Выберите продукцию' : null,
                          builder: (state) => _productSelectTile(
                            ctx,
                            product: selectedProduct,
                            token: token,
                            onPressed: () async {
                              final p = await showProductSelectionDialog(
                                context: ctx,
                                productPresenter: productPresenter,
                                token: token,
                              );
                              if (p != null) {
                                setState(() {
                                  selectedProduct = p;
                                  state.didChange(p);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        /* 2. Ячейка */
                        FormField<Cell>(
                          initialValue: selectedCell,
                          validator: (v) =>
                              v == null ? 'Выберите ячейку' : null,
                          builder: (state) => _cellSelectTile(
                            ctx,
                            cell: selectedCell,
                            onPressed: () async {
                              final c = await showCellSelectionDialog(
                                context: ctx,
                                cellPresenter: cellPresenter,
                              );
                              if (c != null) {
                                setState(() {
                                  selectedCell = c;
                                  state.didChange(c);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        /* 3. Количество */
                        TextFormField(
                          initialValue: qtyStr,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Количество'),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Введите количество';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) {
                              return 'Количество должно быть положительным';
                            }
                            return null;
                          },
                          onSaved: (v) => qtyStr = v!,
                        ),
                        const SizedBox(height: 16),

                        /* 4. Дата + время */
                        _dateTimePickers(ctx, selectedDate, (d) {
                          setState(() => selectedDate = d);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена')),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState!.save();
                      try {
                        receive.product = selectedProduct;
                        receive.cell = selectedCell;
                        receive.receiveQuantity = int.parse(qtyStr);
                        receive.receiveDate = selectedDate;

                        final msg =
                            await ReceivePresenter().updateReceive(receive);
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        await refreshReceives();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 2)),
                        );
                      } catch (e) {
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(e.toString()),
                              duration: const Duration(seconds: 2)),
                        );
                      }
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Диалог создания
   * ────────────────────────────────────────────────────────── */

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
    String qtyStr = '';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(10),
              title: Text('Создать запись приёмки',
                  style: Theme.of(ctx).textTheme.titleMedium),
              content: SizedBox(
                width: MediaQuery.of(ctx).size.width *
                    (MediaQuery.of(ctx).size.width > 800 ? 0.5 : 0.95),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /* 1. Продукция */
                        FormField<Product>(
                          validator: (v) =>
                              v == null ? 'Выберите продукцию' : null,
                          builder: (state) => _productSelectTile(
                            ctx,
                            product: selectedProduct,
                            token: token,
                            placeholder: 'Выберите продукцию',
                            onPressed: () async {
                              final p = await showProductSelectionDialog(
                                context: ctx,
                                productPresenter: productPresenter,
                                token: token,
                              );
                              if (p != null) {
                                setState(() {
                                  selectedProduct = p;
                                  state.didChange(p);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        /* 2. Ячейка */
                        FormField<Cell>(
                          validator: (v) =>
                              v == null ? 'Выберите ячейку' : null,
                          builder: (state) => _cellSelectTile(
                            ctx,
                            cell: selectedCell,
                            placeholder: 'Выберите ячейку',
                            onPressed: () async {
                              final c = await showCellSelectionDialog(
                                context: ctx,
                                cellPresenter: cellPresenter,
                              );
                              if (c != null) {
                                setState(() {
                                  selectedCell = c;
                                  state.didChange(c);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        /* 3. Количество */
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Количество'),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Введите количество';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) {
                              return 'Количество должно быть положительным';
                            }
                            return null;
                          },
                          onSaved: (v) => qtyStr = v!,
                        ),
                        const SizedBox(height: 16),

                        /* 4. Дата + время */
                        _dateTimePickers(ctx, selectedDate, (d) {
                          setState(() => selectedDate = d);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена')),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState!.save();
                      try {
                        final msg = await presenter.createReceive(
                          product: selectedProduct!,
                          cell: selectedCell!,
                          receiveQuantity: int.parse(qtyStr),
                          receiveDate: selectedDate,
                        );
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        await refreshReceives();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 2)),
                        );
                      } catch (e) {
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(e.toString()),
                              duration: const Duration(seconds: 2)),
                        );
                      }
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Подтверждение удаления
   * ────────────────────────────────────────────────────────── */

  static Future<void> confirmDeleteReceive({
    required BuildContext context,
    required Receive receive,
    required ReceivePresenter presenter,
    required Future<void> Function() refreshReceives,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (alertCtx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(
            'Удалить запись приёмки для "${receive.product.productName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(alertCtx, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(alertCtx, true),
              child: const Text('Удалить')),
        ],
      ),
    );

    if (ok == true) {
      try {
        final msg = await presenter.deleteReceive(receive);
        await refreshReceives();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  /* ──────────────────────────────────────────────────────────
   *  Приватные виджеты-утилиты
   * ────────────────────────────────────────────────────────── */

  static Widget _productSelectTile(
    BuildContext ctx, {
    required Product? product,
    required String? token,
    String placeholder = '',
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Продукция', style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (product != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.apiBaseUrl + product.productImage,
                      httpHeaders: token != null
                          ? {"Authorization": "Bearer $token"}
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
                  child: Text(product?.productName ?? placeholder,
                      style: const TextStyle(fontSize: 16)),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _cellSelectTile(
    BuildContext ctx, {
    required Cell? cell,
    String placeholder = '',
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ячейка', style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(cell?.cellName ?? placeholder,
                      style: const TextStyle(fontSize: 16)),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _dateTimePickers(
    BuildContext ctx,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('Дата: ${formatDate(date)}')),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  onChanged(DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    date.hour,
                    date.minute,
                    date.second,
                  ));
                }
              },
              child: const Text('Выбрать дату'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Время: ${formatTime(date)}')),
            TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(date),
                );
                if (picked != null) {
                  onChanged(DateTime(
                    date.year,
                    date.month,
                    date.day,
                    picked.hour,
                    picked.minute,
                    date.second,
                  ));
                }
              },
              child: const Text('Выбрать время'),
            ),
          ],
        ),
      ],
    );
  }
}
