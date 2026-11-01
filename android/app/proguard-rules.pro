# Planner R8 rules. Flutter and the plugins ship their own consumer rules
# (flutter_local_notifications v19+ includes the Gson rules it needs).

# Keep notification payload models used by flutter_local_notifications via
# Gson reflection (defensive; harmless if already covered).
-keep class com.dexterous.** { *; }

# Play Core (deferred components) is referenced by the Flutter engine but not
# used by this app.
-dontwarn com.google.android.play.core.**
