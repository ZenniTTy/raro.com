import 'package:raro_mobile/core/native_bridges/generated/gallery_api.g.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_gallery_exporter_provider.g.dart';

@Riverpod(keepAlive: true)
SystemGalleryExporter systemGalleryExporter(Ref ref) =>
    PigeonSystemGalleryExporter(GalleryHostApi());
