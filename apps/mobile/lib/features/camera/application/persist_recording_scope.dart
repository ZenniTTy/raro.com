import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:logger/logger.dart';

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

Future<String?> persistPendingFor(WidgetRef ref) async {
  final pending = ref.read(pendingRecordingProvider);
  if (pending == null) return null;
  final outcome = await (await persistRecordingFor(ref))(pending);
  if (outcome is PersistSucceeded) {
    ref.read(pendingRecordingProvider.notifier).clearKept();
    ref.invalidate(videoListProvider);
  }
  return pending.id;
}
