// login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Still needed if you might add features later
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/auth/verification.dart'; // Import Verification screen

// Removed unused import for UserDetailsPage
// import 'package:meka_app/screens/userdetailspage.dart';

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

  // Helper to safely update loading state
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  void _showSnackBar(String message) {
    // Ensure widget is still mounted before showing SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _signInWithPhone() async {
    final phone = _phoneController.text.trim();
    // Using 9 digits for Uganda prefix +256
    if (phone.isEmpty || phone.length != 9) {
      _showSnackBar(
          'Please enter a valid 9-digit phone number (e.g., 7xxxxxxxx).');
      return;
    }

    _setLoading(true);

    final String fullPhoneNumber = '+256$phone'; // Add country code

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _showSnackBar('Auto-verification successful. Logging in...');
          _setLoading(true); // Show loading during auto sign-in attempt
          try {
            // Sign in the user automatically
            final UserCredential userCredential =
                await _auth.signInWithCredential(credential);

            // **Correction 1: Navigate to Verification screen after auto-completion**
            if (userCredential.user != null && mounted) {
              print(
                  "Auto Verification Completed: Navigating to Verification screen.");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const Verification(),
                ),
              );
            } else if (mounted) {
              // Handle rare case where user is null after successful sign-in
              _showSnackBar(
                  'Auto sign-in completed but user data is unavailable.');
              _setLoading(false);
            }
          } on FirebaseAuthException catch (e) {
            _showSnackBar('Automatic sign-in failed: ${e.message}');
            _setLoading(false);
          } catch (e) {
            _showSnackBar('An error occurred during auto sign-in: $e');
            _setLoading(false);
          }
          // No finally needed here as navigation replaces screen or error stops loading.
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Phone number verification failed: ${e.message}');
          _setLoading(false); // Stop loading on failure
        },
        codeSent: (String verificationId, int? resendToken) {
          // Update state only if mounted
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true; // Show OTP input
              _isLoading = false; // Stop loading, wait for OTP
            });
            _showSnackBar('OTP sent to $fullPhoneNumber');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _showSnackBar('OTP auto-retrieval timed out.');
          // Update verificationId if component is still mounted
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showSnackBar('An error occurred initiating phone auth: ${e.toString()}');
      _setLoading(false); // Stop loading on error
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP.');
      return;
    }
    if (_verificationId.isEmpty) {
      _showSnackBar('Verification process error. Please request OTP again.');
      return;
    }

    _setLoading(true);

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // **Correction 2: Simplified navigation logic**
      // If sign-in is successful and widget is still mounted, navigate to Verification
      if (userCredential.user != null && mounted) {
        print(
            "Manual OTP Verification Success: Navigating to Verification screen.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const Verification(), // Navigate to Verification screen
          ),
        );
      } else if (mounted) {
        // This case is unlikely if signInWithCredential succeeded, but handles edge cases.
        _showSnackBar('Sign-in succeeded but user data is unavailable.');
        _setLoading(false);
      }
      // Removed the incorrect 'else' block that navigated back to LoginScreen
    } on FirebaseAuthException catch (e) {
      _setLoading(false); // Stop loading on error
      if (e.code == 'invalid-verification-code' ||
          e.code == 'session-expired') {
        _showSnackBar('Invalid or expired OTP. Please try again.');
      } else {
        _showSnackBar('OTP verification failed: ${e.message}');
      }
    } catch (e) {
      _setLoading(false); // Stop loading on error
      _showSnackBar(
          'An error occurred during OTP verification: ${e.toString()}');
    }
    // Loading indicator will disappear upon navigation or be turned off on error.
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
                // Consider adding an error builder for the image asset
                Image.asset(
                  'assets/images/phone.jpg', // Ensure this asset exists
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.phone_android, size: 100), // Placeholder
                ),
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
                  style: theme.textTheme.titleMedium, // Use a clear style
                ),
                const SizedBox(height: 40),

                // Conditionally show phone or OTP input
                if (!_isOtpSent) _buildPhoneInputSection(theme),
                if (_isOtpSent) _buildOtpInputSection(theme),

                // Show loading indicator below inputs when loading
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Button to go back from OTP entry
                if (_isOtpSent && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: TextButton(
                      onPressed: () {
                        // Reset state to go back to phone input
                        setState(() {
                          _isOtpSent = false;
                          _isLoading = false;
                          _verificationId = '';
                          _otpController.clear();
                        });
                      },
                      child: const Text('<- Use a different number'),
                    ),
                  ),

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
            // Consistent theme color usage
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
          keyboardType: TextInputType.phone,
          enabled: !_isLoading, // Disable when loading
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _signInWithPhone,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: theme.textTheme.titleMedium,
          ),
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
              fillColor: theme.colorScheme.surfaceContainerHighest,
              counterText: "", // Hide the counter if not desired
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !_isLoading, // Disable when loading
            autofocus: true, // Focus when visible
            onSubmitted: (_) {
              // Allow submit via keyboard
              if (!_isLoading) _verifyOtp();
            }),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: theme.textTheme.titleMedium,
          ),
          child: const Text('Verify OTP'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
