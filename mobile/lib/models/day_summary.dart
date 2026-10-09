import 'package:json_annotation/json_annotation.dart';

part 'day_summary.g.dart';

@JsonSerializable()
class DaySummary {
  const DaySummary({
    required this.date,
    required this.tripsCount,
    required this.revenue,
    required this.commission,
    required this.payout,
    required this.cash,
    required this.card,
  });

  final String date;
  @JsonKey(name: 'trips_count')
  final int tripsCount;
  final double revenue;
  final double commission;
  final double payout;
  final double cash;
  final double card;

  factory DaySummary.fromJson(Map<String, dynamic> json) => _$DaySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DaySummaryToJson(this);
}
