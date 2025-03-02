import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class PersonalizationView extends StatelessWidget {
  const PersonalizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Персонализация'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Персонализация',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
