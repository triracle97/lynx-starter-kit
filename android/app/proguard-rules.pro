-keepattributes *Annotation*
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
  @androidx.annotation.Keep *;
}

-keep class com.lynx.** { *; }
-keep class * extends com.lynx.tasm.behavior.ui.LynxBaseUI { *; }
-keep class * implements com.lynx.jsbridge.LynxModule { *; }

-keepclasseswithmembernames class * {
  native <methods>;
}
