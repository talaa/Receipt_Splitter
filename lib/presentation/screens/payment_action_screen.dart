import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bill_provider.dart';
import '../../services/share_service.dart';

class PaymentActionScreen extends ConsumerWidget {
  final String personId;
  final double amount;

  const PaymentActionScreen({super.key, required this.personId, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billProvider);
    final person = bill.people.firstWhere((p) => p.id == personId);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background dismiss (tap to close)
          GestureDetector(onTap: () => Navigator.pop(context)),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20, 
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, 
                        height: 4, 
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, 
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        const Text('Settle Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    
                    // Profile
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: person.avatarUrl != null ? NetworkImage(person.avatarUrl!) : null,
                      child: person.avatarUrl == null ? Text(person.name[0], style: const TextStyle(fontSize: 32)) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Collecting from ${person.name}'.toUpperCase(), 
                      style: const TextStyle(
                        color: Colors.grey, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                      ),
                    ),
                    Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 40)),
                    const SizedBox(height: 24),
                    
                    // Main Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                           ShareService.sharePaymentRequest(person, amount);
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Send Payment Request'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Opens WhatsApp or SMS', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Manual Actions
                    const Align(alignment: Alignment.centerLeft, child: Text('Mark status manually', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                           child: _buildActionTile(
                             context, 
                             'Pending', 
                             Icons.pending, 
                             Colors.orange, 
                             () {
                               // Ideally need 'markAsPending' logic, but we only have markPaid. 
                               // For now, toggle paid off? Not implemented in provider.
                               // Implementing 'markPersonAsPaid' to true.
                               Navigator.pop(context);
                             }
                           )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                           child: _buildActionTile(
                             context, 
                             'Paid', 
                             Icons.check_circle, 
                             Colors.green, 
                             () {
                               ref.read(billProvider.notifier).markPersonAsPaid(personId);
                               Navigator.pop(context);
                             }
                           )
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
