import 'dart:typed_data';

enum MvpTaskStatus {
  open,
  negotiating,
  accepted,
  arrived,
  inProgress,
  waitingForCustomer,
  completed,
  cancelled,
}

enum NegotiationStatus { none, pending, accepted, rejected }

class MvpTask {
  MvpTask({
    required this.id,
    required this.locationText,
    required this.description,
    required this.instructions,
    required this.startDate,
    required this.startTimeSlot,
    required this.estimatedTaskHours,
    required this.customerArrivalBufferHours,
    required this.hourlyRateMxn,
    required this.status,
    required this.customerId,
    required this.runnerId,
    required this.checkInImageBytes,
    required this.progressNote,
    required this.handoffCode,
    required this.createdAt,
    required this.waitingStartedAt,
    this.runnerCounterOfferTotalMxn,
    this.negotiationStatus = NegotiationStatus.none,
  });

  final String id;
  final String locationText;
  final String description;
  final String instructions;
  final DateTime startDate;
  final String startTimeSlot;
  final double estimatedTaskHours;
  final double customerArrivalBufferHours;
  final double hourlyRateMxn;
  final MvpTaskStatus status;
  final String customerId;
  final String? runnerId;
  final Uint8List? checkInImageBytes;
  final String? progressNote;
  final String handoffCode;
  final DateTime createdAt;
  final DateTime? waitingStartedAt;
  final double? runnerCounterOfferTotalMxn;
  final NegotiationStatus negotiationStatus;

  bool get isRunnerActive =>
      status == MvpTaskStatus.accepted ||
      status == MvpTaskStatus.arrived ||
      status == MvpTaskStatus.inProgress ||
      status == MvpTaskStatus.waitingForCustomer;

  double get estimatedTotalHours =>
      estimatedTaskHours + customerArrivalBufferHours;

  double get suggestedTotalPriceMxn => estimatedTotalHours * hourlyRateMxn;

  double get displayTotalPriceMxn =>
      negotiationStatus == NegotiationStatus.accepted &&
              runnerCounterOfferTotalMxn != null
          ? runnerCounterOfferTotalMxn!
          : suggestedTotalPriceMxn;

  MvpTask copyWith({
    String? id,
    String? locationText,
    String? description,
    String? instructions,
    DateTime? startDate,
    String? startTimeSlot,
    double? estimatedTaskHours,
    double? customerArrivalBufferHours,
    double? hourlyRateMxn,
    MvpTaskStatus? status,
    String? customerId,
    String? runnerId,
    bool clearRunnerId = false,
    Uint8List? checkInImageBytes,
    bool clearCheckInImageBytes = false,
    String? progressNote,
    bool clearProgressNote = false,
    String? handoffCode,
    DateTime? createdAt,
    DateTime? waitingStartedAt,
    bool clearWaitingStartedAt = false,
    double? runnerCounterOfferTotalMxn,
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
      estimatedTaskHours: estimatedTaskHours ?? this.estimatedTaskHours,
      customerArrivalBufferHours:
          customerArrivalBufferHours ?? this.customerArrivalBufferHours,
      hourlyRateMxn: hourlyRateMxn ?? this.hourlyRateMxn,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      runnerId: clearRunnerId ? null : (runnerId ?? this.runnerId),
      checkInImageBytes: clearCheckInImageBytes
          ? null
          : (checkInImageBytes ?? this.checkInImageBytes),
      progressNote:
          clearProgressNote ? null : (progressNote ?? this.progressNote),
      handoffCode: handoffCode ?? this.handoffCode,
      createdAt: createdAt ?? this.createdAt,
      waitingStartedAt: clearWaitingStartedAt
          ? null
          : (waitingStartedAt ?? this.waitingStartedAt),
      runnerCounterOfferTotalMxn: clearRunnerCounterOfferMxn
          ? null
          : (runnerCounterOfferTotalMxn ?? this.runnerCounterOfferTotalMxn),
      negotiationStatus: negotiationStatus ?? this.negotiationStatus,
    );
  }
}
