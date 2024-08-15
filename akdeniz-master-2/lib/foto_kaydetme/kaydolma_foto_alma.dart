import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

import 'package:sonartiksonnnnnn/firebase/firebase_toptan_kayit_islemleri.dart';
import 'package:sonartiksonnnnnn/googlemaps/google_maps_sayfa.dart';
import 'package:sonartiksonnnnnn/kaydol/kaydol_ilk_sayfa.dart';

class KaydolmaFotoAlma extends StatefulWidget {
  @override
  _KaydolmaFotoAlmaState createState() => _KaydolmaFotoAlmaState();
}

class _KaydolmaFotoAlmaState extends State<KaydolmaFotoAlma> {
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
          _errorMessage = 'Resim seçilmedi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Resim seçme sırasında hata oluştu: $e';
      });
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Kare kırpma için
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

  Future<void> _submit() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Kaydetmeden önce bir resim seçmelisiniz.';
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Kayıt işlemi
        print('Seçilen Resim: ${_image!.path}');

        await register(
          restaurantNameController.text,
          emailController.text,
          passwordController.text,
          onay,
          selectedUniversity!,
          address,
          currentPosition,
          _image!,
          context,
        );

        // Kayıt başarılıysa bir sonraki sayfaya geçiş yap
      } catch (e) {
        setState(() {
          _errorMessage = 'Kayıt sırasında bir hata oluştu: $e';
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
        title: Text('İşletme İçin Resim Yükleyin'),
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
                child: Text('Galeriden Resim Seçin'),
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
