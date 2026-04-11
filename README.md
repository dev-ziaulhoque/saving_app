# SaveSmart – Flutter App

A monthly savings management platform with **Admin** and **User** roles, built with Flutter + GetX.

---

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── splash/             # Splash screen + routing logic
│   ├── routes/
│   │   ├── app_routes.dart # All route name constants
│   │   └── app_pages.dart  # GetX route + binding config
├── core/
│   ├── theme/
│   │   └── app_theme.dart  # Colors, ThemeData, typography
│   ├── utils/
│   │   └── app_utils.dart  # Formatters, validators, helpers
│   └── widgets/
│       └── common_widgets.dart  # Reusable UI components
├── data/
│   ├── models/
│   │   └── models.dart     # UserModel, TransactionModel, etc.
│   ├── providers/
│   │   └── api_provider.dart   # Dio-based HTTP client
│   └── services/
│       └── auth_service.dart   # Session management (GetStorage)
└── modules/
    ├── auth/
    │   ├── login/           # LoginView + LoginController
    │   ├── register/        # RegisterView + RegisterController
    │   └── pending/         # Pending approval screen
    ├── admin/
    │   ├── dashboard/       # Stats, approval requests
    │   ├── users/           # User list, detail, block/unblock
    │   ├── payments/        # Confirm payments
    │   ├── notifications/   # Send push notifications
    │   └── chat/            # Chat list + chat detail
    └── user/
        ├── dashboard/       # Savings card, recent transactions
        ├── history/         # Full transaction history
        ├── notifications/   # Notification inbox
        ├── chat/            # Chat with admin
        └── profile/         # View & edit profile
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / VS Code
- Firebase project (for push notifications)

### Install Dependencies
```bash
flutter pub get
```

### Configure API Base URL
Edit `lib/data/providers/api_provider.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com/api/v1';
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package name: `com.savesmart.app`
3. Download `google-services.json` → place in `android/app/`
4. For iOS: download `GoogleService-Info.plist` → place in `ios/Runner/`

### Run the App
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## API Endpoints Expected

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login (role, email, password) |
| POST | `/auth/register` | Register with document upload |
| GET | `/admin/stats` | Dashboard statistics |
| GET | `/admin/users` | List users (filter by status) |
| POST | `/admin/users/:id/approve` | Approve user |
| POST | `/admin/users/:id/block` | Block user |
| POST | `/admin/payments/:id/confirm` | Confirm payment |
| POST | `/admin/notifications` | Send notification |
| GET | `/user/dashboard` | User savings summary |
| GET | `/user/transactions` | Transaction history |
| GET | `/user/notifications` | Notifications |
| PUT | `/user/profile` | Update profile |
| GET | `/chat/messages/:userId` | Get messages |
| POST | `/chat/send` | Send message |

---

## Key Packages

| Package | Purpose |
|---------|---------|
| `get` | State management, routing, snackbars |
| `get_storage` | Lightweight local storage (auth session) |
| `dio` | HTTP client with interceptors |
| `image_picker` | Document/photo upload |
| `firebase_messaging` | Push notifications |
| `fl_chart` | Charts (optional dashboard charts) |
| `intl` | Date & currency formatting |

---

## Role Flow

```
Login
 ├── Admin  → Admin Dashboard → Users / Payments / Chat / Notifications
 └── User
      ├── status: pending  → Pending Approval Screen
      └── status: active   → User Dashboard → History / Chat / Profile
```

---

## Colors

| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#4F46E5` | Buttons, accents, active nav |
| Background Dark | `#1A1A2E` | App bars, headers |
| Success | `#16A34A` | Confirmed, active badges |
| Warning | `#D97706` | Pending badges |
| Error | `#DC2626` | Blocked, error states |

---

## Notes

- All API calls gracefully fall back to mock data when the server is unreachable (for demo/testing).
- Auth token is stored via `GetStorage` and injected into every request via Dio interceptor.
- Role-based routing is handled in `SplashController` on app launch.
# saving_app
