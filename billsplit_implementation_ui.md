# BillSplit Implementation Guide - UI-Driven (Approach B)

## 1. Project Overview
**Goal:** A Flutter application that helps users split restaurant bills by scanning receipts, assigning items to people (including shared items), calculating totals with proportional tax/service distribution, and requesting payments via Instapay or Cash.

**Phase:** 1 (Local State, No Backend)  
**Architecture Approach:** Service-Repository Pattern with Riverpod State Management  
**UI Reference:** 7-screen flow provided

---

## 2. Tech Stack (Approach B - Finalized)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_generator: ^2.3.0
  # Local Storage
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  # OCR & Camera
  google_ml_kit_text_recognition: ^0.11.0
  image_picker: ^1.0.4
  # Contacts & Utilities
  flutter_contacts: ^1.1.7
  url_launcher: ^6.2.1
  uuid: ^4.2.0
  intl: ^0.18.0
  # UI/Icons
  cupertino_icons: ^1.0.2

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

---

## 3. Directory Structure (Aligned to UI Screens)

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_styles.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── math_utils.dart          <-- Tax/Service calculation logic
│       ├── currency_formatter.dart
│       └── validators.dart
├── data/
│   ├── models/
│   │   ├── bill.dart
│   │   ├── bill_item.dart
│   │   ├── person.dart
│   │   └── payment.dart
│   ├── repositories/
│   │   └── bill_repository.dart     <-- Hive persistence
│   └── datasources/
│       └── local_datasource.dart    <-- Hive operations
├── services/
│   ├── ocr_service.dart             <-- ML Kit integration
│   ├── contact_service.dart         <-- Phone contacts
│   ├── share_service.dart           <-- WhatsApp/SMS links
│   └── storage_service.dart         <-- Hive wrapper
├── providers/
│   ├── bill_provider.dart           <-- Riverpod StateNotifier
│   ├── person_provider.dart
│   └── settings_provider.dart
└── presentation/
    ├── screens/
    │   ├── 1_home_screen.dart              [Screen 1]
    │   ├── 2_capture_bill_screen.dart      [Screen 2]
    │   ├── 3_assign_items_screen.dart      [Screen 3]
    │   ├── 4_tax_service_rules_screen.dart [Screen 4]
    │   ├── 5_summary_screen.dart           [Screen 5]
    │   ├── 6_settlement_screen.dart        [Screen 6]
    │   └── 7_tracking_screen.dart          [Screen 7]
    ├── widgets/
    │   ├── bill_summary_card.dart
    │   ├── item_row_widget.dart
    │   ├── person_avatar_selector.dart
    │   ├── payment_status_badge.dart
    │   ├── tax_rule_option_card.dart
    │   ├── participant_card.dart
    │   └── progress_indicator.dart
    └── viewmodels/
        └── bill_viewmodel.dart
```

---

## 4. Data Models (The Core)

### A. `Person`
```dart
class Person {
  final String id;
  final String name;
  final String? phoneNumber;  // E.164 format
  final String? avatarUrl;    // Local path or URL
  bool isPaid;

  Person({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.isPaid = false,
  });

  // For Hive storage
  Map<String, dynamic> toJson() => {...};
  factory Person.fromJson(Map<String, dynamic> json) => ...;
}
```

### B. `BillItem`
```dart
class BillItem {
  final String id;
  String name;
  double price;                      // Total price for this line
  int quantity;
  List<String> assignedPersonIds;    // Shared item support
  
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

  Map<String, dynamic> toJson() => {...};
  factory BillItem.fromJson(Map<String, dynamic> json) => ...;
}
```

### C. `Bill`
```dart
class Bill {
  final String id;
  final DateTime date;
  final String restaurantName;
  final List<BillItem> items;
  final List<Person> people;
  
  // Tax & Service as percentages (0.14 = 14%)
  double taxPercentage;
  double servicePercentage;
  
  // Tax distribution mode
  TaxDistributionMode taxMode;  // PROPORTIONAL, EQUAL, BILL_OWNER
  
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
  double get grandTotal => subtotal + totalTax + totalService;

  Map<String, dynamic> toJson() => {...};
  factory Bill.fromJson(Map<String, dynamic> json) => ...;
}

enum TaxDistributionMode {
  proportional,  // Based on item cost
  equal,         // Split equally
  billOwner,     // Owner absorbs
}
```

### D. `Payment`
```dart
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

  Map<String, dynamic> toJson() => {...};
  factory Payment.fromJson(Map<String, dynamic> json) => ...;
}

