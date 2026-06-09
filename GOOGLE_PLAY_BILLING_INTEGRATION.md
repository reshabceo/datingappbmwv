# Google Play Billing Integration (Flutter App Only)

This document records the steps followed and all code changes made to migrate the **LoveBug Android app** from Cashfree web checkout to native **Google Play Billing**. No changes were made to `web_admin_dashboard/`, Supabase edge functions, or SQL schemas as part of this work.

---

## Scope

| Area | Changed? |
|------|----------|
| Flutter app (`lib/`, `pubspec.yaml`) | Yes |
| `web_admin_dashboard/` | No — left unchanged |
| Supabase edge functions | No — left unchanged |
| Database SQL scripts | No — left unchanged |

---

## Product IDs (Google Play Console)

These IDs must match exactly in Play Console and in app code.

### Premium subscriptions (`Monetization → Products → Subscriptions`)

| Product ID | Play Console name | Billing period |
|------------|-------------------|----------------|
| `premium_1_month` | Premium 1 month Membership | Monthly |
| `premium_3_month` | 3 months Premium Membership | Every 3 months |
| `premium_6_months` | 6 months premium plan | Every 6 months |

### Super Likes — consumables (`Monetization → Products → In-app products`)

| Product ID | Play Console name | Type |
|------------|-------------------|------|
| `super_like_5` | 5 Super Loves | Consumable |
| `super_like_15` | 15 Super Loves Pack | Consumable |
| `super_like_30` | 30 Super Loves Pack | Consumable |

---

## Steps Followed

### 1. Google Play Console setup

1. Link a **Google Payments Merchant Account** under **Settings → Developer account → Payment settings**.
2. Create all six products above and set them to **Active** (subscriptions need active base plans).
3. Upload a signed release build to **Internal testing** (billing does not work until a build is on a track).
4. Add license testers under **Setup → License testing**.
5. Testers install from the Internal testing link and sign in with a tester Google account on the device.

### 2. Remove Cashfree checkout from the app

- Deleted `lib/Screens/cashfree_checkout_screen.dart` (WebView Cashfree flow).
- Deleted `lib/config/cashfree_config.dart`.
- Stripped Cashfree payment initiation, order creation, and WebView navigation from `lib/services/payment_service.dart`.

### 3. Implement native Google Play Billing

- Extended `lib/services/in_app_purchase_service.dart`:
  - `initialize()` — checks store availability, subscribes to purchase stream, queries product details.
  - `purchaseSuperLikes()` — `buyConsumable()` for super-like packs.
  - `purchasePremium()` — `buyNonConsumable()` for subscriptions (Flutter IAP pattern for Play subscriptions).
  - `restorePurchases()` — restore prior purchases.
  - Purchase handlers record transactions, consume super-like tokens on Android, and update Supabase.

### 4. Wire UI to InAppPurchaseService

- Subscription screens and controllers call `InAppPurchaseService.purchasePremium(planId)`.
- Super Like buttons and dialogs call `InAppPurchaseService.purchaseSuperLikes(packageId)`.
- Footer copy updated from Cashfree to Google Play.

### 5. Initialize billing at app startup

- `lib/main.dart` calls `InAppPurchaseService.initialize()` during startup.

### 6. Keep subscription status checks

- `PaymentService` retained only for **read** operations: `hasActiveSubscription()`, `getSubscriptionDetails()`, `cancelSubscription()` (Supabase RPCs). No payment initiation.

### 7. Dependencies and version

- Added `in_app_purchase_android` for Android consume-purchase support.
- App version bumped to **1.0.3+15** for Play Console upload.

### 8. Release build

```bash
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Signed outputs (not committed):

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`
- Copies: `release_builds/v1.0.3+15/`

**Application ID:** `com.lovebug.lovebug`

---

## Files Changed (App Only)

| File | Change |
|------|--------|
| `lib/services/in_app_purchase_service.dart` | Full Google Play Billing implementation; product IDs; Supabase entitlement updates |
| `lib/services/payment_service.dart` | Removed Cashfree; kept subscription status helpers only |
| `lib/main.dart` | Initialize `InAppPurchaseService` at startup |
| `lib/Screens/SubscriptionPage/controller_subscription_screen.dart` | `initiatePayment()` → `InAppPurchaseService.purchasePremium()` |
| `lib/Screens/SubscriptionPage/ui_subscription_screen.dart` | Same; updated payment footer text |
| `lib/Screens/SubscriptionPage/subscription_plans_screen.dart` | Plan IDs updated to `premium_1_month`, `premium_3_month`, `premium_6_months` |
| `lib/Widgets/super_like_purchase_button.dart` | Routes purchases through `InAppPurchaseService` |
| `lib/Widgets/super_like_purchase_dialog.dart` | Same; restore purchases wired |
| `lib/Screens/cashfree_checkout_screen.dart` | **Deleted** |
| `lib/config/cashfree_config.dart` | **Deleted** |
| `pubspec.yaml` | `in_app_purchase_android`; version `1.0.3+15` |
| `pubspec.lock` | Lockfile updated for IAP dependencies |

---

## Purchase Flow (Runtime)

```
User taps Buy
    → InAppPurchaseService.purchasePremium() / purchaseSuperLikes()
    → Google Play purchase sheet
    → purchaseStream receives PurchaseDetails
    → Record in in_app_purchases table
    → Super likes: consume token (Android) + add_super_likes RPC
    → Premium: activate_premium_subscription RPC + user_subscriptions + profiles.is_premium
    → completePurchase()
```

---

## Testing Checklist

- [ ] AAB uploaded to Internal testing track
- [ ] All six product IDs active in Play Console
- [ ] Tester email added under License testing
- [ ] App installed from Play Internal testing link (not sideloaded APK)
- [ ] Super Like purchase adds count in profile
- [ ] Premium purchase sets `is_premium` and subscription dates
- [ ] Restore purchases works from Super Like dialog

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Product not found | Product ID mismatch or product not Active in console |
| Billing not available | No Play Store / wrong Google account / emulator without Play APIs |
| App not configured | Package name or versionCode lower than uploaded build |
| Purchase succeeds but no premium | User not logged in; check Supabase RPC logs |

---

## Out of Scope / Future Work

- **Server-side receipt verification** via Google Play Developer API (recommended before production scale).
- **iOS App Store** billing (same service structure; separate product setup in App Store Connect).
- **Web admin dashboard** — still uses its own payment test tools; unchanged by this integration.
