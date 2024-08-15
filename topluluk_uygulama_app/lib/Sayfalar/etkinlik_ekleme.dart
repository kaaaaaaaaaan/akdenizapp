import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:topluluk_uygulama_app/Sayfalar/google_maps_sayfasi.dart';

class EventForm extends StatefulWidget {
  @override
  _EventFormState createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  LatLng? _pickedLocation;
  List<File?> _eventImages = [];
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _pickLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerScreen()),
    );
    if (result != null && result is LatLng) {
      setState(() {
        _pickedLocation = result;
        _locationController.text =
            'Lat: ${result.latitude}, Lng: ${result.longitude}';
      });
    }
  }

  Future<void> _pickImage() async {
    if (_eventImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimum 4 fotoğraf ekleyebilirsiniz.')),
      );
      return;
    }

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Fotoğraf Kırp',
              toolbarColor: Colors.blue,
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
              _eventImages.add(file);
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

  Future<List<String>> _uploadImagesToStorage() async {
    List<String> imageUrls = [];

    for (var image in _eventImages) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('events')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putFile(image!);

        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yüklenirken bir hata oluştu: $e')),
        );
      }
    }

    return imageUrls;
  }

  void _scheduleEventDeletion(String eventId, DateTime eventDate) {
    final remainingSeconds = eventDate.difference(DateTime.now()).inSeconds;

    if (remainingSeconds > 0) {
      Timer(Duration(seconds: remainingSeconds), () async {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('events')
            .doc(eventId)
            .delete();
      });
    } else {
      // Etkinlik tarihi geçmişse hemen sil
      FirebaseFirestore.instance
          .collection('communities')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('events')
          .doc(eventId)
          .delete();
    }
  }

  void _addEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final imageUrls = await _uploadImagesToStorage();

      if (imageUrls.isNotEmpty) {
        final eventDate = DateFormat('yyyy-MM-dd HH:mm')
            .parse('${_dateController.text} ${_timeController.text}');

        await FirebaseFirestore.instance
            .collection('communities')
            .doc(user.uid) // Kullanıcının userId'sine göre doküman
            .collection('events') // Bu dokümanın altında events koleksiyonu
            .add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'date': _dateController.text,
          'time': _timeController.text,
          'location': _locationController.text,
          'latitude': _pickedLocation?.latitude,
          'longitude': _pickedLocation?.longitude,
          'image_urls': imageUrls,
          'uid': user.uid,
          'user_name': user.displayName ?? '',
          'eventDate': eventDate,
        }).then((docRef) {
          _scheduleEventDeletion(docRef.id, eventDate);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Etkinlik başarıyla eklendi.')),
          );
          Navigator.pop(context);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Etkinlik eklenirken bir hata oluştu: $error')),
          );
        }).whenComplete(() {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Resim yüklenemedi, lütfen tekrar deneyin.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen etkinlik adını giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Açıklaması',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen etkinlik açıklamasını giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Tarihi (YYYY-AA-GG)',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.blue),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen etkinlik tarihini giriniz';
                  }
                  try {
                    DateFormat('yyyy-MM-dd').parseStrict(value);
                  } catch (e) {
                    return 'Lütfen geçerli bir tarih giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Saati (SS:DD)',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.access_time, color: Colors.blue),
                    onPressed: () => _selectTime(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen etkinlik saatini giriniz';
                  }
                  try {
                    DateFormat('HH:mm').parseStrict(value);
                  } catch (e) {
                    return 'Lütfen geçerli bir saat giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Konumu',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on, color: Colors.blue),
                    onPressed: () => _pickLocation(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen etkinlik konumunu giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _eventImages.map((image) {
                  return Stack(
                    children: [
                      Image.file(image!, height: 100, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _eventImages.remove(image);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _eventImages.length < 4 ? _pickImage : null,
                child: Text(_eventImages.isEmpty
                    ? 'Etkinlik Resmi Seç'
                    : 'Başka Fotoğraf Ekle'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _addEvent,
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text('Etkinlik Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
