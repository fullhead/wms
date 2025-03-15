import 'package:flutter/material.dart';
import 'package:wms/models/dashboard.dart';
import 'package:wms/presenters/dashboard_presenter.dart';

class DashboardStatisticView extends StatefulWidget {
  const DashboardStatisticView({super.key});

  @override
  State<DashboardStatisticView> createState() =>
      _DashboardStatisticViewState();
}

class _DashboardStatisticViewState extends State<DashboardStatisticView> {
  final DashboardPresenter _presenter = DashboardPresenter();
  late Future<DashboardStatistics> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatisticsData();
  }

  void _loadStatisticsData() {
    _statisticsFuture = _presenter.fetchStatistics();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadStatisticsData();
    });
    await _statisticsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<DashboardStatistics>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Нет данных'));
          }
          final stats = snapshot.data!;
          final items = [
            _StatItem(title: 'Пользователи', count: stats.userCount, icon: Icons.person),
            _StatItem(title: 'Группы', count: stats.groupCount, icon: Icons.group),
            _StatItem(title: 'Продукция', count: stats.productCount, icon: Icons.production_quantity_limits),
            _StatItem(title: 'Категории', count: stats.categoryCount, icon: Icons.category),
            _StatItem(title: 'Приемки', count: stats.receiveCount, icon: Icons.call_received),
            _StatItem(title: 'Выдачи', count: stats.issueCount, icon: Icons.call_made),
            _StatItem(title: 'На складе', count: stats.warehouseProductCount, icon: Icons.warehouse),
            _StatItem(title: 'Заполнено ячеек', count: stats.filledCells, icon: Icons.view_list),
            _StatItem(title: 'Пустых ячеек', count: stats.emptyCells, icon: Icons.crop_free),
          ];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 24,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.3,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon,
                              size: 36, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.count.toString(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem {
  final String title;
  final int count;
  final IconData icon;

  _StatItem({required this.title, required this.count, required this.icon});
}
