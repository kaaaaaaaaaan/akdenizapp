import 'package:flutter/material.dart';

class SikcaSorulanSorular extends StatefulWidget {
  const SikcaSorulanSorular({super.key});

  @override
  State<SikcaSorulanSorular> createState() => _HakkimizdaState();
}

class _HakkimizdaState extends State<SikcaSorulanSorular> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text("Sıkça Sorulan Sorular"),
      ),
    );
  }
}
