import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/models/user.dart';
import 'package:meka_app/screens/userdetailspage.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isFetching = true;
  bool _userDetailsExist = false;
  String _userPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() => _isFetching = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isFetching = false);
      return;
    }

    _userPhoneNumber = user.phoneNumber ?? '';

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final userModel = UserModel.fromMap(docSnapshot.data()!);
        _nameController.text = userModel.name;
        _userDetailsExist = true;
      } else {
        _userDetailsExist = false;
      }
    } catch (e) {
      _showSnackBar('Error fetching details: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _saveUserDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not found.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final userModel = UserModel(
      uid: user.uid,
      name: _nameController.text.trim(),
      phone: _userPhoneNumber, // Use the phone number fetched from Firebase
      role: 'user', // Set role to 'user' for the account screen
    );

    try {
      await _firestore.collection('users').doc(user.uid).set(
            userModel.toMap(),
            SetOptions(merge: true),
          );

      _showSnackBar('Account details saved successfully!');
      setState(() {
        _userDetailsExist = true;
      });
    } catch (e) {
      _showSnackBar('Error saving details: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: _isFetching
            ? const Center(child: CircularProgressIndicator())
            : _userDetailsExist
                ? const UserDetailsPage()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Please fill in your details',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              icon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Phone number is automatically shown, not editable
                          TextFormField(
                            controller:
                                TextEditingController(text: _userPhoneNumber),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              icon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            enabled: false, // Disable editing the phone number
                          ),
                          const SizedBox(height: 30),
                          // Save Button with Loading Indicator
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveUserDetails,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Save Details'),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
