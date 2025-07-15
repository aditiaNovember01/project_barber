class Barber {
  final int id;
  final String name;
  final String photo;
  final String specialty;
  final String status;

  Barber({
    required this.id,
    required this.name,
    required this.photo,
    required this.specialty,
    required this.status,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      name: json['name'],
      photo: json['photo'],
      specialty: json['specialty'],
      status: json['status'],
    );
  }
} 