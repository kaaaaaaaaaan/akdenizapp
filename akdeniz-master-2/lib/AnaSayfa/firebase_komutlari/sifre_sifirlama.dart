import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // SnackBar için gerekli

Future<void> sendPasswordResetEmail(BuildContext context, String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi')),
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata: ${e.message}')),
    );
  }
}
