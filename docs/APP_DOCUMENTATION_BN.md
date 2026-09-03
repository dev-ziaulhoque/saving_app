# SaveSmart — সম্পূর্ণ অ্যাপ ডকুমেন্টেশন

শেষ হালনাগাদ: ২ সেপ্টেম্বর ২০২৬  
অ্যাপ ভার্সন: `1.0.0+1`

## ১. অ্যাপ পরিচিতি

SaveSmart একটি foundation/savings management mobile application। এখানে সদস্যরা account তৈরি, payment request, transaction history, notification, profile এবং admin chat ব্যবহার করতে পারে। Admin সদস্য অনুমোদন, payment confirmation, monthly requirement, special charge, notification, chat, audit log এবং foundation investment হিসাব পরিচালনা করতে পারে।

বর্তমান app target মূলত Android mobile। Flutter codebase হওয়ায় প্রয়োজনীয় platform configuration যোগ করে iOS-এও নেওয়া সম্ভব।

## ২. ব্যবহৃত Technology Stack

| অংশ | প্রযুক্তি | ব্যবহার |
|---|---|---|
| Mobile frontend | Flutter / Dart | সম্পূর্ণ mobile UI ও business flow |
| State management | GetX | Controller, dependency injection, reactive UI |
| Navigation | GetX Routes | Named routes ও role middleware |
| Primary backend | Supabase | Authentication, PostgreSQL, RPC, RLS, Realtime, Storage |
| Database | PostgreSQL | User, payment, message, accounting ও audit data |
| Push notification client | Firebase Cloud Messaging | FCM token ও foreground/background message handling |
| Local notifications | flutter_local_notifications | Foreground notification প্রদর্শন |
| Avatar hosting | Cloudinary | Public profile avatar upload |
| Receipt storage | Supabase Storage | Private payment receipt |
| Local cache | GetStorage | Cached authenticated profile/session-related app state |
| HTTP client | Dio | Cloudinary/API requests |
| PDF | pdf package | বাংলা monthly foundation report |
| File sharing | share_plus | Generated PDF share/download flow |
| Fonts | Nunito, Noto Sans Bengali | App UI এবং বাংলা PDF |

প্রধান package versions [pubspec.yaml](../pubspec.yaml)-এ সংরক্ষিত।

## ৩. High-level Architecture

```text
Flutter UI
  ├─ Auth modules
  ├─ User modules
  ├─ Admin modules
  └─ Foundation reporting
        │
        ├─ GetX controllers
        ├─ AuthService / SupabaseService / ChatService
        │      │
        │      └─ Supabase Auth + PostgreSQL + RPC + RLS + Storage
        │
        ├─ Cloudinary (public avatars)
        └─ Firebase Messaging (push client/token)
```

Project structure:

```text
lib/
  app/
    app_config/       Backend এবং integration configuration
    routes/           Routes এবং admin/user middleware
    splash/           Startup/session routing
  core/
    theme/            Colors ও themes
    utils/            Logger এবং utility helpers
    widgets/          Shared UI widgets
  data/
    models/           User, transaction, notification, audit, report models
    services/         Supabase, auth, chat, Cloudinary, notification services
  modules/
    auth/             Login, register, pending approval
    admin/            Dashboard, users, payments, notifications, audit
    user/             Dashboard, history, payment request, profile, notification
    chat/             User-admin messaging
    foundation/       Investment/report/PDF
supabase/
  migrations/         Security, admin এবং accounting migrations
  promote_admin.sql   নির্দিষ্ট profile-কে admin করার script
```

## ৪. Application Startup

App চালু হলে [main.dart](../lib/main.dart) এই ক্রমে initialization করে:

1. Flutter binding initialize
2. Firebase initialize
3. Firebase background message handler register
4. GetStorage initialize
5. Supabase initialize
6. Portrait orientation configure
7. `SupabaseService`, `AuthService`, `NotificationService` register
8. Splash route থেকে session/profile অনুযায়ী সঠিক screen-এ redirect

## ৫. User Roles এবং Status

### Roles

- `user`: সাধারণ সদস্য
- `admin`: application administrator

### User status

