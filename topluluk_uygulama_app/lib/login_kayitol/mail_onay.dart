import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:topluluk_uygulama_app/login_kayitol/topluluk_onay.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    _user = _auth.currentUser;
    await _user?.reload();
    if (_user?.emailVerified ?? false) {
      _timer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => VerifyCommunityPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                '${_user?.email} adresine bir doğrulama e-postası gönderildi. Lütfen doğrulayın.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _user?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Doğrulama e-postası yeniden gönderildi.')),
                );
              },
              child: const Text('E-postayı Tekrar Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
