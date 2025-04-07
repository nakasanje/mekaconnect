import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/screens/userdetailspage.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

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
    setState(() {
      _isFetching = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      // Handle user not logged in
      setState(() {
        _isFetching = false;
      });
      return;
    }

    _userPhoneNumber = user.phoneNumber ?? 'No phone number available';

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _userDetailsExist = true; // User details exist in Firestore
        _nameController.text = data?['name'] ?? '';
        _emailController.text = data?['email'] ?? '';
      } else {
        _userDetailsExist = false; // User details don't exist
      }
    } catch (e) {
      // Error fetching user details
      _showSnackBar('Error fetching details: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _saveUserDetails() async {
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not found. Cannot save details.', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': user.phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );

      _showSnackBar('Account details saved successfully!');
      setState(() {
        _userDetailsExist = true; // Mark that details are now saved
      });
    } catch (e) {
      _showSnackBar('Error saving details: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).snackBarTheme.backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: _isFetching
            ? const Center(
                child: CircularProgressIndicator()) // Show loading spinner
            : _userDetailsExist
                ? UserDetailsPage() // Navigate to UserDetailsPage if data exists
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                                hintText: 'Enter your full name',
                                icon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email address',
                                icon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Save Button with Loading Indicator
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveUserDetails,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Save Details'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
