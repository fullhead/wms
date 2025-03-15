import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/models/dashboard.dart';
import 'package:wms/presenters/dashboard_presenter.dart';

class DashboardMonitoringView extends StatefulWidget {
  const DashboardMonitoringView({super.key});

  @override
  State<DashboardMonitoringView> createState() =>
      _DashboardMonitoringViewState();
}

class _DashboardMonitoringViewState extends State<DashboardMonitoringView> {
  final DashboardPresenter _presenter = DashboardPresenter();
  late Future<DashboardMonitoring> _monitoringFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadMonitoringData();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) {
      setState(() {});
    }
  }

  void _loadMonitoringData() {
    _monitoringFuture = _presenter.fetchMonitoring();
  }

  Future<void> _refreshData() async {
    // Перезагружаем данные
    setState(() {
      _loadMonitoringData();
    });
    await _monitoringFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<DashboardMonitoring>(
        future: _monitoringFuture,
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
          final monitoring = snapshot.data!;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Недавно принятые'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: monitoring.recentReceives.length,
                    itemBuilder: (context, index) {
                      final item = monitoring.recentReceives[index];
                      return _MonitoringCard(
                        token: _token,
                        title: item.productName,
                        subtitle: item.categoryName,
                        quantity: item.quantity,
                        cellName: item.cellName,
                        dateTime: item.receiveDate,
                        imageUrl: item.productImage,
                        icon: Icons.call_received,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle(title: 'Недавно выданные'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: monitoring.recentIssues.length,
                    itemBuilder: (context, index) {
                      final item = monitoring.recentIssues[index];
                      return _MonitoringCard(
                        token: _token,
                        title: item.productName,
                        subtitle: item.categoryName,
                        quantity: item.quantity,
                        cellName: item.cellName,
                        dateTime: item.issueDate,
                        imageUrl: item.productImage,
                        icon: Icons.call_made,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle(title: 'Самые принимаемые'),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: monitoring.mostReceived.length,
                  itemBuilder: (context, index) {
                    final item = monitoring.mostReceived[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: const Icon(Icons.call_received, color: Colors.green),
                      title: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.category, size: 14, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number, size: 14, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text('Количество: ${item.totalReceived}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(item.lastReceiveTime),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const SectionTitle(title: 'Самые выдаваемые'),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: monitoring.mostIssued.length,
                  itemBuilder: (context, index) {
                    final item = monitoring.mostIssued[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: const Icon(Icons.call_made, color: Colors.red),
                      title: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.category, size: 14, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number, size: 14, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text('Количество: ${item.totalIssued}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(item.lastIssueTime),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  final String? token;
  final String title;
  final String subtitle;
  final int quantity;
  final String cellName;
  final DateTime dateTime;
  final String imageUrl;
  final IconData icon;

  const _MonitoringCard({
    required this.token,
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.cellName,
    required this.dateTime,
    required this.imageUrl,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(4, 4, 8, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '${AppConstants.apiBaseUrl}$imageUrl',
                  httpHeaders: token != null ? {"Authorization": "Bearer $token"} : null,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.category, size: 14, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.confirmation_number, size: 14, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Количество: $quantity',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ячейка: $cellName',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
    );
  }
}
