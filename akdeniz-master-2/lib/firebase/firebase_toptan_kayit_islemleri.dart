import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sonartiksonnnnnn/email_dogrulama_bekleme/emailverificationpage.dart';

//Firebase'e Kullanıcı Kayıt Fonksiyonu
Future<UserCredential> registerUser(String email, String password) async {
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } catch (e) {
    throw Exception('Failed to register user: $e');
  }
}

//Firebase Storage'a Görsel Yükleme Fonksiyonu
Future<String> uploadImage(File image, String userId) async {
  try {
    String fileName = 'restaurants/$userId/profile_image.jpg';
    UploadTask uploadTask =
        FirebaseStorage.instance.ref().child(fileName).putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

//Firestore'a Kullanıcı Bilgilerini Kaydetme Fonksiyonu
Future<void> saveUserInfo(
    String userId,
    String restaurantName,
    String email,
    bool onay,
    String selectedUniversity,
    String address,
    LatLng currentPosition,
    String imageUrl) async {
  try {
    await FirebaseFirestore.instance.collection('restaurants').doc(userId).set({
      'restaurantName': restaurantName,
      'email': email,
      'onay': onay,
      'selectedUniversity': selectedUniversity,
      'address': address,
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
      'profileImageUrl': imageUrl,
    });
  } catch (e) {
    throw Exception('Failed to save user info: $e');
  }
}

//E-posta Doğrulama Gönderme Fonksiyonu
Future<void> sendEmailVerification(User user) async {
  try {
    await user.sendEmailVerification();
  } catch (e) {
    throw Exception('Failed to send email verification: $e');
  }
}

//E-posta Doğrulama Durumunu Kontrol Etme Fonksiyonu
Future<bool> checkEmailVerification(User user) async {
  await user.reload();
  return user.emailVerified;
}

//toplu işlem
Future<void> register(
    String restaurantName,
    String email,
    String password,
    bool onay,
    String selectedUniversity,
    String address,
    LatLng currentPosition,
    File image,
    BuildContext context) async {
  try {
    // Register user
    UserCredential userCredential = await registerUser(email, password);
    User? user = userCredential.user;

    if (user == null) {
      throw Exception('User registration failed');
    }

    // Upload image
    String imageUrl = await uploadImage(image, user.uid);

    // Save user info to Firestore
    await saveUserInfo(user.uid, restaurantName, email, onay,
        selectedUniversity, address, currentPosition, imageUrl);

    // Send email verification
    await sendEmailVerification(user);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => EmailVerificationPage()),
    );

    print("Başarılı");
  } catch (e) {
    // Handle the error accordingly
    print('Registration error: $e');
  }
}
