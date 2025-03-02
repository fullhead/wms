import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class CellView extends StatelessWidget {
  const CellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ячейки'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Ячейки',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
