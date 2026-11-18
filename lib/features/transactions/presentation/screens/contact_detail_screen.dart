import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/sync/presentation/screens/reconciliation_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/ledger_history.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/add_transaction_screen.dart';

enum _HistoryFilter { all, sales, manual }

/// One contact's ledger: who they are, where the balance stands, and every
/// entry grouped by day — the digital version of their pages in the notebook.
class ContactDetailScreen extends ConsumerStatefulWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  void _refresh() {
    ref.invalidate(contactTransactionsProvider(widget.contact.id));
    ref.invalidate(contactProvider(widget.contact.id));
    ref.invalidate(allContactsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(contactProvider(widget.contact.id)).valueOrNull ?? widget.contact;
    final transactionsAsync = ref.watch(contactTransactionsProvider(widget.contact.id));
    final transactions = transactionsAsync.valueOrNull ?? const <TransactionModel>[];

    var given = Decimal.zero;
    var received = Decimal.zero;
    for (final tx in transactions) {
      final effect = tx.balanceEffect;
      if (effect >= Decimal.zero) {
        given += effect;
      } else {
        received -= effect;
      }
    }

    final filtered = transactions.where((t) => switch (_filter) {
          _HistoryFilter.sales => t.saleId != null,
          _HistoryFilter.manual => t.saleId == null,
          _HistoryFilter.all => true,
        }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: AppTopBar(
                  eyebrow: contact.roleLabels.isEmpty ? 'CONTACT' : contact.roleLabels.join(' · ').toUpperCase(),
                  title: contact.name,
                  leading: AppTopBarAction(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    AppTopBarAction(
                      icon: Icons.sync_rounded,
                      tooltip: 'Reconcile with their ledger',
                      onTap: () => _openReconciliation(contact),
                    ),
                    AppTopBarAction(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete contact',
                      onTap: () => _confirmDelete(contact),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                sliver: SliverList.list(
                  children: [
                    _IdentityLine(contact: contact),
                    const SizedBox(height: AppDimensions.lg),
                    AppBalancePanel(
                      label: contact.netBalance == Decimal.zero
                          ? 'Settled'
                          : (contact.netBalance > Decimal.zero ? 'They owe you' : 'You owe them'),
                      netBalance: contact.netBalance,
                      receivable: given,
                      payable: received,
                      receivableLabel: 'Given to them',
                      payableLabel: 'Received from them',
                    ),
                    if (contact.linkedUserUid != null || (contact.phoneNumber?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: AppDimensions.md),
                      _ReconcileRow(name: contact.name, onTap: () => _openReconciliation(contact)),
                    ],
                    const SizedBox(height: AppDimensions.xl),
                    Text('HISTORY', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: AppDimensions.sm),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: AppFilterChips<_HistoryFilter>(
                  options: _HistoryFilter.values,
                  selected: _filter,
                  labelBuilder: (f) => switch (f) {
                    _HistoryFilter.all => 'All',
                    _HistoryFilter.sales => 'Sales',
                    _HistoryFilter.manual => 'Manual',
                  },
                  countBuilder: (f) => switch (f) {
                    _HistoryFilter.all => transactions.length,
                    _HistoryFilter.sales => transactions.where((t) => t.saleId != null).length,
                    _HistoryFilter.manual => transactions.where((t) => t.saleId == null).length,
                  },
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
              ...transactionsAsync.when(
                loading: () => [
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
                ],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load history',
                      subtitle: '$e',
                      iconColor: AppColors.negative,
                    ),
                  ),
                ],
                data: (_) => filtered.isEmpty
                    ? [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmptyState(
                            icon: Icons.history_rounded,
                            title: 'No entries yet',
                            subtitle: 'Record what you give and take with "I gave" and "I took" below.',
                          ),
                        ),
                      ]
                    : _historySlivers(filtered, contact),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xxl)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: _EntryButton(
                label: 'I gave',
                caption: 'They owe more',
                icon: Icons.north_east_rounded,
                tone: AppColors.positive,
                onTap: () => _addTransaction(TransactionType.goodsGiven),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _EntryButton(
                label: 'I took',
                caption: 'I owe more',
                icon: Icons.south_west_rounded,
                tone: AppColors.negative,
                onTap: () => _addTransaction(TransactionType.goodsTaken),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _historySlivers(List<TransactionModel> transactions, ContactModel contact) {
    final now = DateTime.now();
    return [
      for (final day in groupByDay(transactions))
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.lg),
          sliver: SliverList.list(
            children: [
              _DayHeader(label: dayLabel(day.day, now), net: day.net),
              const SizedBox(height: AppDimensions.sm),
              AppLedgerGroup(
                children: [
                  for (final tx in day.entries)
                    AppLedgerRow(
                      title: tx.saleId != null ? 'Sale · ${transactionTypeLabel(tx.type)}' : transactionTypeLabel(tx.type),
                      subtitle: notebookFormula(tx) ?? _shortDescription(tx),
                      amount: tx.amount.abs(),
                      direction: tx.balanceEffect >= Decimal.zero ? LedgerDirection.incoming : LedgerDirection.outgoing,
                      meta: DateFormat('h:mm a').format(tx.date),
                      status: switch (tx.status) {
                        TransactionStatus.pending => 'Pending',
                        TransactionStatus.disputed => 'Disputed',
                        TransactionStatus.confirmed => null,
                      },
                      statusTone: tx.status == TransactionStatus.disputed ? AppColors.negative : AppColors.warning,
                      onTap: () => _showEntryActions(tx, contact),
                    ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  String? _shortDescription(TransactionModel tx) {
    final text = tx.description?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  // ── Entry actions ──────────────────────────────────────────────────────

  Future<void> _showEntryActions(TransactionModel tx, ContactModel contact) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _EntryActionsSheet(tx: tx),
    );
    if (action == null || !mounted) return;

    final repo = ref.read(transactionsRepositoryProvider);
    switch (action) {
      case 'open':
        if (tx.saleId != null) {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoicePreviewScreen(saleId: tx.saleId!)));
        } else {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddTransactionScreen(contactId: contact.id, type: tx.type, transactionToEdit: tx),
          ));
        }
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddTransactionScreen(contactId: contact.id, type: tx.type, transactionToEdit: tx),
        ));
      case 'pending':
        await repo.updateTransaction(tx.copyWith(status: TransactionStatus.pending));
      case 'confirmed':
        await repo.updateTransaction(tx.copyWith(status: TransactionStatus.confirmed));
      case 'disputed':
        await repo.updateTransaction(tx.copyWith(status: TransactionStatus.disputed));
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AppDeleteDialog(
            title: 'Delete entry?',
            content: 'Delete this ${transactionTypeLabel(tx.type).toLowerCase()} of ETB ${tx.amount}? This cannot be undone.',
          ),
        );
        if (confirmed == true) await repo.deleteTransaction(tx.id);
    }
    _refresh();
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _openReconciliation(ContactModel contact) {
    if (contact.phoneNumber == null && contact.linkedUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add their phone number to compare ledgers.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReconciliationScreen(
        contactId: contact.id,
        contactName: contact.name,
        contactPhone: contact.phoneNumber,
      ),
    ));
  }

  Future<void> _addTransaction(TransactionType type) async {
    if (!await _ensurePermission('add_transaction', widget.contact.id)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(contactId: widget.contact.id, type: type)),
    );
    _refresh();
  }

  Future<void> _confirmDelete(ContactModel contact) async {
    if (!await _ensurePermission('delete_contact', contact.id)) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDeleteDialog(
        title: 'Delete contact?',
        content: 'Delete "${contact.name}" and all their entries? This cannot be undone.',
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(contactsRepositoryProvider).deleteContact(contact.id);
      await ref.read(auditRepositoryProvider).logAction(
            actorRole: ref.read(currentRoleProvider),
            action: 'contact_deleted',
            entityType: 'contact',
            entityId: contact.id,
            message: 'Contact ${contact.name} was deleted with all transactions.',
          );
      ref.invalidate(recentAuditLogsProvider);
      ref.invalidate(allContactsProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Deleted ${contact.name}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e'), backgroundColor: AppColors.negative));
    }
  }

  Future<bool> _ensurePermission(String attemptedAction, String entityId) async {
    final required = attemptedAction == 'delete_contact' ? TeamPermission.manageTeam : TeamPermission.processSales;
    if (ref.read(hasPermissionProvider(required))) return true;

    final messenger = ScaffoldMessenger.of(context);
    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'permission_denied',
          entityType: 'contact',
          entityId: entityId,
          message: 'Denied $attemptedAction for role ${actorRole.name}.',
        );
    ref.invalidate(recentAuditLogsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('You do not have permission for this action.')));
    return false;
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────────

/// HisabET badge or "Private record", phone number, and verification state —
/// one quiet line under the title.
class _IdentityLine extends StatelessWidget {
  const _IdentityLine({required this.contact});
  final ContactModel contact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = AppTextStyles.labelSmall.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final phone = contact.phoneNumber;
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (contact.linkedUserUid != null) const AppHisabetBadge() else Text('Private record', style: muted),
        if (phone != null && phone.isNotEmpty) Text(phone, style: muted),
        if (contact.verificationStatus == ContactVerificationStatus.pending)
          AppStatusBadge.warning(label: 'Pending', small: true),
        if (contact.verificationStatus == ContactVerificationStatus.expired)
          AppStatusBadge.danger(label: 'Expired', small: true),
      ],
    );
  }
}

class _ReconcileRow extends StatelessWidget {
  const _ReconcileRow({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = isDark ? AppColors.primaryBright : AppColors.primary;
    return AppGroupedRow(
      isFirst: true,
      isLast: true,
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.sync_rounded, color: brand, size: AppDimensions.iconMd),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reconcile ledgers', style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'Compare your entries with $name\'s and fix differences',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.net});
  final String label;
  final Decimal net;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface, fontSize: 14)),
        ),
        if (net != Decimal.zero) ...[
          Text('Net ', style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
          AppMoney.directional(amount: net, size: AppMoneySize.small, showCurrency: false),
        ],
      ],
    );
  }
}

