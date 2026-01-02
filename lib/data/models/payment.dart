enum PaymentMethod {
  instapay,
  cash,
  creditCard
}

enum PaymentStatus {
  pending,
  paid,
  overdue
}

class Payment {
  final String id;
  final String billId;
  final String personId;
  double amount;
  PaymentMethod method;
  PaymentStatus status;
  DateTime createdAt;

  Payment({
    required this.id,
    required this.billId,
    required this.personId,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'billId': billId,
    'personId': personId,
    'amount': amount,
    'method': method.toString(),
    'status': status.toString(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    billId: json['billId'],
    personId: json['personId'],
    amount: (json['amount'] as num).toDouble(),
    method: PaymentMethod.values.firstWhere((e) => e.toString() == json['method']),
    status: PaymentStatus.values.firstWhere((e) => e.toString() == json['status']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
