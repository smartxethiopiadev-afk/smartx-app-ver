# Flutter ProGuard/R8 Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.** { *; }

# Keep manifest/metadata/annotated classes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Prevent warnings from third-party libraries
-dontwarn io.flutter.**
