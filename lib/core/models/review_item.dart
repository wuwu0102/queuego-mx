class ReviewItem {
  const ReviewItem({
    required this.reviewId,
    required this.taskId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String reviewId;
  final String taskId;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String comment;
  final DateTime createdAt;
}
