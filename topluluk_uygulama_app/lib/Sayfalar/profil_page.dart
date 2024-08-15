import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:topluluk_uygulama_app/main.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

String profileImageUrl = '';
String organization = '';
final FirebaseAuth auth = FirebaseAuth.instance;

class _ProfilPageState extends State<ProfilPage> {
  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> changeProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oturumu açık değil.')),
      );
      return;
    }

    try {
      // Galeriden resim seçme
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Henüz bir resim seçilmedi.')),
        );
        return;
      }

      // Resmi kırpma
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğraf Kırp',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resim kırpma işlemi iptal edildi.')),
        );
        return;
      }

      final file = File(croppedFile.path);
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5 MB

      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya boyutu 5 MB\'yi geçemez.')),
        );
        return;
      }

      // Firebase Storage'a yükleme
      final ref =
          storage.ref().child('profile_images').child('${user.uid}.jpg');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'da güncelleme
      await firestore.collection('communities').doc(user.uid).update({
        'profile_image_url': downloadUrl,
      });

      // Local state güncelleme
      setState(() {
        profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profil fotoğrafı başarıyla güncellendi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
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

  Future<void> changeOrganization(BuildContext context) async {
    final user = auth.currentUser;
    if (user != null) {
      String? newName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String tempName = "";
          return AlertDialog(
            title: const Text('Yeni Organizasyon İsmi Girin'),
            content: TextField(
              onChanged: (value) {
                tempName = value;
              },
              decoration:
                  const InputDecoration(hintText: "Yeni Organizasyon İsmi"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('İptal'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Kaydet'),
                onPressed: () {
                  Navigator.of(context).pop(tempName);
                },
              ),
            ],
          );
        },
      );

      if (newName != null && newName.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('communities')
              .doc(user.uid)
              .update({'organization': newName});
          setState(() {
            organization = newName;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Organizasyon ismi başarıyla güncellendi: $newName')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Organizasyon ismi güncellenemedi: $e')),
          );
        }
      }
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılamadı: $e')),
      );
    }
  }

  Future<void> changePassword(BuildContext context) async {
    final user = auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Şifre sıfırlama e-postası gönderildi: ${user.email}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Şifre sıfırlama e-postası gönderilemedi: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Kullanıcı oturumu açık değil veya e-posta adresi bulunamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Sayfası'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () => signOut(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProfileData, // Sayfayı yenileme işlevi
        child: ListView(
          // RefreshIndicator çalışabilmesi için ListView kullanıyoruz
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    organization.isNotEmpty
                        ? organization
                        : 'Organizasyon Adı Yükleniyor...',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ProfilButon(
                    isim: "Organizasyon İsmini Değiştir",
                    func: () => changeOrganization(context),
                  ),
                  ProfilButon(
                    isim: "Şifre Değiştir",
                    func: () => changePassword(context),
                  ),
                  ProfilButon(
                    isim: "Profil Fotoğrafı Değiştir",
                    func: () => changeProfileImage(context),
                  ),
                  ProfilButon(
                    isim: "Çıkış Yap",
                    func: () => signOut(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilButon extends StatelessWidget {
  final String isim;
  final VoidCallback func;
  const ProfilButon({super.key, required this.isim, required this.func});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: func,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF5B75F0),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              isim,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
