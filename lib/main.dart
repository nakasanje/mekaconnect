import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meka_app/Admin/adminscreen.dart';
import 'package:meka_app/screens/home_screen.dart';
import 'package:meka_app/screens/login_screen.dart';
import 'package:meka_app/screens/main_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MechaConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Ensure 'LoginScreen' is correctly imported
      home: const LoginScreen(),
    );
  }
}
