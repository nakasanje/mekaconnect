import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meka_app/Admin/adminscreen.dart';
import 'package:meka_app/mechanic/mechanic_screen.dart';
import 'package:meka_app/screens/home_screen.dart';

class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    userModeCheck();
  }

  userModeCheck() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = snapshot.data();

      setState(() {
        userRole = data?["role"] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == "admin") {
      return const AdminDashboardScreen();
    } else {
      if (userRole == "mechanic") {
        return const MechanicDashboardScreen();
      } else {
        return const HomeScreen();
      }
    }
  }
}
