import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:hisabet/core/presentation/widgets/app_money.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Direction of value for a ledger entry.
enum LedgerDirection {
  /// Value coming toward the user — receivable, cash in, goods given on credit.
  incoming,

  /// Value leaving — payable, cash out, goods taken.
  outgoing,
}

/// A single line in a ledger.
///
/// ## Why this is a row and not a card
///
/// The previous design rendered every transaction as its own elevated card.
/// Stacked, that produces a wall of boxes: the eye has to re-enter each
/// container, amounts never line up, and vertical rhythm is destroyed by the
/// gaps between them. No bank statement, paper or digital, is laid out that
/// way — and the traders this app replaces keep a *ruled notebook*.
///
/// So: rows on one continuous surface, separated by hairlines, amounts
/// right-aligned in a fixed column with tabular figures. Scanning a column of
/// numbers becomes possible, which is the entire point of a ledger.
class AppLedgerRow extends StatelessWidget {
  const AppLedgerRow({
    super.key,
    required this.title,
    required this.amount,
    required this.direction,
    this.subtitle,
    this.meta,
    this.status,
    this.statusTone,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final Decimal amount;
  final LedgerDirection direction;

  /// Second line — counterparty, item breakdown, reference.
  final String? subtitle;

  /// Right-hand secondary line under the amount, e.g. a date.
  final String? meta;

  /// Optional short state word: Pending, Confirmed, Disputed.
  final String? status;
  final Color? statusTone;

  final VoidCallback? onTap;
  final bool dense;

  bool get _isIncoming => direction == LedgerDirection.incoming;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = _isIncoming ? AppColors.positive : AppColors.negative;

    return Semantics(
      button: onTap != null,
      label: '$title, ${_isIncoming ? 'incoming' : 'outgoing'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: dense ? AppDimensions.md : 14,
            ),
            child: Row(
              children: [
                _DirectionMarker(tone: tone, isIncoming: _isIncoming),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null || status != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (status != null) ...[
                              _StatusDot(
                                tone: statusTone ?? colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                status!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusTone ??
                                      colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  '  ·  ',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                            if (subtitle != null)
                              Expanded(
                                child: Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppMoney(
                      amount: amount,
                      size: AppMoneySize.medium,
                      signed: true,
                      showCurrency: false,
                      tone: tone,
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small square carrying the direction arrow.
///
/// Kept modest (34pt) and low-chroma: it is a scanning aid, not an ornament.
/// The arrow means the row is still readable without colour.
class _DirectionMarker extends StatelessWidget {
  const _DirectionMarker({required this.tone, required this.isIncoming});

  final Color tone;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Icon(
        isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
        size: 17,
        color: tone,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
    );
  }
}

/// Groups [AppLedgerRow]s onto one surface with hairline separators.
///
/// Separators are inset to align with the row text, the convention in iOS and
/// in every banking app — a full-bleed rule cuts the leading marker off from
/// its own row.
class AppLedgerGroup extends StatelessWidget {
  const AppLedgerGroup({
    super.key,
    required this.children,
    this.margin,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  /// leading inset (16) + marker (34) + gap (12)
  static const double _separatorInset = 62;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: _separatorInset),
            child: Divider(height: 1, thickness: 1, color: hairline),
          ),
        );
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
