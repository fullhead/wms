import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class IssueView extends StatelessWidget {
  const IssueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выдача'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Выдача',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
