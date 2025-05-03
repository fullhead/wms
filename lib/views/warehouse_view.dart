import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/presenters/warehouse_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';

/// Главное представление склада.
class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  WarehouseViewState createState() => WarehouseViewState();
}

class WarehouseViewState extends State<WarehouseView> {
  /*──────────────────────────────────────────────────────────
   *  Поля
   *─────────────────────────────────────────────────────────*/
  late final WarehousePresenter _warehousePresenter;

  // Полный список позиций со склада
  List<Warehouse> _allWarehouses = [];

  // Отфильтрованный список
  List<Warehouse> _warehouses = [];

  bool _isLoading = false;
  String? _token;

  // Поиск
  bool _isSearching = false;
  String _searchQuery = '';

  // Фильтры
  String? _selectedCell;
  int? _minQuantity;
  int? _maxQuantity;
  DateTime? _startDate;
  DateTime? _endDate;

  int get _activeFilterCount {
    int c = 0;
    if (_selectedCell != null && _selectedCell!.isNotEmpty) c++;
    if (_minQuantity != null) c++;
    if (_maxQuantity != null) c++;
    if (_startDate != null) c++;
    if (_endDate != null) c++;
    return c;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  /*──────────────────────────────────────────────────────────
   *  Жизненный цикл
   *─────────────────────────────────────────────────────────*/
  @override
  void initState() {
    super.initState();
    _warehousePresenter = WarehousePresenter();
    _loadToken();
    _loadWarehouses();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _warehousePresenter.fetchAllWarehouse();
      _allWarehouses = data;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /*──────────────────────────────────────────────────────────
   *  Фильтрация
   *─────────────────────────────────────────────────────────*/
  void _applyFilters() {
    List<Warehouse> res = List.from(_allWarehouses);

    // Поиск (имя / штрих-код)
    if (_searchQuery.isNotEmpty) {
      res = res.where((w) {
        final name = w.warehouseProductID.productName.toLowerCase();
        final code = w.warehouseProductID.productBarcode.toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }

    // Ячейка
    if (_selectedCell != null && _selectedCell!.isNotEmpty) {
      res = res
          .where((w) => w.warehouseCellID.cellName == _selectedCell)
          .toList();
    }

    // Кол-во
    if (_minQuantity != null) {
      res = res.where((w) => w.warehouseQuantity >= _minQuantity!).toList();
    }
    if (_maxQuantity != null) {
      res = res.where((w) => w.warehouseQuantity <= _maxQuantity!).toList();
    }

    // Дата
    if (_startDate != null) {
      res = res
          .where((w) =>
              w.warehouseUpdateDate.isAtSameMomentAs(_startDate!) ||
              w.warehouseUpdateDate.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      res = res
          .where((w) =>
              w.warehouseUpdateDate.isAtSameMomentAs(_endDate!) ||
              w.warehouseUpdateDate.isBefore(_endDate!))
          .toList();
    }

    setState(() => _warehouses = res);
  }

  /*──────────────────────────────────────────────────────────
   *  Диалог фильтров
   *─────────────────────────────────────────────────────────*/
  Future<void> _openFilterDialog() async {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
    final dialogHeight = isDesktop ? size.height * 0.3 : size.height * 0.5;

    final cells =
        _allWarehouses.map((e) => e.warehouseCellID.cellName).toSet().toList();

    String? tCell = _selectedCell;
    String? tMin = _minQuantity?.toString();
    String? tMax = _maxQuantity?.toString();
    DateTime? tStart = _startDate;
    DateTime? tEnd = _endDate;

    final minCtrl = TextEditingController(text: tMin ?? '');
    final maxCtrl = TextEditingController(text: tMax ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Row(
            children: [
              Icon(
                _hasActiveFilters ? Icons.filter_alt : Icons.filter_list,
                color: _hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 4),
              Text('Фильтры ($_activeFilterCount)'),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: StatefulBuilder(
              builder: (ctx, setStateDlg) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* ЯЧЕЙКА */
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: (tCell != null)
                                  ? Theme.of(context).colorScheme.primary
                                  : null),
                          const SizedBox(width: 4),
                          Text(
                            'Ячейка:',
                            style: TextStyle(
                                color: (tCell != null)
                                    ? Theme.of(context).colorScheme.primary
                                    : null),
                          ),
                        ],
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: tCell,
                        hint: const Text('Все ячейки'),
                        items: cells
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        underline: Container(),
                        onChanged: (v) => setStateDlg(() => tCell = v),
                      ),
                      const SizedBox(height: 14),

                      /* КОЛ-ВО */
                      Row(
                        children: [
                          Icon(Icons.format_list_numbered,
                              size: 16,
                              color: ((tMin != null && tMin!.isNotEmpty) ||
                                      (tMax != null && tMax!.isNotEmpty))
                                  ? Theme.of(context).colorScheme.primary
                                  : null),
                          const SizedBox(width: 4),
                          Text('Количество:',
                              style: TextStyle(
                                  color: ((tMin != null && tMin!.isNotEmpty) ||
                                          (tMax != null && tMax!.isNotEmpty))
                                      ? Theme.of(context).colorScheme.primary
                                      : null)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: 'Мин'),
                              onChanged: (v) =>
                                  setStateDlg(() => tMin = v.trim()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: 'Макс'),
                              onChanged: (v) =>
                                  setStateDlg(() => tMax = v.trim()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      /* ДАТА */
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16,
                              color: (tStart != null || tEnd != null)
                                  ? Theme.of(context).colorScheme.primary
                                  : null),
                          const SizedBox(width: 4),
                          Text('Дата обновления:',
                              style: TextStyle(
                                  color: (tStart != null || tEnd != null)
                                      ? Theme.of(context).colorScheme.primary
                                      : null)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  locale: const Locale('ru', 'RU'),
                                  initialDate: tStart ??
                                      DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDlg(() => tStart = picked);
                                }
                              },
                              child: Text(tStart != null
                                  ? 'С ${tStart!.toLocal().toString().split(' ')[0]}'
                                  : 'Начало'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  locale: const Locale('ru', 'RU'),
                                  initialDate: tEnd ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDlg(() => tEnd = picked);
                                }
                              },
                              child: Text(tEnd != null
                                  ? 'По ${tEnd!.toLocal().toString().split(' ')[0]}'
                                  : 'Конец'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      /* ЧИП-ИНФО */
                      Wrap(
                        spacing: 6,
                        children: [
                          if (tCell != null)
                            Chip(
                              label: Text('Ячейка: $tCell'),
                              onDeleted: () => setStateDlg(() => tCell = null),
                            ),
                          if (tMin != null && tMin!.isNotEmpty)
                            Chip(
                              label: Text('Мин: $tMin'),
                              onDeleted: () {
                                setStateDlg(() {
                                  tMin = '';
                                  minCtrl.text = '';
                                });
                              },
                            ),
                          if (tMax != null && tMax!.isNotEmpty)
                            Chip(
                              label: Text('Макс: $tMax'),
                              onDeleted: () {
                                setStateDlg(() {
                                  tMax = '';
                                  maxCtrl.text = '';
                                });
                              },
                            ),
                          if (tStart != null)
                            Chip(
                              label: Text(
                                  'С: ${tStart!.toLocal().toString().split(' ')[0]}'),
                              onDeleted: () => setStateDlg(() => tStart = null),
                            ),
                          if (tEnd != null)
                            Chip(
                              label: Text(
                                  'По: ${tEnd!.toLocal().toString().split(' ')[0]}'),
                              onDeleted: () => setStateDlg(() => tEnd = null),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCell = null;
                    _minQuantity = null;
                    _maxQuantity = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  _applyFilters();
                  Navigator.pop(ctx);
                },
                child: const Text('Сбросить')),
            TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCell = tCell;
                    _minQuantity = (tMin != null && tMin!.isNotEmpty)
                        ? int.tryParse(tMin!)
                        : null;
                    _maxQuantity = (tMax != null && tMax!.isNotEmpty)
                        ? int.tryParse(tMax!)
                        : null;
                    _startDate = tStart;
                    _endDate = tEnd;
                  });
                  _applyFilters();
                  Navigator.pop(ctx);
                },
                child: const Text('Применить')),
          ],
        );
      },
    );
  }

