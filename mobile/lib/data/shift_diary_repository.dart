import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';
import '../models/new_trip_request.dart';
import '../models/trip.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class ShiftDiaryRepository {
  ShiftDiaryRepository(this._dio);

  final Dio _dio;

  Future<List<Trip>> fetchTrips(DateTime day) async {
    final response = await _dio.get<List<dynamic>>(
      '/trips',
      queryParameters: {'date': _dateFormat.format(day)},
    );
    return response.data!
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DaySummary> fetchSummary(DateTime day) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/summary',
      queryParameters: {'date': _dateFormat.format(day)},
    );
    return DaySummary.fromJson(response.data!);
  }

  /// Creates a trip. Re-submitting a request with the same [NewTripRequest.id]
  /// is safe: the server returns the already-stored trip (with its original,
  /// server-computed commission) instead of creating a duplicate (HTTP 200
  /// vs 201 on first creation).
  Future<Trip> addTrip(NewTripRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/trips',
      data: request.toJson(),
    );
    return Trip.fromJson(response.data!);
  }
}
