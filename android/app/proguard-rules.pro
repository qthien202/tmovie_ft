# kotlinx.serialization: keep generated serializers for @Serializable models and nav routes.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keep,includedescriptorclasses class com.thientech.tmovie.**$$serializer { *; }
-keepclassmembers class com.thientech.tmovie.** {
    *** Companion;
}
-keepclasseswithmembers class com.thientech.tmovie.** {
    kotlinx.serialization.KSerializer serializer(...);
}
# OkHttp platform probes.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
