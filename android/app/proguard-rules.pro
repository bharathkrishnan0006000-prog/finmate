# Keep rules for google_mlkit_text_recognition optional language models.
# These classes are only needed if you explicitly use Chinese/Japanese/Korean/Devanagari
# script recognition. Since this app only uses Latin script OCR, they are safe to ignore.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep rules for pdfbox JP2 decoder (optional JPEG2000 support, not used in this app)
-dontwarn com.gemalto.jp2.**

# Flutter Play Store split/deferred component classes — only needed for Play Store
# dynamic feature delivery. Not used when sideloading or building a standard APK.
-dontwarn com.google.android.play.core.**

# Flutter / Dart — keep all Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Drift / SQLite
-keep class androidx.sqlite.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
