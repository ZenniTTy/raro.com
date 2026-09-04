import 'dart:io';

import 'package:logger/logger.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class PersistRecording {
  const PersistRecording({
    required this.billing,
    required this.vault,
    required this.gallery,
    required this.thumbnails,
    required this.logger,
  });

  final BillingGateway billing;
  final VaultService vault;
  final SystemGalleryExporter gallery;
  final CameraRepository thumbnails;
  final Logger logger;

  Future<PersistOutcome> call(PendingClip clip) async {
    try {
      await billing.ensureConfigured();
      final customer = await billing.getCustomer();
      if (!customer.hasPremium) {
        return const PersistNeedsPremium();
      }
    } on BillingException catch (error, stack) {
      logger.e(
        'billing unavailable while persisting id=${clip.id}',
        error: error,
        stackTrace: stack,
      );
      return PersistFailed(error);
    }

    final source = File(clip.path);
    late final VideoEntity entity;
    try {
      entity = await vault.save(source, metadata: clip.metadata);
    } on Object catch (error, stack) {
      logger.e(
        'vault save failed id=${clip.id}',
        error: error,
        stackTrace: stack,
      );
      return PersistFailed(error);
    }

    final vaultPath = entity.filePath;
    var galleryExported = false;
    if (vaultPath != null) {
      try {
        await gallery.exportVideo(vaultPath);
        galleryExported = true;
      } on Object catch (error, stack) {
        logger.w(
          'system gallery export failed id=${clip.id} error=$error',
          error: error,
          stackTrace: stack,
        );
      }
      await _generateThumbnail(clip.id, vaultPath);
      if (source.path != vaultPath) {
        await _deleteSource(source);
      }
    }

    return PersistSucceeded(entity, galleryExported: galleryExported);
  }

  Future<void> _generateThumbnail(String id, String videoPath) async {
    try {
      final thumbnailPath = await thumbnails.generateThumbnail(videoPath);
      await vault.attachThumbnail(id, thumbnailPath);
    } on Object catch (error) {
      logger.w('thumbnail generation failed id=$id error=$error');
    }
  }

  Future<void> _deleteSource(File source) async {
    try {
      if (await source.exists()) {
        await source.delete();
      }
    } on Object catch (error) {
      logger.w('temp delete failed path=${source.path} error=$error');
    }
  }
}
