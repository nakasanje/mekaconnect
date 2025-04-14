import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meka_app/mechanic/view.dart';

class MechanicProfileUpdateScreen extends StatefulWidget {
  const MechanicProfileUpdateScreen({super.key});

  @override
  State<MechanicProfileUpdateScreen> createState() =>
      _MechanicProfileUpdateScreenState();
}

class _MechanicProfileUpdateScreenState
    extends State<MechanicProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  // Check if the mechanic profile is already updated or not
  Future<void> _checkProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Fetch the mechanic-specific data from the 'mechanics' collection
      final mechanicDoc = await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(uid)
          .get();
      if (mechanicDoc.exists) {
        final mechanicData = mechanicDoc.data();
        if (mechanicData?['location'] != null &&
            mechanicData?['specialty'] != null) {
          // Profile is already updated, navigate to the view profile screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MechanicProfileViewScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking profile: ${e.toString()}')),
        );
      }
    }

    // Load user details to pre-fill the name and phone
    _loadMechanicProfile();
  }

  // Load user and mechanic profile data to pre-fill the fields
  Future<void> _loadMechanicProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Fetch the user data from the 'users' collection to pre-fill name and phone
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        _nameController.text = userData?['name'] ?? '';
        _phoneController.text = userData?['phone'] ?? '';
      }

      // Fetch the mechanic-specific data from the 'mechanics' collection
      final mechanicDoc = await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(uid)
          .get();
      if (mechanicDoc.exists) {
        final mechanicData = mechanicDoc.data();
        _locationController.text = mechanicData?['location'] ?? '';
        _specialtyController.text = mechanicData?['specialty'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  // Update profile in both users and mechanics collections
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      // Update the user information in the 'users' collection (name and phone)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      // Update the mechanic-specific information in the 'mechanics' collection (location, specialty)
      await FirebaseFirestore.instance.collection('mechanics').doc(uid).set({
        'location': _locationController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }

      // Navigate to the View Profile screen after successful update
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MechanicProfileViewScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.length < 9
                    ? 'Enter valid phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter specialty' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
