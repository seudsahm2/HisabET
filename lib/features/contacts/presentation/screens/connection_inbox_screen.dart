import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

class ConnectionInboxScreen extends ConsumerStatefulWidget {
  const ConnectionInboxScreen({super.key});

  @override
  ConsumerState<ConnectionInboxScreen> createState() => _ConnectionInboxScreenState();
}

class _ConnectionInboxScreenState extends ConsumerState<ConnectionInboxScreen> {
  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      final repo = ref.read(contactsRepositoryProvider);
      
      // 1. Add them as a verified contact
      final rolesList = (request['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      await repo.addContact(
        request['fromName']?.toString() ?? 'Unknown User',
        request['fromPhone']?.toString(),
        null, // shop
        linkedUserUid: request['fromUid']?.toString(),
        verificationMethod: 'network',
        isRetailer: rolesList.contains('Retailer'),
        isWholesaler: rolesList.contains('Wholesaler'),
        isBroker: rolesList.contains('Broker'),
        isSupplier: rolesList.contains('Supplier'),
      );

      // 2. Mark request as accepted in Firestore
      final requestId = request['id'] as String;
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added back successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
        ref.invalidate(allContactsProvider);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  Future<void> _ignoreRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'ignored'});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(connectionRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.negative))),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppDimensions.md),
                  const Text(
                    'No pending requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  const Text(
                    'When someone adds you to their contacts,\nit will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.lg),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, index) {
              final request = requests[index];
              final name = request['fromName']?.toString() ?? 'Unknown User';
              final phone = request['fromPhone']?.toString() ?? '';
              final email = request['fromEmail']?.toString() ?? '';
              final timestamp = request['timestamp'] as Timestamp?;
              final dateStr = timestamp != null 
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}' 
                  : '';

              return AppCard(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              if (phone.isNotEmpty || email.isNotEmpty)
                                Text(
                                  phone.isNotEmpty ? phone : email,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    const Text(
                      'This user added you to their contacts. Would you like to add them back?',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _ignoreRequest(request['id'] as String),
                          child: const Text('Ignore', style: TextStyle(color: AppColors.textHint)),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        ElevatedButton.icon(
                          onPressed: () => _acceptRequest(request),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Add Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
