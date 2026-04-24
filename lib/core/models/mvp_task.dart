enum MvpTaskStatus { open, accepted, completed }

class MvpTask {
  MvpTask({
    required this.id,
    required this.locationText,
    required this.description,
    required this.startTime,
    required this.priceMxn,
    required this.status,
    required this.customerId,
    required this.runnerId,
    required this.createdAt,
  });

  final String id;
  final String locationText;
  final String description;
  final DateTime startTime;
  final double priceMxn;
  final MvpTaskStatus status;
  final String customerId;
  final String? runnerId;
  final DateTime createdAt;

  MvpTask copyWith({
    String? id,
    String? locationText,
    String? description,
    DateTime? startTime,
    double? priceMxn,
    MvpTaskStatus? status,
    String? customerId,
    String? runnerId,
    bool clearRunnerId = false,
    DateTime? createdAt,
  }) {
    return MvpTask(
      id: id ?? this.id,
      locationText: locationText ?? this.locationText,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      priceMxn: priceMxn ?? this.priceMxn,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      runnerId: clearRunnerId ? null : (runnerId ?? this.runnerId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
