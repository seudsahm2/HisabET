import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';

class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(allContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(
              child: Text(
                'No contacts yet.\nTap + to add your first merchant.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final balanceColor = contact.netBalance.toDouble() >= 0
                  ? Colors.green
                  : Colors.red;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.name[0].toUpperCase()),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber ?? 'No phone'),
                  trailing: Text(
                    '${contact.netBalance.toDouble() >= 0 ? '+' : ''}${contact.netBalance}',
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to Contact Detail / Transactions
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
          // Refresh the list after returning
          ref.invalidate(allContactsProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
