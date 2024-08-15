import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:topluluk_uygulama_app/ana_scaffold.dart';
import 'package:topluluk_uygulama_app/login_kayitol/mail_onay.dart';
import 'package:topluluk_uygulama_app/login_kayitol/topluluk_onay.dart';

class CheckUserStatusPage extends StatefulWidget {
  @override
  _CheckUserStatusPageState createState() => _CheckUserStatusPageState();
}

class _CheckUserStatusPageState extends State<CheckUserStatusPage> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (!user.emailVerified) {
        // Kullanıcı e-posta doğrulamasını yapmamışsa, e-posta doğrulama sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerifyEmailPage()),
        );

        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final toplulukOnay = data['topluluk_onay'] as bool;

        if (!toplulukOnay) {
          // Topluluk onayı yapılmamışsa, onay bekleniyor sayfasına yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerifyCommunityPage()),
          );

          return;
        }

        // Tüm durumlar doğruysa, ana sayfaya yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AnaScaffold()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yükleme sırasında basit bir yükleme göstergesi gösteriyoruz
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
