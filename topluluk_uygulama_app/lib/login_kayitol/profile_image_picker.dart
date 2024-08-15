import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:topluluk_uygulama_app/login_kayitol/mail_onay.dart';

class ProfileImagePickerPage extends StatefulWidget {
  final String email;
  final String password;
  final String organization;

  const ProfileImagePickerPage({
    required this.email,
    required this.password,
    required this.organization,
    super.key,
  });

  @override
  _ProfileImagePickerPageState createState() => _ProfileImagePickerPageState();
}

class _ProfileImagePickerPageState extends State<ProfileImagePickerPage> {
  File? _image;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
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

        if (croppedFile != null) {
          final file = File(croppedFile.path);
          final fileSize = await file.length();
          const maxSize = 5 * 1024 * 1024; // 5 MB

          if (fileSize <= maxSize) {
            setState(() {
              _image = file;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dosya boyutu 5 MB\'yi geçemez.')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Henüz bir resim seçilmedi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçerken bir hata oluştu: $e')),
      );
    }
  }

  Future<String?> _uploadImageToStorage(User user) async {
    try {
      final ref =
          _storage.ref().child('profile_images').child('${user.uid}.jpg');
      final uploadTask = ref.putFile(_image!);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim yüklenirken bir hata oluştu: $e')),
      );
      return null;
    }
  }

  Future<void> _onConfirm() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir resim seçin.')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();

        final downloadUrl = await _uploadImageToStorage(user);

        if (downloadUrl != null) {
          await _firestore.collection('communities').doc(user.uid).set({
            'email': widget.email,
            'organization': widget.organization,
            'profile_image_url': downloadUrl,
            'onay': false,
            'topluluk_onay': false,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Kayıt başarılı, lütfen e-postanızı doğrulayın')),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => VerifyEmailPage()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarısız: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Resmi Seç'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? const Text('Henüz bir resim seçilmedi.')
                : CircleAvatar(
                    radius: 80,
                    backgroundImage: FileImage(_image!),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Galeriden Resim Seç'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onConfirm,
              child: const Text('Onayla'),
            ),
          ],
        ),
      ),
    );
  }
}
////
///
///
