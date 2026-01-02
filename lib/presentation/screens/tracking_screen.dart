import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/person.dart';
import '../../providers/bill_provider.dart';
import 'payment_action_screen.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billProvider);
    final billNotifier = ref.watch(billProvider.notifier);

    final allTotals = billNotifier.getAllTotals();
    final totalBill = bill.totalAmount; 
    
    final totalPaid = bill.people
        .where((p) => p.isPaid)
        .fold(0.0, (sum, p) => sum + (allTotals[p.id] ?? 0));
    final remaining = totalBill - totalPaid;
    final progress = totalBill > 0 ? totalPaid / totalBill : 0.0;
    
    final paidCount = bill.people.where((p) => p.isPaid).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(bill.restaurantName.isEmpty ? 'Bill Tracking' : bill.restaurantName, 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Hero Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                const Text('TOTAL BILL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('\$${totalBill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(context, 'Collected', totalPaid, Colors.green, Icons.account_balance_wallet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStat(context, 'Remaining', remaining, Colors.orange, Icons.pending),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$paidCount/${bill.people.length} Paid', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(progress * 100).toInt()}% Complete', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text('Participants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...bill.people.map((person) {
                   final amount = allTotals[person.id] ?? 0;
                   return _ParticipantRow(
                     person: person, 
                     amount: amount,
                     onTap: () {
                       Navigator.push(context, MaterialPageRoute(
                         builder: (_) => PaymentActionScreen(personId: person.id, amount: amount)
                       ));
                     },
                   );
                }),
              ],
            ),
          ),
          
          // Sticky Bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: () {
                   // Lock/Close logic
                   Navigator.pop(context);
                 },
                 icon: const Icon(Icons.lock),
                 label: const Text('Close Bill & Lock'),
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Slight contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final Person person;
  final double amount;
  final VoidCallback onTap;

  const _ParticipantRow({required this.person, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
             color: person.isPaid 
                 ? Colors.grey.withValues(alpha: 0.1) 
                 : Colors.orange.withValues(alpha: 0.2),
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0,2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: person.avatarUrl != null ? NetworkImage(person.avatarUrl!) : null,
              child: person.avatarUrl == null ? Text(person.name[0]) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: person.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          person.isPaid ? 'Paid' : 'Pending',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: person.isPaid ? Colors.green : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
