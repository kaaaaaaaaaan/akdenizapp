import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:topluluk_uygulama_app/Sayfalar/ilk_sayfa.dart';
import 'package:topluluk_uygulama_app/Sayfalar/profil_page.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

class AnaScaffold extends StatefulWidget {
  const AnaScaffold({super.key});

  @override
  State<AnaScaffold> createState() => _AnaScaffoldState();
}

class _AnaScaffoldState extends State<AnaScaffold> {
  final PageController pageController = PageController();
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    pageController.animateToPage(
      selectedIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final user = auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(user.uid)
          .get();
      setState(() {
        profileImageUrl = userDoc['profile_image_url'] ?? '';
        organization = userDoc['organization'] ?? '';
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        children: [
          IlkSayfa(),
          ProfilPage(),
        ],
      ),
      bottomNavigationBar: WaterDropNavBar(
        backgroundColor: Colors.white,
        onItemSelected: onItemTapped,
        selectedIndex: selectedIndex,
        barItems: [
          BarItem(
            filledIcon: Icons.add_rounded,
            outlinedIcon: Icons.add_outlined,
          ),
          BarItem(
            filledIcon: Icons.settings_rounded,
            outlinedIcon: Icons.settings_outlined,
          ),
        ],
      ),
    );
  }
}
