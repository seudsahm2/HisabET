import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopController = TextEditingController();

  bool _isLoading = false;
  String? _foundUserUid;
  bool _isVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final userData = await repo.searchUserByPhone(phone);
      if (userData != null) {
        final name = userData['name'];
        if (name != null) {
          _nameController.text = name;
          _foundUserUid = userData['uid']; // Assuming repo returns this
          setState(() => _isVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Found Verified Merchant: $name"),
              backgroundColor: AppColors.give,
            ),
          );
        }
      } else {
        setState(() => _isVerified = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Merchant not found on HisabET, adding locally."),
          ),
        );
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(contactsRepositoryProvider);
      final normalizedPhone = _phoneController.text.isNotEmpty
          ? PhoneUtil.normalize(_phoneController.text.trim())
          : null;

      await repo.addContact(
        _nameController.text.trim(),
        normalizedPhone,
        _shopController.text.trim().isEmpty
            ? null
            : _shopController.text.trim(),
        linkedUserUid: _foundUserUid,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Merchant",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Phone Input (Primary)
                _buildInputCard(
                  label: "Phone Number",
                  icon: Icons.phone_android_rounded,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _searchUser(),
                          decoration: const InputDecoration(
                            hintText: "0911...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _searchUser,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.search,
                                color: _isVerified
                                    ? AppColors.give
                                    : AppColors.primary,
                              ),
                      ),
                    ],
                  ),
                ),

                if (_isVerified)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, size: 16, color: AppColors.give),
                        SizedBox(width: 4),
                        Text(
                          "Verified HisabET User",
                          style: TextStyle(
                            color: AppColors.give,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Name Input
                _buildInputCard(
                  label: "Merchant Name",
                  icon: Icons.person_outline_rounded,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Mr. Abebe",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Name is required" : null,
                  ),
                ),

                const SizedBox(height: 20),

                // Shop Input
                _buildInputCard(
                  label: "Shop / Location (Optional)",
                  icon: Icons.storefront_outlined,
                  child: TextFormField(
                    controller: _shopController,
                    decoration: const InputDecoration(
                      hintText: "Merkato Tera, B-12",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CREATE CONTACT",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
