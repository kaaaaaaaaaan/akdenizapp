import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

import 'ikinci_orta.dart';
import 'ucuncu_profil.dart';
import 'ilk_bakis.dart';

String imageUrl = '';
String name = '';
String email = '';
String school = '';
String adress = "";
String isletme_adi = "";

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('restaurants').doc(user.uid);

      try {
        // Load user data
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          setState(() {
            name = docSnapshot['restaurantName'];
            email = docSnapshot['email'];
            school = docSnapshot['selectedUniversity'];
            adress = docSnapshot['address'];
            isletme_adi = docSnapshot['restaurantName'];
          });

          // Load profile image using the URL from Firestore
          final profileImageUrl = docSnapshot['profileImageUrl'];
          setState(() {
            imageUrl = profileImageUrl;
          });
        }
      } catch (e) {
        print('Failed to load profile data: $e');
      }
    }
  }

  int selectedIndex = 0; // selectedIndex değişkeni burada tanımlanmalı
  final pages = [
    IlkBakis(),
    IkinciOrta(),
    ProfilePage(),
  ];

  void onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: WaterDropNavBar(
        backgroundColor: Colors.white,
        waterDropColor: Color(0xFFEA004B),
        selectedIndex: selectedIndex,
        onItemSelected: onItemSelected, // onItemSelected metodunu buraya ekle
        barItems: [
          BarItem(
            filledIcon: Icons.home,
            outlinedIcon: Icons.home_outlined,
          ),
          BarItem(
            filledIcon: Icons.food_bank,
            outlinedIcon: Icons.food_bank_outlined,
          ),
          BarItem(
            filledIcon: Icons.person,
            outlinedIcon: Icons.person_outlined,
          ),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