- `pending`: registration হয়েছে, admin approval প্রয়োজন
- `active`: login ও user features ব্যবহারের অনুমতি আছে
- `blocked`: admin কর্তৃক blocked
- `rejected`: registration reject করা হয়েছে

Registration metadata থেকে কেউ নিজের role `admin` করতে পারে না। Database trigger নতুন account-কে বাধ্যতামূলকভাবে `user/pending` তৈরি করে।

## ৬. Authentication Flow

### Registration

1. User নাম, email, phone, password এবং প্রয়োজনীয় document দিয়ে signup করে।
2. Supabase Auth account তৈরি হয়।
3. `handle_new_user()` trigger `profiles` row তৈরি করে।
4. Default role/status হয় `user` এবং `pending`।
5. Admin approval না হওয়া পর্যন্ত pending screen দেখায়।

### Login

1. Supabase email/password authentication হয়।
2. App `profiles` table থেকে role ও status আনে।
3. Admin হলে admin dashboard, active user হলে user dashboard এবং pending user হলে pending screen খোলে।

### Password reset

Password app database-এ plaintext অবস্থায় থাকে না। Reset করতে Supabase Dashboard → Authentication → Users অথবা password-reset email flow ব্যবহার করতে হবে।

## ৭. Admin Information

বর্তমান configured admin:

| Field | Value |
|---|---|
| Email | `mdziaulhoquesp94@gmail.com` |
| Role | `admin` |
| Status | `active` |
| Profile UUID | `2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a` |
| Promotion script | `supabase/promote_admin.sql` |

Admin password source code বা documentation-এ রাখা হয়নি। Password ভুলে গেলে Supabase Auth থেকে reset করতে হবে। নতুন admin তৈরি করতে প্রথমে স্বাভাবিক registration করে তারপর trusted SQL Editor থেকে role/status update করতে হবে। Client app থেকে admin promotion নিষিদ্ধ।

## ৮. User Features

- Registration ও login
- Admin approval status দেখা
- Savings summary ও progress
- Payment request submit
- একসঙ্গে ১–২৪ মাসের advance payment allocation
- Paid/pending/due/future মাসের visual timeline
- Phone এবং optional receipt attach
- নিজের transaction history
- Payment confirmation status
- Notification list এবং read state
- Admin-এর সঙ্গে realtime chat
- Private image ও document attachment (সর্বোচ্চ ১০ MB)
- Profile view/edit
- Public avatar upload
- Published foundation report দেখা
- Foundation report PDF download/share

User investment, profit, expense বা published report পরিবর্তন করতে পারে না।

## ৯. Admin Features

- Dashboard summary
- Pending user list
- User approve/reject/block/unblock
- User detail ও monthly amount management
- Pending payment list
- Payment confirmation
- পুরোনো savings start month এবং historical payment import support
- Monthly requirement configuration
- Special charge support
- Broadcast বা targeted notification record তৈরি
- User chat inbox
- Secure image/document chat attachments
- Audit log viewer
- Foundation accounting:
  - Investment add
  - Monthly investment profit add/update
  - Foundation expense add
  - Live all-time report (publish step ছাড়া)
  - বাংলা PDF generate/share

## ১০. Payment এবং Member Progress Flow

```text
User payment request
      ↓
transactions.status = pending
      ↓
Admin reviews receipt/information
      ↓
confirm_payment RPC
      ↓
transactions.status = confirmed
      ↓
profiles.total_saved / profiles.dues update
      ↓
Dashboard ও foundation report-এ updated progress
```

Member report-এর data আলাদা manual/dummy table থেকে আসে না। Active user-এর বাস্তব `total_saved` এবং `dues` ব্যবহার করা হয়:

```text
required = total_saved + dues
paid     = total_saved
due      = dues
```

অর্থাৎ user payment submit এবং admin confirmation-এর normal workflow-ই report-এর member progress source।

## ১১. Foundation Accounting

### Admin-managed tables

#### `investments`

- `id`
- `title`
- `amount`
- `invested_at`
- `status`: `active` বা `closed`
- `notes`
- `created_by`
- timestamps

#### `investment_profits`

