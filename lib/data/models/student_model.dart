class Student {
  final int? id;
  final String name;
  final String studentId;
  final String password;
  final String timestamp;
  final String location;

  Student({
    this.id,
    required this.name,
    required this.studentId,
    required this.password,
    required this.timestamp,
    required this.location,
  });

  // Converts a Student object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'password': password,
      'timestamp': timestamp,
      'location': location,
    };
  }

  // Factory to create a Student object from a Database Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      studentId: map['studentId'],
      password: map['password'] ?? "",
      timestamp: map['timestamp'],
      location: map['location'],
    );
  }
}