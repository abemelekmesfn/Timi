import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../models/client_model.dart';
import '../../services/credit_service.dart';
import '../../core/theme/app_colors.dart';

class NewCreditScreen extends StatefulWidget {
  const NewCreditScreen({super.key});

  @override
  State<NewCreditScreen> createState() => _NewCreditScreenState();
}

class _NewCreditScreenState extends State<NewCreditScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final meters = TextEditingController();
  final price = TextEditingController();

  List<ClientModel> suggestions = [];
  ClientModel? selectedClient;

  double total = 0;

  void calculate() {
    final m = double.tryParse(meters.text) ?? 0;
    final p = double.tryParse(price.text) ?? 0;

    setState(() {
      total = m * p;
    });
  }

  Future<void> search(String text) async {
    if (text.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final result = await CreditService().searchClients(text);

    setState(() {
      suggestions = result;
    });
  }

  Future<void> save() async {
    try {
      if (selectedClient == null) {
        selectedClient = await CreditService().createClient(
          firstName: firstName.text,
          lastName: lastName.text,
        );
      }

      await CreditService().createCredit(
        clientId: selectedClient!.id,
        meters: double.parse(meters.text),
        pricePerMeter: double.parse(price.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "creditRegistered"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "newCredit"))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: firstName,
            decoration: InputDecoration(labelText: S.of(context, "firstName")),
            onChanged: search,
          ),

          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (_, i) {
                  final client = suggestions[i];

                  return ListTile(
                    title: Text(client.fullName),
                    onTap: () {
                      selectedClient = client;
                      firstName.text = client.firstName;
                      lastName.text = client.lastName;

                      setState(() {
                        suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          TextField(
            controller: lastName,
            decoration: InputDecoration(
              labelText: "${S.of(context, "lastName")} (${S.of(context, "optional")})",
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: meters,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: S.of(context, "meters")),
            onChanged: (_) => calculate(),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: S.of(context, "pricePerMeter")),
            onChanged: (_) => calculate(),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(S.of(context, "totalCredit"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    "${total.toStringAsFixed(0)} ETB",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton(onPressed: save, child: Text(S.of(context, "register"))),
        ],
      ),
    );
  }
}
