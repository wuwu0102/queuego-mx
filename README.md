# queuego_mx

QueueGo MX is a cross-platform Flutter MVP and pilot platform for **queue and short-wait support in Guadalajara**. It matches Customers who need on-site waiting or line support with Runners who can handle simple, non-sensitive queue or short-wait support requests.

## Project Purpose
- Build an MVP similar in marketplace flow to Uber + TaskRabbit (but for on-site queue assistance only).
- Support three app roles: **Customer / Runner / Admin**.
- Keep sensitive/non-compliant wording out of product UX and policy.
- Provide architecture-ready integration points for Firebase and future scaling.

## Tech Stack
- Flutter (latest stable targeted)
- Firebase Auth (mock fallback login included)
- Cloud Firestore schema defined
- Firebase Storage integration point reserved
- Firebase Cloud Messaging integration point reserved
- Google Maps integration point reserved

## Installation
1. Install Flutter SDK (stable channel).
2. Clone repository and open in VS Code.
3. Run:
   ```bash
   flutter pub get
   ```

## Run
```bash
flutter run
```

## Firebase Setup
1. Create a Firebase project.
2. Add Android/iOS/Web apps in Firebase console.
3. Generate `firebase_options.dart` with FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
4. Initialize Firebase in `main.dart` before `runApp` when you enable real backend.
5. Enable services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Storage
   - Cloud Messaging (later phase)

> Current MVP supports mock login so the app remains runnable even before Firebase wiring is completed.

## Firestore Collections (Schema)

### `users`
- uid
- role: customer / runner / admin
- displayName
- email
- phone
- language
- rating
- completedTasks
- isVerified
- isBlocked
- createdAt

### `tasks`
- taskId
- customerId
- runnerId (nullable)
- title
- category
- placeName
- address
- lat (nullable)
- lng (nullable)
- scheduledDate
- arrivalTime
- estimatedWaitMinutes
- description
- offeredPrice
- currency (default MXN)
- requiresPhoto
- requiresLiveUpdates
- notes
- prohibitedAcknowledged
- status: draft/open/accepted/checked_in/in_progress/completed/cancelled/disputed
- paymentStatus: unpaid/authorized/paid/refunded
- createdAt
- updatedAt

### `task_updates`
- updateId
- taskId
- runnerId
- type: check_in/photo/queue_status/message/completed
- message
- queuePosition (nullable)
- estimatedRemainingMinutes (nullable)
- photoUrl (nullable)
- createdAt

### `reviews`
- reviewId
- taskId
- fromUserId
- toUserId
- rating
- comment
- createdAt

## MVP Feature Checklist
- [x] Trilingual i18n (繁中 / English / es-MX)
- [x] Onboarding: language + role + email/mock login
- [x] Customer shell: create task / my tasks / timeline-based messages / profile
- [x] Runner shell: find tasks / ongoing / earnings placeholder / profile
- [x] Admin dashboard with task status moderation UI
- [x] Terms screen for compliance messaging
- [x] Report/Dispute UI entry point
- [x] Payment status field reserved (no real payment yet)
- [x] FCM + Maps dependencies reserved for next stage

## Compliance/Safety Notes
- Platform only matches on-site assistance services.
- No impersonation, illegal transfer, bribes, queue-jumping, or signature replacement.
- If local rules disallow third-party queuing, Runner must cancel and report.
- All tasks are reportable and admin-reviewable.

## Recommended Next Phase
1. Replace mock auth with Firebase Auth + role-based route guard.
2. Add Firestore repositories and stream-based task updates.
3. Add Storage upload for runner photo evidence.
4. Add FCM notifications for status and timeline updates.
5. Integrate Google Maps picking + distance filtering.
6. Add payment integrations (Stripe/Mercado Pago) with escrow-like state machine.
7. Add KYC workflow and stronger trust/risk controls.
8. Add structured review + blocking policy engine.
9. Add automated dispatch/recommendation algorithm.
