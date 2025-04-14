import 'package:flutter/material.dart';
import 'package:meka_app/models/Servicerequest.dart';

class ServiceRequestDetailScreen extends StatelessWidget {
  final ServiceRequest request;

  const ServiceRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Type: ${request.serviceType}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Description: ${request.description}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Location: ${request.location}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Status: ${request.status}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle update or cancellation here
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }
}