  /*──────────────────────────────────────────────────────────
   *  Виджеты-утилиты
   *─────────────────────────────────────────────────────────*/
  Widget _buildDialogImage({
    File? fileImage,
    String? imageUrl,
    String? token,
    double width = 250,
    double height = 250,
  }) {
    final theme = Theme.of(context);

    if (fileImage != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image:
              DecorationImage(image: FileImage(fileImage), fit: BoxFit.cover),
          borderRadius: BorderRadius.circular(4),
          color: theme.dividerColor,
        ),
      );
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              AppConstants.apiBaseUrl + imageUrl,
              headers:
                  token != null ? {'Authorization': 'Bearer $token'} : null,
            ),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(4),
          color: theme.dividerColor,
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
      child: const Icon(Icons.inventory, size: 50),
    );
  }

  void _showWarehouseDetails(Warehouse w) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isDesktop = size.width > 800;
        final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
        final dialogHeight = size.height * 0.78;
        final imageSize = isDesktop ? 650.0 : 300.0;

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(10),
          titlePadding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    w.warehouseProductID.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close)),
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
                      child: _buildDialogImage(
                        imageUrl: w.warehouseProductID.productImage,
                        token: _token,
                        width: imageSize,
                        height: imageSize,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 20),

                    /* Продукт */
                    Row(
                      children: [
                        const Icon(Icons.inventory,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Продукт:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(w.warehouseProductID.productName,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    /* Категория */
                    Row(
                      children: [
                        const Icon(Icons.category,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Категория:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              w.warehouseProductID.productCategory.categoryName,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    /* Штрих-код */
                    Row(
                      children: [
                        const Icon(Icons.qr_code,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Штрихкод:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(w.warehouseProductID.productBarcode,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    /* Ячейка */
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Ячейка:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(w.warehouseCellID.cellName,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    /* Количество */
                    Row(
                      children: [
                        const Icon(Icons.format_list_numbered,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Количество:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(w.warehouseQuantity.toString(),
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    /* Дата */
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.deepOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text('Обновлено:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              w.warehouseUpdateDate
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Закрыть',
                            style: TextStyle(fontSize: 16)),
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

  Widget _buildWarehouseCard(Warehouse w) {
    final imageAvailable = w.warehouseProductID.productImage.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: imageAvailable
            ? CircleAvatar(
                radius: 30,
                backgroundImage: CachedNetworkImageProvider(
                  AppConstants.apiBaseUrl + w.warehouseProductID.productImage,
                  headers:
                      _token != null ? {'Authorization': 'Bearer $_token'} : {},
                ),
                backgroundColor: Theme.of(context).dividerColor,
              )
            : CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).dividerColor,
                child: const Icon(Icons.inventory, color: Colors.deepOrange),
              ),
        title: Text(w.warehouseProductID.productName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            /* Ячейка */
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(child: Text('Ячейка: ${w.warehouseCellID.cellName}')),
              ],
            ),

            /* Кол-во */
            Row(
              children: [
                const Icon(Icons.format_list_numbered,
                    color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(child: Text('Количество: ${w.warehouseQuantity}')),
              ],
            ),

            /* Штрих-код */
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(
                    child: Text('Код: ${w.warehouseProductID.productBarcode}')),
              ],
            ),
            const SizedBox(height: 4),

            /* Дата */
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Обновлено: ${w.warehouseUpdateDate.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showWarehouseDetails(w),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    final t = Theme.of(context).dividerColor;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(width: 48, height: 48, color: t),
        title: Container(width: double.infinity, height: 16, color: t),
        subtitle: Container(
            margin: const EdgeInsets.only(top: 8),
            width: double.infinity,
            height: 16,
            color: t),
      ),
    );
  }

  Widget _buildBody(List<Warehouse> list) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (_, i) => _buildSkeletonCard(),
      );
    }

    if (list.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ListView(children: [
          const SizedBox(height: 400),
          Center(
              child: Text('Ничего не найдено!',
                  style: Theme.of(context).textTheme.bodyMedium)),
        ]);
      }
      if (_hasActiveFilters) {
        return ListView(children: [
          const SizedBox(height: 400),
          Center(
              child: Text('По выбранным фильтрам ничего не найдено.',
                  style: Theme.of(context).textTheme.bodyMedium)),
        ]);
      }
      return ListView(children: [
        const SizedBox(height: 400),
        Center(
          child: Column(
            children: [
              Text('Нет складских данных. Начните приёмку!',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.receives),
                child: const Text('Начать приёмку'),
              ),
            ],
          ),
        ),
      ]);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildWarehouseCard(list[i]),
    );
  }

  /*──────────────────────────────────────────────────────────
   *  Build
   *─────────────────────────────────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    final list = _warehouses.where((w) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return w.warehouseProductID.productName.toLowerCase().contains(q) ||
          w.warehouseProductID.productBarcode.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Поиск по названию или штрих-коду...',
                    border: InputBorder.none),
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v.trim();
                    _applyFilters();
                  });
                },
              )
            : const Text('Склад', style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.deepOrange),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => setState(() => _isSearching = true),
                  icon: const Icon(Icons.search, color: Colors.deepOrange),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                          _hasActiveFilters
                              ? Icons.filter_alt
                              : Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: _openFilterDialog,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$_activeFilterCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ],
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (_, __) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: _loadWarehouses,
              child: _buildBody(list),
            ),
          ),
        ),
      ),
    );
  }
}
