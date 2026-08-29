import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_model.dart';
import '../services/credit_service.dart';

final creditProvider = FutureProvider<List<CreditModel>>((ref) async {
  return CreditService().getCredits();
});

final totalCreditProvider = FutureProvider<double>((ref) async {
  final credits = await ref.watch(creditProvider.future);
  double total = 0;
  for (var c in credits) {
    total += c.remainingBalance;
  }
  return total;
});
