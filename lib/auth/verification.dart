import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/mechanic/mechanic_screen.dart';
import 'package:meka_app/screens/home_screen.dart';
import 'package:meka_app/screens/login_screen.dart';

class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndNavigate();
  }

  Future<void> _checkUserRoleAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>?;
          final role = data?['role'];

          setState(() {
            _isLoading = false;
          });

          if (role == 'mechanic') {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MechanicDashboardScreen()),
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('User data not found. Please log in again.');
          // Optionally, navigate back to the login screen
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error fetching user data: ${e.toString()}');
        // Optionally, handle error and potentially navigate back
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Not authenticated. Please log in.');
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Verifying User...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
