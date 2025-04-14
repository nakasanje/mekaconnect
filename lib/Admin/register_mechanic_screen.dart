import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/models/user.dart';

class MechanicRegistrationScreen extends StatefulWidget {
  const MechanicRegistrationScreen({super.key});

  @override
  State<MechanicRegistrationScreen> createState() =>
      _MechanicRegistrationScreenState();
}

class _MechanicRegistrationScreenState
    extends State<MechanicRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedRole = 'mechanic'; // Default role
  bool _isLoading = false;
  String? verificationId; // This will store the verification ID from Firebase
  bool _otpSent = false; // Flag to indicate if OTP has been sent

  // Send OTP to the mechanic's phone number
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();

      // Start phone number verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // If the phone is verified, sign in the user
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          _createMechanicUser(
              userCredential.user, _nameController.text.trim(), phone);
        },
        verificationFailed: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${error.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          // OTP is sent successfully
          setState(() {
            this.verificationId = verificationId;
            _otpSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to phone.')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verify OTP entered by the user
  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final otp = _otpController.text.trim();

      // Create a PhoneAuthCredential with the verificationId and OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      // Sign in the user with the credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Once verified, create the mechanic user in Firestore
      _createMechanicUser(userCredential.user, _nameController.text.trim(),
          _phoneController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to create mechanic in Firestore after successful phone number verification
  Future<void> _createMechanicUser(
      User? user, String name, String phone) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    final String uid = user.uid; // This is the new UID assigned to the mechanic
    final userModel = UserModel(
      uid: uid,
      name: name,
      phone: phone,
      role: _selectedRole,
    );

    // Save mechanic details to the 'users' collection in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userModel.toMap());

    // Save mechanic details to the 'mechanics' collection with additional mechanic-specific info
    await FirebaseFirestore.instance.collection('mechanics').doc(uid).set({
      'location':
          '', // Placeholder, you can modify later for mechanic's location
      'specialty':
          '', // Placeholder, you can modify later for mechanic's specialty
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mechanic registered successfully!')),
    );

    // Clear fields
    _nameController.clear();
    _phoneController.clear();
    _otpController.clear();

    // Reset form state and clear role
    setState(() {
      _selectedRole = 'mechanic';
      _otpSent = false;
    });

    // Reset the form
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              'Register New Mechanic',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
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
            if (_otpSent)
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.length < 6 ? 'Enter a valid OTP' : null,
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
              icon: const Icon(Icons.add),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
            )
          ],
        ),
      ),
    );
  }
}
