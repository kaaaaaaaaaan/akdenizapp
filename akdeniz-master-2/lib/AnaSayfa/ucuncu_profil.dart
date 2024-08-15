import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonartiksonnnnnn/AnaDosya/profil_foto_degistirme_image_select/profil_foto_degistirme.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/anasayfa.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/firebase_komutlari/sifre_sifirlama.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/google_maps/adres_degistirme_google_maps.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/profil_yan_pages/gizlilik_politiks.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/profil_yan_pages/hakkimizda.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/profil_yan_pages/isletme_adi_degistirme.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/profil_yan_pages/sikca_sorulan_sorular.dart';
import 'package:sonartiksonnnnnn/AnaSayfa/ucuncu_profil_degerleri.dart/profil_butonlari.dart';
import 'package:sonartiksonnnnnn/main.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String imageUrl = ''; // Resim URL'si
  String name = ''; // İşletme adı
  String email = ''; // E-posta
  String school = ''; // Bölge
  String isletme_adi = ''; // İşletme adı
  String adress = ''; // Adres
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Sayfa yüklendiğinde profil verilerini yükle
  }

  Future<void> _loadProfileData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          imageUrl = docSnapshot['profileImageUrl'] ?? '';
          name = docSnapshot['restaurantName'] ?? '';
          email = docSnapshot['email'] ?? '';
          school = docSnapshot['selectedUniversity'] ?? '';
          isletme_adi = docSnapshot['restaurantName'] ?? '';
          adress = docSnapshot['address'] ?? '';
          _isLoading = false; // Yükleme işlemi bitti
        });
      }
    }
  }

  Future<void> _refreshPage() async {
    await _loadProfileData(); // Sayfa yenilendiğinde profil verilerini yeniden yükle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('İşletme Profili'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person, size: 70)
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        name,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tanitim(
                              deger: email,
                              tanitim_degeri: "E-mail",
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Tanitim(deger: school, tanitim_degeri: "Bölge"),
                            SizedBox(
                              height: 10,
                            ),
                            Tanitim(
                                deger: isletme_adi,
                                tanitim_degeri: "İşletme Adı"),
                            SizedBox(
                              height: 10,
                            ),
                            Tanitim(deger: adress, tanitim_degeri: "Adres")
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      ProfilButonlari(
                        ic_Deger: "Şifre Değiştir",
                        func: () {
                          sendPasswordResetEmail(context, email);
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "İşletme Resmi Değiştirme",
                        func: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      IsletmeProfilResmiDegistir()));
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "Adres Değiştir",
                        func: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AdresDegistirmeGoogleMaps(
                                      onAdresSecildi: (p0) {
                                        adress = p0;
                                      },
                                    )),
                          );
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "İşletme Adı Değiştirme",
                        func: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ChangeRestaurantNameForm()));
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "Hakkımızda",
                        func: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Hakkimizda()));
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "Gizlilik Politikası",
                        func: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GizlilikPolitiks()));
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "Sıkça Sorulan Sorular",
                        func: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SikcaSorulanSorular()));
                        },
                      ),
                      ProfilButonlari(
                        ic_Deger: "Çıkış Yap",
                        func: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => MyApp()),
                              (route) => false,
                            );
                          } catch (e) {
                            print("Çıkış yapma hatası: $e");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class Tanitim extends StatelessWidget {
  final String deger;
  final String tanitim_degeri;
  const Tanitim({super.key, required this.deger, required this.tanitim_degeri});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
        ),
        Text(
          overflow: TextOverflow.ellipsis,
          "${tanitim_degeri}: ",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color.fromARGB(255, 236, 36, 99)),
        ),
        Text(
          deger.length > 25 ? '${deger.substring(0, 25)}...' : deger,
          style: TextStyle(fontSize: 16),
        )
      ],
    );
  }
}
