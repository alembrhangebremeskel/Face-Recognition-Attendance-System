# Keep TensorFlow Lite and GPU Delegate classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep ML Kit and Face Detection classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.ml.** { *; }

# Prevent R8 from crashing on missing optional dependencies
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn com.google.android.gms.internal.ml.**

# Keep the TFLite Native interface
-keepclassmembers class org.tensorflow.lite.** { *; }