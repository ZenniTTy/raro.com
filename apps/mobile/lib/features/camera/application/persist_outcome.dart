import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

sealed class PersistOutcome {
  const PersistOutcome();
}

class PersistNeedsPremium extends PersistOutcome {
  const PersistNeedsPremium();
}

class PersistSucceeded extends PersistOutcome {
  const PersistSucceeded(this.entity, {required this.galleryExported});

  final VideoEntity entity;
  final bool galleryExported;
}

class PersistFailed extends PersistOutcome {
  const PersistFailed(this.error);

  final Object error;
}
