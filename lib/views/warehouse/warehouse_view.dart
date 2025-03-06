import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/presenters/warehouse/warehouse_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'package:wms/services/auth_storage.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  WarehouseViewState createState() => WarehouseViewState();
}

class WarehouseViewState extends State<WarehouseView> {
  late final WarehousePresenter _warehousePresenter;
  List<Warehouse> _allWarehouses = [];
  List<Warehouse> _warehouses = [];
  bool _isLoading = false;
  String? _token;

  bool _isSearching = false;
  String _searchQuery = '';

  String? _selectedCell;
  int? _minQuantity;
  int? _maxQuantity;
  DateTime? _startDate;
  DateTime? _endDate;

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
    setState(() {
      _isLoading = true;
    });
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

  void _applyFilters() {
    List<Warehouse> filtered = List.from(_allWarehouses);

    // Фильтрация по поисковому запросу (наименование продукта)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) => w.warehouseProductID.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Фильтрация по ячейке
    if (_selectedCell != null && _selectedCell!.isNotEmpty) {
      filtered = filtered
          .where((w) => w.warehouseCellID.cellName == _selectedCell)
          .toList();
    }
    // Фильтрация по количеству
    if (_minQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity >= _minQuantity!).toList();
    }
    if (_maxQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity <= _maxQuantity!).toList();
    }
    // Фильтрация по дате обновления
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
    setState(() {
      _warehouses = filtered;
    });
  }

  Future<void> _openFilterDialog() async {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
    final dialogHeight = isDesktop ? size.height * 0.3 : size.height * 0.5;

    // Получаем уникальные ячейки для фильтрации
    final cells =
        _allWarehouses.map((w) => w.warehouseCellID.cellName).toSet().toList();
    String? tempSelectedCell = _selectedCell;
    String? tempMinQuantity = _minQuantity?.toString();
    String? tempMaxQuantity = _maxQuantity?.toString();
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    // Создаем контроллеры для полей ввода количества
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
                      // Фильтр по ячейке с иконкой и изменением стиля, если выбран
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color:
                                tempSelectedCell != null ? Colors.blue : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ячейка:',
                            style: TextStyle(
                              color:
                                  tempSelectedCell != null ? Colors.blue : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: isDesktop
                            ? MediaQuery.of(context).size.width *
                                0.5 // 50% экрана на десктопе
                            : MediaQuery.of(context).size.width *
                                0.8, // 80% на мобильном
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: tempSelectedCell,
                          hint: const Text('Все ячейки'),
                          items: cells
                              .map((cell) => DropdownMenuItem(
                                    value: cell,
                                    child: Text(cell),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              tempSelectedCell = value;
                            });
                          },
                          underline: Container(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Фильтр по количеству с иконкой и изменением стиля если выбран
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            size: 16,
                            color: ((tempMinQuantity != null &&
                                        tempMinQuantity!.isNotEmpty) ||
                                    (tempMaxQuantity != null &&
                                        tempMaxQuantity!.isNotEmpty))
                                ? Colors.blue
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Количество (мин - макс):',
                            style: TextStyle(
                              color: ((tempMinQuantity != null &&
                                          tempMinQuantity!.isNotEmpty) ||
                                      (tempMaxQuantity != null &&
                                          tempMaxQuantity!.isNotEmpty))
                                  ? Colors.blue
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Мин',
                              ),
                              controller: minQuantityController,
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
                              decoration: const InputDecoration(
                                hintText: 'Макс',
                              ),
                              controller: maxQuantityController,
                              onChanged: (value) {
                                setStateDialog(() {
                                  tempMaxQuantity = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Фильтр по дате обновления с иконкой и изменением стиля если выбран
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color:
                                (tempStartDate != null || tempEndDate != null)
                                    ? Colors.blue
                                    : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Дата обновления:',
                            style: TextStyle(
                              color:
                                  (tempStartDate != null || tempEndDate != null)
                                      ? Colors.blue
                                      : null,
                            ),
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
                                  initialDate: tempStartDate ??
                                      DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    tempStartDate = picked;
                                  });
                                }
                              },
                              child: Text(
                                tempStartDate != null
                                    ? 'С ${tempStartDate!.toLocal().toString().split(' ')[0]}'
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
                                  setStateDialog(() {
                                    tempEndDate = picked;
                                  });
                                }
                              },
                              child: Text(
                                tempEndDate != null
                                    ? 'По ${tempEndDate!.toLocal().toString().split(' ')[0]}'
                                    : 'Конец',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Чипы для отображения активных фильтров
                      Wrap(
                        spacing: 6,
                        children: [
                          if (tempSelectedCell != null)
                            Chip(
                              label: Text('Ячейка: $tempSelectedCell'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempSelectedCell = null;
                                });
                              },
                            ),
                          if (tempMinQuantity != null &&
                              tempMinQuantity!.isNotEmpty)
                            Chip(
                              label: Text('Мин: $tempMinQuantity'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempMinQuantity = '';
                                  minQuantityController.text = '';
                                });
                              },
                            ),
                          if (tempMaxQuantity != null &&
                              tempMaxQuantity!.isNotEmpty)
                            Chip(
                              label: Text('Макс: $tempMaxQuantity'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempMaxQuantity = '';
                                  maxQuantityController.text = '';
                                });
                              },
                            ),
                          if (tempStartDate != null)
                            Chip(
                              label: Text(
                                  'С: ${tempStartDate!.toLocal().toString().split(' ')[0]}'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempStartDate = null;
                                });
                              },
                            ),
                          if (tempEndDate != null)
                            Chip(
                              label: Text(
                                  'По: ${tempEndDate!.toLocal().toString().split(' ')[0]}'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempEndDate = null;
                                });
                              },
                            ),
                        ],
                      )
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
                Navigator.of(context).pop();
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCell = tempSelectedCell;
                  _minQuantity =
                      (tempMinQuantity != null && tempMinQuantity!.isNotEmpty)
                          ? int.tryParse(tempMinQuantity!)
                          : null;
                  _maxQuantity =
                      (tempMaxQuantity != null && tempMaxQuantity!.isNotEmpty)
                          ? int.tryParse(tempMaxQuantity!)
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

  Widget _buildDialogImage({
    File? fileImage,
    String? imageUrl,
    String? token,
    double width = 250,
    double height = 250,
  }) {
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
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
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
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
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
                        Row(
                          children: [
                            const Icon(Icons.inventory, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Продукт:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                warehouse.warehouseProductID.productName,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Ячейка:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                warehouse.warehouseCellID.cellName,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.format_list_numbered, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Количество:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                warehouse.warehouseQuantity.toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Обновлено:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                warehouse.warehouseUpdateDate
                                    .toLocal()
                                    .toString()
                                    .split('.')[0],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          "Закрыть",
                          style: TextStyle(fontSize: 16),
                        ),
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

  Widget _buildWarehouseCard(Warehouse warehouse) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: warehouse.warehouseProductID.productImage.isNotEmpty
            ? CircleAvatar(
                radius: 30,
                backgroundImage: CachedNetworkImageProvider(
                  AppConstants.apiBaseUrl +
                      warehouse.warehouseProductID.productImage,
                  headers: _token != null
                      ? {"Authorization": "Bearer $_token"}
                      : null,
                ),
                backgroundColor: Colors.grey[300],
              )
            : CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.inventory),
              ),
        title: Text(
          warehouse.warehouseProductID.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
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
        ),
        onTap: () => _showWarehouseDetails(warehouse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedWarehouses = _warehouses.where((w) {
      return _searchQuery.isEmpty ||
          w.warehouseProductID.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

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
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                // Кнопка фильтров с изменяемой иконкой и бейджем с количеством
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        _hasActiveFilters
                            ? Icons.filter_alt
                            : Icons.filter_list,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadWarehouses,
                      child: ListView.builder(
                        itemCount: displayedWarehouses.length,
                        itemBuilder: (context, index) {
                          final warehouse = displayedWarehouses[index];
                          return _buildWarehouseCard(warehouse);
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
