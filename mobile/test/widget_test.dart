import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shift_diary/data/shift_diary_repository.dart';
import 'package:shift_diary/main.dart';
import 'package:shift_diary/models/day_summary.dart';
import 'package:shift_diary/models/new_trip_request.dart';
import 'package:shift_diary/models/trip.dart';
import 'package:shift_diary/providers/providers.dart';
import 'package:shift_diary/widgets/add_trip_dialog.dart';

class _FakeRepository extends ShiftDiaryRepository {
  _FakeRepository() : super(Dio());

  @override
  Future<DaySummary> fetchSummary(DateTime day) async {
    return const DaySummary(
      date: '2026-10-01',
      tripsCount: 2,
      revenue: 3900,
      commission: 585,
      payout: 3315,
      cash: 1500,
      card: 2400,
    );
  }

  @override
  Future<List<Trip>> fetchTrips(DateTime day) async {
    return [
      Trip(
        id: 't1',
        start: DateTime(2026, 10, 1, 8, 10),
        end: DateTime(2026, 10, 1, 8, 32),
        amount: 2400,
        payment: PaymentMethod.card,
        commission: 360,
      ),
      Trip(
        id: 't2',
        start: DateTime(2026, 10, 1, 9, 5),
        end: DateTime(2026, 10, 1, 9, 20),
        amount: 1500,
        payment: PaymentMethod.cash,
        commission: 225,
      ),
    ];
  }
}

/// addTrip always fails; records the id sent on each call
class _AlwaysFailingAddRepository extends ShiftDiaryRepository {
  _AlwaysFailingAddRepository() : super(Dio());

  final List<String> attemptedIds = [];

  @override
  Future<Trip> addTrip(NewTripRequest request) async {
    attemptedIds.add(request.id);
    throw DioException(
      requestOptions: RequestOptions(path: '/trips'),
      type: DioExceptionType.connectionError,
      message: 'Connection lost',
    );
  }
}

void main() {
  testWidgets('retrying "Сохранить" after a failed submit reuses the same trip id', (tester) async {
      final fakeRepo = _AlwaysFailingAddRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showAddTripDialog(context, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Сумма, ₸'), '1000');

      // Tap "Сохранить" twice — both attempts fail the same way, the
      // dialog just stays open with an error each time. The only thing
      // this test cares about is what id went out on each attempt.
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(fakeRepo.attemptedIds, hasLength(2));
      expect(
        fakeRepo.attemptedIds[0],
        fakeRepo.attemptedIds[1],
        reason: 'retry must reuse the same id so the server\'s id-based '
            'dedup treats it as the same submission, not a new trip',
      );
    },
  );

  testWidgets('shows the day summary from the backend', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const ShiftDiaryApp(),
      ),
    );

    // First frame shows shimmer placeholders while data loads.
    await tester.pump();
    // Let the fake async repository calls resolve.
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // trips_count
    expect(find.text('На руки'), findsOneWidget);
    expect(find.textContaining('315'), findsOneWidget); // payout = 3315
  });
}
