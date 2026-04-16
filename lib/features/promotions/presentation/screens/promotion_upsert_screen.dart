import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/promotions/data/models/promotion_model.dart';
import 'package:hisabet/features/promotions/presentation/providers/promotions_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class PromotionUpsertScreen extends ConsumerStatefulWidget {
  final PromotionModel? promotionToEdit;

  const PromotionUpsertScreen({super.key, this.promotionToEdit});

  @override
  ConsumerState<PromotionUpsertScreen> createState() =>
      _PromotionUpsertScreenState();
}

class _PromotionUpsertScreenState extends ConsumerState<PromotionUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController(text: '0');
  final _minOrderController = TextEditingController(text: '0');
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();

  PromotionDiscountType _discountType = PromotionDiscountType.fixed;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.promotionToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.promotionToEdit;
    if (item == null) return;

    _codeController.text = item.code;
    _titleController.text = item.title;
    _descriptionController.text = item.description ?? '';
    _discountType = item.discountType;
    _discountValueController.text = item.discountValue.toString();
    _minOrderController.text = item.minOrderTotal.toString();
    _maxDiscountController.text = item.maxDiscountAmount?.toString() ?? '';
    _usageLimitController.text = item.usageLimit?.toString() ?? '';
    _startsAt = item.startsAt;
    _endsAt = item.endsAt;
    _isActive = item.isActive;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Promotion' : 'New Promotion'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                controller: _codeController,
                label: 'Code',
                hint: 'e.g. NEW10',
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Code required' : null,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _titleController,
                label: 'Title',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _descriptionController,
                label: 'Description (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<PromotionDiscountType>(
                initialValue: _discountType,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(
                    value: PromotionDiscountType.fixed,
                    child: Text('Fixed amount'),
                  ),
                  DropdownMenuItem(
                    value: PromotionDiscountType.percent,
                    child: Text('Percentage'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _discountType = value);
                },
              ),
              const SizedBox(height: 10),
              _field(
                controller: _discountValueController,
                label: _discountType == PromotionDiscountType.percent
                    ? 'Discount %'
                    : 'Discount amount (ETB)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 10),
              _field(
                controller: _minOrderController,
                label: 'Minimum order total (ETB)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 10),
              _field(
                controller: _maxDiscountController,
                label: 'Max discount (optional, ETB)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 10),
              _field(
                controller: _usageLimitController,
                label: 'Usage limit (optional)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text(
                        _startsAt == null
                            ? 'Set Start Date'
                            : 'Start: ${_fmtDate(_startsAt!)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text(
                        _endsAt == null
                            ? 'Set End Date'
                            : 'End: ${_fmtDate(_endsAt!)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'UPDATE PROMOTION' : 'SAVE PROMOTION',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startsAt : _endsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsAt = picked;
      } else {
        _endsAt = picked;
      }
    });
  }

  String _fmtDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
    );
  }

  Future<void> _save() async {
    final allowed = await _ensurePromotionPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_promotion' : 'create_promotion',
      entityId: widget.promotionToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;

    final discount =
        Decimal.tryParse(_discountValueController.text.trim()) ?? Decimal.zero;
    final minOrder =
        Decimal.tryParse(_minOrderController.text.trim()) ?? Decimal.zero;
    final maxDiscount = Decimal.tryParse(_maxDiscountController.text.trim());
    final usageLimit = int.tryParse(_usageLimitController.text.trim());

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(promotionsRepositoryProvider);
      final actorRole = ref.read(currentRoleProvider);

      if (_isEditing) {
        final item = widget.promotionToEdit!;
        await repo.updatePromotion(
          PromotionModel(
            id: item.id,
            code: _codeController.text.trim().toUpperCase(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            discountType: _discountType,
            discountValue: discount,
            minOrderTotal: minOrder,
            maxDiscountAmount: maxDiscount,
            startsAt: _startsAt,
            endsAt: _endsAt,
            isActive: _isActive,
            usageLimit: usageLimit,
            usedCount: item.usedCount,
            createdAt: item.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        await ref
            .read(auditRepositoryProvider)
            .logAction(
              actorRole: actorRole,
              action: 'promotion_updated',
              entityType: 'promotion',
              entityId: item.id,
              message: 'Promotion ${item.code} updated.',
            );
      } else {
        await repo.addPromotion(
          code: _codeController.text.trim().toUpperCase(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          discountType: _discountType,
          discountValue: discount,
          minOrderTotal: minOrder,
          maxDiscountAmount: maxDiscount,
          startsAt: _startsAt,
          endsAt: _endsAt,
          isActive: _isActive,
          usageLimit: usageLimit,
        );
        await ref
            .read(auditRepositoryProvider)
            .logAction(
              actorRole: actorRole,
              action: 'promotion_created',
              entityType: 'promotion',
              message:
                  'Promotion ${_codeController.text.trim().toUpperCase()} created.',
            );
      }

      ref.invalidate(allPromotionsProvider);
      ref.invalidate(recentAuditLogsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _ensurePromotionPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(
      hasPermissionProvider(TeamPermission.processSales),
    );
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref
        .read(auditRepositoryProvider)
        .logAction(
          actorRole: actorRole,
          action: 'permission_denied',
          entityType: 'promotion',
          entityId: entityId,
          message: 'Denied $attemptedAction for role ${actorRole.name}.',
        );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to manage promotions.'),
        ),
      );
    }
    return false;
  }
}
