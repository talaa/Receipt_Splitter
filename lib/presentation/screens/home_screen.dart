import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/bill.dart';
import '../../providers/bill_provider.dart';
import '../../data/repositories/bill_repository.dart';
import 'capture_bill_screen.dart';
import 'tracking_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = BillRepository();
    final recentBills = repository.getAllBills().toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitIt', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero Action
          Padding(
             padding: const EdgeInsets.all(16),
             child: Center(
               child: ElevatedButton.icon(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const CaptureBillScreen()));
                 },
                 icon: const Icon(Icons.add),
                 label: const Text('Create New Bill'),
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
               ),
             ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(context, 'You Owe', '\$0.00', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, 'Owed to you', '\$0.00', Colors.green)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
          ),
          
          Expanded(
            child: recentBills.isEmpty 
              ? const Center(child: Text('No recent bills found.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: recentBills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bill = recentBills[index];
                    return _BillCard(bill: bill);
                  },
                ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BillCard extends ConsumerWidget {
  final Bill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = bill.people.isNotEmpty && bill.people.every((p) => p.isPaid);
    final total = bill.totalAmount;

    return InkWell(
      onTap: () {
        ref.read(billProvider.notifier).loadBill(bill);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.restaurantName.isEmpty ? 'Restaurant' : bill.restaurantName, 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM dd • Food').format(bill.date), 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
