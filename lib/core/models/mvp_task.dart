enum MvpTaskStatus { open, accepted, arrived, inProgress, completed }

enum NegotiationStatus { none, pending, accepted, rejected }

class MvpTask {
  MvpTask({
    required this.id,
    required this.locationText,
    required this.description,
    required this.instructions,
    required this.startDate,
    required this.startTimeSlot,
    required this.estimatedDuration,
    required this.priceMxn,
    required this.status,
    required this.customerId,
    required this.runnerId,
    required this.checkInPhotoUrl,
    required this.progressNote,
    required this.handoffCode,
    required this.createdAt,
    this.runnerCounterOfferMxn,
    this.negotiationStatus = NegotiationStatus.none,
  });

  final String id;
  final String locationText;
  final String description;
  final String instructions;
  final DateTime startDate;
  final String startTimeSlot;
  final String estimatedDuration;
  final int priceMxn;
  final MvpTaskStatus status;
  final String customerId;
  final String? runnerId;
  final String? checkInPhotoUrl;
  final String? progressNote;
  final String handoffCode;
  final DateTime createdAt;
  final int? runnerCounterOfferMxn;
  final NegotiationStatus negotiationStatus;

  bool get isRunnerActive =>
      status == MvpTaskStatus.accepted ||
      status == MvpTaskStatus.arrived ||
      status == MvpTaskStatus.inProgress;

  int get displayPriceMxn =>
      negotiationStatus == NegotiationStatus.accepted &&
              runnerCounterOfferMxn != null
          ? runnerCounterOfferMxn!
          : priceMxn;

  MvpTask copyWith({
    String? id,
    String? locationText,
    String? description,
    String? instructions,
    DateTime? startDate,
    String? startTimeSlot,
    String? estimatedDuration,
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
    int? runnerCounterOfferMxn,
    bool clearRunnerCounterOfferMxn = false,
    NegotiationStatus? negotiationStatus,
  }) {
    return MvpTask(
      id: id ?? this.id,
      locationText: locationText ?? this.locationText,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      startTimeSlot: startTimeSlot ?? this.startTimeSlot,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
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
      runnerCounterOfferMxn: clearRunnerCounterOfferMxn
          ? null
          : (runnerCounterOfferMxn ?? this.runnerCounterOfferMxn),
      negotiationStatus: negotiationStatus ?? this.negotiationStatus,
    );
  }
}
