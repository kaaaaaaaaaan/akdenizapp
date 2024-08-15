import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:sonartiksonnnnnn/AnaSayfa/anasayfa.dart';

class IsletmeOnayEkrani extends StatefulWidget {
  @override
  _IsletmeOnayEkraniState createState() => _IsletmeOnayEkraniState();
}

class _IsletmeOnayEkraniState extends State<IsletmeOnayEkrani> {
  bool isApproved = false;
  bool isLoading = true;
  late Timer timer;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      checkApprovalStatus();
      timer = Timer.periodic(
        Duration(seconds: 5),
        (_) => checkApprovalStatus(),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Eğer kullanıcı yoksa, giriş sayfasına yönlendirebilirsiniz.
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => Anasayfa()));
    }
  }

  Future<void> checkApprovalStatus() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user!.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          isApproved = snapshot['onay'];
          isLoading = false;
        });

        if (isApproved) {
          timer.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Anasayfa()),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking approval status: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İşletme Onay Ekranı'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : isApproved
                ? Text(
                    'İşletmeniz onaylandı! Anasayfa sayfasına yönlendiriliyorsunuz...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hesabınız onaylanma aşamasındadır.',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          checkApprovalStatus();
                        },
                        child: Text('Durumu Yenile'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
