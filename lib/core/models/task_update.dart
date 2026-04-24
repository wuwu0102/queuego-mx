class TaskUpdate {
  const TaskUpdate({
    required this.updateId,
    required this.taskId,
    required this.runnerId,
    required this.type,
    required this.message,
    this.queuePosition,
    this.estimatedRemainingMinutes,
    this.photoUrl,
    required this.createdAt,
  });

  final String updateId;
  final String taskId;
  final String runnerId;
  final String type;
  final String message;
  final int? queuePosition;
  final int? estimatedRemainingMinutes;
  final String? photoUrl;
  final DateTime createdAt;
}
