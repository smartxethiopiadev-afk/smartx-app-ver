# Flutter ProGuard/R8 Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.** { *; }

# Google Mobile Ads SDK (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Firebase SDK
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep manifest/metadata/annotated classes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Prevent warnings from third-party libraries
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn io.flutter.**
