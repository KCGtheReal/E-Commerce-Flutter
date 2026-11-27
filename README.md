# RESET Store — Flutter Client (Web, Android, iOS)

Cross-platform bilingual (**English / Khmer**) Flutter storefront for **RESET Store**, connecting exclusively to the unified Laravel 13 REST API & Filament v3 Admin Panel in `../Website Project`.

---

## Architecture & Backend Connection

This repository contains **only the Flutter client**. There is no local PHP backend or separate SQLite database inside `Mobile Project`.

- **Default Service URLs (`lib/core/config/app_config.dart`):**
  - **Firebase Gateway API (`../API`, Catalog/Settings/Reviews):** `http://127.0.0.1:4000` (`http://10.0.2.2:4000` on Android Emulator), override with `--dart-define=FIREBASE_API_URL=<url>` — falls back transparently to Laravel `/api/v1/*` if offline
  - **Unified Laravel API (`../Website Project`, Cart/Checkout/Auth/KHQR):**
    - **Web / iOS Simulator / Desktop:** `http://127.0.0.1:8000`
    - **Android Emulator:** `http://10.0.2.2:8000`
    - **Override:** Pass `--dart-define=API_BASE_URL=<url>` at launch/build time, or set a custom server URL in-app under **Preferences -> API Server URL**.
- **Connected Service Endpoints:**
  - **Firebase Gateway API:** `http://127.0.0.1:4000/api/firebase/*` (Swagger UI: `http://127.0.0.1:4000/docs`)
  - **REST API v1:** `http://127.0.0.1:8000/api/v1/*` (`bootstrap`, `home`, `products`, `cart`, `checkout`, `payments`, `auth`, `account`, `wishlist`, `pages`)
  - **Swagger API Docs (Laravel):** `http://127.0.0.1:8000/api/docs`
  - **Web Admin Panel:** `http://127.0.0.1:8000/admin` (store administration lives exclusively in `Website Project`'s Filament v3 admin; in-app admin links open `/admin` externally)

---

## Requirements

- **Flutter 3.35.1+ / Dart 3.9.0+**
- **Unified `Website Project` Backend** running on port `8000` (PHP 8.4+, Composer dependencies installed in `../Website Project`)

---

## Quick Start

### Option A: One-Click Windows Launcher
Double-click [`start-flutter-app.bat`](start-flutter-app.bat). It automatically:
1. Starts the unified Laravel API & Filament Web Admin from `..\Website Project` (`php artisan serve --host=127.0.0.1 --port=8000`)
2. Launches the Flutter storefront in Chrome with `--dart-define=API_BASE_URL=http://127.0.0.1:8000`

### Option B: Manual Startup

#### 1. Start the Unified Backend (`../Website Project`)
```bash
cd "../Website Project"
php artisan serve --host=127.0.0.1 --port=8000
```
> For testing on a physical phone over local Wi-Fi, bind all interfaces in `../Website Project`:
> `php artisan serve --host=0.0.0.0 --port=8000`

#### 2. Run the Flutter Client (`Mobile Project`)
```bash
flutter pub get

# Web (Chrome) -> connects to http://127.0.0.1:8000
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android Emulator -> automatically connects to http://10.0.2.2:8000
flutter run -d android

# iOS Simulator -> automatically connects to http://127.0.0.1:8000
flutter run -d ios

# Physical Device (LAN)
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:8000

# Production Web Bundle (outputs to build/web/)
flutter build web
```

---

## Project Structure & Firebase Setup

- **Firebase Gateway Integration (`reset-store-ecommerce` / `../API`):**
  - `lib/core/firebase/firebase_gateway_client.dart` — Consumes `../API` (`http://127.0.0.1:4000/api/firebase/*` / `10.0.2.2:4000`) via `ApiClient` for storefront reads (`home`, `products`, `search/suggest`, `products/:slug`, `bootstrap` fallback) with automatic Laravel fallback
  - `lib/firebase_options.dart` — Platform options for Web (`1:380926366953:web:662c985f0af96e3efe8c78`), Android (`store.reset.reset_store`), and iOS (`store.reset.resetStore`)
  - `lib/core/firebase/firestore_storefront_service.dart` — Safe FlutterFire bootstrap (`initializeResetFirebase()`) and read-only real-time streams for `settings`, `categories`, published `products` (`is_published == true`), and approved `reviews` (`is_approved == true`)
  - `android/app/google-services.json` & `ios/Runner/GoogleService-Info.plist` — Native platform Firebase configs (wired with `com.google.gms.google-services` `4.4.2`)
- `lib/core/config/app_config.dart` — Platform-aware Firebase Gateway & Laravel API URLs, `/admin`, `/api/docs`, and invoice URL resolution
- `lib/core/api/` — Typed REST client (`ApiClient`), endpoint paths (`ApiEndpoints`), and error handling (`ApiException`)
- `lib/core/storage/` — Persistent token, locale, currency, and custom server URL storage (`SharedPreferences`)
- `lib/core/theme/` & `lib/l10n/` — RESET design tokens, light/dark themes, and English/Khmer translations
- `lib/models/` — DTOs matching the `/api/v1/*` and `/api/firebase/*` contracts
- `lib/providers/` — `BootstrapProvider` (REST + live Firestore sync), `AuthProvider`, `CartProvider`, `WishlistProvider`, `AppSettingsProvider`, `AppNavigationProvider`
- `lib/screens/` & `lib/widgets/` — Storefront tabs (`Home`, `Shop`, `Account`), PDP, Cart, Checkout, Bakong KHQR Payment, Tax Invoice, and Preferences
- `test/` — Unit and widget tests (`flutter test`: 27 passing)

---

## Verification Commands

```bash
flutter analyze --no-pub
flutter test
flutter build web
```
