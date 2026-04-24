import '../core/constants/app_enums.dart';
import '../core/models/task_item.dart';
import '../core/models/task_update.dart';

final now = DateTime.now();

final fakeTasks = <TaskItem>[
  TaskItem(
    taskId: 't1',
    customerId: 'c1',
    title: 'SAT office queue assistance',
    category: TaskCategory.queueAssistance,
    placeName: 'SAT Centro',
    address: 'Av. Juárez 30, CDMX',
    scheduledDate: now,
    arrivalTime: '08:30',
    estimatedWaitMinutes: 120,
    description: 'Need queue assistance and live updates.',
    offeredPrice: 450,
    requiresPhoto: true,
    requiresLiveUpdates: true,
    notes: 'Bring ID copy only for check.',
    prohibitedAcknowledged: true,
    status: TaskStatus.open,
    createdAt: now,
    updatedAt: now,
  ),
  TaskItem(
    taskId: 't2',
    customerId: 'c1',
    runnerId: 'r1',
    title: 'University document dropoff',
    category: TaskCategory.documentDropoff,
    placeName: 'UNAM Office',
    address: 'Coyoacán, CDMX',
    scheduledDate: now,
    arrivalTime: '10:00',
    estimatedWaitMinutes: 80,
    description: 'On-site task for file submission queue.',
    offeredPrice: 380,
    requiresPhoto: true,
    requiresLiveUpdates: true,
    notes: 'No legal signature needed.',
    prohibitedAcknowledged: true,
    status: TaskStatus.inProgress,
    createdAt: now,
    updatedAt: now,
  ),
];

final fakeUpdates = <TaskUpdate>[
  TaskUpdate(
    updateId: 'u1',
    taskId: 't2',
    runnerId: 'r1',
    type: 'check_in',
    message: 'Runner checked in on-site.',
    createdAt: now.subtract(const Duration(minutes: 30)),
  ),
  TaskUpdate(
    updateId: 'u2',
    taskId: 't2',
    runnerId: 'r1',
    type: 'queue_status',
    message: 'Queue moving slowly.',
    queuePosition: 14,
    estimatedRemainingMinutes: 50,
    createdAt: now.subtract(const Duration(minutes: 15)),
  ),
];
