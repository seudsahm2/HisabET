import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/customers/presentation/providers/customers_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class CustomerProfileUpsertScreen extends ConsumerStatefulWidget {
  final ContactModel? customerToEdit;

  const CustomerProfileUpsertScreen({super.key, this.customerToEdit});

  @override
  ConsumerState<CustomerProfileUpsertScreen> createState() => _CustomerProfileUpsertScreenState();
}

class _CustomerProfileUpsertScreenState extends ConsumerState<CustomerProfileUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _loyaltyPointsController = TextEditingController(text: '0');

  bool _isLoading = false;
  bool get _isEditing => widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customerToEdit;
    if (customer == null) return;

    _nameController.text = customer.name;
    _phoneController.text = customer.phoneNumber ?? '';
    _shopController.text = customer.shopNumber ?? '';
    _creditLimitController.text = customer.creditLimit.toString();
    _loyaltyPointsController.text = customer.loyaltyPoints.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopController.dispose();
    _creditLimitController.dispose();
    _loyaltyPointsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    final allowed = await _ensureCustomerPermission(context, ref, attemptedAction: _isEditing ? 'update_customer_profile' : 'create_customer_profile', entityId: widget.customerToEdit?.id);
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      final actorRole = ref.read(currentRoleProvider);

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final shop = _shopController.text.trim();
      final creditLimit = Decimal.tryParse(_creditLimitController.text.trim()) ?? Decimal.zero;
      final loyaltyPoints = int.tryParse(_loyaltyPointsController.text.trim()) ?? 0;

      String customerId;
      if (_isEditing) {
        customerId = widget.customerToEdit!.id;
      } else {
        customerId = await contactsRepo.addContact(name, phone.isEmpty ? null : phone, shop.isEmpty ? null : shop, role: ContactRole.merchant);
      }

      await contactsRepo.updateCustomerProfile(id: customerId, name: name, phone: phone.isEmpty ? null : phone, shop: shop.isEmpty ? null : shop, creditLimit: creditLimit, loyaltyPoints: loyaltyPoints);

      await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: _isEditing ? 'customer_profile_updated' : 'customer_profile_created', entityType: 'customer', entityId: customerId, message: 'Customer profile for $name was ${_isEditing ? 'updated' : 'created'}.');

      ref.invalidate(allContactsProvider);
      ref.invalidate(customerContactsProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'New CRM Profile'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
          children: [
            AppFormSection(
              title: 'Identity Data',
              icon: Icons.person_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Customer Name', border: InputBorder.none, hintText: 'Company or Person'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number (Optional)', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Customer Perks & Limits',
              icon: Icons.bar_chart_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _creditLimitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Owed Limit (Max Allowed Debt)', prefixText: 'ETB ', border: InputBorder.none),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _loyaltyPointsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Active Loyalty Points', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Location',
              icon: Icons.location_on_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _shopController,
                    decoration: const InputDecoration(labelText: 'Shop / Physical Address', border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensureCustomerPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'customer', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}
