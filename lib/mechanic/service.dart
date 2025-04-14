import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _serviceRequests = [];

  @override
  void initState() {
    super.initState();
    _loadServiceRequests();
  }

  Future<void> _loadServiceRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch service requests where the mechanic is assigned
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('service_requests')
          .where('mechanicId', isEqualTo: uid)
          .get();

      List<Map<String, dynamic>> requests = [];
      for (var doc in requestsSnapshot.docs) {
        requests.add(doc.data());
      }

      setState(() {
        _serviceRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service requests: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Requests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _serviceRequests.isEmpty
                ? const Center(child: Text('No service requests found.'))
                : ListView.builder(
                    itemCount: _serviceRequests.length,
                    itemBuilder: (context, index) {
                      final request = _serviceRequests[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title:
                              Text('Service Type: ${request['serviceType']}'),
                          subtitle:
                              Text('Customer: ${request['customerName']}'),
                          trailing: Text('Status: ${request['status']}'),
                          onTap: () {
                            // Navigate to detailed view of the service request
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceRequestDetailScreen(
                                  requestId: request['id'],
                                  request: null,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class ServiceRequestDetailScreen extends StatelessWidget {
  final String requestId;

  const ServiceRequestDetailScreen(
      {super.key, required this.requestId, required request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Request Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Service request not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Type: ${data['serviceType']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Customer Name: ${data['customerName']}'),
                Text('Location: ${data['location']}'),
                Text('Description: ${data['description']}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Accept the request and update status
                        FirebaseFirestore.instance
                            .collection('service_requests')
                            .doc(requestId)
                            .update({'status': 'Accepted'});
                      },
                      child: const Text('Accept'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Reject the request and update status
                        FirebaseFirestore.instance
                            .collection('service_requests')
                            .doc(requestId)
                            .update({'status': 'Rejected'});
                      },
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
