import 'package:json_annotation/json_annotation.dart';
import 'package:shift_diary/models/trip.dart';

part 'new_trip_request.g.dart';

@JsonSerializable()
class NewTripRequest {
  const NewTripRequest({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
  });

  final String id;
  final String start;
  final String end;
  final double amount;
  final PaymentMethod payment;

  factory NewTripRequest.fromJson(Map<String, dynamic> json) => _$NewTripRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NewTripRequestToJson(this);
}
