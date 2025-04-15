import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meka_app/mechanic/service.dart';
import 'package:meka_app/models/Servicerequest.dart';

class UserServiceRequestsScreen extends StatefulWidget {
  const UserServiceRequestsScreen({super.key});

  @override
  _UserServiceRequestsScreenState createState() =>
      _UserServiceRequestsScreenState();
}

class _UserServiceRequestsScreenState extends State<UserServiceRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ServiceRequest>> _fetchServiceRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('serviceRequests')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs
        .map((doc) => ServiceRequest.fromMap(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Service Requests')),
      body: FutureBuilder<List<ServiceRequest>>(
        future: _fetchServiceRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No service requests yet.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text(request.serviceType),
                subtitle: Text('Status: ${request.status}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestDetailScreen(
                        request: request,
                        requestId: '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
