import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';
import '../models/trip.dart';
import '../providers/providers.dart';
import '../widgets/add_trip_dialog.dart';
import '../widgets/shimmer_placeholders.dart';
import '../widgets/summary_card.dart';
import '../widgets/trip_list_item.dart';

final _dayLabelFormat = DateFormat('d MMMM yyyy', 'ru');

class ShiftDiaryScreen extends ConsumerWidget {
  const ShiftDiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(summaryProvider(selectedDate));
    final tripsAsync = ref.watch(tripsProvider(selectedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Дневник смен')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTripDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _DaySwitcher(date: selectedDate),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => refreshDiary(ref, selectedDate),
              child: _AnimatedDayContent(
                date: selectedDate,
                navigatingForward: ref.watch(dayNavigationForwardProvider),
                summaryAsync: summaryAsync,
                tripsAsync: tripsAsync,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySwitcher extends ConsumerWidget {
  const _DaySwitcher({required this.date});

  final DateTime date;

  void goTo(WidgetRef ref, DateTime newDate) {
    // Set BEFORE selectedDateProvider, so _AnimatedDayContent reads the
    // correct direction on the very next build that reacts to the date
    // change.
    ref.read(dayNavigationForwardProvider.notifier).state = newDate.isAfter(date);
    ref.read(selectedDateProvider.notifier).state = newDate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => goTo(ref, date.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                goTo(ref, DateTime(picked.year, picked.month, picked.day));
              }
            },
            child: Text(
              _dayLabelFormat.format(date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => goTo(ref, date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDayContent extends StatelessWidget {
  const _AnimatedDayContent({
    required this.date,
    required this.navigatingForward,
    required this.summaryAsync,
    required this.tripsAsync,
  });

  final DateTime date;
  final bool navigatingForward;
  final AsyncValue<DaySummary> summaryAsync;
  final AsyncValue<List<Trip>> tripsAsync;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // AnimatedSwitcher drives one Animation for both children during a
        // transition: the entering child plays it 0→1, the leaving child
        // plays the SAME animation in reverse (1→0). Comparing keys tells
        // us which of the two is being built right now.
        final entering = child.key == ValueKey(date);
        // ListView/ListTile below expect an ambient Material ancestor for
        // their ink feedback; AnimatedSwitcher's extra subtree during the
        // transition can lose that in debug mode without this wrapper.
        final wrapped = Material(color: Colors.transparent, child: child);
        final gluedTarget = entering
            ? Offset(navigatingForward ? 1 : -1, 0)
            : Offset(navigatingForward ? -1 : 1, 0);
        final slide = Tween<Offset>(begin: gluedTarget, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic))
            .animate(animation);
        return SlideTransition(position: slide, child: wrapped);
      },
      child: ListView(
        key: ValueKey(date),
        children: [
          summaryAsync.when(
            data: (summary) => SummaryCard(summary: summary),
            loading: () => const SummaryCardShimmer(),
            error: (err, _) => _ErrorBox(message: '$err'),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Поездки',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          tripsAsync.when(
            data: (trips) => trips.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('В этот день поездок нет')),
                  )
                : Column(
                    children: trips
                        .map((t) => TripListItem(trip: t))
                        .toList(growable: false),
                  ),
            loading: () => const SizedBox(
              height: 220,
              child: TripListShimmer(),
            ),
            error: (err, _) => _ErrorBox(message: '$err'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
