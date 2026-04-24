enum UserRole { customer, runner, admin }

enum TaskStatus {
  draft,
  open,
  accepted,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  disputed,
}

enum PaymentStatus { unpaid, authorized, paid, refunded }

enum TaskCategory { queueAssistance, ticketPickup, documentDropoff, onSiteWaiting, other }
