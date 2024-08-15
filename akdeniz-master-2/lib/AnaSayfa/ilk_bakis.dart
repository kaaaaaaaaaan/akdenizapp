import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/hikaye_ekleme.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/qrkodes.dart';

class IlkBakis extends StatefulWidget {
  const IlkBakis({super.key});

  @override
  _IlkBakisState createState() => _IlkBakisState();
}

class _IlkBakisState extends State<IlkBakis> {
  Map<String, Map<String, dynamic>> salesDataByMonth = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        print("Kullanıcı UID'si: $uid");

        QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(uid)
            .collection('sales')
            .orderBy('saleDate', descending: true)
            .get();

        print("Çekilen belge sayısı: ${salesSnapshot.docs.length}");

        Map<String, Map<String, dynamic>> groupedData = {};

        for (var doc in salesSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print("Belge verisi: $data");

          Timestamp saleTimestamp = data['saleDate'];
          DateTime saleDate = saleTimestamp.toDate();

          String monthYear = DateFormat('MMMM yyyy').format(saleDate);

          if (!groupedData.containsKey(monthYear)) {
            groupedData[monthYear] = {
              'totalSales': 0.0,
              'totalQuantity': 0,
              'salesDetails': [],
            };
          }

          double totalPrice = (data['totalPrice'] as num).toDouble();
          int quantity = data['items'][0]['quantity'];

          groupedData[monthYear]!['totalSales'] += totalPrice;
          groupedData[monthYear]!['totalQuantity'] += quantity;

          groupedData[monthYear]!['salesDetails'].add({
            'productName': data['items'][0]['productName'],
            'quantity': quantity,
            'totalPrice': totalPrice,
            'saleDate': saleDate,
          });
        }

        setState(() {
          salesDataByMonth = groupedData;
          isLoading = false;
        });
      } else {
        print("Kullanıcı oturumu açmamış.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshPage(BuildContext context) async {
    await _fetchSalesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => _refreshPage(context),
        child: Column(
          children: [
            const StorySection(), // 1/7'lik kısmı ekledik
            Expanded(
              flex: 6, // 6/7'lik kısım
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : salesDataByMonth.isEmpty
                      ? const Center(
                          child: Text("Bu ay için satış verisi bulunamadı."))
                      : ListView.builder(
                          itemCount: salesDataByMonth.length,
                          itemBuilder: (context, index) {
                            String monthYear =
                                salesDataByMonth.keys.elementAt(index);
                            Map<String, dynamic> salesInfo =
                                salesDataByMonth[monthYear]!;

                            return ExpansionTile(
                              title: Text(
                                monthYear,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              children: [
                                ListTile(
                                  title: Text(
                                    "Toplam Satış: ${salesInfo['totalSales']}₺",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Toplam Satılan Ürün: ${salesInfo['totalQuantity']} adet",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                ...salesInfo['salesDetails']
                                    .map<Widget>((sale) {
                                  return ListTile(
                                    title: Text("Ürün: ${sale['productName']}"),
                                    subtitle: Text(
                                      "Miktar: ${sale['quantity']} | Toplam Fiyat: ${sale['totalPrice']}₺",
                                    ),
                                    trailing: Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(sale['saleDate']),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEA004B),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRViewExample()),
          );
        },
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
