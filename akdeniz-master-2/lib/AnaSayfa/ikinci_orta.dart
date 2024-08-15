import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class IkinciOrta extends StatefulWidget {
  const IkinciOrta({super.key});

  @override
  _IkinciOrtaState createState() => _IkinciOrtaState();
}

class _IkinciOrtaState extends State<IkinciOrta> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ürün Listesi"),
        actions: [
          IconButton(
            onPressed: () => _showAddProductBottomSheet(context),
            icon: Icon(
              Icons.add,
              size: 36,
              color: Color(0xFFEA004B),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: ProductsList(),
    );
  }

  void _showAddProductBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddProductForm();
      },
    );
  }
}

class ProductsList extends StatelessWidget {
  Future<void> _refreshProducts(BuildContext context) async {
    // Burada verileri yenilemek için işlemler yapabilirsiniz.
    // StreamBuilder otomatik olarak yeni veriyi çekecektir.
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshProducts(context),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('products')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Product product = Product.fromFirestore(doc);
              return ProductCard(product: product, docId: doc.id);
            }).toList(),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final String docId;

  const ProductCard({required this.product, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(context),
                ),
              ],
            ),
            Text(
              'Kalan Miktar: ${product.quantity}',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            Row(
              children: [
                Text(
                  '${product.oldPrice.toStringAsFixed(2)} ₺',
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  '${product.newPrice.toStringAsFixed(2)} ₺',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ürünü Sil'),
          content: Text('Bu ürünü silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: Text('Hayır'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Evet'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm) {
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('products')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                SizedBox(height: 20),
                _buildCloseKeyboardButton(),
                SizedBox(height: 20),
                ShowModalsButonlari(
                  func: () {
                    _submitForm();
                  },
                  ic_Deger: "Ürün Ekle",
                ),
                SizedBox(height: 20),
              ],
            ),
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
        textInputAction: TextInputAction.next,
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
        textInputAction: TextInputAction.next,
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
        textInputAction: TextInputAction.next,
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

  Widget _buildCloseKeyboardButton() {
    return ElevatedButton(
      onPressed: () {
        FocusScope.of(context).unfocus(); // Klavyeyi kapatır
      },
      style: ElevatedButton.styleFrom(),
      child: Text('Kapat'),
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
        productId: productId, // Benzersiz ID eklendi
        productName: productName,
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
  String productId; // Benzersiz ID alanı eklendi
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
    Map data = doc.data() as Map;
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
