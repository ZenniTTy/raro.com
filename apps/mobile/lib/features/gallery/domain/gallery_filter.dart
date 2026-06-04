import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

enum GalleryFilter {
  all('Todos'),
  today('Hoje'),
  thisWeek('Esta semana'),
  raroReplay('Raro Replay');

  const GalleryFilter(this.label);

  final String label;

  List<VideoEntity> apply(List<VideoEntity> videos, {required DateTime now}) {
    return switch (this) {
      GalleryFilter.all => List.unmodifiable(videos),
      GalleryFilter.today =>
        videos
            .where((v) => _isSameDay(v.recordedAt, now))
            .toList(growable: false),
      GalleryFilter.thisWeek =>
        videos
            .where((v) => _isSameWeek(v.recordedAt, now))
            .toList(growable: false),
      GalleryFilter.raroReplay =>
        videos.where((v) => v.isReplay).toList(growable: false),
    };
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isSameWeek(DateTime date, DateTime now) {
    final startOfWeek = _startOfDay(
      now,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