- সংশ্লিষ্ট `investment_id`
- `amount`
- `profit_month`
- `received_at`
- `notes`
- প্রতি investment/month একটি row

#### `foundation_expenses`

- `title`
- `amount`
- `expense_date`
- `category`
- `notes`

#### Live report

`get_live_foundation_report()` সরাসরি approved member balance, investments, profits এবং expenses থেকে all-time report তৈরি করে। আলাদা publish/update action প্রয়োজন হয় না। Screen pull-to-refresh এবং periodic refresh ব্যবহার করে। পুরোনো `foundation_report_snapshots` table backward compatibility-এর জন্য থাকতে পারে, কিন্তু নতুন UI এটি ব্যবহার করে না।

### Report formula

```text
foundation_total = total_collected + total_profit - total_expenses
available_cash   = foundation_total - total_invested
```

Report-এর investments/profits/expenses নির্বাচিত মাস পর্যন্ত cumulative। Member progress publish করার সময়কার active profiles-এর বর্তমান approved balance snapshot। অতীত মাসের true historical member balance প্রয়োজন হলে ভবিষ্যতে confirmed transaction ledger থেকে date-based calculation যোগ করা উচিত।

## ১২. Database Tables

### Core tables

- `profiles`: application user profile, role, status ও balances
- `transactions`: payment request/confirmation
- `payment_allocations`: একটি transaction-এর মাসভিত্তিক ভাগ; advance payment tracking
- `messages`: user-admin chat
- `notifications`: notification records
- `notification_reads`: per-user read state
- `app_settings`: default amount/start date
- `monthly_requirements`: মাসভিত্তিক requirement
- `special_charges`: global বা user-specific charge

### Security/admin tables

- `audit_logs`: protected admin operations-এর audit trail

### Accounting tables

- `investments`
- `investment_profits`
- `foundation_expenses`
- `foundation_report_snapshots`

Core tables-এর initial schema existing Supabase project-এ আগে তৈরি হয়েছিল। Repository migrations বর্তমান schema-কে security, admin এবং accounting capability দিয়ে extend করে। ভবিষ্যতে fresh project reproducibility-এর জন্য সম্পূর্ণ baseline schema migration repository-তে যোগ করা উচিত।

## ১৩. Important Database Functions / RPC

| RPC/function | কাজ |
|---|---|
| `is_admin()` | Current authenticated profile admin কি না যাচাই |
| `handle_new_user()` | Auth signup থেকে safe user profile তৈরি |
| `protect_profile_sensitive_fields()` | User-এর role/status/balance self-edit বন্ধ |
| `approve_user()` | User approve |
| `reject_user()` | User reject |
| `block_user()` / `unblock_user()` | User access control |
| `confirm_payment()` | Payment transactional confirmation |
| `create_payment_request()` | Single বা multi-month advance request এবং allocations |
| `get_user_payment_calendar()` | সদস্যের মাসভিত্তিক paid/pending/due timeline |
| `set_user_savings_start_admin()` | পুরোনো সদস্যের savings শুরুর মাস |
| `get_user_dashboard()` | User dashboard summary |
| `get_admin_stats()` | Admin dashboard statistics |
| `get_admin_id()` | Active admin chat target |
| `get_admin_chat_list()` | Admin inbox |
| `set_user_monthly_amount()` | Per-user monthly amount |
| `set_month_requirement_admin()` | Monthly requirement |
| `update_app_settings_admin()` | Global settings |
| `send_admin_notification()` | Notification record তৈরি |
| `get_live_foundation_report()` | Always-current all-time accounting statement |
| `add_manual_payment_admin()` | বাধ্যতামূলক proof-সহ immutable admin payment |
| `capture_audit_log()` | Database changes audit |

## ১৪. Row Level Security (RLS)

প্রধান security rules:

- User নিজের pending payment request insert করতে পারে।
- User admin-only profile fields পরিবর্তন করতে পারে না।
- Receipt owner এবং admin ছাড়া private receipt পড়তে পারে না।
- Accounting write access শুধু admin-এর।
- Published foundation snapshot authenticated users পড়তে পারে।
- Audit logs শুধু admin পড়তে পারে।
- Chat admin inbox RPC non-admin ব্যবহার করতে পারে না।
- Admin RPC-গুলো server-side `is_admin()` check করে।

