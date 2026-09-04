import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/gallery_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/GalleryApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'GalleryPigeonError'),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/gallery/GalleryApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.gallery',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
/// Channel suffix: gallery (`com.rarocamera/gallery`).
@HostApi()
abstract class GalleryHostApi {
  @async
  void saveVideoToSystemGallery(String videoPath);
}