enum PaymentMethod { instapay, cash, creditCard }
enum PaymentStatus { pending, paid, overdue }
```

---

## 5. Core Business Logic (Math Engine)

### `MathUtils` - The Calculator

```dart
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
```

---

## 6. Riverpod State Management (The Brain)

### `bill_provider.dart`

```dart
class BillState extends StateNotifier<Bill> {
  BillState(this.repository) : super(_initialBill());

  final BillRepository repository;

  // Create a new bill
  Future<void> createBill(String restaurantName) async {
    state = Bill(
      id: const Uuid().v4(),
      date: DateTime.now(),
      restaurantName: restaurantName,
    );
    await repository.saveBill(state);
  }

  // Add item to bill
  void addItem(BillItem item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
    repository.saveBill(state);
  }

  // Assign person to item
  void assignPersonToItem(String itemId, String personId) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        final newIds = {...item.assignedPersonIds, personId}.toList();
        return item.copyWith(assignedPersonIds: newIds);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    repository.saveBill(state);
  }

  // Add person to bill
  void addPerson(Person person) {
    state = state.copyWith(
      people: [...state.people, person],
    );
    repository.saveBill(state);
  }

  // Update tax/service percentages
  void setTaxAndService(double taxPct, double servicePct) {
    state = state.copyWith(
      taxPercentage: taxPct,
      servicePercentage: servicePct,
    );
    repository.saveBill(state);
  }

  // Change tax distribution mode
  void setTaxDistributionMode(TaxDistributionMode mode) {
    state = state.copyWith(taxMode: mode);
    repository.saveBill(state);
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
    repository.saveBill(state);
  }

  static Bill _initialBill() => Bill(
    id: const Uuid().v4(),
    date: DateTime.now(),
    restaurantName: '',
  );
}

// Riverpod provider
final billProvider = StateNotifierProvider<BillState, Bill>((ref) {
  return BillState(BillRepository());
});
```

### `person_provider.dart`

```dart
final personListProvider = StateNotifierProvider<PersonListState, List<Person>>((ref) {
  return PersonListState(BillRepository());
});

class PersonListState extends StateNotifier<List<Person>> {
  PersonListState(this.repository) : super([]);

  final BillRepository repository;

  Future<void> loadContactsAsPersons() async {
    final contacts = await ContactService().getContacts();
    state = contacts.map((contact) => Person(
      id: const Uuid().v4(),
      name: contact.displayName ?? 'Unknown',
      phoneNumber: contact.phones.isNotEmpty ? contact.phones.first.number : null,
    )).toList();
  }

  void addManualPerson(String name, String? phone) {
    final person = Person(
      id: const Uuid().v4(),
      name: name,
      phoneNumber: phone,
    );
    state = [...state, person];
  }
}
```

### `settings_provider.dart`

```dart
final instapayUsernameProvider = StateProvider<String?>((ref) {
  return null; // Load from Hive on app start
});

final taxDistributionModeProvider = StateProvider<TaxDistributionMode>((ref) {
  return TaxDistributionMode.proportional;
});
```

---

## 7. Service Layer (Integration Points)

### `ocr_service.dart` - Vision to Text

```dart
class OcrService {
  Future<List<BillItem>> extractItemsFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = 
          await textRecognizer.processImage(inputImage);
      
