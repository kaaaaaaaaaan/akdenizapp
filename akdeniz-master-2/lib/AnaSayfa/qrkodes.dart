import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isProcessed = false; // İşlem yapıldı mı kontrolü için değişken

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Kod: ${result!.code}')
                  : const Text('QR kodu taratın'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessed) {
        setState(() {
          result = scanData;
          isProcessed = true; // İşlem yapıldı olarak işaretleyin
        });

        // QR koddan alınan orderId
        String orderId = result!.code ?? '';

        // Satış işlemini gerçekleştirmek için işleyici çağırılır
        bool success = await handleQrScan(orderId);

        // Tarama tamamlandıktan sonra kamerayı durdurun
        controller.pauseCamera();

        if (success) {
          // İşlem tamamlandıktan sonra kullanıcıya bir mesaj gösterin
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ürün başarıyla okundu!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Hata durumunda kullanıcıya bir mesaj gösterin
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: Bu ürün bu restorana ait değil.'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // İşlem tamamlandıktan sonra 1 saniye bekleyip geri dönün
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      }
    });
  }

  // Burada `handleQrScan` fonksiyonu yer alır
  Future<bool> handleQrScan(String orderId) async {
    try {
      // 1. Sipariş bilgilerini Firestore'dan çek
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderSnapshot.exists) {
        return false; // Sipariş bulunamadı
      }

      Map<String, dynamic> orderData =
          orderSnapshot.data() as Map<String, dynamic>;
      String customerId = orderData['customerId'];
      List<dynamic> items = orderData['items']; // Sepetteki ürünler

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Toplam fiyatı hesaplayın
        double totalPrice = 0.0;

        // Ürün miktarını ve ürünün restoran envanterinde olup olmadığını kontrol edin
        for (var item in items) {
          String productId = item['productId'];
          int purchasedQuantity = item['quantity'];
          double pricePerUnit = item['newPrice'];

          totalPrice += pricePerUnit * purchasedQuantity;

          DocumentReference productRef = FirebaseFirestore.instance
              .collection('restaurants')
              .doc(uid)
              .collection('products')
              .doc(productId);

          DocumentSnapshot productSnapshot = await productRef.get();

          if (!productSnapshot.exists) {
            return false; // Ürün bu restoranın envanterinde değilse, işlem iptal edilir
          }

          int currentQuantity = productSnapshot['quantity'];
          int newQuantity = currentQuantity - purchasedQuantity;

          if (newQuantity < 0) {
            return false; // Yetersiz stok, işlem iptal edilir
          }
        }

        // Ürünler restoran envanterinde ve yeterli miktarda mevcutsa devam edin
        for (var item in items) {
          String productId = item['productId'];
          int purchasedQuantity = item['quantity'];

          DocumentReference productRef = FirebaseFirestore.instance
              .collection('restaurants')
              .doc(uid)
              .collection('products')
              .doc(productId);

          int currentQuantity = (await productRef.get())['quantity'];
          int newQuantity = currentQuantity - purchasedQuantity;

          await productRef.update({'quantity': newQuantity});
        }

        // Satış tarihini oluşturun
        Timestamp saleDate = Timestamp.now(); // Tarih ve zaman damgası

        // 2. Satış verilerini işletme sahibinin Firestore kısmına kaydet
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(uid)
            .collection('sales')
            .add({
          'orderId': orderId,
          'items': items, // Tüm ürünleri kaydedin
          'totalPrice': totalPrice,
          'saleDate': saleDate,
          'customerId': customerId,
        });

        // 3. Genel satış dokümanına kaydedin
        await FirebaseFirestore.instance.collection('satislar').add({
          'orderId': orderId,
          'items': items, // Tüm ürünleri kaydedin
          'totalPrice': totalPrice,
          'saleDate': saleDate,
          'customerId': customerId,
          'restaurantId': uid,
        });

        // 4. Müşterinin Firestore kısmına kaydedin
        await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .collection('sales')
            .add({
          'orderId': orderId,
          'items': items, // Tüm ürünleri kaydedin
          'totalPrice': totalPrice,
          'saleDate': saleDate,
        });

        return true; // İşlem başarılı
      }
    } catch (e) {
      print('Failed to complete sale: $e');
      return false; // İşlem başarısız
    }
    return false; // İşlem başarısız
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