Client-side route guard UX-এর জন্য; প্রকৃত security PostgreSQL RLS ও RPC authorization enforce করে।

## ১৫. Storage এবং Media

### Profile avatar

- Provider: Cloudinary
- Upload mode: unsigned preset
- Intended data: public profile avatar only
- Secret API key mobile app-এ রাখা হয় না

### Payment receipt

- Provider: Supabase Storage
- Bucket: `receipts`
- Visibility: private
- Path convention: `<user-id>/<timestamp>.<extension>`
- Access: receipt owner এবং admin

Sensitive document/receipt কখনো public Cloudinary preset-এ upload করা উচিত নয়।

## ১৬. Notifications

বর্তমানে app:

- Firebase initialize করে
- Notification permission চায়
- FCM token `profiles.fcm_token`-এ save করে
- Foreground push local notification হিসেবে দেখায়
- Background callback support করে
- Supabase notification records ও read-state পরিচালনা করে

গুরুত্বপূর্ণ: device-এ real remote push পাঠানোর জন্য trusted backend/Edge Function-এ Firebase Admin SDK/service account sender প্রয়োজন। Firebase service-account secret mobile app-এ রাখা যাবে না। বর্তমান repository-তে production FCM sender Edge Function নেই।

## ১৭. Routes

### Public/auth

- `/splash`
- `/login`
- `/register`
- `/pending-approval`

### Admin protected

- `/admin/dashboard`
- `/admin/users`
- `/admin/users/detail`
- `/admin/payments`
- `/admin/notifications`
- `/admin/chat`
- `/admin/chat/detail`
- `/admin/audit`
- `/admin/accounting`

### User protected

- `/user/dashboard`
- `/user/history`
- `/user/notifications`
- `/user/chat`
- `/user/profile`
- `/user/profile/edit`
- `/user/payment-request`
- `/user/foundation-report`

`AdminMiddleware` এবং `UserMiddleware` session, role ও status অনুযায়ী route protection দেয়।

## ১৮. Configuration

Configuration file: `lib/app/app_config/app_config.dart`

Configured services:

- Supabase project URL
- Supabase publishable/anon key
- Cloudinary cloud name
- Cloudinary unsigned avatar preset
- App name/version
- Admin profile UUID

Firebase Android configuration: `android/app/google-services.json`  
Generated Flutter Firebase configuration: `lib/firebase_options.dart`

Supabase anon/publishable key client app-এ ব্যবহারযোগ্য, তবে security অবশ্যই RLS দিয়ে enforce করতে হবে। Supabase service-role key, Firebase service account, Cloudinary API secret বা admin password repository-তে রাখা যাবে না। Production-এ `--dart-define` বা environment-based configuration ব্যবহার করা ভালো।

## ১৯. Supabase Migration Order

Fresh/current project-এ SQL Editor থেকে এই ক্রমে চালাতে হবে:

1. `202609020001_security_and_app_support.sql`
2. `202609020002_admin_foundation.sql`
3. `202609020003_foundation_accounting.sql`
4. `202609020004_live_reports_and_manual_payments.sql`
5. `202609020005_repair_chat_admin_lookup.sql`
6. `202609020006_chat_attachments.sql`
7. `202609030007_monthly_payment_allocations.sql`
8. প্রয়োজন হলে `promote_admin.sql`

প্রতিটি migration সফল হলে সাধারণত:

```text
Success. No rows returned
```

দেখাবে। Production-এ manual SQL paste-এর পরিবর্তে Supabase CLI migration workflow ব্যবহার করা উচিত।

## ২০. Local Setup এবং Run

Requirements:

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`
- Android Studio/SDK অথবা physical Android device
- Configured Supabase project
- Configured Firebase Android app
- Configured Cloudinary unsigned avatar preset

Commands:

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter run
```

Dependency বা route পরিবর্তনের পর hot reload-এর বদলে full restart প্রয়োজন হতে পারে:

```powershell
q
flutter pub get
flutter run
```