      final items = _parseRecognizedText(recognizedText);
      return items;
    } finally {
      textRecognizer.close();
    }
  }

  List<BillItem> _parseRecognizedText(RecognizedText recognizedText) {
    final items = <BillItem>[];
    
    // Regex patterns for "Item Name" + "Price"
    final pricePattern = RegExp(r'\$?([\d,]+\.?\d{0,2})');
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text;
        
        // Try to extract: [Item Name] [Price]
        final priceMatch = pricePattern.firstMatch(text);
        if (priceMatch != null) {
          final priceStr = priceMatch.group(1)?.replaceAll(',', '');
          final price = double.tryParse(priceStr ?? '0') ?? 0.0;
          
          final name = text.replaceAll(pricePattern, '').trim();
          
          if (name.isNotEmpty && price > 0) {
            items.add(BillItem(
              id: const Uuid().v4(),
              name: name,
              price: price,
            ));
          }
        }
      }
    }
    
    return items;
  }
}
```

### `contact_service.dart` - Phone Contacts

```dart
class ContactService {
  Future<List<Contact>> getContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts;
    } catch (e) {
      print('Error loading contacts: $e');
      return [];
    }
  }

  Future<bool> requestPermission() async {
    final permission = await FlutterContacts.requestPermission();
    return permission;
  }
}
```

### `share_service.dart` - Payment Links

```dart
class ShareService {
  Future<void> sendInstapayRequest({
    required String personName,
    required String phoneNumber,
    required double amount,
    required String billName,
  }) async {
    // Format: wa.me/[phone]?text=[message]
    final message = _buildPaymentMessage(
      personName: personName,
      amount: amount,
      billName: billName,
    );
    
    final phoneClean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final waUrl = 'https://wa.me/$phoneClean?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(waUrl))) {
      await launchUrl(Uri.parse(waUrl));
    }
  }

  String _buildPaymentMessage({
    required String personName,
    required double amount,
    required String billName,
  }) {
    return '''Hi $personName, 
Your total for $billName is \$${amount.toStringAsFixed(2)}.

Pay via Instapay: [Link]

Thanks!''';
  }

  Future<void> sendViaSMS({
    required String phoneNumber,
    required double amount,
    required String billName,
  }) async {
    final message = 'You owe \$${amount.toStringAsFixed(2)} for $billName';
    final smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
    }
  }
}
```

### `storage_service.dart` - Hive Wrapper

```dart
class StorageService {
  static const String billBox = 'bills';
  static const String personBox = 'persons';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters (generated by Hive)
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(BillItemAdapter());
    Hive.registerAdapter(PersonAdapter());
    
