import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meka_app/models/Servicerequest.dart';
import 'package:meka_app/screens/viewswevice.dart'; // Import the UserServiceRequestsScreen
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateServiceRequestScreen extends StatefulWidget {
  @override
  _CreateServiceRequestScreenState createState() =>
      _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState
    extends State<CreateServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _locationData = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getAddressFromLatLng();
  }

  Future<void> _getAddressFromLatLng() async {
    if (!mounted) return;
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      setState(() {
        _locationData = 'Location access denied!';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationData = 'Location access denied!';
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String nominatimUrl =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1';

    http.Response nominatimResponse = await http.get(Uri.parse(nominatimUrl));

    if (nominatimResponse.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(nominatimResponse.body);

      String suburb =
          data['address']['suburb'] ?? data['address']['hamlet'] ?? '';
      String city = data['address']['city'] ?? data['address']['town'] ?? '';
      String amenity =
          data['address']['amenity'] ?? data['address']['village'] ?? '';
      String road = data['address']['road'] ?? data['address']['footway'] ?? '';

      if (city.endsWith(' Capital City')) {
        city = city.replaceAll(' Capital City', '');
      }

      if (!mounted) return;
      setState(() {
        _locationData = "$suburb, $amenity, $road, $city.";
        _locationController.text = _locationData;
      });
    } else {
      setState(() {
        _locationData = 'Error fetching location data';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in')),
        );
        return;
      }

      final docRef =
          FirebaseFirestore.instance.collection('serviceRequests').doc();

      final serviceRequest = ServiceRequest(
        userId: user.uid,
        serviceType: _serviceTypeController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        status: 'Pending',
        requestId: docRef.id,
      );

      await docRef.set(serviceRequest.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request submitted!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserServiceRequestsScreen()),
      );

      _serviceTypeController.clear();
      _descriptionController.clear();
      _locationController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Service Request')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _serviceTypeController,
                decoration: const InputDecoration(labelText: 'Service Type'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter service type' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                enabled: false,
                validator: (value) =>
                    value!.isEmpty ? 'Location not found' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
