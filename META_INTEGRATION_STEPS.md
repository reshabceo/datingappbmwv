# Meta Ads SDK Integration Guide

Follow this guide to finalize connecting your Flutter app to your Meta (Facebook) Developer Account.

---

## 1. What to configure in your Meta Developer Console

In your [Meta Developer Dashboard](https://developers.facebook.com/), go to **App Settings** > **Basic** > scroll down to **Android Platform** (or add Android Platform if not added) and fill in the following:

*   **Google Play Package Name**: `com.lovebug.lovebug`
*   **Class Name**: `com.lovebug.lovebug.MainActivity`
*   **Key Hashes** (Add BOTH of these):
    1.  `3dQGQlfoDYOFAOsZp0YsqxyoH7U=` (Used for users who download your app from the Google Play Store)
    2.  `g3OWOuRaXoeb1g6q8dfhulWrb2Y=` (Used when you install and test the release APK directly on a phone)

*Note: You can add multiple key hashes in the Meta console by clicking "Add Key Hash" or entering them comma-separated.*

---

## 2. Configured Meta Credentials in App Code

We have successfully configured your **Client Token** (`b79adf0c4b48cc7e7a328df733df4cec`) inside the app resources:

👉 [android/app/src/main/res/values/strings.xml](file:///Users/mdsahil/development/datingappbmwv/android/app/src/main/res/values/strings.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">1329066058947943</string>
    <string name="facebook_client_token">b79adf0c4b48cc7e7a328df733df4cec</string>
</resources>
```

---

## 3. Upload & Launch Tracking
After you update the token in the code:
1. Make a fresh release build (using the updated AAB file generated at `release_builds/v1.0.5+21/app-release.aab`).
2. Upload this build to Google Play Console.
3. Once approved, Meta will start receiving App Events (Installs, Registrations, Logins, and Purchases) inside the **Events Manager** in your Meta Business Suite.
