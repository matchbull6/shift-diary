import 'package:flutter/material.dart';

import '../models/trip.dart';

class TripListItem extends StatelessWidget {
  const TripListItem({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final isCard = trip.payment == PaymentMethod.card;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCard ? Colors.indigo.shade50 : Colors.green.shade50,
        child: Icon(
          isCard ? Icons.credit_card : Icons.payments_outlined,
          color: isCard ? Colors.indigo : Colors.green,
        ),
      ),
      title: Text(
        '${trip.startTimeLabel}–${trip.endTimeLabel}'
        '  ${isCard ? 'карта' : 'нал.'}',
      ),
      subtitle: Text('Комиссия: ${trip.commission.round()} ₸'),
      trailing: Text(
        '${trip.amount.round()} ₸',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
