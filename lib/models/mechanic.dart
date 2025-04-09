class MechanicModel {
  final String uid;
  final String name;
  final String location;
  final String specialty;

  MechanicModel({
    required this.uid,
    required this.name,
    required this.location,
    required this.specialty,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'location': location,
      'specialty': specialty,
    };
  }

  factory MechanicModel.fromMap(Map<String, dynamic> map) {
    return MechanicModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      specialty: map['specialty'] ?? '',
    );
  }
}
