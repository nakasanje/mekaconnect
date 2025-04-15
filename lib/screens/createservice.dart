import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meka_app/models/Servicerequest.dart';
import 'package:meka_app/screens/viewswevice.dart';

class CreateServiceRequestScreen extends StatefulWidget {
  const CreateServiceRequestScreen({super.key});

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

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _getCurrentLocation();
  }

  void _onTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId("selected_location"),
          position: location,
        ),
      };
    });

    final address =
        await _getAddressFromLatLng(location.latitude, location.longitude);
    setState(() {
      _locationController.text = address;
    });
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String suburb = data['address']['suburb'] ?? '';
      String city = data['address']['city'] ?? data['address']['town'] ?? '';
      String road = data['address']['road'] ?? '';
      return '$road, $suburb, $city';
    } else {
      return 'Location unknown';
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in')),
        );
        return;
      }

      final serviceRequest = ServiceRequest(
        userId: user.uid,
        serviceType: _serviceTypeController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        status: 'Pending',
        requestId:
            FirebaseFirestore.instance.collection('serviceRequests').doc().id,
      );

      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(serviceRequest.requestId)
          .set(serviceRequest.toMap());

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
      setState(() {
        _selectedLocation = null;
        _markers.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
              SizedBox(
                height: 250,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0.3476, 32.5825), // Kampala default
                    zoom: 14,
                  ),
                  markers: _markers,
                  onTap: _onTap,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration:
                    const InputDecoration(labelText: 'Selected Location'),
                validator: (value) =>
                    value!.isEmpty ? 'Select a location' : null,
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
