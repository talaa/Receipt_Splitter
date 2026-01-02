import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bill.dart';
import '../../providers/bill_provider.dart';

class TaxServiceRulesScreen extends ConsumerStatefulWidget {
  const TaxServiceRulesScreen({super.key});

  @override
  ConsumerState<TaxServiceRulesScreen> createState() => _TaxServiceRulesScreenState();
}

class _TaxServiceRulesScreenState extends ConsumerState<TaxServiceRulesScreen> {
  late TaxDistributionMode _selectedMode;

  @override
  void initState() {
    super.initState();
    // Initialize with current bill state
    final bill = ref.read(billProvider);
    _selectedMode = bill.taxMode;
  }

  void _save() {
    ref.read(billProvider.notifier).setTaxDistributionMode(_selectedMode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Current bill for calculations
    final bill = ref.watch(billProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalTaxService = (bill.items.fold(0.0, (sum, i) => sum + i.price) * (bill.taxPercentage + bill.servicePercentage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax & Service Rules'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Headline
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Total Extra: ', style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : Colors.black87
                            )),
                            TextSpan(text: '\$${totalTaxService.toStringAsFixed(2)}', style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, 
                              color: Theme.of(context).primaryColor
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Choose how to distribute this amount', 
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),

                // Options
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOption(
                        context, 
                        TaxDistributionMode.proportional, 
                        'Split Proportionally', 
                        'Based on individual item costs'
                      ),
                      const SizedBox(height: 12),
                      _buildOption(
                        context, 
                        TaxDistributionMode.equal, 
                        'Split Equally', 
                        'Everyone pays the same amount'
                      ),
                      const SizedBox(height: 12),
                      _buildOption(
                        context, 
                        TaxDistributionMode.billOwner, 
                        'Do Not Split', 
                        'Bill owner absorbs the cost'
                      ),
                    ],
                  ),
                ),
                
                // Preview Section (Simplified)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Impact Preview', style: TextStyle(
                          color: Theme.of(context).primaryColor, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2, fontSize: 10
                        )),
                        const SizedBox(height: 4),
                        const Text('Dynamic Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        const Text('Calculations update automatically based on selection.', 
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 8),
                    Text('Confirm Rule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, TaxDistributionMode mode, String title, String subtitle) {
    final isSelected = _selectedMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50) 
              : (isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  width: 2
                ),
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
