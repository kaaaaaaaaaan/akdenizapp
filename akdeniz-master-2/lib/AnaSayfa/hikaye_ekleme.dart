import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:story_view/story_view.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  Future<void> _addStory(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        File imageFile = File(croppedFile.path);

        try {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String uid = user.uid;
            String fileName =
                'story_${DateTime.now().millisecondsSinceEpoch}.jpg';

            // Firebase Storage'a yükle
            Reference storageRef =
                FirebaseStorage.instance.ref().child('stories/$fileName');
            await storageRef.putFile(imageFile);
            String downloadUrl = await storageRef.getDownloadURL();

            CollectionReference restaurantStoriesRef = FirebaseFirestore
                .instance
                .collection('restaurants')
                .doc(uid)
                .collection('stories');
            CollectionReference globalStoriesRef =
                FirebaseFirestore.instance.collection('stories');

            DocumentReference newStoryRef = restaurantStoriesRef.doc();
            DocumentReference newGlobalStoryRef = globalStoriesRef.doc();

            Map<String, dynamic> storyData = {
              'imageUrl': downloadUrl,
              'timestamp': FieldValue.serverTimestamp(),
              'uid': uid,
              'storyId': newStoryRef.id,
              'watched': false, // Hikaye izleme durumu
            };

            // Hem restaurants collection'a hem de global stories collection'a ekle
            await newStoryRef.set(storyData);
            await newGlobalStoryRef.set({
              ...storyData,
              'restaurantId': uid,
            });

            print("Hikaye başarıyla eklendi.");
          }
        } catch (e) {
          print("Hikaye ekleme hatası: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1));
        },
        child: Container(
          height: MediaQuery.of(context).size.height / 8,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _addStory(context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.0),
                  width: MediaQuery.of(context).size.height /
                      9, // Daire boyutunu küçülttüm
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: Icon(Icons.add,
                      color: Colors.redAccent,
                      size: 30), // İkon boyutunu küçülttüm
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No stories available"));
                    }

                    // Hikayeleri gruplara ayır
                    Map<String, List<QueryDocumentSnapshot>> groupedStories =
                        {};
                    snapshot.data!.docs.forEach((doc) {
                      if (groupedStories[doc['uid']] == null) {
                        groupedStories[doc['uid']] = [];
                      }
                      groupedStories[doc['uid']]!.add(doc);
                    });

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: groupedStories.keys.length,
                      itemBuilder: (context, index) {
                        String uid = groupedStories.keys.elementAt(index);
                        var userStories = groupedStories[uid]!;
                        var storyData =
                            userStories.first.data() as Map<String, dynamic>;
                        bool watched = storyData.containsKey('watched')
                            ? storyData['watched']
                            : false;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StoryDisplayScreen(stories: userStories),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal:
                                        4.0), // Margin değerlerini optimize ettim
                                width: MediaQuery.of(context).size.height /
                                    9, // Daire boyutunu küçülttüm
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: watched
                                          ? Colors.grey
                                          : Colors.redAccent,
                                      width: 2),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: storyData[
                                            'imageUrl'], // Kullanıcının ilk hikayesi
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('restaurants')
                                    .doc(uid)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      "Loading...",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black),
                                    );
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Text(
                                      "Error",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red),
                                    );
                                  }

                                  return Text(
                                    snapshot.data!['restaurantName'],
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryDisplayScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;

  const StoryDisplayScreen({required this.stories, super.key});

  @override
  _StoryDisplayScreenState createState() => _StoryDisplayScreenState();
}

class _StoryDisplayScreenState extends State<StoryDisplayScreen> {
  final StoryController _storyController = StoryController();
  late List<StoryItem> _storyItems = [];
  late String restaurantName = '';

  @override
  void initState() {
    super.initState();
    _loadStories();
    _getRestaurantName(widget.stories.first['uid']);
  }

  Future<void> _loadStories() async {
    List<StoryItem> storyItems = widget.stories.map((doc) {
      return StoryItem.pageImage(
        url: (doc.data() as Map<String, dynamic>)['imageUrl'],
        controller: _storyController,
        caption: Text(timeago.format((doc['timestamp'] as Timestamp).toDate())),
      );
    }).toList();

    setState(() {
      _storyItems = storyItems;
    });
  }

  Future<void> _getRestaurantName(String uid) async {
    var doc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(uid)
        .get();
    setState(() {
      restaurantName = doc['restaurantName'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Dismissible(
        direction: DismissDirection.down,
        key: UniqueKey(),
        onDismissed: (_) {
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            StoryView(
              storyItems: _storyItems,
              controller: _storyController,
              inline: false,
              repeat: false,
              onComplete: () {
                Navigator.pop(context);
              },
            ),
            Positioned(
              top: 40,
              left: 10,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: BackButton(color: Colors.black),
                  ),
                  SizedBox(width: 8),
                  Text(
                    restaurantName,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }
}
