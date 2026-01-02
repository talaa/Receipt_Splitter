class BillItem {
  final String id;
  String name;
  double price;
  int quantity;
  List<String> assignedPersonIds;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.assignedPersonIds = const [],
  });

  // Derived property: cost per person
  double get costPerPerson {
    if (assignedPersonIds.isEmpty) return 0.0;
    return price / assignedPersonIds.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'assignedPersonIds': assignedPersonIds,
  };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] ?? 1,
    assignedPersonIds: List<String>.from(json['assignedPersonIds'] ?? []),
  );

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    List<String>? assignedPersonIds,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedPersonIds: assignedPersonIds ?? this.assignedPersonIds,
    );
  }
}
