class ReviewItem {
  const ReviewItem({
    required this.taskId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String taskId;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}
