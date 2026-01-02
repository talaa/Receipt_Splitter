class Person {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? avatarUrl;
  bool isPaid;

  Person({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'avatarUrl': avatarUrl,
    'isPaid': isPaid,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    avatarUrl: json['avatarUrl'],
    isPaid: json['isPaid'] ?? false,
  );

  Person copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    bool? isPaid,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
