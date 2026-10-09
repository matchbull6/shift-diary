import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/new_trip_request.dart';
import '../models/trip.dart';
import '../providers/providers.dart';
import '../utils/iso8601.dart';

Future<void> showAddTripDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AddTripDialog(),
  );
}

class AddTripDialog extends ConsumerStatefulWidget {
  const AddTripDialog({super.key});

  @override
  ConsumerState<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends ConsumerState<AddTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  // Plain text fields instead of showTimePicker — see commit message for
  // why: Flutter's built-in TimePickerDialog has a hardcoded ~310px minimum
  // content width (in both dial AND text-entry mode) plus a fixed 16px
  // insetPadding, neither overridable via public API or theme. Below
  // ~342px screen width it has to scroll sideways to show its own OK
  // button. Inline fields inside our own dialog have no such floor — they
  // just use whatever width AlertDialog's (already-responsive) content
  // area gives them.
  final _startHourCtrl = TextEditingController(text: '09');
  final _startMinuteCtrl = TextEditingController(text: '00');
  final _endHourCtrl = TextEditingController(text: '09');
  final _endMinuteCtrl = TextEditingController(text: '20');

  PaymentMethod _payment = PaymentMethod.cash;
  bool _submitting = false;
  String? _error;

  // Generated once per dialog, not per submit attempt —
  // if the first POST reaches the server but the response is lost (timeout,
  // dropped connection) and the user taps "Сохранить" again, this retry
  // must reuse the same id so the server's id-based dedup actually catches
  // it instead of creating a second trip.
  late final String _tripId = const Uuid().v4();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _startHourCtrl.dispose();
    _startMinuteCtrl.dispose();
    _endHourCtrl.dispose();
    _endMinuteCtrl.dispose();
    super.dispose();
  }

  /// Null if either field doesn't hold a valid, in-range number — the form's
  /// own field validators are expected to have already caught that and
  /// blocked submission before this is called with bad input.
  DateTime? _combine(DateTime day, TextEditingController hourCtrl, TextEditingController minuteCtrl) {
    final hour = int.tryParse(hourCtrl.text);
    final minute = int.tryParse(minuteCtrl.text);
    if (hour == null || hour > 23 || minute == null || minute > 59) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final day = ref.read(selectedDateProvider);
    final startDt = _combine(day, _startHourCtrl, _startMinuteCtrl);
    final endDt = _combine(day, _endHourCtrl, _endMinuteCtrl);
    if (startDt == null || endDt == null) return; // field validators already caught this

    if (!endDt.isAfter(startDt)) {
      setState(() => _error = 'Время окончания должно быть позже начала');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final request = NewTripRequest(
      id: _tripId,
      start: toIso8601WithOffset(startDt),
      end: toIso8601WithOffset(endDt),
      amount: double.parse(_amountCtrl.text),
      payment: _payment,
    );

    try {
      await ref.read(repositoryProvider).addTrip(request);
      refreshDiary(ref, day);
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _error = _describeError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _describeError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      // FastAPI's 422 validation errors: a list of {msg, loc, ...}.
      if (detail is List) {
        final messages = detail
            .map((d) => d is Map ? d['msg']?.toString() : d.toString())
            .whereType<String>();
        return messages.join('\n');
      }
      // Our own HTTPException(detail=...) errors (e.g. 409 id conflict):
      // detail is a plain string.
      if (detail is String) return detail;
    }
    return 'Не удалось сохранить поездку: ${e.message}';
  }

  @override
  Widget build(BuildContext context) {
    // Default AlertDialog inset is 40px each side. Below 360dp width that
    // alone eats a big share of the screen, so drop it to 0 and let the
    // dialog span the full width; wider screens keep an 16px margin.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = screenWidth < 360 ? 0.0 : 16.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
      title: const Text('Новая поездка'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeRow(label: 'Начало', hourCtrl: _startHourCtrl, minuteCtrl: _startMinuteCtrl),
              const SizedBox(height: 8),
              _TimeRow(label: 'Окончание', hourCtrl: _endHourCtrl, minuteCtrl: _endMinuteCtrl),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Сумма, ₸'),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Сумма должна быть больше 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PaymentMethodToggle(
                selected: _payment,
                onChanged: (method) => setState(() => _payment = method),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Two buttons splitting the available width 50/50 (Expanded), instead of
/// SegmentedButton — SegmentedButton sizes to its labels' intrinsic width
/// and overflows the Row on narrow screens; Expanded can't overflow by
/// construction, it just shrinks (text ellipsizes in the worst case).
class _PaymentMethodToggle extends StatelessWidget {
  const _PaymentMethodToggle({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _option(context, PaymentMethod.cash, 'Нал.')),
        const SizedBox(width: 8),
        Expanded(child: _option(context, PaymentMethod.card, 'Карта')),
      ],
    );
  }

  Widget _option(BuildContext context, PaymentMethod method, String label) {
    final isSelected = method == selected;
    return OutlinedButton(
      onPressed: () => onChanged(method),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? Theme.of(context).colorScheme.secondaryContainer : null,
      ),
      child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

/// Label + "HH : MM" inline text entry — see _AddTripDialogState doc comment
/// on why this replaces showTimePicker.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.hourCtrl,
    required this.minuteCtrl,
  });

  final String label;
  final TextEditingController hourCtrl;
  final TextEditingController minuteCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(width: 44, child: _TwoDigitField(controller: hourCtrl, max: 23)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':'),
        ),
        SizedBox(width: 44, child: _TwoDigitField(controller: minuteCtrl, max: 59)),
      ],
    );
  }
}

class _TwoDigitField extends StatelessWidget {
  const _TwoDigitField({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      maxLength: 2,
      decoration: const InputDecoration(counterText: '', isDense: true),
      validator: (v) {
        final value = int.tryParse(v ?? '');
        return (value == null || value > max) ? '' : null;
      },
    );
  }
}
