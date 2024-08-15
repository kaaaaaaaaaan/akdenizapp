import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth için import
import 'package:sonartiksonnnnnn/Ilk_sayfalar/giris_yap.dart';
import 'package:sonartiksonnnnnn/fonksiyonlar/mail_ve_isletme_onay_ekrani.dart';
import 'firebase_options.dart';
import 'package:sonartiksonnnnnn/AnaDosya/anascaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: _getLandingPage(), // Doğru sayfayı döndüren fonksiyon
    );
  }

  Widget _getLandingPage() {
    // Kullanıcı oturum açmış mı kontrol et
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Kullanıcı oturum açmışsa ana sayfaya yönlendir
      return TumdenKontrol();
    } else {
      // Kullanıcı oturum açmamışsa giriş sayfasına yönlendir
      return GirisYap();
    }
  }
}
