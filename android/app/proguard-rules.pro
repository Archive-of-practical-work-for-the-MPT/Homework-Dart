# Flutter Local Notifications - сохраняем generic-сигнатуры для TypeToken (Gson)
# Иначе R8 обрезает типы и возникает: TypeToken must be created with a type argument
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson TypeAdapter и связанные классы
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# flutter_local_notifications
-keep class com.dexterous.** { *; }
