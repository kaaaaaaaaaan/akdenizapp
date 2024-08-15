import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:topluluk_uygulama_app/Sayfalar/etkinlik_ekleme.dart';

class IlkSayfa extends StatefulWidget {
  @override
  State<IlkSayfa> createState() => _IlkSayfaState();
}

class _IlkSayfaState extends State<IlkSayfa> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Text(
          "+",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: EventForm(),
              );
            },
          );
        },
      ),
      appBar: AppBar(
        title: Text('Etkinlikler'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: StreamBuilder(
          stream: _getFutureEvents(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('Gelecek etkinlik bulunmamaktadır.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var event = snapshot.data!.docs[index];
                  return EventCard(event: event);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _refreshEvents() async {
    setState(() {});
  }

  Stream<QuerySnapshot> _getFutureEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('communities')
          .doc(user.uid)
          .collection('events')
          .orderBy('date', descending: false)
          .snapshots();
    }
    return const Stream.empty();
  }
}

class EventCard extends StatefulWidget {
  final DocumentSnapshot event;

  EventCard({required this.event});

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late Timer _timer;
  Duration _duration = Duration();

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(
        Duration(seconds: 1), (Timer t) => _calculateRemainingTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    var eventDate = DateFormat('yyyy-MM-dd HH:mm')
        .parse('${widget.event['date']} ${widget.event['time']}');
    var now = DateTime.now();
    setState(() {
      _duration = eventDate.difference(now);
    });
  }

  void _deleteEvent(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(user.uid)
          .collection('events')
          .doc(eventId)
          .delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var eventData = widget.event.data() as Map<String, dynamic>;
    var daysLeft = _duration.inDays;
    var hoursLeft = _duration.inHours % 24;
    var minutesLeft = _duration.inMinutes % 60;
    var secondsLeft = _duration.inSeconds % 60;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eventData.containsKey('image_urls') &&
              (eventData['image_urls'] as List).isNotEmpty)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage((eventData['image_urls'] as List).first),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData['name'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tarih: ${eventData['date']}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Saat: ${eventData['time']}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Kalan Süre: $daysLeft gün, $hoursLeft saat, $minutesLeft dakika, $secondsLeft saniye',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteEvent(widget.event.id),
          ),
        ],
      ),
    );
  }
}
