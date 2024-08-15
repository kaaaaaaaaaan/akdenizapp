import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class Product {
  String id; // Benzersiz ID alanı eklendi
  String productName;
  double oldPrice;
  double newPrice;
  int quantity;

  Product({
    required this.id, // ID parametresi eklendi
    required this.productName,
    required this.oldPrice,
    required this.newPrice,
    required this.quantity,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Product(
      id: doc.id, // Firestore'dan gelen ID'yi alıyoruz
      productName: data['productName'] ?? '',
      oldPrice: data['oldPrice'] ?? 0.0,
      newPrice: data['newPrice'] ?? 0.0,
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'quantity': quantity,
    };
  }
}

// Ürün verisi ekleme
Future<void> addProduct(
    String productName, double oldPrice, double newPrice, int quantity) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;

    // UUID oluşturma
    var uuid = Uuid();
    String productId = uuid.v4();

    // Ürün ismi için herhangi bir validation veya sınırlama yok
    Product product = Product(
      id: productId, // UUID ile oluşturulan ID'yi kullanıyoruz
      productName: productName, // Özel karakterler, boşluklar vb. izin verilir
      oldPrice: oldPrice,
      newPrice: newPrice,
      quantity: quantity,
    );

    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(uid)
        .collection('products')
        .doc(productId) // Ürün ID'si olarak benzersiz ID kullanıyoruz
        .set(product.toFirestore());
  } else {
    throw Exception('Şu anda giriş yapılmış bir kullanıcı yok.');
  }
}

// Ürün verisi çekme
Future<List<Product>> getProducts() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String uid = user.uid;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(uid)
        .collection('products')
        .get();

    return querySnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  } else {
    throw Exception('Şu anda giriş yapılmış bir kullanıcı yok.');
  }
}
