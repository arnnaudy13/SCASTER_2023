import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;

  await Firebase.initializeApp().then((firebaseApp) {
    firebaseInitialized = true;
    print('Firebase initialized successfully.');
  }).catchError((error) {
    print('Firebase initialization failed: ${error.message}');
  });

  if (firebaseInitialized) {
    runApp(const MyApp());
  } else {
    print('Failed to initialize Firebase. Please check your connection and configuration.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: IoTScreen(data: {}),
    );
  }
}

// ignore: must_be_immutable
class IoTScreen extends StatefulWidget {
  Map<dynamic, dynamic> data;

  IoTScreen({Key? key, required this.data}) : super(key: key);

  @override
  _IoTScreenState createState() => _IoTScreenState();
}

class _IoTScreenState extends State<IoTScreen> {
  DatabaseReference dbRef = FirebaseDatabase.instance.reference().child('data');
  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    dbRef.onValue.listen((event) {
      Map data = event.snapshot.value as Map;
      data['key'] = event.snapshot.key;
      setState(() {
        widget.data = Map<dynamic, dynamic>.from(data);
      });
    });
  }

 Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, request the user to enable it.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try requesting permissions again.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can continue accessing the position of the device.
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  setState(() {
    latitude = position.latitude;
    longitude = position.longitude;
  });
}

 void _sendLocationToWhatsApp() async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    final String whatsappUrl = "http://wa.me/{emergency number}?text=${Uri.encodeFull('Here is my location: $googleMapsUrl')}";

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      print("Could not open WhatsApp.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SCASTER'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'generator',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.data['generator'] ?? 'off',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'switch',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.data['state']?.toString() ?? '1',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'location',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          Text(
              'Latitude: $latitude',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Longitude: $longitude',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
               onPressed: _sendLocationToWhatsApp,
              child: Text('Send Location to WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
