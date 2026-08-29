import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../models/credit_model.dart';
import '../../services/credit_service.dart';

class CreditHistoryScreen extends StatefulWidget {
  const CreditHistoryScreen({super.key});

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen> {
  late Future<List<CreditModel>> history;

  @override
  void initState() {
    super.initState();
    history = CreditService().getPaidHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(S.of(context, "paidHistory"))),
      body: FutureBuilder<List<CreditModel>>(
        future: history,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(child: Text(S.of(context, "noPaidCredits")));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final credit = items[i];

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD1FAE5),
                    child: Icon(Icons.check, color: AppColors.primary),
                  ),
                  title: Text(
                    credit.client.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${credit.meters} m • ${S.of(context, "paid")}"),
                  trailing: Text(
                    "${credit.totalCredit.toStringAsFixed(0)} ETB",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
