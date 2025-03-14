import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/warehouse.dart';
import 'package:wms/presenters/warehouse_presenter.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/core/routes.dart';

/// Главное представление склада [WarehouseView].
/// Использует [WarehousePresenter] для загрузки данных.
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

  /// Полный список всех складских позиций.
  List<Warehouse> _allWarehouses = [];

  /// Отфильтрованный список позиций.
  List<Warehouse> _warehouses = [];

  /// Индикатор загрузки
  bool _isLoading = false;

  /// Токен авторизации (для заголовков при загрузке изображений)
  String? _token;

  /// Флаги и поля для поиска
  bool _isSearching = false;
  String _searchQuery = '';

  /// Параметры для фильтра
  String? _selectedCell;
  int? _minQuantity;
  int? _maxQuantity;
  DateTime? _startDate;
  DateTime? _endDate;

  /// Считаем количество активных фильтров (для бейджа на иконке)
  int get _activeFilterCount {
    int count = 0;
    if (_selectedCell != null && _selectedCell!.isNotEmpty) count++;
    if (_minQuantity != null) count++;
    if (_maxQuantity != null) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    return count;
  }

  /// Удобный геттер – есть ли вообще активные фильтры
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

  /// Загрузка токена авторизации из хранилища
  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  /// Загрузка списка складских позиций с сервера
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

  /// Применяем фильтры (включая поисковый запрос) к _allWarehouses
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

    // Фильтрация по количеству (мин)
    if (_minQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity >= _minQuantity!).toList();
    }

    // Фильтрация по количеству (макс)
    if (_maxQuantity != null) {
      filtered =
          filtered.where((w) => w.warehouseQuantity <= _maxQuantity!).toList();
    }

    // Фильтрация по дате (начало)
    if (_startDate != null) {
      filtered = filtered
          .where((w) =>
      w.warehouseUpdateDate.isAfter(_startDate!) ||
          w.warehouseUpdateDate.isAtSameMomentAs(_startDate!))
          .toList();
    }

    // Фильтрация по дате (конец)
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

  // -------------------------------------------------------
  // Диалог фильтров
  // -------------------------------------------------------
  /// Открываем диалоговое окно с настройками фильтра
  Future<void> _openFilterDialog() async {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final dialogWidth = isDesktop ? size.width * 0.4 : size.width * 0.9;
    final dialogHeight = isDesktop ? size.height * 0.3 : size.height * 0.5;

    // Получаем уникальные ячейки для фильтрации
    final cells = _allWarehouses.map((w) => w.warehouseCellID.cellName).toSet().toList();
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
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------------
                      // Фильтр по ячейке
                      // -----------------------------
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: (tempSelectedCell != null)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ячейка:',
                            style: TextStyle(
                              color: (tempSelectedCell != null)
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
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
                      const SizedBox(height: 15),

                      // -----------------------------
                      // Фильтр по количеству
                      // -----------------------------
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            size: 16,
                            color: ((tempMinQuantity != null &&
                                tempMinQuantity!.isNotEmpty) ||
                                (tempMaxQuantity != null &&
                                    tempMaxQuantity!.isNotEmpty))
                                ? Theme.of(context).colorScheme.primary
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
                                  ? Theme.of(context).colorScheme.primary
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

                      // -----------------------------
                      // Фильтр по дате
                      // -----------------------------
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: (tempStartDate != null || tempEndDate != null)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Дата обновления:',
                            style: TextStyle(
                              color: (tempStartDate != null || tempEndDate != null)
                                  ? Theme.of(context).colorScheme.primary
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
                                    ? 'С ${tempStartDate?.toLocal().toString().split(' ')[0]}'
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
                                    ? 'По ${tempEndDate?.toLocal().toString().split(' ')[0]}'
                                    : 'Конец',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // -----------------------------
                      // Чипы для отображения активных фильтров
                      // -----------------------------
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
                          if (tempMinQuantity != null && tempMinQuantity!.isNotEmpty)
                            Chip(
                              label: Text('Мин: $tempMinQuantity'),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempMinQuantity = '';
                                  minQuantityController.text = '';
                                });
                              },
                            ),
                          if (tempMaxQuantity != null && tempMaxQuantity!.isNotEmpty)
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
                                'С: ${tempStartDate?.toLocal().toString().split(' ')[0]}',
                              ),
                              onDeleted: () {
                                setStateDialog(() {
                                  tempStartDate = null;
                                });
                              },
                            ),
                          if (tempEndDate != null)
                            Chip(
                              label: Text(
                                'По: ${tempEndDate?.toLocal().toString().split(' ')[0]}',
                              ),
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
                // Полный сброс фильтров
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
                // Сохраняем временные значения в основной State
                setState(() {
                  _selectedCell = tempSelectedCell;
                  _minQuantity = (tempMinQuantity != null &&
                      tempMinQuantity!.isNotEmpty)
                      ? int.tryParse(tempMinQuantity!)
                      : null;
                  _maxQuantity = (tempMaxQuantity != null &&
                      tempMaxQuantity!.isNotEmpty)
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

  // -------------------------------------------------------
  // Вспомогательные методы отображения
  // -------------------------------------------------------
  /// Универсальное построение изображения (локальный файл, сетевое изображение или дефолтная иконка)
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
    // Если нет изображения
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

  /// Показываем диалог с детальной информацией о складе
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
                    // Основная часть
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
                            const Icon(Icons.inventory,
                                color: Colors.deepOrange, size: 16),
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
                            const Icon(Icons.location_on,
                                color: Colors.deepOrange, size: 16),
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
                            const Icon(Icons.format_list_numbered,
                                color: Colors.deepOrange, size: 16),
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
                            const Icon(Icons.access_time,
                                color: Colors.deepOrange, size: 16),
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
                    // Кнопка Закрыть
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Закрыть",
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

  /// Создаём виджет-карту для конкретной позиции склада
  Widget _buildWarehouseCard(Warehouse warehouse) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: (warehouse.warehouseProductID.productImage.isNotEmpty)
            ? CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(
            AppConstants.apiBaseUrl +
                warehouse.warehouseProductID.productImage,
            headers: _token != null
                ? {"Authorization": "Bearer $_token"}
                : null,
          ),
          backgroundColor: Theme.of(context).dividerColor,
        )
            : CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).dividerColor,
          child: const Icon(Icons.inventory, color: Colors.deepOrange),
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
                const Icon(Icons.location_on,
                    color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text("Ячейка: ${warehouse.warehouseCellID.cellName}"),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.format_list_numbered,
                    color: Colors.deepOrange, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text("Количество: ${warehouse.warehouseQuantity}"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: Colors.deepOrange, size: 14),
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

  /// Создаём скелетон-карту
  Widget _buildSkeletonCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          color: theme.dividerColor,
        ),
        title: Container(
          width: double.infinity,
          height: 16,
          color: theme.dividerColor,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
          height: 16,
          color: theme.dividerColor,
        ),
      ),
    );
  }

  /// Строим основной контент страницы (с учётом загрузки, пустого списка и т.д.)
  Widget _buildBody(List<Warehouse> displayedWarehouses) {
    if (_isLoading) {
      // Показываем список из нескольких скелетонов
      return ListView.builder(
        itemCount: 12,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (displayedWarehouses.isEmpty) {
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
      if (_hasActiveFilters) {
        // Если активен хотя бы один фильтр, выводим сообщение
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
              child: Text(
                'По выбранным фильтрам продукций не найдено!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      } else {
        // Если данных в базе вообще нет, выводим сообщение с кнопкой перехода
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Нет складских данных. Начните приёмку продукций!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.receives);
                    },
                    child: const Text('Начать приёмку'),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }

    // Если данные есть, показываем их
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: displayedWarehouses.length,
      itemBuilder: (context, index) {
        final warehouse = displayedWarehouses[index];
        return _buildWarehouseCard(warehouse);
      },
    );
  }

  // -------------------------------------------------------
  // Основной build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Итоговый список для отображения (учитываем и _searchQuery)
    final displayedWarehouses = _warehouses.where((w) {
      return _searchQuery.isEmpty ||
          w.warehouseProductID.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    final theme = Theme.of(context);

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
            : const Text('Склад', style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.deepOrange),
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
            icon: const Icon(Icons.search, color: Colors.deepOrange),
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
          // Кнопка фильтров с изменяемой иконкой и бейджем с количеством
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _hasActiveFilters ? Icons.filter_alt : Icons.filter_list,
                  color: theme.colorScheme.primary,
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
              child: RefreshIndicator(
                onRefresh: _loadWarehouses,
                child: _buildBody(displayedWarehouses),
              ),
            ),
          );
        },
      ),
    );
  }
}
