import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель управления'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Панель управления',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
