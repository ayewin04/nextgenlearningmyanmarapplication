# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ⭐ CRITICAL: Keep Play Core classes (fixes the missing classes error)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep your app package
-keep class com.nextgenlearningmyanmar.polyglot_app.** { *; }

# Keep all model classes
-keep class * extends com.nextgenlearningmyanmar.polyglot_app.models.** { *; }

# Keep all service classes
-keep class * extends com.nextgenlearningmyanmar.polyglot_app.services.** { *; }

# Keep all screen classes
-keep class * extends com.nextgenlearningmyanmar.polyglot_app.screens.** { *; }

# Keep all widget classes
-keep class * extends com.nextgenlearningmyanmar.polyglot_app.widgets.** { *; }

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}