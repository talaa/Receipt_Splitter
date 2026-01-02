import 'bill_item.dart';
import 'person.dart';

enum TaxDistributionMode {
  proportional,
  equal,
  billOwner,
}

class Bill {
  final String id;
  final DateTime date;
  final String restaurantName;
  final List<BillItem> items;
  final List<Person> people;
  final double taxPercentage;
  final double servicePercentage;
  final TaxDistributionMode taxMode;

  Bill({
    required this.id,
    required this.date,
    required this.restaurantName,
    this.items = const [],
    this.people = const [],
    this.taxPercentage = 0.0,
    this.servicePercentage = 0.0,
    this.taxMode = TaxDistributionMode.proportional,
  });

  // Getters for UI display
  double get subtotal => items.fold(0, (sum, item) => sum + item.price);
  double get totalTax => subtotal * taxPercentage;
  double get totalService => subtotal * servicePercentage;
  double get totalAmount => subtotal + totalTax + totalService;
  double get grandTotal => totalAmount; // Alias for backward compatibility

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'restaurantName': restaurantName,
    'items': items.map((i) => i.toJson()).toList(),
    'people': people.map((p) => p.toJson()).toList(),
    'taxPercentage': taxPercentage,
    'servicePercentage': servicePercentage,
    'taxMode': taxMode.toString(),
  };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'],
    date: DateTime.parse(json['date']),
    restaurantName: json['restaurantName'],
    items: (json['items'] as List?)?.map((i) => BillItem.fromJson(i)).toList() ?? [],
    people: (json['people'] as List?)?.map((p) => Person.fromJson(p)).toList() ?? [],
    taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 0.0,
    servicePercentage: (json['servicePercentage'] as num?)?.toDouble() ?? 0.0,
    taxMode: TaxDistributionMode.values.firstWhere(
      (e) => e.toString() == json['taxMode'], 
      orElse: () => TaxDistributionMode.proportional
    ),
  );

  Bill copyWith({
    String? id,
    DateTime? date,
    String? restaurantName,
    List<BillItem>? items,
    List<Person>? people,
    double? taxPercentage,
    double? servicePercentage,
    TaxDistributionMode? taxMode,
  }) {
    return Bill(
      id: id ?? this.id,
      date: date ?? this.date,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      people: people ?? this.people,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      servicePercentage: servicePercentage ?? this.servicePercentage,
      taxMode: taxMode ?? this.taxMode,
    );
  }
}
