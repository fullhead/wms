import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class ProductView extends StatelessWidget {
  const ProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все продукции'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Все продукции',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
