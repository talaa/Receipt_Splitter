import '../../data/models/bill.dart';
import '../../data/models/person.dart';
import '../../data/models/payment.dart';

class MathUtils {
  /// Calculate the amount one person owes
  /// 
  /// Algorithm:
  /// 1. Sum their items (costPerPerson for each)
  /// 2. Calculate consumption ratio = personSubtotal / billSubtotal
  /// 3. Apply proportional tax/service based on ratio
  /// 4. Return: personSubtotal + personTax + personService
  
  static double calculatePersonTotal(
    Person person,
    Bill bill,
  ) {
    // Step 1: Get all items assigned to this person
    double personSubtotal = bill.items
        .where((item) => item.assignedPersonIds.contains(person.id))
        .fold(0, (sum, item) => sum + item.costPerPerson);

    if (personSubtotal == 0) return 0.0;

    // Step 2: Calculate consumption ratio
    // If bill subtotal is 0, avoid division by zero
    double consumptionRatio = bill.subtotal == 0 
        ? 0 
        : personSubtotal / bill.subtotal;

    // Step 3: Apply tax/service based on distribution mode
    double personTax = 0.0;
    double personService = 0.0;

    switch (bill.taxMode) {
      case TaxDistributionMode.proportional:
        personTax = bill.totalTax * consumptionRatio;
        personService = bill.totalService * consumptionRatio;
        break;
      
      case TaxDistributionMode.equal:
        int count = bill.people.length;
        personTax = count == 0 ? 0 : bill.totalTax / count;
        personService = count == 0 ? 0 : bill.totalService / count;
        break;
      
      case TaxDistributionMode.billOwner:
        // Owner absorbs tax; others pay 0
        personTax = 0.0;
        personService = 0.0;
        break;
    }

    return personSubtotal + personTax + personService;
  }

  /// Calculate all people's totals at once
  static Map<String, double> calculateAllTotals(Bill bill) {
    return {
      for (var person in bill.people)
        person.id: calculatePersonTotal(person, bill),
    };
  }

  /// Calculate total collected vs remaining
  static ({double collected, double remaining}) calculatePaymentStatus(
    List<Payment> payments,
    double grandTotal,
  ) {
    double collected = payments
        .where((p) => p.status == PaymentStatus.paid)
        .fold(0, (sum, p) => sum + p.amount);
    
    return (
      collected: collected,
      remaining: grandTotal - collected,
    );
  }
}