Release APK:

```powershell
flutter build apk --release
```

## ২১. Logging এবং Debugging

`AppLogger` গুরুত্বপূর্ণ request, response এবং error console-এ structured format-এ দেখায়। Authentication, upload, transaction, notification ও data fetch debug করতে এটি ব্যবহৃত হয়।

Production build-এ personal information, access token, receipt URL বা password log করা উচিত নয়। বর্তমান logger ব্যবহারের সময় payload redaction বজায় রাখতে হবে।

## ২২. Current Implementation Status

### Implemented

- Supabase email/password authentication
- Pending user approval flow
- Admin/user route guards
- User/payment administration
- Private receipt upload
- Cloudinary avatars
- User-admin chat
- Notification records/read state
- FCM client initialization/token sync
- Audit log infrastructure
- Foundation investments/profits/expenses
- Live all-time report
- Investment-wise nested profit breakdown
- Proof-required immutable manual admin payment
- Bengali PDF report
- Flutter-shaped Bengali PDF page rendering (যুক্তাক্ষর-safe)

### Partially implemented / infrastructure required

- Remote FCM sending: trusted server/Edge Function sender প্রয়োজন
- Automated Google Sheets backup/sync: এখনও implement হয়নি
- Scheduled PostgreSQL backup automation: provider/CLI scheduling প্রয়োজন
- Complete fresh-project baseline schema: repository-তে consolidate করা বাকি
- Historical member report: বর্তমানে publish-time profile snapshot; transaction-date ledger calculation আরও উন্নত করা যায়
- Automated integration/widget tests: পর্যাপ্ত coverage এখনও নেই

## ২৩. Recommended Production Improvements

1. Secrets/config environment variables বা `--dart-define`-এ নেওয়া।
2. Supabase CLI দিয়ে version-controlled migration deployment।
3. FCM sender Edge Function তৈরি এবং service account secret Supabase Vault-এ রাখা।
4. Google Sheets backup server-side Edge Function দিয়ে করা; mobile app-এ service credential না রাখা।
5. Daily/weekly PostgreSQL backup এবং restore test।
6. Historical reports confirmed transaction ledger থেকে calculate করা।
7. Investment close/update/delete-এর explicit secure RPC ও UI যোগ করা।
8. Payment confirmation RPC-এর idempotency এবং concurrent confirmation test করা।
9. Auth, payment, RLS ও accounting integration tests যোগ করা।
10. Android release signing, privacy policy, data retention এবং account deletion policy প্রস্তুত করা।

## ২৪. Security Checklist

- [ ] Supabase service-role key client/repository-তে নেই
- [ ] Firebase service-account JSON client/repository-তে নেই
- [ ] Cloudinary signed secret client-এ নেই
- [ ] Admin password source code/documentation-এ নেই
- [ ] সব exposed table-এ RLS enabled
- [ ] Admin mutations server-side role check করে
- [ ] Receipt bucket private
- [ ] Production logs sensitive data প্রকাশ করে না
- [ ] Database backup tested
- [ ] Admin account-এ শক্ত password এবং MFA ব্যবহৃত

## ২৫. Key Files

- App startup: `lib/main.dart`
- Configuration: `lib/app/app_config/app_config.dart`
- Routes: `lib/app/routes/app_routes.dart`, `app_pages.dart`
- Route security: `lib/app/routes/auth_middleware.dart`
- Backend service: `lib/data/services/supabase_service.dart`
- Authentication state: `lib/data/services/auth_service.dart`
- Push client: `lib/data/services/notification_service.dart`
- Cloudinary upload: `lib/data/services/cloudinary_service.dart`
- Foundation UI: `lib/modules/foundation/views/foundation_report_view.dart`
- Foundation PDF: `lib/modules/foundation/services/foundation_pdf_service.dart`
- Database migrations: `supabase/migrations/`
- Admin promotion: `supabase/promote_admin.sql`

---

এই document বর্তমান repository implementation অনুযায়ী লেখা। Database dashboard-এ repository-এর বাইরে manual পরিবর্তন করা হলে document ও migrations একসঙ্গে update করতে হবে।
