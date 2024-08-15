import 'package:flutter/material.dart';

class BizeUlasin extends StatefulWidget {
  const BizeUlasin({super.key});

  @override
  State<BizeUlasin> createState() => _HakkimizdaState();
}

class _HakkimizdaState extends State<BizeUlasin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text("Bize Ulaşın"),
      ),
    );
  }
}
