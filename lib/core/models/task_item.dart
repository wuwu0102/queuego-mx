import '../constants/app_enums.dart';

class TaskItem {
  const TaskItem({
    required this.taskId,
    required this.customerId,
    this.runnerId,
    required this.title,
    required this.category,
    required this.placeName,
    required this.address,
    this.lat,
    this.lng,
    required this.scheduledDate,
    required this.arrivalTime,
    required this.estimatedWaitMinutes,
    required this.description,
    required this.offeredPrice,
    this.currency = 'MXN',
    required this.requiresPhoto,
    required this.requiresLiveUpdates,
    required this.notes,
    required this.prohibitedAcknowledged,
    required this.status,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.createdAt,
    required this.updatedAt,
  });

  final String taskId;
  final String customerId;
  final String? runnerId;
  final String title;
  final TaskCategory category;
  final String placeName;
  final String address;
  final double? lat;
  final double? lng;
  final DateTime scheduledDate;
  final String arrivalTime;
  final int estimatedWaitMinutes;
  final String description;
  final double offeredPrice;
  final String currency;
  final bool requiresPhoto;
  final bool requiresLiveUpdates;
  final String notes;
  final bool prohibitedAcknowledged;
  final TaskStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}
