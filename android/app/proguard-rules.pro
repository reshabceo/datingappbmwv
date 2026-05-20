#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Retrofit / OkHttp (if used by dependencies)
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Supabase / Postgrest / Gotrue
-keep class io.supabase.** { *; }
-keep enum io.supabase.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }
-keep class com.oney.WebRTCModule.** { *; }
-dontwarn org.webrtc.**

# Jitsi Meet (often use with WebRTC)
-keep class org.jitsi.meet.** { *; }

# Gson (used by many plugins)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
