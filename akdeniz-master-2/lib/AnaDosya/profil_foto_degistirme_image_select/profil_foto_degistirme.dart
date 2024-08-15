import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IsletmeProfilResmiDegistir extends StatefulWidget {
  @override
  _IsletmeProfilResmiDegistirState createState() =>
      _IsletmeProfilResmiDegistirState();
}

class _IsletmeProfilResmiDegistirState
    extends State<IsletmeProfilResmiDegistir> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _pickAndCropImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Fotoğrafı kırp
        final croppedFile = await _cropImage(File(pickedFile.path));

        if (croppedFile != null) {
          setState(() {
            _image = croppedFile;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = 'Resim kırpılamadı.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Resim Seçilmedi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Resim Seçerken Hata yaşandı: $e';
      });
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Kare kırpma
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Resmi Kırp',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Resmi Kırp',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _updateProfileImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu açık değil.';

      String userId = user.uid;

      // Firestore'dan mevcut profil resminin URL'sini al
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        final oldImageUrl = data?['profileImageUrl'];

        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          // Eski resmi Firebase Storage'dan sil
          final oldImageRef = FirebaseStorage.instance.refFromURL(oldImageUrl);
          await oldImageRef.delete();
        }
      }

      // Yeni resmi yükle ve URL'yi al
      String newImageUrl = await _uploadNewImage(userId);

      // Firestore'da profileImageUrl'yi güncelle
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(userId)
          .update({'profileImageUrl': newImageUrl});
    } catch (e) {
      throw 'Profil resmi güncellenemedi: $e';
    }
  }

  Future<String> _uploadNewImage(String userId) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('restaurants/$userId/profileImage.jpg');

    await storageRef.putFile(_image!);
    return await storageRef.getDownloadURL();
  }

  void _submit() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Kaydetmeden önce resim seçin.';
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _updateProfileImage();
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Güncelleme hatası: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Resmini Değiştir'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null ? Text('Resim Seçin') : Image.file(_image!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickAndCropImage,
                child: Text('Galeriden resim seçin'),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text('Onayla'),
                    ),
              if (_errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
