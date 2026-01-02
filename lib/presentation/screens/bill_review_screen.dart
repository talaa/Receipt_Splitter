import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/bill_item.dart';
import '../../providers/bill_provider.dart';
import 'assign_items_screen.dart'; // Next screen

class BillReviewScreen extends ConsumerStatefulWidget {
  final List<BillItem> initialItems;
  
  const BillReviewScreen({super.key, required this.initialItems});

  @override
  ConsumerState<BillReviewScreen> createState() => _BillReviewScreenState();
}

class _BillReviewScreenState extends ConsumerState<BillReviewScreen> {
  late List<BillItem> _items;
  final double _taxPercentage = 0.14; // Default 14%
  final double _servicePercentage = 0.0;
  final TextEditingController _restaurantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.price);
  double get _taxAmount => _subtotal * _taxPercentage;
  double get _serviceAmount => _subtotal * _servicePercentage;
  double get _total => _subtotal + _taxAmount + _serviceAmount;

  void _addItem() {
    setState(() {
      _items.add(BillItem(
        id: const Uuid().v4(),
        name: 'New Item',
        price: 0.0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _processBill() async {
    final restaurantName = _restaurantController.text.trim().isEmpty 
        ? 'Unknown Restaurant' 
        : _restaurantController.text.trim();
        
    final billNotifier = ref.read(billProvider.notifier);
    await billNotifier.createBill(restaurantName);
    
    // 2. Add items
    for (var item in _items) {
      billNotifier.addItem(item);
    }
    
    // 3. Set Tax/Service
    billNotifier.setTaxAndService(_taxPercentage, _servicePercentage);
    
    // 4. Navigate
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssignItemsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Restaurant Name Input
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _restaurantController,
                    decoration: InputDecoration(
                      labelText: 'Establishment',
                      hintText: 'Where did you eat?',
                      prefixIcon: const Icon(Icons.storefront),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.white,
                    ),
                  ),
                ),

                // Receipt Card Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Top decoration
                      Container(height: 4, color: Theme.of(context).primaryColor),
                      
                      // Items List
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.restaurant, size: 18, color: Theme.of(context).primaryColor),
                              ),
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Qty: ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${item.price.toStringAsFixed(2)}', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            ),
                            if (index < _items.length - 1)
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        );
                      }),
                      
                      // Add Item Button
                      InkWell(
                        onTap: _addItem,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text('Add Missing Item', 
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                )),
                            ],
                          ),
                        ),
                      ),
                      
                      // Summary Section
                      Container(
                        color: isDark ? Colors.black12 : Colors.grey.shade50,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', _subtotal),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Tax (14%)', _taxAmount),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Service (0%)', _serviceAmount),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('\$${_total.toStringAsFixed(2)}', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 20,
                                    color: Theme.of(context).primaryColor,
                                  )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please verify all items and prices before proceeding.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Confirm & Assign People', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
