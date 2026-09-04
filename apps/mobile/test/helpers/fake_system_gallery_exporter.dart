import 'package:raro_mobile/features/gallery/data/system_gallery_exporter.dart';

class FakeSystemGalleryExporter implements SystemGalleryExporter {
  FakeSystemGalleryExporter({this.fail = false});

  bool fail;
  final List<String> exported = [];

  @override
  Future<void> exportVideo(String videoPath) async {
    if (fail) {
      throw Exception('gallery down');
    }
    exported.add(videoPath);
  }
}
