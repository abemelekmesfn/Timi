import 'api/api_service.dart';
import '../models/credit_model.dart';
import '../models/client_model.dart';

class CreditService {
  Future<List<CreditModel>> getCredits() async {
    final res = await ApiService.dio.get("/credits/");

    return (res.data as List).map((e) => CreditModel.fromJson(e)).toList();
  }

  Future<List<ClientModel>> searchClients(String text) async {
    final res = await ApiService.dio.get(
      "/credits/clients/search/",
      queryParameters: {"search": text},
    );

    return (res.data as List).map((e) => ClientModel.fromJson(e)).toList();
  }

  Future<ClientModel> createClient({
    required String firstName,
    required String lastName,
  }) async {
    final res = await ApiService.dio.post(
      "/credits/clients/search/",
      data: {"first_name": firstName, "last_name": lastName},
    );

    return ClientModel.fromJson(res.data);
  }

  Future<void> createCredit({
    required String clientId,
    required double meters,
    required double pricePerMeter,
  }) async {
    await ApiService.dio.post("/credits/", data: {
      "client_id": clientId,
      "meters": meters,
      "price_per_meter": pricePerMeter,
    });
  }

  Future<void> receivePayment({
    required String id,
    required double amount,
  }) async {
    await ApiService.dio.post("/credits/$id/pay/", data: {"amount": amount});
  }

  Future<void> editCredit(String id, Map<String, dynamic> data) async {
    await ApiService.dio.put("/credits/$id/", data: data);
  }

  Future<List<CreditModel>> getPaidHistory() async {
    final res = await ApiService.dio.get("/credits/history/");

    return (res.data as List).map((e) => CreditModel.fromJson(e)).toList();
  }
}
