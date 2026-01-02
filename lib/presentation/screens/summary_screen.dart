import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/person.dart';
import '../../providers/bill_provider.dart';
import '../../services/share_service.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billProvider);
    final billNotifier = ref.watch(billProvider.notifier);

    // Calculate totals
    final allTotals = billNotifier.getAllTotals();
    final totalBill = bill.totalAmount;
    final totalPaid = bill.people
        .where((p) => p.isPaid)
        .fold(0.0, (sum, p) => sum + (allTotals[p.id] ?? 0));
    final remaining = totalBill - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bill.people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final person = bill.people[index];
                return _PersonSummaryCard(
                  person: person,
                  total: allTotals[person.id] ?? 0,
                  billNotifier: billNotifier,
                );
              },
            ),
          ),
          
          // Sticky Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL BILL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('\$${totalBill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Row(
                      children: [
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Collected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text('\$${totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Remaining', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text('\$${remaining.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalBill > 0 ? totalPaid / totalBill : 0,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonSummaryCard extends StatelessWidget {
  final Person person;
  final double total;
  final dynamic billNotifier; // Typed as dynamic to avoid import complexity, realistically BillState

  const _PersonSummaryCard({
    required this.person,
    required this.total,
    required this.billNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // Basic items logic (simplified calculation for display)
    // In real app, we should get items for person from logic or filter bill items
    // But calculatePersonTotal returns just double. 
    // We display items if possible, or just total for now as per logic limitation?
    // Review: code.html shows items list.
    // Provider doesn't return list of items per person easily without re-looping.
    // We'll leave item breakdown for v2 or add helper method.
    // Phase 1: Show Total.
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: person.avatarUrl == null ? Theme.of(context).primaryColor : null,
                  backgroundImage: person.avatarUrl != null ? NetworkImage(person.avatarUrl!) : null,
                  child: person.avatarUrl == null ? Text(person.name[0], style: const TextStyle(color: Colors.white)) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(person.isPaid ? 'Paid' : 'Pending', 
                      style: TextStyle(
                        fontSize: 12, 
                        color: person.isPaid ? Colors.green : Theme.of(context).primaryColor, 
                        fontWeight: FontWeight.w600
                      )),
                  ],
                ),
                const Spacer(),
                if (person.isPaid)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Total Line
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Due', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('\$${total.toStringAsFixed(2)}', 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900,
                    color: person.isPaid ? Colors.black : Theme.of(context).primaryColor,
                  )),
              ],
            ),
          ),
          
          // Actions
          if (!person.isPaid)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         // Generate Link
                         ShareService.sharePaymentRequest(person, total);
                      },
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        billNotifier.markPersonAsPaid(person.id);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark Paid'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
