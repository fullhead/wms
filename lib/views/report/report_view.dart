import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчеты'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Отчеты',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
