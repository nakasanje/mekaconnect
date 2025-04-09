// login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:meka_app/screens/userdetailspage.dart'; // Import UserDetailsPage

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _isOtpSent = false;
  bool _isLoading = false;

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _signInWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      _showSnackBar(
          'Please enter a valid 9-digit phone number (e.g., 7xxxxxxxx).');
      return;
    }

    setState(() => _isLoading = true);

    final String fullPhoneNumber = '+256$phone'; // Add country code

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            _checkIfMechanic(); // Check if the user is a mechanic
          } catch (e) {
            _showSnackBar('Error during automatic sign-in: ${e.toString()}');
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          _showSnackBar('OTP sent to $fullPhoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred: ${e.toString()}');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        _checkIfMechanic(); // After OTP verification, check if the user is a mechanic
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'invalid-verification-code') {
        _showSnackBar('Invalid OTP. Please try again.');
      } else {
        _showSnackBar('OTP verification failed: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
          'An error occurred during OTP verification: ${e.toString()}');
    }
  }

  // Check if the user is a mechanic
  Future<void> _checkIfMechanic() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'];
      if (role == 'mechanic') {
        // Navigate to the UserDetailsPage if the user is a mechanic
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDetailsPage()),
        );
      } else {
        // Navigate to home or other screen for normal users
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/phone.jpg', height: 100),
                const SizedBox(height: 20),
                Text(
                  'Welcome to MechaConnect!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _isOtpSent ? 'Enter the OTP' : 'Sign In with Phone Number',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 40),
                if (!_isOtpSent) _buildPhoneInputSection(theme),
                if (_isOtpSent) _buildOtpInputSection(theme),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '7xxxxxxxx',
            prefixText: '+256 ',
            prefixStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            prefixIcon:
                Icon(Icons.phone_android, color: theme.colorScheme.primary),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            filled: true,
            fillColor: theme.colorScheme.primary.withOpacity(0.05),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _signInWithPhone,
          child: const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'OTP Code',
            hintText: 'Enter the 6-digit code',
            prefixIcon:
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            filled: true,
            fillColor: theme.colorScheme.primary.withOpacity(0.05),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: const Text('Verify OTP'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