    await Hive.openBox<Bill>(billBox);
    await Hive.openBox<Person>(personBox);
  }

  static Future<void> saveBill(Bill bill) async {
    final box = Hive.box<Bill>(billBox);
    await box.put(bill.id, bill);
  }

  static Future<Bill?> getBill(String id) async {
    final box = Hive.box<Bill>(billBox);
    return box.get(id);
  }

  static Future<List<Bill>> getAllBills() async {
    final box = Hive.box<Bill>(billBox);
    return box.values.toList();
  }
}
```

---

## 8. Screen Implementation Roadmap

### **Screen 1: Home Screen** (5 hours)
- Display "YOU OWE" / "OWED TO YOU" summary
- List recent bills with status badges
- "Create New Bill" button → navigates to Screen 2

### **Screen 2: Capture Bill** (6 hours)
- Camera picker + ML Kit OCR
- Manual entry fallback
- Edit parsed items before confirmation

### **Screen 3: Assign Items** (8 hours)
- Vertical list of BillItems
- Horizontal person avatar selector (bottom)
- Tap item → tap person to assign
- Visual feedback (green = assigned, red = unassigned)

### **Screen 4: Tax & Service Rules** (5 hours)
- Three radio options: Proportional / Equal / Bill Owner
- Live preview of impact on each person
- "Confirm Rule" button

### **Screen 5: Summary Screen** (7 hours)
- Per-person breakdown (items + tax/tip)
- Collected vs Remaining progress bar
- "Request Payment" button → Screen 6

### **Screen 6: Settlement Modal** (6 hours)
- Show person's avatar, name, amount due
- "Pay via Instapay" button (calls ShareService)
- Manual status toggle (Pending / Paid / Cash)

### **Screen 7: Tracking Screen** (5 hours)
- All participants in one view
- Payment status for each
- "Close Bill & Lock" button

**Total Phase 1 Effort: ~42 hours (5-6 developer weeks)**

---

## 9. Unit Tests (Quality Checkpoint)

### Key Test Cases

```dart
void main() {
  group('MathUtils', () {
    test('calculatePersonTotal - Proportional Tax Distribution', () {
      // Arrange
      final bill = Bill(
        id: '1',
        date: DateTime.now(),
        restaurantName: 'Test',
        items: [
          BillItem(id: '1', name: 'Pizza', price: 100, assignedPersonIds: ['p1']),
          BillItem(id: '2', name: 'Burger', price: 50, assignedPersonIds: ['p2']),
        ],
        people: [
          Person(id: 'p1', name: 'Alice'),
          Person(id: 'p2', name: 'Bob'),
        ],
        taxPercentage: 0.1,
        taxMode: TaxDistributionMode.proportional,
      );

      final person1 = bill.people[0];

      // Act
      final total = MathUtils.calculatePersonTotal(person1, bill);

      // Assert
      // Alice: 100 (food) + 6.67 (tax) = 106.67
      expect(total, closeTo(106.67, 0.01));
    });

    test('calculatePersonTotal - Shared Item Split', () {
      // Arrange
      final bill = Bill(
        id: '1',
        date: DateTime.now(),
        restaurantName: 'Test',
        items: [
          BillItem(
            id: '1',
            name: 'Nachos',
            price: 30,
            assignedPersonIds: ['p1', 'p2', 'p3'],
          ),
        ],
        people: [
          Person(id: 'p1', name: 'Alice'),
          Person(id: 'p2', name: 'Bob'),
          Person(id: 'p3', name: 'Charlie'),
        ],
        taxPercentage: 0.0,
      );

      // Act
      final total = MathUtils.calculatePersonTotal(bill.people[0], bill);

      // Assert
      // Each pays 30/3 = $10
      expect(total, 10.0);
    });
  });
}
```

---

## 10. Implementation Phases (Week-by-Week)

### **Week 1: Foundation**
- [ ] Setup Riverpod + Hive
- [ ] Create all data models (Bill, BillItem, Person, Payment)
- [ ] Implement MathUtils with full unit tests
- [ ] Create BillRepository + StorageService
- [ ] Build home_screen.dart (static UI first)

### **Week 2: Capture & Parse**
- [ ] Integrate ML Kit OCR
- [ ] Build capture_bill_screen.dart
- [ ] Create OcrService + _parseRecognizedText()
- [ ] Manual item entry fallback
- [ ] Test with real receipts

### **Week 3: Assignment Logic**
- [ ] Build assign_items_screen.dart (core complexity)
- [ ] Implement item selection + person assignment
- [ ] Visual feedback (color coding)
- [ ] Create person_avatar_selector widget
- [ ] Connect to BillProvider (Riverpod)

### **Week 4: Tax & Settlement**
- [ ] Build tax_service_rules_screen.dart
- [ ] Implement all three distribution modes
- [ ] Create summary_screen.dart with breakdown
- [ ] Build settlement_screen.dart modal
- [ ] Integrate ShareService (WhatsApp/SMS)

### **Week 5: Polish & Testing**
- [ ] Build tracking_screen.dart
- [ ] Implement payment status persistence
- [ ] Full integration testing
- [ ] Bug fixes + UX refinement
- [ ] Phase 1 release

---

## 11. Risk Mitigation & Fallbacks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| ML Kit OCR accuracy | Medium | Manual entry always available; user can edit |
| WhatsApp deep linking | Low | Fallback to SMS or copy link to clipboard |
| Contact permission denied | Low | Allow manual entry of names/phones |
| Hive storage quota | Low | Phase 1 is local-only; Phase 2 migrates to backend |
| Shared item calculation errors | High | Comprehensive unit tests before release |

---

## 12. Deliverables Checklist

✅ **Architecture:**
- Riverpod state management configured
- Service-Repository pattern implemented
- Models with toJson/fromJson methods

✅ **Logic:**
- MathUtils with proportional/equal/owner tax splits
- BillRepository with CRUD operations
- Person assignment logic

✅ **UI/Screens:**
- All 7 screens built per design
- Real-time summary updates
- Payment status tracking

✅ **Integrations:**
- ML Kit OCR (with manual fallback)
- Flutter Contacts integration
- WhatsApp/SMS share service
- Hive local storage

✅ **Testing:**
- Unit tests for MathUtils
- Integration tests for bill flow
- Manual QA on iOS + Android

✅ **Documentation:**
- Code comments for complex logic
- README with setup instructions
- Contributing guidelines

---

## 13. Success Metrics (Phase 1 Definition)

✅ User can upload/manually enter a bill  
✅ User can assign items to people (single + shared)  
✅ Shared items split correctly  
✅ Tax/Service distribute proportionally (or by chosen mode)  
✅ Person totals calculate to the exact penny  
✅ WhatsApp/SMS payment request works  
✅ Payment status persists (Paid/Pending)  
✅ 0 critical bugs on release  
✅ App runs offline (no backend required)  

---

## Next Steps

1. **Approve this architecture** with your team
2. **Validate tech stack** — ensure team has Riverpod experience (or allocate learning time)
3. **Create GitHub repository** with this folder structure
4. **Assign developers** to screens based on expertise
5. **Start Week 1** with foundation setup + unit tests

---

**Estimated Timeline:** 5-6 weeks (1 senior developer) or 3-4 weeks (2 developers)