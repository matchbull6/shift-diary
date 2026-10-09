/// Formats a local [DateTime] as an ISO-8601 string with an explicit
/// numeric UTC offset (e.g. `2026-10-01T08:10:00+05:00`), matching what
/// the backend expects and what `DateTime.toIso8601String()` does not
/// produce for non-UTC times.
String toIso8601WithOffset(DateTime local) {
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.abs().inHours.toString().padLeft(2, '0');
  final minutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');

  String two(int v) => v.toString().padLeft(2, '0');

  final datePart = '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-${two(local.day)}';
  final timePart = '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';

  return '$datePart' 'T' '$timePart' '$sign$hours:$minutes';
}
