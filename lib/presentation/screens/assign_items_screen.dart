import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/bill_item.dart';
import '../../data/models/person.dart';
import '../../providers/bill_provider.dart';
import '../../providers/person_provider.dart';
import 'summary_screen.dart'; // Next screen

class AssignItemsScreen extends ConsumerWidget {
  const AssignItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billProvider);
    final people = ref.watch(personListProvider);
    
    final totalBill = bill.totalAmount;
    final assignedAmount = bill.items.fold(0.0, (sum, item) {
      return item.assignedPersonIds.isNotEmpty ? sum + item.price : sum;
    });
    final remaining = totalBill - assignedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Items'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Stats Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatCard(context, 'Total Bill', totalBill, Icons.receipt_long, false),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Remaining', remaining, Icons.pie_chart, true),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: bill.items.length,
              itemBuilder: (context, index) {
                final item = bill.items[index];
                return _buildItemCard(context, ref, item, people);
              },
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: totalBill > 0 ? assignedAmount / totalBill : 0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: Theme.of(context).primaryColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: remaining <= 0.01 // Tolerance for float
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SummaryScreen()),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, double amount, IconData icon, bool highlight) {
    final color = highlight ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color;
    final bg = highlight ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardColor;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: highlight ? color : Colors.grey),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: highlight ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text('\$${amount.toStringAsFixed(2)}', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, BillItem item, List<Person> people) {
    final assignedPeople = people.where((p) => item.assignedPersonIds.contains(p.id)).toList();
    final isAssigned = assignedPeople.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isAssigned
            ? Text(assignedPeople.map((p) => p.name).join(', '))
            : Text('\$${item.price.toStringAsFixed(2)}'),
        trailing: isAssigned
            ? Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            : OutlinedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Assign'),
                onPressed: () => _showAssignmentModal(context, ref, item),
              ),
        onTap: () => _showAssignmentModal(context, ref, item),
      ),
    );
  }

  void _showAssignmentModal(BuildContext context, WidgetRef ref, BillItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentModal(item: item),
    );
  }
}

class _AssignmentModal extends ConsumerStatefulWidget {
  final BillItem item;
  const _AssignmentModal({required this.item});

  @override
  ConsumerState<_AssignmentModal> createState() => _AssignmentModalState();
}

class _AssignmentModalState extends ConsumerState<_AssignmentModal> {
  late Set<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.item.assignedPersonIds.toSet();
  }
  
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    ref.read(billProvider.notifier).assignPeopleToItem(
      widget.item.id, 
      _selectedIds.toList(),
    );
    Navigator.pop(context);
  }

  void _addNewPerson(String name) {
     final newPerson = Person(
       id: const Uuid().v4(),
       name: name,
     );
     ref.read(personListProvider.notifier).addPerson(newPerson);
     _toggleSelection(newPerson.id);
     _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(personListProvider);
    final filteredPeople = people.where((p) => 
      p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Who had the ${widget.item.name}?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text('\$${widget.item.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ],
            ),
          ),
          
          const Divider(),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search or add name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (val) => setState(() {}),
              onSubmitted: (val) {
                if (val.isNotEmpty && filteredPeople.isEmpty) {
                  _addNewPerson(val);
                }
              },
            ),
          ),
          
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredPeople.length + (filteredPeople.isEmpty && _searchController.text.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filteredPeople.length) {
                   return GestureDetector(
                     onTap: () => _addNewPerson(_searchController.text),
                     child: Column(
                       children: [
                         Container(
                           width: 56, height: 56,
                           decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                           child: const Icon(Icons.add),
                         ),
                         const SizedBox(height: 4),
                         Text('Add "${_searchController.text}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                       ],
                     ),
                   );
                }
                
                final person = filteredPeople[index];
                final isSelected = _selectedIds.contains(person.id);
                
                return GestureDetector(
                  onTap: () => _toggleSelection(person.id),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                              shape: BoxShape.circle,
                              image: person.avatarUrl != null ? DecorationImage(image: NetworkImage(person.avatarUrl!)) : null,
                            ),
                            child: person.avatarUrl == null 
                                ? Center(child: Text(person.name[0], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)))
                                : null,
                          ),
                          if (isSelected)
                            const Positioned(
                              right: 0, top: 0,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                          style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _confirm,
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   backgroundColor: Theme.of(context).primaryColor,
                   foregroundColor: Colors.white,
                 ),
                 child: const Text('Confirm Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),
            ),
          ),
        ],
      ),
    );
  }
}
