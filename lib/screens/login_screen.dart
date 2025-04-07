import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/screens/home_screen.dart';
import 'package:meka_app/screens/main_screen.dart'; // Assuming HomeScreen is the main logged-in screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _isOtpSent = false;
  bool _isLoading = false; // To show loading indicator

  // Helper to show SnackBars safely
  void _showSnackBar(String message) {
    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _signInWithPhone() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 9) {
      // Basic validation
      _showSnackBar(
          'Please enter a valid 9-digit phone number (e.g., 7xxxxxxxx).');
      return;
    }

    setState(() => _isLoading = true); // Start loading

    final String fullPhoneNumber = '+256$phone'; // Add country code

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification completed
          await _auth.signInWithCredential(credential);
          if (mounted) {
            // Navigate to HomeScreen after successful login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
          });
          _showSnackBar('OTP sent to $fullPhoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Can handle timeout if needed, maybe allow resend
          setState(() {
            _verificationId =
                verificationId; // Update verificationId for potential manual entry
          });
        },
        timeout: const Duration(seconds: 60), // Optional: Set timeout duration
      );
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}');
    } finally {
      // Ensure loading stops even if errors occur before codeSent/verificationFailed
      // Only stop loading if OTP wasn't successfully sent (it will stop naturally then)
      if (mounted && !_isOtpSent) {
        setState(() => _isLoading = false); // Stop loading
      } else if (mounted) {
        // If OTP was sent, the UI changes, so loading naturally stops for the phone input part
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      // OTP is usually 6 digits
      _showSnackBar('Please enter the 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true); // Start loading

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        // Navigate to HomeScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'invalid-verification-code') {
        _showSnackBar('Invalid OTP. Please try again.');
      } else {
        _showSnackBar('OTP verification failed: ${e.message}');
      }
    } catch (e) {
      _showSnackBar(
          'An error occurred during OTP verification: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Stop loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme for consistent styling
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Removed AppBar for a cleaner look, title is now in the body
      // appBar: AppBar(title: const Text('MechaConnect - Login')),
      body: SafeArea(
        // Ensures content doesn't overlap status bar/notches
        child: SingleChildScrollView(
          // Allows scrolling on smaller screens
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Increased padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make children fill width
              children: [
                const SizedBox(height: 40), // Space from top

                // Placeholder for Logo
                // Custom Logo Image
                Image.asset(
                  'assets/images/phone.jpg',
                  height: 100,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Welcome to MechaConnect!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isOtpSent ? 'Enter the OTP' : 'Sign In with Phone Number',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 40), // More space before form

                // Conditional UI for Phone Input or OTP Input
                if (!_isOtpSent)
                  _buildPhoneInputSection(theme, colorScheme)
                else
                  _buildOtpInputSection(theme, colorScheme),

                const SizedBox(height: 20), // Space below button/indicator

                // Loading Indicator centered
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 20), // Bottom space
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Builder for Phone Input Section
  Widget _buildPhoneInputSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '7xxxxxxxx', // Hint for format without country code
            prefixText: '+256 ', // Show country code visually
            prefixStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            prefixIcon: Icon(Icons.phone_android, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              borderSide: BorderSide.none, // Remove default border
            ),
            filled: true, // Add background fill
            fillColor: colorScheme.primary.withOpacity(0.05), // Light fill
          ),
          keyboardType: TextInputType.phone,
          enabled: !_isLoading, // Disable when loading
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Button color
              foregroundColor: colorScheme.onPrimary, // Text color
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0), // Button height
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Match input field
              ),
              textStyle: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          // Disable button when loading, otherwise call function
          onPressed: _isLoading ? null : _signInWithPhone,
          child: const Text('Send OTP'),
        ),
      ],
    );
  }

  // Widget Builder for OTP Input Section
  Widget _buildOtpInputSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional: Display the phone number OTP was sent to
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Text(
            'Enter the 6-digit code sent to +256${_phoneController.text.trim()}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'OTP Code',
            hintText: 'Enter the 6-digit code',
            prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.primary.withOpacity(0.05),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6, // Limit OTP input length
          enabled: !_isLoading, // Disable when loading
          textAlign: TextAlign.center, // Center OTP input
          style: theme.textTheme.titleLarge, // Make OTP digits larger
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              textStyle: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          // Disable button when loading, otherwise call function
          onPressed: _isLoading ? null : _verifyOtp,
          child: const Text('Verify OTP'),
        ),
        const SizedBox(height: 15),
        // Optional: Add a Resend OTP button
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  // Reset state to allow re-entering phone number if needed, or directly call _signInWithPhone again
                  // Option 1: Go back to phone input
                  // setState(() {
                  //   _isOtpSent = false;
                  //   _otpController.clear();
                  //   _verificationId = '';
                  // });
                  // Option 2: Resend OTP to the same number (more common)
                  _signInWithPhone(); // Call the send OTP function again
                },
          child: Text(
            'Resend Code',
            style: TextStyle(color: colorScheme.primary),
          ),
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
