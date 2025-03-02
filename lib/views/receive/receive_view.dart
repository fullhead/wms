import 'package:flutter/material.dart';
import 'package:wms/widgets/wms_drawer.dart';

class ReceiveView extends StatelessWidget {
  const ReceiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приемка'),
      ),
      drawer: const WmsDrawer(),
      body: const Center(
        child: Text(
          'Заглушка для модуля Приемка',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
