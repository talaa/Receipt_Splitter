import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:uuid/uuid.dart';
import '../data/models/person.dart';

class PersonListState extends Notifier<List<Person>> {
  @override
  List<Person> build() => [];

  Future<void> loadContacts() async {
     // Request permission inside the provider or service. 
     // Usually service handles raw contacts, provider maps to domain implementation.
     if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
        
        final mappedContacts = contacts.map((c) => Person(
            id: const Uuid().v4(),
            name: c.displayName,
            phoneNumber: c.phones.isNotEmpty ? c.phones.first.number : null,
            // Skipping avatar for now
          )).toList();
          
        // Avoid duplicates if loading multiple times? 
        // For now, just replace or append. 
        // Logic: Keep existing manually added, append new contacts? 
        // Or simply replace list. User might have selected people from contacts.
        // For Phase 1, we just provide a list to select from.
        state = [...state, ...mappedContacts]; 
     }
  }

  void addPerson(Person person) {
    state = [...state, person];
  }
}

final personListProvider = NotifierProvider<PersonListState, List<Person>>(PersonListState.new);
