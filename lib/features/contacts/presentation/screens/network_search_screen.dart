import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

class NetworkSearchScreen extends ConsumerStatefulWidget {
  const NetworkSearchScreen({super.key});

  @override
  ConsumerState<NetworkSearchScreen> createState() => _NetworkSearchScreenState();
}

class _NetworkSearchScreenState extends ConsumerState<NetworkSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = [];
    });

    final repo = ref.read(contactsRepositoryProvider);
    final results = await repo.searchNetwork(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, dynamic> user) async {
    try {
      final repo = ref.read(contactsRepositoryProvider);
      
      final email = user['email']?.toString();
      final phone = user['phone']?.toString();
      final rolesList = (user['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      await repo.addContact(
        user['name']?.toString() ?? 'Unknown Business',
        phone,
        user['shop']?.toString(),
        linkedUserUid: user['uid']?.toString(),
        verificationMethod: email != null && email.isNotEmpty ? 'email' : 'phone',
        isRetailer: rolesList.contains('Retailer'),
        isWholesaler: rolesList.contains('Wholesaler'),
        isBroker: rolesList.contains('Broker'),
        isSupplier: rolesList.contains('Supplier'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
        // Refresh contacts list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HisabET Directory'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search by Name, Email, or Phone...',
                    onChanged: (_) {},
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                ElevatedButton(
                  onPressed: _isLoading ? null : _performSearch,
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Find'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.md),
            const Text(
              'No users found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.sm),
            const Text(
              'Try searching by an exact email or phone number.',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt_outlined, size: 64, color: AppColors.primaryLight),
            const SizedBox(height: AppDimensions.md),
            const Text(
              'Discover Network',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.sm),
            const Text(
              'Find businesses instantly to add as verified contacts.',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.lg),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, index) {
        final user = _results[index];
        final uid = user['uid']?.toString();
        final name = user['name']?.toString() ?? 'Unknown';
        final email = user['email']?.toString() ?? '';
        final phone = user['phone']?.toString() ?? '';
        final roles = (user['roles'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? '';

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final isCurrentUser = uid != null && currentUid == uid;

        return AppCard(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
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
                    if (roles.isNotEmpty)
                      Text(roles.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    if (email.isNotEmpty || phone.isNotEmpty)
                      Text(
                        email.isNotEmpty ? email : phone,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              if (isCurrentUser)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                  child: Text(
                    'This is you',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint),
                  ),
                )
              else
                OutlinedButton.icon(
                  label: const Text('Add'),
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _addContact(user),
                ),
            ],
          ),
        );
      },
    );
  }
}
