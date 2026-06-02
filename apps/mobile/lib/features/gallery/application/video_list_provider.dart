import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_list_provider.g.dart';

@riverpod
Future<List<VideoEntity>> videoList(Ref ref) async {
  final now = DateTime.now();
  return [
    VideoEntity(
      id: '1',
      name: 'Pôr do sol',
      duration: const Duration(minutes: 2, seconds: 14),
      recordedAt: now.subtract(const Duration(hours: 2)),
      isReplay: false,
      thumbnailHue: 20,
    ),
    VideoEntity(
      id: '2',
      name: 'Skate no parque',
      duration: const Duration(seconds: 48),
      recordedAt: now.subtract(const Duration(hours: 6)),
      isReplay: true,
      thumbnailHue: 200,
    ),
    VideoEntity(
      id: '3',
      name: 'Show ao vivo',
      duration: const Duration(minutes: 5, seconds: 32),
      recordedAt: now.subtract(const Duration(days: 1, hours: 3)),
      isReplay: false,
      thumbnailHue: 320,
    ),
    VideoEntity(
      id: '4',
      name: 'Gol de placa',
      duration: const Duration(seconds: 15),
      recordedAt: now.subtract(const Duration(days: 2)),
      isReplay: true,
      thumbnailHue: 140,
    ),
    VideoEntity(
      id: '5',
      name: 'Praia ao amanhecer',
      duration: const Duration(minutes: 1, seconds: 33),
      recordedAt: now.subtract(const Duration(days: 4)),
      isReplay: false,
      thumbnailHue: 50,
    ),
    VideoEntity(
      id: '6',
      name: 'Aniversário',
      duration: const Duration(minutes: 3, seconds: 51),
      recordedAt: now.subtract(const Duration(days: 20)),
      isReplay: false,
      thumbnailHue: 270,
    ),
  ];
}

@riverpod
class GalleryFilterController extends _$GalleryFilterController {
  @override
  GalleryFilter build() => GalleryFilter.all;

  void select(GalleryFilter filter) {
    state = filter;
  }
}
