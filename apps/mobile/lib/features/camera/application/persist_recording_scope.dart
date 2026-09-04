import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';

sealed class PersistPendingResult {
  const PersistPendingResult();
}

final class PersistPendingAbsent extends PersistPendingResult {
  const PersistPendingAbsent();
}

final class PersistPendingSaved extends PersistPendingResult {
  const PersistPendingSaved(this.id);

  final String id;
}

final class PersistPendingFailed extends PersistPendingResult {
  const PersistPendingFailed();
}

final class PersistPendingNeedsPremium extends PersistPendingResult {
  const PersistPendingNeedsPremium();
}

Future<PersistRecording> persistRecordingFor(WidgetRef ref) {
  return _assemble(
    billing: ref.read(billingGatewayProvider),
    vault: ref.read(vaultServiceProvider.future),
    gallery: ref.read(systemGalleryExporterProvider),
    thumbnails: ref.read(cameraRepositoryProvider),
    logger: ref.read(appLoggerProvider),
  );
}

Future<PersistRecording> persistRecordingForRef(Ref ref) {
  return _assemble(
    billing: ref.read(billingGatewayProvider),
    vault: ref.read(vaultServiceProvider.future),
    gallery: ref.read(systemGalleryExporterProvider),
    thumbnails: ref.read(cameraRepositoryProvider),
    logger: ref.read(appLoggerProvider),
  );
}

Future<PersistRecording> _assemble({
  required BillingGateway billing,
  required Future<VaultService> vault,
  required SystemGalleryExporter gallery,
  required CameraRepository thumbnails,
  required Logger logger,
}) async {
  return PersistRecording(
    billing: billing,
    vault: await vault,
    gallery: gallery,
    thumbnails: thumbnails,
    logger: logger,
  );
}

Future<PersistPendingResult> persistPendingFor(WidgetRef ref) {
  return _persistPending(
    pending: ref.read(pendingRecordingProvider),
    persist: persistRecordingFor(ref),
    onSuccess: () {
      ref.read(pendingRecordingProvider.notifier).clearKept();
      ref.invalidate(videoListProvider);
    },
  );
}

Future<PersistPendingResult> persistPendingForRef(Ref ref) {
  return _persistPending(
    pending: ref.read(pendingRecordingProvider),
    persist: persistRecordingForRef(ref),
    onSuccess: () {
      ref.read(pendingRecordingProvider.notifier).clearKept();
      ref.invalidate(videoListProvider);
    },
  );
}

Future<PersistPendingResult> _persistPending({
  required PendingClip? pending,
  required Future<PersistRecording> persist,
  required void Function() onSuccess,
}) async {
  if (pending == null) return const PersistPendingAbsent();
  final outcome = await (await persist)(pending);
  if (outcome is PersistSucceeded) {
    onSuccess();
  }
  return switch (outcome) {
    PersistSucceeded() => PersistPendingSaved(pending.id),
    PersistFailed() => const PersistPendingFailed(),
    PersistNeedsPremium() => const PersistPendingNeedsPremium(),
  };
}
