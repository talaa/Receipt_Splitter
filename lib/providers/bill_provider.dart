import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bill.dart';
import '../data/models/bill_item.dart';
import '../data/models/person.dart';
import '../data/repositories/bill_repository.dart';
import '../core/utils/math_utils.dart';

class BillState extends Notifier<Bill> {
  @override
  Bill build() => _initialBill();

  // Create a new bill
  Future<void> createBill(String restaurantName) async {
    state = Bill(
      id: const Uuid().v4(),
      date: DateTime.now(),
      restaurantName: restaurantName,
    );
    await BillRepository().saveBill(state);
  }

  // Add item to bill
  void addItem(BillItem item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
    BillRepository().saveBill(state);
  }

  // Assign multiple people to item (overwrite)
  void assignPeopleToItem(String itemId, List<String> personIds) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(assignedPersonIds: personIds);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    BillRepository().saveBill(state);
  }

  // Assign person to item (toggle)
  void togglePersonForItem(String itemId, String personId) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        final currentIds = item.assignedPersonIds.toSet();
        if (currentIds.contains(personId)) {
          currentIds.remove(personId);
        } else {
          currentIds.add(personId);
        }
        return item.copyWith(assignedPersonIds: currentIds.toList());
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    BillRepository().saveBill(state);
  }

  // Add person to bill
  void addPerson(Person person) {
    if (state.people.any((p) => p.id == person.id)) return;
    state = state.copyWith(
      people: [...state.people, person],
    );
    BillRepository().saveBill(state);
  }

  // Update tax/service percentages
  void setTaxAndService(double taxPct, double servicePct) {
    state = state.copyWith(
      taxPercentage: taxPct,
      servicePercentage: servicePct,
    );
    BillRepository().saveBill(state);
  }

  // Change tax distribution mode
  void setTaxDistributionMode(TaxDistributionMode mode) {
    state = state.copyWith(taxMode: mode);
    BillRepository().saveBill(state);
  }

  // Get person's total
  double getPersonTotal(String personId) {
    final person = state.people.firstWhere(
      (p) => p.id == personId,
      orElse: () => throw Exception('Person not found'),
    );
    return MathUtils.calculatePersonTotal(person, state);
  }

  // Get all totals
  Map<String, double> getAllTotals() {
    return MathUtils.calculateAllTotals(state);
  }

  // Mark person as paid
  void markPersonAsPaid(String personId) {
    final updatedPeople = state.people.map((person) {
      if (person.id == personId) {
        return person.copyWith(isPaid: true);
      }
      return person;
    }).toList();
    state = state.copyWith(people: updatedPeople);
    BillRepository().saveBill(state);
  }

  Bill _initialBill() => Bill(
    id: const Uuid().v4(),
    date: DateTime.now(),
    restaurantName: '',
  );
  
  // Load existing bill
  void loadBill(Bill bill) {
    state = bill;
  }
}

final billProvider = NotifierProvider<BillState, Bill>(BillState.new);
