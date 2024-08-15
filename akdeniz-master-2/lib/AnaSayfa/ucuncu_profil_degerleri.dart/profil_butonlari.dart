import 'package:flutter/material.dart';

class ProfilButonlari extends StatefulWidget {
  final Function() func;
  final String ic_Deger;
  const ProfilButonlari(
      {super.key, required this.func, required this.ic_Deger});

  @override
  State<ProfilButonlari> createState() => _ProfilButonlariState();
}

class _ProfilButonlariState extends State<ProfilButonlari> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.func,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: Color(0xFFEA004B), borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Text(
            widget.ic_Deger,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
