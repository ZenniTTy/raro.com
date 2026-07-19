# JNA (usado pelo vosk-android) — regras oficiais do FAQ da JNA.
# Sem elas o R8 do release remove com.sun.jna.Pointer/Native.initIDs (acessados
# via JNI por reflexão), causando UnsatisfiedLinkError "Can't obtain peer field
# ID for class com.sun.jna.Pointer" ao subir o VoiceBackgroundService (crash no
# boot do app — só em release). Fonte: java-native-access/jna FAQ.
-dontwarn java.awt.*
-keep class com.sun.jna.* { *; }
-keep class * extends com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }

# Vosk — API Kotlin/Java que faz ponte para a lib nativa via JNA.
-keep class org.vosk.** { *; }
