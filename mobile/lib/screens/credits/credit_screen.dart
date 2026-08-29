import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/credit_tile.dart';

import 'new_credit_screen.dart';
import 'credit_detail_screen.dart';
import 'credit_history_screen.dart';

class CreditScreen extends ConsumerStatefulWidget {
  const CreditScreen({super.key});

  @override
  ConsumerState<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends ConsumerState<CreditScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: AppBar(
        title: Text(S.of(context, "credit")),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreditHistoryScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewCreditScreen()),
          );

          ref.invalidate(creditProvider);
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, "searchClient"),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: credits.when(
              data: (list) {
                final filtered = list.where((e) {
                  return e.client.fullName.toLowerCase().contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(S.of(context, "noCredits")));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(creditProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      return CreditTile(
                        credit: filtered[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreditDetailScreen(credit: filtered[index]),
                            ),
                          );

                          ref.invalidate(creditProvider);
                        },
                      );
                    },
                  ),
                );
              },

              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
