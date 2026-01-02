import '../models/bill.dart';

class BillRepository {
  // Simple in-memory storage for now as user is not using Hive
  static final List<Bill> _bills = [];

  Future<void> saveBill(Bill bill) async {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
    } else {
      _bills.add(bill);
    }
  }

  Bill? getBill(String id) {
    try {
      return _bills.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Bill> getAllBills() {
    return List.unmodifiable(_bills);
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
  }
}
