# --- WorkManager / Room ---
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class * extends androidx.room.RoomDatabase
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl { *; }

# --- Firebase ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keepclassmembers class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}

-keep class com.google.firebase.appcheck.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.sessions.** { *; }

# --- Flutter ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**