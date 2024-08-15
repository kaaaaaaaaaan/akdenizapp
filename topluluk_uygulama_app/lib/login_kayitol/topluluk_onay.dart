import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:topluluk_uygulama_app/ana_scaffold.dart';
import 'dart:async';

class VerifyCommunityPage extends StatefulWidget {
  const VerifyCommunityPage({super.key});

  @override
  _VerifyCommunityPageState createState() => _VerifyCommunityPageState();
}

class _VerifyCommunityPageState extends State<VerifyCommunityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkCommunityVerified();
    });
  }

  Future<void> _checkCommunityVerified() async {
    DocumentSnapshot snapshot =
        await _firestore.collection('communities').doc(_user?.uid).get();

    if (snapshot.exists) {
      bool? communityVerified = snapshot['topluluk_onay'];
      if (communityVerified ?? false) {
        _timer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AnaScaffold()),
          (Route<dynamic> route) => false,
        );
      }
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
        title: const Text('Topluluk Onayı'),
      ),
      body: const Center(
        child: Text('Topluluk onayı bekleniyor...'),
      ),
    );
  }
}
