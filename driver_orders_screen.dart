
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

class DriverOrdersScreen extends StatefulWidget {
  @override
  _DriverOrdersScreenState createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(Duration(minutes: 1));
      await _fetchDriverLocation();
      return mounted;
    });
  }
  double? driverLat;
  double? driverLng;
  bool filterByDistance = false;
  String cityFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
    _startAutoRefresh();
  }

  Future<void> _fetchDriverLocation() async {
    Location location = Location();
    var current = await location.getLocation();
    setState(() {
      driverLat = current.latitude;
      driverLng = current.longitude;
    });
  }

  bool isNearby(double reqLat, double reqLng) {
    if (!filterByDistance || driverLat == null || driverLng == null) return true;
    final distance = Geolocator.distanceBetween(driverLat!, driverLng!, reqLat, reqLng) / 1000;
    return distance <= 5.0;
  }

  bool matchesCity(String? city) {
    if (cityFilter.isEmpty) return true;
    return city?.toLowerCase().contains(cityFilter.toLowerCase()) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طلبات المشاوير')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _fetchDriverLocation,
                child: Text('🔄 تحديث موقعي'),
              ),
              Checkbox(
                value: filterByDistance,
                onChanged: (value) => setState(() => filterByDistance = value ?? false),
              ),
              Text('فقط الطلبات القريبة'),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'فلترة حسب المدينة'),
                  onChanged: (value) => setState(() => cityFilter = value),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ride_requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
          final AudioPlayer player = AudioPlayer();
          List<String> playedRequests = [];
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          player.play(AssetSource('notify.mp3'));
                final docs = snapshot.data!.docs.where((doc) {
            if (!playedRequests.contains(doc.id)) {
              player.play(AssetSource('notify.mp3'));
              playedRequests.add(doc.id);
            }
                  final data = doc.data() as Map<String, dynamic>;
                  final pickup = data['pickup'];
                  final city = data['city'];
                  return isNearby(pickup['lat'], pickup['lng']) && matchesCity(city);
                }).toList();

                if (docs.isEmpty) return Center(child: Text('لا يوجد طلبات مطابقة'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('الوجهة: ${data['destination']}'),
                      subtitle: Text('الموقع: ${data['pickup']['lat']}, ${data['pickup']['lng']}'),
                      trailing: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('ride_requests')
                              .doc(docs[index].id)
                              .update({'status': 'accepted'});
                        },
                        child: Text('قبول'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
