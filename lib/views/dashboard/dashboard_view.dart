import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';
import 'dashboard_statistic.dart';
import 'dashboard_monitoring.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const WmsDrawer(),
        appBar: AppBar(
          title: const Text(
            'Панель управления',
            style: TextStyle(color: Colors.deepOrange),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const TabBarView(
                  children: [
                    DashboardStatisticView(),
                    DashboardMonitoringView(),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          child: const TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Статистика',
              ),
              Tab(
                icon: Icon(Icons.show_chart),
                text: 'Мониторинг',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
