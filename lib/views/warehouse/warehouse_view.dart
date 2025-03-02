import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class WarehouseView extends StatelessWidget {
  const WarehouseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Пользователей',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
