import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_config.dart';
import '../data/shift_diary_repository.dart';
import '../models/day_summary.dart';
import '../models/trip.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return dio;
});

final repositoryProvider = Provider<ShiftDiaryRepository>((ref) {
  return ShiftDiaryRepository(ref.watch(dioProvider));
});

/// Currently selected day in the diary. Defaults to today.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// true = navigating to a later day (content enters from the right);
/// false = navigating to an earlier day (content enters from the left).
/// Set explicitly, alongside [selectedDateProvider], by whatever UI triggers
/// the day change — see _DaySwitcher in shift_diary_screen.dart.
final dayNavigationForwardProvider = StateProvider<bool>((ref) => true);

/// Keyed by day, NOT auto-disposed: once a day has been fetched, its result
/// stays cached for the lifetime of the app — switching away and back shows
/// it instantly instead of re-fetching. Pull-to-refresh (see
/// _DaySwitcher/RefreshIndicator) explicitly invalidates just that day's
/// entry via [refreshDiary]; nothing else triggers a re-fetch of a day
/// that's already loaded.
final summaryProvider = FutureProvider.family<DaySummary, DateTime>((ref, day) {
  return ref.watch(repositoryProvider).fetchSummary(day);
});

final tripsProvider = FutureProvider.family<List<Trip>, DateTime>((ref, day) {
  return ref.watch(repositoryProvider).fetchTrips(day);
});

/// Refreshes both the summary and the trip list for [day] (e.g. pull-to-
/// refresh, or after adding a new trip). Riverpod's AsyncValue.when()
/// defaults to skipLoadingOnRefresh: true, so this does NOT flip the UI back
/// to the shimmer/loading state — the previous data stays visible while the
/// new fetch is in flight, same as a normal pull-to-refresh elsewhere.
void refreshDiary(WidgetRef ref, DateTime day) {
  ref.invalidate(summaryProvider(day));
  ref.invalidate(tripsProvider(day));
}
