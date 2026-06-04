import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_list_provider.g.dart';

@riverpod
Future<List<VideoEntity>> videoList(Ref ref) async {
  final vault = await ref.watch(vaultServiceProvider.future);
  return vault.listAll();
}

@riverpod
class GalleryFilterController extends _$GalleryFilterController {
  @override
  GalleryFilter build() => GalleryFilter.all;

  void select(GalleryFilter filter) {
    state = filter;
  }
}