/// "I gave" / "I took": the two ways a notebook line starts. Coloured by what
/// it does to the balance, with a caption so meaning never rests on colour.
class _EntryButton extends StatelessWidget {
  const _EntryButton({
    required this.label,
    required this.caption,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        child: SizedBox(
          height: AppDimensions.buttonHeight + 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: AppDimensions.iconSm),
              const SizedBox(width: AppDimensions.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.buttonLabel.copyWith(color: Colors.white)),
                  Text(
                    caption,
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryActionsSheet extends StatelessWidget {
  const _EntryActionsSheet({required this.tx});
  final TransactionModel tx;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget option(String value, IconData icon, String label, {Color? tone, bool isFirst = false, bool isLast = false}) {
      return AppGroupedRow(
        isFirst: isFirst,
        isLast: isLast,
        onTap: () => Navigator.of(context).pop(value),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSm, color: tone ?? colorScheme.onSurfaceVariant),
            const SizedBox(width: AppDimensions.md),
            Text(label, style: AppTextStyles.cardTitle.copyWith(color: tone ?? colorScheme.onSurface)),
          ],
        ),
      );
    }

    final isSale = tx.saleId != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transactionTypeLabel(tx.type),
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                AppMoney(amount: tx.amount.abs(), size: AppMoneySize.medium),
              ],
            ),
            Text(
              DateFormat('EEE d MMM yyyy · h:mm a').format(tx.date),
              style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppDimensions.lg),
            option('open', isSale ? Icons.receipt_long_rounded : Icons.edit_rounded, isSale ? 'Open invoice' : 'Edit entry',
                isFirst: true, isLast: !isSale),
            if (isSale) option('edit', Icons.edit_rounded, 'Edit entry', isLast: true),
            const SizedBox(height: AppDimensions.md),
            Text('STATUS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: AppDimensions.sm),
            if (tx.status != TransactionStatus.confirmed)
              option('confirmed', Icons.check_circle_outline_rounded, 'Mark confirmed', tone: AppColors.positive, isFirst: true),
            if (tx.status != TransactionStatus.pending)
              option('pending', Icons.schedule_rounded, 'Mark pending',
                  isFirst: tx.status == TransactionStatus.confirmed,
                  isLast: tx.status == TransactionStatus.disputed),
            if (tx.status != TransactionStatus.disputed)
              option('disputed', Icons.report_gmailerrorred_rounded, 'Mark disputed', tone: AppColors.warning, isLast: true),
            const SizedBox(height: AppDimensions.md),
            option('delete', Icons.delete_outline_rounded, 'Delete entry', tone: AppColors.negative, isFirst: true, isLast: true),
          ],
        ),
      ),
    );
  }
}
