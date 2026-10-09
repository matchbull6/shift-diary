import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';

final _currency = NumberFormat.decimalPattern('ru');

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Дневник смен', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _Row(label: 'Поездок', value: '${summary.tripsCount}'),
            _Row(label: 'Выручка', value: '${_currency.format(summary.revenue)} ₸'),
            _Row(label: 'Комиссия', value: '-${_currency.format(summary.commission)} ₸'),
            _Row(
              label: 'Наличные / карта',
              value: '${_currency.format(summary.cash)} / ${_currency.format(summary.card)}',
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('На руки', style: theme.textTheme.titleMedium),
                Text(
                  '${_currency.format(summary.payout)} ₸',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
