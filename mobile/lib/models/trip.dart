import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trip.g.dart';

enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('card')
  card,
}

final _timeFormat = DateFormat('HH:mm');

@JsonSerializable()
class Trip {
  const Trip({
    required this.id,
    required this.start,
    required this.end,
    required this.amount,
    required this.payment,
    required this.commission,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final double amount;
  final PaymentMethod payment;
  final double commission;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);

  String get startTimeLabel => _timeFormat.format(start);
  String get endTimeLabel => _timeFormat.format(end);
}
