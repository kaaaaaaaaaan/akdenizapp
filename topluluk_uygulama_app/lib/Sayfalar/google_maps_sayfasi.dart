import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  LatLng currentPosition = LatLng(36.8969, 30.7133); // Varsayılan koordinatlar
  String address = 'Adres alınıyor...';
  bool _isMoving = false;
  bool _locationPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationPermissionGranted = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationPermissionGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionGranted = false;
      });
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
    });

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
    _updateAddress(currentPosition);

    if (_controller != null) {
      _controller!.animateCamera(CameraUpdate.newLatLng(currentPosition));
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    final String apiKey =
        'AIzaSyA85LxqsOdG_voJPBL8d0SqOcGLB_cELp4'; // Replace with your API key
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        setState(() {
          address = data['results'][0]['formatted_address'];
        });
      } else {
        setState(() {
          address = 'Adres bulunamadı';
        });
      }
    } else {
      setState(() {
        address = 'Adres alınamadı';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _controller!.animateCamera(CameraUpdate.newLatLng(currentPosition));
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _isMoving = true;
      currentPosition = position.target;
    });
  }

  void _onCameraMoveStarted() {
    setState(() {
      _isMoving = true;
    });
  }

  void _onCameraIdle() {
    setState(() {
      _isMoving = false;
    });
    _updateAddress(currentPosition);
  }

  void _onConfirmLocation() {
    Navigator.pop(context, currentPosition);
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konum Seç'),
      ),
      body: _locationPermissionGranted
          ? Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: currentPosition,
                    zoom: 15,
                  ),
                  onCameraMove: _onCameraMove,
                  onCameraMoveStarted: _onCameraMoveStarted,
                  onCameraIdle: _onCameraIdle,
                  myLocationButtonEnabled: true,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Yazılı adresinizi haritayı oynatarak seçebilirsiniz',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 10),
                        Text(
                          address,
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
                    onPressed: _isMoving ? null : _onConfirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMoving ? Colors.grey : Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Doğrula',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Konum izinleri verilmemiş. Lütfen ayarlardan izin verin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openAppSettings,
                    child: Text('Ayarları Aç'),
                    style: ElevatedButton.styleFrom(
                      iconColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
