import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotifications();
});
