class ServiceRequest {
  final String userId;
  final String serviceType;
  final String description;
  final String location;
  final String status;
  final String requestId;

  ServiceRequest({
    required this.userId,
    required this.serviceType,
    required this.description,
    required this.location,
    required this.status,
    required this.requestId,
  });

  // Convert ServiceRequest to Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceType': serviceType,
      'description': description,
      'location': location,
      'status': status,
      'requestId': requestId,
    };
  }

  // Convert Map to ServiceRequest
  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    return ServiceRequest(
      userId: map['userId'],
      serviceType: map['serviceType'],
      description: map['description'],
      location: map['location'],
      status: map['status'],
      requestId: map['requestId'],
    );
  }
}
