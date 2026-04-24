enum MvpTaskStatus { open, accepted, arrived, inProgress, completed }

class MvpTask {
  MvpTask({
    required this.id,
    required this.locationText,
    required this.description,
    required this.instructions,
    required this.startTime,
    required this.priceMxn,
    required this.status,
    required this.customerId,
    required this.runnerId,
    required this.checkInPhotoUrl,
    required this.progressNote,
    required this.handoffCode,
    required this.createdAt,
  });

  final String id;
  final String locationText;
  final String description;
  final String instructions;
  final DateTime startTime;
  final int priceMxn;
  final MvpTaskStatus status;
  final String customerId;
  final String? runnerId;
  final String? checkInPhotoUrl;
  final String? progressNote;
  final String handoffCode;
  final DateTime createdAt;

  bool get isRunnerActive =>
      status == MvpTaskStatus.accepted ||
      status == MvpTaskStatus.arrived ||
      status == MvpTaskStatus.inProgress;

  MvpTask copyWith({
    String? id,
    String? locationText,
    String? description,
    String? instructions,
    DateTime? startTime,
    int? priceMxn,
    MvpTaskStatus? status,
    String? customerId,
    String? runnerId,
    bool clearRunnerId = false,
    String? checkInPhotoUrl,
    bool clearCheckInPhotoUrl = false,
    String? progressNote,
    bool clearProgressNote = false,
    String? handoffCode,
    DateTime? createdAt,
  }) {
    return MvpTask(
      id: id ?? this.id,
      locationText: locationText ?? this.locationText,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      startTime: startTime ?? this.startTime,
      priceMxn: priceMxn ?? this.priceMxn,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      runnerId: clearRunnerId ? null : (runnerId ?? this.runnerId),
      checkInPhotoUrl: clearCheckInPhotoUrl
          ? null
          : (checkInPhotoUrl ?? this.checkInPhotoUrl),
      progressNote:
          clearProgressNote ? null : (progressNote ?? this.progressNote),
      handoffCode: handoffCode ?? this.handoffCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
