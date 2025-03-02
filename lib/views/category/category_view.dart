import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Категории',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
