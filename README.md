# SaveSmart

SaveSmart is a Flutter application for managing a foundation's member savings, monthly dues, payments, investments, profits, expenses, reports, notifications, and community communication.

The application has separate member and administrator experiences. Supabase provides authentication, PostgreSQL, Row Level Security, storage, RPC functions, and realtime updates. Firebase Cloud Messaging provides remote push notifications.

## Features

### Members

- Email and password registration and login
- Admin approval workflow
- Savings dashboard and transaction history
- Month-specific and advance payment requests
- Unpaid, partial, and future month selection
- Receipt upload
- Live foundation financial report
- Modern Bengali PDF statement
- Realtime notification inbox with read and completed states
- Community group chat
- Limited active-member directory
- Private member-to-member and member-to-admin messaging
- Image and document chat attachments
- Realtime unread badges

### Administrators

- Dashboard statistics
- Member approval, rejection, activation, and blocking
- Per-member monthly savings amount and savings start date
- Payment review and confirmation
- Proof-required immutable manual payment entries
- Month-specific payment allocations
- Investment, profit, and expense management
- Live foundation accounting report
- Notification broadcasting and targeted notifications
- Community and private messaging
- Audit-log access
- CSV and PDF report sharing

## Technology Stack

| Area | Technology |
| --- | --- |
| Application | Flutter and Dart |
| State and navigation | GetX |
| Authentication | Supabase Auth |
| Database | Supabase PostgreSQL |
| Authorization | PostgreSQL Row Level Security and secure RPC functions |
| Realtime | Supabase Realtime |
| Private storage | Supabase Storage |
| Profile avatars | Cloudinary unsigned upload preset |
| Push notifications | Firebase Cloud Messaging |
| Foreground alerts | Flutter Local Notifications |
| Reports | PDF, CSV, Path Provider, Share Plus |
| Local cache | GetStorage |

## Project Structure

```text
lib/
├── app/
│   ├── app_config/       Runtime configuration
│   ├── routes/           Routes and authorization middleware
│   └── splash/           Startup and session routing
├── core/
│   ├── theme/            Colors and application theme
│   ├── utils/            Logging and formatting helpers
│   └── widgets/          Shared UI components
├── data/
│   ├── models/           Application data models
│   └── services/         Supabase, auth, chat, badge, notification, Cloudinary
├── modules/
│   ├── admin/            Dashboard, members, payments, notifications, audit
│   ├── auth/             Login, registration, pending approval
│   ├── chat/             Community, member directory, private chat
│   ├── foundation/       Accounting report and Bengali PDF generation
│   └── user/             Dashboard, history, notifications, profile
└── main.dart             Firebase, Supabase, and service initialization

supabase/
├── functions/
│   └── send-push/        Secure FCM HTTP v1 sender
└── migrations/           Database functions, RLS, accounting, chat, badges
```

## Requirements

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`
- Android Studio or VS Code with Flutter tooling
- A Supabase project
- A Firebase project
- A Cloudinary account and unsigned avatar upload preset
- Supabase CLI for Edge Function deployment

## Local Setup

1. Install packages:

   ```bash
   flutter pub get
   ```

2. Configure Supabase and Cloudinary values in:

   ```text
   lib/app/app_config/app_config.dart
   ```

   The client may contain a Supabase publishable/anon key, but must never contain a Supabase service-role key, Firebase service-account JSON, or Cloudinary API secret.

3. Configure Firebase using FlutterFire and place the platform configuration files in their expected locations:

   ```text
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

4. Apply the Supabase migrations in filename order:

   Navigate to `supabase/migrations` and run every migration in filename order, from `001` through `012`.

   Current sequence:

   ```text
   202609020001_security_and_app_support.sql
   202609020002_admin_foundation.sql
   202609020003_foundation_accounting.sql
   202609020004_live_reports_and_manual_payments.sql
   202609020005_repair_chat_admin_lookup.sql
   202609020006_chat_attachments.sql
   202609030007_monthly_payment_allocations.sql
   202609030008_unread_badges_and_push.sql
   202609030009_manual_selected_months.sql
   202609030010_canonical_admin_chat.sql
   202609030011_community_chat.sql
   202609030012_notification_completion.sql
   ```

5. Run the application:

   ```bash
   flutter run
   ```

## Push Notification Setup

The Flutter client stores the current FCM token, while the trusted `send-push` Supabase Edge Function sends notifications through FCM HTTP v1.

1. Generate a Firebase service-account JSON file from Firebase Console.
2. Store its complete JSON value as a Supabase secret named:

   ```text
   FIREBASE_SERVICE_ACCOUNT_JSON
   ```

3. Deploy the function:

   ```bash
   supabase functions deploy send-push --project-ref YOUR_PROJECT_REF
   ```

Never commit the service-account JSON. Supabase environment files are ignored by Git.

## Database Model

Important tables include:

- `profiles`: member identity, role, status, savings settings, and balances
- `transactions`: submitted and confirmed payments
- `payment_allocations`: transaction amounts allocated to specific months
- `monthly_requirements`: monthly funding requirements
- `special_charges`: additional charges
- `investments`: foundation investments
- `investment_profits`: investment-specific income
- `foundation_expenses`: foundation expenses
- `messages`: private conversations
- `group_messages`: community conversation
- `group_message_reads`: per-user community read state
- `notifications`: targeted and broadcast notifications
- `notification_reads`: per-user read and completed state
- `audit_logs`: protected administrative activity history

## Payment Rules

- Members can select unpaid, partial, or future months.
- One request can cover multiple non-consecutive months.
- A request supports up to 24 selected months.
- The database prevents duplicate pending or confirmed allocations for the same member and month.
- Admin manual entries require a proof file and meaningful note.
- Confirmed manual entries cannot be silently edited or deleted by application users.

## Chat and Privacy

- Only active profiles can access the community.
- The member directory returns only ID, name, role, avatar, join date, and unread count.
- Phone numbers, email addresses, documents, FCM tokens, and financial fields are not exposed in community profiles.
- Private messages are visible only to their participants.
- Users cannot send private messages to themselves.
- Chat attachments are stored in a private bucket and accessed with short-lived signed URLs.

## Financial Calculations

The live report is generated from confirmed payment allocations and the current accounting ledger.

```text
foundation total = total collected + total profit - total expenses
available cash   = foundation total - active investments
```

The PDF is rendered through Flutter's text engine before being embedded into A4 pages. This preserves Bengali shaping and conjunct characters while supporting a modern multi-page layout.

## Quality Checks

Run these commands before committing:

```bash
dart format .
flutter analyze
flutter test
```

Create a release APK with:

```bash
flutter build apk --release
```

## Production Checklist

- Replace the example Android application ID with a unique production ID
- Configure release signing
- Verify every migration against the production project
- Deploy and test the push Edge Function on physical devices
- Enable scheduled PostgreSQL backups and test restoration
- Add multiple-device FCM token support
- Add chat and group-message push delivery
- Add integration tests for payment confirmation and balance calculations
- Add crash reporting, privacy policy, and store listing assets

## Security Notes

- Never commit service-role keys, passwords, service-account JSON, or private API secrets.
- Administrative access must be assigned through a trusted database operation.
- Client-side role checks improve navigation but do not replace RLS or RPC authorization.
- Financial corrections should use explicit correction entries rather than modifying confirmed evidence.

## License

This repository is currently private and no public license has been assigned.
