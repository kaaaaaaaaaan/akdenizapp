import 'package:flutter/material.dart';
import 'package:sonartiksonnnnnn/googlemaps/google_maps_sayfa.dart';

class RestaurantRegisterPage extends StatefulWidget {
  const RestaurantRegisterPage({super.key});

  @override
  _RestaurantRegisterPageState createState() => _RestaurantRegisterPageState();
}

final _formKey = GlobalKey<FormState>();
final restaurantNameController = TextEditingController();
final emailController = TextEditingController();
final passwordController = TextEditingController();
bool onay = false;
String? selectedUniversity;

class _RestaurantRegisterPageState extends State<RestaurantRegisterPage> {
  final List<String> _universities = [
    'Akdeniz Üniversitesi',
    'Boğaziçi Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'Orta Doğu Teknik Üniversitesi',
    'Bilkent Üniversitesi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Kayıt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: restaurantNameController,
                  decoration: const InputDecoration(labelText: 'Restoran Adı'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen restoran adını girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedUniversity,
                  items: _universities.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUniversity = newValue;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Üniversite'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir üniversite seçin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta adresini girin';
                    }
                    final emailRegExp = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegExp.hasMatch(value)) {
                      return 'Lütfen geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifreyi girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LocationPickerScreen(), // Yeni sayfanın widget'ı
                        ),
                      );
                    }
                  },
                  child: const Text('Kayıt Ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
