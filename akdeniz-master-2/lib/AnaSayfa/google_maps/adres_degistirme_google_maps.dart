import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdresDegistirmeGoogleMaps extends StatefulWidget {
  final Function(String) onAdresSecildi;

  AdresDegistirmeGoogleMaps({required this.onAdresSecildi});

  @override
  _AdresDegistirmeGoogleMapsState createState() =>
      _AdresDegistirmeGoogleMapsState();
}

class _AdresDegistirmeGoogleMapsState extends State<AdresDegistirmeGoogleMaps> {
  GoogleMapController? _controller;
  LatLng mevcutKonum = LatLng(36.8969, 30.7133); // Başlangıç konumu (Antalya)
  String adres = 'Adres alınıyor...';
  bool haritaHareketEdiyor = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Sayfa yüklendiğinde cihazın konumunu alma işlemi başlatılır
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        adres = 'Konum servisleri devre dışı.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          adres = 'Konum izni reddedildi.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        adres = 'Konum izni kalıcı olarak reddedildi.';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      mevcutKonum = LatLng(position.latitude, position.longitude);
      haritaHareketEdiyor = false;
    });

    _adresiGuncelle(mevcutKonum);

    if (_controller != null) {
      _controller!.animateCamera(CameraUpdate.newLatLng(mevcutKonum));
    }
  }

  Future<void> _adresiGuncelle(LatLng position) async {
    final String apiKey =
        "AIzaSyCLcV_vTIOjPM3--ErqiuUKf6Y3Xu0QF6A"; // Google Maps API anahtarınızı buraya ekleyin
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];
        String mahalle = '';
        for (var component in addressComponents) {
          if (component['types'].contains('sublocality_level_1')) {
            mahalle = component['long_name'];
            break;
          }
        }
        setState(() {
          adres = '${data['results'][0]['formatted_address']}, $mahalle';
        });
      } else {
        setState(() {
          adres = 'Adres bulunamadı';
        });
      }
    } else {
      setState(() {
        adres = 'Adres alınamadı';
      });
    }
  }

  void _haritaOlusturuldugunda(GoogleMapController controller) {
    _controller = controller;
    _controller!.animateCamera(CameraUpdate.newLatLng(
        mevcutKonum)); // Harita ilk yüklendiğinde mevcut konuma gider
  }

  void _kameraHareketEttiginde(CameraPosition position) {
    setState(() {
      haritaHareketEdiyor = true;
      mevcutKonum = position.target;
    });
  }

  void _kameraDurdugunda() {
    setState(() {
      haritaHareketEdiyor = false;
    });
    _adresiGuncelle(mevcutKonum); // Kamera durduğunda adresi günceller
  }

  void _konumuOnayla() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adres Onayı'),
          content: Text('Adresiniz bu mu?\n\n$adres'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // İptal butonu
              child: Text('Hayır'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Firestore'da adresi güncelleme
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(user.uid)
                      .update({'address': adres});
                }

                // Callback fonksiyonunu çağır ve önceki sayfaya dön
                widget.onAdresSecildi(adres);
                Navigator.pop(context);
              },
              child: Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konum Seç'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _haritaOlusturuldugunda,
            initialCameraPosition: CameraPosition(
              target: mevcutKonum,
              zoom: 15,
            ),
            onCameraMove: _kameraHareketEttiginde,
            onCameraIdle: _kameraDurdugunda,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red,
            ),
          ),
          Positioned(
            bottom: 150,
            left: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yazılı adresinizi haritayı oynatarak seçebilirsiniz',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (adres.isNotEmpty)
                    Text(
                      adres,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: haritaHareketEdiyor ? null : _konumuOnayla,
              style: ElevatedButton.styleFrom(
                backgroundColor: haritaHareketEdiyor ? Colors.grey : Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Onayla',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
