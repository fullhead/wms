import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/presenters/warehouse/warehouse_presenter.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/widgets/wms_drawer.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  WarehouseViewState createState() => WarehouseViewState();
}

class WarehouseViewState extends State<WarehouseView> {
  // -------------------------------------------------------
  // Поля
  // -------------------------------------------------------
  late final WarehousePresenter _warehousePresenter;
  List<Warehouse> _allWarehouses = [];
  List<Warehouse> _warehouses = [];

  bool _isLoading = false;
  String? _token;

  // Поля поиска
  bool _isSearching = false;
  String _searchQuery = '';

  // Поля фильтра
  String? _selectedCell;
  int? _minQuantity;
  int? _maxQuantity;
  DateTime? _startDate;
  DateTime? _endDate;

  // -------------------------------------------------------
  // Геттеры
  // -------------------------------------------------------
  int get _activeFilterCount {
    int count = 0;
    if (_selectedCell != null && _selectedCell!.isNotEmpty) count++;
    if (_minQuantity != null) count++;
    if (_maxQuantity != null) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  // -------------------------------------------------------
  // Методы жизненного цикла
  // -------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _warehousePresenter = WarehousePresenter();
    _loadToken();
    _loadWarehouses();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _warehousePresenter.fetchAllWarehouse();
      _allWarehouses = warehouses;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка загрузки: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------
  // Логика поиска и фильтров
  // -------------------------------------------------------
  void _applyFilters() {
    List<Warehouse> filtered = List.from(_allWarehouses);

    // Фильтр по поиску (по наименованию продукта)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) => w.warehouseProductID.productName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Фильтр по ячейке
    if (_selectedCell != null && _selectedCell!.isNotEmpty) {
      filtered = filtered
          .where((w) => w.warehouseCellID.cellName == _selectedCell)
          .toList();
    }
    // Фильтр по количеству
    if (_minQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity >= _minQuantity!).toList();
    }
    if (_maxQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity <= _maxQuantity!).toList();
    }
    // Фильтр по дате обновления
    if (_startDate != null) {
      filtered = filtered
          .where((w) =>
      w.warehouseUpdateDate.isAfter(_startDate!) ||
          w.warehouseUpdateDate.isAtSameMomentAs(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((w) =>
      w.warehouseUpdateDate.isBefore(_endDate!) ||
          w.warehouseUpdateDate.isAtSameMomentAs(_endDate!))
          .toList();
    }

    setState(() => _warehouses = filtered);
  }

  // -------------------------------------------------------
  // Диалог фильтров
  // -------------------------------------------------------
  Future<void> _openFilterDialog() async {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
    final dialogHeight = isDesktop ? size.height * 0.3 : size.height * 0.5;

    // Дублируем текущие значения для "черновой" правки
    final cells =
    _allWarehouses.map((w) => w.warehouseCellID.cellName).toSet().toList();
    String? tempSelectedCell = _selectedCell;
    String? tempMinQuantity = _minQuantity?.toString();
    String? tempMaxQuantity = _maxQuantity?.toString();
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    // Контроллеры для полей "Мин" и "Макс"
    final TextEditingController minQuantityController =
    TextEditingController(text: tempMinQuantity ?? '');
    final TextEditingController maxQuantityController =
    TextEditingController(text: tempMaxQuantity ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Row(
            children: [
              Icon(
                _hasActiveFilters ? Icons.filter_alt : Icons.filter_list,
                color: _hasActiveFilters ? Colors.black : null,
              ),
              const SizedBox(width: 4),
              Text('Фильтры ($_activeFilterCount)'),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ячейка
                      _buildFilterCellSection(
                        isDesktop: isDesktop,
                        tempSelectedCell: tempSelectedCell,
                        cells: cells,
                        setStateDialog: setStateDialog,
                      ),
                      const SizedBox(height: 15),
                      // Количество
                      _buildFilterQuantitySection(
                        tempMinQuantity: tempMinQuantity,
                        tempMaxQuantity: tempMaxQuantity,
                        minController: minQuantityController,
                        maxController: maxQuantityController,
                        setStateDialog: setStateDialog,
                      ),
                      const SizedBox(height: 15),
                      // Даты
                      _buildFilterDateSection(
                        tempStartDate: tempStartDate,
                        tempEndDate: tempEndDate,
                        setStateDialog: setStateDialog,
                      ),
                      const SizedBox(height: 10),
                      // Чипы активных фильтров
                      _buildFilterChips(
                        tempSelectedCell: tempSelectedCell,
                        tempMinQuantity: tempMinQuantity,
                        tempMaxQuantity: tempMaxQuantity,
                        tempStartDate: tempStartDate,
                        tempEndDate: tempEndDate,
                        setStateDialog: setStateDialog,
                        minController: minQuantityController,
                        maxController: maxQuantityController,
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
                // Сброс фильтров
                setState(() {
                  _selectedCell = null;
                  _minQuantity = null;
                  _maxQuantity = null;
                  _startDate = null;
                  _endDate = null;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                // Применить изменения
                setState(() {
                  _selectedCell = tempSelectedCell;
                  _minQuantity =
                  (tempMinQuantity != null && tempMinQuantity.isNotEmpty)
                      ? int.tryParse(tempMinQuantity)
                      : null;
                  _maxQuantity =
                  (tempMaxQuantity != null && tempMaxQuantity.isNotEmpty)
                      ? int.tryParse(tempMaxQuantity)
                      : null;
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------
  // Вспомогательные методы для части диалога фильтров
  // -------------------------------------------------------
  Widget _buildFilterCellSection({
    required bool isDesktop,
    required String? tempSelectedCell,
    required List<String> cells,
    required void Function(void Function()) setStateDialog,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: tempSelectedCell != null ? Colors.blue : null,
            ),
            const SizedBox(width: 4),
            Text(
              'Ячейка:',
              style: TextStyle(
                color: tempSelectedCell != null ? Colors.blue : null,
              ),
            ),
          ],
        ),
        Container(
          width: isDesktop
              ? MediaQuery.of(context).size.width * 0.5
              : MediaQuery.of(context).size.width * 0.8,
          alignment: Alignment.centerLeft,
          child: DropdownButton<String>(
            isExpanded: true,
            value: tempSelectedCell,
            hint: const Text('Все ячейки'),
            items: cells
                .map(
                  (cell) => DropdownMenuItem(
                value: cell,
                child: Text(cell),
              ),
            )
                .toList(),
            onChanged: (value) {
              setStateDialog(() {
                tempSelectedCell = value;
              });
            },
            underline: Container(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterQuantitySection({
    required String? tempMinQuantity,
    required String? tempMaxQuantity,
    required TextEditingController minController,
    required TextEditingController maxController,
    required void Function(void Function()) setStateDialog,
  }) {
    final hasQuantityFilter = (tempMinQuantity != null && tempMinQuantity.isNotEmpty) ||
        (tempMaxQuantity != null && tempMaxQuantity.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_list_numbered,
              size: 16,
              color: hasQuantityFilter ? Colors.blue : null,
            ),
            const SizedBox(width: 4),
            Text(
              'Количество (мин - макс):',
              style: TextStyle(
                color: hasQuantityFilter ? Colors.blue : null,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Мин'),
                controller: minController,
                onChanged: (value) {
                  setStateDialog(() {
                    tempMinQuantity = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Макс'),
                controller: maxController,
                onChanged: (value) {
                  setStateDialog(() {
                    tempMaxQuantity = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDateSection({
    required DateTime? tempStartDate,
    required DateTime? tempEndDate,
    required void Function(void Function()) setStateDialog,
  }) {
    final hasDateFilter = tempStartDate != null || tempEndDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: hasDateFilter ? Colors.blue : null,
            ),
            const SizedBox(width: 4),
            Text(
              'Дата обновления:',
              style: TextStyle(color: hasDateFilter ? Colors.blue : null),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    locale: const Locale('ru', 'RU'),
                    initialDate:
                    tempStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setStateDialog(() => tempStartDate = picked);
                  }
                },
                child: Text(
                  tempStartDate != null
                      ? 'С ${tempStartDate.toLocal().toString().split(' ')[0]}'
                      : 'Начало',
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    locale: const Locale('ru', 'RU'),
                    initialDate: tempEndDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setStateDialog(() => tempEndDate = picked);
                  }
                },
                child: Text(
                  tempEndDate != null
                      ? 'По ${tempEndDate.toLocal().toString().split(' ')[0]}'
                      : 'Конец',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips({
    required String? tempSelectedCell,
    required String? tempMinQuantity,
    required String? tempMaxQuantity,
    required DateTime? tempStartDate,
    required DateTime? tempEndDate,
    required void Function(void Function()) setStateDialog,
    required TextEditingController minController,
    required TextEditingController maxController,
  }) {
    final chips = <Widget>[];

    if (tempSelectedCell != null) {
      chips.add(
        Chip(
          label: Text('Ячейка: $tempSelectedCell'),
          onDeleted: () => setStateDialog(() => tempSelectedCell = null),
        ),
      );
    }
    if (tempMinQuantity != null && tempMinQuantity.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Мин: $tempMinQuantity'),
          onDeleted: () => setStateDialog(() {
            tempMinQuantity = '';
            minController.text = '';
          }),
        ),
      );
    }
    if (tempMaxQuantity != null && tempMaxQuantity.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Макс: $tempMaxQuantity'),
          onDeleted: () => setStateDialog(() {
            tempMaxQuantity = '';
            maxController.text = '';
          }),
        ),
      );
    }
    if (tempStartDate != null) {
      chips.add(
        Chip(
          label: Text('С: ${tempStartDate.toLocal().toString().split(' ')[0]}'),
          onDeleted: () => setStateDialog(() => tempStartDate = null),
        ),
      );
    }
    if (tempEndDate != null) {
      chips.add(
        Chip(
          label: Text('По: ${tempEndDate.toLocal().toString().split(' ')[0]}'),
          onDeleted: () => setStateDialog(() => tempEndDate = null),
        ),
      );
    }

    return Wrap(spacing: 6, children: chips);
  }

  // -------------------------------------------------------
  // Детали склада
  // -------------------------------------------------------
  void _showWarehouseDetails(Warehouse warehouse) {
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
                    warehouse.warehouseProductID.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                          child: _buildDialogImage(
                            fileImage: null,
                            imageUrl: warehouse.warehouseProductID.productImage,
                            token: _token,
                            width: imageSize,
                            height: imageSize,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.inventory,
                          label: "Продукт:",
                          value: warehouse.warehouseProductID.productName,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.location_on,
                          label: "Ячейка:",
                          value: warehouse.warehouseCellID.cellName,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.format_list_numbered,
                          label: "Количество:",
                          value: warehouse.warehouseQuantity.toString(),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.access_time,
                          label: "Обновлено:",
                          value: warehouse.warehouseUpdateDate
                              .toLocal()
                              .toString()
                              .split('.')[0],
                        ),
                        const Divider(height: 20),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Закрыть", style: TextStyle(fontSize: 16)),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {

    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildDialogImage({
    File? fileImage,
    String? imageUrl,
    String? token,
    double width = 250,
    double height = 250,
  }) {
    // Если выбрано локальное изображение
    if (fileImage != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(fileImage),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    // Если есть ссылка на изображение
    else if (imageUrl != null && imageUrl.isNotEmpty) {
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
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    // Если нет изображения
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.inventory, size: 50),
    );
  }

  // -------------------------------------------------------
  // Список карточек
  // -------------------------------------------------------
  Widget _buildWarehouseCard(Warehouse warehouse) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: _buildLeadingAvatar(warehouse),
        title: Text(
          warehouse.warehouseProductID.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildWarehouseSubtitle(warehouse),
        onTap: () => _showWarehouseDetails(warehouse),
      ),
    );
  }

  Widget _buildLeadingAvatar(Warehouse warehouse) {
    final imageUrl = warehouse.warehouseProductID.productImage;
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(
          AppConstants.apiBaseUrl + imageUrl,
          headers: _token != null ? {"Authorization": "Bearer $_token"} : null,
        ),
        backgroundColor: Colors.grey[300],
      );
    }
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey,
      child: Icon(Icons.inventory),
    );
  }

  Widget _buildWarehouseSubtitle(Warehouse warehouse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text("Ячейка: ${warehouse.warehouseCellID.cellName}"),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.format_list_numbered, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text("Количество: ${warehouse.warehouseQuantity}"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                "Обновлено: ${warehouse.warehouseUpdateDate.toLocal().toString().split('.')[0]}",
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarehouseList() {
    final displayedWarehouses = _warehouses.where((w) {
      // Повторное наложение поиска (если нужно)
      return _searchQuery.isEmpty ||
          w.warehouseProductID.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadWarehouses,
      child: ListView.builder(
        itemCount: displayedWarehouses.length,
        itemBuilder: (context, index) {
          final warehouse = displayedWarehouses[index];
          return _buildWarehouseCard(warehouse);
        },
      ),
    );
  }

  // -------------------------------------------------------
  // Построение тела
  // -------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildWarehouseList();
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Поиск по наименованию...",
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.black),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        )
            : const Text('Склад'),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _applyFilters();
              });
            },
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
          // Кнопка фильтров с иконкой и бейджем
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _hasActiveFilters ? Icons.filter_alt : Icons.filter_list,
                  color: Colors.black,
                ),
                onPressed: _openFilterDialog,
              ),
              if (_activeFilterCount > 0)
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
                      '$_activeFilterCount',
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
              child: _buildBody(),
            ),
          );
        },
      ),
    );
  }
}
