import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AddProductForm extends StatefulWidget {
  @override
  _AddProductFormState createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  String oldPrice = '';
  String newPrice = '';
  String quantity = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Text(
                "Ürün Ekleme",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.pink.shade400),
              ),
              SizedBox(height: 20),
              _buildTextField(
                'Ürün Adı',
                (value) => productName = value ?? '',
              ),
              _buildDecimalTextField(
                'Eski Fiyat',
                (value) => oldPrice = value ?? '',
                'Lütfen geçerli bir eski fiyat girin',
              ),
              _buildDecimalTextField(
                'Yeni Fiyat',
                (value) => newPrice = value ?? '',
                'Lütfen geçerli bir yeni fiyat girin',
              ),
              _buildIntTextField(
                'Adet',
                (value) => quantity = value ?? '',
                'Lütfen geçerli bir adet girin',
              ),
              SizedBox(height: 10),
              ShowModalsButonlari(
                func: () {
                  _submitForm();
                },
                ic_Deger: "Ürün Ekle",
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, Function(String?) onSaved,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFEA004B),
            ),
          ),
        ),
        keyboardType: keyboardType,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDecimalTextField(
      String labelText, Function(String?) onSaved, String validationMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFEA004B),
            ),
          ),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          final n = num.tryParse(value);
          if (n == null) {
            return validationMessage;
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildIntTextField(
      String labelText, Function(String?) onSaved, String validationMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFEA004B),
            ),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          final n = num.tryParse(value);
          if (n == null) {
            return validationMessage;
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      double parsedOldPrice = double.parse(oldPrice);
      double parsedNewPrice = double.parse(newPrice);
      int parsedQuantity = int.parse(quantity);

      try {
        await addProduct(
            productName, parsedOldPrice, parsedNewPrice, parsedQuantity);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün eklenemedi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addProduct(String productName, double oldPrice, double newPrice,
      int quantity) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Benzersiz bir ID oluşturun
      String productId = Uuid().v4();

      Product product = Product(
        productId: productId, // Benzersiz ID'yi burada kullanıyoruz
        productName: productName, // Özel karakterler serbest
        oldPrice: oldPrice,
        newPrice: newPrice,
        quantity: quantity,
      );

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(uid)
          .collection('products')
          .doc(productId) // Ürünü benzersiz ID ile kaydediyoruz
          .set(product.toFirestore());
    } else {
      throw Exception('Şu anda giriş yapılmış bir kullanıcı yok.');
    }
  }
}

class ShowModalsButonlari extends StatefulWidget {
  final Function() func;
  final String ic_Deger;
  const ShowModalsButonlari(
      {super.key, required this.func, required this.ic_Deger});

  @override
  State<ShowModalsButonlari> createState() => _ShowModalsButonlariState();
}

class _ShowModalsButonlariState extends State<ShowModalsButonlari> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.func,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: Color(0xFFEA004B), borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Text(
            widget.ic_Deger,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class Product {
  String productId;
  String productName;
  double oldPrice;
  double newPrice;
  int quantity;

  Product({
    required this.productId, // Benzersiz ID alanı eklendi
    required this.productName,
    required this.oldPrice,
    required this.newPrice,
    required this.quantity,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      productId: data['productId'] ?? '', // Firestore'dan alınan ID
      productName: data['productName'] ?? '',
      oldPrice: data['oldPrice'] ?? 0.0,
      newPrice: data['newPrice'] ?? 0.0,
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId, // Firestore'a kaydedilecek ID
      'productName': productName,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'quantity': quantity,
    };
  }
}
