# Flutter embedding + plugin registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# sqflite (native SQLite bridge)
-keep class com.tekartik.sqflite.** { *; }

# Play Core split-install classes referenced by Flutter but not used here
-dontwarn com.google.android.play.core.**

# Keep line numbers for crash reports, hide source file names
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
