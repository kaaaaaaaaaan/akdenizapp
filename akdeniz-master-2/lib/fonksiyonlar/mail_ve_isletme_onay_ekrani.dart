import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/anasayfa.dart';
import 'package:sonartiksonnnnnn/email_dogrulama_bekleme/emailverificationpage.dart';
import 'package:sonartiksonnnnnn/email_dogrulama_bekleme/isletme_onay_ekrani.dart';

class TumdenKontrol extends StatefulWidget {
  @override
  _TumdenKontrolState createState() => _TumdenKontrolState();
}

class _TumdenKontrolState extends State<TumdenKontrol> {
  bool isLoading = true; // Yükleniyor durumu

  @override
  void initState() {
    super.initState();
    _checkEmailAndBusinessVerification();
  }

  Future<void> _checkEmailAndBusinessVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload();
      bool isEmailVerified = user.emailVerified;
      bool isBusinessApproved = false;

      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          isBusinessApproved = snapshot['onay'];
        }
      } catch (e) {
        print('Error checking business approval status: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }

      if (isEmailVerified && isBusinessApproved) {
        // Her ikisi de onaylı ise ana sayfaya yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Anasayfa()),
        );
      } else if (isEmailVerified) {
        // Sadece e-posta onaylı, işletme onayı bekleniyor
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => IsletmeOnayEkrani()),
        );
      } else {
        // E-posta doğrulanmamışsa doğrulama sayfasına yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EmailVerificationPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Yükleniyor durumu için gösterge
            : Container(), // Boş container (gerekirse hata mesajı vb. ekleyebilirsiniz)
      ),
    );
  }
}
