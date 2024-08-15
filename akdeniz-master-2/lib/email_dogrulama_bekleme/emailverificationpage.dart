import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:sonartiksonnnnnn/email_dogrulama_bekleme/isletme_onay_ekrani.dart';

class EmailVerificationPage extends StatefulWidget {
  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      isEmailVerified = user.emailVerified;

      if (!isEmailVerified) {
        sendVerificationEmail();
        timer = Timer.periodic(
          Duration(seconds: 3),
          (_) => checkEmailVerified(),
        );
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      setState(() => canResendEmail = false);
      await Future.delayed(Duration(seconds: 60));
      setState(() => canResendEmail = true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        // content: Text(
        //   'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.'),
        //));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('E-posta doğrulama hatası: ${e.message}'),
        ));
      }
    }
  }

  Future<void> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    setState(() {
      isEmailVerified = user.emailVerified;
    });

    if (isEmailVerified) {
      timer.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => IsletmeOnayEkrani()),
      );
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
        automaticallyImplyLeading: false,
        title: Text('E-posta Doğrulama'),
      ),
      body: Center(
        child: isEmailVerified
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'E-posta başarıyla doğrulandı!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => IsletmeOnayEkrani()),
                      );
                    },
                    child: Text('Devam Et'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'E-posta doğrulama bekleniyor...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                    child: Text('Doğrulama E-postasını Tekrar Gönder'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text('Çıkış Yap'),
                  ),
                ],
              ),
      ),
    );
  }
}
