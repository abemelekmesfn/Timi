import 'client_model.dart';

class CreditModel {
  final String id;
  final ClientModel client;
  final double meters;
  final double pricePerMeter;
  final double totalCredit;
  final double paidAmount;
  final double remainingBalance;
  final String status;

  CreditModel({
    required this.id,
    required this.client,
    required this.meters,
    required this.pricePerMeter,
    required this.totalCredit,
    required this.paidAmount,
    required this.remainingBalance,
    required this.status,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json["id"],
      client: ClientModel.fromJson(json["client"]),
      meters: double.parse(json["meters"].toString()),
      pricePerMeter: double.parse(json["price_per_meter"].toString()),
      totalCredit: double.parse(json["total_credit"].toString()),
      paidAmount: double.parse(json["paid_amount"].toString()),
      remainingBalance: double.parse(json["remaining_balance"].toString()),
      status: json["status"],
    );
  }
}
