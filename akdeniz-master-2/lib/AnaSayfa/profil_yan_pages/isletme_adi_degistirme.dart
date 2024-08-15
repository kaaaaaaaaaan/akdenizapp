import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeRestaurantNameForm extends StatefulWidget {
  @override
  _ChangeRestaurantNameFormState createState() =>
      _ChangeRestaurantNameFormState();
}

class _ChangeRestaurantNameFormState extends State<ChangeRestaurantNameForm> {
  final _formKey = GlobalKey<FormState>();
  String newRestaurantName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restoran Adını Değiştir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Yeni Restoran Adını Girin",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Restoran Adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink.shade400),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni bir restoran adı girin';
                  }
                  return null;
                },
                onSaved: (value) {
                  newRestaurantName = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await _updateRestaurantName(newRestaurantName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restoran adı başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restoran adı güncellenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateRestaurantName(String newName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(uid) // restaurantId olarak userId kullanılıyor
          .update({'restaurantName': newName});
    } else {
      throw Exception('Şu anda giriş yapılmış bir kullanıcı yok.');
    }
  }
}
