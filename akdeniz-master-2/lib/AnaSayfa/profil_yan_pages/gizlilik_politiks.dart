import 'package:flutter/material.dart';

class GizlilikPolitiks extends StatefulWidget {
  const GizlilikPolitiks({super.key});

  @override
  State<GizlilikPolitiks> createState() => _HakkimizdaState();
}

class _HakkimizdaState extends State<GizlilikPolitiks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text("Gizlilik Politikası"),
      ),
    );
  }
}
