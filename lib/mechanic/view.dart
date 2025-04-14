import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/mechanic/update.dart';

class MechanicProfileViewScreen extends StatefulWidget {
  const MechanicProfileViewScreen({super.key});

  @override
  State<MechanicProfileViewScreen> createState() =>
      _MechanicProfileViewScreenState();
}

class _MechanicProfileViewScreenState extends State<MechanicProfileViewScreen> {
  String _name = '';
  String _phone = '';
  String _location = '';
  String _specialty = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMechanicProfile();
  }

  Future<void> _loadMechanicProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Fetch the user data from the 'users' collection
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        _name = userData?['name'] ?? 'N/A';
        _phone = userData?['phone'] ?? 'N/A';
      }

      // Fetch the mechanic-specific data from the 'mechanics' collection
      final mechanicDoc = await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(uid)
          .get();
      if (mechanicDoc.exists) {
        final mechanicData = mechanicDoc.data();
        _location = mechanicData?['location'] ?? 'N/A';
        _specialty = mechanicData?['specialty'] ?? 'N/A';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
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
      appBar: AppBar(
        title: const Text('View Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Name: $_name',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: $_phone',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: $_location',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Specialty: $_specialty',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to the update profile screen if needed
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MechanicProfileUpdateScreen(),
                        ),
                      );
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
