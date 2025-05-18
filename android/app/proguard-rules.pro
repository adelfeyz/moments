# Keep AWS Cognito classes
-keep class com.amazonaws.** { *; }
-keep class com.amazonaws.mobile.** { *; }
-keep class com.amazonaws.mobileconnectors.** { *; }
-keep class com.amazonaws.mobile.client.** { *; }
-keep class com.amazonaws.mobile.auth.** { *; }
-keep class com.amazonaws.mobile.auth.core.** { *; }
-keep class com.amazonaws.mobile.auth.userpools.** { *; }
-keep class com.amazonaws.mobile.auth.userpools.signin.** { *; }

# Keep Amplify classes
-keep class com.amplifyframework.** { *; }
-keep class com.amplifyframework.core.** { *; }
-keep class com.amplifyframework.auth.** { *; }
-keep class com.amplifyframework.auth.cognito.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep your app's classes
-keep class com.example.moments.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 