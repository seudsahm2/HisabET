import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

final customerContactsProvider = FutureProvider<List<ContactModel>>((
  ref,
) async {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.getCustomerContacts();
});
